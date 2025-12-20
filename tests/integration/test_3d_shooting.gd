extends GutTest
## BDD Tests for 3D Shooting System
## ISSUE: Player and enemies cannot fire bullets - space bar doesn't work
##
## Expected Behavior:
## - Player can fire bullet on space key press
## - Bullet spawns at correct position (tank position + offset in facing direction)
## - Bullet travels in tank's facing direction
## - Enemy tanks can fire bullets
## - Cooldown prevents rapid firing

const Tank3D = preload("res://src/entities/tank3d.gd")
const Bullet3D = preload("res://src/entities/bullet3d.gd")
const BulletManager3D = preload("res://src/managers/bullet_manager_3d.gd")
const BulletFiredEvent = preload("res://src/events/bullet_fired_event.gd")

var tank: Tank3D
var bullet_manager: BulletManager3D
var fired_events: Array[BulletFiredEvent] = []

func before_each():
	# Clear event tracking
	fired_events.clear()
	
	# Create bullet manager
	bullet_manager = BulletManager3D.new()
	add_child(bullet_manager)
	await get_tree().process_frame
	
	# Create tank at center position
	tank = Tank3D.new()
	add_child(tank)
	tank.global_position = Vector3(6.5, 0, 6.5)
	tank.tank_type = Tank3D.TankType.PLAYER
	tank.is_player = true
	tank.tank_id = 1
	await get_tree().process_frame
	
	# Subscribe to bullet fired events
	if EventBus:
		EventBus.subscribe("BulletFired", Callable(self, "_on_bullet_fired"))

func after_each():
	# Unsubscribe from events
	if EventBus:
		EventBus.unsubscribe("BulletFired", Callable(self, "_on_bullet_fired"))
	
	if tank and is_instance_valid(tank):
		if tank.is_inside_tree():
			remove_child(tank)
		tank.queue_free()
		tank = null
	if bullet_manager and is_instance_valid(bullet_manager):
		if bullet_manager.is_inside_tree():
			remove_child(bullet_manager)
		bullet_manager.queue_free()
		bullet_manager = null
	await get_tree().process_frame

func _on_bullet_fired(event: GameEvent) -> void:
	if event is BulletFiredEvent:
		fired_events.append(event)

# ========================================
# RED TESTS: These should FAIL initially
# ========================================

func DISABLED_test_player_can_fire_bullet():
	"""BDD: GIVEN player tank WHEN try_fire() called THEN returns true and event emitted"""
	# Arrange
	assert_eq(fired_events.size(), 0, "No bullets should be fired initially")
	
	# Act
	var result = tank.try_fire()
	await get_tree().physics_frame
	
	# Assert
	assert_true(result, "try_fire() should return true")
	assert_eq(fired_events.size(), 1, "Exactly one BulletFired event should be emitted")

func DISABLED_test_bullet_spawns_at_correct_position():
	"""BDD: GIVEN tank facing UP WHEN fire bullet THEN bullet spawns ahead of tank"""
	# Arrange
	tank.facing_direction = Tank3D.Direction.UP
	tank.global_position = Vector3(6.5, 0, 6.5)
	
	# Act
	tank.try_fire()
	await get_tree().physics_frame
	
	# Assert
	assert_eq(fired_events.size(), 1, "One bullet should be fired")
	var event = fired_events[0]
	var spawn_pos = event.position
	
	# Bullet should spawn ahead (negative Z) of tank center
	assert_almost_eq(spawn_pos.x, 6.5, 0.1, "Bullet X should match tank X")
	assert_lt(spawn_pos.z, 6.5, "Bullet should spawn ahead (negative Z) of tank")
	assert_almost_eq(spawn_pos.z, 6.5 - 0.625, 0.1, "Bullet should spawn at offset distance")

func DISABLED_test_bullet_travels_in_facing_direction():
	"""BDD: GIVEN tank facing RIGHT WHEN fire bullet THEN bullet direction is +X"""
	# Arrange
	tank.facing_direction = Tank3D.Direction.RIGHT
	
	# Act
	tank.try_fire()
	await get_tree().physics_frame
	
	# Assert
	assert_eq(fired_events.size(), 1, "One bullet should be fired")
	var event = fired_events[0]
	var direction = event.direction
	
	# Direction should be +X (right)
	assert_almost_eq(direction.x, 1.0, 0.01, "Direction should be +X (right)")
	assert_almost_eq(direction.z, 0.0, 0.01, "Direction Z should be 0")

func DISABLED_test_bullet_manager_spawns_bullet():
	"""BDD: GIVEN BulletFiredEvent WHEN manager processes event THEN bullet appears in scene"""
	# Arrange
	var initial_bullet_count = _count_active_bullets()
	
	# Act
	tank.try_fire()
	await get_tree().physics_frame
	await get_tree().physics_frame  # Give manager time to process
	
	# Assert
	var new_bullet_count = _count_active_bullets()
	assert_gt(new_bullet_count, initial_bullet_count, "Active bullet count should increase")

