extends GutTest
## BDD tests for TerrainManager and collision detection

var terrain: TerrainManager
var destroyed_signal_received: bool = false
var destroyed_tile_pos: Vector2i
const TILE_SIZE = 16

func before_each():
	terrain = TerrainManager.new()
	terrain.tile_set = TileSet.new()
	add_child_autofree(terrain)
	destroyed_signal_received = false
	terrain.tile_destroyed.connect(_on_tile_destroyed)

## Feature: Terrain Tile Management

func test_given_empty_terrain_when_set_brick_then_tile_created():
	# Given: Empty terrain
	var tile_pos = Vector2(100, 100)
	
	# When: Set brick tile
	terrain.set_tile_at_position(tile_pos, TerrainManager.TileType.BRICK)
	
	# Then: Tile exists
	var tile_type = terrain.get_tile_at_position(tile_pos)
	assert_eq(tile_type, TerrainManager.TileType.BRICK, "Brick tile should exist")

func test_given_empty_terrain_when_set_steel_then_tile_created():
	# Given: Empty terrain
	var tile_pos = Vector2(200, 200)
	
	# When: Set steel tile
	terrain.set_tile_at_position(tile_pos, TerrainManager.TileType.STEEL)
	
	# Then: Tile exists
	var tile_type = terrain.get_tile_at_position(tile_pos)
	assert_eq(tile_type, TerrainManager.TileType.STEEL, "Steel tile should exist")

func test_given_brick_tile_when_checked_then_is_solid():
	# Given: Brick tile
	var tile_pos = Vector2(100, 100)
	terrain.set_tile_at_position(tile_pos, TerrainManager.TileType.BRICK)
	
	# When/Then: Check if solid
	assert_true(terrain.is_tile_solid(tile_pos), "Brick should be solid")

func test_given_water_tile_when_checked_then_is_solid():
	# Given: Water tile
	var tile_pos = Vector2(100, 100)
	terrain.set_tile_at_position(tile_pos, TerrainManager.TileType.WATER)
	
	# When/Then: Check if solid
	assert_true(terrain.is_tile_solid(tile_pos), "Water should be solid")

func test_given_forest_tile_when_checked_then_not_solid():
	# Given: Forest tile
	var tile_pos = Vector2(100, 100)
	terrain.set_tile_at_position(tile_pos, TerrainManager.TileType.FOREST)
	
	# When/Then: Check if solid
	assert_false(terrain.is_tile_solid(tile_pos), "Forest should not be solid")

## Feature: Destructible Terrain

func _on_tile_destroyed(tile_pos: Vector2i, tile_type):
	destroyed_signal_received = true
	destroyed_tile_pos = tile_pos

func test_given_brick_when_damaged_then_destroys():
	# Given: Brick tile
	var tile_pos = Vector2(100, 100)
	terrain.set_tile_at_position(tile_pos, TerrainManager.TileType.BRICK)
	EventBus.start_recording()
	
	# When: Damage tile
	var result = terrain.damage_tile(tile_pos, false)
	
	# Then: Tile destroyed
	assert_true(result, "Damage should succeed")
	assert_true(destroyed_signal_received, "Destroyed signal emitted")
	assert_eq(terrain.get_tile_at_position(tile_pos), TerrainManager.TileType.EMPTY, "Tile should be empty")
	
	# And: Collision event emitted
	var replay = EventBus.stop_recording()
	var collision_events = []
	for event in replay.events:
		if event.get("type") == "Collision":
			collision_events.append(event)
	
	assert_gt(collision_events.size(), 0, "Collision event emitted")

func test_given_steel_when_damaged_normally_then_survives():
	# Given: Steel tile
	var tile_pos = Vector2(100, 100)
	terrain.set_tile_at_position(tile_pos, TerrainManager.TileType.STEEL)
	
	# When: Damage without steel-destroy capability
	var result = terrain.damage_tile(tile_pos, false)
	
	# Then: Tile survives
	assert_false(result, "Damage should fail")
	assert_eq(terrain.get_tile_at_position(tile_pos), TerrainManager.TileType.STEEL, "Steel should remain")

