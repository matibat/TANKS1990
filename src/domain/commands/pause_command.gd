class_name PauseCommand
extends "res://src/domain/commands/command.gd"

## PauseCommand - Command to pause or unpause the game
## Immutable value object representing a pause request
## Part of DDD architecture - pure domain logic with no Godot dependencies

var should_pause: bool

## Static factory method to create a pause command
static func create(p_should_pause: bool, p_frame: int = 0):
	var cmd = PauseCommand.new()
	cmd.should_pause = p_should_pause
	cmd.frame = p_frame
	return cmd

## Validate command
func is_valid() -> bool:
	return true # Pause command is always valid

## Convert to dictionary
func to_dict() -> Dictionary:
	return {
		"type": "pause",
		"frame": frame,
		"should_pause": should_pause
	}
