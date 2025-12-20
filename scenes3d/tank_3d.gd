class_name Tank3D
extends Node3D
## Tank3D - Visual representation of a tank in 3D
## Pure presentation - reacts to adapter signals, no game logic

const TankEntity = preload("res://src/domain/entities/tank_entity.gd")

## Tank identity
var tank_id: String = ""
var tank_type: int = TankEntity.Type.PLAYER

## Visual components
@onready var body: CSGBox3D = $Body
@onready var turret: CSGBox3D = $Turret

## Movement interpolation (optional)
var target_position: Vector3
var target_rotation: float
var last_position: Vector3 # Position at last logic tick
var movement_speed: float = 5.0
var use_interpolation: bool = true # Enable smooth interpolation

func _ready() -> void:
	target_position = position
	target_rotation = rotation.y
	last_position = position
	
	# Set color based on tank type
	_setup_visual()

## Setup visual appearance based on tank type
func _setup_visual() -> void:
	var material = StandardMaterial3D.new()
	
	match tank_type:
		TankEntity.Type.PLAYER:
			material.albedo_color = Color(0.2, 0.8, 0.2) # Green
		TankEntity.Type.ENEMY_BASIC:
			material.albedo_color = Color(0.8, 0.2, 0.2) # Red
		TankEntity.Type.ENEMY_FAST:
			material.albedo_color = Color(0.9, 0.5, 0.2) # Orange
		TankEntity.Type.ENEMY_ARMORED:
			material.albedo_color = Color(0.6, 0.2, 0.6) # Purple
		_:
			material.albedo_color = Color(0.5, 0.5, 0.5) # Gray
	
	body.material = material
	
	# Turret is slightly darker
	var turret_material = StandardMaterial3D.new()
	turret_material.albedo_color = material.albedo_color.darkened(0.2)
	turret.material = turret_material

## Called when tank should move to new position
func move_to(new_position: Vector3, new_rotation: float) -> void:
	# Store previous position for interpolation
	if use_interpolation:
		last_position = target_position
	
	target_position = new_position
	target_rotation = new_rotation
	
	# If not using interpolation, snap immediately
	if not use_interpolation:
		position = new_position
		rotation.y = new_rotation

## Called when tank takes damage
func take_damage(damage: int, new_health: int) -> void:
	# Visual feedback - flash white
	var original_color = body.material.albedo_color
	body.material.albedo_color = Color.WHITE
	turret.material.albedo_color = Color.WHITE
	
	await get_tree().create_timer(0.1).timeout
	
	body.material.albedo_color = original_color
	turret.material.albedo_color = original_color.darkened(0.2)
	
	# Scale down slightly if damaged
	if new_health <= 1:
		scale = Vector3(0.9, 0.9, 0.9)

## Called when tank is destroyed
func play_destroy_effect() -> void:
	# Simple explosion effect - scale up and fade
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3(1.5, 1.5, 1.5), 0.3)
	tween.tween_property(body.material, "albedo_color", Color(1, 0.5, 0, 0.5), 0.3)
	tween.tween_property(turret.material, "albedo_color", Color(1, 0.5, 0, 0.5), 0.3)

## Optional: Smooth interpolation in physics process
func _physics_process(delta: float) -> void:
	if not use_interpolation:
		return
	
	# Interpolate position with smooth lerp
	# Using higher lerp factor for responsive feel at 60 FPS
	if position.distance_to(target_position) > 0.01:
		position = position.lerp(target_position, min(movement_speed * delta, 1.0))
	else:
		position = target_position
	
	# Interpolate rotation
	var rotation_diff = target_rotation - rotation.y
	if abs(rotation_diff) > 0.01:
		rotation.y = lerp_angle(rotation.y, target_rotation, min(movement_speed * delta, 1.0))
	else:
		rotation.y = target_rotation
