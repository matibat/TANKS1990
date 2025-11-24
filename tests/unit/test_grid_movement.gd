extends GutTest
## BDD: Grid-Based Tank Movement
## Tanks move in discrete 8-pixel increments on a 26x26 tile grid

var tank: Tank

func before_each():
	tank = Tank.new()
	tank.tank_type = Tank.TankType.PLAYER
	tank.base_speed = 100.0
	tank.tank_id = 1
	# Start at grid-aligned position: (16*8, 16*8) = (128, 128)
	tank.global_position = Vector2(128, 128)
	add_child_autofree(tank)
	tank.spawn_timer = 0
	tank._complete_spawn()
	tank.invulnerability_timer = 0
	tank._end_invulnerability()

## Scenario: Tank position is constrained to 8-pixel sub-grid
## Given a tank at any position
## When tank moves
## Then tank position aligns to 8-pixel boundaries (0, 8, 16, 24...)
func test_given_tank_at_grid_position_when_moves_then_stays_on_8px_grid():
	# Given: Tank at (128, 128) - on grid
	assert_eq(tank.global_position, Vector2(128, 128))
	
	# When: Tank moves up
	tank.move_in_direction(Tank.Direction.UP)
	for i in range(30):  # Simulate movement
		tank._physics_process(1.0/60.0)
	
	# Then: Position X and Y are multiples of 8
	var x_mod = int(tank.global_position.x) % 8
	var y_mod = int(tank.global_position.y) % 8
	assert_eq(x_mod, 0, "X position should align to 8-pixel grid, got: %s" % tank.global_position.x)
	assert_eq(y_mod, 0, "Y position should align to 8-pixel grid, got: %s" % tank.global_position.y)

## Scenario: Tank moves in discrete 8-pixel steps
## Given tank at grid position (128, 128)
## When tank moves in a direction
## Then tank position changes by multiples of 8 pixels
func test_given_tank_when_moves_then_position_changes_in_8px_increments():
	# Given: Tank at (128, 128)
	var start_pos = tank.global_position
	assert_eq(start_pos, Vector2(128, 128))
	
	# When: Move right for enough frames to complete one grid step
	tank.move_in_direction(Tank.Direction.RIGHT)
	for i in range(10):
		tank._physics_process(1.0/60.0)
	
	# Then: X changed by multiple of 8
	var delta_x = tank.global_position.x - start_pos.x
	var steps = round(delta_x / 8.0)
	var expected_pos_x = start_pos.x + (steps * 8)
	assert_almost_eq(tank.global_position.x, expected_pos_x, 0.1, 
		"Tank X should move in 8-pixel increments")

## Scenario: Tank snaps to grid when changing direction
## Given tank moving in one direction
## When tank changes direction
## Then tank snaps to nearest 8-pixel grid position before turning
func test_given_tank_moving_when_changes_direction_then_snaps_to_grid():
	# Given: Tank moving up
	tank.move_in_direction(Tank.Direction.UP)
	for i in range(5):
		tank._physics_process(1.0/60.0)
	
	var pos_before_turn = tank.global_position
	
	# When: Change direction to right
	tank.move_in_direction(Tank.Direction.RIGHT)
	
	# Then: Position is snapped to 8-pixel grid
	var x_mod = int(tank.global_position.x) % 8
	var y_mod = int(tank.global_position.y) % 8
	assert_eq(x_mod, 0, "X snapped to grid on direction change")
	assert_eq(y_mod, 0, "Y snapped to grid on direction change")

## Scenario: Tank snaps to grid when stopping
## Given tank moving
## When tank stops
## Then tank position aligns to 8-pixel grid
func test_given_tank_moving_when_stops_then_snaps_to_grid():
	# Given: Tank moving down
	tank.move_in_direction(Tank.Direction.DOWN)
	for i in range(7):
		tank._physics_process(1.0/60.0)
	
	# When: Stop
	tank.stop_movement()
	
	# Then: Position snapped to grid
	var x_mod = int(tank.global_position.x) % 8
	var y_mod = int(tank.global_position.y) % 8
	assert_eq(x_mod, 0, "X snapped to grid on stop")
	assert_eq(y_mod, 0, "Y snapped to grid on stop")
	assert_eq(tank.velocity, Vector2.ZERO, "Tank stopped")

