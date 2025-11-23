class_name GameEvent
extends RefCounted
## Base class for all game events
## Provides serialization and frame tracking for deterministic replay

var frame: int = 0
var timestamp: int = 0  # Milliseconds since game start

## Override in subclasses to provide unique event type identifier
func get_event_type() -> String:
	return "BaseEvent"

## Serialize event to dictionary for storage/network
func to_dict() -> Dictionary:
	return {
		"type": get_event_type(),
		"frame": frame,
		"timestamp": timestamp
	}

## Deserialize event from dictionary
static func from_dict(data: Dictionary) -> GameEvent:
	var event = GameEvent.new()
	event.frame = data.get("frame", 0)
	event.timestamp = data.get("timestamp", 0)
	return event

## Human-readable string representation
func _to_string() -> String:
	return JSON.stringify(to_dict())

## Serialize to bytes for efficient storage/network
func serialize() -> PackedByteArray:
	var dict = to_dict()
	return var_to_bytes(dict)

## Deserialize from bytes
static func deserialize(data: PackedByteArray) -> GameEvent:
	var dict = bytes_to_var(data)
	return from_dict(dict)
