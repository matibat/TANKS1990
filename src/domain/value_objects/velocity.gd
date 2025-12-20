class_name Velocity
extends RefCounted

## Velocity Value Object
## Represents movement delta per frame
## Part of DDD architecture - pure domain logic with no Godot dependencies

const Direction = preload("res://src/domain/value_objects/direction.gd")
const Position = preload("res://src/domain/value_objects/position.gd")

var dx: int
var dy: int

## Static factory method to create velocity
static func create(p_dx: int, p_dy: int):
	var v = new()
	v.dx = p_dx
	v.dy = p_dy
	return v

## Static factory method to create zero velocity
static func zero():
	var v = new()
	v.dx = 0
	v.dy = 0
	return v

## Static factory method to create velocity from direction and speed
static func from_direction(direction, speed: int):
	var delta = direction.to_position_delta()
	var v = new()
	v.dx = delta.x * speed
	v.dy = delta.y * speed
	return v

## Check if velocity is zero
func is_zero() -> bool:
	return dx == 0 and dy == 0

## String representation for debugging
func _to_string() -> String:
	return "Velocity(%d, %d)" % [dx, dy]