## Scenario: Tank cannot move off the 26x26 tile grid
## Given tank at edge of playfield
## When tank tries to move beyond boundary
## Then tank position is clamped to valid grid
func test_given_tank_at_edge_when_moves_beyond_then_clamped_to_grid():
	# Given: Tank near top edge (y=8)
	tank.global_position = Vector2(128, 8)
	
	# When: Try to move up beyond boundary
	tank.move_in_direction(Tank.Direction.UP)
	for i in range(20):
		tank._physics_process(1.0/60.0)
	
	# Then: Tank clamped at y=16 (TILE_SIZE, keeps 2x2 footprint in bounds)
	assert_lte(tank.global_position.y, 16.0, "Tank clamped at top boundary (min 16px)")
	var y_mod = int(tank.global_position.y) % 8
	assert_eq(y_mod, 0, "Tank position still on grid at boundary")

## Scenario: Tank occupies 2x2 tile footprint (32x32 pixels)
## Given tank at position (128, 128)
## When checking occupied tiles
## Then tank occupies 4 tiles in 2x2 pattern
func test_given_tank_at_position_when_get_tiles_then_returns_2x2_footprint():
	# Given: Tank at (128, 128) - center position
	tank.global_position = Vector2(128, 128)
	
	# When: Get occupied tiles
	var tiles = tank.get_occupied_tiles()
	
	# Then: 4 tiles returned
	assert_eq(tiles.size(), 4, "Tank occupies 4 tiles")
	
	# Tank is 32x32, positioned at center
	# Center at (128, 128) means corners at (112, 112) to (144, 144)
	# In tiles: (112/16, 112/16) = (7, 7) to (144/16, 144/16) = (9, 9)
	# Occupies tiles (7,7), (7,8), (8,7), (8,8)
	assert_true(tiles.has(Vector2i(7, 7)), "Occupies top-left tile")
	assert_true(tiles.has(Vector2i(7, 8)), "Occupies bottom-left tile")
	assert_true(tiles.has(Vector2i(8, 7)), "Occupies top-right tile")
	assert_true(tiles.has(Vector2i(8, 8)), "Occupies bottom-right tile")

## Scenario: Multiple tanks can exist on grid without overlapping
## Given two tanks at different grid positions
## When checking positions
## Then positions are distinct and grid-aligned
func test_given_two_tanks_when_at_different_positions_then_both_on_grid():
	# Given: First tank at (128, 128)
	var tank2 = Tank.new()
	tank2.tank_type = Tank.TankType.BASIC
	tank2.global_position = Vector2(200, 200)
	add_child_autofree(tank2)
	tank2.spawn_timer = 0
	tank2._complete_spawn()
	
	# When: Check both positions
	var t1_x_mod = int(tank.global_position.x) % 8
	var t1_y_mod = int(tank.global_position.y) % 8
	var t2_x_mod = int(tank2.global_position.x) % 8
	var t2_y_mod = int(tank2.global_position.y) % 8
	
	# Then: Both on grid
	assert_eq(t1_x_mod, 0, "Tank 1 on grid")
	assert_eq(t1_y_mod, 0, "Tank 1 on grid")
	assert_eq(t2_x_mod, 0, "Tank 2 on grid")
	assert_eq(t2_y_mod, 0, "Tank 2 on grid")
	assert_ne(tank.global_position, tank2.global_position, "Tanks at different positions")

## Scenario: Tank speed determines time to cross one grid cell
## Given tanks with different speeds
## When moving for same duration
## Then faster tanks cover more grid cells
func test_given_fast_and_slow_tanks_when_move_same_time_then_different_distances():
	# Given: Normal tank at (128, 128) and fast tank at (128, 256)
	var fast_tank = Tank.new()
	fast_tank.tank_type = Tank.TankType.FAST
	fast_tank.base_speed = 100.0
	fast_tank.global_position = Vector2(128, 256)
	add_child_autofree(fast_tank)
	fast_tank.spawn_timer = 0
	fast_tank._complete_spawn()
	fast_tank.invulnerability_timer = 0
	fast_tank._end_invulnerability()
	
	var normal_start = tank.global_position.x
	var fast_start = fast_tank.global_position.x
	
	# When: Both move right for 60 frames (need more time to see difference across grid cells)
	for i in range(60):
		# Keep issuing movement commands to continue grid-to-grid movement
		tank.move_in_direction(Tank.Direction.RIGHT)
		fast_tank.move_in_direction(Tank.Direction.RIGHT)
		tank._physics_process(1.0/60.0)
		fast_tank._physics_process(1.0/60.0)
	
	# Then: Fast tank moved further (1.5x speed means 1.5x distance)
	var normal_dist = tank.global_position.x - normal_start
	var fast_dist = fast_tank.global_position.x - fast_start
	assert_gt(fast_dist, normal_dist, "Fast tank should move further in same time")
	
	# Both still on grid
	assert_eq(int(tank.global_position.x) % 8, 0, "Normal tank on grid")
	assert_eq(int(fast_tank.global_position.x) % 8, 0, "Fast tank on grid")
