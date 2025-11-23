extends GutTest
## BDD-style tests for ReplayData
## 
## Feature: Replay Session Storage
## As a developer, I want to save and load replay data
## So that players can watch recorded gameplay

# Scenario: Create replay data
class TestReplayCreation:
	extends GutTest
	
	func test_given_new_replay_when_created_then_defaults_set():
		# When
		var replay = ReplayData.new()
		
		# Then
		assert_eq(replay.version, "1.0.0")
		assert_eq(replay.player_count, 1)
		assert_eq(replay.total_frames, 0)
		assert_not_null(replay.recording_date)
	
	func test_given_replay_when_event_added_then_stored():
		# Given
		var replay = ReplayData.new()
		var event = PlayerInputEvent.create_fire()
		event.frame = 10
		
		# When
		replay.add_event(event)
		
		# Then
		assert_eq(replay.events.size(), 1)
	
	func test_given_events_added_when_added_then_total_frames_updated():
		# Given
		var replay = ReplayData.new()
		var event1 = PlayerInputEvent.create_fire()
		event1.frame = 10
		var event2 = PlayerInputEvent.create_move(PlayerInputEvent.Direction.UP)
		event2.frame = 50
		
		# When
		replay.add_event(event1)
		replay.add_event(event2)
		
		# Then
		assert_eq(replay.total_frames, 50)


# Scenario: Calculate replay duration
class TestReplayDuration:
	extends GutTest
	
	func test_given_60_frames_when_calculated_then_1_second():
		# Given
		var replay = ReplayData.new()
		replay.total_frames = 60
		
		# When
		var duration = replay.get_duration()
		
		# Then
		assert_eq(duration, 1.0)
	
	func test_given_300_frames_when_calculated_then_5_seconds():
		# Given
		var replay = ReplayData.new()
		replay.total_frames = 300
		
		# When
		var duration = replay.get_duration()
		
		# Then
		assert_eq(duration, 5.0)


# Scenario: Save and load replay files
class TestReplaySaveLoad:
	extends GutTest
	
	const TEST_PATH = "user://test_replay.tres"
	
	func after_each():
		# Clean up test file
		if FileAccess.file_exists(TEST_PATH):
			DirAccess.remove_absolute(TEST_PATH)
	
	func test_given_replay_data_when_saved_then_file_created():
		# Given
		var replay = ReplayData.new()
		replay.game_seed = 12345
		replay.stage_id = 5
		var event = PlayerInputEvent.create_fire()
		replay.add_event(event)
		
		# When
		var err = replay.save_to_file(TEST_PATH)
		
		# Then
		assert_eq(err, OK)
		assert_true(FileAccess.file_exists(TEST_PATH))
	
	func test_given_saved_replay_when_loaded_then_data_restored():
		# Given
		var original = ReplayData.new()
		original.game_seed = 99999
		original.stage_id = 10
		original.final_score = 5000
		var event = PlayerInputEvent.create_move(PlayerInputEvent.Direction.UP)
		event.frame = 42
		original.add_event(event)
		original.save_to_file(TEST_PATH)
		
		# When
		var loaded = ReplayData.load_from_file(TEST_PATH)
		
		# Then
		assert_not_null(loaded)
		assert_eq(loaded.game_seed, 99999)
		assert_eq(loaded.stage_id, 10)
		assert_eq(loaded.final_score, 5000)
		assert_eq(loaded.events.size(), 1)
		assert_eq(loaded.total_frames, 42)
	
	func test_given_nonexistent_file_when_loaded_then_returns_null():
		# When
		var loaded = ReplayData.load_from_file("user://does_not_exist.tres")
		
		# Then
		assert_null(loaded)