func test_given_steel_when_damaged_by_super_bullet_then_destroys():
	# Given: Steel tile
	var tile_pos = Vector2(100, 100)
	terrain.set_tile_at_position(tile_pos, TerrainManager.TileType.STEEL)
	
	# When: Damage with steel-destroy capability
	var result = terrain.damage_tile(tile_pos, true)
	
	# Then: Tile destroyed
	assert_true(result, "Damage should succeed")
	assert_true(destroyed_signal_received, "Destroyed signal emitted")
	assert_eq(terrain.get_tile_at_position(tile_pos), TerrainManager.TileType.EMPTY, "Steel should be destroyed")

func test_given_water_when_damaged_then_survives():
	# Given: Water tile (indestructible)
	var tile_pos = Vector2(100, 100)
	terrain.set_tile_at_position(tile_pos, TerrainManager.TileType.WATER)
	
	# When: Damage tile
	var result = terrain.damage_tile(tile_pos, false)
	
	# Then: Tile survives
	assert_false(result, "Water should not be destroyed")
	assert_eq(terrain.get_tile_at_position(tile_pos), TerrainManager.TileType.WATER, "Water should remain")

## Feature: Terrain Loading


	terrain.tile_set = TileSet.new()

func test_given_terrain_array_when_loaded_then_tiles_created():
	# Given: Terrain data array (3x3 for testing)
	var terrain_data = [
		[TerrainManager.TileType.BRICK, TerrainManager.TileType.EMPTY, TerrainManager.TileType.STEEL],
		[TerrainManager.TileType.EMPTY, TerrainManager.TileType.WATER, TerrainManager.TileType.EMPTY],
		[TerrainManager.TileType.FOREST, TerrainManager.TileType.EMPTY, TerrainManager.TileType.ICE]
	]
	
	# When: Load terrain
	terrain.load_terrain_from_array(terrain_data)
	
	# Then: Tiles match data
	assert_eq(terrain.get_tile_at_coords(0, 0), TerrainManager.TileType.BRICK, "Brick at (0,0)")
	assert_eq(terrain.get_tile_at_coords(2, 0), TerrainManager.TileType.STEEL, "Steel at (2,0)")
	assert_eq(terrain.get_tile_at_coords(1, 1), TerrainManager.TileType.WATER, "Water at (1,1)")
	assert_eq(terrain.get_tile_at_coords(0, 2), TerrainManager.TileType.FOREST, "Forest at (0,2)")
	assert_eq(terrain.get_tile_at_coords(2, 2), TerrainManager.TileType.ICE, "Ice at (2,2)")

func test_given_terrain_when_exported_then_array_matches():
	# Given: Terrain with some tiles (3x3)
	terrain.set_tile_at_coords(0, 0, TerrainManager.TileType.BRICK)
	terrain.set_tile_at_coords(1, 1, TerrainManager.TileType.STEEL)
	terrain.set_tile_at_coords(2, 2, TerrainManager.TileType.WATER)
	
	# When: Export terrain
	var exported = terrain.export_terrain_to_array(3, 3)
	
	# Then: Array matches tiles
	assert_eq(exported[0][0], TerrainManager.TileType.BRICK, "Brick exported")
	assert_eq(exported[1][1], TerrainManager.TileType.STEEL, "Steel exported")
	assert_eq(exported[2][2], TerrainManager.TileType.WATER, "Water exported")
	assert_eq(exported[0][1], TerrainManager.TileType.EMPTY, "Empty exported")

func test_given_terrain_when_cleared_then_all_empty():
	# Given: Terrain with tiles
	terrain.set_tile_at_coords(0, 0, TerrainManager.TileType.BRICK)
	terrain.set_tile_at_coords(1, 1, TerrainManager.TileType.STEEL)
	
	# When: Clear terrain
	terrain.clear_terrain()
	
	# Then: All tiles empty
	assert_eq(terrain.get_tile_at_coords(0, 0), TerrainManager.TileType.EMPTY, "Tile cleared")
	assert_eq(terrain.get_tile_at_coords(1, 1), TerrainManager.TileType.EMPTY, "Tile cleared")

