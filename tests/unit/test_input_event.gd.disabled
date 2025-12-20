extends GutTest
## BDD-style tests for InputEvent
## 
## Feature: Player Input Events
## As a developer, I want to create and serialize input events
## So that player actions are recorded deterministically

# Scenario: Create movement input events
class TestMovementEvents:
	extends GutTest
	
	func test_given_up_direction_when_created_then_properties_set():
		# When
		var event = PlayerInputEvent.create_move(PlayerInputEvent.Direction.UP)
		
		# Then
		assert_eq(event.input_type, PlayerInputEvent.InputType.MOVE)
		assert_eq(event.direction, PlayerInputEvent.Direction.UP)
		assert_true(event.is_pressed)
	
	func test_given_down_direction_when_created_then_properties_set():
		# When
		var event = PlayerInputEvent.create_move(PlayerInputEvent.Direction.DOWN, false)
		
		# Then
		assert_eq(event.direction, PlayerInputEvent.Direction.DOWN)
		assert_false(event.is_pressed)
	
	func test_given_player_id_when_created_then_player_set():
		# When
		var event = PlayerInputEvent.create_move(PlayerInputEvent.Direction.LEFT, true, 1)
		
		# Then
		assert_eq(event.player_id, 1)


# Scenario: Create fire input events
class TestFireEvents:
	extends GutTest
	
	func test_given_fire_when_created_then_properties_set():
		# When
		var event = PlayerInputEvent.create_fire()
		
		# Then
		assert_eq(event.input_type, PlayerInputEvent.InputType.FIRE)
		assert_true(event.is_pressed)
	
	func test_given_fire_released_when_created_then_not_pressed():
		# When
		var event = PlayerInputEvent.create_fire(false)
		
		# Then
		assert_false(event.is_pressed)


# Scenario: Serialize and deserialize input events
class TestInputSerialization:
	extends GutTest
	
	func test_given_move_event_when_serialized_then_dict_complete():
		# Given
		var event = PlayerInputEvent.create_move(PlayerInputEvent.Direction.RIGHT, true, 0)
		event.frame = 100
		event.timestamp = 5000
		
		# When
		var dict = event.to_dict()
		
		# Then
		assert_eq(dict["type"], "Input")
		assert_eq(dict["frame"], 100)
		assert_eq(dict["timestamp"], 5000)
		assert_eq(dict["input_type"], PlayerInputEvent.InputType.MOVE)
		assert_eq(dict["direction"], PlayerInputEvent.Direction.RIGHT)
		assert_true(dict["is_pressed"])
		assert_eq(dict["player_id"], 0)
	
	func test_given_serialized_dict_when_deserialized_then_event_restored():
		# Given
		var original = PlayerInputEvent.create_move(PlayerInputEvent.Direction.UP, true, 1)
		original.frame = 42
		original.timestamp = 1000
		var dict = original.to_dict()
		
		# When
		var restored = PlayerInputEvent.from_dict(dict)
		
		# Then
		assert_eq(restored.frame, 42)
		assert_eq(restored.timestamp, 1000)
		assert_eq(restored.input_type, PlayerInputEvent.InputType.MOVE)
		assert_eq(restored.direction, PlayerInputEvent.Direction.UP)
		assert_true(restored.is_pressed)
		assert_eq(restored.player_id, 1)
	
	func test_given_event_when_to_bytes_then_can_deserialize():
		# Given
		var original = PlayerInputEvent.create_fire(true, 0)
		original.frame = 10
		
		# When
		var bytes = original.serialize()
		var restored = PlayerInputEvent.deserialize(bytes)
		
		# Then
		assert_eq(restored.frame, 10)
		assert_eq(restored.input_type, PlayerInputEvent.InputType.FIRE)
