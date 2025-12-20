extends GutTest

## BDD Tests for CollisionEvent
## CollisionEvent represents a collision between entities

const CollisionEvent = preload("res://src/domain/events/collision_event.gd")
const Position = preload("res://src/domain/value_objects/position.gd")

func test_given_collision_between_entities_when_event_created_then_has_correct_properties():
	# Given: Collision properties
	var entity1_id = "bullet_1"
	var entity2_id = "tank_2"
	var position = Position.create(8, 10)
	var collision_type = "bullet_tank"
	
	# When: Creating collision event
	var event = CollisionEvent.create(entity1_id, entity2_id, position, collision_type, 170)
	
	# Then: Event has correct properties
	assert_eq(event.entity1_id, entity1_id)
	assert_eq(event.entity2_id, entity2_id)
	assert_eq(event.position.x, position.x)
	assert_eq(event.position.y, position.y)
	assert_eq(event.collision_type, collision_type)
	assert_eq(event.frame, 170)

func test_given_tank_tank_collision_when_event_created_then_has_correct_type():
	# Given: Tank-tank collision
	var position = Position.create(5, 5)
	
	# When: Creating collision event
	var event = CollisionEvent.create("tank_1", "tank_2", position, "tank_tank", 130)
	
	# Then: Event has correct collision type
	assert_eq(event.collision_type, "tank_tank")

func test_given_collision_event_when_to_dict_then_includes_all_properties():
	# Given: Collision event
	var position = Position.create(11, 14)
	var event = CollisionEvent.create("bullet_3", "wall_5", position, "bullet_wall", 135)
	event.timestamp = 888999
	
	# When: Converting to dictionary
	var dict = event.to_dict()
	
	# Then: Dictionary contains all properties
	assert_eq(dict["type"], "collision")
	assert_eq(dict["frame"], 135)
	assert_eq(dict["timestamp"], 888999)
	assert_eq(dict["entity1_id"], "bullet_3")
	assert_eq(dict["entity2_id"], "wall_5")
	assert_eq(dict["position"]["x"], 11)
	assert_eq(dict["position"]["y"], 14)
	assert_eq(dict["collision_type"], "bullet_wall")
