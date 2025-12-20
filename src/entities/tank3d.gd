class_name Tank3D
extends CharacterBody3D
## 3D Tank entity with movement, shooting, and health (CharacterBody3D)
##
## This is the 3D equivalent of Tank (CharacterBody2D), using Vector3 and 3D physics.
## Maintains the same gameplay logic but operates in 3D space (X/Z plane, Y=0).

signal health_changed(new_health: int, max_health: int)
signal died()
signal state_changed(new_state: State)

enum State { IDLE, MOVING, SHOOTING, DYING, INVULNERABLE, SPAWNING }
enum Direction { UP, DOWN, LEFT, RIGHT }
enum TankType { PLAYER, BASIC, FAST, POWER, ARMORED }

# Configuration
@export var tank_type: TankType = TankType.PLAYER
@export var base_speed: float = 5.0  # Units per second (vs 100 pixels/sec in 2D)
@export var max_health: int = 1
@export var fire_cooldown_time: float = 0.5
@export var invulnerability_duration: float = 3.0

# State
var current_state: State = State.SPAWNING
var facing_direction: Direction = Direction.UP
var current_health: int
var level: int = 0  # 0-3 for player upgrades
var is_player: bool = false
var tank_id: int = 0
var lives: int = 3  # Player lives (only used for player tank)

# Power-up states
var is_invulnerable: bool = false
var invulnerability_time: float = 0.0
var is_frozen: bool = false
var freeze_time: float = 0.0

# Visual
var base_color: Color = Color.WHITE

# Internal
var fire_cooldown: float = 0.0
var invulnerability_timer: float = 0.0
var spawn_timer: float = 0.0
const SPAWN_DURATION: float = 2.0
const TILE_SIZE: float = 0.5  # 3D tile size in units (vs 16px in 2D)
const MAP_WIDTH: float = 13.0  # 26 tiles * 0.5 units
const MAP_HEIGHT: float = 13.0  # 26 tiles * 0.5 units
const TANK_SIZE: float = 1.0  # Tank footprint is 1x1 units (2x2 tiles)
const SUB_GRID_SIZE: float = 0.25  # Movement precision
const BULLET_SPAWN_OFFSET: float = 0.625  # Distance from center (20px / 32 = 0.625)
const EDGE_FIRE_MARGIN: float = 0.5  # Min distance from edge to fire

# Movement control (for continuous 3D movement)
var movement_direction: Vector3 = Vector3.ZERO
var use_continuous_movement: bool = false  # MUST use discrete grid movement for game logic

# Components
@onready var collision_shape: CollisionShape3D = $CollisionShape3D if has_node("CollisionShape3D") else null
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D if has_node("MeshInstance3D") else null

const Vector3Helpers = preload("res://src/utils/vector3_helpers.gd")

func _ready() -> void:
	current_health = max_health
	is_player = (tank_type == TankType.PLAYER)
	_setup_collision()
	_setup_collision_layers()
	
	# Snap spawn position to grid and clamp to safe bounds
	global_position = _snap_to_grid_position(global_position)
	global_position.x = clampf(global_position.x, TILE_SIZE, MAP_WIDTH - TILE_SIZE)
	global_position.z = clampf(global_position.z, TILE_SIZE, MAP_HEIGHT - TILE_SIZE)
	global_position.y = 0.0  # Ground plane
	
	# Quantize for determinism
	global_position = Vector3Helpers.quantize_vec3(global_position)
	
	# Skip spawn animation for testing - go straight to idle
	_change_state(State.IDLE)
	
	# Set visual color based on tank type
	# Note: In 3D, color will be applied via material, not modulate
	match tank_type:
		TankType.PLAYER:
			base_color = Color(0.3, 0.7, 1.0)  # Blue - player tank
		_:
			base_color = Color.WHITE  # Enemies get colored by spawner
	
	# Apply color to mesh if available
	if mesh_instance and mesh_instance.get_surface_override_material_count() > 0:
		var mat = mesh_instance.get_surface_override_material(0)
		if mat and mat is StandardMaterial3D:
			mat.albedo_color = base_color

