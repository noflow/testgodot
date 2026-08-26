extends RefCounted
class_name PortAlderSimulationEngine

const GameClockScript: GDScript = preload("res://src/simulation/game_clock.gd")
const MAX_EVENT_LOG: int = 500
const RELATIONSHIP_METERS: PackedStringArray = [
	"friendship", "love", "attraction", "lust", "trust", "respect",
	"resentment", "jealousy", "comfort", "commitment", "compatibility", "satisfaction",
]

var _registry: Node
var _clock: RefCounted


func _init(content_registry: Node) -> void:
	_registry = content_registry
	_clock = GameClockScript.new()


func apply_operation(state: Dictionary, operation: String, payload: Dictionary, source: String) -> Dictionary:
	if state.is_empty():
		return _failure("No active runtime state.")
	if _registry.get_content("operations", operation) == null:
		return _failure("Unknown simulation operation: %s" % operation)
	if source.is_empty():
		return _failure("Simulation events require a source.")

	var working_state: Dictionary = state.duplicate(true)
	var error: String = _apply_to_working_state(working_state, operation, payload)
	if not error.is_empty():
		return _failure(error)

	var event: Dictionary = _create_event(working_state, operation, payload, source)
	_append_event(working_state, event)
	return {"ok": true, "state": working_state, "event": event, "errors": PackedStringArray()}


func _apply_to_working_state(state: Dictionary, operation: String, payload: Dictionary) -> String:
	match operation:
		"time.advance":
			return _apply_time_advance(state, payload)
		"need.adjust":
			return _adjust_player_value(state, "needs", payload, "need", 0.0, 100.0)
		"attribute.adjust":
			return _adjust_player_value(state, "attributes", payload, "attribute", 0.0, 250.0)
		"reputation.adjust":
			return _adjust_player_value(state, "reputations", payload, "category", -100.0, 100.0)
		"skill.add_experience":
			return _add_skill_experience(state, payload)
		"relationship.adjust_meter":
			return _adjust_relationship(state, payload)
		"relationship.set_agreement":
			return _set_relationship_agreement(state, payload)
		"relationship.record_date":
			return _record_relationship_date(state, payload)
		"relationship.record_conflict":
			return _record_relationship_conflict(state, payload)
		"economy.transaction":
			return _apply_transaction(state, payload)
		"economy.process_recurring":
			return _record_recurring_transaction(state, payload)
		"inventory.add":
			return _adjust_inventory(state, payload, 1)
		"inventory.remove":
			return _adjust_inventory(state, payload, -1)
		"inventory.equip":
			return _equip_inventory(state, payload)
		"inventory.clean_container":
			return _clean_inventory_container(state, payload)
		"phone.append_message":
			return _append_phone_message(state, payload)
		"phone.mark_thread_read":
			return _mark_phone_thread_read(state, payload)
		"quest.discover":
			return _discover_quest(state, payload)
		"quest.set_available":
			return _set_quest_available(state, payload)
		"quest.accept":
			return _accept_quest(state, payload)
		"quest.postpone":
			return _postpone_quest(state, payload)
		"quest.decline":
			return _decline_quest(state, payload)
		"quest.start":
			return _start_quest(state, payload)
		"quest.set_tracked":
			return _set_quest_tracked(state, payload)
		"quest.objective_complete":
			return _complete_objective(state, payload)
		"quest.complete":
			return _complete_quest(state, payload)
		"quest.fail_or_defer":
			return _fail_or_defer_quest(state, payload)
		"conversation.begin":
			return _begin_conversation(state, payload)
		"conversation.choose":
			return _record_conversation_choice(state, payload)
		"conversation.end":
			return _end_conversation(state, payload)
		"travel.begin":
			return _begin_travel(state, payload)
		"calendar.schedule":
			return _schedule_calendar_event(state, payload)
		"calendar.cancel_or_reschedule":
			return _cancel_or_reschedule_calendar_event(state, payload)
		"calendar.arrival":
			return _complete_calendar_arrival(state, payload)
		"memory.create":
			return _create_memory(state, payload)
		"education.enroll":
			return _apply_education_enrollment(state, payload)
		"education.attendance":
			return _apply_education_attendance(state, payload)
		"education.grade":
			return _apply_education_grade(state, payload)
		"employment.apply":
			return _apply_employment_application(state, payload)
		"employment.interview":
			return _apply_employment_interview(state, payload)
		"employment.accept_offer":
			return _accept_employment_offer(state, payload)
		"employment.shift":
			return _apply_employment_shift(state, payload)
		"economy.payday":
			return _apply_employment_payday(state, payload)
		"housing.acquire":
			return _acquire_housing(state, payload)
		"housing.move":
			return _move_housing(state, payload)
		"employment.promote_or_raise":
			return _apply_employment_career_change(state, payload)
		"travel.complete":
			return _complete_travel(state, payload)
		"world.unlock_location":
			return _unlock_location(state, payload)
		"world.discover_location":
			return _discover_location(state, payload)
		_:
			return "Operation is registered but not implemented yet: %s" % operation


func _apply_time_advance(state: Dictionary, payload: Dictionary) -> String:
	var clock_result: Dictionary = _clock.advance(state["clock"], payload)
	if not clock_result.get("ok", false):
		return str(clock_result.get("error", "Unable to advance time."))

	_apply_passive_needs(state, int(clock_result["minutes_advanced"]))
	_update_weather_for_date(state)
	var simulation: Dictionary = state["simulation"]
	if int(clock_result["days_crossed"]) > 0:
		simulation["last_daily_tick"] = _date_string(state["clock"])
	if int(clock_result["weeks_crossed"]) > 0:
		simulation["last_weekly_tick"] = int(state["clock"]["week_number"])
	if int(clock_result["months_crossed"]) > 0:
		simulation["last_monthly_tick"] = "Y%d-%02d" % [state["clock"]["year"], state["clock"]["month"]]
	return ""


func _update_weather_for_date(state: Dictionary) -> void:
	var opening_week: Variant = _registry.get_package("opening_week_calendar")
	if not opening_week is Dictionary:
		return
	var current_date: String = _date_string(state["clock"])
	for day: Variant in opening_week.get("days", []):
		if day is Dictionary and str(day.get("date", "")) == current_date:
			state["world_state"]["weather"] = day.get("weather", {}).duplicate(true)
			return


func _apply_passive_needs(state: Dictionary, elapsed_minutes: int) -> void:
	var scale: float = float(elapsed_minutes) / 180.0
	var needs: Dictionary = state["player"]["needs"]
	needs["energy"] = clampf(float(needs["energy"]) - 2.0 * scale, 0.0, 100.0)
	needs["fatigue"] = clampf(float(needs["fatigue"]) + 2.0 * scale, 0.0, 100.0)
	needs["hunger"] = clampf(float(needs["hunger"]) + 4.0 * scale, 0.0, 100.0)
	needs["hydration"] = clampf(float(needs["hydration"]) + 5.0 * scale, 0.0, 100.0)
	needs["hygiene"] = clampf(float(needs["hygiene"]) - 1.0 * scale, 0.0, 100.0)


func _adjust_player_value(
	state: Dictionary,
	section_name: String,
	payload: Dictionary,
	value_key: String,
	minimum: float,
	maximum: float
) -> String:
	var field: String = str(payload.get(value_key, ""))
	var section: Dictionary = state["player"].get(section_name, {})
	if not section.has(field):
		return "Unknown %s: %s" % [value_key, field]
	if not payload.get("amount") is int and not payload.get("amount") is float:
		return "%s adjustment requires a numeric amount." % value_key.capitalize()
	section[field] = clampf(float(section[field]) + float(payload["amount"]), minimum, maximum)
	return ""


func _add_skill_experience(state: Dictionary, payload: Dictionary) -> String:
	var skill: String = str(payload.get("skill", ""))
	if skill.is_empty():
		return "Skill experience requires a skill id."
	if not payload.get("experience") is int and not payload.get("experience") is float:
		return "Skill experience must be numeric."
	var added_experience: float = maxf(float(payload["experience"]), 0.0)
	var player: Dictionary = state["player"]
	var skills: Dictionary = player["skills"]
	var experience: Dictionary = player["skill_experience"]
	var level: int = clampi(int(skills.get(skill, 0)), 0, 250)
	var activity_difficulty: int = int(payload.get("activity_difficulty", level))
	if activity_difficulty + 25 < level:
		added_experience *= 0.1
	var stored_experience: float = float(experience.get(skill, 0.0)) + added_experience
	while level < 250:
		var required: float = _experience_for_next_level(level)
		if stored_experience < required:
			break
		if level == 249 and not bool(payload.get("mastery_completed", false)):
			stored_experience = minf(stored_experience, required - 0.01)
			break
		stored_experience -= required
		level += 1
	skills[skill] = level
	experience[skill] = stored_experience
	return ""


func _experience_for_next_level(level: int) -> float:
	return 100.0 + float(level * 20) + float(level * level) * 0.8


