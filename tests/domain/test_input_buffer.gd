extends GutTest

## BDD Tests for InputBuffer Value Object
## InputBuffer buffers player input actions between game ticks to prevent input drops
## This is a pure domain value object with no Godot engine dependencies (except RefCounted)

const InputBuffer = preload("res://src/domain/value_objects/input_buffer.gd")

## Test Case 1: Buffer stores single keypress before game tick
## Scenario: Player presses one key between ticks, buffer captures it
func test_given_empty_buffer_when_single_action_added_then_buffer_contains_action():
	# Given: An empty input buffer
	var buffer = InputBuffer.create()
	
	# When: A single action is added with timestamp
	buffer.add_action("move_up", 0.042)
	
	# Then: Buffer contains that action
	var actions = buffer.get_buffered_actions()
	assert_eq(actions.size(), 1, "Buffer should contain exactly one action")
	assert_eq(actions[0]["action"], "move_up", "Action name should match")
	assert_almost_eq(actions[0]["timestamp"], 0.042, 0.001, "Timestamp should be preserved")

func test_given_empty_buffer_when_checked_then_is_empty_returns_true():
	# Given: An empty input buffer
	var buffer = InputBuffer.create()
	
	# When: Checking if buffer is empty
	var is_empty = buffer.is_empty()
	
	# Then: Buffer reports as empty
	assert_true(is_empty, "Empty buffer should return true for is_empty()")

func test_given_buffer_with_action_when_checked_then_is_empty_returns_false():
	# Given: A buffer with one action
	var buffer = InputBuffer.create()
	buffer.add_action("fire", 0.015)
	
	# When: Checking if buffer is empty
	var is_empty = buffer.is_empty()
	
	# Then: Buffer reports as not empty
	assert_false(is_empty, "Buffer with actions should return false for is_empty()")


## Test Case 2: Buffer stores multiple keypresses in order
## Scenario: Player presses multiple keys rapidly, buffer maintains insertion order
func test_given_empty_buffer_when_multiple_actions_added_then_maintains_insertion_order():
	# Given: An empty input buffer
	var buffer = InputBuffer.create()
	
	# When: Multiple actions are added in sequence
	buffer.add_action("move_up", 0.010)
	buffer.add_action("move_right", 0.025)
	buffer.add_action("fire", 0.040)
	buffer.add_action("move_down", 0.055)
	
	# Then: Buffer returns actions in insertion order
	var actions = buffer.get_buffered_actions()
	assert_eq(actions.size(), 4, "Buffer should contain all four actions")
	assert_eq(actions[0]["action"], "move_up", "First action should be move_up")
	assert_eq(actions[1]["action"], "move_right", "Second action should be move_right")
	assert_eq(actions[2]["action"], "fire", "Third action should be fire")
	assert_eq(actions[3]["action"], "move_down", "Fourth action should be move_down")

func test_given_empty_buffer_when_actions_added_with_timestamps_then_preserves_all_timestamps():
	# Given: An empty input buffer
	var buffer = InputBuffer.create()
	
	# When: Actions added with specific timestamps
	var timestamp1 = 0.012
	var timestamp2 = 0.028
	var timestamp3 = 0.045
	buffer.add_action("move_left", timestamp1)
	buffer.add_action("fire", timestamp2)
	buffer.add_action("move_right", timestamp3)
	
	# Then: All timestamps are preserved correctly
	var actions = buffer.get_buffered_actions()
	assert_almost_eq(actions[0]["timestamp"], timestamp1, 0.001, "First timestamp preserved")
	assert_almost_eq(actions[1]["timestamp"], timestamp2, 0.001, "Second timestamp preserved")
	assert_almost_eq(actions[2]["timestamp"], timestamp3, 0.001, "Third timestamp preserved")


## Test Case 3: Buffer is consumed on game tick (clear after read)
## Scenario: After reading buffered inputs, buffer should be cleared for next tick
func test_given_buffer_with_actions_when_cleared_then_buffer_becomes_empty():
	# Given: A buffer with multiple actions
	var buffer = InputBuffer.create()
	buffer.add_action("move_up", 0.010)
	buffer.add_action("fire", 0.025)
	buffer.add_action("move_down", 0.040)
	assert_eq(buffer.get_buffered_actions().size(), 3, "Buffer should start with 3 actions")
	
	# When: Buffer is cleared
	buffer.clear()
	
	# Then: Buffer is empty
	assert_true(buffer.is_empty(), "Buffer should be empty after clear()")
	assert_eq(buffer.get_buffered_actions().size(), 0, "Buffer should contain no actions after clear()")

func test_given_buffer_with_actions_when_get_then_clear_then_subsequent_get_returns_empty():
	# Given: A buffer with actions
	var buffer = InputBuffer.create()
	buffer.add_action("move_left", 0.015)
	buffer.add_action("fire", 0.030)
	
	# When: Actions are retrieved, then buffer is cleared
	var first_read = buffer.get_buffered_actions()
	assert_eq(first_read.size(), 2, "First read should return 2 actions")
	buffer.clear()
	
	# Then: Subsequent reads return empty array
	var second_read = buffer.get_buffered_actions()
	assert_eq(second_read.size(), 0, "Second read after clear should return empty array")

