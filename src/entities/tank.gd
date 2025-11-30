class_name Tank
extends CharacterBody2D
## Base tank entity with movement, shooting, and health

signal health_changed(new_health: int, max_health: int)
signal died()
signal state_changed(new_state: State)

enum State { IDLE, MOVING, SHOOTING, DYING, INVULNERABLE, SPAWNING }
enum Direction { UP, DOWN, LEFT, RIGHT }
enum TankType { PLAYER, BASIC, FAST, POWER, ARMORED }

# Configuration
@export var tank_type: TankType = TankType.PLAYER
@export var base_speed: float = 100.0
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
var base_color: Color = Color.WHITE  # Original tank color before effects

# Internal
var fire_cooldown: float = 0.0
var invulnerability_timer: float = 0.0
var spawn_timer: float = 0.0
const SPAWN_DURATION: float = 2.0
const TILE_SIZE: int = 16
const MAP_WIDTH: int = 416  # 26 tiles * 16px
const MAP_HEIGHT: int = 416  # 26 tiles * 16px
const TANK_SIZE: int = 32  # Tank is 32x32 pixels (2x2 tiles)
const SUB_GRID_SIZE: int = 8  # Movement precision (half-tile)
const BULLET_SPAWN_OFFSET: int = 20  # Distance from center
const EDGE_FIRE_MARGIN: int = 16  # Min distance from edge to fire

# Grid movement state
var target_position: Vector2 = Vector2.ZERO  # Target grid cell
var is_moving_to_target: bool = false
var movement_progress: float = 0.0

# Visual
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null

func _ready() -> void:
	current_health = max_health
	is_player = (tank_type == TankType.PLAYER)
	_setup_collision()
	_setup_collision_layers()
	# Snap spawn position to grid and clamp to safe bounds
	global_position = _snap_to_grid_position(global_position)
	global_position.x = clampf(global_position.x, TILE_SIZE, MAP_WIDTH - TILE_SIZE)
	global_position.y = clampf(global_position.y, TILE_SIZE, MAP_HEIGHT - TILE_SIZE)
	target_position = global_position
	# Skip spawn animation for testing - go straight to idle
	_change_state(State.IDLE)
	
	# Set visual color based on tank type (if not already colored)
	if modulate == Color.WHITE:
		match tank_type:
			TankType.PLAYER:
				modulate = Color(0.3, 0.7, 1.0)  # Blue - player tank
			_:
				modulate = Color.WHITE  # Enemies get colored by spawner
	
	# Store base color for restoration after effects
	base_color = modulate
	
	# Create pixel art visual
	_create_tank_sprite()

func _create_tank_sprite() -> void:
	"""Create pixel art tank sprite based on type"""
	# Remove existing sprite if any
	for child in get_children():
		if child is Node2D and child.name == "TankSprite":
			child.queue_free()
	
	var sprite_container = Node2D.new()
	sprite_container.name = "TankSprite"
	add_child(sprite_container)
	
	# Tank body (24x24 center)
	var body = ColorRect.new()
	body.size = Vector2(24, 24)
	body.position = Vector2(-12, -12)
	body.color = base_color
	sprite_container.add_child(body)
	
	# Tracks (left and right)
	var track_left = ColorRect.new()
	track_left.size = Vector2(4, 28)
	track_left.position = Vector2(-16, -14)
	track_left.color = base_color.darkened(0.3)
	sprite_container.add_child(track_left)
	
	var track_right = ColorRect.new()
	track_right.size = Vector2(4, 28)
	track_right.position = Vector2(12, -14)
	track_right.color = base_color.darkened(0.3)
	sprite_container.add_child(track_right)
	
	# Turret/Cannon based on facing direction
	var cannon = ColorRect.new()
	cannon.color = base_color.darkened(0.2)
	
	match facing_direction:
		Direction.UP:
			cannon.size = Vector2(4, 12)
			cannon.position = Vector2(-2, -20)
		Direction.DOWN:
			cannon.size = Vector2(4, 12)
			cannon.position = Vector2(-2, 8)
		Direction.LEFT:
			cannon.size = Vector2(12, 4)
			cannon.position = Vector2(-20, -2)
		Direction.RIGHT:
			cannon.size = Vector2(12, 4)
			cannon.position = Vector2(8, -2)
	
	sprite_container.add_child(cannon)
	
	# Tank type indicator (small colored square on top)
	var indicator = ColorRect.new()
	indicator.size = Vector2(6, 6)
	indicator.position = Vector2(-3, -6)
	
	match tank_type:
		TankType.PLAYER:
			indicator.color = Color.CYAN  # Blue indicator
		TankType.BASIC:
			indicator.color = Color(0.6, 0.4, 0.2)  # Brown
		TankType.FAST:
			indicator.color = Color.GREEN  # Green
		TankType.POWER:
			indicator.color = Color.YELLOW  # Yellow
		TankType.ARMORED:
			indicator.color = Color.RED  # Red
	
	sprite_container.add_child(indicator)
	
	# Add health bars for tanks with >1 HP
	if max_health > 1:
		for i in range(max_health):
			var hp_dot = ColorRect.new()
			hp_dot.name = "HP_" + str(i)
			hp_dot.size = Vector2(2, 2)
			hp_dot.position = Vector2(-8 + (i * 4), 10)
			hp_dot.color = Color.GREEN if i < current_health else Color(0.3, 0.3, 0.3)
			sprite_container.add_child(hp_dot)

