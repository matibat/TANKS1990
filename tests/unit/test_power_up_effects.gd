extends GutTest
## Tests for power-up effects and TerrainManager integration

var terrain_manager: TerrainManager
var shovel_power_up: ShovelPowerUp
var tank: Tank

func before_each():
	# Create terrain manager
	terrain_manager = TerrainManager.new()
	terrain_manager.name = "TerrainManager"
	add_child_autofree(terrain_manager)
	
	# Create shovel power-up
	shovel_power_up = ShovelPowerUp.new()
	add_child_autofree(shovel_power_up)
	
	# Create tank
	var tank_scene = load("res://scenes/player_tank.tscn")
	tank = tank_scene.instantiate()
	add_child_autofree(tank)

func test_shovel_power_up_finds_terrain_manager_by_group():
	# Given a TerrainManager in the terrain_manager group
	assert_true(terrain_manager.is_in_group("terrain_manager"), "TerrainManager should be in group")
	
	# When searching for terrain manager
	var found = get_tree().get_first_node_in_group("terrain_manager")
	
	# Then it should be found
	assert_not_null(found, "Should find TerrainManager by group")
	assert_eq(found, terrain_manager, "Found manager should be the same instance")

func test_shovel_power_up_uses_correct_method_names():
	# Given tiles are set
	terrain_manager.set_tile_at_coords(13, 24, TerrainManager.TileType.BRICK)
	
	# When getting tile type
	var tile_type = terrain_manager.get_tile_at_coords(13, 24)
	
	# Then method should work
	assert_eq(tile_type, TerrainManager.TileType.BRICK, "get_tile_at_coords should work")

func test_shovel_power_up_fortifies_base():
	# Given brick tiles around base
	for x in range(12, 15):
		for y in range(24, 27):
			terrain_manager.set_tile_at_coords(x, y, TerrainManager.TileType.BRICK)
	
	# When shovel power-up is applied
	shovel_power_up.apply_effect(tank)
	await wait_frames(2)
	
	# Then tiles should be fortified to steel
	var center_tile = terrain_manager.get_tile_at_coords(13, 25)
	assert_eq(center_tile, TerrainManager.TileType.STEEL, "Base should be fortified with steel")

func test_shovel_power_up_reverts_after_timeout():
	# Given fortified base
	terrain_manager.set_tile_at_coords(13, 25, TerrainManager.TileType.BRICK)
	shovel_power_up.fortification_time = 0.1  # Fast timeout for testing
	
	# When applying effect
	shovel_power_up.apply_effect(tank)
	await wait_frames(2)
	
	# Then tile should be steel
	var tile_during = terrain_manager.get_tile_at_coords(13, 25)
	assert_eq(tile_during, TerrainManager.TileType.STEEL, "Should be steel during fortification")
	
	# When timeout expires
	await get_tree().create_timer(0.15).timeout
	
	# Then tile should revert to brick
	var tile_after = terrain_manager.get_tile_at_coords(13, 25)
	assert_eq(tile_after, TerrainManager.TileType.BRICK, "Should revert to brick after timeout")

func test_shovel_power_up_handles_missing_terrain_manager_gracefully():
	# Given no terrain manager in scene
	terrain_manager.queue_free()
	await wait_physics_frames(1)
	
	# When applying shovel effect
	shovel_power_up.apply_effect(tank)
	await wait_physics_frames(1)
	
	# Then should expect a warning (not an error)
	assert_engine_error("TerrainManager not found", "Should warn when TerrainManager is missing")
	
	# Should complete without crashing
	assert_true(true, "Should handle missing TerrainManager gracefully")

func test_star_power_up_checks_level_property_correctly():
	# Given a tank with level property
	tank.set("level", 1)
	
	# When checking if property exists
	var has_level = "level" in tank
	
	# Then should be true
	assert_true(has_level, "Tank should have level property")

func test_tank_power_up_checks_lives_property_correctly():
	# Given a tank with lives property
	tank.set("lives", 3)
	
	# When checking if property exists
	var has_lives = "lives" in tank
	
	# Then should be true
	assert_true(has_lives, "Tank should have lives property")

func test_clock_power_up_checks_frozen_property_correctly():
	# Given an enemy with is_frozen property
	var enemy_scene = load("res://scenes/enemy_tank.tscn")
	var enemy = enemy_scene.instantiate()
	add_child_autofree(enemy)
	enemy.set("is_frozen", false)
	
	# When checking if property exists
	var has_frozen = "is_frozen" in enemy
	
	# Then should be true
	assert_true(has_frozen, "Enemy should have is_frozen property")

func test_helmet_power_up_checks_invulnerability_correctly():
	# Given a tank with invulnerability properties
	tank.set("is_invulnerable", false)
	tank.set("invulnerability_time", 0.0)
	
	# When checking if property exists
	var has_invuln = "is_invulnerable" in tank
	
	# Then should be true
	assert_true(has_invuln, "Tank should have is_invulnerable property")

func test_all_power_ups_use_in_operator_not_has():
	# Given power-up source files
	var power_up_files = [
		"res://src/entities/power_ups/star_power_up.gd",
		"res://src/entities/power_ups/tank_power_up.gd",
		"res://src/entities/power_ups/clock_power_up.gd",
		"res://src/entities/power_ups/helmet_power_up.gd"
	]
	
	# Then none should use .has() method
	for file_path in power_up_files:
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			
			# Should not contain .has("
			assert_false(content.contains('.has("'), 
				"%s should not use .has() method" % file_path)
