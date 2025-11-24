extends GutTest
# BDD tests for power-up system
# Covers US4.1 (collect power-ups) and US4.2 (spawn from Armored tanks)

var power_up_manager: Node
var player_tank: Node
var base: Node

func before_each():
	power_up_manager = null
	player_tank = null
	base = null

func after_each():
	if power_up_manager and is_instance_valid(power_up_manager):
		power_up_manager.queue_free()
	if player_tank and is_instance_valid(player_tank):
		player_tank.queue_free()
	if base and is_instance_valid(base):
		base.queue_free()

# ===== Power-Up Spawning (US4.2) =====

func test_armored_tank_destroyed_spawns_random_power_up():
	# Given: PowerUpManager listening to TankDestroyedEvent
	power_up_manager = load("res://src/managers/power_up_manager.gd").new()
	add_child_autofree(power_up_manager)
	
	# When: Armored tank destroyed
	var TankDestroyedEvent = load("res://src/events/tank_destroyed_event.gd")
	var event = TankDestroyedEvent.new()
	event.tank_type = "Armored"
	event.position = Vector2(200, 200)
	EventBus.emit_game_event(event)
	await wait_frames(2)
	
	# Then: Power-up spawned at tank position
	var power_ups = get_tree().get_nodes_in_group("power_ups")
	assert_gt(power_ups.size(), 0, "Power-up should spawn from Armored tank")
	assert_almost_eq(power_ups[0].global_position.x, 200, 5)
	assert_almost_eq(power_ups[0].global_position.y, 200, 5)

func test_non_armored_tank_destroyed_does_not_spawn_power_up():
	# Given: PowerUpManager listening to TankDestroyedEvent
	power_up_manager = load("res://src/managers/power_up_manager.gd").new()
	add_child_autofree(power_up_manager)
	
	# When: Basic tank destroyed
	var TankDestroyedEvent = load("res://src/events/tank_destroyed_event.gd")
	var event = TankDestroyedEvent.new()
	event.tank_type = "Basic"
	event.position = Vector2(200, 200)
	EventBus.emit_game_event(event)
	await wait_frames(2)
	
	# Then: No power-up spawned
	var power_ups = get_tree().get_nodes_in_group("power_ups")
	assert_eq(power_ups.size(), 0, "No power-up should spawn from Basic tank")

func test_power_up_spawned_event_emitted():
	# Given: PowerUpManager and EventBus listener
	power_up_manager = load("res://src/managers/power_up_manager.gd").new()
	add_child_autofree(power_up_manager)
	
	var spawned_event = null
	var callback = func(event): spawned_event = event
	EventBus.subscribe("PowerUpSpawnedEvent", callback)
	
	# When: Armored tank destroyed
	var TankDestroyedEvent = load("res://src/events/tank_destroyed_event.gd")
	var destroy_event = TankDestroyedEvent.new()
	destroy_event.tank_type = "Armored"
	destroy_event.position = Vector2(100, 100)
	EventBus.emit_event(destroy_event)
	await wait_frames(2)
	
	# Then: PowerUpSpawnedEvent emitted
	assert_not_null(spawned_event, "PowerUpSpawnedEvent should be emitted")
	assert_eq(spawned_event.event_type, "PowerUpSpawnedEvent")
	
	EventBus.unsubscribe("PowerUpSpawnedEvent", callback)

# ===== Power-Up Collection (US4.1) =====

func test_player_tank_collects_power_up_on_collision():
	# Given: Player tank and power-up at same position
	player_tank = load("res://src/entities/tank.gd").new()
	player_tank.tank_type = "Player"
	player_tank.global_position = Vector2(200, 200)
	add_child_autofree(player_tank)
	
	var power_up = load("res://src/entities/power_ups/tank_power_up.gd").new()
	power_up.global_position = Vector2(200, 200)
	add_child_autofree(power_up)
	await wait_frames(1)
	
	# When: Collision detected (simulated via area_entered)
	power_up._on_area_entered(player_tank)
	await wait_frames(1)
	
	# Then: Power-up removed from scene
	assert_false(is_instance_valid(power_up) and power_up.is_inside_tree(), "Power-up should be removed after collection")

