class_name Base
extends Area2D
## Eagle base entity - game ends if destroyed

signal destroyed()
signal damaged(health: int)

@export var max_health: int = 1
var health: int = 1
var is_destroyed: bool = false

# Constants
const TILE_SIZE: int = 16

func _init() -> void:
	# Create collision shape immediately in _init so it's available for tests
	var collision_shape = CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	var rect = RectangleShape2D.new()
	rect.size = Vector2(16, 16)  # 1 tile
	collision_shape.shape = rect
	add_child(collision_shape)

func _ready() -> void:
	health = max_health
	
	# Position at bottom center of viewport
	var viewport_size = get_viewport().get_visible_rect().size
	position.x = viewport_size.x / 2.0
	position.y = viewport_size.y - (TILE_SIZE * 2)  # 2 tiles from bottom
	
	# Set up collision detection
	collision_layer = 8  # Base on layer 4 (2^3)
	collision_mask = 4   # Detect bullets on layer 3 (2^2)
	
	# Connect signals
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# Add visual representation
	_create_visual()

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
	
	# Then emit event
	var event = BaseDestroyedEvent.new()
	event.position = global_position
	event.destroyed_by_id = -1
	EventBus.emit_game_event(event)
	
	# Visual feedback
	modulate = Color.RED

func _on_area_entered(area: Area2D) -> void:
	"""Handle bullet collision"""
	if area is Bullet:
		var bullet = area as Bullet
		# Only enemy bullets damage base
		if bullet.owner_type == Bullet.OwnerType.ENEMY:
			take_damage(1)
		# All bullets are destroyed on base contact
		bullet._destroy()

func _on_body_entered(body: Node2D) -> void:
	"""Handle tank collision"""
	if body is Tank:
		var tank = body as Tank
		# Only enemy tanks damage base
		if tank.tank_type != Tank.TankType.PLAYER:
			take_damage(1)

func _create_visual() -> void:
	"""Create visual representation of base"""
	var sprite = ColorRect.new()
	sprite.size = Vector2(16, 16)
	sprite.position = Vector2(-8, -8)  # Center it
	sprite.color = Color.YELLOW
	add_child(sprite)
	
	# Add label for debug
	var label = Label.new()
	label.text = "BASE"
	label.position = Vector2(-12, -24)
	label.add_theme_font_size_override("font_size", 8)
	add_child(label)
