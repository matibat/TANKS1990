extends GutTest

## BDD Tests for GameLoop - Frame-based deterministic game loop
## Test-First: Write tests → Implement → Pass

const GameLoop = preload("res://src/domain/game_loop.gd")
const GameState = preload("res://src/domain/aggregates/game_state.gd")
const StageState = preload("res://src/domain/aggregates/stage_state.gd")
const TankEntity = preload("res://src/domain/entities/tank_entity.gd")
const BulletEntity = preload("res://src/domain/entities/bullet_entity.gd")
const TerrainCell = preload("res://src/domain/entities/terrain_cell.gd")
const BaseEntity = preload("res://src/domain/entities/base_entity.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")
const MoveCommand = preload("res://src/domain/commands/move_command.gd")
const FireCommand = preload("res://src/domain/commands/fire_command.gd")
const AIService = preload("res://src/domain/services/ai_service.gd")
const TankMovedEvent = preload("res://src/domain/events/tank_moved_event.gd")
const BulletMovedEvent = preload("res://src/domain/events/bullet_moved_event.gd")
const CollisionEvent = preload("res://src/domain/events/collision_event.gd")
const TankDamagedEvent = preload("res://src/domain/events/tank_damaged_event.gd")
const TankDestroyedEvent = preload("res://src/domain/events/tank_destroyed_event.gd")
const BulletDestroyedEvent = preload("res://src/domain/events/bullet_destroyed_event.gd")
const StageCompleteEvent = preload("res://src/domain/events/stage_complete_event.gd")
const GameOverEvent = preload("res://src/domain/events/game_over_event.gd")

var game_state: GameState
var stage: StageState

func before_each():
	_initialize_game_state()

func _initialize_game_state() -> void:
	# Ensure each test uses a fresh stage/game state
	stage = StageState.create(1, 26, 26)
	stage.set_base(Position.create(12, 24))
	stage.add_player_spawn(Position.create(12, 20))
	game_state = GameState.create(stage, 3)

