class_name Health
extends RefCounted

## Health Value Object
## Represents entity hit points with validation
## Part of DDD architecture - pure domain logic with no Godot dependencies

var current: int
var maximum: int

## Static factory method to create health with specific current and max
static func create(p_current: int, p_maximum: int):
	var h = new()
	h.maximum = max(0, p_maximum)
	h.current = clamp(p_current, 0, h.maximum)
	return h

## Static factory method to create full health
static func full(p_maximum: int):
	var h = new()
	h.maximum = max(0, p_maximum)
	h.current = h.maximum
	return h

## Check if entity is alive (current > 0)
func is_alive() -> bool:
	return current > 0

## Take damage and return new Health (immutable)
func take_damage(amount: int):
	var h = new()
	h.maximum = maximum
	h.current = max(0, current - amount)
	return h

## Heal and return new Health (immutable)
func heal(amount: int):
	var h = new()
	h.maximum = maximum
	h.current = min(maximum, current + amount)
	return h

## String representation for debugging
func _to_string() -> String:
	return "Health(%d/%d)" % [current, maximum]
