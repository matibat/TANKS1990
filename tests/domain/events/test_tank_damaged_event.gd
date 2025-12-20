extends GutTest

## BDD Tests for TankDamagedEvent
## TankDamagedEvent represents a tank taking damage

const TankDamagedEvent = preload("res://src/domain/events/tank_damaged_event.gd")

func test_given_tank_damage_when_event_created_then_has_correct_properties():
	# Given: Tank damage properties
	var tank_id = "player_1"
	var damage = 25
	var old_health = 100
	var new_health = 75
	
	# When: Creating tank damaged event
	var event = TankDamagedEvent.create(tank_id, damage, old_health, new_health, 120)
	
	# Then: Event has correct properties
	assert_eq(event.tank_id, tank_id)
	assert_eq(event.damage, damage)
	assert_eq(event.old_health, old_health)
	assert_eq(event.new_health, new_health)
	assert_eq(event.frame, 120)

func test_given_tank_damaged_event_when_to_dict_then_includes_all_properties():
	# Given: Tank damaged event
	var event = TankDamagedEvent.create("enemy_3", 50, 100, 50, 70)
	event.timestamp = 555666
	
	# When: Converting to dictionary
	var dict = event.to_dict()
	
	# Then: Dictionary contains all properties
	assert_eq(dict["type"], "tank_damaged")
	assert_eq(dict["frame"], 70)
	assert_eq(dict["timestamp"], 555666)
	assert_eq(dict["tank_id"], "enemy_3")
	assert_eq(dict["damage"], 50)
	assert_eq(dict["old_health"], 100)
	assert_eq(dict["new_health"], 50)
