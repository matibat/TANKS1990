extends GutTest

## BDD Tests for CollisionService
## Test-first approach: Write behavior tests before implementation

const CollisionService = preload("res://src/domain/services/collision_service.gd")
const TankEntity = preload("res://src/domain/entities/tank_entity.gd")
const BulletEntity = preload("res://src/domain/entities/bullet_entity.gd")
const TerrainCell = preload("res://src/domain/entities/terrain_cell.gd")
const BaseEntity = preload("res://src/domain/entities/base_entity.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")
const StageState = preload("res://src/domain/aggregates/stage_state.gd")
const GameState = preload("res://src/domain/aggregates/game_state.gd")

## Test: Tank-Bullet Collision Detection
func test_given_tank_and_bullet_at_same_position_when_collision_checked_then_returns_true():
	# Given: A tank and bullet at same position
	var pos = Position.create(5, 5)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, pos, Direction.create(Direction.UP))
	var bullet = BulletEntity.create("bullet_1", "other_tank", pos, Direction.create(Direction.UP), 2, 1)
	
	# When: Collision is checked
	var collided = CollisionService.check_tank_bullet_collision(tank, bullet)
	
	# Then: Collision is detected
	assert_true(collided, "Tank and bullet at same position should collide")

func test_given_tank_and_own_bullet_at_same_position_when_collision_checked_then_returns_false():
	# Given: A tank and its own bullet at same position
	var pos = Position.create(5, 5)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, pos, Direction.create(Direction.UP))
	var bullet = BulletEntity.create("bullet_1", "tank_1", pos, Direction.create(Direction.UP), 2, 1)
	
	# When: Collision is checked
	var collided = CollisionService.check_tank_bullet_collision(tank, bullet)
	
	# Then: No collision (tank can't collide with own bullet)
	assert_false(collided, "Tank should not collide with own bullet")

func test_given_tank_and_bullet_at_different_positions_when_collision_checked_then_returns_false():
	# Given: A tank and bullet at different positions
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(5, 5), Direction.create(Direction.UP))
	var bullet = BulletEntity.create("bullet_1", "other_tank", Position.create(7, 7), Direction.create(Direction.UP), 2, 1)
	
	# When: Collision is checked
	var collided = CollisionService.check_tank_bullet_collision(tank, bullet)
	
	# Then: No collision
	assert_false(collided, "Tank and bullet at different positions should not collide")

func test_given_dead_tank_and_bullet_when_collision_checked_then_returns_false():
	# Given: A dead tank and bullet at same position
	var pos = Position.create(5, 5)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, pos, Direction.create(Direction.UP))
	tank.take_damage(tank.health.current) # Kill tank
	var bullet = BulletEntity.create("bullet_1", "other_tank", pos, Direction.create(Direction.UP), 2, 1)
	
	# When: Collision is checked
	var collided = CollisionService.check_tank_bullet_collision(tank, bullet)
	
	# Then: No collision (dead tanks don't collide)
	assert_false(collided, "Dead tank should not collide")

func test_given_inactive_bullet_and_tank_when_collision_checked_then_returns_false():
	# Given: A tank and inactive bullet at same position
	var pos = Position.create(5, 5)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, pos, Direction.create(Direction.UP))
	var bullet = BulletEntity.create("bullet_1", "other_tank", pos, Direction.create(Direction.UP), 2, 1)
	bullet.deactivate()
	
	# When: Collision is checked
	var collided = CollisionService.check_tank_bullet_collision(tank, bullet)
	
	# Then: No collision (inactive bullets don't collide)
	assert_false(collided, "Inactive bullet should not collide")

## Test: Tank-Terrain Collision Detection
func test_given_tank_and_brick_terrain_at_same_position_when_collision_checked_then_returns_true():
	# Given: A tank and brick terrain at same position
	var pos = Position.create(5, 5)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, pos, Direction.create(Direction.UP))
	var terrain = TerrainCell.create(pos, TerrainCell.CellType.BRICK)
	
	# When: Collision is checked
	var collided = CollisionService.check_tank_terrain_collision(tank, terrain)
	
	# Then: Collision is detected
	assert_true(collided, "Tank should collide with brick terrain")

