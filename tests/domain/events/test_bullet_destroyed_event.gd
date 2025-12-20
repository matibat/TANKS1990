extends GutTest

## BDD Tests for BulletDestroyedEvent
## BulletDestroyedEvent represents a bullet being destroyed

const BulletDestroyedEvent = preload("res://src/domain/events/bullet_destroyed_event.gd")
const Position = preload("res://src/domain/value_objects/position.gd")

func test_given_bullet_destruction_when_event_created_then_has_correct_properties():
	# Given: Bullet destruction properties
	var bullet_id = "bullet_4"
	var position = Position.create(12, 8)
	var reason = "hit_wall"
	
	# When: Creating bullet destroyed event
	var event = BulletDestroyedEvent.create(bullet_id, position, reason, 160)
	
	# Then: Event has correct properties
	assert_eq(event.bullet_id, bullet_id)
	assert_eq(event.position.x, position.x)
	assert_eq(event.position.y, position.y)
	assert_eq(event.reason, reason)
	assert_eq(event.frame, 160)

func test_given_bullet_destroyed_by_collision_when_event_created_then_has_reason():
	# Given: Bullet destroyed by collision
	var position = Position.create(4, 6)
	
	# When: Creating bullet destroyed event
	var event = BulletDestroyedEvent.create("bullet_9", position, "hit_tank", 115)
	
	# Then: Event has correct reason
	assert_eq(event.reason, "hit_tank")

func test_given_bullet_destroyed_event_when_to_dict_then_includes_all_properties():
	# Given: Bullet destroyed event
	var position = Position.create(15, 20)
	var event = BulletDestroyedEvent.create("bullet_10", position, "hit_boundary", 125)
	event.timestamp = 666777
	
	# When: Converting to dictionary
	var dict = event.to_dict()
	
	# Then: Dictionary contains all properties
	assert_eq(dict["type"], "bullet_destroyed")
	assert_eq(dict["frame"], 125)
	assert_eq(dict["timestamp"], 666777)
	assert_eq(dict["bullet_id"], "bullet_10")
	assert_eq(dict["position"]["x"], 15)
	assert_eq(dict["position"]["y"], 20)
	assert_eq(dict["reason"], "hit_boundary")
