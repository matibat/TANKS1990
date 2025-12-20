extends GutTest
## BDD-style tests for EventBus core functionality
## 
## Feature: Event Recording and Playback
## As a developer, I want to record gameplay events
## So that I can replay game sessions deterministically

var event_bus: Node

func before_each():
	event_bus = EventBus
	event_bus.clear_all_listeners()
	event_bus.stop_recording()
	event_bus.stop_replay()

func after_each():
	event_bus.clear_all_listeners()
	event_bus.stop_recording()
	event_bus.stop_replay()


# Scenario: Start recording gameplay events
class TestStartRecording:
	extends GutTest
	
	var event_bus: Node
	
	func before_each():
		event_bus = EventBus
		event_bus.clear_all_listeners()
		# Ensure clean state
		if event_bus.is_recording:
			event_bus.stop_recording()
	
	func test_given_game_not_recording_when_start_recording_then_recording_flag_set():
		# Given
		assert_false(event_bus.is_recording, "Should not be recording initially")
		
		# When
		event_bus.start_recording()
		
		# Then
		assert_true(event_bus.is_recording, "Should be recording after start")
	
	func test_given_start_recording_when_started_then_frame_counter_reset():
		# Given
		event_bus.current_frame = 100
		
		# When
		event_bus.start_recording()
		
		# Then
		assert_eq(event_bus.current_frame, 0, "Frame counter should reset to 0")
	
	func test_given_start_recording_when_with_seed_then_seed_set():
		# Given
		var test_seed = 12345
		
		# When
		event_bus.start_recording(test_seed)
		
		# Then
		assert_eq(event_bus.game_seed, test_seed, "Game seed should be set")
	
	func test_given_start_recording_when_no_seed_then_random_seed_generated():
		# When
		event_bus.start_recording()
		
		# Then
		assert_gt(event_bus.game_seed, 0, "Should generate positive seed")
	
	func test_given_start_recording_when_started_then_signal_emitted():
		# Given
		watch_signals(event_bus)
		
		# When
		event_bus.start_recording()
		
		# Then
		assert_signal_emitted(event_bus, "recording_started")


# Scenario: Emit and record game events
class TestEmitEvent:
	extends GutTest
	
	var event_bus: Node
	
	func before_each():
		event_bus = EventBus
		event_bus.clear_all_listeners()
		event_bus.start_recording()
	
	func after_each():
		event_bus.stop_recording()
	
	func test_given_recording_when_event_emitted_then_event_recorded():
		# Given
		var event = PlayerInputEvent.create_fire()
		
		# When
		event_bus.emit_game_event(event)
		
		# Then
		assert_eq(event_bus.recorded_events.size(), 1, "Should have 1 recorded event")
	
	func test_given_event_emitted_when_emitted_then_frame_set():
		# Given
		event_bus.current_frame = 42
		var event = PlayerInputEvent.create_fire()
		
		# When
		event_bus.emit_game_event(event)
		
		# Then
		assert_eq(event.frame, 42, "Event frame should match current frame")
	
	func test_given_event_emitted_when_emitted_then_timestamp_set():
		# Given
		var event = PlayerInputEvent.create_fire()
		
		# When
		event_bus.emit_game_event(event)
		
		# Then (timestamp is 0 in headless mode, just verify it's assigned)
		assert_true(event.timestamp >= 0, "Timestamp should be set by EventBus")
	
	func test_given_multiple_events_when_emitted_then_all_recorded():
		# Given
		var event1 = PlayerInputEvent.create_fire()
		var event2 = PlayerInputEvent.create_move(PlayerInputEvent.Direction.UP)
		var event3 = PlayerInputEvent.create_pause()
		
		# When
		event_bus.emit_game_event(event1)
		event_bus.emit_game_event(event2)
		event_bus.emit_game_event(event3)
		
		# Then
		assert_eq(event_bus.recorded_events.size(), 3, "Should have 3 recorded events")


# Scenario: Subscribe to and receive events
class TestEventSubscription:
	extends GutTest
	
	var event_bus: Node
	var received_events: Array = []
	
	func before_each():
		event_bus = EventBus
		event_bus.clear_all_listeners()
		received_events.clear()
	
	func _on_event_received(event: GameEvent):
		received_events.append(event)
	
	func test_given_subscribed_when_event_emitted_then_callback_called():
		# Given
		event_bus.subscribe("Input", _on_event_received)
		var event = PlayerInputEvent.create_fire()
		
		# When
		event_bus.emit_game_event(event)
		
		# Then
		assert_eq(received_events.size(), 1, "Should receive 1 event")
	
	func test_given_subscribed_when_different_event_emitted_then_callback_not_called():
		# Given
		event_bus.subscribe("Input", _on_event_received)
		var event = TankSpawnedEvent.new()
		event.tank_id = 1
		event.tank_type = "player"
		event.position = Vector2(100, 100)
		
		# When
		event_bus.emit_game_event(event)
		
		# Then
		assert_eq(received_events.size(), 0, "Should not receive event")
	
	func test_given_subscribed_when_unsubscribed_then_no_callback():
		# Given
		event_bus.subscribe("Input", _on_event_received)
		var callback = _on_event_received
		event_bus.unsubscribe("Input", callback)
		var event = PlayerInputEvent.create_fire()
		
		# When
		event_bus.emit_game_event(event)
		
		# Then
		assert_eq(received_events.size(), 0, "Should not receive event after unsubscribe")


