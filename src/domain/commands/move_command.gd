class_name MoveCommand
extends "res://src/domain/commands/command.gd"

## MoveCommand - Command to move a tank in a direction
## Immutable value object representing a movement request
## Part of DDD architecture - pure domain logic with no Godot dependencies

const Direction = preload("res://src/domain/value_objects/direction.gd")

var tank_id: String
var direction: Direction

## Static factory method to create a move command
static func create(p_tank_id: String, p_direction: Direction, p_frame: int = 0):
	var cmd = MoveCommand.new()
	cmd.tank_id = p_tank_id
	cmd.direction = p_direction
	cmd.frame = p_frame
	return cmd

## Validate command
func is_valid() -> bool:
	return tank_id != "" and direction != null

## Convert to dictionary
func to_dict() -> Dictionary:
	return {
		"type": "move",
		"frame": frame,
		"tank_id": tank_id,
		"direction": direction.value
	}
