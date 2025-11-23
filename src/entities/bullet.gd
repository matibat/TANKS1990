class_name Bullet
extends Area2D
## Bullet projectile with collision detection

signal hit_target(target: Node2D)
signal hit_terrain(position: Vector2)
signal destroyed()

enum BulletLevel { NORMAL = 1, ENHANCED = 2, SUPER = 3 }

# Configuration
@export var speed: float = 200.0
@export var level: BulletLevel = BulletLevel.NORMAL
@export var can_destroy_steel: bool = false
@export var penetration: int = 1  # How many targets before destruction

# State
var direction: Vector2 = Vector2.UP
var owner_tank_id: int = -1
var bullet_id: int = 0
var targets_hit: int = 0
var is_active: bool = true

# Visual
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null

const TILE_SIZE: int = 16

# Game bounds (matches window size)
static var game_bounds_min: Vector2 = Vector2(0, 0)
static var game_bounds_max: Vector2 = Vector2(832, 832)

func _ready() -> void:
	_setup_collision()
	area_entered.connect(_on_area_entered)
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
	
	# Move bullet
	global_position += direction * speed * delta
	
	# Check if out of bounds
	if _is_out_of_bounds():
		_destroy()

func initialize(start_pos: Vector2, dir: Vector2, tank_id: int, bullet_level: BulletLevel = BulletLevel.NORMAL) -> void:
	global_position = start_pos
	direction = dir.normalized()
	owner_tank_id = tank_id
	level = bullet_level
	
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
