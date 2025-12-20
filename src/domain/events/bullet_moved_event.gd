class_name BulletMovedEvent
extends "res://src/domain/events/domain_event.gd"

## BulletMovedEvent - Event emitted when a bullet moves
## Immutable value object representing bullet movement
## Part of DDD architecture - pure domain logic with no Godot dependencies

const Position = preload("res://src/domain/value_objects/position.gd")

var bullet_id: String
var old_position: Position
var new_position: Position

## Static factory method to create a bullet moved event
static func create(p_bullet_id: String, p_old_position: Position, p_new_position: Position, p_frame: int = 0):
	var event = BulletMovedEvent.new()
	event.bullet_id = p_bullet_id
	event.old_position = p_old_position
	event.new_position = p_new_position
	event.frame = p_frame
	event.timestamp = Time.get_unix_time_from_system()
	return event

## Convert to dictionary
func to_dict() -> Dictionary:
	return {
		"type": "bullet_moved",
		"frame": frame,
		"timestamp": timestamp,
		"bullet_id": bullet_id,
		"old_position": {"x": old_position.x, "y": old_position.y},
		"new_position": {"x": new_position.x, "y": new_position.y}
	}
