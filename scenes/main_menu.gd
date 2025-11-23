extends Control
## Main Menu UI

signal start_game_pressed()
signal quit_pressed()

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Work when game is paused
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	start_button.grab_focus()

func _on_start_pressed() -> void:
	start_game_pressed.emit()

func _on_quit_pressed() -> void:
	quit_pressed.emit()
	get_tree().quit()
