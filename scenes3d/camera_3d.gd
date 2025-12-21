extends Camera3D

## Top-down orthogonal camera for TANKS1990 3D view
## Provides arcade-style overhead perspective matching original 2D gameplay
## Camera is locked to playfield bounds (26x26 tiles = 416x416 pixels)

const GRID_SIZE := 26
const CAMERA_HEIGHT := 10.0
const PLAYFIELD_SIZE_PIXELS := 416 # 26 tiles * 16 pixels
const TILE_SIZE_WORLD := 1.0 / 16.0 # World units per pixel
const CAMERA_PADDING := 0.75 # Base padding to avoid clipping at edges
const UI_SAFE_MARGIN := 1.0 # Additional world-units margin so HUD never hides the playfield

var player_tank: Node3D = null
var _playfield_world_size: float = PLAYFIELD_SIZE_PIXELS * TILE_SIZE_WORLD

func _ready() -> void:
	# Configure camera for top-down orthogonal view
	projection = PROJECTION_ORTHOGONAL
	current = true
	_update_camera_size()
	
	# Position centered over playfield
	position = Vector3(_playfield_world_size * 0.5, CAMERA_HEIGHT, _playfield_world_size * 0.5)
	
	# Rotate to look straight down (-90° on X-axis)
	rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	
	# Set reasonable clipping planes
	near = 0.1
	far = 50.0

	# Recompute framing when viewport size changes
	get_viewport().size_changed.connect(_update_camera_size)

## Calculate orthographic size so the full playfield is visible regardless of aspect ratio
func _update_camera_size() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var aspect: float = max(viewport_size.aspect(), 0.0001)
	var safety: float = CAMERA_PADDING + UI_SAFE_MARGIN
	var half_height: float = _playfield_world_size * 0.5 + safety
	var half_width: float = _playfield_world_size * 0.5 + safety

	# Size is half of the vertical span; ensure both width and height fit
	size = max(half_height, half_width / aspect)

## Set the player tank to follow (optional - for camera tracking)
func set_player_tank(tank: Node3D) -> void:
	player_tank = tank

func _process(_delta: float) -> void:
	if player_tank and is_instance_valid(player_tank):
		_follow_player_clamped()

## Follow player tank but clamp to playfield bounds
func _follow_player_clamped() -> void:
	# Calculate half viewport size in world units
	var half_view_width: float = size * get_viewport().get_visible_rect().size.aspect()
	var half_view_height: float = size

	# Playfield bounds in world units (0 to 26)
	var playfield_min := 0.0
	var playfield_max := _playfield_world_size

	# Clamp camera position to keep it within playfield while handling oversized views
	position.x = _clamp_axis(player_tank.position.x, half_view_width, playfield_min, playfield_max)
	position.z = _clamp_axis(player_tank.position.z, half_view_height, playfield_min, playfield_max)

func _clamp_axis(value: float, half_view: float, min_bound: float, max_bound: float) -> float:
	# If the view is wider than the playfield, anchor to center to avoid inverted clamps
	if half_view * 2.0 >= (max_bound - min_bound):
		return (min_bound + max_bound) * 0.5
	return clampf(value, min_bound + half_view, max_bound - half_view)
