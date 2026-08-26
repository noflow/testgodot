extends RefCounted
class_name PortAlderQuestEngine

var _registry: Node
var _simulation: RefCounted


func _init(content_registry: Node, simulation_engine: RefCounted) -> void:
	_registry = content_registry
	_simulation = simulation_engine


func start_quest(state: Dictionary, quest_id: String, source: String) -> Dictionary:
	if quest_id in state["quest_state"]["active"]:
		return _success(state)
	return _simulation.apply_operation(state, "quest.start", {"quest_id": quest_id}, source)


func complete_objective(
	state: Dictionary,
	quest_id: String,
	objective_id: String,
	source: String,
	only_if_active: bool = false
) -> Dictionary:
	if only_if_active and quest_id not in state["quest_state"]["active"]:
		return _success(state)
	var result: Dictionary = _simulation.apply_operation(
		state,
		"quest.objective_complete",
		{"quest_id": quest_id, "objective_id": objective_id},
		source
	)
	if not result.get("ok", false):
		return result
	if _all_objectives_complete(result["state"], quest_id):
		return complete_quest(result["state"], quest_id, "%s.auto_complete" % source)
	return _success(result["state"])


func record_event(state: Dictionary, event_name: String, payload: Dictionary, source: String) -> Dictionary:
	if event_name.is_empty():
		return _failure("Quest events require an event name.")
	var working: Dictionary = state
	for quest: Variant in _registry.get_all("quests"):
		if not quest is Dictionary:
			continue
		var quest_id: String = str(quest.get("id", ""))
		if quest_id in working["quest_state"]["active"] or quest_id in working["quest_state"]["completed"]:
			continue
		if quest_id in working["quest_state"].get("failed", []) or quest_id in working["quest_state"].get("deferred", []):
			continue
		if not _event_condition_matches(quest.get("activation", {}), event_name, payload):
			continue
		var activation_result: Dictionary = start_quest(working, quest_id, "%s.activation" % source)
		if not activation_result.get("ok", false):
			return activation_result
		working = activation_result["state"]

	for quest_id_value: Variant in working["quest_state"].get("active", []).duplicate():
		var quest_id: String = str(quest_id_value)
		var quest: Variant = _registry.get_content("quests", quest_id)
		if not quest is Dictionary:
			continue
		for objective: Variant in quest.get("objectives", []):
			if not objective is Dictionary or quest_id not in working["quest_state"]["active"]:
				continue
			var objective_id: String = str(objective.get("id", ""))
			if bool(working["quest_state"].get("objectives", {}).get(quest_id, {}).get(objective_id, false)):
				continue
			if not _event_condition_matches(objective.get("completion", {}), event_name, payload):
				continue
			var objective_result: Dictionary = complete_objective(
				working, quest_id, objective_id, "%s:%s" % [source, event_name]
			)
			if not objective_result.get("ok", false):
				return objective_result
			working = objective_result["state"]
	return _success(working)


func complete_quest(state: Dictionary, quest_id: String, source: String) -> Dictionary:
	var quest: Variant = _registry.get_content("quests", quest_id)
	if not quest is Dictionary:
		return _failure("Unknown quest: %s" % quest_id)
	if quest_id in state["quest_state"].get("completed", []):
		return _success(state)
	var branch: Dictionary = _matching_branch(state, quest)
	var result: Dictionary = _simulation.apply_operation(
		state,
		"quest.complete",
		{"quest_id": quest_id, "branch_id": branch.get("id")},
		source
	)
	if not result.get("ok", false):
		return result
	var branch_result: Dictionary = apply_matching_branch(result["state"], quest_id, source)
	if not branch_result.get("ok", false):
		return branch_result
	var working: Dictionary = branch_result["state"]

	for effect: Variant in quest.get("completion_effects", []):
		if effect is Dictionary:
			_apply_completion_effect(working, effect)
	var activation_result: Dictionary = sync_automatic_activations(working, "%s.followups" % source)
	if not activation_result.get("ok", false):
		return activation_result
	return _success(activation_result["state"], activation_result["activated"])


func sync_automatic_activations(state: Dictionary, source: String) -> Dictionary:
	var working: Dictionary = state
	var activated: PackedStringArray = []
	for quest: Variant in _registry.get_all("quests"):
		if not quest is Dictionary:
			continue
		var quest_id: String = str(quest.get("id", ""))
		if quest_id.is_empty() or quest_id in working["quest_state"]["active"] or quest_id in working["quest_state"]["completed"]:
			continue
		if quest_id in working["quest_state"].get("failed", []) or quest_id in working["quest_state"].get("deferred", []):
			continue
		if not _automatic_activation_ready(working, quest):
			continue
		var result: Dictionary = start_quest(working, quest_id, source)
		if not result.get("ok", false):
			return {"ok": false, "state": state, "activated": PackedStringArray(), "errors": result.get("errors", PackedStringArray())}
		working = result["state"]
		activated.append(quest_id)
	return {"ok": true, "state": working, "activated": activated, "errors": PackedStringArray()}


