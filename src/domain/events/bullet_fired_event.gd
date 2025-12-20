class_name BulletFiredEvent
extends "res://src/domain/events/domain_event.gd"

## BulletFiredEvent - Event emitted when a bullet is fired
## Immutable value object representing a bullet being fired
## Part of DDD architecture - pure domain logic with no Godot dependencies

const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")

var bullet_id: String
var tank_id: String
var position: Position
var direction: Direction

## Static factory method to create a bullet fired event
static func create(p_bullet_id: String, p_tank_id: String, p_position: Position, p_direction: Direction, p_frame: int = 0):
	var event = BulletFiredEvent.new()
	event.bullet_id = p_bullet_id
	event.tank_id = p_tank_id
	event.position = p_position
	event.direction = p_direction
	event.frame = p_frame
	event.timestamp = Time.get_unix_time_from_system()
	return event

## Convert to dictionary
func to_dict() -> Dictionary:
	return {
		"type": "bullet_fired",
		"frame": frame,
		"timestamp": timestamp,
		"bullet_id": bullet_id,
		"tank_id": tank_id,
		"position": {"x": position.x, "y": position.y},
		"direction": direction.value
	}
