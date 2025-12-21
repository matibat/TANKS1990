class_name GameRoot3D
extends Node3D
## GameRoot3D - Presentation Layer Root Script for DDD Architecture  
## Manages visual representation of game entities by listening to adapter signals
## Pure presentation logic - no game rules, just visual updates
## Now acts as GameCoordinator - integrates GameStateMachine and UI screens

## Debug logger autoload
var DebugLog: Node

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
const GameStateMachine = preload("res://src/domain/game_state_machine.gd")
const GameStateEnum = preload("res://src/domain/value_objects/game_state_enum.gd")
const GameTiming = preload("res://src/domain/constants/game_timing.gd")

## Node references
@onready var adapter: GodotGameAdapter = $GodotGameAdapter
@onready var tanks_container: Node3D = $Tanks
@onready var bullets_container: Node3D = $Bullets
@onready var camera: Camera3D = $Camera3D

## UI Screen references
@onready var main_menu: Control = $UI/MainMenu
@onready var hud: Control = $UI/HUD
@onready var pause_menu: Control = $UI/PauseMenu
@onready var game_over: Control = $UI/GameOver
@onready var stage_complete: Control = $UI/StageComplete

## State Management
var _state_machine: GameStateMachine

## Visual node instances
var tank_nodes: Dictionary = {} # tank_id -> Tank3D instance
var bullet_nodes: Dictionary = {} # bullet_id -> Bullet3D instance
var terrain_nodes: Array = [] # terrain tiles

## Coordinate conversion
# Adapter provides pixel coordinates (0-416 range for 26 tiles * 16 pixels)
# Convert to world units: 1 pixel = 1/16 world units, so 416 pixels = 26 world units
const TILE_SIZE: float = 1.0 / 16.0 # 0.0625 world units per pixel

## Game state tracking
var player_tank_id: String = ""
var terrain_container: Node3D
var current_score: int = 0
var current_lives: int = 3

func _ready() -> void:
	# Get debug logger
	if has_node("/root/DebugLogger"):
		DebugLog = get_node("/root/DebugLogger")
		DebugLog.info("GameRoot3D initializing...")
	
	# Initialize state machine
	_state_machine = GameStateMachine.new()
	_state_machine.state_changed.connect(_on_state_changed)
	
	# Connect UI signals
	_connect_ui_signals()
	
	# Hide all UI screens except main menu
	_hide_all_ui()
	main_menu.show()
	
	# Create terrain container
	terrain_container = Node3D.new()
	terrain_container.name = "Terrain"
	add_child(terrain_container)
	
	# Start in MENU state
	if DebugLog:
		DebugLog.info("GameCoordinator initialized in MENU state")
	
	print("GameRoot3D ready - GameCoordinator initialized")

## Connect UI screen signals
func _connect_ui_signals() -> void:
	# Main Menu signals
	main_menu.start_game_pressed.connect(_on_start_game)
	main_menu.quit_pressed.connect(_on_quit_game)
	
	# Pause Menu signals
	pause_menu.resume_pressed.connect(_on_resume_game)
	pause_menu.quit_to_menu_pressed.connect(_on_quit_to_menu)
	
	# Game Over signals
	game_over.try_again_pressed.connect(_on_try_again)
	game_over.main_menu_pressed.connect(_on_quit_to_menu)
	
	# Stage Complete signals
	stage_complete.next_stage_pressed.connect(_on_next_stage)

## State transition handler
func _on_state_changed(old_state: int, new_state: int) -> void:
	if DebugLog:
		DebugLog.info("State transition", {
			"from": GameStateEnum.state_to_string(old_state),
			"to": GameStateEnum.state_to_string(new_state)
		})
	
	match new_state:
		GameStateEnum.State.MENU:
			_show_main_menu()
		GameStateEnum.State.PLAYING:
			_show_hud()
		GameStateEnum.State.PAUSED:
			_show_pause_menu()
		GameStateEnum.State.GAME_OVER:
			_show_game_over()
		GameStateEnum.State.STAGE_COMPLETE:
			_show_stage_complete()

## UI Screen Management

func _hide_all_ui() -> void:
	main_menu.hide()
	hud.hide()
	pause_menu.hide()
	game_over.hide()
	stage_complete.hide()

func _show_main_menu() -> void:
	_hide_all_ui()
	main_menu.show()

func _show_hud() -> void:
	_hide_all_ui()
	hud.show()
	# Update HUD with current values
	hud.update_score(current_score)
	hud.update_lives(current_lives)

func _show_pause_menu() -> void:
	pause_menu.show_menu()

func _show_game_over() -> void:
	_hide_all_ui()
	game_over.show_game_over(current_score)

