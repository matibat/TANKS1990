class_name Bullet3D
extends Node3D
## Bullet3D - Visual representation of a bullet in 3D
## Pure presentation - reacts to adapter signals, no game logic

## Bullet identity
var bullet_id: String = ""

## Visual component
@onready var sphere: CSGSphere3D = $Sphere

## Movement interpolation
var target_position: Vector3
var last_position: Vector3 # Position at last logic tick
var tick_progress: float = 0.0
var movement_speed: float = 15.0 # Faster than tanks for bullets
var use_interpolation: bool = true
var _has_pending_motion: bool = false

func _ready() -> void:
	target_position = position
	last_position = position
	
	# Set bullet appearance
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 1.0, 0.3) # Yellowish
	material.emission_enabled = true
	material.emission = Color(1.0, 1.0, 0.5)
	material.emission_energy = 2.0
	sphere.material = material

## Called when bullet should move to new position
func move_to(new_position: Vector3) -> void:
	# Store previous target so interpolation starts from last committed position
	if use_interpolation:
		last_position = target_position
	else:
		position = new_position

	target_position = new_position
	tick_progress = 0.0
	_has_pending_motion = use_interpolation

	# If not using interpolation, snap immediately
	if not use_interpolation:
		tick_progress = 1.0

## Called when bullet is destroyed
func play_destroy_effect() -> void:
	# Simple flash effect
	var material = sphere.material
	material.albedo_color = Color.WHITE
	material.emission = Color.WHITE
	material.emission_energy = 5.0
	
	# Scale up briefly
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(2.0, 2.0, 2.0), 0.1)

## Smooth interpolation in physics process
func _physics_process(_delta: float) -> void:
	if not use_interpolation:
		return

	position = last_position.lerp(target_position, tick_progress)

func set_tick_progress(progress: float) -> void:
	if not use_interpolation:
		return
	if not _has_pending_motion:
		return
	tick_progress = clamp(progress, 0.0, 1.0)
	position = last_position.lerp(target_position, tick_progress)
	if is_equal_approx(tick_progress, 1.0):
		_has_pending_motion = false
		last_position = target_position
