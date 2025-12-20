class_name FireCommand
extends "res://src/domain/commands/command.gd"

## FireCommand - Command for a tank to fire a bullet
## Immutable value object representing a fire request
## Part of DDD architecture - pure domain logic with no Godot dependencies

var tank_id: String

## Static factory method to create a fire command
static func create(p_tank_id: String, p_frame: int = 0):
	var cmd = new()
	cmd.tank_id = p_tank_id
	cmd.frame = p_frame
	return cmd

## Validate command
func is_valid() -> bool:
	return tank_id != ""

## Convert to dictionary
func to_dict() -> Dictionary:
	return {
		"type": "fire",
		"frame": frame,
		"tank_id": tank_id
	}
