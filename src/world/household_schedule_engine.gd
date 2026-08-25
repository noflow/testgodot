extends RefCounted
class_name PortAlderHouseholdScheduleEngine

const HOME_LOCATION: String = "hale_home"

var _registry: Node


func _init(content_registry: Node) -> void:
	_registry = content_registry


func resolve_character(state: Dictionary, character_id: String) -> Dictionary:
	var character: Variant = _registry.get_character(character_id)
	if not character is Dictionary:
		return {}
	var clock: Dictionary = state.get("clock", {})
	var weekday: String = str(clock.get("weekday", "monday"))
	var block: String = str(clock.get("block", "early_morning"))
	for commitment: Variant in character.get("schedule", {}).get("fixed_commitments", []):
		if not commitment is Dictionary or not _commitment_matches(commitment, weekday, block):
			continue
		var location: String = str(commitment.get("location", ""))
		if location.is_empty():
			location = _existing_location(state, character_id)
		var result: Dictionary = {
			"character_id": character_id,
			"display_name": character.get("display_name", character_id),
			"activity": commitment.get("activity", "scheduled_commitment"),
			"activity_label": commitment.get("label", _label_for_activity(str(commitment.get("activity", "scheduled_commitment")))),
			"location": location,
			"unavailable": bool(commitment.get("unavailable", true)),
			"at_home": location == HOME_LOCATION or location.begins_with("%s." % HOME_LOCATION),
			"present": false,
		}
		if result["at_home"]:
			var placement: Dictionary = commitment.get("home_placement", {})
			if placement.is_empty():
				placement = _home_placement(character, weekday, block)
			_apply_placement(result, placement)
		return result

	var placement: Dictionary = _home_placement(character, weekday, block)
	var home_result: Dictionary = {
		"character_id": character_id,
		"display_name": character.get("display_name", character_id),
		"activity": placement.get("activity", "at_home"),
		"activity_label": placement.get("label", _label_for_activity(str(placement.get("activity", "at_home")))),
		"location": HOME_LOCATION,
		"unavailable": bool(placement.get("unavailable", false)),
		"at_home": true,
		"present": false,
	}
	_apply_placement(home_result, placement)
	return home_result


func synchronize_npc_states(state: Dictionary, character_ids: PackedStringArray) -> Dictionary:
	var working: Dictionary = state.duplicate(true)
	var changed: bool = false
	var resolutions: Dictionary = {}
	for character_id: String in character_ids:
		var resolution: Dictionary = resolve_character(working, character_id)
		resolutions[character_id] = resolution
		if resolution.is_empty():
			continue
		var npc_state: Dictionary = _npc_state(working, character_id)
		if npc_state.is_empty():
			continue
		for key: String in ["current_location", "current_activity", "schedule_unavailable"]:
			var value: Variant
			match key:
				"current_location": value = resolution.get("location", HOME_LOCATION)
				"current_activity": value = resolution.get("activity", "at_home")
				_: value = resolution.get("unavailable", false)
			if npc_state.get(key) != value:
				npc_state[key] = value
				changed = true
	return {"state": working if changed else state, "changed": changed, "resolutions": resolutions}


func _commitment_matches(commitment: Dictionary, weekday: String, block: String) -> bool:
	return weekday in commitment.get("days", []) and block in commitment.get("blocks", [])


func _home_placement(character: Dictionary, weekday: String, block: String) -> Dictionary:
	var routine: Dictionary = character.get("home_routine", {})
	for override: Variant in routine.get("overrides", []):
		if not override is Dictionary:
			continue
		if weekday in override.get("days", []) and block in override.get("blocks", []):
			return override
	var placement: Variant = routine.get("default_by_block", {}).get(block, {})
	return placement if placement is Dictionary else {}


func _apply_placement(result: Dictionary, placement: Dictionary) -> void:
	var room: String = str(placement.get("room", ""))
	if not room.is_empty():
		result["room"] = room
		result["location"] = "%s.%s" % [HOME_LOCATION, room]
	var position: Array = placement.get("position", [])
	if position.size() == 2:
		result["position"] = [float(position[0]), float(position[1])]
	result["present"] = bool(placement.get("spawn", not room.is_empty())) and position.size() == 2
	result["unavailable"] = bool(placement.get("unavailable", result.get("unavailable", false)))
	if placement.has("activity"):
		result["activity"] = placement["activity"]
		result["activity_label"] = placement.get("label", _label_for_activity(str(placement["activity"])))


func _existing_location(state: Dictionary, character_id: String) -> String:
	var npc_state: Dictionary = _npc_state(state, character_id)
	return str(npc_state.get("current_location", HOME_LOCATION))


func _npc_state(state: Dictionary, character_id: String) -> Dictionary:
	for candidate: Variant in state.get("npc_states", []):
		if candidate is Dictionary and str(candidate.get("character_id", "")) == character_id:
			return candidate
	return {}


func _label_for_activity(activity: String) -> String:
	if activity == "at_home":
		return "At home"
	return activity.replace("_", " ").capitalize()
