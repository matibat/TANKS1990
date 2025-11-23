class_name PlayerInputEvent
extends GameEvent
## Player input event for deterministic replay

enum InputType { MOVE, FIRE, PAUSE }
enum Direction { UP, DOWN, LEFT, RIGHT, NONE }

var input_type: InputType
var direction: Direction = Direction.NONE
var is_pressed: bool = true
var player_id: int = 0

func get_event_type() -> String:
	return "Input"

func to_dict() -> Dictionary:
	var base = super.to_dict()
	base["input_type"] = input_type
	base["direction"] = direction
	base["is_pressed"] = is_pressed
	base["player_id"] = player_id
	return base

static func from_dict(data: Dictionary) -> PlayerInputEvent:
	var event = PlayerInputEvent.new()
	event.frame = data.get("frame", 0)
	event.timestamp = data.get("timestamp", 0)
	event.input_type = data.get("input_type", InputType.MOVE)
	event.direction = data.get("direction", Direction.NONE)
	event.is_pressed = data.get("is_pressed", true)
	event.player_id = data.get("player_id", 0)
	return event

## Deserialize from bytes
static func deserialize(data: PackedByteArray) -> PlayerInputEvent:
	var dict = bytes_to_var(data)
	return from_dict(dict)

## Helper to create move event
static func create_move(dir: Direction, pressed: bool = true, player: int = 0) -> PlayerInputEvent:
	var event = PlayerInputEvent.new()
	event.input_type = InputType.MOVE
	event.direction = dir
	event.is_pressed = pressed
	event.player_id = player
	return event

## Helper to create fire event
static func create_fire(pressed: bool = true, player: int = 0) -> PlayerInputEvent:
	var event = PlayerInputEvent.new()
	event.input_type = InputType.FIRE
	event.is_pressed = pressed
	event.player_id = player
	return event

## Helper to create pause event
static func create_pause(pressed: bool = true) -> PlayerInputEvent:
	var event = PlayerInputEvent.new()
	event.input_type = InputType.PAUSE
	event.is_pressed = pressed
	return event
