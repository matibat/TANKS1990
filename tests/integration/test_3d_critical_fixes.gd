extends GutTest
## 3D Gameplay Critical Fixes - Test-First Approach
## Tests for: discrete movement, Vector3 consistency, 4-directional movement, shooting, camera follow

const Tank3D = preload("res://src/entities/tank3d.gd")
const Bullet3D = preload("res://src/entities/bullet3d.gd")
const BulletManager3D = preload("res://src/managers/bullet_manager_3d.gd")
const GameController3D = preload("res://scenes3d/game_controller_3d.gd")
const BulletFiredEvent = preload("res://src/events/bullet_fired_event.gd")

var tank: Tank3D
var bullet_manager: BulletManager3D
var received_events: Array[GameEvent] = []

func before_each():
	# Create tank
	tank = Tank3D.new()
	add_child(tank)
	tank.global_position = Vector3(6.5, 0, 6.5)  # Center position
	tank.tank_type = Tank3D.TankType.PLAYER
	tank.is_player = true
	tank.use_continuous_movement = false  # MUST be discrete
	await get_tree().process_frame
	
	# Create bullet manager
	bullet_manager = BulletManager3D.new()
	add_child(bullet_manager)
	await get_tree().process_frame
	
	# Subscribe to events
	received_events.clear()
	EventBus.subscribe("BulletFired", Callable(self, "_on_event_received"))

func after_each():
	EventBus.unsubscribe("BulletFired", Callable(self, "_on_event_received"))
	received_events.clear()
	if tank:
		tank.queue_free()
	if bullet_manager:
		bullet_manager.queue_free()

func _on_event_received(event: GameEvent):
	received_events.append(event)

# ========================================
# DISCRETE MOVEMENT TESTS
# ========================================

func test_tank_uses_discrete_movement_not_continuous():
	assert_false(tank.use_continuous_movement, "Tank should use discrete grid movement")

func test_tank_snaps_to_grid_on_spawn():
	tank.global_position = Vector3(6.3, 0, 7.8)
	tank._ready()
	await get_tree().process_frame
	
	# Should snap to nearest 0.5 grid
	assert_eq(tank.global_position.x, 6.5, "X should snap to 0.5 grid")
	assert_eq(tank.global_position.z, 8.0, "Z should snap to 0.5 grid")
	assert_eq(tank.global_position.y, 0.0, "Y should be on ground plane")

func test_tank_moves_exactly_half_unit_per_step():
	var start_pos = tank.global_position
	
	# Move up (negative Z)
	tank.set_movement_direction(Vector3(0, 0, -1))
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var moved_distance = start_pos.distance_to(tank.global_position)
	assert_eq(moved_distance, 0.5, "Should move exactly 0.5 units (one tile)")

func test_tank_cannot_move_diagonally():
	tank.global_position = Vector3(5.0, 0, 5.0)
	
	# Try diagonal input
	tank.set_movement_direction(Vector3(1, 0, 1).normalized())
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	# Should only move in one cardinal direction (or not at all)
	var pos = tank.global_position
	var moved_diagonally = (pos.x != 5.0 and pos.z != 5.0)
	assert_false(moved_diagonally, "Should not move diagonally")

func test_tank_stops_at_tile_centers():
	tank.global_position = Vector3(5.0, 0, 5.0)
	tank.set_movement_direction(Vector3(1, 0, 0))  # Right
	
	for i in range(5):
		await get_tree().physics_frame
	
	# Should be at 5.5, 6.0, 6.5, 7.0, or 7.5 (tile centers)
	var x = tank.global_position.x
	var is_on_grid = is_equal_approx(fmod(x, 0.5), 0.0)
	assert_true(is_on_grid, "Tank should stop at tile center: " + str(x))

# ========================================
# VECTOR3 CONSISTENCY TESTS
# ========================================

func test_bullet_fired_event_uses_vector3_position():
	tank.fire_cooldown = 0.0
	tank.try_fire()
	await get_tree().physics_frame
	
	assert_gt(received_events.size(), 0, "Should emit BulletFired event")
	
	var event = received_events[0] as BulletFiredEvent
	assert_not_null(event, "Event should be BulletFiredEvent")
	
	# CRITICAL: Position must be Vector3, not Vector2
	assert_true(typeof(event.position) == TYPE_VECTOR3, "Event position must be Vector3, got: " + str(typeof(event.position)))

func test_bullet_fired_event_uses_vector3_direction():
	tank.fire_cooldown = 0.0
	tank.facing_direction = Tank3D.Direction.UP
	tank.try_fire()
	await get_tree().physics_frame
	
	var event = received_events[0] as BulletFiredEvent
	assert_not_null(event)
	
	# CRITICAL: Direction must be Vector3, not Vector2
	assert_true(typeof(event.direction) == TYPE_VECTOR3, "Event direction must be Vector3, got: " + str(typeof(event.direction)))

