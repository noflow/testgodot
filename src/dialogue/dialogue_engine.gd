extends RefCounted
class_name PortAlderDialogueEngine

var _registry: Node
var _simulation: RefCounted
var _quests: RefCounted


func _init(content_registry: Node, simulation_engine: RefCounted, quest_engine: RefCounted) -> void:
	_registry = content_registry
	_simulation = simulation_engine
	_quests = quest_engine


func begin(state: Dictionary, conversation_id: String) -> Dictionary:
	var conversation: Variant = _registry.get_content("conversations", conversation_id)
	if not conversation is Dictionary:
		return _failure("Unknown conversation: %s" % conversation_id)
	var activation_error: String = _activation_error(state, conversation)
	if not activation_error.is_empty():
		return _failure(activation_error)
	if "conversation:%s" % conversation_id in state["conversation_state"]["once_only_flags"]:
		return _failure("This conversation can only occur once.")
	var result: Dictionary = _simulation.apply_operation(
		state,
		"conversation.begin",
		{
			"conversation_id": conversation_id,
			"start_node": conversation["start_node"],
			"participants": _conversation_participants(conversation),
		},
		"dialogue.begin"
	)
	if not result.get("ok", false):
		return result
	var working: Dictionary = result["state"]
	for participant: Variant in _conversation_participants(conversation):
		var character_id: String = str(participant)
		if character_id == "player" or _registry.get_character(character_id) == null:
			continue
		var encounter_result: Dictionary = _quests.record_event(working, "npc_encounter_started", {
			"character": character_id,
			"location": str(working["world_state"].get("current_location", "")),
		}, "dialogue.begin:%s" % conversation_id)
		if not encounter_result.get("ok", false):
			return encounter_result
		working = encounter_result["state"]
	return _enter_node(working, conversation, str(conversation["start_node"]))


func can_begin(state: Dictionary, conversation_id: String) -> Dictionary:
	var conversation: Variant = _registry.get_content("conversations", conversation_id)
	if not conversation is Dictionary:
		return {"ok": false, "reason": "Unknown conversation: %s" % conversation_id}
	if state.get("conversation_state", {}).get("active") is Dictionary:
		return {"ok": false, "reason": "Another conversation is already active."}
	if "conversation:%s" % conversation_id in state["conversation_state"]["once_only_flags"]:
		return {"ok": false, "reason": "This conversation can only occur once."}
	var activation_error: String = _activation_error(state, conversation)
	return {"ok": activation_error.is_empty(), "reason": activation_error}


func resume(state: Dictionary) -> Dictionary:
	var active: Variant = state.get("conversation_state", {}).get("active")
	if not active is Dictionary:
		return _failure("No conversation is active.")
	var conversation: Variant = _registry.get_content("conversations", str(active.get("conversation_id", "")))
	if not conversation is Dictionary:
		return _failure("The active conversation content is unavailable.")
	return _success(state, _make_view(state, conversation))


func advance(state: Dictionary) -> Dictionary:
	var context: Dictionary = _active_context(state)
	if context.is_empty():
		return _failure("No conversation is active.")
	var conversation: Dictionary = context["conversation"]
	var node: Dictionary = context["node"]
	if not node.get("branches", []).is_empty():
		return _resolve_automatic_branch(state, conversation, node)
	if not _visible_choices(state, node).is_empty():
		return _failure("A dialogue choice is required.")
	var next_node: Variant = node.get("next")
	if next_node == null:
		return _finish(state, conversation)
	return _transition(state, conversation, str(next_node), "__continue__")


func choose(state: Dictionary, choice_id: String) -> Dictionary:
	var context: Dictionary = _active_context(state)
	if context.is_empty():
		return _failure("No conversation is active.")
	var conversation: Dictionary = context["conversation"]
	var node: Dictionary = context["node"]
	var choice: Dictionary = {}
	for candidate: Variant in _visible_choices(state, node):
		if candidate is Dictionary and str(candidate.get("id", "")) == choice_id:
			choice = candidate
			break
	if choice.is_empty():
		return _failure("Dialogue choice is unavailable: %s" % choice_id)

	var original: Dictionary = state
	var working: Dictionary = state.duplicate(true)
	var effects_result: Dictionary = _apply_effects(
		working,
		choice.get("effects", []),
		"dialogue.choice:%s:%s" % [conversation["id"], choice_id]
	)
	if not effects_result.get("ok", false):
		return _failure(str(effects_result.get("errors", ["Choice effect failed."])[0]), original)
	working = effects_result["state"]
	return _transition(working, conversation, choice.get("next"), choice_id)


func get_view(state: Dictionary) -> Dictionary:
	var resumed: Dictionary = resume(state)
	return resumed.get("view", {}) if resumed.get("ok", false) else {}


func _transition(state: Dictionary, conversation: Dictionary, next_node: Variant, choice_id: String) -> Dictionary:
	if next_node == null:
		return _finish(state, conversation)
	var active: Dictionary = state["conversation_state"]["active"]
	var result: Dictionary = _simulation.apply_operation(
		state,
		"conversation.choose",
		{
			"conversation_id": conversation["id"],
			"node_id": active["node_id"],
			"choice_id": choice_id,
			"next_node": next_node,
		},
		"dialogue.transition"
	)
	if not result.get("ok", false):
		return result
	return _enter_node(result["state"], conversation, str(next_node))


