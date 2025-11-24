extends PowerUp
class_name TankPowerUp
# Tank power-up: Grants player an extra life

func _ready():
	power_up_type = "Tank"
	super._ready()

func _create_placeholder_visual():
	var sprite = ColorRect.new()
	sprite.size = Vector2(32, 32)
	sprite.position = Vector2(-16, -16)
	sprite.color = Color.DARK_GREEN  # Green for extra life
	add_child(sprite)

func apply_effect(tank):
	# Grant extra life to player
	if tank.has("lives"):
		tank.lives += 1