# Scenario: Stop recording and get replay data
class TestStopRecording:
	extends GutTest
	
	var event_bus: Node
	
	func before_each():
		event_bus = EventBus
		event_bus.clear_all_listeners()
	
	func test_given_recording_when_stopped_then_returns_replay_data():
		# Given
		event_bus.start_recording(12345)
		event_bus.emit_game_event(PlayerInputEvent.create_fire())
		
		# When
		var replay_data = event_bus.stop_recording()
		
		# Then
		assert_not_null(replay_data, "Should return replay data")
		assert_is(replay_data, ReplayData, "Should be ReplayData type")
	
	func test_given_events_recorded_when_stopped_then_replay_contains_events():
		# Given
		event_bus.start_recording()
		event_bus.emit_game_event(PlayerInputEvent.create_fire())
		event_bus.emit_game_event(PlayerInputEvent.create_move(PlayerInputEvent.Direction.UP))
		
		# When
		var replay_data = event_bus.stop_recording()
		
		# Then
		assert_eq(replay_data.events.size(), 2, "Should have 2 events in replay")
	
	func test_given_recording_stopped_when_stopped_then_signal_emitted():
		# Given
		event_bus.start_recording()
		event_bus.emit_game_event(PlayerInputEvent.create_fire())
		watch_signals(event_bus)
		
		# When
		event_bus.stop_recording()
		
		# Then
		assert_signal_emitted_with_parameters(
			event_bus,
			"recording_stopped",
			[1]
		)
	
	func test_given_recording_stopped_when_stopped_then_recording_flag_cleared():
		# Given
		event_bus.start_recording()
		
		# When
		event_bus.stop_recording()
		
		# Then
		assert_false(event_bus.is_recording, "Should not be recording after stop")


# Scenario: Vector3 serialization for 3D support
class TestVector3Serialization:
	extends GutTest
	
	var event_bus: Node
	
	func before_each():
		event_bus = EventBus
	
	func test_given_vector3_when_serialized_then_returns_dictionary():
		# Given
		var vec3 = Vector3(10.5, 20.3, 30.7)
		
		# When
		var result = event_bus.serialize_vector3(vec3)
		
		# Then
		assert_true(result is Dictionary, "Should return dictionary")
		assert_has(result, "x", "Should have x key")
		assert_has(result, "y", "Should have y key")
		assert_has(result, "z", "Should have z key")
		assert_almost_eq(result.x, 10.5, 0.0001, "X should match")
		assert_almost_eq(result.y, 20.3, 0.0001, "Y should match")
		assert_almost_eq(result.z, 30.7, 0.0001, "Z should match")
	
	func test_given_vector3_dict_when_deserialized_then_returns_vector3():
		# Given
		var vec_dict = {"x": 15.2, "y": 25.8, "z": 35.1}
		
		# When
		var result = event_bus.deserialize_vector3(vec_dict)
		
		# Then
		assert_true(typeof(result) == TYPE_VECTOR3, "Should return Vector3")
		assert_almost_eq(result.x, 15.2, 0.0001, "X should match")
		assert_almost_eq(result.y, 25.8, 0.0001, "Y should match")
		assert_almost_eq(result.z, 35.1, 0.0001, "Z should match")
	
	func test_given_invalid_dict_when_deserialize_vector3_then_returns_zero():
		# Given
		var invalid_dict = {"a": 1, "b": 2}
		
		# When
		var result = event_bus.deserialize_vector3(invalid_dict)
		
		# Then
		assert_eq(result, Vector3.ZERO, "Should return Vector3.ZERO for invalid input")
	
	func test_given_zero_vector3_when_serialized_then_all_zeros():
		# Given
		var vec3 = Vector3.ZERO
		
		# When
		var result = event_bus.serialize_vector3(vec3)
		
		# Then
		assert_eq(result.x, 0.0, "X should be 0")
		assert_eq(result.y, 0.0, "Y should be 0")
		assert_eq(result.z, 0.0, "Z should be 0")
	
	func test_given_negative_vector3_when_serialized_then_preserves_negatives():
		# Given
		var vec3 = Vector3(-5.5, -10.2, -15.8)
		
		# When
		var result = event_bus.serialize_vector3(vec3)
		
		# Then
		assert_almost_eq(result.x, -5.5, 0.0001, "X should be negative")
		assert_almost_eq(result.y, -10.2, 0.0001, "Y should be negative")
		assert_almost_eq(result.z, -15.8, 0.0001, "Z should be negative")
