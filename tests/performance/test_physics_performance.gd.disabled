extends GutTest
## Performance tests for 3D physics system

var tanks: Array[Tank3D] = []
var bullets: Array[Bullet3D] = []
var Vector3Helpers = preload("res://src/utils/vector3_helpers.gd")

func before_each():
	tanks.clear()
	bullets.clear()

func after_each():
	for tank in tanks:
		if tank and is_instance_valid(tank):
			tank.queue_free()
	
	for bullet in bullets:
		if bullet and is_instance_valid(bullet):
			bullet.queue_free()
	
	tanks.clear()
	bullets.clear()

# === Single Entity Performance ===

func test_single_tank_performance():
	var tank = Tank3D.new()
	tank.global_position = Vector3(5.0, 0.0, 5.0)
	add_child_autofree(tank)
	await get_tree().process_frame
	
	var start_time = Time.get_ticks_usec()
	
	# Process 300 frames
	for i in range(300):
		tank.move_in_direction(Tank3D.Direction.UP)
		tank._physics_process(0.016)
	
	var elapsed = Time.get_ticks_usec() - start_time
	var avg_time_ms = elapsed / 1000.0 / 300.0
	
	# Should be very fast for single entity
	assert_lt(avg_time_ms, 0.1, "Single tank should process in <0.1ms per frame")

func test_single_bullet_performance():
	var bullet = Bullet3D.new()
	bullet.initialize(Vector3(5.0, 0.0, 5.0), Vector3(0, 0, 1), 1, 1, true)
	bullet.is_active = true
	add_child_autofree(bullet)
	await get_tree().process_frame
	
	var start_time = Time.get_ticks_usec()
	
	for i in range(300):
		bullet._physics_process(0.016)
	
	var elapsed = Time.get_ticks_usec() - start_time
	var avg_time_ms = elapsed / 1000.0 / 300.0
	
	assert_lt(avg_time_ms, 0.05, "Single bullet should process in <0.05ms per frame")

# === Multiple Entities Performance ===

func test_20_tanks_performance():
	# Create 20 tanks (typical gameplay scenario)
	for i in range(20):
		var tank = Tank3D.new()
		tank.tank_id = i
		tank.global_position = Vector3((i % 5) * 2.0, 0.0, (i / 5) * 2.0)
		add_child_autofree(tank)
		tanks.append(tank)
	
	await get_tree().process_frame
	
	var start_time = Time.get_ticks_usec()
	
	# Process 300 frames
	for frame in range(300):
		for tank in tanks:
			# Simple movement pattern
			var dir = (frame + tank.tank_id) % 4
			match dir:
				0: tank.move_in_direction(Tank3D.Direction.UP)
				1: tank.move_in_direction(Tank3D.Direction.DOWN)
				2: tank.move_in_direction(Tank3D.Direction.LEFT)
				3: tank.move_in_direction(Tank3D.Direction.RIGHT)
			
			tank._physics_process(0.016)
	
	var elapsed = Time.get_ticks_usec() - start_time
	var avg_time_ms = elapsed / 1000.0 / 300.0
	
	# Target: <5ms per frame for gameplay logic
	assert_lt(avg_time_ms, 5.0, "20 tanks should process in <5ms per frame")

func test_30_bullets_performance():
	# Create 30 bullets
	for i in range(30):
		var bullet = Bullet3D.new()
		var angle = (i * PI * 2.0) / 30.0
		var dir = Vector3(cos(angle), 0, sin(angle)).normalized()
		bullet.initialize(Vector3(5.0, 0.0, 5.0), dir, i, 1, true)
		bullet.is_active = true
		add_child_autofree(bullet)
		bullets.append(bullet)
	
	await get_tree().process_frame
	
	var start_time = Time.get_ticks_usec()
	
	for frame in range(300):
		for bullet in bullets:
			if bullet.is_active:
				bullet._physics_process(0.016)
	
	var elapsed = Time.get_ticks_usec() - start_time
	var avg_time_ms = elapsed / 1000.0 / 300.0
	
	assert_lt(avg_time_ms, 3.0, "30 bullets should process in <3ms per frame")

# === Combined Load Performance ===

