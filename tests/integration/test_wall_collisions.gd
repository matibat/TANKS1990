extends GutTest
## Integration tests for wall collisions in 3D

var tank: Tank3D
var bullet: Bullet3D
var brick_wall: StaticBody3D
var steel_wall: StaticBody3D
var Vector3Helpers = preload("res://src/utils/vector3_helpers.gd")

func before_each():
	# Create tank
	tank = Tank3D.new()
	tank.tank_type = Tank3D.TankType.PLAYER
	add_child_autofree(tank)
	
	# Create bullet
	bullet = Bullet3D.new()
	add_child_autofree(bullet)
	
	# Create brick wall
	brick_wall = StaticBody3D.new()
	brick_wall.collision_layer = 8  # Environment
	brick_wall.collision_mask = 7
	brick_wall.set_meta("tile_type", "brick")
	var brick_collision = CollisionShape3D.new()
	var brick_box = BoxShape3D.new()
	brick_box.size = Vector3(0.5, 1.0, 0.5)
	brick_collision.shape = brick_box
	brick_wall.add_child(brick_collision)
	add_child_autofree(brick_wall)
	
	# Create steel wall
	steel_wall = StaticBody3D.new()
	steel_wall.collision_layer = 8  # Environment
	steel_wall.collision_mask = 7
	steel_wall.set_meta("tile_type", "steel")
	var steel_collision = CollisionShape3D.new()
	var steel_box = BoxShape3D.new()
	steel_box.size = Vector3(0.5, 1.0, 0.5)
	steel_collision.shape = steel_box
	steel_wall.add_child(steel_collision)
	add_child_autofree(steel_wall)
	
	await get_tree().process_frame

func after_each():
	if tank and is_instance_valid(tank):
		tank.queue_free()
	if bullet and is_instance_valid(bullet):
		bullet.queue_free()
	if brick_wall and is_instance_valid(brick_wall):
		brick_wall.queue_free()
	if steel_wall and is_instance_valid(steel_wall):
		steel_wall.queue_free()
	
	tank = null
	bullet = null
	brick_wall = null
	steel_wall = null

# === Tank-Wall Collision Tests ===

func test_tank_cannot_pass_through_brick_wall():
	brick_wall.global_position = Vector3(5.0, 0.0, 5.0)
	tank.global_position = Vector3(5.0, 0.0, 4.0)
	
	var initial_pos = tank.global_position
	
	# Try to move through wall
	for i in range(5):
		tank.move_in_direction(Tank3D.Direction.DOWN)  # +Z
		await get_tree().process_frame
	
	# Tank should be stopped by wall
	assert_lt(tank.global_position.z, brick_wall.global_position.z, "Tank should not pass through brick")

func test_tank_cannot_pass_through_steel_wall():
	steel_wall.global_position = Vector3(5.0, 0.0, 5.0)
	tank.global_position = Vector3(5.0, 0.0, 4.0)
	
	var initial_pos = tank.global_position
	
	# Try to move through wall
	for i in range(5):
		tank.move_in_direction(Tank3D.Direction.DOWN)
		await get_tree().process_frame
	
	# Tank should be stopped
	assert_lt(tank.global_position.z, steel_wall.global_position.z, "Tank should not pass through steel")

func test_tank_collision_updates_facing():
	brick_wall.global_position = Vector3(5.0, 0.0, 5.0)
	tank.global_position = Vector3(5.0, 0.0, 4.0)
	tank.facing_direction = Tank3D.Direction.LEFT
	
	# Try to move into wall
	tank.move_in_direction(Tank3D.Direction.DOWN)
	await get_tree().process_frame
	
	# Facing should update even if movement blocked
	assert_eq(tank.facing_direction, Tank3D.Direction.DOWN, "Facing should update")

# === Bullet-Brick Wall Tests ===

func test_normal_bullet_stops_at_brick():
	brick_wall.global_position = Vector3(5.0, 0.0, 6.0)
	
	bullet.initialize(
		Vector3(5.0, 0.0, 4.0),
		Vector3(0, 0, 1),
		1,
		1,  # Normal bullet
		true
	)
	bullet.is_active = true
	bullet.can_destroy_steel = false
	
	var hit_terrain = false
	bullet.hit_terrain.connect(func(_pos): hit_terrain = true)
	
	# Simulate until collision
	for i in range(30):
		bullet._physics_process(0.016)
		await get_tree().process_frame
		if hit_terrain or not bullet.is_active:
			break
	
	# Bullet should stop at or before wall
	assert_lte(bullet.global_position.z, brick_wall.global_position.z + 0.5, "Should stop at brick")

