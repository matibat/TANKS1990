class_name SpawnController
extends RefCounted

## SpawnController - Domain Service
## Handles enemy spawning logic for each stage
## Part of DDD architecture - pure domain logic with no Godot dependencies

const TankEntity = preload("res://src/domain/entities/tank_entity.gd")
const GameState = preload("res://src/domain/aggregates/game_state.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")
const GameTiming = preload("res://src/domain/constants/game_timing.gd")

## Constants
const ENEMIES_PER_STAGE = 20
const MAX_ENEMIES_ON_FIELD = 4
const SPAWN_INTERVAL_MIN = 3.0 # seconds
const SPAWN_INTERVAL_MAX = 5.0 # seconds
const TILE_SIZE = 16

## Spawn locations (top of screen)
const SPAWN_POSITIONS = [
	Vector2(1, 0), # Left
	Vector2(12, 0), # Center
	Vector2(24, 0) # Right
]

## Enemy type distribution (weights)
const BASIC_WEIGHT = 0.50 # 50%
const FAST_WEIGHT = 0.25 # 25%
const POWER_WEIGHT = 0.15 # 15%
const ARMORED_WEIGHT = 0.10 # 10%

## Properties
var _stage_number: int
var _enemies_remaining: int
var _enemies_spawned: int
var _spawn_timer: float
var _spawn_interval: float
var rng: RandomNumberGenerator

func _init(stage_number: int, p_rng: RandomNumberGenerator = null):
	_stage_number = stage_number
	_enemies_remaining = ENEMIES_PER_STAGE
	_enemies_spawned = 0
	_spawn_timer = 0.0
	rng = p_rng if p_rng != null else RandomNumberGenerator.new()
	if p_rng == null:
		rng.randomize()
	_spawn_interval = rng.randf_range(SPAWN_INTERVAL_MIN, SPAWN_INTERVAL_MAX)

func set_rng(p_rng: RandomNumberGenerator) -> void:
	# Allow deterministic seeding for tests/server replay
	rng = p_rng if p_rng != null else RandomNumberGenerator.new()
	if p_rng == null:
		rng.randomize()

## Get number of enemies remaining to spawn
func get_enemies_remaining() -> int:
	return _enemies_remaining

## Check if should spawn a new enemy
func should_spawn(game_state: GameState, delta: float) -> bool:
	# No more enemies to spawn
	if _enemies_remaining <= 0:
		return false
	
	# Check enemy count on field
	var enemy_count = game_state.get_enemy_tanks().size()
	if enemy_count >= MAX_ENEMIES_ON_FIELD:
		return false
	
	# Update spawn timer
	_spawn_timer += delta
	
	# Check if spawn interval has passed
	if _spawn_timer >= _spawn_interval:
		_spawn_timer = 0.0
		_spawn_interval = rng.randf_range(SPAWN_INTERVAL_MIN, SPAWN_INTERVAL_MAX)
		return true
	
	return false

## Spawn a new enemy and add to game state
func spawn_enemy(game_state: GameState) -> TankEntity:
	if _enemies_remaining <= 0:
		return null
	
	var enemy_id = game_state.generate_entity_id("enemy")
	var enemy_type = get_random_enemy_type()
	var spawn_pos = get_spawn_position()
	var spawn_dir = Direction.create(Direction.DOWN)
	
	var enemy = TankEntity.create(enemy_id, enemy_type, spawn_pos, spawn_dir)
	enemy.set_invulnerable(GameTiming.INVULNERABILITY_FRAMES)
	game_state.add_tank(enemy)
	
	_enemies_remaining -= 1
	_enemies_spawned += 1
	
	return enemy

## Get spawn position (one of three top locations)
func get_spawn_position() -> Position:
	var spawn_idx = rng.randi() % SPAWN_POSITIONS.size()
	var tile_pos = SPAWN_POSITIONS[spawn_idx]
	return Position.create(int(tile_pos.x * TILE_SIZE), int(tile_pos.y * TILE_SIZE))

## Get random enemy type based on weighted distribution
func get_random_enemy_type() -> int:
	var rand_val = rng.randf()
	
	if rand_val < BASIC_WEIGHT:
		return TankEntity.Type.ENEMY_BASIC
	elif rand_val < BASIC_WEIGHT + FAST_WEIGHT:
		return TankEntity.Type.ENEMY_FAST
	elif rand_val < BASIC_WEIGHT + FAST_WEIGHT + POWER_WEIGHT:
		return TankEntity.Type.ENEMY_POWER
	else:
		return TankEntity.Type.ENEMY_ARMORED

## Check if stage is complete (all enemies spawned and killed)
func is_stage_complete(game_state: GameState) -> bool:
	# All enemies must be spawned
	if _enemies_remaining > 0:
		return false
	
	# No enemies should be on field
	var enemy_count = game_state.get_enemy_tanks().size()
	return enemy_count == 0
