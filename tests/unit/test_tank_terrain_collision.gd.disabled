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
func test_given_tank_blocked_by_brick_wall_when_tries_to_move_then_stays_at_current_position():
	# Given: Wall at tile (9, 8) - blocks movement to (144, 128)
	terrain.set_tile_at_coord(Vector2i(9, 8), TerrainManager.TileType.BRICK)
	var start_pos = tank.global_position
	
	# When: Try to move right toward wall (discrete movement - either moves or doesn't)
	tank.move_in_direction(Tank.Direction.RIGHT)
	tank._physics_process(0.016)
	
	# Then: Tank should stay at current position (blocked by brick wall)
	# Tank at (128, 128) trying to move to (144, 128) would occupy tiles (8,7)-(9,8), hitting wall at (9,8)
	assert_eq(tank.global_position, start_pos, "Tank should stay at current position when blocked by brick wall")

## Scenario: Tank blocked by steel wall
func test_given_tank_blocked_by_steel_wall_when_tries_to_move_then_stays_at_current_position():
	# Given: Steel wall at tile (9, 7) - blocks movement to (144, 128)
	terrain.set_tile_at_coord(Vector2i(9, 7), TerrainManager.TileType.STEEL)
	var start_pos = tank.global_position
	
	# When: Try to move right toward steel wall
	tank.move_in_direction(Tank.Direction.RIGHT)
	tank._physics_process(0.016)
	
	# Then: Tank should stay at current position (blocked by steel wall)
	# Tank at (128, 128) trying to move to (144, 128) would occupy tiles (8,7)-(9,8), hitting wall at (9,7)
	assert_eq(tank.global_position, start_pos, "Tank should stay at current position when blocked by steel wall")

## Scenario: Tank blocked by water tile
func test_given_tank_blocked_by_water_when_tries_to_move_then_stays_at_current_position():
	# Given: Water at tile (7, 9) - blocks movement down to (128, 144)
	terrain.set_tile_at_coord(Vector2i(7, 9), TerrainManager.TileType.WATER)
	var start_pos = tank.global_position
	
	# When: Try to move down toward water
	tank.move_in_direction(Tank.Direction.DOWN)
	tank._physics_process(0.016)
	
	# Then: Tank should stay at current position (blocked by water)
	# Tank at (128, 128) trying to move to (128, 144) would occupy tiles (7,8)-(8,9), hitting water at (7,9)
	assert_eq(tank.global_position, start_pos, "Tank should stay at current position when blocked by water")

## Scenario: Tank moves freely in empty space
func test_given_tank_when_moves_multiple_times_in_empty_space_then_moves_multiple_tiles():
	# Given: No walls in path
	var start_pos = tank.global_position
	
	# When: Move right multiple times (each move is one tile)
	for i in range(3):
		tank.move_in_direction(Tank.Direction.RIGHT)
		tank._physics_process(0.016)
	
	# Then: Tank should have moved exactly 3 tiles (48 pixels)
	var expected_pos = Vector2(start_pos.x + 48, start_pos.y)
	assert_eq(tank.global_position, expected_pos, "Tank should move exactly 3 tiles in empty space")

## Scenario: Tank navigates around obstacle
func test_given_tank_blocked_when_changes_direction_then_can_move_around():
	# Given: Wall to the right at (9,8) - blocks movement to (144, 128) and (144, 144)
	terrain.set_tile_at_coord(Vector2i(9, 8), TerrainManager.TileType.BRICK)
	var start_pos = tank.global_position
	
	# When: Try to move right (should be blocked)
	tank.move_in_direction(Tank.Direction.RIGHT)
	tank._physics_process(0.016)
	assert_eq(tank.global_position, start_pos, "Tank should be blocked by wall")
	
	# Then: Change direction and move down to go around
	tank.move_in_direction(Tank.Direction.DOWN)
	tank._physics_process(0.016)
	var after_down = tank.global_position
	assert_eq(after_down, Vector2(128, 144), "Tank should move down one tile")
	
	# And: Try to move right again (still blocked by same wall)
	tank.move_in_direction(Tank.Direction.RIGHT)
	tank._physics_process(0.016)
	assert_eq(tank.global_position, after_down, "Tank should still be blocked by wall at (9,8)")

## Scenario: Tank encounters 2x2 wall cluster
func test_given_tank_blocked_by_wall_cluster_when_tries_to_move_then_stays_at_current_position():
	# Given: 2x2 wall cluster at tiles (9,7) (9,8) (10,7) (10,8) - blocks movement to (144, 128)
	terrain.set_tile_at_coord(Vector2i(9, 7), TerrainManager.TileType.BRICK)
	terrain.set_tile_at_coord(Vector2i(9, 8), TerrainManager.TileType.BRICK)
	terrain.set_tile_at_coord(Vector2i(10, 7), TerrainManager.TileType.BRICK)
	terrain.set_tile_at_coord(Vector2i(10, 8), TerrainManager.TileType.BRICK)
	var start_pos = tank.global_position
	
	# When: Try to move right into wall cluster
	tank.move_in_direction(Tank.Direction.RIGHT)
	tank._physics_process(0.016)
	
	# Then: Tank should stay at current position (blocked by wall cluster)
	assert_eq(tank.global_position, start_pos, "Tank should be blocked by wall cluster")

## Scenario: Tank stops immediately when wall placed in front
func test_given_tank_when_wall_placed_ahead_then_next_move_attempt_fails():
	# Given: Tank at starting position
	var start_pos = tank.global_position
	
	# When: Place wall in path at tile (9, 8) - blocks movement to (144, 128)
	terrain.set_tile_at_coord(Vector2i(9, 8), TerrainManager.TileType.STEEL)
	
	# And: Try to move right
	tank.move_in_direction(Tank.Direction.RIGHT)
	tank._physics_process(0.016)
	
	# Then: Tank should stay at current position (blocked by newly placed wall)
	assert_eq(tank.global_position, start_pos, "Tank should stay at current position when wall appears in path")
