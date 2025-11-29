class_name Bullet
extends Area2D
## Bullet projectile with collision detection

signal hit_target(target: Node2D)
signal hit_terrain(position: Vector2)
signal destroyed()

enum BulletLevel { NORMAL = 1, ENHANCED = 2, SUPER = 3 }
enum OwnerType { PLAYER, ENEMY }

# Configuration
@export var speed: float = 200.0
@export var level: BulletLevel = BulletLevel.NORMAL
@export var can_destroy_steel: bool = false
@export var penetration: int = 1  # How many targets before destruction

# State
var direction: Vector2 = Vector2.UP
var owner_tank_id: int = -1
var owner_type: OwnerType = OwnerType.ENEMY
var bullet_id: int = 0
var bullet_level: int = 1  # 1-3, matches tank level for steel destruction
var targets_hit: int = 0
var is_active: bool = true
var grace_timer: float = 0.0  # Prevent hitting owner immediately
const GRACE_PERIOD: float = 0.1  # 100ms grace period

# Visual
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null

const TILE_SIZE: int = 16

# Game bounds (matches window size)
static var game_bounds_min: Vector2 = Vector2(0, 0)
static var game_bounds_max: Vector2 = Vector2(832, 832)

func _ready() -> void:
	_setup_collision()
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _setup_collision() -> void:
	# Bullet collision is 4x4 (smaller than tank)
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(4, 4)
		collision_shape.shape = rect
		add_child(collision_shape)
	
	# Set collision layers
	collision_layer = 4  # Bullet layer
	collision_mask = 3   # Collide with tanks (layer 1) and terrain (layer 2)

func _physics_process(delta: float) -> void:
	if not is_active:
		return
	
	# Update grace timer
	if grace_timer > 0:
		grace_timer -= delta
	
	# Move bullet
	global_position += direction * speed * delta
	
	# Check grid-based terrain collision at bullet center
	if _check_terrain_collision():
		_destroy()
		return
	
	# Check if out of bounds
	if _is_out_of_bounds():
		_destroy()

func initialize(start_pos: Vector2, dir: Vector2, tank_id: int, bullet_lvl: BulletLevel = BulletLevel.NORMAL, is_player: bool = false) -> void:
	global_position = start_pos
	direction = dir.normalized()
	owner_tank_id = tank_id
	level = bullet_lvl
	owner_type = OwnerType.PLAYER if is_player else OwnerType.ENEMY
	grace_timer = GRACE_PERIOD  # Reset grace period
	
	# Apply level bonuses
	match level:
		BulletLevel.ENHANCED:
			speed = 250.0
			penetration = 2
		BulletLevel.SUPER:
			speed = 300.0
			penetration = 3
			can_destroy_steel = true
	
	_update_sprite_rotation()

func _on_area_entered(area: Area2D) -> void:
	if not is_active:
		return
	
	# Hit another bullet
	if area is Bullet:
		var other_bullet = area as Bullet
		if other_bullet.owner_tank_id != owner_tank_id:
			_destroy()
			other_bullet._destroy()

func _on_body_entered(body: Node2D) -> void:
	if not is_active:
		return
	
	# Hit tank
	if body is Tank:
		var tank = body as Tank
		# Ignore owner tank during grace period
		if tank.tank_id == owner_tank_id and grace_timer > 0:
			return
		if tank.tank_id != owner_tank_id:
			hit_target.emit(tank)
			tank.take_damage(1)
			_register_hit()
	
	# Hit terrain (TileMap or StaticBody2D)
	elif body is TileMapLayer or body is StaticBody2D:
		hit_terrain.emit(global_position)
		_handle_terrain_collision(body)

func _handle_terrain_collision(body: Node2D) -> void:
	# Check if terrain is destructible
	if body.has_method("damage_tile"):
		body.damage_tile(global_position, can_destroy_steel)
	
	_destroy()

func _register_hit() -> void:
	targets_hit += 1
	
	# Check penetration limit
	if targets_hit >= penetration:
		_destroy()

func _destroy() -> void:
	if not is_active:
		return
	
	is_active = false
	destroyed.emit()
	# Don't queue_free - let BulletManager handle recycling

func _is_out_of_bounds() -> bool:
	# Check against game bounds
	# PlayArea in main scene: 800x800 pixels (offset 16 to 816)
	# Using 832 for full screen bounds to account for edges
	var bounds_min = Vector2(0, 0)
	var bounds_max = Vector2(832, 832)
	
	return global_position.x < bounds_min.x or global_position.x > bounds_max.x or \
		   global_position.y < bounds_min.y or global_position.y > bounds_max.y

func _update_sprite_rotation() -> void:
	if not sprite:
		return
	
	# Rotate sprite to match direction
	sprite.rotation = direction.angle()

## Tile Geometry Methods

## Check if this bullet collides with another bullet (4-pixel radius)
func check_bullet_collision(other: Bullet) -> bool:
	const COLLISION_RADIUS = 4.0  # 4-pixel radius per bullet
	const COMBINED_RADIUS = COLLISION_RADIUS * 2  # 8-pixel diameter
	
	var distance = position.distance_to(other.position)
	return distance < COMBINED_RADIUS

## Check grid-based terrain collision at bullet center position
func _check_terrain_collision() -> bool:
	var terrain = _get_terrain_manager()
	if not terrain:
		# Try to find it by group
		terrain = get_tree().get_first_node_in_group("terrain_manager") as TerrainManager
		if terrain:
			set_meta("cached_terrain", terrain)
	
	if not terrain:
		return false
	
	# Get tile coordinate at bullet center (grid-based, not sub-pixel)
	var tile_x = int(floor(global_position.x / TILE_SIZE))
	var tile_y = int(floor(global_position.y / TILE_SIZE))
	var tile_type = terrain.get_tile_at_coords(tile_x, tile_y)
	
	# Check if tile is solid
	if tile_type == TerrainManager.TileType.BRICK:
		# Destructible - damage it
		terrain.damage_tile(global_position, can_destroy_steel)
		return true
	elif tile_type == TerrainManager.TileType.STEEL:
		if can_destroy_steel:
			# Can destroy steel
			terrain.damage_tile(global_position, true)
			return true
		else:
			# Bounce off steel
			terrain.damage_tile(global_position, false)
			return true
	elif tile_type == TerrainManager.TileType.WATER:
		# Water blocks bullets
		return true
	
	return false

## Get terrain manager from scene tree
func _get_terrain_manager() -> TerrainManager:
	if not has_meta("cached_terrain"):
		var root = get_tree().root if get_tree() else null
		if root:
			for child in root.get_children():
				var terrain = _find_terrain_recursive(child)
				if terrain:
					set_meta("cached_terrain", terrain)
					return terrain
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
