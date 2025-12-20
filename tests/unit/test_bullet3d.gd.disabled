extends GutTest
## BDD tests for Bullet3D entity - 3D bullet implementation with Area3D

var bullet3d: Area3D
var event_bus: Node

const Vector3Helpers = preload("res://src/utils/vector3_helpers.gd")

func before_each():
	event_bus = EventBus
	event_bus.start_recording()

func after_each():
	event_bus.stop_recording()

## Feature: Bullet3D Instantiation
class TestBullet3DInstantiation:
	extends GutTest
	
	var bullet3d
	
	func test_given_new_bullet3d_when_created_then_is_area_3d():
		# Given/When: Create Bullet3D instance
		var Bullet3D = load("res://src/entities/bullet3d.gd")
		bullet3d = Bullet3D.new()
		add_child_autofree(bullet3d)
		
		# Then: Should be Area3D
		assert_true(bullet3d is Area3D, "Bullet3D should extend Area3D")
	
	func test_given_new_bullet3d_when_created_then_has_vector3_position():
		# Given/When: Create Bullet3D instance
		var Bullet3D = load("res://src/entities/bullet3d.gd")
		bullet3d = Bullet3D.new()
		add_child_autofree(bullet3d)
		bullet3d.global_position = Vector3(5.0, 0.25, 5.0)
		
		# Then: Position should be Vector3
		assert_typeof(bullet3d.global_position, TYPE_VECTOR3, "Position should be Vector3")
		assert_almost_eq(bullet3d.global_position.y, 0.25, 0.01, "Y should be 0.25 (bullet height)")
	
	func test_given_new_bullet3d_when_created_then_has_collision_shape_3d():
		# Given/When: Create Bullet3D with collision
		var Bullet3D = load("res://src/entities/bullet3d.gd")
		bullet3d = Bullet3D.new()
		add_child_autofree(bullet3d)
		await get_tree().process_frame  # Wait for _ready()
		
		# Then: Should have CollisionShape3D child
		var collision_shape = bullet3d.get_node_or_null("CollisionShape3D")
		assert_not_null(collision_shape, "Should have CollisionShape3D")
		assert_true(collision_shape is CollisionShape3D, "Should be CollisionShape3D type")
	
	func test_given_new_bullet3d_when_created_then_collision_is_sphere_shape_3d():
		# Given/When: Create Bullet3D with collision
		var Bullet3D = load("res://src/entities/bullet3d.gd")
		bullet3d = Bullet3D.new()
		add_child_autofree(bullet3d)
		await get_tree().process_frame  # Wait for _ready()
		
		# Then: Collision shape should be SphereShape3D
		var collision_shape = bullet3d.get_node_or_null("CollisionShape3D")
		assert_not_null(collision_shape, "Should have CollisionShape3D")
		if collision_shape and collision_shape.shape:
			assert_true(collision_shape.shape is SphereShape3D, "Shape should be SphereShape3D")
			var sphere = collision_shape.shape as SphereShape3D
			assert_almost_eq(sphere.radius, 0.125, 0.05, "Radius should be ~0.125 units")

## Feature: Bullet3D Properties
class TestBullet3DProperties:
	extends GutTest
	
	var bullet3d
	
	func before_each():
		var Bullet3D = load("res://src/entities/bullet3d.gd")
		bullet3d = Bullet3D.new()
		add_child_autofree(bullet3d)
		await get_tree().process_frame
	
	func test_given_bullet3d_when_created_then_has_speed_property():
		# Then: Should have speed property
		assert_true("speed" in bullet3d, "Should have speed property")
		assert_gt(bullet3d.speed, 0.0, "Speed should be positive")
	
	func test_given_bullet3d_when_created_then_has_direction_vector3():
		# Then: Should have direction as Vector3
		assert_true("direction" in bullet3d, "Should have direction property")
		if "direction" in bullet3d:
			assert_typeof(bullet3d.direction, TYPE_VECTOR3, "Direction should be Vector3")
	
	func test_given_bullet3d_when_created_then_has_owner_properties():
		# Then: Should have owner tracking
		assert_true("owner_tank_id" in bullet3d, "Should have owner_tank_id")
		assert_true("owner_type" in bullet3d, "Should have owner_type")
	
	func test_given_bullet3d_when_created_then_has_level_property():
		# Then: Should have level property
		assert_true("level" in bullet3d, "Should have level property")
	
	func test_given_bullet3d_when_created_then_has_is_active_state():
		# Then: Should have is_active flag
		assert_true("is_active" in bullet3d, "Should have is_active property")
		assert_true(bullet3d.is_active, "Should be active initially")

