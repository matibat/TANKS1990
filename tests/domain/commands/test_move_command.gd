extends GutTest

## BDD Tests for MoveCommand
## MoveCommand represents a request to move a tank in a direction

const MoveCommand = preload("res://src/domain/commands/move_command.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")

func test_given_tank_id_and_direction_when_move_command_created_then_has_correct_properties():
	# Given: Tank ID and direction
	var tank_id = "player_1"
	var direction = Direction.create(Direction.RIGHT)
	
	# When: Creating move command
	var command = MoveCommand.create(tank_id, direction, 10)
	
	# Then: Command has correct properties
	assert_eq(command.tank_id, tank_id)
	assert_eq(command.direction.value, direction.value)
	assert_eq(command.frame, 10)

func test_given_valid_move_command_when_is_valid_then_returns_true():
	# Given: Valid move command
	var command = MoveCommand.create("tank_1", Direction.create(Direction.UP))
	
	# When: Checking validity
	var is_valid = command.is_valid()
	
	# Then: Command is valid
	assert_true(is_valid)

func test_given_empty_tank_id_when_is_valid_then_returns_false():
	# Given: Move command with empty tank ID
	var command = MoveCommand.create("", Direction.create(Direction.UP))
	
	# When: Checking validity
	var is_valid = command.is_valid()
	
	# Then: Command is invalid
	assert_false(is_valid)

func test_given_move_command_when_to_dict_then_includes_all_properties():
	# Given: Move command
	var direction = Direction.create(Direction.LEFT)
	var command = MoveCommand.create("player_1", direction, 25)
	
	# When: Converting to dictionary
	var dict = command.to_dict()
	
	# Then: Dictionary contains all properties
	assert_eq(dict["type"], "move")
	assert_eq(dict["frame"], 25)
	assert_eq(dict["tank_id"], "player_1")
	assert_eq(dict["direction"], Direction.LEFT)
