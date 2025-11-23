class_name PowerUpSpawnedEvent
extends GameEvent
## Event emitted when power-up spawns

enum PowerUpType { STAR, GRENADE, HELMET, SHOVEL, TANK, TIMER }

var powerup_id: int
var powerup_type: PowerUpType
var position: Vector2
var spawned_by_tank_id: int  # Which armored tank dropped it

func get_event_type() -> String:
	return "PowerUpSpawned"

func to_dict() -> Dictionary:
	var base = super.to_dict()
	base["powerup_id"] = powerup_id
	base["powerup_type"] = powerup_type
	base["position"] = {"x": position.x, "y": position.y}
	base["spawned_by_tank_id"] = spawned_by_tank_id
	return base

static func from_dict(data: Dictionary) -> PowerUpSpawnedEvent:
	var event = PowerUpSpawnedEvent.new()
	event.frame = data.get("frame", 0)
	event.timestamp = data.get("timestamp", 0)
	event.powerup_id = data.get("powerup_id", 0)
	event.powerup_type = data.get("powerup_type", PowerUpType.STAR)
	var pos = data.get("position", {"x": 0, "y": 0})
	event.position = Vector2(pos.x, pos.y)
	event.spawned_by_tank_id = data.get("spawned_by_tank_id", -1)
	return event
