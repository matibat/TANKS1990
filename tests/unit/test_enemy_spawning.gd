extends GutTest
## BDD Test Suite: Enemy Spawning Integration
## Tests that enemies spawn when game starts

var enemy_spawner: EnemySpawner
var event_bus: Node

func before_each():
	event_bus = get_node("/root/EventBus")
	event_bus.recorded_events.clear()
	event_bus.current_frame = 0
	enemy_spawner = EnemySpawner.new()
	add_child_autofree(enemy_spawner)

## ============================================================================
## Epic: Enemy Spawning Activation
## ============================================================================

func test_given_game_starts_when_wave_started_then_enemies_begin_spawning():
	# Given: EnemySpawner ready
	watch_signals(enemy_spawner)
	
	# When: Wave starts
	enemy_spawner.start_wave(1)
	
	# Then: Spawning begins
	assert_signal_emitted(enemy_spawner, "wave_started", "Should emit wave_started signal")
	assert_true(enemy_spawner.is_spawning, "Should be in spawning state")
	assert_gt(enemy_spawner.enemies_remaining, 0, "Should have enemies to spawn")

func test_given_wave_started_when_time_passes_then_enemy_spawns():
	# Given: EnemySpawner ready and wave started
	watch_signals(enemy_spawner)
	
	# When: Wave starts
	enemy_spawner.start_wave(1)
	
	# Then: Spawning begins
	assert_signal_emitted(enemy_spawner, "wave_started", "Should emit wave_started signal")
	assert_true(enemy_spawner.is_spawning, "Should be in spawning state")
	assert_gt(enemy_spawner.enemies_remaining, 0, "Should have enemies to spawn")
	
	# When: Wait for spawn interval to pass (simulate physics process)
	var initial_spawned = enemy_spawner.enemies_spawned
	var frames_to_wait = int(enemy_spawner.SPAWN_INTERVAL / (1.0/60.0)) + 1  # 60 FPS
	
	for i in range(frames_to_wait):
		enemy_spawner._physics_process(1.0/60.0)
		await get_tree().process_frame
	
	# Then: At least one enemy should have spawned
	assert_gt(enemy_spawner.enemies_spawned, initial_spawned, 
		"Should have spawned at least one enemy after spawn interval")
	assert_gt(enemy_spawner.get_active_enemy_count(), 0, 
		"Should have active enemies after spawning")

func test_given_max_enemies_active_when_spawn_timer_expires_then_no_new_spawn():
	# Given: Wave started with max concurrent enemies already active
	enemy_spawner.start_wave(1)
	
	# Spawn max concurrent enemies manually
	for i in range(enemy_spawner.MAX_CONCURRENT_ENEMIES):
		enemy_spawner._try_spawn_enemy()
	
	var initial_active = enemy_spawner.get_active_enemy_count()
	var initial_spawned = enemy_spawner.enemies_spawned
	
	# When: Spawn timer expires (simulate physics process)
	var frames_to_wait = int(enemy_spawner.SPAWN_INTERVAL / (1.0/60.0)) + 1
	
	for i in range(frames_to_wait):
		enemy_spawner._physics_process(1.0/60.0)
		await get_tree().process_frame
	
	# Then: No new enemy should spawn due to concurrent limit
	assert_eq(enemy_spawner.get_active_enemy_count(), initial_active,
		"Should not exceed max concurrent enemies")
	assert_eq(enemy_spawner.enemies_spawned, initial_spawned,
		"Should not spawn when at concurrent limit")

func test_given_wave_in_progress_when_all_enemies_spawned_then_spawning_stops():
	# Given: Wave started
	enemy_spawner.start_wave(1)
	
	# When: All enemies are spawned (simulate by setting counters)
	enemy_spawner.enemies_spawned = enemy_spawner.ENEMIES_PER_STAGE
	enemy_spawner.enemies_remaining = 0
	
	# And spawn timer expires
	var frames_to_wait = int(enemy_spawner.SPAWN_INTERVAL / (1.0/60.0)) + 1
	
	for i in range(frames_to_wait):
		enemy_spawner._physics_process(1.0/60.0)
		await get_tree().process_frame
	
	# Then: No additional spawning should occur
	assert_eq(enemy_spawner.enemies_spawned, enemy_spawner.ENEMIES_PER_STAGE,
		"Should not spawn beyond wave limit")

func test_given_multiple_spawn_cycles_when_time_passes_then_enemies_spawn_progressively():
	# Given: Wave started
	enemy_spawner.start_wave(1)
	var spawn_count = 0
	
	# When: Allow multiple spawn cycles
	for cycle in range(3):  # Test 3 spawn cycles
		var initial_spawned = enemy_spawner.enemies_spawned
		
		# Wait for spawn interval
		var frames_to_wait = int(enemy_spawner.SPAWN_INTERVAL / (1.0/60.0)) + 1
		
		for i in range(frames_to_wait):
			enemy_spawner._physics_process(1.0/60.0)
			await get_tree().process_frame
		
		# Then: Enemy should have spawned in this cycle
		assert_gt(enemy_spawner.enemies_spawned, initial_spawned,
			"Should spawn enemy in cycle " + str(cycle + 1))
		
		spawn_count += 1
		
		# Stop if we've reached concurrent limit
		if enemy_spawner.get_active_enemy_count() >= enemy_spawner.MAX_CONCURRENT_ENEMIES:
			break
	
	# Then: At least one enemy should have spawned
	assert_gt(spawn_count, 0, "Should have completed at least one spawn cycle")

func test_given_game_flow_manager_when_game_starts_then_spawner_activated():
	# Given: GameFlowManager with spawner reference
	var flow_manager = GameFlowManager.new()
	add_child_autofree(flow_manager)
	flow_manager.enemy_manager = enemy_spawner
	await get_tree().process_frame
	
	# When: Game starts
	flow_manager.start_new_game()
	await get_tree().process_frame
	
	# Then: Spawner should be active
	assert_true(enemy_spawner.is_spawning, "Enemy spawner should be activated when game starts")
