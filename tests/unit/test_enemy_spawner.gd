extends GutTest
## Unit tests for EnemySpawner - BDD style

const EnemySpawnerScript = preload("res://src/managers/enemy_spawner.gd")

var spawner
var mock_parent

func before_each():
	spawner = EnemySpawnerScript.new()
	mock_parent = Node2D.new()
	add_child_autofree(mock_parent)
	mock_parent.add_child(spawner)

func after_each():
	if spawner and is_instance_valid(spawner):
		spawner.queue_free()
	spawner = null

# ==================== Wave Initialization ====================

func test_start_wave_initializes_state():
	# Given a fresh spawner
	# When starting wave 1
	spawner.start_wave(1)
	
	# Then wave state is initialized correctly
	assert_eq(spawner.current_stage, 1, "Should set current stage")
	assert_eq(spawner.enemies_remaining, 20, "Should have 20 enemies remaining")
	assert_eq(spawner.enemies_spawned, 0, "Should have spawned 0 enemies")
	assert_true(spawner.is_spawning, "Should be in spawning state")
	assert_eq(spawner.get_active_enemy_count(), 0, "Should have no active enemies")

func test_start_wave_generates_enemy_queue():
	# Given a fresh spawner
	# When starting wave 1
	spawner.start_wave(1)
	
	# Then enemy queue is generated with 20 enemies
	assert_eq(spawner.enemy_queue.size(), 20, "Queue should have 20 enemies")
	
	# And queue contains valid tank types
	for tank_type in spawner.enemy_queue:
		assert_true(tank_type >= Tank.TankType.BASIC and tank_type <= Tank.TankType.ARMORED,
			"Queue should contain valid tank types")

func test_start_wave_emits_signal():
	# Given a fresh spawner
	watch_signals(spawner)
	
	# When starting wave 1
	spawner.start_wave(1)
	
	# Then wave_started signal is emitted
	assert_signal_emitted(spawner, "wave_started", "Should emit wave_started signal")
	assert_signal_emit_count(spawner, "wave_started", 1)

# ==================== Enemy Spawning ====================

func test_try_spawn_enemy_creates_tank():
	# Given a wave in progress
	spawner.start_wave(1)
	var initial_count: int = mock_parent.get_child_count()
	
	# When spawning an enemy
	spawner._try_spawn_enemy()
	
	# Then a tank is added to the scene
	assert_eq(mock_parent.get_child_count(), initial_count + 1, "Should add enemy to scene")
	assert_eq(spawner.get_active_enemy_count(), 1, "Should track 1 active enemy")
	assert_eq(spawner.enemies_spawned, 1, "Should increment spawned count")

func test_try_spawn_enemy_respects_concurrent_limit():
	# Given a wave with 4 active enemies
	spawner.start_wave(1)
	for i in 4:
		spawner._try_spawn_enemy()
	
	var count_before: int = spawner.get_active_enemy_count()
	
	# When trying to spawn another enemy
	spawner._try_spawn_enemy()
	
	# Then no new enemy is spawned
	assert_eq(spawner.get_active_enemy_count(), count_before, "Should not exceed max concurrent")
	assert_eq(count_before, 4, "Should have max concurrent enemies")

func test_try_spawn_enemy_stops_at_wave_limit():
	# Given a wave with 20 enemies spawned
	spawner.start_wave(1)
	
	# Spawn all 20 enemies by clearing active list between batches
	for i in 5:  # 5 batches of 4
		for j in 4:
			spawner._try_spawn_enemy()
		# Clear active enemies to free slots
		spawner.active_enemies.clear()
	
	var count_before: int = spawner.enemies_spawned
	
	# When trying to spawn another enemy
	spawner._try_spawn_enemy()
	
	# Then no new enemy is spawned
	assert_eq(spawner.enemies_spawned, count_before, "Should not spawn beyond wave limit")
	assert_eq(count_before, 20, "Should have spawned all 20 enemies")

