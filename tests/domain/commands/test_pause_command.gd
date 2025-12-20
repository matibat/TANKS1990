extends GutTest

## BDD Tests for PauseCommand
## PauseCommand represents a request to pause or unpause the game

const PauseCommand = preload("res://src/domain/commands/pause_command.gd")

func test_given_pause_true_when_pause_command_created_then_has_correct_properties():
	# Given: Pause flag true
	var should_pause = true
	
	# When: Creating pause command
	var command = PauseCommand.create(should_pause, 40)
	
	# Then: Command has correct properties
	assert_eq(command.should_pause, should_pause)
	assert_eq(command.frame, 40)

func test_given_pause_false_when_pause_command_created_then_has_correct_properties():
	# Given: Pause flag false
	var should_pause = false
	
	# When: Creating pause command
	var command = PauseCommand.create(should_pause, 45)
	
	# Then: Command has correct properties
	assert_eq(command.should_pause, should_pause)
	assert_eq(command.frame, 45)

func test_given_pause_command_when_is_valid_then_returns_true():
	# Given: Pause command
	var command = PauseCommand.create(true)
	
	# When: Checking validity
	var is_valid = command.is_valid()
	
	# Then: Command is valid
	assert_true(is_valid)

func test_given_pause_command_when_to_dict_then_includes_all_properties():
	# Given: Pause command
	var command = PauseCommand.create(true, 50)
	
	# When: Converting to dictionary
	var dict = command.to_dict()
	
	# Then: Dictionary contains all properties
	assert_eq(dict["type"], "pause")
	assert_eq(dict["frame"], 50)
	assert_eq(dict["should_pause"], true)
