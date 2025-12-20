extends GutTest

## BDD Tests for GameState Aggregate (Root Aggregate)
## Test-first approach: Write behavior tests before implementation

const GameState = preload("res://src/domain/aggregates/game_state.gd")
const StageState = preload("res://src/domain/aggregates/stage_state.gd")
const TankEntity = preload("res://src/domain/entities/tank_entity.gd")
const BulletEntity = preload("res://src/domain/entities/bullet_entity.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")
## Test: GameState Creation
func test_given_stage_when_game_state_created_then_has_correct_initial_state():
	# Given: A stage
	var stage = StageState.create(1, 26, 26)
	var player_lives = 3
	
	# When: GameState is created
	var game_state = GameState.create(stage, player_lives)
	
	# Then: GameState has correct initial properties
	assert_not_null(game_state, "GameState should be created")
	assert_eq(game_state.frame, 0, "Frame should start at 0")
	assert_eq(game_state.player_lives, player_lives, "Should have correct player lives")
	assert_eq(game_state.score, 0, "Score should start at 0")
	assert_false(game_state.is_paused, "Game should not be paused initially")
	assert_false(game_state.is_game_over, "Game should not be over initially")
	assert_not_null(game_state.stage, "Should have stage reference")
	assert_eq(game_state.tanks.size(), 0, "Should start with no tanks")
	assert_eq(game_state.bullets.size(), 0, "Should start with no bullets")

## Test: Entity ID Generation
func test_given_game_state_when_generate_entity_id_then_is_unique():
	# Given: A game state
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage, 3)
	
	# When: Generating multiple IDs
	var id1 = game_state.generate_entity_id("tank")
	var id2 = game_state.generate_entity_id("tank")
	var id3 = game_state.generate_entity_id("bullet")
	
	# Then: Each ID is unique
	assert_ne(id1, id2, "Tank IDs should be unique")
	assert_ne(id2, id3, "Different entity type IDs should be unique")
	assert_string_contains(id1, "tank", "Tank ID should contain prefix")
	assert_string_contains(id3, "bullet", "Bullet ID should contain prefix")

## Test: Tank Management - Add/Remove/Get
func test_given_game_state_when_tank_added_then_can_retrieve_tank():
	# Given: A game state
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage, 3)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER,
								 Position.create(5, 5), Direction.create(Direction.UP))
	
	# When: Tank is added
	game_state.add_tank(tank)
	
	# Then: Tank can be retrieved
	var retrieved = game_state.get_tank("tank_1")
	assert_not_null(retrieved, "Tank should be retrievable")
	assert_eq(retrieved.id, "tank_1", "Retrieved tank should have correct ID")
	assert_eq(game_state.tanks.size(), 1, "Should have 1 tank in collection")

func test_given_game_state_with_tank_when_removed_then_cannot_retrieve():
	# Given: A game state with a tank
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage, 3)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER,
								 Position.create(5, 5), Direction.create(Direction.UP))
	game_state.add_tank(tank)
	
	# When: Tank is removed
	game_state.remove_tank("tank_1")
	
	# Then: Tank cannot be retrieved
	var retrieved = game_state.get_tank("tank_1")
	assert_null(retrieved, "Removed tank should not be retrievable")
	assert_eq(game_state.tanks.size(), 0, "Should have 0 tanks in collection")

func test_given_game_state_when_nonexistent_tank_retrieved_then_returns_null():
	# Given: A game state without tanks
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage, 3)
	
	# When: Retrieving nonexistent tank
	var retrieved = game_state.get_tank("nonexistent")
	
	# Then: Returns null
	assert_null(retrieved, "Should return null for nonexistent tank")

func test_given_game_state_with_multiple_tanks_when_get_all_tanks_then_returns_all():
	# Given: A game state with multiple tanks
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage, 3)
	var tank1 = TankEntity.create("tank_1", TankEntity.Type.PLAYER,
								  Position.create(5, 5), Direction.create(Direction.UP))
	var tank2 = TankEntity.create("tank_2", TankEntity.Type.ENEMY_BASIC,
								  Position.create(10, 10), Direction.create(Direction.DOWN))
	
	# When: Adding tanks and getting all
	game_state.add_tank(tank1)
	game_state.add_tank(tank2)
	var all_tanks = game_state.get_all_tanks()
	
	# Then: All tanks are returned
	assert_eq(all_tanks.size(), 2, "Should return all 2 tanks")

