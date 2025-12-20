extends Node
class_name CollisionHandler3D
## Centralized collision response system for 3D entities
##
## Handles all collision logic consistently across the game:
## - Tank-bullet collisions (damage application)
## - Bullet-wall collisions (terrain destruction)
## - Tank-tank collisions (blocking)
## - Bullet-base collisions (base damage)

signal collision_processed(type: String, data: Dictionary)

enum CollisionType {
	TANK_BULLET,
	BULLET_WALL,
	TANK_TANK,
	BULLET_BASE,
	BULLET_BULLET
}

## Handle tank hit by bullet
func handle_tank_hit(tank: Node3D, bullet: Node3D) -> void:
	if not tank or not bullet:
		return
	
	if not tank.has_method("take_damage"):
		push_warning("Tank does not have take_damage method")
		return
	
	# Get bullet properties
	var owner_type = bullet.get("owner_type")
	var is_player_tank = tank.get("is_player") if "is_player" in tank else false
	var owner_tank_id = bullet.get("owner_tank_id") if "owner_tank_id" in bullet else -1
	var tank_id = tank.get("tank_id") if "tank_id" in tank else -1
	
	# Check grace period (don't hit owner)
	var grace_timer = bullet.get("grace_timer") if "grace_timer" in bullet else 0.0
	if owner_tank_id == tank_id and grace_timer > 0.0:
		return
	
	# Check if should damage (opposing teams only)
	var should_damage = false
	
	# OwnerType: PLAYER=0, ENEMY=1
	if owner_type == 0 and not is_player_tank:  # Player bullet hits enemy
		should_damage = true
	elif owner_type == 1 and is_player_tank:  # Enemy bullet hits player
		should_damage = true
	
	if should_damage:
		# Apply damage
		tank.take_damage(1)
		
		# Register hit on bullet
		if bullet.has_method("_register_hit"):
			bullet._register_hit()
		
		# Emit event
		var data = {
			"tank_id": tank_id,
			"bullet_owner": owner_tank_id,
			"damage": 1
		}
		collision_processed.emit("tank_bullet", data)

## Handle bullet hitting wall/terrain
func handle_bullet_wall_hit(bullet: Node3D, wall: Node3D, hit_position: Vector3) -> void:
	if not bullet or not wall:
		return
	
	# Get wall type (brick/steel)
	var tile_type = wall.get_meta("tile_type", "unknown")
	var can_destroy_steel = bullet.get("can_destroy_steel") if "can_destroy_steel" in bullet else false
	
	# Handle based on wall type
	match tile_type:
		"brick":
			# Brick is always destructible
			_damage_wall(wall, hit_position, false)
			_destroy_bullet(bullet)
		
		"steel":
			if can_destroy_steel:
				# Super bullet destroys steel
				_damage_wall(wall, hit_position, true)
				_destroy_bullet(bullet)
			else:
				# Normal bullets bounce off
				_destroy_bullet(bullet)
		
		_:
			# Unknown wall type - just destroy bullet
			_destroy_bullet(bullet)
	
	var data = {
		"wall_type": tile_type,
		"position": hit_position,
		"destroyed": can_destroy_steel or tile_type == "brick"
	}
	collision_processed.emit("bullet_wall", data)

## Handle tank-tank collision (blocking)
func handle_tank_tank_collision(tank1: Node3D, tank2: Node3D) -> bool:
	if not tank1 or not tank2:
		return false
	
	# Tanks block each other (no pushing)
	# Return true to indicate collision should block movement
	
	var data = {
		"tank1_id": tank1.get("tank_id") if "tank_id" in tank1 else -1,
		"tank2_id": tank2.get("tank_id") if "tank_id" in tank2 else -1,
		"blocked": true
	}
	collision_processed.emit("tank_tank", data)
	
	return true  # Block movement

## Handle bullet hitting base
func handle_bullet_base_hit(bullet: Node3D, base: Node3D) -> void:
	if not bullet or not base:
		return
	
	if not base.has_method("take_damage"):
		return
	
	# Get bullet owner type
	var owner_type = bullet.get("owner_type")
	
	# Only enemy bullets damage base (OwnerType.ENEMY = 1)
	if owner_type == 1:
		base.take_damage(1)
	
	# Destroy bullet regardless
	_destroy_bullet(bullet)
	
	var data = {
		"base_damaged": (owner_type == 1),
		"owner_type": owner_type
	}
	collision_processed.emit("bullet_base", data)

