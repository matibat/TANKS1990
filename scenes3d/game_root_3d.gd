class_name GameRoot3D
extends Node3D
## GameRoot3D - Presentation Layer Root Script for DDD Architecture
## Manages visual representation of game entities by listening to adapter signals
## Pure presentation logic - no game rules, just visual updates

const GodotGameAdapter = preload("res://src/adapters/godot_game_adapter.gd")
const GameState = preload("res://src/domain/aggregates/game_state.gd")
const StageState = preload("res://src/domain/aggregates/stage_state.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")
const TankEntity = preload("res://src/domain/entities/tank_entity.gd")
const TerrainCell = preload("res://src/domain/entities/terrain_cell.gd")
const SpawningService = preload("res://src/domain/services/spawning_service.gd")
const Tank3D = preload("res://scenes3d/tank_3d.gd")
const Bullet3D = preload("res://scenes3d/bullet_3d.gd")

## Node references
@onready var adapter: GodotGameAdapter = $GodotGameAdapter
@onready var tanks_container: Node3D = $Tanks
@onready var bullets_container: Node3D = $Bullets
@onready var camera: Camera3D = $Camera3D

## Visual node instances
var tank_nodes: Dictionary = {} # tank_id -> Tank3D instance
var bullet_nodes: Dictionary = {} # bullet_id -> Bullet3D instance

## Coordinate conversion
const TILE_SIZE: float = 1.0 # 1 tile = 1 unit in 3D space

## Game state tracking
var player_tank_id: String = ""

func _ready() -> void:
	# Create and initialize game state
	var game_state = _create_test_game_state()
	
	# Initialize adapter
	adapter.initialize(game_state)
	
	# Connect adapter signals
	_connect_adapter_signals()
	
	# Set player tank for input
	if player_tank_id != "":
		adapter.set_player_tank(player_tank_id)
	
	print("GameRoot3D ready - DDD architecture initialized")
	print("Player tank ID: ", player_tank_id)

## Connect all adapter signals to presentation handlers
func _connect_adapter_signals() -> void:
	adapter.tank_spawned.connect(_on_tank_spawned)
	adapter.tank_moved.connect(_on_tank_moved)
	adapter.tank_damaged.connect(_on_tank_damaged)
	adapter.tank_destroyed.connect(_on_tank_destroyed)
	adapter.bullet_fired.connect(_on_bullet_fired)
	adapter.bullet_moved.connect(_on_bullet_moved)
	adapter.bullet_destroyed.connect(_on_bullet_destroyed)
	adapter.stage_complete.connect(_on_stage_complete)
	adapter.game_over.connect(_on_game_over)

## Create a test game state with player and enemies
func _create_test_game_state() -> GameState:
	# Create stage first
	var stage = StageState.create(1, 26, 26)
	
	# Add terrain (simple walls around the perimeter)
	for x in range(26):
		stage.add_terrain_cell(TerrainCell.create(Position.create(x, 0), TerrainCell.CellType.BRICK))
		stage.add_terrain_cell(TerrainCell.create(Position.create(x, 25), TerrainCell.CellType.BRICK))
	for y in range(1, 25):
		stage.add_terrain_cell(TerrainCell.create(Position.create(0, y), TerrainCell.CellType.BRICK))
		stage.add_terrain_cell(TerrainCell.create(Position.create(25, y), TerrainCell.CellType.BRICK))
	
	# Add base at bottom center
	stage.set_base(Position.create(12, 23))
	
	# Set enemy spawn positions (top of map)
	stage.add_enemy_spawn(Position.create(5, 2))
	stage.add_enemy_spawn(Position.create(13, 2))
	stage.add_enemy_spawn(Position.create(20, 2))
	
	# Set stage enemy counts
	stage.enemies_remaining = 3
	stage.enemies_on_field = 0
	
	# Set player spawn positions
	stage.add_player_spawn(Position.create(12, 20))
	
	# Create game state with the stage
	var game_state = GameState.create(stage, 3)
	
	# Spawn player tank at first spawn position
	var player_tank = SpawningService.spawn_player_tank(game_state, 0)
	game_state.add_tank(player_tank)
	player_tank_id = player_tank.id
	
	# Spawn one enemy tank for testing
	if stage.can_spawn_enemy():
		var enemy_tank = SpawningService.spawn_enemy_tank(game_state, TankEntity.Type.ENEMY_BASIC, 0)
		game_state.add_tank(enemy_tank)
	
	return game_state