func _enter_node(state: Dictionary, conversation: Dictionary, node_id: String) -> Dictionary:
	var node: Variant = conversation.get("nodes", {}).get(node_id)
	if not node is Dictionary:
		return _failure("Conversation %s is missing node %s." % [conversation["id"], node_id])
	var working: Dictionary = state.duplicate(true)
	var active: Dictionary = working["conversation_state"]["active"]
	active["node_id"] = node_id
	if node_id not in active["applied_nodes"]:
		var effects_result: Dictionary = _apply_effects(
			working,
			node.get("effects", []),
			"dialogue.node:%s:%s" % [conversation["id"], node_id]
		)
		if not effects_result.get("ok", false):
			return effects_result
		working = effects_result["state"]
		active = working["conversation_state"]["active"]
		active["applied_nodes"].append(node_id)

	var seen_nodes: Dictionary = working["conversation_state"]["seen_nodes"]
	if not seen_nodes.has(conversation["id"]):
		seen_nodes[conversation["id"]] = []
	if node_id not in seen_nodes[conversation["id"]]:
		seen_nodes[conversation["id"]].append(node_id)
	_append_history(working, conversation, node_id, node)
	var quest_result: Dictionary = _quests.record_event(working, "conversation_node_reached", {
		"conversation": conversation["id"],
		"node": node_id,
	}, "dialogue.node:%s:%s" % [conversation["id"], node_id])
	if not quest_result.get("ok", false):
		return quest_result
	working = quest_result["state"]
	if not node.get("branches", []).is_empty():
		return _resolve_automatic_branch(working, conversation, node)
	return _success(working, _make_view(working, conversation))


func _finish(state: Dictionary, conversation: Dictionary) -> Dictionary:
	var completion_result: Dictionary = _apply_effects(
		state,
		conversation.get("completion_effects", []),
		"dialogue.complete:%s" % conversation["id"]
	)
	if not completion_result.get("ok", false):
		return completion_result
	var result: Dictionary = _simulation.apply_operation(
		completion_result["state"],
		"conversation.end",
		{"conversation_id": conversation["id"], "outcome": "completed"},
		"dialogue.end"
	)
	if not result.get("ok", false):
		return result
	var working: Dictionary = result["state"]
	var quest_result: Dictionary = _quests.record_event(working, "conversation_completed", {
		"conversation": conversation["id"],
	}, "dialogue.end:%s" % conversation["id"])
	if not quest_result.get("ok", false):
		return quest_result
	working = quest_result["state"]
	var completed_calendar_event_id: String = ""
	for calendar_event: Variant in working["calendar_state"].get("events", []):
		if not calendar_event is Dictionary or str(calendar_event.get("source", "")) != str(conversation["id"]):
			continue
		if str(calendar_event.get("status", "scheduled")) != "scheduled":
			continue
		completed_calendar_event_id = str(calendar_event.get("id", ""))
		break
	if completed_calendar_event_id.is_empty():
		var calendar_participant: String = str(conversation.get("activation", {}).get("calendar_participant", ""))
		if not calendar_participant.is_empty():
			var participant_event: Dictionary = _current_calendar_event_for_participant(working, calendar_participant)
			completed_calendar_event_id = str(participant_event.get("id", ""))
	if not completed_calendar_event_id.is_empty():
		result = _simulation.apply_operation(
			working,
			"calendar.arrival",
			{"event_id": completed_calendar_event_id},
			"dialogue.end"
		)
		if not result.get("ok", false):
			return result
		working = result["state"]
	return {"ok": true, "state": working, "ended": true, "view": {}, "errors": PackedStringArray()}


func _apply_effects(state: Dictionary, effects: Array, source: String) -> Dictionary:
	var working: Dictionary = state
	for effect: Variant in effects:
		if not effect is Dictionary:
			continue
		var result: Dictionary = _apply_effect(working, effect, source)
		if not result.get("ok", false):
			return result
		working = result["state"]
	return _success(working)


