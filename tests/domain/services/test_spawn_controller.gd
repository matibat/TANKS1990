extends GutTest

const SpawnController = preload("res://src/domain/services/spawn_controller.gd")
const TankEntity = preload("res://src/domain/entities/tank_entity.gd")
const GameState = preload("res://src/domain/aggregates/game_state.gd")
const StageState = preload("res://src/domain/aggregates/stage_state.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")

func test_given_stage_start_when_initialize_then_enemies_remaining_20():
	# Given: New spawn controller for stage 1
	var controller = SpawnController.new(1)
	
	# Then: Should have 20 enemies remaining
	assert_eq(controller.get_enemies_remaining(), 20, "Stage should start with 20 enemies")

func test_given_less_than_4_enemies_when_spawn_tick_then_spawns_one_enemy():
	# Given: Game state with only 2 enemies on field
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)
	
	var enemy1 = TankEntity.create("enemy1", TankEntity.Type.ENEMY_BASIC,
		Position.create(100, 100), Direction.create(Direction.DOWN))
	var enemy2 = TankEntity.create("enemy2", TankEntity.Type.ENEMY_BASIC,
		Position.create(200, 100), Direction.create(Direction.DOWN))
	
	game_state.add_tank(enemy1)
	game_state.add_tank(enemy2)
	
	var controller = SpawnController.new(1)
	controller._spawn_timer = 100.0  # Force spawn ready
	
	# When: Check if should spawn
	var should_spawn = controller.should_spawn(game_state, 0.016)
	
	# Then: Should return true
	assert_true(should_spawn, "Should spawn when less than 4 enemies on field")

func test_given_4_enemies_on_field_when_spawn_tick_then_no_spawn():
	# Given: Game state with 4 enemies on field
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)
	
	for i in range(4):
		var enemy = TankEntity.create("enemy%d" % i, TankEntity.Type.ENEMY_BASIC,
			Position.create(100 + i * 50, 100), Direction.create(Direction.DOWN))
		game_state.add_tank(enemy)
	
	var controller = SpawnController.new(1)
	controller._spawn_timer = 100.0  # Force spawn ready
	
	# When: Check if should spawn
	var should_spawn = controller.should_spawn(game_state, 0.016)
	
	# Then: Should return false
	assert_false(should_spawn, "Should not spawn when 4 enemies already on field")

func test_given_0_enemies_remaining_when_spawn_tick_then_no_spawn():
	# Given: Spawn controller with no enemies remaining
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)
	
	var controller = SpawnController.new(1)
	controller._enemies_remaining = 0  # All enemies spawned
	controller._spawn_timer = 100.0  # Force spawn ready
	
	# When: Check if should spawn
	var should_spawn = controller.should_spawn(game_state, 0.016)
	
	# Then: Should return false
	assert_false(should_spawn, "Should not spawn when no enemies remaining")

func test_given_enemy_destroyed_when_field_count_drops_then_spawns_next():
	# Given: Game state with 3 enemies (one just destroyed)
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)
	
	for i in range(3):
		var enemy = TankEntity.create("enemy%d" % i, TankEntity.Type.ENEMY_BASIC,
			Position.create(100 + i * 50, 100), Direction.create(Direction.DOWN))
		game_state.add_tank(enemy)
	
	var controller = SpawnController.new(1)
	controller._spawn_timer = 100.0  # Force spawn ready
	controller._enemies_remaining = 10  # Still have enemies to spawn
	
	# When: Check if should spawn
	var should_spawn = controller.should_spawn(game_state, 0.016)
	
	# Then: Should spawn next enemy
	assert_true(should_spawn, "Should spawn when field count drops below 4")
	
	# When: Spawn enemy
	var new_enemy = controller.spawn_enemy(game_state)
	
	# Then: Should return valid enemy
	assert_not_null(new_enemy, "Should spawn a new enemy")
	assert_eq(controller.get_enemies_remaining(), 9, "Enemies remaining should decrease")

func test_given_spawn_interval_passes_when_tick_then_spawns_on_schedule():
	# Given: Spawn controller with timer at 0
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)
	
	var controller = SpawnController.new(1)
	controller._spawn_timer = 0.0
	
	# When: Accumulate time until spawn interval
	var total_time = 0.0
	var spawn_ready = false
	while total_time < 5.0 and not spawn_ready:
		total_time += 0.016
		spawn_ready = controller.should_spawn(game_state, 0.016)
	
	# Then: Should eventually be ready to spawn
	assert_true(spawn_ready, "Should be ready to spawn after enough time passes")

func test_given_random_enemy_type_when_spawn_then_uses_weighted_distribution():
	# Given: Spawn controller
	var controller = SpawnController.new(1)
	
	# When: Generate many enemy types
	var type_counts = {
		TankEntity.Type.ENEMY_BASIC: 0,
		TankEntity.Type.ENEMY_FAST: 0,
		TankEntity.Type.ENEMY_POWER: 0,
		TankEntity.Type.ENEMY_ARMORED: 0
	}
	
	for i in range(100):
		var enemy_type = controller.get_random_enemy_type()
		type_counts[enemy_type] += 1
	
	# Then: Basic should be most common (roughly 50%)
	assert_true(type_counts[TankEntity.Type.ENEMY_BASIC] > 30, 
		"BASIC should be most common (expected ~50, got %d)" % type_counts[TankEntity.Type.ENEMY_BASIC])

func test_given_spawn_locations_when_spawn_then_uses_top_positions():
	# Given: Spawn controller
	var controller = SpawnController.new(1)
	
	# When: Get spawn position
	var pos = controller.get_spawn_position()
	
	# Then: Should be one of three top positions (x: 16, 192, 384; y: 0)
	assert_eq(pos.y, 0, "Spawn Y should be 0 (top of screen)")
	var valid_x = [16, 192, 384]  # (1*16, 12*16, 24*16)
	assert_true(pos.x in valid_x, 
		"Spawn X should be one of %s, got %d" % [valid_x, pos.x])

func test_given_stage_complete_when_all_spawned_and_killed_then_returns_true():
	# Given: Spawn controller with all enemies spawned and killed
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)
	
	var controller = SpawnController.new(1)
	controller._enemies_remaining = 0  # All spawned
	controller._enemies_spawned = 20
	# No enemies on field (all killed)
	
	# When: Check if stage complete
	var is_complete = controller.is_stage_complete(game_state)
	
	# Then: Should return true
	assert_true(is_complete, "Stage should be complete when all enemies spawned and killed")

func test_given_enemies_still_on_field_when_check_complete_then_returns_false():
	# Given: Spawn controller with enemies still on field
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)
	
	var enemy = TankEntity.create("enemy1", TankEntity.Type.ENEMY_BASIC,
		Position.create(100, 100), Direction.create(Direction.DOWN))
	game_state.add_tank(enemy)
	
	var controller = SpawnController.new(1)
	controller._enemies_remaining = 0  # All spawned
	controller._enemies_spawned = 20
	
	# When: Check if stage complete
	var is_complete = controller.is_stage_complete(game_state)
	
	# Then: Should return false
	assert_false(is_complete, "Stage should not be complete while enemies still on field")
