extends GutTest
## Unit Tests for InputAdapter
## Tests input buffering to prevent missed key presses

const InputAdapter = preload("res://src/adapters/input_adapter.gd")
const MoveCommand = preload("res://src/domain/commands/move_command.gd")
const FireCommand = preload("res://src/domain/commands/fire_command.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")

var input_adapter: InputAdapter

func before_each():
	input_adapter = InputAdapter.new()

func after_each():
	pass

## ============================================================================
## Epic: Input Handling - get_commands_for_frame
## ============================================================================

func test_given_input_adapter_when_get_commands_for_frame_with_move_up_then_returns_move_command():
	# Clear any lingering input state
	Input.action_release("move_up")
	Input.action_release("move_down")
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("fire")
	Input.action_release("ui_up")
	Input.action_release("ui_down")
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	Input.flush_buffered_events()
	
	input_adapter = InputAdapter.new()
	
	# Given: Simulate input by pressing move_up
	Input.action_press("move_up")
	
	# When: Call get_commands_for_frame
	var commands = input_adapter.get_commands_for_frame("tank1", 0)
	
	# Then: Returns move command
	assert_eq(commands.size(), 1, "Should return 1 command")
	assert_true(commands[0] is MoveCommand, "Should be MoveCommand")
	assert_eq(commands[0].direction.value, Direction.UP, "Should move UP")
	assert_eq(commands[0].tank_id, "tank1", "Should have correct tank_id")
	assert_eq(commands[0].frame, 0, "Should have correct frame")
	
	# Cleanup
	Input.action_release("move_up")
	input_adapter = null

func test_given_input_adapter_when_get_commands_for_frame_with_move_down_then_returns_move_command():
	# Clear any lingering input state
	Input.action_release("move_up")
	Input.action_release("move_down")
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("fire")
	Input.action_release("ui_up")
	Input.action_release("ui_down")
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	Input.flush_buffered_events()
	
	input_adapter = InputAdapter.new()
	
	# Given: Simulate input by pressing move_down
	Input.action_press("move_down")
	
	# When: Call get_commands_for_frame
	var commands = input_adapter.get_commands_for_frame("tank1", 0)
	
	# Then: Returns move command
	assert_eq(commands.size(), 1, "Should return 1 command")
	assert_true(commands[0] is MoveCommand, "Should be MoveCommand")
	assert_eq(commands[0].direction.value, Direction.DOWN, "Should move DOWN")
	
	# Cleanup
	Input.action_release("move_down")
	input_adapter = null

func test_given_input_adapter_when_get_commands_for_frame_with_move_left_then_returns_move_command():
	# Given: Simulate input by pressing move_left
	Input.action_press("move_left")
	
	# When: Call get_commands_for_frame
	var commands = input_adapter.get_commands_for_frame("tank1", 0)
	
	# Then: Returns move command
	assert_eq(commands.size(), 1, "Should return 1 command")
	assert_true(commands[0] is MoveCommand, "Should be MoveCommand")
	assert_eq(commands[0].direction.value, Direction.LEFT, "Should move LEFT")
	
	# Cleanup
	Input.action_release("move_left")

func test_given_input_adapter_when_get_commands_for_frame_with_move_right_then_returns_move_command():
	# Given: Simulate input by pressing move_right
	Input.action_press("move_right")
	
	# When: Call get_commands_for_frame
	var commands = input_adapter.get_commands_for_frame("tank1", 0)
	
	# Then: Returns move command
	assert_eq(commands.size(), 1, "Should return 1 command")
	assert_true(commands[0] is MoveCommand, "Should be MoveCommand")
	assert_eq(commands[0].direction.value, Direction.RIGHT, "Should move RIGHT")
	
	# Cleanup
	Input.action_release("move_right")

func test_given_input_adapter_when_get_commands_for_frame_with_fire_then_returns_fire_command():
	# Given: Simulate input by pressing fire
	Input.action_press("fire")
	
	# When: Call get_commands_for_frame
	var commands = input_adapter.get_commands_for_frame("tank1", 0)
	
	# Then: Returns fire command
	assert_eq(commands.size(), 1, "Should return 1 command")
	assert_true(commands[0] is FireCommand, "Should be FireCommand")
	assert_eq(commands[0].tank_id, "tank1", "Should have correct tank_id")
	assert_eq(commands[0].frame, 0, "Should have correct frame")
	
	# Cleanup
	Input.action_release("fire")

