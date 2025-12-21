extends GutTest

## BDD Tests for CollisionService
## Test-first approach: Write behavior tests before implementation

const CollisionService = preload("res://src/domain/services/collision_service.gd")
const MovementService = preload("res://src/domain/services/movement_service.gd")
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

## Test: Bullet-to-Bullet Collision Detection (Phase 2.3)
func test_given_two_bullets_at_same_position_when_check_collision_then_returns_true():
	# Given: Two bullets from different owners at same position
	var pos = Position.create(100, 100)
	var bullet1 = BulletEntity.create("bullet_1", "tank_1", pos, Direction.create(Direction.UP), 2, 1)
	var bullet2 = BulletEntity.create("bullet_2", "tank_2", pos, Direction.create(Direction.DOWN), 2, 1)
	
	# When: Check collision
	var collided = CollisionService.check_bullet_to_bullet_collision(bullet1, bullet2)
	
	# Then: Should return true
	assert_true(collided, "Bullets at same position should collide")

func test_given_bullets_from_same_owner_when_check_collision_then_returns_false():
	# Given: Two bullets from same owner at same position
	var pos = Position.create(100, 100)
	var bullet1 = BulletEntity.create("bullet_1", "tank_1", pos, Direction.create(Direction.UP), 2, 1)
	var bullet2 = BulletEntity.create("bullet_2", "tank_1", pos, Direction.create(Direction.DOWN), 2, 1)
	
	# When: Check collision
	var collided = CollisionService.check_bullet_to_bullet_collision(bullet1, bullet2)
	
	# Then: Should return false
	assert_false(collided, "Bullets from same owner should not collide")

func test_given_inactive_bullet_when_check_collision_then_returns_false():
	# Given: One inactive bullet
	var pos = Position.create(100, 100)
	var bullet1 = BulletEntity.create("bullet_1", "tank_1", pos, Direction.create(Direction.UP), 2, 1)
	var bullet2 = BulletEntity.create("bullet_2", "tank_2", pos, Direction.create(Direction.DOWN), 2, 1)
	bullet1.deactivate()
	
	# When: Check collision
	var collided = CollisionService.check_bullet_to_bullet_collision(bullet1, bullet2)
	
	# Then: Should return false
	assert_false(collided, "Inactive bullet should not collide")

## Test: Grid-Based Bullet-to-Bullet Collision (New Grid-Only Logic)
## These tests verify exact grid position matching for bullet collision

func test_given_two_active_bullets_at_same_exact_grid_position_when_collision_checked_then_returns_true():
	# Given: Two active bullets from different owners at exact same grid position
	var pos = Position.create(5, 5)
	var bullet1 = BulletEntity.create("bullet_1", "tank_1", pos, Direction.create(Direction.UP), 2, 1)
	var bullet2 = BulletEntity.create("bullet_2", "tank_2", pos, Direction.create(Direction.DOWN), 2, 1)
	
	# When: Collision is checked
	var collided = CollisionService.check_bullet_to_bullet_collision(bullet1, bullet2)
	
	# Then: Collision is detected
	assert_true(collided, "Two active bullets at exact same grid position should collide")

func test_given_two_active_bullets_at_different_grid_positions_when_collision_checked_then_returns_false():
	# Given: Two active bullets at different grid positions (even if visually close)
	var bullet1 = BulletEntity.create("bullet_1", "tank_1", Position.create(5, 5), Direction.create(Direction.UP), 2, 1)
	var bullet2 = BulletEntity.create("bullet_2", "tank_2", Position.create(6, 5), Direction.create(Direction.DOWN), 2, 1)
	
	# When: Collision is checked
	var collided = CollisionService.check_bullet_to_bullet_collision(bullet1, bullet2)
	
	# Then: No collision (different grid positions)
	assert_false(collided, "Bullets at different grid positions should not collide, even if adjacent")

func test_given_bullets_in_same_tile_but_different_vertices_when_collision_checked_then_returns_false():
	# Given: Two bullets in adjacent grid positions (same tile at 0.5 precision, different vertices)
	var bullet1 = BulletEntity.create("bullet_1", "tank_1", Position.create(10, 10), Direction.create(Direction.UP), 2, 1)
	var bullet2 = BulletEntity.create("bullet_2", "tank_2", Position.create(10, 11), Direction.create(Direction.DOWN), 2, 1)
	
	# When: Collision is checked
	var collided = CollisionService.check_bullet_to_bullet_collision(bullet1, bullet2)
	
	# Then: No collision (different grid positions means different vertices)
	assert_false(collided, "Bullets at adjacent grid positions should not collide")