func _setup_collision() -> void:
	# Tank collision is 1x0.5x1 units (width x height x depth)
	if not collision_shape:
		collision_shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(1.0, 0.5, 1.0)  # 1 unit footprint, 0.5 unit height
		collision_shape.shape = box
		add_child(collision_shape)
		collision_shape.name = "CollisionShape3D"

func _setup_collision_layers() -> void:
	if is_player:
		# Player tanks: Layer 1, Mask: 2|4|5|6 (Enemy, Environment, Base, PowerUp)
		collision_layer = 1
		collision_mask = 2 | 4 | 5 | 6
	else:
		# Enemy tanks: Layer 2, Mask: 1|3|4|5 (Player, Projectile, Environment, Base)
		collision_layer = 2
		collision_mask = 1 | 3 | 4 | 5

func _physics_process(delta: float) -> void:
	# Update timers
	if fire_cooldown > 0:
		fire_cooldown -= delta
	
	if invulnerability_timer > 0:
		invulnerability_timer -= delta
		if invulnerability_timer <= 0:
			_end_invulnerability()
	
	# Power-up timers
	if invulnerability_time > 0:
		invulnerability_time -= delta
		if invulnerability_time <= 0:
			is_invulnerable = false
			_set_tank_color(base_color)
	
	if freeze_time > 0:
		freeze_time -= delta
		if freeze_time <= 0:
			is_frozen = false
			_set_tank_color(base_color)
	
	if spawn_timer > 0:
		spawn_timer -= delta
		if spawn_timer <= 0:
			_complete_spawn()
	
	# Skip processing if frozen
	if is_frozen:
		return
	
	# Process movement
	if current_state == State.MOVING or current_state == State.IDLE:
		_process_movement(delta)

func _process_movement(delta: float) -> void:
	# For discrete movement, all movement logic is handled in move_in_direction()
	# For continuous movement, process velocity here
	if use_continuous_movement and movement_direction.length() > 0:
		_process_continuous_movement(delta)
	# No continuous movement processing needed for discrete mode

func _process_continuous_movement(delta: float) -> void:
	"""Handle smooth continuous movement for 3D demo"""
	if movement_direction.length() > 0:
		# Set velocity based on direction
		velocity = movement_direction * base_speed
		
		# Update rotation to face movement direction
		var angle = atan2(movement_direction.x, -movement_direction.z)
		rotation.y = angle
		
		# Move the tank
		move_and_slide()
		
		# Quantize position for determinism
		global_position = Vector3Helpers.quantize_vec3(global_position, 0.001)
		
		if current_state != State.MOVING:
			_change_state(State.MOVING)
	else:
		velocity = Vector3.ZERO
		if current_state == State.MOVING:
			_change_state(State.IDLE)

## Set movement direction for continuous movement (used by 3D controller)
func set_movement_direction(dir: Vector3) -> void:
	# Force discrete movement and cardinal directions
	use_continuous_movement = false
	
	if dir.length() < 0.01:
		movement_direction = Vector3.ZERO
		stop_movement()
		return
	
	# Snap to cardinal direction (no diagonals!)
	var cardinal_dir = _snap_to_cardinal(dir)
	movement_direction = cardinal_dir
	
	# Convert to Direction enum and move
	var direction_enum = _vector_to_direction(cardinal_dir)
	move_in_direction(direction_enum)

## Set movement direction and perform discrete tile movement
func move_in_direction(direction: Direction) -> void:
	if current_state == State.DYING or current_state == State.SPAWNING:
		return
	
	# Update facing direction
	facing_direction = direction
	
	var current_pos = global_position
	var target_pos = _get_next_tile_center(direction)
	
	# Check if target position would collide with terrain
	if _would_collide_with_terrain(target_pos):
		# Blocked - don't move, but still update facing direction
		_update_rotation()
		return
	
	# Check if target position would collide with another tank
	if _would_collide_with_tank(target_pos):
		# Blocked - don't move, but still update facing direction
		_update_rotation()
		return
	
	# Clear to move - instantly jump to next tile center
	global_position = target_pos
	
	# Quantize for determinism
	global_position = Vector3Helpers.quantize_vec3(global_position)
	
	_update_rotation()
	
	# Emit movement event
	_emit_tank_moved_event()
	
	if current_state != State.MOVING:
		_change_state(State.MOVING)