func _apply_effect(state: Dictionary, effect: Dictionary, source: String) -> Dictionary:
	match str(effect.get("operation", "")):
		"add_meter":
			return _simulation.apply_operation(state, "relationship.adjust_meter", {
				"character_id": effect.get("character"),
				"meter": effect.get("meter"),
				"amount": effect.get("value", effect.get("amount", 0)),
				"reason": source,
			}, source)
		"start_quest":
			return _quests.start_quest(state, str(effect.get("value", effect.get("quest", ""))), source)
		"complete_objective", "complete_objective_if_active":
			if str(effect.get("quest", "")).is_empty():
				return _complete_named_objective_if_active(state, str(effect.get("objective", "")), source)
			return _quests.complete_objective(
				state,
				str(effect.get("quest", "")),
				str(effect.get("objective", "")),
				source,
				str(effect.get("operation")) == "complete_objective_if_active"
			)
		"complete_quest":
			return _quests.complete_quest(state, str(effect.get("quest", "")), source)
		"set_value":
			var changed: Dictionary = state.duplicate(true)
			var value_path: String = str(effect.get("key", ""))
			_set_state_value(changed, value_path, effect.get("value"))
			if value_path == "player.life_path":
				return _quests.apply_matching_branch(changed, "opening_future_choice", source)
			var value_result: Dictionary = _quests.record_event(changed, "value_set", {
				"key": value_path,
				"value": effect.get("value"),
			}, source)
			return value_result if not value_result.get("ok", false) else _success(value_result["state"])
		"set_flag":
			var flagged: Dictionary = state.duplicate(true)
			flagged["player"]["flags"][str(effect.get("key", ""))] = effect.get("value", true)
			return _success(flagged)
		"unlock_phone_app":
			var unlocked: Dictionary = state.duplicate(true)
			var app_id: String = str(effect.get("value", ""))
			if app_id not in unlocked["player"]["phone"]["unlocked_apps"]:
				unlocked["player"]["phone"]["unlocked_apps"].append(app_id)
			return _success(unlocked)
		"discover_location":
			return _simulation.apply_operation(state, "world.discover_location", {
				"location_id": effect.get("location_id", effect.get("value", "")),
				"discovery_source": effect.get("discovery_source", "invitation"),
				"character_id": effect.get("character", ""),
				"room_ids": effect.get("room_ids", []),
			}, source)
		"create_memory":
			return _simulation.apply_operation(state, "memory.create", {
				"character_id": effect.get("character"),
				"memory_id": effect.get("value", effect.get("memory_id", "")),
				"importance": effect.get("importance", 50),
				"tags": effect.get("tags", []),
			}, source)
		"unlock_relationship_chapter":
			return _unlock_relationship_chapter(state, effect)
		"add_character_stat":
			return _add_character_stat(state, effect)
		"add_player_value":
			return _add_player_value(state, effect, source)
		"complete_activity":
			return _complete_activity(state, str(effect.get("value", effect.get("activity", ""))), source)
		"spend_money":
			return _spend_money(state, float(effect.get("value", 0)), source, str(effect.get("category", "dialogue_purchase")))
		"schedule_event":
			return _schedule_dialogue_event(state, effect.get("value"), source)
		"create_debt":
			return _create_debt(state, effect, source)
		"create_calendar_from_class_schedule":
			return _create_class_schedule(state, source)
		"complete_conversation":
			return _success(state)
		_:
			return _failure("Unsupported dialogue effect: %s" % effect.get("operation", ""), state)


func _resolve_automatic_branch(state: Dictionary, conversation: Dictionary, node: Dictionary) -> Dictionary:
	for branch_value: Variant in node.get("branches", []):
		if not branch_value is Dictionary:
			continue
		var branch: Dictionary = branch_value
		if not _conditions_pass(state, branch.get("conditions", [])):
			continue
		var branch_id: String = str(branch.get("id", "branch"))
		var effects_result: Dictionary = _apply_effects(
			state,
			branch.get("effects", []),
			"dialogue.branch:%s:%s" % [conversation["id"], branch_id]
		)
		if not effects_result.get("ok", false):
			return effects_result
		return _transition(effects_result["state"], conversation, branch.get("next"), branch_id)
	return _failure("No automatic dialogue branch is available in %s." % conversation.get("id", "conversation"), state)


func _unlock_relationship_chapter(state: Dictionary, effect: Dictionary) -> Dictionary:
	var character_id: String = str(effect.get("character", ""))
	if not state.get("relationships", {}).has(character_id):
		return _failure("Unknown relationship character: %s" % character_id, state)
	var level: int = clampi(int(effect.get("level", 1)), 1, 5)
	var changed: Dictionary = state.duplicate(true)
	var relationship: Dictionary = changed["relationships"][character_id]
	relationship["unlocked_chapter_level"] = maxi(int(relationship.get("unlocked_chapter_level", 1)), level)
	relationship["relationship_level"] = maxi(int(relationship.get("relationship_level", 1)), level)
	return _success(changed)


func _add_character_stat(state: Dictionary, effect: Dictionary) -> Dictionary:
	var character_id: String = str(effect.get("character", ""))
	var stat_id: String = str(effect.get("key", ""))
	if not state.get("relationships", {}).has(character_id):
		return _failure("Unknown character-stat owner: %s" % character_id, state)
	if stat_id.is_empty():
		return _failure("Character-stat effects require a key.", state)
	var amount: Variant = effect.get("value", effect.get("amount"))
	if not amount is int and not amount is float:
		return _failure("Character-stat effects require a numeric value.", state)
	var changed: Dictionary = state.duplicate(true)
	var relationship: Dictionary = changed["relationships"][character_id]
	if not relationship.get("character_stats") is Dictionary:
		relationship["character_stats"] = {}
	var minimum: float = 0.0
	var maximum: float = 100.0
	var character: Variant = _registry.get_character(character_id)
	if character is Dictionary:
		var definition: Variant = character.get("custom_stat_definitions", {}).get(stat_id)
		if definition is Dictionary:
			minimum = float(definition.get("minimum", minimum))
			maximum = float(definition.get("maximum", maximum))
	var current: float = float(relationship["character_stats"].get(stat_id, 0.0))
	relationship["character_stats"][stat_id] = clampf(current + float(amount), minimum, maximum)
	return _success(changed)


