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

# Movement repeat settings
const INITIAL_DELAY = 0.3  # Delay before first repeat
const REPEAT_DELAY = 0.1   # Delay between subsequent repeats

var time_since_last_move: float = 0.0
var last_move_direction: Tank.Direction
var has_last_direction: bool = false
var is_repeating: bool = false

func _ready() -> void:
	if not tank:
		tank = get_parent() as Tank
	
	if tank:
		tank.is_player = true
		tank.tank_id = player_id

func _physics_process(delta: float) -> void:
	if not tank or not is_instance_valid(tank):
		return
	
	# Skip input processing when game is paused
	if get_tree().paused:
		return
	
	time_since_last_move += delta
	_process_input()

func _process_input() -> void:
	var emit_events = EventBus != null and EventBus.has_method("emit_game_event")
	
	# Handle movement with repeat on hold
	_handle_movement_input()
	
	# Fire input
	if Input.is_action_just_pressed(INPUT_FIRE):
		if tank.try_fire():
			_emit_fire_event(true)

func _handle_movement_input() -> void:
	var emit_events = EventBus != null and EventBus.has_method("emit_game_event")
	
	# Handle movement with repeat on hold
	var direction_pressed: Tank.Direction
	var has_direction_pressed: bool = false
	
	if Input.is_action_pressed(INPUT_UP):
		direction_pressed = Tank.Direction.UP
		has_direction_pressed = true
	elif Input.is_action_pressed(INPUT_DOWN):
		direction_pressed = Tank.Direction.DOWN
		has_direction_pressed = true
	elif Input.is_action_pressed(INPUT_LEFT):
		direction_pressed = Tank.Direction.LEFT
		has_direction_pressed = true
	elif Input.is_action_pressed(INPUT_RIGHT):
		direction_pressed = Tank.Direction.RIGHT
		has_direction_pressed = true
	
	if has_direction_pressed:
		if Input.is_action_just_pressed(_get_input_action(direction_pressed)):
			# Initial press - move immediately
			_perform_move(direction_pressed, emit_events)
			time_since_last_move = 0.0
			last_move_direction = direction_pressed
			has_last_direction = true
			is_repeating = false
		elif has_last_direction and last_move_direction == direction_pressed and time_since_last_move > (INITIAL_DELAY if not is_repeating else REPEAT_DELAY):
			# Repeat movement
			_perform_move(direction_pressed, emit_events)
			time_since_last_move = 0.0
			is_repeating = true
	else:
		# Reset when no direction pressed
		is_repeating = false
		has_last_direction = false
		time_since_last_move = 0.0

func _perform_move(direction: Tank.Direction, emit_events: bool) -> void:
	tank.move_in_direction(direction)
	if emit_events:
		_emit_input_event(direction, true)

func _get_input_action(direction: Tank.Direction) -> String:
	match direction:
		Tank.Direction.UP:
			return INPUT_UP
		Tank.Direction.DOWN:
			return INPUT_DOWN
		Tank.Direction.LEFT:
			return INPUT_LEFT
		Tank.Direction.RIGHT:
			return INPUT_RIGHT
	return ""

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