func _adjust_relationship(state: Dictionary, payload: Dictionary) -> String:
	var character_id: String = str(payload.get("character_id", ""))
	var meter: String = str(payload.get("meter", ""))
	if not state["relationships"].has(character_id):
		return "Unknown relationship character: %s" % character_id
	if meter not in RELATIONSHIP_METERS:
		return "Unknown relationship meter: %s" % meter
	if not payload.get("amount") is int and not payload.get("amount") is float:
		return "Relationship adjustment requires a numeric amount."
	var relationship: Dictionary = state["relationships"][character_id]
	relationship[meter] = clampf(float(relationship.get(meter, 0.0)) + float(payload["amount"]), 0.0, 100.0)
	return ""


func _set_relationship_agreement(state: Dictionary, payload: Dictionary) -> String:
	var character_id: String = str(payload.get("character_id", ""))
	if not state["relationships"].has(character_id):
		return "Unknown relationship character: %s" % character_id
	var character: Variant = _registry.get_character(character_id)
	if not character is Dictionary or int(character.get("profile", {}).get("age", 0)) < 18 or not bool(character.get("profile", {}).get("romance_eligible", false)):
		return "A dating agreement is unavailable with this character."
	if not bool(payload.get("mutual_acknowledgment", false)):
		return "A dating agreement requires mutual acknowledgment."
	var agreement_value: Variant = payload.get("agreement")
	if not agreement_value is Dictionary:
		return "Dating agreement details are missing."
	var agreement: Dictionary = agreement_value.duplicate(true)
	var agreement_type: String = str(agreement.get("type", ""))
	if agreement_type not in ["casual", "exclusive", "open"]:
		return "Unknown dating agreement: %s" % agreement_type
	agreement["status"] = str(agreement.get("status", "active"))
	agreement["established_on"] = str(agreement.get("established_on", _date_string(state["clock"])))
	agreement["mutual_acknowledgment"] = true
	state["relationships"][character_id]["dating_agreement"] = agreement
	state["relationships"][character_id]["relationship_stage"] = "committed" if agreement_type == "exclusive" else "dating"
	return ""


func _record_relationship_date(state: Dictionary, payload: Dictionary) -> String:
	var character_id: String = str(payload.get("character_id", ""))
	if not state["relationships"].has(character_id):
		return "Unknown relationship character: %s" % character_id
	var character: Variant = _registry.get_character(character_id)
	if not character is Dictionary or int(character.get("profile", {}).get("age", 0)) < 18 or not bool(character.get("profile", {}).get("romance_eligible", false)):
		return "Date history is unavailable with this character."
	var record_value: Variant = payload.get("date_record")
	if not record_value is Dictionary:
		return "Date history requires a record."
	var record: Dictionary = record_value.duplicate(true)
	var record_id: String = str(record.get("id", ""))
	if record_id.is_empty():
		return "Date history requires a unique id."
	var relationship: Dictionary = state["relationships"][character_id]
	if not relationship.has("dating_history"):
		relationship["dating_history"] = []
	for existing: Variant in relationship["dating_history"]:
		if existing is Dictionary and str(existing.get("id", "")) == record_id:
			return "Date history already contains %s." % record_id
	relationship["dating_history"].append(record)
	if str(record.get("outcome", "")) == "completed" and str(relationship.get("relationship_stage", "")) not in ["committed", "ended"]:
		relationship["relationship_stage"] = "dating"
		relationship["romantic_interest_known"] = true
	return ""


func _record_relationship_conflict(state: Dictionary, payload: Dictionary) -> String:
	var character_id: String = str(payload.get("character_id", ""))
	if not state["relationships"].has(character_id):
		return "Unknown relationship character: %s" % character_id
	var record_value: Variant = payload.get("conflict_record")
	if not record_value is Dictionary:
		return "Relationship conflict requires a record."
	var record: Dictionary = record_value.duplicate(true)
	var record_id: String = str(record.get("id", ""))
	if record_id.is_empty():
		return "Relationship conflict requires a unique id."
	var relationship: Dictionary = state["relationships"][character_id]
	if not relationship.has("conflict_history"):
		relationship["conflict_history"] = []
	for existing: Variant in relationship["conflict_history"]:
		if existing is Dictionary and str(existing.get("id", "")) == record_id:
			return "Relationship conflict already contains %s." % record_id
	relationship["conflict_history"].append(record)
	if bool(record.get("relationship_ended", false)):
		relationship["relationship_stage"] = "ended"
		var agreement: Dictionary = relationship.get("dating_agreement", {}).duplicate(true)
		agreement["status"] = "ended"
		agreement["ended_on"] = _date_string(state["clock"])
		agreement["ended_reason"] = record.get("outcome", "conflict")
		relationship["dating_agreement"] = agreement
	return ""


func _apply_transaction(state: Dictionary, payload: Dictionary) -> String:
	var account_id: String = str(payload.get("account", ""))
	var accounts: Dictionary = state["player"]["economy"]["accounts"]
	if not accounts.has(account_id):
		return "Unknown financial account: %s" % account_id
	if not payload.get("amount") is int and not payload.get("amount") is float:
		return "Transaction amount must be numeric."
	var amount: float = float(payload["amount"])
	var new_balance: float = float(accounts[account_id]) + amount
	var minimum_balance: float = 0.0
	var account_definition: Dictionary = _find_by_id(
		_registry.get_package("port_alder_economy_system").get("accounts", []), account_id
	)
	if str(account_definition.get("type", "")) == "credit":
		minimum_balance = -float(account_definition.get("credit_limit", 0.0))
	if new_balance < minimum_balance:
		return "Insufficient funds in %s." % account_id
	accounts[account_id] = new_balance
	var ledger_entry: Dictionary = payload.duplicate(true)
	ledger_entry["balance_after"] = new_balance
	ledger_entry["date"] = str(payload.get("date", _date_string(state["clock"])))
	state["player"]["economy"]["ledger"].append(ledger_entry)
	return ""


func _record_recurring_transaction(state: Dictionary, payload: Dictionary) -> String:
	var record_value: Variant = payload.get("record")
	if not record_value is Dictionary:
		return "Recurring processing requires a transaction record."
	var record: Dictionary = record_value.duplicate(true)
	var record_id: String = str(record.get("id", ""))
	if record_id.is_empty() or str(record.get("rule_id", "")).is_empty():
		return "Recurring transaction identity is invalid."
	for existing: Variant in state["player"]["economy"].get("recurring_transactions", []):
		if existing is Dictionary and str(existing.get("id", "")) == record_id:
			return "Recurring transaction was already processed: %s" % record_id
	state["player"]["economy"]["recurring_transactions"].append(record)
	return ""


func _adjust_inventory(state: Dictionary, payload: Dictionary, direction: int) -> String:
	var container_id: String = str(payload.get("container_id", ""))
	var item_id: String = str(payload.get("item_id", ""))
	var quantity: int = int(payload.get("quantity", 0))
	if quantity <= 0:
		return "Inventory quantity must be positive."
	if _registry.get_content("items", item_id) == null:
		return "Unknown inventory item: %s" % item_id
	var container: Dictionary = _find_container(state, container_id)
	if container.is_empty():
		return "Unknown inventory container: %s" % container_id
	var items: Array = container.get("items", [])
	var stack: Dictionary = _find_item_stack(items, item_id)
	if direction > 0:
		var capacity_error: String = _inventory_capacity_error(container, item_id, quantity)
		if not capacity_error.is_empty():
			return capacity_error
		if stack.is_empty():
			stack = {"item_id": item_id, "quantity": quantity, "item_state": payload.get("item_state", {}).duplicate(true)}
			items.append(stack)
		else:
			stack["quantity"] = int(stack["quantity"]) + quantity
	else:
		if stack.is_empty() or int(stack.get("quantity", 0)) < quantity:
			return "Not enough %s in %s." % [item_id, container_id]
		stack["quantity"] = int(stack["quantity"]) - quantity
		if int(stack["quantity"]) == 0:
			items.erase(stack)
	container["items"] = items
	return ""


func _equip_inventory(state: Dictionary, payload: Dictionary) -> String:
	var item_id: String = str(payload.get("item_id", ""))
	var wardrobe_slot: String = str(payload.get("wardrobe_slot", ""))
	var item: Variant = _registry.get_content("items", item_id)
	if not item is Dictionary or str(item.get("category", "")) != "clothing":
		return "Only a known clothing item can be equipped."
	if str(item.get("slot", "")) != wardrobe_slot:
		return "%s does not fit the %s wardrobe slot." % [item_id, wardrobe_slot]
	var owned: bool = false
	for container: Variant in state["player"]["inventory"].get("containers", []):
		if container is Dictionary and not _find_item_stack(container.get("items", []), item_id).is_empty():
			owned = true
			break
	if not owned:
		return "Clothing item is not owned: %s" % item_id
	state["player"]["inventory"]["equipped_outfit"][wardrobe_slot] = item_id
	return ""