## Stop tank movement
func stop_movement() -> void:
	# For discrete movement, tanks are always "stopped" at tile centers
	velocity = Vector3.ZERO
	if current_state == State.MOVING:
		_change_state(State.IDLE)

func _snap_to_grid_position(pos: Vector3) -> Vector3:
	"""Snap position to nearest tile center (0.5 unit grid)"""
	return Vector3(
		roundf(pos.x / TILE_SIZE) * TILE_SIZE,
		0.0,  # Ground plane
		roundf(pos.z / TILE_SIZE) * TILE_SIZE
	)

func _get_next_tile_center(direction: Direction) -> Vector3:
	"""Calculate the next tile center position in the given direction"""
	var current_pos = global_position
	var direction_vec = _direction_to_vector(direction)
	var next_pos = current_pos + (direction_vec * TILE_SIZE)
	
	# Clamp to map boundaries
	next_pos.x = clampf(next_pos.x, TILE_SIZE, MAP_WIDTH - TILE_SIZE)
	next_pos.z = clampf(next_pos.z, TILE_SIZE, MAP_HEIGHT - TILE_SIZE)
	next_pos.y = 0.0  # Ground plane
	
	return next_pos

func _direction_to_vector(direction: Direction) -> Vector3:
	"""Convert direction enum to 3D vector (X/Z plane)"""
	match direction:
		Direction.UP:
			return Vector3(0, 0, -1)  # Forward (-Z)
		Direction.DOWN:
			return Vector3(0, 0, 1)   # Backward (+Z)
		Direction.LEFT:
			return Vector3(-1, 0, 0)  # Left (-X)
		Direction.RIGHT:
			return Vector3(1, 0, 0)   # Right (+X)
		_:
			return Vector3.ZERO

func _update_rotation() -> void:
	"""Update tank rotation based on facing direction (Y-axis rotation)"""
	match facing_direction:
		Direction.UP:
			rotation.y = 0.0  # Facing -Z (forward)
		Direction.RIGHT:
			rotation.y = PI / 2  # Facing +X (right)
		Direction.DOWN:
			rotation.y = PI  # Facing +Z (backward)
		Direction.LEFT:
			rotation.y = -PI / 2  # Facing -X (left)

func _snap_to_cardinal(dir: Vector3) -> Vector3:
	"""Force diagonal input to nearest cardinal direction"""
	if absf(dir.x) > absf(dir.z):
		# Horizontal movement dominant
		return Vector3(sign(dir.x), 0, 0)
	else:
		# Vertical movement dominant
		return Vector3(0, 0, sign(dir.z))

func _vector_to_direction(vec: Vector3) -> Direction:
	"""Convert Vector3 to Direction enum"""
	if vec.z < -0.5:
		return Direction.UP
	elif vec.z > 0.5:
		return Direction.DOWN
	elif vec.x < -0.5:
		return Direction.LEFT
	elif vec.x > 0.5:
		return Direction.RIGHT
	else:
		return Direction.UP  # Default

## Attempt to fire bullet
func try_fire() -> bool:
	if fire_cooldown > 0.0:
		return false
	
	if current_state == State.DYING or current_state == State.SPAWNING:
		return false
	
	fire_cooldown = fire_cooldown_time
	_emit_bullet_fired_event()
	return true

## Take damage from bullet or collision
func take_damage(amount: int = 1) -> void:
	if current_state == State.INVULNERABLE or current_state == State.SPAWNING:
		return
	
	# Power-up invulnerability protection
	if is_invulnerable:
		return
	
	if current_state == State.DYING:
		return
	
	current_health -= amount
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		die()

## Handle tank death
func die() -> void:
	_change_state(State.DYING)
	velocity = Vector3.ZERO
	
	# Emit death event
	if EventBus:
		var event = TankDestroyedEvent.new()
		event.tank_id = tank_id
		event.tank_type = _get_tank_type_string()
		event.was_player = is_player
		event.position = global_position  # Vector3
		event.destroyed_by_id = -1
		event.score_value = _get_score_value()
		EventBus.emit_game_event(event)
	
	died.emit()
	
	# Queue free (no animation for now)
	queue_free()

