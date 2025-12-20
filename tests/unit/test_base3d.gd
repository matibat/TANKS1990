extends GutTest
## BDD tests for Base3D entity - 3D base/eagle implementation with StaticBody3D

var base3d: StaticBody3D
var event_bus: Node

const Vector3Helpers = preload("res://src/utils/vector3_helpers.gd")

func before_each():
	event_bus = EventBus
	event_bus.start_recording()

func after_each():
	event_bus.stop_recording()

## Feature: Base3D Instantiation
class TestBase3DInstantiation:
	extends GutTest
	
	var base3d
	
	func test_given_new_base3d_when_created_then_is_static_body_3d():
		# Given/When: Create Base3D instance
		var Base3D = load("res://src/entities/base3d.gd")
		base3d = Base3D.new()
		add_child_autofree(base3d)
		
		# Then: Should be StaticBody3D
		assert_true(base3d is StaticBody3D, "Base3D should extend StaticBody3D")
	
	func test_given_new_base3d_when_created_then_has_vector3_position():
		# Given/When: Create Base3D instance
		var Base3D = load("res://src/entities/base3d.gd")
		base3d = Base3D.new()
		add_child_autofree(base3d)
		base3d.global_position = Vector3(6.5, 0.0, 12.5)
		
		# Then: Position should be Vector3
		assert_typeof(base3d.global_position, TYPE_VECTOR3, "Position should be Vector3")
		assert_almost_eq(base3d.global_position.y, 0.0, 0.01, "Y should be 0 (ground plane)")
	
	func test_given_new_base3d_when_created_then_has_collision_shape_3d():
		# Given/When: Create Base3D with collision
		var Base3D = load("res://src/entities/base3d.gd")
		base3d = Base3D.new()
		add_child_autofree(base3d)
		await get_tree().process_frame  # Wait for _ready()
		
		# Then: Should have CollisionShape3D child
		var collision_shape = base3d.get_node_or_null("CollisionShape3D")
		assert_not_null(collision_shape, "Should have CollisionShape3D")
		assert_true(collision_shape is CollisionShape3D, "Should be CollisionShape3D type")
	
	func test_given_new_base3d_when_created_then_collision_is_box_shape_3d():
		# Given/When: Create Base3D with collision
		var Base3D = load("res://src/entities/base3d.gd")
		base3d = Base3D.new()
		add_child_autofree(base3d)
		await get_tree().process_frame  # Wait for _ready()
		
		# Then: Collision shape should be BoxShape3D
		var collision_shape = base3d.get_node_or_null("CollisionShape3D")
		assert_not_null(collision_shape, "Should have CollisionShape3D")
		if collision_shape and collision_shape.shape:
			assert_true(collision_shape.shape is BoxShape3D, "Shape should be BoxShape3D")
			var box = collision_shape.shape as BoxShape3D
			# Base is ~1x1x1 units
			assert_almost_eq(box.size.x, 1.0, 0.3, "Width should be ~1.0 units")
			assert_almost_eq(box.size.z, 1.0, 0.3, "Depth should be ~1.0 units")

## Feature: Base3D Health System
class TestBase3DHealth:
	extends GutTest
	
	var base3d
	
	func before_each():
		var Base3D = load("res://src/entities/base3d.gd")
		base3d = Base3D.new()
		add_child_autofree(base3d)
		await get_tree().process_frame
	
	func test_given_base3d_when_created_then_has_default_health():
		# Given/When: Base3D created
		# Then: Has default health
		assert_true("health" in base3d, "Should have health property")
		assert_eq(base3d.health, 1, "Default health should be 1")
	
	func test_given_base3d_when_created_then_has_max_health():
		# Then: Has max_health property
		assert_true("max_health" in base3d, "Should have max_health property")
		assert_eq(base3d.max_health, 1, "Default max_health should be 1")
	
	func test_given_base3d_when_created_then_not_destroyed():
		# Then: Should not be destroyed initially
		assert_true("is_destroyed" in base3d, "Should have is_destroyed property")
		assert_false(base3d.is_destroyed, "Should not be destroyed initially")

## Feature: Base3D Damage System
class TestBase3DDamage:
	extends GutTest
	
	var base3d
	
	func before_each():
		var Base3D = load("res://src/entities/base3d.gd")
		base3d = Base3D.new()
		add_child_autofree(base3d)
		await get_tree().process_frame
	
	func test_given_base3d_when_takes_damage_then_health_decreases():
		# Given: Base3D with full health
		var initial_health = base3d.health
		
		# When: Takes damage
		base3d.take_damage(1)
		
		# Then: Health decreases
		assert_eq(base3d.health, initial_health - 1, "Health should decrease by 1")
	
	func test_given_base3d_when_health_zero_then_is_destroyed():
		# Given: Base3D with 1 health
		assert_eq(base3d.health, 1)
		
		# When: Takes fatal damage
		base3d.take_damage(1)
		
		# Then: Is destroyed
		assert_eq(base3d.health, 0, "Health should be 0")
		assert_true(base3d.is_destroyed, "Should be marked as destroyed")
	
	func test_given_base3d_destroyed_when_takes_more_damage_then_ignores():
		# Given: Destroyed base
		base3d.take_damage(1)
		assert_true(base3d.is_destroyed)
		var health_after_death = base3d.health
		
		# When: Takes more damage
		base3d.take_damage(1)
		
		# Then: Health unchanged
		assert_eq(base3d.health, health_after_death, "Health should not decrease further")

