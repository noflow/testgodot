extends RefCounted
class_name PortAlderPhoneEngine

const GameClockScript: GDScript = preload("res://src/simulation/game_clock.gd")
const QuestEngineScript: GDScript = preload("res://src/quests/quest_engine.gd")
const SUPPORTED_TRIGGER_KEYS: PackedStringArray = [
	"sandbox_activated", "quest_started", "objective_completed", "hours_after_quest",
	"hours_before_calendar_event", "message_sent", "message_replied", "reply_selected",
	"days", "blocks", "flag", "flag_not", "meter_at_least", "meter_at_most",
]

var _registry: Node
var _simulation: RefCounted
var _quests: RefCounted


func _init(content_registry: Node, simulation_engine: RefCounted) -> void:
	_registry = content_registry
	_simulation = simulation_engine
	_quests = QuestEngineScript.new(content_registry, simulation_engine)


func sync_triggered_messages(state: Dictionary) -> Dictionary:
	var working: Dictionary = state.duplicate(true)
	var events: Array = []
	var delivered_in_pass: bool = true
	var pass_count: int = 0
	while delivered_in_pass and pass_count < 100:
		delivered_in_pass = false
		pass_count += 1
		for npc_state: Variant in working.get("npc_states", []):
			if not npc_state is Dictionary:
				continue
			var character_id: String = str(npc_state.get("character_id", ""))
			var character: Variant = _registry.get_character(character_id)
			if not character is Dictionary:
				continue
			for definition_value: Variant in character.get("text_messages", []):
				if not definition_value is Dictionary:
					continue
				var definition: Dictionary = definition_value
				if _message_direction(definition, character_id) != "incoming":
					continue
				var message_id: String = str(definition.get("id", ""))
				if _thread_has_message(working, character_id, message_id):
					continue
				var known_contact: bool = character_id in working["player"]["phone"].get("known_contacts", [])
				if not known_contact and not bool(definition.get("introduces_contact", false)):
					continue
				if not _trigger_met(working, definition.get("trigger", {}), character_id):
					continue
				if not _conditions_met(working, definition.get("conditions", []), character_id):
					continue
				var result: Dictionary
				if not known_contact:
					result = _apply(working, "phone.add_contact", {
						"character_id": character_id,
						"source": "message:%s" % message_id,
					}, "phone.introduce:%s" % message_id, events)
					if not result.get("ok", false):
						return result
					working = result["state"]
				result = _apply(
					working,
					"phone.append_message",
					{
						"character_id": character_id,
						"message": {
							"id": message_id,
							"sender": character_id,
							"text": definition.get("text", ""),
							"authored": true,
							"direction": "incoming",
						},
					},
					"phone.trigger:%s" % message_id,
					events
				)
				if not result.get("ok", false):
					return result
				working = result["state"]
				delivered_in_pass = true
	return _success(working, events)


func available_outgoing_messages(state: Dictionary, character_id: String) -> Array:
	if character_id not in state["player"]["phone"].get("known_contacts", []):
		return []
	var available: Array = []
	var character: Variant = _registry.get_character(character_id)
	if not character is Dictionary:
		return available
	for definition_value: Variant in character.get("text_messages", []):
		if not definition_value is Dictionary:
			continue
		var definition: Dictionary = definition_value
		if _message_direction(definition, character_id) != "outgoing":
			continue
		if _thread_has_message(state, character_id, str(definition.get("id", ""))):
			continue
		if not _trigger_met(state, definition.get("trigger", {}), character_id):
			continue
		if not _conditions_met(state, definition.get("conditions", []), character_id):
			continue
		available.append(definition.duplicate(true))
	return available


func available_replies(state: Dictionary, character_id: String, message_id: String) -> Array:
	var definition: Dictionary = _find_message_definition(character_id, message_id)
	if definition.is_empty() or not _thread_has_message(state, character_id, message_id):
		return []
	if _thread_has_reply(state, character_id, message_id):
		return []
	var available: Array = []
	var replies: Array = definition.get("quick_replies", [])
	for reply_index: int in replies.size():
		var reply: Variant = replies[reply_index]
		if not reply is Dictionary or not _conditions_met(state, reply.get("conditions", []), character_id):
			continue
		var entry: Dictionary = reply.duplicate(true)
		entry["index"] = reply_index
		entry["id"] = str(reply.get("id", "reply_%d" % reply_index))
		available.append(entry)
	return available


