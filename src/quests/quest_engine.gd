extends RefCounted
class_name PortAlderQuestEngine

const BLOCKS: PackedStringArray = [
	"early_morning", "morning", "lunch", "afternoon", "evening", "late_evening", "night",
]

var _registry: Node
var _simulation: RefCounted


func _init(content_registry: Node, simulation_engine: RefCounted) -> void:
	_registry = content_registry
	_simulation = simulation_engine


func start_quest(state: Dictionary, quest_id: String, source: String) -> Dictionary:
	if quest_id in state["quest_state"]["active"]:
		return _success(state)
	var quest: Variant = _registry.get_content("quests", quest_id)
	if quest is Dictionary and _repeat_completion_count(state, quest_id) > 0:
		var report: Dictionary = gate_report(state, quest_id)
		if not bool(report.get("met", false)):
			var failures: PackedStringArray = PackedStringArray(report.get("visible_failures", []))
			return _failure(failures[0] if not failures.is_empty() else "This repeatable quest is not ready yet.")
	return _simulation.apply_operation(state, "quest.start", {"quest_id": quest_id, "discovery_source": source}, source)


func discover_quest(state: Dictionary, quest_id: String, source: String) -> Dictionary:
	var quest: Variant = _registry.get_content("quests", quest_id)
	if not quest is Dictionary:
		return _failure("Unknown quest: %s" % quest_id)
	var quest_state: Dictionary = state["quest_state"]
	if quest_id in quest_state.get("completed", []) or quest_id in quest_state.get("failed", []) or quest_id in quest_state.get("deferred", []):
		return _success(state)
	var working: Dictionary = state
	var newly_discovered: bool = quest_id not in quest_state.get("discovered", [])
	if newly_discovered:
		var discovery_result: Dictionary = _simulation.apply_operation(
			working,
			"quest.discover",
			{"quest_id": quest_id, "discovery_source": source},
			source
		)
		if not discovery_result.get("ok", false):
			return discovery_result
		working = discovery_result["state"]
	var policy: String = str(quest.get("discovery", {}).get(
		"policy", _registry.get_package("port_alder_sandbox_quest_system").get("default_discovery_policy", "offer")
	))
	if policy == "auto_start":
		if not bool(gate_report(working, quest_id).get("met", false)):
			return _success(
				working,
				PackedStringArray(),
				PackedStringArray([quest_id]) if newly_discovered else PackedStringArray()
			)
		var start_result: Dictionary = start_quest(working, quest_id, "%s.auto_start" % source)
		if not start_result.get("ok", false):
			return start_result
		return _success(
			start_result["state"],
			PackedStringArray([quest_id]),
			PackedStringArray([quest_id]) if newly_discovered else PackedStringArray()
		)
	var availability_result: Dictionary = sync_availability(working, "%s.gates" % source)
	if not availability_result.get("ok", false):
		return availability_result
	return _success(
		availability_result["state"],
		PackedStringArray(),
		PackedStringArray([quest_id]) if newly_discovered else PackedStringArray(),
		availability_result.get("available", PackedStringArray())
	)


func accept_quest(state: Dictionary, quest_id: String, source: String) -> Dictionary:
	var report: Dictionary = gate_report(state, quest_id)
	if not report.get("known", false):
		return _failure("Unknown quest: %s" % quest_id)
	if not report.get("met", false):
		var reasons: PackedStringArray = PackedStringArray(report.get("visible_failures", []))
		return _failure(reasons[0] if not reasons.is_empty() else "This quest is not available yet.")
	return _simulation.apply_operation(state, "quest.accept", {"quest_id": quest_id, "decision_source": source}, source)


func postpone_quest(state: Dictionary, quest_id: String, source: String) -> Dictionary:
	return _simulation.apply_operation(state, "quest.postpone", {"quest_id": quest_id, "decision_source": source}, source)


