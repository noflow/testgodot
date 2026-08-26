extends Node

signal relationship_state_changed
signal relationship_error(errors: PackedStringArray)

const SimulationEngineScript: GDScript = preload("res://src/simulation/simulation_engine.gd")
const RelationshipEngineScript: GDScript = preload("res://src/relationships/relationship_engine.gd")

var _engine: RefCounted


func _ready() -> void:
	var simulation: RefCounted = SimulationEngineScript.new(ContentRegistry)
	_engine = RelationshipEngineScript.new(ContentRegistry, simulation)


func sync_dates() -> Dictionary:
	return _commit(_engine.synchronize(GameState.current_state))


func candidates() -> Array:
	return _engine.candidates(GameState.current_state)


func relationship_profile(character_id: String) -> Dictionary:
	return _engine.relationship_profile(GameState.current_state, character_id)


func invitation_options(character_id: String, activity_id: String, maximum: int = 3) -> Array:
	return _engine.invitation_options(GameState.current_state, character_id, activity_id, maximum)


func ask_out(
	character_id: String,
	activity_id: String,
	date: String,
	weekday: String,
	block: String,
	disclose_to_partners: bool = true
) -> Dictionary:
	return _commit(_engine.ask_out(
		GameState.current_state, character_id, activity_id, date, weekday, block, disclose_to_partners
	))


func date_status(character_id: String) -> Dictionary:
	return _engine.date_status(GameState.current_state, character_id)


func complete_date(event_id: String, approach_id: String) -> Dictionary:
	return _commit(_engine.complete_date(GameState.current_state, event_id, approach_id))


func cancel_date(event_id: String) -> Dictionary:
	return _commit(_engine.cancel_date(GameState.current_state, event_id))


func can_propose_agreement(character_id: String) -> Dictionary:
	return _engine.can_propose_agreement(GameState.current_state, character_id)


func propose_agreement(character_id: String, agreement_type: String) -> Dictionary:
	return _commit(_engine.propose_agreement(GameState.current_state, character_id, agreement_type))


func respond_to_npc_proposal(character_id: String, accept: bool) -> Dictionary:
	return _commit(_engine.respond_to_npc_proposal(GameState.current_state, character_id, accept))


func is_date_event(event_id: String) -> bool:
	return _engine.is_date_event(GameState.current_state, event_id)


func active_partner_ids(excluding_character: String = "") -> Array:
	return _engine.active_partner_ids(GameState.current_state, excluding_character)


func _commit(result: Dictionary) -> Dictionary:
	if not result.get("ok", false):
		relationship_error.emit(result.get("errors", PackedStringArray()))
		return result
	GameState.replace_state(result["state"])
	relationship_state_changed.emit()
	return result
