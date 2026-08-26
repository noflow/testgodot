extends Node

signal employment_state_changed
signal employment_error(errors: PackedStringArray)

const SimulationEngineScript: GDScript = preload("res://src/simulation/simulation_engine.gd")
const QuestEngineScript: GDScript = preload("res://src/quests/quest_engine.gd")
const EmploymentEngineScript: GDScript = preload("res://src/employment/employment_engine.gd")

var _engine: RefCounted


func _ready() -> void:
	var simulation: RefCounted = SimulationEngineScript.new(ContentRegistry)
	var quests: RefCounted = QuestEngineScript.new(ContentRegistry, simulation)
	_engine = EmploymentEngineScript.new(ContentRegistry, simulation, quests)


func get_listings(filter_id: String = "all") -> Array:
	return [] if not GameState.has_active_game() else _engine.get_listings(GameState.current_state, filter_id)


func qualification_report(job_id: String) -> Dictionary:
	if not GameState.has_active_game():
		return {}
	var job: Variant = ContentRegistry.get_content("jobs", job_id)
	return {} if not job is Dictionary else _engine.qualification_report(GameState.current_state, job)


func compatible_schedules(job_id: String, requested_type: String = "all") -> Array:
	return [] if not GameState.has_active_game() else _engine.compatible_schedules(GameState.current_state, job_id, requested_type)


func record_listings_viewed(filter_id: String) -> Dictionary:
	return _commit(_engine.record_listings_viewed(GameState.current_state, filter_id))


func save_availability() -> Dictionary:
	return _commit(_engine.save_availability(GameState.current_state))


func apply_to_job(job_id: String, requested_type: String) -> Dictionary:
	return _commit(_engine.apply_to_job(GameState.current_state, job_id, requested_type))


func interview_ready(job_id: String) -> Dictionary:
	return {"ready": false, "reason": "No active game."} if not GameState.has_active_game() else _engine.interview_ready(GameState.current_state, job_id)


func complete_interview(job_id: String, answer_quality: int) -> Dictionary:
	return _commit(_engine.complete_interview(GameState.current_state, job_id, answer_quality))


func accept_offer(job_id: String, schedule_id: String) -> Dictionary:
	return _commit(_engine.accept_offer(GameState.current_state, job_id, schedule_id))


func sync_employment() -> Dictionary:
	return _commit(_engine.sync_employment(GameState.current_state))


func shift_status(job_id: String) -> Dictionary:
	return {"ready": false, "reason": "No active game."} if not GameState.has_active_game() else _engine.shift_status(GameState.current_state, job_id)


func perform_shift(job_id: String, approach_id: String) -> Dictionary:
	return _commit(_engine.perform_shift(GameState.current_state, job_id, approach_id))


func career_review_status(job_id: String) -> Dictionary:
	return {"due": false, "reason": "No active game."} if not GameState.has_active_game() else _engine.career_review_status(GameState.current_state, job_id)


func process_career_review(job_id: String) -> Dictionary:
	return _commit(_engine.process_career_review(GameState.current_state, job_id))


func accept_promotion(job_id: String) -> Dictionary:
	return _commit(_engine.accept_promotion(GameState.current_state, job_id))


func _commit(result: Dictionary) -> Dictionary:
	if not result.get("ok", false):
		employment_error.emit(result.get("errors", PackedStringArray()))
		return result
	GameState.replace_state(result["state"])
	employment_state_changed.emit()
	return result