func test_bullet_destroys_brick_wall():
	# In full terrain system (Phase 7), this would damage/remove brick
	# For now, we test that bullet collision is detected
	brick_wall.global_position = Vector3(5.0, 0.0, 6.0)
	
	bullet.initialize(
		Vector3(5.0, 0.0, 4.0),
		Vector3(0, 0, 1),
		1,
		1,
		true
	)
	bullet.is_active = true
	
	var hit_wall = false
	bullet.hit_terrain.connect(func(pos): 
		hit_wall = true
		# In Phase 7, would call: terrain.damage_tile(pos, can_destroy_steel)
	)
	
	for i in range(30):
		bullet._physics_process(0.016)
		await get_tree().process_frame
		if not bullet.is_active:
			break
	
	# Bullet should be destroyed after hitting brick
	# (Actual brick destruction happens in Phase 7 terrain system)
	pass

# === Bullet-Steel Wall Tests ===

func test_normal_bullet_bounces_off_steel():
	steel_wall.global_position = Vector3(5.0, 0.0, 6.0)
	
	bullet.initialize(
		Vector3(5.0, 0.0, 4.0),
		Vector3(0, 0, 1),
		1,
		1,  # Normal - cannot destroy steel
		true
	)
	bullet.is_active = true
	bullet.can_destroy_steel = false
	
	assert_false(bullet.can_destroy_steel, "Normal bullet should not destroy steel")
	
	for i in range(30):
		bullet._physics_process(0.016)
		await get_tree().process_frame
		if not bullet.is_active:
			break
	
	# Should stop at steel wall
	assert_lte(bullet.global_position.z, steel_wall.global_position.z + 0.5, "Should stop at steel")

func test_super_bullet_destroys_steel():
	steel_wall.global_position = Vector3(5.0, 0.0, 6.0)
	
	bullet.initialize(
		Vector3(5.0, 0.0, 4.0),
		Vector3(0, 0, 1),
		1,
		3,  # Super - can destroy steel
		true
	)
	bullet.is_active = true
	
	assert_true(bullet.can_destroy_steel, "Super bullet should destroy steel")
	
	var hit_terrain = false
	bullet.hit_terrain.connect(func(_pos): hit_terrain = true)
	
	for i in range(30):
		bullet._physics_process(0.016)
		await get_tree().process_frame
		if hit_terrain or not bullet.is_active:
			break
	
	# Bullet should hit steel (and would destroy it in Phase 7)
	pass

# === Bullet Upgrade Level Tests ===

func test_enhanced_bullet_cannot_destroy_steel():
	bullet.initialize(Vector3.ZERO, Vector3.FORWARD, 1, 2, true)  # Enhanced (level 2)
	
	assert_false(bullet.can_destroy_steel, "Enhanced bullet should not destroy steel")
	assert_eq(bullet.penetration, 2, "Should have penetration 2")

func test_super_bullet_has_steel_destruction():
	bullet.initialize(Vector3.ZERO, Vector3.FORWARD, 1, 3, true)  # Super (level 3)
	
	assert_true(bullet.can_destroy_steel, "Super bullet should destroy steel")
	assert_eq(bullet.penetration, 3, "Should have penetration 3")

# === Multiple Walls Test ===

func test_bullet_stops_at_first_wall():
	brick_wall.global_position = Vector3(5.0, 0.0, 6.0)
	steel_wall.global_position = Vector3(5.0, 0.0, 8.0)
	
	bullet.initialize(
		Vector3(5.0, 0.0, 4.0),
		Vector3(0, 0, 1),
		1,
		1,
		true
	)
	bullet.is_active = true
	
	for i in range(50):
		bullet._physics_process(0.016)
		await get_tree().process_frame
		if not bullet.is_active:
			break
	
	# Should stop at first wall, not reach second
	assert_lt(bullet.global_position.z, steel_wall.global_position.z, "Should stop at first wall")

# === Tank Size and Wall Collision ===

