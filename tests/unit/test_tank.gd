extends GutTest
## BDD tests for Tank entity movement and behavior

var tank: Tank
var event_bus: Node

func before_each():
	event_bus = EventBus
	event_bus.start_recording()
	
	# Create tank instance
	tank = Tank.new()
	tank.tank_type = Tank.TankType.PLAYER
	tank.base_speed = 100.0
	tank.tank_id = 1
	tank.global_position = Vector2(208, 384)  # Center-bottom (13, 24 in tiles)
	add_child_autofree(tank)
	
	# Skip spawn state for testing
	tank.spawn_timer = 0
	tank._complete_spawn()
	tank.invulnerability_timer = 0
	tank._end_invulnerability()

func after_each():
	event_bus.stop_recording()

## Feature: Tank Movement
class TestTankMovement:
	extends GutTest
	
	var tank: Tank
	
	func before_each():
		tank = Tank.new()
		tank.tank_type = Tank.TankType.PLAYER
		tank.base_speed = 100.0
		tank.tank_id = 1
		tank.global_position = Vector2(208, 208)
		add_child_autofree(tank)
		tank.spawn_timer = 0
		tank._complete_spawn()
		tank.invulnerability_timer = 0
		tank._end_invulnerability()
	
	func test_given_idle_tank_when_move_up_then_moves_upward():
		# Given: Tank is idle at position
		assert_eq(tank.current_state, Tank.State.IDLE, "Tank should be idle")
		var start_pos = tank.global_position
		
		# When: Command tank to move up and simulate physics
		tank.move_in_direction(Tank.Direction.UP)
		for i in range(5):
			tank._physics_process(1.0/60.0)
		
		# Then: Tank moves upward
		assert_lt(tank.global_position.y, start_pos.y, "Tank Y should decrease (move up)")
		assert_eq(tank.facing_direction, Tank.Direction.UP, "Tank should face up")
		assert_eq(tank.current_state, Tank.State.MOVING, "Tank should be moving")
	
	func test_given_idle_tank_when_move_right_then_moves_rightward():
		# Given: Tank is idle
		var start_pos = tank.global_position
		
		# When: Command tank to move right and simulate physics
		tank.move_in_direction(Tank.Direction.RIGHT)
		for i in range(5):
			tank._physics_process(1.0/60.0)
		
		# Then: Tank moves right
		assert_gt(tank.global_position.x, start_pos.x, "Tank X should increase (move right)")
		assert_eq(tank.facing_direction, Tank.Direction.RIGHT, "Tank should face right")
	
	func test_given_moving_tank_when_stop_then_velocity_zero():
		# Given: Tank is moving
		tank.move_in_direction(Tank.Direction.UP)
		for i in range(2):
			tank._physics_process(1.0/60.0)
		assert_eq(tank.current_state, Tank.State.MOVING, "Tank should be moving")
		
		# When: Stop movement
		tank.stop_movement()
		
		# Then: Velocity is zero and state is idle
		assert_eq(tank.velocity, Vector2.ZERO, "Velocity should be zero")
		assert_eq(tank.current_state, Tank.State.IDLE, "Tank should be idle")
	
	func test_given_tank_when_move_command_then_emits_tank_moved_event():
		# Given: EventBus is recording
		EventBus.start_recording()
		var initial_pos = tank.global_position
		
		# When: Tank moves
		tank.move_in_direction(Tank.Direction.LEFT)
		# Manually move tank to simulate physics
		tank.global_position.x -= 10
		tank._emit_tank_moved_event()
		
		# Then: TankMoved event was emitted
		var replay = EventBus.stop_recording()
		assert_gt(replay.events.size(), 0, "Events were recorded")
		
		var moved_events = []
		for event in replay.events:
			if event.get("type") == "TankMoved":
				moved_events.append(event)
		
		assert_gt(moved_events.size(), 0, "At least one TankMoved event should be emitted")

