class_name GameOverEvent
extends "res://src/domain/events/domain_event.gd"

## GameOverEvent - Event emitted when game is over
## Immutable value object representing game over condition
## Part of DDD architecture - pure domain logic with no Godot dependencies

var reason: String # Reason for game over (e.g., "Base destroyed", "No lives")

## Static factory method to create a game over event
static func create(p_frame: int, p_reason: String = "") -> DomainEvent:
	var event = load("res://src/domain/events/game_over_event.gd").new()
	event.frame = p_frame
	event.reason = p_reason
	event.timestamp = Time.get_unix_time_from_system()
	return event

## Convert to dictionary
func to_dict() -> Dictionary:
	return {
		"type": "game_over",
		"frame": frame,
		"timestamp": timestamp,
		"reason": reason
	}
