extends GutTest

const AIService = preload("res://src/domain/services/ai_service.gd")
const TankEntity = preload("res://src/domain/entities/tank_entity.gd")
const GameState = preload("res://src/domain/aggregates/game_state.gd")
const StageState = preload("res://src/domain/aggregates/stage_state.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")
const MoveCommand = preload("res://src/domain/commands/move_command.gd")
const FireCommand = preload("res://src/domain/commands/fire_command.gd")

func test_given_enemy_far_from_player_when_decide_action_then_returns_patrol_command():
	# Given: Enemy far from player (outside chase radius)
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)

	var player = TankEntity.create("player1", TankEntity.Type.PLAYER,
		Position.create(100, 100), Direction.create(Direction.UP))
	var enemy = TankEntity.create("enemy1", TankEntity.Type.ENEMY_BASIC,
		Position.create(320, 320), Direction.create(Direction.DOWN))

	game_state.add_tank(player)
	game_state.add_tank(enemy)

	# When: Decide action
	var command = AIService.decide_action(enemy, game_state, 0.1)

	# Then: Should return patrol command (MoveCommand)
	assert_not_null(command, "Should return a command")
	assert_true(command is MoveCommand, "Should return MoveCommand for patrol")

func test_given_enemy_in_chase_radius_when_decide_action_then_moves_toward_player():
	# Given: Enemy close enough to chase
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)

	var player = TankEntity.create("player1", TankEntity.Type.PLAYER,
		Position.create(100, 100), Direction.create(Direction.UP))
	var enemy = TankEntity.create("enemy1", TankEntity.Type.ENEMY_BASIC,
		Position.create(100, 200), Direction.create(Direction.DOWN))

	game_state.add_tank(player)
	game_state.add_tank(enemy)

	# When: Decide action
	var command = AIService.decide_action(enemy, game_state, 0.1)

	# Then: Should move up toward the player
	assert_not_null(command, "Should return a command")
	assert_true(command is MoveCommand, "Should return MoveCommand for chase")
	assert_eq(command.direction.value, Direction.UP, "Should chase toward player position")

func test_given_enemy_facing_player_when_can_shoot_then_returns_fire_command():
	# Given: Enemy facing player within shooting range
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)

	var player = TankEntity.create("player1", TankEntity.Type.PLAYER,
		Position.create(100, 100), Direction.create(Direction.UP))
	var enemy = TankEntity.create("enemy1", TankEntity.Type.ENEMY_BASIC,
		Position.create(100, 150), Direction.create(Direction.UP))

	enemy.cooldown_frames = 0

	game_state.add_tank(player)
	game_state.add_tank(enemy)

	# When: Decide action
	var command = AIService.decide_action(enemy, game_state, 0.1)

	# Then: Should return fire command
	assert_not_null(command, "Should return a command")
	assert_true(command is FireCommand, "Should return FireCommand when facing player")

func test_given_enemy_aligned_but_not_facing_player_then_turns_before_attacking():
	# Given: Enemy aligned but facing away
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)

	var player = TankEntity.create("player1", TankEntity.Type.PLAYER,
		Position.create(100, 100), Direction.create(Direction.UP))
	var enemy = TankEntity.create("enemy1", TankEntity.Type.ENEMY_BASIC,
		Position.create(100, 180), Direction.create(Direction.DOWN))

	game_state.add_tank(player)
	game_state.add_tank(enemy)

	# When: Decide action
	var command = AIService.decide_action(enemy, game_state, 0.1)

	# Then: Should rotate/move toward player axis
	assert_not_null(command, "Should return a command")
	assert_true(command is MoveCommand, "Should move to face the player")
	assert_eq(command.direction.value, Direction.UP, "Should turn toward the aligned player")

func test_given_fast_enemy_when_farther_than_basic_then_chases_due_to_extended_radius():
	# Given: Fast enemy slightly outside basic chase range but inside fast range
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)

	var player = TankEntity.create("player1", TankEntity.Type.PLAYER,
		Position.create(260, 100), Direction.create(Direction.UP))
	var enemy = TankEntity.create("enemy1", TankEntity.Type.ENEMY_FAST,
		Position.create(100, 100), Direction.create(Direction.UP))

	game_state.add_tank(player)
	game_state.add_tank(enemy)

	# When: Decide action
	var command = AIService.decide_action(enemy, game_state, 0.1)

	# Then: Should choose to chase right toward the player
	assert_not_null(command, "Fast enemy should return command")
	assert_true(command is MoveCommand, "Should move when chasing")
	assert_eq(command.direction.value, Direction.RIGHT, "Fast enemy should chase with larger radius")