## Feature: Bullet3D Initialization
class TestBullet3DInitialization:
	extends GutTest
	
	var bullet3d
	
	func before_each():
		var Bullet3D = load("res://src/entities/bullet3d.gd")
		bullet3d = Bullet3D.new()
		add_child_autofree(bullet3d)
		await get_tree().process_frame
	
	func test_given_bullet3d_when_initialized_then_sets_position():
		# Given: Bullet3D instance
		var start_pos = Vector3(5.0, 0.25, 5.0)
		
		# When: Initialize with position
		bullet3d.initialize(start_pos, Vector3(0, 0, -1), 1, 1, false)
		
		# Then: Position is set
		assert_true(Vector3Helpers.vec3_approx_equal(bullet3d.global_position, start_pos, 0.01), 
			"Position should match initialization")
	
	func test_given_bullet3d_when_initialized_then_sets_direction():
		# Given: Bullet3D instance
		var direction = Vector3(1, 0, 0).normalized()
		
		# When: Initialize with direction
		bullet3d.initialize(Vector3(5.0, 0.25, 5.0), direction, 1, 1, false)
		
		# Then: Direction is set and normalized
		assert_true(Vector3Helpers.vec3_approx_equal(bullet3d.direction, direction, 0.01), 
			"Direction should match initialization")
		assert_almost_eq(bullet3d.direction.length(), 1.0, 0.01, "Direction should be normalized")
	
	func test_given_bullet3d_when_initialized_with_level_then_adjusts_speed():
		# Given: Bullet3D instance
		
		# When: Initialize with ENHANCED level (2)
		bullet3d.initialize(Vector3(5.0, 0.25, 5.0), Vector3(0, 0, -1), 1, 2, false)
		
		# Then: Speed increased for enhanced level
		assert_gt(bullet3d.speed, 6.25, "Enhanced level should increase speed")
	
	func test_given_bullet3d_when_initialized_with_super_level_then_can_destroy_steel():
		# Given: Bullet3D instance
		
		# When: Initialize with SUPER level (3)
		bullet3d.initialize(Vector3(5.0, 0.25, 5.0), Vector3(0, 0, -1), 1, 3, true)
		
		# Then: Can destroy steel
		assert_true(bullet3d.can_destroy_steel, "Super level should enable steel destruction")

