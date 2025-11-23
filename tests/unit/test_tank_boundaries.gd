extends GutTest
## BDD tests for tank and terrain boundary enforcement

var tank: Tank
var terrain: TerrainManager
const MAP_WIDTH: int = 416  # 26 tiles * 16px
const MAP_HEIGHT: int = 832  # 52 tiles * 16px
const MAP_WIDTH_TILES: int = 26
const MAP_HEIGHT_TILES: int = 26

func before_each():
	tank = Tank.new()
	tank.tank_type = Tank.TankType.PLAYER
	tank.base_speed = 100.0
	add_child_autofree(tank)
	tank._ready()
	tank.spawn_timer = 0.0  # Complete spawn immediately
	tank.current_state = Tank.State.IDLE
	
	terrain = TerrainManager.new()
	terrain.tile_set = TileSet.new()  # Required for TileMapLayer operations
	add_child_autofree(terrain)

# ============================================================================
# FEATURE: Map Boundary Enforcement
# As a game designer
# I want terrain boundaries to be unbreakable steel tiles
# So that tanks and bullets cannot escape the play area
# ============================================================================

# SCENARIO: Terrain manager enforces steel boundaries
func test_given_terrain_loaded_when_enforce_boundaries_called_then_edges_are_steel():
	# Given: Empty terrain
	terrain.clear_terrain()
	
	# When: Boundaries are enforced
	terrain.enforce_boundaries()
	
	# Then: All edge tiles are steel
	assert_true(terrain.has_valid_boundaries(), "All boundary tiles should be steel")
	
	# Verify specific corners
	assert_eq(terrain.get_tile_at_coords(0, 0), TerrainManager.TileType.STEEL, "Top-left corner should be steel")
	assert_eq(terrain.get_tile_at_coords(MAP_WIDTH_TILES - 1, 0), TerrainManager.TileType.STEEL, "Top-right corner should be steel")
	assert_eq(terrain.get_tile_at_coords(0, MAP_HEIGHT_TILES - 1), TerrainManager.TileType.STEEL, "Bottom-left corner should be steel")
	assert_eq(terrain.get_tile_at_coords(MAP_WIDTH_TILES - 1, MAP_HEIGHT_TILES - 1), TerrainManager.TileType.STEEL, "Bottom-right corner should be steel")

# SCENARIO: Loading terrain from array enforces boundaries
func test_given_terrain_array_when_loaded_then_boundaries_automatically_enforced():
	# Given: Terrain data with non-steel boundaries
	var terrain_data = []
	for y in range(MAP_HEIGHT_TILES):
		var row = []
		for x in range(MAP_WIDTH_TILES):
			row.append(TerrainManager.TileType.EMPTY)
		terrain_data.append(row)
	
	# When: Terrain is loaded
	terrain.load_terrain_from_array(terrain_data)
	
	# Then: Boundaries are automatically steel
	assert_true(terrain.has_valid_boundaries(), "Boundaries should be enforced after loading")

# SCENARIO: Steel boundary tiles cannot be destroyed by normal bullets
func test_given_steel_boundary_when_damaged_without_power_then_remains_intact():
	# Given: Terrain with enforced boundaries
	terrain.enforce_boundaries()
	var boundary_pos = terrain.map_to_local(Vector2i(0, 5))  # Left edge, middle
	
	# When: Boundary is damaged without steel-destroying power
	var destroyed = terrain.damage_tile(boundary_pos, false)
	
	# Then: Tile is not destroyed
	assert_false(destroyed, "Boundary steel should not be destroyed")
	assert_eq(terrain.get_tile_at_coords(0, 5), TerrainManager.TileType.STEEL, "Boundary tile should remain steel")

