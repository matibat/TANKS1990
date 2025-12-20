extends GutTest
## BDD Tests for Issue #1: Left/Right Controls Crossed
## ISSUE: Pressing left goes right, pressing right goes left
##
## Expected Behavior:
## - Pressing LEFT arrow should move tank LEFT (-X direction) and face LEFT (270° rotation)
## - Pressing RIGHT arrow should move tank RIGHT (+X direction) and face RIGHT (90° rotation)
##
## Root Cause Investigation:
## - Check _direction_to_vector() mapping for LEFT/RIGHT
## - Check _update_rotation() for LEFT/RIGHT angles
## - Check input handling in game_controller_3d.gd

const Tank3D = preload("res://src/entities/tank3d.gd")
const GameController3D = preload("res://scenes3d/game_controller_3d.gd")

var tank: Tank3D
var controller: GameController3D

func before_each():
	# Create tank at center position
	tank = Tank3D.new()
	add_child(tank)
	tank.global_position = Vector3(6.5, 0, 6.5)
	tank.tank_type = Tank3D.TankType.PLAYER
	tank.is_player = true
	await get_tree().process_frame

func after_each():
	if tank:
		tank.queue_free()
	if controller:
		controller.queue_free()

# ========================================
# RED TESTS: These should FAIL initially
# ========================================

func test_pressing_left_moves_tank_in_negative_x_direction():
	"""BDD: GIVEN tank at center WHEN move_in_direction(LEFT) THEN X position decreases"""
	var start_x = tank.global_position.x
	
	# Act: Move left
	tank.move_in_direction(Tank3D.Direction.LEFT)
	await get_tree().physics_frame
	
	# Assert: Tank moved left (negative X)
	var new_x = tank.global_position.x
	assert_lt(new_x, start_x, "LEFT should decrease X position (move left), but X changed from " + str(start_x) + " to " + str(new_x))

func test_pressing_right_moves_tank_in_positive_x_direction():
	"""BDD: GIVEN tank at center WHEN move_in_direction(RIGHT) THEN X position increases"""
	var start_x = tank.global_position.x
	
	# Act: Move right
	tank.move_in_direction(Tank3D.Direction.RIGHT)
	await get_tree().physics_frame
	
	# Assert: Tank moved right (positive X)
	var new_x = tank.global_position.x
	assert_gt(new_x, start_x, "RIGHT should increase X position (move right), but X changed from " + str(start_x) + " to " + str(new_x))

func test_left_direction_enum_maps_to_negative_x_vector():
	"""BDD: GIVEN Direction.LEFT WHEN converted to vector THEN returns Vector3(-1, 0, 0)"""
	var direction_vec = tank._direction_to_vector(Tank3D.Direction.LEFT)
	
	assert_eq(direction_vec.x, -1.0, "LEFT should map to -X (x=-1)")
	assert_eq(direction_vec.y, 0.0, "LEFT should have no Y component")
	assert_eq(direction_vec.z, 0.0, "LEFT should have no Z component")

func test_right_direction_enum_maps_to_positive_x_vector():
	"""BDD: GIVEN Direction.RIGHT WHEN converted to vector THEN returns Vector3(1, 0, 0)"""
	var direction_vec = tank._direction_to_vector(Tank3D.Direction.RIGHT)
	
	assert_eq(direction_vec.x, 1.0, "RIGHT should map to +X (x=1)")
	assert_eq(direction_vec.y, 0.0, "RIGHT should have no Y component")
	assert_eq(direction_vec.z, 0.0, "RIGHT should have no Z component")

func test_facing_left_rotates_to_270_degrees():
	"""BDD: GIVEN tank facing LEFT WHEN rotation updated THEN rotation.y = 270° (3π/2)"""
	tank.facing_direction = Tank3D.Direction.LEFT
	tank._update_rotation()
	
	var expected_rotation = 3 * PI / 2  # 270 degrees
	assert_almost_eq(tank.rotation.y, expected_rotation, 0.01, 
		"LEFT facing should be 270° (3π/2), got " + str(tank.rotation.y))

func test_facing_right_rotates_to_90_degrees():
	"""BDD: GIVEN tank facing RIGHT WHEN rotation updated THEN rotation.y = 90° (π/2)"""
	tank.facing_direction = Tank3D.Direction.RIGHT
	tank._update_rotation()
	
	var expected_rotation = PI / 2  # 90 degrees
	assert_almost_eq(tank.rotation.y, expected_rotation, 0.01, 
		"RIGHT facing should be 90° (π/2), got " + str(tank.rotation.y))

func test_move_left_one_tile_exactly_half_unit():
	"""BDD: GIVEN tank at X=6.5 WHEN move LEFT THEN moves to X=6.0 (exactly 0.5 units)"""
	tank.global_position = Vector3(6.5, 0, 6.5)
	
	tank.move_in_direction(Tank3D.Direction.LEFT)
	await get_tree().physics_frame
	
	assert_almost_eq(tank.global_position.x, 6.0, 0.01, 
		"After moving LEFT from 6.5, should be at 6.0")

