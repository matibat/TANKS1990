extends GutTest
## Integration tests for collision system
## Verifies that Tank, Bullet, and Terrain collision layers work together

var terrain: TerrainManager
var tank: Tank
var bullet: Bullet

func before_each():
	terrain = TerrainManager.new()
	terrain.tile_set = TileSet.new()
	add_child_autofree(terrain)
	
	tank = Tank.new()
	add_child_autofree(tank)
	
	bullet = Bullet.new()
	add_child_autofree(bullet)

## Terrain System Integration Tests

func test_terrain_manager_has_collision_enabled():
	# Given: Terrain manager (from before_each)
	
	# Then: Terrain should have collision enabled
	assert_true(terrain.collision_enabled, "Terrain should have collision enabled")
	assert_not_null(terrain.tile_set, "Terrain should have a TileSet")

func test_brick_tile_can_be_set_and_retrieved():
	# Given: Empty terrain (from before_each)
	
	# When: Set brick tile
	terrain.set_tile_at_position(Vector2(100, 100), TerrainManager.TileType.BRICK)
	
	# Then: Tile should be retrievable
	var tile_type = terrain.get_tile_at_position(Vector2(100, 100))
	assert_eq(tile_type, TerrainManager.TileType.BRICK, "Brick tile should be set")

func test_terrain_loading_from_array():
	# Given: Terrain data array
	var data = [
		[TerrainManager.TileType.BRICK, TerrainManager.TileType.EMPTY],
		[TerrainManager.TileType.EMPTY, TerrainManager.TileType.STEEL]
	]
	
	# When: Load terrain
	terrain.load_terrain_from_array(data)
	
	# Then: Tiles should match
	assert_eq(terrain.get_tile_at_coords(0, 0), TerrainManager.TileType.BRICK, "Brick at (0,0)")
	assert_eq(terrain.get_tile_at_coords(1, 1), TerrainManager.TileType.STEEL, "Steel at (1,1)")

## Collision Layer Tests

func test_bullet_has_correct_collision_layers():
	# Given/Then: Bullet should be on layer 4 and collide with layers 1 and 2
	assert_eq(bullet.collision_layer, 4, "Bullet is on layer 4")
	assert_eq(bullet.collision_mask, 3, "Bullet collides with layers 1 and 2")

func test_tank_has_correct_collision_layer():
	# Given/Then: Tank should be on layer 1
	assert_eq(tank.collision_layer, 1, "Tank is on layer 1")

func test_tank_collides_with_terrain():
	# Given: Tank at grid position with wall ahead
	tank.global_position = Vector2(128, 128)
	tank._complete_spawn()
	tank.invulnerability_timer = 0
	tank._end_invulnerability()
	
	# Load terrain with wall at tile (9, 8)
	var empty_terrain = []
	for y in range(26):
		for x in range(26):
			empty_terrain.append(TerrainManager.TileType.EMPTY)
	terrain.load_terrain(empty_terrain)
	terrain.set_tile_at_coord(Vector2i(9, 8), TerrainManager.TileType.BRICK)
	
	# When: Try to move right toward wall (multiple grid cells)
	for i in range(20):
		tank.move_in_direction(Tank.Direction.RIGHT)
		tank._physics_process(1.0/60.0)
	
	# Then: Tank should be blocked immediately by wall at (9,8)
	# Moving right from (128, 128) would go to (144, 128), which occupies tile (9,8) with wall
	assert_eq(tank.global_position.x, 128.0, "Tank should be blocked by wall and not move")

## Terrain Destruction Tests

func test_damage_tile_destroys_brick():
	# Given: Terrain with brick tile
	terrain.set_tile_at_position(Vector2(100, 100), TerrainManager.TileType.BRICK)
	
	# When: Damage tile
	var result = terrain.damage_tile(Vector2(100, 100), false)
	
	# Then: Should be destroyed
	assert_true(result, "Brick should be destroyed")
	assert_eq(terrain.get_tile_at_position(Vector2(100, 100)), TerrainManager.TileType.EMPTY, "Tile should be empty")

func test_damage_tile_preserves_steel_without_power():
	# Given: Terrain with steel tile
	terrain.set_tile_at_position(Vector2(200, 200), TerrainManager.TileType.STEEL)
	
	# When: Damage tile without steel-destroy capability
	var result = terrain.damage_tile(Vector2(200, 200), false)
	
	# Then: Should not be destroyed
	assert_false(result, "Steel should not be destroyed")
	assert_eq(terrain.get_tile_at_position(Vector2(200, 200)), TerrainManager.TileType.STEEL, "Steel should remain")

func test_damage_tile_destroys_steel_with_power():
	# Given: Terrain with steel tile
	terrain.set_tile_at_position(Vector2(300, 300), TerrainManager.TileType.STEEL)
	
	# When: Damage tile with steel-destroy capability
	var result = terrain.damage_tile(Vector2(300, 300), true)
	
	# Then: Should be destroyed
	assert_true(result, "Steel should be destroyed with power")
	assert_eq(terrain.get_tile_at_position(Vector2(300, 300)), TerrainManager.TileType.EMPTY, "Steel should be empty")