func test_given_input_adapter_when_get_commands_for_frame_with_move_and_fire_then_returns_both_commands():
	# Given: Simulate input by pressing move_up and fire
	Input.action_press("move_up")
	Input.action_press("fire")
	
	# When: Call get_commands_for_frame
	var commands = input_adapter.get_commands_for_frame("tank1", 0)
	
	# Then: Returns both commands
	assert_eq(commands.size(), 2, "Should return 2 commands")
	assert_true(commands[0] is MoveCommand, "First should be MoveCommand")
	assert_true(commands[1] is FireCommand, "Second should be FireCommand")
	
	# Cleanup
	Input.action_release("move_up")
	Input.action_release("fire")

func test_given_no_input_when_get_commands_for_frame_then_returns_empty():
	# Given: No input (ensure no actions are pressed)
	
	# When: Call get_commands_for_frame
	var commands = input_adapter.get_commands_for_frame("tank1", 0)
	
	# Then: Returns empty
	assert_eq(commands.size(), 0, "Should return empty commands")

## ============================================================================
## Epic: Input Handling - get_commands_wasd
## ============================================================================

func test_given_input_adapter_when_get_commands_wasd_with_ui_up_then_returns_move_command():
	# Given: Simulate input by pressing ui_up
	Input.action_press("ui_up")
	
	# When: Call get_commands_wasd
	var commands = input_adapter.get_commands_wasd("tank1", 0)
	
	# Then: Returns move command
	assert_eq(commands.size(), 1, "Should return 1 command")
	assert_true(commands[0] is MoveCommand, "Should be MoveCommand")
	assert_eq(commands[0].direction.value, Direction.UP, "Should move UP")
	
	# Cleanup
	Input.action_release("ui_up")

func test_given_input_adapter_when_get_commands_wasd_with_ui_down_then_returns_move_command():
	# Given: Simulate input by pressing ui_down
	Input.action_press("ui_down")
	
	# When: Call get_commands_wasd
	var commands = input_adapter.get_commands_wasd("tank1", 0)
	
	# Then: Returns move command
	assert_eq(commands.size(), 1, "Should return 1 command")
	assert_true(commands[0] is MoveCommand, "Should be MoveCommand")
	assert_eq(commands[0].direction.value, Direction.DOWN, "Should move DOWN")
	
	# Cleanup
	Input.action_release("ui_down")

func test_given_input_adapter_when_get_commands_wasd_with_ui_left_then_returns_move_command():
	# Given: Simulate input by pressing ui_left
	Input.action_press("ui_left")
	
	# When: Call get_commands_wasd
	var commands = input_adapter.get_commands_wasd("tank1", 0)
	
	# Then: Returns move command
	assert_eq(commands.size(), 1, "Should return 1 command")
	assert_true(commands[0] is MoveCommand, "Should be MoveCommand")
	assert_eq(commands[0].direction.value, Direction.LEFT, "Should move LEFT")
	
	# Cleanup
	Input.action_release("ui_left")

func test_given_input_adapter_when_get_commands_wasd_with_ui_right_then_returns_move_command():
	# Given: Simulate input by pressing ui_right
	Input.action_press("ui_right")
	
	# When: Call get_commands_wasd
	var commands = input_adapter.get_commands_wasd("tank1", 0)
	
	# Then: Returns move command
	assert_eq(commands.size(), 1, "Should return 1 command")
	assert_true(commands[0] is MoveCommand, "Should be MoveCommand")
	assert_eq(commands[0].direction.value, Direction.RIGHT, "Should move RIGHT")
	
	# Cleanup
	Input.action_release("ui_right")

func test_given_input_adapter_when_get_commands_wasd_with_fire_then_returns_fire_command():
	# Given: Simulate input by pressing fire
	Input.action_press("fire")
	
	# When: Call get_commands_wasd
	var commands = input_adapter.get_commands_wasd("tank1", 0)
	
	# Then: Returns fire command
	assert_eq(commands.size(), 1, "Should return 1 command")
	assert_true(commands[0] is FireCommand, "Should be FireCommand")
	
	# Cleanup
	Input.action_release("fire")

## ============================================================================
## Epic: Input Handling - event_to_command
## ============================================================================

func test_given_input_event_move_up_when_event_to_command_then_returns_move_command():
	# Given: InputEvent with move_up action pressed
	var event = InputEventAction.new()
	event.action = "move_up"
	event.pressed = true
	
	# When: Call event_to_command
	var command = input_adapter.event_to_command(event, "tank1", 0)
	
	# Then: Returns move command
	assert_not_null(command, "Should return a command")
	assert_true(command is MoveCommand, "Should be MoveCommand")
	assert_eq(command.direction.value, Direction.UP, "Should move UP")
	assert_eq(command.tank_id, "tank1", "Should have correct tank_id")
	assert_eq(command.frame, 0, "Should have correct frame")

