extends GutTest

# BDD Tests for Direction Value Object
# Direction represents the four cardinal directions for tank movement

const Direction = preload("res://src/domain/value_objects/direction.gd")
const Position = preload("res://src/domain/value_objects/position.gd")

func test_given_up_direction_when_created_then_stores_correctly():
	# Given/When: Create UP direction
	var dir = Direction.create(Direction.UP)
	
	# Then: Direction is UP
	assert_eq(dir.value, Direction.UP)

func test_given_down_direction_when_created_then_stores_correctly():
	# Given/When: Create DOWN direction
	var dir = Direction.create(Direction.DOWN)
	
	# Then: Direction is DOWN
	assert_eq(dir.value, Direction.DOWN)

func test_given_left_direction_when_created_then_stores_correctly():
	# Given/When: Create LEFT direction
	var dir = Direction.create(Direction.LEFT)
	
	# Then: Direction is LEFT
	assert_eq(dir.value, Direction.LEFT)

func test_given_right_direction_when_created_then_stores_correctly():
	# Given/When: Create RIGHT direction
	var dir = Direction.create(Direction.RIGHT)
	
	# Then: Direction is RIGHT
	assert_eq(dir.value, Direction.RIGHT)

func test_given_up_direction_when_converted_to_delta_then_returns_negative_y():
	# Given: UP direction
	var dir = Direction.create(Direction.UP)
	
	# When: Convert to position delta
	var delta = dir.to_position_delta()
	
	# Then: Delta is (0, -1)
	assert_eq(delta.x, 0)
	assert_eq(delta.y, -1)

func test_given_down_direction_when_converted_to_delta_then_returns_positive_y():
	# Given: DOWN direction
	var dir = Direction.create(Direction.DOWN)
	
	# When: Convert to position delta
	var delta = dir.to_position_delta()
	
	# Then: Delta is (0, 1)
	assert_eq(delta.x, 0)
	assert_eq(delta.y, 1)

func test_given_left_direction_when_converted_to_delta_then_returns_negative_x():
	# Given: LEFT direction
	var dir = Direction.create(Direction.LEFT)
	
	# When: Convert to position delta
	var delta = dir.to_position_delta()
	
	# Then: Delta is (-1, 0)
	assert_eq(delta.x, -1)
	assert_eq(delta.y, 0)

func test_given_right_direction_when_converted_to_delta_then_returns_positive_x():
	# Given: RIGHT direction
	var dir = Direction.create(Direction.RIGHT)
	
	# When: Convert to position delta
	var delta = dir.to_position_delta()
	
	# Then: Delta is (1, 0)
	assert_eq(delta.x, 1)
	assert_eq(delta.y, 0)

func test_given_up_direction_when_opposite_called_then_returns_down():
	# Given: UP direction
	var dir = Direction.create(Direction.UP)
	
	# When: Get opposite
	var opp = dir.opposite()
	
	# Then: Opposite is DOWN
	assert_eq(opp.value, Direction.DOWN)

func test_given_down_direction_when_opposite_called_then_returns_up():
	# Given: DOWN direction
	var dir = Direction.create(Direction.DOWN)
	
	# When: Get opposite
	var opp = dir.opposite()
	
	# Then: Opposite is UP
	assert_eq(opp.value, Direction.UP)

func test_given_left_direction_when_opposite_called_then_returns_right():
	# Given: LEFT direction
	var dir = Direction.create(Direction.LEFT)
	
	# When: Get opposite
	var opp = dir.opposite()
	
	# Then: Opposite is RIGHT
	assert_eq(opp.value, Direction.RIGHT)

func test_given_right_direction_when_opposite_called_then_returns_left():
	# Given: RIGHT direction
	var dir = Direction.create(Direction.RIGHT)
	
	# When: Get opposite
	var opp = dir.opposite()
	
	# Then: Opposite is LEFT
	assert_eq(opp.value, Direction.LEFT)

func test_given_two_directions_with_same_value_when_compared_then_equal():
	# Given: Two UP directions
	var dir1 = Direction.create(Direction.UP)
	var dir2 = Direction.create(Direction.UP)
	
	# When/Then: They are equal
	assert_true(dir1.equals(dir2))

func test_given_two_directions_with_different_values_when_compared_then_not_equal():
	# Given: UP and DOWN directions
	var dir1 = Direction.create(Direction.UP)
	var dir2 = Direction.create(Direction.DOWN)
	
	# When/Then: They are not equal
	assert_false(dir1.equals(dir2))
