## Game Over Screen
## Displays final score and Try Again/Main Menu options
extends Control

## Emitted when player clicks Try Again button
signal try_again_pressed

## Emitted when player clicks Main Menu button
signal main_menu_pressed

@onready var final_score_label: Label = %FinalScoreLabel


func _ready() -> void:
	# Connect button signals
	%TryAgainButton.pressed.connect(_on_try_again_button_pressed)
	%MainMenuButton.pressed.connect(_on_main_menu_button_pressed)
	
	# Start hidden
	hide()


## Sets and displays the final score
func set_final_score(score: int) -> void:
	final_score_label.text = "FINAL SCORE: %d" % score


## Shows the game over screen with the given score
func show_game_over(score: int) -> void:
	set_final_score(score)
	show()


func _on_try_again_button_pressed() -> void:
	try_again_pressed.emit()


func _on_main_menu_button_pressed() -> void:
	main_menu_pressed.emit()
