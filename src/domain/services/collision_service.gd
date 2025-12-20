class_name CollisionService
extends RefCounted

## CollisionService - Domain Service
## Handles all collision detection logic in the game
## All methods are static (stateless service)
## Part of DDD architecture - pure domain logic with no Godot dependencies

const TankEntity = preload("res://src/domain/entities/tank_entity.gd")
const BulletEntity = preload("res://src/domain/entities/bullet_entity.gd")
const TerrainCell = preload("res://src/domain/entities/terrain_cell.gd")
const BaseEntity = preload("res://src/domain/entities/base_entity.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const StageState = preload("res://src/domain/aggregates/stage_state.gd")
const GameState = preload("res://src/domain/aggregates/game_state.gd")

## Check if tank and bullet collide
## Returns false if tank owns the bullet (can't hit own bullets)
## Returns false if tank is dead or bullet is inactive
static func check_tank_bullet_collision(tank: TankEntity, bullet: BulletEntity) -> bool:
	# Dead tanks don't collide
	if not tank.is_alive():
		return false
	
	# Inactive bullets don't collide
	if not bullet.is_active:
		return false
	
	# Tank can't collide with own bullet
	if tank.id == bullet.owner_id:
		return false
	
	# Check position overlap
	return tank.position.equals(bullet.position)

## Check if tank and terrain collide
## Returns true if tank is at position with impassable terrain
static func check_tank_terrain_collision(tank: TankEntity, terrain_cell: TerrainCell) -> bool:
	# Check if positions match
	if not tank.position.equals(terrain_cell.position):
		return false
	
	# Check if terrain is passable for tank
	return not terrain_cell.is_passable_for_tank()

## Check if bullet and terrain collide
## Returns true if bullet is at position with impassable terrain for bullets
static func check_bullet_terrain_collision(bullet: BulletEntity, terrain_cell: TerrainCell) -> bool:
	# Check if positions match
	if not bullet.position.equals(terrain_cell.position):
		return false
	
	# Check if terrain is passable for bullet
	return not terrain_cell.is_passable_for_bullet()

## Check if two tanks collide
## Returns false if either tank is dead
static func check_tank_tank_collision(tank1: TankEntity, tank2: TankEntity) -> bool:
	# Dead tanks don't collide
	if not tank1.is_alive() or not tank2.is_alive():
		return false
	
	# Check position overlap
	return tank1.position.equals(tank2.position)

## Check if bullet and base collide
## Returns false if bullet is inactive or base is destroyed
static func check_bullet_base_collision(bullet: BulletEntity, base: BaseEntity) -> bool:
	# Inactive bullets don't collide
	if not bullet.is_active:
		return false
	
	# Destroyed base doesn't collide
	if not base.is_alive():
		return false
	
	# Check position overlap
	return bullet.position.equals(base.position)

## Find terrain cell at given position in stage
## Returns null if no terrain at position
static func find_terrain_at_position(stage: StageState, pos: Position):
	return stage.get_terrain_at(pos)

## Check if position is blocked for tank movement
## Considers out of bounds and impassable terrain
## ignore_tank_id allows checking future position of moving tank
static func is_position_blocked_for_tank(stage: StageState, pos: Position, ignore_tank_id) -> bool:
	# Out of bounds is blocked
	if not stage.is_within_bounds(pos):
		return true
	
	# Check terrain at position
	var terrain = find_terrain_at_position(stage, pos)
	if terrain != null:
		# If terrain is not passable, position is blocked
		if not terrain.is_passable_for_tank():
			return true
	
	return false

## Check if position is occupied by a tank
## ignore_tank_id allows checking if tank can stay at its current position
## Dead tanks don't occupy positions
static func is_position_occupied_by_tank(game_state: GameState, pos: Position, ignore_tank_id) -> bool:
	for tank_id in game_state.tanks:
		# Skip ignored tank
		if ignore_tank_id != null and tank_id == ignore_tank_id:
			continue
		
		var tank = game_state.tanks[tank_id]
		
		# Dead tanks don't occupy
		if not tank.is_alive():
			continue
		
		# Check if tank is at position
		if tank.position.equals(pos):
			return true
	
	return false

## Check if two bullets collide (Phase 2.3)
## Bullets from same owner don't collide
## Inactive bullets don't collide
## Collision radius: 4 pixels per bullet (total 8 pixels)
static func check_bullet_to_bullet_collision(b1: BulletEntity, b2: BulletEntity) -> bool:
	# Inactive bullets don't collide
	if not b1.is_active or not b2.is_active:
		return false
	
	# Bullets from same owner don't collide
	if b1.owner_id == b2.owner_id:
		return false
	
	# Calculate distance between bullets
	var dx = b2.position.x - b1.position.x
	var dy = b2.position.y - b1.position.y
	var distance = sqrt(dx * dx + dy * dy)
	
	# Collision if distance <= 8 pixels (4 + 4 radius)
	const BULLET_RADIUS = 4
	const COLLISION_DISTANCE = BULLET_RADIUS * 2
	
	return distance <= COLLISION_DISTANCE
