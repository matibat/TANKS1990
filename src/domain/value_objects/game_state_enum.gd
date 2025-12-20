class_name GameStateEnum

## Game State Enumeration
## Defines all possible game states and provides string conversion

enum State {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER,
	STAGE_COMPLETE
}

static func state_to_string(state: State) -> String:
	match state:
		State.MENU: return "MENU"
		State.PLAYING: return "PLAYING"
		State.PAUSED: return "PAUSED"
		State.GAME_OVER: return "GAME_OVER"
		State.STAGE_COMPLETE: return "STAGE_COMPLETE"
		_: return "UNKNOWN"