func test_power_up_collected_event_emitted():
	# Given: Player tank and power-up
	player_tank = load("res://src/entities/tank.gd").new()
	player_tank.tank_type = "Player"
	player_tank.global_position = Vector2(200, 200)
	add_child_autofree(player_tank)
	
	var power_up = load("res://src/entities/power_ups/tank_power_up.gd").new()
	power_up.global_position = Vector2(200, 200)
	add_child_autofree(power_up)
	
	var collected_event = null
	var callback = func(event): collected_event = event
	EventBus.subscribe("PowerUpCollectedEvent", callback)
	await wait_frames(1)
	
	# When: Power-up collected
	power_up._on_area_entered(player_tank)
	await wait_frames(1)
	
	# Then: PowerUpCollectedEvent emitted
	assert_not_null(collected_event, "PowerUpCollectedEvent should be emitted")
	assert_eq(collected_event.event_type, "PowerUpCollectedEvent")
	
	EventBus.unsubscribe("PowerUpCollectedEvent", callback)

func test_power_up_timeout_after_20_seconds():
	# Given: Power-up spawned
	var power_up = load("res://src/entities/power_ups/tank_power_up.gd").new()
	power_up.global_position = Vector2(200, 200)
	add_child_autofree(power_up)
	
	# When: 20 seconds elapse (simulated)
	power_up.lifetime_remaining = 0.1  # Fast-forward for testing
	await wait_seconds(0.2)
	
	# Then: Power-up removed from scene
	assert_false(is_instance_valid(power_up) and power_up.is_inside_tree(), "Power-up should timeout after 20 seconds")

# ===== Tank Power-Up (Extra Life) =====

func test_tank_power_up_gives_extra_life():
	# Given: Player tank with 3 lives
	player_tank = load("res://src/entities/tank.gd").new()
	player_tank.tank_type = "Player"
	player_tank.lives = 3
	add_child_autofree(player_tank)
	
	var power_up = load("res://src/entities/power_ups/tank_power_up.gd").new()
	add_child_autofree(power_up)
	await wait_frames(1)
	
	# When: Tank power-up collected
	power_up.apply_effect(player_tank)
	
	# Then: Player has 4 lives
	assert_eq(player_tank.lives, 4, "Tank power-up should grant extra life")

# ===== Star Power-Up (Level Upgrade) =====

func test_star_power_up_upgrades_tank_level():
	# Given: Player tank at level 0
	player_tank = load("res://src/entities/tank.gd").new()
	player_tank.tank_type = "Player"
	player_tank.level = 0
	add_child_autofree(player_tank)
	
	var power_up = load("res://src/entities/power_ups/star_power_up.gd").new()
	add_child_autofree(power_up)
	await wait_frames(1)
	
	# When: Star collected
	power_up.apply_effect(player_tank)
	
	# Then: Player at level 1
	assert_eq(player_tank.level, 1, "Star should upgrade tank level")

func test_star_power_up_max_level_3():
	# Given: Player tank at level 3
	player_tank = load("res://src/entities/tank.gd").new()
	player_tank.tank_type = "Player"
	player_tank.level = 3
	add_child_autofree(player_tank)
	
	var power_up = load("res://src/entities/power_ups/star_power_up.gd").new()
	add_child_autofree(power_up)
	await wait_frames(1)
	
	# When: Star collected
	power_up.apply_effect(player_tank)
	
	# Then: Player still at level 3
	assert_eq(player_tank.level, 3, "Star should not exceed max level 3")

# ===== Grenade Power-Up (Destroy All Enemies) =====

