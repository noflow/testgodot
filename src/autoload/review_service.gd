extends Node

signal review_state_changed
signal review_error(errors: PackedStringArray)

const SimulationEngineScript: GDScript = preload("res://src/simulation/simulation_engine.gd")
const WeeklyReviewEngineScript: GDScript = preload("res://src/review/weekly_review_engine.gd")

var _engine: RefCounted


func _ready() -> void:
	_engine = WeeklyReviewEngineScript.new(ContentRegistry, SimulationEngineScript.new(ContentRegistry))


func review_status() -> Dictionary:
	return {"due": false, "pending": false} if not GameState.has_active_game() else _engine.review_status(GameState.current_state)


func synchronize() -> Dictionary:
	return _commit(_engine.synchronize(GameState.current_state))


func current_review() -> Dictionary:
	return {} if not GameState.has_active_game() else _engine.current_review(GameState.current_state)


func priority_definitions() -> Array:
	return _engine.priority_definitions()


func toggle_priority(priority_id: String) -> Dictionary:
	return _commit(_engine.toggle_priority(GameState.current_state, priority_id))


func complete_review(keep_priorities: bool = true) -> Dictionary:
	return _commit(_engine.complete_review(GameState.current_state, keep_priorities))


func _commit(result: Dictionary) -> Dictionary:
	if not result.get("ok", false):
		review_error.emit(result.get("errors", PackedStringArray()))
		return result
	GameState.replace_state(result["state"])
	review_state_changed.emit()
	return result
