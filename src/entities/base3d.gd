class_name Base3D
extends StaticBody3D
## 3D Eagle base entity - game ends if destroyed

signal destroyed()
signal damaged(health: int)

@export var max_health: int = 1
var health: int = 1
var is_destroyed: bool = false

# Constants
const TILE_SIZE: float = 0.5  # 3D tile size in units
const Vector3Helpers = preload("res://src/utils/vector3_helpers.gd")

func _init() -> void:
	# Create collision shape immediately in _init so it's available for tests
	var collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	var box = BoxShape3D.new()
	box.size = Vector3(1.0, 1.0, 1.0)  # 1x1x1 unit base
	collision_shape.shape = box
	add_child(collision_shape)

func _ready() -> void:
	health = max_health
	
	# Position at bottom center of map (tile 13, 25)
	# 2D: (13*16+8, 25*16+8) = (208, 408) pixels
	# 3D: (13*0.5+0.25, 0, 25*0.5+0.25) = (6.75, 0, 12.75) units
	# Adjusted for centering: (6.5, 0, 12.5)
	var tile_center_x = 13 * TILE_SIZE
	var tile_center_z = 25 * TILE_SIZE
	global_position = Vector3(tile_center_x, 0.0, tile_center_z)
	global_position = Vector3Helpers.quantize_vec3(global_position, 0.001)
	
	# Set up collision detection
	# Layer 5 (Base) = bit 4 = value 16 (2^4)
	collision_layer = 16
	# Mask: Enemy(2) | Projectiles(3) = bits 1,2 = 2+4 = 6
	collision_mask = 6
	
	# Add Area3D for detecting bullet collisions (StaticBody3D doesn't have body_entered)
	var area = Area3D.new()
	area.name = "DetectionArea"
	area.collision_layer = 16  # Same as base
	area.collision_mask = 6     # Detect Enemy | Projectiles
	add_child(area)
	
	# Add collision shape to area
	var area_collision = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(1.0, 1.0, 1.0)
	area_collision.shape = box
	area.add_child(area_collision)
	
	# Connect area signals
	area.body_entered.connect(_on_body_entered)
	area.area_entered.connect(_on_area_entered)
	
	# Add visual representation (placeholder)
	_create_visual()

func _on_area_entered(area: Area3D) -> void:
	"""Handle Area3D collisions (bullets are Area3D)"""
	_handle_bullet_collision(area)

func take_damage(amount: int = 1) -> void:
	"""Apply damage to base"""
	if is_destroyed:
		return
	
	health -= amount
	damaged.emit(health)
	
	if health <= 0:
		health = 0
		_destroy()

func _destroy() -> void:
	"""Handle base destruction"""
	if is_destroyed:
		return
	
	is_destroyed = true
	
	# Emit signal first
	destroyed.emit()
	
	# Then emit event (convert Vector3 to Vector2 for legacy events)
	if EventBus:
		var event = BaseDestroyedEvent.new()
		event.position = Vector2(global_position.x, global_position.z)  # X,Z -> X,Y in 2D
		event.destroyed_by_id = -1
		EventBus.emit_game_event(event)
	
	# Visual feedback - change mesh material color
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance and mesh_instance.get_surface_override_material_count() > 0:
		var material = mesh_instance.get_surface_override_material(0)
		if material:
			material.albedo_color = Color.RED

func _on_body_entered(body: Node3D) -> void:
	"""Handle collision with bullets and tanks"""
	# Check if it's a bullet
	if body.has_method("get_class") and body.get_class() == "Bullet3D":
		_handle_bullet_collision(body)
	elif body is Area3D and "owner_type" in body:  # Bullet3D
		_handle_bullet_collision(body)
	# Check if it's a tank
	elif body.has_method("take_damage") and "tank_type" in body:
		_handle_tank_collision(body)

func _handle_bullet_collision(bullet: Node) -> void:
	"""Handle bullet collision"""
	# Get bullet owner type
	var owner_type = bullet.get("owner_type")
	
	# Only enemy bullets damage base
	if owner_type != null:
		# Check if it's an enemy bullet (assuming OwnerType.ENEMY = 1)
		var is_enemy_bullet = (owner_type == 1) if typeof(owner_type) == TYPE_INT else false
		
		if is_enemy_bullet:
			take_damage(1)
	
	# All bullets are destroyed on base contact
	if bullet.has_method("_destroy"):
		bullet._destroy()

func _handle_tank_collision(tank: Node3D) -> void:
	"""Handle tank collision"""
	# Get tank properties
	var is_player_tank = tank.get("is_player") if "is_player" in tank else false
	
	# Only enemy tanks damage base
	if not is_player_tank:
		take_damage(1)

func _create_visual() -> void:
	"""Create visual representation of base (placeholder)"""
	# This will be replaced with actual 3D mesh
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1.0, 0.5, 1.0)
	mesh_instance.mesh = box_mesh
	
	# Create simple material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.YELLOW
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.set_surface_override_material(0, material)
	
	add_child(mesh_instance)
