extends GutTest

## BDD Tests for TankSpawnedEvent
## TankSpawnedEvent represents a tank being spawned in the game

const TankSpawnedEvent = preload("res://src/domain/events/tank_spawned_event.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")
const TankEntity = preload("res://src/domain/entities/tank_entity.gd")

func test_given_tank_id_and_properties_when_event_created_then_has_correct_properties():
	# Given: Tank properties
	var tank_id = "player_1"
	var position = Position.create(5, 10)
	var direction = Direction.create(Direction.UP)
	var tank_type = TankEntity.Type.PLAYER
	
	# When: Creating tank spawned event
	var event = TankSpawnedEvent.create(tank_id, tank_type, position, direction, 100)
	
	# Then: Event has correct properties
	assert_eq(event.tank_id, tank_id)
	assert_eq(event.tank_type, tank_type)
	assert_eq(event.position.x, position.x)
	assert_eq(event.position.y, position.y)
	assert_eq(event.direction.value, direction.value)
	assert_eq(event.frame, 100)

func test_given_tank_spawned_event_when_to_dict_then_includes_all_properties():
	# Given: Tank spawned event
	var position = Position.create(3, 7)
	var direction = Direction.create(Direction.DOWN)
	var event = TankSpawnedEvent.create("enemy_1", TankEntity.Type.ENEMY_BASIC, position, direction, 50)
	event.timestamp = 123456
	
	# When: Converting to dictionary
	var dict = event.to_dict()
	
	# Then: Dictionary contains all properties
	assert_eq(dict["type"], "tank_spawned")
	assert_eq(dict["frame"], 50)
	assert_eq(dict["timestamp"], 123456)
	assert_eq(dict["tank_id"], "enemy_1")
	assert_eq(dict["tank_type"], TankEntity.Type.ENEMY_BASIC)
	assert_eq(dict["position"]["x"], 3)
	assert_eq(dict["position"]["y"], 7)
	assert_eq(dict["direction"], Direction.DOWN)
