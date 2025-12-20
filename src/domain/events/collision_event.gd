class_name CollisionEvent
extends "res://src/domain/events/domain_event.gd"

## CollisionEvent - Event emitted when entities collide
## Immutable value object representing a collision
## Part of DDD architecture - pure domain logic with no Godot dependencies

const Position = preload("res://src/domain/value_objects/position.gd")

var entity1_id: String
var entity2_id: String
var position: Position
var collision_type: String # Type of collision (e.g., "bullet_tank", "tank_tank", "bullet_wall")

## Static factory method to create a collision event
static func create(p_entity1_id: String, p_entity2_id: String, p_position: Position, p_collision_type: String, p_frame: int = 0):
	var event = CollisionEvent.new()
	event.entity1_id = p_entity1_id
	event.entity2_id = p_entity2_id
	event.position = p_position
	event.collision_type = p_collision_type
	event.frame = p_frame
	event.timestamp = Time.get_unix_time_from_system()
	return event

## Convert to dictionary
func to_dict() -> Dictionary:
	return {
		"type": "collision",
		"frame": frame,
		"timestamp": timestamp,
		"entity1_id": entity1_id,
		"entity2_id": entity2_id,
		"position": {"x": position.x, "y": position.y},
		"collision_type": collision_type
	}
