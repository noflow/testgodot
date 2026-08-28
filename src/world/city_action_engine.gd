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
	if str(interaction.get("type", "activity")) == "store":
		var store: Variant = _registry.get_content("stores", str(interaction.get("store_id", "")))
		if not store is Dictionary:
			return "This storefront is not configured yet."
		if store.has("open_days") and str(state["clock"].get("weekday", "")) not in store["open_days"]:
			return "%s is closed today." % store.get("name", "This store")
		if store.has("open_blocks") and str(state["clock"].get("block", "")) not in store["open_blocks"]:
			return "%s is closed during this activity block." % store.get("name", "This store")

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
	var interaction_type: String = str(interaction.get("type", "activity"))
	if interaction_type not in ["activity", "exploration"]:
		return _failure("This interaction begins a conversation instead of an activity.")
	var quest_sync: Dictionary = _quests.sync_automatic_activations(state, "city.activity:%s.preflight" % interaction_id)
	if not quest_sync.get("ok", false):
		return _failure(str(quest_sync.get("errors", ["Quest state could not be synchronized."])[0]))
	var working: Dictionary = quest_sync["state"]
	var reason: String = availability_error(working, interaction)
	if not reason.is_empty():
		return _failure(reason)
	working = working.duplicate(true)

	var outcome: Dictionary = {}
	if interaction_type == "exploration":
		outcome = _select_exploration_outcome(working, interaction)
		if outcome.is_empty():
			return _failure("Nothing new draws your attention here right now.")

	var applied_events: Array = []
	var operations: Array = interaction.get("operations", []).duplicate(true)
	operations.append_array(outcome.get("operations", []))
	for operation_entry: Variant in operations:
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
	var state_updates: Array = interaction.get("state_updates", []).duplicate(true)
	state_updates.append_array(outcome.get("state_updates", []))
	for update: Variant in state_updates:
		if update is Dictionary:
			_set_state_value(working, str(update.get("path", "")), update.get("value"))
	var quest_events: Array = interaction.get("quest_events", []).duplicate(true)
	quest_events.append_array(outcome.get("quest_events", []))
	for quest_event: Variant in quest_events:
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
	if interaction_type == "exploration":
		_record_exploration(working, interaction, outcome)
	if bool(interaction.get("once_only", false)):
		working["player"]["flags"]["city_activity.%s" % interaction_id] = true
	return {
		"ok": true,
		"state": working,
		"interaction": interaction,
		"outcome": outcome,
		"events": applied_events,
		"errors": PackedStringArray(),
	}


func _select_exploration_outcome(state: Dictionary, interaction: Dictionary) -> Dictionary:
	var selected: Dictionary = {}
	var selected_priority: int = -2147483648
	for outcome_value: Variant in interaction.get("outcomes", []):
		if not outcome_value is Dictionary:
			continue
		var outcome: Dictionary = outcome_value
		if not _exploration_outcome_matches(state, str(interaction.get("id", "")), outcome):
			continue
		var priority: int = int(outcome.get("priority", 0))
		if selected.is_empty() or priority > selected_priority:
			selected = outcome.duplicate(true)
			selected_priority = priority
	return selected


func _exploration_outcome_matches(state: Dictionary, interaction_id: String, outcome: Dictionary) -> bool:
	var exploration: Dictionary = state.get("world_state", {}).get("exploration", {})
	var outcome_key: String = "%s:%s" % [interaction_id, outcome.get("id", "outcome")]
	if bool(outcome.get("once_only", false)) and outcome_key in exploration.get("completed_outcomes", []):
		return false
	var requirements: Dictionary = outcome.get("requirements", {})
	var block: String = str(state.get("clock", {}).get("block", ""))
	if requirements.has("blocks") and block not in requirements.get("blocks", []):
		return false
	var weather: String = str(state.get("world_state", {}).get("weather", {}).get("condition", ""))
	if requirements.has("weather_conditions") and weather not in requirements.get("weather_conditions", []):
		return false
	var flags: Dictionary = state.get("player", {}).get("flags", {})
	var required_flag: String = str(requirements.get("flag", ""))
	if not required_flag.is_empty() and not bool(flags.get(required_flag, false)):
		return false
	var forbidden_flag: String = str(requirements.get("not_flag", ""))
	if not forbidden_flag.is_empty() and bool(flags.get(forbidden_flag, false)):
		return false
	var skill_requirement: Variant = requirements.get("skill_at_least")
	if skill_requirement is Array and skill_requirement.size() == 2:
		if float(state.get("player", {}).get("skills", {}).get(str(skill_requirement[0]), 0.0)) < float(skill_requirement[1]):
			return false
	var positive_trait: String = str(requirements.get("positive_trait", ""))
	if not positive_trait.is_empty() and positive_trait not in state.get("player", {}).get("selected_traits", {}).get("positive", []):
		return false
	return true