func _clean_inventory_container(state: Dictionary, payload: Dictionary) -> String:
	var container_id: String = str(payload.get("container_id", ""))
	if not payload.get("cleanliness") is int and not payload.get("cleanliness") is float:
		return "Cleaning requires a numeric cleanliness value."
	var container: Dictionary = _find_container(state, container_id)
	if container.is_empty():
		return "Unknown inventory container: %s" % container_id
	var cleaned_items: int = 0
	for stack: Variant in container.get("items", []):
		if not stack is Dictionary:
			continue
		var item: Variant = _registry.get_content("items", str(stack.get("item_id", "")))
		if not item is Dictionary or str(item.get("category", "")) != "clothing":
			continue
		var item_state: Dictionary = stack.get("item_state", {}).duplicate(true)
		item_state["cleanliness"] = clampi(int(payload["cleanliness"]), 0, 100)
		stack["item_state"] = item_state
		cleaned_items += 1
	if cleaned_items == 0:
		return "No clothing is stored in %s." % container_id
	return ""


func _append_phone_message(state: Dictionary, payload: Dictionary) -> String:
	var character_id: String = str(payload.get("character_id", ""))
	if character_id not in state["player"]["phone"].get("known_contacts", []):
		return "Unknown phone contact: %s" % character_id
	var message: Variant = payload.get("message")
	if not message is Dictionary:
		return "Phone message payload is missing."
	var message_id: String = str(message.get("id", ""))
	var sender: String = str(message.get("sender", ""))
	if message_id.is_empty() or str(message.get("text", "")).is_empty():
		return "Phone messages require an id and text."
	if sender != "player" and sender != character_id:
		return "Phone message sender does not match its thread."
	var phone: Dictionary = state["player"]["phone"]
	if not phone.has("message_threads"):
		phone["message_threads"] = {}
	if not phone["message_threads"].has(character_id):
		phone["message_threads"][character_id] = {
			"character_id": character_id, "messages": [], "last_read_sequence": 0,
		}
	var thread: Dictionary = phone["message_threads"][character_id]
	for existing: Variant in thread.get("messages", []):
		if existing is Dictionary and str(existing.get("id", "")) == message_id:
			return "Phone message already exists: %s" % message_id
	var stored: Dictionary = message.duplicate(true)
	stored["timestamp"] = _clock.timestamp(state["clock"])
	stored["thread_sequence"] = thread.get("messages", []).size() + 1
	thread["messages"].append(stored)
	if sender != "player" and character_id not in phone["unread_threads"]:
		phone["unread_threads"].append(character_id)
	return ""


func _mark_phone_thread_read(state: Dictionary, payload: Dictionary) -> String:
	var character_id: String = str(payload.get("character_id", ""))
	var phone: Dictionary = state["player"]["phone"]
	if character_id not in phone.get("known_contacts", []):
		return "Unknown phone contact: %s" % character_id
	var thread: Variant = phone.get("message_threads", {}).get(character_id)
	if not thread is Dictionary:
		return "Missing phone thread: %s" % character_id
	thread["last_read_sequence"] = thread.get("messages", []).size()
	phone["unread_threads"].erase(character_id)
	return ""


func _schedule_calendar_event(state: Dictionary, payload: Dictionary) -> String:
	var event_value: Variant = payload.get("calendar_event")
	if not event_value is Dictionary:
		return "Calendar scheduling requires an event."
	var calendar_event: Dictionary = event_value.duplicate(true)
	var date: String = str(calendar_event.get("date", ""))
	var block: String = str(calendar_event.get("block", ""))
	if not _valid_date_string(date):
		return "Calendar event date is invalid: %s" % date
	if _clock.block_index(block) < 0:
		return "Calendar event has an invalid activity block: %s" % block
	if _date_sort_value(date) < _date_sort_value(_date_string(state["clock"])):
		return "Calendar events cannot be scheduled in the past."
	if date == _date_string(state["clock"]) and _clock.block_index(block) < _clock.block_index(str(state["clock"]["block"])):
		return "Calendar events cannot be scheduled in a completed activity block."
	var participants: Array = calendar_event.get("participants", [])
	for participant: Variant in participants:
		var character_id: String = str(participant)
		if character_id not in state["player"]["phone"].get("known_contacts", []):
			return "Calendar participant is not a known contact: %s" % character_id
		var availability_error: String = _npc_commitment_error(
			character_id, str(calendar_event.get("weekday", "")), block
		)
		if not availability_error.is_empty():
			return availability_error
	var event_id: String = str(calendar_event.get("id", ""))
	if event_id.is_empty():
		event_id = "cal-%08d" % int(state["simulation"].get("next_event_sequence", 1))
	for existing: Variant in state["calendar_state"].get("events", []):
		if not existing is Dictionary:
			continue
		if str(existing.get("id", "")) == event_id:
			return "Calendar event id already exists: %s" % event_id
		if str(existing.get("status", "scheduled")) != "scheduled":
			continue
		if str(existing.get("date", "")) != date or str(existing.get("block", "")) != block:
			continue
		var existing_type: String = str(existing.get("type", ""))
		var new_type: String = str(calendar_event.get("type", ""))
		if existing_type in ["class", "exam", "work", "interview"] or new_type in ["class", "exam", "work", "interview"]:
			return "This time conflicts with a required class, shift, interview, or exam."
		state["calendar_state"]["conflicts"].append({
			"event_ids": [str(existing.get("id", "")), event_id],
			"date": date,
			"block": block,
			"status": "warning",
		})
	calendar_event["id"] = event_id
	calendar_event["status"] = "scheduled"
	calendar_event["created_at"] = _clock.timestamp(state["clock"])
	state["calendar_state"]["events"].append(calendar_event)
	return ""


func _cancel_or_reschedule_calendar_event(state: Dictionary, payload: Dictionary) -> String:
	var event_id: String = str(payload.get("event_id", ""))
	for calendar_event: Variant in state["calendar_state"].get("events", []):
		if not calendar_event is Dictionary or str(calendar_event.get("id", "")) != event_id:
			continue
		if bool(payload.get("cancel", false)) or str(payload.get("new_time_or_cancel", "")) == "cancel":
			calendar_event["status"] = "cancelled"
			calendar_event["cancelled_at"] = _clock.timestamp(state["clock"])
			for conflict: Variant in state["calendar_state"].get("conflicts", []):
				if conflict is Dictionary and event_id in conflict.get("event_ids", []):
					conflict["status"] = "resolved"
			return ""
		return "Calendar rescheduling requires a replacement date and block."
	return "Unknown calendar event: %s" % event_id


func _complete_calendar_arrival(state: Dictionary, payload: Dictionary) -> String:
	var event_id: String = str(payload.get("event_id", ""))
	for calendar_event: Variant in state["calendar_state"].get("events", []):
		if not calendar_event is Dictionary or str(calendar_event.get("id", "")) != event_id:
			continue
		if str(calendar_event.get("status", "scheduled")) != "scheduled":
			return "Calendar event is not currently scheduled: %s" % event_id
		calendar_event["status"] = "completed"
		var arrival_timestamp: Variant = payload.get("arrival_timestamp")
		calendar_event["completed_at"] = _clock.timestamp(state["clock"]) if arrival_timestamp == null else arrival_timestamp
		return ""
	return "Unknown calendar event: %s" % event_id


func _npc_commitment_error(character_id: String, weekday: String, block: String) -> String:
	var character: Variant = _registry.get_character(character_id)
	if not character is Dictionary:
		return "Unknown calendar participant: %s" % character_id
	for commitment: Variant in character.get("schedule", {}).get("fixed_commitments", []):
		if not commitment is Dictionary or not bool(commitment.get("unavailable", false)):
			continue
		if weekday in commitment.get("days", []) and block in commitment.get("blocks", []):
			return "%s is unavailable during %s because of %s." % [
				character.get("display_name", character_id),
				block.replace("_", " ").capitalize(),
				str(commitment.get("activity", "a prior commitment")).replace("_", " "),
			]
	return ""


func _valid_date_string(date: String) -> bool:
	if not date.begins_with("Y"):
		return false
	var parts: PackedStringArray = date.trim_prefix("Y").split("-")
	if parts.size() != 3:
		return false
	if not parts[0].is_valid_int() or not parts[1].is_valid_int() or not parts[2].is_valid_int():
		return false
	var year: int = int(parts[0])
	var month: int = int(parts[1])
	var day: int = int(parts[2])
	return year >= 1 and month >= 1 and month <= 12 and day >= 1 and day <= _days_in_calendar_month(month, year)


func _date_sort_value(date: String) -> int:
	var parts: PackedStringArray = date.trim_prefix("Y").split("-")
	if parts.size() != 3:
		return -1
	return int(parts[0]) * 372 + int(parts[1]) * 31 + int(parts[2])


