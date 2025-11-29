extends PowerUp
class_name ClockPowerUp
# Clock power-up: Freezes all enemies for 6 seconds

func _ready():
	power_up_type = "Clock"
	super._ready()

func _create_placeholder_visual():
	var bg = ColorRect.new()
	bg.size = Vector2(30, 30)
	bg.position = Vector2(-15, -15)
	bg.color = Color.ORANGE
	add_child(bg)
	_create_icon()

func _create_icon():
	var icon = Label.new()
	icon.text = "⏰"
	icon.position = Vector2(-10, -12)
	icon.add_theme_font_size_override("font_size", 20)
	add_child(icon)

func apply_effect(_tank):
	# Freeze all enemy tanks for 6 seconds
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("freeze"):
			enemy.freeze(6.0)
		elif is_instance_valid(enemy) and "is_frozen" in enemy:
			# Fallback: set properties directly
			enemy.is_frozen = true
			enemy.freeze_time = 6.0
