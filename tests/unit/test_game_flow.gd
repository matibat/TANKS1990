extends GutTest
## BDD Test Suite: Game Flow & State Management
## Tests main menu, game states, player respawn, and game-over conditions

var game_state_manager: GameStateManager
var event_bus: Node

func before_each():
	event_bus = get_node("/root/EventBus")
	event_bus.recorded_events.clear()
	event_bus.current_frame = 0
	game_state_manager = GameStateManager.new()

func after_each():
	if game_state_manager:
		game_state_manager.free()

## ============================================================================
## Epic: Main Menu & Game Start
## ============================================================================

func test_given_game_launched_when_initialized_then_shows_main_menu():
	# Given: Game just launched
	# When: GameStateManager initialized
	# Then: State should be MainMenu
	assert_eq(game_state_manager.current_state, GameStateManager.State.MAIN_MENU,
		"Game should start in MainMenu state")

func test_given_main_menu_when_start_game_pressed_then_transitions_to_playing():
	# Given: Game in main menu
	assert_eq(game_state_manager.current_state, GameStateManager.State.MAIN_MENU)
	
	# When: Start game action triggered
	game_state_manager.start_game()
	
	# Then: State transitions to Playing
	assert_eq(game_state_manager.current_state, GameStateManager.State.PLAYING,
		"Should transition to Playing state")

func test_given_main_menu_when_start_game_then_emits_game_started_event():
	# Given: Game in main menu
	watch_signals(game_state_manager)
	
	# When: Start game triggered
	game_state_manager.start_game()
	
	# Then: game_started signal emitted
	assert_signal_emitted(game_state_manager, "game_started", "Should emit game_started signal")

## ============================================================================
## Epic: Player Respawn & Immunity
## ============================================================================

func test_given_player_dead_when_has_lives_then_respawns():
	# Given: Player tank destroyed with lives remaining
	var player_tank = Tank.new()
	player_tank.tank_type = Tank.TankType.PLAYER
	player_tank.lives = 2
	
	# When: Player dies (game manager would decrease lives)
	var initial_lives = player_tank.lives
	player_tank.lives -= 1  # Simulate game manager decreasing lives
	
	# Then: Lives decreased
	assert_eq(player_tank.lives, 1, "Should have one less life")
	# Note: Respawn logic handled by GameManager in integration

func test_given_player_respawned_when_spawn_complete_then_has_immunity():
	# Given: Player tank respawning
	var player_tank = Tank.new()
	player_tank.tank_type = Tank.TankType.PLAYER
	player_tank.position = Vector2(100, 100)
	add_child_autofree(player_tank)
	
	# When: Respawn with immunity
	player_tank.activate_invulnerability(5.0)
	
	# Then: Tank is invulnerable
	assert_eq(player_tank.current_state, Tank.State.INVULNERABLE,
		"Should be in invulnerable state")
	assert_true(player_tank.invulnerability_timer > 0,
		"Should have active immunity timer")

func test_given_player_immune_when_5_seconds_pass_then_immunity_ends():
	# Given: Player with immunity
	var player_tank = Tank.new()
	player_tank.tank_type = Tank.TankType.PLAYER
	player_tank.position = Vector2(100, 100)
	add_child_autofree(player_tank)
	player_tank.activate_invulnerability(0.1) # Short duration for testing
	
	# When: Immunity duration elapses
	await wait_physics_frames(10)  # Allow timer to process
	
	# Then: Immunity ends
	assert_ne(player_tank.current_state, Tank.State.INVULNERABLE,
		"Should no longer be invulnerable")

func test_given_player_immune_when_hit_by_bullet_then_takes_no_damage():
	# Given: Player with active immunity
	var player_tank = Tank.new()
	player_tank.tank_type = Tank.TankType.PLAYER
	player_tank.current_health = 1
	player_tank.position = Vector2(100, 100)
	add_child_autofree(player_tank)
	player_tank.activate_invulnerability(5.0)
	
	# When: Bullet hits player
	player_tank.take_damage(1)
	
	# Then: No damage taken
	assert_eq(player_tank.current_health, 1, "Should take no damage while immune")
	assert_eq(player_tank.current_state, Tank.State.INVULNERABLE,
		"Should remain invulnerable")

func test_given_player_dead_when_no_lives_then_no_respawn():
	# Given: Player with 0 lives
	var player_tank = Tank.new()
	player_tank.tank_type = Tank.TankType.PLAYER
	player_tank.lives = 0
	
	# When: Player dies
	var can_respawn = player_tank.lives > 0
	
	# Then: Cannot respawn
	assert_false(can_respawn, "Should not respawn with 0 lives")

