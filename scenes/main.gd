extends Node
## Root game controller - manages menu, gameplay, and game over flow

# UI References - loaded at runtime since they're instance placeholders
var main_menu: Control = null
var game_over_ui: Control = null

# Game systems
var game_manager: GameFlowManager

func _ready() -> void:
	# Load UI nodes (they're instance placeholders in the scene)
	if has_node("UI/MainMenu"):
		var menu_node = get_node("UI/MainMenu")
		if menu_node is InstancePlaceholder:
			main_menu = menu_node.create_instance()
			if main_menu:
				get_node("UI").add_child(main_menu)
				menu_node.queue_free()
		else:
			main_menu = menu_node
	
	if has_node("UI/GameOver"):
		var game_over_node = get_node("UI/GameOver")
		if game_over_node is InstancePlaceholder:
			game_over_ui = game_over_node.create_instance()
			if game_over_ui:
				get_node("UI").add_child(game_over_ui)
				game_over_node.queue_free()
		else:
			game_over_ui = game_over_node
	
	# Initialize game manager
	game_manager = GameFlowManager.new()
	add_child(game_manager)
	
	# Connect UI to game manager
	game_manager.main_menu = main_menu
	game_manager.game_over_ui = game_over_ui
	
	# Connect menu signals
	if main_menu:
		if main_menu.has_signal("start_game_pressed"):
			main_menu.start_game_pressed.connect(_on_start_game)
		if main_menu.has_signal("quit_pressed"):
			main_menu.quit_pressed.connect(_on_quit_game)
		main_menu.visible = true
	
	# Connect game over signals  
	if game_over_ui:
		if game_over_ui.has_signal("retry_pressed"):
			game_over_ui.retry_pressed.connect(_on_retry_game)
		if game_over_ui.has_signal("quit_to_menu_pressed"):
			game_over_ui.quit_to_menu_pressed.connect(_on_return_to_menu)
		game_over_ui.visible = false
	
	# Hide player tank until game starts
	if has_node("PlayerTank"):
		get_node("PlayerTank").visible = false
	
	print("Tank 1990 - Ready to play!")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if game_manager and game_manager.state_manager:
			game_manager.toggle_pause()

func _on_start_game() -> void:
	if main_menu:
		main_menu.visible = false
	if game_manager:
		game_manager.start_new_game()

func _on_quit_game() -> void:
	get_tree().quit()

func _on_retry_game() -> void:
	if game_over_ui:
		game_over_ui.visible = false
	if game_manager:
		game_manager.retry_current_stage()

func _on_return_to_menu() -> void:
	if game_over_ui:
		game_over_ui.visible = false
	if main_menu:
		main_menu.visible = true
	if game_manager:
		game_manager.return_to_main_menu()
