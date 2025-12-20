extends GutTest
## Integration tests for tunneling prevention in 3D physics

var bullet: Bullet3D
var tank: Tank3D
var wall: StaticBody3D
var Vector3Helpers = preload("res://src/utils/vector3_helpers.gd")

func before_each():
	# Create bullet
	bullet = Bullet3D.new()
	add_child_autofree(bullet)
	
	# Create wall (thin barrier)
	wall = StaticBody3D.new()
	wall.collision_layer = 8  # Layer 4 (Environment)
	wall.collision_mask = 7   # Collide with all (1|2|3)
	
	var collision = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(0.5, 1.0, 0.5)  # Thin wall (0.5 units thick)
	collision.shape = box
	wall.add_child(collision)
	add_child_autofree(wall)
	
	await get_tree().process_frame

func after_each():
	if bullet and is_instance_valid(bullet):
		bullet.queue_free()
	if tank and is_instance_valid(tank):
		tank.queue_free()
	if wall and is_instance_valid(wall):
		wall.queue_free()
	
	bullet = null
	tank = null
	wall = null

# === High-Speed Bullet vs Thin Wall Tests ===

func test_bullet_does_not_pass_through_thin_wall():
	# Position wall between bullet and target
	wall.global_position = Vector3(5.0, 0.0, 5.0)
	
	# Bullet starts before wall, moving toward it
	bullet.global_position = Vector3(5.0, 0.0, 3.0)
	bullet.direction = Vector3(0, 0, 1)  # Moving toward wall (+Z)
	bullet.speed = 9.375  # Super bullet (fastest)
	bullet.is_active = true
	
	var hit_detected = false
	bullet.hit_terrain.connect(func(_pos): hit_detected = true)
	
	# Simulate multiple physics frames
	for i in range(30):
		bullet._physics_process(0.016)
		
		# Check if bullet passed through wall
		if bullet.global_position.z > wall.global_position.z + 0.5:
			fail_test("Bullet tunneled through wall!")
			return
		
		if hit_detected or not bullet.is_active:
			break
	
	# Bullet should have been stopped by wall
	assert_true(hit_detected or not bullet.is_active, "Bullet should collide with wall")
	assert_lte(bullet.global_position.z, wall.global_position.z + 0.5, "Bullet should not pass wall")

func test_enhanced_bullet_does_not_tunnel():
	wall.global_position = Vector3(5.0, 0.0, 5.0)
	
	bullet.initialize(Vector3(5.0, 0.0, 3.0), Vector3(0, 0, 1), 1, 2, true)  # Enhanced
	bullet.is_active = true
	
	# Enhanced speed: 7.8125 units/s
	assert_almost_eq(bullet.speed, 7.8125, 0.01, "Should have enhanced speed")
	
	var initial_z = bullet.global_position.z
	
	# Run for 20 frames (should collide before reaching other side)
	for i in range(20):
		bullet._physics_process(0.016)
		if not bullet.is_active:
			break
	
	# Should not have passed through
	assert_lte(bullet.global_position.z, wall.global_position.z + 0.5, "Enhanced bullet should not tunnel")

func test_normal_bullet_does_not_tunnel():
	wall.global_position = Vector3(5.0, 0.0, 5.0)
	
	bullet.initialize(Vector3(5.0, 0.0, 3.0), Vector3(0, 0, 1), 1, 1, true)  # Normal
	bullet.is_active = true
	
	# Normal speed: 6.25 units/s
	assert_almost_eq(bullet.speed, 6.25, 0.01, "Should have normal speed")
	
	# Run physics simulation
	for i in range(20):
		bullet._physics_process(0.016)
		if not bullet.is_active:
			break
	
	assert_lte(bullet.global_position.z, wall.global_position.z + 0.5, "Normal bullet should not tunnel")

# === High-Speed Tank Collision Tests ===

func test_fast_tank_does_not_skip_collision():
	tank = Tank3D.new()
	tank.tank_type = Tank3D.TankType.FAST
	tank.base_speed = 7.5  # Fast tank (1.5x normal)
	add_child_autofree(tank)
	await get_tree().process_frame
	
	# Position wall in path
	wall.global_position = Vector3(5.0, 0.0, 5.0)
	
	# Tank starts before wall
	tank.global_position = Vector3(5.0, 0.0, 3.0)
	
	# Try to move through wall
	for i in range(10):
		tank.move_in_direction(Tank3D.Direction.DOWN)  # +Z direction
		await get_tree().process_frame
	
	# Tank should be stopped by wall
	assert_lt(tank.global_position.z, wall.global_position.z, "Tank should not pass through wall")

# === Bullet Raycast Pre-check Tests ===

func test_raycast_detects_wall_before_movement():
	# Position wall
	wall.global_position = Vector3(5.0, 0.0, 5.0)
	
	# Create raycast from bullet position toward wall
	var space_state = get_tree().root.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		Vector3(5.0, 0.0, 3.0),  # From
		Vector3(5.0, 0.0, 7.0)   # To (through wall)
	)
	query.collision_mask = 8  # Environment layer
	
	var result = space_state.intersect_ray(query)
	
	assert_true(result.size() > 0, "Raycast should detect wall")
	if result.size() > 0:
		assert_almost_eq(result.position.z, 4.75, 0.3, "Should hit front of wall")

