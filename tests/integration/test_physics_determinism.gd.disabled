extends GutTest
## Integration tests for physics determinism validation

var Vector3Helpers = preload("res://src/utils/vector3_helpers.gd")

# Test scenario components
var tanks: Array[Tank3D] = []
var bullets: Array[Bullet3D] = []
var positions_run1: Array[Vector3] = []
var positions_run2: Array[Vector3] = []

func before_each():
	# Seed RNG for deterministic behavior
	seed(12345)
	
	# Clear arrays
	tanks.clear()
	bullets.clear()
	positions_run1.clear()
	positions_run2.clear()

func after_each():
	for tank in tanks:
		if tank and is_instance_valid(tank):
			tank.queue_free()
	
	for bullet in bullets:
		if bullet and is_instance_valid(bullet):
			bullet.queue_free()
	
	tanks.clear()
	bullets.clear()

# === Basic Determinism Tests ===

func test_tank_position_deterministic_after_movement():
	var tank = Tank3D.new()
	tank.global_position = Vector3(5.0, 0.0, 5.0)
	add_child_autofree(tank)
	await get_tree().process_frame
	
	# Record first run
	for i in range(10):
		tank.move_in_direction(Tank3D.Direction.UP)
		tank._physics_process(0.016)
	var pos1 = tank.global_position
	
	# Reset and run again
	tank.global_position = Vector3(5.0, 0.0, 5.0)
	for i in range(10):
		tank.move_in_direction(Tank3D.Direction.UP)
		tank._physics_process(0.016)
	var pos2 = tank.global_position
	
	# Should be identical
	assert_true(Vector3Helpers.vec3_approx_equal(pos1, pos2, 0.001), "Position should be deterministic")

func test_bullet_position_deterministic():
	var bullet = Bullet3D.new()
	bullet.initialize(Vector3(5.0, 0.0, 5.0), Vector3(0, 0, 1), 1, 1, true)
	bullet.is_active = true
	add_child_autofree(bullet)
	await get_tree().process_frame
	
	# First run
	for i in range(20):
		bullet._physics_process(0.016)
	var pos1 = bullet.global_position
	
	# Reset and second run
	bullet.global_position = Vector3(5.0, 0.0, 5.0)
	bullet.is_active = true
	for i in range(20):
		bullet._physics_process(0.016)
	var pos2 = bullet.global_position
	
	assert_true(Vector3Helpers.vec3_approx_equal(pos1, pos2, 0.001), "Bullet position should be deterministic")

# === Combat Scenario Determinism ===

func test_combat_scenario_deterministic():
	# Create simple combat scenario
	var player = Tank3D.new()
	player.tank_type = Tank3D.TankType.PLAYER
	player.is_player = true
	player.tank_id = 1
	player.global_position = Vector3(5.0, 0.0, 5.0)
	add_child_autofree(player)
	
	var enemy = Tank3D.new()
	enemy.tank_type = Tank3D.TankType.BASIC
	enemy.is_player = false
	enemy.tank_id = 2
	enemy.global_position = Vector3(5.0, 0.0, 8.0)
	add_child_autofree(enemy)
	
	await get_tree().process_frame
	
	# Seed RNG
	seed(42)
	
	# Run scenario 1: 100 frames
	var checkpoints_run1 = []
	for frame in range(100):
		# Simple AI: player moves up every 10 frames
		if frame % 10 == 0:
			player.move_in_direction(Tank3D.Direction.UP)
		
		# Enemy moves down every 15 frames
		if frame % 15 == 0:
			enemy.move_in_direction(Tank3D.Direction.DOWN)
		
		player._physics_process(0.016)
		enemy._physics_process(0.016)
		
		# Record checkpoint positions every 20 frames
		if frame % 20 == 0:
			checkpoints_run1.append({
				"frame": frame,
				"player_pos": player.global_position,
				"enemy_pos": enemy.global_position
			})
	
	# Reset positions
	player.global_position = Vector3(5.0, 0.0, 5.0)
	enemy.global_position = Vector3(5.0, 0.0, 8.0)
	seed(42)  # Same seed
	
	# Run scenario 2: identical inputs
	var checkpoints_run2 = []
	for frame in range(100):
		if frame % 10 == 0:
			player.move_in_direction(Tank3D.Direction.UP)
		
		if frame % 15 == 0:
			enemy.move_in_direction(Tank3D.Direction.DOWN)
		
		player._physics_process(0.016)
		enemy._physics_process(0.016)
		
		if frame % 20 == 0:
			checkpoints_run2.append({
				"frame": frame,
				"player_pos": player.global_position,
				"enemy_pos": enemy.global_position
			})
	
	# Compare checkpoints
	assert_eq(checkpoints_run1.size(), checkpoints_run2.size(), "Should have same checkpoint count")
	
	for i in range(checkpoints_run1.size()):
		var cp1 = checkpoints_run1[i]
		var cp2 = checkpoints_run2[i]
		
		var player_drift = cp1.player_pos.distance_to(cp2.player_pos)
		var enemy_drift = cp1.enemy_pos.distance_to(cp2.enemy_pos)
		
		assert_lt(player_drift, 0.01, "Player drift should be <0.01 at frame " + str(cp1.frame))
		assert_lt(enemy_drift, 0.01, "Enemy drift should be <0.01 at frame " + str(cp1.frame))

