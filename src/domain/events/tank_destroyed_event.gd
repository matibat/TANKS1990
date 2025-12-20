class_name TankDestroyedEvent
extends "res://src/domain/events/domain_event.gd"

## TankDestroyedEvent - Event emitted when a tank is destroyed
## Immutable value object representing tank destruction
## Part of DDD architecture - pure domain logic with no Godot dependencies

const Position = preload("res://src/domain/value_objects/position.gd")

var tank_id: String
var position: Position
var killer_id: String # ID of tank that destroyed this tank (empty if not by tank)

## Static factory method to create a tank destroyed event
static func create(p_tank_id: String, p_position: Position, p_killer_id: String = "", p_frame: int = 0):
	var event = new()
	event.tank_id = p_tank_id
	event.position = p_position
	event.killer_id = p_killer_id
	event.frame = p_frame
	event.timestamp = Time.get_unix_time_from_system()
	return event

## Convert to dictionary
func to_dict() -> Dictionary:
	return {
		"type": "tank_destroyed",
		"frame": frame,
		"timestamp": timestamp,
		"tank_id": tank_id,
		"position": {"x": position.x, "y": position.y},
		"killer_id": killer_id
	}
