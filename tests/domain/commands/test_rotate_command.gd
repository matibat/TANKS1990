extends GutTest

## BDD Tests for RotateCommand
## RotateCommand represents a request to rotate a tank to a new direction

const RotateCommand = preload("res://src/domain/commands/rotate_command.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")

func test_given_tank_id_and_direction_when_rotate_command_created_then_has_correct_properties():
	# Given: Tank ID and direction
	var tank_id = "player_1"
	var direction = Direction.create(Direction.UP)
	
	# When: Creating rotate command
	var command = RotateCommand.create(tank_id, direction, 20)
	
	# Then: Command has correct properties
	assert_eq(command.tank_id, tank_id)
	assert_eq(command.direction.value, direction.value)
	assert_eq(command.frame, 20)

func test_given_valid_rotate_command_when_is_valid_then_returns_true():
	# Given: Valid rotate command
	var command = RotateCommand.create("tank_1", Direction.create(Direction.DOWN))
	
	# When: Checking validity
	var is_valid = command.is_valid()
	
	# Then: Command is valid
	assert_true(is_valid)

func test_given_empty_tank_id_when_is_valid_then_returns_false():
	# Given: Rotate command with empty tank ID
	var command = RotateCommand.create("", Direction.create(Direction.LEFT))
	
	# When: Checking validity
	var is_valid = command.is_valid()
	
	# Then: Command is invalid
	assert_false(is_valid)

func test_given_rotate_command_when_to_dict_then_includes_all_properties():
	# Given: Rotate command
	var direction = Direction.create(Direction.RIGHT)
	var command = RotateCommand.create("enemy_3", direction, 35)
	
	# When: Converting to dictionary
	var dict = command.to_dict()
	
	# Then: Dictionary contains all properties
	assert_eq(dict["type"], "rotate")
	assert_eq(dict["frame"], 35)
	assert_eq(dict["tank_id"], "enemy_3")
	assert_eq(dict["direction"], Direction.RIGHT)