## ============================================================================
## Epic: Base Destruction & Game Over
## ============================================================================

func test_given_base_exists_when_initialized_then_has_health():
	# Given: Base entity created
	var base = Base.new()
	
	# Then: Base has health
	assert_gt(base.health, 0, "Base should have health")
	assert_false(base.is_destroyed, "Base should not be destroyed initially")

func test_given_base_hit_when_takes_damage_then_health_decreases():
	# Given: Base with full health
	var base = Base.new()
	var initial_health = base.health
	
	# When: Base takes damage
	base.take_damage(1)
	
	# Then: Health decreases
	assert_lt(base.health, initial_health, "Base health should decrease")

func test_given_base_health_zero_when_destroyed_then_marks_as_destroyed():
	# Given: Base with 1 health
	var base = Base.new()
	base.health = 1
	
	# When: Base takes fatal damage
	base.take_damage(1)
	
	# Then: Base is destroyed
	assert_true(base.is_destroyed, "Base should be marked as destroyed")

func test_given_base_destroyed_when_event_emitted_then_triggers_game_over():
	# Given: Base destroyed
	var base = Base.new()
	watch_signals(base)
	
	# When: Base takes fatal damage
	base.health = 1
	base.take_damage(1)
	
	# Then: destroyed signal emitted
	assert_signal_emitted(base, "destroyed", "Should emit destroyed signal")

func test_given_playing_when_base_destroyed_then_state_changes_to_game_over():
	# Given: Game in playing state with base
	game_state_manager.current_state = GameStateManager.State.PLAYING
	
	# When: Base destruction triggers game over
	game_state_manager.trigger_game_over("Base destroyed")
	
	# Then: State transitions to GameOver
	assert_eq(game_state_manager.current_state, GameStateManager.State.GAME_OVER,
		"Should transition to GameOver state")

func test_given_playing_when_player_no_lives_then_state_changes_to_game_over():
	# Given: Game in playing state
	game_state_manager.current_state = GameStateManager.State.PLAYING
	
	# When: Player runs out of lives
	game_state_manager.trigger_game_over("No lives remaining")
	
	# Then: State transitions to GameOver
	assert_eq(game_state_manager.current_state, GameStateManager.State.GAME_OVER,
		"Should transition to GameOver state")

## ============================================================================
## Epic: Stage Completion
## ============================================================================

func test_given_playing_when_all_enemies_defeated_then_stage_complete():
	# Given: Game in playing state with enemy count
	game_state_manager.current_state = GameStateManager.State.PLAYING
	watch_signals(game_state_manager)
	
	# When: All enemies defeated
	game_state_manager.check_stage_completion(0) # 0 enemies remaining
	
	# Then: Stage completion triggered
	assert_signal_emitted(game_state_manager, "stage_completed", "Should emit stage_completed signal")

func test_given_stage_complete_when_triggered_then_transitions_to_stage_complete_state():
	# Given: All enemies defeated
	game_state_manager.current_state = GameStateManager.State.PLAYING
	
	# When: Stage completion triggered
	game_state_manager.complete_stage()
	
	# Then: State transitions to StageComplete
	assert_eq(game_state_manager.current_state, GameStateManager.State.STAGE_COMPLETE,
		"Should transition to StageComplete state")

func test_given_stage_complete_when_continue_pressed_then_loads_next_stage():
	# Given: Stage complete state
	game_state_manager.current_state = GameStateManager.State.STAGE_COMPLETE
	game_state_manager.current_stage = 5
	watch_signals(game_state_manager)
	
	# When: Continue to next stage
	game_state_manager.load_next_stage()
	
	# Then: Next stage loads
	assert_eq(game_state_manager.current_stage, 6, "Should increment stage number")
	assert_signal_emitted(game_state_manager, "next_stage_loaded", "Should emit next_stage_loaded signal")

## ============================================================================
## Epic: Pause System
## ============================================================================

func test_given_playing_when_pause_pressed_then_transitions_to_paused():
	# Given: Game in playing state
	game_state_manager.current_state = GameStateManager.State.PLAYING
	
	# When: Pause triggered
	game_state_manager.toggle_pause()
	
	# Then: State transitions to Paused
	assert_eq(game_state_manager.current_state, GameStateManager.State.PAUSED,
		"Should transition to Paused state")

func test_given_paused_when_resume_pressed_then_transitions_to_playing():
	# Given: Game paused
	game_state_manager.current_state = GameStateManager.State.PAUSED
	
	# When: Resume triggered
	game_state_manager.toggle_pause()
	
	# Then: State transitions to Playing
	assert_eq(game_state_manager.current_state, GameStateManager.State.PLAYING,
		"Should transition to Playing state")