func apply_matching_branch(state: Dictionary, quest_id: String, source: String) -> Dictionary:
	var quest: Variant = _registry.get_content("quests", quest_id)
	if not quest is Dictionary:
		return _failure("Unknown quest: %s" % quest_id)
	var branch: Dictionary = _matching_branch(state, quest)
	if branch.is_empty():
		return _success(state)
	var working: Dictionary = state
	for next_quest_id: Variant in branch.get("start_quests", []):
		var result: Dictionary = start_quest(working, str(next_quest_id), source)
		if not result.get("ok", false):
			return result
		working = result["state"]
	for key: Variant in branch.get("set_rules", {}):
		_set_state_value(working, str(key), branch["set_rules"][key])
	return _success(working)


func get_active_quests(state: Dictionary) -> Array:
	var active: Array = []
	for quest_id: Variant in state.get("quest_state", {}).get("active", []):
		var quest: Variant = _registry.get_content("quests", str(quest_id))
		if quest is Dictionary:
			active.append(quest)
	return active


func get_progress(state: Dictionary, quest_id: String) -> Dictionary:
	var quest: Variant = _registry.get_content("quests", quest_id)
	if not quest is Dictionary:
		return {}
	var completed: Dictionary = state["quest_state"].get("objectives", {}).get(quest_id, {})
	var objectives: Array = []
	for objective: Variant in quest.get("objectives", []):
		if objective is Dictionary:
			var entry: Dictionary = objective.duplicate(true)
			entry["completed"] = bool(completed.get(str(objective.get("id", "")), false))
			objectives.append(entry)
	return {
		"quest_id": quest_id,
		"title": quest.get("title", quest_id),
		"active": quest_id in state["quest_state"]["active"],
		"completed": quest_id in state["quest_state"]["completed"],
		"objectives": objectives,
	}


func _matching_branch(state: Dictionary, quest: Dictionary) -> Dictionary:
	for branch: Variant in quest.get("branches", []):
		if not branch is Dictionary:
			continue
		var condition: Dictionary = branch.get("condition", {})
		var comparison: Array = condition.get("value_equals", [])
		if comparison.size() == 2 and _get_state_value(state, str(comparison[0])) == comparison[1]:
			return branch
	return {}


func _automatic_activation_ready(state: Dictionary, quest: Dictionary) -> bool:
	var activation: Dictionary = quest.get("activation", {})
	if str(activation.get("event", "")) != "quest_completed":
		return false
	var prerequisite: String = str(activation.get("quest", ""))
	if prerequisite.is_empty() or prerequisite not in state["quest_state"]["completed"]:
		return false
	var earliest_block: String = str(activation.get("earliest_block", ""))
	if earliest_block.is_empty():
		return true
	var completion_date: String = _quest_completion_date(state, prerequisite)
	var current_date: String = "Y%d-%02d-%02d" % [state["clock"]["year"], state["clock"]["month"], state["clock"]["day"]]
	if not completion_date.is_empty() and completion_date != current_date:
		return true
	const BLOCKS: PackedStringArray = ["early_morning", "morning", "lunch", "afternoon", "evening", "late_evening", "night"]
	return BLOCKS.find(str(state["clock"]["block"])) >= BLOCKS.find(earliest_block)


func _quest_completion_date(state: Dictionary, quest_id: String) -> String:
	var events: Array = state.get("simulation", {}).get("recent_event_log", [])
	for index: int in range(events.size() - 1, -1, -1):
		var event: Variant = events[index]
		if not event is Dictionary or str(event.get("operation", "")) != "quest.complete":
			continue
		if str(event.get("payload", {}).get("quest_id", "")) != quest_id:
			continue
		return str(event.get("game_timestamp", "")).get_slice(":", 0)
	return ""


func _apply_completion_effect(state: Dictionary, effect: Dictionary) -> void:
	match str(effect.get("operation", "")):
		"unlock_phone_app":
			var app_id: String = str(effect.get("value", ""))
			if app_id not in state["player"]["phone"]["unlocked_apps"]:
				state["player"]["phone"]["unlocked_apps"].append(app_id)
		"set_flag":
			var key: String = str(effect.get("key", ""))
			if key in ["education.enrolled", "employment.employed"]:
				_set_state_value(state, "player.%s" % key, effect.get("value"))
				if key == "education.enrolled" and bool(effect.get("value", false)):
					state["player"]["education"]["enrollment_date"] = "Y%d-%02d-%02d" % [state["clock"]["year"], state["clock"]["month"], state["clock"]["day"]]
			else:
				state["player"]["flags"][key] = effect.get("value")
		"add_attribute":
			var attribute: String = str(effect.get("attribute", ""))
			if state["player"]["attributes"].has(attribute):
				state["player"]["attributes"][attribute] = clampf(
					float(state["player"]["attributes"][attribute]) + float(effect.get("value", 0)), 0.0, 250.0
				)
		"unlock_phone_section", "unlock_activity":
			state["player"]["flags"]["unlocked.%s" % str(effect.get("value", ""))] = true
		"unlock_relationship_chapter":
			var character_id: String = str(effect.get("character", ""))
			if state["relationships"].has(character_id):
				var chapter_level: int = int(effect.get("level", 1))
				state["relationships"][character_id]["unlocked_chapter_level"] = maxi(
					int(state["relationships"][character_id].get("unlocked_chapter_level", 1)), chapter_level
				)
				state["relationships"][character_id]["relationship_level"] = maxi(
					int(state["relationships"][character_id].get("relationship_level", 1)), chapter_level
				)
		"set_value":
			_set_state_value(state, str(effect.get("key", "")), effect.get("value"))
		"schedule_event":
			var event_id: String = str(effect.get("value", ""))
			if not event_id.is_empty():
				if event_id == "westshore_orientation" and not _calendar_has_event(state, event_id):
					state["calendar_state"]["events"].append({
						"id": event_id,
						"template_id": event_id,
						"title": "Westshore Orientation",
						"type": "education",
						"source": "enroll_at_westshore",
						"date": "Y1-08-30",
						"weekday": "friday",
						"block": "morning",
						"location": "westshore_campus.courtyard",
						"participants": [],
						"status": "scheduled",
					})
				elif not _calendar_has_event(state, event_id):
					state["calendar_state"]["reminders"].append({"id": event_id, "status": "pending_scheduling"})


