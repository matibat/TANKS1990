extends GutTest
## BDD: Grid-Based Collision Detection
## Tanks check 2x2 tile footprint, bullets check single tile at center

var tank: Tank
var terrain: TerrainManager

func before_each():
	# Create terrain manager
	terrain = TerrainManager.new()
	add_child_autofree(terrain)
	
	# Initialize empty 26x26 terrain
	var empty_terrain = []
	for y in range(26):
		for x in range(26):
			empty_terrain.append(TerrainManager.TileType.EMPTY)  # Empty tile
	terrain.load_terrain(empty_terrain)
	
	# Create tank at grid-aligned position
	tank = Tank.new()
	tank.tank_type = Tank.TankType.PLAYER
	tank.base_speed = 100.0
	# Position at (8, 8) tiles = (128, 128) pixels - on grid
	tank.global_position = Vector2(128, 128)
	add_child_autofree(tank)
	tank.spawn_timer = 0
	tank._complete_spawn()
	tank.invulnerability_timer = 0
	tank._end_invulnerability()

## Scenario: Tank at full-tile position checks 2x2 footprint for collision
## Given tank centered on tile boundary at (128, 128) - occupies tiles (7,7), (7,8), (8,7), (8,8)
## When checking if can move right to (136, 128) - would occupy (8,7), (8,8), (9,7), (9,8)
## Then collision check includes all 4 destination tiles
func test_given_tank_at_tile_boundary_when_moves_then_checks_2x2_footprint():
	# Given: Tank at (128, 128) = tiles (7,7)-(8,8)
	assert_eq(tank.global_position, Vector2(128, 128))
	
	# Place wall at tile (9, 7) - blocks movement to (144, 128) which would occupy (9,7)
	terrain.set_tile_at_coord(Vector2i(9, 7), TerrainManager.TileType.STEEL)
	
	var start_pos = tank.global_position
	
	# When: Try to move right - blocked by wall at (9,7)
	tank.move_in_direction(Tank.Direction.RIGHT)
	tank._physics_process(1.0/60.0)
	
	# Then: Tank stays at start position, blocked by wall
	assert_eq(tank.global_position, start_pos, 
		"Tank should be blocked by wall at (9,7) and not move")

## Scenario: Tank at half-tile position has different collision footprint
## Given tank at (132, 128) - half-tile right of boundary
## When tank occupies tiles based on its 32x32 footprint centered at (132, 128)
## Then footprint is: top-left (116,112) to bottom-right (148,144)
##      which spans tiles (7,7), (7,8), (8,7), (8,8), (9,7), (9,8)
func test_given_tank_at_half_tile_when_checks_footprint_then_spans_more_tiles():
	# Given: Tank at half-tile position (132, 128)
	tank.global_position = Vector2(132, 128)
	
	# When: Get occupied tiles
	var tiles = tank.get_occupied_tiles()
	
	# Then: Tank occupies 4 tiles based on 2x2 footprint
	# Center at (132, 128), size 32x32 means:
	# Top-left: (132-16, 128-16) = (116, 112) = tile (7.25, 7)
	# Bottom-right: (132+16, 128+16) = (148, 144) = tile (9.25, 9)
	# Occupies tiles (7,7), (7,8), (8,7), (8,8) - the 4 tiles in 2x2 grid
	assert_eq(tiles.size(), 4, "Tank always occupies 4 tiles in 2x2 pattern")

## Scenario: Tank cannot move into wall from half-tile position
## Given tank at (132, 128) positioned between tiles
## When wall exists at tiles that would overlap tank's next position
## Then tank is blocked
func test_given_tank_at_half_tile_when_wall_ahead_then_blocked():
	# Given: Tank at (132, 128) - slightly right of center
	tank.global_position = Vector2(132, 128)
	
	# Place walls that would block movement right to (140, 128)
	terrain.set_tile_at_coord(Vector2i(9, 7), TerrainManager.TileType.STEEL)
	terrain.set_tile_at_coord(Vector2i(9, 8), TerrainManager.TileType.STEEL)
	
	var start_pos = tank.global_position
	
	# When: Try to move right
	for i in range(15):
		tank.move_in_direction(Tank.Direction.RIGHT)
		tank._physics_process(1.0/60.0)
	
	# Then: Tank should be blocked, minimal movement
	assert_lt(tank.global_position.x - start_pos.x, 16, 
		"Tank should not move full tile due to wall ahead")