func _get_tank_type_string() -> String:
	match tank_type:
		TankType.PLAYER:
			return "Player"
		TankType.BASIC:
			return "Basic"
		TankType.FAST:
			return "Fast"
		TankType.POWER:
			return "Power"
		TankType.ARMORED:
			return "Armored"
		_:
			return "Unknown"

func _get_score_value() -> int:
	match tank_type:
		TankType.BASIC:
			return 100
		TankType.FAST:
			return 200
		TankType.POWER:
			return 300
		TankType.ARMORED:
			return 400
		TankType.PLAYER:
			return 0
	return 0

## Activate invulnerability shield
func activate_invulnerability(duration: float = 0.0) -> void:
	if duration > 0:
		invulnerability_duration = duration
	
	invulnerability_timer = invulnerability_duration
	_change_state(State.INVULNERABLE)
	
	# Visual feedback (shield effect)
	_set_tank_color(Color(1, 1, 1, 0.7))

## Upgrade player tank level (0-3)
func upgrade_level() -> void:
	if not is_player:
		return
	
	level = mini(level + 1, 3)
	_apply_level_bonuses()

func _apply_level_bonuses() -> void:
	match level:
		1:
			fire_cooldown_time = 0.4
		2:
			fire_cooldown_time = 0.3
			max_health = 2
		3:
			fire_cooldown_time = 0.25
			max_health = 2

func _complete_spawn() -> void:
	_change_state(State.IDLE)
	activate_invulnerability(invulnerability_duration)

func _end_invulnerability() -> void:
	if current_state == State.INVULNERABLE:
		_change_state(State.IDLE)
	_set_tank_color(base_color)

## Power-up method: Make tank invulnerable for duration
func make_invulnerable(duration: float) -> void:
	is_invulnerable = true
	invulnerability_time = duration
	_set_tank_color(Color.CYAN)

## Power-up method: Freeze tank for duration
func freeze(duration: float) -> void:
	is_frozen = true
	freeze_time = duration
	velocity = Vector3.ZERO
	_set_tank_color(Color.LIGHT_BLUE)

func _change_state(new_state: State) -> void:
	if current_state == new_state:
		return
	
	current_state = new_state
	state_changed.emit(new_state)
	
	# Handle state entry
	match new_state:
		State.SPAWNING:
			spawn_timer = SPAWN_DURATION
			_set_tank_color(Color(1, 1, 1, 0.5))
		State.IDLE:
			velocity = Vector3.ZERO
		State.DYING:
			set_physics_process(false)

func _emit_tank_moved_event() -> void:
	if not EventBus:
		return
	var event = TankMovedEvent.new()
	event.tank_id = tank_id
	event.position = global_position  # Vector3
	event.direction = _direction_to_vector(facing_direction)  # Vector3
	event.velocity = velocity  # Vector3
	EventBus.emit_game_event(event)

func _emit_bullet_fired_event() -> void:
	if not EventBus:
		return
	var event = BulletFiredEvent.new()
	event.tank_id = tank_id
	event.bullet_id = 0  # Will be set by BulletManager
	event.position = get_bullet_spawn_position()  # Vector3
	event.direction = _direction_to_vector(facing_direction)  # Vector3
	event.bullet_level = level
	event.is_player_bullet = is_player
	EventBus.emit_game_event(event)

## Calculate bullet spawn position
func get_bullet_spawn_position() -> Vector3:
	var dir = _direction_to_vector(facing_direction)
	return position + dir * BULLET_SPAWN_OFFSET

## Check if bullet can be fired (not too close to edge)
func can_fire_bullet() -> bool:
	return position.x >= EDGE_FIRE_MARGIN and \
		   position.x <= MAP_WIDTH - EDGE_FIRE_MARGIN and \
		   position.z >= EDGE_FIRE_MARGIN and \
		   position.z <= MAP_HEIGHT - EDGE_FIRE_MARGIN

## Tile Geometry Methods

