extends GutTest

## BDD Tests for Bullet Spawning at 4th Unit
## Critical: Bullets must spawn at 4th unit (3.0 tiles from tank center) to prevent instant collisions
## Current implementation spawns at 0.5 tiles (WRONG - causes instant wall hits)
## Test-First: Write tests → All should FAIL (RED phase) → Then implement fix

const CommandHandler = preload("res://src/domain/services/command_handler.gd")
const GameState = preload("res://src/domain/aggregates/game_state.gd")
const StageState = preload("res://src/domain/aggregates/stage_state.gd")
const TankEntity = preload("res://src/domain/entities/tank_entity.gd")
const BulletEntity = preload("res://src/domain/entities/bullet_entity.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")
const FireCommand = preload("res://src/domain/commands/fire_command.gd")
const TerrainCell = preload("res://src/domain/entities/terrain_cell.gd")

## Helper: Create game state with stage
func create_game_state_with_stage() -> GameState:
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage)
	return game_state

## Helper: Create tank at position facing direction
func create_tank_at(game_state: GameState, tank_id: String, pos: Position, dir: Direction) -> TankEntity:
	var tank = TankEntity.create(tank_id, TankEntity.Type.PLAYER, pos, dir)
	game_state.add_tank(tank)
	return tank

## Helper: Check if position contains bullet
func find_bullet_at_position(game_state: GameState, pos: Position) -> BulletEntity:
	for bullet in game_state.get_all_bullets():
		if bullet.position.equals(pos):
			return bullet
	return null

## =============================================================================
## Test Group: Bullet Spawn Position at 4th Unit for Each Direction
## =============================================================================

## Test: NORTH (UP) direction - bullet spawns at y-3
func test_given_tank_facing_north_when_fire_command_executed_then_bullet_spawns_3_tiles_ahead():
	# Given: Tank at (10, 10) facing NORTH (UP)
	var game_state = create_game_state_with_stage()
	var tank = create_tank_at(game_state, "tank_1", Position.create(10, 10), Direction.create(Direction.UP))
	var command = FireCommand.create(tank.id, 1)
	
	# When: Fire command is executed
	var events = CommandHandler.execute_command(game_state, command)
	
	# Then: Bullet should spawn at 4th unit (3 tiles north = y-3)
	# Expected position: (10, 7) - 3 tiles ahead in UP direction
	var expected_spawn_pos = Position.create(10, 7)
	var bullet = find_bullet_at_position(game_state, expected_spawn_pos)
	
	assert_not_null(bullet, "Bullet should be spawned")
	assert_true(bullet.position.equals(expected_spawn_pos), 
		"Bullet should spawn at (10, 7) for tank at (10, 10) facing NORTH, but spawned at (%d, %d)" % [bullet.position.x, bullet.position.y])
	assert_eq(bullet.direction.value, Direction.UP, "Bullet should face same direction as tank")

## Test: SOUTH (DOWN) direction - bullet spawns at y+3
func test_given_tank_facing_south_when_fire_command_executed_then_bullet_spawns_3_tiles_ahead():
	# Given: Tank at (10, 10) facing SOUTH (DOWN)
	var game_state = create_game_state_with_stage()
	var tank = create_tank_at(game_state, "tank_1", Position.create(10, 10), Direction.create(Direction.DOWN))
	var command = FireCommand.create(tank.id, 1)
	
	# When: Fire command is executed
	var events = CommandHandler.execute_command(game_state, command)
	
	# Then: Bullet should spawn at 4th unit (3 tiles south = y+3)
	# Expected position: (10, 13) - 3 tiles ahead in DOWN direction
	var expected_spawn_pos = Position.create(10, 13)
	var bullet = find_bullet_at_position(game_state, expected_spawn_pos)
	
	assert_not_null(bullet, "Bullet should be spawned")
	assert_true(bullet.position.equals(expected_spawn_pos), 
		"Bullet should spawn at (10, 13) for tank at (10, 10) facing SOUTH, but spawned at (%d, %d)" % [bullet.position.x, bullet.position.y])
	assert_eq(bullet.direction.value, Direction.DOWN, "Bullet should face same direction as tank")

## Test: EAST (RIGHT) direction - bullet spawns at x+3
func test_given_tank_facing_east_when_fire_command_executed_then_bullet_spawns_3_tiles_ahead():
	# Given: Tank at (10, 10) facing EAST (RIGHT)
	var game_state = create_game_state_with_stage()
	var tank = create_tank_at(game_state, "tank_1", Position.create(10, 10), Direction.create(Direction.RIGHT))
	var command = FireCommand.create(tank.id, 1)
	
	# When: Fire command is executed
	var events = CommandHandler.execute_command(game_state, command)
	
	# Then: Bullet should spawn at 4th unit (3 tiles east = x+3)
	# Expected position: (13, 10) - 3 tiles ahead in RIGHT direction
	var expected_spawn_pos = Position.create(13, 10)
	var bullet = find_bullet_at_position(game_state, expected_spawn_pos)
	
	assert_not_null(bullet, "Bullet should be spawned")
	assert_true(bullet.position.equals(expected_spawn_pos), 
		"Bullet should spawn at (13, 10) for tank at (10, 10) facing EAST, but spawned at (%d, %d)" % [bullet.position.x, bullet.position.y])
	assert_eq(bullet.direction.value, Direction.RIGHT, "Bullet should face same direction as tank")