func _update_health_display() -> void:
	"""Update health indicator dots when taking damage"""
	var sprite_container = get_node_or_null("TankSprite")
	if not sprite_container:
		return
	
	for i in range(max_health):
		var hp_dot = sprite_container.get_node_or_null("HP_" + str(i))
		if hp_dot and hp_dot is ColorRect:
			hp_dot.color = Color.GREEN if i < current_health else Color(0.3, 0.3, 0.3)

func _setup_collision_layers() -> void:
	# Tanks are on layer 1 and collide with terrain (layer 2) and other tanks (layer 1)
	collision_layer = 1
	collision_mask = 3  # Collide with layers 1 (tanks) and 2 (terrain)

func _setup_collision() -> void:
	# Tank collision is 16x16 (1 tile)
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(TILE_SIZE, TILE_SIZE)
		collision_shape.shape = rect
		add_child(collision_shape)

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
			modulate = base_color  # Restore original color
	
	if freeze_time > 0:
		freeze_time -= delta
		if freeze_time <= 0:
			is_frozen = false
			modulate = base_color  # Restore original color
	
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
	# Grid-based discrete movement: move from grid cell to grid cell
	if not is_moving_to_target:
		return
	
	var old_pos = global_position
	
	# Calculate step size based on speed and delta
	var step_distance = _get_current_speed() * delta
	var remaining_distance = global_position.distance_to(target_position)
	
	if remaining_distance <= step_distance:
		# Reached target - snap to exact grid position
		global_position = target_position
		movement_progress = 0.0
		
		# Emit movement event
		if old_pos != global_position:
			_emit_tank_moved_event()
		
		# For continuous movement, set next grid target in same direction
		var direction_vec = _direction_to_vector(facing_direction)
		var next_target = global_position + (direction_vec * SUB_GRID_SIZE)
		
		# Clamp to map boundaries (keep tank center 16px from edges so 2x2 footprint stays in grid)
		next_target.x = clampf(next_target.x, TILE_SIZE, MAP_WIDTH - TILE_SIZE)
		next_target.y = clampf(next_target.y, TILE_SIZE, MAP_HEIGHT - TILE_SIZE)
		next_target = _snap_to_grid_position(next_target)
		
		# Check if we can move to next target (grid-based terrain collision)
		var test_movement = next_target - global_position
		if test_movement.length() > 0:
			# Check terrain collision at target position using 2x2 footprint
			if _would_collide_with_terrain(next_target):
				# Blocked by terrain - stop here
				is_moving_to_target = false
				velocity = Vector2.ZERO
			else:
				# Continue to next grid cell
				target_position = next_target
				is_moving_to_target = true
		else:
			# At boundary, stop
			is_moving_to_target = false
			velocity = Vector2.ZERO
	else:
		# Move toward target (grid-based, no physics collision)
		var direction = (target_position - global_position).normalized()
		var movement = direction * step_distance
		
		# Move directly - collision already checked when setting target
		global_position += movement
		movement_progress += step_distance
		
		# Emit movement event
		if old_pos.distance_to(global_position) > 0.1:
			_emit_tank_moved_event()

## Set movement direction and velocity
func move_in_direction(direction: Direction) -> void:
	if current_state == State.DYING or current_state == State.SPAWNING:
		return
	
	# If changing direction, complete current movement first
	if is_moving_to_target and direction != facing_direction:
		# Snap to current grid position when changing direction
		global_position = _snap_to_grid_position(global_position)
		is_moving_to_target = false
	
	facing_direction = direction
	_update_sprite_rotation()
	
	# Only set new target if not already moving in this direction
	# This allows continuous grid-to-grid movement
	if not is_moving_to_target:
		# Calculate next grid cell in the movement direction
		var direction_vec = _direction_to_vector(direction)
		var proposed_target = global_position + (direction_vec * SUB_GRID_SIZE)
		
		# Clamp target to map boundaries (keep tank center 16px from edges)
		proposed_target.x = clampf(proposed_target.x, TILE_SIZE, MAP_WIDTH - TILE_SIZE)
		proposed_target.y = clampf(proposed_target.y, TILE_SIZE, MAP_HEIGHT - TILE_SIZE)
		proposed_target = _snap_to_grid_position(proposed_target)
		
		# Check terrain collision before setting target
		var would_collide = _would_collide_with_terrain(proposed_target)
		if would_collide:
			# Blocked by terrain - don't move
			is_moving_to_target = false
			velocity = Vector2.ZERO
			return
		
		# All clear - start moving to target
		target_position = proposed_target
		is_moving_to_target = true
		velocity = direction_vec * _get_current_speed()  # For visual/physics info
	
	if current_state != State.MOVING:
		_change_state(State.MOVING)

