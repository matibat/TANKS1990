extends Area2D
class_name PowerUp
# Abstract base class for power-ups
# All power-ups spawn from Armored tank destruction and timeout after 20 seconds

@export var power_up_type: String = "Base"  # Overridden by subclasses
@export var lifetime_seconds: float = 20.0

var lifetime_remaining: float

func _ready():
	add_to_group("power_ups")
	collision_layer = 8  # Layer 4 (power-ups)
	collision_mask = 1   # Detect tanks on layer 1
	
	lifetime_remaining = lifetime_seconds
	
	# Connect collision signals
	body_entered.connect(_on_body_entered)
	
	# Visual placeholder (32x32 colored square until sprite added)
	_create_placeholder_visual()
	
	# Defer collision setup to avoid physics callback errors
	call_deferred("_setup_collision")

func _process(delta: float):
	# Timeout mechanism
	lifetime_remaining -= delta
	if lifetime_remaining <= 0:
		_timeout()

func _create_placeholder_visual():
	# Create background square
	var bg = ColorRect.new()
	bg.size = Vector2(30, 30)
	bg.position = Vector2(-15, -15)
	bg.color = Color.WHITE
	add_child(bg)
	
	# Add icon/symbol (subclasses override to customize)
	_create_icon()

func _on_body_entered(body: Node2D):
	# Detect player tank collision (CharacterBody2D)
	if body is CharacterBody2D and "is_player" in body and body.is_player:
		_collect(body)
		print("[PowerUp] Collected by player at ", body.global_position)

func _collect(tank):
	# Apply effect and remove power-up
	apply_effect(tank)
	_emit_collected_event(tank)
	queue_free()

func _timeout():
	# Remove power-up after 20 seconds
	queue_free()

func _emit_collected_event(tank):
	var event = load("res://src/events/powerup_collected_event.gd").new()
	
	# Convert string power_up_type to enum
	var PowerUpEventClass = load("res://src/events/powerup_spawned_event.gd")
	var powerup_enum = PowerUpEventClass.PowerUpType.STAR  # Default
	match power_up_type:
		"Star": powerup_enum = PowerUpEventClass.PowerUpType.STAR
		"Grenade": powerup_enum = PowerUpEventClass.PowerUpType.GRENADE
		"Helmet": powerup_enum = PowerUpEventClass.PowerUpType.HELMET
		"Shovel": powerup_enum = PowerUpEventClass.PowerUpType.SHOVEL
		"Tank": powerup_enum = PowerUpEventClass.PowerUpType.TANK
		"Clock": powerup_enum = PowerUpEventClass.PowerUpType.TIMER
	
	event.powerup_type = powerup_enum
	event.powerup_id = get_instance_id()
	event.collected_by_tank_id = tank.tank_id if "tank_id" in tank else 0
	event.position = tank.global_position
	event.frame = EventBus.current_frame
	EventBus.emit_game_event(event)

func _setup_collision():
	# Add collision shape (called deferred to avoid physics callback errors)
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(28, 28)  # Slightly smaller than visual for easier pickup
	collision_shape.shape = shape
	add_child(collision_shape)
	
	# Enable monitoring
	monitoring = true
	monitorable = true

# Create icon/symbol - subclasses should override
func _create_icon():
	pass

# Abstract method - must be overridden by subclasses
func apply_effect(_tank):
	push_error("PowerUp.apply_effect() must be overridden by subclass")