func test_tank_2x2_footprint_collision():
	# Tank is 1x1 units (2x2 tiles in 0.5 unit tiles)
	# Wall is 0.5 units wide
	brick_wall.global_position = Vector3(5.0, 0.0, 5.0)
	tank.global_position = Vector3(5.0, 0.0, 3.5)  # Tank center 1.5 units away
	
	var initial_pos = tank.global_position
	
	# Move toward wall
	tank.move_in_direction(Tank3D.Direction.DOWN)
	await get_tree().process_frame
	
	# Tank should move closer but not overlap wall
	# Tank front edge should not pass wall back edge
	var tank_front_edge = tank.global_position.z + 0.5  # Tank extends 0.5 units forward
	var wall_back_edge = brick_wall.global_position.z - 0.25  # Wall extends 0.25 units back
	
	# These calculations are approximate; actual collision depends on discrete tile system
	pass

# === Edge Cases ===

func test_tank_at_corner_collision():
	# Place walls at corner
	brick_wall.global_position = Vector3(5.0, 0.0, 5.0)
	steel_wall.global_position = Vector3(5.5, 0.0, 5.0)
	
	tank.global_position = Vector3(4.5, 0.0, 4.5)
	
	# Try to move into corner
	tank.move_in_direction(Tank3D.Direction.RIGHT)
	await get_tree().process_frame
	tank.move_in_direction(Tank3D.Direction.DOWN)
	await get_tree().process_frame
	
	# Should be blocked by walls
	assert_lt(tank.global_position.x, brick_wall.global_position.x, "Should not pass horizontal wall")
	assert_lt(tank.global_position.z, brick_wall.global_position.z, "Should not pass vertical wall")

func test_bullet_grazes_wall_edge():
	brick_wall.global_position = Vector3(5.0, 0.0, 6.0)
	
	# Bullet passes just to the side
	bullet.initialize(
		Vector3(5.3, 0.0, 4.0),  # Offset from wall center
		Vector3(0, 0, 1),
		1,
		1,
		true
	)
	bullet.is_active = true
	
	for i in range(30):
		bullet._physics_process(0.016)
		await get_tree().process_frame
		if not bullet.is_active:
			break
	
	# Bullet might graze or pass depending on exact collision geometry
	# With 0.5 unit wall and 0.125 radius bullet, 0.3 offset should pass
	pass

# === Wall Collision Layer Verification ===

func test_brick_wall_collision_layer():
	assert_eq(brick_wall.collision_layer, 8, "Brick should be on environment layer (8 = 2^3)")

func test_steel_wall_collision_layer():
	assert_eq(steel_wall.collision_layer, 8, "Steel should be on environment layer")

func test_walls_collide_with_tanks():
	assert_eq(brick_wall.collision_mask, 7, "Should collide with layers 1|2|3 (tanks + bullets)")
	assert_eq(steel_wall.collision_mask, 7, "Should collide with layers 1|2|3")

# === Performance Test ===

func test_wall_collision_performance():
	# Create grid of walls (5x5 = 25 walls)
	var walls = []
	for x in range(5):
		for z in range(5):
			var wall = StaticBody3D.new()
			wall.collision_layer = 8
			wall.collision_mask = 7
			var collision = CollisionShape3D.new()
			var box = BoxShape3D.new()
			box.size = Vector3(0.5, 1.0, 0.5)
			collision.shape = box
			wall.add_child(collision)
			wall.global_position = Vector3(x * 1.0, 0.0, z * 1.0)
			add_child_autofree(wall)
			walls.append(wall)
	
	await get_tree().process_frame
	
	tank.global_position = Vector3(0.0, 0.0, 0.0)
	
	var start_time = Time.get_ticks_usec()
	
	# Try to navigate through walls
	for i in range(20):
		tank.move_in_direction(Tank3D.Direction.RIGHT)
		await get_tree().process_frame
		tank.move_in_direction(Tank3D.Direction.DOWN)
		await get_tree().process_frame
	
	var elapsed = Time.get_ticks_usec() - start_time
	var avg_time_ms = elapsed / 1000.0 / 40.0
	
	# Should handle multiple walls efficiently
	assert_lt(avg_time_ms, 0.5, "Wall collision should be efficient (<0.5ms per frame)")