# SCENARIO: Interior tiles can still be placed and destroyed
func test_given_enforced_boundaries_when_interior_tiles_modified_then_boundaries_unaffected():
	# Given: Terrain with enforced boundaries
	terrain.enforce_boundaries()
	
	# When: Interior brick tile is placed and destroyed
	terrain.set_tile_at_coords(10, 10, TerrainManager.TileType.BRICK)
	var brick_pos = terrain.map_to_local(Vector2i(10, 10))
	terrain.damage_tile(brick_pos, false)
	
	# Then: Interior tile destroyed but boundaries remain
	assert_eq(terrain.get_tile_at_coords(10, 10), TerrainManager.TileType.EMPTY, "Interior brick should be destroyed")
	assert_true(terrain.has_valid_boundaries(), "Boundaries should remain intact")

# ============================================================================
# FEATURE: Tank Position Clamping
# As a game designer
# I want tanks to stay within the map boundaries
# So that gameplay remains within the visible play area
# ============================================================================

# SCENARIO: Tank at left edge cannot move further left
func test_given_tank_at_left_edge_when_moves_left_then_position_clamped():
	# Given: Tank positioned at left edge
	tank.global_position = Vector2(8, 100)  # Half tile width from edge (16px / 2)
	
	# When: Tank attempts to move left
	tank.move_in_direction(Tank.Direction.LEFT)
	for i in range(10):
		tank._physics_process(0.016)
		get_tree().physics_frame.emit()
	
	# Then: Tank position is clamped at or above 0
	assert_gte(tank.global_position.x, 0.0, "Tank X should not go negative")

# SCENARIO: Tank at right edge cannot move further right
func test_given_tank_at_right_edge_when_moves_right_then_position_clamped():
	# Given: Tank positioned at right edge
	tank.global_position = Vector2(MAP_WIDTH - 8, 100)
	
	# When: Tank attempts to move right
	tank.move_in_direction(Tank.Direction.RIGHT)
	for i in range(10):
		tank._physics_process(0.016)
		get_tree().physics_frame.emit()
	
	# Then: Tank position is clamped at or below MAP_WIDTH
	assert_lte(tank.global_position.x, MAP_WIDTH, "Tank X should not exceed map width")

# SCENARIO: Tank at top edge cannot move further up
func test_given_tank_at_top_edge_when_moves_up_then_position_clamped():
	# Given: Tank positioned at top edge
	tank.global_position = Vector2(200, 8)
	
	# When: Tank attempts to move up
	tank.move_in_direction(Tank.Direction.UP)
	for i in range(10):
		tank._physics_process(0.016)
		get_tree().physics_frame.emit()
	
	# Then: Tank position is clamped at or above 0
	assert_gte(tank.global_position.y, 0.0, "Tank Y should not go negative")

# SCENARIO: Tank at bottom edge cannot move further down
func test_given_tank_at_bottom_edge_when_moves_down_then_position_clamped():
	# Given: Tank positioned at bottom edge
	tank.global_position = Vector2(200, MAP_HEIGHT - 8)
	
	# When: Tank attempts to move down
	tank.move_in_direction(Tank.Direction.DOWN)
	for i in range(10):
		tank._physics_process(0.016)
		get_tree().physics_frame.emit()
	
	# Then: Tank position is clamped at or below MAP_HEIGHT
	assert_lte(tank.global_position.y, MAP_HEIGHT, "Tank Y should not exceed map height")

# SCENARIO: Tank within bounds can move freely
func test_given_tank_in_center_when_moves_any_direction_then_position_valid():
	# Given: Tank positioned in center of map
	tank.global_position = Vector2(MAP_WIDTH / 2, MAP_HEIGHT / 2)
	var start_pos = tank.global_position
	
	# When: Tank moves in any direction
	tank.move_in_direction(Tank.Direction.UP)
	for i in range(5):
		tank._physics_process(0.016)
	
	# Then: Tank has moved and is still within bounds
	assert_ne(tank.global_position, start_pos, "Tank should have moved")
	assert_gte(tank.global_position.x, 0.0, "Tank X should be >= 0")
	assert_lte(tank.global_position.x, MAP_WIDTH, "Tank X should be <= MAP_WIDTH")
	assert_gte(tank.global_position.y, 0.0, "Tank Y should be >= 0")
	assert_lte(tank.global_position.y, MAP_HEIGHT, "Tank Y should be <= MAP_HEIGHT")
