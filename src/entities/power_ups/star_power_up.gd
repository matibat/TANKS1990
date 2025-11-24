extends PowerUp
class_name StarPowerUp
# Star power-up: Upgrades player tank level (max 3)

func _ready():
	power_up_type = "Star"
	super._ready()

func _create_placeholder_visual():
	var sprite = ColorRect.new()
	sprite.size = Vector2(32, 32)
	sprite.position = Vector2(-16, -16)
	sprite.color = Color.YELLOW  # Yellow star
	add_child(sprite)

func apply_effect(tank):
	# Upgrade tank level (max 3)
	if tank.has("level"):
		tank.level = min(tank.level + 1, 3)
