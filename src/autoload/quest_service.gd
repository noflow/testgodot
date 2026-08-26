extends Node

signal quest_state_changed(quest_id: String)
signal quest_error(errors: PackedStringArray)

const SimulationEngineScript: GDScript = preload("res://src/simulation/simulation_engine.gd")
const QuestEngineScript: GDScript = preload("res://src/quests/quest_engine.gd")

var _engine: RefCounted


func _ready() -> void:
	var simulation: RefCounted = SimulationEngineScript.new(ContentRegistry)
	_engine = QuestEngineScript.new(ContentRegistry, simulation)


func get_active_quests() -> Array:
	return [] if not GameState.has_active_game() else _engine.get_active_quests(GameState.current_state)


func get_progress(quest_id: String) -> Dictionary:
	return {} if not GameState.has_active_game() else _engine.get_progress(GameState.current_state, quest_id)


func start_quest(quest_id: String, source: String = "gameplay") -> Dictionary:
	return _commit(_engine.start_quest(GameState.current_state, quest_id, source), quest_id)


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
	if activated.is_empty():
		return result
	GameState.replace_state(result["state"])
	for quest_id: String in activated:
		quest_state_changed.emit(quest_id)
	return result


func record_event(event_name: String, payload: Dictionary = {}, source: String = "gameplay.event") -> Dictionary:
	if not GameState.has_active_game():
		return {"ok": false, "errors": PackedStringArray(["No active game."])}
	var result: Dictionary = _engine.record_event(GameState.current_state, event_name, payload, source)
	if not result.get("ok", false):
		quest_error.emit(result.get("errors", PackedStringArray()))
		return result
	GameState.replace_state(result["state"])
	for quest_id: Variant in GameState.current_state["quest_state"].get("active", []):
		quest_state_changed.emit(str(quest_id))
	return result


func _commit(result: Dictionary, quest_id: String) -> Dictionary:
	if not result.get("ok", false):
		quest_error.emit(result.get("errors", PackedStringArray()))
		return result
	GameState.replace_state(result["state"])
	quest_state_changed.emit(quest_id)
	for activated_id: String in result.get("activated", PackedStringArray()):
		if activated_id != quest_id:
			quest_state_changed.emit(activated_id)
	return result
