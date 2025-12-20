extends GutTest

## BDD Tests for BulletFiredEvent
## BulletFiredEvent represents a bullet being fired

const BulletFiredEvent = preload("res://src/domain/events/bullet_fired_event.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")

func test_given_bullet_firing_when_event_created_then_has_correct_properties():
	# Given: Bullet firing properties
	var bullet_id = "bullet_1"
	var tank_id = "player_1"
	var position = Position.create(5, 10)
	var direction = Direction.create(Direction.UP)
	
	# When: Creating bullet fired event
	var event = BulletFiredEvent.create(bullet_id, tank_id, position, direction, 140)
	
	# Then: Event has correct properties
	assert_eq(event.bullet_id, bullet_id)
	assert_eq(event.tank_id, tank_id)
	assert_eq(event.position.x, position.x)
	assert_eq(event.position.y, position.y)
	assert_eq(event.direction.value, direction.value)
	assert_eq(event.frame, 140)

func test_given_bullet_fired_event_when_to_dict_then_includes_all_properties():
	# Given: Bullet fired event
	var position = Position.create(7, 9)
	var direction = Direction.create(Direction.LEFT)
	var event = BulletFiredEvent.create("bullet_5", "enemy_2", position, direction, 95)
	event.timestamp = 111222
	
	# When: Converting to dictionary
	var dict = event.to_dict()
	
	# Then: Dictionary contains all properties
	assert_eq(dict["type"], "bullet_fired")
	assert_eq(dict["frame"], 95)
	assert_eq(dict["timestamp"], 111222)
	assert_eq(dict["bullet_id"], "bullet_5")
	assert_eq(dict["tank_id"], "enemy_2")
	assert_eq(dict["position"]["x"], 7)
	assert_eq(dict["position"]["y"], 9)
	assert_eq(dict["direction"], Direction.LEFT)
