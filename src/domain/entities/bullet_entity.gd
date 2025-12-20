class_name BulletEntity
extends RefCounted

## BulletEntity - Domain Entity
## Represents a bullet in the game with identity, state, and behavior
## Part of DDD architecture - pure domain logic with no Godot dependencies

const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")
const Velocity = preload("res://src/domain/value_objects/velocity.gd")

## Identity
var id: String

## Properties
var owner_id: String
var position: Position
var direction: Direction
var velocity: Velocity
var damage: int
var is_active: bool

## Static factory method to create a bullet
static func create(p_id: String, p_owner_id: String, p_position: Position,
				   p_direction: Direction, p_speed: int, p_damage: int):
	var bullet = new()
	bullet.id = p_id
	bullet.owner_id = p_owner_id
	bullet.position = p_position
	bullet.direction = p_direction
	bullet.velocity = Velocity.from_direction(p_direction, p_speed)
	bullet.damage = p_damage
	bullet.is_active = true
	return bullet

## Deactivate bullet (e.g., after collision)
func deactivate() -> void:
	is_active = false

## Get next position based on current velocity
func get_next_position() -> Position:
	var delta = Position.create(velocity.dx, velocity.dy)
	return position.add(delta)

## Move bullet forward by its velocity
func move_forward() -> void:
	position = get_next_position()

## Serialize to dictionary
func to_dict() -> Dictionary:
	return {
		"id": id,
		"owner_id": owner_id,
		"position": position.to_dict(),
		"direction": direction.value,
		"velocity_dx": velocity.dx,
		"velocity_dy": velocity.dy,
		"damage": damage,
		"is_active": is_active
	}

## Deserialize from dictionary
static func from_dict(dict: Dictionary):
	var bullet = new()
	bullet.id = dict["id"]
	bullet.owner_id = dict["owner_id"]
	bullet.position = Position.from_dict(dict["position"])
	bullet.direction = Direction.create(dict["direction"])
	bullet.velocity = Velocity.create(dict["velocity_dx"], dict["velocity_dy"])
	bullet.damage = dict["damage"]
	bullet.is_active = dict["is_active"]
	return bullet

## String representation for debugging
func _to_string() -> String:
	return "BulletEntity(%s, owner:%s, pos:%s, dir:%d, dmg:%d, active:%s)" % [
		id, owner_id, position, direction.value, damage, is_active
	]
