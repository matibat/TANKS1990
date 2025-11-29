extends PowerUp
class_name TankPowerUp
# Tank power-up: Grants player an extra life

func _ready():
	power_up_type = "Tank"
	super._ready()

func _create_placeholder_visual():
	var bg = ColorRect.new()
	bg.size = Vector2(30, 30)
	bg.position = Vector2(-15, -15)
	bg.color = Color.DARK_GREEN
	add_child(bg)
	_create_icon()

func _create_icon():
	# Draw tank icon (simplified)
	var icon = Label.new()
	icon.text = "T"
	icon.position = Vector2(-8, -12)
	icon.add_theme_font_size_override("font_size", 20)
	icon.add_theme_color_override("font_color", Color.WHITE)
	add_child(icon)

func apply_effect(tank):
	# Grant extra life to player
	if "lives" in tank:
		tank.lives += 1