func test_given_cleared_buffer_when_new_actions_added_then_buffer_stores_new_actions():
	# Given: A buffer that has been used and cleared
	var buffer = InputBuffer.create()
	buffer.add_action("move_up", 0.010)
	buffer.clear()
	assert_true(buffer.is_empty(), "Buffer should be empty after clear")
	
	# When: New actions are added after clearing
	buffer.add_action("move_down", 0.060)
	buffer.add_action("fire", 0.075)
	
	# Then: Buffer contains only the new actions
	var actions = buffer.get_buffered_actions()
	assert_eq(actions.size(), 2, "Buffer should contain 2 new actions")
	assert_eq(actions[0]["action"], "move_down", "First new action should be move_down")
	assert_eq(actions[1]["action"], "fire", "Second new action should be fire")


## Test Case 4: Buffer handles duplicate commands
## Design Decision: Keep all duplicates (useful for detecting double-taps, rapid fire)
## Rationale: Duplicate detection should be in adapter/application layer, not value object
func test_given_empty_buffer_when_same_action_added_twice_then_both_stored():
	# Given: An empty input buffer
	var buffer = InputBuffer.create()
	
	# When: Same action added twice with different timestamps
	buffer.add_action("fire", 0.010)
	buffer.add_action("fire", 0.025)
	
	# Then: Both actions are stored (no deduplication)
	var actions = buffer.get_buffered_actions()
	assert_eq(actions.size(), 2, "Buffer should store both duplicate actions")
	assert_eq(actions[0]["action"], "fire", "First action should be fire")
	assert_eq(actions[1]["action"], "fire", "Second action should also be fire")
	assert_almost_eq(actions[0]["timestamp"], 0.010, 0.001, "First timestamp preserved")
	assert_almost_eq(actions[1]["timestamp"], 0.025, 0.001, "Second timestamp preserved")

func test_given_empty_buffer_when_multiple_identical_actions_added_then_all_stored_in_order():
	# Given: An empty input buffer
	var buffer = InputBuffer.create()
	
	# When: Same action added multiple times (e.g., holding key across frames)
	buffer.add_action("move_up", 0.008)
	buffer.add_action("move_up", 0.016)
	buffer.add_action("move_up", 0.024)
	buffer.add_action("move_up", 0.032)
	
	# Then: All instances are stored in order
	var actions = buffer.get_buffered_actions()
	assert_eq(actions.size(), 4, "All four duplicate actions should be stored")
	for i in range(4):
		assert_eq(actions[i]["action"], "move_up", "Action %d should be move_up" % i)
	# Verify timestamps are ascending
	assert_true(actions[0]["timestamp"] < actions[1]["timestamp"], "Timestamps should be in order")
	assert_true(actions[1]["timestamp"] < actions[2]["timestamp"], "Timestamps should be in order")
	assert_true(actions[2]["timestamp"] < actions[3]["timestamp"], "Timestamps should be in order")


## Test Case 5: Buffer handles conflicting commands (e.g., UP then DOWN)
## Design Decision: Store all conflicting actions, let application layer decide precedence
## Rationale: Buffer is a dumb queue; conflict resolution belongs in InputAdapter/CommandHandler
func test_given_empty_buffer_when_opposing_directions_added_then_both_stored():
	# Given: An empty input buffer
	var buffer = InputBuffer.create()
	
	# When: Conflicting directional inputs added (UP then DOWN)
	buffer.add_action("move_up", 0.010)
	buffer.add_action("move_down", 0.025)
	
	# Then: Both actions are stored without conflict resolution
	var actions = buffer.get_buffered_actions()
	assert_eq(actions.size(), 2, "Both conflicting actions should be stored")
	assert_eq(actions[0]["action"], "move_up", "First action should be move_up")
	assert_eq(actions[1]["action"], "move_down", "Second action should be move_down")

func test_given_empty_buffer_when_left_then_right_added_then_both_stored():
	# Given: An empty input buffer
	var buffer = InputBuffer.create()
	
	# When: Conflicting horizontal inputs added
	buffer.add_action("move_left", 0.012)
	buffer.add_action("move_right", 0.030)
	
	# Then: Both actions stored in insertion order
	var actions = buffer.get_buffered_actions()
	assert_eq(actions.size(), 2, "Both horizontal conflicts should be stored")
	assert_eq(actions[0]["action"], "move_left", "First action should be move_left")
	assert_eq(actions[1]["action"], "move_right", "Second action should be move_right")