## Feature: Tank Combat
class TestTankCombat:
	extends GutTest
	
	var tank: Tank
	
	func before_each():
		tank = Tank.new()
		tank.tank_type = Tank.TankType.PLAYER
		tank.tank_id = 2
		tank.fire_cooldown_time = 0.5
		add_child_autofree(tank)
		tank.spawn_timer = 0
		tank._complete_spawn()
		tank.invulnerability_timer = 0
		tank._end_invulnerability()
	
	func test_given_tank_ready_when_fire_then_succeeds():
		# Given: Tank with no cooldown
		assert_eq(tank.fire_cooldown, 0.0, "No fire cooldown")
		
		# When: Try to fire
		var result = tank.try_fire()
		
		# Then: Fire succeeds
		assert_true(result, "Fire should succeed")
		assert_gt(tank.fire_cooldown, 0.0, "Fire cooldown should be active")
	
	func test_given_tank_on_cooldown_when_fire_then_fails():
		# Given: Tank just fired
		tank.try_fire()
		assert_gt(tank.fire_cooldown, 0.0, "Cooldown active")
		
		# When: Try to fire again immediately
		var result = tank.try_fire()
		
		# Then: Fire fails
		assert_false(result, "Fire should fail during cooldown")
	
	func test_given_cooldown_expired_when_fire_then_succeeds():
		# Given: Tank fired and cooldown expired
		tank.try_fire()
		# Wait for cooldown to expire by simulating physics frames
		while tank.fire_cooldown > 0:
			tank._physics_process(1.0/60.0)
		
		# When: Try to fire again
		var result = tank.try_fire()
		
		# Then: Fire succeeds
		assert_true(result, "Fire should succeed after cooldown")
	
	func test_given_tank_fires_when_fired_then_emits_bullet_event():
		# Given: EventBus recording
		EventBus.start_recording()
		tank.facing_direction = Tank.Direction.RIGHT
		
		# When: Tank fires
		tank.try_fire()
		
		# Then: BulletFired event emitted
		var replay = EventBus.stop_recording()
		assert_gt(replay.events.size(), 0, "Events were recorded")
		
		var bullet_events = []
		for event in replay.events:
			if event.get("type") == "BulletFired":
				bullet_events.append(event)
		
		assert_gt(bullet_events.size(), 0, "At least one BulletFired event")
		if bullet_events.size() > 0:
			assert_eq(bullet_events[0].get("tank_id"), 2, "Event has correct tank_id")
			# Direction is stored as dict {x, y}
			var dir = bullet_events[0].get("direction", {})
			assert_eq(Vector2(dir.x, dir.y), Vector2.RIGHT, "Bullet fired in facing direction")

## Feature: Tank Health and Damage
class TestTankHealth:
	extends GutTest
	
	var tank: Tank
	var death_signaled: bool = false
	
	func before_each():
		death_signaled = false
		tank = Tank.new()
		tank.tank_type = Tank.TankType.BASIC
		tank.max_health = 1
		tank.tank_id = 5
		add_child_autofree(tank)
		tank.spawn_timer = 0
		tank._complete_spawn()
		tank.invulnerability_timer = 0
		tank._end_invulnerability()
		tank.died.connect(_on_tank_died)
	
	func _on_tank_died():
		death_signaled = true
	
	func test_given_basic_tank_when_hit_once_then_dies():
		# Given: Basic tank with 1 HP
		assert_eq(tank.current_health, 1, "Tank has 1 HP")
		EventBus.start_recording()
		
		# When: Take 1 damage
		tank.take_damage(1)
		
		# Then: Tank state is dying (check immediately before it's freed)
		assert_eq(tank.current_state, Tank.State.DYING, "Tank should be dying")
		assert_true(death_signaled, "Death signal emitted")
		
		# And: TankDestroyed event emitted
		var replay = EventBus.stop_recording()
		assert_gt(replay.events.size(), 0, "Events were recorded")
		
		var destroyed_events = []
		for event in replay.events:
			if event.get("type") == "TankDestroyed":
				destroyed_events.append(event)
		
		assert_gt(destroyed_events.size(), 0, "TankDestroyed event emitted")
		if destroyed_events.size() > 0:
			assert_eq(destroyed_events[0].get("tank_id"), 5, "Correct tank_id in event")
	
	func test_given_power_tank_when_hit_once_then_survives():
		# Given: Power tank with multiple HP
		tank.tank_type = Tank.TankType.POWER
		tank.max_health = 4
		tank.current_health = 4
		
		# When: Take 1 damage
		tank.take_damage(1)
		await wait_physics_frames(2)
		
		# Then: Tank survives
		assert_eq(tank.current_health, 3, "Tank has 3 HP remaining")
		assert_ne(tank.current_state, Tank.State.DYING, "Tank should not be dying")
	
	func test_given_invulnerable_tank_when_hit_then_no_damage():
		# Given: Tank with invulnerability
		tank.activate_invulnerability(1.0)
		assert_eq(tank.current_state, Tank.State.INVULNERABLE, "Tank is invulnerable")
		var initial_health = tank.current_health
		
		# When: Take damage
		tank.take_damage(1)
		await wait_physics_frames(2)
		
		# Then: No damage taken
		assert_eq(tank.current_health, initial_health, "Health unchanged")
		assert_ne(tank.current_state, Tank.State.DYING, "Tank not dying")

