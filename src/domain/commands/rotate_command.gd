class_name RotateCommand
extends "res://src/domain/commands/command.gd"

## RotateCommand - Command to rotate a tank to a new direction
## Immutable value object representing a rotation request
## Part of DDD architecture - pure domain logic with no Godot dependencies

const Direction = preload("res://src/domain/value_objects/direction.gd")

var tank_id: String
var direction: Direction

## Static factory method to create a rotate command
static func create(p_tank_id: String, p_direction: Direction, p_frame: int = 0):
	var cmd = RotateCommand.new()
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
		"type": "rotate",
		"frame": frame,
		"tank_id": tank_id,
		"direction": direction.value
	}
