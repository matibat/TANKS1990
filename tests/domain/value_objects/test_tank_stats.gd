extends GutTest

# BDD Tests for TankStats Value Object
# TankStats represents tank capabilities and attributes

const TankStats = preload("res://src/domain/value_objects/tank_stats.gd")

func test_given_stats_when_created_then_stores_all_values():
	# Given/When: Create tank stats
	var stats = TankStats.create(2, 6, 1, 2)
	
	# Then: All values are stored correctly
	assert_eq(stats.speed, 2)
	assert_eq(stats.fire_rate, 6)
	assert_eq(stats.armor, 1)
	assert_eq(stats.bullet_speed, 2)

func test_given_player_default_when_created_then_returns_standard_player_stats():
	# Given/When: Create player default stats
	var stats = TankStats.player_default()
	
	# Then: Has player-appropriate values
	assert_eq(stats.speed, 2)
	assert_eq(stats.fire_rate, 6)
	assert_eq(stats.armor, 1)
	assert_eq(stats.bullet_speed, 2)

func test_given_enemy_basic_when_created_then_returns_basic_enemy_stats():
	# Given/When: Create basic enemy stats
	var stats = TankStats.enemy_basic()
	
	# Then: Has basic enemy values (slow, weak)
	assert_eq(stats.speed, 1)
	assert_eq(stats.fire_rate, 10)
	assert_eq(stats.armor, 1)
	assert_eq(stats.bullet_speed, 2)

func test_given_enemy_fast_when_created_then_returns_fast_enemy_stats():
	# Given/When: Create fast enemy stats
	var stats = TankStats.enemy_fast()
	
	# Then: Has fast enemy values (higher speed)
	assert_eq(stats.speed, 3)
	assert_eq(stats.fire_rate, 8)
	assert_eq(stats.armor, 1)
	assert_eq(stats.bullet_speed, 3)

func test_given_enemy_armored_when_created_then_returns_armored_enemy_stats():
	# Given/When: Create armored enemy stats
	var stats = TankStats.enemy_armored()
	
	# Then: Has armored enemy values (higher armor, slower fire)
	assert_eq(stats.speed, 1)
	assert_eq(stats.fire_rate, 14)
	assert_eq(stats.armor, 4)
	assert_eq(stats.bullet_speed, 2)

func test_given_stats_when_created_then_speed_is_positive():
	# Given/When: Create any stats
	var stats = TankStats.create(2, 6, 1, 2)
	
	# Then: Speed is positive
	assert_gt(stats.speed, 0, "Speed must be positive")

func test_given_stats_when_created_then_fire_rate_is_positive():
	# Given/When: Create any stats
	var stats = TankStats.create(2, 6, 1, 2)
	
	# Then: Fire rate is positive
	assert_gt(stats.fire_rate, 0, "Fire rate must be positive")

func test_given_stats_when_created_then_armor_is_non_negative():
	# Given/When: Create any stats
	var stats = TankStats.create(2, 6, 1, 2)
	
	# Then: Armor is non-negative
	assert_true(stats.armor >= 0, "Armor must be non-negative")

func test_given_stats_when_created_then_bullet_speed_is_positive():
	# Given/When: Create any stats
	var stats = TankStats.create(2, 6, 1, 2)
	
	# Then: Bullet speed is positive
	assert_gt(stats.bullet_speed, 0, "Bullet speed must be positive")

func test_given_different_enemy_types_when_compared_then_have_different_stats():
	# Given: Different enemy types
	var basic = TankStats.enemy_basic()
	var fast = TankStats.enemy_fast()
	var armored = TankStats.enemy_armored()
	
	# When/Then: They have different stat combinations
	assert_true(basic.speed != fast.speed or basic.fire_rate != fast.fire_rate)
	assert_true(basic.armor != armored.armor or basic.speed != armored.speed)