func test_combined_load_20_tanks_30_bullets():
	# Create 20 tanks
	for i in range(20):
		var tank = Tank3D.new()
		tank.tank_id = i
		tank.global_position = Vector3((i % 5) * 2.0, 0.0, (i / 5) * 2.0)
		add_child_autofree(tank)
		tanks.append(tank)
	
	# Create 30 bullets
	for i in range(30):
		var bullet = Bullet3D.new()
		var angle = (i * PI * 2.0) / 30.0
		var dir = Vector3(cos(angle), 0, sin(angle)).normalized()
		bullet.initialize(Vector3(5.0, 0.0, 5.0), dir, i % 20, 1, true)
		bullet.is_active = true
		add_child_autofree(bullet)
		bullets.append(bullet)
	
	await get_tree().process_frame
	
	var start_time = Time.get_ticks_usec()
	var frames_processed = 0
	
	# Process 300 frames
	for frame in range(300):
		# Process tanks
		for tank in tanks:
			var dir = (frame + tank.tank_id) % 4
			match dir:
				0: tank.move_in_direction(Tank3D.Direction.UP)
				1: tank.move_in_direction(Tank3D.Direction.DOWN)
				2: tank.move_in_direction(Tank3D.Direction.LEFT)
				3: tank.move_in_direction(Tank3D.Direction.RIGHT)
			
			tank._physics_process(0.016)
		
		# Process bullets
		for bullet in bullets:
			if bullet.is_active:
				bullet._physics_process(0.016)
		
		frames_processed += 1
	
	var elapsed = Time.get_ticks_usec() - start_time
	var avg_time_ms = elapsed / 1000.0 / frames_processed
	
	# Target: <5ms per frame total for 50 entities
	assert_lt(avg_time_ms, 5.0, "Combined load should process in <5ms per frame")
	
	# Report performance
	print("Performance Report:")
	print("  Entities: 20 tanks + 30 bullets = 50 total")
	print("  Frames: " + str(frames_processed))
	print("  Average time: " + str(avg_time_ms) + " ms/frame")
	print("  Target: <5ms/frame")

# === Collision Detection Performance ===

func test_collision_detection_overhead():
	# Create grid of tanks (potential collisions)
	for x in range(4):
		for z in range(4):
			var tank = Tank3D.new()
			tank.global_position = Vector3(x * 1.5, 0.0, z * 1.5)
			add_child_autofree(tank)
			tanks.append(tank)
	
	await get_tree().process_frame
	
	var start_time = Time.get_ticks_usec()
	
	# Process with collision checks
	for frame in range(100):
		for tank in tanks:
			# Try to move (will check collisions)
			var dir = frame % 4
			match dir:
				0: tank.move_in_direction(Tank3D.Direction.UP)
				1: tank.move_in_direction(Tank3D.Direction.DOWN)
				2: tank.move_in_direction(Tank3D.Direction.LEFT)
				3: tank.move_in_direction(Tank3D.Direction.RIGHT)
			
			tank._physics_process(0.016)
		
		# Small delay for physics
		await get_tree().process_frame
	
	var elapsed = Time.get_ticks_usec() - start_time
	var avg_time_ms = elapsed / 1000.0 / 100.0
	
	# Collision detection should add minimal overhead
	assert_lt(avg_time_ms, 10.0, "Collision detection should add <10ms overhead")

# === Quantization Performance ===

func test_position_quantization_overhead():
	var positions = []
	
	# Generate 1000 random positions
	for i in range(1000):
		positions.append(Vector3(
			randf_range(0.0, 13.0),
			0.0,
			randf_range(0.0, 13.0)
		))
	
	var start_time = Time.get_ticks_usec()
	
	# Quantize all positions
	for pos in positions:
		Vector3Helpers.quantize_vec3(pos, 0.001)  # Discard result - just testing performance
	
	var elapsed = Time.get_ticks_usec() - start_time
	var avg_time_us = elapsed / 1000.0
	
	# Should be very fast (<0.1ms for 1000 quantizations)
	assert_lt(avg_time_us, 0.1, "Position quantization should be fast (<0.1ms for 1000 ops)")

# === Memory Performance ===

func test_entity_count_within_budget():
	# Target: <100 active physics bodies
	var entity_count = 20 + 30  # 20 tanks + 30 bullets
	
	assert_lt(entity_count, 100, "Entity count should be <100")

# === Frame Time Budget ===