func test_given_armored_enemy_when_beyond_cautious_radius_then_patrols():
	# Given: Armored enemy stays cautious until close
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)

	var player = TankEntity.create("player1", TankEntity.Type.PLAYER,
		Position.create(260, 100), Direction.create(Direction.UP))
	var enemy = TankEntity.create("enemy1", TankEntity.Type.ENEMY_ARMORED,
		Position.create(100, 100), Direction.create(Direction.RIGHT))

	game_state.add_tank(player)
	game_state.add_tank(enemy)

	# When: Decide action
	var command = AIService.decide_action(enemy, game_state, 0.1)

	# Then: Should keep patrolling (not chase yet)
	assert_not_null(command, "Armored enemy should return command")
	assert_true(command is MoveCommand, "Armored enemy patrols when far")

func test_given_power_enemy_when_aligned_then_prefers_shooting_at_longer_range():
	# Given: Power enemy fires from slightly longer distance
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)

	var player = TankEntity.create("player1", TankEntity.Type.PLAYER,
		Position.create(100, 100), Direction.create(Direction.UP))
	var enemy = TankEntity.create("enemy1", TankEntity.Type.ENEMY_POWER,
		Position.create(100, 244), Direction.create(Direction.UP))

	enemy.cooldown_frames = 0

	game_state.add_tank(player)
	game_state.add_tank(enemy)

	# When: Decide action
	var command = AIService.decide_action(enemy, game_state, 0.1)

	# Then: Should fire because power tanks shoot more often
	assert_not_null(command, "Power enemy should return command")
	assert_true(command is FireCommand, "Power enemy should prefer shooting when aligned")

func test_given_cooldown_active_when_decide_then_no_fire_command():
	# Given: Enemy with active cooldown facing player
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)

	var player = TankEntity.create("player1", TankEntity.Type.PLAYER,
		Position.create(100, 100), Direction.create(Direction.UP))
	var enemy = TankEntity.create("enemy1", TankEntity.Type.ENEMY_BASIC,
		Position.create(100, 150), Direction.create(Direction.UP))

	enemy.cooldown_frames = 30

	game_state.add_tank(player)
	game_state.add_tank(enemy)

	# When: Decide action
	var command = AIService.decide_action(enemy, game_state, 0.1)

	# Then: Should not fire (return move command instead)
	assert_not_null(command, "Should return a command")
	assert_true(command is MoveCommand, "Should not fire when cooldown active")

func test_enemy_holds_direction_until_hold_frames_elapse():
	# Given: Enemy chasing player that changes axis rapidly
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)

	var enemy = TankEntity.create("enemy_hold", TankEntity.Type.ENEMY_BASIC,
		Position.create(100, 100), Direction.create(Direction.RIGHT))
	var player = TankEntity.create("player_hold", TankEntity.Type.PLAYER,
		Position.create(105, 103), Direction.create(Direction.UP))

	AIService.clear_direction_state(enemy.id)
	game_state.add_tank(enemy)
	game_state.add_tank(player)

	var profile = AIService._get_ai_profile(enemy.tank_type)
	var hold_frames = profile["direction_hold_frames"]

	# When: First decision should chase to the right
	var initial = AIService.decide_action(enemy, game_state, 0.1)
	assert_true(initial is MoveCommand, "Should initially chase instead of firing")
	var initial_direction_value = initial.direction.value

	# Move player to a new axis that would normally require switching to UP
	player.position = Position.create(98, 94)
	for _i in range(hold_frames):
		game_state.frame += 1
		var held = AIService.decide_action(enemy, game_state, 0.1)
		assert_eq(held.direction.value, initial_direction_value, "Should keep previous direction until real frames advance")

	# Simulate the frame-based hold expiring before switching to the new axis
	game_state.frame += 1
	var swung = AIService.decide_action(enemy, game_state, 0.1)
	assert_eq(swung.direction.value, Direction.UP, "Should switch direction after hold frames")
