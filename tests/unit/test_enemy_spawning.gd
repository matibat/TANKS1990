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
	pending("Requires full scene setup - move to integration tests")
	return
	
	# Given: Wave started
	enemy_spawner.start_wave(1)
	
	# When: Enough time passes for spawn
	await wait_seconds(3.1) # SPAWN_INTERVAL + buffer
	
	# Then: Enemy should be spawned
	assert_gt(enemy_spawner.enemies_spawned, 0, "Should have spawned at least one enemy")

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