func test_given_bullets_with_fractional_step_positions_when_at_same_grid_position_then_collides():
	# Given: Bullets that moved with fractional steps (0.125) but landed at same grid position
	# Simulating Position(8, 8) which could be reached by various fractional movements
	var pos = Position.create(8, 8)
	var bullet1 = BulletEntity.create("bullet_1", "tank_1", pos, Direction.create(Direction.RIGHT), 2, 1)
	var bullet2 = BulletEntity.create("bullet_2", "tank_2", pos, Direction.create(Direction.LEFT), 2, 1)
	
	# When: Collision is checked
	var collided = CollisionService.check_bullet_to_bullet_collision(bullet1, bullet2)
	
	# Then: Collision is detected (same integer grid position)
	assert_true(collided, "Bullets with fractional movement history at same grid position should collide")

func test_given_bullets_at_grid_edge_boundaries_when_at_same_position_then_collides():
	# Given: Two bullets at edge boundary positions (grid bounds)
	var edge_positions = [
		Position.create(0, 0), # Top-left corner
		Position.create(25, 0), # Top-right corner
		Position.create(0, 25), # Bottom-left corner
		Position.create(25, 25), # Bottom-right corner
		Position.create(12, 0), # Top edge
		Position.create(0, 12) # Left edge
	]
	
	for pos in edge_positions:
		# Given: Two bullets at edge boundary position
		var bullet1 = BulletEntity.create("bullet_1", "tank_1", pos, Direction.create(Direction.UP), 2, 1)
		var bullet2 = BulletEntity.create("bullet_2", "tank_2", pos, Direction.create(Direction.DOWN), 2, 1)
		
		# When: Collision is checked
		var collided = CollisionService.check_bullet_to_bullet_collision(bullet1, bullet2)
		
		# Then: Collision is detected at edge boundaries
		assert_true(collided, "Bullets at edge boundary position %s should collide" % pos)

func test_given_multiple_bullets_at_same_grid_position_when_checked_pairwise_then_all_collide():
	# Given: Three bullets from different owners at same grid position
	var pos = Position.create(10, 10)
	var bullet1 = BulletEntity.create("bullet_1", "tank_1", pos, Direction.create(Direction.UP), 2, 1)
	var bullet2 = BulletEntity.create("bullet_2", "tank_2", pos, Direction.create(Direction.DOWN), 2, 1)
	var bullet3 = BulletEntity.create("bullet_3", "tank_3", pos, Direction.create(Direction.LEFT), 2, 1)
	
	# When: Checking all pairwise collisions
	var collided_1_2 = CollisionService.check_bullet_to_bullet_collision(bullet1, bullet2)
	var collided_1_3 = CollisionService.check_bullet_to_bullet_collision(bullet1, bullet3)
	var collided_2_3 = CollisionService.check_bullet_to_bullet_collision(bullet2, bullet3)
	
	# Then: All pairs should collide
	assert_true(collided_1_2, "Bullet 1 and 2 should collide at same position")
	assert_true(collided_1_3, "Bullet 1 and 3 should collide at same position")
	assert_true(collided_2_3, "Bullet 2 and 3 should collide at same position")

func test_given_bullets_moving_opposite_directions_at_same_grid_position_when_collision_checked_then_returns_true():
	# Given: Two bullets moving in opposite directions at same grid position
	var pos = Position.create(12, 12)
	var bullet1 = BulletEntity.create("bullet_1", "tank_1", pos, Direction.create(Direction.UP), 2, 1)
	var bullet2 = BulletEntity.create("bullet_2", "tank_2", pos, Direction.create(Direction.DOWN), 2, 1)
	
	# When: Collision is checked
	var collided = CollisionService.check_bullet_to_bullet_collision(bullet1, bullet2)
	
	# Then: Collision is detected (direction doesn't matter, only position)
	assert_true(collided, "Bullets at same position should collide regardless of direction")