## Test: Tank Filtering
func test_given_game_state_with_mixed_tanks_when_get_player_tanks_then_returns_only_players():
	# Given: A game state with player and enemy tanks
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage, 3)
	var player_tank = TankEntity.create("player_1", TankEntity.Type.PLAYER,
										Position.create(5, 5), Direction.create(Direction.UP))
	var enemy_tank = TankEntity.create("enemy_1", TankEntity.Type.ENEMY_BASIC,
									   Position.create(10, 10), Direction.create(Direction.DOWN))
	
	# When: Adding tanks and getting player tanks
	game_state.add_tank(player_tank)
	game_state.add_tank(enemy_tank)
	var player_tanks = game_state.get_player_tanks()
	
	# Then: Only player tanks are returned
	assert_eq(player_tanks.size(), 1, "Should return only 1 player tank")
	assert_eq(player_tanks[0].id, "player_1", "Returned tank should be player tank")

func test_given_game_state_with_mixed_tanks_when_get_enemy_tanks_then_returns_only_enemies():
	# Given: A game state with player and enemy tanks
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage, 3)
	var player_tank = TankEntity.create("player_1", TankEntity.Type.PLAYER,
										Position.create(5, 5), Direction.create(Direction.UP))
	var enemy1 = TankEntity.create("enemy_1", TankEntity.Type.ENEMY_BASIC,
								   Position.create(10, 10), Direction.create(Direction.DOWN))
	var enemy2 = TankEntity.create("enemy_2", TankEntity.Type.ENEMY_FAST,
								   Position.create(15, 15), Direction.create(Direction.LEFT))
	
	# When: Adding tanks and getting enemy tanks
	game_state.add_tank(player_tank)
	game_state.add_tank(enemy1)
	game_state.add_tank(enemy2)
	var enemy_tanks = game_state.get_enemy_tanks()
	
	# Then: Only enemy tanks are returned
	assert_eq(enemy_tanks.size(), 2, "Should return only 2 enemy tanks")

## Test: Bullet Management
func test_given_game_state_when_bullet_added_then_can_retrieve_bullet():
	# Given: A game state
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage, 3)
	var bullet = BulletEntity.create("bullet_1", "tank_1",
									 Position.create(5, 5), Direction.create(Direction.UP),
									 2, 1)
	
	# When: Bullet is added
	game_state.add_bullet(bullet)
	
	# Then: Bullet can be retrieved
	var retrieved = game_state.get_bullet("bullet_1")
	assert_not_null(retrieved, "Bullet should be retrievable")
	assert_eq(retrieved.id, "bullet_1", "Retrieved bullet should have correct ID")
	assert_eq(game_state.bullets.size(), 1, "Should have 1 bullet in collection")

func test_given_game_state_with_bullet_when_removed_then_cannot_retrieve():
	# Given: A game state with a bullet
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage, 3)
	var bullet = BulletEntity.create("bullet_1", "tank_1",
									 Position.create(5, 5), Direction.create(Direction.UP),
									 2, 1)
	game_state.add_bullet(bullet)
	
	# When: Bullet is removed
	game_state.remove_bullet("bullet_1")
	
	# Then: Bullet cannot be retrieved
	var retrieved = game_state.get_bullet("bullet_1")
	assert_null(retrieved, "Removed bullet should not be retrievable")
	assert_eq(game_state.bullets.size(), 0, "Should have 0 bullets in collection")

func test_given_game_state_with_multiple_bullets_when_get_all_bullets_then_returns_all():
	# Given: A game state with multiple bullets
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage, 3)
	var bullet1 = BulletEntity.create("bullet_1", "tank_1",
									  Position.create(5, 5), Direction.create(Direction.UP),
									  2, 1)
	var bullet2 = BulletEntity.create("bullet_2", "tank_2",
									  Position.create(10, 10), Direction.create(Direction.DOWN),
									  2, 1)
	
	# When: Adding bullets and getting all
	game_state.add_bullet(bullet1)
	game_state.add_bullet(bullet2)
	var all_bullets = game_state.get_all_bullets()
	
	# Then: All bullets are returned
	assert_eq(all_bullets.size(), 2, "Should return all 2 bullets")

## Test: Frame Advancement
func test_given_game_state_when_advance_frame_then_frame_increments():
	# Given: A game state
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage, 3)
	var initial_frame = game_state.frame
	
	# When: Frame is advanced
	game_state.advance_frame()
	
	# Then: Frame number increments
	assert_eq(game_state.frame, initial_frame + 1, "Frame should increment by 1")

func test_given_game_state_when_advance_frame_multiple_times_then_frame_increments_correctly():
	# Given: A game state
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage, 3)
	
	# When: Frame is advanced multiple times
	for i in range(10):
		game_state.advance_frame()
	
	# Then: Frame number is correct
	assert_eq(game_state.frame, 10, "Frame should be 10 after 10 advances")

## Test: Pause/Unpause
func test_given_game_state_when_paused_then_is_paused_true():
	# Given: A game state
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage, 3)
	
	# When: Game is paused
	game_state.pause()
	
	# Then: is_paused is true
	assert_true(game_state.is_paused, "Game should be paused")