func _add_player_value(state: Dictionary, effect: Dictionary, source: String) -> Dictionary:
	var section: String = str(effect.get("section", ""))
	var key: String = str(effect.get("key", ""))
	var amount: Variant = effect.get("value", effect.get("amount"))
	if section == "attributes":
		return _simulation.apply_operation(state, "attribute.adjust", {"attribute": key, "amount": amount}, source)
	if section == "needs":
		return _simulation.apply_operation(state, "need.adjust", {"need": key, "amount": amount}, source)
	return _failure("Unsupported player-value section: %s" % section, state)


func _complete_activity(state: Dictionary, activity_id: String, source: String) -> Dictionary:
	var activity: Variant = _registry.get_content("activities", activity_id)
	if not activity is Dictionary:
		return _failure("Unknown character activity: %s" % activity_id, state)
	var changed: Dictionary = state.duplicate(true)
	var conversation_state: Dictionary = changed["conversation_state"]
	if not conversation_state.get("activity_progress") is Dictionary:
		conversation_state["activity_progress"] = {}
	var progress: Dictionary = conversation_state["activity_progress"].get(activity_id, {}).duplicate(true)
	var count: int = int(progress.get("count", 0)) + 1
	progress["count"] = count
	progress["last_completed_at"] = "Y%d-%02d-%02d:%s" % [
		int(changed["clock"].get("year", 1)),
		int(changed["clock"].get("month", 1)),
		int(changed["clock"].get("day", 1)),
		str(changed["clock"].get("block", "morning")),
	]
	conversation_state["activity_progress"][activity_id] = progress
	var counter_key: String = str(activity.get("counter_key", "activity.%s.count" % activity_id))
	changed["player"]["flags"][counter_key] = count
	var success_flag: String = str(activity.get("success_flag", ""))
	if not success_flag.is_empty():
		changed["player"]["flags"][success_flag] = true
	var event_result: Dictionary = _quests.record_event(changed, "activity_completed", {
		"activity": activity_id,
		"count": count,
	}, source)
	if not event_result.get("ok", false):
		return event_result
	return _quests.record_event(event_result["state"], "activity_count_at_least", {
		"activity": activity_id,
		"count": count,
	}, source)


func _spend_money(state: Dictionary, amount: float, source: String, category: String = "dialogue_purchase") -> Dictionary:
	var remaining: float = amount
	var working: Dictionary = state
	for account_id: String in ["wallet_cash", "checking", "savings"]:
		var balance: float = float(working["player"]["economy"]["accounts"].get(account_id, 0.0))
		var debit: float = minf(balance, remaining)
		if debit > 0.0:
			var result: Dictionary = _simulation.apply_operation(working, "economy.transaction", {
				"account": account_id,
				"amount": -debit,
				"type": "tuition" if category == "tuition" else "purchase",
				"category": category,
				"description": source,
			}, source)
			if not result.get("ok", false):
				return result
			working = result["state"]
			remaining -= debit
	if remaining > 0.0:
		return _failure("Insufficient available funds.", state)
	return _success(working)


func _complete_named_objective_if_active(state: Dictionary, objective_id: String, source: String) -> Dictionary:
	if objective_id.is_empty():
		return _success(state)
	var working: Dictionary = state
	for quest_id_value: Variant in working["quest_state"].get("active", []).duplicate():
		var quest_id: String = str(quest_id_value)
		var quest: Variant = _registry.get_content("quests", quest_id)
		if not quest is Dictionary:
			continue
		var found: bool = false
		for objective: Variant in quest.get("objectives", []):
			if objective is Dictionary and str(objective.get("id", "")) == objective_id:
				found = true
				break
		if not found or bool(working["quest_state"].get("objectives", {}).get(quest_id, {}).get(objective_id, false)):
			continue
		var result: Dictionary = _quests.complete_objective(working, quest_id, objective_id, source, true)
		if not result.get("ok", false):
			return result
		working = result["state"]
	return _success(working)


func _create_debt(state: Dictionary, effect: Dictionary, source: String) -> Dictionary:
	var principal: float = float(effect.get("principal", 0.0))
	if principal <= 0.0:
		return _failure("Debt principal must be positive.", state)
	var changed: Dictionary = state.duplicate(true)
	var debt_type: String = str(effect.get("type", "student_loan"))
	changed["player"]["economy"]["debts"].append({
		"id": "%s-%d" % [debt_type, changed["player"]["economy"]["debts"].size() + 1],
		"type": debt_type,
		"principal": principal,
		"balance": principal,
		"source": source,
	})
	if debt_type == "student_loan":
		changed["player"]["education"]["student_debt"] = float(changed["player"]["education"].get("student_debt", 0.0)) + principal
	return _success(changed)


