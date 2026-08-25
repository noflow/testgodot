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


func complete_objective(quest_id: String, objective_id: String, source: String = "gameplay") -> Dictionary:
	return _commit(_engine.complete_objective(GameState.current_state, quest_id, objective_id, source), quest_id)


func complete_quest(quest_id: String, source: String = "gameplay") -> Dictionary:
	return _commit(_engine.complete_quest(GameState.current_state, quest_id, source), quest_id)


func _commit(result: Dictionary, quest_id: String) -> Dictionary:
	if not result.get("ok", false):
		quest_error.emit(result.get("errors", PackedStringArray()))
		return result
	GameState.replace_state(result["state"])
	quest_state_changed.emit(quest_id)
	return result
