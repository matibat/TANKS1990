extends GutTest
## BDD: Tank-Terrain Collision in Discrete Grid System
## Verifies tanks stop at walls and cannot pass through solid tiles

var tank: Tank
var terrain: TerrainManager
var game_root: Node2D

func before_each():
	# Create a game scene hierarchy
	game_root = Node2D.new()
	add_child_autofree(game_root)
	
	# Create terrain manager as child of game root
	terrain = TerrainManager.new()
	game_root.add_child(terrain)
	
	# Initialize empty 26x26 terrain
	var empty_terrain = []
	for y in range(26):
		for x in range(26):
			empty_terrain.append(TerrainManager.TileType.EMPTY)
	terrain.load_terrain(empty_terrain)
	
	# Create tank as child of game root (sibling of terrain)
	tank = Tank.new()
	tank.tank_type = Tank.TankType.PLAYER
	tank.base_speed = 100.0
	tank.global_position = Vector2(128, 128)
	game_root.add_child(tank)
	
	# Complete spawn
	tank.spawn_timer = 0
	tank._complete_spawn()
	tank.invulnerability_timer = 0
	tank._end_invulnerability()

## Scenario: Tank finds terrain manager in scene
func test_given_tank_in_scene_with_terrain_when_checks_collision_then_finds_terrain():
	# When: Get terrain manager
	var found_terrain = tank._get_terrain_manager()
	
	# Then: Should find the terrain
	assert_not_null(found_terrain, "Tank should find terrain manager")
	assert_same(found_terrain, terrain, "Should find the correct terrain instance")

## Scenario: Tank blocked by single brick wall
func test_given_tank_when_moves_toward_brick_wall_then_stops_before_collision():
	# Given: Wall at tile (9, 8)
	terrain.set_tile_at_coord(Vector2i(9, 8), TerrainManager.TileType.BRICK)
	
	# When: Move right toward wall (simulate multiple frames)
	for i in range(20):
		tank.move_in_direction(Tank.Direction.RIGHT)
		tank._physics_process(0.016)  # ~60fps
	
	# Then: Tank should stop before hitting wall
	# Tank at (128, 128) can reach (136, 128) but NOT (144, 128) due to wall
	# At (144, 128) it would occupy tiles (8,7)-(9,8), hitting wall at (9,8)
	assert_eq(tank.global_position, Vector2(136, 128), "Tank should stop at (136, 128) before brick wall")

## Scenario: Tank blocked by steel wall
func test_given_tank_when_moves_toward_steel_wall_then_stops_before_collision():
	# Given: Steel wall at tile (9, 7) - one tile to the right of tank
	terrain.set_tile_at_coord(Vector2i(9, 7), TerrainManager.TileType.STEEL)
	
	# When: Move right toward wall
	for i in range(20):
		tank.move_in_direction(Tank.Direction.RIGHT)
		tank._physics_process(0.016)
	
	# Then: Tank should be blocked
	# Tank at (128, 128) occupies (7,7)-(8,8)
	# Can move to (136, 128) occupying (7,7)-(8,8) - still clear
	# But at (144, 128) would occupy (8,7)-(9,8), hitting wall at (9,7)
	assert_eq(tank.global_position, Vector2(136, 128), "Tank should stop one cell before steel wall")

## Scenario: Tank blocked by water tile
func test_given_tank_when_moves_toward_water_then_stops_before_collision():
	# Given: Water at tile (7, 9)
	terrain.set_tile_at_coord(Vector2i(7, 9), TerrainManager.TileType.WATER)
	
	# When: Move down toward water
	for i in range(20):
		tank.move_in_direction(Tank.Direction.DOWN)
		tank._physics_process(0.016)
	
	# Then: Tank should stop before water
	# Tank at (128, 128) can reach (128, 136), at (128, 144) would occupy (7,8)-(8,9) hitting water at (7,9)
	assert_lt(tank.global_position.y, 144.0, "Tank should be blocked by water")

## Scenario: Tank moves freely in empty space
func test_given_tank_when_moves_in_empty_space_then_moves_freely():
	# Given: No walls in path
	
	# When: Move right (auto-chains through multiple cells)
	tank.move_in_direction(Tank.Direction.RIGHT)
	for i in range(30):
		tank._physics_process(0.016)
	
	# Then: Tank should move multiple cells
	assert_gt(tank.global_position.x, 160.0, "Tank should move freely in empty space")

## Scenario: Tank navigates around obstacle
func test_given_tank_blocked_when_changes_direction_then_can_move_around():
	# Given: Wall to the right at (9,8)
	terrain.set_tile_at_coord(Vector2i(9, 8), TerrainManager.TileType.BRICK)
	
	# When: Move right until blocked
	tank.move_in_direction(Tank.Direction.RIGHT)
	for i in range(20):
		tank._physics_process(0.016)
	
	var blocked_x = tank.global_position.x
	assert_eq(blocked_x, 136.0, "Tank should stop at x=136 before wall")
	
	# Then: Move down TWO cells to clear the wall (wall is at y=8)
	# Need to reach y >= 160 to have footprint below the wall
	tank.move_in_direction(Tank.Direction.DOWN)
	for i in range(30):
		tank._physics_process(0.016)
	
	# Then: Should have moved down significantly
	assert_gte(tank.global_position.y, 144.0, "Tank should move down to clear obstacle")
	
	# And: Move right again past obstacle
	tank.move_in_direction(Tank.Direction.RIGHT)
	for i in range(30):
		tank._physics_process(0.016)
	
	# Then: Should be past the original block point
	assert_gt(tank.global_position.x, 144.0, "Tank should move past obstacle after navigating around")

## Scenario: Tank encounters 2x2 wall cluster
func test_given_tank_when_encounters_wall_cluster_then_stops_before_cluster():
	# Given: 2x2 wall cluster at tiles (9,7) (9,8) (10,7) (10,8)
	terrain.set_tile_at_coord(Vector2i(9, 7), TerrainManager.TileType.BRICK)
	terrain.set_tile_at_coord(Vector2i(9, 8), TerrainManager.TileType.BRICK)
	terrain.set_tile_at_coord(Vector2i(10, 7), TerrainManager.TileType.BRICK)
	terrain.set_tile_at_coord(Vector2i(10, 8), TerrainManager.TileType.BRICK)
	
	# When: Move right
	tank.move_in_direction(Tank.Direction.RIGHT)
	for i in range(20):
		tank._physics_process(0.016)
	
	# Then: Tank should be blocked by cluster
	assert_eq(tank.global_position, Vector2(136, 128), "Tank should be blocked by wall cluster")

## Scenario: Tank stops immediately when wall placed in front
func test_given_tank_moving_when_wall_placed_ahead_then_stops_at_next_grid():
	# Given: Tank moving right
	tank.move_in_direction(Tank.Direction.RIGHT)
	for i in range(5):
		tank._physics_process(0.016)
	
	# When: Place wall in path at tile (10, 8)
	terrain.set_tile_at_coord(Vector2i(10, 8), TerrainManager.TileType.STEEL)
	
	# And: Continue moving
	for i in range(20):
		tank._physics_process(0.016)
	
	# Then: Tank should stop before the wall
	# Wall at (10,8) blocks position (160, 128) and beyond
	assert_lt(tank.global_position.x, 160.0, "Tank should stop when wall appears in path")
