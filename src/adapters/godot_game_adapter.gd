class_name GodotGameAdapter
extends Node
## GodotGameAdapter - Adapter Layer for DDD Architecture
## Bridges pure domain logic (RefCounted) with Godot presentation layer (Node)
## Synchronizes domain state to presentation and converts domain events to Godot signals

const GameState = preload("res://src/domain/aggregates/game_state.gd")
const GameLoop = preload("res://src/domain/game_loop.gd")
const GameTiming = preload("res://src/domain/constants/game_timing.gd")
const InputAdapter = preload("res://src/adapters/input_adapter.gd")
const TankEntity = preload("res://src/domain/entities/tank_entity.gd")
const BulletEntity = preload("res://src/domain/entities/bullet_entity.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")
const DomainEvent = preload("res://src/domain/events/domain_event.gd")
const TankSpawnedEvent = preload("res://src/domain/events/tank_spawned_event.gd")
const TankMovedEvent = preload("res://src/domain/events/tank_moved_event.gd")
const TankDamagedEvent = preload("res://src/domain/events/tank_damaged_event.gd")
const TankDestroyedEvent = preload("res://src/domain/events/tank_destroyed_event.gd")
const BulletFiredEvent = preload("res://src/domain/events/bullet_fired_event.gd")
const BulletMovedEvent = preload("res://src/domain/events/bullet_moved_event.gd")
const BulletDestroyedEvent = preload("res://src/domain/events/bullet_destroyed_event.gd")
const StageCompleteEvent = preload("res://src/domain/events/stage_complete_event.gd")
const GameOverEvent = preload("res://src/domain/events/game_over_event.gd")
const LOGIC_TPS: int = GameTiming.LOGIC_TPS

## Signals for presentation layer
signal tank_spawned(tank_id: String, position: Vector2, tank_type: int, direction: int)
signal tank_moved(tank_id: String, old_position: Vector2, new_position: Vector2, direction: int)
signal tank_damaged(tank_id: String, damage: int, old_health: int, new_health: int)
signal tank_destroyed(tank_id: String, position: Vector2)
signal bullet_fired(bullet_id: String, position: Vector2, direction: int, tank_id: String)
signal bullet_moved(bullet_id: String, old_position: Vector2, new_position: Vector2)
signal bullet_destroyed(bullet_id: String, position: Vector2)
signal stage_complete()
signal game_over(reason: String)
signal lives_changed(lives: int)
signal score_changed(score: int)

## Domain state
var game_state: GameState
var game_loop: GameLoop

## Input handler (can be swapped for remote/server command providers)
var input_adapter
var command_provider

## Tracking dictionaries for entity lifecycle
var tracked_tanks: Dictionary # tank_id -> {position, health, direction}
var tracked_bullets: Dictionary # bullet_id -> {position}
var tracked_lives: int = -1
var tracked_score: int = -1

## Constants
const TILE_SIZE: float = 16.0 # Pixels per tile (for 2D)
const PHYSICS_FPS: int = 60

## Player tank ID (to be set externally)
var player_tank_id: String = ""

## Initialize the adapter with a game state
func initialize(p_game_state: GameState) -> void:
	game_state = p_game_state
	game_loop = GameLoop.new()
	game_loop.set_ticks_per_second(LOGIC_TPS)
	input_adapter = InputAdapter.new()
	command_provider = input_adapter
	tracked_tanks = {}
	tracked_bullets = {}
	tracked_lives = game_state.player_lives
	tracked_score = game_state.score
	
	# Enable physics processing for frame-based updates
	set_physics_process(true)

func _ready() -> void:
	# Adapter should be initialized externally via initialize()
	set_physics_process(false)

## Process one physics frame (60 FPS)
func _physics_process(_delta: float) -> void:
	if game_state == null or game_loop == null:
		return
	
	# 1. Gather input commands
	var commands: Array = []
	if player_tank_id != "" and game_state.get_tank(player_tank_id) != null and command_provider and command_provider.has_method("get_commands_for_frame"):
		commands = command_provider.get_commands_for_frame(player_tank_id, game_state.frame)
	
	# 2. Process frame in domain (pure logic)
	var events = game_loop.process_frame(game_state, commands, _delta)
	
	# 3. Convert domain events to Godot signals
	_process_domain_events(events)
	
	# 4. Sync domain state to presentation
	sync_state_to_presentation()
	_sync_meta()

## Sync domain state to presentation layer
func sync_state_to_presentation() -> void:
	# Sync tanks
	_sync_tanks()
	
	# Sync bullets
	_sync_bullets()
	
	# Clean up removed entities
	_cleanup_removed_entities()