func decline_quest(state: Dictionary, quest_id: String, source: String) -> Dictionary:
	return _simulation.apply_operation(state, "quest.decline", {"quest_id": quest_id, "decision_source": source}, source)


func reconsider_quest(state: Dictionary, quest_id: String, source: String) -> Dictionary:
	if quest_id not in state["quest_state"].get("postponed", []):
		return _failure("Quest is not postponed: %s" % quest_id)
	var report: Dictionary = gate_report(state, quest_id)
	if not report.get("met", false):
		var reasons: PackedStringArray = PackedStringArray(report.get("visible_failures", []))
		return _failure(reasons[0] if not reasons.is_empty() else "This quest is not available yet.")
	return _simulation.apply_operation(
		state,
		"quest.set_available",
		{"quest_id": quest_id, "available": true, "reconsider": true, "decision_source": source},
		source
	)


func sync_availability(state: Dictionary, source: String) -> Dictionary:
	var working: Dictionary = state
	var became_available: PackedStringArray = []
	var became_unavailable: PackedStringArray = []
	var quest_state: Dictionary = working["quest_state"]
	for quest_id_value: Variant in quest_state.get("discovered", []):
		var quest_id: String = str(quest_id_value)
		var quest: Variant = _registry.get_content("quests", quest_id)
		if quest is Dictionary and str(quest.get("discovery", {}).get("policy", "offer")) == "auto_start":
			continue
		if quest_id in quest_state.get("active", []) or quest_id in quest_state.get("completed", []) or quest_id in quest_state.get("failed", []) or quest_id in quest_state.get("deferred", []):
			continue
		if quest_id in quest_state.get("postponed", []):
			continue
		var should_be_available: bool = bool(gate_report(working, quest_id).get("met", false))
		var is_available: bool = quest_id in quest_state.get("available", [])
		if should_be_available == is_available:
			continue
		var result: Dictionary = _simulation.apply_operation(
			working,
			"quest.set_available",
			{"quest_id": quest_id, "available": should_be_available},
			source
		)
		if not result.get("ok", false):
			return result
		working = result["state"]
		quest_state = working["quest_state"]
		if should_be_available:
			became_available.append(quest_id)
		else:
			became_unavailable.append(quest_id)
	return {
		"ok": true,
		"state": working,
		"available": became_available,
		"unavailable": became_unavailable,
		"errors": PackedStringArray(),
	}


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
		var activation_result: Dictionary = discover_quest(working, quest_id, "%s.activation" % source)
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
	var availability_result: Dictionary = sync_availability(working, "%s.availability" % source)
	return availability_result if not availability_result.get("ok", false) else _success(availability_result["state"])


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
	var working: Dictionary = result["state"]
	var repeatable: Dictionary = _repeatable_definition(quest)
	if not repeatable.is_empty():
		_record_repeat_completion(working, quest, branch)
		for effect: Variant in repeatable.get("each_completion_effects", []):
			if effect is Dictionary:
				_apply_completion_effect(working, effect)
		if _repeat_completion_count(working, quest_id) < int(repeatable.get("target_completions", 1)):
			working["quest_state"]["completed"].erase(quest_id)
			working["quest_state"]["objectives"][quest_id] = {}
			var repeat_sync: Dictionary = sync_automatic_activations(working, "%s.repeat_restart" % source)
			if not repeat_sync.get("ok", false):
				return repeat_sync
			return _success(
				repeat_sync["state"],
				repeat_sync.get("activated", PackedStringArray()),
				repeat_sync.get("discovered", PackedStringArray()),
				repeat_sync.get("available", PackedStringArray())
			)
	var branch_result: Dictionary = apply_matching_branch(working, quest_id, source)
	if not branch_result.get("ok", false):
		return branch_result
	working = branch_result["state"]

	for effect: Variant in quest.get("completion_effects", []):
		if effect is Dictionary:
			_apply_completion_effect(working, effect)
	var activation_result: Dictionary = sync_automatic_activations(working, "%s.followups" % source)
	if not activation_result.get("ok", false):
		return activation_result
	return _success(
		activation_result["state"],
		activation_result["activated"],
		activation_result.get("discovered", PackedStringArray()),
		activation_result.get("available", PackedStringArray())
	)