## Get the 4 tiles occupied by this tank (2x2 footprint)
func get_occupied_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	
	# Tank is 1x1 units, positioned by center
	# Top-left corner of tank in world space
	var top_left = global_position - Vector3(TANK_SIZE / 2, 0, TANK_SIZE / 2)
	
	# Calculate which tiles are covered (each tile is 0.5x0.5)
	var tile_x_start = int(floor(top_left.x / TILE_SIZE))
	var tile_z_start = int(floor(top_left.z / TILE_SIZE))
	
	# Tank covers 2x2 tiles
	for dz in range(2):
		for dx in range(2):
			tiles.append(Vector2i(tile_x_start + dx, tile_z_start + dz))
	
	return tiles

## Check if tank would collide with terrain at given position
func _would_collide_with_terrain(target_pos: Vector3) -> bool:
	# Get terrain manager from scene
	var terrain = _get_terrain_manager()
	if not terrain:
		# No terrain found - allow movement (tests may not have terrain)
		return false
	
	# Calculate 2x2 tile footprint at target position
	var top_left = target_pos - Vector3(TANK_SIZE / 2, 0, TANK_SIZE / 2)
	var tile_x_start = int(floor(top_left.x / TILE_SIZE))
	var tile_z_start = int(floor(top_left.z / TILE_SIZE))
	
	# Check all 4 tiles in 2x2 footprint
	for dz in range(2):
		for dx in range(2):
			var tile_coord = Vector2i(tile_x_start + dx, tile_z_start + dz)
			var tile_type = terrain.get_tile_at_coords(tile_coord.x, tile_coord.y)
			
			# Check if tile is solid (blocks movement)
			if tile_type in [TerrainManager.TileType.BRICK, 
							TerrainManager.TileType.STEEL, 
							TerrainManager.TileType.WATER]:
				return true
	
	return false

## Check if tank would collide with another tank at given position
func _would_collide_with_tank(target_pos: Vector3) -> bool:
	# Calculate 2x2 tile footprint at target position
	var top_left = target_pos - Vector3(TANK_SIZE / 2, 0, TANK_SIZE / 2)
	var tile_x_start = int(floor(top_left.x / TILE_SIZE))
	var tile_z_start = int(floor(top_left.z / TILE_SIZE))
	
	# Get target tiles
	var target_tiles: Array[Vector2i] = []
	for dz in range(2):
		for dx in range(2):
			target_tiles.append(Vector2i(tile_x_start + dx, tile_z_start + dz))
	
	# Find all other tanks in the scene
	var all_tanks = get_tree().get_nodes_in_group("tanks")
	
	for tank in all_tanks:
		if tank == self:
			continue  # Skip self
		
		# Get tiles occupied by this tank
		var tank_tiles = tank.get_occupied_tiles()
		
		# Check for overlap
		for target_tile in target_tiles:
			if target_tile in tank_tiles:
				return true  # Collision detected
	
	return false

## Get terrain manager from scene tree
func _get_terrain_manager() -> TerrainManager:
	# Cache the terrain reference for performance
	if not has_meta("cached_terrain"):
		if not get_tree():
			return null
		
		# Search from tank's parent upward to find terrain in same scene
		var current = get_parent()
		while current:
			# Check siblings of current node
			for sibling in current.get_children():
				if sibling is TerrainManager:
					set_meta("cached_terrain", sibling)
					return sibling
			# Move up the tree
			current = current.get_parent()
		
		# Cache null to avoid repeated searches
		set_meta("cached_terrain", null)
		return null
	else:
		return get_meta("cached_terrain")

## Helper function to set tank color in 3D (via mesh material or transparency)
func _set_tank_color(color: Color) -> void:
	"""Set tank color by modifying mesh material albedo (3D equivalent of modulate)"""
	if mesh_instance:
		# Try to set material color if mesh has materials
		var surface_count = mesh_instance.get_surface_override_material_count()
		if surface_count > 0:
			var mat = mesh_instance.get_surface_override_material(0)
			if mat and mat is StandardMaterial3D:
				mat.albedo_color = color
				return
	
	# Fallback: Store color for when mesh is added
	base_color = color