func test_given_paused_game_state_when_unpaused_then_is_paused_false():
	# Given: A paused game state
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage, 3)
	game_state.pause()
	
	# When: Game is unpaused
	game_state.unpause()
	
	# Then: is_paused is false
	assert_false(game_state.is_paused, "Game should not be paused")

## Test: Game Over
func test_given_game_state_when_end_game_then_is_game_over_true():
	# Given: A game state
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage, 3)
	
	# When: Game is ended
	game_state.end_game()
	
	# Then: is_game_over is true
	assert_true(game_state.is_game_over, "Game should be over")

## Test: Stage Completion Detection
func test_given_game_state_with_incomplete_stage_when_is_stage_complete_then_returns_false():
	# Given: A game state with incomplete stage
	var stage = StageState.create(1, 26, 26)
	stage.enemies_remaining = 10
	var game_state = GameState.create(stage, 3)
	
	# When: Checking if stage is complete
	var is_complete = game_state.is_stage_complete()
	
	# Then: Stage is not complete
	assert_false(is_complete, "Stage should not be complete")

func test_given_game_state_with_complete_stage_when_is_stage_complete_then_returns_true():
	# Given: A game state with complete stage
	var stage = StageState.create(1, 26, 26)
	stage.enemies_remaining = 0
	stage.enemies_on_field = 0
	var game_state = GameState.create(stage, 3)
	
	# When: Checking if stage is complete
	var is_complete = game_state.is_stage_complete()
	
	# Then: Stage is complete
	assert_true(is_complete, "Stage should be complete")

## Test: Stage Failure Detection
func test_given_game_state_with_alive_base_when_is_stage_failed_then_returns_false():
	# Given: A game state with alive base
	var stage = StageState.create(1, 26, 26)
	stage.set_base(Position.create(12, 24))
	var game_state = GameState.create(stage, 3)
	
	# When: Checking if stage is failed
	var is_failed = game_state.is_stage_failed()
	
	# Then: Stage is not failed
	assert_false(is_failed, "Stage should not be failed")

func test_given_game_state_with_destroyed_base_when_is_stage_failed_then_returns_true():
	# Given: A game state with destroyed base
	var stage = StageState.create(1, 26, 26)
	stage.set_base(Position.create(12, 24))
	stage.base.take_damage(stage.base.health.current)
	var game_state = GameState.create(stage, 3)
	
	# When: Checking if stage is failed
	var is_failed = game_state.is_stage_failed()
	
	# Then: Stage is failed
	assert_true(is_failed, "Stage should be failed")

## Test: Invariants
func test_given_valid_game_state_when_check_invariants_then_returns_true():
	# Given: A valid game state
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage, 3)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER,
								 Position.create(5, 5), Direction.create(Direction.UP))
	game_state.add_tank(tank)
	
	# When: Checking invariants
	var valid = game_state.check_invariants()
	
	# Then: Invariants are satisfied
	assert_true(valid, "Valid game state should satisfy invariants")

func test_given_game_state_with_negative_lives_when_check_invariants_then_returns_false():
	# Given: A game state with negative lives
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage, 3)
	game_state.player_lives = -1 # Invalid state
	
	# When: Checking invariants
	var valid = game_state.check_invariants()
	
	# Then: Invariants are violated
	assert_false(valid, "Negative lives should violate invariants")

func test_given_game_state_with_tank_out_of_bounds_when_check_invariants_then_returns_false():
	# Given: A game state with tank out of bounds
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage, 3)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER,
								 Position.create(30, 30), Direction.create(Direction.UP)) # Out of bounds
	game_state.add_tank(tank)
	
	# When: Checking invariants
	var valid = game_state.check_invariants()
	
	# Then: Invariants are violated
	assert_false(valid, "Tank out of bounds should violate invariants")

## Test: Serialization
func test_given_game_state_when_serialized_then_contains_all_data():
	# Given: A game state with data
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage, 3)
	game_state.score = 1000
	game_state.advance_frame()
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER,
								 Position.create(5, 5), Direction.create(Direction.UP))
	game_state.add_tank(tank)
	
	# When: Serializing
	var dict = game_state.to_dict()
	
	# Then: Dictionary contains all data
	assert_has(dict, "frame", "Should have frame")
	assert_has(dict, "player_lives", "Should have player_lives")
	assert_has(dict, "score", "Should have score")
	assert_has(dict, "is_paused", "Should have is_paused")
	assert_has(dict, "is_game_over", "Should have is_game_over")
	assert_has(dict, "stage", "Should have stage")
	assert_has(dict, "tanks", "Should have tanks")
	assert_has(dict, "bullets", "Should have bullets")
	assert_eq(dict["score"], 1000, "Score should match")
	assert_eq(dict["frame"], 1, "Frame should match")