## Stop tank movement
func stop_movement() -> void:
	# Complete movement to current grid cell
	if is_moving_to_target:
		global_position = _snap_to_grid_position(global_position)
		target_position = global_position
		is_moving_to_target = false
	
	velocity = Vector2.ZERO
	if current_state == State.MOVING:
		_change_state(State.IDLE)

func _snap_to_grid_position(pos: Vector2) -> Vector2:
	"""Snap position to nearest 8-pixel grid cell"""
	return Vector2(
		round(pos.x / SUB_GRID_SIZE) * SUB_GRID_SIZE,
		round(pos.y / SUB_GRID_SIZE) * SUB_GRID_SIZE
	)

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
	_update_health_display()
	
	if current_health <= 0:
		die()

## Handle tank death
func die() -> void:
	_change_state(State.DYING)
	velocity = Vector2.ZERO
	
	# Emit death event
	var event = TankDestroyedEvent.new()
	event.tank_id = tank_id
	event.tank_type = _get_tank_type_string()
	event.was_player = is_player
	event.position = global_position
	event.destroyed_by_id = -1  # Will be set by damage dealer
	event.score_value = _get_score_value()
	EventBus.emit_game_event(event)
	
	died.emit()
	
	# Play death animation then queue_free
	if animation_player and animation_player.has_animation("die"):
		animation_player.play("die")
		await animation_player.animation_finished
	
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

## Activate invulnerability shield
func activate_invulnerability(duration: float = 0.0) -> void:
	if duration > 0:
		invulnerability_duration = duration
	
	invulnerability_timer = invulnerability_duration
	_change_state(State.INVULNERABLE)
	
	# Visual feedback (shield effect)
	modulate = Color(1, 1, 1, 0.7)

## Upgrade player tank level (0-3)
func upgrade_level() -> void:
	if not is_player:
		return
	
	level = mini(level + 1, 3)
	_apply_level_bonuses()

func _apply_level_bonuses() -> void:
	match level:
		1:
			fire_cooldown_time = 0.4  # Faster shooting
		2:
			fire_cooldown_time = 0.3
			max_health = 2  # Can take 1 hit
		3:
			fire_cooldown_time = 0.25
			max_health = 2

func _complete_spawn() -> void:
	_change_state(State.IDLE)
	activate_invulnerability(invulnerability_duration)

func _end_invulnerability() -> void:
	if current_state == State.INVULNERABLE:
		_change_state(State.IDLE)
	modulate = base_color  # Restore original color

## Power-up method: Make tank invulnerable for duration
func make_invulnerable(duration: float) -> void:
	is_invulnerable = true
	invulnerability_time = duration
	modulate = Color.CYAN  # Visual feedback

## Power-up method: Freeze tank for duration
func freeze(duration: float) -> void:
	is_frozen = true
	freeze_time = duration
	velocity = Vector2.ZERO
	is_moving_to_target = false
	modulate = Color.LIGHT_BLUE  # Visual feedback

func _change_state(new_state: State) -> void:
	if current_state == new_state:
		return
	
	current_state = new_state
	state_changed.emit(new_state)
	
	# Handle state entry
	match new_state:
		State.SPAWNING:
			spawn_timer = SPAWN_DURATION
			modulate = Color(1, 1, 1, 0.5)
		State.IDLE:
			velocity = Vector2.ZERO
		State.DYING:
			set_physics_process(false)

func _direction_to_vector(direction: Direction) -> Vector2:
	match direction:
		Direction.UP:
			return Vector2.UP
		Direction.DOWN:
			return Vector2.DOWN
		Direction.LEFT:
			return Vector2.LEFT
		Direction.RIGHT:
			return Vector2.RIGHT
	return Vector2.ZERO

func _get_current_speed() -> float:
	var speed = base_speed
	
	# Tank type modifiers
	match tank_type:
		TankType.FAST:
			speed *= 1.5
		TankType.POWER:
			speed *= 0.8
	
	return speed

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