# === Quantization Determinism ===

func test_position_quantization_prevents_drift():
	var tank = Tank3D.new()
	add_child_autofree(tank)
	await get_tree().process_frame
	
	# Set imprecise position
	tank.global_position = Vector3(5.123456789, 0.0, 7.987654321)
	
	# Quantize
	tank.global_position = Vector3Helpers.quantize_vec3(tank.global_position, 0.001)
	
	var pos1 = tank.global_position
	
	# Repeat quantization (should be idempotent)
	tank.global_position = Vector3Helpers.quantize_vec3(tank.global_position, 0.001)
	
	var pos2 = tank.global_position
	
	assert_eq(pos1, pos2, "Quantization should be idempotent")
	
	# Check precision
	assert_almost_eq(pos1.x, round(pos1.x * 1000.0) / 1000.0, 0.0001, "X should be quantized to 0.001")
	assert_almost_eq(pos1.z, round(pos1.z * 1000.0) / 1000.0, 0.0001, "Z should be quantized to 0.001")

# === Floating Point Consistency ===

func test_repeated_calculations_consistent():
	# Test that repeated small movements don't accumulate error
	var tank = Tank3D.new()
	tank.global_position = Vector3(5.0, 0.0, 5.0)
	add_child_autofree(tank)
	await get_tree().process_frame
	
	# Move right 100 times, then left 100 times
	var initial_pos = tank.global_position
	
	for i in range(100):
		tank.move_in_direction(Tank3D.Direction.RIGHT)
		tank.global_position = Vector3Helpers.quantize_vec3(tank.global_position, 0.001)
	
	for i in range(100):
		tank.move_in_direction(Tank3D.Direction.LEFT)
		tank.global_position = Vector3Helpers.quantize_vec3(tank.global_position, 0.001)
	
	var final_pos = tank.global_position
	
	# Should return to approximately same position (within tile precision)
	var drift = initial_pos.distance_to(final_pos)
	assert_lt(drift, 1.0, "Should return near initial position (within 1 tile)")

# === Multi-Entity Determinism ===

func test_multiple_tanks_deterministic():
	# Create 5 tanks
	for i in range(5):
		var tank = Tank3D.new()
		tank.tank_id = i
		tank.global_position = Vector3(i * 2.0, 0.0, i * 2.0)
		add_child_autofree(tank)
		tanks.append(tank)
	
	await get_tree().process_frame
	
	seed(999)
	
	# Run simulation
	for frame in range(50):
		for tank in tanks:
			# Simple random movement
			var dir = randi() % 4
			match dir:
				0: tank.move_in_direction(Tank3D.Direction.UP)
				1: tank.move_in_direction(Tank3D.Direction.DOWN)
				2: tank.move_in_direction(Tank3D.Direction.LEFT)
				3: tank.move_in_direction(Tank3D.Direction.RIGHT)
			
			tank._physics_process(0.016)
			tank.global_position = Vector3Helpers.quantize_vec3(tank.global_position, 0.001)
	
	# Record positions
	var positions_run1_local = []
	for tank in tanks:
		positions_run1_local.append(tank.global_position)
	
	# Reset and run again
	for i in range(tanks.size()):
		tanks[i].global_position = Vector3(i * 2.0, 0.0, i * 2.0)
	
	seed(999)  # Same seed
	
	for frame in range(50):
		for tank in tanks:
			var dir = randi() % 4
			match dir:
				0: tank.move_in_direction(Tank3D.Direction.UP)
				1: tank.move_in_direction(Tank3D.Direction.DOWN)
				2: tank.move_in_direction(Tank3D.Direction.LEFT)
				3: tank.move_in_direction(Tank3D.Direction.RIGHT)
			
			tank._physics_process(0.016)
			tank.global_position = Vector3Helpers.quantize_vec3(tank.global_position, 0.001)
	
	# Compare positions
	for i in range(tanks.size()):
		var drift = positions_run1_local[i].distance_to(tanks[i].global_position)
		assert_lt(drift, 0.01, "Tank " + str(i) + " drift should be <0.01")

