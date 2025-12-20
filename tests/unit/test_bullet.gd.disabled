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
	var TankScript = preload("res://src/entities/tank.gd")
	var bullet
	
	var tank_destroyed_received = false
	var bullet_destroyed_received = false
	
	func before_each():
		bullet = BulletScript.new()
		bullet.speed = 200.0
		add_child_autofree(bullet)
	
	func _on_test_tank_died():
		tank_destroyed_received = true
	
	func _on_test_bullet_destroyed():
		bullet_destroyed_received = true
	
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

	func test_given_enemy_tank_moving_forward_when_shoots_then_bullet_moves_independently():
		# Given: Enemy tank moving forward (down) and shooting through EventBus
		var enemy_tank = TankScript.new()
		enemy_tank.tank_type = TankScript.TankType.BASIC
		enemy_tank.is_player = false
		enemy_tank.global_position = Vector2(200, 200)
		enemy_tank.facing_direction = TankScript.Direction.DOWN
		add_child_autofree(enemy_tank)
		enemy_tank.spawn_timer = 0
		enemy_tank._complete_spawn()
		enemy_tank.invulnerability_timer = 0
		enemy_tank._end_invulnerability()
		
		# Start tank moving forward
		enemy_tank.move_in_direction(TankScript.Direction.DOWN)
		enemy_tank._physics_process(1.0/60.0)  # Process one frame
		
		# Set up BulletManager to listen for events
		var bullet_manager = load("res://src/managers/bullet_manager.gd").new()
		add_child_autofree(bullet_manager)
		await wait_physics_frames(1)  # Let it initialize
		
		# When: Tank fires (this emits BulletFiredEvent)
		enemy_tank.try_fire()
		# Event should be processed synchronously
		
		# Then: Bullet should be spawned and moving
		var active_bullets = bullet_manager.get_bullet_count_for_tank(enemy_tank.tank_id)
		assert_eq(active_bullets, 1, "One bullet should be active for the tank")
		
		# Get the actual bullet instance
		var bullet = bullet_manager.active_bullets[enemy_tank.tank_id][0]
		assert_not_null(bullet, "Bullet should exist")
		assert_true(bullet.is_active, "Bullet should be active")
		assert_true(bullet.visible, "Bullet should be visible")
		
		# Check initial position (should be at spawn position)
		var expected_spawn_pos = enemy_tank.get_bullet_spawn_position()
		assert_almost_eq(bullet.global_position.x, expected_spawn_pos.x, 1, "Bullet should spawn at correct X position")
		assert_almost_eq(bullet.global_position.y, expected_spawn_pos.y, 1, "Bullet should spawn at correct Y position")
		
		# Check direction (should match tank's facing direction)
		var expected_direction = enemy_tank._direction_to_vector(enemy_tank.facing_direction)
		assert_eq(bullet.direction, expected_direction, "Bullet should move in tank's facing direction")
		
		# Check speed is set correctly (normal bullet = 200)
		assert_eq(bullet.speed, 200.0, "Bullet should have normal speed")
		
		# Process bullet movement
		var initial_pos = bullet.global_position
		bullet._physics_process(0.1)  # Simulate movement
		
		# Bullet should have moved down (positive Y direction)
		assert_gt(bullet.global_position.y, initial_pos.y, "Bullet should move downward")
		assert_eq(bullet.global_position.x, initial_pos.x, "Bullet X position should remain unchanged")
		assert_true(bullet.is_active, "Bullet should remain active after moving")

	func test_given_player_tank_shooting_before_moving_when_bullet_moves_then_no_collision_with_shooter():
		# Given: Player tank at position, shooting first then moving
		var player_tank = TankScript.new()
		player_tank.tank_type = TankScript.TankType.BASIC
		player_tank.is_player = true
		player_tank.global_position = Vector2(200, 200)
		player_tank.facing_direction = TankScript.Direction.DOWN
		add_child_autofree(player_tank)
		player_tank.spawn_timer = 0
		player_tank._complete_spawn()
		player_tank.invulnerability_timer = 0
		player_tank._end_invulnerability()
		
		# Set up BulletManager
		var bullet_manager = load("res://src/managers/bullet_manager.gd").new()
		add_child_autofree(bullet_manager)
		await wait_physics_frames(1)
		
		# When: Tank fires first
		player_tank.try_fire()
		
		# Then move tank (shooting before moving)
		player_tank.move_in_direction(TankScript.Direction.DOWN)
		player_tank._physics_process(1.0/60.0)
		
		# Then: Bullet should exist and be moving
		var active_bullets = bullet_manager.get_bullet_count_for_tank(player_tank.tank_id)
		assert_eq(active_bullets, 1, "One bullet should be active for the tank")
		
		var bullet = bullet_manager.active_bullets[player_tank.tank_id][0]
		assert_true(bullet.is_active, "Bullet should remain active")
		
		# Bullet should be moving independently
		var initial_pos = bullet.global_position
		bullet._physics_process(0.1)
		assert_gt(bullet.global_position.y, initial_pos.y, "Bullet should move downward")

	func test_given_player_tank_shooting_and_moving_simultaneously_when_bullet_moves_then_no_collision_with_shooter():
		# Given: Player tank at position
		var player_tank = TankScript.new()
		player_tank.tank_type = TankScript.TankType.BASIC
		player_tank.is_player = true
		player_tank.global_position = Vector2(200, 200)
		player_tank.facing_direction = TankScript.Direction.DOWN
		add_child_autofree(player_tank)
		player_tank.spawn_timer = 0
		player_tank._complete_spawn()
		player_tank.invulnerability_timer = 0
		player_tank._end_invulnerability()
		
		# Set up BulletManager
		var bullet_manager = load("res://src/managers/bullet_manager.gd").new()
		add_child_autofree(bullet_manager)
		await wait_physics_frames(1)
		
		# When: Tank fires and moves simultaneously
		player_tank.try_fire()
		player_tank.move_in_direction(TankScript.Direction.DOWN)
		player_tank._physics_process(1.0/60.0)
		
		# Then: Bullet should exist and be moving
		var active_bullets = bullet_manager.get_bullet_count_for_tank(player_tank.tank_id)
		assert_eq(active_bullets, 1, "One bullet should be active for the tank")
		
		var bullet = bullet_manager.active_bullets[player_tank.tank_id][0]
		assert_true(bullet.is_active, "Bullet should remain active")
		
		# Bullet should be moving independently
		var initial_pos = bullet.global_position
		bullet._physics_process(0.1)
		assert_gt(bullet.global_position.y, initial_pos.y, "Bullet should move downward")

	func test_given_player_tank_moving_then_shooting_with_epsilon_when_bullet_moves_then_collides_with_shooter_but_survives():
		# Given: Player tank at position, moving first then shooting with small epsilon
		var player_tank = TankScript.new()
		player_tank.tank_type = TankScript.TankType.BASIC
		player_tank.is_player = true
		player_tank.global_position = Vector2(200, 200)
		player_tank.facing_direction = TankScript.Direction.DOWN
		add_child_autofree(player_tank)
		player_tank.spawn_timer = 0
		player_tank._complete_spawn()
		player_tank.invulnerability_timer = 0
		player_tank._end_invulnerability()
		
		# Set up BulletManager
		var bullet_manager = load("res://src/managers/bullet_manager.gd").new()
		add_child_autofree(bullet_manager)
		await wait_physics_frames(1)
		
		# When: Tank moves first
		player_tank.move_in_direction(TankScript.Direction.DOWN)
		player_tank._physics_process(1.0/60.0)  # Move slightly
		
		# Small epsilon delay before shooting
		await wait_physics_frames(1)
		
		# Then shoot
		player_tank.try_fire()
		
		# Then: Bullet should exist
		var active_bullets = bullet_manager.get_bullet_count_for_tank(player_tank.tank_id)
		assert_eq(active_bullets, 1, "One bullet should be active for the tank")
		
		var bullet = bullet_manager.active_bullets[player_tank.tank_id][0]
		assert_true(bullet.is_active, "Bullet should be active initially")
		
		# Move bullet and check if it collides with shooter but survives due to grace period
		var initial_pos = bullet.global_position
		var initial_active = bullet.is_active
		
		# Process several frames to see if bullet collides with tank
		for i in range(10):
			bullet._physics_process(0.1)
			# Manually check collision with tank during movement
			if bullet.global_position.distance_to(player_tank.global_position) < 16:  # Tank collision radius
				bullet._on_body_entered(player_tank)
				break
		
		# Bullet should still be active (grace period prevents destruction)
		assert_true(bullet.is_active, "Bullet should survive collision with shooter due to grace period")
		
		# But it should have moved
		assert_gt(bullet.global_position.y, initial_pos.y, "Bullet should have moved downward")

	func test_given_player_tank_shoots_then_moves_backward_when_bullet_collides_with_shooter_then_survives():
		# Given: Player tank shoots forward, then moves backward toward the bullet
		var player_tank = TankScript.new()
		player_tank.tank_type = TankScript.TankType.BASIC
		player_tank.is_player = true
		player_tank.global_position = Vector2(200, 200)
		player_tank.facing_direction = TankScript.Direction.DOWN
		add_child_autofree(player_tank)
		player_tank.spawn_timer = 0
		player_tank._complete_spawn()
		player_tank.invulnerability_timer = 0
		player_tank._end_invulnerability()
		
		# Set up BulletManager
		var bullet_manager = load("res://src/managers/bullet_manager.gd").new()
		add_child_autofree(bullet_manager)
		await wait_physics_frames(1)
		
		# When: Tank shoots forward
		player_tank.try_fire()
		
		# Then immediately move backward (UP) toward the bullet
		player_tank.move_in_direction(TankScript.Direction.UP)
		
		# Then: Bullet should exist and be moving downward
		var active_bullets = bullet_manager.get_bullet_count_for_tank(player_tank.tank_id)
		assert_eq(active_bullets, 1, "One bullet should be active for the tank")
		
		var bullet = bullet_manager.active_bullets[player_tank.tank_id][0]
		assert_true(bullet.is_active, "Bullet should be active initially")
		
		var bullet_start_pos = bullet.global_position
		
		# Move both tank and bullet for several frames
		for i in range(15):  # Enough frames for tank to move toward bullet
			player_tank._physics_process(1.0/60.0)  # Tank moves up (backward)
			bullet._physics_process(1.0/60.0)     # Bullet moves down
			
			# Check for collision
			if bullet.global_position.distance_to(player_tank.global_position) < 16:
				# Bullet collides with shooter
				bullet._on_body_entered(player_tank)
				break
		
		# Bullet should still be active (grace period prevents destruction)
		assert_true(bullet.is_active, "Bullet should survive collision with shooter due to grace period")
		
		# Bullet should have moved from its starting position
		assert_gt(bullet.global_position.y, bullet_start_pos.y, "Bullet should have moved downward")
		
		# Tank should have moved upward (backward)
		assert_lt(player_tank.global_position.y, 200, "Tank should have moved upward")

	func test_given_bullet_fired_when_tank_moves_into_stationary_bullet_then_survives_collision():
		# Given: Player tank shoots, bullet becomes stationary, tank moves into it
		var player_tank = TankScript.new()
		player_tank.tank_type = TankScript.TankType.BASIC
		player_tank.is_player = true
		player_tank.global_position = Vector2(200, 200)
		player_tank.facing_direction = TankScript.Direction.DOWN
		add_child_autofree(player_tank)
		player_tank.spawn_timer = 0
		player_tank._complete_spawn()
		player_tank.invulnerability_timer = 0
		player_tank._end_invulnerability()
		
		# Set up BulletManager
		var bullet_manager = load("res://src/managers/bullet_manager.gd").new()
		add_child_autofree(bullet_manager)
		await wait_physics_frames(1)
		
		# When: Tank shoots forward
		player_tank.try_fire()
		
		# Get the bullet and make it stationary
		var bullet = bullet_manager.active_bullets[player_tank.tank_id][0]
		bullet.direction = Vector2.ZERO  # Make bullet stationary
		var bullet_pos = bullet.global_position
		
		# Move tank toward the stationary bullet
		player_tank.move_in_direction(TankScript.Direction.DOWN)
		
		# Process frames until collision
		for i in range(20):  # Enough frames for tank to reach bullet
			player_tank._physics_process(1.0/60.0)
			
			# Check for collision
			if player_tank.global_position.distance_to(bullet_pos) < 16:
				# Tank collides with bullet
				bullet._on_body_entered(player_tank)
				break
		
		# Bullet should still be active (grace period prevents destruction)
		assert_true(bullet.is_active, "Bullet should survive collision with shooter due to grace period")
		
		# Bullet should remain at its position
		assert_almost_eq(bullet.global_position.x, bullet_pos.x, 1, "Bullet X position should remain unchanged")
		assert_almost_eq(bullet.global_position.y, bullet_pos.y, 1, "Bullet Y position should remain unchanged")
		
		# Tank should have moved toward the bullet
		assert_gt(player_tank.global_position.y, 200, "Tank should have moved downward toward bullet")

	func test_given_bullet_and_tank_when_collision_occurs_then_observe_events():
		# Given: Bullet and tank positioned for collision
		var player_tank = TankScript.new()
		player_tank.tank_type = TankScript.TankType.BASIC
		player_tank.is_player = false  # Make it enemy tank
		player_tank.tank_id = 2
		player_tank.global_position = Vector2(200, 200)
		player_tank.facing_direction = TankScript.Direction.DOWN
		add_child_autofree(player_tank)
		player_tank.spawn_timer = 0
		player_tank._complete_spawn()
		player_tank.invulnerability_timer = 0
		player_tank._end_invulnerability()
		player_tank.current_state = TankScript.State.IDLE  # Ensure state is IDLE
		
		var bullet = BulletScript.new()
		bullet.speed = 200.0
		bullet.initialize(Vector2(200, 216), Vector2.DOWN, 1, Bullet.BulletLevel.NORMAL, true)  # Player bullet
		add_child_autofree(bullet)
		bullet.is_active = true  # Activate the bullet after adding to scene
		
		tank_destroyed_received = false
		bullet_destroyed_received = false
		
		# Connect to signals
		player_tank.died.connect(_on_test_tank_died)
		bullet.destroyed.connect(_on_test_bullet_destroyed)
		
		# When: Bullet collides with tank
		bullet._on_body_entered(player_tank)
		
		# Then: Observe that events/signals are emitted correctly
		# Bullet should be destroyed (different owner)
		assert_true(bullet_destroyed_received, "Bullet destroyed signal should be emitted")
		assert_false(bullet.is_active, "Bullet should be inactive after collision")
		
		# Tank should take damage but not be destroyed (has 1 health)
		assert_eq(player_tank.current_health, 0, "Tank should have 0 health")
		assert_true(tank_destroyed_received, "Tank died signal should be emitted")

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
		bullet.initialize(tank.global_position, Vector2.UP, 1, Bullet.BulletLevel.NORMAL, true)  # Player bullet
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
	
	func test_given_bullet_hits_own_tank_during_grace_period_when_colliding_then_no_damage():
		# Given: Bullet from same tank with grace period active
		bullet.initialize(tank.global_position, Vector2.UP, tank.tank_id)
		bullet.grace_timer = 0.05  # Grace period still active
		tank.max_health = 2
		tank.current_health = 2
		
		# When: Bullet collides with own tank during grace period
		bullet._on_body_entered(tank)
		
		# Then: No damage (grace period prevents self-hit)
		assert_eq(tank.current_health, 2, "Own tank should not take damage during grace period")
		assert_true(bullet.is_active, "Bullet should remain active during grace period")
	
	func test_given_bullet_hits_tank_when_penetration_limit_then_destroys():
		# Given: Bullet with penetration 1
		bullet.initialize(tank.global_position, Vector2.UP, 1, Bullet.BulletLevel.NORMAL, true)  # Player bullet
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
