class_name AIService
extends RefCounted

## AIService - Domain Service
## Handles AI decision-making for enemy tanks
## All methods are static (stateless service)
## Part of DDD architecture - pure domain logic with no Godot dependencies

const TankEntity = preload("res://src/domain/entities/tank_entity.gd")
const GameState = preload("res://src/domain/aggregates/game_state.gd")
const MoveCommand = preload("res://src/domain/commands/move_command.gd")
const FireCommand = preload("res://src/domain/commands/fire_command.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")

## AI behavior constants
const TILE_SIZE = 16
const ALIGN_TOLERANCE_PIXELS = 8
const DEFAULT_DIRECTION_HOLD_FRAMES = 3
static var _direction_state: Dictionary = {}

const DEFAULT_PROFILE = {
	"chase_tiles": 8,
	"shoot_tiles": 10,
	"patrol_interval_frames": 24,
	"direction_hold_frames": DEFAULT_DIRECTION_HOLD_FRAMES
}

const AI_PROFILES = {
	TankEntity.Type.ENEMY_BASIC: {
		"chase_tiles": 8,
		"shoot_tiles": 10,
		"patrol_interval_frames": 24,
		"direction_hold_frames": 4
	},
	TankEntity.Type.ENEMY_FAST: {
		"chase_tiles": 12,
		"shoot_tiles": 10,
		"patrol_interval_frames": 18,
		"direction_hold_frames": 3
	},
	TankEntity.Type.ENEMY_POWER: {
		"chase_tiles": 10,
		"shoot_tiles": 12,
		"patrol_interval_frames": 20,
		"direction_hold_frames": 3
	},
	TankEntity.Type.ENEMY_ARMORED: {
		"chase_tiles": 6,
		"shoot_tiles": 9,
		"patrol_interval_frames": 30,
		"direction_hold_frames": 5
	}
}

static var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
static func set_rng(p_rng: RandomNumberGenerator) -> void:
	# Allow deterministic seeding for tests/server or replay
	_rng = p_rng if p_rng != null else RandomNumberGenerator.new()
	if p_rng == null:
		_rng.randomize()

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

	var shoot_range = profile["shoot_tiles"] * TILE_SIZE
	var in_engagement = distance <= shoot_range

	# Close the gap until we can shoot
	if not in_engagement:
		return _create_chase_command(enemy, nearest_player.position, game_state.frame, profile)

	# Inside engagement window: prioritize lining up and firing instead of crowding the player
	if aligned:
		if _is_facing_target(enemy, nearest_player.position) and can_shoot(enemy):
			return FireCommand.create(enemy.id, game_state.frame)
		return _create_face_target_command(enemy, nearest_player.position, game_state.frame, profile)

	# Not aligned yet: step toward an alignment axis but avoid over-closing beyond engagement range
	return _create_alignment_step(enemy, nearest_player.position, game_state.frame, profile)

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
	return _create_move_command_with_hold(enemy.id, Direction.create(dir_value), frame, profile, true, enemy.get_instance_id())

## Create chase command (move toward player)
static func _create_chase_command(enemy: TankEntity, target_pos: Position, frame: int, profile: Dictionary) -> Command:
	var direction = _get_direction_toward(enemy.position, target_pos)
	return _create_move_command_with_hold(enemy.id, direction, frame, profile, true, enemy.get_instance_id())

## Create command that turns tank to face aligned target axis

static func _create_face_target_command(enemy: TankEntity, target_pos: Position, frame: int, profile: Dictionary) -> Command:
	var direction = _get_axis_facing_direction(enemy.position, target_pos)
	# Honor the direction hold even when aligning so the enemy keeps a steady heading for the requested frames.
	return _create_move_command_with_hold(enemy.id, direction, frame, profile, true, enemy.get_instance_id())

## Create a small alignment step to line up shots without over-chasing
static func _create_alignment_step(enemy: TankEntity, target_pos: Position, frame: int, profile: Dictionary) -> Command:
	var direction = _get_direction_toward(enemy.position, target_pos)
	return _create_move_command_with_hold(enemy.id, direction, frame, profile, true, enemy.get_instance_id())


static func _create_move_command_with_hold(tank_id: String, direction: Direction, frame: int, profile: Dictionary, allow_hold: bool, instance_id: int) -> MoveCommand:
	var config = profile if profile != null else DEFAULT_PROFILE
	if allow_hold:
		var hold_frames = max(1, config.get("direction_hold_frames", DEFAULT_PROFILE["direction_hold_frames"]))
		direction = _get_smoothed_direction(tank_id, direction, hold_frames, frame, instance_id)
	else:
		_reset_direction_state(tank_id, direction, frame, instance_id)
	return MoveCommand.create(tank_id, direction, frame)


static func _get_smoothed_direction(tank_id: String, desired_direction: Direction, hold_limit: int, frame: int, instance_id: int) -> Direction:
	var now_frame = frame
	var desired_value = desired_direction.value
	var record = _direction_state.get(tank_id, null)
	if record != null:
		if record.get("instance_id", -1) != instance_id:
			record = null
			_direction_state.erase(tank_id)
		else:
			var last_frame = record.get("last_frame", -1)
			if last_frame >= 0 and now_frame < last_frame:
				record = null
				_direction_state.erase(tank_id)
	if record == null:
		record = {
			"direction": desired_value,
			"unlock_frame": now_frame + hold_limit,
			"last_frame": now_frame,
			"instance_id": instance_id
		}
		_direction_state[tank_id] = record
		return desired_direction
	if now_frame <= record["unlock_frame"]:
		record["last_frame"] = now_frame
		_direction_state[tank_id] = record
		return Direction.create(record["direction"])
	record["direction"] = desired_value
	record["unlock_frame"] = now_frame + hold_limit
	record["last_frame"] = now_frame
	_direction_state[tank_id] = record
	return desired_direction

static func _reset_direction_state(tank_id: String, direction: Direction, frame: int, instance_id: int) -> void:
	_direction_state[tank_id] = {
		"direction": direction.value,
		"unlock_frame": frame,
		"last_frame": frame,
		"instance_id": instance_id
	}

static func clear_direction_state(tank_id: String) -> void:
	_direction_state.erase(tank_id)

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