func test_bullet_manager_accepts_vector3_positions():
	var event = BulletFiredEvent.new()
	event.position = Vector3(5.0, 0, 5.0)  # Vector3
	event.direction = Vector3(0, 0, -1)  # Vector3
	event.tank_id = 1
	event.bullet_level = 0
	event.is_player_bullet = true
	
	# Should not crash when processing Vector3
	bullet_manager._on_bullet_fired(event)
	await get_tree().physics_frame
	
	pass_test("BulletManager accepts Vector3 without crashing")

# ========================================
# 4-DIRECTIONAL MOVEMENT TESTS
# ========================================

func test_tank_only_moves_in_four_cardinal_directions():
	var test_inputs = [
		Vector3(1, 0, 1),   # Diagonal
		Vector3(-1, 0, 1),  # Diagonal
		Vector3(1, 0, -1),  # Diagonal
		Vector3(-1, 0, -1)  # Diagonal
	]
	
	for input in test_inputs:
		tank.global_position = Vector3(5.0, 0, 5.0)
		tank.set_movement_direction(input.normalized())
		await get_tree().physics_frame
		await get_tree().physics_frame
		
		# Should snap to cardinal direction
		var moved = tank.global_position - Vector3(5.0, 0, 5.0)
		var is_cardinal = (moved.x == 0 or moved.z == 0)
		assert_true(is_cardinal, "Movement should be cardinal only, got: " + str(moved))

func test_tank_facing_up_means_negative_z():
	tank.facing_direction = Tank3D.Direction.UP
	var direction_vec = tank._direction_to_vector(Tank3D.Direction.UP)
	
	assert_eq(direction_vec.x, 0, "UP should have no X component")
	assert_lt(direction_vec.z, 0, "UP should be negative Z")
	assert_eq(direction_vec.y, 0, "UP should have no Y component")

func test_tank_facing_down_means_positive_z():
	tank.facing_direction = Tank3D.Direction.DOWN
	var direction_vec = tank._direction_to_vector(Tank3D.Direction.DOWN)
	
	assert_eq(direction_vec.x, 0, "DOWN should have no X component")
	assert_gt(direction_vec.z, 0, "DOWN should be positive Z")

func test_tank_facing_left_means_negative_x():
	var direction_vec = tank._direction_to_vector(Tank3D.Direction.LEFT)
	assert_lt(direction_vec.x, 0, "LEFT should be negative X")
	assert_eq(direction_vec.z, 0, "LEFT should have no Z component")

func test_tank_facing_right_means_positive_x():
	var direction_vec = tank._direction_to_vector(Tank3D.Direction.RIGHT)
	assert_gt(direction_vec.x, 0, "RIGHT should be positive X")
	assert_eq(direction_vec.z, 0, "RIGHT should have no Z component")

# ========================================
# ROTATION TESTS
# ========================================

func test_tank_rotation_matches_facing_direction():
	var test_cases = [
		{"dir": Tank3D.Direction.UP, "expected_y": 0.0},           # Facing -Z (0°)
		{"dir": Tank3D.Direction.RIGHT, "expected_y": PI/2},       # Facing +X (90°)
		{"dir": Tank3D.Direction.DOWN, "expected_y": PI},          # Facing +Z (180°)
		{"dir": Tank3D.Direction.LEFT, "expected_y": 3*PI/2}       # Facing -X (270°)
	]
	
	for case in test_cases:
		tank.facing_direction = case.dir
		tank._update_rotation()
		
		var rotation_y = tank.rotation.y
		assert_almost_eq(rotation_y, case.expected_y, 0.1, 
			"Rotation for " + str(case.dir) + " should be " + str(case.expected_y))

# ========================================
# SHOOTING TESTS
# ========================================

func test_tank_can_fire_bullet():
	tank.fire_cooldown = 0.0
	tank.try_fire()
	await get_tree().physics_frame
	
	assert_gt(received_events.size(), 0, "Should fire bullet")

func test_bullet_spawns_in_front_of_tank():
	tank.global_position = Vector3(5.0, 0, 5.0)
	tank.facing_direction = Tank3D.Direction.UP
	tank.fire_cooldown = 0.0
	tank.try_fire()
	await get_tree().physics_frame
	
	var event = received_events[0] as BulletFiredEvent
	var bullet_pos = event.position as Vector3
	
	# Bullet should spawn in front (negative Z)
	assert_lt(bullet_pos.z, 5.0, "Bullet should spawn in front (UP = -Z)")

func test_bullet_direction_matches_tank_facing():
	tank.facing_direction = Tank3D.Direction.RIGHT
	tank.fire_cooldown = 0.0
	tank.try_fire()
	await get_tree().physics_frame
	
	var event = received_events[0] as BulletFiredEvent
	var bullet_dir = event.direction as Vector3
	
	assert_gt(bullet_dir.x, 0, "Bullet should move right (+X)")
	assert_eq(bullet_dir.z, 0, "Bullet should have no Z component")

# ========================================
# CAMERA FOLLOW TESTS
# ========================================

