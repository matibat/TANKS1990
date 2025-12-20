extends GutTest
## BDD Test: 3D Tank Direction Mapping - Left/Right Control Bug
##
## This test suite verifies that input directions correctly map to 3D world coordinates.
## Bug: Left/right controls are reversed in the current implementation.
##
## Expected behavior (cardinal directions in 3D):
## - UP input should move tank in -Z direction (forward)
## - DOWN input should move tank in +Z direction (backward)
## - LEFT input should move tank in -X direction (left)
## - RIGHT input should move tank in +X direction (right)

const Tank3D = preload("res://src/entities/tank3d.gd")
const Vector3Helpers = preload("res://src/utils/vector3_helpers.gd")

var tank: Tank3D
const TILE_SIZE = 0.5

func before_each():
	tank = Tank3D.new()
	tank.tank_type = Tank3D.TankType.PLAYER
	add_child_autofree(tank)
	tank.global_position = Vector3(5.0, 0.0, 5.0)  # Center position
	await get_tree().process_frame

## SCENARIO: Player presses RIGHT arrow key
## GIVEN a tank at position (5.0, 0, 5.0)
## WHEN player presses RIGHT (positive X direction)
## THEN tank should move to (5.5, 0, 5.0) - moving RIGHT in +X direction
func test_given_tank_at_center_when_input_right_then_moves_positive_x():
	# Given: Tank at center position
	var initial_pos = Vector3(5.0, 0.0, 5.0)
	tank.global_position = initial_pos
	await get_tree().process_frame
	
	# When: Input RIGHT direction (positive X in 3D)
	var input_direction = Vector3(1.0, 0.0, 0.0)  # RIGHT = +X
	tank.set_movement_direction(input_direction)
	await get_tree().process_frame
	
	# Then: Tank should be at X+0.5 (one tile right)
	var expected_pos = Vector3(5.5, 0.0, 5.0)
	assert_almost_eq(tank.global_position.x, expected_pos.x, 0.01, 
		"Tank X should increase by TILE_SIZE when moving RIGHT")
	assert_almost_eq(tank.global_position.z, expected_pos.z, 0.01,
		"Tank Z should not change when moving RIGHT")
	assert_eq(tank.facing_direction, Tank3D.Direction.RIGHT,
		"Tank should face RIGHT direction")

## SCENARIO: Player presses LEFT arrow key
## GIVEN a tank at position (5.0, 0, 5.0)
## WHEN player presses LEFT (negative X direction)
## THEN tank should move to (4.5, 0, 5.0) - moving LEFT in -X direction
func test_given_tank_at_center_when_input_left_then_moves_negative_x():
	# Given: Tank at center position
	var initial_pos = Vector3(5.0, 0.0, 5.0)
	tank.global_position = initial_pos
	await get_tree().process_frame
	
	# When: Input LEFT direction (negative X in 3D)
	var input_direction = Vector3(-1.0, 0.0, 0.0)  # LEFT = -X
	tank.set_movement_direction(input_direction)
	await get_tree().process_frame
	
	# Then: Tank should be at X-0.5 (one tile left)
	var expected_pos = Vector3(4.5, 0.0, 5.0)
	assert_almost_eq(tank.global_position.x, expected_pos.x, 0.01,
		"Tank X should decrease by TILE_SIZE when moving LEFT")
	assert_almost_eq(tank.global_position.z, expected_pos.z, 0.01,
		"Tank Z should not change when moving LEFT")
	assert_eq(tank.facing_direction, Tank3D.Direction.LEFT,
		"Tank should face LEFT direction")

## SCENARIO: Player presses UP arrow key
## GIVEN a tank at position (5.0, 0, 5.0)
## WHEN player presses UP (negative Z direction)
## THEN tank should move to (5.0, 0, 4.5) - moving FORWARD in -Z direction
func test_given_tank_at_center_when_input_up_then_moves_negative_z():
	# Given: Tank at center position
	var initial_pos = Vector3(5.0, 0.0, 5.0)
	tank.global_position = initial_pos
	await get_tree().process_frame
	
	# When: Input UP direction (negative Z in 3D)
	var input_direction = Vector3(0.0, 0.0, -1.0)  # UP = -Z
	tank.set_movement_direction(input_direction)
	await get_tree().process_frame
	
	# Then: Tank should be at Z-0.5 (one tile forward/up)
	var expected_pos = Vector3(5.0, 0.0, 4.5)
	assert_almost_eq(tank.global_position.x, expected_pos.x, 0.01,
		"Tank X should not change when moving UP")
	assert_almost_eq(tank.global_position.z, expected_pos.z, 0.01,
		"Tank Z should decrease by TILE_SIZE when moving UP")
	assert_eq(tank.facing_direction, Tank3D.Direction.UP,
		"Tank should face UP direction")

## SCENARIO: Player presses DOWN arrow key
## GIVEN a tank at position (5.0, 0, 5.0)
## WHEN player presses DOWN (positive Z direction)
## THEN tank should move to (5.0, 0, 5.5) - moving BACKWARD in +Z direction
func test_given_tank_at_center_when_input_down_then_moves_positive_z():
	# Given: Tank at center position
	var initial_pos = Vector3(5.0, 0.0, 5.0)
	tank.global_position = initial_pos
	await get_tree().process_frame
	
	# When: Input DOWN direction (positive Z in 3D)
	var input_direction = Vector3(0.0, 0.0, 1.0)  # DOWN = +Z
	tank.set_movement_direction(input_direction)
	await get_tree().process_frame
	
	# Then: Tank should be at Z+0.5 (one tile backward/down)
	var expected_pos = Vector3(5.0, 0.0, 5.5)
	assert_almost_eq(tank.global_position.x, expected_pos.x, 0.01,
		"Tank X should not change when moving DOWN")
	assert_almost_eq(tank.global_position.z, expected_pos.z, 0.01,
		"Tank Z should increase by TILE_SIZE when moving DOWN")
	assert_eq(tank.facing_direction, Tank3D.Direction.DOWN,
		"Tank should face DOWN direction")