## Test: WEST (LEFT) direction - bullet spawns at x-3
func test_given_tank_facing_west_when_fire_command_executed_then_bullet_spawns_3_tiles_ahead():
	# Given: Tank at (10, 10) facing WEST (LEFT)
	var game_state = create_game_state_with_stage()
	var tank = create_tank_at(game_state, "tank_1", Position.create(10, 10), Direction.create(Direction.LEFT))
	var command = FireCommand.create(tank.id, 1)
	
	# When: Fire command is executed
	var events = CommandHandler.execute_command(game_state, command)
	
	# Then: Bullet should spawn at 4th unit (3 tiles west = x-3)
	# Expected position: (7, 10) - 3 tiles ahead in LEFT direction
	var expected_spawn_pos = Position.create(7, 10)
	var bullet = find_bullet_at_position(game_state, expected_spawn_pos)
	
	assert_not_null(bullet, "Bullet should be spawned")
	assert_true(bullet.position.equals(expected_spawn_pos), 
		"Bullet should spawn at (7, 10) for tank at (10, 10) facing WEST, but spawned at (%d, %d)" % [bullet.position.x, bullet.position.y])
	assert_eq(bullet.direction.value, Direction.LEFT, "Bullet should face same direction as tank")

## =============================================================================
## Test Group: Bullet Spawns Outside Tank's 3-Unit Hitbox
## =============================================================================

## Test: Bullet spawn position is beyond tank's 3-unit hitbox (NORTH)
func test_given_tank_with_3_unit_hitbox_facing_north_when_fires_then_bullet_spawns_outside_hitbox():
	# Given: Tank at (10, 10) facing NORTH with 3-unit-long hitbox
	# Tank hitbox extends from center (10,10) to 3 units ahead: (10,10), (10,9), (10,8)
	var game_state = create_game_state_with_stage()
	var tank = create_tank_at(game_state, "tank_1", Position.create(10, 10), Direction.create(Direction.UP))
	var command = FireCommand.create(tank.id, 1)
	
	# When: Fire command is executed
	var events = CommandHandler.execute_command(game_state, command)
	
	# Then: Bullet should spawn at (10, 7) which is OUTSIDE the 3-unit hitbox
	# Tank hitbox tiles: (10,10), (10,9), (10,8) for center column
	# Bullet at (10,7) is beyond hitbox
	var all_bullets = game_state.get_all_bullets()
	var bullet = all_bullets[0]
	var hitbox = tank.get_hitbox()
	var hitbox_tiles = hitbox.get_occupied_tiles()
	
	# Verify bullet is NOT in any hitbox tile
	var bullet_in_hitbox = false
	for tile in hitbox_tiles:
		if tile.equals(bullet.position):
			bullet_in_hitbox = true
			break
	
	assert_false(bullet_in_hitbox, 
		"Bullet at (%d, %d) should NOT be inside tank hitbox (spawn at 4th unit, beyond 3-unit hitbox)" % [bullet.position.x, bullet.position.y])

## Test: Bullet spawn position is beyond tank's 3-unit hitbox (EAST)
func test_given_tank_with_3_unit_hitbox_facing_east_when_fires_then_bullet_spawns_outside_hitbox():
	# Given: Tank at (10, 10) facing EAST with 3-unit-long hitbox
	var game_state = create_game_state_with_stage()
	var tank = create_tank_at(game_state, "tank_1", Position.create(10, 10), Direction.create(Direction.RIGHT))
	var command = FireCommand.create(tank.id, 1)
	
	# When: Fire command is executed
	var events = CommandHandler.execute_command(game_state, command)
	
	# Then: Bullet should spawn at (13, 10) which is OUTSIDE the 3-unit hitbox
	var all_bullets = game_state.get_all_bullets()
	var bullet = all_bullets[0]
	var hitbox = tank.get_hitbox()
	var hitbox_tiles = hitbox.get_occupied_tiles()
	
	var bullet_in_hitbox = false
	for tile in hitbox_tiles:
		if tile.equals(bullet.position):
			bullet_in_hitbox = true
			break
	
	assert_false(bullet_in_hitbox, 
		"Bullet at (%d, %d) should NOT be inside tank hitbox" % [bullet.position.x, bullet.position.y])

