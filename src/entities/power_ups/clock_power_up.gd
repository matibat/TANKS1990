extends PowerUp
class_name ClockPowerUp
# Clock power-up: Freezes all enemies for 6 seconds

func _ready():
	power_up_type = "Clock"
	super._ready()

func _create_placeholder_visual():
	var sprite = ColorRect.new()
	sprite.size = Vector2(32, 32)
	sprite.position = Vector2(-16, -16)
	sprite.color = Color.ORANGE  # Orange for time freeze
	add_child(sprite)

func apply_effect(tank):
	# Freeze all enemy tanks for 6 seconds
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("freeze"):
			enemy.freeze(6.0)
		elif is_instance_valid(enemy) and enemy.has("is_frozen"):
			# Fallback: set properties directly
			enemy.is_frozen = true
			enemy.freeze_time = 6.0
