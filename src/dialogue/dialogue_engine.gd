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
	return _enter_node(result["state"], conversation, str(conversation["start_node"]))


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
	return _success(working, _make_view(working, conversation))


func _finish(state: Dictionary, conversation: Dictionary) -> Dictionary:
	var result: Dictionary = _simulation.apply_operation(
		state,
		"conversation.end",
		{"conversation_id": conversation["id"], "outcome": "completed"},
		"dialogue.end"
	)
	if not result.get("ok", false):
		return result
	return {"ok": true, "state": result["state"], "ended": true, "view": {}, "errors": PackedStringArray()}


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
				"amount": effect.get("value", 0),
				"reason": source,
			}, source)
		"start_quest":
			return _quests.start_quest(state, str(effect.get("value", "")), source)
		"complete_objective", "complete_objective_if_active":
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
			return _success(changed)
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
		"create_memory":
			return _simulation.apply_operation(state, "memory.create", {
				"character_id": effect.get("character"),
				"memory_id": effect.get("value"),
				"importance": effect.get("importance", 50),
				"tags": effect.get("tags", []),
			}, source)
		"spend_money":
			return _spend_money(state, float(effect.get("value", 0)), source)
		"schedule_event":
			var scheduled: Dictionary = state.duplicate(true)
			scheduled["calendar_state"]["events"].append(effect.get("value", {}).duplicate(true))
			return _success(scheduled)
		"complete_conversation", "create_calendar_from_class_schedule":
			return _success(state)
		_:
			return _failure("Unsupported dialogue effect: %s" % effect.get("operation", ""), state)


func _spend_money(state: Dictionary, amount: float, source: String) -> Dictionary:
	var remaining: float = amount
	var working: Dictionary = state
	for account_id: String in ["wallet_cash", "checking", "savings"]:
		var balance: float = float(working["player"]["economy"]["accounts"].get(account_id, 0.0))
		var debit: float = minf(balance, remaining)
		if debit > 0.0:
			var result: Dictionary = _simulation.apply_operation(working, "economy.transaction", {
				"account": account_id,
				"amount": -debit,
				"type": "debit",
				"category": "dialogue_purchase",
				"description": source,
			}, source)
			if not result.get("ok", false):
				return result
			working = result["state"]
			remaining -= debit
	if remaining > 0.0:
		return _failure("Insufficient available funds.", state)
	return _success(working)


func _activation_error(state: Dictionary, conversation: Dictionary) -> String:
	var activation: Dictionary = conversation.get("activation", {})
	if activation.has("quest_active") and str(activation["quest_active"]) not in state["quest_state"]["active"]:
		return "Required quest is not active."
	if activation.has("location") and str(activation["location"]) != str(state["world_state"]["current_location"]):
		return "Conversation is unavailable at the current location."
	if activation.has("block") and str(activation["block"]) != str(state["clock"]["block"]):
		return "Conversation is unavailable during this activity block."
	return ""


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
		"line": _resolve_tokens(str(node.get("line", "")), state),
		"stage_direction": _resolve_tokens(str(node.get("stage_direction", "")), state),
		"choices": choices,
		"can_advance": choices.is_empty(),
	}


func _visible_choices(state: Dictionary, node: Dictionary) -> Array:
	var visible: Array = []
	for choice: Variant in node.get("choices", []):
		if choice is Dictionary and _conditions_pass(state, choice.get("conditions", [])):
			visible.append(choice)
	return visible


func _conditions_pass(state: Dictionary, conditions: Array) -> bool:
	for condition: Variant in conditions:
		if not condition is Dictionary:
			continue
		if condition.has("money_at_least"):
			var accounts: Dictionary = state["player"]["economy"]["accounts"]
			var available: float = float(accounts.get("wallet_cash", 0)) + float(accounts.get("checking", 0)) + float(accounts.get("savings", 0))
			if available < float(condition["money_at_least"]):
				return false
		if condition.has("value_equals"):
			var comparison: Array = condition["value_equals"]
			if comparison.size() != 2 or _get_state_value(state, str(comparison[0])) != comparison[1]:
				return false
	return true


func _set_state_value(state: Dictionary, path: String, value: Variant) -> void:
	if path.begins_with("education.") or path.begins_with("employment.") or path.begins_with("economy."):
		path = "player.%s" % path
	var parts: PackedStringArray = path.split(".")
	var current: Dictionary = state
	for index: int in range(parts.size() - 1):
		if not current.has(parts[index]) or not current[parts[index]] is Dictionary:
			current[parts[index]] = {}
		current = current[parts[index]]
	current[parts[-1]] = value


func _get_state_value(state: Dictionary, path: String) -> Variant:
	if path.begins_with("education.") or path.begins_with("employment.") or path.begins_with("economy."):
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
