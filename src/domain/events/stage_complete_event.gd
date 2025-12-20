class_name StageCompleteEvent
extends "res://src/domain/events/domain_event.gd"

## StageCompleteEvent - Event emitted when stage is complete
## Immutable value object representing stage completion
## Part of DDD architecture - pure domain logic with no Godot dependencies

## Static factory method to create a stage complete event
static func create(p_frame: int = 0) -> DomainEvent:
	var event = load("res://src/domain/events/stage_complete_event.gd").new()
	event.frame = p_frame
	event.timestamp = Time.get_unix_time_from_system()
	return event

## Convert to dictionary
func to_dict() -> Dictionary:
	return {
		"type": "stage_complete",
		"frame": frame,
		"timestamp": timestamp
	}
