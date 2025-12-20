class_name AIService
extends RefCounted

## AIService - Domain Service
## Handles AI decision-making for enemy tanks
## All methods are static (stateless service)
## Part of DDD architecture - pure domain logic with no Godot dependencies

const TankEntity = preload("res://src/domain/entities/tank_entity.gd")
const GameState = preload("res://src/domain/aggregates/game_state.gd")
const Command = preload("res://src/domain/commands/command.gd")
const MoveCommand = preload("res://src/domain/commands/move_command.gd")
const FireCommand = preload("res://src/domain/commands/fire_command.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")

## AI behavior constants
const CHASE_DISTANCE_TILES = 8 # Chase player within 8 tiles
const SHOOT_RANGE_TILES = 10 # Shoot player within 10 tiles
const TILE_SIZE = 16

## Random timer for patrol direction changes (in seconds)
var _patrol_timer: float = 0.0
var _patrol_change_interval: float = 2.0

## Decide action for enemy tank based on game state
static func decide_action(enemy: TankEntity, game_state: GameState, delta: float) -> Command:
	if not enemy or not enemy.is_alive():
		return null
	
	# Find nearest player tank
	var nearest_player = get_nearest_player_tank(game_state, enemy.position)
	
	# If no player exists, patrol
	if not nearest_player:
		return _create_patrol_command(enemy)
	
	# Calculate distance to player
	var distance = _calculate_distance(enemy.position, nearest_player.position)
	
	# Check if can shoot at player
	if can_shoot(enemy) and _is_facing_target(enemy, nearest_player.position):
		var shoot_range = SHOOT_RANGE_TILES * TILE_SIZE
		if distance <= shoot_range:
			return FireCommand.create(enemy.id, game_state.frame)
	
	# Check if should chase player
	var chase_range = CHASE_DISTANCE_TILES * TILE_SIZE
	if distance <= chase_range:
		return _create_chase_command(enemy, nearest_player.position)
	
	# Default to patrol
	return _create_patrol_command(enemy)

## Update cooldowns for enemy tank
static func update_cooldowns(enemy: TankEntity, delta: float) -> void:
	if enemy:
		enemy.update_cooldown()

## Check if enemy can shoot
static func can_shoot(enemy: TankEntity) -> bool:
	if not enemy:
		return false
	return enemy.can_shoot()

## Get nearest player tank to enemy position
static func get_nearest_player_tank(game_state: GameState, enemy_pos: Position) -> TankEntity:
	var players = game_state.get_player_tanks()
	if players.is_empty():
		return null
	
	var nearest: TankEntity = null
	var min_distance = INF
	
	for player in players:
		var distance = _calculate_distance(enemy_pos, player.position)
		if distance < min_distance:
			min_distance = distance
			nearest = player
	
	return nearest

## Create patrol command (random or forward movement)
static func _create_patrol_command(enemy: TankEntity) -> Command:
	# Simple patrol: continue in current direction or pick random direction occasionally
	var direction = enemy.direction
	
	# 10% chance to change direction for variety
	if randf() < 0.1:
		direction = _get_random_direction()
	
	return MoveCommand.create(enemy.id, direction, 0)

## Create chase command (move toward player)
static func _create_chase_command(enemy: TankEntity, target_pos: Position) -> Command:
	var direction = _get_direction_toward(enemy.position, target_pos)
	return MoveCommand.create(enemy.id, direction, 0)

## Calculate Euclidean distance between two positions
static func _calculate_distance(pos1: Position, pos2: Position) -> float:
	var dx = pos2.x - pos1.x
	var dy = pos2.y - pos1.y
	return sqrt(dx * dx + dy * dy)

## Check if enemy is facing toward target position
static func _is_facing_target(enemy: TankEntity, target_pos: Position) -> bool:
	var delta = enemy.direction.to_position_delta()
	var to_target = Position.create(target_pos.x - enemy.position.x, target_pos.y - enemy.position.y)
	
	# Check if direction delta points toward target (same sign)
	if abs(delta.x) > abs(delta.y):
		# Horizontal movement
		return (delta.x * to_target.x) > 0
	else:
		# Vertical movement
		return (delta.y * to_target.y) > 0

## Get direction toward target position
static func _get_direction_toward(from_pos: Position, to_pos: Position) -> Direction:
	var dx = to_pos.x - from_pos.x
	var dy = to_pos.y - from_pos.y
	
	# Choose direction based on larger axis difference
	if abs(dx) > abs(dy):
		if dx > 0:
			return Direction.create(Direction.RIGHT)
		else:
			return Direction.create(Direction.LEFT)
	else:
		if dy > 0:
			return Direction.create(Direction.DOWN)
		else:
			return Direction.create(Direction.UP)

## Get random direction
static func _get_random_direction() -> Direction:
	var directions = [Direction.UP, Direction.DOWN, Direction.LEFT, Direction.RIGHT]
	var random_index = randi() % directions.size()
	return Direction.create(directions[random_index])
