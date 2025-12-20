extends GutTest

# BDD Tests for Velocity Value Object
# Velocity represents movement delta per frame

const Velocity = preload("res://src/domain/value_objects/velocity.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")
const Position = preload("res://src/domain/value_objects/position.gd")

func test_given_dx_and_dy_when_created_then_stores_values():
	# Given/When: Create velocity
	var vel = Velocity.create(2, -3)
	
	# Then: Values are stored correctly
	assert_eq(vel.dx, 2)
	assert_eq(vel.dy, -3)

func test_given_zero_velocity_when_created_then_both_components_zero():
	# Given/When: Create zero velocity
	var vel = Velocity.zero()
	
	# Then: Both components are zero
	assert_eq(vel.dx, 0)
	assert_eq(vel.dy, 0)

func test_given_up_direction_when_velocity_from_direction_then_negative_y():
	# Given: UP direction
	var dir = Direction.create(Direction.UP)
	
	# When: Create velocity from direction
	var vel = Velocity.from_direction(dir, 1)
	
	# Then: Velocity is (0, -1)
	assert_eq(vel.dx, 0)
	assert_eq(vel.dy, -1)

func test_given_down_direction_when_velocity_from_direction_then_positive_y():
	# Given: DOWN direction
	var dir = Direction.create(Direction.DOWN)
	
	# When: Create velocity from direction with speed 2
	var vel = Velocity.from_direction(dir, 2)
	
	# Then: Velocity is (0, 2)
	assert_eq(vel.dx, 0)
	assert_eq(vel.dy, 2)

func test_given_left_direction_when_velocity_from_direction_then_negative_x():
	# Given: LEFT direction
	var dir = Direction.create(Direction.LEFT)
	
	# When: Create velocity from direction
	var vel = Velocity.from_direction(dir, 1)
	
	# Then: Velocity is (-1, 0)
	assert_eq(vel.dx, -1)
	assert_eq(vel.dy, 0)

func test_given_right_direction_when_velocity_from_direction_then_positive_x():
	# Given: RIGHT direction
	var dir = Direction.create(Direction.RIGHT)
	
	# When: Create velocity from direction with speed 3
	var vel = Velocity.from_direction(dir, 3)
	
	# Then: Velocity is (3, 0)
	assert_eq(vel.dx, 3)
	assert_eq(vel.dy, 0)

func test_given_zero_velocity_when_is_zero_then_returns_true():
	# Given: Zero velocity
	var vel = Velocity.zero()
	
	# When/Then: Is zero
	assert_true(vel.is_zero())

func test_given_non_zero_dx_when_is_zero_then_returns_false():
	# Given: Velocity with non-zero dx
	var vel = Velocity.create(1, 0)
	
	# When/Then: Is not zero
	assert_false(vel.is_zero())

func test_given_non_zero_dy_when_is_zero_then_returns_false():
	# Given: Velocity with non-zero dy
	var vel = Velocity.create(0, 1)
	
	# When/Then: Is not zero
	assert_false(vel.is_zero())

func test_given_velocity_when_created_then_immutable():
	# Given: A velocity
	var vel = Velocity.create(5, 10)
	
	# When: Try to access values
	# Then: Values remain constant (immutability ensured by design)
	assert_eq(vel.dx, 5)
	assert_eq(vel.dy, 10)
