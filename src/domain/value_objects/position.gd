class_name Position
extends RefCounted

## Position Value Object
## Represents an immutable coordinate on the 26x26 tile grid
## Part of DDD architecture - pure domain logic with no Godot dependencies

var x: int
var y: int

## Static factory method to create a position
static func create(p_x: int, p_y: int):
	var pos = new()
	pos.x = p_x
	pos.y = p_y
	return pos

## Check equality with another position
func equals(other) -> bool:
	if other == null:
		return false
	return x == other.x and y == other.y

## Add two positions together (immutable - returns new Position)
func add(other):
	var pos = new()
	pos.x = x + other.x
	pos.y = y + other.y
	return pos

## Convert to dictionary for serialization
func to_dict() -> Dictionary:
	return {
		"x": x,
		"y": y
	}

## Create position from dictionary (deserialization)
static func from_dict(dict: Dictionary):
	var pos = new()
	pos.x = dict["x"]
	pos.y = dict["y"]
	return pos

## String representation for debugging
func _to_string() -> String:
	return "Position(%d, %d)" % [x, y]
