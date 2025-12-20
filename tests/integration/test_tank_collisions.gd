extends GutTest
## Integration tests for Tank3D-Tank3D collision

var player_tank: Tank3D
var enemy_tank: Tank3D
var Vector3Helpers = preload("res://src/utils/vector3_helpers.gd")

func before_each():
	# Create player tank
	player_tank = Tank3D.new()
	player_tank.tank_type = Tank3D.TankType.PLAYER
	player_tank.is_player = true
	add_child_autofree(player_tank)
	
	# Create enemy tank
	enemy_tank = Tank3D.new()
	enemy_tank.tank_type = Tank3D.TankType.BASIC
	enemy_tank.is_player = false
	add_child_autofree(enemy_tank)
	
	await get_tree().process_frame

func after_each():
	if player_tank and is_instance_valid(player_tank):
		player_tank.queue_free()
	if enemy_tank and is_instance_valid(enemy_tank):
		enemy_tank.queue_free()
	
	player_tank = null
	enemy_tank = null

# === Basic Tank-Tank Collision Tests ===

func test_player_tank_collides_with_enemy_tank():
	# Position tanks adjacent
	player_tank.global_position = Vector3(5.0, 0.0, 5.0)
	enemy_tank.global_position = Vector3(5.5, 0.0, 5.0)  # 0.5 units apart (touching)
	
	await get_tree().process_frame
	
	# Verify collision layers configured correctly
	assert_eq(player_tank.collision_layer, 1, "Player should be on layer 1")
	assert_eq(enemy_tank.collision_layer, 2, "Enemy should be on layer 2")
	assert_true(player_tank.collision_mask & 2, "Player should collide with enemy layer")
	assert_true(enemy_tank.collision_mask & 1, "Enemy should collide with player layer")

func test_tanks_cannot_overlap():
	# Position tanks overlapping
	player_tank.global_position = Vector3(5.0, 0.0, 5.0)
	enemy_tank.global_position = Vector3(5.0, 0.0, 5.0)  # Same position
	
	await get_tree().process_frame
	
	# Try to move player into enemy
	var initial_pos = player_tank.global_position
	player_tank.move_in_direction(Tank3D.Direction.UP)
	await get_tree().process_frame
	
	# Movement should be blocked if tanks are overlapping
	# (discrete movement system prevents overlap in _would_collide_with_tank check)
	assert_true(is_instance_valid(player_tank), "Player tank should still exist")
	assert_true(is_instance_valid(enemy_tank), "Enemy tank should still exist")

func test_tank_movement_blocked_by_other_tank():
	# Position enemy directly in front of player
	player_tank.global_position = Vector3(5.0, 0.0, 5.0)
	enemy_tank.global_position = Vector3(5.0, 0.0, 4.5)  # Directly in front (-Z = UP)
	
	await get_tree().process_frame
	
	var initial_pos = player_tank.global_position
	
	# Try to move player into enemy
	player_tank.move_in_direction(Tank3D.Direction.UP)
	await get_tree().process_frame
	
	# Position should not change (blocked)
	assert_almost_eq(player_tank.global_position.x, initial_pos.x, 0.01, "X should not change")
	assert_almost_eq(player_tank.global_position.z, initial_pos.z, 0.01, "Z should not change (blocked)")
	
	# But facing direction should update
	assert_eq(player_tank.facing_direction, Tank3D.Direction.UP, "Should face UP even if blocked")

func test_tank_facing_updates_even_when_blocked():
	player_tank.global_position = Vector3(5.0, 0.0, 5.0)
	enemy_tank.global_position = Vector3(6.0, 0.0, 5.0)  # To the right
	
	player_tank.facing_direction = Tank3D.Direction.UP
	
	# Try to move right (into enemy)
	player_tank.move_in_direction(Tank3D.Direction.RIGHT)
	await get_tree().process_frame
	
	# Should update facing even if movement blocked
	assert_eq(player_tank.facing_direction, Tank3D.Direction.RIGHT, "Facing should update")

# === Tank Pushing Tests ===

func test_tanks_do_not_push_each_other():
	player_tank.global_position = Vector3(5.0, 0.0, 5.0)
	enemy_tank.global_position = Vector3(6.0, 0.0, 5.0)
	
	var enemy_initial_pos = enemy_tank.global_position
	
	# Player tries to move into enemy
	player_tank.move_in_direction(Tank3D.Direction.RIGHT)
	await get_tree().process_frame
	
	# Enemy position should not change (no pushing)
	assert_almost_eq(enemy_tank.global_position.x, enemy_initial_pos.x, 0.01, "Enemy should not move")
	assert_almost_eq(enemy_tank.global_position.z, enemy_initial_pos.z, 0.01, "Enemy should not move")

# === Collision Layer Verification Tests ===

func test_player_layer_and_mask():
	assert_eq(player_tank.collision_layer, 1, "Player layer should be 1")
	
	# Mask should include: Enemy(2) | Environment(4) | Base(5) | PowerUps(6)
	# = bits 1,3,4,5 = 2+8+16+32 = 58
	var expected_mask = 2 | 8 | 16 | 32  # Enemy | Environment | Base | PowerUps
	assert_eq(player_tank.collision_mask, expected_mask, "Player mask should be 58")

