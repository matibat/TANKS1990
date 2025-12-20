class_name BulletFiredEvent
extends GameEvent
## Event emitted when a bullet is fired

var bullet_id: int
var tank_id: int
var position: Variant  # Vector2 (2D) or Vector3 (3D)
var direction: Variant  # Vector2 (2D) or Vector3 (3D)
var bullet_level: int = 1  # Affects speed/power
var is_player_bullet: bool = false  # True if fired by player

func get_event_type() -> String:
	return "BulletFired"

func to_dict() -> Dictionary:
	var base = super.to_dict()
	base["bullet_id"] = bullet_id
	base["tank_id"] = tank_id
	base["position"] = {"x": position.x, "y": position.y}
	base["direction"] = {"x": direction.x, "y": direction.y}
	base["bullet_level"] = bullet_level
	base["is_player_bullet"] = is_player_bullet
	return base

static func from_dict(data: Dictionary) -> BulletFiredEvent:
	var event = BulletFiredEvent.new()
	event.frame = data.get("frame", 0)
	event.timestamp = data.get("timestamp", 0)
	event.bullet_id = data.get("bullet_id", 0)
	event.tank_id = data.get("tank_id", 0)
	var pos = data.get("position", {"x": 0, "y": 0})
	event.position = Vector2(pos.x, pos.y)
	var dir = data.get("direction", {"x": 0, "y": -1})
	event.direction = Vector2(dir.x, dir.y)
	event.bullet_level = data.get("bullet_level", 1)
	event.is_player_bullet = data.get("is_player_bullet", false)
	return event