func _schedule_dialogue_event(state: Dictionary, value: Variant, source: String) -> Dictionary:
	if value is Dictionary:
		var direct_result: Dictionary = _simulation.apply_operation(state, "calendar.schedule", {
			"calendar_event": value,
		}, source)
		return direct_result if not direct_result.get("ok", false) else _success(direct_result["state"])
	var event_name: String = str(value)
	if event_name.is_empty():
		return _success(state)
	for existing: Variant in state["calendar_state"].get("events", []):
		if existing is Dictionary and str(existing.get("template_id", "")) == event_name and str(existing.get("status", "scheduled")) == "scheduled":
			return _success(state)
	var next_day: Dictionary = _date_after_days(state["clock"], 1)
	var event: Dictionary = {
		"id": "%s-y%d-%02d-%02d" % [event_name, next_day["year"], next_day["month"], next_day["day"]],
		"template_id": event_name,
		"title": event_name.replace("_", " ").capitalize(),
		"type": "activity",
		"source": "fitness_plan" if event_name == "beginner_forge_workout" else source,
		"date": "Y%d-%02d-%02d" % [next_day["year"], next_day["month"], next_day["day"]],
		"weekday": next_day["weekday"],
		"block": "afternoon",
		"location": "forge_fitness.strength_floor" if event_name == "beginner_forge_workout" else str(state["world_state"].get("current_location", "")),
		"participants": [],
	}
	var result: Dictionary = _simulation.apply_operation(state, "calendar.schedule", {"calendar_event": event}, source)
	return result if not result.get("ok", false) else _success(result["state"])


func _create_class_schedule(state: Dictionary, source: String) -> Dictionary:
	var program_id: String = str(state["player"]["education"].get("program", ""))
	var load_id: String = str(state["player"]["education"].get("load", state["player"]["education"].get("course_load", "")))
	var program: Variant = _registry.get_content("programs", program_id)
	if not program is Dictionary:
		return _failure("Choose a valid Westshore program before confirming the schedule.", state)
	if load_id not in ["full_time", "part_time"]:
		return _failure("Choose a full-time or part-time course load.", state)
	var course_limit: int = 4 if load_id == "full_time" else 2
	var course_ids: Array = Array(program.get("first_semester_courses", [])).slice(0, course_limit)
	var selected_sections: Array = []
	var occupied_slots: Dictionary = {}
	for course_id_value: Variant in course_ids:
		var course: Variant = _registry.get_content("courses", str(course_id_value))
		if not course is Dictionary:
			continue
		var selected: Dictionary = {}
		for section: Variant in course.get("sections", []):
			if not section is Dictionary:
				continue
			var conflict: bool = false
			for weekday: Variant in section.get("days", []):
				if occupied_slots.has("%s:%s" % [weekday, section.get("block", "")]):
					conflict = true
					break
			if not conflict:
				selected = section
				break
		if selected.is_empty() and not course.get("sections", []).is_empty():
			selected = course["sections"][0]
		if selected.is_empty():
			continue
		for weekday: Variant in selected.get("days", []):
			occupied_slots["%s:%s" % [weekday, selected.get("block", "")]] = true
		selected_sections.append({"course": course, "section": selected})

	var changed: Dictionary = state.duplicate(true)
	var education: Dictionary = changed["player"]["education"]
	var semester: Dictionary = _registry.get_package("westshore_education_system").get("institution", {}).get("fall_semester", {})
	education["institution"] = "westshore_college"
	education["course_load"] = load_id
	education["enrolled"] = true
	education["courses"] = course_ids.duplicate(true)
	education["course_sections"] = {}
	education["attendance_history"] = []
	education["assessments"] = []
	education["assessment_results"] = []
	education["course_preparation"] = {}
	education["semester_number"] = 1
	education["semester"] = {
		"id": semester.get("id", "fall_y1"),
		"number": 1,
		"status": "enrolled",
		"phase": "pre_orientation",
		"orientation": semester.get("orientation", "Y1-08-30"),
		"classes_begin": semester.get("classes_begin", "Y1-09-03"),
		"classes_end": semester.get("classes_end", "Y1-12-13"),
		"exam_week_begins": semester.get("exam_week_begins", "Y1-12-16"),
		"term_complete": semester.get("term_complete", "Y1-12-20"),
	}
	for selection: Variant in selected_sections:
		if not selection is Dictionary:
			continue
		var selected_course: Dictionary = selection["course"]
		var selected_section: Dictionary = selection["section"]
		education["course_sections"][str(selected_course.get("id", ""))] = {
			"section_id": selected_section.get("id", "A"),
			"days": selected_section.get("days", []).duplicate(true),
			"block": selected_section.get("block", "morning"),
			"lab": selected_course.get("lab", {}).duplicate(true),
		}
	for course_id_value: Variant in course_ids:
		education["grades"][str(course_id_value)] = {"current_percent": 0.0, "letter_grade": "—", "graded_weight": 0.0, "component_scores": {}, "status": "not_started"}
		education["attendance"][str(course_id_value)] = {"attended": 0, "late": 0, "absent": 0}
		education["course_preparation"][str(course_id_value)] = 0.0

	var created_count: int = 0
	var cursor: Dictionary = {"year": 1, "month": 9, "day": 3, "weekday": "tuesday"}
	while _calendar_value(cursor) <= _calendar_value({"year": 1, "month": 12, "day": 13}):
		for selection: Variant in selected_sections:
			if not selection is Dictionary:
				continue
			var course: Dictionary = selection["course"]
			var section: Dictionary = selection["section"]
			if cursor["weekday"] in section.get("days", []):
				changed["calendar_state"]["events"].append(_class_event(course, section, cursor, false))
				created_count += 1
			var lab: Dictionary = course.get("lab", {})
			if not lab.is_empty() and str(lab.get("day", "")) == str(cursor["weekday"]):
				changed["calendar_state"]["events"].append(_class_event(course, lab, cursor, true))
				created_count += 1
		cursor = _advance_date(cursor)
	if created_count == 0:
		return _failure("Westshore could not build a class schedule for that program.", state)
	var quest_result: Dictionary = _quests.record_event(changed, "calendar_events_created", {
		"tag": "westshore_class",
		"count": created_count,
	}, source)
	return quest_result if not quest_result.get("ok", false) else _success(quest_result["state"])