func send_outgoing_message(state: Dictionary, character_id: String, message_id: String) -> Dictionary:
	var definition: Dictionary = _find_message_definition(character_id, message_id)
	if definition.is_empty() or _message_direction(definition, character_id) != "outgoing":
		return _failure("Unknown outgoing phone message: %s" % message_id)
	var allowed: bool = false
	for candidate: Variant in available_outgoing_messages(state, character_id):
		if candidate is Dictionary and str(candidate.get("id", "")) == message_id:
			allowed = true
			break
	if not allowed:
		return _failure("This outgoing message is not currently available.")

	var working: Dictionary = state
	var events: Array = []
	var result: Dictionary = _apply(working, "time.advance", {"minutes": 5}, "phone.send:%s" % message_id, events)
	if not result.get("ok", false):
		return result
	working = result["state"]
	result = _apply(working, "phone.append_message", {
		"character_id": character_id,
		"message": {
			"id": message_id,
			"sender": "player",
			"text": definition.get("text", ""),
			"authored": true,
			"direction": "outgoing",
		},
	}, "phone.send:%s" % message_id, events)
	if not result.get("ok", false):
		return result
	working = result["state"]
	var effects_result: Dictionary = _apply_phone_effects(
		working, definition.get("effects", []), character_id, "phone.send:%s" % message_id, events
	)
	if not effects_result.get("ok", false):
		return effects_result
	working = effects_result["state"]
	result = _record_text_event(working, "text_sent", {
		"character": character_id,
		"message": message_id,
		"thread": message_id,
	}, "phone.send:%s" % message_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	var sync_result: Dictionary = sync_triggered_messages(working)
	if not sync_result.get("ok", false):
		return sync_result
	events.append_array(sync_result.get("events", []))
	var success: Dictionary = _success(sync_result["state"], events)
	success["scheduler_participant"] = effects_result.get("scheduler_participant", "")
	success["rescheduler_event"] = effects_result.get("rescheduler_event", "")
	return success


func reply_to_message(state: Dictionary, character_id: String, message_id: String, reply_index: int) -> Dictionary:
	var definition: Dictionary = _find_message_definition(character_id, message_id)
	if definition.is_empty():
		return _failure("Unknown authored phone message: %s" % message_id)
	var replies: Array = definition.get("quick_replies", [])
	if reply_index < 0 or reply_index >= replies.size() or not replies[reply_index] is Dictionary:
		return _failure("Unknown quick reply.")
	if not _thread_has_message(state, character_id, message_id):
		return _failure("The message has not been received yet.")
	if _thread_has_reply(state, character_id, message_id):
		return _failure("This message has already been answered.")
	var reply_available: bool = false
	for available_reply: Variant in available_replies(state, character_id, message_id):
		if available_reply is Dictionary and int(available_reply.get("index", -1)) == reply_index:
			reply_available = true
			break
	if not reply_available:
		return _failure("This quick reply is currently locked.")

	var reply: Dictionary = replies[reply_index]
	var working: Dictionary = state.duplicate(true)
	var events: Array = []
	var result: Dictionary = _apply(
		working,
		"time.advance",
		{"minutes": 5},
		"phone.reply:%s" % message_id,
		events
	)
	if not result.get("ok", false):
		return result
	working = result["state"]
	result = _apply(
		working,
		"phone.append_message",
		{
			"character_id": character_id,
			"message": {
				"id": "reply-%s-%s" % [message_id, str(reply.get("id", "reply_%d" % reply_index))],
				"sender": "player",
				"text": reply.get("text", ""),
				"tone": reply.get("tone", []).duplicate(true),
				"reply_to": message_id,
				"reply_id": str(reply.get("id", "reply_%d" % reply_index)),
			},
		},
		"phone.reply:%s" % message_id,
		events
	)
	if not result.get("ok", false):
		return result
	working = result["state"]
	var effects_result: Dictionary = _apply_phone_effects(
		working, reply.get("effects", []), character_id, "phone.reply:%s" % message_id, events
	)
	if not effects_result.get("ok", false):
		return effects_result
	working = effects_result["state"]
	var reply_id: String = str(reply.get("id", "reply_%d" % reply_index))
	result = _record_text_event(working, "text_replied", {
		"character": character_id,
		"message": message_id,
		"thread": message_id,
		"reply": reply_id,
	}, "phone.reply:%s" % message_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	result = _record_text_event(working, "text_thread_completed", {
		"character": character_id,
		"message": message_id,
		"thread": message_id,
		"reply": reply_id,
	}, "phone.reply:%s" % message_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	var sync_result: Dictionary = sync_triggered_messages(working)
	if not sync_result.get("ok", false):
		return sync_result
	events.append_array(sync_result.get("events", []))
	var success: Dictionary = _success(sync_result["state"], events)
	success["scheduler_participant"] = effects_result.get("scheduler_participant", "")
	success["rescheduler_event"] = effects_result.get("rescheduler_event", "")
	return success


func mark_thread_read(state: Dictionary, character_id: String) -> Dictionary:
	return _simulation.apply_operation(
		state,
		"phone.mark_thread_read",
		{"character_id": character_id},
		"phone.thread_read"
	)


func _apply_phone_effects(
	state: Dictionary,
	effects: Array,
	character_id: String,
	source: String,
	events: Array
) -> Dictionary:
	var working: Dictionary = state
	var scheduler_participant: String = ""
	var rescheduler_event: String = ""
	for effect_value: Variant in effects:
		if not effect_value is Dictionary:
			continue
		var effect: Dictionary = effect_value
		var result: Dictionary
		match str(effect.get("operation", "")):
			"add_meter":
				result = _apply(working, "relationship.adjust_meter", {
					"character_id": effect.get("character", character_id),
					"meter": effect.get("meter"),
					"amount": effect.get("value", effect.get("amount", 0)),
					"reason": "phone_message",
				}, source, events)
			"start_quest":
				result = _quests.start_quest(working, str(effect.get("quest", effect.get("value", ""))), source)
			"complete_objective":
				result = _quests.complete_objective(
					working,
					str(effect.get("quest", "")),
					str(effect.get("objective", "")),
					source
				)
			"complete_quest":
				result = _quests.complete_quest(working, str(effect.get("quest", effect.get("value", ""))), source)
			"set_quest_state":
				result = _apply(working, "quest.fail_or_defer", {
					"quest_id": effect.get("quest"),
					"result": effect.get("value", "deferred"),
					"reason": "phone_message",
				}, source, events)
			"set_flag":
				var flagged: Dictionary = working.duplicate(true)
				flagged["player"]["flags"][str(effect.get("key", ""))] = effect.get("value", true)
				result = _success(flagged)
			"set_value":
				var changed: Dictionary = working.duplicate(true)
				_set_state_value(changed, str(effect.get("key", "")), effect.get("value"))
				result = _success(changed)
			"open_calendar_scheduler":
				scheduler_participant = str(effect.get("participant", character_id))
				result = _success(working)
			"open_calendar_rescheduler":
				rescheduler_event = str(effect.get("event", effect.get("value", "")))
				result = _success(working)
			_:
				return _failure("Unsupported phone effect: %s" % effect.get("operation", ""))
		if not result.get("ok", false):
			return result
		working = result["state"]
	var success: Dictionary = _success(working, events)
	success["scheduler_participant"] = scheduler_participant
	success["rescheduler_event"] = rescheduler_event
	return success


func _record_text_event(state: Dictionary, event_name: String, payload: Dictionary, source: String) -> Dictionary:
	return _quests.record_event(state, event_name, payload, source)


func _apply(
	state: Dictionary,
	operation: String,
	payload: Dictionary,
	source: String,
	events: Array
) -> Dictionary:
	var result: Dictionary = _simulation.apply_operation(state, operation, payload, source)
	if result.get("ok", false):
		events.append(result["event"])
	return result


func _trigger_met(state: Dictionary, trigger: Dictionary, owner_id: String) -> bool:
	for trigger_key: Variant in trigger.keys():
		if str(trigger_key) not in SUPPORTED_TRIGGER_KEYS:
			return false
	if trigger.has("days"):
		var days: Array = trigger["days"] if trigger["days"] is Array else [trigger["days"]]
		if str(state["clock"].get("weekday", "")) not in days:
			return false
	if trigger.has("blocks"):
		var blocks: Array = trigger["blocks"] if trigger["blocks"] is Array else [trigger["blocks"]]
		if str(state["clock"].get("block", "")) not in blocks:
			return false
	if trigger.has("flag") and not _flag_is_set(state, str(trigger["flag"])):
		return false
	if trigger.has("flag_not") and _flag_is_set(state, str(trigger["flag_not"])):
		return false
	for key: String in ["meter_at_least", "meter_at_most"]:
		if trigger.has(key) and not _meter_condition_met(state, trigger[key], owner_id, key == "meter_at_least"):
			return false

	var has_primary_trigger: bool = false
	if trigger.has("sandbox_activated"):
		has_primary_trigger = true
		if bool(trigger["sandbox_activated"]) != bool(state["player"]["flags"].get("sandbox.active", false)):
			return false
	if trigger.has("quest_started"):
		has_primary_trigger = true
		if str(trigger["quest_started"]) not in state["quest_state"]["active"]:
			return false
	if trigger.has("objective_completed"):
		has_primary_trigger = true
		var objective: Variant = trigger["objective_completed"]
		if not objective is Array or objective.size() != 2 or not bool(
			state["quest_state"].get("objectives", {}).get(str(objective[0]), {}).get(str(objective[1]), false)
		):
			return false
	if trigger.has("hours_after_quest"):
		has_primary_trigger = true
		var after: Variant = trigger["hours_after_quest"]
		if not after is Array or after.size() != 2 or str(after[0]) not in state["quest_state"]["completed"]:
			return false
		if _minutes_since_quest(state, str(after[0])) < int(after[1]) * 60:
			return false
	if trigger.has("hours_before_calendar_event"):
		has_primary_trigger = true
		var before: Variant = trigger["hours_before_calendar_event"]
		if not before is Array or before.size() != 2:
			return false
		var minutes_until: int = _minutes_until_event(state, str(before[0]))
		if minutes_until < 0 or minutes_until > int(before[1]) * 60:
			return false
	if trigger.has("message_sent"):
		has_primary_trigger = true
		var sent_ref: Dictionary = _message_trigger_reference(trigger["message_sent"], owner_id)
		if sent_ref.is_empty() or not _thread_has_message(state, sent_ref["character"], sent_ref["message"], "player"):
			return false
	if trigger.has("message_replied"):
		has_primary_trigger = true
		var replied_ref: Dictionary = _message_trigger_reference(trigger["message_replied"], owner_id)
		if replied_ref.is_empty() or not _thread_has_reply(state, replied_ref["character"], replied_ref["message"]):
			return false
	if trigger.has("reply_selected"):
		has_primary_trigger = true
		var selected: Variant = trigger["reply_selected"]
		if not selected is Array or selected.size() != 2 or not _thread_has_selected_reply(
			state, owner_id, str(selected[0]), str(selected[1])
		):
			return false
	return has_primary_trigger or trigger.is_empty() or _trigger_has_only_gates(trigger)


func _trigger_has_only_gates(trigger: Dictionary) -> bool:
	for key: Variant in trigger.keys():
		if str(key) not in ["days", "blocks", "flag", "flag_not", "meter_at_least", "meter_at_most"]:
			return false
	return true


func _message_trigger_reference(value: Variant, owner_id: String) -> Dictionary:
	if value is String:
		return {"character": owner_id, "message": value}
	if value is Array and value.size() == 2:
		return {"character": str(value[0]), "message": str(value[1])}
	return {}


func _conditions_met(state: Dictionary, conditions_value: Variant, owner_id: String) -> bool:
	if conditions_value == null:
		return true
	if not conditions_value is Array:
		return false
	for condition_value: Variant in conditions_value:
		if not condition_value is Dictionary or condition_value.is_empty():
			return false
		var condition: Dictionary = condition_value
		var recognized: int = 0
		if condition.has("flag"):
			recognized += 1
			if not _flag_is_set(state, str(condition["flag"])):
				return false
		if condition.has("flag_not"):
			recognized += 1
			if _flag_is_set(state, str(condition["flag_not"])):
				return false
		if condition.has("value_equals"):
			recognized += 1
			var comparison: Variant = condition["value_equals"]
			if not comparison is Array or comparison.size() != 2 or _get_state_value(state, str(comparison[0])) != comparison[1]:
				return false
		for key: String in ["meter_at_least", "meter_at_most"]:
			if not condition.has(key):
				continue
			recognized += 1
			if not _meter_condition_met(state, condition[key], owner_id, key == "meter_at_least"):
				return false
		if recognized != condition.size():
			return false
	return true


func _meter_condition_met(state: Dictionary, rule_value: Variant, owner_id: String, at_least: bool) -> bool:
	if not rule_value is Array or rule_value.size() not in [2, 3]:
		return false
	var character_id: String = owner_id if rule_value.size() == 2 else str(rule_value[0])
	var meter: String = str(rule_value[0] if rule_value.size() == 2 else rule_value[1])
	var target: float = float(rule_value[1] if rule_value.size() == 2 else rule_value[2])
	var relationship: Variant = state.get("relationships", {}).get(character_id)
	if not relationship is Dictionary or not relationship.has(meter):
		return false
	return float(relationship[meter]) >= target if at_least else float(relationship[meter]) <= target


func _flag_is_set(state: Dictionary, key: String) -> bool:
	var flags: Dictionary = state.get("player", {}).get("flags", {})
	if flags.has(key):
		return _truthy(flags[key])
	return _truthy(_get_state_value(state, key))


func _truthy(value: Variant) -> bool:
	if value is bool:
		return value
	if value is int or value is float:
		return float(value) != 0.0
	if value is String:
		return not value.is_empty()
	return value != null


func _set_state_value(state: Dictionary, path: String, value: Variant) -> void:
	if path.begins_with("education.") or path.begins_with("employment.") or path.begins_with("fitness.") or path.begins_with("economy."):
		path = "player.%s" % path
	var parts: PackedStringArray = path.split(".")
	if parts.is_empty() or path.is_empty():
		return
	var current: Dictionary = state
	for index: int in range(parts.size() - 1):
		if not current.get(parts[index]) is Dictionary:
			current[parts[index]] = {}
		current = current[parts[index]]
	current[parts[-1]] = value


func _get_state_value(state: Dictionary, path: String) -> Variant:
	var flags: Dictionary = state.get("player", {}).get("flags", {})
	if flags.has(path):
		return flags[path]
	if path.begins_with("education.") or path.begins_with("employment.") or path.begins_with("fitness.") or path.begins_with("economy."):
		path = "player.%s" % path
	var current: Variant = state
	for part: String in path.split("."):
		if not current is Dictionary or not current.has(part):
			return null
		current = current[part]
	return current


func _minutes_since_quest(state: Dictionary, quest_id: String) -> int:
	for index: int in range(state["simulation"].get("recent_event_log", []).size() - 1, -1, -1):
		var event: Variant = state["simulation"]["recent_event_log"][index]
		if event is Dictionary and str(event.get("operation", "")) == "quest.complete" and str(event.get("payload", {}).get("quest_id", "")) == quest_id:
			return _clock_serial_minutes(state["clock"]) - _timestamp_serial_minutes(str(event.get("game_timestamp", "")))
	return 0


func _minutes_until_event(state: Dictionary, event_id: String) -> int:
	for calendar_event: Variant in state["calendar_state"].get("events", []):
		if calendar_event is Dictionary and str(calendar_event.get("id", "")) == event_id and str(calendar_event.get("status", "scheduled")) == "scheduled":
			return _calendar_event_serial_minutes(calendar_event) - _clock_serial_minutes(state["clock"])
	return -1


func _clock_serial_minutes(clock: Dictionary) -> int:
	return _date_serial_days(int(clock["year"]), int(clock["month"]), int(clock["day"])) * 1440 + _block_start_minutes(str(clock["block"])) + int(clock["minute_within_block"])


func _timestamp_serial_minutes(timestamp: String) -> int:
	var pieces: PackedStringArray = timestamp.split(":")
	if pieces.size() != 2:
		return 0
	var date_parts: PackedStringArray = pieces[0].trim_prefix("Y").split("-")
	var block_parts: PackedStringArray = pieces[1].split("+")
	if date_parts.size() != 3 or block_parts.size() != 2:
		return 0
	return _date_serial_days(int(date_parts[0]), int(date_parts[1]), int(date_parts[2])) * 1440 + _block_start_minutes(block_parts[0]) + int(block_parts[1])


func _calendar_event_serial_minutes(calendar_event: Dictionary) -> int:
	var parts: PackedStringArray = str(calendar_event.get("date", "")).trim_prefix("Y").split("-")
	if parts.size() != 3:
		return 0
	return _date_serial_days(int(parts[0]), int(parts[1]), int(parts[2])) * 1440 + _block_start_minutes(str(calendar_event.get("block", "early_morning")))


func _date_serial_days(year: int, month: int, day: int) -> int:
	var days: int = (year - 1) * 365
	for previous_month: int in range(1, month):
		days += _days_in_month(previous_month, year)
	return days + day - 1


func _days_in_month(month: int, year: int) -> int:
	if month in [4, 6, 9, 11]:
		return 30
	if month == 2:
		return 29 if year % 4 == 0 else 28
	return 31


func _block_start_minutes(block: String) -> int:
	var minutes: int = 0
	for candidate: String in GameClockScript.BLOCKS:
		if candidate == block:
			break
		minutes += int(GameClockScript.BLOCK_MINUTES[candidate])
	return minutes


func _find_message_definition(character_id: String, message_id: String) -> Dictionary:
	var character: Variant = _registry.get_character(character_id)
	if not character is Dictionary:
		return {}
	for definition: Variant in character.get("text_messages", []):
		if definition is Dictionary and str(definition.get("id", "")) == message_id:
			return definition
	return {}


func _thread_has_message(state: Dictionary, character_id: String, message_id: String, sender: String = "") -> bool:
	var thread: Variant = state["player"]["phone"].get("message_threads", {}).get(character_id)
	if not thread is Dictionary:
		return false
	for message: Variant in thread.get("messages", []):
		if message is Dictionary and str(message.get("id", "")) == message_id and (sender.is_empty() or str(message.get("sender", "")) == sender):
			return true
	return false


func _thread_has_reply(state: Dictionary, character_id: String, message_id: String) -> bool:
	var thread: Variant = state["player"]["phone"].get("message_threads", {}).get(character_id)
	if not thread is Dictionary:
		return false
	for message: Variant in thread.get("messages", []):
		if message is Dictionary and str(message.get("reply_to", "")) == message_id:
			return true
	return false


func _thread_has_selected_reply(state: Dictionary, character_id: String, message_id: String, reply_id: String) -> bool:
	var thread: Variant = state["player"]["phone"].get("message_threads", {}).get(character_id)
	if not thread is Dictionary:
		return false
	for message: Variant in thread.get("messages", []):
		if not message is Dictionary:
			continue
		if str(message.get("reply_to", "")) == message_id and str(message.get("reply_id", "")) == reply_id:
			return true
	return false


func _message_direction(definition: Dictionary, owner_id: String) -> String:
	var direction: String = str(definition.get("direction", ""))
	if direction in ["incoming", "outgoing"]:
		return direction
	return "outgoing" if str(definition.get("sender", owner_id)) == "player" else "incoming"


func _success(state: Dictionary, events: Array = []) -> Dictionary:
	return {"ok": true, "state": state, "events": events, "errors": PackedStringArray()}


func _failure(message: String) -> Dictionary:
	return {"ok": false, "errors": PackedStringArray([message])}
