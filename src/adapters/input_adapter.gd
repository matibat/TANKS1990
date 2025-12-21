class_name InputAdapter
extends RefCounted
## InputAdapter - Converts Godot Input to Domain Commands
## Part of DDD architecture - bridges Godot input system with pure domain logic

const MoveCommand = preload("res://src/domain/commands/move_command.gd")
const FireCommand = preload("res://src/domain/commands/fire_command.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")
const InputBuffer = preload("res://src/domain/value_objects/input_buffer.gd")

## Input buffer for capturing actions between ticks
var input_buffer: InputBuffer = InputBuffer.create()

## Capture an input action to be processed in the next frame
## Should be called from Node's _input() or _unhandled_input()
## @param action: The action name (e.g., "move_up", "fire")
## @param timestamp: The time when the action occurred (in msec)
func capture_action(action: String, timestamp: float) -> void:
	input_buffer.add_action(action, timestamp)

## Get commands for current frame based on player input
## @param tank_id: ID of the tank receiving commands
## @param frame: Current frame number
## @return Array of commands to execute this frame
func get_commands_for_frame(tank_id: String, frame: int) -> Array:
	var commands: Array = []
	
	# Process buffered inputs first (event-based capture)
	var buffered_actions = input_buffer.get_buffered_actions()
	if not buffered_actions.is_empty():
		# Convert buffered actions to commands with priority handling
		var has_movement = false
		var has_fire = false
		
		# Priority: up > down > left > right
		var movement_priority = ["move_up", "move_down", "move_left", "move_right"]
		var selected_movement = ""
		
		for action_data in buffered_actions:
			var action = action_data["action"]
			
			# Check for movement actions
			if action in movement_priority:
				# Select highest priority movement
				if not has_movement:
					selected_movement = action
					has_movement = true
				else:
					# Check if this action has higher priority
					var current_idx = movement_priority.find(selected_movement)
					var new_idx = movement_priority.find(action)
					if new_idx < current_idx:
						selected_movement = action
			
			# Check for fire action
			elif action == "fire":
				has_fire = true
		
		# Create movement command if buffered
		if has_movement:
			commands.append(_create_command_from_action(selected_movement, tank_id, frame))
		
		# Create fire command if buffered
		if has_fire:
			commands.append(FireCommand.create(tank_id, frame))
		
		# Clear buffer after processing
		input_buffer.clear()
		
		return commands
	
	# Fallback to polling if no buffered inputs
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

## Helper method to create command from action string
## @param action: Action name (e.g., "move_up", "fire")
## @param tank_id: Tank ID
## @param frame: Current frame number
## @return Command instance
func _create_command_from_action(action: String, tank_id: String, frame: int):
	match action:
		"move_up":
			return MoveCommand.create(tank_id, Direction.create(Direction.UP), frame)
		"move_down":
			return MoveCommand.create(tank_id, Direction.create(Direction.DOWN), frame)
		"move_left":
			return MoveCommand.create(tank_id, Direction.create(Direction.LEFT), frame)
		"move_right":
			return MoveCommand.create(tank_id, Direction.create(Direction.RIGHT), frame)
		"fire":
			return FireCommand.create(tank_id, frame)
		_:
			return null

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
