extends GutTest

# BDD Tests for Position Value Object
# Position represents an immutable coordinate on the 26x26 tile grid

const Position = preload("res://src/domain/value_objects/position.gd")

func test_given_coordinates_when_created_then_stores_values():
	# Given/When: Create position with coordinates
	var pos = Position.create(5, 10)
	
	# Then: Values are stored correctly
	assert_eq(pos.x, 5)
	assert_eq(pos.y, 10)

func test_given_two_positions_with_same_coordinates_when_compared_then_equal():
	# Given: Two positions with same coordinates
	var pos1 = Position.create(3, 7)
	var pos2 = Position.create(3, 7)
	
	# When/Then: They are equal
	assert_true(pos1.equals(pos2))

func test_given_two_positions_with_different_coordinates_when_compared_then_not_equal():
	# Given: Two positions with different coordinates
	var pos1 = Position.create(3, 7)
	var pos2 = Position.create(3, 8)
	
	# When/Then: They are not equal
	assert_false(pos1.equals(pos2))

func test_given_position_when_added_to_another_then_returns_new_position():
	# Given: Two positions
	var pos1 = Position.create(2, 3)
	var pos2 = Position.create(5, 7)
	
	# When: Add them together
	var result = pos1.add(pos2)
	
	# Then: New position with summed coordinates
	assert_eq(result.x, 7)
	assert_eq(result.y, 10)

func test_given_position_when_converted_to_dict_then_serializes_correctly():
	# Given: A position
	var pos = Position.create(12, 18)
	
	# When: Convert to dictionary
	var dict = pos.to_dict()
	
	# Then: Dictionary contains coordinates
	assert_eq(dict["x"], 12)
	assert_eq(dict["y"], 18)

func test_given_dict_when_creating_from_dict_then_deserializes_correctly():
	# Given: A dictionary with coordinates
	var dict = {"x": 15, "y": 22}
	
	# When: Create position from dictionary
	var pos = Position.from_dict(dict)
	
	# Then: Position has correct values
	assert_eq(pos.x, 15)
	assert_eq(pos.y, 22)

func test_given_position_when_add_called_then_original_unchanged():
	# Given: A position
	var pos1 = Position.create(5, 5)
	var pos2 = Position.create(1, 1)
	
	# When: Add another position
	var result = pos1.add(pos2)
	
	# Then: Original position unchanged (immutability)
	assert_eq(pos1.x, 5)
	assert_eq(pos1.y, 5)
	assert_eq(result.x, 6)
	assert_eq(result.y, 6)
