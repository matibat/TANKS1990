extends GutTest
## Unit tests for 3D movement system with velocity-based physics

var tank: Tank3D
var Vector3Helpers = preload("res://src/utils/vector3_helpers.gd")

func before_each():
	tank = Tank3D.new()
	add_child_autofree(tank)
	await get_tree().process_frame

func after_each():
	if tank and is_instance_valid(tank):
		tank.queue_free()
	tank = null

# === 4-Directional Grid-Aligned Movement Tests ===

func test_move_up_direction_updates_position():
	var start_pos = Vector3(5.0, 0.0, 5.0)
	tank.global_position = start_pos
	
	tank.move_in_direction(Tank3D.Direction.UP)
	await get_tree().process_frame
	
	assert_eq(tank.facing_direction, Tank3D.Direction.UP, "Should face UP")
	assert_lt(tank.global_position.z, start_pos.z, "Should move in -Z direction (UP)")

func test_move_down_direction_updates_position():
	var start_pos = Vector3(5.0, 0.0, 5.0)
	tank.global_position = start_pos
	
	tank.move_in_direction(Tank3D.Direction.DOWN)
	await get_tree().process_frame
	
	assert_eq(tank.facing_direction, Tank3D.Direction.DOWN, "Should face DOWN")
	assert_gt(tank.global_position.z, start_pos.z, "Should move in +Z direction (DOWN)")

func test_move_left_direction_updates_position():
	var start_pos = Vector3(5.0, 0.0, 5.0)
	tank.global_position = start_pos
	
	tank.move_in_direction(Tank3D.Direction.LEFT)
	await get_tree().process_frame
	
	assert_eq(tank.facing_direction, Tank3D.Direction.LEFT, "Should face LEFT")
	assert_lt(tank.global_position.x, start_pos.x, "Should move in -X direction (LEFT)")

func test_move_right_direction_updates_position():
	var start_pos = Vector3(5.0, 0.0, 5.0)
	tank.global_position = start_pos
	
	tank.move_in_direction(Tank3D.Direction.RIGHT)
	await get_tree().process_frame
	
	assert_eq(tank.facing_direction, Tank3D.Direction.RIGHT, "Should face RIGHT")
	assert_gt(tank.global_position.x, start_pos.x, "Should move in +X direction (RIGHT)")

# === Velocity Clamping Tests ===

func test_velocity_clamped_to_max_speed():
	# Set high target velocity
	tank.velocity = Vector3(100.0, 0.0, 100.0)
	tank.base_speed = 5.0
	
	# Process physics to apply clamping
	tank._physics_process(0.016)
	
	# Velocity should be clamped
	assert_lte(abs(tank.velocity.x), tank.base_speed, "X velocity should be <= max_speed")
	assert_lte(abs(tank.velocity.z), tank.base_speed, "Z velocity should be <= max_speed")

func test_velocity_clamped_prevents_tunneling():
	tank.base_speed = 5.0
	tank.velocity = Vector3(50.0, 0.0, 50.0)  # Excessive velocity
	
	tank._physics_process(0.016)
	
	# Should not exceed reasonable limits
	var max_distance = tank.base_speed * 0.016  # Max travel per frame
	assert_lte(tank.velocity.length(), tank.base_speed * 1.5, "Velocity should be reasonably bounded")

# === Acceleration/Deceleration Tests ===

func test_acceleration_from_zero():
	tank.velocity = Vector3.ZERO
	tank.base_speed = 5.0
	var target_velocity = Vector3(5.0, 0.0, 0.0)
	
	# Simulate gradual acceleration
	var acceleration = 10.0  # units/s^2
	var delta = 0.016
	
	for i in range(10):
		tank.velocity = tank.velocity.move_toward(target_velocity, acceleration * delta)
	
	assert_almost_eq(tank.velocity.x, target_velocity.x, 0.1, "Should accelerate to target velocity")

func test_deceleration_to_zero():
	tank.velocity = Vector3(5.0, 0.0, 0.0)
	var target_velocity = Vector3.ZERO
	
	# Simulate gradual deceleration
	var deceleration = 10.0  # units/s^2
	var delta = 0.016
	
	for i in range(10):
		tank.velocity = tank.velocity.move_toward(target_velocity, deceleration * delta)
	
	assert_almost_eq(tank.velocity.x, 0.0, 0.1, "Should decelerate to zero")

# === Collision Sliding Tests ===

