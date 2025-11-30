extends GutTest
## Quick test to verify regular enemy spawning behavior

var enemy_spawner: EnemySpawner
var test_scene: Node2D

func before_each() -> void:
	test_scene = Node2D.new()
	add_child_autofree(test_scene)

	enemy_spawner = EnemySpawner.new()
	test_scene.add_child(enemy_spawner)

func test_regular_spawning_creates_varied_enemy_types():
	# Given: Regular spawning mode (not test mode)
	enemy_spawner.infinite_spawn_mode = false
	enemy_spawner.test_armored_only = false

	# When: Start wave 1
	enemy_spawner.start_wave(1)

	# Then: Enemy queue should contain varied types
	assert_gt(enemy_spawner.enemy_queue.size(), 0, "Should generate enemy queue")
	assert_eq(enemy_spawner.enemy_queue.size(), 20, "Should have 20 enemies for stage 1")

	# And: Should contain different enemy types (not all armored)
	var has_basic = false
	var has_fast = false
	var has_power = false
	var has_armored = false

	for enemy_type in enemy_spawner.enemy_queue:
		match enemy_type:
			Tank.TankType.BASIC:
				has_basic = true
			Tank.TankType.FAST:
				has_fast = true
			Tank.TankType.POWER:
				has_power = true
			Tank.TankType.ARMORED:
				has_armored = true

	# Stage 1 should have mostly basic enemies with some fast
	assert_true(has_basic, "Should have basic enemies")
	assert_true(has_fast, "Should have fast enemies")
	# Power and armored might not appear in stage 1, so don't assert them

func test_infinite_mode_disabled_by_default():
	# Given: Fresh enemy spawner
	# Then: Should not be in infinite mode
	assert_false(enemy_spawner.infinite_spawn_mode, "Should not be in infinite mode by default")
	assert_false(enemy_spawner.test_armored_only, "Should not spawn only armored tanks by default")

func test_infinite_mode_spawns_endlessly():
	# Given: Infinite spawning mode
	enemy_spawner.infinite_spawn_mode = true
	enemy_spawner.start_wave(1)

	# When: Spawn many enemies (more than the normal 20)
	var total_spawned = 0
	for batch in range(7):  # 7 batches of 4 = 28 total (more than 20)
		for i in range(4):  # Spawn up to concurrent limit
			enemy_spawner._try_spawn_enemy()
			total_spawned += 1
		# Clear active enemies to allow next batch
		enemy_spawner.active_enemies.clear()

	# Then: Should have spawned more than 20 enemies
	assert_gt(enemy_spawner.enemies_spawned, 20, "Should spawn endlessly in infinite mode")