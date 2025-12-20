class_name Bullet3D
extends Area3D
## 3D Bullet projectile with collision detection

signal hit_target(target: Node3D)
signal hit_terrain(position: Vector3)
signal destroyed()

enum BulletLevel { NORMAL = 1, ENHANCED = 2, SUPER = 3 }
enum OwnerType { PLAYER, ENEMY }

# Configuration
@export var speed: float = 6.25  # ~200px/s scaled (200/32)
@export var level: BulletLevel = BulletLevel.NORMAL
@export var can_destroy_steel: bool = false
@export var penetration: int = 1  # How many targets before destruction

# State
var direction: Vector3 = Vector3(0, 0, -1)  # Forward by default
var owner_tank_id: int = -1
var owner_type: OwnerType = OwnerType.ENEMY
var bullet_id: int = 0
var bullet_level: int = 1  # 1-3, matches tank level for steel destruction
var targets_hit: int = 0
var is_active: bool = true
var grace_timer: float = 0.0  # Prevent hitting owner immediately
const GRACE_PERIOD: float = 0.1  # 100ms grace period

# Visual
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D if has_node("MeshInstance3D") else null
@onready var collision_shape: CollisionShape3D = $CollisionShape3D if has_node("CollisionShape3D") else null

const TILE_SIZE: float = 0.5  # 3D tile size in units
const Vector3Helpers = preload("res://src/utils/vector3_helpers.gd")

# Game bounds (26x26 tiles = 13x13 units)
static var game_bounds_min: Vector3 = Vector3(0, 0, 0)
static var game_bounds_max: Vector3 = Vector3(26.0, 5.0, 26.0)  # Using 26 units for full map

func _init() -> void:
	# Create collision shape immediately in _init so it's available for tests
	collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	var sphere = SphereShape3D.new()
	sphere.radius = 0.125  # ~4px scaled (4/32)
	collision_shape.shape = sphere
	add_child(collision_shape)

func _ready() -> void:
	_setup_collision()
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _setup_collision() -> void:
	# Update collision shape if it exists, otherwise create
	if not collision_shape:
		collision_shape = CollisionShape3D.new()
		var sphere = SphereShape3D.new()
		sphere.radius = 0.125  # ~4px scaled (4/32)
		collision_shape.shape = sphere
		add_child(collision_shape)
	
	# Set collision layers
	# Layer 3 (Projectiles) = bit 2 = value 4 (2^2)
	collision_layer = 4
	# Mask: Enemy(2) | Environment(4) | Base(5) = bits 1,2,4 = 2+4+32 = 38
	collision_mask = 38

func _physics_process(delta: float) -> void:
	if not is_active:
		return
	
	# Update grace timer
	if grace_timer > 0:
		grace_timer -= delta
	
	# Move bullet
	var movement = direction * speed * delta
	global_position += movement
	
	# Quantize position for determinism
	global_position = Vector3Helpers.quantize_vec3(global_position, 0.001)
	
	# Check if out of bounds
	if _is_out_of_bounds():
		_destroy()

func initialize(start_pos: Vector3, dir: Vector3, tank_id: int, bullet_lvl: int = 1, is_player: bool = false) -> void:
	global_position = Vector3Helpers.quantize_vec3(start_pos, 0.001)
	direction = dir.normalized()
	owner_tank_id = tank_id
	level = bullet_lvl as BulletLevel
	owner_type = OwnerType.PLAYER if is_player else OwnerType.ENEMY
	grace_timer = GRACE_PERIOD  # Reset grace period
	bullet_level = bullet_lvl
	
	# Apply level bonuses
	match level:
		BulletLevel.ENHANCED:
			speed = 7.8125  # ~250px/s scaled (250/32)
			penetration = 2
		BulletLevel.SUPER:
			speed = 9.375  # ~300px/s scaled (300/32)
			penetration = 3
			can_destroy_steel = true
		_:
			speed = 6.25  # Normal speed
			penetration = 1
	
	_update_rotation()

func _on_area_entered(area: Area3D) -> void:
	if not is_active:
		return
	
	# Hit another bullet
	if area.has_method("get_class") and area.get_class() == "Bullet3D":
		var other_bullet = area
		if other_bullet.owner_tank_id != owner_tank_id:
			_destroy()
			other_bullet._destroy()
	elif area is Bullet3D:
		var other_bullet = area as Bullet3D
		if other_bullet.owner_tank_id != owner_tank_id:
			_destroy()
			other_bullet._destroy()

func _on_body_entered(body: Node3D) -> void:
	if not is_active:
		return
	
	# Hit tank (CharacterBody3D with tank script)
	if body.has_method("take_damage"):
		var tank_id = body.get("tank_id") if "tank_id" in body else -1
		
		# Ignore owner tank during grace period
		if tank_id == owner_tank_id and grace_timer > 0:
			return
		
		# Check if should damage (opposing team)
		var is_player_tank = body.get("is_player") if "is_player" in body else false
		var should_damage = false
		
		if owner_type == OwnerType.PLAYER and not is_player_tank:
			should_damage = true
		elif owner_type == OwnerType.ENEMY and is_player_tank:
			should_damage = true
		
		if should_damage:
			hit_target.emit(body)
			body.take_damage(1)
			_register_hit()
	
	# Hit terrain or base (StaticBody3D)
	elif body is StaticBody3D:
		hit_terrain.emit(global_position)
		_handle_terrain_collision(body)

func _handle_terrain_collision(body: Node3D) -> void:
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
	
	# Disable collision and physics
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	process_mode = Node.PROCESS_MODE_DISABLED
	visible = false
	global_position = Vector3(-1000, -1000, -1000)  # Move off-map

func _is_out_of_bounds() -> bool:
	# Check against 3D game bounds (26x26 units, allowing some margin)
	return global_position.x < -1.0 or global_position.x > 27.0 or \
		   global_position.z < -1.0 or global_position.z > 27.0

func _update_rotation() -> void:
	# Rotate mesh to face direction (optional, depends on mesh design)
	if mesh_instance:
		# Calculate rotation from direction vector
		var angle = atan2(direction.x, -direction.z)
		mesh_instance.rotation.y = angle