## Feature: Tile Type Properties


	terrain.tile_set = TileSet.new()

func test_given_brick_when_checked_then_is_destructible():
	# Given: Brick tile
	var tile_pos = Vector2(100, 100)
	terrain.set_tile_at_position(tile_pos, TerrainManager.TileType.BRICK)
	
	# When/Then: Check destructibility
	assert_true(terrain.is_tile_destructible(tile_pos), "Brick is destructible")

func test_given_steel_when_checked_then_not_destructible():
	# Given: Steel tile
	var tile_pos = Vector2(100, 100)
	terrain.set_tile_at_position(tile_pos, TerrainManager.TileType.STEEL)
	
	# When/Then: Check destructibility
	assert_false(terrain.is_tile_destructible(tile_pos), "Steel not normally destructible")

func test_given_ice_when_checked_then_not_solid():
	# Given: Ice tile
	var tile_pos = Vector2(100, 100)
	terrain.set_tile_at_position(tile_pos, TerrainManager.TileType.ICE)
	
	# When/Then: Check solidity
	assert_false(terrain.is_tile_solid(tile_pos), "Ice is not solid (slippery)")

## Feature: Base Protection Terrain Setup

func test_given_terrain_loaded_with_base_protection_when_checked_then_bricks_around_base():
	# Given: Terrain loaded with base protection (simulating main.gd setup)
	var terrain_data = []
	for i in range(26 * 26):
		terrain_data.append(TerrainManager.TileType.EMPTY)
	
	# Add boundary walls (steel)
	for x in range(26):
		terrain_data[x] = TerrainManager.TileType.STEEL  # Top
		terrain_data[25 * 26 + x] = TerrainManager.TileType.STEEL  # Bottom
	for y in range(26):
		terrain_data[y * 26] = TerrainManager.TileType.STEEL  # Left
		terrain_data[y * 26 + 25] = TerrainManager.TileType.STEEL  # Right
	
	# Clear base position (13, 25)
	terrain_data[25 * 26 + 13] = TerrainManager.TileType.EMPTY
	
	# Add center obstacle
	for y in range(12, 16):
		for x in range(12, 16):
			terrain_data[y * 26 + x] = TerrainManager.TileType.BRICK
	
	# Add base protection around (13, 25)
	var base_x = 13
	var base_y = 25
	# Top row
	for x in range(base_x - 1, base_x + 2):
		terrain_data[(base_y - 1) * 26 + x] = TerrainManager.TileType.BRICK
	# Left and right sides
	terrain_data[base_y * 26 + (base_x - 1)] = TerrainManager.TileType.BRICK
	terrain_data[base_y * 26 + (base_x + 1)] = TerrainManager.TileType.BRICK
	
	# When: Load terrain
	terrain.load_terrain(terrain_data)
	
	# Then: Protective bricks exist around base position (13, 25)
	assert_eq(terrain.get_tile_at_coords(12, 24), TerrainManager.TileType.BRICK, "Brick at (12,24)")
	assert_eq(terrain.get_tile_at_coords(13, 24), TerrainManager.TileType.BRICK, "Brick at (13,24)")
	assert_eq(terrain.get_tile_at_coords(14, 24), TerrainManager.TileType.BRICK, "Brick at (14,24)")
	assert_eq(terrain.get_tile_at_coords(12, 25), TerrainManager.TileType.BRICK, "Brick at (12,25)")
	assert_eq(terrain.get_tile_at_coords(14, 25), TerrainManager.TileType.BRICK, "Brick at (14,25)")
	
	# And: Base position itself should be empty (not obstructed)
	assert_eq(terrain.get_tile_at_coords(13, 25), TerrainManager.TileType.EMPTY, "Base position (13,25) should be empty")
