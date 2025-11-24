extends Node
## Quick test script - spawn armored tank and power-up on key press

func _ready():
	print("Power-up test loaded - Press 'T' to spawn armored tank, 'P' to spawn power-up directly")

func _input(event):
	if event.is_action_pressed("ui_text_completion_accept"):  # T key
		spawn_test_armored_tank()
	elif event.is_action_pressed("ui_page_down"):  # P key
		spawn_test_power_up()

func spawn_test_armored_tank():
	var Tank = load("res://src/entities/tank.gd")
	var tank = Tank.new()
	tank.tank_type = Tank.TankType.ARMORED
	tank.global_position = get_viewport().get_mouse_position()
	get_tree().current_scene.add_child(tank)
	print("Spawned Armored tank at ", tank.global_position)

func spawn_test_power_up():
	var PowerUpManager = load("res://src/managers/power_up_manager.gd")
	var manager = PowerUpManager.new()
	manager.spawn_power_up(get_viewport().get_mouse_position())
	print("Spawned power-up at mouse position")