func test_given_tank_and_steel_terrain_at_same_position_when_collision_checked_then_returns_true():
	# Given: A tank and steel terrain at same position
	var pos = Position.create(5, 5)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, pos, Direction.create(Direction.UP))
	var terrain = TerrainCell.create(pos, TerrainCell.CellType.STEEL)
	
	# When: Collision is checked
	var collided = CollisionService.check_tank_terrain_collision(tank, terrain)
	
	# Then: Collision is detected
	assert_true(collided, "Tank should collide with steel terrain")

func test_given_tank_and_water_terrain_at_same_position_when_collision_checked_then_returns_true():
	# Given: A tank and water terrain at same position
	var pos = Position.create(5, 5)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, pos, Direction.create(Direction.UP))
	var terrain = TerrainCell.create(pos, TerrainCell.CellType.WATER)
	
	# When: Collision is checked
	var collided = CollisionService.check_tank_terrain_collision(tank, terrain)
	
	# Then: Collision is detected
	assert_true(collided, "Tank should collide with water terrain")

func test_given_tank_and_empty_terrain_at_same_position_when_collision_checked_then_returns_false():
	# Given: A tank and empty terrain at same position
	var pos = Position.create(5, 5)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, pos, Direction.create(Direction.UP))
	var terrain = TerrainCell.create(pos, TerrainCell.CellType.EMPTY)
	
	# When: Collision is checked
	var collided = CollisionService.check_tank_terrain_collision(tank, terrain)
	
	# Then: No collision (empty terrain is passable)
	assert_false(collided, "Tank should not collide with empty terrain")

func test_given_tank_and_destroyed_brick_when_collision_checked_then_returns_false():
	# Given: A tank and destroyed brick at same position
	var pos = Position.create(5, 5)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, pos, Direction.create(Direction.UP))
	var terrain = TerrainCell.create(pos, TerrainCell.CellType.BRICK)
	terrain.take_damage(1) # Destroy brick
	
	# When: Collision is checked
	var collided = CollisionService.check_tank_terrain_collision(tank, terrain)
	
	# Then: No collision (destroyed terrain is passable)
	assert_false(collided, "Tank should not collide with destroyed terrain")

## Test: Bullet-Terrain Collision Detection
func test_given_bullet_and_brick_terrain_at_same_position_when_collision_checked_then_returns_true():
	# Given: A bullet and brick terrain at same position
	var pos = Position.create(5, 5)
	var bullet = BulletEntity.create("bullet_1", "tank_1", pos, Direction.create(Direction.UP), 2, 1)
	var terrain = TerrainCell.create(pos, TerrainCell.CellType.BRICK)
	
	# When: Collision is checked
	var collided = CollisionService.check_bullet_terrain_collision(bullet, terrain)
	
	# Then: Collision is detected
	assert_true(collided, "Bullet should collide with brick terrain")

func test_given_bullet_and_steel_terrain_at_same_position_when_collision_checked_then_returns_true():
	# Given: A bullet and steel terrain at same position
	var pos = Position.create(5, 5)
	var bullet = BulletEntity.create("bullet_1", "tank_1", pos, Direction.create(Direction.UP), 2, 1)
	var terrain = TerrainCell.create(pos, TerrainCell.CellType.STEEL)
	
	# When: Collision is checked
	var collided = CollisionService.check_bullet_terrain_collision(bullet, terrain)
	
	# Then: Collision is detected
	assert_true(collided, "Bullet should collide with steel terrain")

func test_given_bullet_and_water_terrain_at_same_position_when_collision_checked_then_returns_false():
	# Given: A bullet and water terrain at same position
	var pos = Position.create(5, 5)
	var bullet = BulletEntity.create("bullet_1", "tank_1", pos, Direction.create(Direction.UP), 2, 1)
	var terrain = TerrainCell.create(pos, TerrainCell.CellType.WATER)
	
	# When: Collision is checked
	var collided = CollisionService.check_bullet_terrain_collision(bullet, terrain)
	
	# Then: No collision (bullets pass over water)
	assert_false(collided, "Bullet should not collide with water")

## Test: Tank-Tank Collision Detection
func test_given_two_tanks_at_same_position_when_collision_checked_then_returns_true():
	# Given: Two tanks at same position
	var pos = Position.create(5, 5)
	var tank1 = TankEntity.create("tank_1", TankEntity.Type.PLAYER, pos, Direction.create(Direction.UP))
	var tank2 = TankEntity.create("tank_2", TankEntity.Type.ENEMY_BASIC, pos, Direction.create(Direction.DOWN))
	
	# When: Collision is checked
	var collided = CollisionService.check_tank_tank_collision(tank1, tank2)
	
	# Then: Collision is detected
	assert_true(collided, "Two tanks at same position should collide")