## Sync all tanks from domain to presentation
func _sync_tanks() -> void:
	for tank in game_state.get_all_tanks():
		var tank_id = tank.id
		if tank.is_player and (player_tank_id == "" or game_state.get_tank(player_tank_id) == null):
			player_tank_id = tank_id
		
		# Check if this is a new tank
		if not tracked_tanks.has(tank_id):
			# New tank - emit spawned signal
			var godot_pos = domain_position_to_godot(tank.position)
			tank_spawned.emit(tank_id, godot_pos, tank.tank_type, tank.direction.value)
			
			# Start tracking
			tracked_tanks[tank_id] = {
				"position": Position.create(tank.position.x, tank.position.y),
				"health": tank.health.current,
				"direction": tank.direction.value
			}
		else:
			# Existing tank - check for changes
			var tracked = tracked_tanks[tank_id]
			
			# Check position change
			if tracked["position"].x != tank.position.x or tracked["position"].y != tank.position.y:
				var old_pos = domain_position_to_godot(tracked["position"])
				var new_pos = domain_position_to_godot(tank.position)
				tank_moved.emit(tank_id, old_pos, new_pos, tank.direction.value)
				tracked["position"] = Position.create(tank.position.x, tank.position.y)
			
			# Check health change
			if tracked["health"] != tank.health.current:
				var damage = tracked["health"] - tank.health.current
				tank_damaged.emit(tank_id, damage, tracked["health"], tank.health.current)
				tracked["health"] = tank.health.current
			
			# Update direction
			tracked["direction"] = tank.direction.value

## Sync all bullets from domain to presentation
func _sync_bullets() -> void:
	for bullet in game_state.get_all_bullets():
		var bullet_id = bullet.id
		
		# Check if this is a new bullet
		if not tracked_bullets.has(bullet_id):
			# New bullet - emit fired signal
			var godot_pos = domain_position_to_godot(bullet.position)
			bullet_fired.emit(bullet_id, godot_pos, bullet.direction.value, bullet.owner_id)
			
			# Start tracking
			tracked_bullets[bullet_id] = {
				"position": Position.create(bullet.position.x, bullet.position.y)
			}
		else:
			# Existing bullet - check for position change
			var tracked = tracked_bullets[bullet_id]
			
			if tracked["position"].x != bullet.position.x or tracked["position"].y != bullet.position.y:
				var old_pos = domain_position_to_godot(tracked["position"])
				var new_pos = domain_position_to_godot(bullet.position)
				bullet_moved.emit(bullet_id, old_pos, new_pos)
				tracked["position"] = Position.create(bullet.position.x, bullet.position.y)

## Clean up removed entities (tanks and bullets no longer in domain state)
func _cleanup_removed_entities() -> void:
	# Check for removed tanks
	var tanks_to_remove = []
	for tank_id in tracked_tanks:
		if game_state.get_tank(tank_id) == null:
			# Tank was removed - emit destroyed signal
			var tracked = tracked_tanks[tank_id]
			var godot_pos = domain_position_to_godot(tracked["position"])
			tank_destroyed.emit(tank_id, godot_pos)
			tanks_to_remove.append(tank_id)
	
	# Remove from tracking
	for tank_id in tanks_to_remove:
		tracked_tanks.erase(tank_id)
	
	# Check for removed bullets
	var bullets_to_remove = []
	for bullet_id in tracked_bullets:
		if game_state.get_bullet(bullet_id) == null:
			# Bullet was removed - emit destroyed signal
			var tracked = tracked_bullets[bullet_id]
			var godot_pos = domain_position_to_godot(tracked["position"])
			bullet_destroyed.emit(bullet_id, godot_pos)
			bullets_to_remove.append(bullet_id)
	
	# Remove from tracking
	for bullet_id in bullets_to_remove:
		tracked_bullets.erase(bullet_id)

## Sync meta values like lives and score
func _sync_meta() -> void:
	if game_state == null:
		return
	if tracked_lives != game_state.player_lives:
		tracked_lives = game_state.player_lives
		lives_changed.emit(tracked_lives)
	if tracked_score != game_state.score:
		tracked_score = game_state.score
		score_changed.emit(tracked_score)

## Process domain events and emit corresponding Godot signals
func _process_domain_events(events: Array) -> void:
	for event in events:
		if event is StageCompleteEvent:
			stage_complete.emit()
		elif event is GameOverEvent:
			game_over.emit(event.reason)
		# Note: Most events are handled via sync_state_to_presentation
		# This is for game-level events that need immediate signaling

## Convert domain Position (tile coords) to Godot Vector2 (pixel coords)
func domain_position_to_godot(pos: Position) -> Vector2:
	return Vector2(pos.x * TILE_SIZE, pos.y * TILE_SIZE)

## Convert Godot Vector2 (pixel coords) to domain Position (tile coords)
func godot_position_to_domain(pos: Vector2) -> Position:
	return Position.create(
		int(pos.x / TILE_SIZE),
		int(pos.y / TILE_SIZE)
	)

## Convert domain Direction to rotation angle (radians)
func direction_to_rotation(direction: Direction) -> float:
	match direction.value:
		Direction.UP:
			return -PI / 2 # -90 degrees
		Direction.DOWN:
			return PI / 2 # 90 degrees
		Direction.LEFT:
			return PI # 180 degrees
		Direction.RIGHT:
			return 0.0 # 0 degrees
		_:
			return 0.0

## Set the player tank ID for input processing
func set_player_tank(tank_id: String) -> void:
	player_tank_id = tank_id

## Swap the command provider (e.g., remote/network source)
func set_command_provider(provider) -> void:
	command_provider = provider

## Get current frame number
func get_current_frame() -> int:
	if game_state:
		return game_state.frame
	return 0

func get_tick_progress() -> float:
	if game_loop == null:
		return 0.0
	return game_loop.get_tick_progress()
