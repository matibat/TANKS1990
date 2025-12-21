extends GutTest

## BDD Tests for SpawningService
## Test-first approach: Write behavior tests before implementation

const SpawningService = preload("res://src/domain/services/spawning_service.gd")
const TankEntity = preload("res://src/domain/entities/tank_entity.gd")
const BulletEntity = preload("res://src/domain/entities/bullet_entity.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")
const StageState = preload("res://src/domain/aggregates/stage_state.gd")
const GameState = preload("res://src/domain/aggregates/game_state.gd")

## Test: Spawn Player Tank
func test_given_spawn_index_when_spawning_player_tank_then_tank_created_at_spawn():
	# Given: A game state with player spawn positions
	var stage = StageState.create(1, 26, 26)
	stage.add_player_spawn(Position.create(8, 24))
	stage.add_player_spawn(Position.create(16, 24))
	var game_state = GameState.create(stage)
	
	# When: Spawning player tank at spawn index 0
	var tank = SpawningService.spawn_player_tank(game_state, 0)
	
	# Then: Tank is created at correct spawn position
	assert_not_null(tank, "Player tank should be created")
	assert_true(tank.is_player, "Tank should be player type")
	assert_eq(tank.tank_type, TankEntity.Type.PLAYER, "Tank should have PLAYER type")
	assert_true(tank.position.equals(Position.create(8, 24)), "Tank should be at spawn position 0")
	assert_true(tank.is_alive(), "Tank should be alive")

func test_given_second_spawn_index_when_spawning_player_tank_then_uses_correct_spawn():
	# Given: A game state with multiple player spawn positions
	var stage = StageState.create(1, 26, 26)
	stage.add_player_spawn(Position.create(8, 24))
	stage.add_player_spawn(Position.create(16, 24))
	var game_state = GameState.create(stage)
	
	# When: Spawning player tank at spawn index 1
	var tank = SpawningService.spawn_player_tank(game_state, 1)
	
	# Then: Tank is created at second spawn position
	assert_not_null(tank, "Player tank should be created")
	assert_true(tank.position.equals(Position.create(16, 24)), "Tank should be at spawn position 1")

func test_given_player_tank_spawned_when_added_to_game_state_then_present_in_state():
	# Given: A game state with spawn positions
	var stage = StageState.create(1, 26, 26)
	stage.add_player_spawn(Position.create(8, 24))
	var game_state = GameState.create(stage)
	
	# When: Spawning and adding player tank
	var tank = SpawningService.spawn_player_tank(game_state, 0)
	game_state.add_tank(tank)
	
	# Then: Tank is in game state
	assert_eq(game_state.tanks.size(), 1, "Game state should have 1 tank")
	assert_not_null(game_state.get_tank(tank.id), "Tank should be retrievable by ID")

## Test: Spawn Enemy Tank
func test_given_spawn_index_when_spawning_enemy_tank_then_tank_created_at_spawn():
	# Given: A game state with enemy spawn positions
	var stage = StageState.create(1, 26, 26)
	stage.add_enemy_spawn(Position.create(0, 0))
	stage.add_enemy_spawn(Position.create(12, 0))
	stage.add_enemy_spawn(Position.create(24, 0))
	var game_state = GameState.create(stage)
	var initial_remaining = game_state.stage.enemies_remaining
	
	# When: Spawning basic enemy tank at spawn index 0
	var tank = SpawningService.spawn_enemy_tank(game_state, TankEntity.Type.ENEMY_BASIC, 0)
	
	# Then: Tank is created at correct spawn position
	assert_not_null(tank, "Enemy tank should be created")
	assert_false(tank.is_player, "Tank should be enemy type")
	assert_eq(tank.tank_type, TankEntity.Type.ENEMY_BASIC, "Tank should have ENEMY_BASIC type")
	assert_true(tank.position.equals(Position.create(0, 0)), "Tank should be at spawn position 0")
	assert_true(tank.is_alive(), "Tank should be alive")

func test_given_enemy_spawned_when_spawning_then_enemies_remaining_decreases():
	# Given: A game state with enemy spawns and 20 enemies remaining
	var stage = StageState.create(1, 26, 26)
	stage.add_enemy_spawn(Position.create(0, 0))
	var game_state = GameState.create(stage)
	var initial_remaining = game_state.stage.enemies_remaining
	
	# When: Spawning enemy tank
	var tank = SpawningService.spawn_enemy_tank(game_state, TankEntity.Type.ENEMY_BASIC, 0)
	
	# Then: Enemies remaining decreased by 1
	assert_eq(game_state.stage.enemies_remaining, initial_remaining - 1,
			  "Enemies remaining should decrease by 1")