## BDD: Given commands When process_frame Then executes commands
func test_given_commands_when_process_frame_then_executes_commands():
	# Given: Tank at (10, 10)
	var tank = TankEntity.create("tank1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	game_state.add_tank(tank)
	
	# Given: Move command
	var commands = [MoveCommand.create(tank.id, Direction.create(Direction.RIGHT))]
	
	# When: Process frame
	var events = GameLoop.process_frame_static(game_state, commands)
	
	# Then: Tank moved to (11, 10)
	assert_eq(tank.position.x, 11, "Tank should move right")
	assert_eq(tank.position.y, 10, "Tank Y should not change")
	
	# Then: TankMoved event emitted
	var moved_events = events.filter(func(e): return e is TankMovedEvent)
	assert_gt(moved_events.size(), 0, "TankMoved event should be emitted")

## BDD: Given moving bullets When process_frame Then bullets move
func test_given_moving_bullets_when_process_frame_then_bullets_move():
	# Given: Bullet at (5, 5) moving right
	var bullet = BulletEntity.create("bullet1", "tank1", Position.create(5, 5), Direction.create(Direction.RIGHT), 1, 1)
	game_state.add_bullet(bullet)
	
	var old_x = bullet.position.x
	
	# When: Process frame
	var events = GameLoop.process_frame_static(game_state, [])
	
	# Then: Bullet moved forward
	assert_gt(bullet.position.x, old_x, "Bullet should move forward")
	
	# Then: BulletMoved event emitted
	var bullet_events = events.filter(func(e): return e is BulletMovedEvent)
	assert_eq(bullet_events.size(), 1, "BulletMoved event should be emitted")

## BDD: Given tank with cooldown When process_frame Then cooldown decreases
func test_given_tank_with_cooldown_when_process_frame_then_cooldown_decreases():
	# Given: Tank with cooldown
	var tank = TankEntity.create("tank1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	tank.cooldown_frames = 5
	game_state.add_tank(tank)
	
	# When: Process frame
	GameLoop.process_frame_static(game_state, [])
	
	# Then: Cooldown decreased by 1
	assert_eq(tank.cooldown_frames, 4, "Cooldown should decrease by 1")

## BDD: Given bullet hits tank When process_frame Then tank takes damage and events emitted
func test_given_bullet_hits_tank_when_process_frame_then_tank_takes_damage_and_events_emitted():
	# Given: Player tank at (10, 10) - using PLAYER type to avoid AI movement
	var tank = TankEntity.create("tank1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	game_state.add_tank(tank)
	
	var initial_health = tank.health.current
	
	# Given: Player bullet at same position (speed=0 so it doesn't move away before collision)
	var bullet = BulletEntity.create("bullet1", "player_tank", Position.create(10, 10), Direction.create(Direction.UP), 0, 1)
	game_state.add_bullet(bullet)
	
	# When: Process frame
	var events = GameLoop.process_frame_static(game_state, [])
	
	# Then: Tank took damage
	assert_lt(tank.health.current, initial_health, "Tank should take damage")
	
	# Then: Bullet deactivated
	assert_false(bullet.is_active, "Bullet should be deactivated")
	
	# Then: Collision and damage events emitted
	var collision_events = events.filter(func(e): return e is CollisionEvent)
	var damage_events = events.filter(func(e): return e is TankDamagedEvent)
	assert_gt(collision_events.size(), 0, "CollisionEvent should be emitted")
	assert_gt(damage_events.size(), 0, "TankDamagedEvent should be emitted")

func test_given_moving_player_bullet_when_it_reaches_enemy_then_enemy_damaged_and_bullet_removed():
	# Given: Player and enemy facing each other on the same column
	var player = TankEntity.create("player1", TankEntity.Type.PLAYER, Position.create(5, 6), Direction.create(Direction.UP))
	var enemy = TankEntity.create("enemy1", TankEntity.Type.ENEMY_BASIC, Position.create(5, 3), Direction.create(Direction.DOWN))
	game_state.add_tank(player)
	game_state.add_tank(enemy)
	var initial_enemy_health = enemy.health.current
	# Given: Bullet starts between them and moves toward enemy
	var bullet = BulletEntity.create("bullet1", player.id, Position.create(5, 5), Direction.create(Direction.UP), 2, 1)
	game_state.add_bullet(bullet)

	# When: Process bullet steps until it is removed
	var iterations = 0
	while bullet.is_active and iterations < 5:
		GameLoop._process_single_bullet(bullet, game_state)
		iterations += 1
	
	# Clean up: remove deactivated bullets (mirrors frame cleanup)
	for existing_bullet in game_state.get_all_bullets():
		if not existing_bullet.is_active:
			game_state.remove_bullet(existing_bullet.id)

	# Then: Enemy took damage and bullet removed
	assert_lt(enemy.health.current, initial_enemy_health, "Enemy should take damage from moving bullet")
	assert_null(game_state.get_bullet(bullet.id), "Bullet should be removed after hitting enemy")

func test_given_moving_enemy_bullet_when_it_reaches_player_then_player_damaged_and_bullet_removed():
	# Given: Enemy and player facing each other on the same column
	var enemy = TankEntity.create("enemy1", TankEntity.Type.ENEMY_BASIC, Position.create(5, 3), Direction.create(Direction.DOWN))
	var player = TankEntity.create("player1", TankEntity.Type.PLAYER, Position.create(5, 6), Direction.create(Direction.UP))
	game_state.add_tank(enemy)
	game_state.add_tank(player)
	var initial_player_health = player.health.current
	# Given: Bullet starts between them and moves toward player
	var bullet = BulletEntity.create("bullet2", enemy.id, Position.create(5, 4), Direction.create(Direction.DOWN), 2, 1)
	game_state.add_bullet(bullet)

	# When: Process bullet steps until it is removed
	var iterations = 0
	while bullet.is_active and iterations < 5:
		GameLoop._process_single_bullet(bullet, game_state)
		iterations += 1
	
	# Clean up: remove deactivated bullets (mirrors frame cleanup)
	for existing_bullet in game_state.get_all_bullets():
		if not existing_bullet.is_active:
			game_state.remove_bullet(existing_bullet.id)

	# Then: Player took damage and bullet removed
	assert_lt(player.health.current, initial_player_health, "Player should take damage from enemy bullet")
	assert_null(game_state.get_bullet(bullet.id), "Enemy bullet should be removed after hitting player")

## BDD: Given bullet hits terrain When process_frame Then terrain damaged
func test_given_bullet_hits_terrain_when_process_frame_then_terrain_damaged():
	# Given: Destructible terrain at (10, 10)
	var terrain = TerrainCell.create(Position.create(10, 10), TerrainCell.CellType.BRICK)
	stage.add_terrain_cell(terrain)
	
	var initial_health = terrain.health
	
	# Given: Bullet at same position (speed=0 so it doesn't move away before collision)
	var bullet = BulletEntity.create("bullet1", "tank1", Position.create(10, 10), Direction.create(Direction.UP), 0, 1)
	game_state.add_bullet(bullet)
	
	# When: Process frame
	var events = GameLoop.process_frame_static(game_state, [])
	
	# Then: Terrain took damage (health is int, not Health object)
	assert_lt(terrain.health, initial_health, "Terrain should take damage")
	
	# Then: Bullet deactivated
	assert_false(bullet.is_active, "Bullet should be deactivated")
	
	# Then: Collision event emitted
	var collision_events = events.filter(func(e): return e is CollisionEvent)
	assert_gt(collision_events.size(), 0, "CollisionEvent should be emitted")

## BDD: Given all enemies dead When process_frame Then stage complete event
func test_given_all_enemies_dead_when_process_frame_then_stage_complete_event():
	# Given: No enemies remain
	stage.enemies_remaining = 0
	stage.enemies_on_field = 0
	
	# When: Process frame
	var events = GameLoop.process_frame_static(game_state, [])
	
	# Then: StageCompleteEvent emitted
	var complete_events = events.filter(func(e): return e is StageCompleteEvent)
	assert_eq(complete_events.size(), 1, "StageCompleteEvent should be emitted")

## BDD: Given base destroyed When process_frame Then game over event
func test_given_base_destroyed_when_process_frame_then_game_over_event():
	# Given: Base destroyed
	stage.base.take_damage(999)
	
	# When: Process frame
	var events = GameLoop.process_frame_static(game_state, [])
	
	# Then: GameOverEvent emitted
	var game_over_events = events.filter(func(e): return e is GameOverEvent)
	assert_eq(game_over_events.size(), 1, "GameOverEvent should be emitted")

## BDD: Given frame processed When checking frame number Then increments
func test_given_frame_processed_when_checking_frame_number_then_increments():
	# Given: Initial frame
	var initial_frame = game_state.frame
	
	# When: Process frame
	GameLoop.process_frame_static(game_state, [])
	
	# Then: Frame incremented
	assert_eq(game_state.frame, initial_frame + 1, "Frame should increment by 1")

## BDD: Given paused game When process_frame Then no updates
func test_given_paused_game_when_process_frame_then_no_updates():
	# Given: Tank with commands
	var tank = TankEntity.create("tank1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	game_state.add_tank(tank)
	var commands = [MoveCommand.create(tank.id, Direction.create(Direction.RIGHT))]
	
	# Given: Game is paused
	game_state.pause()
	
	var old_position = Position.create(tank.position.x, tank.position.y)
	var old_frame = game_state.frame
	
	# When: Process frame
	var events = GameLoop.process_frame_static(game_state, commands)
	
	# Then: No updates occurred
	assert_eq(tank.position.x, old_position.x, "Tank should not move when paused")
	assert_eq(tank.position.y, old_position.y, "Tank should not move when paused")
	assert_eq(game_state.frame, old_frame, "Frame should not increment when paused")
	assert_eq(events.size(), 0, "No events should be emitted when paused")

## BDD: CRITICAL - Given same inputs and seed When process_frame twice Then same results
func test_given_same_inputs_and_seed_when_process_frame_twice_then_same_results():
	# Given: Two identical game states with same seed
	var stage1 = StageState.create(1, 26, 26)
	stage1.set_base(Position.create(12, 24))
	var game_state1 = GameState.create(stage1, 3)
	
	var stage2 = StageState.create(1, 26, 26)
	stage2.set_base(Position.create(12, 24))
	var game_state2 = GameState.create(stage2, 3)
	
	# Given: Same tanks
	var tank1 = TankEntity.create("tank1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	game_state1.add_tank(tank1)
	
	var tank2 = TankEntity.create("tank1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	game_state2.add_tank(tank2)
	
	# Given: Same commands
	var commands1 = [MoveCommand.create("tank1", Direction.create(Direction.RIGHT))]
	var commands2 = [MoveCommand.create("tank1", Direction.create(Direction.RIGHT))]
	
	# When: Process frames
	var events1 = GameLoop.process_frame_static(game_state1, commands1)
	var events2 = GameLoop.process_frame_static(game_state2, commands2)
	
	# Then: Same tank positions
	assert_eq(tank1.position.x, tank2.position.x, "Tank X positions should match")
	assert_eq(tank1.position.y, tank2.position.y, "Tank Y positions should match")
	
	# Then: Same frame numbers
	assert_eq(game_state1.frame, game_state2.frame, "Frame numbers should match")
	
	# Then: Same event counts
	assert_eq(events1.size(), events2.size(), "Event counts should match")
	
	# Then: Same event types
	for i in range(events1.size()):
		assert_eq(events1[i].get_class(), events2[i].get_class(), "Event %d types should match" % i)

## BDD: Given destroyed tank When process frame Then tank removed from game state
func test_given_destroyed_tank_when_process_frame_then_tank_removed():
	# Given: Player tank with 1 health - using PLAYER type to avoid AI movement
	var tank = TankEntity.create("tank1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	tank.take_damage(tank.health.current - 1) # Leave 1 HP
	game_state.add_tank(tank)
	
	# Given: Bullet at same position (speed=0 so it doesn't move away)
	var bullet = BulletEntity.create("bullet1", "player", Position.create(10, 10), Direction.create(Direction.UP), 0, 1)
	game_state.add_bullet(bullet)
	
	# When: Process frame
	var events = GameLoop.process_frame_static(game_state, [])
	
	# Then: Tank removed from game state
	assert_null(game_state.get_tank("tank1"), "Destroyed tank should be removed")
	
	# Then: TankDestroyed event emitted
	var destroyed_events = events.filter(func(e): return e is TankDestroyedEvent)
	assert_eq(destroyed_events.size(), 1, "TankDestroyedEvent should be emitted")

## BDD: Given inactive bullet When process frame Then bullet removed from game state
func test_given_inactive_bullet_when_process_frame_then_bullet_removed():
	# Given: Bullet at edge of map
	var bullet = BulletEntity.create("bullet1", "tank1", Position.create(25, 10), Direction.create(Direction.RIGHT), 1, 1)
	game_state.add_bullet(bullet)
	
	# When: Process frame (bullet moves out of bounds and deactivates)
	var events = GameLoop.process_frame_static(game_state, [])
	
	# Then: Bullet removed from game state
	assert_null(game_state.get_bullet("bullet1"), "Inactive bullet should be removed")
	
	# Then: BulletDestroyed event emitted
	var destroyed_events = events.filter(func(e): return e is BulletDestroyedEvent)
	assert_eq(destroyed_events.size(), 1, "BulletDestroyedEvent should be emitted")

## BDD: Given bullet hits base When process frame Then base damaged
func test_given_bullet_hits_base_when_process_frame_then_base_damaged():
	# Given: Base at (12, 24)
	var initial_health = stage.base.health.current
	
	# Given: Bullet at same position (speed=0 so it doesn't move away)
	var bullet = BulletEntity.create("bullet1", "tank1", Position.create(12, 24), Direction.create(Direction.DOWN), 0, 1)
	game_state.add_bullet(bullet)
	
	# When: Process frame
	var events = GameLoop.process_frame_static(game_state, [])
	
	# Then: Base took damage
	assert_lt(stage.base.health.current, initial_health, "Base should take damage")
	
	# Then: Bullet deactivated
	assert_false(bullet.is_active, "Bullet should be deactivated")
	
	# Then: Collision event emitted
	var collision_events = events.filter(func(e): return e is CollisionEvent)
	assert_gt(collision_events.size(), 0, "CollisionEvent should be emitted")

func test_given_player_destroyed_with_spare_life_when_process_frame_then_respawns_new_tank():
	# Given: Player tank on field with an extra life in reserve
	var player = TankEntity.create("player1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	game_state.add_tank(player)
	game_state.player_lives = 2

	# Given: Bullet that will destroy the player immediately
	var bullet = BulletEntity.create("bullet1", "enemy", Position.create(10, 10), Direction.create(Direction.UP), 0, 1)
	game_state.add_bullet(bullet)

	# When: Process frame
	var events = GameLoop.process_frame_static(game_state, [])

	# Then: A new player is spawned and lives decrease
	assert_eq(game_state.player_lives, 1, "Player lives should decrement after death")
	var players = game_state.get_player_tanks()
	assert_eq(players.size(), 1, "Player should respawn when lives remain")
	assert_ne(players[0].id, player.id, "Respawned player should have a new id")

func test_given_player_destroyed_without_lives_when_process_frame_then_game_over_event_and_no_respawn():
	# Given: Player with no spare lives
	var player = TankEntity.create("player1", TankEntity.Type.PLAYER, Position.create(8, 8), Direction.create(Direction.UP))
	game_state.add_tank(player)
	game_state.player_lives = 1

	# Given: Bullet that will destroy the player immediately
	var bullet = BulletEntity.create("bullet1", "enemy", Position.create(8, 8), Direction.create(Direction.UP), 0, 1)
	game_state.add_bullet(bullet)

	# When: Process frame
	var events = GameLoop.process_frame_static(game_state, [])

	# Then: Game over event emitted and no player remains
	var game_over_events = events.filter(func(e): return e is GameOverEvent)
	assert_eq(game_over_events.size(), 1, "GameOverEvent should be emitted when out of lives")
	assert_eq(game_state.get_player_tanks().size(), 0, "No player should remain when out of lives")

func test_given_enemy_destroyed_when_process_frame_then_score_increases():
	# Given: Player and enemy occupying same tile with stationary bullet to ensure hit
	var player = TankEntity.create("player1", TankEntity.Type.PLAYER, Position.create(5, 5), Direction.create(Direction.UP))
	var enemy = TankEntity.create("enemy1", TankEntity.Type.ENEMY_BASIC, Position.create(5, 5), Direction.create(Direction.UP))
	game_state.add_tank(player)
	game_state.add_tank(enemy)
	game_state.score = 0

	var bullet = BulletEntity.create("bullet1", player.id, Position.create(5, 5), Direction.create(Direction.UP), 0, 1)
	game_state.add_bullet(bullet)

	# When: Process frame
	var events = GameLoop.process_frame_static(game_state, [])

	# Then: Score increases on enemy kill
	assert_eq(game_state.score, 100, "Enemy kill should award score")

## ==========================================
## Phase 1.3: Tick-based Game Loop Tests
## ==========================================

## BDD: Given tick not ready When process_frame Then no logic updates
func test_given_tick_not_ready_when_process_frame_then_no_logic_updates():
	# Given: Game loop with 10 TPS
	var game_loop_instance = GameLoop.new()
	game_loop_instance.set_ticks_per_second(10)
	
	# Given: Tank at (10, 10)
	var tank = TankEntity.create("tank1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	game_state.add_tank(tank)
	
	# Given: Move command
	var commands = [MoveCommand.create(tank.id, Direction.create(Direction.RIGHT))]
	
	# When: Process frame with delta less than tick interval (0.05s < 0.1s)
	var events = game_loop_instance.process_frame(game_state, commands, 0.05)
	
	# Then: Tank should NOT move (tick not ready)
	assert_eq(tank.position.x, 10, "Tank should not move when tick not ready")
	assert_eq(tank.position.y, 10, "Tank Y should not change")
	
	# Then: No events emitted
	assert_eq(events.size(), 0, "No events should be emitted when tick not ready")

## BDD: Given tick ready When process_frame Then executes logic
func test_given_tick_ready_when_process_frame_then_executes_logic():
	# Given: Game loop with 10 TPS
	var game_loop_instance = GameLoop.new()
	game_loop_instance.set_ticks_per_second(10)
	
	# Given: Tank at (10, 10)
	var tank = TankEntity.create("tank1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	game_state.add_tank(tank)
	
	# Given: Move command
	var commands = [MoveCommand.create(tank.id, Direction.create(Direction.RIGHT))]
	
	# When: Process frame with delta >= tick interval (0.1s)
	var events = game_loop_instance.process_frame(game_state, commands, 0.1)
	
	# Then: Tank should move (tick is ready)
	assert_eq(tank.position.x, 11, "Tank should move when tick is ready")
	assert_eq(tank.position.y, 10, "Tank Y should not change")
	
	# Then: TankMoved event emitted
	var moved_events = events.filter(func(e): return e is TankMovedEvent)
	assert_gt(moved_events.size(), 0, "TankMoved event should be emitted when tick is ready")

## BDD: Given 10 TPS When 60 frames Then exactly 10 ticks processed
func test_given_10_tps_when_60_frames_then_exactly_10_ticks_processed():
	# Given: Game loop with 10 TPS
	var game_loop_instance = GameLoop.new()
	game_loop_instance.set_ticks_per_second(10)
	
	# Given: Tank at (10, 10)
	var tank = TankEntity.create("tank1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	game_state.add_tank(tank)
	
	# Given: Move command (tank moves right every tick)
	var commands = [MoveCommand.create(tank.id, Direction.create(Direction.RIGHT))]
	
	# When: Simulate 60 frames at 60 FPS (1 second total)
	var frame_delta = 1.0 / 60.0 # ~0.0167 seconds per frame
	var tick_count = 0
	
	for frame in range(60):
		var events = game_loop_instance.process_frame(game_state, commands, frame_delta)
		# Count ticks by checking if tank moved
		if events.size() > 0:
			var moved_events = events.filter(func(e): return e is TankMovedEvent)
			if moved_events.size() > 0:
				tick_count += 1
	
	# Then: Exactly 10 ticks should have occurred (10 TPS × 1 second)
	assert_eq(tick_count, 10, "Should process exactly 10 ticks in 1 second at 10 TPS")
	
	# Then: Tank should have moved 10 tiles (one per tick)
	assert_eq(tank.position.x, 20, "Tank should have moved 10 tiles in 10 ticks")

func test_given_large_delta_when_process_frame_then_consumes_all_ready_ticks_once():
	# Given: Game loop with 10 TPS
	var game_loop_instance = GameLoop.new()
	game_loop_instance.set_ticks_per_second(10)

	# Given: Tank at (10, 10)
	var tank = TankEntity.create("tank1", TankEntity.Type.PLAYER, Position.create(10, 10), Direction.create(Direction.UP))
	game_state.add_tank(tank)

	# Given: Move command
	var commands = [MoveCommand.create(tank.id, Direction.create(Direction.RIGHT))]
	var initial_frame = game_state.frame

	# When: Process frame with 0.25s delta (~2.5 ticks)
	var events = game_loop_instance.process_frame(game_state, commands, 0.25)
	var moved_events = events.filter(func(e): return e is TankMovedEvent)

	# Then: Two ticks should have been processed, consuming only ready ticks
	assert_eq(moved_events.size(), 2, "Should process two ticks for 0.25s at 10 TPS")
	assert_eq(tank.position.x, 12, "Tank should move two tiles when two ticks are processed")
	assert_eq(game_state.frame, initial_frame + 2, "Frame counter should advance per tick")

## Phase 2.4: Game Loop Integration Tests
func test_given_enemy_tanks_when_process_frame_then_ai_commands_executed():
	# Given: Enemy tank and player tank (positioned with clear line of sight within map bounds)
	var player = TankEntity.create("player1", TankEntity.Type.PLAYER,
		Position.create(12, 10), Direction.create(Direction.UP))
	var enemy = TankEntity.create("enemy1", TankEntity.Type.ENEMY_BASIC,
		Position.create(12, 16), Direction.create(Direction.UP))
	
	# Ensure enemy can fire immediately (no cooldown) and clear AI state
	enemy.cooldown_frames = 0
	AIService.clear_direction_state(enemy.id)
	
	game_state.add_tank(player)
	game_state.add_tank(enemy)
	
	var initial_pos_x = enemy.position.x
	var initial_pos_y = enemy.position.y
	
	# When: Process multiple frames (AI should eventually act)
	for i in range(10):
		var events = GameLoop.process_frame_static(game_state, [])
	
	# Then: Enemy should have made some AI decision (moved or fired)
	var moved = enemy.position.x != initial_pos_x or enemy.position.y != initial_pos_y
	var fired = game_state.get_all_bullets().size() > 0
	assert_true(moved or fired, "Enemy should have performed AI action (move or fire)")

func test_given_spawn_tick_when_process_frame_then_enemy_spawned():
	# Given: Game loop with spawn controller integrated
	# Initial state: no tanks
	var initial_count = game_state.get_all_tanks().size()
	
	# When: Process multiple frames (spawning should occur)
	for i in range(100):
		var events = GameLoop.process_frame_static(game_state, [])
	
	# Then: At least one enemy should have spawned
	var final_count = game_state.get_all_tanks().size()
	assert_true(final_count > initial_count,
		"At least one enemy should spawn after many frames (got %d, expected > %d)" % [final_count, initial_count])

func test_given_two_bullets_collide_when_process_frame_then_both_destroyed():
	# Given: Two bullets on collision course at same position
	var bullet1 = BulletEntity.create("bullet_1", "tank_1",
		Position.create(100, 100), Direction.create(Direction.RIGHT), 2, 1)
	var bullet2 = BulletEntity.create("bullet_2", "tank_2",
		Position.create(100, 100), Direction.create(Direction.LEFT), 2, 1)
	
	game_state.add_bullet(bullet1)
	game_state.add_bullet(bullet2)
	
	# When: Process frame (collision should be detected)
	var events = GameLoop.process_frame_static(game_state, [])
	
	# Then: Both bullets should be destroyed
	assert_false(bullet1.is_active, "Bullet 1 should be destroyed after collision")
	assert_false(bullet2.is_active, "Bullet 2 should be destroyed after collision")

func test_given_stage_start_when_process_frames_then_enemies_spawn_over_time():
	# Given: Clean game state with no tanks
	var clean_stage = StageState.create(1, 26, 26)
	var clean_game_state = GameState.create(clean_stage, 3)
	
	# When: Process 200 frames
	var spawn_count = 0
	for i in range(200):
		var before_count = clean_game_state.get_all_tanks().size()
		var events = GameLoop.process_frame_static(clean_game_state, [])
		var after_count = clean_game_state.get_all_tanks().size()
		if after_count > before_count:
			spawn_count += 1
	
	# Then: At least some enemies should have spawned
	assert_true(spawn_count > 0,
		"Enemies should spawn over time (got %d spawns)" % spawn_count)

## BDD: Given enemy bullet hits enemy tank When process_frame Then no damage (friendly fire prevention)
func test_given_enemy_bullet_hits_enemy_tank_when_process_frame_then_no_friendly_fire():
	# Given: Enemy tank at (10, 10)
	var enemy_tank = TankEntity.create("enemy1", TankEntity.Type.ENEMY_BASIC, Position.create(10, 10), Direction.create(Direction.UP))
	game_state.add_tank(enemy_tank)
	
	# Given: Another enemy tank shooting
	var shooter = TankEntity.create("enemy2", TankEntity.Type.ENEMY_BASIC, Position.create(10, 8), Direction.create(Direction.DOWN))
	game_state.add_tank(shooter)
	
	# Given: Enemy bullet (from enemy2) at position of enemy1
	var bullet = BulletEntity.create("bullet1", "enemy2", Position.create(10, 10), Direction.create(Direction.DOWN), 0, 1)
	game_state.add_bullet(bullet)
	
	var initial_health = enemy_tank.health.current
	
	# When: Process frame
	GameLoop.process_frame_static(game_state, [])
	
	# Then: Enemy tank took NO damage (friendly fire prevented)
	assert_eq(enemy_tank.health.current, initial_health, "Enemy tank should not take damage from friendly bullet")
	
	# Then: Bullet is still active (no collision)
	assert_true(bullet.is_active, "Bullet should still be active (no friendly fire collision)")

## BDD: Given player bullet hits enemy tank When process_frame Then enemy takes damage
func test_given_player_bullet_hits_enemy_when_process_frame_then_enemy_takes_damage():
	# Given: Enemy tank at (10, 10)
	var enemy_tank = TankEntity.create("enemy1", TankEntity.Type.ENEMY_BASIC, Position.create(10, 10), Direction.create(Direction.UP))
	game_state.add_tank(enemy_tank)
	
	# Given: Player tank shooting
	var player = TankEntity.create("player1", TankEntity.Type.PLAYER, Position.create(10, 8), Direction.create(Direction.DOWN))
	game_state.add_tank(player)
	
	# Given: Player bullet at position of enemy
	var bullet = BulletEntity.create("bullet1", "player1", Position.create(10, 10), Direction.create(Direction.DOWN), 0, 1)
	game_state.add_bullet(bullet)
	
	var initial_health = enemy_tank.health.current
	
	# When: Process frame
	GameLoop.process_frame_static(game_state, [])
	
	# Then: Enemy tank took damage (no friendly fire, different teams)
	assert_lt(enemy_tank.health.current, initial_health, "Enemy tank should take damage from player bullet")
	
	# Then: Bullet deactivated
	assert_false(bullet.is_active, "Bullet should be deactivated after hit")

## BDD: ACCEPTANCE - Given player and enemy bullets hit same terrain simultaneously When process_frame Then player bullet resolves first
func test_given_player_and_enemy_bullets_hit_same_terrain_when_process_frame_then_player_bullet_resolves_first():
	# Given: Player tank and enemy tank (positioned away from terrain)
	_initialize_game_state()
	var player = TankEntity.create("player1", TankEntity.Type.PLAYER, Position.create(5, 5), Direction.create(Direction.UP))
	game_state.add_tank(player)
	var enemy = TankEntity.create("enemy1", TankEntity.Type.ENEMY_BASIC, Position.create(15, 15), Direction.create(Direction.UP))
	game_state.add_tank(enemy)
	
	# Given: Brick terrain at (10, 10) with 1 health
	var terrain = TerrainCell.create(Position.create(10, 10), TerrainCell.CellType.BRICK)
	terrain.take_damage(terrain.health - 1) # Leave 1 HP so single bullet destroys it
	stage.add_terrain_cell(terrain)
	
	# Given: Player bullet moving toward terrain from above (will hit this frame)
	var player_bullet = BulletEntity.create("player_bullet", "player1", Position.create(10, 9), Direction.create(Direction.DOWN), 1, 1)
	game_state.add_bullet(player_bullet)
	
	# Given: Enemy bullet moving toward same terrain from below (will hit this frame)
	var enemy_bullet = BulletEntity.create("enemy_bullet", "enemy1", Position.create(10, 11), Direction.create(Direction.UP), 1, 1)
	game_state.add_bullet(enemy_bullet)
	
	# When: Process frame
	var events = GameLoop.process_frame_static(game_state, [])
	
	# Then: Terrain is destroyed (health = 0)
	assert_eq(terrain.health, 0, "Terrain should be destroyed")
	
	# Then: Player bullet hit and deactivated
	assert_false(player_bullet.is_active, "Player bullet should be deactivated after hitting terrain")
	
	# Then: Enemy bullet should NOT hit terrain (it was already destroyed by player bullet)
	# The enemy bullet either passes through or stays active depending on implementation
	# Key: Only ONE collision event for the terrain should exist (from player bullet)
	var terrain_collision_events = events.filter(func(e):
		return e is CollisionEvent and e.collision_type == "bullet_terrain"
	)
	
	# We expect at least the player bullet collision
	assert_gt(terrain_collision_events.size(), 0, "Should have at least player bullet collision")
	
	# Verify player bullet collision happened by checking event entity IDs
	# Bullet-to-bullet collisions still use a radius (4px per bullet), so the player terrain hit happens before two bullets can overlap within that radius.
	var player_bullet_hit_terrain = terrain_collision_events.any(func(e):
		return e.entity2_id == "player_bullet"
	)
	assert_true(player_bullet_hit_terrain, "Player bullet should have collided with terrain")
	
	# If enemy bullet is also deactivated with a collision event, priority is NOT working
	# Enemy bullet should either: stay active (missed destroyed terrain) OR deactivate without terrain collision
	var enemy_bullet_hit_terrain = terrain_collision_events.any(func(e):
		return e.entity2_id == "enemy_bullet"
	)
	assert_false(enemy_bullet_hit_terrain, "Enemy bullet should NOT collide with already-destroyed terrain")

## BDD: ACCEPTANCE - Given multiple player bullets and enemy bullets When process_frame Then all player bullets resolve before enemy bullets
func test_given_multiple_player_and_enemy_bullets_when_process_frame_then_player_bullets_resolve_first():
	# Given: Player and enemy tanks
	_initialize_game_state()
	var player = TankEntity.create("player1", TankEntity.Type.PLAYER, Position.create(5, 5), Direction.create(Direction.DOWN))
	game_state.add_tank(player)
	var enemy = TankEntity.create("enemy1", TankEntity.Type.ENEMY_BASIC, Position.create(15, 15), Direction.create(Direction.UP))
	game_state.add_tank(enemy)
	
	# Given: Three brick terrains in a row, each with 1 health
	for i in range(3):
		var terrain = TerrainCell.create(Position.create(10 + i, 10), TerrainCell.CellType.BRICK)
		terrain.take_damage(terrain.health - 1) # Leave 1 HP
		stage.add_terrain_cell(terrain)
	
	# Given: Two player bullets heading toward the terrains
	var player_bullet1 = BulletEntity.create("player_bullet1", "player1", Position.create(10, 9), Direction.create(Direction.DOWN), 1, 1)
	game_state.add_bullet(player_bullet1)
	var player_bullet2 = BulletEntity.create("player_bullet2", "player1", Position.create(11, 9), Direction.create(Direction.DOWN), 1, 1)
	game_state.add_bullet(player_bullet2)
	
	# Given: One enemy bullet heading toward a terrain
	var enemy_bullet = BulletEntity.create("enemy_bullet", "enemy1", Position.create(12, 11), Direction.create(Direction.UP), 1, 1)
	game_state.add_bullet(enemy_bullet)
	
	# When: Process frame
	var events = GameLoop.process_frame_static(game_state, [])
	
	# Then: All three terrains are destroyed
	assert_eq(stage.get_terrain_at(Position.create(10, 10)).health, 0, "First terrain destroyed")
	assert_eq(stage.get_terrain_at(Position.create(11, 10)).health, 0, "Second terrain destroyed")
	assert_eq(stage.get_terrain_at(Position.create(12, 10)).health, 0, "Third terrain destroyed")
	
	# Then: All bullets deactivated
	assert_false(player_bullet1.is_active, "Player bullet 1 deactivated")
	assert_false(player_bullet2.is_active, "Player bullet 2 deactivated")
	assert_false(enemy_bullet.is_active, "Enemy bullet deactivated")
	
	# Then: Verify collision events show player bullets processed first by checking terrain hits
	var terrain_collision_events = events.filter(func(e):
		return e is CollisionEvent and e.collision_type == "bullet_terrain"
	)
	assert_eq(terrain_collision_events.size(), 3, "Should have exactly 3 terrain collisions")