func test_given_empty_buffer_when_rapid_direction_changes_added_then_all_stored_in_order():
	# Given: An empty input buffer
	var buffer = InputBuffer.create()
	
	# When: Player rapidly changes direction (simulating confusion or complex movement)
	buffer.add_action("move_up", 0.005)
	buffer.add_action("move_left", 0.015)
	buffer.add_action("move_down", 0.025)
	buffer.add_action("move_right", 0.035)
	buffer.add_action("move_up", 0.045)
	
	# Then: All direction changes stored in sequence
	var actions = buffer.get_buffered_actions()
	assert_eq(actions.size(), 5, "All five direction changes should be stored")
	assert_eq(actions[0]["action"], "move_up", "Sequence preserved: move_up first")
	assert_eq(actions[1]["action"], "move_left", "Sequence preserved: move_left second")
	assert_eq(actions[2]["action"], "move_down", "Sequence preserved: move_down third")
	assert_eq(actions[3]["action"], "move_right", "Sequence preserved: move_right fourth")
	assert_eq(actions[4]["action"], "move_up", "Sequence preserved: move_up fifth")

func test_given_empty_buffer_when_movement_and_fire_interleaved_then_all_stored():
	# Given: An empty input buffer
	var buffer = InputBuffer.create()
	
	# When: Movement and fire actions interleaved (common in gameplay)
	buffer.add_action("move_up", 0.008)
	buffer.add_action("fire", 0.016)
	buffer.add_action("move_left", 0.024)
	buffer.add_action("fire", 0.032)
	buffer.add_action("move_down", 0.040)
	
	# Then: All actions stored in exact order
	var actions = buffer.get_buffered_actions()
	assert_eq(actions.size(), 5, "All interleaved actions should be stored")
	assert_eq(actions[0]["action"], "move_up", "Action 0: move_up")
	assert_eq(actions[1]["action"], "fire", "Action 1: fire")
	assert_eq(actions[2]["action"], "move_left", "Action 2: move_left")
	assert_eq(actions[3]["action"], "fire", "Action 3: fire")
	assert_eq(actions[4]["action"], "move_down", "Action 4: move_down")


## Edge Cases and Robustness Tests
func test_given_empty_buffer_when_action_added_with_zero_timestamp_then_accepts():
	# Given: An empty input buffer
	var buffer = InputBuffer.create()
	
	# When: Action added with timestamp of 0.0
	buffer.add_action("move_up", 0.0)
	
	# Then: Action is stored normally
	var actions = buffer.get_buffered_actions()
	assert_eq(actions.size(), 1, "Buffer should accept zero timestamp")
	assert_almost_eq(actions[0]["timestamp"], 0.0, 0.001, "Zero timestamp preserved")

func test_given_empty_buffer_when_action_added_with_negative_timestamp_then_accepts():
	# Given: An empty input buffer
	var buffer = InputBuffer.create()
	
	# When: Action added with negative timestamp (edge case for time rewind)
	buffer.add_action("fire", -0.001)
	
	# Then: Action is stored (buffer doesn't validate timestamp semantics)
	var actions = buffer.get_buffered_actions()
	assert_eq(actions.size(), 1, "Buffer should accept negative timestamp")
	assert_almost_eq(actions[0]["timestamp"], -0.001, 0.001, "Negative timestamp preserved")

func test_given_empty_buffer_when_empty_action_string_added_then_stores():
	# Given: An empty input buffer
	var buffer = InputBuffer.create()
	
	# When: Empty action string added (validation should be done by caller)
	buffer.add_action("", 0.010)
	
	# Then: Buffer stores it (buffer is dumb queue, doesn't validate semantics)
	var actions = buffer.get_buffered_actions()
	assert_eq(actions.size(), 1, "Buffer should store empty action string")
	assert_eq(actions[0]["action"], "", "Empty string action preserved")

func test_given_buffer_when_get_buffered_actions_called_multiple_times_then_returns_same_data():
	# Given: A buffer with actions
	var buffer = InputBuffer.create()
	buffer.add_action("move_up", 0.010)
	buffer.add_action("fire", 0.025)
	
	# When: get_buffered_actions called multiple times without clearing
	var first_call = buffer.get_buffered_actions()
	var second_call = buffer.get_buffered_actions()
	
	# Then: Both calls return same data (non-destructive read)
	assert_eq(first_call.size(), 2, "First call returns 2 actions")
	assert_eq(second_call.size(), 2, "Second call also returns 2 actions")
	assert_eq(first_call[0]["action"], second_call[0]["action"], "Same action in both calls")
	assert_eq(first_call[1]["action"], second_call[1]["action"], "Same action in both calls")

func test_given_empty_buffer_when_cleared_then_remains_usable():
	# Given: An empty buffer
	var buffer = InputBuffer.create()
	
	# When: clear() called on already empty buffer
	buffer.clear()
	
	# Then: Buffer remains usable and empty
	assert_true(buffer.is_empty(), "Buffer should remain empty")
	assert_eq(buffer.get_buffered_actions().size(), 0, "Should return empty array")
	
	# And: Can still add actions after clearing empty buffer
	buffer.add_action("move_up", 0.010)
	assert_eq(buffer.get_buffered_actions().size(), 1, "Buffer still functional after clear")