func test_move_and_slide_basic():
	tank.velocity = Vector3(5.0, 0.0, 0.0)
	
	# move_and_slide should return updated velocity after collisions
	var result_velocity = tank.move_and_slide()
	
	assert_true(is_instance_valid(tank), "Tank should still be valid")
	assert_true(result_velocity is Vector3, "Should return Vector3")

func test_move_and_slide_with_floor_normal():
	tank.velocity = Vector3(5.0, -1.0, 0.0)  # Trying to move down
	
	var result_velocity = tank.move_and_slide()
	
	# Y component should be constrained by ground plane
	assert_almost_eq(tank.global_position.y, 0.0, 0.1, "Should stay on ground plane")

# === Quantized Positioning Tests ===

func test_position_quantized_after_movement():
	tank.global_position = Vector3(5.123456, 0.0, 7.987654)
	
	tank.move_in_direction(Tank3D.Direction.RIGHT)
	await get_tree().process_frame
	
	# Position should be quantized to 0.001 precision
	var pos = tank.global_position
	assert_almost_eq(pos.x, round(pos.x * 1000.0) / 1000.0, 0.0001, "X should be quantized")
	assert_almost_eq(pos.z, round(pos.z * 1000.0) / 1000.0, 0.0001, "Z should be quantized")

func test_position_stays_on_ground_plane():
	tank.global_position = Vector3(5.0, 0.0, 5.0)
	
	for dir in [Tank3D.Direction.UP, Tank3D.Direction.DOWN, Tank3D.Direction.LEFT, Tank3D.Direction.RIGHT]:
		tank.move_in_direction(dir)
		await get_tree().process_frame
	
	assert_almost_eq(tank.global_position.y, 0.0, 0.01, "Tank should stay at Y=0")

# === Movement State Tests ===

func test_movement_changes_state_to_moving():
	tank.current_state = Tank3D.State.IDLE
	
	tank.move_in_direction(Tank3D.Direction.UP)
	await get_tree().process_frame
	
	assert_eq(tank.current_state, Tank3D.State.MOVING, "Should change to MOVING state")

func test_stop_movement_changes_state_to_idle():
	tank.current_state = Tank3D.State.MOVING
	tank.velocity = Vector3(5.0, 0.0, 0.0)
	
	tank.stop_movement()
	
	assert_eq(tank.current_state, Tank3D.State.IDLE, "Should change to IDLE state")
	assert_eq(tank.velocity, Vector3.ZERO, "Velocity should be zero")

# === Grid Alignment Tests ===

func test_discrete_movement_snaps_to_tile_centers():
	tank.global_position = Vector3(5.0, 0.0, 5.0)
	
	tank.move_in_direction(Tank3D.Direction.UP)
	await get_tree().process_frame
	
	# Should move exactly one tile (0.5 units)
	var expected_pos = Vector3(5.0, 0.0, 4.5)
	assert_almost_eq(tank.global_position.x, expected_pos.x, 0.01, "X should stay aligned")
	assert_almost_eq(tank.global_position.z, expected_pos.z, 0.01, "Z should be at tile center")

# === Boundary Clamping Tests ===

func test_position_clamped_to_map_bounds():
	tank.global_position = Vector3(0.0, 0.0, 0.0)  # Near edge
	
	tank.move_in_direction(Tank3D.Direction.LEFT)
	await get_tree().process_frame
	
	# Should not go beyond minimum boundary
	assert_gte(tank.global_position.x, 0.0, "Should not go below X=0")
	assert_gte(tank.global_position.z, 0.0, "Should not go below Z=0")

func test_position_clamped_to_max_bounds():
	tank.global_position = Vector3(12.5, 0.0, 12.5)  # Near max edge
	
	tank.move_in_direction(Tank3D.Direction.RIGHT)
	await get_tree().process_frame
	
	# Should not exceed maximum boundary
	assert_lte(tank.global_position.x, 13.0, "Should not exceed X=13.0")

# === Performance Tests ===

func test_movement_processing_is_efficient():
	var start_time = Time.get_ticks_usec()
	
	for i in range(100):
		tank.move_in_direction(Tank3D.Direction.UP)
		tank._physics_process(0.016)
	
	var elapsed = Time.get_ticks_usec() - start_time
	var avg_time_ms = elapsed / 1000.0 / 100.0
	
	# Should process movement in < 0.1ms per frame on average
	assert_lt(avg_time_ms, 0.1, "Movement should be efficient (<0.1ms)")
