extends GutTest

const GridMovementService = preload("res://src/domain/services/grid_movement_service.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")

func test_given_pixel_position_when_snap_to_half_tile_then_aligns_to_8px_grid():
	# Given: Arbitrary pixel position
	var pixel_pos = Vector2(103, 57)
	
	# When: Snap to half-tile grid
	var snapped = GridMovementService.snap_to_half_tile(pixel_pos)
	
	# Then: Should align to nearest 8-pixel boundary
	assert_eq(snapped, Vector2(104, 56), "Should snap (103, 57) to (104, 56)")
	
	# Additional test cases
	assert_eq(GridMovementService.snap_to_half_tile(Vector2(96, 96)), Vector2(96, 96), "Already aligned should stay same")
	assert_eq(GridMovementService.snap_to_half_tile(Vector2(101, 101)), Vector2(104, 104), "Should snap to nearest 8px")
	assert_eq(GridMovementService.snap_to_half_tile(Vector2(105, 105)), Vector2(104, 104), "Should snap down to 104")

func test_given_tank_at_100_50_when_move_up_then_snaps_to_nearest_half_tile():
	# Given: Tank at position (96, 50) - aligned on X, not on Y
	var start_pos = Vector2(96, 50)
	
	# When: Snap to half-tile
	var snapped = GridMovementService.snap_to_half_tile(start_pos)
	
	# Then: Should snap to (96, 48) - nearest half-tile
	# 50 is 2 pixels from 48, and 6 pixels from 56, so should snap to 48
	assert_eq(snapped, Vector2(96, 48), "Should snap to nearest half-tile at (96, 48)")

func test_given_movement_direction_when_calculate_next_half_tile_then_returns_correct_pos():
	# Given: Starting position at (100, 100)
	var start_pos = Vector2(100, 100)
	
	# When/Then: Calculate next half-tile in each direction
	# UP: decrease Y by 8 pixels
	var next_up = GridMovementService.calculate_next_half_tile(start_pos, Direction.UP)
	assert_eq(next_up, Vector2(100, 92), "Moving UP should decrease Y by 8")
	
	# RIGHT: increase X by 8 pixels
	var next_right = GridMovementService.calculate_next_half_tile(start_pos, Direction.RIGHT)
	assert_eq(next_right, Vector2(108, 100), "Moving RIGHT should increase X by 8")
	
	# DOWN: increase Y by 8 pixels
	var next_down = GridMovementService.calculate_next_half_tile(start_pos, Direction.DOWN)
	assert_eq(next_down, Vector2(100, 108), "Moving DOWN should increase Y by 8")
	
	# LEFT: decrease X by 8 pixels
	var next_left = GridMovementService.calculate_next_half_tile(start_pos, Direction.LEFT)
	assert_eq(next_left, Vector2(92, 100), "Moving LEFT should decrease X by 8")

func test_given_tank_at_half_tile_when_validate_position_then_returns_true():
	# Given: Position on half-tile boundary (multiple of 8)
	var valid_pos = Vector2(96, 104)
	
	# When: Validate position
	var is_valid = GridMovementService.is_on_half_tile_boundary(valid_pos)
	
	# Then: Should return true
	assert_true(is_valid, "(96, 104) is on half-tile boundary")
	
	# Given: Position NOT on half-tile boundary
	var invalid_pos = Vector2(97, 104)
	
	# When: Validate position
	var is_invalid = GridMovementService.is_on_half_tile_boundary(invalid_pos)
	
	# Then: Should return false
	assert_false(is_invalid, "(97, 104) is NOT on half-tile boundary")
	
	# Additional cases
	assert_true(GridMovementService.is_on_half_tile_boundary(Vector2(0, 0)), "(0, 0) is valid")
	assert_true(GridMovementService.is_on_half_tile_boundary(Vector2(8, 16)), "(8, 16) is valid")
	assert_false(GridMovementService.is_on_half_tile_boundary(Vector2(7, 8)), "(7, 8) is invalid")

func test_given_pixel_pos_when_convert_to_tile_coords_then_returns_correct_tile():
	# Given: Pixel position (100, 100)
	var pixel_pos = Vector2(100, 100)
	
	# When: Convert to tile coordinates
	var tile_coords = GridMovementService.pixel_to_tile(pixel_pos)
	
	# Then: Should return tile (6, 6) because 100 / 16 = 6.25 → floor to 6
	assert_eq(tile_coords, Vector2i(6, 6), "(100, 100) should be in tile (6, 6)")
	
	# Additional test cases
	assert_eq(GridMovementService.pixel_to_tile(Vector2(0, 0)), Vector2i(0, 0), "(0, 0) → tile (0, 0)")
	assert_eq(GridMovementService.pixel_to_tile(Vector2(15, 15)), Vector2i(0, 0), "(15, 15) → tile (0, 0)")
	assert_eq(GridMovementService.pixel_to_tile(Vector2(16, 16)), Vector2i(1, 1), "(16, 16) → tile (1, 1)")
	assert_eq(GridMovementService.pixel_to_tile(Vector2(32, 48)), Vector2i(2, 3), "(32, 48) → tile (2, 3)")

func test_given_tile_coords_when_convert_to_pixel_pos_then_returns_center_pixel():
	# Given: Tile coordinates (6, 6)
	var tile_coords = Vector2i(6, 6)
	
	# When: Convert to pixel position
	var pixel_pos = GridMovementService.tile_to_pixel(tile_coords)
	
	# Then: Should return top-left pixel (96, 96) because 6 * 16 = 96
	assert_eq(pixel_pos, Vector2(96, 96), "Tile (6, 6) → pixel (96, 96)")
	
	# Additional test cases
	assert_eq(GridMovementService.tile_to_pixel(Vector2i(0, 0)), Vector2(0, 0), "Tile (0, 0) → pixel (0, 0)")
	assert_eq(GridMovementService.tile_to_pixel(Vector2i(1, 1)), Vector2(16, 16), "Tile (1, 1) → pixel (16, 16)")
	assert_eq(GridMovementService.tile_to_pixel(Vector2i(2, 3)), Vector2(32, 48), "Tile (2, 3) → pixel (32, 48)")