func test_given_bullets_at_diagonal_adjacent_positions_when_collision_checked_then_returns_false():
	# Given: Two bullets at diagonal adjacent positions
	var bullet1 = BulletEntity.create("bullet_1", "tank_1", Position.create(10, 10), Direction.create(Direction.UP), 2, 1)
	var bullet2 = BulletEntity.create("bullet_2", "tank_2", Position.create(11, 11), Direction.create(Direction.DOWN), 2, 1)
	
	# When: Collision is checked
	var collided = CollisionService.check_bullet_to_bullet_collision(bullet1, bullet2)
	
	# Then: No collision (diagonal positions don't match exactly)
	assert_false(collided, "Bullets at diagonal adjacent positions should not collide")

func test_given_same_bullet_positions_when_checked_multiple_times_then_results_are_deterministic():
	# Given: Two bullets at same position
	var pos = Position.create(15, 15)
	var bullet1 = BulletEntity.create("bullet_1", "tank_1", pos, Direction.create(Direction.UP), 2, 1)
	var bullet2 = BulletEntity.create("bullet_2", "tank_2", pos, Direction.create(Direction.DOWN), 2, 1)
	
	# When: Checking collision multiple times
	var results = []
	for i in range(100):
		results.append(CollisionService.check_bullet_to_bullet_collision(bullet1, bullet2))
	
	# Then: All results should be identical (deterministic)
	var first_result = results[0]
	for result in results:
		assert_eq(result, first_result, "Collision check should be deterministic across multiple calls")
	assert_true(first_result, "Bullets at same position should always collide")

func test_given_two_bullets_when_collision_checked_in_either_order_then_results_are_identical():
	# Given: Two bullets at same position
	var pos = Position.create(7, 7)
	var bullet1 = BulletEntity.create("bullet_1", "tank_1", pos, Direction.create(Direction.RIGHT), 2, 1)
	var bullet2 = BulletEntity.create("bullet_2", "tank_2", pos, Direction.create(Direction.LEFT), 2, 1)
	
	# When: Checking collision in both orders
	var collided_1_2 = CollisionService.check_bullet_to_bullet_collision(bullet1, bullet2)
	var collided_2_1 = CollisionService.check_bullet_to_bullet_collision(bullet2, bullet1)
	
	# Then: Results should be identical (commutative)
	assert_eq(collided_1_2, collided_2_1, "Collision check should be order-independent")
	assert_true(collided_1_2, "Bullets at same position should collide regardless of check order")
## ============================================================================
## Test: Multi-Tile Tank Hitbox Collision Detection
## Tanks are 4 units wide × 3 units long (hitbox)
## 4th visual unit is NOT part of collision hitbox
## ============================================================================

## Test: Tank-Bullet Collision with Multi-Tile Hitbox
func test_given_bullet_at_tank_hitbox_front_tile_when_collision_checked_then_returns_true():
	# Given: Tank at (10, 10) facing NORTH, bullet at front-left tile (8, 8)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	var bullet = BulletEntity.create("bullet_1", "other_tank", Position.create(8, 8), Direction.create(Direction.UP), 2, 1)
	
	# When: Collision is checked
	var collided = CollisionService.check_tank_bullet_collision(tank, bullet)
	
	# Then: Collision should be detected (bullet hits front tile of hitbox)
	assert_true(collided, "Bullet at front tile of multi-tile hitbox should collide with tank")

func test_given_bullet_at_tank_hitbox_back_tile_when_collision_checked_then_returns_true():
	# Given: Tank at (10, 10) facing NORTH, bullet at back-left tile (8, 10)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	var bullet = BulletEntity.create("bullet_1", "other_tank", Position.create(8, 10), Direction.create(Direction.UP), 2, 1)
	
	# When: Collision is checked
	var collided = CollisionService.check_tank_bullet_collision(tank, bullet)
	
	# Then: Collision should be detected (bullet hits back tile of hitbox)
	assert_true(collided, "Bullet at back tile of multi-tile hitbox should collide with tank")

func test_given_bullet_at_tank_hitbox_side_tile_when_collision_checked_then_returns_true():
	# Given: Tank at (10, 10) facing NORTH, bullet at right-middle tile (11, 9)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	var bullet = BulletEntity.create("bullet_1", "other_tank", Position.create(11, 9), Direction.create(Direction.UP), 2, 1)
	
	# When: Collision is checked
	var collided = CollisionService.check_tank_bullet_collision(tank, bullet)
	
	# Then: Collision should be detected (bullet hits side tile of hitbox)
	assert_true(collided, "Bullet at side tile of multi-tile hitbox should collide with tank")