func test_given_two_tanks_at_different_positions_when_collision_checked_then_returns_false():
	# Given: Two tanks at different positions
	var tank1 = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(5, 5), Direction.create(Direction.UP))
	var tank2 = TankEntity.create("tank_2", TankEntity.Type.ENEMY_BASIC, Position.create(7, 7), Direction.create(Direction.DOWN))
	
	# When: Collision is checked
	var collided = CollisionService.check_tank_tank_collision(tank1, tank2)
	
	# Then: No collision
	assert_false(collided, "Two tanks at different positions should not collide")

func test_given_one_dead_tank_when_collision_checked_then_returns_false():
	# Given: One alive tank and one dead tank at same position
	var pos = Position.create(5, 5)
	var tank1 = TankEntity.create("tank_1", TankEntity.Type.PLAYER, pos, Direction.create(Direction.UP))
	var tank2 = TankEntity.create("tank_2", TankEntity.Type.ENEMY_BASIC, pos, Direction.create(Direction.DOWN))
	tank2.take_damage(tank2.health.current) # Kill tank2
	
	# When: Collision is checked
	var collided = CollisionService.check_tank_tank_collision(tank1, tank2)
	
	# Then: No collision (dead tanks don't collide)
	assert_false(collided, "Dead tank should not collide")

## Test: Bullet-Base Collision Detection
func test_given_bullet_and_base_at_same_position_when_collision_checked_then_returns_true():
	# Given: A bullet and base at same position
	var pos = Position.create(12, 24)
	var bullet = BulletEntity.create("bullet_1", "tank_1", pos, Direction.create(Direction.UP), 2, 1)
	var base = BaseEntity.create("base", pos, 1)
	
	# When: Collision is checked
	var collided = CollisionService.check_bullet_base_collision(bullet, base)
	
	# Then: Collision is detected
	assert_true(collided, "Bullet and base at same position should collide")

func test_given_bullet_and_base_at_different_positions_when_collision_checked_then_returns_false():
	# Given: A bullet and base at different positions
	var bullet = BulletEntity.create("bullet_1", "tank_1", Position.create(5, 5), Direction.create(Direction.UP), 2, 1)
	var base = BaseEntity.create("base", Position.create(12, 24), 1)
	
	# When: Collision is checked
	var collided = CollisionService.check_bullet_base_collision(bullet, base)
	
	# Then: No collision
	assert_false(collided, "Bullet and base at different positions should not collide")

func test_given_inactive_bullet_and_base_when_collision_checked_then_returns_false():
	# Given: An inactive bullet and base at same position
	var pos = Position.create(12, 24)
	var bullet = BulletEntity.create("bullet_1", "tank_1", pos, Direction.create(Direction.UP), 2, 1)
	bullet.deactivate()
	var base = BaseEntity.create("base", pos, 1)
	
	# When: Collision is checked
	var collided = CollisionService.check_bullet_base_collision(bullet, base)
	
	# Then: No collision (inactive bullets don't collide)
	assert_false(collided, "Inactive bullet should not collide")

func test_given_destroyed_base_and_bullet_when_collision_checked_then_returns_false():
	# Given: A bullet and destroyed base at same position
	var pos = Position.create(12, 24)
	var bullet = BulletEntity.create("bullet_1", "tank_1", pos, Direction.create(Direction.UP), 2, 1)
	var base = BaseEntity.create("base", pos, 1)
	base.take_damage(1) # Destroy base
	
	# When: Collision is checked
	var collided = CollisionService.check_bullet_base_collision(bullet, base)
	
	# Then: No collision (destroyed base doesn't collide)
	assert_false(collided, "Destroyed base should not collide")

## Test: Find Terrain at Position
func test_given_stage_with_terrain_when_finding_terrain_at_position_then_returns_correct_cell():
	# Given: A stage with terrain at specific position
	var stage = StageState.create(1, 26, 26)
	var pos = Position.create(5, 5)
	var terrain = TerrainCell.create(pos, TerrainCell.CellType.BRICK)
	stage.add_terrain_cell(terrain)
	
	# When: Finding terrain at position
	var found = CollisionService.find_terrain_at_position(stage, pos)
	
	# Then: Correct terrain cell is returned
	assert_not_null(found, "Should find terrain at position")
	assert_eq(found.cell_type, TerrainCell.CellType.BRICK, "Should return correct terrain type")

