class_name SpawningService
extends RefCounted

## SpawningService - Domain Service
## Handles entity creation and cleanup in the game
## All methods are static (stateless service)
## Part of DDD architecture - pure domain logic with no Godot dependencies

const TankEntity = preload("res://src/domain/entities/tank_entity.gd")
const BulletEntity = preload("res://src/domain/entities/bullet_entity.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")
const GameState = preload("res://src/domain/aggregates/game_state.gd")

## Spawn a player tank at given spawn index
## Returns newly created TankEntity
static func spawn_player_tank(game_state: GameState, spawn_index: int) -> TankEntity:
	# Get spawn position
	var spawn_pos = game_state.stage.player_spawn_positions[spawn_index]
	
	# Generate unique tank ID
	var tank_id = game_state.generate_entity_id("player")
	
	# Create player tank facing UP by default
	var tank = TankEntity.create(tank_id, TankEntity.Type.PLAYER, spawn_pos, Direction.create(Direction.UP))
	
	# Set spawn invulnerability (3 seconds at 60 FPS)
	tank.set_invulnerable(180)
	
	return tank

## Spawn an enemy tank at given spawn index
## Decrements enemies_remaining and increments enemies_on_field
## Returns newly created TankEntity
static func spawn_enemy_tank(game_state: GameState, enemy_type: int, spawn_index: int) -> TankEntity:
	# Get spawn position
	var spawn_pos = game_state.stage.enemy_spawn_positions[spawn_index]
	
	# Generate unique tank ID
	var tank_id = game_state.generate_entity_id("enemy")
	
	# Create enemy tank facing DOWN by default
	var tank = TankEntity.create(tank_id, enemy_type, spawn_pos, Direction.create(Direction.DOWN))
	
	# Set spawn invulnerability (3 seconds at 60 FPS)
	tank.set_invulnerable(180)
	
	# Update stage enemy counts
	game_state.stage.enemies_remaining -= 1
	game_state.stage.enemies_on_field += 1
	
	return tank

## Spawn a bullet from tank
## Bullet spawns one tile in front of tank in its facing direction
## Sets tank cooldown after spawning
## Returns newly created BulletEntity
static func spawn_bullet(game_state: GameState, tank: TankEntity) -> BulletEntity:
	# Calculate spawn position (one tile in front of tank)
	var delta = tank.direction.to_position_delta()
	var bullet_pos = tank.position.add(delta)
	
	# Generate unique bullet ID
	var bullet_id = game_state.generate_entity_id("bullet")
	
	# Create bullet with tank's stats
	var bullet = BulletEntity.create(
		bullet_id,
		tank.id,
		bullet_pos,
		tank.direction,
		tank.stats.bullet_speed,
		1 # Default damage
	)
	
	# Start tank cooldown
	tank.start_cooldown()
	
	# Add bullet to game state
	game_state.add_bullet(bullet)
	
	return bullet

## Remove all destroyed entities from game state
## Removes dead tanks and inactive bullets
## Decrements enemies_on_field for removed enemy tanks
static func remove_destroyed_entities(game_state: GameState) -> void:
	# Remove dead tanks
	var tanks_to_remove = []
	for tank_id in game_state.tanks:
		var tank = game_state.tanks[tank_id]
		if not tank.is_alive():
			tanks_to_remove.append(tank_id)
			# Decrement enemies on field if enemy tank
			if not tank.is_player:
				game_state.stage.enemies_on_field -= 1
	
	for tank_id in tanks_to_remove:
		game_state.remove_tank(tank_id)
	
	# Remove inactive bullets
	var bullets_to_remove = []
	for bullet_id in game_state.bullets:
		var bullet = game_state.bullets[bullet_id]
		if not bullet.is_active:
			bullets_to_remove.append(bullet_id)
	
	for bullet_id in bullets_to_remove:
		game_state.remove_bullet(bullet_id)
