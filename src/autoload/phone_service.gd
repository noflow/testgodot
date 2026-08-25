extends Node

signal phone_state_changed
signal phone_error(errors: PackedStringArray)

const SimulationEngineScript: GDScript = preload("res://src/simulation/simulation_engine.gd")
const PhoneEngineScript: GDScript = preload("res://src/phone/phone_engine.gd")

var _engine: RefCounted


func _ready() -> void:
	var simulation: RefCounted = SimulationEngineScript.new(ContentRegistry)
	_engine = PhoneEngineScript.new(ContentRegistry, simulation)


func sync_messages() -> Dictionary:
	return _commit(_engine.sync_triggered_messages(GameState.current_state))


func reply_to_message(character_id: String, message_id: String, reply_index: int) -> Dictionary:
	return _commit(_engine.reply_to_message(GameState.current_state, character_id, message_id, reply_index))


func mark_thread_read(character_id: String) -> Dictionary:
	return _commit(_engine.mark_thread_read(GameState.current_state, character_id))


func _commit(result: Dictionary) -> Dictionary:
	if not result.get("ok", false):
		phone_error.emit(result.get("errors", PackedStringArray()))
		return result
	GameState.replace_state(result["state"])
	phone_state_changed.emit()
	return result
