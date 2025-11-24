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
	collision_mask = 1   # Detect player tanks (layer 1)
	
	lifetime_remaining = lifetime_seconds
	
	# Connect collision signal
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# Visual placeholder (32x32 colored square until sprite added)
	_create_placeholder_visual()

func _process(delta: float):
	# Timeout mechanism
	lifetime_remaining -= delta
	if lifetime_remaining <= 0:
		_timeout()

func _create_placeholder_visual():
	# Subclasses override this with specific colors
	var sprite = ColorRect.new()
	sprite.size = Vector2(32, 32)
	sprite.position = Vector2(-16, -16)  # Center on power-up position
	sprite.color = Color.WHITE
	add_child(sprite)

func _on_area_entered(area: Area2D):
	# Detect player tank collision (tanks have Area2D component)
	var parent = area.get_parent()
	if parent and parent.has("tank_type") and parent.tank_type == "Player":
		_collect(parent)

func _on_body_entered(body: Node2D):
	# Detect player tank collision (CharacterBody2D)
	if body.has("tank_type") and body.tank_type == "Player":
		_collect(body)

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
	event.power_up_type = power_up_type
	event.collector_position = tank.global_position
	event.frame = EventBus.current_frame
	EventBus.emit_game_event(event)

# Abstract method - must be overridden by subclasses
func apply_effect(tank):
	push_error("PowerUp.apply_effect() must be overridden by subclass")