func sync_automatic_activations(state: Dictionary, source: String) -> Dictionary:
	var working: Dictionary = state
	var activated: PackedStringArray = []
	var discovered: PackedStringArray = []
	var available: PackedStringArray = []
	for quest_id_value: Variant in working["quest_state"].get("discovered", []).duplicate():
		var repeat_quest_id: String = str(quest_id_value)
		var repeat_quest: Variant = _registry.get_content("quests", repeat_quest_id)
		if not repeat_quest is Dictionary or not _repeat_is_pending(working, repeat_quest):
			continue
		if str(repeat_quest.get("repeatable", {}).get("restart_policy", "offer")) != "auto_start":
			continue
		if not bool(gate_report(working, repeat_quest_id).get("met", false)):
			continue
		var restart_result: Dictionary = start_quest(working, repeat_quest_id, "%s.repeatable" % source)
		if not restart_result.get("ok", false):
			return restart_result
		working = restart_result["state"]
		activated.append(repeat_quest_id)
	for quest: Variant in _registry.get_all("quests"):
		if not quest is Dictionary:
			continue
		var quest_id: String = str(quest.get("id", ""))
		if quest_id.is_empty() or quest_id in working["quest_state"]["active"] or quest_id in working["quest_state"]["completed"]:
			continue
		if quest_id in working["quest_state"].get("failed", []) or quest_id in working["quest_state"].get("deferred", []):
			continue
		if not _state_activation_ready(working, quest):
			continue
		var result: Dictionary = discover_quest(working, quest_id, source)
		if not result.get("ok", false):
			return {"ok": false, "state": state, "activated": PackedStringArray(), "discovered": PackedStringArray(), "available": PackedStringArray(), "errors": result.get("errors", PackedStringArray())}
		working = result["state"]
		activated.append_array(result.get("activated", PackedStringArray()))
		discovered.append_array(result.get("discovered", PackedStringArray()))
		available.append_array(result.get("available", PackedStringArray()))
	var availability_result: Dictionary = sync_availability(working, "%s.availability" % source)
	if not availability_result.get("ok", false):
		return availability_result
	working = availability_result["state"]
	available.append_array(availability_result.get("available", PackedStringArray()))
	return {"ok": true, "state": working, "activated": activated, "discovered": discovered, "available": available, "errors": PackedStringArray()}


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


func get_discovered_quests(state: Dictionary) -> Array:
	return _quest_definitions(state.get("quest_state", {}).get("discovered", []))


func get_available_quests(state: Dictionary) -> Array:
	return _quest_definitions(state.get("quest_state", {}).get("available", []))