func test_camera_exists_in_game_controller():
	var controller = GameController3D.new()
	add_child(controller)
	await get_tree().process_frame
	
	# Controller should find or create camera
	assert_not_null(controller.camera, "GameController should have camera reference")
	
	controller.queue_free()

func test_camera_follows_player_position():
	var controller = GameController3D.new()
	add_child(controller)
	
	# Mock player tank
	controller.player_tank = tank
	
	# Create camera if not exists
	if not controller.camera:
		controller.camera = Camera3D.new()
		controller.add_child(controller.camera)
	
	await get_tree().process_frame
	
	# Move player
	tank.global_position = Vector3(10, 0, 10)
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	# Camera should follow (with offset)
	var cam_x = controller.camera.global_position.x
	var cam_z = controller.camera.global_position.z
	
	# Camera should be centered on player (with some vertical offset)
	assert_almost_eq(cam_x, 10.0, 2.0, "Camera X should follow player")
	assert_almost_eq(cam_z, 10.0, 2.0, "Camera Z should follow player")
	
	controller.queue_free()
# ========================================
# CRITICAL FIX: LEFT/RIGHT CONTROL INVERSION
# ========================================

func test_left_input_moves_tank_left_and_faces_left():
	"""Validate that LEFT input moves tank left (-X) and rotates to 270°"""
	var start_pos = tank.global_position
	var start_x = start_pos.x
	
	# Move left
	tank.move_in_direction(Tank3D.Direction.LEFT)
	await get_tree().physics_frame
	
	# Assert movement: tank should move in -X direction
	assert_lt(tank.global_position.x, start_x, "LEFT should move tank in -X direction (left)")
	assert_eq(tank.global_position.z, start_pos.z, "LEFT should not change Z position")
	
	# Assert rotation: tank should face left (270° = 3*PI/2)
	assert_almost_eq(tank.rotation.y, 3*PI/2, 0.1, "LEFT should rotate to 270° (3*PI/2)")
	
	# Assert facing direction enum
	assert_eq(tank.facing_direction, Tank3D.Direction.LEFT, "Facing direction should be LEFT")

func test_right_input_moves_tank_right_and_faces_right():
	"""Validate that RIGHT input moves tank right (+X) and rotates to 90°"""
	var start_pos = tank.global_position
	var start_x = start_pos.x
	
	# Move right
	tank.move_in_direction(Tank3D.Direction.RIGHT)
	await get_tree().physics_frame
	
	# Assert movement: tank should move in +X direction
	assert_gt(tank.global_position.x, start_x, "RIGHT should move tank in +X direction (right)")
	assert_eq(tank.global_position.z, start_pos.z, "RIGHT should not change Z position")
	
	# Assert rotation: tank should face right (90° = PI/2)
	assert_almost_eq(tank.rotation.y, PI/2, 0.1, "RIGHT should rotate to 90° (PI/2)")
	
	# Assert facing direction enum
	assert_eq(tank.facing_direction, Tank3D.Direction.RIGHT, "Facing direction should be RIGHT")

func test_all_four_directions_match_movement_and_rotation():
	"""Comprehensive test: all four directions move correctly and face correctly"""
	var test_cases = [
		{
			"dir": Tank3D.Direction.UP,
			"name": "UP",
			"expected_rotation": 0.0,
			"check_pos": func(start, end): return end.z < start.z,  # -Z
			"error_msg": "UP should move in -Z and face 0°"
		},
		{
			"dir": Tank3D.Direction.RIGHT,
			"name": "RIGHT",
			"expected_rotation": PI/2,
			"check_pos": func(start, end): return end.x > start.x,  # +X
			"error_msg": "RIGHT should move in +X and face 90°"
		},
		{
			"dir": Tank3D.Direction.DOWN,
			"name": "DOWN",
			"expected_rotation": PI,
			"check_pos": func(start, end): return end.z > start.z,  # +Z
			"error_msg": "DOWN should move in +Z and face 180°"
		},
		{
			"dir": Tank3D.Direction.LEFT,
			"name": "LEFT",
			"expected_rotation": 3*PI/2,
			"check_pos": func(start, end): return end.x < start.x,  # -X
			"error_msg": "LEFT should move in -X and face 270°"
		}
	]
	
	for case in test_cases:
		# Reset tank to center
		tank.global_position = Vector3(6.5, 0, 6.5)
		await get_tree().physics_frame
		
		var start_pos = tank.global_position
		
		# Execute move
		tank.move_in_direction(case.dir)
		await get_tree().physics_frame
		
		var end_pos = tank.global_position
		
		# Check movement direction
		var moved_correctly = case.check_pos.call(start_pos, end_pos)
		assert_true(moved_correctly, case.name + " movement incorrect: " + case.error_msg)
		
		# Check rotation
		assert_almost_eq(tank.rotation.y, case.expected_rotation, 0.1, 
			case.name + " rotation incorrect: expected " + str(case.expected_rotation) + " got " + str(tank.rotation.y))
		
		# Check facing direction
		assert_eq(tank.facing_direction, case.dir, 
			case.name + " facing_direction should be " + str(case.dir))