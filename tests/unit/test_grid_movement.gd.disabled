extends GutTest
## BDD: Discrete Tile-Based Tank Movement
## Tanks move instantly from tile center to adjacent tile center on a 26x26 tile grid

var tank: Tank

func before_each():
	tank = Tank.new()
	tank.tank_type = Tank.TankType.PLAYER
	tank.base_speed = 100.0
	tank.tank_id = 1
	# Start at tile center: (8*16, 8*16) = (128, 128)
	tank.global_position = Vector2(128, 128)
	add_child_autofree(tank)
	tank.spawn_timer = 0
	tank._complete_spawn()
	tank.invulnerability_timer = 0
	tank._end_invulnerability()

## Scenario: Tank position is constrained to 16-pixel tile centers
## Given a tank at any position
## When tank moves
## Then tank position aligns to 16-pixel tile centers (0, 16, 32, 48...)
func test_given_tank_at_tile_center_when_moves_then_stays_on_16px_grid():
	# Given: Tank at (128, 128) - on tile center
	assert_eq(tank.global_position, Vector2(128, 128))
	
	# When: Tank moves up (instant discrete movement)
	tank.move_in_direction(Tank.Direction.UP)
	# For discrete movement, position changes immediately
	tank._physics_process(1.0/60.0)
	
	# Then: Position X and Y are multiples of 16 (tile centers)
	var x_mod = int(tank.global_position.x) % 16
	var y_mod = int(tank.global_position.y) % 16
	assert_eq(x_mod, 0, "X position should align to 16-pixel tile center, got: %s" % tank.global_position.x)
	assert_eq(y_mod, 0, "Y position should align to 16-pixel tile center, got: %s" % tank.global_position.y)

## Scenario: Tank moves in discrete 16-pixel tile steps
## Given tank at tile center (128, 128)
## When tank moves in a direction
## Then tank position changes by exactly 16 pixels to adjacent tile center
func test_given_tank_when_moves_then_position_changes_by_16px_to_next_tile():
	# Given: Tank at (128, 128) - tile center
	var start_pos = tank.global_position
	assert_eq(start_pos, Vector2(128, 128))
	
	# When: Move right (instant discrete movement)
	tank.move_in_direction(Tank.Direction.RIGHT)
	tank._physics_process(1.0/60.0)  # Process one frame
	
	# Then: X changed by exactly 16 pixels to next tile center
	var expected_pos = Vector2(144, 128)  # 128 + 16
	assert_eq(tank.global_position, expected_pos, "Tank should move exactly 16px to next tile center")

## Scenario: Tank changes direction and moves to new tile
## Given tank at tile center
## When tank changes direction
## Then tank moves to adjacent tile center in new direction
func test_given_tank_at_tile_center_when_changes_direction_then_moves_to_new_tile():
	# Given: Tank at tile center (128, 128)
	assert_eq(tank.global_position, Vector2(128, 128))
	assert_eq(tank.facing_direction, Tank.Direction.UP)
	
	# When: Change direction to right (moves immediately in discrete system)
	tank.move_in_direction(Tank.Direction.RIGHT)
	tank._physics_process(1.0/60.0)
	
	# Then: Position moves to adjacent tile center, direction changed
	assert_eq(tank.global_position, Vector2(144, 128), "Tank should move to adjacent tile center when changing direction")
	assert_eq(tank.facing_direction, Tank.Direction.RIGHT, "Tank should face new direction")

## Scenario: Tank stops at tile centers
## Given tank at tile center
## When tank stops
## Then tank position remains at tile center
func test_given_tank_at_tile_center_when_stops_then_stays_at_center():
	# Given: Tank at tile center
	assert_eq(tank.global_position, Vector2(128, 128))
	
	# When: Stop movement (though tank isn't moving in discrete system)
	tank.stop_movement()
	
	# Then: Position remains at tile center
	assert_eq(tank.global_position, Vector2(128, 128), "Tank should stay at tile center when stopped")
	assert_eq(tank.velocity, Vector2.ZERO, "Tank velocity should be zero")

## Scenario: Tank cannot move beyond map boundaries
## Given tank at edge tile center
## When tank tries to move beyond boundary
## Then tank position remains at boundary tile center
func test_given_tank_at_boundary_when_tries_to_move_beyond_then_stays_at_boundary():
	# Given: Tank at top boundary tile center (y=16, which is TILE_SIZE)
	tank.global_position = Vector2(128, 16)
	
	# When: Try to move up beyond boundary
	tank.move_in_direction(Tank.Direction.UP)
	tank._physics_process(1.0/60.0)
	
	# Then: Tank stays at boundary tile center (y=16)
	assert_eq(tank.global_position, Vector2(128, 16), "Tank should stay at boundary tile center")
	var y_mod = int(tank.global_position.y) % 16
	assert_eq(y_mod, 0, "Tank position should remain at tile center")

