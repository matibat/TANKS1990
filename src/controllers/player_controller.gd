class_name PlayerController
extends Node
## Handles player input and controls player tank

@export var tank: Tank
@export var player_id: int = 0

# Input mapping
const INPUT_UP = "move_up"
const INPUT_DOWN = "move_down"
const INPUT_LEFT = "move_left"
const INPUT_RIGHT = "move_right"
const INPUT_FIRE = "fire"

func _ready() -> void:
	if not tank:
		tank = get_parent() as Tank
	
	if tank:
		tank.is_player = true
		tank.tank_id = player_id

func _physics_process(_delta: float) -> void:
	if not tank or not is_instance_valid(tank):
		return
	
	# Skip input processing when game is paused
	if get_tree().paused:
		return
	
	_process_input()

func _process_input() -> void:
	# Movement input - discrete movement on key press
	var emit_events = EventBus != null and EventBus.has_method("emit_game_event")
	
	if Input.is_action_just_pressed(INPUT_UP):
		tank.move_in_direction(Tank.Direction.UP)
		if emit_events: _emit_input_event(Tank.Direction.UP, true)
	elif Input.is_action_just_pressed(INPUT_DOWN):
		tank.move_in_direction(Tank.Direction.DOWN)
		if emit_events: _emit_input_event(Tank.Direction.DOWN, true)
	elif Input.is_action_just_pressed(INPUT_LEFT):
		tank.move_in_direction(Tank.Direction.LEFT)
		if emit_events: _emit_input_event(Tank.Direction.LEFT, true)
	elif Input.is_action_just_pressed(INPUT_RIGHT):
		tank.move_in_direction(Tank.Direction.RIGHT)
		if emit_events: _emit_input_event(Tank.Direction.RIGHT, true)
	
	# Fire input
	if Input.is_action_just_pressed(INPUT_FIRE):
		if tank.try_fire():
			_emit_fire_event(true)

func _emit_input_event(direction: Tank.Direction, pressed: bool) -> void:
	var event = PlayerInputEvent.create_move(_convert_direction(direction), pressed, player_id)
	EventBus.emit_game_event(event)

func _emit_fire_event(pressed: bool) -> void:
	var event = PlayerInputEvent.create_fire(pressed, player_id)
	EventBus.emit_game_event(event)

func _convert_direction(tank_dir: Tank.Direction) -> PlayerInputEvent.Direction:
	match tank_dir:
		Tank.Direction.UP:
			return PlayerInputEvent.Direction.UP
		Tank.Direction.DOWN:
			return PlayerInputEvent.Direction.DOWN
		Tank.Direction.LEFT:
			return PlayerInputEvent.Direction.LEFT
		Tank.Direction.RIGHT:
			return PlayerInputEvent.Direction.RIGHT
	return PlayerInputEvent.Direction.NONE