func test_given_stage_without_terrain_at_position_when_finding_terrain_then_returns_null():
	# Given: A stage with no terrain at specific position
	var stage = StageState.create(1, 26, 26)
	var pos = Position.create(5, 5)
	
	# When: Finding terrain at position
	var found = CollisionService.find_terrain_at_position(stage, pos)
	
	# Then: Returns null
	assert_null(found, "Should return null when no terrain at position")

## Test: Position Blocked for Tank
func test_given_position_with_brick_terrain_when_checking_blocked_then_returns_true():
	# Given: A stage with brick terrain at position
	var stage = StageState.create(1, 26, 26)
	var pos = Position.create(5, 5)
	var terrain = TerrainCell.create(pos, TerrainCell.CellType.BRICK)
	stage.add_terrain_cell(terrain)
	
	# When: Checking if position is blocked
	var blocked = CollisionService.is_position_blocked_for_tank(stage, pos, null)
	
	# Then: Position is blocked
	assert_true(blocked, "Position with brick should be blocked for tank")

func test_given_position_with_empty_terrain_when_checking_blocked_then_returns_false():
	# Given: A stage with empty terrain at position
	var stage = StageState.create(1, 26, 26)
	var pos = Position.create(5, 5)
	
	# When: Checking if position is blocked
	var blocked = CollisionService.is_position_blocked_for_tank(stage, pos, null)
	
	# Then: Position is not blocked
	assert_false(blocked, "Position with no terrain should not be blocked")

func test_given_position_out_of_bounds_when_checking_blocked_then_returns_true():
	# Given: A stage and position out of bounds
	var stage = StageState.create(1, 26, 26)
	var pos = Position.create(-1, 5)
	
	# When: Checking if position is blocked
	var blocked = CollisionService.is_position_blocked_for_tank(stage, pos, null)
	
	# Then: Position is blocked
	assert_true(blocked, "Out of bounds position should be blocked")

## Test: Position Occupied by Tank
func test_given_position_with_tank_when_checking_occupied_then_returns_true():
	# Given: A game state with tank at position
	var game_state = GameState.create(StageState.create(1, 26, 26))
	var pos = Position.create(5, 5)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, pos, Direction.create(Direction.UP))
	game_state.add_tank(tank)
	
	# When: Checking if position is occupied
	var occupied = CollisionService.is_position_occupied_by_tank(game_state, pos, null)
	
	# Then: Position is occupied
	assert_true(occupied, "Position with tank should be occupied")

func test_given_position_without_tank_when_checking_occupied_then_returns_false():
	# Given: A game state with no tank at position
	var game_state = GameState.create(StageState.create(1, 26, 26))
	var pos = Position.create(5, 5)
	
	# When: Checking if position is occupied
	var occupied = CollisionService.is_position_occupied_by_tank(game_state, pos, null)
	
	# Then: Position is not occupied
	assert_false(occupied, "Position without tank should not be occupied")

func test_given_position_with_ignored_tank_when_checking_occupied_then_returns_false():
	# Given: A game state with tank at position, but we're ignoring it
	var game_state = GameState.create(StageState.create(1, 26, 26))
	var pos = Position.create(5, 5)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, pos, Direction.create(Direction.UP))
	game_state.add_tank(tank)
	
	# When: Checking if position is occupied, ignoring tank_1
	var occupied = CollisionService.is_position_occupied_by_tank(game_state, pos, "tank_1")
	
	# Then: Position is not occupied (ignoring the tank)
	assert_false(occupied, "Position should not be occupied when ignoring the tank there")

func test_given_position_with_dead_tank_when_checking_occupied_then_returns_false():
	# Given: A game state with dead tank at position
	var game_state = GameState.create(StageState.create(1, 26, 26))
	var pos = Position.create(5, 5)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, pos, Direction.create(Direction.UP))
	tank.take_damage(tank.health.current) # Kill tank
	game_state.add_tank(tank)
	
	# When: Checking if position is occupied
	var occupied = CollisionService.is_position_occupied_by_tank(game_state, pos, null)
	
	# Then: Position is not occupied (dead tanks don't occupy)
	assert_false(occupied, "Position with dead tank should not be occupied")
