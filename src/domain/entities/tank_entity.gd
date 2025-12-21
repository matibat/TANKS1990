class_name TankEntity
extends RefCounted

## TankEntity - Domain Entity
## Represents a tank in the game with identity, state, and behavior
## Part of DDD architecture - pure domain logic with no Godot dependencies

const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")
const Health = preload("res://src/domain/value_objects/health.gd")
const TankStats = preload("res://src/domain/value_objects/tank_stats.gd")

## Tank type enum
enum Type {
	PLAYER = 0,
	ENEMY_BASIC = 1,
	ENEMY_FAST = 2,
	ENEMY_POWER = 3,
	ENEMY_ARMORED = 4
}

## Identity
var id: String

## Properties
var tank_type: int
var position: Position
var direction: Direction
var health: Health
var stats: TankStats
var cooldown_frames: int
var invulnerability_frames: int
var is_moving: bool
var is_player: bool

## Static factory method to create a tank
static func create(p_id: String, p_tank_type: int, p_position: Position, p_direction: Direction):
	var tank = new()
	tank.id = p_id
	tank.tank_type = p_tank_type
	tank.position = p_position
	tank.direction = p_direction
	tank.cooldown_frames = 0
	tank.invulnerability_frames = 0
	tank.is_moving = false
	
	# Determine if player tank
	tank.is_player = (p_tank_type == Type.PLAYER)
	
	# Assign stats based on tank type
	match p_tank_type:
		Type.PLAYER:
			tank.stats = TankStats.player_default()
		Type.ENEMY_BASIC:
			tank.stats = TankStats.enemy_basic()
		Type.ENEMY_FAST:
			tank.stats = TankStats.enemy_fast()
		Type.ENEMY_POWER:
			tank.stats = TankStats.enemy_power()
		Type.ENEMY_ARMORED:
			tank.stats = TankStats.enemy_armored()
		_:
			push_error("Invalid tank type: %d" % p_tank_type)
			tank.stats = TankStats.player_default()
	
	# Initialize health based on armor stat
	tank.health = Health.full(tank.stats.armor)
	
	return tank

## Check if tank is alive
func is_alive() -> bool:
	return health.is_alive()

## Check if tank can shoot (no cooldown)
func can_shoot() -> bool:
	return cooldown_frames == 0

## Alias for can_shoot (different terminology)
func can_fire() -> bool:
	return can_shoot()

## Check if tank can move (is alive)
func can_move() -> bool:
	return is_alive()

## Check if tank is invulnerable (spawn protection)
func is_invulnerable() -> bool:
	return invulnerability_frames > 0

## Set invulnerability frames (typically on spawn)
func set_invulnerable(frames: int) -> void:
	invulnerability_frames = frames

## Take damage
func take_damage(amount: int) -> void:
	health = health.take_damage(amount)

## Rotate tank to new direction
func rotate_to(new_direction: Direction) -> void:
	direction = new_direction

## Start shooting cooldown
func start_cooldown() -> void:
	cooldown_frames = stats.fire_rate

## Fire weapon (alias for start_cooldown for clarity)
func fire() -> void:
	start_cooldown()

## Update cooldown (decrease by 1 per frame)
func update_cooldown() -> void:
	if cooldown_frames > 0:
		cooldown_frames -= 1
	if invulnerability_frames > 0:
		invulnerability_frames -= 1

## Get next position based on current direction and speed
func get_next_position() -> Position:
	var delta = direction.to_position_delta()
	return position.add(delta)

## Move tank to new position
func move_to(new_position: Position) -> void:
	position = new_position
	is_moving = true

## Stop tank movement
func stop_moving() -> void:
	is_moving = false

## Serialize to dictionary
func to_dict() -> Dictionary:
	return {
		"id": id,
		"tank_type": tank_type,
		"position": position.to_dict(),
		"direction": direction.value,
		"health_current": health.current,
		"health_maximum": health.maximum,
		"cooldown_frames": cooldown_frames,
		"is_moving": is_moving,
		"is_player": is_player
	}

## Deserialize from dictionary
static func from_dict(dict: Dictionary):
	var tank = new()
	tank.id = dict["id"]
	tank.tank_type = dict["tank_type"]
	tank.position = Position.from_dict(dict["position"])
	tank.direction = Direction.create(dict["direction"])
	tank.health = Health.create(dict["health_current"], dict["health_maximum"])
	tank.cooldown_frames = dict["cooldown_frames"]
	tank.is_moving = dict["is_moving"]
	tank.is_player = dict["is_player"]
	
	# Restore stats based on tank type
	match tank.tank_type:
		Type.PLAYER:
			tank.stats = TankStats.player_default()
		Type.ENEMY_BASIC:
			tank.stats = TankStats.enemy_basic()
		Type.ENEMY_FAST:
			tank.stats = TankStats.enemy_fast()
		Type.ENEMY_POWER:
			tank.stats = TankStats.enemy_power()
		Type.ENEMY_ARMORED:
			tank.stats = TankStats.enemy_armored()
		_:
			tank.stats = TankStats.player_default()
	
	return tank

## String representation for debugging
func _to_string() -> String:
	return "TankEntity(%s, type:%d, pos:%s, dir:%d, hp:%d/%d)" % [
		id, tank_type, position, direction.value, health.current, health.maximum
	]
