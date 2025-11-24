extends GutTest
## BDD tests for Bullet entity and collision system

var BulletScript = preload("res://src/entities/bullet.gd")
var TankScript = preload("res://src/entities/tank.gd")
var bullet
var tank

func before_each():
	bullet = BulletScript.new()
	bullet.speed = 200.0
	add_child_autofree(bullet)

## Feature: Bullet Movement
class TestBulletMovement:
	extends GutTest
	
	var BulletScript = preload("res://src/entities/bullet.gd")
	var bullet
	
	func before_each():
		bullet = BulletScript.new()
		bullet.speed = 200.0
		add_child_autofree(bullet)
	
	func test_given_bullet_initialized_when_created_then_moves_in_direction():
		# Given: Bullet initialized with direction
		bullet.initialize(Vector2(100, 100), Vector2.UP, 1)
		var start_pos = bullet.global_position
		
		# When: Physics processes
		bullet._physics_process(0.016)  # 1 frame at 60 FPS
		
		# Then: Bullet moves upward
		assert_lt(bullet.global_position.y, start_pos.y, "Bullet should move up")
		assert_eq(bullet.global_position.x, start_pos.x, "X position unchanged")
	
	func test_given_bullet_moving_right_when_processed_then_x_increases():
		# Given: Bullet moving right
		bullet.initialize(Vector2(100, 100), Vector2.RIGHT, 1)
		var start_pos = bullet.global_position
		
		# When: Physics processes
		bullet._physics_process(0.016)
		
		# Then: X increases
		assert_gt(bullet.global_position.x, start_pos.x, "Bullet should move right")
	
	func test_given_bullet_when_out_of_bounds_then_destroys():
		# Given: Bullet near right boundary (832 - 20 = 812)
		bullet.initialize(Vector2(812, 100), Vector2.RIGHT, 1)
		bullet.is_active = true
		
		# When: Physics processes enough frames to go out (20 pixels at speed 200)
		for i in range(2):
			bullet._physics_process(0.1)
		
		# Then: Bullet is destroyed (should be at ~852, which is > 832)
		assert_false(bullet.is_active, "Bullet should be destroyed out of bounds")

## Feature: Bullet Levels
class TestBulletLevels:
	extends GutTest
	
	var BulletScript = preload("res://src/entities/bullet.gd")
	var bullet
	
	func before_each():
		bullet = BulletScript.new()
		add_child_autofree(bullet)
	
	func test_given_normal_bullet_when_created_then_base_stats():
		# Given/When: Normal bullet
		bullet.initialize(Vector2.ZERO, Vector2.UP, 1, 1)  # BulletLevel.NORMAL
		
		# Then: Base stats
		assert_eq(bullet.speed, 200.0, "Normal speed")
		assert_eq(bullet.penetration, 1, "No penetration")
		assert_false(bullet.can_destroy_steel, "Cannot destroy steel")
	
	func test_given_enhanced_bullet_when_created_then_increased_speed():
		# Given/When: Enhanced bullet
		bullet.initialize(Vector2.ZERO, Vector2.UP, 1, 2)  # BulletLevel.ENHANCED
		
		# Then: Enhanced stats
		assert_eq(bullet.speed, 250.0, "Enhanced speed")
		assert_eq(bullet.penetration, 2, "Can penetrate 2 targets")
	
	func test_given_super_bullet_when_created_then_max_stats():
		# Given/When: Super bullet
		bullet.initialize(Vector2.ZERO, Vector2.UP, 1, 3)  # BulletLevel.SUPER
		
		# Then: Max stats
		assert_eq(bullet.speed, 300.0, "Super speed")
		assert_eq(bullet.penetration, 3, "Can penetrate 3 targets")
		assert_true(bullet.can_destroy_steel, "Can destroy steel")

