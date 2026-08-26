extends Node

signal travel_completed(destination: String, route: Dictionary)
signal travel_state_changed
signal travel_error(errors: PackedStringArray)

const SimulationEngineScript: GDScript = preload("res://src/simulation/simulation_engine.gd")
const QuestEngineScript: GDScript = preload("res://src/quests/quest_engine.gd")
const TravelEngineScript: GDScript = preload("res://src/world/travel_engine.gd")

var _engine: RefCounted


func _ready() -> void:
	var simulation: RefCounted = SimulationEngineScript.new(ContentRegistry)
	var quests: RefCounted = QuestEngineScript.new(ContentRegistry, simulation)
	_engine = TravelEngineScript.new(ContentRegistry, simulation, quests)


func plan_routes(destination: String) -> Dictionary:
	return _engine.plan_routes(GameState.current_state, destination)


func travel(destination: String, mode: String, source: String = "phone.city_map") -> Dictionary:
	var result: Dictionary = _engine.execute_travel(GameState.current_state, destination, mode, source)
	if not _commit(result):
		return result
	travel_completed.emit(str(result["destination"]), result["route"].duplicate(true))
	return result


func start_transportation_tutorial(source: String = "world.first_exit") -> Dictionary:
	var result: Dictionary = _engine.start_transportation_tutorial(GameState.current_state, source)
	_commit(result)
	return result


func record_map_viewed(source: String = "phone.city_map") -> Dictionary:
	var result: Dictionary = _engine.record_map_viewed(GameState.current_state, source)
	_commit(result)
	return result


func record_routes_viewed(destination: String, modes: PackedStringArray, source: String = "phone.route_planner") -> Dictionary:
	var result: Dictionary = _engine.record_routes_viewed(GameState.current_state, destination, modes, source)
	_commit(result)
	return result


func _commit(result: Dictionary) -> bool:
	if not result.get("ok", false):
		travel_error.emit(result.get("errors", PackedStringArray()))
		return false
	if bool(result.get("changed", true)):
		GameState.replace_state(result["state"])
		travel_state_changed.emit()
	return true
