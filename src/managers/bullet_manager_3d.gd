extends Node3D
class_name BulletManager3D
## Manages bullet pooling and spawning for 3D gameplay

const MAX_BULLETS_PER_TANK: int = 2
const BULLET_POOL_SIZE: int = 20

# Bullet tracking
var active_bullets: Dictionary = {}  # tank_id -> Array[Bullet3D]
var bullet_pool: Array[Area3D] = []
var next_bullet_id: int = 0

# Preloaded scenes
var bullet_scene: PackedScene

func _ready() -> void:
	# Try to load 3D bullet scene
	if ResourceLoader.exists("res://scenes3d/bullet3d.tscn"):
		bullet_scene = load("res://scenes3d/bullet3d.tscn")
		_initialize_pool()
	else:
		print("Warning: bullet3d.tscn not found, bullets disabled")
	
	# Subscribe to bullet fired events
	if EventBus:
		EventBus.subscribe("BulletFired", Callable(self, "_on_bullet_fired"))

func _exit_tree() -> void:
	# Unsubscribe from EventBus to prevent dangling references
	if EventBus and EventBus.has_method("unsubscribe"):
		EventBus.unsubscribe("BulletFired", Callable(self, "_on_bullet_fired"))

func _initialize_pool() -> void:
	if not bullet_scene:
		return
	
	for i in range(BULLET_POOL_SIZE):
		var bullet = _create_bullet()
		bullet.process_mode = Node.PROCESS_MODE_DISABLED
		bullet.visible = false
		bullet_pool.append(bullet)

func _create_bullet() -> Area3D:
	var bullet: Area3D
	if bullet_scene:
		bullet = bullet_scene.instantiate() as Area3D
	else:
		# Fallback: create simple bullet
		bullet = Area3D.new()
		var collision = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(0.2, 0.2, 0.2)
		collision.shape = shape
		bullet.add_child(collision)
	
	add_child(bullet)
	
	# Connect destroyed signal if it exists
	if bullet.has_signal("destroyed"):
		bullet.destroyed.connect(_on_bullet_destroyed.bind(bullet))
	
	return bullet

func _on_bullet_fired(event: GameEvent) -> void:
	# Convert to BulletFiredEvent
	if not event is BulletFiredEvent:
		return
	
	var bullet_event = event as BulletFiredEvent
	var tank_id = bullet_event.tank_id
	
	# Check bullet limit for this tank
	if not active_bullets.has(tank_id):
		active_bullets[tank_id] = []
	
	if active_bullets[tank_id].size() >= MAX_BULLETS_PER_TANK:
		return  # Tank has reached bullet limit
	
	# Get bullet from pool
	var bullet = _get_bullet_from_pool()
	if not bullet:
		return  # Pool exhausted
	
	# Initialize bullet
	var spawn_position = bullet_event.position
	var direction = bullet_event.direction
	var level = bullet_event.bullet_level
	var is_player = bullet_event.is_player_bullet
	
	# Set bullet properties
	bullet.global_position = spawn_position
	bullet.process_mode = Node.PROCESS_MODE_INHERIT
	bullet.visible = true
	
	# Initialize bullet if it has the method
	if bullet.has_method("initialize"):
		bullet.initialize(spawn_position, direction, tank_id, level, is_player)
	
	# Re-enable collision detection
	bullet.monitoring = true
	bullet.monitorable = true
	
	# Track active bullet
	active_bullets[tank_id].append(bullet)
	
	print("Bullet fired from tank ", tank_id, " at ", spawn_position, " dir: ", direction)

func _get_bullet_from_pool() -> Area3D:
	if bullet_pool.is_empty():
		# Pool exhausted, create new bullet
		if bullet_scene:
			return _create_bullet()
		return null
	
	# Get bullet from pool
	var bullet = bullet_pool.pop_back()
	return bullet

func _on_bullet_destroyed(bullet: Area3D) -> void:
	if not is_instance_valid(bullet):
		return
	
	# Remove from active tracking
	for tank_id in active_bullets.keys():
		if active_bullets[tank_id].has(bullet):
			active_bullets[tank_id].erase(bullet)
			break
	
	# Immediately disable the bullet
	bullet.process_mode = Node.PROCESS_MODE_DISABLED
	bullet.visible = false
	bullet.monitoring = false
	bullet.monitorable = false
	
	# Return to pool
	bullet_pool.append(bullet)