func _days_in_calendar_month(month: int, year: int) -> int:
	if month in [4, 6, 9, 11]:
		return 30
	if month == 2:
		return 29 if year % 4 == 0 else 28
	return 31


func _start_quest(state: Dictionary, payload: Dictionary) -> String:
	var quest_id: String = str(payload.get("quest_id", ""))
	if _registry.get_content("quests", quest_id) == null:
		return "Unknown quest: %s" % quest_id
	var quest_state: Dictionary = state["quest_state"]
	if quest_id in quest_state["active"] or quest_id in quest_state["completed"]:
		return "Quest is already active or completed: %s" % quest_id
	_ensure_quest_discovery_state(quest_state)
	if quest_id not in quest_state["discovered"]:
		quest_state["discovered"].append(quest_id)
		quest_state["discovery_history"].append({
			"quest_id": quest_id,
			"source": str(payload.get("discovery_source", "direct_path")),
			"discovered_on": _date_string(state["clock"]),
		})
	quest_state["available"].erase(quest_id)
	quest_state["postponed"].erase(quest_id)
	quest_state["deferred"].erase(quest_id)
	quest_state["active"].append(quest_id)
	quest_state["objectives"][quest_id] = {}
	return ""


func _discover_quest(state: Dictionary, payload: Dictionary) -> String:
	var quest_id: String = str(payload.get("quest_id", ""))
	if _registry.get_content("quests", quest_id) == null:
		return "Unknown quest: %s" % quest_id
	var quest_state: Dictionary = state["quest_state"]
	_ensure_quest_discovery_state(quest_state)
	if quest_id in quest_state["completed"] or quest_id in quest_state["failed"] or quest_id in quest_state["deferred"]:
		return "A terminal quest cannot be rediscovered: %s" % quest_id
	if quest_id in quest_state["discovered"]:
		return ""
	quest_state["discovered"].append(quest_id)
	quest_state["discovery_history"].append({
		"quest_id": quest_id,
		"source": str(payload.get("discovery_source", "gameplay")),
		"discovered_on": _date_string(state["clock"]),
	})
	return ""


func _set_quest_available(state: Dictionary, payload: Dictionary) -> String:
	var quest_id: String = str(payload.get("quest_id", ""))
	var quest_state: Dictionary = state["quest_state"]
	_ensure_quest_discovery_state(quest_state)
	if not payload.get("available") is bool:
		return "Quest availability requires a true or false value."
	if quest_id not in quest_state["discovered"]:
		return "Only a discovered quest can become available: %s" % quest_id
	if quest_id in quest_state["active"] or quest_id in quest_state["completed"] or quest_id in quest_state["failed"] or quest_id in quest_state["deferred"]:
		return "A started or terminal quest cannot change offer availability: %s" % quest_id
	if bool(payload["available"]):
		if quest_id not in quest_state["available"]:
			quest_state["available"].append(quest_id)
		if bool(payload.get("reconsider", false)):
			quest_state["postponed"].erase(quest_id)
			quest_state["decision_history"].append({"quest_id": quest_id, "decision": "reconsidered", "source": str(payload.get("decision_source", "gameplay")), "date": _date_string(state["clock"])})
	else:
		quest_state["available"].erase(quest_id)
	return ""


func _accept_quest(state: Dictionary, payload: Dictionary) -> String:
	var quest_id: String = str(payload.get("quest_id", ""))
	var quest_state: Dictionary = state["quest_state"]
	_ensure_quest_discovery_state(quest_state)
	if quest_id not in quest_state["available"]:
		return "Quest is not currently available to accept: %s" % quest_id
	var start_error: String = _start_quest(state, {"quest_id": quest_id})
	if not start_error.is_empty():
		return start_error
	quest_state["decision_history"].append({"quest_id": quest_id, "decision": "accepted", "source": str(payload.get("decision_source", "gameplay")), "date": _date_string(state["clock"])})
	return ""


func _postpone_quest(state: Dictionary, payload: Dictionary) -> String:
	var quest_id: String = str(payload.get("quest_id", ""))
	var quest_state: Dictionary = state["quest_state"]
	_ensure_quest_discovery_state(quest_state)
	if quest_id not in quest_state["available"]:
		return "Quest is not currently available to postpone: %s" % quest_id
	quest_state["available"].erase(quest_id)
	if quest_id not in quest_state["postponed"]:
		quest_state["postponed"].append(quest_id)
	quest_state["decision_history"].append({"quest_id": quest_id, "decision": "postponed", "source": str(payload.get("decision_source", "gameplay")), "date": _date_string(state["clock"])})
	return ""


func _decline_quest(state: Dictionary, payload: Dictionary) -> String:
	var quest_id: String = str(payload.get("quest_id", ""))
	var quest_state: Dictionary = state["quest_state"]
	_ensure_quest_discovery_state(quest_state)
	if quest_id not in quest_state["available"]:
		return "Quest is not currently available to decline: %s" % quest_id
	quest_state["available"].erase(quest_id)
	quest_state["postponed"].erase(quest_id)
	if quest_id not in quest_state["deferred"]:
		quest_state["deferred"].append(quest_id)
	quest_state["decision_history"].append({"quest_id": quest_id, "decision": "declined", "source": str(payload.get("decision_source", "gameplay")), "date": _date_string(state["clock"])})
	return ""


func _ensure_quest_discovery_state(quest_state: Dictionary) -> void:
	for key: String in ["discovered", "available", "postponed", "discovery_history", "decision_history"]:
		if not quest_state.get(key) is Array:
			quest_state[key] = []
	if not quest_state.get("repeatable_progress") is Dictionary:
		quest_state["repeatable_progress"] = {}
	for status: String in ["active", "completed", "failed", "deferred"]:
		for quest_id: Variant in quest_state.get(status, []):
			if quest_id not in quest_state["discovered"]:
				quest_state["discovered"].append(quest_id)


func _set_quest_tracked(state: Dictionary, payload: Dictionary) -> String:
	var quest_id: String = str(payload.get("quest_id", ""))
	var quest_state: Dictionary = state["quest_state"]
	if _registry.get_content("quests", quest_id) == null:
		return "Unknown quest: %s" % quest_id
	if not payload.get("tracked") is bool:
		return "Quest tracking requires a true or false value."
	if not quest_state.get("tracked") is Array:
		quest_state["tracked"] = []
	if bool(payload["tracked"]):
		if quest_id not in quest_state["active"]:
			return "Only an active quest can be tracked: %s" % quest_id
		if quest_id not in quest_state["tracked"]:
			quest_state["tracked"].append(quest_id)
	else:
		quest_state["tracked"].erase(quest_id)
	return ""


func _complete_objective(state: Dictionary, payload: Dictionary) -> String:
	var quest_id: String = str(payload.get("quest_id", ""))
	var objective_id: String = str(payload.get("objective_id", ""))
	var quest_state: Dictionary = state["quest_state"]
	if quest_id not in quest_state["active"]:
		return "Quest is not active: %s" % quest_id
	var quest: Variant = _registry.get_content("quests", quest_id)
	if not quest is Dictionary or not _objective_exists(quest, objective_id):
		return "Unknown objective %s for quest %s." % [objective_id, quest_id]
	if not quest_state["objectives"].has(quest_id):
		quest_state["objectives"][quest_id] = {}
	quest_state["objectives"][quest_id][objective_id] = true
	return ""


func _complete_quest(state: Dictionary, payload: Dictionary) -> String:
	var quest_id: String = str(payload.get("quest_id", ""))
	var quest_state: Dictionary = state["quest_state"]
	if quest_id not in quest_state["active"]:
		return "Quest is not active: %s" % quest_id
	quest_state["active"].erase(quest_id)
	quest_state.get("tracked", []).erase(quest_id)
	quest_state.get("available", []).erase(quest_id)
	quest_state.get("postponed", []).erase(quest_id)
	quest_state["completed"].append(quest_id)
	quest_state["branch_history"].append({
		"quest_id": quest_id,
		"branch_id": payload.get("branch_id"),
		"completed_on": _date_string(state["clock"]),
	})
	return ""


func _fail_or_defer_quest(state: Dictionary, payload: Dictionary) -> String:
	var quest_id: String = str(payload.get("quest_id", ""))
	var result: String = str(payload.get("result", "deferred"))
	var quest_state: Dictionary = state["quest_state"]
	if quest_id not in quest_state["active"]:
		return "Quest is not active: %s" % quest_id
	if result not in ["deferred", "failed"]:
		return "Quest result must be deferred or failed."
	quest_state["active"].erase(quest_id)
	quest_state.get("tracked", []).erase(quest_id)
	quest_state.get("available", []).erase(quest_id)
	quest_state.get("postponed", []).erase(quest_id)
	if quest_id not in quest_state[result]:
		quest_state[result].append(quest_id)
	return ""


