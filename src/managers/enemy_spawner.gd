class_name EnemySpawner
extends Node
## Manages enemy tank spawning and wave progression

signal wave_started(stage: int, total_enemies: int)
signal enemy_spawned(enemy: Tank, spawn_position: Vector2)
signal wave_completed(stage: int)
signal all_enemies_defeated()

# Spawn configuration
const ENEMIES_PER_STAGE: int = 20
const MAX_CONCURRENT_ENEMIES: int = 4
const SPAWN_INTERVAL: float = 3.0  # Seconds between spawns
const SPAWN_Y_POSITION: float = 32.0  # 2 tiles from top

# Testing mode - set to true for infinite spawning
@export var infinite_spawn_mode: bool = false
@export var test_armored_only: bool = false  # Spawn only Armored tanks for power-up testing

# Spawn points (26x26 grid, tiles are 16px)
const SPAWN_POINTS: Array[Vector2] = [
	Vector2(48, SPAWN_Y_POSITION),   # Left (tile 3)
	Vector2(208, SPAWN_Y_POSITION),  # Center (tile 13)
	Vector2(368, SPAWN_Y_POSITION)   # Right (tile 23)
]

# Wave state
var current_stage: int = 1
var enemies_remaining: int = 0
var enemies_spawned: int = 0
var active_enemies: Array[Tank] = []
var spawn_timer: float = 0.0
var is_spawning: bool = false

# Enemy composition per stage (indexes into TankType enum)
var enemy_queue: Array[Tank.TankType] = []

# Tank scene for instantiation
var tank_scene: PackedScene = preload("res://scenes/enemy_tank.tscn")

func _ready() -> void:
	EventBus.subscribe("TankDestroyed", _on_tank_destroyed)
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	if not is_spawning:
		return
	
	spawn_timer += delta
	if spawn_timer >= SPAWN_INTERVAL:
		spawn_timer = 0.0
		_try_spawn_enemy()

func start_wave(stage: int) -> void:
	"""Initialize and start a new enemy wave"""
	current_stage = stage
	enemies_remaining = ENEMIES_PER_STAGE
	enemies_spawned = 0
	active_enemies.clear()
	spawn_timer = 0.0
	is_spawning = true
	
	_generate_enemy_queue(stage)
	wave_started.emit(stage, ENEMIES_PER_STAGE)
	set_physics_process(true)

func stop_wave() -> void:
	"""Stop spawning enemies"""
	is_spawning = false
	set_physics_process(false)

func get_active_enemy_count() -> int:
	"""Returns number of enemies currently alive"""
	return active_enemies.size()

func get_enemies_remaining() -> int:
	"""Returns total enemies left to spawn + active"""
	return enemies_remaining

