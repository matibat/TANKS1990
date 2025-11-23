class_name BulletManager
extends Node2D
## Manages bullet pooling and spawning

const MAX_BULLETS_PER_TANK: int = 2
const BULLET_POOL_SIZE: int = 20

# Bullet tracking
var active_bullets: Dictionary = {}  # tank_id -> Array[Bullet]
var bullet_pool: Array[Bullet] = []
var next_bullet_id: int = 0

# Preloaded scenes
var bullet_scene: PackedScene

func _ready() -> void:
	bullet_scene = preload("res://scenes/bullet.tscn")
	_initialize_pool()
	
	# Subscribe to bullet fired events with proper callable binding
	EventBus.subscribe("BulletFired", Callable(self, "_on_bullet_fired"))

func _initialize_pool() -> void:
	for i in range(BULLET_POOL_SIZE):
		var bullet = _create_bullet()
		bullet.process_mode = Node.PROCESS_MODE_DISABLED
		bullet.visible = false
		bullet_pool.append(bullet)

func _create_bullet() -> Bullet:
	var bullet: Bullet
	if bullet_scene:
		bullet = bullet_scene.instantiate() as Bullet
	else:
		bullet = Bullet.new()
	
	add_child(bullet)
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
	var position = bullet_event.position
	var direction = bullet_event.direction
	var level = bullet_event.bullet_level
	
	bullet.bullet_id = next_bullet_id
	next_bullet_id += 1
	
	bullet.initialize(position, direction, tank_id, level)
	bullet.process_mode = Node.PROCESS_MODE_INHERIT
	bullet.visible = true
	bullet.is_active = true
	
	# Track active bullet
	active_bullets[tank_id].append(bullet)

func _get_bullet_from_pool() -> Bullet:
	if bullet_pool.is_empty():
		# Pool exhausted, create new bullet
		return _create_bullet()
	
	return bullet_pool.pop_back()

func _on_bullet_destroyed(bullet: Bullet) -> void:
	# Remove from active tracking
	if active_bullets.has(bullet.owner_tank_id):
		active_bullets[bullet.owner_tank_id].erase(bullet)
	
	# Return to pool
	bullet.process_mode = Node.PROCESS_MODE_DISABLED
	bullet.visible = false
	bullet_pool.append(bullet)

func clear_all_bullets() -> void:
	for tank_id in active_bullets.keys():
		for bullet in active_bullets[tank_id]:
			if is_instance_valid(bullet):
				bullet._destroy()
	
	active_bullets.clear()

func get_bullet_count_for_tank(tank_id: int) -> int:
	if active_bullets.has(tank_id):
		return active_bullets[tank_id].size()
	return 0
