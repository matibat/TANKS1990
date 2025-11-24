extends PowerUp
class_name GrenadePowerUp
# Grenade power-up: Destroys all enemies on screen

func _ready():
	power_up_type = "Grenade"
	super._ready()

func _create_placeholder_visual():
	var sprite = ColorRect.new()
	sprite.size = Vector2(32, 32)
	sprite.position = Vector2(-16, -16)
	sprite.color = Color.RED  # Red for explosive
	add_child(sprite)

func apply_effect(tank):
	# Destroy all enemy tanks
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(9999)  # Instant kill