## Handle bullet-bullet collision
func handle_bullet_bullet_collision(bullet1: Node3D, bullet2: Node3D) -> void:
	if not bullet1 or not bullet2:
		return
	
	# Get owner IDs
	var owner1 = bullet1.get("owner_tank_id") if "owner_tank_id" in bullet1 else -1
	var owner2 = bullet2.get("owner_tank_id") if "owner_tank_id" in bullet2 else -1
	
	# Only destroy if from different owners
	if owner1 != owner2:
		_destroy_bullet(bullet1)
		_destroy_bullet(bullet2)
		
		var data = {
			"bullet1_owner": owner1,
			"bullet2_owner": owner2
		}
		collision_processed.emit("bullet_bullet", data)

## Apply damage to destructible wall
func _damage_wall(wall: Node3D, position: Vector3, is_steel: bool) -> void:
	# Check if wall has damage method
	if wall.has_method("damage_tile"):
		wall.damage_tile(position, is_steel)
	elif wall.has_method("take_damage"):
		wall.take_damage(1)
	
	# Future: Emit event for terrain destruction
	# EventBus.emit_game_event(TerrainDamagedEvent.new(...))

## Destroy bullet safely
func _destroy_bullet(bullet: Node3D) -> void:
	if bullet and bullet.has_method("_destroy"):
		bullet._destroy()

## Check if collision should be ignored based on layers
func should_ignore_collision(body1: Node3D, body2: Node3D) -> bool:
	if not body1 or not body2:
		return true
	
	# Check if collision layers/masks allow collision
	var layer1 = body1.get("collision_layer") if "collision_layer" in body1 else 0
	var mask1 = body1.get("collision_mask") if "collision_mask" in body1 else 0
	var layer2 = body2.get("collision_layer") if "collision_layer" in body2 else 0
	var mask2 = body2.get("collision_mask") if "collision_mask" in body2 else 0
	
	# Collision occurs if:
	# - body1's mask includes body2's layer, OR
	# - body2's mask includes body1's layer
	var can_collide = (mask1 & layer2) != 0 or (mask2 & layer1) != 0
	
	return not can_collide

## Get collision type from nodes
func get_collision_type(body1: Node3D, body2: Node3D) -> CollisionType:
	var is_tank1 = body1.has_method("move_in_direction")
	var is_tank2 = body2.has_method("move_in_direction")
	var is_bullet1 = body1.get_script() and "Bullet3D" in str(body1.get_script().get_path())
	var is_bullet2 = body2.get_script() and "Bullet3D" in str(body2.get_script().get_path())
	var is_base1 = body1.get_script() and "Base3D" in str(body1.get_script().get_path())
	var is_base2 = body2.get_script() and "Base3D" in str(body2.get_script().get_path())
	var is_wall1 = body1 is StaticBody3D and body1.collision_layer == 8
	var is_wall2 = body2 is StaticBody3D and body2.collision_layer == 8
	
	if is_tank1 and is_bullet2:
		return CollisionType.TANK_BULLET
	elif is_tank2 and is_bullet1:
		return CollisionType.TANK_BULLET
	elif is_bullet1 and is_wall2:
		return CollisionType.BULLET_WALL
	elif is_bullet2 and is_wall1:
		return CollisionType.BULLET_WALL
	elif is_tank1 and is_tank2:
		return CollisionType.TANK_TANK
	elif is_bullet1 and is_base2:
		return CollisionType.BULLET_BASE
	elif is_bullet2 and is_base1:
		return CollisionType.BULLET_BASE
	elif is_bullet1 and is_bullet2:
		return CollisionType.BULLET_BULLET
	
	return CollisionType.TANK_BULLET  # Default

## Process collision event from physics
func process_collision(body1: Node3D, body2: Node3D) -> void:
	if should_ignore_collision(body1, body2):
		return
	
	var collision_type = get_collision_type(body1, body2)
	
	match collision_type:
		CollisionType.TANK_BULLET:
			if body1.has_method("move_in_direction"):
				handle_tank_hit(body1, body2)
			else:
				handle_tank_hit(body2, body1)
		
		CollisionType.BULLET_WALL:
			if body1.get_script() and "Bullet3D" in str(body1.get_script().get_path()):
				handle_bullet_wall_hit(body1, body2, body1.global_position)
			else:
				handle_bullet_wall_hit(body2, body1, body2.global_position)
		
		CollisionType.TANK_TANK:
			handle_tank_tank_collision(body1, body2)
		
		CollisionType.BULLET_BASE:
			if body1.get_script() and "Bullet3D" in str(body1.get_script().get_path()):
				handle_bullet_base_hit(body1, body2)
			else:
				handle_bullet_base_hit(body2, body1)
		
		CollisionType.BULLET_BULLET:
			handle_bullet_bullet_collision(body1, body2)
