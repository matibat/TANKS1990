class_name InputAdapter
extends RefCounted
## InputAdapter - Converts Godot Input to Domain Commands
## Part of DDD architecture - bridges Godot input system with pure domain logic

const MoveCommand = preload("res://src/domain/commands/move_command.gd")
const FireCommand = preload("res://src/domain/commands/fire_command.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")

## Get commands for current frame based on player input
## @param tank_id: ID of the tank receiving commands
## @param frame: Current frame number
## @return Array of commands to execute this frame
func get_commands_for_frame(tank_id: String, frame: int) -> Array:
	var commands: Array = []
	
	# Check movement input (only one direction at a time, priority: up > down > left > right)
	if Input.is_action_pressed("move_up"):
		var direction = Direction.create(Direction.UP)
		commands.append(MoveCommand.create(tank_id, direction, frame))
	elif Input.is_action_pressed("move_down"):
		var direction = Direction.create(Direction.DOWN)
		commands.append(MoveCommand.create(tank_id, direction, frame))
	elif Input.is_action_pressed("move_left"):
		var direction = Direction.create(Direction.LEFT)
		commands.append(MoveCommand.create(tank_id, direction, frame))
	elif Input.is_action_pressed("move_right"):
		var direction = Direction.create(Direction.RIGHT)
		commands.append(MoveCommand.create(tank_id, direction, frame))
	
	# Check fire input
	if Input.is_action_pressed("fire"):
		commands.append(FireCommand.create(tank_id, frame))
	
	return commands

## Get commands for WASD input (alternative controls)
## @param tank_id: ID of the tank receiving commands
## @param frame: Current frame number
## @return Array of commands to execute this frame
func get_commands_wasd(tank_id: String, frame: int) -> Array:
	var commands: Array = []
	
	# Check WASD movement
	if Input.is_action_pressed("ui_up"):
		var direction = Direction.create(Direction.UP)
		commands.append(MoveCommand.create(tank_id, direction, frame))
	elif Input.is_action_pressed("ui_down"):
		var direction = Direction.create(Direction.DOWN)
		commands.append(MoveCommand.create(tank_id, direction, frame))
	elif Input.is_action_pressed("ui_left"):
		var direction = Direction.create(Direction.LEFT)
		commands.append(MoveCommand.create(tank_id, direction, frame))
	elif Input.is_action_pressed("ui_right"):
		var direction = Direction.create(Direction.RIGHT)
		commands.append(MoveCommand.create(tank_id, direction, frame))
	
	if Input.is_action_pressed("fire"):
		commands.append(FireCommand.create(tank_id, frame))
	
	return commands

## Convert Godot input event to domain command
## Useful for event-based input handling
## @param event: Godot InputEvent
## @param tank_id: ID of the tank receiving commands
## @param frame: Current frame number
## @return Command or null if event doesn't map to a command
func event_to_command(event: InputEvent, tank_id: String, frame: int):
	if event.is_action_pressed("move_up"):
		return MoveCommand.create(tank_id, Direction.create(Direction.UP), frame)
	elif event.is_action_pressed("move_down"):
		return MoveCommand.create(tank_id, Direction.create(Direction.DOWN), frame)
	elif event.is_action_pressed("move_left"):
		return MoveCommand.create(tank_id, Direction.create(Direction.LEFT), frame)
	elif event.is_action_pressed("move_right"):
		return MoveCommand.create(tank_id, Direction.create(Direction.RIGHT), frame)
	elif event.is_action_pressed("fire"):
		return FireCommand.create(tank_id, frame)
	
	return null
