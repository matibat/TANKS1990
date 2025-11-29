extends PowerUp
class_name HelmetPowerUp
# Helmet power-up: Grants 6 seconds of invulnerability

func _ready():
	power_up_type = "Helmet"
	super._ready()

func _create_placeholder_visual():
	var bg = ColorRect.new()
	bg.size = Vector2(30, 30)
	bg.position = Vector2(-15, -15)
	bg.color = Color.CYAN
	add_child(bg)
	_create_icon()

func _create_icon():
	var icon = Label.new()
	icon.text = "H"
	icon.position = Vector2(-8, -12)
	icon.add_theme_font_size_override("font_size", 20)
	icon.add_theme_color_override("font_color", Color.WHITE)
	add_child(icon)

func apply_effect(tank):
	# Grant 6 seconds invulnerability
	if tank.has_method("make_invulnerable"):
		tank.make_invulnerable(6.0)
	elif "is_invulnerable" in tank:
		# Fallback: set properties directly
		tank.is_invulnerable = true
		tank.invulnerability_time = 6.0
