extends GutTest
## BDD-style tests for Entity Events
## 
## Feature: Tank Lifecycle Events
## As a developer, I want to track tank spawning and destruction
## So that replay accurately represents entity state changes

# Scenario: Tank spawned events
class TestTankSpawnedEvent:
	extends GutTest
	
	func test_given_player_tank_when_created_then_properties_set():
		# Given
		var event = TankSpawnedEvent.new()
		event.tank_id = 1
		event.tank_type = "player"
		event.position = Vector2(100, 200)
		event.is_player = true
		
		# Then
		assert_eq(event.tank_id, 1)
		assert_eq(event.tank_type, "player")
		assert_eq(event.position, Vector2(100, 200))
		assert_true(event.is_player)
	
	func test_given_enemy_tank_when_created_then_player_false():
		# Given
		var event = TankSpawnedEvent.new()
		event.tank_id = 5
		event.tank_type = "basic"
		event.position = Vector2(50, 0)
		event.is_player = false
		
		# Then
		assert_false(event.is_player)
		assert_eq(event.tank_type, "basic")
	
	func test_given_tank_spawned_when_serialized_then_dict_complete():
		# Given
		var event = TankSpawnedEvent.new()
		event.frame = 10
		event.tank_id = 3
		event.tank_type = "fast"
		event.position = Vector2(150, 50)
		event.is_player = false
		
		# When
		var dict = event.to_dict()
		
		# Then
		assert_eq(dict["type"], "TankSpawned")
		assert_eq(dict["frame"], 10)
		assert_eq(dict["tank_id"], 3)
		assert_eq(dict["tank_type"], "fast")
		assert_eq(dict["position"]["x"], 150)
		assert_eq(dict["position"]["y"], 50)
		assert_false(dict["is_player"])
	
	func test_given_serialized_when_deserialized_then_event_restored():
		# Given
		var original = TankSpawnedEvent.new()
		original.frame = 20
		original.tank_id = 7
		original.tank_type = "armored"
		original.position = Vector2(200, 100)
		original.is_player = false
		var dict = original.to_dict()
		
		# When
		var restored = TankSpawnedEvent.from_dict(dict)
		
		# Then
		assert_eq(restored.frame, 20)
		assert_eq(restored.tank_id, 7)
		assert_eq(restored.tank_type, "armored")
		assert_eq(restored.position, Vector2(200, 100))
		assert_false(restored.is_player)


# Scenario: Tank destroyed events
class TestTankDestroyedEvent:
	extends GutTest
	
	func test_given_tank_destroyed_when_created_then_properties_set():
		# Given
		var event = TankDestroyedEvent.new()
		event.tank_id = 5
		event.destroyed_by_id = 1
		event.position = Vector2(150, 150)
		event.was_player = false
		event.score_value = 100
		
		# Then
		assert_eq(event.tank_id, 5)
		assert_eq(event.destroyed_by_id, 1)
		assert_eq(event.score_value, 100)
		assert_false(event.was_player)
	
	func test_given_player_destroyed_when_created_then_was_player_true():
		# Given
		var event = TankDestroyedEvent.new()
		event.tank_id = 1
		event.was_player = true
		event.score_value = 0
		
		# Then
		assert_true(event.was_player)
		assert_eq(event.score_value, 0)


# Scenario: Bullet fired events
class TestBulletFiredEvent:
	extends GutTest
	
	func test_given_bullet_fired_when_created_then_properties_set():
		# Given
		var event = BulletFiredEvent.new()
		event.bullet_id = 10
		event.tank_id = 1
		event.position = Vector2(100, 100)
		event.direction = Vector2(0, -1)
		event.bullet_level = 2
		
		# Then
		assert_eq(event.bullet_id, 10)
		assert_eq(event.tank_id, 1)
		assert_eq(event.direction, Vector2(0, -1))
		assert_eq(event.bullet_level, 2)
	
	func test_given_bullet_when_serialized_then_dict_complete():
		# Given
		var event = BulletFiredEvent.new()
		event.frame = 50
		event.bullet_id = 15
		event.tank_id = 3
		event.position = Vector2(200, 200)
		event.direction = Vector2(1, 0)
		event.bullet_level = 1
		
		# When
		var dict = event.to_dict()
		
		# Then
		assert_eq(dict["type"], "BulletFired")
		assert_eq(dict["bullet_id"], 15)
		assert_eq(dict["tank_id"], 3)
		assert_eq(dict["direction"]["x"], 1)
		assert_eq(dict["direction"]["y"], 0)
		assert_eq(dict["bullet_level"], 1)
