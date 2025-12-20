extends Camera3D

## Top-down orthogonal camera for TANKS1990 3D view
## Provides arcade-style overhead perspective matching original 2D gameplay
## Camera is locked to playfield bounds (26x26 tiles = 416x416 pixels)

const GRID_SIZE := 26
const CAMERA_HEIGHT := 10.0
const ORTHO_SIZE := 20.0
const PLAYFIELD_SIZE_PIXELS := 416 # 26 tiles * 16 pixels
const TILE_SIZE_WORLD := 1.0 / 16.0 # World units per pixel

var player_tank: Node3D = null

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

## Set the player tank to follow (optional - for camera tracking)
func set_player_tank(tank: Node3D) -> void:
	player_tank = tank

func _process(_delta: float) -> void:
	if player_tank and is_instance_valid(player_tank):
		_follow_player_clamped()

## Follow player tank but clamp to playfield bounds
func _follow_player_clamped() -> void:
	# Calculate half viewport size in world units
	var half_view_width := size * get_viewport().get_visible_rect().size.aspect()
	var half_view_height := size
	
	# Playfield bounds in world units (0 to 26)
	var playfield_min := 0.0
	var playfield_max := PLAYFIELD_SIZE_PIXELS * TILE_SIZE_WORLD
	
	# Clamp camera position to keep it within playfield
	var target_x := clampf(player_tank.position.x, 
		playfield_min + half_view_width, 
		playfield_max - half_view_width)
	var target_z := clampf(player_tank.position.z, 
		playfield_min + half_view_height, 
		playfield_max - half_view_height)
	
	# Update camera position (keep Y fixed)
	position.x = target_x
	position.z = target_z
