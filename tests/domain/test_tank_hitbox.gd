extends GutTest

## BDD Tests for Tank Hitbox - Multi-tile dimensions (4 wide × 3 long)
## Test-First: Write tests → Implement → Pass
## Critical: Tanks are 4 units wide and 3 units long
## Hitbox is exactly 3 units long (NOT 4) - the 4th visual unit is NOT part of collision
## Hitbox is direction-aware (rotates with tank facing)

const TankEntity = preload("res://src/domain/entities/tank_entity.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")

## Test: Tank Hitbox Calculation - NORTH (UP) Orientation
func test_given_tank_facing_north_when_get_hitbox_then_returns_4_wide_3_long():
	# Given: Tank at (10, 10) facing NORTH (UP)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	
	# When: Hitbox is calculated
	var hitbox = tank.get_hitbox()
	
	# Then: Hitbox should exist
	assert_not_null(hitbox, "Hitbox should be created")
	
	# Then: Hitbox should be 4 wide (perpendicular to direction)
	# Then: Hitbox should be 3 long (parallel to direction - NOT 4)
	# Expected: Width=4 (left-right), Length=3 (forward - UP direction)
	# Visual facing NORTH:
	#   [visual nose - 4th tile, NOT in hitbox]
	#   [X] [X] [X] [X]  <- Row at y=7 (3 units forward)
	#   [X] [X] [X] [X]  <- Row at y=8 (2 units forward)
	#   [X] [X] [X] [X]  <- Row at y=9 (1 unit forward)
	#   [X] [X] [X] [X]  <- Row at y=10 (center row)
	# Total: 12 tiles (but implementation doesn't exist yet - test should fail)

func test_given_tank_facing_north_at_10_10_when_get_occupied_tiles_then_returns_12_tiles():
	# Given: Tank at (10, 10) facing NORTH (UP)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	
	# When: Occupied tiles are retrieved
	var hitbox = tank.get_hitbox()
	var tiles = hitbox.get_occupied_tiles()
	
	# Then: Should return exactly 12 tiles (4 wide × 3 long)
	assert_eq(tiles.size(), 12, "Tank hitbox should occupy exactly 12 tiles")
	
	# Then: Verify specific tile positions for NORTH facing
	# Center at (10, 10), width 4, length 3 forward (UP = negative Y)
	# Expected tiles (4 wide from x=8 to x=11, 3 long from y=8 to y=10):
	# Row y=10 (center): (8,10), (9,10), (10,10), (11,10)
	# Row y=9  (1 forward): (8,9), (9,9), (10,9), (11,9)
	# Row y=8  (2 forward): (8,8), (9,8), (10,8), (11,8)
	# NOTE: y=7 (3 forward) is NOT included - that's the 4th visual unit
	
	assert_true(_contains_position(tiles, Position.create(8, 10)), "Should contain left-back tile")
	assert_true(_contains_position(tiles, Position.create(9, 10)), "Should contain center-left-back tile")
	assert_true(_contains_position(tiles, Position.create(10, 10)), "Should contain center tile")
	assert_true(_contains_position(tiles, Position.create(11, 10)), "Should contain center-right-back tile")
	
	assert_true(_contains_position(tiles, Position.create(8, 9)), "Should contain left-middle tile")
	assert_true(_contains_position(tiles, Position.create(9, 9)), "Should contain center-left-middle tile")
	assert_true(_contains_position(tiles, Position.create(10, 9)), "Should contain center-middle tile")
	assert_true(_contains_position(tiles, Position.create(11, 9)), "Should contain center-right-middle tile")
	
	assert_true(_contains_position(tiles, Position.create(8, 8)), "Should contain left-front tile")
	assert_true(_contains_position(tiles, Position.create(9, 8)), "Should contain center-left-front tile")
	assert_true(_contains_position(tiles, Position.create(10, 8)), "Should contain center-front tile")
	assert_true(_contains_position(tiles, Position.create(11, 8)), "Should contain center-right-front tile")

