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
		"economy.transaction":
			return _apply_transaction(state, payload)
		"inventory.add":
			return _adjust_inventory(state, payload, 1)
		"inventory.remove":
			return _adjust_inventory(state, payload, -1)
		"inventory.equip":
			return _equip_inventory(state, payload)
		"inventory.clean_container":
			return _clean_inventory_container(state, payload)
		"quest.start":
			return _start_quest(state, payload)
		"quest.objective_complete":
			return _complete_objective(state, payload)
		"quest.complete":
			return _complete_quest(state, payload)
		"conversation.begin":
			return _begin_conversation(state, payload)
		"conversation.choose":
			return _record_conversation_choice(state, payload)
		"conversation.end":
			return _end_conversation(state, payload)
		"memory.create":
			return _create_memory(state, payload)
		"travel.complete":
			return _complete_travel(state, payload)
		"world.unlock_location":
			return _unlock_location(state, payload)
		_:
			return "Operation is registered but not implemented yet: %s" % operation


func _apply_time_advance(state: Dictionary, payload: Dictionary) -> String:
	var clock_result: Dictionary = _clock.advance(state["clock"], payload)
	if not clock_result.get("ok", false):
		return str(clock_result.get("error", "Unable to advance time."))

	_apply_passive_needs(state, int(clock_result["minutes_advanced"]))
	var simulation: Dictionary = state["simulation"]
	if int(clock_result["days_crossed"]) > 0:
		simulation["last_daily_tick"] = _date_string(state["clock"])
	if int(clock_result["weeks_crossed"]) > 0:
		simulation["last_weekly_tick"] = int(state["clock"]["week_number"])
	if int(clock_result["months_crossed"]) > 0:
		simulation["last_monthly_tick"] = "Y%d-%02d" % [state["clock"]["year"], state["clock"]["month"]]
	return ""


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
	ledger_entry["date"] = _date_string(state["clock"])
	state["player"]["economy"]["ledger"].append(ledger_entry)
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


func _start_quest(state: Dictionary, payload: Dictionary) -> String:
	var quest_id: String = str(payload.get("quest_id", ""))
	if _registry.get_content("quests", quest_id) == null:
		return "Unknown quest: %s" % quest_id
	var quest_state: Dictionary = state["quest_state"]
	if quest_id in quest_state["active"] or quest_id in quest_state["completed"]:
		return "Quest is already active or completed: %s" % quest_id
	quest_state["active"].append(quest_id)
	quest_state["objectives"][quest_id] = {}
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
	quest_state["completed"].append(quest_id)
	quest_state["branch_history"].append({
		"quest_id": quest_id,
		"branch_id": payload.get("branch_id"),
		"completed_on": _date_string(state["clock"]),
	})
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


func _complete_travel(state: Dictionary, payload: Dictionary) -> String:
	var destination: String = str(payload.get("destination", ""))
	var location_id: String = destination.get_slice(".", 0)
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
	if location_id not in state["world_state"]["discovered_locations"]:
		state["world_state"]["discovered_locations"].append(location_id)
	return ""


func _unlock_location(state: Dictionary, payload: Dictionary) -> String:
	var location_id: String = str(payload.get("location_id", ""))
	if _registry.get_location(location_id) == null:
		return "Unknown location: %s" % location_id
	if location_id not in state["world_state"]["unlocked_locations"]:
		state["world_state"]["unlocked_locations"].append(location_id)
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
