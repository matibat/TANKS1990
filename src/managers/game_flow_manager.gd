class_name GameFlowManager
extends Node
## Coordinates game flow: menu, gameplay, respawns, game over

# References
var state_manager: GameStateManager
var player_tank: Tank
var base: Base
var enemy_manager: Node  # Will be EnemyAIController
var power_up_manager: Node  # PowerUpManager for spawning power-ups

# Player tracking
var player_spawn_position: Vector2 = Vector2(128, 368)  # Bottom left (8 tiles from left, 23 tiles from top)
const RESPAWN_IMMUNITY_DURATION: float = 5.0

# UI references
var main_menu: Control
var game_over_ui: Control
var hud: Control

func _ready() -> void:
	# Initialize state manager
	state_manager = GameStateManager.new()
	add_child(state_manager)
	
	# Initialize power-up manager
	var PowerUpManagerClass = load("res://src/managers/power_up_manager.gd")
	power_up_manager = PowerUpManagerClass.new()
	add_child(power_up_manager)
	
	# Connect state change signals
	state_manager.state_changed.connect(_on_state_changed)
	state_manager.game_started.connect(_on_game_started)
	state_manager.game_over_triggered.connect(_on_game_over)
	state_manager.stage_completed.connect(_on_stage_completed)
	state_manager.stage_restarted.connect(_on_stage_restarted)
	
	# Subscribe to EventBus for base destruction
	EventBus.subscribe("BaseDestroyed", _on_event_emitted)

func _on_state_changed(_from_state: GameStateManager.State, to_state: GameStateManager.State) -> void:
	match to_state:
		GameStateManager.State.MAIN_MENU:
			_show_main_menu()
			get_tree().paused = true  # Pause during menu
		GameStateManager.State.PLAYING:
			_hide_menus()
			get_tree().paused = false
		GameStateManager.State.PAUSED:
			get_tree().paused = true
		GameStateManager.State.GAME_OVER:
			_show_game_over()
			get_tree().paused = true  # Pause during game over
			# Stop enemy spawning
			if enemy_manager and enemy_manager.has_method("stop_wave"):
				enemy_manager.stop_wave()
		GameStateManager.State.STAGE_COMPLETE:
			_show_stage_complete()
			get_tree().paused = true  # Pause during stage complete

func _on_game_started() -> void:
	"""Start new game session"""
	_spawn_player()
	_spawn_base()
	_load_stage(state_manager.current_stage)

func _on_game_over(reason: String) -> void:
	"""Handle game over"""
	print("Game Over: ", reason)
	if game_over_ui and game_over_ui.has_method("set_game_over_data"):
		game_over_ui.set_game_over_data(
			state_manager.current_stage,
			state_manager.total_score,
			reason
		)

func _on_stage_completed() -> void:
	"""Handle stage completion"""
	await get_tree().create_timer(2.0).timeout
	state_manager.load_next_stage()

func _on_stage_restarted() -> void:
	"""Restart current stage"""
	_clear_stage()
	_spawn_player()
	_spawn_base()
	_load_stage(state_manager.current_stage)

func _on_event_emitted(event: GameEvent) -> void:
	"""Handle game events"""
	var event_type = event.get_event_type()
	match event_type:
		"BaseDestroyed":
			state_manager.trigger_game_over("Base destroyed")
		"TankDestroyed":
			var tank_event = event as TankDestroyedEvent
			if tank_event.was_player:
				_on_player_died()

## ============================================================================
## Player Management
## ============================================================================

func _spawn_player() -> void:
	"""Spawn or respawn player tank"""
	# Get player tank from scene
	if not player_tank:
		var game_root = get_parent()
		if game_root and game_root.has_node("PlayerTank"):
			player_tank = game_root.get_node("PlayerTank")
		else:
			# Create new player tank if not in scene
			player_tank = _create_player_tank()
			if game_root:
				game_root.add_child(player_tank)
	
	# Reset player tank
	player_tank.position = player_spawn_position
	player_tank.lives = state_manager.player_lives
	player_tank.current_health = player_tank.max_health
	player_tank.visible = true
	
	# Start with immunity
	player_tank.activate_invulnerability(RESPAWN_IMMUNITY_DURATION)

func _create_player_tank() -> Tank:
	"""Create player tank instance"""
	var tank_scene = load("res://scenes/player_tank.tscn")
	if tank_scene:
		return tank_scene.instantiate()
	else:
		# Fallback to programmatic creation
		var tank = Tank.new()
		tank.tank_type = Tank.TankType.PLAYER
		tank.is_player = true
		return tank

func _on_player_died() -> void:
	"""Handle player death"""
	state_manager.player_lives -= 1
	
	if state_manager.player_lives > 0:
		# Respawn after delay
		await get_tree().create_timer(1.0).timeout
		_spawn_player()
	else:
		# Game over
		state_manager.trigger_game_over("No lives remaining")

## ============================================================================
## Base Management
## ============================================================================

func _spawn_base() -> void:
	"""Spawn the Eagle base"""
	if base:
		base.queue_free()
	
	base = Base.new()
	# Position set in base._ready() - bottom center at (208, 384)
	
	# Add to game root
	var game_root = get_parent()
	if game_root:
		game_root.add_child(base)
	else:
		add_child(base)

## ============================================================================
## Stage Management
## ============================================================================

func _load_stage(stage_number: int) -> void:
	"""Load stage data and spawn enemies"""
	print("Loading stage ", stage_number)
	
	# Get enemy spawner from scene if not set
	if not enemy_manager:
		var game_root = get_parent()
		if game_root and game_root.has_node("EnemySpawner"):
			enemy_manager = game_root.get_node("EnemySpawner")
	
	# Start enemy spawning
	if enemy_manager and enemy_manager.has_method("start_wave"):
		enemy_manager.start_wave(stage_number)
	
	# TODO: Load terrain from stage file

func _clear_stage() -> void:
	"""Clear current stage entities"""
	# Clear all bullets
	get_tree().call_group("bullets", "queue_free")
	
	# Clear all enemies
	get_tree().call_group("enemies", "queue_free")
	
	# Clear terrain
	# TODO: Clear terrain tiles

## ============================================================================
## UI Management
## ============================================================================

func _show_main_menu() -> void:
	"""Display main menu"""
	if main_menu:
		main_menu.visible = true
	if hud:
		hud.visible = false

func _hide_menus() -> void:
	"""Hide all UI menus"""
	if main_menu:
		main_menu.visible = false
	if game_over_ui:
		game_over_ui.visible = false
	if hud:
		hud.visible = true

func _show_game_over() -> void:
	"""Display game over screen"""
	if game_over_ui:
		game_over_ui.visible = true
	if hud:
		hud.visible = false

func _show_stage_complete() -> void:
	"""Display stage complete notification"""
	# TODO: Show stage complete UI
	pass

## ============================================================================
## Public API
## ============================================================================

func start_new_game() -> void:
	"""Start new game from main menu"""
	state_manager.start_game()

func retry_current_stage() -> void:
	"""Retry after game over"""
	state_manager.retry_stage()

func return_to_main_menu() -> void:
	"""Return to main menu"""
	_clear_stage()
	state_manager.quit_to_menu()

func toggle_pause() -> void:
	"""Toggle pause state"""
	state_manager.toggle_pause()