func get_progress(state: Dictionary, quest_id: String) -> Dictionary:
	var quest: Variant = _registry.get_content("quests", quest_id)
	if not quest is Dictionary:
		return {}
	var quest_state: Dictionary = state.get("quest_state", {})
	if quest_id not in quest_state.get("discovered", []) and quest_id not in quest_state.get("active", []) and quest_id not in quest_state.get("completed", []) and quest_id not in quest_state.get("failed", []) and quest_id not in quest_state.get("deferred", []):
		return {}
	var completed: Dictionary = state["quest_state"].get("objectives", {}).get(quest_id, {})
	var objectives: Array = []
	for objective: Variant in quest.get("objectives", []):
		if objective is Dictionary:
			var entry: Dictionary = objective.duplicate(true)
			entry["completed"] = bool(completed.get(str(objective.get("id", "")), false))
			objectives.append(entry)
	var repeatable: Dictionary = _repeatable_definition(quest)
	var completion_count: int = _repeat_completion_count(state, quest_id)
	var target_completions: int = int(repeatable.get("target_completions", 1))
	return {
		"quest_id": quest_id,
		"title": quest.get("title", quest_id),
		"active": quest_id in state["quest_state"]["active"],
		"discovered": quest_id in state["quest_state"].get("discovered", []),
		"available": quest_id in state["quest_state"].get("available", []),
		"postponed": quest_id in state["quest_state"].get("postponed", []),
		"completed": quest_id in state["quest_state"]["completed"],
		"repeatable": not repeatable.is_empty(),
		"completion_count": completion_count,
		"target_completions": target_completions,
		"progress_label": str(repeatable.get("progress_label", "Completions")),
		"progress_text": "%d/%d" % [completion_count, target_completions],
		"cooldown_remaining_blocks": _repeat_cooldown_remaining(state, quest_id),
		"chain_id": str(repeatable.get("chain_id", "")),
		"chain_stage": int(repeatable.get("stage", 0)),
		"gates": gate_report(state, quest_id),
		"objectives": objectives,
	}


