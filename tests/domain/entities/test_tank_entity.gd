extends GutTest

## BDD Tests for TankEntity
## Test-first approach: Write behavior tests before implementation

const TankEntity = preload("res://src/domain/entities/tank_entity.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")
const Health = preload("res://src/domain/value_objects/health.gd")
const TankStats = preload("res://src/domain/value_objects/tank_stats.gd")

## Test: Tank Creation and Identity
func test_given_tank_parameters_when_created_then_has_correct_properties():
	# Given: Tank creation parameters
	var tank_id = "tank_1"
	var tank_type = TankEntity.Type.PLAYER
	var position = Position.create(5, 5)
	var direction = Direction.create(Direction.UP)
	
	# When: Tank is created
	var tank = TankEntity.create(tank_id, tank_type, position, direction)
	
	# Then: Tank has correct properties
	assert_not_null(tank, "Tank should be created")
	assert_eq(tank.id, tank_id, "Tank should have correct ID")
	assert_eq(tank.tank_type, tank_type, "Tank should have correct type")
	assert_true(tank.position.equals(position), "Tank should have correct position")
	assert_eq(tank.direction.value, direction.value, "Tank should have correct direction")
	assert_true(tank.is_alive(), "Tank should be alive when created")
	assert_false(tank.is_moving, "Tank should not be moving initially")

## Test: Tank Health and Damage
func test_given_tank_with_health_when_takes_damage_then_health_decreases():
	# Given: An armored tank with initial health > 1
	var tank = TankEntity.create("t1", TankEntity.Type.ENEMY_ARMORED,
								 Position.create(5, 5), Direction.create(Direction.UP))
	var initial_health = tank.health.current
	assert_true(initial_health > 1, "Test requires tank with health > 1")
	
	# When: Tank takes 1 damage
	tank.take_damage(1)
	
	# Then: Health decreases by 1
	assert_eq(tank.health.current, initial_health - 1, "Health should decrease by damage amount")
	assert_true(tank.is_alive(), "Tank should still be alive")

func test_given_tank_when_takes_fatal_damage_then_dies():
	# Given: A tank with 1 health
	var tank = TankEntity.create("t1", TankEntity.Type.PLAYER,
								 Position.create(5, 5), Direction.create(Direction.UP))
	var damage = tank.health.current # Fatal damage
	
	# When: Tank takes fatal damage
	tank.take_damage(damage)
	
	# Then: Tank is dead
	assert_false(tank.is_alive(), "Tank should be dead after fatal damage")
	assert_eq(tank.health.current, 0, "Health should be zero")

## Test: Tank Shooting Cooldown
func test_given_tank_without_cooldown_when_can_shoot_then_returns_true():
	# Given: A tank with no cooldown
	var tank = TankEntity.create("t1", TankEntity.Type.PLAYER,
								 Position.create(5, 5), Direction.create(Direction.UP))
	tank.cooldown_frames = 0
	
	# When: Checking if tank can shoot
	var can_shoot = tank.can_shoot()
	
	# Then: Tank can shoot
	assert_true(can_shoot, "Tank should be able to shoot when cooldown is zero")

func test_given_tank_with_cooldown_when_can_shoot_then_returns_false():
	# Given: A tank with active cooldown
	var tank = TankEntity.create("t1", TankEntity.Type.PLAYER,
								 Position.create(5, 5), Direction.create(Direction.UP))
	tank.start_cooldown()
	
	# When: Checking if tank can shoot
	var can_shoot = tank.can_shoot()
	
	# Then: Tank cannot shoot
	assert_false(can_shoot, "Tank should not be able to shoot during cooldown")

func test_given_tank_when_starts_cooldown_then_cooldown_set():
	# Given: A tank with no cooldown
	var tank = TankEntity.create("t1", TankEntity.Type.PLAYER,
								 Position.create(5, 5), Direction.create(Direction.UP))
	var fire_rate = tank.stats.fire_rate
	
	# When: Tank starts cooldown
	tank.start_cooldown()
	
	# Then: Cooldown is set to fire rate
	assert_eq(tank.cooldown_frames, fire_rate, "Cooldown should equal fire rate")

func test_given_tank_with_cooldown_when_updates_then_cooldown_decreases():
	# Given: A tank with active cooldown
	var tank = TankEntity.create("t1", TankEntity.Type.PLAYER,
								 Position.create(5, 5), Direction.create(Direction.UP))
	tank.start_cooldown()
	var initial_cooldown = tank.cooldown_frames
	
	# When: Tank updates cooldown
	tank.update_cooldown()
	
	# Then: Cooldown decreases
	assert_eq(tank.cooldown_frames, initial_cooldown - 1, "Cooldown should decrease by 1")

func test_given_tank_with_cooldown_1_when_updates_then_cooldown_becomes_zero():
	# Given: A tank with cooldown of 1
	var tank = TankEntity.create("t1", TankEntity.Type.PLAYER,
								 Position.create(5, 5), Direction.create(Direction.UP))
	tank.cooldown_frames = 1
	
	# When: Tank updates cooldown
	tank.update_cooldown()
	
	# Then: Cooldown becomes zero
	assert_eq(tank.cooldown_frames, 0, "Cooldown should become zero")