func _show_stage_complete() -> void:
	_hide_all_ui()
	# TODO: Track actual stats
	stage_complete.show_stage_complete(20, 120.0, 1000)

## UI Signal Handlers

func _on_start_game() -> void:
	if _state_machine.transition_to(GameStateEnum.State.PLAYING):
		_start_new_game()

func _on_quit_game() -> void:
	get_tree().quit()

func _on_resume_game() -> void:
	_state_machine.transition_to(GameStateEnum.State.PLAYING)
	pause_menu.hide_menu()

func _on_quit_to_menu() -> void:
	if _state_machine.transition_to(GameStateEnum.State.MENU):
		_cleanup_game()

func _on_try_again() -> void:
	if _state_machine.transition_to(GameStateEnum.State.PLAYING):
		_start_new_game()

func _on_next_stage() -> void:
	if _state_machine.transition_to(GameStateEnum.State.PLAYING):
		_start_next_stage()

## Game Management

func _start_new_game() -> void:
	_cleanup_game()
	current_score = 0
	current_lives = 3
	
	# Create and initialize game state
	var game_state = _create_test_game_state()
	
	# Render terrain from game state
	_render_terrain(game_state.stage)
	
	# Initialize adapter
	adapter.initialize(game_state)
	current_lives = game_state.player_lives
	current_score = game_state.score
	
	# Connect adapter signals
	_connect_adapter_signals()
	
	# Set player tank for input
	if player_tank_id != "":
		adapter.set_player_tank(player_tank_id)
		if DebugLog:
			DebugLog.info("Player tank set", {"tank_id": player_tank_id})
	
	print("New game started")

func _start_next_stage() -> void:
	# TODO: Implement next stage logic
	print("Next stage not yet implemented")

func _cleanup_game() -> void:
	_disconnect_adapter_signals()
	if adapter:
		adapter.set_physics_process(false)
		adapter.game_state = null

	# Remove all tanks
	for tank_node in tank_nodes.values():
		tank_node.queue_free()
	tank_nodes.clear()
	
	# Remove all bullets
	for bullet_node in bullet_nodes.values():
		bullet_node.queue_free()
	bullet_nodes.clear()
	
	# Remove terrain
	for terrain_node in terrain_nodes:
		terrain_node.queue_free()
	terrain_nodes.clear()
	
	player_tank_id = ""

## Input handling for pause
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if _state_machine.get_current_state() == GameStateEnum.State.PLAYING:
				_state_machine.transition_to(GameStateEnum.State.PAUSED)
			elif _state_machine.get_current_state() == GameStateEnum.State.PAUSED:
				_state_machine.transition_to(GameStateEnum.State.PLAYING)
				pause_menu.hide_menu()

func _physics_process(_delta: float) -> void:
	if adapter == null:
		return
	var progress = adapter.get_tick_progress()
	for tank_node in tank_nodes.values():
		tank_node.set_tick_progress(progress)
	for bullet_node in bullet_nodes.values():
		bullet_node.set_tick_progress(progress)


## Render terrain from stage state
func _render_terrain(stage: StageState) -> void:
	if DebugLog:
		DebugLog.info("Rendering terrain", {"cell_count": stage.terrain.size()})
	
	# Load terrain tile script
	var TerrainTile3D = load("res://scenes3d/terrain_tile_3d.gd")
	
	# Render all terrain cells
	for terrain_cell in stage.terrain.values():
		var tile = CSGBox3D.new()
		tile.set_script(TerrainTile3D)
		tile.cell_type = terrain_cell.cell_type
		tile.position = _tile_to_world_pos(Vector2(terrain_cell.position.x, terrain_cell.position.y))
		tile.position.y = 0.25 # Half height of the box
		terrain_container.add_child(tile)
		terrain_nodes.append(tile)
	
	# Render base if present
	if stage.base:
		var base_tile = CSGBox3D.new()
		base_tile.set_script(TerrainTile3D)
		base_tile.cell_type = 5 # BASE type
		base_tile.size = Vector3(2.0, 0.6, 2.0) # Larger than normal tiles
		base_tile.position = _tile_to_world_pos(Vector2(stage.base.position.x, stage.base.position.y))
		base_tile.position.y = 0.3
		terrain_container.add_child(base_tile)
		terrain_nodes.append(base_tile)
	
	if DebugLog:
		DebugLog.info("Terrain rendered", {"tile_count": terrain_nodes.size()})

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
	adapter.lives_changed.connect(_on_lives_changed)
	adapter.score_changed.connect(_on_score_changed)

