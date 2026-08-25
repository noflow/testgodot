extends Node

signal action_completed(action_id: String, action: Dictionary)
signal action_failed(action_id: String, errors: PackedStringArray)

const SimulationEngineScript: GDScript = preload("res://src/simulation/simulation_engine.gd")
const HomeActionEngineScript: GDScript = preload("res://src/world/home_action_engine.gd")

var _engine: RefCounted


func _ready() -> void:
	var simulation: RefCounted = SimulationEngineScript.new(ContentRegistry)
	_engine = HomeActionEngineScript.new(ContentRegistry, simulation)


func perform(action_id: String) -> Dictionary:
	var result: Dictionary = _engine.perform_action(GameState.current_state, action_id)
	if not result.get("ok", false):
		action_failed.emit(action_id, result.get("errors", PackedStringArray()))
		return result
	GameState.replace_state(result["state"])
	action_completed.emit(action_id, result["action"])
	return result