## Test: Tank Movement
func test_given_tank_when_gets_next_position_then_returns_correct_position():
	# Given: A tank facing UP
	var tank = TankEntity.create("t1", TankEntity.Type.PLAYER,
								 Position.create(5, 5), Direction.create(Direction.UP))
	
	# When: Getting next position
	var next_pos = tank.get_next_position()
	
	# Then: Next position is one tile up
	assert_eq(next_pos.x, 5, "X position should be same")
	assert_eq(next_pos.y, 4, "Y position should be one less (up)")

func test_given_tank_when_moves_to_position_then_position_updated():
	# Given: A tank at position (5, 5)
	var tank = TankEntity.create("t1", TankEntity.Type.PLAYER,
								 Position.create(5, 5), Direction.create(Direction.UP))
	var new_position = Position.create(6, 6)
	
	# When: Tank moves to new position
	tank.move_to(new_position)
	
	# Then: Tank position is updated
	assert_true(tank.position.equals(new_position), "Tank position should be updated")
	assert_true(tank.is_moving, "Tank should be marked as moving")

func test_given_moving_tank_when_stops_then_not_moving():
	# Given: A moving tank
	var tank = TankEntity.create("t1", TankEntity.Type.PLAYER,
								 Position.create(5, 5), Direction.create(Direction.UP))
	tank.is_moving = true
	
	# When: Tank stops
	tank.stop_moving()
	
	# Then: Tank is not moving
	assert_false(tank.is_moving, "Tank should not be moving after stop")

## Test: Tank Rotation
func test_given_tank_facing_up_when_rotates_to_right_then_direction_changed():
	# Given: A tank facing UP
	var tank = TankEntity.create("t1", TankEntity.Type.PLAYER,
								 Position.create(5, 5), Direction.create(Direction.UP))
	var new_direction = Direction.create(Direction.RIGHT)
	
	# When: Tank rotates to RIGHT
	tank.rotate_to(new_direction)
	
	# Then: Tank is now facing RIGHT
	assert_eq(tank.direction.value, Direction.RIGHT, "Tank should face RIGHT")

## Test: Tank Serialization
func test_given_tank_when_serialized_then_can_deserialize():
	# Given: A tank with specific state
	var tank = TankEntity.create("t1", TankEntity.Type.PLAYER,
								 Position.create(5, 5), Direction.create(Direction.UP))
	tank.take_damage(1)
	tank.start_cooldown()
	
	# When: Tank is serialized and deserialized
	var dict = tank.to_dict()
	var restored_tank = TankEntity.from_dict(dict)
	
	# Then: Restored tank has same state
	assert_eq(restored_tank.id, tank.id, "ID should match")
	assert_eq(restored_tank.tank_type, tank.tank_type, "Type should match")
	assert_true(restored_tank.position.equals(tank.position), "Position should match")
	assert_eq(restored_tank.direction.value, tank.direction.value, "Direction should match")
	assert_eq(restored_tank.health.current, tank.health.current, "Health should match")
	assert_eq(restored_tank.cooldown_frames, tank.cooldown_frames, "Cooldown should match")

## Test: Tank Type Specific Stats
func test_given_player_tank_when_created_then_has_player_stats():
	# Given/When: Creating a player tank
	var tank = TankEntity.create("t1", TankEntity.Type.PLAYER,
								 Position.create(5, 5), Direction.create(Direction.UP))
	
	# Then: Tank has player stats
	assert_eq(tank.stats.speed, 2, "Player should have speed 2")
	assert_eq(tank.stats.armor, 1, "Player should have armor 1")

func test_given_enemy_basic_tank_when_created_then_has_basic_enemy_stats():
	# Given/When: Creating a basic enemy tank
	var tank = TankEntity.create("t1", TankEntity.Type.ENEMY_BASIC,
								 Position.create(5, 5), Direction.create(Direction.UP))
	
	# Then: Tank has basic enemy stats
	assert_eq(tank.stats.speed, 1, "Basic enemy should have speed 1")
	assert_eq(tank.stats.armor, 1, "Basic enemy should have armor 1")

## Test: Can Move
func test_given_alive_tank_when_can_move_then_returns_true():
	# Given: An alive tank
	var tank = TankEntity.create("t1", TankEntity.Type.PLAYER,
								 Position.create(5, 5), Direction.create(Direction.UP))
	
	# When: Checking if tank can move
	var can_move = tank.can_move()
	
	# Then: Tank can move
	assert_true(can_move, "Alive tank should be able to move")

func test_given_dead_tank_when_can_move_then_returns_false():
	# Given: A dead tank
	var tank = TankEntity.create("t1", TankEntity.Type.PLAYER,
								 Position.create(5, 5), Direction.create(Direction.UP))
	tank.take_damage(tank.health.current) # Kill tank
	
	# When: Checking if tank can move
	var can_move = tank.can_move()
	
	# Then: Tank cannot move
	assert_false(can_move, "Dead tank should not be able to move")