## SCENARIO: Game controller converts input to 3D direction
## GIVEN player uses Input.get_vector() for arrow keys
## WHEN player presses RIGHT arrow (move_right action)
## THEN Input.get_vector returns (1.0, 0.0) which maps to Vector3(1.0, 0, 0.0)
func test_given_input_vector_when_right_pressed_then_creates_positive_x_direction():
	# This test documents how Input.get_vector() works
	# Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# Returns Vector2 where:
	#   x = move_right (1.0) - move_left (-1.0)
	#   y = move_down (1.0) - move_up (-1.0)
	
	# Simulated: Player presses RIGHT key only
	# input_dir = Vector2(1.0, 0.0)  # x=1.0 from move_right
	
	# Game controller converts to 3D:
	# direction_3d = Vector3(input_dir.x, 0, input_dir.y)
	# direction_3d = Vector3(1.0, 0, 0.0)  # Should be +X (RIGHT)
	
	var simulated_input = Vector2(1.0, 0.0)  # RIGHT pressed
	var direction_3d = Vector3(simulated_input.x, 0, simulated_input.y)
	
	assert_almost_eq(direction_3d.x, 1.0, 0.01, "RIGHT input should map to +X")
	assert_almost_eq(direction_3d.z, 0.0, 0.01, "RIGHT input should not affect Z")
	
	# Verify this creates the correct direction enum
	tank.set_movement_direction(direction_3d)
	await get_tree().process_frame
	
	assert_eq(tank.facing_direction, Tank3D.Direction.RIGHT,
		"Vector3(1,0,0) should convert to Direction.RIGHT")

## SCENARIO: Game controller converts input to 3D direction
## GIVEN player uses Input.get_vector() for arrow keys
## WHEN player presses LEFT arrow (move_left action)
## THEN Input.get_vector returns (-1.0, 0.0) which maps to Vector3(-1.0, 0, 0.0)
func test_given_input_vector_when_left_pressed_then_creates_negative_x_direction():
	# Simulated: Player presses LEFT key only
	# input_dir = Vector2(-1.0, 0.0)  # x=-1.0 from move_left
	
	# Game controller converts to 3D:
	# direction_3d = Vector3(input_dir.x, 0, input_dir.y)
	# direction_3d = Vector3(-1.0, 0, 0.0)  # Should be -X (LEFT)
	
	var simulated_input = Vector2(-1.0, 0.0)  # LEFT pressed
	var direction_3d = Vector3(simulated_input.x, 0, simulated_input.y)
	
	assert_almost_eq(direction_3d.x, -1.0, 0.01, "LEFT input should map to -X")
	assert_almost_eq(direction_3d.z, 0.0, 0.01, "LEFT input should not affect Z")
	
	# Verify this creates the correct direction enum
	tank.set_movement_direction(direction_3d)
	await get_tree().process_frame
	
	assert_eq(tank.facing_direction, Tank3D.Direction.LEFT,
		"Vector3(-1,0,0) should convert to Direction.LEFT")

## SCENARIO: Verify all four cardinal directions map correctly end-to-end
## GIVEN a tank at center position
## WHEN each direction input is applied
## THEN tank position changes by exactly one tile in the correct direction
func test_given_tank_when_all_cardinal_inputs_then_position_changes_correctly():
	var start_pos = Vector3(5.0, 0.0, 5.0)
	
	# Test RIGHT: Should move +X
	tank.global_position = start_pos
	tank.set_movement_direction(Vector3(1.0, 0.0, 0.0))
	await get_tree().process_frame
	assert_almost_eq(tank.global_position.x, 5.5, 0.01, "RIGHT should move +X")
	assert_almost_eq(tank.global_position.z, 5.0, 0.01, "RIGHT should not move Z")
	
	# Test LEFT: Should move -X
	tank.global_position = start_pos
	tank.set_movement_direction(Vector3(-1.0, 0.0, 0.0))
	await get_tree().process_frame
	assert_almost_eq(tank.global_position.x, 4.5, 0.01, "LEFT should move -X")
	assert_almost_eq(tank.global_position.z, 5.0, 0.01, "LEFT should not move Z")
	
	# Test UP: Should move -Z
	tank.global_position = start_pos
	tank.set_movement_direction(Vector3(0.0, 0.0, -1.0))
	await get_tree().process_frame
	assert_almost_eq(tank.global_position.x, 5.0, 0.01, "UP should not move X")
	assert_almost_eq(tank.global_position.z, 4.5, 0.01, "UP should move -Z")
	
	# Test DOWN: Should move +Z
	tank.global_position = start_pos
	tank.set_movement_direction(Vector3(0.0, 0.0, 1.0))
	await get_tree().process_frame
	assert_almost_eq(tank.global_position.x, 5.0, 0.01, "DOWN should not move X")
	assert_almost_eq(tank.global_position.z, 5.5, 0.01, "DOWN should move +Z")
