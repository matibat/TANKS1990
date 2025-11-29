extends PowerUp
class_name GrenadePowerUp
# Grenade power-up: Destroys all enemies on screen

func _ready():
	power_up_type = "Grenade"
	super._ready()

func _create_placeholder_visual():
	var bg = ColorRect.new()
	bg.size = Vector2(30, 30)
	bg.position = Vector2(-15, -15)
	bg.color = Color.RED
	add_child(bg)
	_create_icon()

func _create_icon():
	var icon = Label.new()
	icon.text = "💣"
	icon.position = Vector2(-10, -12)
	icon.add_theme_font_size_override("font_size", 20)
	add_child(icon)

func apply_effect(_tank):
	# Destroy all enemy tanks
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(9999)  # Instant kill