func _class_event(course: Dictionary, section: Dictionary, date: Dictionary, is_lab: bool) -> Dictionary:
	var suffix: String = "lab" if is_lab else str(section.get("id", "A"))
	return {
		"id": "class-%s-%s-y%d-%02d-%02d" % [course.get("id", "course"), suffix, date["year"], date["month"], date["day"]],
		"title": "%s%s" % [course.get("name", course.get("id", "Class")), " Lab" if is_lab else ""],
		"course_id": course.get("id"),
		"section_id": suffix,
		"type": "class",
		"source": "westshore_enrollment",
		"tags": ["westshore_class"],
		"date": "Y%d-%02d-%02d" % [date["year"], date["month"], date["day"]],
		"weekday": date["weekday"],
		"block": section.get("block", "morning"),
		"location": "westshore_campus.science_labs" if is_lab else "westshore_campus.classrooms",
		"participants": [],
		"status": "scheduled",
	}


func _date_after_days(clock: Dictionary, days: int) -> Dictionary:
	var date: Dictionary = {
		"year": int(clock.get("year", 1)),
		"month": int(clock.get("month", 1)),
		"day": int(clock.get("day", 1)),
		"weekday": str(clock.get("weekday", "monday")),
	}
	for _index: int in days:
		date = _advance_date(date)
	return date


func _advance_date(date: Dictionary) -> Dictionary:
	const WEEKDAYS: PackedStringArray = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
	var next: Dictionary = date.duplicate(true)
	next["day"] = int(next["day"]) + 1
	var month_days: int = _days_in_month(int(next["month"]), int(next["year"]))
	if int(next["day"]) > month_days:
		next["day"] = 1
		next["month"] = int(next["month"]) + 1
		if int(next["month"]) > 12:
			next["month"] = 1
			next["year"] = int(next["year"]) + 1
	var weekday_index: int = WEEKDAYS.find(str(date.get("weekday", "monday")))
	next["weekday"] = WEEKDAYS[(weekday_index + 1) % WEEKDAYS.size()]
	return next


func _days_in_month(month: int, year: int) -> int:
	if month in [4, 6, 9, 11]:
		return 30
	if month == 2:
		return 29 if year % 4 == 0 else 28
	return 31


func _calendar_value(date: Dictionary) -> int:
	return int(date.get("year", 1)) * 372 + int(date.get("month", 1)) * 31 + int(date.get("day", 1))


func _activation_error(state: Dictionary, conversation: Dictionary) -> String:
	var activation: Dictionary = conversation.get("activation", {})
	if not _conditions_pass(state, conversation.get("condition", [])):
		return "Conversation requirements are not met."
	if activation.has("quest_active") and str(activation["quest_active"]) not in state["quest_state"]["active"]:
		return "Required quest is not active."
	if activation.has("quest_any_active"):
		var any_quest_active: bool = false
		for quest_id: Variant in activation["quest_any_active"]:
			if str(quest_id) in state["quest_state"]["active"]:
				any_quest_active = true
				break
		if not any_quest_active:
			return "A related quest must be active."
	if activation.has("location"):
		var expected_location: String = str(activation["location"])
		var current_location: String = str(state["world_state"]["current_location"])
		if current_location != expected_location and not current_location.begins_with("%s." % expected_location):
			return "Conversation is unavailable at the current location."
	if activation.has("block") and str(activation["block"]) != str(state["clock"]["block"]):
		return "Conversation is unavailable during this activity block."
	if activation.has("blocks") and str(state["clock"]["block"]) not in activation["blocks"]:
		return "Conversation is unavailable during this activity block."
	if activation.has("day") and str(activation["day"]) != str(state["clock"]["weekday"]):
		return "Conversation is unavailable today."
	if activation.has("days") and str(state["clock"]["weekday"]) not in activation["days"]:
		return "Conversation is unavailable today."
	if activation.has("npc_available"):
		var character: Variant = _registry.get_character(str(activation["npc_available"]))
		if not character is Dictionary:
			return "The required character is unavailable."
		for commitment: Variant in character.get("schedule", {}).get("fixed_commitments", []):
			if not commitment is Dictionary or not bool(commitment.get("unavailable", false)):
				continue
			if str(state["clock"]["weekday"]) in commitment.get("days", []) and str(state["clock"]["block"]) in commitment.get("blocks", []):
				return "%s is busy with %s right now." % [
					character.get("display_name", activation["npc_available"]),
					str(commitment.get("activity", "work")).replace("_", " "),
				]
	if activation.has("calendar_participant"):
		var participant_id: String = str(activation["calendar_participant"])
		if _current_calendar_event_for_participant(state, participant_id).is_empty():
			return "This scene requires a current calendar plan with %s." % _speaker_name(participant_id, state)
	return ""


