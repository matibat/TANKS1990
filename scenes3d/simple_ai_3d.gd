extends Node
class_name SimpleAI3D
## Simple AI controller for 3D enemy tanks

@export var tank: Tank3D = null
@export var target: Node3D = null  # Player tank
@export var move_interval: float = 1.0
@export var shoot_chance: float = 0.02  # 2% chance per frame

var move_timer: float = 0.0
var current_direction: Vector3 = Vector3.ZERO
var shoot_timer: float = 0.0
var shoot_cooldown: float = 1.5

func _ready() -> void:
	# If tank not set, try to get parent
	if not tank:
		var parent = get_parent()
		if parent is Tank3D:
			tank = parent
	
	# Choose initial direction
	choose_new_direction()
	move_timer = move_interval

func _physics_process(delta: float) -> void:
	if not tank or not is_instance_valid(tank):
		return
	
	# Skip if tank is spawning or dying
	if tank.current_state == Tank3D.State.SPAWNING or tank.current_state == Tank3D.State.DYING:
		return
	
	# Update movement timer
	move_timer -= delta
	if move_timer <= 0:
		choose_new_direction()
		move_timer = move_interval
	
	# Apply movement
	tank.set_movement_direction(current_direction)
	
	# Shooting logic
	shoot_timer -= delta
	if shoot_timer <= 0 and randf() < shoot_chance:
		tank.try_fire()
		shoot_timer = shoot_cooldown

func choose_new_direction() -> void:
	if not target or not is_instance_valid(target):
		# Random direction
		_choose_random_direction()
		return
	
	# Simple: move toward player with some randomness
	var to_target = (target.global_position - tank.global_position)
	to_target.y = 0  # Ignore Y axis
	to_target = to_target.normalized()
	
	# Add random component for more interesting behavior
	var random_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	
	# 70% toward target, 30% random
	current_direction = (to_target * 0.7 + random_dir * 0.3).normalized()
	
	# Occasionally choose pure random direction (10% chance)
	if randf() < 0.1:
		_choose_random_direction()

func _choose_random_direction() -> void:
	var random_angle = randf() * TAU
	current_direction = Vector3(cos(random_angle), 0, sin(random_angle))
