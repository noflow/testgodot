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
	return _simulation.apply_operation(
		state,
		"quest.objective_complete",
		{"quest_id": quest_id, "objective_id": objective_id},
		source
	)


func complete_quest(state: Dictionary, quest_id: String, source: String) -> Dictionary:
	var quest: Variant = _registry.get_content("quests", quest_id)
	if not quest is Dictionary:
		return _failure("Unknown quest: %s" % quest_id)
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
	return _success(working)


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


func _apply_completion_effect(state: Dictionary, effect: Dictionary) -> void:
	match str(effect.get("operation", "")):
		"unlock_phone_app":
			var app_id: String = str(effect.get("value", ""))
			if app_id not in state["player"]["phone"]["unlocked_apps"]:
				state["player"]["phone"]["unlocked_apps"].append(app_id)
		"set_flag":
			state["player"]["flags"][str(effect.get("key", ""))] = effect.get("value")


func _get_state_value(state: Dictionary, path: String) -> Variant:
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
	var parts: PackedStringArray = path.split(".")
	var current: Dictionary = state
	for index: int in range(parts.size() - 1):
		if not current.has(parts[index]) or not current[parts[index]] is Dictionary:
			current[parts[index]] = {}
		current = current[parts[index]]
	current[parts[-1]] = value


func _success(state: Dictionary) -> Dictionary:
	return {"ok": true, "state": state, "errors": PackedStringArray()}


func _failure(message: String) -> Dictionary:
	return {"ok": false, "errors": PackedStringArray([message])}
