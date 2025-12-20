extends GutTest

## BDD Tests for MovementService
## Test-first approach: Write behavior tests before implementation

const MovementService = preload("res://src/domain/services/movement_service.gd")
const CollisionService = preload("res://src/domain/services/collision_service.gd")
const TankEntity = preload("res://src/domain/entities/tank_entity.gd")
const BulletEntity = preload("res://src/domain/entities/bullet_entity.gd")
const TerrainCell = preload("res://src/domain/entities/terrain_cell.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")
const StageState = preload("res://src/domain/aggregates/stage_state.gd")
const GameState = preload("res://src/domain/aggregates/game_state.gd")

## Test: Tank Can Move To Position
func test_given_valid_position_when_checking_tank_can_move_then_returns_true():
	# Given: A game state with tank and valid target position
	var game_state = GameState.create(StageState.create(1, 26, 26))
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(5, 5), Direction.create(Direction.UP))
	game_state.add_tank(tank)
	var target_pos = Position.create(5, 4) # One tile up
	
	# When: Checking if tank can move to position
	var can_move = MovementService.can_tank_move_to(game_state, tank, target_pos)
	
	# Then: Tank can move
	assert_true(can_move, "Tank should be able to move to valid position")

func test_given_out_of_bounds_position_when_checking_tank_can_move_then_returns_false():
	# Given: A game state with tank and out of bounds target
	var game_state = GameState.create(StageState.create(1, 26, 26))
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(0, 0), Direction.create(Direction.UP))
	game_state.add_tank(tank)
	var target_pos = Position.create(0, -1) # Out of bounds
	
	# When: Checking if tank can move to position
	var can_move = MovementService.can_tank_move_to(game_state, tank, target_pos)
	
	# Then: Tank cannot move
	assert_false(can_move, "Tank should not be able to move out of bounds")

func test_given_position_with_brick_wall_when_checking_tank_can_move_then_returns_false():
	# Given: A game state with tank and brick wall at target
	var game_state = GameState.create(StageState.create(1, 26, 26))
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(5, 5), Direction.create(Direction.UP))
	game_state.add_tank(tank)
	var target_pos = Position.create(5, 4)
	var terrain = TerrainCell.create(target_pos, TerrainCell.CellType.BRICK)
	game_state.stage.add_terrain_cell(terrain)
	
	# When: Checking if tank can move to position
	var can_move = MovementService.can_tank_move_to(game_state, tank, target_pos)
	
	# Then: Tank cannot move through wall
	assert_false(can_move, "Tank should not be able to move through brick wall")

func test_given_position_occupied_by_another_tank_when_checking_can_move_then_returns_false():
	# Given: A game state with two tanks, one blocking the other
	var game_state = GameState.create(StageState.create(1, 26, 26))
	var tank1 = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(5, 5), Direction.create(Direction.UP))
	var tank2 = TankEntity.create("tank_2", TankEntity.Type.ENEMY_BASIC, Position.create(5, 4), Direction.create(Direction.DOWN))
	game_state.add_tank(tank1)
	game_state.add_tank(tank2)
	var target_pos = Position.create(5, 4) # Where tank2 is
	
	# When: Checking if tank1 can move to position
	var can_move = MovementService.can_tank_move_to(game_state, tank1, target_pos)
	
	# Then: Tank cannot move to occupied position
	assert_false(can_move, "Tank should not be able to move to position occupied by another tank")

func test_given_dead_tank_when_checking_can_move_then_returns_false():
	# Given: A dead tank
	var game_state = GameState.create(StageState.create(1, 26, 26))
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(5, 5), Direction.create(Direction.UP))
	tank.take_damage(tank.health.current) # Kill tank
	game_state.add_tank(tank)
	var target_pos = Position.create(5, 4)
	
	# When: Checking if dead tank can move
	var can_move = MovementService.can_tank_move_to(game_state, tank, target_pos)
	
	# Then: Dead tank cannot move
	assert_false(can_move, "Dead tank should not be able to move")

## Test: Execute Tank Movement
func test_given_valid_direction_when_executing_movement_then_tank_moves():
	# Given: A game state with tank and valid movement direction
	var game_state = GameState.create(StageState.create(1, 26, 26))
	var initial_pos = Position.create(5, 5)
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, initial_pos, Direction.create(Direction.UP))
	game_state.add_tank(tank)
	
	# When: Executing tank movement
	var moved = MovementService.execute_tank_movement(game_state, tank, Direction.create(Direction.UP))
	
	# Then: Tank moved and position changed
	assert_true(moved, "Tank should successfully move")
	assert_eq(tank.position.y, 4, "Tank should move up by 1 tile")
	assert_true(tank.is_moving, "Tank should be in moving state")

func test_given_blocked_direction_when_executing_movement_then_tank_does_not_move():
	# Given: A game state with tank facing a wall
	var game_state = GameState.create(StageState.create(1, 26, 26))
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(5, 5), Direction.create(Direction.UP))
	game_state.add_tank(tank)
	var blocked_pos = Position.create(5, 4)
	var terrain = TerrainCell.create(blocked_pos, TerrainCell.CellType.BRICK)
	game_state.stage.add_terrain_cell(terrain)
	
	# When: Executing tank movement toward wall
	var moved = MovementService.execute_tank_movement(game_state, tank, Direction.create(Direction.UP))
	
	# Then: Tank did not move
	assert_false(moved, "Tank should not move when blocked")
	assert_eq(tank.position.y, 5, "Tank position should not change")

