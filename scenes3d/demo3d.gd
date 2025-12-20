extends Node3D
## Demo scene script for testing 3D gameplay

func _ready() -> void:
	print("=== 3D DEMO SCENE LOADED ===")
	print("Camera: ", $Camera3D.global_position)
	print("Player Tank: ", $GameplayLayer/PlayerTank3D.global_position)
	print("Base: ", $GameplayLayer/Base3D.global_position)
	print("Enemy Tanks: ", $GameplayLayer.get_child_count())
	print("Press F5 to play this scene in Godot editor")
	print("WASD should control player tank (if controller is attached)")
	print("=============================")

func _process(_delta: float) -> void:
	# Simple camera controls for demo
	if Input.is_action_pressed("ui_up"):
		$Camera3D.position.z -= 10 * _delta
	if Input.is_action_pressed("ui_down"):
		$Camera3D.position.z += 10 * _delta
	if Input.is_action_pressed("ui_left"):
		$Camera3D.position.x -= 10 * _delta
	if Input.is_action_pressed("ui_right"):
		$Camera3D.position.x += 10 * _delta
