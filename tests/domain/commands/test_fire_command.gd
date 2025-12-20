extends GutTest

## BDD Tests for FireCommand
## FireCommand represents a request for a tank to fire a bullet

const FireCommand = preload("res://src/domain/commands/fire_command.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")

func test_given_tank_id_when_fire_command_created_then_has_correct_properties():
	# Given: Tank ID
	var tank_id = "player_1"
	
	# When: Creating fire command
	var command = FireCommand.create(tank_id, 15)
	
	# Then: Command has correct properties
	assert_eq(command.tank_id, tank_id)
	assert_eq(command.frame, 15)

func test_given_valid_fire_command_when_is_valid_then_returns_true():
	# Given: Valid fire command
	var command = FireCommand.create("tank_1")
	
	# When: Checking validity
	var is_valid = command.is_valid()
	
	# Then: Command is valid
	assert_true(is_valid)

func test_given_empty_tank_id_when_is_valid_then_returns_false():
	# Given: Fire command with empty tank ID
	var command = FireCommand.create("")
	
	# When: Checking validity
	var is_valid = command.is_valid()
	
	# Then: Command is invalid
	assert_false(is_valid)

func test_given_fire_command_when_to_dict_then_includes_all_properties():
	# Given: Fire command
	var command = FireCommand.create("enemy_2", 30)
	
	# When: Converting to dictionary
	var dict = command.to_dict()
	
	# Then: Dictionary contains all properties
	assert_eq(dict["type"], "fire")
	assert_eq(dict["frame"], 30)
	assert_eq(dict["tank_id"], "enemy_2")
