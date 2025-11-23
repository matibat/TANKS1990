class_name CollisionEvent
extends GameEvent
## Event emitted when collision occurs

enum ColliderType { TANK, BULLET, TERRAIN, BASE, POWER_UP }

var entity_id: int
var collider_type: ColliderType
var collider_id: int
var position: Vector2
var result: String  # "bounce", "destroy", "pass_through", "damage"

func get_event_type() -> String:
	return "Collision"

func to_dict() -> Dictionary:
	var base = super.to_dict()
	base["entity_id"] = entity_id
	base["collider_type"] = collider_type
	base["collider_id"] = collider_id
	base["position"] = {"x": position.x, "y": position.y}
	base["result"] = result
	return base

static func from_dict(data: Dictionary) -> CollisionEvent:
	var event = CollisionEvent.new()
	event.frame = data.get("frame", 0)
	event.timestamp = data.get("timestamp", 0)
	event.entity_id = data.get("entity_id", 0)
	event.collider_type = data.get("collider_type", ColliderType.TERRAIN)
	event.collider_id = data.get("collider_id", -1)
	var pos = data.get("position", {"x": 0, "y": 0})
	event.position = Vector2(pos.x, pos.y)
	event.result = data.get("result", "destroy")
	return event