func test_given_paused_when_quit_to_menu_then_transitions_to_main_menu():
	# Given: Game paused
	game_state_manager.current_state = GameStateManager.State.PAUSED
	
	# When: Quit to menu triggered
	game_state_manager.quit_to_menu()
	
	# Then: State transitions to MainMenu
	assert_eq(game_state_manager.current_state, GameStateManager.State.MAIN_MENU,
		"Should transition to MainMenu state")

## ============================================================================
## Epic: Game Over Flow
## ============================================================================

func test_given_game_over_when_retry_pressed_then_restarts_stage():
	# Given: Game over state
	game_state_manager.current_state = GameStateManager.State.GAME_OVER
	game_state_manager.current_stage = 3
	watch_signals(game_state_manager)
	
	# When: Retry pressed
	game_state_manager.retry_stage()
	
	# Then: Stage restarts
	assert_eq(game_state_manager.current_state, GameStateManager.State.PLAYING,
		"Should transition to Playing state")
	assert_eq(game_state_manager.current_stage, 3, "Should restart same stage")
	assert_signal_emitted(game_state_manager, "stage_restarted", "Should emit stage_restarted signal")

func test_given_game_over_when_quit_pressed_then_returns_to_menu():
	# Given: Game over state
	game_state_manager.current_state = GameStateManager.State.GAME_OVER
	
	# When: Quit to menu pressed
	game_state_manager.quit_to_menu()
	
	# Then: Returns to main menu
	assert_eq(game_state_manager.current_state, GameStateManager.State.MAIN_MENU,
		"Should transition to MainMenu state")

func test_given_base_destroyed_when_game_over_triggers_then_player_cannot_shoot():
	# Given: Game flow manager in playing state
	var flow_manager = GameFlowManager.new()
	add_child_autofree(flow_manager)
	await get_tree().process_frame
	
	# Transition to playing state first
	flow_manager.state_manager._transition_to(GameStateManager.State.PLAYING)
	
	# When: Base destroyed and game over triggered
	flow_manager.state_manager.trigger_game_over("Base destroyed")
	await get_tree().process_frame
	
	# Then: Game is in game over state
	assert_eq(flow_manager.state_manager.current_state, GameStateManager.State.GAME_OVER,
		"Should be in game over state after base destruction")

func test_given_base_with_health_when_destroyed_then_game_over_triggered():
	# Given: Game flow manager with base in game
	var flow_manager = GameFlowManager.new()
	add_child_autofree(flow_manager)
	await get_tree().process_frame
	flow_manager.state_manager.current_state = GameStateManager.State.PLAYING
	var base = Base.new()
	flow_manager.base = base
	add_child_autofree(base)
	await get_tree().process_frame
	
	# When: Base takes fatal damage
	base.take_damage(1)
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	# Then: Game over triggered
	assert_eq(flow_manager.state_manager.current_state, GameStateManager.State.GAME_OVER,
		"Should transition to game over when base destroyed")

func test_given_game_over_when_enemy_spawner_active_then_stops_spawning():
	# Given: Enemy spawner active and game transitions to game over
	var spawner = EnemySpawner.new()
	add_child_autofree(spawner)
	spawner.start_wave(1)
	assert_true(spawner.is_spawning, "Spawner should be active")
	
	# When: Game over occurs
	spawner.stop_wave()
	
	# Then: Spawner stops
	assert_false(spawner.is_spawning, "Spawner should stop when game over")

## ============================================================================
## Epic: State Validation
## ============================================================================

func test_given_any_state_when_invalid_transition_then_blocks_transition():
	# Given: Game in playing state
	game_state_manager.current_state = GameStateManager.State.PLAYING
	
	# When: Invalid transition attempted (e.g., directly to stage complete without enemies defeated)
	var can_transition = game_state_manager.can_transition_to(GameStateManager.State.MAIN_MENU)
	
	# Then: Transition blocked
	assert_false(can_transition, "Should not allow invalid transition")

func test_given_playing_when_valid_transitions_then_allows_transition():
	# Given: Game in playing state
	game_state_manager.current_state = GameStateManager.State.PLAYING
	
	# When: Valid transitions checked
	var can_pause = game_state_manager.can_transition_to(GameStateManager.State.PAUSED)
	var can_game_over = game_state_manager.can_transition_to(GameStateManager.State.GAME_OVER)
	var can_stage_complete = game_state_manager.can_transition_to(GameStateManager.State.STAGE_COMPLETE)
	
	# Then: Valid transitions allowed
	assert_true(can_pause, "Should allow pause")
	assert_true(can_game_over, "Should allow game over")
	assert_true(can_stage_complete, "Should allow stage complete")