func test_given_bullet_at_4th_visual_unit_when_collision_checked_then_returns_false():
	# Given: Tank at (10, 10) facing NORTH, bullet at 4th unit (10, 7) - BEYOND hitbox
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	var bullet = BulletEntity.create("bullet_1", "other_tank", Position.create(10, 7), Direction.create(Direction.UP), 2, 1)
	
	# When: Collision is checked
	var collided = CollisionService.check_tank_bullet_collision(tank, bullet)
	
	# Then: NO collision (4th unit is visual only, NOT part of hitbox)
	assert_false(collided, "Bullet at 4th visual unit (beyond 3-tile hitbox) should NOT collide")

func test_given_bullet_moving_past_4th_unit_when_collision_checked_then_returns_false():
	# Given: Tank at (10, 10) facing EAST, bullet just past 4th unit at (13, 10)
	# Tank EAST hitbox: x=10,11,12 (3 long), y=8,9,10,11 (4 wide)
	# Bullet at x=13 is beyond the 3-tile hitbox (4th visual unit position)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.RIGHT))
	var bullet = BulletEntity.create("bullet_1", "other_tank", Position.create(13, 10), Direction.create(Direction.RIGHT), 2, 1)
	
	# When: Collision is checked
	var collided = CollisionService.check_tank_bullet_collision(tank, bullet)
	
	# Then: NO collision (bullet beyond hitbox)
	assert_false(collided, "Bullet moving past 4th visual unit should NOT hit tank")

func test_given_bullet_at_corner_of_hitbox_when_collision_checked_then_returns_true():
	# Given: Tank at (10, 10) facing SOUTH, bullet at front-left corner (8, 12)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.DOWN))
	var bullet = BulletEntity.create("bullet_1", "other_tank", Position.create(8, 12), Direction.create(Direction.UP), 2, 1)
	
	# When: Collision is checked
	var collided = CollisionService.check_tank_bullet_collision(tank, bullet)
	
	# Then: Collision should be detected (bullet at valid hitbox corner)
	assert_true(collided, "Bullet at corner of multi-tile hitbox should collide")

## Test: Tank-Tank Collision with Multi-Tile Hitboxes
func test_given_two_tanks_hitboxes_overlap_at_one_tile_when_collision_checked_then_returns_true():
	# Given: Tank1 at (10, 10) facing NORTH, Tank2 at (11, 9) facing EAST
	# Tank1 hitbox includes (11, 9), Tank2 center is at (11, 9)
	var tank1 = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	var tank2 = TankEntity.create("tank_2", TankEntity.Type.ENEMY_BASIC, Position.create(11, 9), Direction.create(Direction.RIGHT))
	
	# When: Collision is checked
	var collided = CollisionService.check_tank_tank_collision(tank1, tank2)
	
	# Then: Collision should be detected (hitboxes overlap)
	assert_true(collided, "Tanks with overlapping multi-tile hitboxes should collide")

func test_given_two_tanks_hitboxes_touch_at_edge_when_collision_checked_then_returns_false():
	# Given: Tank1 at (5, 10) facing EAST, Tank2 at (10, 10) facing WEST
	# Tank1 EAST: x=5,6,7 (ends at x=7), Tank2 WEST: x=8,9,10 (starts at x=8)
	# They are adjacent but do not overlap (x=7 and x=8 are different tiles)
	var tank1 = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(5, 10), Direction.create(Direction.RIGHT))
	var tank2 = TankEntity.create("tank_2", TankEntity.Type.ENEMY_BASIC, Position.create(10, 10), Direction.create(Direction.LEFT))
	
	# When: Collision is checked
	var collided = CollisionService.check_tank_tank_collision(tank1, tank2)
	
	# Then: NO collision (hitboxes adjacent but not overlapping)
	assert_false(collided, "Tanks with adjacent but non-overlapping hitboxes should NOT collide")

