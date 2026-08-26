extends Node

signal housing_state_changed
signal housing_error(errors: PackedStringArray)

const SimulationEngineScript: GDScript = preload("res://src/simulation/simulation_engine.gd")
const HousingEngineScript: GDScript = preload("res://src/housing/housing_engine.gd")

var _engine: RefCounted


func _ready() -> void:
	_engine = HousingEngineScript.new(ContentRegistry, SimulationEngineScript.new(ContentRegistry))


func sync_housing() -> Dictionary:
	return _commit(_engine.sync_housing(GameState.current_state))


func list_listings() -> Array:
	return [] if not GameState.has_active_game() else _engine.list_listings(GameState.current_state)


func qualification_report(listing_id: String) -> Dictionary:
	return {} if not GameState.has_active_game() else _engine.qualification_report(GameState.current_state, listing_id)


func acquire(listing_id: String) -> Dictionary:
	return _commit(_engine.acquire(GameState.current_state, listing_id))


func move_to(listing_id: String) -> Dictionary:
	return _commit(_engine.move_to(GameState.current_state, listing_id))


func return_to_family_home() -> Dictionary:
	return _commit(_engine.return_to_family_home(GameState.current_state))


func _commit(result: Dictionary) -> Dictionary:
	if not result.get("ok", false):
		housing_error.emit(result.get("errors", PackedStringArray()))
		return result
	GameState.replace_state(result["state"])
	housing_state_changed.emit()
	return result
