extends Node
## Root game controller - manages full game flow

@onready var game_manager: GameFlowManager = $GameFlowManager
@onready var main_menu: Control = $UI/MainMenu
@onready var game_over_ui: Control = $UI/GameOver
@onready var gameplay_root: Node2D = $GameplayRoot

func _ready() -> void:
	# Connect UI to game manager
	if game_manager:
		game_manager.main_menu = main_menu
		game_manager.game_over_ui = game_over_ui
	
	# Connect menu signals
	if main_menu:
		main_menu.start_game_pressed.connect(_on_start_game)
		main_menu.quit_pressed.connect(_on_quit)
	
	# Connect game over signals
	if game_over_ui:
		game_over_ui.retry_pressed.connect(_on_retry)
		game_over_ui.quit_to_menu_pressed.connect(_on_quit_to_menu)
		game_over_ui.visible = false
	
	# Start in main menu
	print("Tank 1990 - Game started")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if game_manager and game_manager.state_manager:
			game_manager.toggle_pause()

func _on_start_game() -> void:
	if game_manager:
		game_manager.start_new_game()

func _on_retry() -> void:
	if game_manager:
		game_manager.retry_current_stage()

func _on_quit_to_menu() -> void:
	if game_manager:
		game_manager.return_to_main_menu()

func _on_quit() -> void:
	get_tree().quit()
