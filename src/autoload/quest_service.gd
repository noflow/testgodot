extends Node

signal quest_state_changed(quest_id: String)
signal quest_discovered(quest_id: String)
signal quest_available(quest_id: String)
signal quest_error(errors: PackedStringArray)

const SimulationEngineScript: GDScript = preload("res://src/simulation/simulation_engine.gd")
const QuestEngineScript: GDScript = preload("res://src/quests/quest_engine.gd")

var _engine: RefCounted


func _ready() -> void:
	var simulation: RefCounted = SimulationEngineScript.new(ContentRegistry)
	_engine = QuestEngineScript.new(ContentRegistry, simulation)


func get_active_quests() -> Array:
	return [] if not GameState.has_active_game() else _engine.get_active_quests(GameState.current_state)


func get_discovered_quests() -> Array:
	return [] if not GameState.has_active_game() else _engine.get_discovered_quests(GameState.current_state)


func get_available_quests() -> Array:
	return [] if not GameState.has_active_game() else _engine.get_available_quests(GameState.current_state)


func get_progress(quest_id: String) -> Dictionary:
	return {} if not GameState.has_active_game() else _engine.get_progress(GameState.current_state, quest_id)


func start_quest(quest_id: String, source: String = "gameplay") -> Dictionary:
	return _commit(_engine.start_quest(GameState.current_state, quest_id, source), quest_id)


func accept_quest(quest_id: String) -> Dictionary:
	return _commit(_engine.accept_quest(GameState.current_state, quest_id, "phone.quest_accept"), quest_id)


func postpone_quest(quest_id: String) -> Dictionary:
	return _commit(_engine.postpone_quest(GameState.current_state, quest_id, "phone.quest_postpone"), quest_id)


func decline_quest(quest_id: String) -> Dictionary:
	return _commit(_engine.decline_quest(GameState.current_state, quest_id, "phone.quest_decline"), quest_id)


func reconsider_quest(quest_id: String) -> Dictionary:
	return _commit(_engine.reconsider_quest(GameState.current_state, quest_id, "phone.quest_reconsider"), quest_id)


func gate_report(quest_id: String) -> Dictionary:
	return {} if not GameState.has_active_game() else _engine.gate_report(GameState.current_state, quest_id)


func sync_availability(source: String = "gameplay.quest_availability") -> Dictionary:
	if not GameState.has_active_game():
		return {"ok": false, "errors": PackedStringArray(["No active game."])}
	var result: Dictionary = _engine.sync_availability(GameState.current_state, source)
	if not result.get("ok", false):
		quest_error.emit(result.get("errors", PackedStringArray()))
		return result
	if not result.get("available", PackedStringArray()).is_empty() or not result.get("unavailable", PackedStringArray()).is_empty():
		GameState.replace_state(result["state"])
	for quest_id: String in result.get("available", PackedStringArray()):
		quest_available.emit(quest_id)
		quest_state_changed.emit(quest_id)
	for quest_id: String in result.get("unavailable", PackedStringArray()):
		quest_state_changed.emit(quest_id)
	return result


func set_tracked(quest_id: String, tracked: bool) -> Dictionary:
	if not GameState.has_active_game():
		return {"ok": false, "errors": PackedStringArray(["No active game."])}
	var result: Dictionary = SimulationService.apply_operation(
		"quest.set_tracked",
		{"quest_id": quest_id, "tracked": tracked},
		"phone.quest_tracker"
	)
	if result.get("ok", false):
		quest_state_changed.emit(quest_id)
	else:
		quest_error.emit(result.get("errors", PackedStringArray()))
	return result


func complete_objective(quest_id: String, objective_id: String, source: String = "gameplay") -> Dictionary:
	return _commit(_engine.complete_objective(GameState.current_state, quest_id, objective_id, source), quest_id)


func complete_quest(quest_id: String, source: String = "gameplay") -> Dictionary:
	return _commit(_engine.complete_quest(GameState.current_state, quest_id, source), quest_id)


func sync_automatic_activations(source: String = "gameplay.quest_sync") -> Dictionary:
	if not GameState.has_active_game():
		return {"ok": false, "activated": PackedStringArray(), "errors": PackedStringArray(["No active game."])}
	var result: Dictionary = _engine.sync_automatic_activations(GameState.current_state, source)
	if not result.get("ok", false):
		quest_error.emit(result.get("errors", PackedStringArray()))
		return result
	var activated: PackedStringArray = result.get("activated", PackedStringArray())
	var discovered: PackedStringArray = result.get("discovered", PackedStringArray())
	var available: PackedStringArray = result.get("available", PackedStringArray())
	if activated.is_empty() and discovered.is_empty() and available.is_empty() and result.get("unavailable", PackedStringArray()).is_empty():
		return result
	GameState.replace_state(result["state"])
	for quest_id: String in discovered:
		quest_discovered.emit(quest_id)
		quest_state_changed.emit(quest_id)
	for quest_id: String in available:
		quest_available.emit(quest_id)
		quest_state_changed.emit(quest_id)
	for quest_id: String in activated:
		quest_state_changed.emit(quest_id)
	return result


func record_event(event_name: String, payload: Dictionary = {}, source: String = "gameplay.event") -> Dictionary:
	if not GameState.has_active_game():
		return {"ok": false, "errors": PackedStringArray(["No active game."])}
	var previously_discovered: Array = GameState.current_state["quest_state"].get("discovered", []).duplicate()
	var previously_available: Array = GameState.current_state["quest_state"].get("available", []).duplicate()
	var result: Dictionary = _engine.record_event(GameState.current_state, event_name, payload, source)
	if not result.get("ok", false):
		quest_error.emit(result.get("errors", PackedStringArray()))
		return result
	GameState.replace_state(result["state"])
	for quest_id: Variant in GameState.current_state["quest_state"].get("discovered", []):
		if quest_id not in previously_discovered:
			quest_discovered.emit(str(quest_id))
			quest_state_changed.emit(str(quest_id))
	for quest_id: Variant in GameState.current_state["quest_state"].get("available", []):
		if quest_id not in previously_available:
			quest_available.emit(str(quest_id))
			quest_state_changed.emit(str(quest_id))
	for quest_id: Variant in GameState.current_state["quest_state"].get("active", []):
		quest_state_changed.emit(str(quest_id))
	return result


func _commit(result: Dictionary, quest_id: String) -> Dictionary:
	if not result.get("ok", false):
		quest_error.emit(result.get("errors", PackedStringArray()))
		return result
	GameState.replace_state(result["state"])
	for discovered_id: String in result.get("discovered", PackedStringArray()):
		quest_discovered.emit(discovered_id)
	for available_id: String in result.get("available", PackedStringArray()):
		quest_available.emit(available_id)
	quest_state_changed.emit(quest_id)
	for activated_id: String in result.get("activated", PackedStringArray()):
		if activated_id != quest_id:
			quest_state_changed.emit(activated_id)
	return result