func _get_state_value(state: Dictionary, path: String) -> Variant:
	if path.begins_with("education.") or path.begins_with("employment.") or path.begins_with("fitness.") or path.begins_with("economy."):
		path = "player.%s" % path
	var parts: PackedStringArray = path.split(".")
	var current: Variant = state
	for part: String in parts:
		if not current is Dictionary or not current.has(part):
			return null
		current = current[part]
	return current


func _set_state_value(state: Dictionary, path: String, value: Variant) -> void:
	if path.begins_with("household."):
		var household_key: String = path.trim_prefix("household.")
		state["household_state"]["rules"][household_key] = value
		if household_key == "monthly_rent":
			state["player"]["housing"]["monthly_rent"] = value
		elif household_key == "rent_due_date":
			state["player"]["housing"]["rent_first_due"] = "Y1-%s" % str(value)
		elif household_key == "weekly_allowance_active":
			state["player"]["flags"]["weekly_allowance_active"] = value
		return
	if path.begins_with("education.") or path.begins_with("employment.") or path.begins_with("fitness.") or path.begins_with("economy."):
		path = "player.%s" % path
	var parts: PackedStringArray = path.split(".")
	var current: Dictionary = state
	for index: int in range(parts.size() - 1):
		if not current.has(parts[index]) or not current[parts[index]] is Dictionary:
			current[parts[index]] = {}
		current = current[parts[index]]
	current[parts[-1]] = value


func _all_objectives_complete(state: Dictionary, quest_id: String) -> bool:
	var quest: Variant = _registry.get_content("quests", quest_id)
	if not quest is Dictionary:
		return false
	var progress: Dictionary = state["quest_state"].get("objectives", {}).get(quest_id, {})
	var objectives: Array = quest.get("objectives", [])
	if objectives.is_empty():
		return false
	for objective: Variant in objectives:
		if objective is Dictionary and not bool(progress.get(str(objective.get("id", "")), false)):
			return false
	return true


func _event_condition_matches(condition: Dictionary, event_name: String, payload: Dictionary) -> bool:
	if str(condition.get("event", "")) != event_name:
		return false
	for key: String in ["conversation", "node", "character", "activity", "tag", "key", "mode", "quest", "recipient"]:
		if condition.has(key) and str(condition[key]) != str(payload.get(key, "")):
			return false
	if condition.has("location"):
		var expected_location: String = str(condition["location"])
		var actual_location: String = str(payload.get("location", ""))
		if actual_location != expected_location and not actual_location.begins_with("%s." % expected_location):
			return false
	if condition.has("allowed_values") and payload.get("value") not in condition["allowed_values"]:
		return false
	if condition.has("minimum") and int(payload.get("count", 0)) < int(condition["minimum"]):
		return false
	if condition.has("hours_minimum") and float(payload.get("hours", 0.0)) < float(condition["hours_minimum"]):
		return false
	if condition.has("hours_maximum") and float(payload.get("hours", 0.0)) > float(condition["hours_maximum"]):
		return false
	if condition.has("filter"):
		var expected_filter: String = str(condition["filter"])
		if str(payload.get("filter", "")) != expected_filter and expected_filter not in payload.get("employment_types", []):
			return false
	return true


func _calendar_has_event(state: Dictionary, event_id: String) -> bool:
	for calendar_event: Variant in state["calendar_state"].get("events", []):
		if calendar_event is Dictionary and str(calendar_event.get("id", "")) == event_id:
			return true
	return false


func _success(state: Dictionary, activated: PackedStringArray = PackedStringArray()) -> Dictionary:
	return {"ok": true, "state": state, "activated": activated, "errors": PackedStringArray()}


func _failure(message: String) -> Dictionary:
	return {"ok": false, "errors": PackedStringArray([message])}