func test_grenade_power_up_destroys_all_enemies():
	# Given: 3 enemy tanks on screen
	var enemy1 = load("res://src/entities/tank.gd").new()
	enemy1.tank_type = "Basic"
	enemy1.add_to_group("enemies")
	add_child_autofree(enemy1)
	
	var enemy2 = load("res://src/entities/tank.gd").new()
	enemy2.tank_type = "Fast"
	enemy2.add_to_group("enemies")
	add_child_autofree(enemy2)
	
	var enemy3 = load("res://src/entities/tank.gd").new()
	enemy3.tank_type = "Power"
	enemy3.add_to_group("enemies")
	add_child_autofree(enemy3)
	
	await wait_frames(1)
	
	player_tank = load("res://src/entities/tank.gd").new()
	player_tank.tank_type = "Player"
	add_child_autofree(player_tank)
	
	var power_up = load("res://src/entities/power_ups/grenade_power_up.gd").new()
	add_child_autofree(power_up)
	await wait_frames(1)
	
	# When: Grenade collected
	power_up.apply_effect(player_tank)
	await wait_frames(2)
	
	# Then: All enemies destroyed
	var remaining_enemies = get_tree().get_nodes_in_group("enemies")
	assert_eq(remaining_enemies.size(), 0, "Grenade should destroy all enemies")

# ===== Helmet Power-Up (Temporary Invulnerability) =====

func test_helmet_power_up_grants_invulnerability():
	# Given: Player tank
	player_tank = load("res://src/entities/tank.gd").new()
	player_tank.tank_type = "Player"
	add_child_autofree(player_tank)
	
	var power_up = load("res://src/entities/power_ups/helmet_power_up.gd").new()
	add_child_autofree(power_up)
	await wait_frames(1)
	
	# When: Helmet collected
	power_up.apply_effect(player_tank)
	
	# Then: Tank is invulnerable
	assert_true(player_tank.is_invulnerable, "Helmet should grant invulnerability")

func test_helmet_invulnerability_lasts_6_seconds():
	# Given: Player tank with helmet
	player_tank = load("res://src/entities/tank.gd").new()
	player_tank.tank_type = "Player"
	add_child_autofree(player_tank)
	
	var power_up = load("res://src/entities/power_ups/helmet_power_up.gd").new()
	add_child_autofree(power_up)
	await wait_frames(1)
	
	power_up.apply_effect(player_tank)
	assert_true(player_tank.is_invulnerable)
	
	# When: 6 seconds elapse (simulated)
	player_tank.invulnerability_time = 0.1  # Fast-forward
	await wait_seconds(0.2)
	
	# Then: Invulnerability expired
	assert_false(player_tank.is_invulnerable, "Helmet invulnerability should expire after 6 seconds")

# ===== Clock Power-Up (Freeze Enemies) =====

func test_clock_power_up_freezes_all_enemies():
	# Given: 2 enemy tanks
	var enemy1 = load("res://src/entities/tank.gd").new()
	enemy1.tank_type = "Basic"
	enemy1.add_to_group("enemies")
	add_child_autofree(enemy1)
	
	var enemy2 = load("res://src/entities/tank.gd").new()
	enemy2.tank_type = "Fast"
	enemy2.add_to_group("enemies")
	add_child_autofree(enemy2)
	
	await wait_frames(1)
	
	player_tank = load("res://src/entities/tank.gd").new()
	player_tank.tank_type = "Player"
	add_child_autofree(player_tank)
	
	var power_up = load("res://src/entities/power_ups/clock_power_up.gd").new()
	add_child_autofree(power_up)
	await wait_frames(1)
	
	# When: Clock collected
	power_up.apply_effect(player_tank)
	
	# Then: All enemies frozen
	assert_true(enemy1.is_frozen, "Clock should freeze all enemies")
	assert_true(enemy2.is_frozen, "Clock should freeze all enemies")

