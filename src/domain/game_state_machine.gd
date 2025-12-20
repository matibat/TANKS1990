class_name GameStateMachine
extends RefCounted

## Game State Machine
## Manages game state transitions and emits state change signals

signal state_changed(old_state: int, new_state: int)

var current_state: GameStateEnum.State = GameStateEnum.State.MENU
var _valid_transitions: Dictionary = {}

func _init():
	_setup_transitions()

func _setup_transitions():
	# Define valid state transitions
	_valid_transitions[GameStateEnum.State.MENU] = [
		GameStateEnum.State.PLAYING
	]
	
	_valid_transitions[GameStateEnum.State.PLAYING] = [
		GameStateEnum.State.PAUSED,
		GameStateEnum.State.GAME_OVER,
		GameStateEnum.State.STAGE_COMPLETE,
		GameStateEnum.State.MENU
	]
	
	_valid_transitions[GameStateEnum.State.PAUSED] = [
		GameStateEnum.State.PLAYING,
		GameStateEnum.State.MENU
	]
	
	_valid_transitions[GameStateEnum.State.GAME_OVER] = [
		GameStateEnum.State.PLAYING,
		GameStateEnum.State.MENU
	]
	
	_valid_transitions[GameStateEnum.State.STAGE_COMPLETE] = [
		GameStateEnum.State.PLAYING,
		GameStateEnum.State.MENU
	]

func transition_to(new_state: GameStateEnum.State) -> bool:
	if not can_transition_to(new_state):
		return false
	
	var old_state = current_state
	current_state = new_state
	state_changed.emit(old_state, new_state)
	return true

func can_transition_to(new_state: GameStateEnum.State) -> bool:
	return new_state in _valid_transitions.get(current_state, [])

func get_current_state() -> GameStateEnum.State:
	return current_state