func test_given_enemy_spawned_when_spawning_then_enemies_on_field_increases():
	# Given: A game state with enemy spawns
	var stage = StageState.create(1, 26, 26)
	stage.add_enemy_spawn(Position.create(0, 0))
	var game_state = GameState.create(stage)
	var initial_on_field = game_state.stage.enemies_on_field
	
	# When: Spawning enemy tank
	var tank = SpawningService.spawn_enemy_tank(game_state, TankEntity.Type.ENEMY_BASIC, 0)
	
	# Then: Enemies on field increased by 1
	assert_eq(game_state.stage.enemies_on_field, initial_on_field + 1,
			  "Enemies on field should increase by 1")

func test_given_different_enemy_types_when_spawning_then_correct_types_created():
	# Given: A game state with enemy spawn
	var stage = StageState.create(1, 26, 26)
	stage.add_enemy_spawn(Position.create(0, 0))
	var game_state = GameState.create(stage)
	
	# When: Spawning different enemy types
	var basic = SpawningService.spawn_enemy_tank(game_state, TankEntity.Type.ENEMY_BASIC, 0)
	var fast = SpawningService.spawn_enemy_tank(game_state, TankEntity.Type.ENEMY_FAST, 0)
	var armored = SpawningService.spawn_enemy_tank(game_state, TankEntity.Type.ENEMY_ARMORED, 0)
	
	# Then: Each has correct type
	assert_eq(basic.tank_type, TankEntity.Type.ENEMY_BASIC, "Should create ENEMY_BASIC")
	assert_eq(fast.tank_type, TankEntity.Type.ENEMY_FAST, "Should create ENEMY_FAST")
	assert_eq(armored.tank_type, TankEntity.Type.ENEMY_ARMORED, "Should create ENEMY_ARMORED")

## Test: Spawn Bullet
func test_given_tank_facing_up_when_spawning_bullet_then_bullet_spawns_one_tile_ahead():
	# Given: A tank facing UP
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(5, 5), Direction.create(Direction.UP))
	game_state.add_tank(tank)
	
	# When: Spawning bullet
	var bullet = SpawningService.spawn_bullet(game_state, tank)
	
	# Then: Bullet spawns one tile in front of tank (close to tank nose)
	assert_not_null(bullet, "Bullet should be created")
	assert_eq(bullet.owner_id, tank.id, "Bullet should have correct owner ID")
	assert_true(bullet.position.equals(Position.create(5, 4)), "Bullet should start one tile ahead (UP)")
	assert_eq(bullet.direction.value, Direction.UP, "Bullet should face same direction as tank")
	assert_true(bullet.is_active, "Bullet should be active")

func test_given_tank_facing_right_when_spawning_bullet_then_bullet_spawns_one_tile_ahead():
	# Given: A tank facing RIGHT
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(5, 5), Direction.create(Direction.RIGHT))
	game_state.add_tank(tank)
	
	# When: Spawning bullet
	var bullet = SpawningService.spawn_bullet(game_state, tank)
	
	# Then: Bullet spawns one tile to the right
	assert_true(bullet.position.equals(Position.create(6, 5)), "Bullet should start one tile ahead (RIGHT)")

func test_given_tank_facing_down_when_spawning_bullet_then_bullet_spawns_one_tile_ahead():
	# Given: A tank facing DOWN
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(5, 5), Direction.create(Direction.DOWN))
	game_state.add_tank(tank)

	# When: Spawning bullet
	var bullet = SpawningService.spawn_bullet(game_state, tank)

	# Then: Bullet spawns one tile below
	assert_true(bullet.position.equals(Position.create(5, 6)), "Bullet should start one tile ahead (DOWN)")

func test_given_tank_facing_left_when_spawning_bullet_then_bullet_spawns_one_tile_ahead():
	# Given: A tank facing LEFT
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(5, 5), Direction.create(Direction.LEFT))
	game_state.add_tank(tank)

	# When: Spawning bullet
	var bullet = SpawningService.spawn_bullet(game_state, tank)

	# Then: Bullet spawns one tile to the left
	assert_true(bullet.position.equals(Position.create(4, 5)), "Bullet should start one tile ahead (LEFT)")

func test_given_bullet_spawned_when_spawning_then_tank_cooldown_starts():
	# Given: A tank with no cooldown
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(5, 5), Direction.create(Direction.UP))
	game_state.add_tank(tank)
	assert_eq(tank.cooldown_frames, 0, "Tank should start with no cooldown")
	
	# When: Spawning bullet
	var bullet = SpawningService.spawn_bullet(game_state, tank)
	
	# Then: Tank has cooldown
	assert_gt(tank.cooldown_frames, 0, "Tank should have cooldown after shooting")

func test_given_bullet_spawned_when_checking_properties_then_has_correct_damage():
	# Given: A player tank
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(5, 5), Direction.create(Direction.UP))
	game_state.add_tank(tank)
	
	# When: Spawning bullet
	var bullet = SpawningService.spawn_bullet(game_state, tank)
	
	# Then: Bullet has default damage
	assert_eq(bullet.damage, 1, "Bullet should have default damage of 1")

