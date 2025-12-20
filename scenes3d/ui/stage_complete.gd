## Stage Complete Screen
## Displays stage statistics and Next Stage option
extends Control

## Emitted when player clicks Next Stage button
signal next_stage_pressed

@onready var enemies_label: Label = %EnemiesLabel
@onready var time_label: Label = %TimeLabel
@onready var bonus_label: Label = %BonusLabel
@onready var total_label: Label = %TotalLabel


func _ready() -> void:
	# Connect button signals
	%NextStageButton.pressed.connect(_on_next_stage_button_pressed)
	
	# Start hidden
	hide()


## Sets and displays the stage statistics
## enemies: Number of enemies defeated
## time: Time taken in seconds
## bonus: Bonus points earned
func set_stage_stats(enemies: int, time: float, bonus: int) -> void:
	enemies_label.text = "Enemies Defeated: %d" % enemies
	time_label.text = "Time: %.1f sec" % time
	bonus_label.text = "Bonus: %d" % bonus
	
	# Calculate total score
	var enemy_points := enemies * 100
	var total := enemy_points + bonus
	total_label.text = "TOTAL: %d" % total


## Shows the stage complete screen with the given stats
func show_stage_complete(enemies: int, time: float, bonus: int) -> void:
	set_stage_stats(enemies, time, bonus)
	show()


func _on_next_stage_button_pressed() -> void:
	next_stage_pressed.emit()