func test_spawn_positions_cycle_through_spawn_points():
	# Given a fresh spawner
	spawner.start_wave(1)
	var positions: Array[Vector2] = []
	
	# When spawning 6 enemies (2 cycles)
	for i in 6:
		var pos: Vector2 = spawner._get_spawn_position()
		positions.append(pos)
		spawner.enemies_spawned += 1
	
	# Then positions cycle through spawn points
	assert_eq(positions[0], spawner.SPAWN_POINTS[0], "First spawn at left")
	assert_eq(positions[1], spawner.SPAWN_POINTS[1], "Second spawn at center")
	assert_eq(positions[2], spawner.SPAWN_POINTS[2], "Third spawn at right")
	assert_eq(positions[3], spawner.SPAWN_POINTS[0], "Fourth spawn cycles to left")

func test_spawned_enemy_has_correct_type_configuration():
	# Given a wave with BASIC enemy first
	spawner.start_wave(1)
	spawner.enemy_queue[0] = Tank.TankType.BASIC
	
	# When spawning the first enemy
	spawner._try_spawn_enemy()
	
	# Then enemy has BASIC configuration
	var enemy: Tank = mock_parent.get_child(1) as Tank  # Skip spawner itself
	assert_not_null(enemy, "Enemy should exist")
	assert_eq(enemy.tank_type, Tank.TankType.BASIC, "Should be BASIC type")
	assert_eq(enemy.base_speed, 50.0, "Should have BASIC speed")
	assert_eq(enemy.max_health, 1, "Should have BASIC health")

# ==================== Enemy Types Configuration ====================

func test_fast_enemy_configuration():
	# Given a wave with FAST enemy first
	spawner.start_wave(1)
	spawner.enemy_queue[0] = Tank.TankType.FAST
	
	# When spawning the enemy
	spawner._try_spawn_enemy()
	
	# Then enemy has FAST configuration
	var enemy: Tank = mock_parent.get_child(1) as Tank
	assert_eq(enemy.tank_type, Tank.TankType.FAST, "Should be FAST type")
	assert_eq(enemy.base_speed, 100.0, "Should have FAST speed")
	assert_eq(enemy.max_health, 1, "Should have FAST health")

func test_power_enemy_configuration():
	# Given a wave with POWER enemy first
	spawner.start_wave(1)
	spawner.enemy_queue[0] = Tank.TankType.POWER
	
	# When spawning the enemy
	spawner._try_spawn_enemy()
	
	# Then enemy has POWER configuration
	var enemy: Tank = mock_parent.get_child(1) as Tank
	assert_eq(enemy.tank_type, Tank.TankType.POWER, "Should be POWER type")
	assert_eq(enemy.base_speed, 50.0, "Should have POWER speed")
	assert_eq(enemy.max_health, 4, "Should have POWER health (4 hits)")

func test_armored_enemy_configuration():
	# Given a wave with ARMORED enemy first
	spawner.start_wave(1)
	spawner.enemy_queue[0] = Tank.TankType.ARMORED
	
	# When spawning the enemy
	spawner._try_spawn_enemy()
	
	# Then enemy has ARMORED configuration
	var enemy: Tank = mock_parent.get_child(1) as Tank
	assert_eq(enemy.tank_type, Tank.TankType.ARMORED, "Should be ARMORED type")
	assert_eq(enemy.base_speed, 50.0, "Should have ARMORED speed")
	assert_eq(enemy.max_health, 2, "Should have ARMORED health")

# ==================== Wave Progression ====================

func test_enemy_destruction_updates_tracking():
	# Given a wave with 1 spawned enemy
	spawner.start_wave(1)
	spawner._try_spawn_enemy()
	var enemy: Tank = mock_parent.get_child(1) as Tank
	
	# When enemy is destroyed
	var event := TankDestroyedEvent.new()
	event.tank_id = enemy.tank_id
	spawner._on_tank_destroyed(event)
	
	# Then tracking is updated
	assert_eq(spawner.get_active_enemy_count(), 0, "Should have no active enemies")
	assert_eq(spawner.enemies_remaining, 19, "Should decrement enemies remaining")

