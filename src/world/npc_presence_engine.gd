extends RefCounted
class_name PortAlderNpcPresenceEngine

const OPENING_DATE_SERIAL: int = 232

var _registry: Node


func _init(content_registry: Node) -> void:
	_registry = content_registry


func resolve_character(state: Dictionary, character_id: String) -> Dictionary:
	var character: Variant = _registry.get_character(character_id)
	if not character is Dictionary:
		return {}
	var entry: Dictionary = _calendar_presence(state, character_id)
	var source: String = "calendar"
	if entry.is_empty():
		entry = _matching_schedule_entry(state, character.get("schedule", {}).get("fixed_commitments", []))
		source = "fixed_commitment"
	if entry.is_empty():
		entry = _matching_schedule_entry(state, character.get("schedule", {}).get("public_presence", []))
		source = "public_presence"
	if entry.is_empty():
		return _home_resolution(state, character)
	var room_hint: String = str(entry.get("room", ""))
	if room_hint.is_empty() and entry.get("home_placement") is Dictionary:
		room_hint = str(entry.get("home_placement", {}).get("room", ""))
	var location_path: String = _normalized_location_path(str(entry.get("location", "")), room_hint)
	if location_path.is_empty():
		return _home_resolution(state, character)
	var unavailable: bool = bool(entry.get("unavailable", false))
	if source == "calendar":
		unavailable = false
	return {
		"character_id": character_id,
		"display_name": character.get("display_name", character_id),
		"location": location_path,
		"location_id": location_path.get_slice(".", 0),
		"room_id": location_path.get_slice(".", 1),
		"activity": entry.get("activity", source),
		"activity_label": entry.get("label", _activity_label(str(entry.get("activity", source)))),
		"source": source,
		"present": true,
		"unavailable": unavailable,
		"available_to_talk": not unavailable,
		"discovered": _npc_discovered(state, character_id),
		"phone_contact": character_id in state.get("player", {}).get("phone", {}).get("known_contacts", []),
		"busy_line": str(character.get("encounter", {}).get("busy_line", "They are occupied right now.")),
	}


func present_in_room(state: Dictionary, location_id: String, room_id: String) -> Array:
	var results: Array = []
	for npc_state_value: Variant in state.get("npc_states", []):
		if not npc_state_value is Dictionary:
			continue
		var resolution: Dictionary = resolve_character(state, str(npc_state_value.get("character_id", "")))
		if resolution.get("present", false) and str(resolution.get("location_id", "")) == location_id and str(resolution.get("room_id", "")) == room_id:
			results.append(resolution)
	results.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return str(left.get("display_name", "")) < str(right.get("display_name", "")))
	return results


func interactions_for_room(state: Dictionary, location_id: String, room_id: String) -> Array:
	var interactions: Array = []
	for resolution_value: Variant in present_in_room(state, location_id, room_id):
		if not resolution_value is Dictionary:
			continue
		var resolution: Dictionary = resolution_value
		var available: bool = bool(resolution.get("available_to_talk", false))
		var identity_known: bool = bool(resolution.get("discovered", false)) or bool(resolution.get("phone_contact", false))
		var encounter_name: String = str(resolution.get("display_name", "Someone")) if identity_known else "Someone New"
		var description: String = str(resolution.get("activity_label", "Present"))
		if not available:
			description = "%s — %s" % [description, resolution.get("busy_line", "They are busy right now.")]
		interactions.append({
			"id": "npc_presence.%s" % resolution.get("character_id", ""),
			"name": "%s • %s" % [encounter_name, "Available to talk" if available else "Busy"],
			"description": description,
			"type": "npc_presence",
			"character_id": resolution.get("character_id", ""),
			"available": available,
			"unavailable_reason": str(resolution.get("busy_line", "They are occupied right now.")) if not available else "",
		})
	return interactions


func synchronize_npc_states(state: Dictionary) -> Dictionary:
	var working: Dictionary = state.duplicate(true)
	var changed: bool = false
	var resolutions: Dictionary = {}
	for npc_state_value: Variant in working.get("npc_states", []):
		if not npc_state_value is Dictionary:
			continue
		var character_id: String = str(npc_state_value.get("character_id", ""))
		var resolution: Dictionary = resolve_character(working, character_id)
		resolutions[character_id] = resolution
		if resolution.is_empty():
			continue
		var updates: Dictionary = {
			"current_location": resolution.get("location", npc_state_value.get("current_location", "")),
			"current_activity": resolution.get("activity", "at_home"),
			"schedule_unavailable": resolution.get("unavailable", false),
		}
		for key_value: Variant in updates:
			var key: String = str(key_value)
			if npc_state_value.get(key) != updates[key]:
				npc_state_value[key] = updates[key]
				changed = true
	return {"state": working if changed else state, "changed": changed, "resolutions": resolutions}


func available_conversations(character_id: String) -> Array:
	var character: Variant = _registry.get_character(character_id)
	return character.get("conversations", []) if character is Dictionary else []


func ambient_line(state: Dictionary, character_id: String, location_id: String) -> String:
	var character: Variant = _registry.get_character(character_id)
	if not character is Dictionary:
		return ""
	var block: String = str(state.get("clock", {}).get("block", "morning"))
	for entry_value: Variant in character.get("ambient_dialogue", []):
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		if not entry.get("blocks", []).is_empty() and block not in entry.get("blocks", []):
			continue
		if not entry.get("locations", []).is_empty() and location_id not in entry.get("locations", []):
			continue
		return _player_tokens(str(entry.get("line", "")), state)
	return _player_tokens(str(character.get("encounter", {}).get("ambient_line", "Nice running into you.")), state)