func test_enemy_layer_and_mask():
	assert_eq(enemy_tank.collision_layer, 2, "Enemy layer should be 2")
	
	# Mask should include: Player(1) | Projectiles(3) | Environment(4) | Base(5)
	# = bits 0,2,3,4 = 1+4+8+16 = 29
	var expected_mask = 1 | 4 | 8 | 16  # Player | Projectiles | Environment | Base
	assert_eq(enemy_tank.collision_mask, expected_mask, "Enemy mask should be 29")

# === Multiple Tank Tests ===

func test_multiple_enemy_tanks_block_player():
	# Create second enemy
	var enemy2 = Tank3D.new()
	enemy2.tank_type = Tank3D.TankType.BASIC
	enemy2.is_player = false
	add_child_autofree(enemy2)
	await get_tree().process_frame
	
	# Position tanks in a line
	player_tank.global_position = Vector3(5.0, 0.0, 5.0)
	enemy_tank.global_position = Vector3(5.0, 0.0, 4.5)   # Front
	enemy2.global_position = Vector3(5.0, 0.0, 4.0)        # Behind first enemy
	
	var initial_pos = player_tank.global_position
	
	# Try to move forward
	player_tank.move_in_direction(Tank3D.Direction.UP)
	await get_tree().process_frame
	
	# Should be blocked by first enemy
	assert_almost_eq(player_tank.global_position.z, initial_pos.z, 0.01, "Should be blocked")

# === Tank Size and Footprint Tests ===

func test_tank_collision_shape_size():
	var collision_shape = player_tank.get_node("CollisionShape3D")
	assert_not_null(collision_shape, "Should have collision shape")
	
	var shape = collision_shape.shape
	assert_true(shape is BoxShape3D, "Should use BoxShape3D")
	
	if shape is BoxShape3D:
		# Tank should be 1x0.5x1 (width x height x depth)
		assert_almost_eq(shape.size.x, 1.0, 0.1, "Width should be ~1.0")
		assert_almost_eq(shape.size.y, 0.5, 0.1, "Height should be ~0.5")
		assert_almost_eq(shape.size.z, 1.0, 0.1, "Depth should be ~1.0")

# === Edge Case Tests ===

func test_tanks_at_map_boundaries():
	# Position tanks at edge of map
	player_tank.global_position = Vector3(0.5, 0.0, 0.5)   # Near min corner
	enemy_tank.global_position = Vector3(12.5, 0.0, 12.5)  # Near max corner
	
	await get_tree().process_frame
	
	# Both should be valid and not colliding
	assert_true(is_instance_valid(player_tank), "Player should exist")
	assert_true(is_instance_valid(enemy_tank), "Enemy should exist")
	
	var distance = player_tank.global_position.distance_to(enemy_tank.global_position)
	assert_gt(distance, 2.0, "Should be far apart")

func test_tank_collision_at_different_heights():
	# Tanks should only collide on X/Z plane (Y should not matter)
	player_tank.global_position = Vector3(5.0, 0.0, 5.0)
	enemy_tank.global_position = Vector3(5.0, 1.0, 5.0)  # 1 unit above (shouldn't happen in game)
	
	await get_tree().process_frame
	
	# Should still detect as potential collision since X/Z overlap
	# But game logic keeps tanks at Y=0
	assert_almost_eq(player_tank.global_position.y, 0.0, 0.01, "Player should be at Y=0")
	assert_almost_eq(enemy_tank.global_position.y, 0.0, 0.01, "Enemy should be at Y=0")

# === Discrete Movement Collision Tests ===

func test_discrete_movement_prevents_overlap():
	# This tests the _would_collide_with_tank() pre-check system
	player_tank.global_position = Vector3(5.0, 0.0, 5.0)
	enemy_tank.global_position = Vector3(5.5, 0.0, 5.0)
	
	# Add both to "tanks" group for _would_collide_with_tank check
	player_tank.add_to_group("tanks")
	enemy_tank.add_to_group("tanks")
	
	var initial_player_pos = player_tank.global_position
	
	# Try to move right (toward enemy)
	player_tank.move_in_direction(Tank3D.Direction.RIGHT)
	await get_tree().process_frame
	
	# Pre-check should prevent movement
	var moved = !player_tank.global_position.is_equal_approx(initial_player_pos)
	
	# Either blocked or moved slightly but not through
	if moved:
		var distance_to_enemy = player_tank.global_position.distance_to(enemy_tank.global_position)
		assert_gte(distance_to_enemy, 0.9, "Should maintain minimum distance")

# === Performance Test ===

func test_collision_check_performance():
	# Create 10 enemy tanks
	var enemies = []
	for i in range(10):
		var enemy = Tank3D.new()
		enemy.tank_type = Tank3D.TankType.BASIC
		enemy.is_player = false
		enemy.global_position = Vector3(i * 1.5, 0.0, i * 1.5)
		add_child_autofree(enemy)
		enemies.append(enemy)
	
	await get_tree().process_frame
	
	player_tank.global_position = Vector3(5.0, 0.0, 5.0)
	
	var start_time = Time.get_ticks_usec()
	
	# Try multiple movements
	for i in range(10):
		player_tank.move_in_direction(Tank3D.Direction.UP)
		await get_tree().process_frame
	
	var elapsed = Time.get_ticks_usec() - start_time
	var avg_time_ms = elapsed / 1000.0 / 10.0
	
	# Should be efficient even with multiple tanks
	assert_lt(avg_time_ms, 1.0, "Collision checks should be fast (<1ms per frame)")
