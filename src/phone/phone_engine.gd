extends RefCounted
class_name PortAlderPhoneEngine

const GameClockScript: GDScript = preload("res://src/simulation/game_clock.gd")

var _registry: Node
var _simulation: RefCounted


func _init(content_registry: Node, simulation_engine: RefCounted) -> void:
	_registry = content_registry
	_simulation = simulation_engine


func sync_triggered_messages(state: Dictionary) -> Dictionary:
	var working: Dictionary = state.duplicate(true)
	var events: Array = []
	for character_id_value: Variant in working["player"]["phone"].get("known_contacts", []):
		var character_id: String = str(character_id_value)
		var character: Variant = _registry.get_character(character_id)
		if not character is Dictionary:
			continue
		for definition: Variant in character.get("text_messages", []):
			if not definition is Dictionary or not _trigger_met(working, definition.get("trigger", {})):
				continue
			if _thread_has_message(working, character_id, str(definition.get("id", ""))):
				continue
			var result: Dictionary = _simulation.apply_operation(
				working,
				"phone.append_message",
				{
					"character_id": character_id,
					"message": {
						"id": definition.get("id"),
						"sender": character_id,
						"text": definition.get("text", ""),
						"authored": true,
					},
				},
				"phone.trigger"
			)
			if not result.get("ok", false):
				return result
			working = result["state"]
			events.append(result["event"])
	return _success(working, events)


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
				"id": "reply-%s" % message_id,
				"sender": "player",
				"text": reply.get("text", ""),
				"tone": reply.get("tone", []).duplicate(true),
				"reply_to": message_id,
			},
		},
		"phone.reply:%s" % message_id,
		events
	)
	if not result.get("ok", false):
		return result
	working = result["state"]
	var scheduler_participant: String = ""
	for effect: Variant in reply.get("effects", []):
		if not effect is Dictionary:
			continue
		match str(effect.get("operation", "")):
			"add_meter":
				result = _apply(
					working,
					"relationship.adjust_meter",
					{
						"character_id": effect.get("character"),
						"meter": effect.get("meter"),
						"amount": effect.get("value", 0),
						"reason": "phone_reply",
					},
					"phone.reply:%s" % message_id,
					events
				)
				if not result.get("ok", false):
					return result
				working = result["state"]
			"open_calendar_scheduler":
				scheduler_participant = str(effect.get("participant", character_id))
			"set_quest_state":
				result = _apply(
					working,
					"quest.fail_or_defer",
					{
						"quest_id": effect.get("quest"),
						"result": effect.get("value", "deferred"),
						"reason": "phone_reply",
					},
					"phone.reply:%s" % message_id,
					events
				)
				if not result.get("ok", false):
					return result
				working = result["state"]
	result = _complete_text_objectives(working, message_id, events)
	if not result.get("ok", false):
		return result
	working = result["state"]
	var success: Dictionary = _success(working, events)
	success["scheduler_participant"] = scheduler_participant
	return success


func mark_thread_read(state: Dictionary, character_id: String) -> Dictionary:
	return _simulation.apply_operation(
		state,
		"phone.mark_thread_read",
		{"character_id": character_id},
		"phone.thread_read"
	)


func _complete_text_objectives(state: Dictionary, message_id: String, events: Array) -> Dictionary:
	var working: Dictionary = state
	for quest_id_value: Variant in working["quest_state"].get("active", []).duplicate():
		var quest_id: String = str(quest_id_value)
		var quest: Variant = _registry.get_content("quests", quest_id)
		if not quest is Dictionary:
			continue
		for objective: Variant in quest.get("objectives", []):
			if not objective is Dictionary:
				continue
			var completion: Dictionary = objective.get("completion", {})
			if str(completion.get("event", "")) != "text_replied" or str(completion.get("thread", "")) != message_id:
				continue
			var objective_id: String = str(objective.get("id", ""))
			if bool(working["quest_state"].get("objectives", {}).get(quest_id, {}).get(objective_id, false)):
				continue
			var result: Dictionary = _apply(
				working,
				"quest.objective_complete",
				{"quest_id": quest_id, "objective_id": objective_id},
				"phone.reply:%s" % message_id,
				events
			)
			if not result.get("ok", false):
				return result
			working = result["state"]
	return _success(working, events)


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


func _trigger_met(state: Dictionary, trigger: Dictionary) -> bool:
	if bool(trigger.get("sandbox_activated", false)):
		return bool(state["player"]["flags"].get("sandbox.active", false))
	if trigger.has("quest_started"):
		return str(trigger["quest_started"]) in state["quest_state"]["active"]
	if trigger.has("objective_completed"):
		var objective: Array = trigger["objective_completed"]
		return objective.size() == 2 and bool(
			state["quest_state"].get("objectives", {}).get(str(objective[0]), {}).get(str(objective[1]), false)
		)
	if trigger.has("hours_after_quest"):
		var after: Array = trigger["hours_after_quest"]
		if after.size() != 2 or str(after[0]) not in state["quest_state"]["completed"]:
			return false
		return _minutes_since_quest(state, str(after[0])) >= int(after[1]) * 60
	if trigger.has("hours_before_calendar_event"):
		var before: Array = trigger["hours_before_calendar_event"]
		return before.size() == 2 and _minutes_until_event(state, str(before[0])) in range(0, int(before[1]) * 60 + 1)
	return false


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


func _thread_has_message(state: Dictionary, character_id: String, message_id: String) -> bool:
	var thread: Variant = state["player"]["phone"].get("message_threads", {}).get(character_id)
	if not thread is Dictionary:
		return false
	for message: Variant in thread.get("messages", []):
		if message is Dictionary and str(message.get("id", "")) == message_id:
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


func _success(state: Dictionary, events: Array = []) -> Dictionary:
	return {"ok": true, "state": state, "events": events, "errors": PackedStringArray()}


func _failure(message: String) -> Dictionary:
	return {"ok": false, "errors": PackedStringArray([message])}