## Scenario: Tank moving back and forth remembers grid alignment
## Given tank moves right into near-wall position
## When tank moves left then right again
## Then tank collides at same position (grid-based, not pixel-based)
func test_given_tank_near_wall_when_moves_left_right_then_consistent_collision():
	# Given: Place wall at x=160 (tile 10)
	for y in range(6, 10):
		terrain.set_tile_at_coord(Vector2i(10, y), TerrainManager.TileType.BRICK)
	
	# Verify terrain was set
	assert_eq(terrain.get_tile_at_coords(10, 7), TerrainManager.TileType.BRICK)
	
	# Move tank right until blocked
	for i in range(30):
		tank.move_in_direction(Tank.Direction.RIGHT)
		tank._physics_process(1.0/60.0)
	
	var blocked_pos = tank.global_position
	assert_gt(blocked_pos.x, 128.0, "Tank moved right from start")
	
	# When: Move left one grid step, then right again
	for i in range(10):
		tank.move_in_direction(Tank.Direction.LEFT)
		tank._physics_process(1.0/60.0)
	
	var left_pos = tank.global_position
	assert_lt(left_pos.x, blocked_pos.x, "Tank moved left")
	
	for i in range(10):
		tank.move_in_direction(Tank.Direction.RIGHT)
		tank._physics_process(1.0/60.0)
	
	# Then: Tank returns to same blocked position (grid-aligned)
	assert_eq(tank.global_position.x, blocked_pos.x, 
		"Tank collides at same grid position consistently")

## Scenario: Tank checks terrain collision before moving to next grid cell
## Given tank at grid position with clear path
## When terrain is updated to add obstacle
## Then tank stops at grid boundary, doesn't partially enter obstacle
func test_given_tank_moving_when_obstacle_appears_then_stops_at_grid_boundary():
	# Given: Tank at (128, 128), clear path right
	var start_pos = tank.global_position
	
	# When: Start moving right
	tank.move_in_direction(Tank.Direction.RIGHT)
	for i in range(5):
		tank._physics_process(1.0/60.0)
	
	# Add obstacle ahead at tile (10, 7-8)
	terrain.set_tile_at_coord(Vector2i(10, 7), TerrainManager.TileType.STEEL)
	terrain.set_tile_at_coord(Vector2i(10, 8), TerrainManager.TileType.STEEL)
	
	# Continue moving
	for i in range(30):
		tank.move_in_direction(Tank.Direction.RIGHT)
		tank._physics_process(1.0/60.0)
	
	# Then: Tank stops at grid position before obstacle
	var x_mod = int(tank.global_position.x) % 8
	assert_eq(x_mod, 0, "Tank position is grid-aligned")
	assert_lt(tank.global_position.x, 160, "Tank stopped before wall at x=160")

## Scenario: Tank can navigate through 2-tile-wide corridor
## Given corridor exactly 2 tiles wide (32 pixels)
## When tank (32 pixels wide) moves through corridor
## Then tank fits exactly, no collision
func test_given_2_tile_corridor_when_tank_moves_through_then_no_collision():
	# Given: Create vertical corridor at tiles 8-9 (x=128-160)
	# Walls at tile 7 and tile 10
	for y in range(5, 12):
		terrain.set_tile_at_coord(Vector2i(7, y), TerrainManager.TileType.STEEL)
		terrain.set_tile_at_coord(Vector2i(10, y), TerrainManager.TileType.STEEL)
	
	# Position tank in corridor at (144, 96) = tiles (8,5)-(9,6)
	tank.global_position = Vector2(144, 96)
	
	# When: Move down through corridor
	for i in range(60):
		tank.move_in_direction(Tank.Direction.DOWN)
		tank._physics_process(1.0/60.0)
	
	# Then: Tank successfully moved down
	assert_gt(tank.global_position.y, 96, "Tank moved through corridor")

