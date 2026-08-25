extends RefCounted
class_name PortAlderHomeActionEngine

var _registry: Node
var _simulation: RefCounted


func _init(content_registry: Node, simulation_engine: RefCounted) -> void:
	_registry = content_registry
	_simulation = simulation_engine


func perform_action(state: Dictionary, action_id: String) -> Dictionary:
	var action: Variant = _registry.get_content("actions", action_id)
	if not action is Dictionary:
		return _failure("Unknown home action: %s" % action_id)
	var working: Dictionary = state.duplicate(true)
	var applied_events: Array = []
	for operation_entry: Variant in action.get("operations", []):
		if not operation_entry is Dictionary:
			continue
		var operation: String = str(operation_entry.get("operation", ""))
		var result: Dictionary = _simulation.apply_operation(
			working,
			operation,
			operation_entry.get("payload", {}),
			"home.action:%s" % action_id
		)
		if not result.get("ok", false):
			return _failure(str(result.get("errors", ["Home action failed."])[0]))
		working = result["state"]
		applied_events.append(result["event"])
	return {
		"ok": true,
		"state": working,
		"action": action,
		"events": applied_events,
		"errors": PackedStringArray(),
	}


func _failure(message: String) -> Dictionary:
	return {"ok": false, "errors": PackedStringArray([message])}
