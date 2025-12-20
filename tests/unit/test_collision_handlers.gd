extends GutTest
## Unit tests for CollisionHandler3D system

var handler: CollisionHandler3D
var tank: Tank3D
var bullet: Bullet3D
var base: Base3D
var wall: StaticBody3D

func before_each():
	handler = CollisionHandler3D.new()
	add_child_autofree(handler)
	
	tank = Tank3D.new()
	tank.tank_id = 1
	tank.is_player = true
	add_child_autofree(tank)
	
	bullet = Bullet3D.new()
	add_child_autofree(bullet)
	
	base = Base3D.new()
	add_child_autofree(base)
	
	wall = StaticBody3D.new()
	wall.collision_layer = 8
	wall.set_meta("tile_type", "brick")
	add_child_autofree(wall)
	
	await get_tree().process_frame

func after_each():
	if handler and is_instance_valid(handler):
		handler.queue_free()
	handler = null
	tank = null
	bullet = null
	base = null
	wall = null

# === Damage Application Tests ===

func test_handle_tank_hit_applies_damage():
	bullet.owner_type = Bullet3D.OwnerType.ENEMY
	bullet.owner_tank_id = 2
	bullet.grace_timer = 0.0
	
	var initial_health = tank.current_health
	
	handler.handle_tank_hit(tank, bullet)
	
	assert_lt(tank.current_health, initial_health, "Tank should take damage")

func test_handle_tank_hit_respects_grace_period():
	bullet.owner_type = Bullet3D.OwnerType.PLAYER
	bullet.owner_tank_id = 1  # Same as tank
	bullet.grace_timer = 0.1  # Grace period active
	
	var initial_health = tank.current_health
	
	handler.handle_tank_hit(tank, bullet)
	
	assert_eq(tank.current_health, initial_health, "Should not damage during grace period")

func test_handle_tank_hit_enemy_bullet_damages_player():
	tank.is_player = true
	bullet.owner_type = Bullet3D.OwnerType.ENEMY
	bullet.grace_timer = 0.0
	
	var initial_health = tank.current_health
	
	handler.handle_tank_hit(tank, bullet)
	
	assert_lt(tank.current_health, initial_health, "Enemy bullet should damage player")

func test_handle_tank_hit_player_bullet_damages_enemy():
	tank.is_player = false
	bullet.owner_type = Bullet3D.OwnerType.PLAYER
	bullet.grace_timer = 0.0
	
	var initial_health = tank.current_health
	
	handler.handle_tank_hit(tank, bullet)
	
	assert_lt(tank.current_health, initial_health, "Player bullet should damage enemy")

# === Health Reduction Tests ===

func test_damage_reduces_health_by_one():
	tank.current_health = 3
	bullet.owner_type = Bullet3D.OwnerType.ENEMY
	bullet.grace_timer = 0.0
	
	handler.handle_tank_hit(tank, bullet)
	
	assert_eq(tank.current_health, 2, "Should reduce health by 1")

# === Destruction Signal Tests ===

func test_tank_death_triggers_signal():
	tank.current_health = 1
	bullet.owner_type = Bullet3D.OwnerType.ENEMY
	bullet.grace_timer = 0.0
	
	var died_signaled = false
	tank.died.connect(func(): died_signaled = true)
	
	handler.handle_tank_hit(tank, bullet)
	
	assert_true(died_signaled, "Should emit died signal")

# === Event Emission Tests ===

func test_collision_processed_signal():
	bullet.owner_type = Bullet3D.OwnerType.ENEMY
	bullet.grace_timer = 0.0
	
	var signal_emitted = false
	var event_type = ""
	handler.collision_processed.connect(func(type, data):
		signal_emitted = true
		event_type = type
	)
	
	handler.handle_tank_hit(tank, bullet)
	
	assert_true(signal_emitted, "Should emit collision_processed signal")
	assert_eq(event_type, "tank_bullet", "Event type should be tank_bullet")

# === Bullet-Wall Collision Tests ===

func test_handle_bullet_wall_brick():
	wall.set_meta("tile_type", "brick")
	bullet.is_active = true
	
	handler.handle_bullet_wall_hit(bullet, wall, Vector3.ZERO)
	
	assert_false(bullet.is_active, "Bullet should be destroyed")

func test_handle_bullet_wall_steel_normal_bullet():
	wall.set_meta("tile_type", "steel")
	bullet.is_active = true
	bullet.can_destroy_steel = false
	
	handler.handle_bullet_wall_hit(bullet, wall, Vector3.ZERO)
	
	assert_false(bullet.is_active, "Bullet should be destroyed (bounced off)")

func test_handle_bullet_wall_steel_super_bullet():
	wall.set_meta("tile_type", "steel")
	bullet.is_active = true
	bullet.can_destroy_steel = true
	
	handler.handle_bullet_wall_hit(bullet, wall, Vector3.ZERO)
	
	assert_false(bullet.is_active, "Bullet should be destroyed (after destroying steel)")

# === Tank-Tank Collision Tests ===

