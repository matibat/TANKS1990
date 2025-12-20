extends GutTest

## BDD Tests for BaseEntity
## Test-first approach: Write behavior tests before implementation

const BaseEntity = preload("res://src/domain/entities/base_entity.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const Health = preload("res://src/domain/value_objects/health.gd")

## Test: Base Creation and Identity
func test_given_base_parameters_when_created_then_has_correct_properties():
	# Given: Base creation parameters
	var base_id = "base_1"
	var position = Position.create(13, 24)
	var health_value = 1
	
	# When: Base is created
	var base = BaseEntity.create(base_id, position, health_value)
	
	# Then: Base has correct properties
	assert_not_null(base, "Base should be created")
	assert_eq(base.id, base_id, "Base should have correct ID")
	assert_true(base.position.equals(position), "Base should have correct position")
	assert_eq(base.health.current, health_value, "Base should have correct health")
	assert_eq(base.health.maximum, health_value, "Base maximum health should match")
	assert_true(base.is_alive(), "Base should be alive when created")
	assert_false(base.is_destroyed, "Base should not be destroyed initially")

## Test: Base Health and Damage
func test_given_base_with_health_when_takes_damage_then_health_decreases():
	# Given: A base with 3 health
	var base = BaseEntity.create("base_1", Position.create(13, 24), 3)
	var initial_health = base.health.current
	
	# When: Base takes 1 damage
	base.take_damage(1)
	
	# Then: Health decreases by 1
	assert_eq(base.health.current, initial_health - 1, "Health should decrease by damage amount")
	assert_true(base.is_alive(), "Base should still be alive")
	assert_false(base.is_destroyed, "Base should not be destroyed yet")

func test_given_base_when_takes_fatal_damage_then_dies():
	# Given: A base with 1 health
	var base = BaseEntity.create("base_1", Position.create(13, 24), 1)
	
	# When: Base takes fatal damage
	base.take_damage(1)
	
	# Then: Base is dead and destroyed
	assert_false(base.is_alive(), "Base should be dead after fatal damage")
	assert_eq(base.health.current, 0, "Health should be zero")
	assert_true(base.is_destroyed, "Base should be marked as destroyed")

func test_given_base_with_health_when_takes_excessive_damage_then_dies():
	# Given: A base with 2 health
	var base = BaseEntity.create("base_1", Position.create(13, 24), 2)
	
	# When: Base takes excessive damage (more than health)
	base.take_damage(5)
	
	# Then: Base is dead
	assert_false(base.is_alive(), "Base should be dead")
	assert_eq(base.health.current, 0, "Health should be zero (not negative)")
	assert_true(base.is_destroyed, "Base should be destroyed")

## Test: Base Position
func test_given_base_when_created_then_has_correct_position():
	# Given/When: Creating a base at specific position
	var position = Position.create(13, 24)
	var base = BaseEntity.create("base_1", position, 1)
	
	# Then: Base is at correct position
	assert_eq(base.position.x, 13, "Base X position should be correct")
	assert_eq(base.position.y, 24, "Base Y position should be correct")

## Test: Base Serialization
func test_given_base_when_serialized_then_can_deserialize():
	# Given: A base with specific state
	var base = BaseEntity.create("base_1", Position.create(13, 24), 3)
	base.take_damage(1)
	
	# When: Base is serialized and deserialized
	var dict = base.to_dict()
	var restored_base = BaseEntity.from_dict(dict)
	
	# Then: Restored base has same state
	assert_eq(restored_base.id, base.id, "ID should match")
	assert_true(restored_base.position.equals(base.position), "Position should match")
	assert_eq(restored_base.health.current, base.health.current, "Health current should match")
	assert_eq(restored_base.health.maximum, base.health.maximum, "Health maximum should match")
	assert_eq(restored_base.is_destroyed, base.is_destroyed, "Destroyed state should match")

func test_given_destroyed_base_when_serialized_then_can_deserialize():
	# Given: A destroyed base
	var base = BaseEntity.create("base_1", Position.create(13, 24), 1)
	base.take_damage(1) # Destroy it
	
	# When: Base is serialized and deserialized
	var dict = base.to_dict()
	var restored_base = BaseEntity.from_dict(dict)
	
	# Then: Restored base is also destroyed
	assert_false(restored_base.is_alive(), "Restored base should be dead")
	assert_true(restored_base.is_destroyed, "Restored base should be destroyed")

## Test: Multiple Bases
func test_given_multiple_bases_when_created_then_have_unique_ids():
	# Given/When: Creating multiple bases
	var base1 = BaseEntity.create("base_1", Position.create(13, 24), 1)
	var base2 = BaseEntity.create("base_2", Position.create(14, 24), 1)
	
	# Then: Bases have unique IDs
	assert_ne(base1.id, base2.id, "Bases should have different IDs")

## Test: Base with Different Health Values
func test_given_base_with_different_health_when_created_then_has_correct_health():
	# Given/When: Creating bases with different health values
	var base1 = BaseEntity.create("base_1", Position.create(13, 24), 1)
	var base2 = BaseEntity.create("base_2", Position.create(14, 24), 5)
	
	# Then: Bases have correct health
	assert_eq(base1.health.current, 1, "Base 1 should have 1 health")
	assert_eq(base2.health.current, 5, "Base 2 should have 5 health")