## Scenario: Tank occupies 2x2 tile footprint (32x32 pixels)
## Given tank at tile center (128, 128)
## When checking occupied tiles
## Then tank occupies 4 tiles in 2x2 pattern around center
func test_given_tank_at_tile_center_when_get_tiles_then_returns_2x2_footprint():
	# Given: Tank at (128, 128) - tile center
	tank.global_position = Vector2(128, 128)
	
	# When: Get occupied tiles
	var tiles = tank.get_occupied_tiles()
	
	# Then: 4 tiles returned
	assert_eq(tiles.size(), 4, "Tank occupies 4 tiles")
	
	# Tank is 32x32, positioned at center (128, 128)
	# Corners at (112, 112) to (144, 144)
	# In 16px tiles: (112/16, 112/16) = (7, 7) to (144/16, 144/16) = (9, 9)
	# Occupies tiles (7,7), (7,8), (8,7), (8,8)
	assert_true(tiles.has(Vector2i(7, 7)), "Occupies top-left tile")
	assert_true(tiles.has(Vector2i(7, 8)), "Occupies bottom-left tile")
	assert_true(tiles.has(Vector2i(8, 7)), "Occupies top-right tile")
	assert_true(tiles.has(Vector2i(8, 8)), "Occupies bottom-right tile")

## Scenario: Multiple tanks can exist at different tile centers
## Given two tanks at different tile centers
## When checking positions
## Then positions are distinct and tile-center aligned
func test_given_two_tanks_when_at_different_tile_centers_then_both_on_grid():
	# Given: First tank at (128, 128) - tile center
	var tank2 = Tank.new()
	tank2.tank_type = Tank.TankType.BASIC
	tank2.global_position = Vector2(192, 192)  # Another tile center (12*16, 12*16)
	add_child_autofree(tank2)
	tank2.spawn_timer = 0
	tank2._complete_spawn()
	
	# When: Check both positions
	var t1_x_mod = int(tank.global_position.x) % 16
	var t1_y_mod = int(tank.global_position.y) % 16
	var t2_x_mod = int(tank2.global_position.x) % 16
	var t2_y_mod = int(tank2.global_position.y) % 16
	
	# Then: Both at tile centers
	assert_eq(t1_x_mod, 0, "Tank 1 at tile center")
	assert_eq(t1_y_mod, 0, "Tank 1 at tile center")
	assert_eq(t2_x_mod, 0, "Tank 2 at tile center")
	assert_eq(t2_y_mod, 0, "Tank 2 at tile center")
	assert_ne(tank.global_position, tank2.global_position, "Tanks at different tile centers")

## Scenario: Tank movement is instant regardless of speed
## Given tanks with different speeds at tile centers
## When both move in same direction
## Then both move instantly to next tile center (speed affects future movement rate)
func test_given_fast_and_normal_tanks_when_move_then_both_move_instantly_to_next_tile():
	# Given: Normal tank at (128, 128) and fast tank at (128, 192)
	var fast_tank = Tank.new()
	fast_tank.tank_type = Tank.TankType.FAST
	fast_tank.base_speed = 100.0
	fast_tank.global_position = Vector2(128, 192)  # Different tile center
	add_child_autofree(fast_tank)
	fast_tank.spawn_timer = 0
	fast_tank._complete_spawn()
	fast_tank.invulnerability_timer = 0
	fast_tank._end_invulnerability()
	
	var normal_start = tank.global_position
	var fast_start = fast_tank.global_position
	
	# When: Both move right (instant discrete movement)
	tank.move_in_direction(Tank.Direction.RIGHT)
	fast_tank.move_in_direction(Tank.Direction.RIGHT)
	tank._physics_process(1.0/60.0)
	fast_tank._physics_process(1.0/60.0)
	
	# Then: Both moved instantly to next tile center
	var normal_expected = Vector2(144, 128)  # 128 + 16
	var fast_expected = Vector2(144, 192)    # 128 + 16
	assert_eq(tank.global_position, normal_expected, "Normal tank moved to next tile center")
	assert_eq(fast_tank.global_position, fast_expected, "Fast tank moved to next tile center")
	
	# Both still at tile centers
	assert_eq(int(tank.global_position.x) % 16, 0, "Normal tank at tile center")
	assert_eq(int(fast_tank.global_position.x) % 16, 0, "Fast tank at tile center")
