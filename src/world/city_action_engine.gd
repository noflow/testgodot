extends RefCounted
class_name PortAlderCityActionEngine

const BLOCK_ORDER: PackedStringArray = [
	"early_morning", "morning", "lunch", "afternoon", "evening", "late_evening", "night",
]

var _registry: Node
var _simulation: RefCounted
var _quests: RefCounted


func _init(content_registry: Node, simulation_engine: RefCounted, quest_engine: RefCounted) -> void:
	_registry = content_registry
	_simulation = simulation_engine
	_quests = quest_engine


func interactions_for_room(state: Dictionary, location_id: String, room_id: String) -> Array:
	var results: Array = []
	for value: Variant in _registry.get_all("city_interactions"):
		if not value is Dictionary:
			continue
		var interaction: Dictionary = value
		if str(interaction.get("location", "")) != location_id or room_id not in interaction.get("rooms", []):
			continue
		var entry: Dictionary = interaction.duplicate(true)
		var reason: String = availability_error(state, entry)
		entry["available"] = reason.is_empty()
		entry["unavailable_reason"] = reason
		results.append(entry)
	return results


func availability_error(state: Dictionary, interaction: Dictionary) -> String:
	var current_location: String = str(state["world_state"].get("current_location", ""))
	if current_location.get_slice(".", 0) != str(interaction.get("location", "")):
		return "Travel to this destination before using the activity."
	var current_room: String = current_location.get_slice(".", 1)
	if not current_room.is_empty() and current_room not in interaction.get("rooms", []):
		return "Move to the activity's room first."
	var location: Variant = _registry.get_location(str(interaction.get("location", "")))
	if location is Dictionary:
		var access: Dictionary = location.get("access", {})
		if access.has("open_days") and str(state["clock"].get("weekday", "")) not in access["open_days"]:
			return "%s is closed today." % location.get("name", "This destination")
		if access.has("open_blocks") and str(state["clock"].get("block", "")) not in access["open_blocks"]:
			return "%s is closed during this activity block." % location.get("name", "This destination")

	var requirements: Dictionary = interaction.get("requirements", {})
	var active_quests: Array = state["quest_state"].get("active", [])
	var required_quest: String = str(requirements.get("quest_active", ""))
	if not required_quest.is_empty() and required_quest not in active_quests:
		return "Required quest is not active."
	if requirements.has("quest_any_active"):
		var found_active: bool = false
		for quest_id: Variant in requirements["quest_any_active"]:
			if str(quest_id) in active_quests:
				found_active = true
				break
		if not found_active:
			return "A related employment quest must be active."
	var complete_requirement: Array = requirements.get("quest_objective_complete", [])
	if complete_requirement.size() == 2 and not _objective_complete(state, str(complete_requirement[0]), str(complete_requirement[1])):
		return "Complete the previous quest step first."
	var incomplete_requirement: Array = requirements.get("quest_objective_incomplete", [])
	if incomplete_requirement.size() == 2 and _objective_complete(state, str(incomplete_requirement[0]), str(incomplete_requirement[1])):
		return "This quest activity is already complete."
	var flag: String = str(requirements.get("flag", ""))
	if not flag.is_empty() and not bool(state["player"].get("flags", {}).get(flag, false)):
		return "Gym access is required. Talk to Rachel at the front desk."
	if bool(requirements.get("appropriate_shoes", false)) and not _wearing_training_shoes(state):
		return "Wear sneakers or athletic shoes before training."
	if float(state["player"]["needs"].get("inebriation", 0.0)) > float(requirements.get("maximum_inebriation", 100.0)):
		return "Training is unavailable while impaired."
	if float(state["player"]["needs"].get("energy", 0.0)) < float(requirements.get("minimum_energy", 0.0)):
		return "You need more energy before this workout."
	if bool(interaction.get("once_only", false)) and bool(state["player"]["flags"].get("city_activity.%s" % interaction.get("id", ""), false)):
		return "This one-time activity is already complete."
	return ""


func perform_activity(state: Dictionary, interaction_id: String) -> Dictionary:
	var value: Variant = _registry.get_content("city_interactions", interaction_id)
	if not value is Dictionary:
		return _failure("Unknown city interaction: %s" % interaction_id)
	var interaction: Dictionary = value
	if str(interaction.get("type", "activity")) != "activity":
		return _failure("This interaction begins a conversation instead of an activity.")
	var reason: String = availability_error(state, interaction)
	if not reason.is_empty():
		return _failure(reason)

	var working: Dictionary = state.duplicate(true)
	var applied_events: Array = []
	for operation_entry: Variant in interaction.get("operations", []):
		if not operation_entry is Dictionary:
			continue
		var result: Dictionary = _simulation.apply_operation(
			working,
			str(operation_entry.get("operation", "")),
			operation_entry.get("payload", {}),
			"city.activity:%s" % interaction_id
		)
		if not result.get("ok", false):
			return _failure(str(result.get("errors", ["City activity failed."])[0]))
		working = result["state"]
		applied_events.append(result["event"])
	for update: Variant in interaction.get("state_updates", []):
		if update is Dictionary:
			_set_state_value(working, str(update.get("path", "")), update.get("value"))
	for quest_event: Variant in interaction.get("quest_events", []):
		if not quest_event is Dictionary:
			continue
		var event_payload: Dictionary = quest_event.duplicate(true)
		var event_name: String = str(event_payload.get("event", ""))
		event_payload.erase("event")
		var quest_result: Dictionary = _quests.record_event(
			working, event_name, event_payload, "city.activity:%s" % interaction_id
		)
		if not quest_result.get("ok", false):
			return _failure(str(quest_result.get("errors", ["Quest progress could not be recorded."])[0]))
		working = quest_result["state"]
	if bool(interaction.get("once_only", false)):
		working["player"]["flags"]["city_activity.%s" % interaction_id] = true
	return {
		"ok": true,
		"state": working,
		"interaction": interaction,
		"events": applied_events,
		"errors": PackedStringArray(),
	}


func _objective_complete(state: Dictionary, quest_id: String, objective_id: String) -> bool:
	return bool(state["quest_state"].get("objectives", {}).get(quest_id, {}).get(objective_id, false))


func _wearing_training_shoes(state: Dictionary) -> bool:
	var shoe_id: String = str(state["player"]["inventory"].get("equipped_outfit", {}).get("shoes", ""))
	if shoe_id.is_empty():
		return false
	var item: Variant = _registry.get_content("items", shoe_id)
	if not item is Dictionary:
		return false
	var searchable: String = "%s %s" % [shoe_id, item.get("name", "")]
	searchable = searchable.to_lower()
	return "sneaker" in searchable or "athletic" in searchable or "trainer" in searchable


func _set_state_value(state: Dictionary, path: String, value: Variant) -> void:
	if path.is_empty():
		return
	var parts: PackedStringArray = path.split(".")
	var current: Dictionary = state
	for index: int in range(parts.size() - 1):
		if not current.has(parts[index]) or not current[parts[index]] is Dictionary:
			current[parts[index]] = {}
		current = current[parts[index]]
	current[parts[-1]] = value.duplicate(true) if value is Array or value is Dictionary else value


func _failure(message: String) -> Dictionary:
	return {"ok": false, "errors": PackedStringArray([message])}
