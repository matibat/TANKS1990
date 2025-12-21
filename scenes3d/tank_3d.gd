class_name Tank3D
extends Node3D
## Tank3D - Visual representation of a tank in 3D
## Pure presentation - reacts to adapter signals, no game logic

const TankEntity = preload("res://src/domain/entities/tank_entity.gd")
const INTERP_EPS := 0.1

## Tank identity
var tank_id: String = ""
var tank_type: int = TankEntity.Type.PLAYER
var tank_entity: TankEntity = null # Reference to domain entity for invulnerability check

## Visual components
@onready var body: CSGBox3D = $Body
@onready var turret: CSGBox3D = $Turret

## Movement interpolation (optional)
var target_position: Vector3
var target_rotation: float
var last_position: Vector3 # Position at last logic tick
var last_rotation: float
var tick_progress: float = 0.0
var movement_speed: float = 5.0
var use_interpolation: bool = true # Enable smooth interpolation
var _has_pending_motion: bool = false
var _idle_time: float = 0.0
var _base_turret_scale: Vector3
var _idle_scale_pulse: float = 0.015
var _base_body_color: Color
var _base_turret_color: Color
var previous_progress: float = 0.0

func _ready() -> void:
	target_position = position
	target_rotation = rotation.y
	last_position = position
	last_rotation = rotation.y
	_base_turret_scale = turret.scale
	
	# Set color based on tank type
	_setup_visual()
	_base_body_color = body.material.albedo_color
	_base_turret_color = turret.material.albedo_color

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
	if target_position.is_equal_approx(new_position) and is_equal_approx(target_rotation, new_rotation):
		return
	# Store current pose so interpolation starts from the actual previous position
	if use_interpolation:
		last_position = position
		last_rotation = rotation.y
	else:
		position = new_position
		rotation.y = new_rotation

	target_position = new_position
	target_rotation = new_rotation
	tick_progress = 0.0
	_has_pending_motion = use_interpolation

	# If not using interpolation, snap immediately
	if not use_interpolation:
		tick_progress = 1.0

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
func _physics_process(_delta: float) -> void:
	# Interpolation is handled by set_tick_progress called from game_root
	pass

func _process(delta: float) -> void:
	# Invulnerability visual: gentle alpha pulse instead of visibility toggling
	var invuln = tank_entity and tank_entity.is_invulnerable()
	if invuln:
		_idle_time = 0.0
		turret.scale = _base_turret_scale
		var phase = sin(Time.get_ticks_msec() * 0.0125)
		var alpha = clamp(0.6 + 0.4 * phase, 0.2, 1.0)
		var body_color = _base_body_color
		body_color.a = alpha
		var turret_color = _base_turret_color
		turret_color.a = alpha
		body.material.albedo_color = body_color
		turret.material.albedo_color = turret_color
	else:
		visible = true
		body.material.albedo_color = _base_body_color
		turret.material.albedo_color = _base_turret_color

	# Idle animation: subtle turret breathing only when no motion is pending
	if not use_interpolation:
		return
	if _has_pending_motion:
		_idle_time = 0.0
		turret.scale = _base_turret_scale
		return
	_idle_time += delta
	var cycle_time = 4.0
	var cycle_progress = fmod(_idle_time, cycle_time)
	if cycle_progress < 2.0:
		var wobble = sin(cycle_progress * TAU * 0.5) * _idle_scale_pulse
		var scale_factor = 1.0 + wobble
		turret.scale = _base_turret_scale * scale_factor
	else:
		turret.scale = _base_turret_scale

func set_tick_progress(progress: float) -> void:
	if not use_interpolation:
		return
	
	# Detect tick reset (progress went low, assuming tick happened)
	var was_reset = progress < previous_progress
	previous_progress = progress
	
	if was_reset:
		# Complete interpolation
		_has_pending_motion = false
		position = target_position
		rotation.y = target_rotation
		last_position = target_position
		last_rotation = target_rotation
		tick_progress = 1.0
	
	if not _has_pending_motion:
		position = target_position
		rotation.y = target_rotation
		return
	
	tick_progress = clamp(progress, 0.0, 1.0)
	position = last_position.lerp(target_position, tick_progress)
	rotation.y = lerp_angle(last_rotation, target_rotation, tick_progress)
	
	if tick_progress >= 0.5:
		_has_pending_motion = false
		last_position = target_position
		last_rotation = target_rotation
		tick_progress = 1.0

	if not _has_pending_motion:
		position = target_position
		rotation.y = target_rotation

func is_interpolating() -> bool:
	return _has_pending_motion