## Feature: Base3D Signals
class TestBase3DSignals:
	extends GutTest
	
	var base3d
	
	func before_each():
		var Base3D = load("res://src/entities/base3d.gd")
		base3d = Base3D.new()
		add_child_autofree(base3d)
		await get_tree().process_frame
	
	func test_given_base3d_when_created_then_has_destroyed_signal():
		# Given/When: Base3D created
		# Then: Has destroyed signal
		assert_has_signal(base3d, "destroyed", "Should have destroyed signal")
	
	func test_given_base3d_when_created_then_has_damaged_signal():
		# Then: Has damaged signal
		assert_has_signal(base3d, "damaged", "Should have damaged signal")
	
	func test_given_base3d_when_takes_damage_then_emits_damaged():
		# Given: Base3D with signal watching
		watch_signals(base3d)
		
		# When: Takes damage
		base3d.take_damage(1)
		
		# Then: damaged signal emitted
		assert_signal_emitted(base3d, "damaged", "Should emit damaged signal")
	
	func test_given_base3d_when_destroyed_then_emits_destroyed():
		# Given: Base3D with signal watching
		watch_signals(base3d)
		
		# When: Takes fatal damage
		base3d.take_damage(1)
		
		# Then: destroyed signal emitted
		assert_signal_emitted(base3d, "destroyed", "Should emit destroyed signal")

## Feature: Base3D Collision Configuration
class TestBase3DCollision:
	extends GutTest
	
	var base3d
	
	func before_each():
		var Base3D = load("res://src/entities/base3d.gd")
		base3d = Base3D.new()
		add_child_autofree(base3d)
		await get_tree().process_frame
	
	func test_given_base3d_when_created_then_has_correct_collision_layers():
		# Given/When: Base3D created
		# Then: Collision layers configured correctly
		# Layer 5 (Base) = bit 4 = value 16 (2^4)
		assert_eq(base3d.collision_layer, 16, "Should be on layer 5 (bit 4 = value 16)")
		# Mask: Enemy(2) | Projectiles(3) = bits 1,2 = 2+4 = 6
		assert_eq(base3d.collision_mask, 6, "Should collide with layers 2|3 (2+4 = 6)")

## Feature: Base3D Positioning
class TestBase3DPositioning:
	extends GutTest
	
	var base3d
	
	func before_each():
		var Base3D = load("res://src/entities/base3d.gd")
		base3d = Base3D.new()
		add_child_autofree(base3d)
		await get_tree().process_frame
	
	func test_given_base3d_when_ready_then_positioned_at_bottom_center():
		# Given/When: Base3D ready
		# Then: Position at bottom center of map
		# Tile (13, 25) center in 3D = (6.5, 0, 12.5)
		var expected_pos = Vector3(6.5, 0.0, 12.5)
		assert_true(Vector3Helpers.vec3_approx_equal(base3d.global_position, expected_pos, 0.5), 
			"Base should be at bottom center ~(6.5, 0, 12.5)")
	
	func test_given_base3d_when_positioned_then_y_is_ground_level():
		# Given/When: Base3D positioned
		# Then: Y coordinate is 0 (ground plane)
		assert_almost_eq(base3d.global_position.y, 0.0, 0.1, "Y should be at ground level (0)")

## Feature: Base3D Bullet Collision
class TestBase3DBulletCollision:
	extends GutTest
	
	var base3d
	
	func before_each():
		var Base3D = load("res://src/entities/base3d.gd")
		base3d = Base3D.new()
		add_child_autofree(base3d)
		await get_tree().process_frame
	
	func test_given_base3d_when_player_bullet_hits_then_no_damage():
		# Given: Base3D with full health
		var Bullet3D = load("res://src/entities/bullet3d.gd")
		var bullet = Bullet3D.new()
		bullet.owner_type = Bullet3D.OwnerType.PLAYER
		add_child_autofree(bullet)
		await get_tree().process_frame
		
		var initial_health = base3d.health
		
		# When: Player bullet hits base
		if base3d.has_method("_on_body_entered"):
			base3d._on_body_entered(bullet)
		
		# Then: Base takes no damage
		assert_eq(base3d.health, initial_health, "Base should not take damage from player bullets")
		assert_false(base3d.is_destroyed, "Base should not be destroyed by player bullets")
	
	func test_given_base3d_when_enemy_bullet_hits_then_takes_damage():
		# Given: Base3D with full health
		var Bullet3D = load("res://src/entities/bullet3d.gd")
		var bullet = Bullet3D.new()
		bullet.owner_type = Bullet3D.OwnerType.ENEMY
		add_child_autofree(bullet)
		await get_tree().process_frame
		
		var initial_health = base3d.health
		
		# When: Enemy bullet hits base
		if base3d.has_method("_on_body_entered"):
			base3d._on_body_entered(bullet)
		
		# Then: Base takes damage
		assert_lt(base3d.health, initial_health, "Base should take damage from enemy bullets")
