class_name GameStateManager
extends Node
## Manages global game state transitions and flow
## Handles: MainMenu, Playing, Paused, GameOver, StageComplete states

enum State {
	MAIN_MENU,
	PLAYING,
	PAUSED,
	GAME_OVER,
	STAGE_COMPLETE
}

# Current state
var current_state: State = State.MAIN_MENU
var previous_state: State = State.MAIN_MENU

# Stage tracking
var current_stage: int = 1
var total_stages: int = 35

# Game session data
var total_score: int = 0
var player_lives: int = 3

# Signals for state changes
signal state_changed(from_state: State, to_state: State)
signal game_started()
signal game_paused()
signal game_resumed()
signal stage_completed()
signal stage_restarted()
signal next_stage_loaded()
signal game_over_triggered(reason: String)

func _ready() -> void:
	# Initialize in main menu state
	current_state = State.MAIN_MENU

## ============================================================================
## State Transitions
## ============================================================================

func start_game() -> void:
	"""Start new game from main menu"""
	if current_state != State.MAIN_MENU:
		return
	
	_transition_to(State.PLAYING)
	game_started.emit()
	
	# Reset game session
	current_stage = 1
	total_score = 0
	player_lives = 3

func toggle_pause() -> void:
	"""Toggle between playing and paused states"""
	if current_state == State.PLAYING:
		_transition_to(State.PAUSED)
		game_paused.emit()
	elif current_state == State.PAUSED:
		_transition_to(State.PLAYING)
		game_resumed.emit()

func complete_stage() -> void:
	"""Mark current stage as complete"""
	if current_state != State.PLAYING:
		return
	
	_transition_to(State.STAGE_COMPLETE)
	stage_completed.emit()

func load_next_stage() -> void:
	"""Load next stage after completion"""
	if current_state != State.STAGE_COMPLETE:
		return
	
	current_stage += 1
	
	if current_stage > total_stages:
		# Game fully completed
		trigger_game_over("All stages completed")
	else:
		_transition_to(State.PLAYING)
		next_stage_loaded.emit()

func retry_stage() -> void:
	"""Retry current stage after game over"""
	if current_state != State.GAME_OVER:
		return
	
	# Reset lives for retry
	player_lives = 3
	
	_transition_to(State.PLAYING)
	stage_restarted.emit()

func quit_to_menu() -> void:
	"""Return to main menu from any state"""
	_transition_to(State.MAIN_MENU)

func trigger_game_over(reason: String) -> void:
	"""Trigger game over state with reason"""
	if current_state == State.GAME_OVER:
		return
	
	_transition_to(State.GAME_OVER)
	game_over_triggered.emit(reason)

## ============================================================================
## State Validation
## ============================================================================

func can_transition_to(new_state: State) -> bool:
	"""Check if transition to new state is valid"""
	match current_state:
		State.MAIN_MENU:
			return new_state == State.PLAYING
		State.PLAYING:
			return new_state in [State.PAUSED, State.GAME_OVER, State.STAGE_COMPLETE]
		State.PAUSED:
			return new_state in [State.PLAYING, State.MAIN_MENU]
		State.GAME_OVER:
			return new_state in [State.PLAYING, State.MAIN_MENU]
		State.STAGE_COMPLETE:
			return new_state in [State.PLAYING, State.GAME_OVER]
	
	return false

func _transition_to(new_state: State) -> void:
	"""Internal method to handle state transition"""
	if not can_transition_to(new_state):
		push_warning("Invalid state transition: %s -> %s" % [
			State.keys()[current_state],
			State.keys()[new_state]
		])
		return
	
	previous_state = current_state
	current_state = new_state
	state_changed.emit(previous_state, current_state)

## ============================================================================
## Stage Completion Checking
## ============================================================================

func check_stage_completion(remaining_enemies: int) -> void:
	"""Check if stage is complete based on remaining enemies"""
	if remaining_enemies == 0 and current_state == State.PLAYING:
		complete_stage()

## ============================================================================
## Game Over Conditions
## ============================================================================

func check_game_over_conditions(base_destroyed: bool, player_dead: bool) -> void:
	"""Check various game over conditions"""
	if base_destroyed:
		trigger_game_over("Base destroyed")
	elif player_dead and player_lives <= 0:
		trigger_game_over("No lives remaining")