func _current_calendar_event_for_participant(state: Dictionary, character_id: String) -> Dictionary:
	var current_date: String = "Y%d-%02d-%02d" % [
		int(state["clock"].get("year", 1)),
		int(state["clock"].get("month", 1)),
		int(state["clock"].get("day", 1)),
	]
	var current_block: String = str(state["clock"].get("block", ""))
	var current_location: String = str(state.get("world_state", {}).get("current_location", ""))
	for event_value: Variant in state.get("calendar_state", {}).get("events", []):
		if not event_value is Dictionary:
			continue
		var event: Dictionary = event_value
		if str(event.get("status", "scheduled")) != "scheduled":
			continue
		if character_id not in event.get("participants", []):
			continue
		if str(event.get("date", "")) != current_date or str(event.get("block", "")) != current_block:
			continue
		var event_location: String = str(event.get("location", ""))
		if not event_location.is_empty() and event_location.get_slice(".", 0) != current_location.get_slice(".", 0):
			continue
		return event
	return {}


func _active_context(state: Dictionary) -> Dictionary:
	var active: Variant = state.get("conversation_state", {}).get("active")
	if not active is Dictionary:
		return {}
	var conversation: Variant = _registry.get_content("conversations", str(active.get("conversation_id", "")))
	if not conversation is Dictionary:
		return {}
	var node: Variant = conversation.get("nodes", {}).get(str(active.get("node_id", "")))
	if not node is Dictionary:
		return {}
	return {"active": active, "conversation": conversation, "node": node}


func _make_view(state: Dictionary, conversation: Dictionary) -> Dictionary:
	var active: Dictionary = state["conversation_state"]["active"]
	var node_id: String = str(active["node_id"])
	var node: Dictionary = conversation["nodes"][node_id]
	var choices: Array = []
	for choice: Dictionary in _visible_choices(state, node):
		choices.append({"id": choice.get("id"), "text": _resolve_tokens(str(choice.get("text", "")), state)})
	var speaker_id: String = str(node.get("speaker", ""))
	return {
		"conversation_id": conversation["id"],
		"node_id": node_id,
		"speaker_id": speaker_id,
		"speaker_name": _speaker_name(speaker_id, state),
		"participants": _conversation_participants(conversation),
		"portrait_id": str(node.get("portrait", "default")),
		"background_variant": str(node.get("background_variant", "")),
		"line": _resolve_tokens(str(node.get("line", "")), state),
		"stage_direction": _resolve_tokens(str(node.get("stage_direction", "")), state),
		"choices": choices,
		"can_advance": choices.is_empty() and node.get("branches", []).is_empty(),
	}


func _visible_choices(state: Dictionary, node: Dictionary) -> Array:
	var visible: Array = []
	for choice: Variant in node.get("choices", []):
		if choice is Dictionary and _conditions_pass(state, choice.get("conditions", [])):
			visible.append(choice)
	return visible


func _conditions_pass(state: Dictionary, conditions_value: Variant) -> bool:
	var conditions: Array = conditions_value if conditions_value is Array else ([conditions_value] if conditions_value is Dictionary and not conditions_value.is_empty() else [])
	for condition: Variant in conditions:
		if not condition is Dictionary:
			return false
		var handled_keys: Dictionary = {}
		if condition.has("money_at_least"):
			handled_keys["money_at_least"] = true
			var accounts: Dictionary = state["player"]["economy"]["accounts"]
			var available: float = float(accounts.get("wallet_cash", 0)) + float(accounts.get("checking", 0)) + float(accounts.get("savings", 0))
			if available < float(condition["money_at_least"]):
				return false
		if condition.has("value_equals"):
			handled_keys["value_equals"] = true
			var comparison: Array = condition["value_equals"]
			if comparison.size() != 2 or _get_state_value(state, str(comparison[0])) != comparison[1]:
				return false
		for key: String in ["flag", "flag_not"]:
			if not condition.has(key):
				continue
			handled_keys[key] = true
			var flag_set: bool = _flag_is_set(state, str(condition[key]))
			if (key == "flag" and not flag_set) or (key == "flag_not" and flag_set):
				return false
		for key: String in ["meter_at_least", "meter_at_most", "meter_equals"]:
			if not condition.has(key):
				continue
			handled_keys[key] = true
			var meter_rule: Variant = condition[key]
			if not meter_rule is Array or meter_rule.size() != 3:
				return false
			var relationship: Variant = state.get("relationships", {}).get(str(meter_rule[0]))
			if not relationship is Dictionary or not relationship.has(str(meter_rule[1])):
				return false
			var meter_value: float = float(relationship[str(meter_rule[1])])
			var meter_target: float = float(meter_rule[2])
			if key == "meter_at_least" and meter_value < meter_target:
				return false
			if key == "meter_at_most" and meter_value > meter_target:
				return false
			if key == "meter_equals" and not is_equal_approx(meter_value, meter_target):
				return false
		for key: String in ["character_stat_at_least", "character_stat_at_most"]:
			if not condition.has(key):
				continue
			handled_keys[key] = true
			var stat_rule: Variant = condition[key]
			if not stat_rule is Array or stat_rule.size() != 3:
				return false
			var stat_relationship: Variant = state.get("relationships", {}).get(str(stat_rule[0]))
			if not stat_relationship is Dictionary:
				return false
			var stat_value: float = float(stat_relationship.get("character_stats", {}).get(str(stat_rule[1]), 0.0))
			if key == "character_stat_at_least" and stat_value < float(stat_rule[2]):
				return false
			if key == "character_stat_at_most" and stat_value > float(stat_rule[2]):
				return false
		if condition.has("chapter_at_least"):
			handled_keys["chapter_at_least"] = true
			var chapter_rule: Variant = condition["chapter_at_least"]
			if not chapter_rule is Array or chapter_rule.size() != 2:
				return false
			var chapter_relationship: Variant = state.get("relationships", {}).get(str(chapter_rule[0]))
			if not chapter_relationship is Dictionary or int(chapter_relationship.get("unlocked_chapter_level", 1)) < int(chapter_rule[1]):
				return false
		for key: String in ["memory_exists", "memory_missing"]:
			if not condition.has(key):
				continue
			handled_keys[key] = true
			var memory_rule: Variant = condition[key]
			if not memory_rule is Array or memory_rule.size() != 2:
				return false
			var memory_found: bool = _memory_exists(state, str(memory_rule[0]), str(memory_rule[1]))
			if (key == "memory_exists" and not memory_found) or (key == "memory_missing" and memory_found):
				return false
		if condition.has("event"):
			handled_keys["event"] = true
			for selector: String in ["character", "quest", "conversation"]:
				if condition.has(selector):
					handled_keys[selector] = true
			if not _state_event_condition_passes(state, condition):
				return false
		for condition_key: Variant in condition.keys():
			if not handled_keys.has(str(condition_key)):
				return false
	return true