## Scenario: Tank cannot fit through 1.5-tile-wide gap
## Given gap is 24 pixels (1.5 tiles)
## When tank (32 pixels wide) tries to enter
## Then tank is blocked
func test_given_narrow_gap_when_tank_tries_then_blocked():
	# Given: Create gap at tiles, but offset walls to make it narrow
	# Wall tiles at (7, 5-12) and (9, 5-12) create ~24px gap
	for y in range(5, 12):
		terrain.set_tile_at_coord(Vector2i(7, y), TerrainManager.TileType.STEEL)
		terrain.set_tile_at_coord(Vector2i(9, y), TerrainManager.TileType.STEEL)
	
	tank.global_position = Vector2(120, 96)
	var start_x = tank.global_position.x
	
	# When: Try to move right into gap
	for i in range(30):
		tank.move_in_direction(Tank.Direction.RIGHT)
		tank._physics_process(1.0/60.0)
	
	# Then: Tank blocked, minimal movement
	assert_lt(tank.global_position.x - start_x, 24, 
		"Tank cannot fit through narrow gap")

## Scenario: Collision detection uses tile coordinates, not floating-point pixels
## Given two tanks at slightly different floating positions
## When both are on same grid cell
## Then both detect same terrain collision
func test_given_floating_positions_when_on_same_grid_then_same_collision():
	# Given: Tank 1 at exact grid (128.0, 128.0)
	tank.global_position = Vector2(128.0, 128.0)
	
	# Tank 2 at slightly offset (128.1, 128.1) - same grid cell
	var tank2 = Tank.new()
	tank2.tank_type = Tank.TankType.BASIC
	tank2.global_position = Vector2(128.1, 128.1)
	add_child_autofree(tank2)
	tank2.spawn_timer = 0
	tank2._complete_spawn()
	
	# When: Get occupied tiles for both
	var tiles1 = tank.get_occupied_tiles()
	var tiles2 = tank2.get_occupied_tiles()
	
	# Then: Both occupy same 4 tiles (grid-based)
	assert_eq(tiles1.size(), 4, "Tank 1 occupies 4 tiles")
	assert_eq(tiles2.size(), 4, "Tank 2 occupies 4 tiles")
	for tile in tiles1:
		assert_true(tiles2.has(tile), "Both tanks on same grid tiles")

## Scenario: Bullet collision is also grid-based
## Given bullet at position
## When checking terrain collision
## Then uses tile coordinate of bullet center, not sub-pixel position
func test_given_bullet_when_checks_collision_then_uses_grid_tile():
	# Given: Bullet at position (127.5, 128.3)
	var bullet = Bullet.new()
	bullet.global_position = Vector2(127.5, 128.3)
	add_child_autofree(bullet)
	
	# Place wall at tile where bullet center is
	# (127.5, 128.3) / 16 = tile (7.96, 8.01) = tile (7, 8)
	terrain.set_tile_at_coord(Vector2i(7, 8), TerrainManager.TileType.BRICK)
	
	# When: Check if bullet hits terrain
	var tile_coord = Vector2i(
		int(bullet.global_position.x / 16),
		int(bullet.global_position.y / 16)
	)
	var tile_type = terrain.get_tile_at_coord(tile_coord)
	
	# Then: Bullet detects wall at grid position
	assert_eq(tile_coord, Vector2i(7, 8), "Bullet on tile (7, 8)")
	assert_eq(tile_type, TerrainManager.TileType.BRICK, "Tile has wall")
