class_name BaseEntity
extends RefCounted

## BaseEntity - Domain Entity
## Represents the player's base (eagle) that must be protected
## Part of DDD architecture - pure domain logic with no Godot dependencies

const Position = preload("res://src/domain/value_objects/position.gd")
const Health = preload("res://src/domain/value_objects/health.gd")

## Identity
var id: String

## Properties
var position: Position
var health: Health
var is_destroyed: bool

## Static factory method to create a base
static func create(p_id: String, p_position: Position, p_health: int):
	var base = new()
	base.id = p_id
	base.position = p_position
	base.health = Health.full(p_health)
	base.is_destroyed = false
	return base

## Check if base is alive
func is_alive() -> bool:
	return health.is_alive()

## Take damage
func take_damage(amount: int) -> void:
	health = health.take_damage(amount)
	if not is_alive():
		is_destroyed = true

## Serialize to dictionary
func to_dict() -> Dictionary:
	return {
		"id": id,
		"position": position.to_dict(),
		"health_current": health.current,
		"health_maximum": health.maximum,
		"is_destroyed": is_destroyed
	}

## Deserialize from dictionary
static func from_dict(dict: Dictionary):
	var base = new()
	base.id = dict["id"]
	base.position = Position.from_dict(dict["position"])
	base.health = Health.create(dict["health_current"], dict["health_maximum"])
	base.is_destroyed = dict["is_destroyed"]
	return base

## String representation for debugging
func _to_string() -> String:
	return "BaseEntity(%s, pos:%s, hp:%d/%d, destroyed:%s)" % [
		id, position, health.current, health.maximum, is_destroyed
	]
