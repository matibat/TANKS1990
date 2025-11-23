class_name PowerUpCollectedEvent
extends GameEvent
## Event emitted when player collects power-up

var powerup_id: int
var powerup_type: PowerUpSpawnedEvent.PowerUpType
var collected_by_tank_id: int
var position: Vector2

func get_event_type() -> String:
	return "PowerUpCollected"

func to_dict() -> Dictionary:
	var base = super.to_dict()
	base["powerup_id"] = powerup_id
	base["powerup_type"] = powerup_type
	base["collected_by_tank_id"] = collected_by_tank_id
	base["position"] = {"x": position.x, "y": position.y}
	return base

static func from_dict(data: Dictionary) -> PowerUpCollectedEvent:
	var event = PowerUpCollectedEvent.new()
	event.frame = data.get("frame", 0)
	event.timestamp = data.get("timestamp", 0)
	event.powerup_id = data.get("powerup_id", 0)
	event.powerup_type = data.get("powerup_type", PowerUpSpawnedEvent.PowerUpType.STAR)
	event.collected_by_tank_id = data.get("collected_by_tank_id", 0)
	var pos = data.get("position", {"x": 0, "y": 0})
	event.position = Vector2(pos.x, pos.y)
	return event
