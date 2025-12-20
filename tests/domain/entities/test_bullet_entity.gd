extends GutTest

## BDD Tests for BulletEntity
## Test-first approach: Write behavior tests before implementation

const BulletEntity = preload("res://src/domain/entities/bullet_entity.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")
const Velocity = preload("res://src/domain/value_objects/velocity.gd")

## Test: Bullet Creation and Identity
func test_given_bullet_parameters_when_created_then_has_correct_properties():
	# Given: Bullet creation parameters
	var bullet_id = "bullet_1"
	var owner_id = "tank_1"
	var position = Position.create(5, 5)
	var direction = Direction.create(Direction.UP)
	var speed = 4
	var damage = 1
	
	# When: Bullet is created
	var bullet = BulletEntity.create(bullet_id, owner_id, position, direction, speed, damage)
	
	# Then: Bullet has correct properties
	assert_not_null(bullet, "Bullet should be created")
	assert_eq(bullet.id, bullet_id, "Bullet should have correct ID")
	assert_eq(bullet.owner_id, owner_id, "Bullet should have correct owner ID")
	assert_true(bullet.position.equals(position), "Bullet should have correct position")
	assert_eq(bullet.direction.value, direction.value, "Bullet should have correct direction")
	assert_eq(bullet.damage, damage, "Bullet should have correct damage")
	assert_true(bullet.is_active, "Bullet should be active when created")

## Test: Bullet Movement
func test_given_bullet_when_gets_next_position_then_returns_correct_position():
	# Given: A bullet moving UP with speed 4
	var bullet = BulletEntity.create("b1", "t1", Position.create(5, 5),
									 Direction.create(Direction.UP), 4, 1)
	
	# When: Getting next position
	var next_pos = bullet.get_next_position()
	
	# Then: Next position is 4 tiles up
	assert_eq(next_pos.x, 5, "X position should be same")
	assert_eq(next_pos.y, 1, "Y position should be 4 less (4 tiles up)")

func test_given_bullet_when_moves_forward_then_position_updated():
	# Given: A bullet at position (5, 5)
	var bullet = BulletEntity.create("b1", "t1", Position.create(5, 5),
									 Direction.create(Direction.RIGHT), 3, 1)
	var old_x = bullet.position.x
	
	# When: Bullet moves forward
	bullet.move_forward()
	
	# Then: Bullet position is updated by velocity
	assert_eq(bullet.position.x, old_x + 3, "X position should increase by speed")
	assert_eq(bullet.position.y, 5, "Y position should stay same")

func test_given_bullet_moving_down_when_moves_forward_then_position_increases():
	# Given: A bullet moving DOWN with speed 2
	var bullet = BulletEntity.create("b1", "t1", Position.create(10, 10),
									 Direction.create(Direction.DOWN), 2, 1)
	
	# When: Bullet moves forward
	bullet.move_forward()
	
	# Then: Y position increases by 2
	assert_eq(bullet.position.x, 10, "X position should stay same")
	assert_eq(bullet.position.y, 12, "Y position should increase by 2")

## Test: Bullet Activation
func test_given_active_bullet_when_deactivated_then_not_active():
	# Given: An active bullet
	var bullet = BulletEntity.create("b1", "t1", Position.create(5, 5),
									 Direction.create(Direction.UP), 4, 1)
	assert_true(bullet.is_active, "Bullet should start active")
	
	# When: Bullet is deactivated
	bullet.deactivate()
	
	# Then: Bullet is not active
	assert_false(bullet.is_active, "Bullet should be deactivated")

## Test: Bullet Velocity
func test_given_bullet_when_created_then_has_correct_velocity():
	# Given/When: Creating a bullet moving LEFT with speed 3
	var bullet = BulletEntity.create("b1", "t1", Position.create(10, 10),
									 Direction.create(Direction.LEFT), 3, 1)
	
	# Then: Velocity matches direction and speed
	assert_eq(bullet.velocity.dx, -3, "Velocity dx should be -3 (left)")
	assert_eq(bullet.velocity.dy, 0, "Velocity dy should be 0")

func test_given_bullet_moving_up_when_created_then_velocity_correct():
	# Given/When: Creating a bullet moving UP with speed 5
	var bullet = BulletEntity.create("b1", "t1", Position.create(5, 5),
									 Direction.create(Direction.UP), 5, 1)
	
	# Then: Velocity matches upward movement
	assert_eq(bullet.velocity.dx, 0, "Velocity dx should be 0")
	assert_eq(bullet.velocity.dy, -5, "Velocity dy should be -5 (up)")

## Test: Bullet Serialization
func test_given_bullet_when_serialized_then_can_deserialize():
	# Given: A bullet with specific state
	var bullet = BulletEntity.create("b1", "t1", Position.create(5, 5),
									 Direction.create(Direction.RIGHT), 4, 2)
	bullet.move_forward()
	bullet.deactivate()
	
	# When: Bullet is serialized and deserialized
	var dict = bullet.to_dict()
	var restored_bullet = BulletEntity.from_dict(dict)
	
	# Then: Restored bullet has same state
	assert_eq(restored_bullet.id, bullet.id, "ID should match")
	assert_eq(restored_bullet.owner_id, bullet.owner_id, "Owner ID should match")
	assert_true(restored_bullet.position.equals(bullet.position), "Position should match")
	assert_eq(restored_bullet.direction.value, bullet.direction.value, "Direction should match")
	assert_eq(restored_bullet.velocity.dx, bullet.velocity.dx, "Velocity dx should match")
	assert_eq(restored_bullet.velocity.dy, bullet.velocity.dy, "Velocity dy should match")
	assert_eq(restored_bullet.damage, bullet.damage, "Damage should match")
	assert_eq(restored_bullet.is_active, bullet.is_active, "Active state should match")

## Test: Bullet Damage Values
func test_given_bullet_with_damage_2_when_created_then_has_correct_damage():
	# Given/When: Creating a bullet with damage 2
	var bullet = BulletEntity.create("b1", "t1", Position.create(5, 5),
									 Direction.create(Direction.UP), 4, 2)
	
	# Then: Bullet has damage 2
	assert_eq(bullet.damage, 2, "Bullet should have damage 2")

## Test: Multiple Bullets with Different Owners
func test_given_bullets_from_different_tanks_when_created_then_have_correct_owners():
	# Given/When: Creating bullets from different tanks
	var bullet1 = BulletEntity.create("b1", "tank1", Position.create(5, 5),
									  Direction.create(Direction.UP), 4, 1)
	var bullet2 = BulletEntity.create("b2", "tank2", Position.create(10, 10),
									  Direction.create(Direction.DOWN), 3, 1)
	
	# Then: Bullets have correct owners
	assert_eq(bullet1.owner_id, "tank1", "Bullet 1 should be owned by tank1")
	assert_eq(bullet2.owner_id, "tank2", "Bullet 2 should be owned by tank2")
	assert_ne(bullet1.id, bullet2.id, "Bullets should have different IDs")