func test_given_different_direction_when_executing_movement_then_tank_rotates():
	# Given: A tank facing UP
	var game_state = GameState.create(StageState.create(1, 26, 26))
	var tank = TankEntity.create("tank_1", TankEntity.Type.PLAYER, Position.create(5, 5), Direction.create(Direction.UP))
	game_state.add_tank(tank)
	
	# When: Executing movement in RIGHT direction
	var moved = MovementService.execute_tank_movement(game_state, tank, Direction.create(Direction.RIGHT))
	
	# Then: Tank rotated to RIGHT and moved
	assert_true(moved, "Tank should move in new direction")
	assert_eq(tank.direction.value, Direction.RIGHT, "Tank should face RIGHT")
	assert_eq(tank.position.x, 6, "Tank should move right by 1 tile")

## Test: Execute Bullet Movement
func test_given_active_bullet_when_executing_movement_then_bullet_moves():
	# Given: A game state with active bullet
	var game_state = GameState.create(StageState.create(1, 26, 26))
	var initial_pos = Position.create(5, 5)
	var bullet = BulletEntity.create("bullet_1", "tank_1", initial_pos, Direction.create(Direction.UP), 2, 1)
	game_state.add_bullet(bullet)
	
	# When: Executing bullet movement
	MovementService.execute_bullet_movement(game_state, bullet)
	
	# Then: Bullet moved forward
	assert_eq(bullet.position.y, 3, "Bullet should move up by 2 tiles (speed=2)")
	assert_true(bullet.is_active, "Bullet should remain active")

func test_given_bullet_moving_out_of_bounds_when_executing_movement_then_deactivates():
	# Given: A bullet near edge moving toward boundary
	var game_state = GameState.create(StageState.create(1, 26, 26))
	var bullet = BulletEntity.create("bullet_1", "tank_1", Position.create(0, 0), Direction.create(Direction.UP), 2, 1)
	game_state.add_bullet(bullet)
	
	# When: Executing bullet movement (will go out of bounds)
	MovementService.execute_bullet_movement(game_state, bullet)
	
	# Then: Bullet deactivated
	assert_false(bullet.is_active, "Bullet should deactivate when going out of bounds")

func test_given_inactive_bullet_when_executing_movement_then_nothing_happens():
	# Given: An inactive bullet
	var game_state = GameState.create(StageState.create(1, 26, 26))
	var initial_pos = Position.create(5, 5)
	var bullet = BulletEntity.create("bullet_1", "tank_1", initial_pos, Direction.create(Direction.UP), 2, 1)
	bullet.deactivate()
	game_state.add_bullet(bullet)
	
	# When: Executing bullet movement
	MovementService.execute_bullet_movement(game_state, bullet)
	
	# Then: Bullet did not move
	assert_true(bullet.position.equals(initial_pos), "Inactive bullet should not move")

## Test: Update All Bullets
func test_given_multiple_active_bullets_when_updating_all_then_all_move():
	# Given: A game state with multiple active bullets
	var game_state = GameState.create(StageState.create(1, 26, 26))
	var bullet1 = BulletEntity.create("bullet_1", "tank_1", Position.create(5, 5), Direction.create(Direction.UP), 2, 1)
	var bullet2 = BulletEntity.create("bullet_2", "tank_2", Position.create(10, 10), Direction.create(Direction.DOWN), 2, 1)
	game_state.add_bullet(bullet1)
	game_state.add_bullet(bullet2)
	
	# When: Updating all bullets
	MovementService.update_all_bullets(game_state)
	
	# Then: All bullets moved
	assert_eq(bullet1.position.y, 3, "Bullet 1 should move up")
	assert_eq(bullet2.position.y, 12, "Bullet 2 should move down")

func test_given_mixed_active_inactive_bullets_when_updating_all_then_only_active_move():
	# Given: A game state with active and inactive bullets
	var game_state = GameState.create(StageState.create(1, 26, 26))
	var active_bullet = BulletEntity.create("bullet_1", "tank_1", Position.create(5, 5), Direction.create(Direction.UP), 2, 1)
	var inactive_bullet = BulletEntity.create("bullet_2", "tank_2", Position.create(10, 10), Direction.create(Direction.DOWN), 2, 1)
	inactive_bullet.deactivate()
	game_state.add_bullet(active_bullet)
	game_state.add_bullet(inactive_bullet)
	
	# When: Updating all bullets
	MovementService.update_all_bullets(game_state)
	
	# Then: Only active bullet moved
	assert_eq(active_bullet.position.y, 3, "Active bullet should move")
	assert_eq(inactive_bullet.position.y, 10, "Inactive bullet should not move")

func test_given_no_bullets_when_updating_all_then_no_errors():
	# Given: A game state with no bullets
	var game_state = GameState.create(StageState.create(1, 26, 26))
	
	# When: Updating all bullets
	MovementService.update_all_bullets(game_state)
	
	# Then: No errors (test passes if this completes)
	assert_true(true, "Should handle empty bullet list without errors")