func _record_exploration(state: Dictionary, interaction: Dictionary, outcome: Dictionary) -> void:
	var world: Dictionary = state["world_state"]
	if not world.get("exploration") is Dictionary:
		world["exploration"] = {}
	var exploration: Dictionary = world["exploration"]
	for collection_name: String in ["completed_outcomes", "discovered_leads", "history"]:
		if not exploration.get(collection_name) is Array:
			exploration[collection_name] = []
	var interaction_id: String = str(interaction.get("id", ""))
	var outcome_id: String = str(outcome.get("id", "outcome"))
	var outcome_key: String = "%s:%s" % [interaction_id, outcome_id]
	if outcome_key not in exploration["completed_outcomes"]:
		exploration["completed_outcomes"].append(outcome_key)
	for lead_value: Variant in outcome.get("leads", []):
		if not lead_value is Dictionary:
			continue
		var lead: Dictionary = lead_value.duplicate(true)
		var lead_id: String = str(lead.get("id", ""))
		if lead_id.is_empty() or _exploration_lead_exists(exploration["discovered_leads"], lead_id):
			continue
		lead["discovered_at"] = _clock_timestamp(state["clock"])
		lead["source"] = interaction_id
		exploration["discovered_leads"].append(lead)
	exploration["history"].append({
		"interaction_id": interaction_id,
		"outcome_id": outcome_id,
		"location": str(world.get("current_location", "")),
		"timestamp": _clock_timestamp(state["clock"]),
		"summary": str(outcome.get("summary", "")),
	})
	while exploration["history"].size() > 100:
		exploration["history"].pop_front()
	var notification: Variant = outcome.get("notification")
	if notification is Dictionary:
		_append_phone_notification(state, interaction_id, outcome_id, notification)


func _exploration_lead_exists(leads: Array, lead_id: String) -> bool:
	for lead_value: Variant in leads:
		if lead_value is Dictionary and str(lead_value.get("id", "")) == lead_id:
			return true
	return false


func _append_phone_notification(
	state: Dictionary,
	interaction_id: String,
	outcome_id: String,
	notification: Dictionary
) -> void:
	var phone: Dictionary = state["player"]["phone"]
	if not phone.get("notifications") is Array:
		phone["notifications"] = []
	var notification_id: String = "exploration.%s.%s" % [interaction_id, outcome_id]
	for existing_value: Variant in phone["notifications"]:
		if existing_value is Dictionary and str(existing_value.get("id", "")) == notification_id:
			return
	phone["notifications"].append({
		"id": notification_id,
		"category": str(notification.get("category", "exploration")),
		"title": str(notification.get("title", "Local discovery")),
		"body": str(notification.get("body", "A new local note was saved.")),
		"timestamp": _clock_timestamp(state["clock"]),
		"read": false,
		"location": str(state["world_state"].get("current_location", "")),
	})


func _clock_timestamp(state_clock: Dictionary) -> String:
	return "Y%d-%02d-%02d:%s+%03d" % [
		int(state_clock.get("year", 1)), int(state_clock.get("month", 1)), int(state_clock.get("day", 1)),
		str(state_clock.get("block", "early_morning")), int(state_clock.get("minute_within_block", 0)),
	]


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