func _update_sprite_rotation() -> void:
	# Update pixel art cannon direction
	var sprite_container = get_node_or_null("TankSprite")
	if not sprite_container:
		return
	
	# Find and update cannon
	for child in sprite_container.get_children():
		if child is ColorRect and child.get_index() == 3:  # Cannon is 4th child (index 3)
			match facing_direction:
				Direction.UP:
					child.size = Vector2(4, 12)
					child.position = Vector2(-2, -20)
				Direction.DOWN:
					child.size = Vector2(4, 12)
					child.position = Vector2(-2, 8)
				Direction.LEFT:
					child.size = Vector2(12, 4)
					child.position = Vector2(-20, -2)
				Direction.RIGHT:
					child.size = Vector2(12, 4)
					child.position = Vector2(8, -2)
			break
	
	# Legacy sprite support
	if sprite:
		match facing_direction:
			Direction.UP:
				sprite.rotation_degrees = 0
			Direction.RIGHT:
				sprite.rotation_degrees = 90
			Direction.DOWN:
				sprite.rotation_degrees = 180
			Direction.LEFT:
				sprite.rotation_degrees = 270

func _emit_tank_moved_event() -> void:
	var event = TankMovedEvent.new()
	event.tank_id = tank_id
	event.position = global_position
	event.direction = _direction_to_vector(facing_direction)
	event.velocity = velocity
	EventBus.emit_game_event(event)

func _emit_bullet_fired_event() -> void:
	var event = BulletFiredEvent.new()
	event.tank_id = tank_id
	event.bullet_id = 0  # Will be set by BulletManager
	event.position = global_position
	event.direction = _direction_to_vector(facing_direction)
	event.bullet_level = level
	event.is_player_bullet = is_player  # Set owner type based on tank type
	EventBus.emit_game_event(event)

## Tile Geometry Methods

## Snap position to 8-pixel sub-grid
func snap_to_sub_grid(pos: Vector2) -> Vector2:
	return Vector2(
		round(pos.x / SUB_GRID_SIZE) * SUB_GRID_SIZE,
		round(pos.y / SUB_GRID_SIZE) * SUB_GRID_SIZE
	)

## Get the 4 tiles occupied by this tank (2x2 footprint)
func get_occupied_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	
	# Tank is 32x32, positioned by center
	# Top-left corner of tank in world space
	var top_left = global_position - Vector2(TANK_SIZE / 2, TANK_SIZE / 2)
	
	# Calculate which tiles are covered (each tile is 16x16)
	var tile_x_start = int(floor(top_left.x / TILE_SIZE))
	var tile_y_start = int(floor(top_left.y / TILE_SIZE))
	
	# Tank covers 2x2 tiles
	for dy in range(2):
		for dx in range(2):
			tiles.append(Vector2i(tile_x_start + dx, tile_y_start + dy))
	
	return tiles

## Check if tank would collide with terrain at given position
func _would_collide_with_terrain(target_pos: Vector2) -> bool:
	# Get terrain manager from scene
	var terrain = _get_terrain_manager()
	if not terrain:
		# No terrain found - allow movement (tests may not have terrain)
		return false
	
	# Calculate 2x2 tile footprint at target position
	var top_left = target_pos - Vector2(TANK_SIZE / 2, TANK_SIZE / 2)
	var tile_x_start = int(floor(top_left.x / TILE_SIZE))
	var tile_y_start = int(floor(top_left.y / TILE_SIZE))
	
	# Check all 4 tiles in 2x2 footprint
	for dy in range(2):
		for dx in range(2):
			var tile_coord = Vector2i(tile_x_start + dx, tile_y_start + dy)
			var tile_type = terrain.get_tile_at_coords(tile_coord.x, tile_coord.y)
			
			# Check if tile is solid (blocks movement)
			if tile_type in [TerrainManager.TileType.BRICK, 
							TerrainManager.TileType.STEEL, 
							TerrainManager.TileType.WATER]:
				return true
	
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

func _find_terrain_recursive(node: Node) -> TerrainManager:
	if node is TerrainManager:
		return node
	for child in node.get_children():
		var terrain = _find_terrain_recursive(child)
		if terrain:
			return terrain
	return null

## Get world-space bounding box of tank
func get_world_bounds() -> Rect2:
	var half_size = TANK_SIZE / 2
	return Rect2(
		position - Vector2(half_size, half_size),
		Vector2(TANK_SIZE, TANK_SIZE)
	)

## Calculate bullet spawn position (20 pixels from center in facing direction)
func get_bullet_spawn_position() -> Vector2:
	var dir = _direction_to_vector(facing_direction)
	return position + dir * BULLET_SPAWN_OFFSET

## Check if bullet can be fired (not too close to edge)
func can_fire_bullet() -> bool:
	# Bullet cannot spawn if tank is within 16 pixels of playfield edge
	return position.x >= EDGE_FIRE_MARGIN and \
		   position.x <= MAP_WIDTH - EDGE_FIRE_MARGIN and \
		   position.y >= EDGE_FIRE_MARGIN and \
		   position.y <= MAP_HEIGHT - EDGE_FIRE_MARGIN
