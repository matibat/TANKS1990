class_name LocalServerAdapter
extends ServerAdapter
## Local adapter keeps current single-player behavior but honors deterministic seeds

func on_session_start(seed: int, _stage: int) -> void:
	RandomProvider.set_seed(seed)

func on_state_changed(_previous_state: int, _new_state: int) -> void:
	pass

func publish_input(event: GameEvent) -> void:
	EventBus.emit_game_event(event)

func is_authoritative() -> bool:
	return true