func gate_report(state: Dictionary, quest_id: String) -> Dictionary:
	var quest: Variant = _registry.get_content("quests", quest_id)
	if not quest is Dictionary:
		return {"known": false, "met": false, "requirements": [], "visible_failures": PackedStringArray(), "has_hidden_failures": false}
	var results: Array = []
	var visible_failures: PackedStringArray = []
	var has_hidden_failures: bool = false
	for requirement_value: Variant in quest.get("requirements", []):
		if not requirement_value is Dictionary:
			continue
		var result: Dictionary = _evaluate_requirement(state, requirement_value)
		results.append(result)
		if bool(result.get("met", false)):
			continue
		if bool(result.get("visible", true)):
			visible_failures.append(str(result.get("reason", "Requirement not met.")))
		else:
			has_hidden_failures = true
	var cooldown_remaining: int = _repeat_cooldown_remaining(state, quest_id)
	if cooldown_remaining > 0:
		var cooldown_result: Dictionary = {
			"type": "repeatable_cooldown",
			"met": false,
			"visible": true,
			"reason": "Available again in %d activity block%s." % [cooldown_remaining, "" if cooldown_remaining == 1 else "s"],
			"current": cooldown_remaining,
		}
		results.append(cooldown_result)
		visible_failures.append(str(cooldown_result["reason"]))
	return {
		"known": true,
		"met": visible_failures.is_empty() and not has_hidden_failures,
		"requirements": results,
		"visible_failures": visible_failures,
		"has_hidden_failures": has_hidden_failures,
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


func _state_activation_ready(state: Dictionary, quest: Dictionary) -> bool:
	var activation: Dictionary = quest.get("activation", {})
	var event_name: String = str(activation.get("event", ""))
	if event_name == "quest_completed":
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
	if event_name == "sandbox_activated":
		return bool(state["player"].get("flags", {}).get("sandbox.active", false))
	if event_name == "location_discovered":
		return str(activation.get("location", "")) in state["world_state"].get("discovered_locations", [])
	if activation.has("value_equals"):
		var equals: Array = activation.get("value_equals", [])
		return equals.size() == 2 and _get_state_value(state, str(equals[0])) == equals[1]
	if activation.has("value_in"):
		var contained: Array = activation.get("value_in", [])
		return contained.size() == 2 and contained[1] is Array and _get_state_value(state, str(contained[0])) in contained[1]
	return false


func _quest_definitions(quest_ids: Array) -> Array:
	var definitions: Array = []
	for quest_id_value: Variant in quest_ids:
		var quest: Variant = _registry.get_content("quests", str(quest_id_value))
		if quest is Dictionary:
			definitions.append(quest)
	return definitions


func _evaluate_requirement(state: Dictionary, requirement: Dictionary) -> Dictionary:
	var requirement_type: String = str(requirement.get("type", ""))
	var visible: bool = str(requirement.get("visibility", "visible")) != "hidden"
	var current: Variant = null
	var met: bool = false
	match requirement_type:
		"attribute":
			current = state["player"].get("attributes", {}).get(str(requirement.get("id", "")), 0)
			met = _number_requirement_met(float(current), requirement)
		"skill":
			current = state["player"].get("skills", {}).get(str(requirement.get("id", "")), 0)
			met = _number_requirement_met(float(current), requirement)
		"relationship":
			var relationship: Dictionary = state["relationships"].get(str(requirement.get("character_id", "")), {})
			var field: String = str(requirement.get("meter", "relationship_level"))
			current = relationship.get(field, 0)
			met = _number_requirement_met(float(current), requirement)
		"prior_choice", "world_state":
			current = _get_state_value(state, str(requirement.get("path", "")))
			met = _value_requirement_met(current, requirement)
		"quest":
			var required_quest: String = str(requirement.get("quest_id", ""))
			var required_status: String = str(requirement.get("status", "completed"))
			current = required_status
			met = required_quest in state["quest_state"].get(required_status, [])
		"location":
			var location_id: String = str(requirement.get("location_id", ""))
			var location_state: String = str(requirement.get("state", "discovered"))
			current = location_state
			if location_state == "current":
				var current_location: String = str(state["world_state"].get("current_location", ""))
				met = current_location == location_id or current_location.begins_with("%s." % location_id)
			elif location_state == "unlocked":
				met = location_id in state["world_state"].get("unlocked_locations", [])
			else:
				met = location_id in state["world_state"].get("discovered_locations", [])
		"life_direction":
			current = state["player"].get("life_path", "undecided")
			met = _value_requirement_met(current, requirement)
		"resource":
			var resource_id: String = str(requirement.get("resource", "money"))
			if resource_id == "money":
				var accounts: Dictionary = state["player"].get("economy", {}).get("accounts", {})
				current = float(accounts.get("wallet_cash", 0.0)) + float(accounts.get("checking", 0.0))
				met = _number_requirement_met(float(current), requirement)
			elif resource_id == "item":
				current = _inventory_quantity(state, str(requirement.get("item_id", "")))
				met = int(current) >= int(requirement.get("minimum", 1))
		_:
			met = false
	var reason: String = str(requirement.get("description", ""))
	if reason.is_empty():
		reason = _default_requirement_reason(requirement_type, requirement)
	return {
		"type": requirement_type,
		"met": met,
		"visible": visible,
		"reason": reason,
		"current": current if visible else null,
	}


func _number_requirement_met(current: float, requirement: Dictionary) -> bool:
	if requirement.has("minimum") and current < float(requirement["minimum"]):
		return false
	if requirement.has("maximum") and current > float(requirement["maximum"]):
		return false
	return true


func _value_requirement_met(current: Variant, requirement: Dictionary) -> bool:
	if requirement.has("equals"):
		return current == requirement["equals"]
	if requirement.get("values") is Array:
		return current in requirement["values"]
	return false


func _inventory_quantity(state: Dictionary, item_id: String) -> int:
	var quantity: int = 0
	for container_value: Variant in state["player"].get("inventory", {}).get("containers", []):
		if not container_value is Dictionary:
			continue
		for stack_value: Variant in container_value.get("items", []):
			if stack_value is Dictionary and str(stack_value.get("item_id", "")) == item_id:
				quantity += int(stack_value.get("quantity", 0))
	return quantity


func _default_requirement_reason(requirement_type: String, requirement: Dictionary) -> String:
	var name: String = str(requirement.get("id", requirement.get("meter", requirement_type))).replace("_", " ").capitalize()
	if requirement.has("minimum"):
		return "%s %s or higher is required." % [name, requirement.get("minimum")]
	if requirement.has("maximum"):
		return "%s must be %s or lower." % [name, requirement.get("maximum")]
	return "A %s requirement is not met yet." % requirement_type.replace("_", " ")


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


func _repeatable_definition(quest: Dictionary) -> Dictionary:
	var definition: Variant = quest.get("repeatable")
	if not definition is Dictionary or int(definition.get("target_completions", 0)) < 2:
		return {}
	return definition


func _ensure_repeatable_progress(state: Dictionary) -> Dictionary:
	var quest_state: Dictionary = state["quest_state"]
	if not quest_state.get("repeatable_progress") is Dictionary:
		quest_state["repeatable_progress"] = {}
	return quest_state["repeatable_progress"]


func _repeat_completion_count(state: Dictionary, quest_id: String) -> int:
	return maxi(int(state.get("quest_state", {}).get("repeatable_progress", {}).get(quest_id, {}).get("completions", 0)), 0)


func _repeat_is_pending(state: Dictionary, quest: Dictionary) -> bool:
	var quest_id: String = str(quest.get("id", ""))
	var target: int = int(_repeatable_definition(quest).get("target_completions", 0))
	var count: int = _repeat_completion_count(state, quest_id)
	return (
		target > 1
		and count > 0
		and count < target
		and quest_id not in state["quest_state"].get("active", [])
		and quest_id not in state["quest_state"].get("completed", [])
		and quest_id not in state["quest_state"].get("failed", [])
		and quest_id not in state["quest_state"].get("deferred", [])
	)


func _record_repeat_completion(state: Dictionary, quest: Dictionary, branch: Dictionary) -> void:
	var quest_id: String = str(quest.get("id", ""))
	var definition: Dictionary = _repeatable_definition(quest)
	var all_progress: Dictionary = _ensure_repeatable_progress(state)
	var entry: Dictionary = all_progress.get(quest_id, {}).duplicate(true)
	var count: int = int(entry.get("completions", 0)) + 1
	var completed_block: int = _clock_block_serial(state["clock"])
	var cooldown_blocks: int = maxi(int(definition.get("cooldown_blocks", 0)), 0)
	entry["completions"] = count
	entry["target_completions"] = int(definition.get("target_completions", 1))
	entry["chain_id"] = str(definition.get("chain_id", ""))
	entry["stage"] = int(definition.get("stage", 0))
	entry["last_completed_at"] = _clock_timestamp(state["clock"])
	entry["last_completed_block"] = completed_block
	entry["cooldown_until_block"] = completed_block + cooldown_blocks
	if not entry.get("completion_history") is Array:
		entry["completion_history"] = []
	entry["completion_history"].append({
		"completion": count,
		"completed_at": entry["last_completed_at"],
		"branch_id": branch.get("id"),
	})
	all_progress[quest_id] = entry


func _repeat_cooldown_remaining(state: Dictionary, quest_id: String) -> int:
	var entry: Variant = state.get("quest_state", {}).get("repeatable_progress", {}).get(quest_id)
	if not entry is Dictionary or int(entry.get("completions", 0)) <= 0:
		return 0
	var quest: Variant = _registry.get_content("quests", quest_id)
	if not quest is Dictionary or not _repeat_is_pending(state, quest):
		return 0
	return maxi(int(entry.get("cooldown_until_block", 0)) - _clock_block_serial(state["clock"]), 0)


func _clock_block_serial(clock: Dictionary) -> int:
	var year: int = maxi(int(clock.get("year", 1)), 1)
	var month: int = clampi(int(clock.get("month", 1)), 1, 12)
	var day: int = maxi(int(clock.get("day", 1)), 1)
	var days: int = 0
	for elapsed_year: int in range(1, year):
		days += 366 if elapsed_year % 4 == 0 else 365
	for elapsed_month: int in range(1, month):
		days += _days_in_month(elapsed_month, year)
	days += day - 1
	return days * BLOCKS.size() + maxi(BLOCKS.find(str(clock.get("block", "early_morning"))), 0)


func _days_in_month(month: int, year: int) -> int:
	if month in [4, 6, 9, 11]:
		return 30
	if month == 2:
		return 29 if year % 4 == 0 else 28
	return 31


func _clock_timestamp(clock: Dictionary) -> String:
	return "Y%d-%02d-%02d:%s+%03d" % [
		int(clock.get("year", 1)), int(clock.get("month", 1)), int(clock.get("day", 1)),
		str(clock.get("block", "early_morning")), int(clock.get("minute_within_block", 0)),
	]


func _apply_completion_effect(state: Dictionary, effect: Dictionary) -> void:
	match str(effect.get("operation", "")):
		"add_meter":
			var character_id: String = str(effect.get("character", ""))
			var meter: String = str(effect.get("meter", ""))
			if state["relationships"].has(character_id) and state["relationships"][character_id].has(meter):
				state["relationships"][character_id][meter] = clampf(
					float(state["relationships"][character_id][meter]) + float(effect.get("value", 0.0)), 0.0, 100.0
				)
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
		"discover_location":
			var location_id: String = str(effect.get("location_id", effect.get("value", "")))
			if not location_id.is_empty() and _registry.get_location(location_id) is Dictionary:
				for collection_name: String in ["unlocked_locations", "discovered_locations"]:
					if location_id not in state["world_state"][collection_name]:
						state["world_state"][collection_name].append(location_id)
				if not state["world_state"].get("location_access") is Dictionary:
					state["world_state"]["location_access"] = {}
				var record: Dictionary = state["world_state"]["location_access"].get(location_id, {})
				for record_key: String in ["sources", "granted_by", "room_grants"]:
					if not record.get(record_key) is Array:
						record[record_key] = []
				if "quest" not in record["sources"]:
					record["sources"].append("quest")
				for room_id: Variant in effect.get("room_ids", []):
					if str(room_id) not in record["room_grants"]:
						record["room_grants"].append(str(room_id))
				state["world_state"]["location_access"][location_id] = record
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
		"create_memory":
			var character_id: String = str(effect.get("character", ""))
			var memory_id: String = str(effect.get("value", effect.get("memory_id", "")))
			if state["relationships"].has(character_id) and not memory_id.is_empty():
				var relationship: Dictionary = state["relationships"][character_id]
				if not relationship.get("memories") is Array:
					relationship["memories"] = []
				var already_recorded: bool = false
				for memory_value: Variant in relationship["memories"]:
					if memory_value is Dictionary and str(memory_value.get("id", "")) == memory_id:
						already_recorded = true
						break
				if not already_recorded:
					relationship["memories"].append({
						"id": memory_id,
						"importance": effect.get("importance", 50),
						"tags": effect.get("tags", []).duplicate(true),
						"created_on": "Y%d-%02d-%02d" % [state["clock"]["year"], state["clock"]["month"], state["clock"]["day"]],
					})
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
	if path.begins_with("player.flags."):
		return state.get("player", {}).get("flags", {}).get(path.trim_prefix("player.flags."))
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
	if event_name == "activity_count_at_least" and int(payload.get("count", 0)) < int(condition.get("value", 1)):
		return false
	for key: String in ["conversation", "node", "character", "participant", "activity", "tag", "key", "mode", "quest", "recipient", "district", "area", "outcome", "thread", "message", "reply"]:
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


func _success(
	state: Dictionary,
	activated: PackedStringArray = PackedStringArray(),
	discovered: PackedStringArray = PackedStringArray(),
	available: PackedStringArray = PackedStringArray()
) -> Dictionary:
	return {
		"ok": true,
		"state": state,
		"activated": activated,
		"discovered": discovered,
		"available": available,
		"errors": PackedStringArray(),
	}


func _failure(message: String) -> Dictionary:
	return {"ok": false, "errors": PackedStringArray([message])}