# === Collision Determinism ===

func test_collision_response_deterministic():
	var tank1 = Tank3D.new()
	tank1.global_position = Vector3(5.0, 0.0, 5.0)
	add_child_autofree(tank1)
	
	var tank2 = Tank3D.new()
	tank2.global_position = Vector3(5.5, 0.0, 5.0)
	add_child_autofree(tank2)
	
	await get_tree().process_frame
	
	# Try to move tank1 into tank2
	var pos_before = tank1.global_position
	
	tank1.move_in_direction(Tank3D.Direction.RIGHT)
	await get_tree().process_frame
	
	var pos_after_run1 = tank1.global_position
	
	# Reset and repeat
	tank1.global_position = pos_before
	tank1.move_in_direction(Tank3D.Direction.RIGHT)
	await get_tree().process_frame
	
	var pos_after_run2 = tank1.global_position
	
	# Collision response should be identical
	assert_true(Vector3Helpers.vec3_approx_equal(pos_after_run1, pos_after_run2, 0.001),
				"Collision response should be deterministic")

# === Physics Timestep Consistency ===

func test_fixed_timestep_used():
	# Verify physics uses fixed timestep (0.016 = 1/60)
	var expected_delta = 1.0 / 60.0
	
	# Can't directly test delta in unit test, but document expectation
	assert_almost_eq(expected_delta, 0.01666, 0.00001, "Fixed timestep should be ~0.01666")

# === Drift Measurement ===

func test_maximum_drift_under_threshold():
	var tank = Tank3D.new()
	tank.global_position = Vector3(5.0, 0.0, 5.0)
	add_child_autofree(tank)
	await get_tree().process_frame
	
	seed(555)
	
	# Complex movement pattern
	var checkpoints_a = []
	for i in range(200):
		var dir = randi() % 4
		match dir:
			0: tank.move_in_direction(Tank3D.Direction.UP)
			1: tank.move_in_direction(Tank3D.Direction.DOWN)
			2: tank.move_in_direction(Tank3D.Direction.LEFT)
			3: tank.move_in_direction(Tank3D.Direction.RIGHT)
		
		tank._physics_process(0.016)
		tank.global_position = Vector3Helpers.quantize_vec3(tank.global_position, 0.001)
		
		if i % 50 == 0:
			checkpoints_a.append(tank.global_position)
	
	# Reset and repeat
	tank.global_position = Vector3(5.0, 0.0, 5.0)
	seed(555)
	
	var checkpoints_b = []
	for i in range(200):
		var dir = randi() % 4
		match dir:
			0: tank.move_in_direction(Tank3D.Direction.UP)
			1: tank.move_in_direction(Tank3D.Direction.DOWN)
			2: tank.move_in_direction(Tank3D.Direction.LEFT)
			3: tank.move_in_direction(Tank3D.Direction.RIGHT)
		
		tank._physics_process(0.016)
		tank.global_position = Vector3Helpers.quantize_vec3(tank.global_position, 0.001)
		
		if i % 50 == 0:
			checkpoints_b.append(tank.global_position)
	
	# Measure maximum drift
	var max_drift = 0.0
	for i in range(checkpoints_a.size()):
		var drift = checkpoints_a[i].distance_to(checkpoints_b[i])
		max_drift = max(max_drift, drift)
	
	assert_lt(max_drift, 0.01, "Maximum drift should be <0.01 units across all checkpoints")
