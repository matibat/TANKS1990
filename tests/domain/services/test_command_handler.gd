extends GutTest

## BDD Tests for CommandHandler Service
## CommandHandler executes commands on GameState and emits events

const CommandHandler = preload("res://src/domain/services/command_handler.gd")
const GameState = preload("res://src/domain/aggregates/game_state.gd")
const StageState = preload("res://src/domain/aggregates/stage_state.gd")
const TankEntity = preload("res://src/domain/entities/tank_entity.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")
const MoveCommand = preload("res://src/domain/commands/move_command.gd")
const FireCommand = preload("res://src/domain/commands/fire_command.gd")
const RotateCommand = preload("res://src/domain/commands/rotate_command.gd")
const PauseCommand = preload("res://src/domain/commands/pause_command.gd")
const TankMovedEvent = preload("res://src/domain/events/tank_moved_event.gd")
const BulletFiredEvent = preload("res://src/domain/events/bullet_fired_event.gd")

## Helper: Create game state with player tank
func create_game_state_with_player_tank() -> GameState:
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)
	
	# Add player tank at position (5, 5) facing UP
	var tank_pos = Position.create(5, 5)
	var tank_dir = Direction.create(Direction.UP)
	var tank = TankEntity.create("player_1", TankEntity.Type.PLAYER, tank_pos, tank_dir)
	game_state.add_tank(tank)
	
	return game_state

func test_given_invalid_command_when_executed_then_returns_empty_events():
	# Given: Game state and invalid command (empty tank ID)
	var game_state = create_game_state_with_player_tank()
	var command = MoveCommand.create("", Direction.create(Direction.UP))
	
	# When: Executing invalid command
	var events = CommandHandler.execute_command(game_state, command)
	
	# Then: No events emitted
	assert_eq(events.size(), 0)

func test_given_valid_move_command_when_executed_then_emits_tank_moved_event():
	# Given: Game state with tank and valid move command
	var game_state = create_game_state_with_player_tank()
	var tank = game_state.get_player_tanks()[0]
	var old_pos = tank.position
	var command = MoveCommand.create(tank.id, Direction.create(Direction.RIGHT), 10)
	
	# When: Executing command
	var events = CommandHandler.execute_command(game_state, command)
	
	# Then: Tank moved event emitted
	assert_eq(events.size(), 1)
	assert_true(events[0] is TankMovedEvent)
	var event = events[0] as TankMovedEvent
	assert_eq(event.tank_id, tank.id)
	assert_eq(event.old_position.x, old_pos.x)
	assert_eq(event.old_position.y, old_pos.y)
	assert_eq(event.new_position.x, old_pos.x + 1)
	assert_eq(event.frame, 10)

func test_given_move_command_to_blocked_position_when_executed_then_no_events():
	# Given: Game state with tank at edge of stage
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)
	var tank_pos = Position.create(0, 0) # At left edge
	var tank_dir = Direction.create(Direction.LEFT)
	var tank = TankEntity.create("player_1", TankEntity.Type.PLAYER, tank_pos, tank_dir)
	game_state.add_tank(tank)
	
	# When: Trying to move left (out of bounds)
	var command = MoveCommand.create(tank.id, Direction.create(Direction.LEFT))
	var events = CommandHandler.execute_command(game_state, command)
	
	# Then: No events emitted (movement blocked)
	assert_eq(events.size(), 0)

func test_given_fire_command_when_executed_then_emits_bullet_fired_event():
	# Given: Game state with tank and fire command
	var game_state = create_game_state_with_player_tank()
	var tank = game_state.get_player_tanks()[0]
	var command = FireCommand.create(tank.id, 20)
	
	# When: Executing fire command
	var events = CommandHandler.execute_command(game_state, command)
	
	# Then: Bullet fired event emitted
	assert_eq(events.size(), 1)
	assert_true(events[0] is BulletFiredEvent)
	var event = events[0] as BulletFiredEvent
	assert_eq(event.tank_id, tank.id)
	assert_eq(event.frame, 20)

func test_given_fire_command_with_cooldown_when_executed_then_no_events():
	# Given: Game state with tank that has cooldown
	var game_state = create_game_state_with_player_tank()
	var tank = game_state.get_player_tanks()[0]
	tank.cooldown_frames = 10 # Tank is on cooldown
	var command = FireCommand.create(tank.id)
	
	# When: Executing fire command
	var events = CommandHandler.execute_command(game_state, command)
	
	# Then: No events (tank on cooldown)
	assert_eq(events.size(), 0)

func test_given_rotate_command_when_executed_then_tank_direction_changed():
	# Given: Game state with tank facing UP
	var game_state = create_game_state_with_player_tank()
	var tank = game_state.get_player_tanks()[0]
	assert_eq(tank.direction.value, Direction.UP)
	
	# When: Executing rotate command to face RIGHT
	var new_direction = Direction.create(Direction.RIGHT)
	var command = RotateCommand.create(tank.id, new_direction, 30)
	var events = CommandHandler.execute_command(game_state, command)
	
	# Then: Tank direction changed (rotate doesn't emit events, just changes state)
	assert_eq(tank.direction.value, Direction.RIGHT)

func test_given_pause_command_when_executed_then_game_paused():
	# Given: Game state not paused
	var game_state = create_game_state_with_player_tank()
	assert_false(game_state.is_paused)
	
	# When: Executing pause command
	var command = PauseCommand.create(true, 40)
	var events = CommandHandler.execute_command(game_state, command)
	
	# Then: Game is paused
	assert_true(game_state.is_paused)

func test_given_unpause_command_when_executed_then_game_unpaused():
	# Given: Game state paused
	var game_state = create_game_state_with_player_tank()
	game_state.is_paused = true
	
	# When: Executing unpause command
	var command = PauseCommand.create(false, 45)
	var events = CommandHandler.execute_command(game_state, command)
	
	# Then: Game is not paused
	assert_false(game_state.is_paused)

func test_given_nonexistent_tank_when_move_command_executed_then_no_events():
	# Given: Game state and command for nonexistent tank
	var game_state = create_game_state_with_player_tank()
	var command = MoveCommand.create("nonexistent_tank", Direction.create(Direction.UP))
	
	# When: Executing command
	var events = CommandHandler.execute_command(game_state, command)
	
	# Then: No events emitted
	assert_eq(events.size(), 0)
