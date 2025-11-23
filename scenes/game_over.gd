extends Control
## Game Over UI

signal retry_pressed()
signal quit_to_menu_pressed()

@onready var stage_label: Label = $VBoxContainer/StageLabel
@onready var score_label: Label = $VBoxContainer/ScoreLabel
@onready var retry_button: Button = $VBoxContainer/RetryButton
@onready var menu_button: Button = $VBoxContainer/MenuButton

var final_stage: int = 1
var final_score: int = 0
var reason: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Work when game is paused
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	retry_button.grab_focus()
	
	_update_display()

func set_game_over_data(stage: int, score: int, game_over_reason: String) -> void:
	final_stage = stage
	final_score = score
	reason = game_over_reason
	_update_display()

func _update_display() -> void:
	if stage_label:
		stage_label.text = "Stage: %d" % final_stage
	if score_label:
		score_label.text = "Score: %d" % final_score

func _on_retry_pressed() -> void:
	retry_pressed.emit()

func _on_menu_pressed() -> void:
	quit_to_menu_pressed.emit()
