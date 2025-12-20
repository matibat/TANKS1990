extends GutTest

## BDD Tests for BulletMovedEvent
## BulletMovedEvent represents a bullet moving

const BulletMovedEvent = preload("res://src/domain/events/bullet_moved_event.gd")
const Position = preload("res://src/domain/value_objects/position.gd")

func test_given_bullet_movement_when_event_created_then_has_correct_properties():
	# Given: Bullet movement properties
	var bullet_id = "bullet_3"
	var old_pos = Position.create(5, 5)
	var new_pos = Position.create(5, 4)
	
	# When: Creating bullet moved event
	var event = BulletMovedEvent.create(bullet_id, old_pos, new_pos, 150)
	
	# Then: Event has correct properties
	assert_eq(event.bullet_id, bullet_id)
	assert_eq(event.old_position.x, old_pos.x)
	assert_eq(event.old_position.y, old_pos.y)
	assert_eq(event.new_position.x, new_pos.x)
	assert_eq(event.new_position.y, new_pos.y)
	assert_eq(event.frame, 150)

func test_given_bullet_moved_event_when_to_dict_then_includes_all_properties():
	# Given: Bullet moved event
	var old_pos = Position.create(10, 10)
	var new_pos = Position.create(9, 10)
	var event = BulletMovedEvent.create("bullet_7", old_pos, new_pos, 105)
	event.timestamp = 333444
	
	# When: Converting to dictionary
	var dict = event.to_dict()
	
	# Then: Dictionary contains all properties
	assert_eq(dict["type"], "bullet_moved")
	assert_eq(dict["frame"], 105)
	assert_eq(dict["timestamp"], 333444)
	assert_eq(dict["bullet_id"], "bullet_7")
	assert_eq(dict["old_position"]["x"], 10)
	assert_eq(dict["old_position"]["y"], 10)
	assert_eq(dict["new_position"]["x"], 9)
	assert_eq(dict["new_position"]["y"], 10)
