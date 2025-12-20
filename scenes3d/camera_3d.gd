extends Camera3D

## Top-down orthogonal camera for TANKS1990 3D view
## Provides arcade-style overhead perspective matching original 2D gameplay

const GRID_SIZE := 26
const CAMERA_HEIGHT := 10.0
const ORTHO_SIZE := 20.0


func _ready() -> void:
	# Configure camera for top-down orthogonal view
	projection = PROJECTION_ORTHOGONAL
	size = ORTHO_SIZE
	current = true
	
	# Position centered over 26x26 grid
	position = Vector3(GRID_SIZE / 2.0, CAMERA_HEIGHT, GRID_SIZE / 2.0)
	
	# Rotate to look straight down (-90° on X-axis)
	rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	
	# Set reasonable clipping planes
	near = 0.1
	far = 50.0