func _begin_conversation(state: Dictionary, payload: Dictionary) -> String:
	var conversation_id: String = str(payload.get("conversation_id", ""))
	var start_node: String = str(payload.get("start_node", ""))
	var conversation: Variant = _registry.get_content("conversations", conversation_id)
	if not conversation is Dictionary:
		return "Unknown conversation: %s" % conversation_id
	if not conversation.get("nodes", {}).has(start_node):
		return "Conversation %s has unknown start node %s." % [conversation_id, start_node]
	if state["conversation_state"].get("active") != null:
		return "Another conversation is already active."
	state["conversation_state"]["active"] = {
		"conversation_id": conversation_id,
		"node_id": start_node,
		"applied_nodes": [],
		"choice_history": [],
		"participants": payload.get("participants", []).duplicate(true),
	}
	return ""


func _record_conversation_choice(state: Dictionary, payload: Dictionary) -> String:
	var active: Variant = state["conversation_state"].get("active")
	if not active is Dictionary:
		return "No conversation is active."
	if str(active.get("conversation_id", "")) != str(payload.get("conversation_id", "")):
		return "Conversation choice does not match the active conversation."
	active["choice_history"].append({
		"node_id": payload.get("node_id"),
		"choice_id": payload.get("choice_id"),
	})
	active["node_id"] = payload.get("next_node")
	return ""


func _end_conversation(state: Dictionary, payload: Dictionary) -> String:
	var active: Variant = state["conversation_state"].get("active")
	if not active is Dictionary:
		return "No conversation is active."
	var conversation_id: String = str(active.get("conversation_id", ""))
	if conversation_id != str(payload.get("conversation_id", conversation_id)):
		return "Conversation end does not match the active conversation."
	if conversation_id not in state["conversation_state"]["completed"]:
		state["conversation_state"]["completed"].append(conversation_id)
	var conversation: Dictionary = _registry.get_content("conversations", conversation_id)
	if bool(conversation.get("repetition", {}).get("once_only", false)):
		var once_flag: String = "conversation:%s" % conversation_id
		if once_flag not in state["conversation_state"]["once_only_flags"]:
			state["conversation_state"]["once_only_flags"].append(once_flag)
	state["conversation_state"]["active"] = null
	return ""


func _create_memory(state: Dictionary, payload: Dictionary) -> String:
	var character_id: String = str(payload.get("character_id", ""))
	var memory_id: String = str(payload.get("memory_id", ""))
	if not state["relationships"].has(character_id):
		return "Unknown memory owner: %s" % character_id
	if memory_id.is_empty():
		return "Memory requires an id."
	var relationship: Dictionary = state["relationships"][character_id]
	if not relationship.has("memories"):
		relationship["memories"] = []
	for memory: Variant in relationship["memories"]:
		if memory is Dictionary and str(memory.get("id", "")) == memory_id:
			return ""
	relationship["memories"].append({
		"id": memory_id,
		"importance": payload.get("importance", 50),
		"tags": payload.get("tags", []).duplicate(true),
		"created_on": _date_string(state["clock"]),
	})
	return ""


func _apply_education_enrollment(state: Dictionary, payload: Dictionary) -> String:
	var program_id: String = str(payload.get("program", ""))
	if _registry.get_content("programs", program_id) == null:
		return "Unknown education program: %s" % program_id
	var load_id: String = str(payload.get("load", ""))
	if load_id not in ["full_time", "part_time"]:
		return "Education enrollment requires a full-time or part-time load."
	var courses: Array = payload.get("courses", [])
	if courses.is_empty():
		return "Education enrollment requires at least one course."
	for course_id_value: Variant in courses:
		if _registry.get_content("courses", str(course_id_value)) == null:
			return "Unknown enrolled course: %s" % course_id_value
	var education: Dictionary = state["player"]["education"]
	education["institution"] = "westshore_college"
	education["program"] = program_id
	education["course_load"] = load_id
	education["courses"] = courses.duplicate(true)
	education["tuition_plan"] = payload.get("tuition_plan")
	education["enrolled"] = true
	education["enrollment_date"] = _date_string(state["clock"])
	return ""


func _apply_education_attendance(state: Dictionary, payload: Dictionary) -> String:
	var course_id: String = str(payload.get("course_id", ""))
	if course_id not in state["player"]["education"].get("courses", []):
		return "This course is not part of the active enrollment: %s" % course_id
	var attendance_value: Variant = payload.get("attendance_record")
	if not attendance_value is Dictionary:
		return "Education attendance requires an attendance record."
	var attendance_record: Dictionary = attendance_value.duplicate(true)
	var record_id: String = str(attendance_record.get("id", ""))
	var event_id: String = str(attendance_record.get("calendar_event_id", ""))
	var attendance_status: String = str(attendance_record.get("status", payload.get("status", "")))
	if record_id.is_empty() or event_id.is_empty() or attendance_status not in ["present", "late", "absent"]:
		return "Education attendance identity or status is invalid."
	for existing: Variant in state["player"]["education"].get("attendance_history", []):
		if existing is Dictionary and str(existing.get("id", "")) == record_id:
			return "Education attendance was already recorded: %s" % record_id
	var calendar_event: Dictionary = {}
	for event_value: Variant in state["calendar_state"].get("events", []):
		if event_value is Dictionary and str(event_value.get("id", "")) == event_id:
			calendar_event = event_value
			break
	if calendar_event.is_empty() or str(calendar_event.get("course_id", "")) != course_id:
		return "Education attendance has an invalid calendar event."
	if str(calendar_event.get("status", "scheduled")) != "scheduled":
		return "Education calendar event is no longer scheduled: %s" % event_id
	if not state["player"]["education"].get("attendance") is Dictionary:
		state["player"]["education"]["attendance"] = {}
	if not state["player"]["education"]["attendance"].has(course_id):
		state["player"]["education"]["attendance"][course_id] = {"attended": 0, "late": 0, "absent": 0}
	var counters: Dictionary = state["player"]["education"]["attendance"][course_id]
	var counter_key: String = "attended" if attendance_status == "present" else attendance_status
	counters[counter_key] = int(counters.get(counter_key, 0)) + 1
	state["player"]["education"]["attendance_history"].append(attendance_record)
	calendar_event["status"] = "missed" if attendance_status == "absent" else "completed"
	calendar_event["attendance"] = attendance_status
	calendar_event["performance"] = float(attendance_record.get("performance", payload.get("performance", 0.0)))
	calendar_event["completed_at"] = _clock.timestamp(state["clock"])
	return ""


func _apply_education_grade(state: Dictionary, payload: Dictionary) -> String:
	var course_id: String = str(payload.get("course_id", ""))
	if course_id not in state["player"]["education"].get("courses", []):
		return "This course is not part of the active enrollment: %s" % course_id
	var result_value: Variant = payload.get("assessment_result")
	if not result_value is Dictionary:
		return "Education grading requires an assessment result."
	var assessment_result: Dictionary = result_value.duplicate(true)
	var assessment_id: String = str(assessment_result.get("assessment_id", payload.get("assessment", "")))
	var result_id: String = str(assessment_result.get("id", ""))
	if result_id.is_empty() or assessment_id.is_empty() or str(assessment_result.get("course_id", "")) != course_id:
		return "Education assessment result identity is invalid."
	if not payload.get("score") is int and not payload.get("score") is float:
		return "Education assessment scores must be numeric."
	assessment_result["score"] = clampf(float(payload["score"]), 0.0, 100.0)
	var assessment: Dictionary = {}
	for assessment_value: Variant in state["player"]["education"].get("assessments", []):
		if assessment_value is Dictionary and str(assessment_value.get("id", "")) == assessment_id:
			assessment = assessment_value
			break
	if assessment.is_empty() or str(assessment.get("course_id", "")) != course_id:
		return "Unknown course assessment: %s" % assessment_id
	if str(assessment.get("status", "scheduled")) != "scheduled":
		return "Course assessment is already resolved: %s" % assessment_id
	for existing: Variant in state["player"]["education"].get("assessment_results", []):
		if existing is Dictionary and str(existing.get("id", "")) == result_id:
			return "Education assessment result was already recorded: %s" % result_id
	var result_status: String = str(assessment_result.get("status", "completed"))
	if result_status not in ["completed", "missed"]:
		return "Unknown education assessment result: %s" % result_status
	assessment["status"] = result_status
	assessment["score"] = assessment_result["score"]
	assessment["resolved_at"] = _clock.timestamp(state["clock"])
	state["player"]["education"]["assessment_results"].append(assessment_result)
	var calendar_event_id: String = str(assessment.get("calendar_event_id", ""))
	for event_value: Variant in state["calendar_state"].get("events", []):
		if event_value is Dictionary and str(event_value.get("id", "")) == calendar_event_id:
			event_value["status"] = "missed" if result_status == "missed" else "completed"
			event_value["score"] = assessment_result["score"]
			event_value["completed_at"] = _clock.timestamp(state["clock"])
			break
	return ""