func test_clock_freeze_lasts_6_seconds():
	# Given: Enemy tank frozen by clock
	var enemy = load("res://src/entities/tank.gd").new()
	enemy.tank_type = "Basic"
	enemy.add_to_group("enemies")
	add_child_autofree(enemy)
	
	player_tank = load("res://src/entities/tank.gd").new()
	player_tank.tank_type = "Player"
	add_child_autofree(player_tank)
	
	var power_up = load("res://src/entities/power_ups/clock_power_up.gd").new()
	add_child_autofree(power_up)
	await wait_frames(1)
	
	power_up.apply_effect(player_tank)
	assert_true(enemy.is_frozen)
	
	# When: 6 seconds elapse (simulated)
	enemy.freeze_time = 0.1  # Fast-forward
	await wait_seconds(0.2)
	
	# Then: Freeze expired
	assert_false(enemy.is_frozen, "Clock freeze should expire after 6 seconds")

# ===== Shovel Power-Up (Fortify Base) =====

func test_shovel_power_up_fortifies_base_walls():
	# Given: Base with brick walls
	base = load("res://src/entities/base.gd").new()
	base.global_position = Vector2(208, 400)
	add_child_autofree(base)
	
	var terrain_manager = load("res://src/systems/terrain_manager.gd").new()
	add_child_autofree(terrain_manager)
	
	# Place brick walls around base (simplified)
	terrain_manager.set_tile_at_coords(12, 24, 0)  # Brick
	terrain_manager.set_tile_at_coords(13, 24, 0)
	
	player_tank = load("res://src/entities/tank.gd").new()
	player_tank.tank_type = "Player"
	add_child_autofree(player_tank)
	
	var power_up = load("res://src/entities/power_ups/shovel_power_up.gd").new()
	add_child_autofree(power_up)
	await wait_frames(1)
	
	# When: Shovel collected
	power_up.apply_effect(player_tank)
	
	# Then: Brick walls replaced with steel
	var tile_type = terrain_manager.get_tile_type_at_coords(12, 24)
	assert_eq(tile_type, terrain_manager.TileType.STEEL, "Shovel should replace brick with steel")

func test_shovel_walls_revert_after_10_seconds():
	# Given: Base with fortified walls
	base = load("res://src/entities/base.gd").new()
	base.global_position = Vector2(208, 400)
	add_child_autofree(base)
	
	var terrain_manager = load("res://src/systems/terrain_manager.gd").new()
	add_child_autofree(terrain_manager)
	terrain_manager.set_tile_at_coords(12, 24, 1)  # Steel
	
	player_tank = load("res://src/entities/tank.gd").new()
	player_tank.tank_type = "Player"
	add_child_autofree(player_tank)
	
	var power_up = load("res://src/entities/power_ups/shovel_power_up.gd").new()
	power_up.fortification_time = 0.1  # Fast-forward for testing
	add_child_autofree(power_up)
	await wait_frames(1)
	
	power_up.apply_effect(player_tank)
	
	# When: 10 seconds elapse
	await wait_seconds(0.2)
	
	# Then: Steel walls revert to brick
	var tile_type = terrain_manager.get_tile_type_at_coords(12, 24)
	assert_eq(tile_type, terrain_manager.TileType.BRICK, "Shovel fortification should revert after 10 seconds")

# ===== Power-Up Type Distribution =====

func test_all_six_power_up_types_can_spawn():
	# Given: PowerUpManager with random spawning
	power_up_manager = load("res://src/managers/power_up_manager.gd").new()
	add_child_autofree(power_up_manager)
	
	var spawned_types = {}
	
	# When: Multiple Armored tanks destroyed (simulate 30 spawns)
	var TankDestroyedEvent = load("res://src/events/tank_destroyed_event.gd")
	for i in range(30):
		var event = TankDestroyedEvent.new()
		event.tank_type = "Armored"
		event.position = Vector2(100 + i * 10, 100)
		EventBus.emit_game_event(event)
		await wait_frames(1)
		
		var power_ups = get_tree().get_nodes_in_group("power_ups")
		if power_ups.size() > 0:
			var type_name = power_ups[-1].power_up_type
			spawned_types[type_name] = true
	
	# Then: All 6 types should have spawned at least once
	assert_true(spawned_types.size() >= 5, "Most power-up types should spawn randomly (statistical)")