func test_handle_tank_tank_collision_blocks():
	var tank2 = Tank3D.new()
	tank2.tank_id = 2
	add_child_autofree(tank2)
	await get_tree().process_frame
	
	var blocked = handler.handle_tank_tank_collision(tank, tank2)
	
	assert_true(blocked, "Should block movement")

# === Bullet-Base Collision Tests ===

func test_handle_bullet_base_enemy_bullet_damages():
	bullet.owner_type = Bullet3D.OwnerType.ENEMY
	bullet.is_active = true
	
	var initial_health = base.health
	
	handler.handle_bullet_base_hit(bullet, base)
	
	assert_lt(base.health, initial_health, "Enemy bullet should damage base")
	assert_false(bullet.is_active, "Bullet should be destroyed")

func test_handle_bullet_base_player_bullet_no_damage():
	bullet.owner_type = Bullet3D.OwnerType.PLAYER
	bullet.is_active = true
	
	var initial_health = base.health
	
	handler.handle_bullet_base_hit(bullet, base)
	
	assert_eq(base.health, initial_health, "Player bullet should not damage base")
	assert_false(bullet.is_active, "Bullet still destroyed")

# === Bullet-Bullet Collision Tests ===

func test_handle_bullet_bullet_different_owners():
	bullet.owner_tank_id = 1
	bullet.is_active = true
	
	var bullet2 = Bullet3D.new()
	bullet2.owner_tank_id = 2
	bullet2.is_active = true
	add_child_autofree(bullet2)
	await get_tree().process_frame
	
	handler.handle_bullet_bullet_collision(bullet, bullet2)
	
	assert_false(bullet.is_active, "First bullet should be destroyed")
	assert_false(bullet2.is_active, "Second bullet should be destroyed")

func test_handle_bullet_bullet_same_owner():
	bullet.owner_tank_id = 1
	bullet.is_active = true
	
	var bullet2 = Bullet3D.new()
	bullet2.owner_tank_id = 1  # Same owner
	bullet2.is_active = true
	add_child_autofree(bullet2)
	await get_tree().process_frame
	
	handler.handle_bullet_bullet_collision(bullet, bullet2)
	
	# Same owner bullets don't destroy each other
	assert_true(bullet.is_active, "First bullet should remain active")
	assert_true(bullet2.is_active, "Second bullet should remain active")

# === Collision Layer Tests ===

func test_should_ignore_collision_incompatible_layers():
	var body1 = StaticBody3D.new()
	body1.collision_layer = 1  # Layer 1
	body1.collision_mask = 2   # Only collides with layer 2
	
	var body2 = StaticBody3D.new()
	body2.collision_layer = 4  # Layer 3
	body2.collision_mask = 8   # Only collides with layer 4
	
	var should_ignore = handler.should_ignore_collision(body1, body2)
	
	assert_true(should_ignore, "Should ignore incompatible layers")
	
	body1.queue_free()
	body2.queue_free()

func test_should_not_ignore_compatible_layers():
	var body1 = StaticBody3D.new()
	body1.collision_layer = 1  # Layer 1
	body1.collision_mask = 2   # Collides with layer 2
	
	var body2 = StaticBody3D.new()
	body2.collision_layer = 2  # Layer 2
	body2.collision_mask = 1   # Collides with layer 1
	
	var should_ignore = handler.should_ignore_collision(body1, body2)
	
	assert_false(should_ignore, "Should not ignore compatible layers")
	
	body1.queue_free()
	body2.queue_free()

# === Collision Type Detection Tests ===

func test_get_collision_type_tank_bullet():
	var collision_type = handler.get_collision_type(tank, bullet)
	
	assert_eq(collision_type, CollisionHandler3D.CollisionType.TANK_BULLET, "Should detect tank-bullet")

func test_get_collision_type_bullet_wall():
	var collision_type = handler.get_collision_type(bullet, wall)
	
	assert_eq(collision_type, CollisionHandler3D.CollisionType.BULLET_WALL, "Should detect bullet-wall")

func test_get_collision_type_bullet_base():
	var collision_type = handler.get_collision_type(bullet, base)
	
	assert_eq(collision_type, CollisionHandler3D.CollisionType.BULLET_BASE, "Should detect bullet-base")

# === Process Collision Tests ===

func test_process_collision_delegates_to_handler():
	bullet.owner_type = Bullet3D.OwnerType.ENEMY
	bullet.grace_timer = 0.0
	
	var signal_received = false
	handler.collision_processed.connect(func(_type, _data): signal_received = true)
	
	handler.process_collision(tank, bullet)
	
	assert_true(signal_received, "Should process and emit signal")

# === Null Safety Tests ===

func test_handle_tank_hit_null_tank():
	# Should not crash
	handler.handle_tank_hit(null, bullet)
	assert_true(true, "Should handle null tank safely")

func test_handle_tank_hit_null_bullet():
	# Should not crash
	handler.handle_tank_hit(tank, null)
	assert_true(true, "Should handle null bullet safely")

func test_handle_bullet_wall_null_bullet():
	# Should not crash
	handler.handle_bullet_wall_hit(null, wall, Vector3.ZERO)
	assert_true(true, "Should handle null bullet safely")
