class_name BulletDestroyedEvent
extends "res://src/domain/events/domain_event.gd"

## BulletDestroyedEvent - Event emitted when a bullet is destroyed
## Immutable value object representing bullet destruction
## Part of DDD architecture - pure domain logic with no Godot dependencies

const Position = preload("res://src/domain/value_objects/position.gd")

var bullet_id: String
var position: Position
var reason: String # Reason for destruction (e.g., "hit_wall", "hit_tank", "hit_boundary")

## Static factory method to create a bullet destroyed event
static func create(p_bullet_id: String, p_position: Position, p_reason: String = "", p_frame: int = 0):
	var event = BulletDestroyedEvent.new()
	event.bullet_id = p_bullet_id
	event.position = p_position
	event.reason = p_reason
	event.frame = p_frame
	event.timestamp = Time.get_unix_time_from_system()
	return event

## Convert to dictionary
func to_dict() -> Dictionary:
	return {
		"type": "bullet_destroyed",
		"frame": frame,
		"timestamp": timestamp,
		"bullet_id": bullet_id,
		"position": {"x": position.x, "y": position.y},
		"reason": reason
	}