func test_wave_completion_when_all_enemies_defeated():
	# Given a wave with 1 enemy left to defeat
	spawner.start_wave(1)
	spawner._try_spawn_enemy()
	var enemy = mock_parent.get_child(1)
	
	# Simulate all other enemies defeated (19 spawned, 19 destroyed, 1 active)
	spawner.enemies_spawned = 20
	spawner.enemies_remaining = 1
	
	watch_signals(spawner)
	
	# When the last enemy is destroyed
	var event := TankDestroyedEvent.new()
	event.tank_id = enemy.tank_id
	spawner._on_tank_destroyed(event)
	
	# Then wave is completed
	assert_false(spawner.is_spawning, "Should stop spawning")
	assert_signal_emitted(spawner, "wave_completed", "Should emit wave_completed")
	assert_signal_emitted(spawner, "all_enemies_defeated", "Should emit all_enemies_defeated")

func test_stop_wave_halts_spawning():
	# Given an active wave
	spawner.start_wave(1)
	assert_true(spawner.is_spawning, "Should be spawning")
	
	# When stopping the wave
	spawner.stop_wave()
	
	# Then spawning is halted
	assert_false(spawner.is_spawning, "Should stop spawning")

# ==================== Enemy Queue Generation ====================

func test_enemy_queue_scales_with_stage_difficulty():
	# Given stages 1, 5, and 10
	var stage_compositions: Array = []
	
	for stage in [1, 5, 10]:
		spawner._generate_enemy_queue(stage)
		var composition := {
			"basic": 0,
			"fast": 0,
			"power": 0,
			"armored": 0
		}
		
		for tank_type in spawner.enemy_queue:
			match tank_type:
				Tank.TankType.BASIC:
					composition.basic += 1
				Tank.TankType.FAST:
					composition.fast += 1
				Tank.TankType.POWER:
					composition.power += 1
				Tank.TankType.ARMORED:
					composition.armored += 1
		
		stage_compositions.append(composition)
	
	# Then later stages have more difficult enemies
	assert_true(stage_compositions[1].fast > stage_compositions[0].fast, 
		"Stage 5 should have more fast enemies than stage 1")
	assert_true(stage_compositions[2].power > stage_compositions[0].power, 
		"Stage 10 should have more power enemies than stage 1")

func test_enemy_queue_always_totals_20_enemies():
	# Given various stage numbers
	for stage in [1, 5, 10, 20, 35]:
		# When generating enemy queue
		spawner._generate_enemy_queue(stage)
		
		# Then queue always has exactly 20 enemies
		assert_eq(spawner.enemy_queue.size(), 20, 
			"Stage %d should have exactly 20 enemies" % stage)

# ==================== EventBus Integration ====================

func test_spawner_emits_tank_spawned_event():
	# Given EventBus is recording
	EventBus.start_recording()
	spawner.start_wave(1)
	
	# When spawning an enemy
	spawner._try_spawn_enemy()
	
	# Then TankSpawnedEvent is emitted
	var events: Array = EventBus.recorded_events.filter(
		func(e): return e is TankSpawnedEvent
	)
	assert_eq(events.size(), 1, "Should emit 1 TankSpawnedEvent")
	
	var event: TankSpawnedEvent = events[0]
	assert_false(event.is_player, "Should not be player tank")
	# Enemy type is randomized, so just check it's valid
	var valid_types = ["basic", "fast", "power", "armored"]
	assert_true(event.tank_type in valid_types, "Should spawn valid enemy type")
	
	EventBus.stop_recording()

func test_spawner_listens_to_tank_destroyed_events():
	# Given a wave with spawned enemy
	spawner.start_wave(1)
	spawner._try_spawn_enemy()
	var enemy: Tank = mock_parent.get_child(1) as Tank
	var initial_active: int = spawner.get_active_enemy_count()
	
	# When TankDestroyedEvent is emitted via EventBus
	var event := TankDestroyedEvent.new()
	event.tank_id = enemy.tank_id
	EventBus.emit_game_event(event)
	
	# Then spawner handles the destruction
	await get_tree().process_frame
	assert_lt(spawner.get_active_enemy_count(), initial_active, 
		"Should remove enemy from active list")