## Signal Handlers - Tank Events

func _on_tank_spawned(tank_id: String, position: Vector2, tank_type: int, direction: int) -> void:
	var tank_node: Tank3D = preload("res://scenes3d/tank_3d.tscn").instantiate() as Tank3D
	tank_node.tank_id = tank_id
	tank_node.tank_type = tank_type
	tank_node.name = "Tank_" + tank_id
	
	# Set initial position and rotation
	tank_node.position = _tile_to_world_pos(position)
	tank_node.rotation.y = _direction_to_rotation(direction)
	
	# Add to scene
	tanks_container.add_child(tank_node)
	tank_nodes[tank_id] = tank_node
	
	print("Tank spawned: ", tank_id, " at ", position, " type: ", tank_type)

func _on_tank_moved(tank_id: String, old_position: Vector2, new_position: Vector2, direction: int) -> void:
	if tank_nodes.has(tank_id):
		var tank_node = tank_nodes[tank_id]
		tank_node.move_to(_tile_to_world_pos(new_position), _direction_to_rotation(direction))

func _on_tank_damaged(tank_id: String, damage: int, old_health: int, new_health: int) -> void:
	if tank_nodes.has(tank_id):
		var tank_node = tank_nodes[tank_id]
		tank_node.take_damage(damage, new_health)
	
	print("Tank damaged: ", tank_id, " health: ", old_health, " -> ", new_health)

func _on_tank_destroyed(tank_id: String, position: Vector2) -> void:
	if tank_nodes.has(tank_id):
		var tank_node = tank_nodes[tank_id]
		tank_node.play_destroy_effect()
		
		# Remove after animation
		await get_tree().create_timer(0.5).timeout
		tank_node.queue_free()
		tank_nodes.erase(tank_id)
	
	print("Tank destroyed: ", tank_id, " at ", position)

## Signal Handlers - Bullet Events

func _on_bullet_fired(bullet_id: String, position: Vector2, direction: int, tank_id: String) -> void:
	var bullet_node: Bullet3D = preload("res://scenes3d/bullet_3d.tscn").instantiate() as Bullet3D
	bullet_node.bullet_id = bullet_id
	bullet_node.name = "Bullet_" + bullet_id
	
	# Set initial position and rotation
	bullet_node.position = _tile_to_world_pos(position)
	bullet_node.rotation.y = _direction_to_rotation(direction)
	
	# Add to scene
	bullets_container.add_child(bullet_node)
	bullet_nodes[bullet_id] = bullet_node

func _on_bullet_moved(bullet_id: String, old_position: Vector2, new_position: Vector2) -> void:
	if bullet_nodes.has(bullet_id):
		var bullet_node = bullet_nodes[bullet_id]
		bullet_node.move_to(_tile_to_world_pos(new_position))

func _on_bullet_destroyed(bullet_id: String, position: Vector2) -> void:
	if bullet_nodes.has(bullet_id):
		var bullet_node = bullet_nodes[bullet_id]
		bullet_node.play_destroy_effect()
		
		# Remove after brief delay
		await get_tree().create_timer(0.1).timeout
		bullet_node.queue_free()
		bullet_nodes.erase(bullet_id)

## Signal Handlers - Game Events

func _on_stage_complete() -> void:
	print("=== STAGE COMPLETE ===")
	# Could show UI, load next stage, etc.

func _on_game_over(reason: String) -> void:
	print("=== GAME OVER ===")
	print("Reason: ", reason)
	# Could show game over screen, etc.

## Coordinate Conversion

func _tile_to_world_pos(tile_pos: Vector2) -> Vector3:
	# Convert from tile coordinates (2D) to world position (3D)
	# Y tile coord becomes Z in 3D, X stays X, Y=0 (ground level)
	return Vector3(tile_pos.x * TILE_SIZE, 0, tile_pos.y * TILE_SIZE)

func _direction_to_rotation(direction: int) -> float:
	# Convert domain direction to Y rotation (radians)
	match direction:
		Direction.UP: # North
			return 0.0
		Direction.DOWN: # South
			return PI
		Direction.LEFT: # West
			return PI / 2
		Direction.RIGHT: # East
			return -PI / 2
		_:
			return 0.0