func test_given_two_tanks_parallel_different_rows_when_collision_checked_then_returns_false():
	# Given: Tank1 at (10, 10) facing NORTH, Tank2 at (15, 10) facing NORTH
	# Both face same direction, sufficiently separated in X axis
	var tank1 = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	var tank2 = TankEntity.create("tank_2", TankEntity.Type.ENEMY_BASIC, Position.create(15, 10), Direction.create(Direction.UP))
	
	# When: Collision is checked
	var collided = CollisionService.check_tank_tank_collision(tank1, tank2)
	
	# Then: NO collision (tanks in different rows, no overlap)
	assert_false(collided, "Tanks in parallel formation without overlap should NOT collide")

func test_given_tanks_perpendicular_hitboxes_overlap_when_collision_checked_then_returns_true():
	# Given: Tank1 at (10, 10) facing NORTH (4 wide in X, 3 long in Y)
	#        Tank2 at (9, 9) facing EAST (3 long in X, 4 wide in Y)
	# Tank1 includes tile (9, 9), Tank2 center is at (9, 9) - definite overlap
	var tank1 = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	var tank2 = TankEntity.create("tank_2", TankEntity.Type.ENEMY_BASIC, Position.create(9, 9), Direction.create(Direction.RIGHT))
	
	# When: Collision is checked
	var collided = CollisionService.check_tank_tank_collision(tank1, tank2)
	
	# Then: Collision should be detected
	assert_true(collided, "Tanks with perpendicular hitboxes that overlap should collide")

## Test: Tank-Terrain Collision with Multi-Tile Hitbox
func test_given_brick_at_tank_front_hitbox_tile_when_collision_checked_then_returns_true():
	# Given: Tank at (10, 10) facing NORTH, brick at front tile (10, 8)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	var terrain = TerrainCell.create(Position.create(10, 8), TerrainCell.CellType.BRICK)
	
	# When: Collision is checked
	var collided = CollisionService.check_tank_terrain_collision(tank, terrain)
	
	# Then: Collision should be detected (brick at front hitbox tile)
	assert_true(collided, "Brick at front of multi-tile tank hitbox should collide")

func test_given_brick_at_tank_back_hitbox_tile_when_collision_checked_then_returns_true():
	# Given: Tank at (10, 10) facing NORTH, brick at back tile (11, 10)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	var terrain = TerrainCell.create(Position.create(11, 10), TerrainCell.CellType.BRICK)
	
	# When: Collision is checked
	var collided = CollisionService.check_tank_terrain_collision(tank, terrain)
	
	# Then: Collision should be detected (brick at back hitbox tile)
	assert_true(collided, "Brick at back of multi-tile tank hitbox should collide")

func test_given_brick_at_4th_visual_unit_when_collision_checked_then_returns_false():
	# Given: Tank at (10, 10) facing NORTH, brick at 4th unit (10, 7) - beyond hitbox
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	var terrain = TerrainCell.create(Position.create(10, 7), TerrainCell.CellType.BRICK)
	
	# When: Collision is checked
	var collided = CollisionService.check_tank_terrain_collision(tank, terrain)
	
	# Then: NO collision (4th unit not part of hitbox)
	assert_false(collided, "Brick at 4th visual unit should NOT collide with tank hitbox")

func test_given_water_at_tank_side_hitbox_tile_when_collision_checked_then_returns_true():
	# Given: Tank at (10, 10) facing EAST, water at side tile (10, 8)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.RIGHT))
	var terrain = TerrainCell.create(Position.create(10, 8), TerrainCell.CellType.WATER)
	
	# When: Collision is checked
	var collided = CollisionService.check_tank_terrain_collision(tank, terrain)
	
	# Then: Collision should be detected (water at hitbox tile)
	assert_true(collided, "Water at side of multi-tile tank hitbox should collide")

func test_given_steel_at_tank_corner_hitbox_tile_when_collision_checked_then_returns_true():
	# Given: Tank at (10, 10) facing WEST, steel at corner tile (8, 11)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.LEFT))
	var terrain = TerrainCell.create(Position.create(8, 11), TerrainCell.CellType.STEEL)
	
	# When: Collision is checked
	var collided = CollisionService.check_tank_terrain_collision(tank, terrain)
	
	# Then: Collision should be detected (steel at corner hitbox tile)
	assert_true(collided, "Steel at corner of multi-tile tank hitbox should collide")