## Feature: Bullet Collision
class TestBulletCollision:
	extends GutTest
	
	var BulletScript = preload("res://src/entities/bullet.gd")
	var TankScript = preload("res://src/entities/tank.gd")
	var bullet
	var tank
	var destroyed_signal_received: bool = false
	
	func before_each():
		destroyed_signal_received = false
		
		bullet = BulletScript.new()
		bullet.speed = 200.0
		add_child_autofree(bullet)
		bullet.destroyed.connect(_on_bullet_destroyed)
		
		tank = TankScript.new()
		tank.tank_type = Tank.TankType.BASIC
		tank.tank_id = 2
		tank.max_health = 1
		add_child_autofree(tank)
		tank.spawn_timer = 0
		tank._complete_spawn()
		tank.invulnerability_timer = 0
		tank._end_invulnerability()
	
	func _on_bullet_destroyed():
		destroyed_signal_received = true
	
	func test_given_bullet_hits_tank_when_colliding_then_tank_takes_damage():
		# Given: Bullet and tank from different owners
		bullet.initialize(tank.global_position, Vector2.UP, 1)
		var initial_health = tank.current_health
		
		# When: Bullet collides with tank
		bullet._on_body_entered(tank)
		
		# Then: Tank takes damage
		assert_lt(tank.current_health, initial_health, "Tank should take damage")
	
	func test_given_bullet_hits_own_tank_when_colliding_then_no_damage():
		# Given: Bullet from same tank
		bullet.initialize(tank.global_position, Vector2.UP, tank.tank_id)
		tank.max_health = 2
		tank.current_health = 2
		
		# When: Bullet collides with own tank
		bullet._on_body_entered(tank)
		
		# Then: No damage
		assert_eq(tank.current_health, 2, "Own tank should not take damage")
	
	func test_given_bullet_hits_tank_when_penetration_limit_then_destroys():
		# Given: Bullet with penetration 1
		bullet.initialize(tank.global_position, Vector2.UP, 1)
		bullet.penetration = 1
		
		# When: Bullet hits one target
		bullet._on_body_entered(tank)
		
		# Then: Bullet is destroyed
		assert_false(bullet.is_active, "Bullet should be destroyed after hitting limit")

## Feature: Bullet Manager
class TestBulletManager:
	extends GutTest
	
	var BulletManagerScript = preload("res://src/managers/bullet_manager.gd")
	var manager
	
	func before_each():
		manager = BulletManagerScript.new()
		add_child(manager)  # Don't use autofree - prevents callback issues
		await wait_physics_frames(1)  # Let _ready() execute
	
	func after_each():
		if is_instance_valid(manager):
			EventBus.unsubscribe("BulletFired", Callable(manager, "_on_bullet_fired"))
			manager.queue_free()
			manager = null
	
	func test_given_manager_when_created_then_pool_initialized():
		# Given/When: Manager created
		
		# Then: Pool has bullets
		assert_gt(manager.bullet_pool.size(), 0, "Pool should have bullets")
	
	func test_given_bullet_fired_event_when_emitted_then_bullet_spawns():
		# Given: Manager with pool and EventBus
		var initial_pool_size = manager.bullet_pool.size()
		
		# When: BulletFired event emitted through EventBus
		var event = BulletFiredEvent.new()
		event.tank_id = 1
		event.position = Vector2(100, 100)
		event.direction = Vector2.UP
		event.bullet_level = 1
		EventBus.emit_game_event(event)
		await wait_physics_frames(1)
		
		# Then: Bullet taken from pool
		assert_lt(manager.bullet_pool.size(), initial_pool_size, "Bullet taken from pool")
		assert_eq(manager.get_bullet_count_for_tank(1), 1, "One active bullet for tank")
	
	func test_given_tank_has_max_bullets_when_fires_then_no_spawn():
		# Given: Tank already has 2 bullets (max)
		for i in range(2):
			var event = BulletFiredEvent.new()
			event.tank_id = 1
			event.position = Vector2(100, 100)
			event.direction = Vector2.UP
			event.bullet_level = 1
			EventBus.emit_game_event(event)
			await wait_physics_frames(1)
		
		var bullet_count = manager.get_bullet_count_for_tank(1)
		
		# When: Try to fire again
		var event = BulletFiredEvent.new()
		event.tank_id = 1
		event.position = Vector2(100, 100)
		event.direction = Vector2.UP
		event.bullet_level = 1
		EventBus.emit_game_event(event)
		await wait_physics_frames(1)
		
		# Then: No new bullet spawned
		assert_eq(manager.get_bullet_count_for_tank(1), bullet_count, "Bullet count should not increase")
	
	func test_given_bullet_destroyed_when_destroyed_then_returned_to_pool():
		# Given: Active bullet spawned through EventBus
		var event = BulletFiredEvent.new()
		event.tank_id = 1
		event.position = Vector2(100, 100)
		event.direction = Vector2.UP
		event.bullet_level = 1
		EventBus.emit_game_event(event)
		await wait_physics_frames(1)
		
		# Check if bullet was actually spawned
		assert_true(manager.active_bullets.has(1), "Tank should have entry in active_bullets")
		assert_gt(manager.active_bullets[1].size(), 0, "Tank should have at least one bullet")
		
		var initial_pool_size = manager.bullet_pool.size()
		var bullet = manager.active_bullets[1][0]
		
		# When: Bullet destroyed
		bullet._destroy()
		await wait_physics_frames(1)
		
		# Then: Returned to pool
		assert_gt(manager.bullet_pool.size(), initial_pool_size, "Bullet returned to pool")
		assert_eq(manager.get_bullet_count_for_tank(1), 0, "No active bullets")