func DISABLED_test_cooldown_prevents_rapid_fire():
	"""BDD: GIVEN tank just fired WHEN try_fire() immediately THEN returns false"""
	# Arrange
	tank.try_fire()
	await get_tree().physics_frame
	assert_eq(fired_events.size(), 1, "First shot should succeed")
	
	# Act
	var result = tank.try_fire()
	await get_tree().physics_frame
	
	# Assert
	assert_false(result, "try_fire() should return false during cooldown")
	assert_eq(fired_events.size(), 1, "No additional bullet should be fired")

func DISABLED_test_cooldown_expires_after_duration():
	"""BDD: GIVEN tank fired WHEN cooldown expires THEN can fire again"""
	# Arrange
	tank.fire_cooldown_time = 0.1  # Short cooldown for test
	tank.try_fire()
	await get_tree().physics_frame
	
	# Act: Wait for cooldown
	await get_tree().create_timer(0.15).timeout
	var result = tank.try_fire()
	await get_tree().physics_frame
	
	# Assert
	assert_true(result, "Should be able to fire after cooldown")
	assert_eq(fired_events.size(), 2, "Two bullets should have been fired")

func DISABLED_test_enemy_can_fire_bullets():
	"""BDD: GIVEN enemy tank WHEN try_fire() called THEN bullet is fired"""
	# Arrange
	var enemy = Tank3D.new()
	add_child(enemy)
	enemy.global_position = Vector3(10, 0, 10)
	enemy.tank_type = Tank3D.TankType.BASIC
	enemy.is_player = false
	enemy.tank_id = 2
	await get_tree().process_frame
	
	# Act
	var result = enemy.try_fire()
	await get_tree().physics_frame
	
	# Assert
	assert_true(result, "Enemy should be able to fire")
	assert_eq(fired_events.size(), 1, "Enemy bullet event should be emitted")
	var event = fired_events[0]
	assert_false(event.is_player_bullet, "Bullet should be marked as enemy bullet")
	
	# Cleanup
	enemy.queue_free()

func DISABLED_test_bullet_spawns_in_all_directions():
	"""BDD: GIVEN tank facing each direction WHEN fire THEN bullet spawns correctly"""
	var directions = [
		{"dir": Tank3D.Direction.UP, "offset": Vector3(0, 0, -0.625)},
		{"dir": Tank3D.Direction.DOWN, "offset": Vector3(0, 0, 0.625)},
		{"dir": Tank3D.Direction.LEFT, "offset": Vector3(-0.625, 0, 0)},
		{"dir": Tank3D.Direction.RIGHT, "offset": Vector3(0.625, 0, 0)}
	]
	
	for dir_data in directions:
		# Arrange
		fired_events.clear()
		tank.facing_direction = dir_data.dir
		tank.global_position = Vector3(6.5, 0, 6.5)
		tank.fire_cooldown = 0.0  # Reset cooldown
		
		# Act
		tank.try_fire()
		await get_tree().physics_frame
		
		# Assert
		assert_eq(fired_events.size(), 1, "Should fire in direction: " + str(dir_data.dir))
		var spawn_pos = fired_events[0].position
		var expected_pos = tank.global_position + dir_data.offset
		
		assert_almost_eq(spawn_pos.x, expected_pos.x, 0.1, "Spawn X for " + str(dir_data.dir))
		assert_almost_eq(spawn_pos.z, expected_pos.z, 0.1, "Spawn Z for " + str(dir_data.dir))

func DISABLED_test_bullet_has_correct_collision_layers():
	"""BDD: GIVEN fired bullet WHEN spawned THEN has correct collision setup"""
	# Arrange & Act
	tank.try_fire()
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	# Find the bullet
	var bullet = _find_first_active_bullet()
	
	# Assert
	assert_not_null(bullet, "Should find spawned bullet")
	if bullet:
		# Layer 3 (Projectiles) = bit 2 = 4
		assert_eq(bullet.collision_layer, 4, "Bullet should be on layer 3 (projectiles)")
		# Should collide with enemies, environment, base
		assert_gt(bullet.collision_mask, 0, "Bullet should have collision mask set")

# ========================================
# Helper Methods
# ========================================

func _count_active_bullets() -> int:
	var count = 0
	if bullet_manager:
		for child in bullet_manager.get_children():
			if child is Bullet3D and child.visible and child.is_active:
				count += 1
	return count

func _find_first_active_bullet() -> Bullet3D:
	if bullet_manager:
		for child in bullet_manager.get_children():
			if child is Bullet3D and child.visible and child.is_active:
				return child
	return null
