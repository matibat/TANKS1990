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
var movement_speed: float = 10.0

func _ready() -> void:
	target_position = position
	
	# Set bullet appearance
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 1.0, 0.3) # Yellowish
	material.emission_enabled = true
	material.emission = Color(1.0, 1.0, 0.5)
	material.emission_energy = 2.0
	sphere.material = material

## Called when bullet should move to new position
func move_to(new_position: Vector3) -> void:
	target_position = new_position

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
func _physics_process(delta: float) -> void:
	if position.distance_to(target_position) > 0.01:
		position = position.lerp(target_position, movement_speed * delta)
