extends GutTest
# BDD: GameStateManager forwards lifecycle to ServerAdapter for local/remote orchestration

const GameStateManagerScript = preload("res://src/managers/game_state_manager.gd")
const ServerAdapter = preload("res://src/systems/server_adapter.gd")

class MockAdapter:
	extends ServerAdapter
	var started: bool = false
	var seen_seed: int = -1
	var seen_stage: int = -1
	var state_changes: Array = []
	
	func on_session_start(seed: int, stage: int) -> void:
		started = true
		seen_seed = seed
		seen_stage = stage
	
	func on_state_changed(previous_state: int, new_state: int) -> void:
		state_changes.append({"prev": previous_state, "next": new_state})

func test_given_adapter_when_starting_game_then_session_seed_passed():
	# Given: Game state manager with mock adapter
	var gsm = GameStateManagerScript.new()
	add_child_autofree(gsm)
	var adapter := MockAdapter.new()
	gsm.set_server_adapter(adapter)
	
	# When: Starting game with explicit seed
	gsm.start_game(888)
	
	# Then: Adapter receives session start with seed
	assert_true(adapter.started, "Adapter should be started")
	assert_eq(adapter.seen_seed, 888, "Seed should be forwarded to adapter")
	assert_eq(adapter.seen_stage, 1, "Stage should be forwarded to adapter")

func test_given_adapter_when_state_changes_then_notified():
	# Given: Game state manager with mock adapter
	var gsm = GameStateManagerScript.new()
	add_child_autofree(gsm)
	var adapter := MockAdapter.new()
	gsm.set_server_adapter(adapter)
	gsm.start_game(999)
	
	# When: Completing a stage triggers state change
	gsm.complete_stage()
	
	# Then: Adapter is notified of transition
	assert_gt(adapter.state_changes.size(), 0, "Adapter should receive state change callbacks")