## Test: Movement Validation with Multi-Tile Hitbox
func test_given_tank_front_edge_blocked_by_brick_when_move_validated_then_returns_false():
	# Given: Game state with tank at (10, 10) facing NORTH
	#        Brick wall at y=7 blocking front edge (beyond 3-tile hitbox at y=8)
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage, 3)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	game_state.add_tank(tank)
	
	# Add brick at (10, 6) - would block movement from (10, 10) to (10, 9)
	# When tank moves to (10, 9), front hitbox tile would be at (10, 7)
	# Then moving to (10, 8) would put front tile at (10, 6)
	stage.add_terrain_cell(TerrainCell.create(Position.create(10, 6), TerrainCell.CellType.BRICK))
	
	# When: Check if tank can move multiple steps forward
	var target_pos = Position.create(10, 8) # Move 2 steps forward
	var can_move = MovementService.can_tank_move_to(game_state, tank, target_pos)
	
	# Then: Movement should be blocked (front hitbox tile would hit brick)
	assert_false(can_move, "Tank should be blocked when front edge of multi-tile hitbox would hit brick")

func test_given_tank_side_blocked_by_water_when_move_validated_then_returns_false():
	# Given: Game state with tank at (10, 10) facing EAST
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage, 3)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.RIGHT))
	game_state.add_tank(tank)
	
	# Add water at (10, 7) - would block side of hitbox when tank moves up
	# Tank EAST at (10, 10): x=10,11,12, y=8,9,10,11
	# Moving to (10, 8) would give hitbox: x=10,11,12, y=6,7,8,9
	# Water at (10, 7) would be inside the new hitbox
	stage.add_terrain_cell(TerrainCell.create(Position.create(10, 7), TerrainCell.CellType.WATER))
	
	# When: Check if tank can move in direction where side would hit water
	var target_pos = Position.create(10, 8) # Move up
	var can_move = MovementService.can_tank_move_to(game_state, tank, target_pos)
	
	# Then: Movement should be blocked (water inside target hitbox)
	assert_false(can_move, "Tank should be blocked when any hitbox tile would hit water")

func test_given_tank_hitbox_would_overlap_other_tank_when_move_validated_then_returns_false():
	# Given: Game state with two tanks
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage, 3)
	var tank1 = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	var tank2 = TankEntity.create("tank_2", TankEntity.Type.ENEMY_BASIC, Position.create(10, 6), Direction.create(Direction.DOWN))
	game_state.add_tank(tank1)
	game_state.add_tank(tank2)
	
	# When: Tank1 tries to move toward Tank2 causing hitbox overlap
	# Tank1 at (10, 10) moving to (10, 8): front hitbox at (10, 6) overlaps Tank2
	var target_pos = Position.create(10, 8)
	var can_move = MovementService.can_tank_move_to(game_state, tank1, target_pos)
	
	# Then: Movement should be blocked (hitboxes would overlap)
	assert_false(can_move, "Tank movement should be blocked when multi-tile hitboxes would overlap")

func test_given_tank_near_grid_edge_when_move_would_go_out_of_bounds_then_returns_false():
	# Given: Game state with tank near edge at (2, 2) facing WEST
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage, 3)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(2, 2), Direction.create(Direction.LEFT))
	game_state.add_tank(tank)
	
	# When: Tank tries to move left (would put hitbox tiles at negative X)
	# Tank WEST at (2, 2): hitbox extends to x=0,1,2
	# Moving to (1, 2) would extend to x=-1,0,1 (out of bounds)
	var target_pos = Position.create(1, 2)
	var can_move = MovementService.can_tank_move_to(game_state, tank, target_pos)
	
	# Then: Movement should be blocked (hitbox would extend out of bounds)
	assert_false(can_move, "Tank should be blocked when multi-tile hitbox would extend out of bounds")

func test_given_tank_has_clear_path_when_move_validated_then_returns_true():
	# Given: Game state with tank at (10, 10) facing NORTH, clear path ahead
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage, 3)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	game_state.add_tank(tank)
	
	# When: Tank tries to move forward to clear space
	var target_pos = Position.create(10, 9)
	var can_move = MovementService.can_tank_move_to(game_state, tank, target_pos)
	
	# Then: Movement should be allowed (all hitbox tiles clear)
	assert_true(can_move, "Tank should be able to move when all multi-tile hitbox positions are clear")