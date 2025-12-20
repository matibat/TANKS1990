class_name CommandHandler
extends RefCounted

## CommandHandler - Domain Service
## Executes commands on GameState and emits domain events
## All methods are static (stateless service)
## Part of DDD architecture - pure domain logic with no Godot dependencies

const GameState = preload("res://src/domain/aggregates/game_state.gd")
const MovementService = preload("res://src/domain/services/movement_service.gd")
const Command = preload("res://src/domain/commands/command.gd")
const MoveCommand = preload("res://src/domain/commands/move_command.gd")
const FireCommand = preload("res://src/domain/commands/fire_command.gd")
const RotateCommand = preload("res://src/domain/commands/rotate_command.gd")
const PauseCommand = preload("res://src/domain/commands/pause_command.gd")
const DomainEvent = preload("res://src/domain/events/domain_event.gd")
const TankMovedEvent = preload("res://src/domain/events/tank_moved_event.gd")
const BulletFiredEvent = preload("res://src/domain/events/bullet_fired_event.gd")
const BulletEntity = preload("res://src/domain/entities/bullet_entity.gd")
const Position = preload("res://src/domain/value_objects/position.gd")

## Execute a command on game state and return emitted events
static func execute_command(game_state: GameState, command: Command) -> Array[DomainEvent]:
	var events: Array[DomainEvent] = []
	
	# Validate command
	if not command.is_valid():
		return events
	
	# Route to appropriate handler
	if command is MoveCommand:
		events.append_array(_execute_move_command(game_state, command))
	elif command is FireCommand:
		events.append_array(_execute_fire_command(game_state, command))
	elif command is RotateCommand:
		events.append_array(_execute_rotate_command(game_state, command))
	elif command is PauseCommand:
		events.append_array(_execute_pause_command(game_state, command))
	
	return events

## Execute move command
static func _execute_move_command(game_state: GameState, cmd: MoveCommand) -> Array[DomainEvent]:
	var events: Array[DomainEvent] = []
	
	# Get tank
	var tank = game_state.get_tank(cmd.tank_id)
	if tank == null:
		return events
	
	# Store old position
	var old_position = Position.create(tank.position.x, tank.position.y)
	
	# Try to move tank
	var moved = MovementService.execute_tank_movement(game_state, tank, cmd.direction)
	
	# If tank moved, emit event
	if moved:
		var event = TankMovedEvent.create(
			tank.id,
			old_position,
			tank.position,
			tank.direction,
			cmd.frame
		)
		events.append(event)
	
	return events

## Execute fire command
static func _execute_fire_command(game_state: GameState, cmd: FireCommand) -> Array[DomainEvent]:
	var events: Array[DomainEvent] = []
	
	# Get tank
	var tank = game_state.get_tank(cmd.tank_id)
	if tank == null:
		return events
	
	# Check if tank can fire
	if not tank.can_fire():
		return events
	
	# Generate bullet ID
	var bullet_id = game_state.generate_entity_id("bullet")
	
	# Calculate bullet spawn position (in front of tank)
	var spawn_offset = tank.direction.to_position_delta()
	var bullet_position = tank.position.add(spawn_offset)
	
	# Create bullet with speed and damage
	var bullet_speed = tank.stats.bullet_speed
	var bullet_damage = 1 # Default bullet damage
	var bullet = BulletEntity.create(bullet_id, tank.id, bullet_position, tank.direction, bullet_speed, bullet_damage)
	game_state.add_bullet(bullet)
	
	# Set tank cooldown
	tank.fire()
	
	# Emit event
	var event = BulletFiredEvent.create(
		bullet_id,
		tank.id,
		bullet_position,
		tank.direction,
		cmd.frame
	)
	events.append(event)
	
	return events

## Execute rotate command
static func _execute_rotate_command(game_state: GameState, cmd: RotateCommand) -> Array[DomainEvent]:
	var events: Array[DomainEvent] = []
	
	# Get tank
	var tank = game_state.get_tank(cmd.tank_id)
	if tank == null:
		return events
	
	# Rotate tank (just change direction, no event needed for rotation)
	tank.direction = cmd.direction
	
	return events

## Execute pause command
static func _execute_pause_command(game_state: GameState, cmd: PauseCommand) -> Array[DomainEvent]:
	var events: Array[DomainEvent] = []
	
	# Set pause state
	game_state.is_paused = cmd.should_pause
	
	# Pause command doesn't emit events
	return events
