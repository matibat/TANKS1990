class_name MovementService
extends RefCounted

## MovementService - Domain Service
## Handles movement validation and execution for tanks and bullets
## All methods are static (stateless service)
## Part of DDD architecture - pure domain logic with no Godot dependencies

const CollisionService = preload("res://src/domain/services/collision_service.gd")
const TankEntity = preload("res://src/domain/entities/tank_entity.gd")
const BulletEntity = preload("res://src/domain/entities/bullet_entity.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")
const GameState = preload("res://src/domain/aggregates/game_state.gd")

## Check if tank can move to target position
## Validates: tank is alive, position in bounds, no terrain blocking, no tank blocking
## Uses multi-tile hitbox (4×3 tiles) to check all occupied positions
static func can_tank_move_to(game_state: GameState, tank: TankEntity, target_pos: Position) -> bool:
	# Dead tanks can't move
	if not tank.is_alive():
		return false
	
	# Create a temporary tank at target position with same direction to get the hitbox
	var temp_tank = TankEntity.create(tank.id, tank.tank_type, target_pos, tank.direction)
	var target_hitbox = temp_tank.get_hitbox()
	
	# Check if any tile in the target hitbox is blocked or occupied
	for tile_pos in target_hitbox.get_occupied_tiles():
		# Check if position is blocked by terrain or out of bounds
		if CollisionService.is_position_blocked_for_tank(game_state.stage, tile_pos, tank.id):
			return false
		
		# Check if position is occupied by another tank
		if CollisionService.is_position_occupied_by_tank(game_state, tile_pos, tank.id):
			return false
	
	return true

## Execute tank movement in given direction
## Returns true if tank moved, false if blocked
## Updates tank position and direction
static func execute_tank_movement(game_state: GameState, tank: TankEntity, direction: Direction) -> bool:
	# Update tank direction
	tank.direction = direction
	
	# Calculate target position
	var delta = direction.to_position_delta()
	var target_pos = tank.position.add(delta)
	
	# Check if tank can move to target
	if not can_tank_move_to(game_state, tank, target_pos):
		tank.is_moving = false
		return false
	
	# Move tank
	tank.position = target_pos
	tank.is_moving = true
	return true

## Execute bullet movement
## Moves bullet forward by its velocity
## Deactivates bullet if it goes out of bounds
static func execute_bullet_movement(game_state: GameState, bullet: BulletEntity) -> void:
	# Inactive bullets don't move
	if not bullet.is_active:
		return
	
	# Move bullet forward
	bullet.move_forward()
	
	# Check if bullet is out of bounds
	if not game_state.stage.is_within_bounds(bullet.position):
		bullet.deactivate()

## Update all bullets in game state
## Moves all active bullets forward
static func update_all_bullets(game_state: GameState) -> void:
	for bullet_id in game_state.bullets:
		var bullet = game_state.bullets[bullet_id]
		execute_bullet_movement(game_state, bullet)
