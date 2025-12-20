extends GutTest

# Test Suite: Game State Machine
# Purpose: Verify state transitions and signal emissions

var state_machine: GameStateMachine

func before_each():
	state_machine = GameStateMachine.new()

func test_given_new_machine_when_created_then_starts_in_menu():
	# Given/When: New state machine
	# Then: Starts in MENU state
	assert_eq(state_machine.get_current_state(), GameStateEnum.State.MENU,
		"State machine should start in MENU state")

func test_given_menu_when_start_game_then_transitions_to_playing():
	# Given: State machine in MENU
	assert_eq(state_machine.get_current_state(), GameStateEnum.State.MENU)
	
	# When: Transition to PLAYING
	var result = state_machine.transition_to(GameStateEnum.State.PLAYING)
	
	# Then: Transition succeeds
	assert_true(result, "Transition from MENU to PLAYING should succeed")
	assert_eq(state_machine.get_current_state(), GameStateEnum.State.PLAYING,
		"State should be PLAYING")

func test_given_playing_when_pause_then_transitions_to_paused():
	# Given: State machine in PLAYING
	state_machine.transition_to(GameStateEnum.State.PLAYING)
	
	# When: Transition to PAUSED
	var result = state_machine.transition_to(GameStateEnum.State.PAUSED)
	
	# Then: Transition succeeds
	assert_true(result, "Transition from PLAYING to PAUSED should succeed")
	assert_eq(state_machine.get_current_state(), GameStateEnum.State.PAUSED,
		"State should be PAUSED")

func test_given_paused_when_resume_then_transitions_to_playing():
	# Given: State machine in PAUSED
	state_machine.transition_to(GameStateEnum.State.PLAYING)
	state_machine.transition_to(GameStateEnum.State.PAUSED)
	
	# When: Transition back to PLAYING
	var result = state_machine.transition_to(GameStateEnum.State.PLAYING)
	
	# Then: Transition succeeds
	assert_true(result, "Transition from PAUSED to PLAYING should succeed")
	assert_eq(state_machine.get_current_state(), GameStateEnum.State.PLAYING,
		"State should be PLAYING")

func test_given_playing_when_base_destroyed_then_game_over():
	# Given: State machine in PLAYING
	state_machine.transition_to(GameStateEnum.State.PLAYING)
	
	# When: Transition to GAME_OVER
	var result = state_machine.transition_to(GameStateEnum.State.GAME_OVER)
	
	# Then: Transition succeeds
	assert_true(result, "Transition from PLAYING to GAME_OVER should succeed")
	assert_eq(state_machine.get_current_state(), GameStateEnum.State.GAME_OVER,
		"State should be GAME_OVER")

func test_given_playing_when_all_enemies_killed_then_stage_complete():
	# Given: State machine in PLAYING
	state_machine.transition_to(GameStateEnum.State.PLAYING)
	
	# When: Transition to STAGE_COMPLETE
	var result = state_machine.transition_to(GameStateEnum.State.STAGE_COMPLETE)
	
	# Then: Transition succeeds
	assert_true(result, "Transition from PLAYING to STAGE_COMPLETE should succeed")
	assert_eq(state_machine.get_current_state(), GameStateEnum.State.STAGE_COMPLETE,
		"State should be STAGE_COMPLETE")

func test_given_stage_complete_when_continue_then_playing():
	# Given: State machine in STAGE_COMPLETE
	state_machine.transition_to(GameStateEnum.State.PLAYING)
	state_machine.transition_to(GameStateEnum.State.STAGE_COMPLETE)
	
	# When: Transition to PLAYING
	var result = state_machine.transition_to(GameStateEnum.State.PLAYING)
	
	# Then: Transition succeeds
	assert_true(result, "Transition from STAGE_COMPLETE to PLAYING should succeed")
	assert_eq(state_machine.get_current_state(), GameStateEnum.State.PLAYING,
		"State should be PLAYING")

func test_given_game_over_when_retry_then_playing():
	# Given: State machine in GAME_OVER
	state_machine.transition_to(GameStateEnum.State.PLAYING)
	state_machine.transition_to(GameStateEnum.State.GAME_OVER)
	
	# When: Transition to PLAYING
	var result = state_machine.transition_to(GameStateEnum.State.PLAYING)
	
	# Then: Transition succeeds
	assert_true(result, "Transition from GAME_OVER to PLAYING should succeed")
	assert_eq(state_machine.get_current_state(), GameStateEnum.State.PLAYING,
		"State should be PLAYING")

func test_given_any_state_when_quit_then_menu():
	# Given: Various states
	var test_states = [
		GameStateEnum.State.PLAYING,
		GameStateEnum.State.PAUSED,
		GameStateEnum.State.GAME_OVER,
		GameStateEnum.State.STAGE_COMPLETE
	]
	
	for test_state in test_states:
		# Setup state
		state_machine = GameStateMachine.new()
		if test_state != GameStateEnum.State.MENU:
			if test_state == GameStateEnum.State.PAUSED:
				state_machine.transition_to(GameStateEnum.State.PLAYING)
			elif test_state in [GameStateEnum.State.GAME_OVER, GameStateEnum.State.STAGE_COMPLETE]:
				state_machine.transition_to(GameStateEnum.State.PLAYING)
			state_machine.transition_to(test_state)
		
		# When: Transition to MENU
		var result = state_machine.transition_to(GameStateEnum.State.MENU)
		
		# Then: Transition succeeds
		assert_true(result,
			"Transition from %s to MENU should succeed" % GameStateEnum.state_to_string(test_state))
		assert_eq(state_machine.get_current_state(), GameStateEnum.State.MENU,
			"State should be MENU")

func test_given_invalid_transition_when_attempted_then_returns_false():
	# Given: State machine in MENU
	assert_eq(state_machine.get_current_state(), GameStateEnum.State.MENU)
	
	# When: Attempt invalid transition (MENU -> PAUSED not allowed)
	var result = state_machine.transition_to(GameStateEnum.State.PAUSED)
	
	# Then: Transition fails
	assert_false(result, "Invalid transition should return false")
	assert_eq(state_machine.get_current_state(), GameStateEnum.State.MENU,
		"State should remain MENU")

func test_given_state_change_when_emitted_then_signal_received():
	# Given: Signal watcher
	watch_signals(state_machine)
	
	# When: Transition to new state
	state_machine.transition_to(GameStateEnum.State.PLAYING)
	
	# Then: Signal emitted with correct parameters
	assert_signal_emitted(state_machine, "state_changed",
		"state_changed signal should be emitted")
	var params = get_signal_parameters(state_machine, "state_changed")
	assert_eq(params[0], GameStateEnum.State.MENU, "Old state should be MENU")
	assert_eq(params[1], GameStateEnum.State.PLAYING, "New state should be PLAYING")
