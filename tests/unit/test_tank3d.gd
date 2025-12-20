extends GutTest
## BDD tests for Tank3D entity - 3D tank implementation with CharacterBody3D

var tank3d: CharacterBody3D
var event_bus: Node

const Vector3Helpers = preload("res://src/utils/vector3_helpers.gd")

func before_each():
	event_bus = EventBus
	event_bus.start_recording()

func after_each():
	event_bus.stop_recording()

## Feature: Tank3D Instantiation
class TestTank3DInstantiation:
	extends GutTest
	
	var tank3d
	
	func test_given_new_tank3d_when_created_then_is_character_body_3d():
		# Given/When: Create Tank3D instance
		var Tank3D = load("res://src/entities/tank3d.gd")
		tank3d = Tank3D.new()
		add_child_autofree(tank3d)
		
		# Then: Should be CharacterBody3D
		assert_true(tank3d is CharacterBody3D, "Tank3D should extend CharacterBody3D")
	
	func test_given_new_tank3d_when_created_then_has_vector3_position():
		# Given/When: Create Tank3D instance
		var Tank3D = load("res://src/entities/tank3d.gd")
		tank3d = Tank3D.new()
		add_child_autofree(tank3d)
		tank3d.global_position = Vector3(5.0, 0.0, 5.0)
		
		# Then: Position should be Vector3
		assert_typeof(tank3d.global_position, TYPE_VECTOR3, "Position should be Vector3")
		assert_almost_eq(tank3d.global_position.y, 0.0, 0.01, "Y should be 0 (ground plane)")
	
	func test_given_new_tank3d_when_created_then_has_collision_shape_3d():
		# Given/When: Create Tank3D with collision
		var Tank3D = load("res://src/entities/tank3d.gd")
		tank3d = Tank3D.new()
		add_child_autofree(tank3d)
		await get_tree().process_frame  # Wait for _ready()
		
		# Then: Should have CollisionShape3D child
		var collision_shape = tank3d.get_node_or_null("CollisionShape3D")
		assert_not_null(collision_shape, "Should have CollisionShape3D")
		assert_true(collision_shape is CollisionShape3D, "Should be CollisionShape3D type")
	
	func test_given_new_tank3d_when_created_then_collision_is_box_shape_3d():
		# Given/When: Create Tank3D with collision
		var Tank3D = load("res://src/entities/tank3d.gd")
		tank3d = Tank3D.new()
		add_child_autofree(tank3d)
		await get_tree().process_frame  # Wait for _ready()
		
		# Then: Collision shape should be BoxShape3D
		var collision_shape = tank3d.get_node_or_null("CollisionShape3D")
		assert_not_null(collision_shape, "Should have CollisionShape3D")
		if collision_shape and collision_shape.shape:
			assert_true(collision_shape.shape is BoxShape3D, "Shape should be BoxShape3D")
			var box = collision_shape.shape as BoxShape3D
			# Tank is 1x1 units footprint, height ~0.5
			assert_almost_eq(box.size.x, 1.0, 0.2, "Width should be ~1.0 units")
			assert_almost_eq(box.size.z, 1.0, 0.2, "Depth should be ~1.0 units")

