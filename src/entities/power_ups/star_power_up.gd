extends PowerUp
class_name StarPowerUp
# Star power-up: Upgrades player tank level (max 3)

func _ready():
	power_up_type = "Star"
	super._ready()

func _create_placeholder_visual():
	var bg = ColorRect.new()
	bg.size = Vector2(30, 30)
	bg.position = Vector2(-15, -15)
	bg.color = Color.YELLOW
	add_child(bg)
	_create_icon()

func _create_icon():
	var icon = Label.new()
	icon.text = "★"
	icon.position = Vector2(-10, -12)
	icon.add_theme_font_size_override("font_size", 24)
	icon.add_theme_color_override("font_color", Color.ORANGE)
	add_child(icon)

func apply_effect(tank):
	# Upgrade tank level (max 3)
	if "level" in tank:
		tank.level = min(tank.level + 1, 3)