func _apply_employment_application(state: Dictionary, payload: Dictionary) -> String:
	var job_id: String = str(payload.get("job_id", ""))
	if _registry.get_content("jobs", job_id) == null:
		return "Unknown job listing: %s" % job_id
	for existing: Variant in state["player"]["employment"].get("applications", []):
		if existing is Dictionary and str(existing.get("job_id", "")) == job_id and str(existing.get("stage", "")) not in ["rejected", "declined", "withdrawn"]:
			return "An active application already exists for this job."
	var application_value: Variant = payload.get("application")
	if not application_value is Dictionary:
		return "Employment applications require an application record."
	var application: Dictionary = application_value.duplicate(true)
	if str(application.get("id", "")).is_empty() or str(application.get("job_id", "")) != job_id:
		return "Employment application identity is invalid."
	state["player"]["employment"]["applications"].append(application)
	var interview_value: Variant = payload.get("interview")
	if interview_value is Dictionary:
		state["player"]["employment"]["interviews"].append(interview_value.duplicate(true))
	return ""


func _apply_employment_interview(state: Dictionary, payload: Dictionary) -> String:
	var application_id: String = str(payload.get("application_id", ""))
	var application: Dictionary = _find_employment_record(state["player"]["employment"].get("applications", []), application_id)
	if application.is_empty():
		return "Unknown employment application: %s" % application_id
	if str(application.get("stage", "")) != "interview_scheduled":
		return "This application is not ready for an interview."
	var interview_id: String = str(payload.get("interview_id", ""))
	var interview: Dictionary = _find_employment_record(state["player"]["employment"].get("interviews", []), interview_id)
	if interview.is_empty():
		return "Unknown scheduled interview: %s" % interview_id
	interview["status"] = "completed"
	interview["completed_at"] = _clock.timestamp(state["clock"])
	interview["score"] = float(payload.get("score", 0.0))
	interview["score_breakdown"] = payload.get("score_breakdown", {}).duplicate(true)
	interview["outcome"] = payload.get("outcome", "rejected")
	application["interview_score"] = interview["score"]
	application["interview_outcome"] = interview["outcome"]
	var offer_value: Variant = payload.get("offer")
	if offer_value is Dictionary:
		application["stage"] = "offer_received"
		application["offer"] = offer_value.duplicate(true)
	elif str(payload.get("outcome", "")) == "waitlisted":
		application["stage"] = "waitlisted"
	else:
		application["stage"] = "rejected"
		application["rejected_on"] = _date_string(state["clock"])
	return ""


func _accept_employment_offer(state: Dictionary, payload: Dictionary) -> String:
	var application_id: String = str(payload.get("application_id", ""))
	var application: Dictionary = _find_employment_record(state["player"]["employment"].get("applications", []), application_id)
	if application.is_empty() or str(application.get("stage", "")) != "offer_received":
		return "This application has no active offer."
	var offer: Dictionary = application.get("offer", {})
	if str(offer.get("status", "offered")) != "offered":
		return "This offer is no longer available."
	var active_job_value: Variant = payload.get("active_job")
	if not active_job_value is Dictionary:
		return "Accepting an offer requires a job contract."
	var active_job: Dictionary = active_job_value.duplicate(true)
	if str(active_job.get("job_id", "")) != str(application.get("job_id", "")):
		return "The job contract does not match the offer."
	for existing_job: Variant in state["player"]["employment"].get("active_jobs", []):
		if existing_job is Dictionary and str(existing_job.get("job_id", "")) == str(active_job.get("job_id", "")):
			return "This job is already active."
	offer["status"] = "accepted"
	offer["accepted_at"] = _clock.timestamp(state["clock"])
	application["stage"] = "accepted"
	application["accepted_schedule_id"] = active_job.get("schedule_id")
	state["player"]["employment"]["active_jobs"].append(active_job)
	state["player"]["employment"]["employed"] = true
	return ""


func _apply_employment_shift(state: Dictionary, payload: Dictionary) -> String:
	var job_id: String = str(payload.get("job_id", ""))
	var active_job: Dictionary = _active_employment_job(state, job_id)
	if active_job.is_empty():
		return "This job is not active: %s" % job_id
	var shift_value: Variant = payload.get("shift_record")
	if not shift_value is Dictionary:
		return "Employment shifts require a shift record."
	var shift: Dictionary = shift_value.duplicate(true)
	var shift_id: String = str(shift.get("id", ""))
	if shift_id.is_empty() or str(shift.get("job_id", "")) != job_id:
		return "Employment shift identity is invalid."
	for existing: Variant in state["player"]["employment"].get("work_history", []):
		if existing is Dictionary and str(existing.get("id", "")) == shift_id:
			return "Employment shift was already recorded: %s" % shift_id
	var calendar_event_ids: Array = shift.get("calendar_event_ids", [])
	if calendar_event_ids.is_empty():
		return "Employment shifts require scheduled calendar events."
	for event_id_value: Variant in calendar_event_ids:
		var calendar_event: Dictionary = _find_employment_record(state["calendar_state"].get("events", []), str(event_id_value))
		if calendar_event.is_empty() or str(calendar_event.get("job_id", "")) != job_id:
			return "Employment shift has an invalid calendar event."
		if str(calendar_event.get("status", "scheduled")) != "scheduled":
			return "Employment calendar event is no longer scheduled: %s" % event_id_value
	var attendance: String = str(shift.get("attendance", "absent"))
	if attendance not in ["present", "late", "absent"]:
		return "Unknown shift attendance result: %s" % attendance
	for event_id_value: Variant in calendar_event_ids:
		var calendar_event: Dictionary = _find_employment_record(state["calendar_state"]["events"], str(event_id_value))
		calendar_event["status"] = "missed" if attendance == "absent" else "completed"
		calendar_event["attendance"] = attendance
		calendar_event["completed_at"] = _clock.timestamp(state["clock"])
	state["player"]["employment"]["work_history"].append(shift)
	if not active_job.has("shift_history"):
		active_job["shift_history"] = []
	active_job["shift_history"].append(shift_id)
	active_job["shifts_completed"] = int(active_job.get("shifts_completed", 0)) + (0 if attendance == "absent" else 1)
	active_job["shifts_missed"] = int(active_job.get("shifts_missed", 0)) + (1 if attendance == "absent" else 0)
	active_job["late_shifts"] = int(active_job.get("late_shifts", 0)) + (1 if attendance == "late" else 0)
	active_job["hours_worked_total"] = float(active_job.get("hours_worked_total", 0.0)) + float(shift.get("hours_worked", 0.0))
	active_job["performance"] = clampf(float(shift.get("performance_after", active_job.get("performance", 50.0))), 0.0, 100.0)
	active_job["last_shift_date"] = shift.get("date")
	var pending: Dictionary = active_job.get("pending_pay", {}).duplicate(true)
	pending["hours"] = float(pending.get("hours", 0.0)) + float(shift.get("hours_worked", 0.0))
	pending["overtime_hours"] = float(pending.get("overtime_hours", 0.0)) + float(shift.get("overtime_hours", 0.0))
	pending["gross_wages"] = float(pending.get("gross_wages", 0.0)) + float(shift.get("gross_wages", 0.0))
	pending["tips"] = float(pending.get("tips", 0.0)) + float(shift.get("tips", 0.0))
	active_job["pending_pay"] = pending
	return ""


func _apply_employment_payday(state: Dictionary, payload: Dictionary) -> String:
	var job_id: String = str(payload.get("job_id", ""))
	var active_job: Dictionary = _active_employment_job(state, job_id)
	if active_job.is_empty():
		return "This job is not active: %s" % job_id
	var pay_value: Variant = payload.get("pay_record")
	if not pay_value is Dictionary:
		return "Payday requires a payroll record."
	var pay_record: Dictionary = pay_value.duplicate(true)
	var net: float = float(pay_record.get("net", 0.0))
	if net < 0.0:
		return "Net pay cannot be negative."
	var transaction_error: String = _apply_transaction(state, {
		"id": pay_record.get("id", "payday-%s" % job_id),
		"timestamp": _clock.timestamp(state["clock"]),
		"type": "income",
		"amount": net,
		"account": "checking",
		"description": "Paycheck — %s" % active_job.get("employer", job_id),
		"category": "employment",
		"job_id": job_id,
		"gross": pay_record.get("gross", 0.0),
		"tips": pay_record.get("tips", 0.0),
		"withholding": pay_record.get("withholding", 0.0),
		"date": pay_record.get("pay_date", _date_string(state["clock"])),
	})
	if not transaction_error.is_empty():
		return transaction_error
	if not state["player"]["employment"].has("payroll_history"):
		state["player"]["employment"]["payroll_history"] = []
	state["player"]["employment"]["payroll_history"].append(pay_record)
	if not active_job.has("payroll_history"):
		active_job["payroll_history"] = []
	active_job["payroll_history"].append(str(pay_record.get("id", "")))
	active_job["lifetime_gross"] = float(active_job.get("lifetime_gross", 0.0)) + float(pay_record.get("gross", 0.0)) + float(pay_record.get("tips", 0.0))
	active_job["lifetime_net"] = float(active_job.get("lifetime_net", 0.0)) + net
	active_job["pending_pay"] = {"hours": 0.0, "overtime_hours": 0.0, "gross_wages": 0.0, "tips": 0.0}
	active_job["next_payday"] = payload.get("next_payday")
	return ""