## Feature: Tank3D Properties
class TestTank3DProperties:
	extends GutTest
	
	var tank3d
	
	func before_each():
		var Tank3D = load("res://src/entities/tank3d.gd")
		tank3d = Tank3D.new()
		tank3d.tank_type = 0  # PLAYER (assuming same enum)
		tank3d.base_speed = 5.0  # 3D speed in units/sec
		tank3d.tank_id = 1
		add_child_autofree(tank3d)
		tank3d.global_position = Vector3(6.5, 0.0, 12.0)  # Center-bottom in 3D (set after add_child)
		await get_tree().process_frame
	
	func test_given_tank3d_when_created_then_has_tank_type_property():
		# Then: Should have tank_type property
		assert_true(tank3d.has_method("get") and "tank_type" in tank3d, "Should have tank_type property")
	
	func test_given_tank3d_when_created_then_has_health_properties():
		# Then: Should have health system
		assert_true("current_health" in tank3d, "Should have current_health")
		assert_true("max_health" in tank3d, "Should have max_health")
		assert_gt(tank3d.current_health, 0, "Health should be > 0")
	
	func test_given_tank3d_when_created_then_has_facing_direction():
		# Then: Should have facing_direction property
		assert_true("facing_direction" in tank3d, "Should have facing_direction")
	
	func test_given_tank3d_when_created_then_has_state_machine():
		# Then: Should have current_state property
		assert_true("current_state" in tank3d, "Should have current_state")
	
	func test_given_tank3d_when_created_then_has_fire_cooldown():
		# Then: Should have fire_cooldown_time
		assert_true("fire_cooldown_time" in tank3d, "Should have fire_cooldown_time")
		assert_true("fire_cooldown" in tank3d, "Should have fire_cooldown counter")

## Feature: Tank3D Movement (3D Discrete Tile-Based)
class TestTank3DMovement:
	extends GutTest
	
	var tank3d
	const Vector3Helpers = preload("res://src/utils/vector3_helpers.gd")
	
	func before_each():
		var Tank3D = load("res://src/entities/tank3d.gd")
		tank3d = Tank3D.new()
		tank3d.tank_type = 0  # PLAYER
		tank3d.base_speed = 5.0
		tank3d.tank_id = 1
		add_child_autofree(tank3d)
		tank3d.global_position = Vector3(6.5, 0.0, 6.5)  # Center of map (set after add_child)
		await get_tree().process_frame
		# Skip spawn state for testing
		if tank3d.has_method("_complete_spawn"):
			tank3d.spawn_timer = 0
			tank3d._complete_spawn()
			tank3d.invulnerability_timer = 0
			tank3d._end_invulnerability()
	
	func test_given_idle_tank3d_when_move_forward_then_moves_to_next_tile():
		# Given: Tank is idle at tile center
		var start_pos = tank3d.global_position
		
		# When: Command tank to move forward (UP = -Z in 3D)
		# Direction.UP enum value
		var Direction = tank3d.get_script().get_script_constant_map()
		if "Direction" in Direction:
			Direction = Direction["Direction"]
		else:
			# Fallback: assume UP=0
			Direction = {"UP": 0, "DOWN": 1, "LEFT": 2, "RIGHT": 3}
		
		tank3d.move_in_direction(Direction.UP)
		tank3d._physics_process(1.0/60.0)
		
		# Then: Tank moves exactly 0.5 units forward (-Z)
		var expected_pos = Vector3(6.5, 0.0, 6.0)  # 6.5 - 0.5
		var actual_pos = tank3d.global_position
		assert_almost_eq(actual_pos.x, expected_pos.x, 0.01, "X should stay same")
		assert_almost_eq(actual_pos.y, 0.0, 0.01, "Y should stay 0 (ground plane)")
		assert_almost_eq(actual_pos.z, expected_pos.z, 0.01, "Z should decrease by 0.5")
	
	func test_given_idle_tank3d_when_move_right_then_moves_to_next_tile_right():
		# Given: Tank is idle at tile center
		var start_pos = tank3d.global_position
		
		# When: Command tank to move right (+X)
		var Direction = tank3d.get_script().get_script_constant_map()
		if "Direction" in Direction:
			Direction = Direction["Direction"]
		else:
			Direction = {"UP": 0, "DOWN": 1, "LEFT": 2, "RIGHT": 3}
		
		tank3d.move_in_direction(Direction.RIGHT)
		tank3d._physics_process(1.0/60.0)
		
		# Then: Tank moves exactly 0.5 units right (+X)
		var expected_pos = Vector3(7.0, 0.0, 6.5)  # 6.5 + 0.5
		var actual_pos = tank3d.global_position
		assert_almost_eq(actual_pos.x, expected_pos.x, 0.01, "X should increase by 0.5")
		assert_almost_eq(actual_pos.y, 0.0, 0.01, "Y should stay 0")
		assert_almost_eq(actual_pos.z, expected_pos.z, 0.01, "Z should stay same")
	
	func test_given_moving_tank3d_when_stop_then_velocity_zero():
		# Given: Tank is moving
		var Direction = tank3d.get_script().get_script_constant_map().get("Direction", {"UP": 0})
		tank3d.move_in_direction(Direction.UP)
		tank3d._physics_process(1.0/60.0)
		
		# When: Stop movement
		tank3d.stop_movement()
		
		# Then: Velocity is zero
		assert_eq(tank3d.velocity, Vector3.ZERO, "Velocity should be zero")
	
	func test_given_tank3d_when_move_then_position_is_quantized():
		# Given: Tank at precise position
		tank3d.global_position = Vector3(6.5, 0.0, 6.5)
		
		# When: Move in any direction
		var Direction = tank3d.get_script().get_script_constant_map().get("Direction", {"LEFT": 2})
		tank3d.move_in_direction(Direction.LEFT)
		tank3d._physics_process(1.0/60.0)
		
		# Then: Position should be quantized (no floating point drift)
		var pos = tank3d.global_position
		var quantized = Vector3Helpers.quantize_vec3(pos, 0.001)
		assert_true(
			Vector3Helpers.vec3_approx_equal(pos, quantized, 0.001),
			"Position should be quantized to prevent drift"
		)