func _flag_is_set(state: Dictionary, key: String) -> bool:
	if key.begins_with("met_"):
		var character_id: String = key.trim_prefix("met_")
		for npc_state: Variant in state.get("npc_states", []):
			if npc_state is Dictionary and str(npc_state.get("character_id", "")) == character_id:
				return npc_state.get("discovered", false) == true
	var flags: Dictionary = state.get("player", {}).get("flags", {})
	if flags.has(key):
		return _value_is_truthy(flags[key])
	return _value_is_truthy(_get_state_value(state, key))


func _value_is_truthy(value: Variant) -> bool:
	if value is bool:
		return value
	if value is int or value is float:
		return float(value) != 0.0
	if value is String:
		return not value.is_empty()
	return value != null


func _memory_exists(state: Dictionary, character_id: String, memory_id: String) -> bool:
	var relationship: Variant = state.get("relationships", {}).get(character_id)
	if not relationship is Dictionary:
		return false
	for memory: Variant in relationship.get("memories", []):
		if memory is Dictionary and str(memory.get("id", "")) == memory_id:
			return true
	return false


func _state_event_condition_passes(state: Dictionary, condition: Dictionary) -> bool:
	match str(condition.get("event", "")):
		"character_met":
			return _flag_is_set(state, "met_%s" % str(condition.get("character", "")))
		"quest_completed":
			return str(condition.get("quest", "")) in state.get("quest_state", {}).get("completed", [])
		"conversation_completed":
			return str(condition.get("conversation", "")) in state.get("conversation_state", {}).get("completed", [])
		_:
			return false


func _set_state_value(state: Dictionary, path: String, value: Variant) -> void:
	if path.begins_with("education.") or path.begins_with("employment.") or path.begins_with("fitness.") or path.begins_with("economy."):
		path = "player.%s" % path
	var parts: PackedStringArray = path.split(".")
	var current: Dictionary = state
	for index: int in range(parts.size() - 1):
		if not current.has(parts[index]) or not current[parts[index]] is Dictionary:
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


func _speaker_name(speaker_id: String, state: Dictionary) -> String:
	if speaker_id == "player":
		return str(state["player"]["identity"]["first_name"])
	var character: Variant = _registry.get_character(speaker_id)
	if character is Dictionary:
		return str(character.get("display_name", speaker_id))
	return speaker_id.replace("_", " ").capitalize()


func _resolve_tokens(text: String, state: Dictionary) -> String:
	return text.replace("{player_first_name}", str(state["player"]["identity"]["first_name"]))


func _conversation_participants(conversation: Dictionary) -> Array:
	var participants: Array = ["player"]
	for node: Variant in conversation.get("nodes", {}).values():
		if node is Dictionary:
			var speaker: String = str(node.get("speaker", ""))
			if not speaker.is_empty() and speaker != "player" and speaker not in participants:
				participants.append(speaker)
	return participants


func _append_history(state: Dictionary, conversation: Dictionary, node_id: String, node: Dictionary) -> void:
	if not state["conversation_state"].has("history"):
		state["conversation_state"]["history"] = []
	var text: String = str(node.get("line", node.get("stage_direction", "")))
	if text.is_empty():
		return
	state["conversation_state"]["history"].append({
		"conversation_id": conversation["id"],
		"node_id": node_id,
		"speaker": node.get("speaker", "narration"),
		"text": _resolve_tokens(text, state),
	})


func _success(state: Dictionary, view: Dictionary = {}) -> Dictionary:
	return {"ok": true, "state": state, "view": view, "ended": false, "errors": PackedStringArray()}


func _failure(message: String, state: Dictionary = {}) -> Dictionary:
	return {"ok": false, "state": state, "errors": PackedStringArray([message])}
