extends Node

signal view_changed(view: Dictionary)
signal conversation_finished(conversation_id: String)
signal dialogue_error(errors: PackedStringArray)

const SimulationEngineScript: GDScript = preload("res://src/simulation/simulation_engine.gd")
const QuestEngineScript: GDScript = preload("res://src/quests/quest_engine.gd")
const DialogueEngineScript: GDScript = preload("res://src/dialogue/dialogue_engine.gd")

var _engine: RefCounted


func _ready() -> void:
	var simulation: RefCounted = SimulationEngineScript.new(ContentRegistry)
	var quests: RefCounted = QuestEngineScript.new(ContentRegistry, simulation)
	_engine = DialogueEngineScript.new(ContentRegistry, simulation, quests)


func begin(conversation_id: String) -> Dictionary:
	return _commit_result(_engine.begin(GameState.current_state, conversation_id), conversation_id)


func can_begin(conversation_id: String) -> Dictionary:
	if not GameState.has_active_game():
		return {"ok": false, "reason": "No active game."}
	return _engine.can_begin(GameState.current_state, conversation_id)


func resume() -> Dictionary:
	return _engine.resume(GameState.current_state)


func advance() -> Dictionary:
	var active_id: String = _active_conversation_id()
	return _commit_result(_engine.advance(GameState.current_state), active_id)


func choose(choice_id: String) -> Dictionary:
	var active_id: String = _active_conversation_id()
	return _commit_result(_engine.choose(GameState.current_state, choice_id), active_id)


func get_view() -> Dictionary:
	return _engine.get_view(GameState.current_state)


func _commit_result(result: Dictionary, conversation_id: String) -> Dictionary:
	if not result.get("ok", false):
		dialogue_error.emit(result.get("errors", PackedStringArray()))
		return result
	GameState.replace_state(result["state"])
	if result.get("ended", false):
		conversation_finished.emit(conversation_id)
	else:
		view_changed.emit(result["view"].duplicate(true))
	return result


func _active_conversation_id() -> String:
	var active: Variant = GameState.current_state.get("conversation_state", {}).get("active")
	return "" if not active is Dictionary else str(active.get("conversation_id", ""))
