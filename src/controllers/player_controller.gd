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
	# Movement input
	var input_vector = Vector2.ZERO
	
	if Input.is_action_pressed(INPUT_UP):
		input_vector.y -= 1
		_emit_input_event(Tank.Direction.UP, true)
	if Input.is_action_pressed(INPUT_DOWN):
		input_vector.y += 1
		_emit_input_event(Tank.Direction.DOWN, true)
	if Input.is_action_pressed(INPUT_LEFT):
		input_vector.x -= 1
		_emit_input_event(Tank.Direction.LEFT, true)
	if Input.is_action_pressed(INPUT_RIGHT):
		input_vector.x += 1
		_emit_input_event(Tank.Direction.RIGHT, true)
	
	# Apply movement to tank
	if input_vector.length() > 0:
		# Tank 1990 uses 4-directional movement, prioritize vertical
		if input_vector.y != 0:
			tank.move_in_direction(
				Tank.Direction.UP if input_vector.y < 0 else Tank.Direction.DOWN
			)
		elif input_vector.x != 0:
			tank.move_in_direction(
				Tank.Direction.LEFT if input_vector.x < 0 else Tank.Direction.RIGHT
			)
	else:
		tank.stop_movement()
	
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