## =============================================================================
## Test Group: Bullet Spawn Validation (Basic)
## =============================================================================

## Test: Bullet spawn at map edge (valid boundary case)
func test_given_tank_facing_east_near_edge_when_fires_then_bullet_spawns_if_space_valid():
	# Given: Tank at (22, 10) facing EAST (spawn at x=25, still in bounds for 26x26 grid)
	var game_state = create_game_state_with_stage()
	var tank = create_tank_at(game_state, "tank_1", Position.create(22, 10), Direction.create(Direction.RIGHT))
	var command = FireCommand.create(tank.id, 1)
	
	# When: Fire command is executed
	var events = CommandHandler.execute_command(game_state, command)
	
	# Then: Bullet should spawn at (25, 10) - still within bounds
	var all_bullets = game_state.get_all_bullets()
	assert_eq(all_bullets.size(), 1, "Bullet should spawn at valid edge position")
	assert_true(all_bullets[0].position.equals(Position.create(25, 10)), 
		"Bullet should be at (25, 10)")

## Test: Bullet spawn calculation is consistent across all directions
func test_given_tank_rotated_to_all_directions_when_fires_then_spawn_offset_is_always_3_tiles():
	# Given: Game state with tank
	var game_state = create_game_state_with_stage()
	var tank = create_tank_at(game_state, "tank_1", Position.create(13, 13), Direction.create(Direction.UP))
	
	# Test each direction
	var directions = [
		{"dir": Direction.UP, "expected_x": 13, "expected_y": 10},
		{"dir": Direction.DOWN, "expected_x": 13, "expected_y": 16},
		{"dir": Direction.LEFT, "expected_x": 10, "expected_y": 13},
		{"dir": Direction.RIGHT, "expected_x": 16, "expected_y": 13}
	]
	
	for dir_data in directions:
		# When: Tank rotated and fires
		tank.direction = Direction.create(dir_data.dir)
		tank.cooldown_frames = 0  # Reset cooldown
		var command = FireCommand.create(tank.id, game_state.frame)
		var events = CommandHandler.execute_command(game_state, command)
		
		# Then: Bullet spawns at correct position (3 tiles ahead)
		var all_bullets = game_state.get_all_bullets()
		var last_bullet = all_bullets[all_bullets.size() - 1]
		assert_eq(last_bullet.position.x, dir_data.expected_x, 
			"Direction %d: Bullet X should be %d" % [dir_data.dir, dir_data.expected_x])
		assert_eq(last_bullet.position.y, dir_data.expected_y, 
			"Direction %d: Bullet Y should be %d" % [dir_data.dir, dir_data.expected_y])

## Test: Bullet direction matches tank direction at spawn
func test_given_tank_when_fires_then_bullet_direction_matches_tank_direction():
	# Given: Tank at (10, 10) facing SOUTH
	var game_state = create_game_state_with_stage()
	var tank = create_tank_at(game_state, "tank_1", Position.create(10, 10), Direction.create(Direction.DOWN))
	var command = FireCommand.create(tank.id, 1)
	
	# When: Fire command is executed
	var events = CommandHandler.execute_command(game_state, command)
	
	# Then: Bullet should have same direction as tank
	var all_bullets = game_state.get_all_bullets()
	var bullet = all_bullets[0]
	assert_true(bullet.direction.equals(tank.direction), 
		"Bullet direction should match tank direction")

## Test: Multiple bullets spawn at correct positions (rapid fire with cooldown reset)
func test_given_tank_fires_multiple_times_when_rotated_then_each_bullet_spawns_at_correct_position():
	# Given: Tank that can fire multiple times
	var game_state = create_game_state_with_stage()
	var tank = create_tank_at(game_state, "tank_1", Position.create(13, 13), Direction.create(Direction.UP))
	
	# When: Fire command executed facing NORTH
	tank.cooldown_frames = 0
	var command1 = FireCommand.create(tank.id, 1)
	CommandHandler.execute_command(game_state, command1)
	
	# When: Tank rotates and fires facing EAST
	tank.direction = Direction.create(Direction.RIGHT)
	tank.cooldown_frames = 0  # Reset cooldown for test
	var command2 = FireCommand.create(tank.id, 2)
	CommandHandler.execute_command(game_state, command2)
	
	# Then: Two bullets at different positions
	var all_bullets = game_state.get_all_bullets()
	assert_eq(all_bullets.size(), 2, "Should have 2 bullets")
	assert_true(all_bullets[0].position.equals(Position.create(13, 10)), 
		"First bullet should be at (13, 10) - NORTH spawn")
	assert_true(all_bullets[1].position.equals(Position.create(16, 13)), 
		"Second bullet should be at (16, 13) - EAST spawn")
