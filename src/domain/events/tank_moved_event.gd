class_name TankMovedEvent
extends "res://src/domain/events/domain_event.gd"

## TankMovedEvent - Event emitted when a tank moves
## Immutable value object representing a tank movement
## Part of DDD architecture - pure domain logic with no Godot dependencies

const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")

var tank_id: String
var old_position: Position
var new_position: Position
var direction: Direction

## Static factory method to create a tank moved event
static func create(p_tank_id: String, p_old_position: Position, p_new_position: Position, p_direction: Direction, p_frame: int = 0):
	var event = new()
	event.tank_id = p_tank_id
	event.old_position = p_old_position
	event.new_position = p_new_position
	event.direction = p_direction
	event.frame = p_frame
	event.timestamp = Time.get_unix_time_from_system()
	return event

## Convert to dictionary
func to_dict() -> Dictionary:
	return {
		"type": "tank_moved",
		"frame": frame,
		"timestamp": timestamp,
		"tank_id": tank_id,
		"old_position": {"x": old_position.x, "y": old_position.y},
		"new_position": {"x": new_position.x, "y": new_position.y},
		"direction": direction.value
	}