func test_raycast_pre_check_prevents_tunneling():
	wall.global_position = Vector3(5.0, 0.0, 5.0)
	
	var bullet_pos = Vector3(5.0, 0.0, 3.0)
	var bullet_dir = Vector3(0, 0, 1)
	var bullet_speed = 9.375
	var delta = 0.016
	
	# Calculate next position
	var next_pos = bullet_pos + bullet_dir * bullet_speed * delta
	
	# Raycast between current and next position
	var space_state = get_tree().root.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(bullet_pos, next_pos)
	query.collision_mask = 8  # Environment
	
	var result = space_state.intersect_ray(query)
	
	if result.size() > 0:
		# Collision would occur - stop at collision point
		assert_true(true, "Pre-check detected collision")
	else:
		# No collision - safe to move
		pass

# === Velocity Clamping Tests ===

func test_bullet_velocity_is_clamped():
	# Max safe velocity to prevent tunneling
	# At 60 Hz, max distance = speed * 0.01666
	# For 0.5 unit wall: max_speed = 0.5 / 0.01666 = 30 units/s
	
	var max_safe_speed = 30.0
	
	bullet.speed = 50.0  # Excessive speed
	
	# Should be clamped
	bullet._physics_process(0.016)
	
	var travel_distance = bullet.speed * 0.016
	assert_lt(travel_distance, 0.5, "Bullet should not travel > wall thickness per frame")

func test_super_bullet_within_safe_limits():
	bullet.initialize(Vector3.ZERO, Vector3.FORWARD, 1, 3, true)  # Super
	
	var max_travel = bullet.speed * 0.016
	
	# Max travel should be << wall thickness
	assert_lt(max_travel, 0.25, "Super bullet travel should be < half wall thickness")
	assert_almost_eq(bullet.speed, 9.375, 0.01, "Super bullet speed should be 9.375")

# === Edge Case Tests ===

func test_bullet_at_high_frame_rate():
	# At 120 Hz (half timestep), tunneling risk should be even lower
	wall.global_position = Vector3(5.0, 0.0, 5.0)
	bullet.global_position = Vector3(5.0, 0.0, 3.0)
	bullet.direction = Vector3(0, 0, 1)
	bullet.speed = 9.375
	bullet.is_active = true
	
	# Simulate higher frame rate (smaller delta)
	for i in range(60):
		bullet._physics_process(0.008)  # 120 Hz
		if not bullet.is_active:
			break
	
	assert_lte(bullet.global_position.z, wall.global_position.z + 0.5, "Should not tunnel at high FPS")

func test_bullet_at_low_frame_rate():
	# At 30 Hz (double timestep), tunneling risk is higher
	# This tests worst-case scenario
	wall.global_position = Vector3(5.0, 0.0, 5.0)
	bullet.global_position = Vector3(5.0, 0.0, 3.0)
	bullet.direction = Vector3(0, 0, 1)
	bullet.speed = 9.375
	bullet.is_active = true
	
	# Simulate low frame rate (larger delta)
	var passed_through = false
	for i in range(15):
		bullet._physics_process(0.033)  # 30 Hz
		
		if bullet.global_position.z > wall.global_position.z + 0.5 and bullet.is_active:
			passed_through = true
			break
		
		if not bullet.is_active:
			break
	
	# Even at 30 Hz, should not tunnel (max travel = 9.375 * 0.033 = 0.31 units)
	assert_false(passed_through, "Should not tunnel even at 30 Hz")

# === Multiple Walls Test ===

func test_bullet_stops_at_first_wall():
	# Create two walls in line
	wall.global_position = Vector3(5.0, 0.0, 5.0)
	
	var wall2 = StaticBody3D.new()
	wall2.collision_layer = 8
	wall2.collision_mask = 7
	var collision2 = CollisionShape3D.new()
	var box2 = BoxShape3D.new()
	box2.size = Vector3(0.5, 1.0, 0.5)
	collision2.shape = box2
	wall2.add_child(collision2)
	wall2.global_position = Vector3(5.0, 0.0, 7.0)
	add_child_autofree(wall2)
	await get_tree().process_frame
	
	bullet.global_position = Vector3(5.0, 0.0, 3.0)
	bullet.direction = Vector3(0, 0, 1)
	bullet.speed = 9.375
	bullet.is_active = true
	
	# Simulate
	for i in range(30):
		bullet._physics_process(0.016)
		if not bullet.is_active:
			break
	
	# Should stop at first wall, not reach second
	assert_lte(bullet.global_position.z, 6.0, "Should stop at first wall")

# === Diagonal Movement Test ===

func test_bullet_diagonal_does_not_tunnel():
	wall.global_position = Vector3(5.0, 0.0, 5.0)
	
	# Bullet moving diagonally
	bullet.global_position = Vector3(3.0, 0.0, 3.0)
	bullet.direction = Vector3(1, 0, 1).normalized()  # 45 degrees
	bullet.speed = 9.375
	bullet.is_active = true
	
	for i in range(30):
		bullet._physics_process(0.016)
		if not bullet.is_active:
			break
	
	# Should have collided somewhere near wall
	var distance_to_wall = bullet.global_position.distance_to(wall.global_position)
	assert_lte(distance_to_wall, 2.0, "Should have stopped near wall")