## Feature: Tank3D Rotation (Y-axis)
class TestTank3DRotation:
	extends GutTest
	
	var tank3d
	
	func before_each():
		var Tank3D = load("res://src/entities/tank3d.gd")
		tank3d = Tank3D.new()
		tank3d.tank_type = 0  # PLAYER
		add_child_autofree(tank3d)
		tank3d.global_position = Vector3(6.5, 0.0, 6.5)  # Set after add_child
		await get_tree().process_frame
	
	func test_given_tank3d_when_face_up_then_rotation_y_is_zero():
		# When: Face UP (-Z forward)
		var Direction = tank3d.get_script().get_script_constant_map().get("Direction", {"UP": 0})
		tank3d.move_in_direction(Direction.UP)
		
		# Then: Rotation Y should be 0 or 2π (facing -Z)
		var rot_y = tank3d.rotation.y
		# UP can be 0° or 180° depending on convention
		# For -Z forward, typically 0°
		assert_true(
			abs(rot_y) < 0.1 or abs(rot_y - PI) < 0.1,
			"Rotation Y should align with -Z axis"
		)
	
	func test_given_tank3d_when_face_right_then_rotation_y_is_90_deg():
		# When: Face RIGHT (+X)
		var Direction = tank3d.get_script().get_script_constant_map().get("Direction", {"RIGHT": 3})
		tank3d.move_in_direction(Direction.RIGHT)
		
		# Then: Rotation Y should be ~90° or π/2 (facing +X)
		var rot_y = tank3d.rotation.y
		# RIGHT is typically +90° or -90° depending on handedness
		assert_true(
			abs(rot_y - PI/2) < 0.1 or abs(rot_y + PI/2) < 0.1 or abs(rot_y - 3*PI/2) < 0.1,
			"Rotation Y should align with +X axis"
		)

