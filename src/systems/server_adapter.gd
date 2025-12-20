class_name ServerAdapter
extends RefCounted
## Boundary for routing gameplay to a local or remote authoritative server
## Default implementation is for local single-player with deterministic seeds

func on_session_start(seed: int, _stage: int) -> void:
	RandomProvider.set_seed(seed)

func on_state_changed(_previous_state: int, _new_state: int) -> void:
	pass

func publish_input(event: GameEvent) -> void:
	EventBus.emit_game_event(event)

func apply_snapshot(_snapshot: Dictionary) -> void:
	pass

func is_authoritative() -> bool:
	return true
