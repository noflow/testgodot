extends Node

signal education_state_changed
signal education_error(errors: PackedStringArray)

const SimulationEngineScript: GDScript = preload("res://src/simulation/simulation_engine.gd")
const EducationEngineScript: GDScript = preload("res://src/education/education_engine.gd")

var _engine: RefCounted


func _ready() -> void:
	_engine = EducationEngineScript.new(ContentRegistry, SimulationEngineScript.new(ContentRegistry))


func sync_education() -> Dictionary:
	if not GameState.has_active_game():
		return {"ok": false, "errors": PackedStringArray(["No active game."])}
	return _commit(_engine.sync_education(GameState.current_state))


func class_status() -> Dictionary:
	return {"ready": false, "reason": "No active game."} if not GameState.has_active_game() else _engine.class_status(GameState.current_state)


func attend_class(approach_id: String = "balanced") -> Dictionary:
	return _commit(_engine.attend_class(GameState.current_state, approach_id))


func study_course(course_id: String, effort_id: String = "standard") -> Dictionary:
	return _commit(_engine.study_course(GameState.current_state, course_id, effort_id))


func complete_assessment(assessment_id: String, effort_id: String = "standard") -> Dictionary:
	return _commit(_engine.complete_assessment(GameState.current_state, assessment_id, effort_id))


func upcoming_assessments(limit: int = 8) -> Array:
	return [] if not GameState.has_active_game() else _engine.upcoming_assessments(GameState.current_state, limit)


func _commit(result: Dictionary) -> Dictionary:
	if not result.get("ok", false):
		education_error.emit(result.get("errors", PackedStringArray()))
		return result
	GameState.replace_state(result["state"])
	education_state_changed.emit()
	return result