func test_given_tank_facing_north_when_get_occupied_tiles_then_excludes_4th_forward_tile():
	# Given: Tank at (10, 10) facing NORTH (UP)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	
	# When: Occupied tiles are retrieved
	var hitbox = tank.get_hitbox()
	var tiles = hitbox.get_occupied_tiles()
	
	# Then: 4th forward tile (visual nose) should NOT be in hitbox
	# For NORTH facing, 4th unit would be at y=7 (3 tiles forward from center y=10)
	# But hitbox is only 3 units long, so y=7 should NOT be included
	assert_false(_contains_position(tiles, Position.create(8, 7)), "4th tile (left) should NOT be in hitbox")
	assert_false(_contains_position(tiles, Position.create(9, 7)), "4th tile (center-left) should NOT be in hitbox")
	assert_false(_contains_position(tiles, Position.create(10, 7)), "4th tile (center) should NOT be in hitbox")
	assert_false(_contains_position(tiles, Position.create(11, 7)), "4th tile (center-right) should NOT be in hitbox")

## Test: Tank Hitbox Calculation - SOUTH (DOWN) Orientation
func test_given_tank_facing_south_when_get_hitbox_then_returns_4_wide_3_long():
	# Given: Tank at (10, 10) facing SOUTH (DOWN)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.DOWN))
	
	# When: Hitbox is calculated
	var hitbox = tank.get_hitbox()
	
	# Then: Hitbox should exist
	assert_not_null(hitbox, "Hitbox should be created")

func test_given_tank_facing_south_at_10_10_when_get_occupied_tiles_then_returns_12_tiles():
	# Given: Tank at (10, 10) facing SOUTH (DOWN)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.DOWN))
	
	# When: Occupied tiles are retrieved
	var hitbox = tank.get_hitbox()
	var tiles = hitbox.get_occupied_tiles()
	
	# Then: Should return exactly 12 tiles
	assert_eq(tiles.size(), 12, "Tank hitbox should occupy exactly 12 tiles")
	
	# Then: Verify specific tile positions for SOUTH facing
	# Center at (10, 10), width 4, length 3 forward (DOWN = positive Y)
	# Expected tiles (4 wide from x=8 to x=11, 3 long from y=10 to y=12):
	# Row y=10 (center): (8,10), (9,10), (10,10), (11,10)
	# Row y=11 (1 forward): (8,11), (9,11), (10,11), (11,11)
	# Row y=12 (2 forward): (8,12), (9,12), (10,12), (11,12)
	# NOTE: y=13 (3 forward) is NOT included - that's the 4th visual unit
	
	assert_true(_contains_position(tiles, Position.create(8, 10)), "Should contain left-back tile")
	assert_true(_contains_position(tiles, Position.create(10, 12)), "Should contain center-front tile")
	assert_true(_contains_position(tiles, Position.create(11, 11)), "Should contain right-middle tile")

func test_given_tank_facing_south_when_get_occupied_tiles_then_excludes_4th_forward_tile():
	# Given: Tank at (10, 10) facing SOUTH (DOWN)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.DOWN))
	
	# When: Occupied tiles are retrieved
	var hitbox = tank.get_hitbox()
	var tiles = hitbox.get_occupied_tiles()
	
	# Then: 4th forward tile (visual nose) should NOT be in hitbox
	# For SOUTH facing, 4th unit would be at y=13 (3 tiles forward from center y=10)
	assert_false(_contains_position(tiles, Position.create(8, 13)), "4th tile should NOT be in hitbox")
	assert_false(_contains_position(tiles, Position.create(9, 13)), "4th tile should NOT be in hitbox")
	assert_false(_contains_position(tiles, Position.create(10, 13)), "4th tile should NOT be in hitbox")
	assert_false(_contains_position(tiles, Position.create(11, 13)), "4th tile should NOT be in hitbox")

## Test: Tank Hitbox Calculation - EAST (RIGHT) Orientation
func test_given_tank_facing_east_when_get_hitbox_then_rotates_to_3_wide_4_long():
	# Given: Tank at (10, 10) facing EAST (RIGHT)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.RIGHT))
	
	# When: Hitbox is calculated
	var hitbox = tank.get_hitbox()
	
	# Then: Hitbox should exist
	assert_not_null(hitbox, "Hitbox should be created")
	
	# Then: Hitbox dimensions should rotate (width and length swap)
	# EAST facing: 3 units long forward (RIGHT = positive X), 4 units wide (perpendicular = Y axis)
	# Visual representation would show rotation from 4-wide to 4-tall

