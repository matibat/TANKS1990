extends GutTest

## BDD Tests for DomainEvent Base Class
## Events represent immutable outputs from the system

const DomainEvent = preload("res://src/domain/events/domain_event.gd")

func test_given_event_when_created_then_has_frame_and_timestamp():
	# Given: Base event
	var event = DomainEvent.new()
	event.frame = 10
	event.timestamp = 1234567890
	
	# When/Then: Event has frame and timestamp
	assert_eq(event.frame, 10)
	assert_eq(event.timestamp, 1234567890)

func test_given_event_when_to_dict_then_includes_frame_and_timestamp():
	# Given: Event with frame and timestamp
	var event = DomainEvent.new()
	event.frame = 42
	event.timestamp = 9876543210
	
	# When: Converting to dictionary
	var dict = event.to_dict()
	
	# Then: Dictionary contains frame and timestamp
	assert_eq(dict["frame"], 42)
	assert_eq(dict["timestamp"], 9876543210)
