class_name Direction
extends RefCounted

## Direction Value Object
## Represents the four cardinal directions for tank movement
## Part of DDD architecture - pure domain logic with no Godot dependencies

const Position = preload("res://src/domain/value_objects/position.gd")

## Direction enum
enum {
	UP = 0,
	DOWN = 1,
	LEFT = 2,
	RIGHT = 3
}

var value: int

## Static factory method to create a direction
static func create(p_value: int):
	var dir = new()
	dir.value = p_value
	return dir

## Convert direction to position delta (for movement)
func to_position_delta():
	var pos = Position.new()
	match value:
		UP:
			pos.x = 0
			pos.y = -1
		DOWN:
			pos.x = 0
			pos.y = 1
		LEFT:
			pos.x = -1
			pos.y = 0
		RIGHT:
			pos.x = 1
			pos.y = 0
		_:
			push_error("Invalid direction value: %d" % value)
			pos.x = 0
			pos.y = 0
	return pos

## Get opposite direction
func opposite():
	var dir = new()
	match value:
		UP:
			dir.value = DOWN
		DOWN:
			dir.value = UP
		LEFT:
			dir.value = RIGHT
		RIGHT:
			dir.value = LEFT
		_:
			push_error("Invalid direction value: %d" % value)
			dir.value = UP
	return dir

## Check equality with another direction
func equals(other) -> bool:
	if other == null:
		return false
	return value == other.value

## String representation for debugging
func _to_string() -> String:
	match value:
		UP:
			return "Direction.UP"
		DOWN:
			return "Direction.DOWN"
		LEFT:
			return "Direction.LEFT"
		RIGHT:
			return "Direction.RIGHT"
		_:
			return "Direction.UNKNOWN"
