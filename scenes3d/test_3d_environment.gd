extends Node3D

## Phase 2: Test 3D Environment Scene
## Provides orthogonal camera, lighting, and ground plane for top-down arcade view
## 
## Coordinate System: Y-up (3D standard)
## Camera Position: (13, 10, 13) - centered over 26x26 grid
## Camera Rotation: (-90°, 0°, 0°) - looking straight down
## Projection: Orthogonal with size=20 for clear top-down view

func _ready():
	# Scene is configured in .tscn file
	# This script provides documentation and future extension points
	pass

func get_camera() -> Camera3D:
	return $Camera3D

func get_light() -> DirectionalLight3D:
	return $DirectionalLight3D

func get_ground() -> MeshInstance3D:
	return $GroundPlane

## Returns the world center position in 3D space (center of 26x26 grid)
func get_world_center() -> Vector3:
	return Vector3(13.0, 0.0, 13.0)
