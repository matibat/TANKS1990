## HUD (Heads-Up Display)
## Shows real-time game information: score, lives, enemies, stage
extends Control

@onready var score_label: Label = %ScoreLabel
@onready var lives_label: Label = %LivesLabel
@onready var enemies_label: Label = %EnemiesLabel
@onready var stage_label: Label = %StageLabel


func _ready() -> void:
	# Initialize with default values
	update_score(0)
	update_lives(3)
	update_enemies(20)
	update_stage(1)


## Updates the score display
func update_score(score: int) -> void:
	score_label.text = "SCORE: %d" % score


## Updates the lives counter display
func update_lives(lives: int) -> void:
	lives_label.text = "LIVES: %d" % lives


## Updates the remaining enemies display
func update_enemies(remaining: int) -> void:
	enemies_label.text = "ENEMIES: %d" % remaining


## Updates the current stage number display
func update_stage(stage_num: int) -> void:
	stage_label.text = "STAGE %d" % stage_num
