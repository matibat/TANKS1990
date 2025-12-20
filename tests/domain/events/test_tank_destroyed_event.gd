extends GutTest

## BDD Tests for TankDestroyedEvent
## TankDestroyedEvent represents a tank being destroyed

const TankDestroyedEvent = preload("res://src/domain/events/tank_destroyed_event.gd")
const Position = preload("res://src/domain/value_objects/position.gd")

func test_given_tank_destruction_when_event_created_then_has_correct_properties():
	# Given: Tank destruction properties
	var tank_id = "enemy_1"
	var position = Position.create(8, 12)
	var killer_id = "player_1"
	
	# When: Creating tank destroyed event
	var event = TankDestroyedEvent.create(tank_id, position, killer_id, 130)
	
	# Then: Event has correct properties
	assert_eq(event.tank_id, tank_id)
	assert_eq(event.position.x, position.x)
	assert_eq(event.position.y, position.y)
	assert_eq(event.killer_id, killer_id)
	assert_eq(event.frame, 130)

func test_given_tank_destroyed_event_without_killer_when_created_then_killer_is_empty():
	# Given: Tank destruction without killer
	var position = Position.create(3, 5)
	
	# When: Creating tank destroyed event without killer
	var event = TankDestroyedEvent.create("player_1", position, "", 80)
	
	# Then: Killer ID is empty
	assert_eq(event.killer_id, "")

func test_given_tank_destroyed_event_when_to_dict_then_includes_all_properties():
	# Given: Tank destroyed event
	var position = Position.create(10, 15)
	var event = TankDestroyedEvent.create("enemy_4", position, "player_2", 90)
	event.timestamp = 777888
	
	# When: Converting to dictionary
	var dict = event.to_dict()
	
	# Then: Dictionary contains all properties
	assert_eq(dict["type"], "tank_destroyed")
	assert_eq(dict["frame"], 90)
	assert_eq(dict["timestamp"], 777888)
	assert_eq(dict["tank_id"], "enemy_4")
	assert_eq(dict["position"]["x"], 10)
	assert_eq(dict["position"]["y"], 15)
	assert_eq(dict["killer_id"], "player_2")
