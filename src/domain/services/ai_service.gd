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
const TILE_SIZE = 16
const ALIGN_TOLERANCE_PIXELS = 8

const DEFAULT_PROFILE = {
	"chase_tiles": 8,
	"shoot_tiles": 10,
	"patrol_interval_frames": 24
}

const AI_PROFILES = {
	TankEntity.Type.ENEMY_BASIC: {
		"chase_tiles": 8,
		"shoot_tiles": 10,
		"patrol_interval_frames": 24
	},
	TankEntity.Type.ENEMY_FAST: {
		"chase_tiles": 12,
		"shoot_tiles": 10,
		"patrol_interval_frames": 18
	},
	TankEntity.Type.ENEMY_POWER: {
		"chase_tiles": 10,
		"shoot_tiles": 12,
		"patrol_interval_frames": 20
	},
	TankEntity.Type.ENEMY_ARMORED: {
		"chase_tiles": 6,
		"shoot_tiles": 9,
		"patrol_interval_frames": 30
	}
}

## Decide action for enemy tank based on game state
static func decide_action(enemy: TankEntity, game_state: GameState, delta: float) -> Command:
	if not enemy or not enemy.is_alive():
		return null
	
	# Find nearest player tank
	var nearest_player = get_nearest_player_tank(game_state, enemy.position)
	
	# If no player exists, patrol
	if not nearest_player:
		return _create_patrol_command(enemy, game_state.frame, _get_ai_profile(enemy.tank_type))
	
	var profile = _get_ai_profile(enemy.tank_type)
	var distance = _calculate_distance(enemy.position, nearest_player.position)
	var aligned = _is_axis_aligned(enemy.position, nearest_player.position)
	
	# Shoot if lined up and ready
	var shoot_range = profile["shoot_tiles"] * TILE_SIZE
	if aligned and _is_facing_target(enemy, nearest_player.position) and can_shoot(enemy):
		if distance <= shoot_range:
			return FireCommand.create(enemy.id, game_state.frame)

	# If aligned but not facing the player, turn toward them
	if aligned and not _is_facing_target(enemy, nearest_player.position):
		return _create_face_target_command(enemy, nearest_player.position, game_state.frame)
	
	# Chase when close enough
	var chase_range = profile["chase_tiles"] * TILE_SIZE
	if distance <= chase_range:
		return _create_chase_command(enemy, nearest_player.position, game_state.frame)
	
	# Default to patrol
	return _create_patrol_command(enemy, game_state.frame, profile)

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
static func _create_patrol_command(enemy: TankEntity, frame: int, profile: Dictionary) -> Command:
	var directions = [Direction.UP, Direction.RIGHT, Direction.DOWN, Direction.LEFT]
	var interval = max(1, profile.get("patrol_interval_frames", DEFAULT_PROFILE["patrol_interval_frames"]))
	var phase = int(frame / interval) + abs(hash(enemy.id))
	var dir_value = directions[phase % directions.size()]
	return MoveCommand.create(enemy.id, Direction.create(dir_value), frame)

## Create chase command (move toward player)
static func _create_chase_command(enemy: TankEntity, target_pos: Position, frame: int) -> Command:
	var direction = _get_direction_toward(enemy.position, target_pos)
	return MoveCommand.create(enemy.id, direction, frame)

## Create command that turns tank to face aligned target axis
static func _create_face_target_command(enemy: TankEntity, target_pos: Position, frame: int) -> Command:
	var direction = _get_axis_facing_direction(enemy.position, target_pos)
	return MoveCommand.create(enemy.id, direction, frame)

## Calculate Euclidean distance between two positions
static func _calculate_distance(pos1: Position, pos2: Position) -> float:
	var dx = pos2.x - pos1.x
	var dy = pos2.y - pos1.y
	return sqrt(dx * dx + dy * dy)

## Check if enemy is facing toward target position
static func _is_facing_target(enemy: TankEntity, target_pos: Position) -> bool:
	var dx = target_pos.x - enemy.position.x
	var dy = target_pos.y - enemy.position.y

	if abs(dx) <= ALIGN_TOLERANCE_PIXELS:
		if dy < 0:
			return enemy.direction.value == Direction.UP
		elif dy > 0:
			return enemy.direction.value == Direction.DOWN
		return true

	if abs(dy) <= ALIGN_TOLERANCE_PIXELS:
		if dx < 0:
			return enemy.direction.value == Direction.LEFT
		elif dx > 0:
			return enemy.direction.value == Direction.RIGHT
		return true

	return false

## Check if aligned on either axis
static func _is_axis_aligned(pos1: Position, pos2: Position) -> bool:
	return abs(pos1.x - pos2.x) <= ALIGN_TOLERANCE_PIXELS or abs(pos1.y - pos2.y) <= ALIGN_TOLERANCE_PIXELS

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

## Get axis direction toward an aligned target (used for turning)
static func _get_axis_facing_direction(from_pos: Position, to_pos: Position) -> Direction:
	var dx = to_pos.x - from_pos.x
	var dy = to_pos.y - from_pos.y

	if abs(dx) <= ALIGN_TOLERANCE_PIXELS and dy != 0:
		return Direction.create(Direction.DOWN if dy > 0 else Direction.UP)

	if abs(dy) <= ALIGN_TOLERANCE_PIXELS and dx != 0:
		return Direction.create(Direction.RIGHT if dx > 0 else Direction.LEFT)

	return _get_direction_toward(from_pos, to_pos)

## Select AI profile for given enemy type
static func _get_ai_profile(tank_type: int) -> Dictionary:
	if AI_PROFILES.has(tank_type):
		return AI_PROFILES[tank_type]
	return DEFAULT_PROFILE
