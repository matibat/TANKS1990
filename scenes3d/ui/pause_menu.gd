## Pause Menu Screen
## Overlay shown when game is paused with Resume/Quit options
extends Control

## Emitted when player clicks Resume button
signal resume_pressed

## Emitted when player clicks Quit to Menu button
signal quit_to_menu_pressed


func _ready() -> void:
	# Connect button signals
	%ResumeButton.pressed.connect(_on_resume_button_pressed)
	%QuitButton.pressed.connect(_on_quit_button_pressed)
	
	# Start hidden
	hide()


## Shows the pause menu
func show_menu() -> void:
	show()


## Hides the pause menu
func hide_menu() -> void:
	hide()


func _on_resume_button_pressed() -> void:
	resume_pressed.emit()


func _on_quit_button_pressed() -> void:
	quit_to_menu_pressed.emit()
