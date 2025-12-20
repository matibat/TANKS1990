extends GutTest

# BDD Tests for Health Value Object
# Health represents entity hit points with validation

const Health = preload("res://src/domain/value_objects/health.gd")

func test_given_current_and_max_when_created_then_stores_values():
	# Given/When: Create health with current and max
	var health = Health.create(2, 3)
	
	# Then: Values are stored correctly
	assert_eq(health.current, 2)
	assert_eq(health.maximum, 3)

func test_given_max_health_when_full_called_then_returns_full_health():
	# Given/When: Create full health
	var health = Health.full(5)
	
	# Then: Current equals maximum
	assert_eq(health.current, 5)
	assert_eq(health.maximum, 5)

func test_given_positive_health_when_is_alive_then_returns_true():
	# Given: Health with current > 0
	var health = Health.create(1, 3)
	
	# When/Then: Is alive
	assert_true(health.is_alive())

func test_given_zero_health_when_is_alive_then_returns_false():
	# Given: Health with current = 0
	var health = Health.create(0, 3)
	
	# When/Then: Is not alive
	assert_false(health.is_alive())

func test_given_health_when_takes_damage_then_current_decreases():
	# Given: Health at 3/5
	var health = Health.create(3, 5)
	
	# When: Take 1 damage
	var new_health = health.take_damage(1)
	
	# Then: Current is 2
	assert_eq(new_health.current, 2)
	assert_eq(new_health.maximum, 5)

func test_given_health_when_takes_fatal_damage_then_current_becomes_zero():
	# Given: Health at 2/5
	var health = Health.create(2, 5)
	
	# When: Take 5 damage (more than current)
	var new_health = health.take_damage(5)
	
	# Then: Current is 0 (not negative)
	assert_eq(new_health.current, 0)
	assert_eq(new_health.maximum, 5)

func test_given_health_when_healed_then_current_increases():
	# Given: Health at 2/5
	var health = Health.create(2, 5)
	
	# When: Heal 2 points
	var new_health = health.heal(2)
	
	# Then: Current is 4
	assert_eq(new_health.current, 4)
	assert_eq(new_health.maximum, 5)

func test_given_health_when_healed_beyond_max_then_capped_at_maximum():
	# Given: Health at 3/5
	var health = Health.create(3, 5)
	
	# When: Heal 5 points (more than needed)
	var new_health = health.heal(5)
	
	# Then: Current is capped at maximum
	assert_eq(new_health.current, 5)
	assert_eq(new_health.maximum, 5)

func test_given_invalid_health_when_created_then_fails():
	# Given/When: Try to create with current > maximum
	# Then: Should fail (we'll use assertion error)
	# Note: In GDScript, we can check if assertion fails
	var health = Health.create(5, 3)
	# Implementation should clamp or validate this
	assert_true(health.current <= health.maximum, "Current should not exceed maximum")

func test_given_negative_current_when_created_then_clamped_to_zero():
	# Given/When: Try to create with negative current
	var health = Health.create(-1, 5)
	
	# Then: Current is clamped to 0
	assert_eq(health.current, 0)

func test_given_health_when_take_damage_called_then_original_unchanged():
	# Given: A health value
	var health = Health.create(3, 5)
	
	# When: Take damage
	var new_health = health.take_damage(1)
	
	# Then: Original unchanged (immutability)
	assert_eq(health.current, 3)
	assert_eq(new_health.current, 2)

func test_given_health_when_heal_called_then_original_unchanged():
	# Given: A health value
	var health = Health.create(2, 5)
	
	# When: Heal
	var new_health = health.heal(1)
	
	# Then: Original unchanged (immutability)
	assert_eq(health.current, 2)
	assert_eq(new_health.current, 3)