func _disconnect_adapter_signals() -> void:
	if adapter == null:
		return

	var connections = {
		"tank_spawned": _on_tank_spawned,
		"tank_moved": _on_tank_moved,
		"tank_damaged": _on_tank_damaged,
		"tank_destroyed": _on_tank_destroyed,
		"bullet_fired": _on_bullet_fired,
		"bullet_moved": _on_bullet_moved,
		"bullet_destroyed": _on_bullet_destroyed,
		"stage_complete": _on_stage_complete,
		"game_over": _on_game_over,
		"lives_changed": _on_lives_changed,
		"score_changed": _on_score_changed,
	}

	for signal_name in connections.keys():
		if adapter.is_connected(signal_name, connections[signal_name]):
			adapter.disconnect(signal_name, connections[signal_name])

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
	player_tank.set_invulnerable(GameTiming.INVULNERABILITY_FRAMES) # ~3 seconds at logic tick rate
	game_state.add_tank(player_tank)
	player_tank_id = player_tank.id
	
	# Spawn one enemy tank for testing
	if stage.can_spawn_enemy():
		var enemy_tank = SpawningService.spawn_enemy_tank(game_state, TankEntity.Type.ENEMY_BASIC, 0)
		game_state.add_tank(enemy_tank)
	
	return game_state

## Signal Handlers - Tank Events

func _on_tank_spawned(tank_id: String, position: Vector2, tank_type: int, direction: int) -> void:
	var world_pos = _tile_to_world_pos(position)
	var rotation_y = _direction_to_rotation(direction)
	
	if DebugLog:
		DebugLog.spawning("Tank spawned", {
"tank_id": tank_id,
"tile_pos": position,
"world_pos": world_pos,
"tank_type": tank_type,
"direction": direction
})
	
	var tank_node: Tank3D = preload("res://scenes3d/tank_3d.tscn").instantiate() as Tank3D
	tank_node.tank_id = tank_id
	tank_node.tank_type = tank_type
	tank_node.name = "Tank_" + tank_id
	
	# Set reference to domain entity for invulnerability checking
	if adapter and adapter.game_state:
		tank_node.tank_entity = adapter.game_state.get_tank(tank_id)
	
	# Set initial position and rotation
	tank_node.position = world_pos
	tank_node.rotation.y = rotation_y
	
	# Add to scene
	tanks_container.add_child(tank_node)
	tank_nodes[tank_id] = tank_node
	
	# If this is the player tank, tell camera to track it
	if tank_type == TankEntity.Type.PLAYER:
		player_tank_id = tank_id
		camera.set_player_tank(tank_node)
		if DebugLog:
			DebugLog.info("Camera tracking player tank", {"tank_id": tank_id})
	
	print("Tank spawned: ", tank_id, " at ", position, " world: ", world_pos, " type: ", tank_type)

func _on_tank_moved(tank_id: String, old_position: Vector2, new_position: Vector2, direction: int) -> void:
	if tank_nodes.has(tank_id):
		var tank_node = tank_nodes[tank_id]
		var world_pos = _tile_to_world_pos(new_position)
		var rotation_y = _direction_to_rotation(direction)
		
		if DebugLog:
			DebugLog.gameplay("Tank moved", {
"tank_id": tank_id,
"old_tile": old_position,
"new_tile": new_position,
"world_pos": world_pos
})
		
		tank_node.move_to(world_pos, rotation_y)

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
	
	if DebugLog:
		DebugLog.gameplay("Bullet fired", {"bullet_id": bullet_id, "tank_id": tank_id})

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
	if DebugLog:
		DebugLog.gameplay("Stage complete")
	if _state_machine.transition_to(GameStateEnum.State.STAGE_COMPLETE):
		_show_stage_complete()

func _on_game_over(reason: String) -> void:
	print("=== GAME OVER ===")
	print("Reason: ", reason)
	if DebugLog:
		DebugLog.gameplay("Game over", {"reason": reason})
	if _state_machine.transition_to(GameStateEnum.State.GAME_OVER):
		_show_game_over()

func _on_lives_changed(lives: int) -> void:
	current_lives = lives
	if hud:
		hud.update_lives(current_lives)

func _on_score_changed(score: int) -> void:
	current_score = score
	if hud:
		hud.update_score(current_score)

## Coordinate Conversion

func _tile_to_world_pos(tile_pos: Vector2) -> Vector3:
	# Convert from pixel coordinates (from adapter) to world position (3D)
	# Adapter provides pixels (0-416), we convert to world units (0-26)
	# Y pixel coord becomes Z in 3D, X stays X
	# Add TILE_SIZE/2 to center entities in their tiles
	# Y=0.5 to place tanks slightly above ground for visibility
	return Vector3(tile_pos.x * TILE_SIZE + TILE_SIZE * 8.0, 0.5, tile_pos.y * TILE_SIZE + TILE_SIZE * 8.0)

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
