class_name GameLoop
extends RefCounted
## Deterministic frame-based game loop
## Processes commands, updates state, detects collisions, and emits events
## Part of DDD architecture - pure domain logic with no Godot dependencies

const GameState = preload("res://src/domain/aggregates/game_state.gd")
const Command = preload("res://src/domain/commands/command.gd")
const CommandHandler = preload("res://src/domain/services/command_handler.gd")
const MovementService = preload("res://src/domain/services/movement_service.gd")
const CollisionService = preload("res://src/domain/services/collision_service.gd")
const TickManager = preload("res://src/domain/services/tick_manager.gd")
const AIService = preload("res://src/domain/services/ai_service.gd")
const SpawnController = preload("res://src/domain/services/spawn_controller.gd")
const DomainEvent = preload("res://src/domain/events/domain_event.gd")
const TankDestroyedEvent = preload("res://src/domain/events/tank_destroyed_event.gd")
const BulletDestroyedEvent = preload("res://src/domain/events/bullet_destroyed_event.gd")
const BulletMovedEvent = preload("res://src/domain/events/bullet_moved_event.gd")
const CollisionEvent = preload("res://src/domain/events/collision_event.gd")
const TankDamagedEvent = preload("res://src/domain/events/tank_damaged_event.gd")
const StageCompleteEvent = preload("res://src/domain/events/stage_complete_event.gd")
const GameOverEvent = preload("res://src/domain/events/game_over_event.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const TankEntity = preload("res://src/domain/entities/tank_entity.gd")

# Instance-based tick manager (for Phase 1.3)
var _tick_manager: TickManager

func _init():
	_tick_manager = TickManager.new()

## Set ticks per second for tick-based game loop
func set_ticks_per_second(tps: int) -> void:
	_tick_manager.set_ticks_per_second(tps)

func get_tick_progress() -> float:
	return _tick_manager.get_tick_progress()

## Instance method: Process one game frame with tick-based logic
## Returns array of events that occurred this frame (or empty if tick not ready)
func process_frame(game_state: GameState, commands: Array, delta: float) -> Array[DomainEvent]:
	var events: Array[DomainEvent] = []
	var current_delta = delta
	while _tick_manager.should_process_tick(current_delta):
		current_delta = 0.0
		events.append_array(process_frame_static(game_state, commands, _tick_manager.get_fixed_delta()))
	return events

## Static method: Process one game frame (legacy/direct call)
## Returns array of events that occurred this frame
static func process_frame_static(game_state: GameState, commands: Array, fixed_delta: float = 0.1) -> Array[DomainEvent]:
	var events: Array[DomainEvent] = []
	
	# Early exit if game is paused or over
	if game_state.is_paused or game_state.is_game_over:
		return events
	
	# 0a. Check if enemy should spawn
	if game_state.spawn_controller and game_state.spawn_controller.should_spawn(game_state, fixed_delta):
		var new_enemy = game_state.spawn_controller.spawn_enemy(game_state)
		if new_enemy:
			# Enemy spawned - game_state already updated
			pass
	
	# 0b. AI decisions for enemy tanks
	for tank in game_state.get_all_tanks():
		if tank.tank_type != TankEntity.Type.PLAYER: # Only AI for enemies
			var ai_command = AIService.decide_action(tank, game_state, fixed_delta)
			if ai_command:
				commands.append(ai_command)
	
	# 1. Execute player/AI commands
	for command in commands:
		var cmd_events = CommandHandler.execute_command(game_state, command)
		events.append_array(cmd_events)
	
	# 2. Update tank cooldowns
	for tank in game_state.get_all_tanks():
		tank.update_cooldown()
	
	# 3. Move bullets with per-step collision handling to avoid tunneling
	var bullet_events = _move_bullets_and_handle_collisions(game_state)
	events.append_array(bullet_events)
	
	# 5. Remove destroyed entities
	var destroyed_tanks = []
	var destroyed_bullets = []
	
	# Find destroyed tanks
	for tank in game_state.get_all_tanks():
		if not tank.is_alive():
			destroyed_tanks.append(tank.id)
			events.append(TankDestroyedEvent.create(
				tank.id,
				tank.position,
				"", # killer_id (unknown at this point)
				game_state.frame
			))
	
	# Find destroyed bullets
	for bullet in game_state.get_all_bullets():
		if not bullet.is_active:
			destroyed_bullets.append(bullet.id)
			events.append(BulletDestroyedEvent.create(
				bullet.id,
				bullet.position,
				"deactivated",
				game_state.frame
			))
	
	# Remove destroyed tanks
	for tank_id in destroyed_tanks:
		game_state.remove_tank(tank_id)
	
	# Remove destroyed bullets
	for bullet_id in destroyed_bullets:
		game_state.remove_bullet(bullet_id)
	
	# 6. Check win/loss conditions
	if game_state.is_stage_complete():
		events.append(StageCompleteEvent.create(game_state.frame))
	elif game_state.is_stage_failed():
		events.append(GameOverEvent.create(game_state.frame, "Base destroyed or no lives"))
	
	# 7. Advance frame counter
	game_state.advance_frame()
	
	return events

## Move bullets step-by-step and resolve collisions during movement
## Returns array of movement and collision events
static func _move_bullets_and_handle_collisions(game_state: GameState) -> Array[DomainEvent]:
	var events: Array[DomainEvent] = []
	
	for bullet in game_state.get_all_bullets():
		if not bullet.is_active:
			continue
		
		var steps = max(1, max(abs(bullet.velocity.dx), abs(bullet.velocity.dy)))
		var step_dx = 0 if bullet.velocity.dx == 0 else int(sign(bullet.velocity.dx))
		var step_dy = 0 if bullet.velocity.dy == 0 else int(sign(bullet.velocity.dy))
		
		for _i in range(steps):
			if not bullet.is_active:
				break
			
			var old_pos = Position.create(bullet.position.x, bullet.position.y)
			bullet.position = Position.create(bullet.position.x + step_dx, bullet.position.y + step_dy)
			
			# Out of bounds check
			if not game_state.stage.is_within_bounds(bullet.position):
				bullet.deactivate()
				break
			
			# Tank collisions
			var hit_something = false
			for tank in game_state.get_all_tanks():
				if not tank.is_alive():
					continue
				if tank.id == bullet.owner_id:
					continue
				if CollisionService.check_tank_bullet_collision(tank, bullet):
					var old_health = tank.health.current
					tank.take_damage(bullet.damage)
					var new_health = tank.health.current
					bullet.deactivate()
					events.append(CollisionEvent.create(
						tank.id,
						bullet.id,
						tank.position,
						"tank_bullet",
						game_state.frame
					))
					events.append(TankDamagedEvent.create(
						tank.id,
						bullet.damage,
						old_health,
						new_health,
						game_state.frame
					))
					hit_something = true
					break
			if hit_something:
				break
			
			# Base collision
			if game_state.stage.base != null and game_state.stage.base.is_alive():
				if CollisionService.check_bullet_base_collision(bullet, game_state.stage.base):
					game_state.stage.base.take_damage(bullet.damage)
					bullet.deactivate()
					events.append(CollisionEvent.create(
						game_state.stage.base.id,
						bullet.id,
						game_state.stage.base.position,
						"bullet_base",
						game_state.frame
					))
					hit_something = true
					break
			
			# Terrain collision
			var terrain = game_state.stage.get_terrain_at(bullet.position)
			if terrain != null and CollisionService.check_bullet_terrain_collision(bullet, terrain):
				terrain.take_damage(bullet.damage)
				bullet.deactivate()
				var terrain_id = "terrain_%d_%d" % [terrain.position.x, terrain.position.y]
				events.append(CollisionEvent.create(
					terrain_id,
					bullet.id,
					terrain.position,
					"bullet_terrain",
					game_state.frame
				))
				hit_something = true
				break
			
			# Bullet-to-bullet collision
			for other_bullet in game_state.get_all_bullets():
				if other_bullet == bullet or not other_bullet.is_active:
					continue
				if CollisionService.check_bullet_to_bullet_collision(bullet, other_bullet):
					bullet.deactivate()
					other_bullet.deactivate()
					events.append(BulletDestroyedEvent.create(bullet.id, bullet.position, "bullet_collision", game_state.frame))
					events.append(BulletDestroyedEvent.create(other_bullet.id, other_bullet.position, "bullet_collision", game_state.frame))
					hit_something = true
					break
			if hit_something:
				break
			
			# If still active after this step, emit movement event for interpolation
			events.append(BulletMovedEvent.create(
				bullet.id,
				old_pos,
				bullet.position,
				game_state.frame
			))

	return events
