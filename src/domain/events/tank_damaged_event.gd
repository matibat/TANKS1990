class_name TankDamagedEvent
extends "res://src/domain/events/domain_event.gd"

## TankDamagedEvent - Event emitted when a tank takes damage
## Immutable value object representing tank damage
## Part of DDD architecture - pure domain logic with no Godot dependencies

var tank_id: String
var damage: int
var old_health: int
var new_health: int

## Static factory method to create a tank damaged event
static func create(p_tank_id: String, p_damage: int, p_old_health: int, p_new_health: int, p_frame: int = 0):
	var event = TankDamagedEvent.new()
	event.tank_id = p_tank_id
	event.damage = p_damage
	event.old_health = p_old_health
	event.new_health = p_new_health
	event.frame = p_frame
	event.timestamp = Time.get_unix_time_from_system()
	return event

## Convert to dictionary
func to_dict() -> Dictionary:
	return {
		"type": "tank_damaged",
		"frame": frame,
		"timestamp": timestamp,
		"tank_id": tank_id,
		"damage": damage,
		"old_health": old_health,
		"new_health": new_health
	}