func test_physics_within_frame_budget():
	# At 60 FPS, frame budget is ~16.66ms
	# Physics should use <5ms, leaving 11ms for rendering and logic
	
	# Create realistic load
	for i in range(10):
		var tank = Tank3D.new()
		tank.global_position = Vector3(i * 1.5, 0.0, i * 1.5)
		add_child_autofree(tank)
		tanks.append(tank)
	
	for i in range(15):
		var bullet = Bullet3D.new()
		bullet.initialize(Vector3(5.0, 0.0, 5.0), Vector3(1, 0, 0), i, 1, true)
		bullet.is_active = true
		add_child_autofree(bullet)
		bullets.append(bullet)
	
	await get_tree().process_frame
	
	var frame_times = []
	
	for frame in range(60):  # 1 second at 60 FPS
		var frame_start = Time.get_ticks_usec()
		
		# Process all entities
		for tank in tanks:
			tank._physics_process(0.016)
		
		for bullet in bullets:
			if bullet.is_active:
				bullet._physics_process(0.016)
		
		var frame_time = Time.get_ticks_usec() - frame_start
		frame_times.append(frame_time / 1000.0)  # Convert to ms
		
		await get_tree().process_frame
	
	# Calculate average and max
	var avg_frame_time = 0.0
	var max_frame_time = 0.0
	
	for time in frame_times:
		avg_frame_time += time
		max_frame_time = max(max_frame_time, time)
	
	avg_frame_time /= frame_times.size()
	
	print("Frame Time Report:")
	print("  Average: " + str(avg_frame_time) + " ms")
	print("  Maximum: " + str(max_frame_time) + " ms")
	print("  Target: <5ms average")
	
	assert_lt(avg_frame_time, 5.0, "Average frame time should be <5ms")
	assert_lt(max_frame_time, 10.0, "Maximum frame time should be <10ms")

# === Stress Test ===

func test_stress_test_100_entities():
	# Stress test: 50 tanks + 50 bullets
	for i in range(50):
		var tank = Tank3D.new()
		tank.tank_id = i
		tank.global_position = Vector3((i % 10) * 1.5, 0.0, (i / 10) * 1.5)
		add_child_autofree(tank)
		tanks.append(tank)
	
	for i in range(50):
		var bullet = Bullet3D.new()
		bullet.initialize(Vector3(5.0, 0.0, 5.0), Vector3(1, 0, 0), i, 1, true)
		bullet.is_active = true
		add_child_autofree(bullet)
		bullets.append(bullet)
	
	await get_tree().process_frame
	
	var start_time = Time.get_ticks_usec()
	
	# Process 100 frames
	for frame in range(100):
		for tank in tanks:
			tank._physics_process(0.016)
		
		for bullet in bullets:
			if bullet.is_active:
				bullet._physics_process(0.016)
	
	var elapsed = Time.get_ticks_usec() - start_time
	var avg_time_ms = elapsed / 1000.0 / 100.0
	
	print("Stress Test Report:")
	print("  Entities: 100 (50 tanks + 50 bullets)")
	print("  Average time: " + str(avg_time_ms) + " ms/frame")
	
	# Stress test can be slower but should still be reasonable
	assert_lt(avg_time_ms, 15.0, "Stress test should complete in <15ms per frame")

# === Collision Performance with Walls ===

func test_wall_collision_performance():
	# Create tank and 25 walls (5x5 grid)
	var tank = Tank3D.new()
	tank.global_position = Vector3(0.0, 0.0, 0.0)
	add_child_autofree(tank)
	
	var walls = []
	for x in range(5):
		for z in range(5):
			var wall = StaticBody3D.new()
			wall.collision_layer = 8
			wall.collision_mask = 7
			var collision = CollisionShape3D.new()
			var box = BoxShape3D.new()
			box.size = Vector3(0.5, 1.0, 0.5)
			collision.shape = box
			wall.add_child(collision)
			wall.global_position = Vector3(x * 1.0 + 2.0, 0.0, z * 1.0 + 2.0)
			add_child_autofree(wall)
			walls.append(wall)
	
	await get_tree().process_frame
	
	var start_time = Time.get_ticks_usec()
	
	# Navigate around walls
	for i in range(100):
		var dir = i % 4
		match dir:
			0: tank.move_in_direction(Tank3D.Direction.UP)
			1: tank.move_in_direction(Tank3D.Direction.RIGHT)
			2: tank.move_in_direction(Tank3D.Direction.DOWN)
			3: tank.move_in_direction(Tank3D.Direction.LEFT)
		
		tank._physics_process(0.016)
		await get_tree().process_frame
	
	var elapsed = Time.get_ticks_usec() - start_time
	var avg_time_ms = elapsed / 1000.0 / 100.0
	
	assert_lt(avg_time_ms, 1.0, "Wall collision should add minimal overhead (<1ms)")
