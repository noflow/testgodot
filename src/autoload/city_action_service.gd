extends Node

signal activity_completed(interaction_id: String, interaction: Dictionary)
signal activity_failed(interaction_id: String, errors: PackedStringArray)

const SimulationEngineScript: GDScript = preload("res://src/simulation/simulation_engine.gd")
const QuestEngineScript: GDScript = preload("res://src/quests/quest_engine.gd")
const CityActionEngineScript: GDScript = preload("res://src/world/city_action_engine.gd")

var _engine: RefCounted


func _ready() -> void:
	var simulation: RefCounted = SimulationEngineScript.new(ContentRegistry)
	var quests: RefCounted = QuestEngineScript.new(ContentRegistry, simulation)
	_engine = CityActionEngineScript.new(ContentRegistry, simulation, quests)


func interactions_for_room(location_id: String, room_id: String) -> Array:
	if not GameState.has_active_game():
		return []
	return _engine.interactions_for_room(GameState.current_state, location_id, room_id)


func perform(interaction_id: String) -> Dictionary:
	var result: Dictionary = _engine.perform_activity(GameState.current_state, interaction_id)
	if not result.get("ok", false):
		activity_failed.emit(interaction_id, result.get("errors", PackedStringArray()))
		return result
	GameState.replace_state(result["state"])
	activity_completed.emit(interaction_id, result["interaction"])
	return result
