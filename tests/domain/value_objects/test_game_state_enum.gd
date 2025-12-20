extends GutTest

# Test Suite: Game State Enum
# Purpose: Verify game state enumeration and string conversion

func test_given_enum_when_has_all_states_then_accessible():
	# Given/When: Enum states exist
	var menu = GameStateEnum.State.MENU
	var playing = GameStateEnum.State.PLAYING
	var paused = GameStateEnum.State.PAUSED
	var game_over = GameStateEnum.State.GAME_OVER
	var stage_complete = GameStateEnum.State.STAGE_COMPLETE
	
	# Then: All states are accessible
	assert_not_null(menu, "MENU state should exist")
	assert_not_null(playing, "PLAYING state should exist")
	assert_not_null(paused, "PAUSED state should exist")
	assert_not_null(game_over, "GAME_OVER state should exist")
	assert_not_null(stage_complete, "STAGE_COMPLETE state should exist")

func test_given_state_when_to_string_then_returns_name():
	# Given: Each state
	var states = [
		[GameStateEnum.State.MENU, "MENU"],
		[GameStateEnum.State.PLAYING, "PLAYING"],
		[GameStateEnum.State.PAUSED, "PAUSED"],
		[GameStateEnum.State.GAME_OVER, "GAME_OVER"],
		[GameStateEnum.State.STAGE_COMPLETE, "STAGE_COMPLETE"]
	]
	
	# When/Then: Convert each to string
	for state_pair in states:
		var result = GameStateEnum.state_to_string(state_pair[0])
		assert_eq(result, state_pair[1],
			"State %s should convert to '%s'" % [state_pair[0], state_pair[1]])

func test_given_unknown_state_when_to_string_then_returns_unknown():
	# Given: Invalid state value
	var invalid_state = 999
	
	# When: Convert to string
	var result = GameStateEnum.state_to_string(invalid_state)
	
	# Then: Returns "UNKNOWN"
	assert_eq(result, "UNKNOWN", "Unknown state should return 'UNKNOWN'")