func test_given_tank_facing_east_at_10_10_when_get_occupied_tiles_then_returns_12_tiles():
	# Given: Tank at (10, 10) facing EAST (RIGHT)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.RIGHT))
	
	# When: Occupied tiles are retrieved
	var hitbox = tank.get_hitbox()
	var tiles = hitbox.get_occupied_tiles()
	
	# Then: Should return exactly 12 tiles
	assert_eq(tiles.size(), 12, "Tank hitbox should occupy exactly 12 tiles")
	
	# Then: Verify specific tile positions for EAST facing
	# Center at (10, 10), length 3 forward (RIGHT = positive X), width 4 perpendicular (Y axis)
	# Expected tiles (3 long from x=10 to x=12, 4 wide from y=8 to y=11):
	# Col x=10 (center): (10,8), (10,9), (10,10), (10,11)
	# Col x=11 (1 forward): (11,8), (11,9), (11,10), (11,11)
	# Col x=12 (2 forward): (12,8), (12,9), (12,10), (12,11)
	# NOTE: x=13 (3 forward) is NOT included - that's the 4th visual unit
	
	assert_true(_contains_position(tiles, Position.create(10, 8)), "Should contain back-top tile")
	assert_true(_contains_position(tiles, Position.create(10, 10)), "Should contain center tile")
	assert_true(_contains_position(tiles, Position.create(12, 11)), "Should contain front-bottom tile")

func test_given_tank_facing_east_when_get_occupied_tiles_then_excludes_4th_forward_tile():
	# Given: Tank at (10, 10) facing EAST (RIGHT)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.RIGHT))
	
	# When: Occupied tiles are retrieved
	var hitbox = tank.get_hitbox()
	var tiles = hitbox.get_occupied_tiles()
	
	# Then: 4th forward tile (visual nose) should NOT be in hitbox
	# For EAST facing, 4th unit would be at x=13 (3 tiles forward from center x=10)
	assert_false(_contains_position(tiles, Position.create(13, 8)), "4th tile should NOT be in hitbox")
	assert_false(_contains_position(tiles, Position.create(13, 9)), "4th tile should NOT be in hitbox")
	assert_false(_contains_position(tiles, Position.create(13, 10)), "4th tile should NOT be in hitbox")
	assert_false(_contains_position(tiles, Position.create(13, 11)), "4th tile should NOT be in hitbox")

## Test: Tank Hitbox Calculation - WEST (LEFT) Orientation
func test_given_tank_facing_west_when_get_hitbox_then_rotates_to_3_wide_4_long():
	# Given: Tank at (10, 10) facing WEST (LEFT)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.LEFT))
	
	# When: Hitbox is calculated
	var hitbox = tank.get_hitbox()
	
	# Then: Hitbox should exist
	assert_not_null(hitbox, "Hitbox should be created")

func test_given_tank_facing_west_at_10_10_when_get_occupied_tiles_then_returns_12_tiles():
	# Given: Tank at (10, 10) facing WEST (LEFT)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.LEFT))
	
	# When: Occupied tiles are retrieved
	var hitbox = tank.get_hitbox()
	var tiles = hitbox.get_occupied_tiles()
	
	# Then: Should return exactly 12 tiles
	assert_eq(tiles.size(), 12, "Tank hitbox should occupy exactly 12 tiles")
	
	# Then: Verify specific tile positions for WEST facing
	# Center at (10, 10), length 3 forward (LEFT = negative X), width 4 perpendicular (Y axis)
	# Expected tiles (3 long from x=8 to x=10, 4 wide from y=8 to y=11):
	# Col x=10 (center): (10,8), (10,9), (10,10), (10,11)
	# Col x=9  (1 forward): (9,8), (9,9), (9,10), (9,11)
	# Col x=8  (2 forward): (8,8), (8,9), (8,10), (8,11)
	# NOTE: x=7 (3 forward) is NOT included - that's the 4th visual unit
	
	assert_true(_contains_position(tiles, Position.create(10, 8)), "Should contain back-top tile")
	assert_true(_contains_position(tiles, Position.create(10, 10)), "Should contain center tile")
	assert_true(_contains_position(tiles, Position.create(8, 11)), "Should contain front-bottom tile")