func _try_spawn_enemy() -> void:
	"""Attempt to spawn an enemy if conditions are met"""
	if not is_spawning:
		return
	
	# Check concurrent limit
	if active_enemies.size() >= MAX_CONCURRENT_ENEMIES:
		return
	
	# Check if wave complete (skip in infinite mode)
	if not infinite_spawn_mode and enemies_spawned >= ENEMIES_PER_STAGE:
		return
	
	# Get next enemy type from queue (or force Armored in test mode)
	var enemy_type: Tank.TankType
	if test_armored_only:
		enemy_type = Tank.TankType.ARMORED
	elif infinite_spawn_mode:
		# In infinite mode, cycle through queue and repeat
		var queue_index = enemies_spawned % enemy_queue.size()
		enemy_type = enemy_queue[queue_index]
	else:
		enemy_type = enemy_queue[enemies_spawned]
	var spawn_point: Vector2 = _get_spawn_position()
	
	# Create enemy tank
	var enemy: Tank = tank_scene.instantiate()
	enemy.tank_type = enemy_type
	enemy.is_player = false
	enemy.tank_id = enemies_spawned + 1000  # Offset to avoid collision with player
	enemy.invulnerability_duration = 1.0  # Shorter spawn protection for enemies
	
	# Configure based on type
	match enemy_type:
		Tank.TankType.BASIC:
			enemy.base_speed = 50.0
			enemy.max_health = 1
			enemy.modulate = Color(0.8, 0.6, 0.4)  # Brown - basic enemy
		Tank.TankType.FAST:
			enemy.base_speed = 100.0
			enemy.max_health = 1
			enemy.modulate = Color(0.4, 0.8, 0.4)  # Green - fast enemy
		Tank.TankType.POWER:
			enemy.base_speed = 50.0
			enemy.max_health = 4
			enemy.modulate = Color(0.9, 0.9, 0.3)  # Yellow - power enemy
		Tank.TankType.ARMORED:
			enemy.base_speed = 50.0
			enemy.max_health = 2
			enemy.modulate = Color(0.9, 0.3, 0.3)  # Red - armored enemy (drops power-ups)
	
	enemy.position = spawn_point
	enemy.current_health = enemy.max_health
	
	# Add to scene and track
	get_parent().add_child(enemy)
	enemy.add_to_group("tanks")
	enemy.add_to_group("enemies")
	
	# Add AI controller to enemy tank
	var ai_controller = EnemyAIController.new()
	ai_controller.tank = enemy
	# Get player reference and base position from scene
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		ai_controller.player = players[0]
	var bases = get_tree().get_nodes_in_group("base")
	if bases.size() > 0:
		ai_controller.base_position = bases[0].global_position
	enemy.add_child(ai_controller)
	
	# Reduce spawn time for enemies
	enemy.spawn_timer = 0.5  # Faster spawn for enemies
	
	active_enemies.append(enemy)
	enemies_spawned += 1
	
	# Emit events
	enemy_spawned.emit(enemy, spawn_point)
	
	var spawn_event := TankSpawnedEvent.new()
	spawn_event.tank_id = enemy.tank_id
	spawn_event.tank_type = _tank_type_to_string(enemy_type)
	spawn_event.position = spawn_point
	spawn_event.is_player = false
	EventBus.emit_game_event(spawn_event)

func _get_spawn_position() -> Vector2:
	"""Cycle through spawn points"""
	var spawn_index: int = enemies_spawned % SPAWN_POINTS.size()
	return SPAWN_POINTS[spawn_index]

func _generate_enemy_queue(stage: int) -> void:
	"""Generate enemy composition based on stage difficulty"""
	enemy_queue.clear()
	
	# Stage difficulty progression
	var fast_count: int = mini(stage * 2, 8)
	var power_count: int = mini(stage, 5)
	var armored_count: int = mini(int(stage / 3.0), 3)  # Integer division
	var basic_count: int = ENEMIES_PER_STAGE - fast_count - power_count - armored_count
	
	# Build queue
	for i in basic_count:
		enemy_queue.append(Tank.TankType.BASIC)
	for i in fast_count:
		enemy_queue.append(Tank.TankType.FAST)
	for i in power_count:
		enemy_queue.append(Tank.TankType.POWER)
	for i in armored_count:
		enemy_queue.append(Tank.TankType.ARMORED)
	
	# Shuffle for variety
	enemy_queue.shuffle()

func _on_tank_destroyed(event: TankDestroyedEvent) -> void:
	"""Handle enemy tank destruction"""
	# Find and remove from active list
	for i in range(active_enemies.size() - 1, -1, -1):
		if active_enemies[i].tank_id == event.tank_id:
			active_enemies.remove_at(i)
			enemies_remaining -= 1
			break
	
	# Check wave completion
	if enemies_remaining <= 0 and active_enemies.is_empty():
		_complete_wave()

func _complete_wave() -> void:
	"""Handle wave completion"""
	is_spawning = false
	set_physics_process(false)
	wave_completed.emit(current_stage)
	all_enemies_defeated.emit()

func _tank_type_to_string(type: Tank.TankType) -> String:
	"""Convert TankType enum to string for events"""
	match type:
		Tank.TankType.PLAYER:
			return "Player"
		Tank.TankType.BASIC:
			return "Basic"
		Tank.TankType.FAST:
			return "Fast"
		Tank.TankType.POWER:
			return "Power"
		Tank.TankType.ARMORED:
			return "Armored"
		_:
			return "Unknown"

func _exit_tree() -> void:
	EventBus.unsubscribe("TankDestroyed", _on_tank_destroyed)