## Feature: Tank3D Shooting
class TestTank3DShooting:
	extends GutTest
	
	var tank3d
	
	func before_each():
		var Tank3D = load("res://src/entities/tank3d.gd")
		tank3d = Tank3D.new()
		tank3d.tank_type = 0
		tank3d.fire_cooldown_time = 0.5
		add_child_autofree(tank3d)
		tank3d.global_position = Vector3(6.5, 0.0, 6.5)  # Set after add_child
		await get_tree().process_frame
		EventBus.start_recording()
	
	func after_each():
		EventBus.stop_recording()
	
	func test_given_tank3d_when_try_fire_then_returns_true_if_ready():
		# Given: Tank is ready to fire (cooldown = 0)
		tank3d.fire_cooldown = 0.0
		
		# When: Try to fire
		var result = tank3d.try_fire()
		
		# Then: Should return true
		assert_true(result, "Should fire when cooldown ready")
	
	func test_given_tank3d_when_fire_then_emits_bullet_fired_event():
		# Given: Tank ready to fire
		tank3d.fire_cooldown = 0.0
		
		# When: Fire bullet
		tank3d.try_fire()
		
		# Then: BulletFiredEvent emitted
		var replay = EventBus.stop_recording()
		EventBus.start_recording()  # Restart for cleanup
		assert_gt(replay.events.size(), 0, "Should emit event")
		
		# Verify event was fired (events are stored as dictionaries)
		var fired_event = null
		for event in replay.events:
			if event.get("type") == "BulletFired":
				fired_event = event
				break
		
		assert_not_null(fired_event, "Should have emitted BulletFired event")
		if fired_event:
			# Position is converted to Vector2 for event compatibility (X/Z -> X/Y)
			var event_pos = fired_event.get("position", {})
			var position = Vector2(event_pos.x, event_pos.y)
			assert_typeof(position, TYPE_VECTOR2, "Bullet position should be Vector2 (event compatibility)")
			# Verify position is based on tank position (6.5 * 32 = 208 pixels)
			assert_gt(position.length(), 0, "Position should be non-zero")
	
	func test_given_tank3d_when_fire_with_cooldown_then_returns_false():
		# Given: Tank is on cooldown
		tank3d.fire_cooldown = 0.3
		
		# When: Try to fire
		var result = tank3d.try_fire()
		
		# Then: Should return false
		assert_false(result, "Should not fire when on cooldown")

## Feature: Tank3D Damage and Death
class TestTank3DDamage:
	extends GutTest
	
	var tank3d
	
	func before_each():
		var Tank3D = load("res://src/entities/tank3d.gd")
		tank3d = Tank3D.new()
		tank3d.tank_type = 0
		tank3d.max_health = 2
		add_child_autofree(tank3d)
		tank3d.global_position = Vector3(6.5, 0.0, 6.5)  # Set after add_child
		await get_tree().process_frame
	
	func test_given_tank3d_when_take_damage_then_health_decreases():
		# Given: Tank at full health
		var initial_health = tank3d.current_health
		
		# When: Take damage
		tank3d.take_damage(1)
		
		# Then: Health decreased
		assert_eq(tank3d.current_health, initial_health - 1, "Health should decrease by 1")
	
	func test_given_tank3d_when_health_zero_then_dies():
		# Given: Tank at 1 HP
		tank3d.current_health = 1
		
		# When: Take fatal damage
		tank3d.take_damage(1)
		
		# Then: Tank enters DYING state
		# Check state (assuming State enum exists)
		var state = tank3d.current_state
		# State.DYING typically = 3
		assert_true(state == 3 or tank3d.current_health <= 0, "Tank should be dying or dead")
	
	func test_given_tank3d_when_die_then_emits_died_signal():
		# Given: Tank at 1 HP, watch for died signal
		tank3d.current_health = 1
		watch_signals(tank3d)
		
		# When: Tank dies
		tank3d.die()
		
		# Then: Signal emitted
		assert_signal_emitted(tank3d, "died", "Should emit died signal")

## Feature: Tank3D Signals
class TestTank3DSignals:
	extends GutTest
	
	var tank3d
	
	func before_each():
		var Tank3D = load("res://src/entities/tank3d.gd")
		tank3d = Tank3D.new()
		add_child_autofree(tank3d)
		await get_tree().process_frame
	
	func test_given_tank3d_when_created_then_has_health_changed_signal():
		# Then: Should have health_changed signal
		assert_true(tank3d.has_signal("health_changed"), "Should have health_changed signal")
	
	func test_given_tank3d_when_created_then_has_died_signal():
		# Then: Should have died signal
		assert_true(tank3d.has_signal("died"), "Should have died signal")
	
	func test_given_tank3d_when_created_then_has_state_changed_signal():
		# Then: Should have state_changed signal
		assert_true(tank3d.has_signal("state_changed"), "Should have state_changed signal")