func _apply_employment_career_change(state: Dictionary, payload: Dictionary) -> String:
	var job_id: String = str(payload.get("job_id", ""))
	var active_job: Dictionary = _active_employment_job(state, job_id)
	if active_job.is_empty():
		return "This job is not active: %s" % job_id
	var change_type: String = str(payload.get("change_type", ""))
	if change_type not in ["raise", "promotion"]:
		return "Career changes must be a raise or promotion."
	var new_pay_value: Variant = payload.get("new_pay")
	if not new_pay_value is int and not new_pay_value is float:
		return "Career changes require numeric pay."
	var new_pay: float = float(new_pay_value)
	if new_pay <= float(active_job.get("hourly_pay", 0.0)):
		return "Career change pay must increase."
	var history_entry: Dictionary = {
		"id": payload.get("change_id", "career-change-%s-%d" % [job_id, active_job.get("career_history", []).size() + 1]),
		"type": change_type,
		"date": _date_string(state["clock"]),
		"old_title": active_job.get("title", ""),
		"new_title": payload.get("new_title", active_job.get("title", "")),
		"old_pay": active_job.get("hourly_pay", 0.0),
		"new_pay": new_pay,
		"performance": active_job.get("performance", 50.0),
	}
	if not active_job.has("career_history"):
		active_job["career_history"] = []
	active_job["career_history"].append(history_entry)
	active_job["hourly_pay"] = new_pay
	if change_type == "promotion":
		active_job["title"] = payload.get("new_title", active_job.get("title", ""))
		active_job["career_level"] = int(active_job.get("career_level", 0)) + 1
		active_job["pending_promotion"] = null
	return ""


func _active_employment_job(state: Dictionary, job_id: String) -> Dictionary:
	for active_job: Variant in state["player"]["employment"].get("active_jobs", []):
		if active_job is Dictionary and str(active_job.get("job_id", "")) == job_id and str(active_job.get("status", "active")) == "active":
			return active_job
	return {}


func _find_employment_record(records: Array, record_id: String) -> Dictionary:
	for record: Variant in records:
		if record is Dictionary and str(record.get("id", "")) == record_id:
			return record
	return {}


func _complete_travel(state: Dictionary, payload: Dictionary) -> String:
	var destination: String = str(payload.get("destination", ""))
	var location_id: String = destination.get_slice(".", 0)
	var pending_value: Variant = state["world_state"].get("pending_travel")
	var pending: Dictionary = pending_value if pending_value is Dictionary else {}
	if not pending.is_empty():
		if str(pending.get("destination", "")) != location_id or str(pending.get("mode", "")) != str(payload.get("mode", "")):
			return "Completed travel does not match the pending trip."
		if int(pending.get("minutes", 0)) != int(payload.get("minutes", 0)) or not is_equal_approx(float(pending.get("cost", 0.0)), float(payload.get("cost", 0.0))):
			return "Completed travel time or cost does not match the confirmed route."
	var location: Variant = _registry.get_location(location_id)
	if not location is Dictionary:
		return "Unknown travel destination: %s" % destination
	if destination.contains("."):
		var room_id: String = destination.get_slice(".", 1)
		if not _room_exists(location, room_id):
			return "Unknown room at travel destination: %s" % destination
	var cost: float = float(payload.get("cost", 0.0))
	if cost < 0.0:
		return "Travel cost cannot be negative."
	if cost > 0.0:
		var transaction_error: String = _apply_transaction(state, {
			"account": payload.get("account", "wallet_cash"),
			"amount": -cost,
			"type": "debit",
			"category": "transportation",
			"description": "Travel to %s" % destination,
		})
		if not transaction_error.is_empty():
			return transaction_error
	var minutes: int = int(payload.get("minutes", 0)) + int(payload.get("delay", 0))
	if minutes <= 0:
		return "Travel must consume positive time."
	var time_error: String = _apply_time_advance(state, {"minutes": minutes})
	if not time_error.is_empty():
		return time_error
	state["world_state"]["current_location"] = destination
	state["world_state"]["last_trip"] = {
		"origin": payload.get("origin", pending.get("origin", "")),
		"destination": destination,
		"mode": payload.get("mode", pending.get("mode", "")),
		"minutes": minutes,
		"cost": cost,
		"route_ids": Array(payload.get("route_ids", [])).duplicate(true),
	}
	state["world_state"]["pending_travel"] = null
	if location_id not in state["world_state"]["discovered_locations"]:
		state["world_state"]["discovered_locations"].append(location_id)
	return ""


func _begin_travel(state: Dictionary, payload: Dictionary) -> String:
	if state["world_state"].get("pending_travel") is Dictionary:
		return "Another trip is already in progress."
	var origin: String = str(payload.get("origin", ""))
	var destination: String = str(payload.get("destination", ""))
	var mode: String = str(payload.get("mode", ""))
	var current_root: String = str(state["world_state"].get("current_location", "")).get_slice(".", 0)
	if origin != current_root:
		return "Travel origin does not match the current location."
	if _registry.get_location(destination) == null:
		return "Unknown travel destination: %s" % destination
	if destination not in state["world_state"].get("unlocked_locations", []):
		return "Travel destination is still locked: %s" % destination
	var transportation: Variant = _registry.get_package("port_alder_initial_transportation")
	if not transportation is Dictionary or _find_by_id(transportation.get("modes", []), mode).is_empty():
		return "Unknown transportation mode: %s" % mode
	if mode == "car" and not bool(state["player"]["transportation"].get("license", false)):
		return "A driver's license is required."
	if mode == "car" and float(state["player"]["needs"].get("inebriation", 0.0)) >= 25.0:
		return "Driving is blocked while impaired."
	var route: Variant = payload.get("route")
	if not route is Dictionary or int(route.get("minutes", 0)) <= 0 or float(route.get("cost", -1.0)) < 0.0:
		return "Travel requires a valid planned route."
	state["world_state"]["pending_travel"] = {
		"origin": origin,
		"destination": destination,
		"mode": mode,
		"minutes": route.get("minutes", 0),
		"cost": route.get("cost", 0.0),
		"route_ids": Array(route.get("route_ids", [])).duplicate(true),
	}
	return ""


func _unlock_location(state: Dictionary, payload: Dictionary) -> String:
	var location_id: String = str(payload.get("location_id", ""))
	if _registry.get_location(location_id) == null:
		return "Unknown location: %s" % location_id
	if location_id not in state["world_state"]["unlocked_locations"]:
		state["world_state"]["unlocked_locations"].append(location_id)
	return ""


func _discover_location(state: Dictionary, payload: Dictionary) -> String:
	var location_id: String = str(payload.get("location_id", ""))
	var location: Variant = _registry.get_location(location_id)
	if not location is Dictionary:
		return "Unknown location: %s" % location_id
	var discovery: Dictionary = location.get("discovery", {})
	if not bool(discovery.get("discoverable", true)):
		return "This location cannot be discovered through gameplay: %s" % location_id
	var discovery_source: String = str(payload.get("discovery_source", "quest"))
	var allowed_sources: Array = discovery.get("sources", [])
	if not allowed_sources.is_empty() and discovery_source not in allowed_sources:
		return "The %s source cannot reveal %s." % [discovery_source, location_id]
	var world: Dictionary = state["world_state"]
	for collection_name: String in ["unlocked_locations", "discovered_locations"]:
		if location_id not in world[collection_name]:
			world[collection_name].append(location_id)
	if not world.get("location_access") is Dictionary:
		world["location_access"] = {}
	var record: Dictionary = world["location_access"].get(location_id, {})
	if not record.get("sources") is Array:
		record["sources"] = []
	if discovery_source not in record["sources"]:
		record["sources"].append(discovery_source)
	record["discovered_at"] = record.get("discovered_at", _clock.timestamp(state["clock"]))
	var granted_by: String = str(payload.get("character_id", ""))
	if not granted_by.is_empty():
		if not record.get("granted_by") is Array:
			record["granted_by"] = []
		if granted_by not in record["granted_by"]:
			record["granted_by"].append(granted_by)
	if not record.get("room_grants") is Array:
		record["room_grants"] = []
	for room_id_value: Variant in payload.get("room_ids", []):
		var room_id: String = str(room_id_value)
		if not _room_exists(location, room_id):
			return "Unknown room access grant: %s.%s" % [location_id, room_id]
		if room_id not in record["room_grants"]:
			record["room_grants"].append(room_id)
	world["location_access"][location_id] = record
	return ""


