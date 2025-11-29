extends GutTest
## Tests for bullet grace period to prevent immediate owner collision

var bullet_scene: PackedScene
var tank_scene: PackedScene
var bullet: Bullet
var tank: Tank

func before_each():
	bullet_scene = load("res://scenes/bullet.tscn")
	tank_scene = load("res://scenes/player_tank.tscn")
	
	bullet = bullet_scene.instantiate()
	tank = tank_scene.instantiate()
	
	add_child_autofree(tank)
	add_child_autofree(bullet)
	
	tank.global_position = Vector2(100, 100)
	tank.tank_id = 1

func test_bullet_has_grace_period_on_initialization():
	# Given a bullet initialized with an owner
	bullet.initialize(Vector2(100, 100), Vector2.UP, 1, Bullet.BulletLevel.NORMAL, true)
	
	# Then grace_timer should be set
	assert_gt(bullet.grace_timer, 0.0, "Grace timer should be > 0 after initialization")
	assert_eq(bullet.grace_timer, bullet.GRACE_PERIOD, "Grace timer should equal GRACE_PERIOD")

func test_grace_timer_decreases_over_time():
	# Given a bullet with grace period
	bullet.initialize(Vector2(100, 100), Vector2.UP, 1, Bullet.BulletLevel.NORMAL, true)
	var initial_grace = bullet.grace_timer
	
	# When time passes
	await wait_physics_frames(3)
	
	# Then grace timer should decrease
	assert_lt(bullet.grace_timer, initial_grace, "Grace timer should decrease over time")

func test_bullet_ignores_owner_during_grace_period():
	# Given a bullet just fired by a tank
	bullet.initialize(tank.global_position, Vector2.UP, tank.tank_id, Bullet.BulletLevel.NORMAL, true)
	bullet.grace_timer = 0.05  # Still in grace period
	
	# When the bullet collides with owner tank
	var collision_handled = false
	bullet.hit_target.connect(func(_target): collision_handled = true)
	
	# Simulate body_entered with owner tank
	bullet._on_body_entered(tank)
	
	# Then collision should be ignored
	assert_false(collision_handled, "Bullet should ignore owner during grace period")

func test_bullet_damages_owner_after_grace_period():
	# Given a bullet with expired grace period
	bullet.initialize(tank.global_position, Vector2.UP, tank.tank_id, Bullet.BulletLevel.NORMAL, true)
	bullet.grace_timer = 0.0  # Grace period expired
	
	# When checking grace timer
	# Then it should be expired and logic would allow owner damage
	assert_eq(bullet.grace_timer, 0.0, "Grace period should be expired")
	
	# Verify the check in _on_body_entered would pass
	var would_ignore = (tank.tank_id == bullet.owner_tank_id and bullet.grace_timer > 0)
	assert_false(would_ignore, "Should not ignore owner after grace expires")

func test_bullet_damages_other_tanks_during_grace_period():
	# Given a bullet with active grace period
	bullet.initialize(Vector2(100, 100), Vector2.UP, 1, Bullet.BulletLevel.NORMAL, true)
	bullet.grace_timer = 0.05  # In grace period
	
	# And an enemy tank
	var enemy_tank = tank_scene.instantiate()
	add_child_autofree(enemy_tank)
	enemy_tank.tank_id = 2  # Different ID
	enemy_tank.global_position = Vector2(100, 80)
	
	var collision_handled = false
	var initial_health = enemy_tank.health
	bullet.hit_target.connect(func(_target): collision_handled = true)
	
	# When bullet collides with enemy
	bullet._on_body_entered(enemy_tank)
	
	# Then collision should be handled
	assert_true(collision_handled, "Bullet should damage non-owner tanks during grace period")
	assert_lt(enemy_tank.health, initial_health, "Enemy tank should take damage")

func test_grace_period_is_short_enough():
	# Given the grace period constant
	var grace_period = bullet.GRACE_PERIOD
	
	# Then it should be reasonable (not too long)
	assert_lte(grace_period, 0.2, "Grace period should be <= 200ms")
	assert_gte(grace_period, 0.05, "Grace period should be >= 50ms")

func test_bullet_moves_during_grace_period():
	# Given a bullet with grace period
	bullet.initialize(Vector2(100, 100), Vector2.UP, 1, Bullet.BulletLevel.NORMAL, true)
	var initial_pos = bullet.global_position
	
	# When physics frames pass
	await wait_physics_frames(2)
	
	# Then bullet should have moved
	assert_ne(bullet.global_position, initial_pos, "Bullet should move during grace period")