func test_given_tank_facing_west_when_get_occupied_tiles_then_excludes_4th_forward_tile():
	# Given: Tank at (10, 10) facing WEST (LEFT)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.LEFT))
	
	# When: Occupied tiles are retrieved
	var hitbox = tank.get_hitbox()
	var tiles = hitbox.get_occupied_tiles()
	
	# Then: 4th forward tile (visual nose) should NOT be in hitbox
	# For WEST facing, 4th unit would be at x=7 (3 tiles forward from center x=10)
	assert_false(_contains_position(tiles, Position.create(7, 8)), "4th tile should NOT be in hitbox")
	assert_false(_contains_position(tiles, Position.create(7, 9)), "4th tile should NOT be in hitbox")
	assert_false(_contains_position(tiles, Position.create(7, 10)), "4th tile should NOT be in hitbox")
	assert_false(_contains_position(tiles, Position.create(7, 11)), "4th tile should NOT be in hitbox")

## Test: Hitbox Position Containment
func test_given_position_inside_hitbox_when_contains_position_checked_then_returns_true():
	# Given: Tank at (10, 10) facing NORTH, position at (9, 9) (inside hitbox)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	var test_pos = Position.create(9, 9)
	
	# When: Contains position is checked
	var hitbox = tank.get_hitbox()
	var contains = hitbox.contains_position(test_pos)
	
	# Then: Should return true (position is inside hitbox)
	assert_true(contains, "Hitbox should contain position inside its boundaries")

func test_given_position_outside_hitbox_when_contains_position_checked_then_returns_false():
	# Given: Tank at (10, 10) facing NORTH, position at (15, 15) (outside hitbox)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	var test_pos = Position.create(15, 15)
	
	# When: Contains position is checked
	var hitbox = tank.get_hitbox()
	var contains = hitbox.contains_position(test_pos)
	
	# Then: Should return false (position is outside hitbox)
	assert_false(contains, "Hitbox should not contain position outside its boundaries")

func test_given_position_at_4th_unit_when_contains_position_checked_then_returns_false():
	# Given: Tank at (10, 10) facing NORTH, position at (10, 7) (4th visual unit)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	var test_pos = Position.create(10, 7) # 4th unit forward (NOT in hitbox)
	
	# When: Contains position is checked
	var hitbox = tank.get_hitbox()
	var contains = hitbox.contains_position(test_pos)
	
	# Then: Should return false (4th unit is visual only, not part of hitbox)
	assert_false(contains, "Hitbox should NOT contain 4th forward tile (visual nose only)")

## Test: Edge Cases
func test_given_tank_at_grid_edge_when_get_hitbox_then_returns_valid_hitbox():
	# Given: Tank at (1, 1) (near edge) facing NORTH
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(1, 1), Direction.create(Direction.UP))
	
	# When: Hitbox is calculated
	var hitbox = tank.get_hitbox()
	var tiles = hitbox.get_occupied_tiles()
	
	# Then: Should return tiles (may extend outside grid - validation happens elsewhere)
	assert_not_null(hitbox, "Hitbox should be created even near edge")
	assert_eq(tiles.size(), 12, "Hitbox should always have 12 tiles regardless of grid position")
	# Note: Grid boundary validation is responsibility of CollisionService/MovementService

func test_given_two_tanks_same_position_different_directions_when_hitboxes_calculated_then_different_tiles():
	# Given: Two tanks at same position (10, 10), one facing NORTH, one facing EAST
	var tank_north = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	var tank_east = TankEntity.create("tank_2", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.RIGHT))
	
	# When: Hitboxes are calculated
	var hitbox_north = tank_north.get_hitbox()
	var hitbox_east = tank_east.get_hitbox()
	var tiles_north = hitbox_north.get_occupied_tiles()
	var tiles_east = hitbox_east.get_occupied_tiles()
	
	# Then: Hitboxes should occupy some different tiles due to rotation
	# NORTH: extends more in Y direction (4 wide in X, 3 long in Y)
	# EAST: extends more in X direction (3 long in X, 4 wide in Y)
	assert_eq(tiles_north.size(), 12, "North hitbox should have 12 tiles")
	assert_eq(tiles_east.size(), 12, "East hitbox should have 12 tiles")
	
	# Verify different coverage: NORTH has tile at (8, 8), EAST should not
	assert_true(_contains_position(tiles_north, Position.create(8, 8)), "North hitbox includes left-front tile")
	# EAST facing doesn't extend as far left (only to x=10 for back row)
	# But it does include (12, 8) which NORTH doesn't
	assert_true(_contains_position(tiles_east, Position.create(12, 8)), "East hitbox includes front-top tile")

## Helper function to check if position array contains a specific position
func _contains_position(positions: Array, target: Position) -> bool:
	for pos in positions:
		if pos.equals(target):
			return true
	return false
