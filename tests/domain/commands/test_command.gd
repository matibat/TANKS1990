extends GutTest

## BDD Tests for Command Base Class
## Commands represent immutable inputs to the system

const Command = preload("res://src/domain/commands/command.gd")

func test_given_command_when_created_then_is_valid():
	# Given: Base command
	var command = Command.new()
	command.frame = 10
	
	# When: Checking validity
	var is_valid = command.is_valid()
	
	# Then: Command is valid by default
	assert_true(is_valid)

func test_given_command_with_frame_when_to_dict_then_includes_frame():
	# Given: Command with frame
	var command = Command.new()
	command.frame = 42
	
	# When: Converting to dictionary
	var dict = command.to_dict()
	
	# Then: Dictionary contains frame
	assert_eq(dict["frame"], 42)
