extends GutTest
## Integration test for 3D gameplay scene
## Verifies that the 3D scene loads and initializes correctly

const GameRoot3D = preload("res://scenes3d/game_root_3d.gd")
const GameState = preload("res://src/domain/aggregates/game_state.gd")

var game_root: GameRoot3D
var scene: PackedScene

func before_all():
	scene = load("res://scenes3d/game_3d_ddd.tscn")

func before_each():
	game_root = scene.instantiate()
	add_child_autofree(game_root)
	# Wait for _ready() to complete
	await get_tree().process_frame

func after_each():
	if game_root and is_instance_valid(game_root):
		game_root.queue_free()
	game_root = null

## Test: Scene loads without errors
func test_scene_loads_successfully():
	assert_not_null(game_root, "GameRoot3D should be instantiated")
	assert_true(is_instance_valid(game_root), "GameRoot3D should be valid")

## Test: Required nodes exist
func test_required_nodes_exist():
	assert_not_null(game_root.get_node("GodotGameAdapter"), "GodotGameAdapter should exist")
	assert_not_null(game_root.get_node("Camera3D"), "Camera3D should exist")
	assert_not_null(game_root.get_node("Tanks"), "Tanks container should exist")
	assert_not_null(game_root.get_node("Bullets"), "Bullets container should exist")

## Test: Camera configuration
func test_camera_is_configured_correctly():
	var camera = game_root.get_node("Camera3D") as Camera3D
	assert_eq(camera.projection, Camera3D.PROJECTION_ORTHOGONAL, "Camera should be orthogonal")
	assert_true(camera.current, "Camera should be active")
	assert_gt(camera.size, 20.0, "Camera size should cover arena")
	# Camera should be positioned above the arena
	assert_gt(camera.position.y, 20.0, "Camera should be elevated above ground")

## Test: Terrain renders
func test_terrain_renders():
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Check terrain container was created
	var terrain_container = null
	for child in game_root.get_children():
		if child.name == "Terrain":
			terrain_container = child
			break
	
	assert_not_null(terrain_container, "Terrain container should be created")
	assert_gt(terrain_container.get_child_count(), 0, "Terrain should have tiles")
	
	# Should have 100 wall tiles + 1 base = 101 total
	assert_eq(game_root.terrain_nodes.size(), 101, "Should render 101 terrain tiles")

## Test: Player tank spawns
func test_player_tank_spawns():
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Check that player tank was spawned
	assert_false(game_root.player_tank_id.is_empty(), "Player tank ID should be set")
	
	# Check tank node exists in scene
	var tanks_container = game_root.get_node("Tanks")
	assert_gt(tanks_container.get_child_count(), 0, "At least player tank should be spawned")
	
	# Verify tank is in tank_nodes dictionary
	assert_true(game_root.tank_nodes.has(game_root.player_tank_id), "Player tank should be in tank_nodes")
	
	# Get the tank node and verify position
	var player_tank = game_root.tank_nodes[game_root.player_tank_id]
	assert_not_null(player_tank, "Player tank node should exist")
	
	# Tank should be above ground (y > 0)
	assert_gt(player_tank.position.y, 0.0, "Tank should be above ground level")

## Test: Enemy tank spawns
func test_enemy_tank_spawns():
	await get_tree().process_frame
	await get_tree().process_frame
	
	var tanks_container = game_root.get_node("Tanks")
	# Should have player + at least 1 enemy
	assert_gte(tanks_container.get_child_count(), 2, "Should have player and enemy tanks")
	assert_gte(game_root.tank_nodes.size(), 2, "Tank nodes dictionary should have >=2 entries")

## Test: Coordinate conversion
func test_coordinate_conversion_centers_entities():
	# Adapter provides pixel coordinates (tile * 16)
	# e.g., tile 12 = pixel 192, tile 20 = pixel 320
	# With TILE_SIZE = 1/16, pixel 192 should become world ~12.5, pixel 320 -> ~20.5
	var pixel_pos = Vector2(192, 320) # Tile (12, 20) in pixels
	var world_pos = game_root._tile_to_world_pos(pixel_pos)
	
	# With TILE_SIZE=0.0625 and centering offset of 8*TILE_SIZE=0.5:
	# 192 * 0.0625 + 0.5 = 12 + 0.5 = 12.5
	# 320 * 0.0625 + 0.5 = 20 + 0.5 = 20.5
	assert_almost_eq(world_pos.x, 12.5, 0.1, "X coordinate should convert pixels to world")
	assert_almost_eq(world_pos.z, 20.5, 0.1, "Z coordinate should convert pixels to world")
	assert_eq(world_pos.y, 0.5, "Y coordinate should be above ground")

## Test: Adapter is initialized
func test_adapter_initializes():
	await get_tree().process_frame
	
	var adapter = game_root.get_node("GodotGameAdapter")
	assert_not_null(adapter.game_state, "Adapter should have game state")
	assert_true(adapter.is_physics_processing(), "Adapter should be processing physics")

## Test: Debug logger integration
func test_debug_logger_available():
	# DebugLog may or may not be available depending on configuration
	# This just verifies the code handles both cases gracefully
	var has_debug_log = game_root.has_node("/root/DebugLogger")
	if has_debug_log:
		var logger = game_root.get_node("/root/DebugLogger")
		assert_not_null(logger, "DebugLogger should be accessible if registered")

## Test: Tank nodes have correct types
func test_tank_nodes_have_correct_properties():
	await get_tree().process_frame
	await get_tree().process_frame
	
	for tank_id in game_root.tank_nodes.keys():
		var tank_node = game_root.tank_nodes[tank_id]
		assert_not_null(tank_node, "Tank node should exist")
		assert_eq(tank_node.tank_id, tank_id, "Tank node ID should match dictionary key")
		assert_true(tank_node.has_node("Body"), "Tank should have Body mesh")
		assert_true(tank_node.has_node("Turret"), "Tank should have Turret mesh")
