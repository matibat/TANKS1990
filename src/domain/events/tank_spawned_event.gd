class_name TankSpawnedEvent
extends "res://src/domain/events/domain_event.gd"

## TankSpawnedEvent - Event emitted when a tank is spawned
## Immutable value object representing a tank spawn
## Part of DDD architecture - pure domain logic with no Godot dependencies

const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")

var tank_id: String
var tank_type: int
var position: Position
var direction: Direction

## Static factory method to create a tank spawned event
static func create(p_tank_id: String, p_tank_type: int, p_position: Position, p_direction: Direction, p_frame: int = 0):
	var event = TankSpawnedEvent.new()
	event.tank_id = p_tank_id
	event.tank_type = p_tank_type
	event.position = p_position
	event.direction = p_direction
	event.frame = p_frame
	event.timestamp = Time.get_unix_time_from_system()
	return event

## Convert to dictionary
func to_dict() -> Dictionary:
	return {
		"type": "tank_spawned",
		"frame": frame,
		"timestamp": timestamp,
		"tank_id": tank_id,
		"tank_type": tank_type,
		"position": {"x": position.x, "y": position.y},
		"direction": direction.value
	}
