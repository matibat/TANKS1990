extends GutTest

## BDD Tests for TankMovedEvent
## TankMovedEvent represents a tank moving in the game

const TankMovedEvent = preload("res://src/domain/events/tank_moved_event.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")

func test_given_tank_movement_when_event_created_then_has_correct_properties():
	# Given: Tank movement properties
	var tank_id = "player_1"
	var old_pos = Position.create(5, 5)
	var new_pos = Position.create(5, 6)
	var direction = Direction.create(Direction.DOWN)
	
	# When: Creating tank moved event
	var event = TankMovedEvent.create(tank_id, old_pos, new_pos, direction, 110)
	
	# Then: Event has correct properties
	assert_eq(event.tank_id, tank_id)
	assert_eq(event.old_position.x, old_pos.x)
	assert_eq(event.old_position.y, old_pos.y)
	assert_eq(event.new_position.x, new_pos.x)
	assert_eq(event.new_position.y, new_pos.y)
	assert_eq(event.direction.value, direction.value)
	assert_eq(event.frame, 110)

func test_given_tank_moved_event_when_to_dict_then_includes_all_properties():
	# Given: Tank moved event
	var old_pos = Position.create(2, 3)
	var new_pos = Position.create(3, 3)
	var direction = Direction.create(Direction.RIGHT)
	var event = TankMovedEvent.create("enemy_2", old_pos, new_pos, direction, 60)
	event.timestamp = 999888
	
	# When: Converting to dictionary
	var dict = event.to_dict()
	
	# Then: Dictionary contains all properties
	assert_eq(dict["type"], "tank_moved")
	assert_eq(dict["frame"], 60)
	assert_eq(dict["timestamp"], 999888)
	assert_eq(dict["tank_id"], "enemy_2")
	assert_eq(dict["old_position"]["x"], 2)
	assert_eq(dict["old_position"]["y"], 3)
	assert_eq(dict["new_position"]["x"], 3)
	assert_eq(dict["new_position"]["y"], 3)
	assert_eq(dict["direction"], Direction.RIGHT)