func introduction_line(state: Dictionary, character_id: String) -> String:
	var character: Variant = _registry.get_character(character_id)
	if not character is Dictionary:
		return "You introduce yourselves."
	return _player_tokens(str(character.get("encounter", {}).get("intro_line", "You introduce yourselves and talk for a few minutes.")), state)


func contact_line(state: Dictionary, character_id: String) -> String:
	var character: Variant = _registry.get_character(character_id)
	if not character is Dictionary:
		return "You exchange contact information."
	return _player_tokens(str(character.get("encounter", {}).get("contact_line", "You exchange numbers and add each other to your contacts.")), state)


func contact_exchange_allowed(character_id: String) -> bool:
	var character: Variant = _registry.get_character(character_id)
	if not character is Dictionary:
		return false
	return str(character.get("encounter", {}).get("contact_policy", "after_introduction")) != "never"


func _matching_schedule_entry(state: Dictionary, entries: Array) -> Dictionary:
	var weekday: String = str(state.get("clock", {}).get("weekday", "monday"))
	var block: String = str(state.get("clock", {}).get("block", "morning"))
	for entry_value: Variant in entries:
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		if block not in entry.get("blocks", []):
			continue
		if _day_matches(state, weekday, entry.get("days", [])):
			return entry
	return {}


func _day_matches(state: Dictionary, weekday: String, days: Array) -> bool:
	if weekday in days or "all" in days:
		return true
	var rotation_day: int = posmod(_date_serial(state.get("clock", {})) - OPENING_DATE_SERIAL, 7) + 1
	if "rotation_day_%d" % rotation_day in days:
		return true
	if rotation_day == 5 and "first_day_off" in days:
		return true
	if rotation_day == 6 and "second_day_off" in days:
		return true
	return rotation_day == 7 and "third_day_off" in days


func _calendar_presence(state: Dictionary, character_id: String) -> Dictionary:
	var today: String = _date_string(state.get("clock", {}))
	var block: String = str(state.get("clock", {}).get("block", "morning"))
	for event_value: Variant in state.get("calendar_state", {}).get("events", []):
		if not event_value is Dictionary:
			continue
		var event: Dictionary = event_value
		if str(event.get("status", "scheduled")) not in ["scheduled", "arrived"]:
			continue
		if str(event.get("date", "")) != today or str(event.get("block", "")) != block or character_id not in event.get("participants", []):
			continue
		var location: String = str(event.get("location", event.get("meeting_location", "")))
		if location.is_empty():
			continue
		return {
			"location": location,
			"activity": event.get("type", "scheduled_meetup"),
			"label": event.get("title", "Scheduled time together"),
			"unavailable": false,
		}
	return {}


func _home_resolution(state: Dictionary, character: Dictionary) -> Dictionary:
	var character_id: String = str(character.get("id", ""))
	var home_location: String = str(character.get("home", {}).get("location_id", ""))
	return {
		"character_id": character_id,
		"display_name": character.get("display_name", character_id),
		"location": home_location,
		"location_id": home_location,
		"room_id": "",
		"activity": "at_home",
		"activity_label": "At home",
		"source": "home",
		"present": false,
		"unavailable": false,
		"available_to_talk": false,
		"discovered": _npc_discovered(state, character_id),
		"phone_contact": character_id in state.get("player", {}).get("phone", {}).get("known_contacts", []),
	}


func _normalized_location_path(location: String, room: String) -> String:
	if location.is_empty():
		return ""
	if location.contains("."):
		return location
	var definition: Variant = _registry.get_location(location)
	if not definition is Dictionary:
		return ""
	var room_id: String = room
	if room_id.is_empty():
		room_id = str(definition.get("outside_room", ""))
	if room_id.is_empty() and not definition.get("rooms", []).is_empty() and definition.get("rooms", [])[0] is Dictionary:
		room_id = str(definition.get("rooms", [])[0].get("id", ""))
	return "%s.%s" % [location, room_id] if not room_id.is_empty() else location


func _npc_discovered(state: Dictionary, character_id: String) -> bool:
	for npc_state_value: Variant in state.get("npc_states", []):
		if npc_state_value is Dictionary and str(npc_state_value.get("character_id", "")) == character_id:
			return bool(npc_state_value.get("discovered", false))
	return false


func _player_tokens(line: String, state: Dictionary) -> String:
	return line.replace("{player_first_name}", str(state.get("player", {}).get("identity", {}).get("first_name", "you")))


func _activity_label(activity: String) -> String:
	return activity.replace("_", " ").capitalize()


func _date_string(clock: Dictionary) -> String:
	return "Y%d-%02d-%02d" % [int(clock.get("year", 1)), int(clock.get("month", 1)), int(clock.get("day", 1))]


func _date_serial(clock: Dictionary) -> int:
	var year: int = int(clock.get("year", 1))
	var month: int = int(clock.get("month", 1))
	var day: int = int(clock.get("day", 1))
	var serial: int = 0
	for previous_year: int in range(1, year):
		serial += 366 if previous_year % 4 == 0 else 365
	for previous_month: int in range(1, month):
		serial += _days_in_month(previous_month, year)
	return serial + day


func _days_in_month(month: int, year: int) -> int:
	match month:
		4, 6, 9, 11:
			return 30
		2:
			return 29 if year % 4 == 0 else 28
		_:
			return 31