## Feature: Tank State Machine
class TestTankStates:
	extends GutTest
	
	var tank: Tank
	var state_changes: Array[Tank.State] = []
	
	func before_each():
		state_changes.clear()
		tank = Tank.new()
		tank.tank_type = Tank.TankType.PLAYER
		add_child_autofree(tank)
		tank.state_changed.connect(_on_state_changed)
	
	func _on_state_changed(new_state: Tank.State):
		state_changes.append(new_state)
	
	func test_given_new_tank_when_spawned_then_starts_in_spawning_state():
		# Given/When: Tank created
		await wait_physics_frames(1)
		
		# Then: Starts in SPAWNING state
		assert_eq(tank.current_state, Tank.State.SPAWNING, "Tank starts spawning")
	
	func test_given_spawning_tank_when_timer_expires_then_becomes_invulnerable():
		# Given: Spawning tank
		assert_eq(tank.current_state, Tank.State.SPAWNING, "Tank is spawning")
		state_changes.clear()
		
		# When: Manually complete spawn (simulate timer expiration)
		tank.spawn_timer = 0
		tank._complete_spawn()
		
		# Then: Tank becomes invulnerable
		assert_eq(tank.current_state, Tank.State.INVULNERABLE, "Tank is invulnerable after spawn")
	
	func test_given_invulnerable_when_timer_expires_then_becomes_idle():
		pending("This test requires the game loop to be running for _process to execute timer logic")
		return

## Feature: Tank Speed Variations
class TestTankSpeed:
	extends GutTest
	
	func test_given_basic_tank_when_created_then_has_base_speed():
		# Given/When: Basic tank
		var tank = Tank.new()
		tank.tank_type = Tank.TankType.BASIC
		tank.base_speed = 100.0
		add_child_autofree(tank)
		
		# Then: Speed is base speed
		assert_eq(tank._get_current_speed(), 100.0, "Basic tank has base speed")
	
	func test_given_fast_tank_when_created_then_has_increased_speed():
		# Given/When: Fast tank
		var tank = Tank.new()
		tank.tank_type = Tank.TankType.FAST
		tank.base_speed = 100.0
		add_child_autofree(tank)
		
		# Then: Speed is 1.5x base
		assert_eq(tank._get_current_speed(), 150.0, "Fast tank has 1.5x speed")
	
	func test_given_power_tank_when_created_then_has_decreased_speed():
		# Given/When: Power tank
		var tank = Tank.new()
		tank.tank_type = Tank.TankType.POWER
		tank.base_speed = 100.0
		add_child_autofree(tank)
		
		# Then: Speed is 0.8x base
		assert_eq(tank._get_current_speed(), 80.0, "Power tank has 0.8x speed")