func test_given_input_event_move_down_when_event_to_command_then_returns_move_command():
	# Given: InputEvent with move_down action pressed
	var event = InputEventAction.new()
	event.action = "move_down"
	event.pressed = true
	
	# When: Call event_to_command
	var command = input_adapter.event_to_command(event, "tank1", 0)
	
	# Then: Returns move command
	assert_not_null(command, "Should return a command")
	assert_true(command is MoveCommand, "Should be MoveCommand")
	assert_eq(command.direction.value, Direction.DOWN, "Should move DOWN")

func test_given_input_event_move_left_when_event_to_command_then_returns_move_command():
	# Given: InputEvent with move_left action pressed
	var event = InputEventAction.new()
	event.action = "move_left"
	event.pressed = true
	
	# When: Call event_to_command
	var command = input_adapter.event_to_command(event, "tank1", 0)
	
	# Then: Returns move command
	assert_not_null(command, "Should return a command")
	assert_true(command is MoveCommand, "Should be MoveCommand")
	assert_eq(command.direction.value, Direction.LEFT, "Should move LEFT")

func test_given_input_event_move_right_when_event_to_command_then_returns_move_command():
	# Given: InputEvent with move_right action pressed
	var event = InputEventAction.new()
	event.action = "move_right"
	event.pressed = true
	
	# When: Call event_to_command
	var command = input_adapter.event_to_command(event, "tank1", 0)
	
	# Then: Returns move command
	assert_not_null(command, "Should return a command")
	assert_true(command is MoveCommand, "Should be MoveCommand")
	assert_eq(command.direction.value, Direction.RIGHT, "Should move RIGHT")

func test_given_input_event_fire_when_event_to_command_then_returns_fire_command():
	# Given: InputEvent with fire action pressed
	var event = InputEventAction.new()
	event.action = "fire"
	event.pressed = true
	
	# When: Call event_to_command
	var command = input_adapter.event_to_command(event, "tank1", 0)
	
	# Then: Returns fire command
	assert_not_null(command, "Should return a command")
	assert_true(command is FireCommand, "Should be FireCommand")
	assert_eq(command.tank_id, "tank1", "Should have correct tank_id")
	assert_eq(command.frame, 0, "Should have correct frame")

func test_given_input_event_unknown_action_when_event_to_command_then_returns_null():
	# Given: InputEvent with unknown action
	var event = InputEventAction.new()
	event.action = "unknown_action"
	event.pressed = true
	
	# When: Call event_to_command
	var command = input_adapter.event_to_command(event, "tank1", 0)
	
	# Then: Returns null
	assert_null(command, "Should return null for unknown action")

func test_given_input_event_not_pressed_when_event_to_command_then_returns_null():
	# Given: InputEvent with action not pressed
	var event = InputEventAction.new()
	event.action = "move_up"
	event.pressed = false
	
	# When: Call event_to_command
	var command = input_adapter.event_to_command(event, "tank1", 0)
	
	# Then: Returns null
	assert_null(command, "Should return null for not pressed action")

## ============================================================================
## Epic: Input Buffering - Just Pressed Events
## ============================================================================

func test_given_just_pressed_move_up_when_get_commands_for_frame_then_captures_input():
	# Given: Simulate just_pressed event for move_up
	Input.action_press("move_up")
	
	# When: Call get_commands_for_frame
	var commands = input_adapter.get_commands_for_frame("tank1", 0)
	
	# Then: Input is captured in command
	assert_eq(commands.size(), 1, "Should capture the just pressed input")
	assert_eq(commands[0].direction.value, Direction.UP, "Should capture UP direction")
	
	# Cleanup
	Input.action_release("move_up")

func test_given_just_pressed_fire_when_get_commands_for_frame_then_captures_input():
	# Given: Simulate just_pressed event for fire
	Input.action_press("fire")
	
	# When: Call get_commands_for_frame
	var commands = input_adapter.get_commands_for_frame("tank1", 0)
	
	# Then: Input is captured in command
	assert_eq(commands.size(), 1, "Should capture the just pressed input")
	assert_true(commands[0] is FireCommand, "Should capture fire command")
	
	# Cleanup
	Input.action_release("fire")

func test_given_multiple_just_pressed_when_get_commands_for_frame_then_captures_all():
	# Given: Simulate just_pressed for multiple actions
	Input.action_press("move_up")
	Input.action_press("fire")
	
	# When: Call get_commands_for_frame
	var commands = input_adapter.get_commands_for_frame("tank1", 0)
	
	# Then: All inputs are captured
	assert_eq(commands.size(), 2, "Should capture all just pressed inputs")
	assert_true(commands[0] is MoveCommand, "First should be move")
	assert_true(commands[1] is FireCommand, "Second should be fire")
	
	# Cleanup
	Input.action_release("move_up")
	Input.action_release("fire")