func _acquire_housing(state: Dictionary, payload: Dictionary) -> String:
	var listing_id: String = str(payload.get("listing_id", ""))
	var listing: Variant = _registry.get_content("housing_listings", listing_id)
	var contract_value: Variant = payload.get("contract")
	if not listing is Dictionary:
		return "Unknown housing listing: %s" % listing_id
	if not contract_value is Dictionary:
		return "Housing acquisition requires a contract."
	var housing: Dictionary = state["player"]["housing"]
	for key: String in ["contracts", "leases", "owned_properties", "move_history", "payment_history"]:
		if not housing.get(key) is Array:
			housing[key] = []
	for existing_value: Variant in housing["contracts"]:
		if existing_value is Dictionary and str(existing_value.get("listing_id", "")) == listing_id and str(existing_value.get("status", "active")) == "active":
			return "This residence is already in your housing portfolio."
	var contract: Dictionary = contract_value.duplicate(true)
	var contract_id: String = str(contract.get("id", ""))
	if contract_id.is_empty():
		return "Housing contract requires an id."
	housing["contracts"].append(contract)
	if str(contract.get("tenure", "rental")) == "purchase":
		housing["owned_properties"].append({
			"listing_id": listing_id,
			"contract_id": contract_id,
			"location_id": contract.get("location_id", ""),
			"acquired_on": contract.get("acquired_on", ""),
			"purchase_price": contract.get("purchase_price", 0.0),
			"mortgage_balance": contract.get("mortgage_balance", 0.0),
		})
	else:
		housing["leases"].append({
			"listing_id": listing_id,
			"contract_id": contract_id,
			"location_id": contract.get("location_id", ""),
			"status": "active",
			"started_on": contract.get("acquired_on", ""),
			"monthly_rent": contract.get("base_rent", 0.0),
		})
	var location_id: String = str(contract.get("location_id", ""))
	if not location_id.is_empty() and location_id not in state["world_state"]["unlocked_locations"]:
		state["world_state"]["unlocked_locations"].append(location_id)
	return ""


func _move_housing(state: Dictionary, payload: Dictionary) -> String:
	var listing_id: String = str(payload.get("listing_id", ""))
	var residence: String = str(payload.get("residence", ""))
	var room: String = str(payload.get("room", ""))
	var household_value: Variant = payload.get("household")
	var location: Variant = _registry.get_location(residence)
	if not location is Dictionary or not household_value is Dictionary:
		return "Housing move requires a valid residence and household."
	if room.get_slice(".", 0) != residence or not _room_exists(location, room.get_slice(".", 1)):
		return "Housing move has an invalid destination room."
	var housing: Dictionary = state["player"]["housing"]
	if listing_id != "family_home":
		var owns_access: bool = false
		for contract_value: Variant in housing.get("contracts", []):
			if contract_value is Dictionary and str(contract_value.get("listing_id", "")) == listing_id and str(contract_value.get("status", "active")) == "active":
				owns_access = true
				break
		if not owns_access:
			return "Acquire this residence before moving into it."
	if str(housing.get("residence", "hale_home")) == "hale_home" and residence != "hale_home" and housing.get("family_household_snapshot") == null:
		housing["family_household_snapshot"] = state["household_state"].duplicate(true)
	if str(housing.get("residence", "hale_home")) == "hale_home" and residence != "hale_home" and housing.get("family_housing_snapshot") == null:
		housing["family_housing_snapshot"] = {
			"monthly_rent": housing.get("monthly_rent", 0.0),
			"monthly_housing_cost": housing.get("monthly_housing_cost", housing.get("monthly_rent", 0.0)),
			"monthly_utilities": housing.get("monthly_utilities", 0.0),
			"rent_first_due": housing.get("rent_first_due", "Y1-09-01"),
			"guest_permissions": housing.get("guest_permissions", "ask_household"),
			"assigned_chores": Array(housing.get("assigned_chores", [])).duplicate(true),
		}
	if not housing.get("move_history") is Array:
		housing["move_history"] = []
	var move_record: Variant = payload.get("move_record")
	if move_record is Dictionary:
		housing["move_history"].append(move_record.duplicate(true))
	state["household_state"] = household_value.duplicate(true)
	housing["residence"] = residence
	housing["room"] = room
	housing["household"] = state["household_state"].get("household_id", "")
	housing["tenure"] = payload.get("tenure", "family_home")
	housing["active_listing_id"] = null if listing_id == "family_home" else listing_id
	housing["monthly_rent"] = maxf(float(payload.get("monthly_rent", 0.0)), 0.0)
	housing["monthly_housing_cost"] = maxf(float(payload.get("monthly_housing_cost", 0.0)), 0.0)
	housing["monthly_utilities"] = maxf(float(payload.get("monthly_utilities", 0.0)), 0.0)
	housing["guest_permissions"] = payload.get("guest_permissions", "player_controls")
	housing["assigned_chores"] = Array(payload.get("assigned_chores", [])).duplicate(true)
	if payload.has("rent_first_due"):
		housing["rent_first_due"] = payload["rent_first_due"]
	var storage_access: Variant = payload.get("storage_access")
	if storage_access is Dictionary:
		for container_value: Variant in state["player"]["inventory"].get("containers", []):
			if not container_value is Dictionary:
				continue
			var container_id: String = str(container_value.get("id", ""))
			if storage_access.has(container_id):
				container_value["access"] = storage_access[container_id]
	state["world_state"]["current_location"] = room
	for world_key: String in ["unlocked_locations", "discovered_locations"]:
		if residence not in state["world_state"][world_key]:
			state["world_state"][world_key].append(residence)
	return ""


func _create_event(state: Dictionary, operation: String, payload: Dictionary, source: String) -> Dictionary:
	var sequence: int = int(state["simulation"].get("next_event_sequence", 1))
	state["simulation"]["next_event_sequence"] = sequence + 1
	return {
		"event_id": "evt-%08d" % sequence,
		"sequence": sequence,
		"game_timestamp": _clock.timestamp(state["clock"]),
		"operation": operation,
		"source": source,
		"payload": payload.duplicate(true),
	}


func _append_event(state: Dictionary, event: Dictionary) -> void:
	var log: Array = state["simulation"]["recent_event_log"]
	log.append(event)
	while log.size() > MAX_EVENT_LOG:
		log.pop_front()


func _find_container(state: Dictionary, container_id: String) -> Dictionary:
	for container: Variant in state["player"]["inventory"].get("containers", []):
		if container is Dictionary and str(container.get("id", "")) == container_id:
			return container
	return {}


func _find_item_stack(items: Array, item_id: String) -> Dictionary:
	for stack: Variant in items:
		if stack is Dictionary and str(stack.get("item_id", "")) == item_id:
			return stack
	return {}


func _inventory_capacity_error(container: Dictionary, added_item_id: String, added_quantity: int) -> String:
	var total_weight: float = 0.0
	var used_slots: int = 0
	var matched_existing_stack: bool = false
	for stack: Variant in container.get("items", []):
		if not stack is Dictionary:
			continue
		var item: Variant = _registry.get_content("items", str(stack.get("item_id", "")))
		if not item is Dictionary:
			continue
		var quantity: int = int(stack.get("quantity", 0))
		if str(stack.get("item_id", "")) == added_item_id:
			quantity += added_quantity
			matched_existing_stack = true
		total_weight += float(item.get("weight", 0.0)) * quantity
		used_slots += ceili(float(quantity) / maxf(float(item.get("stack_limit", 1)), 1.0))
	var added_item: Dictionary = _registry.get_content("items", added_item_id)
	if not matched_existing_stack:
		total_weight += float(added_item.get("weight", 0.0)) * added_quantity
		used_slots += ceili(float(added_quantity) / maxf(float(added_item.get("stack_limit", 1)), 1.0))
	if total_weight > float(container.get("capacity_weight", 0.0)):
		return "Inventory container %s exceeds its weight capacity." % container.get("id", "")
	if used_slots > int(container.get("capacity_slots", 0)):
		return "Inventory container %s has no free slots." % container.get("id", "")
	return ""


func _find_by_id(entries: Array, content_id: String) -> Dictionary:
	for entry: Variant in entries:
		if entry is Dictionary and str(entry.get("id", "")) == content_id:
			return entry
	return {}


func _room_exists(location: Dictionary, room_id: String) -> bool:
	for room: Variant in location.get("rooms", []):
		if room is Dictionary and str(room.get("id", "")) == room_id:
			return true
	return false


func _objective_exists(quest: Dictionary, objective_id: String) -> bool:
	for objective: Variant in quest.get("objectives", []):
		if objective is Dictionary and str(objective.get("id", "")) == objective_id:
			return true
	return false


func _date_string(clock: Dictionary) -> String:
	return "Y%d-%02d-%02d" % [clock["year"], clock["month"], clock["day"]]


func _failure(message: String) -> Dictionary:
	return {"ok": false, "errors": PackedStringArray([message])}
