class_name GameState
extends RefCounted

## GameState Aggregate (Root Aggregate)
## Represents the complete game state - root of the consistency boundary
## Part of DDD architecture - pure domain logic with no Godot dependencies

const StageState = preload("res://src/domain/aggregates/stage_state.gd")
const TankEntity = preload("res://src/domain/entities/tank_entity.gd")
const BulletEntity = preload("res://src/domain/entities/bullet_entity.gd")
const SpawnController = preload("res://src/domain/services/spawn_controller.gd")

## Properties
var frame: int # Current frame number
var stage: StageState # Current stage
var tanks: Dictionary # tank_id -> TankEntity
var bullets: Dictionary # bullet_id -> BulletEntity
var player_lives: int
var score: int
var is_paused: bool
var is_game_over: bool
var next_entity_id: int # For generating unique IDs
var spawn_controller: SpawnController # Handles enemy spawning

## Static factory method to create game state
static func create(p_stage: StageState, p_player_lives: int = 3):
	var game_state = new()
	game_state.frame = 0
	game_state.stage = p_stage
	game_state.tanks = {}
	game_state.bullets = {}
	game_state.player_lives = p_player_lives
	game_state.score = 0
	game_state.is_paused = false
	game_state.is_game_over = false
	game_state.next_entity_id = 0
	game_state.spawn_controller = SpawnController.new(p_stage.stage_number)
	return game_state

## Generate unique entity ID
func generate_entity_id(prefix: String) -> String:
	var id = "%s_%d" % [prefix, next_entity_id]
	next_entity_id += 1
	return id

## Add tank to game state
func add_tank(tank: TankEntity) -> void:
	tanks[tank.id] = tank

## Remove tank from game state
func remove_tank(tank_id: String) -> void:
	tanks.erase(tank_id)

## Get tank by ID
func get_tank(tank_id: String):
	if tanks.has(tank_id):
		return tanks[tank_id]
	return null

## Get all tanks
func get_all_tanks() -> Array:
	var result = []
	for tank_id in tanks:
		result.append(tanks[tank_id])
	return result

## Get player tanks
func get_player_tanks() -> Array:
	var result = []
	for tank_id in tanks:
		var tank = tanks[tank_id]
		if tank.is_player:
			result.append(tank)
	return result

## Get enemy tanks
func get_enemy_tanks() -> Array:
	var result = []
	for tank_id in tanks:
		var tank = tanks[tank_id]
		if not tank.is_player:
			result.append(tank)
	return result

## Add bullet to game state
func add_bullet(bullet: BulletEntity) -> void:
	bullets[bullet.id] = bullet

## Remove bullet from game state
func remove_bullet(bullet_id: String) -> void:
	bullets.erase(bullet_id)

## Get bullet by ID
func get_bullet(bullet_id: String):
	if bullets.has(bullet_id):
		return bullets[bullet_id]
	return null

## Get all bullets
func get_all_bullets() -> Array:
	var result = []
	for bullet_id in bullets:
		result.append(bullets[bullet_id])
	return result

## Check game state invariants
func check_invariants() -> bool:
	# Invariant: Player lives must be >= 0
	if player_lives < 0:
		return false
	
	# Invariant: Score must be >= 0
	if score < 0:
		return false
	
	# Invariant: All tanks must be within stage bounds
	for tank_id in tanks:
		var tank = tanks[tank_id]
		if not stage.is_within_bounds(tank.position):
			return false
	
	# Invariant: All bullets must be within stage bounds
	for bullet_id in bullets:
		var bullet = bullets[bullet_id]
		if not stage.is_within_bounds(bullet.position):
			return false
	
	return true

## Advance game frame
func advance_frame() -> void:
	frame += 1

## Pause game
func pause() -> void:
	is_paused = true

## Unpause game
func unpause() -> void:
	is_paused = false

## End game
func end_game() -> void:
	is_game_over = true

## Check if stage is complete
func is_stage_complete() -> bool:
	return stage.is_complete()

## Check if stage is failed
func is_stage_failed() -> bool:
	return stage.is_failed()

## Serialize to dictionary
func to_dict() -> Dictionary:
	var tanks_array = []
	for tank_id in tanks:
		tanks_array.append(tanks[tank_id].to_dict())
	
	var bullets_array = []
	for bullet_id in bullets:
		bullets_array.append(bullets[bullet_id].to_dict())
	
	return {
		"frame": frame,
		"stage": stage.to_dict(),
		"tanks": tanks_array,
		"bullets": bullets_array,
		"player_lives": player_lives,
		"score": score,
		"is_paused": is_paused,
		"is_game_over": is_game_over,
		"next_entity_id": next_entity_id
	}
