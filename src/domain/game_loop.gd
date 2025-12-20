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
const DomainEvent = preload("res://src/domain/events/domain_event.gd")
const TankDestroyedEvent = preload("res://src/domain/events/tank_destroyed_event.gd")
const BulletDestroyedEvent = preload("res://src/domain/events/bullet_destroyed_event.gd")
const BulletMovedEvent = preload("res://src/domain/events/bullet_moved_event.gd")
const CollisionEvent = preload("res://src/domain/events/collision_event.gd")
const TankDamagedEvent = preload("res://src/domain/events/tank_damaged_event.gd")
const StageCompleteEvent = preload("res://src/domain/events/stage_complete_event.gd")
const GameOverEvent = preload("res://src/domain/events/game_over_event.gd")
const Position = preload("res://src/domain/value_objects/position.gd")

## Process one game frame
## Returns array of events that occurred this frame
static func process_frame(game_state: GameState, commands: Array) -> Array[DomainEvent]:
	var events: Array[DomainEvent] = []
	
	# Early exit if game is paused or over
	if game_state.is_paused or game_state.is_game_over:
		return events
	
	# 1. Execute player/AI commands
	for command in commands:
		var cmd_events = CommandHandler.execute_command(game_state, command)
		events.append_array(cmd_events)
	
	# 2. Update tank cooldowns
	for tank in game_state.get_all_tanks():
		tank.update_cooldown()
	
	# 3. Move all bullets and emit move events
	for bullet in game_state.get_all_bullets():
		if bullet.is_active:
			var old_pos = Position.create(bullet.position.x, bullet.position.y)
			MovementService.execute_bullet_movement(game_state, bullet)
			if bullet.is_active: # Only emit event if bullet still active after move
				events.append(BulletMovedEvent.create(
					bullet.id,
					old_pos,
					bullet.position,
					game_state.frame
				))
	
	# 4. Detect and handle collisions
	var collision_events = _detect_and_handle_collisions(game_state)
	events.append_array(collision_events)
	
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

## Detect and handle all collisions in the game state
## Returns array of collision and damage events
static func _detect_and_handle_collisions(game_state: GameState) -> Array[DomainEvent]:
	var events: Array[DomainEvent] = []
	
	# Tank-Bullet collisions
	for bullet in game_state.get_all_bullets():
		if not bullet.is_active:
			continue
			
		for tank in game_state.get_all_tanks():
			if not tank.is_alive():
				continue
				
			if CollisionService.check_tank_bullet_collision(tank, bullet):
				var old_health = tank.health.current
				tank.take_damage(bullet.damage)
				var new_health = tank.health.current
				bullet.deactivate()
				
				# Emit collision event
				events.append(CollisionEvent.create(
					tank.id,
					bullet.id,
					tank.position,
					"tank_bullet",
					game_state.frame
				))
				
				# Emit damage event
				events.append(TankDamagedEvent.create(
					tank.id,
					bullet.damage,
					old_health,
					new_health,
					game_state.frame
				))
				break
	
	# Bullet-Base collisions
	if game_state.stage.base != null and game_state.stage.base.is_alive():
		for bullet in game_state.get_all_bullets():
			if not bullet.is_active:
				continue
				
			if CollisionService.check_bullet_base_collision(bullet, game_state.stage.base):
				game_state.stage.base.take_damage(bullet.damage)
				bullet.deactivate()
				
				# Emit collision event
				events.append(CollisionEvent.create(
					game_state.stage.base.id,
					bullet.id,
					game_state.stage.base.position,
					"bullet_base",
					game_state.frame
				))
	
	# Bullet-Terrain collisions
	for bullet in game_state.get_all_bullets():
		if not bullet.is_active:
			continue
			
		var terrain = game_state.stage.get_terrain_at(bullet.position)
		if terrain != null and CollisionService.check_bullet_terrain_collision(bullet, terrain):
			terrain.take_damage(bullet.damage)
			bullet.deactivate()
			
			# Create a string ID for terrain (position-based)
			var terrain_id = "terrain_%d_%d" % [terrain.position.x, terrain.position.y]
			
			# Emit collision event
			events.append(CollisionEvent.create(
				terrain_id,
				bullet.id,
				terrain.position,
				"bullet_terrain",
				game_state.frame
			))
	
	return events