## Feature: Bullet3D Movement
class TestBullet3DMovement:
	extends GutTest
	
	var bullet3d
	
	func before_each():
		var Bullet3D = load("res://src/entities/bullet3d.gd")
		bullet3d = Bullet3D.new()
		add_child_autofree(bullet3d)
		await get_tree().process_frame
	
	func test_given_bullet3d_initialized_when_physics_processed_then_moves_in_direction():
		# Given: Bullet3D initialized moving forward (-Z)
		bullet3d.initialize(Vector3(5.0, 0.25, 5.0), Vector3(0, 0, -1), 1, 1, false)
		var start_pos = bullet3d.global_position
		
		# When: Physics processes one frame
		bullet3d._physics_process(1.0/60.0)  # 1 frame at 60 FPS
		
		# Then: Bullet moves forward (negative Z)
		assert_lt(bullet3d.global_position.z, start_pos.z, "Bullet should move forward (-Z)")
		assert_almost_eq(bullet3d.global_position.x, start_pos.x, 0.01, "X should remain constant")
		assert_almost_eq(bullet3d.global_position.y, start_pos.y, 0.01, "Y should remain constant")
	
	func test_given_bullet3d_moving_right_when_processed_then_x_increases():
		# Given: Bullet3D moving right (+X)
		bullet3d.initialize(Vector3(5.0, 0.25, 5.0), Vector3(1, 0, 0), 1, 1, false)
		var start_pos = bullet3d.global_position
		
		# When: Physics processes
		bullet3d._physics_process(1.0/60.0)
		
		# Then: X increases
		assert_gt(bullet3d.global_position.x, start_pos.x, "X should increase moving right")
		assert_almost_eq(bullet3d.global_position.z, start_pos.z, 0.01, "Z should remain constant")
	
	func test_given_bullet3d_when_inactive_then_does_not_move():
		# Given: Bullet3D initialized but deactivated
		bullet3d.initialize(Vector3(5.0, 0.25, 5.0), Vector3(0, 0, -1), 1, 1, false)
		bullet3d.is_active = false
		var start_pos = bullet3d.global_position
		
		# When: Physics processes
		bullet3d._physics_process(1.0/60.0)
		
		# Then: Position unchanged
		assert_true(Vector3Helpers.vec3_approx_equal(bullet3d.global_position, start_pos, 0.01), 
			"Inactive bullet should not move")
	
	func test_given_bullet3d_when_moves_then_position_quantized():
		# Given: Bullet3D initialized
		bullet3d.initialize(Vector3(5.123456, 0.25, 5.789012), Vector3(1, 0, 0), 1, 1, false)
		
		# When: Physics processes
		bullet3d._physics_process(1.0/60.0)
		
		# Then: Position is quantized (no excessive decimal places)
		var pos = bullet3d.global_position
		assert_almost_eq(pos.x, round(pos.x * 1000.0) / 1000.0, 0.0001, "X should be quantized")
		assert_almost_eq(pos.z, round(pos.z * 1000.0) / 1000.0, 0.0001, "Z should be quantized")

## Feature: Bullet3D Collision Detection
class TestBullet3DCollision:
	extends GutTest
	
	var bullet3d
	
	func before_each():
		var Bullet3D = load("res://src/entities/bullet3d.gd")
		bullet3d = Bullet3D.new()
		add_child_autofree(bullet3d)
		await get_tree().process_frame
	
	func test_given_bullet3d_when_created_then_has_correct_collision_layers():
		# Given/When: Bullet3D created
		# Then: Collision layers configured correctly
		assert_eq(bullet3d.collision_layer, 4, "Should be on layer 3 (bit 2 = value 4)")
		assert_eq(bullet3d.collision_mask, 38, "Should collide with layers 2|4|5 (2+4+32 = 38)")
	
	func test_given_bullet3d_when_area_entered_signal_then_connected():
		# Given: Bullet3D with signal
		watch_signals(bullet3d)
		
		# When: Checking for area_entered signal
		# Then: Signal should exist
		assert_has_signal(bullet3d, "area_entered", "Should have area_entered signal")
	
	func test_given_bullet3d_when_hits_target_then_emits_destroyed():
		# Given: Bullet3D initialized
		bullet3d.initialize(Vector3(5.0, 0.25, 5.0), Vector3(0, 0, -1), 1, 1, false)
		watch_signals(bullet3d)
		
		# When: Bullet destroys
		bullet3d._destroy()
		
		# Then: destroyed signal emitted
		assert_signal_emitted(bullet3d, "destroyed", "Should emit destroyed signal")

