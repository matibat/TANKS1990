class_name InputBuffer
extends RefCounted

## InputBuffer Value Object
## Buffers player input actions between game ticks to prevent input drops
## Part of DDD architecture - pure domain logic with no Godot dependencies (except RefCounted)

## Buffered actions - each entry contains {action: String, timestamp: float}
var _buffered_actions: Array = []

## Static factory method to create an InputBuffer
static func create() -> InputBuffer:
	var buffer = InputBuffer.new()
	buffer._buffered_actions = []
	return buffer

## Add an action to the buffer with its timestamp
## @param action: The action string (e.g., "move_up", "fire")
## @param timestamp: The time when the action occurred
func add_action(action: String, timestamp: float) -> void:
	_buffered_actions.append({
		"action": action,
		"timestamp": timestamp
	})

## Get all buffered actions
## Non-destructive read - returns copy of buffered actions
## @return Array of action dictionaries [{action: String, timestamp: float}, ...]
func get_buffered_actions() -> Array:
	var result: Array = []
	for action_data in _buffered_actions:
		result.append(action_data)
	return result

## Clear all buffered actions
## Should be called after processing buffered inputs
func clear() -> void:
	_buffered_actions.clear()

## Check if buffer is empty
## @return true if buffer contains no actions, false otherwise
func is_empty() -> bool:
	return _buffered_actions.is_empty()

## Convert to dictionary for serialization (if needed)
func to_dict() -> Dictionary:
	return {
		"buffered_actions": _buffered_actions.duplicate(true)
	}

## Create InputBuffer from dictionary (deserialization)
static func from_dict(dict: Dictionary) -> InputBuffer:
	var buffer = InputBuffer.new()
	if dict.has("buffered_actions"):
		buffer._buffered_actions = dict["buffered_actions"].duplicate(true)
	else:
		buffer._buffered_actions = []
	return buffer

## String representation for debugging
func _to_string() -> String:
	return "InputBuffer(%d actions)" % _buffered_actions.size()
