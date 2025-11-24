extends PowerUp
class_name HelmetPowerUp
# Helmet power-up: Grants 6 seconds of invulnerability

func _ready():
	power_up_type = "Helmet"
	super._ready()

func _create_placeholder_visual():
	var sprite = ColorRect.new()
	sprite.size = Vector2(32, 32)
	sprite.position = Vector2(-16, -16)
	sprite.color = Color.CYAN  # Cyan for shield
	add_child(sprite)

func apply_effect(tank):
	# Grant 6 seconds invulnerability
	if tank.has_method("make_invulnerable"):
		tank.make_invulnerable(6.0)
	else:
		# Fallback: set properties directly
		tank.is_invulnerable = true
		tank.invulnerability_time = 6.0