## Feature: Bullet3D Lifetime Management
class TestBullet3DLifetime:
	extends GutTest
	
	var bullet3d
	
	func before_each():
		var Bullet3D = load("res://src/entities/bullet3d.gd")
		bullet3d = Bullet3D.new()
		add_child_autofree(bullet3d)
		await get_tree().process_frame
	
	func test_given_bullet3d_when_out_of_bounds_then_destroys():
		# Given: Bullet3D near edge of map moving outward
		bullet3d.initialize(Vector3(25.5, 0.25, 5.0), Vector3(1, 0, 0), 1, 1, false)
		
		# When: Physics processes multiple frames (moves out of bounds)
		for i in range(30):  # More frames to ensure out of bounds
			bullet3d._physics_process(1.0/60.0)
		
		# Then: Bullet should be inactive (destroyed)
		assert_false(bullet3d.is_active, "Bullet should be destroyed when out of bounds")
	
	func test_given_bullet3d_when_destroyed_then_is_active_false():
		# Given: Active bullet3d
		bullet3d.initialize(Vector3(5.0, 0.25, 5.0), Vector3(0, 0, -1), 1, 1, false)
		assert_true(bullet3d.is_active, "Should start active")
		
		# When: Destroyed
		bullet3d._destroy()
		
		# Then: Is no longer active
		assert_false(bullet3d.is_active, "Should be inactive after destroy")
	
	func test_given_bullet3d_when_destroyed_twice_then_no_error():
		# Given: Bullet3D initialized
		bullet3d.initialize(Vector3(5.0, 0.25, 5.0), Vector3(0, 0, -1), 1, 1, false)
		
		# When: Destroyed twice
		bullet3d._destroy()
		bullet3d._destroy()
		
		# Then: No error, still inactive
		assert_false(bullet3d.is_active, "Should remain inactive")

## Feature: Bullet3D Grace Period
class TestBullet3DGracePeriod:
	extends GutTest
	
	var bullet3d
	
	func before_each():
		var Bullet3D = load("res://src/entities/bullet3d.gd")
		bullet3d = Bullet3D.new()
		add_child_autofree(bullet3d)
		await get_tree().process_frame
	
	func test_given_bullet3d_when_initialized_then_has_grace_timer():
		# Given/When: Bullet3D initialized
		bullet3d.initialize(Vector3(5.0, 0.25, 5.0), Vector3(0, 0, -1), 1, 1, false)
		
		# Then: Grace timer set
		assert_true("grace_timer" in bullet3d, "Should have grace_timer property")
		assert_gt(bullet3d.grace_timer, 0.0, "Grace timer should be > 0 after init")
	
	func test_given_bullet3d_with_grace_timer_when_physics_processed_then_timer_decrements():
		# Given: Bullet3D with grace timer
		bullet3d.initialize(Vector3(5.0, 0.25, 5.0), Vector3(0, 0, -1), 1, 1, false)
		var initial_timer = bullet3d.grace_timer
		
		# When: Physics processes
		bullet3d._physics_process(1.0/60.0)
		
		# Then: Timer decremented
		assert_lt(bullet3d.grace_timer, initial_timer, "Grace timer should decrement")

## Feature: Bullet3D Damage Properties
class TestBullet3DDamage:
	extends GutTest
	
	var bullet3d
	
	func before_each():
		var Bullet3D = load("res://src/entities/bullet3d.gd")
		bullet3d = Bullet3D.new()
		add_child_autofree(bullet3d)
		await get_tree().process_frame
	
	func test_given_bullet3d_normal_level_when_created_then_penetration_is_one():
		# Given/When: Normal level bullet
		bullet3d.initialize(Vector3(5.0, 0.25, 5.0), Vector3(0, 0, -1), 1, 1, false)
		
		# Then: Penetration is 1
		assert_eq(bullet3d.penetration, 1, "Normal bullet should have penetration=1")
	
	func test_given_bullet3d_enhanced_level_when_created_then_penetration_is_two():
		# Given/When: Enhanced level bullet
		bullet3d.initialize(Vector3(5.0, 0.25, 5.0), Vector3(0, 0, -1), 1, 2, false)
		
		# Then: Penetration is 2
		assert_eq(bullet3d.penetration, 2, "Enhanced bullet should have penetration=2")
	
	func test_given_bullet3d_super_level_when_created_then_penetration_is_three():
		# Given/When: Super level bullet
		bullet3d.initialize(Vector3(5.0, 0.25, 5.0), Vector3(0, 0, -1), 1, 3, false)
		
		# Then: Penetration is 3
		assert_eq(bullet3d.penetration, 3, "Super bullet should have penetration=3")
