## Main Menu Screen
## Displays title and Start/Quit options for the game
extends Control

## Emitted when player clicks Start Game button
signal start_game_pressed

## Emitted when player clicks Quit button
signal quit_pressed


func _ready() -> void:
	# Connect button signals
	%StartButton.pressed.connect(_on_start_button_pressed)
	%QuitButton.pressed.connect(_on_quit_button_pressed)


func _on_start_button_pressed() -> void:
	start_game_pressed.emit()


func _on_quit_button_pressed() -> void:
	quit_pressed.emit()