func test_move_right_one_tile_exactly_half_unit():
	"""BDD: GIVEN tank at X=6.5 WHEN move RIGHT THEN moves to X=7.0 (exactly 0.5 units)"""
	tank.global_position = Vector3(6.5, 0, 6.5)
	
	tank.move_in_direction(Tank3D.Direction.RIGHT)
	await get_tree().physics_frame
	
	assert_almost_eq(tank.global_position.x, 7.0, 0.01, 
		"After moving RIGHT from 6.5, should be at 7.0")

func test_input_vector_negative_x_converts_to_left_direction():
	"""BDD: GIVEN input Vector3(-1, 0, 0) WHEN set_movement_direction THEN tank faces LEFT"""
	tank.set_movement_direction(Vector3(-1, 0, 0))
	await get_tree().physics_frame
	
	assert_eq(tank.facing_direction, Tank3D.Direction.LEFT, 
		"Input (-1, 0, 0) should result in LEFT facing")

func test_input_vector_positive_x_converts_to_right_direction():
	"""BDD: GIVEN input Vector3(1, 0, 0) WHEN set_movement_direction THEN tank faces RIGHT"""
	tank.set_movement_direction(Vector3(1, 0, 0))
	await get_tree().physics_frame
	
	assert_eq(tank.facing_direction, Tank3D.Direction.RIGHT, 
		"Input (1, 0, 0) should result in RIGHT facing")

func test_game_controller_left_arrow_generates_negative_x_input():
	"""BDD: GIVEN LEFT arrow pressed WHEN input processed THEN generates Vector3(-1, 0, 0)"""
	controller = GameController3D.new()
	add_child(controller)
	controller.player_tank = tank
	await get_tree().process_frame
	
	# Simulate left arrow key
	Input.action_press("move_left")
	await get_tree().physics_frame
	
	# The input_dir in _handle_player_input should have negative X
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	assert_lt(input_dir.x, 0, "LEFT arrow should produce negative X in input_dir")
	
	Input.action_release("move_left")

func test_game_controller_right_arrow_generates_positive_x_input():
	"""BDD: GIVEN RIGHT arrow pressed WHEN input processed THEN generates Vector3(1, 0, 0)"""
	controller = GameController3D.new()
	add_child(controller)
	controller.player_tank = tank
	await get_tree().process_frame
	
	# Simulate right arrow key
	Input.action_press("move_right")
	await get_tree().physics_frame
	
	# The input_dir in _handle_player_input should have positive X
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	assert_gt(input_dir.x, 0, "RIGHT arrow should produce positive X in input_dir")
	
	Input.action_release("move_right")

func test_left_and_right_are_opposites():
	"""BDD: GIVEN LEFT and RIGHT vectors WHEN compared THEN they are exact opposites"""
	var left_vec = tank._direction_to_vector(Tank3D.Direction.LEFT)
	var right_vec = tank._direction_to_vector(Tank3D.Direction.RIGHT)
	
	# They should be negatives of each other
	assert_eq(left_vec.x + right_vec.x, 0.0, "LEFT and RIGHT X components should sum to 0")
	assert_eq(left_vec, -right_vec, "LEFT should be exact opposite of RIGHT")

# ========================================
# SCENARIO TESTS: Real gameplay scenarios
# ========================================

func test_scenario_tank_moves_left_three_times():
	"""SCENARIO: Player repeatedly presses LEFT arrow"""
	tank.global_position = Vector3(7.0, 0, 6.5)
	var expected_positions = [6.5, 6.0, 5.5]
	
	for i in range(3):
		tank.move_in_direction(Tank3D.Direction.LEFT)
		await get_tree().physics_frame
		
		assert_almost_eq(tank.global_position.x, expected_positions[i], 0.01,
			"After " + str(i+1) + " LEFT moves, X should be " + str(expected_positions[i]))

func test_scenario_tank_moves_right_three_times():
	"""SCENARIO: Player repeatedly presses RIGHT arrow"""
	tank.global_position = Vector3(5.0, 0, 6.5)
	var expected_positions = [5.5, 6.0, 6.5]
	
	for i in range(3):
		tank.move_in_direction(Tank3D.Direction.RIGHT)
		await get_tree().physics_frame
		
		assert_almost_eq(tank.global_position.x, expected_positions[i], 0.01,
			"After " + str(i+1) + " RIGHT moves, X should be " + str(expected_positions[i]))

func test_scenario_tank_moves_left_then_right_returns_to_start():
	"""SCENARIO: Player presses LEFT then RIGHT - should return to original position"""
	tank.global_position = Vector3(6.5, 0, 6.5)
	var start_x = tank.global_position.x
	
	# Move left
	tank.move_in_direction(Tank3D.Direction.LEFT)
	await get_tree().physics_frame
	
	# Move right (should undo)
	tank.move_in_direction(Tank3D.Direction.RIGHT)
	await get_tree().physics_frame
	
	assert_almost_eq(tank.global_position.x, start_x, 0.01,
		"Moving LEFT then RIGHT should return to start position")