## Test: Remove Destroyed Entities
func test_given_dead_tank_when_removing_destroyed_then_tank_removed():
	# Given: A game state with a dead tank
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(5, 5), Direction.create(Direction.UP))
	tank.take_damage(tank.health.current) # Kill tank
	game_state.add_tank(tank)
	assert_eq(game_state.tanks.size(), 1, "Should have 1 tank before removal")
	
	# When: Removing destroyed entities
	SpawningService.remove_destroyed_entities(game_state)
	
	# Then: Dead tank is removed
	assert_eq(game_state.tanks.size(), 0, "Dead tank should be removed")

func test_given_alive_tank_when_removing_destroyed_then_tank_remains():
	# Given: A game state with an alive tank
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(5, 5), Direction.create(Direction.UP))
	game_state.add_tank(tank)
	
	# When: Removing destroyed entities
	SpawningService.remove_destroyed_entities(game_state)
	
	# Then: Alive tank remains
	assert_eq(game_state.tanks.size(), 1, "Alive tank should remain")

func test_given_inactive_bullet_when_removing_destroyed_then_bullet_removed():
	# Given: A game state with an inactive bullet
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)
	var bullet = BulletEntity.create("bullet_1", "tank_1", Position.create(5, 5), Direction.create(Direction.UP), 2, 1)
	bullet.deactivate()
	game_state.add_bullet(bullet)
	assert_eq(game_state.bullets.size(), 1, "Should have 1 bullet before removal")
	
	# When: Removing destroyed entities
	SpawningService.remove_destroyed_entities(game_state)
	
	# Then: Inactive bullet is removed
	assert_eq(game_state.bullets.size(), 0, "Inactive bullet should be removed")

func test_given_active_bullet_when_removing_destroyed_then_bullet_remains():
	# Given: A game state with an active bullet
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)
	var bullet = BulletEntity.create("bullet_1", "tank_1", Position.create(5, 5), Direction.create(Direction.UP), 2, 1)
	game_state.add_bullet(bullet)
	
	# When: Removing destroyed entities
	SpawningService.remove_destroyed_entities(game_state)
	
	# Then: Active bullet remains
	assert_eq(game_state.bullets.size(), 1, "Active bullet should remain")

func test_given_mixed_entities_when_removing_destroyed_then_only_destroyed_removed():
	# Given: A game state with mix of alive/dead entities
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)
	
	var alive_tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(5, 5), Direction.create(Direction.UP))
	var dead_tank = TankEntity.create("tank_2", TankEntity.Type.ENEMY_BASIC, Position.create(10, 10), Direction.create(Direction.DOWN))
	dead_tank.take_damage(dead_tank.health.current)
	
	var active_bullet = BulletEntity.create("bullet_1", "tank_1", Position.create(7, 7), Direction.create(Direction.UP), 2, 1)
	var inactive_bullet = BulletEntity.create("bullet_2", "tank_2", Position.create(8, 8), Direction.create(Direction.DOWN), 2, 1)
	inactive_bullet.deactivate()
	
	game_state.add_tank(alive_tank)
	game_state.add_tank(dead_tank)
	game_state.add_bullet(active_bullet)
	game_state.add_bullet(inactive_bullet)
	
	# When: Removing destroyed entities
	SpawningService.remove_destroyed_entities(game_state)
	
	# Then: Only alive tank and active bullet remain
	assert_eq(game_state.tanks.size(), 1, "Should have 1 tank remaining")
	assert_eq(game_state.bullets.size(), 1, "Should have 1 bullet remaining")
	assert_not_null(game_state.get_tank("tank_1"), "Alive tank should remain")
	assert_null(game_state.get_tank("tank_2"), "Dead tank should be removed")
	assert_not_null(game_state.get_bullet("bullet_1"), "Active bullet should remain")
	assert_null(game_state.get_bullet("bullet_2"), "Inactive bullet should be removed")

func test_given_dead_enemy_when_removing_then_enemies_on_field_decreases():
	# Given: A game state with a dead enemy tank
	var stage = StageState.create(1, 26, 26)
	stage.add_enemy_spawn(Position.create(0, 0))
	var game_state = GameState.create(stage)
	var tank = SpawningService.spawn_enemy_tank(game_state, TankEntity.Type.ENEMY_BASIC, 0)
	game_state.add_tank(tank)
	var enemies_on_field_before = game_state.stage.enemies_on_field
	tank.take_damage(tank.health.current) # Kill tank
	
	# When: Removing destroyed entities
	SpawningService.remove_destroyed_entities(game_state)
	
	# Then: Enemies on field decreased
	assert_eq(game_state.stage.enemies_on_field, enemies_on_field_before - 1,
			  "Enemies on field should decrease when enemy removed")
