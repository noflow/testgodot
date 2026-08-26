extends RefCounted
class_name PortAlderEducationEngine

const GameClockScript: GDScript = preload("res://src/simulation/game_clock.gd")
const COURSEWORK_LOCATIONS: PackedStringArray = [
	"hale_home.player_bedroom", "hale_home.dining_room", "westshore_campus.library",
]

var _registry: Node
var _simulation: RefCounted


func _init(content_registry: Node, simulation_engine: RefCounted) -> void:
	_registry = content_registry
	_simulation = simulation_engine


func sync_education(state: Dictionary) -> Dictionary:
	if state.is_empty():
		return _failure("No active runtime state.")
	var working: Dictionary = state.duplicate(true)
	if not bool(working["player"]["education"].get("enrolled", false)):
		return _success(working, {"notices": PackedStringArray(), "missed_classes": 0, "missed_assessments": 0})
	_ensure_education_shape(working)
	_initialize_assessments(working)
	_update_semester_phase(working)
	var notices: PackedStringArray = []
	var missed_classes_result: Dictionary = _process_missed_classes(working)
	if not missed_classes_result.get("ok", false):
		return missed_classes_result
	working = missed_classes_result["state"]
	for notice: Variant in missed_classes_result.get("data", {}).get("notices", []):
		notices.append(str(notice))
	var missed_assessments_result: Dictionary = _process_missed_assessments(working)
	if not missed_assessments_result.get("ok", false):
		return missed_assessments_result
	working = missed_assessments_result["state"]
	for notice: Variant in missed_assessments_result.get("data", {}).get("notices", []):
		notices.append(str(notice))
	_recalculate_grades(working, false)
	_update_academic_standing(working, false)
	if _date_serial_from_string(_date_string(working["clock"])) > _date_serial_from_string(str(working["player"]["education"]["semester"].get("term_complete", "Y1-12-20"))):
		var final_result: Dictionary = _finalize_semester(working)
		if not final_result.get("ok", false):
			return final_result
		working = final_result["state"]
		for notice: Variant in final_result.get("data", {}).get("notices", []):
			notices.append(str(notice))
	working["player"]["education"]["last_sync_date"] = _date_string(working["clock"])
	return _success(working, {
		"notices": notices,
		"missed_classes": int(missed_classes_result.get("data", {}).get("count", 0)),
		"missed_assessments": int(missed_assessments_result.get("data", {}).get("count", 0)),
	})


func class_status(state: Dictionary) -> Dictionary:
	if not bool(state.get("player", {}).get("education", {}).get("enrolled", false)):
		return {"ready": false, "reason": "You are not enrolled at Westshore."}
	var current_event: Dictionary = {}
	var next_event: Dictionary = {}
	var next_value: int = 2147483647
	var current_value: int = _clock_serial_blocks(state["clock"])
	for event_value: Variant in state["calendar_state"].get("events", []):
		if not event_value is Dictionary:
			continue
		var event: Dictionary = event_value
		if str(event.get("type", "")) != "class" or str(event.get("status", "scheduled")) != "scheduled" or str(event.get("course_id", "")) not in state["player"]["education"].get("courses", []):
			continue
		var event_value_serial: int = _event_serial_blocks(event)
		if event_value_serial == current_value:
			current_event = event
			break
		if event_value_serial > current_value and event_value_serial < next_value:
			next_value = event_value_serial
			next_event = event
	if current_event.is_empty():
		return {"ready": false, "reason": "No class is scheduled in the current activity block.", "next_event": next_event}
	var maximum_late: int = int(_academic_rules().get("attendance", {}).get("maximum_late_minutes", 60))
	if int(state["clock"].get("minute_within_block", 0)) > maximum_late:
		return {"ready": false, "reason": "The class attendance window has closed.", "event": current_event, "next_event": next_event}
	var required_location: String = str(current_event.get("location", "westshore_campus.classrooms"))
	var current_location: String = str(state["world_state"].get("current_location", ""))
	if current_location != required_location:
		return {"ready": false, "reason": "Go to %s before class." % _location_label(required_location), "event": current_event, "next_event": next_event}
	return {"ready": true, "reason": "", "event": current_event, "next_event": next_event}


func attend_class(state: Dictionary, approach_id: String = "balanced") -> Dictionary:
	var synced: Dictionary = sync_education(state)
	if not synced.get("ok", false):
		return synced
	var working: Dictionary = synced["state"]
	var status: Dictionary = class_status(working)
	if not bool(status.get("ready", false)):
		return _failure(str(status.get("reason", "No class can be attended right now.")))
	var approaches: Dictionary = _academic_rules().get("class_approaches", {})
	if not approaches.has(approach_id):
		return _failure("Unknown class approach: %s" % approach_id)
	var approach: Dictionary = approaches[approach_id]
	var event: Dictionary = status["event"]
	var course_id: String = str(event.get("course_id", ""))
	var course: Dictionary = _course(course_id)
	var minutes_late: int = int(working["clock"].get("minute_within_block", 0))
	var late_after: int = int(_academic_rules().get("attendance", {}).get("late_after_minutes", 15))
	var attendance_status: String = "late" if minutes_late > late_after else "present"
	var performance: float = _class_performance(working, course, approach, attendance_status)
	var record: Dictionary = {
		"id": "attendance-%s" % str(event.get("id", "class")),
		"course_id": course_id,
		"calendar_event_id": event.get("id"),
		"date": event.get("date"),
		"block": event.get("block"),
		"status": attendance_status,
		"minutes_late": minutes_late,
		"performance": performance,
		"approach": approach_id,
		"recorded_at": _timestamp(working),
	}
	var result: Dictionary = _simulation.apply_operation(working, "education.attendance", {
		"course_id": course_id, "status": attendance_status, "performance": performance, "attendance_record": record,
	}, "education.class:%s" % course_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	result = _grant_course_experience(working, course, float(approach.get("experience", 90.0)), "education.class:%s" % course_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	result = _apply_need(working, "energy", -float(approach.get("energy_cost", 8.0)), "education.class:%s" % course_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	result = _apply_need(working, "stress", float(approach.get("stress_cost", 1.0)), "education.class:%s" % course_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	result = _simulation.apply_operation(working, "time.advance", {"blocks": 1}, "education.class:%s" % course_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	_recalculate_grades(working, false)
	_update_academic_standing(working, false)
	return _success(working, {"record": record, "course": course, "performance": performance})


func study_course(state: Dictionary, course_id: String, effort_id: String = "standard") -> Dictionary:
	var synced: Dictionary = sync_education(state)
	if not synced.get("ok", false):
		return synced
	var working: Dictionary = synced["state"]
	if course_id not in working["player"]["education"].get("courses", []):
		return _failure("That course is not part of your active schedule.")
	if str(working["world_state"].get("current_location", "")) not in COURSEWORK_LOCATIONS:
		return _failure("Study in your bedroom, the dining room, or Westshore Library.")
	var efforts: Dictionary = _academic_rules().get("coursework_effort", {})
	if not efforts.has(effort_id):
		return _failure("Unknown study effort: %s" % effort_id)
	var effort: Dictionary = efforts[effort_id]
	if float(working["player"]["needs"].get("energy", 0.0)) < float(effort.get("energy_cost", 8.0)):
		return _failure("You need more energy before studying.")
	var result: Dictionary = _simulation.apply_operation(working, "time.advance", {"minutes": int(effort.get("minutes", 90))}, "education.study:%s" % course_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	result = _simulation.apply_operation(working, "skill.add_experience", {
		"skill": "study", "experience": float(effort.get("experience", 100.0)), "activity_difficulty": int(_course(course_id).get("difficulty", 30)),
	}, "education.study:%s" % course_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	result = _apply_need(working, "energy", -float(effort.get("energy_cost", 8.0)), "education.study:%s" % course_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	result = _apply_need(working, "stress", float(effort.get("stress_cost", 2.0)), "education.study:%s" % course_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	var preparation_gain: float = float(effort.get("preparation_gain", 12.0))
	working["player"]["education"]["course_preparation"][course_id] = minf(100.0, float(working["player"]["education"]["course_preparation"].get(course_id, 0.0)) + preparation_gain)
	return _success(working, {"course_id": course_id, "preparation_gain": preparation_gain})


func complete_assessment(state: Dictionary, assessment_id: String, effort_id: String = "standard") -> Dictionary:
	var synced: Dictionary = sync_education(state)
	if not synced.get("ok", false):
		return synced
	var working: Dictionary = synced["state"]
	var assessment: Dictionary = _assessment(working, assessment_id)
	if assessment.is_empty():
		return _failure("Unknown course assessment: %s" % assessment_id)
	if str(assessment.get("status", "scheduled")) != "scheduled":
		return _failure("This assessment is already resolved.")
	var assessment_type: String = str(assessment.get("type", "assignment"))
	var is_exam: bool = assessment_type in ["midterm", "final"]
	var validation_error: String = _assessment_availability_error(working, assessment, is_exam)
	if not validation_error.is_empty():
		return _failure(validation_error)
	var effort: Dictionary = {}
	if is_exam:
		effort_id = "exam"
	else:
		var efforts: Dictionary = _academic_rules().get("coursework_effort", {})
		if not efforts.has(effort_id):
			return _failure("Unknown coursework effort: %s" % effort_id)
		effort = efforts[effort_id]
		if float(working["player"]["needs"].get("energy", 0.0)) < float(effort.get("energy_cost", 8.0)):
			return _failure("You need more energy before completing this coursework.")
	var course_id: String = str(assessment.get("course_id", ""))
	var course: Dictionary = _course(course_id)
	var score: float = _assessment_score(working, course, assessment, effort)
	var result_record: Dictionary = {
		"id": "result-%s" % assessment_id,
		"assessment_id": assessment_id,
		"course_id": course_id,
		"type": assessment_type,
		"score": score,
		"status": "completed",
		"effort": effort_id,
		"submitted_on": _date_string(working["clock"]),
		"recorded_at": _timestamp(working),
	}
	var result: Dictionary = _simulation.apply_operation(working, "education.grade", {
		"course_id": course_id, "assessment": assessment_id, "score": score, "assessment_result": result_record,
	}, "education.assessment:%s" % assessment_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	var experience: float = 140.0 if is_exam else float(effort.get("experience", 100.0))
	result = _grant_course_experience(working, course, experience, "education.assessment:%s" % assessment_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	var energy_cost: float = 12.0 if is_exam else float(effort.get("energy_cost", 8.0))
	var stress_cost: float = 5.0 if is_exam else float(effort.get("stress_cost", 2.0))
	result = _apply_need(working, "energy", -energy_cost, "education.assessment:%s" % assessment_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	result = _apply_need(working, "stress", stress_cost, "education.assessment:%s" % assessment_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	result = _simulation.apply_operation(working, "time.advance", {"blocks": 1} if is_exam else {"minutes": int(effort.get("minutes", 90))}, "education.assessment:%s" % assessment_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	working["player"]["education"]["course_preparation"][course_id] = maxf(0.0, float(working["player"]["education"]["course_preparation"].get(course_id, 0.0)) - (25.0 if is_exam else 15.0))
	_recalculate_grades(working, false)
	_update_academic_standing(working, false)
	return _success(working, {"result": result_record, "assessment": assessment, "course": course})


func upcoming_assessments(state: Dictionary, limit: int = 8) -> Array:
	var entries: Array = []
	for assessment_value: Variant in state.get("player", {}).get("education", {}).get("assessments", []):
		if assessment_value is Dictionary and str(assessment_value.get("status", "scheduled")) == "scheduled":
			entries.append(assessment_value)
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var date_comparison: int = _date_serial_from_string(str(a.get("due_date", ""))) - _date_serial_from_string(str(b.get("due_date", "")))
		return GameClockScript.BLOCKS.find(str(a.get("block", "late_evening"))) < GameClockScript.BLOCKS.find(str(b.get("block", "late_evening"))) if date_comparison == 0 else date_comparison < 0
	)
	if entries.size() > limit:
		entries.resize(limit)
	return entries


func _ensure_education_shape(state: Dictionary) -> void:
	var education: Dictionary = state["player"]["education"]
	for key: String in ["course_sections", "grades", "attendance", "course_preparation"]:
		if not education.get(key) is Dictionary:
			education[key] = {}
	for key: String in ["attendance_history", "assessments", "assessment_results", "semester_history"]:
		if not education.get(key) is Array:
			education[key] = []
	for course_id_value: Variant in education.get("courses", []):
		var course_id: String = str(course_id_value)
		if not education["grades"].has(course_id):
			education["grades"][course_id] = {"current_percent": 0.0, "letter_grade": "—", "graded_weight": 0.0, "component_scores": {}, "status": "not_started"}
		if not education["attendance"].has(course_id):
			education["attendance"][course_id] = {"attended": 0, "late": 0, "absent": 0}
		if not education["course_preparation"].has(course_id):
			education["course_preparation"][course_id] = 0.0
	if education.get("semester", {}).is_empty():
		var authored: Dictionary = _education_package().get("institution", {}).get("fall_semester", {})
		education["semester_number"] = maxi(1, int(education.get("semester_number", 0)))
		education["semester"] = {
			"id": authored.get("id", "fall_y1"), "number": education["semester_number"], "status": "enrolled", "phase": "pre_orientation",
			"orientation": authored.get("orientation", "Y1-08-30"), "classes_begin": authored.get("classes_begin", "Y1-09-03"),
			"classes_end": authored.get("classes_end", "Y1-12-13"), "exam_week_begins": authored.get("exam_week_begins", "Y1-12-16"),
			"term_complete": authored.get("term_complete", "Y1-12-20"),
		}
	if str(education.get("academic_standing", "")) in ["", "not_enrolled"]:
		education["academic_standing"] = "good_standing"
	if not education.has("credits_earned"):
		education["credits_earned"] = 0
	if not education.has("semesters_completed"):
		education["semesters_completed"] = 0
	if not education.has("registration_hold"):
		education["registration_hold"] = false


func _initialize_assessments(state: Dictionary) -> void:
	var education: Dictionary = state["player"]["education"]
	if not education.get("assessments", []).is_empty():
		return
	var calendar_rules: Dictionary = _academic_rules().get("assessment_calendar", {})
	var assessment_weights: Dictionary = _academic_rules().get("assessment_weights_within_component", {})
	var assignments: Array = calendar_rules.get("assignments", [])
	var final_blocks: Array = calendar_rules.get("final_blocks", ["morning", "lunch", "afternoon"])
	var exam_start: Dictionary = _date_parts(str(education["semester"].get("exam_week_begins", "Y1-12-16")))
	for course_index: int in education.get("courses", []).size():
		var course_id: String = str(education["courses"][course_index])
		var course: Dictionary = _course(course_id)
		for assignment_value: Variant in assignments:
			if not assignment_value is Dictionary:
				continue
			var assignment_number: int = int(assignment_value.get("sequence", 1))
			var due_date: String = str(assignment_value.get("due", "Y1-09-27"))
			var assignment_id: String = "%s-assignment-%d" % [course_id.to_lower(), assignment_number]
			var available_date: String = _date_string_from_parts(_advance_date_by(_date_parts(due_date), -int(assignment_value.get("available_days_before", 14))))
			_append_assessment(state, {
				"id": assignment_id, "course_id": course_id, "title": "%s — Assignment %d" % [course.get("name", course_id), assignment_number],
				"type": "assignment", "component": "assignments", "weight_within_component": assessment_weights.get("assignment", 1), "available_date": available_date,
				"due_date": due_date, "block": "late_evening", "location": "remote_coursework", "status": "scheduled",
			})
		var project_rule: Dictionary = calendar_rules.get("project", {})
		var project_due: String = str(project_rule.get("due", "Y1-12-06"))
		_append_assessment(state, {
			"id": "%s-project" % course_id.to_lower(), "course_id": course_id, "title": "%s — Semester Project" % course.get("name", course_id),
			"type": "project", "component": "projects", "weight_within_component": assessment_weights.get("project", 1),
			"available_date": _date_string_from_parts(_advance_date_by(_date_parts(project_due), -int(project_rule.get("available_days_before", 28)))),
			"due_date": project_due, "block": "late_evening", "location": "remote_coursework", "status": "scheduled",
		})
		var midterm_event: Dictionary = _first_course_event_on_or_after(state, course_id, str(calendar_rules.get("midterm_window_begins", "Y1-10-14")))
		if not midterm_event.is_empty():
			var midterm_id: String = "%s-midterm" % course_id.to_lower()
			midterm_event["type"] = "exam"
			midterm_event["academic_event_type"] = "midterm"
			midterm_event["assessment_id"] = midterm_id
			midterm_event["title"] = "%s Midterm" % course.get("name", course_id)
			_append_assessment(state, {
				"id": midterm_id, "course_id": course_id, "title": midterm_event["title"], "type": "midterm", "component": "exams",
				"weight_within_component": assessment_weights.get("midterm", 10), "available_date": midterm_event.get("date"), "due_date": midterm_event.get("date"),
				"block": midterm_event.get("block"), "location": midterm_event.get("location"), "calendar_event_id": midterm_event.get("id"), "status": "scheduled",
			}, false)
		var final_date_parts: Dictionary = _advance_date_by(exam_start, course_index / maxi(1, final_blocks.size()))
		var final_date: String = _date_string_from_parts(final_date_parts)
		var final_block: String = str(final_blocks[course_index % maxi(1, final_blocks.size())])
		var final_id: String = "%s-final" % course_id.to_lower()
		_append_assessment(state, {
			"id": final_id, "course_id": course_id, "title": "%s Final Examination" % course.get("name", course_id), "type": "final", "component": "exams",
			"weight_within_component": assessment_weights.get("final", 20), "available_date": final_date, "due_date": final_date, "block": final_block,
			"location": "westshore_campus.classrooms", "status": "scheduled",
		})


func _append_assessment(state: Dictionary, assessment: Dictionary, create_calendar_event: bool = true) -> void:
	state["player"]["education"]["assessments"].append(assessment)
	if not create_calendar_event:
		return
	var event_id: String = "academic-%s" % str(assessment.get("id", "assessment"))
	assessment["calendar_event_id"] = event_id
	if _calendar_event(state, event_id).is_empty():
		state["calendar_state"]["events"].append({
			"id": event_id, "title": assessment.get("title", "Coursework"), "course_id": assessment.get("course_id"),
			"assessment_id": assessment.get("id"), "academic_event_type": assessment.get("type"),
			"type": "exam" if str(assessment.get("type", "")) in ["midterm", "final"] else str(assessment.get("type", "assignment")),
			"source": "westshore_academics", "date": assessment.get("due_date"), "weekday": _weekday_for_date(str(assessment.get("due_date", ""))),
			"block": assessment.get("block", "late_evening"), "location": assessment.get("location", "remote_coursework"),
			"participants": [], "status": "scheduled", "required": true,
		})


func _process_missed_classes(state: Dictionary) -> Dictionary:
	var working: Dictionary = state
	var notices: PackedStringArray = []
	var missed: int = 0
	var events: Array = working["calendar_state"].get("events", []).duplicate(true)
	for event_value: Variant in events:
		if not event_value is Dictionary:
			continue
		var event: Dictionary = event_value
		if str(event.get("type", "")) != "class" or str(event.get("status", "scheduled")) != "scheduled" or str(event.get("course_id", "")) not in working["player"]["education"].get("courses", []):
			continue
		if not _calendar_event_expired(working, event):
			continue
		var course_id: String = str(event.get("course_id", ""))
		var record: Dictionary = {
			"id": "attendance-%s" % str(event.get("id", "class")), "course_id": course_id, "calendar_event_id": event.get("id"),
			"date": event.get("date"), "block": event.get("block"), "status": "absent", "minutes_late": 0,
			"performance": 0.0, "approach": "none", "recorded_at": _timestamp(working),
		}
		var result: Dictionary = _simulation.apply_operation(working, "education.attendance", {
			"course_id": course_id, "status": "absent", "performance": 0.0, "attendance_record": record,
		}, "education.missed_class:%s" % course_id)
		if not result.get("ok", false):
			return result
		working = result["state"]
		missed += 1
		notices.append("Missed %s on %s." % [_course(course_id).get("name", course_id), event.get("date", "")])
	return _success(working, {"notices": notices, "count": missed})


func _process_missed_assessments(state: Dictionary) -> Dictionary:
	var working: Dictionary = state
	var notices: PackedStringArray = []
	var missed: int = 0
	var assessments: Array = working["player"]["education"].get("assessments", []).duplicate(true)
	for assessment_value: Variant in assessments:
		if not assessment_value is Dictionary or str(assessment_value.get("status", "scheduled")) != "scheduled":
			continue
		var assessment: Dictionary = assessment_value
		if not _assessment_expired(working, assessment):
			continue
		var result_record: Dictionary = {
			"id": "result-%s" % assessment.get("id"), "assessment_id": assessment.get("id"), "course_id": assessment.get("course_id"),
			"type": assessment.get("type"), "score": 0.0, "status": "missed", "effort": "none",
			"submitted_on": null, "recorded_at": _timestamp(working),
		}
		var result: Dictionary = _simulation.apply_operation(working, "education.grade", {
			"course_id": assessment.get("course_id"), "assessment": assessment.get("id"), "score": 0.0, "assessment_result": result_record,
		}, "education.missed_assessment:%s" % assessment.get("id"))
		if not result.get("ok", false):
			return result
		working = result["state"]
		missed += 1
		notices.append("Missed deadline: %s." % assessment.get("title", assessment.get("id")))
	return _success(working, {"notices": notices, "count": missed})


func _recalculate_grades(state: Dictionary, finalizing: bool) -> void:
	var education: Dictionary = state["player"]["education"]
	var component_weights: Dictionary = _academic_rules().get("grade_components", {})
	var late_value: float = float(_academic_rules().get("attendance", {}).get("late_grade_value", 80.0))
	for course_id_value: Variant in education.get("courses", []):
		var course_id: String = str(course_id_value)
		var component_scores: Dictionary = {}
		var attendance: Dictionary = education["attendance"].get(course_id, {})
		var attended: int = int(attendance.get("attended", 0))
		var late: int = int(attendance.get("late", 0))
		var absent: int = int(attendance.get("absent", 0))
		var attendance_total: int = attended + late + absent
		if attendance_total > 0 or finalizing:
			component_scores["attendance"] = 0.0 if attendance_total == 0 else (float(attended) * 100.0 + float(late) * late_value) / float(attendance_total)
		for component_id: String in ["assignments", "projects", "exams"]:
			var weighted_score: float = 0.0
			var result_weight: float = 0.0
			for result_value: Variant in education.get("assessment_results", []):
				if not result_value is Dictionary or str(result_value.get("course_id", "")) != course_id:
					continue
				var assessment: Dictionary = _assessment(state, str(result_value.get("assessment_id", "")))
				if str(assessment.get("component", "")) != component_id:
					continue
				var within_weight: float = float(assessment.get("weight_within_component", 1.0))
				weighted_score += float(result_value.get("score", 0.0)) * within_weight
				result_weight += within_weight
			if result_weight > 0.0 or finalizing:
				component_scores[component_id] = 0.0 if result_weight <= 0.0 else weighted_score / result_weight
		var grade_points: float = 0.0
		var graded_weight: float = 0.0
		for component_id: Variant in component_weights:
			if not component_scores.has(str(component_id)):
				continue
			var weight: float = float(component_weights[component_id])
			grade_points += float(component_scores[str(component_id)]) * weight / 100.0
			graded_weight += weight
		var percent: float = 0.0 if graded_weight <= 0.0 else grade_points / graded_weight * 100.0
		var grade: Dictionary = education["grades"].get(course_id, {})
		grade["current_percent"] = _round_one(percent)
		grade["letter_grade"] = _letter_grade(percent) if graded_weight > 0.0 else "—"
		grade["graded_weight"] = graded_weight
		grade["component_scores"] = component_scores
		grade["status"] = ("passed" if percent >= float(_academic_rules().get("academic_standing", {}).get("passing_course_percent", 60.0)) else "failed") if finalizing else ("not_started" if graded_weight <= 0.0 else "in_progress")
		education["grades"][course_id] = grade


func _update_academic_standing(state: Dictionary, finalizing: bool) -> void:
	var education: Dictionary = state["player"]["education"]
	var attendance_warning: bool = false
	var warning_absences: int = int(_academic_rules().get("attendance", {}).get("warning_absences", 3))
	for attendance_value: Variant in education.get("attendance", {}).values():
		if attendance_value is Dictionary and int(attendance_value.get("absent", 0)) >= warning_absences:
			attendance_warning = true
			break
	if attendance_warning:
		state["player"]["flags"][str(_academic_rules().get("attendance", {}).get("three_unexcused_absences_flag", "academic_warning"))] = true
	var grade_total: float = 0.0
	var graded_courses: int = 0
	var resolved_assessments: int = education.get("assessment_results", []).size()
	for grade_value: Variant in education.get("grades", {}).values():
		if grade_value is Dictionary and (float(grade_value.get("graded_weight", 0.0)) > 0.0 or finalizing):
			grade_total += float(grade_value.get("current_percent", 0.0))
			graded_courses += 1
	if graded_courses == 0:
		education["academic_standing"] = "warning" if attendance_warning else "good_standing"
		return
	var average: float = grade_total / float(graded_courses)
	var rules: Dictionary = _academic_rules().get("academic_standing", {})
	if finalizing and average < float(rules.get("suspension_review_below", 50.0)):
		education["academic_standing"] = "suspension_review"
		education["registration_hold"] = true
	elif (finalizing or resolved_assessments >= 2) and average < float(rules.get("probation_minimum", 60.0)):
		education["academic_standing"] = "academic_probation"
	elif attendance_warning or ((finalizing or resolved_assessments >= 2) and average < float(rules.get("good_standing_minimum", 70.0))):
		education["academic_standing"] = "warning"
	else:
		education["academic_standing"] = "good_standing"


func _finalize_semester(state: Dictionary) -> Dictionary:
	var education: Dictionary = state["player"]["education"]
	if str(education.get("semester", {}).get("status", "")) == "completed":
		return _success(state, {"notices": PackedStringArray()})
	_recalculate_grades(state, true)
	_update_academic_standing(state, true)
	var total: float = 0.0
	var course_results: Array = []
	var credits: int = 0
	for course_id_value: Variant in education.get("courses", []):
		var course_id: String = str(course_id_value)
		var grade: Dictionary = education["grades"].get(course_id, {})
		var course: Dictionary = _course(course_id)
		var passed: bool = str(grade.get("status", "failed")) == "passed"
		var standing_rules: Dictionary = _academic_rules().get("academic_standing", {})
		var course_credits: int = (int(standing_rules.get("laboratory_course_credits", 4)) if not course.get("lab", {}).is_empty() else int(standing_rules.get("default_course_credits", 3))) if passed else 0
		credits += course_credits
		total += float(grade.get("current_percent", 0.0))
		course_results.append({"course_id": course_id, "percent": grade.get("current_percent", 0.0), "letter_grade": grade.get("letter_grade", "F"), "status": grade.get("status", "failed"), "credits": course_credits})
	var average: float = 0.0 if course_results.is_empty() else total / float(course_results.size())
	education["credits_earned"] = int(education.get("credits_earned", 0)) + credits
	education["semesters_completed"] = int(education.get("semesters_completed", 0)) + 1
	education["semester"]["status"] = "completed"
	education["semester"]["phase"] = "completed"
	education["semester"]["average"] = _round_one(average)
	education["semester"]["credits_earned"] = credits
	education["semester_history"].append({
		"semester_id": education["semester"].get("id", "fall_y1"), "semester_number": education.get("semester_number", 1),
		"completed_on": _date_string(state["clock"]), "average": _round_one(average), "credits_earned": credits,
		"academic_standing": education.get("academic_standing", "good_standing"), "course_results": course_results,
	})
	state["clock"]["semester_phase"] = "winter_break"
	var changes: Dictionary = _academic_rules().get("semester_reputation_change", {})
	var reputation_change: float = float(changes.get("excellent", 8.0)) if average >= 90.0 else (float(changes.get("strong", 5.0)) if average >= 80.0 else (float(changes.get("passing", 2.0)) if average >= 60.0 else float(changes.get("failed", -6.0))))
	var result: Dictionary = _simulation.apply_operation(state, "reputation.adjust", {
		"category": "academic", "amount": reputation_change, "reason": "semester_result",
	}, "education.semester_complete")
	if not result.get("ok", false):
		return result
	return _success(result["state"], {"notices": PackedStringArray(["Fall semester completed with a %.1f%% average and %d earned credits." % [average, credits]])})


func _update_semester_phase(state: Dictionary) -> void:
	var education: Dictionary = state["player"]["education"]
	var semester: Dictionary = education["semester"]
	if str(semester.get("status", "")) == "completed":
		semester["phase"] = "completed"
		state["clock"]["semester_phase"] = "winter_break"
		return
	var today: int = _date_serial_from_string(_date_string(state["clock"]))
	var phase: String = "pre_orientation"
	if today >= _date_serial_from_string(str(semester.get("exam_week_begins", "Y1-12-16"))):
		phase = "exam_week"
	elif today > _date_serial_from_string(str(semester.get("classes_end", "Y1-12-13"))):
		phase = "study_break"
	elif today >= _date_serial_from_string(str(semester.get("classes_begin", "Y1-09-03"))):
		phase = "classes_in_session"
	elif today >= _date_serial_from_string(str(semester.get("orientation", "Y1-08-30"))):
		phase = "orientation"
	semester["phase"] = phase
	state["clock"]["semester_phase"] = phase


func _class_performance(state: Dictionary, course: Dictionary, approach: Dictionary, attendance_status: String) -> float:
	var player: Dictionary = state["player"]
	var preparation: float = float(player["education"]["course_preparation"].get(str(course.get("id", "")), 0.0))
	var subject_skill: float = _course_skill_average(state, course)
	var score: float = 45.0
	score += float(player["attributes"].get("focus", 0.0)) * 0.25
	score += float(player["attributes"].get("intelligence", 0.0)) * 0.12
	score += float(player["skills"].get("study", 0.0)) * 0.18
	score += subject_skill * 0.18 + preparation * 0.10
	score += (float(player["needs"].get("energy", 50.0)) - 50.0) * 0.12
	score -= float(player["needs"].get("stress", 0.0)) * 0.10
	score -= float(course.get("difficulty", 30.0)) * 0.25
	score += float(approach.get("performance_modifier", 0.0))
	if attendance_status == "late":
		score -= 10.0
	return _round_one(clampf(score, 0.0, 100.0))


func _assessment_score(state: Dictionary, course: Dictionary, assessment: Dictionary, effort: Dictionary) -> float:
	var player: Dictionary = state["player"]
	var course_id: String = str(course.get("id", ""))
	var score: float = 35.0
	score += float(player["attributes"].get("focus", 0.0)) * 0.35
	score += float(player["attributes"].get("intelligence", 0.0)) * 0.20
	score += float(player["skills"].get("study", 0.0)) * 0.25
	score += _course_skill_average(state, course) * 0.25
	score += float(player["education"]["course_preparation"].get(course_id, 0.0)) * 0.20
	score += float(player["needs"].get("energy", 0.0)) * 0.15
	score -= float(player["needs"].get("stress", 0.0)) * 0.15
	score -= float(course.get("difficulty", 30.0)) * 0.35
	score += float(effort.get("score_modifier", 0.0))
	if str(assessment.get("type", "")) == "project":
		score += float(player["attributes"].get("creativity", 0.0)) * 0.08
	return _round_one(clampf(score, 0.0, 100.0))


func _grant_course_experience(state: Dictionary, course: Dictionary, total_experience: float, source: String) -> Dictionary:
	var skills: Dictionary = course.get("skills", {})
	if skills.is_empty():
		return _success(state)
	var working: Dictionary = state
	var divisor: float = float(skills.size())
	for skill_id: Variant in skills:
		var result: Dictionary = _simulation.apply_operation(working, "skill.add_experience", {
			"skill": str(skill_id), "experience": total_experience / divisor, "activity_difficulty": int(course.get("difficulty", 30)),
		}, source)
		if not result.get("ok", false):
			return result
		working = result["state"]
	return _success(working)


func _apply_need(state: Dictionary, need: String, amount: float, source: String) -> Dictionary:
	return _simulation.apply_operation(state, "need.adjust", {"need": need, "amount": amount}, source)


func _assessment_availability_error(state: Dictionary, assessment: Dictionary, is_exam: bool) -> String:
	var today: int = _date_serial_from_string(_date_string(state["clock"]))
	var available: int = _date_serial_from_string(str(assessment.get("available_date", assessment.get("due_date", ""))))
	var due: int = _date_serial_from_string(str(assessment.get("due_date", "")))
	if today < available:
		return "This assessment opens on %s." % assessment.get("available_date", "")
	if today > due:
		return "This assessment deadline has passed."
	if is_exam:
		if today != due or str(state["clock"].get("block", "")) != str(assessment.get("block", "")):
			return "The exam must be taken during its scheduled calendar block."
		if str(state["world_state"].get("current_location", "")) != str(assessment.get("location", "")):
			return "Go to %s before the exam." % _location_label(str(assessment.get("location", "")))
	return ""


func _assessment_expired(state: Dictionary, assessment: Dictionary) -> bool:
	var due_date: int = _date_serial_from_string(str(assessment.get("due_date", "")))
	var current_date: int = _date_serial_from_string(_date_string(state["clock"]))
	if current_date != due_date:
		return current_date > due_date
	var current_block: int = GameClockScript.BLOCKS.find(str(state["clock"].get("block", "early_morning")))
	var due_block: int = GameClockScript.BLOCKS.find(str(assessment.get("block", "late_evening")))
	if current_block != due_block:
		return current_block > due_block
	return str(assessment.get("type", "")) in ["midterm", "final"] and int(state["clock"].get("minute_within_block", 0)) > int(_academic_rules().get("attendance", {}).get("maximum_late_minutes", 60))


func _calendar_event_expired(state: Dictionary, event: Dictionary) -> bool:
	var event_serial: int = _event_serial_blocks(event)
	var current_serial: int = _clock_serial_blocks(state["clock"])
	if current_serial != event_serial:
		return current_serial > event_serial
	return int(state["clock"].get("minute_within_block", 0)) > int(_academic_rules().get("attendance", {}).get("maximum_late_minutes", 60))


func _course_skill_average(state: Dictionary, course: Dictionary) -> float:
	var course_skills: Dictionary = course.get("skills", {})
	if course_skills.is_empty():
		return 0.0
	var total: float = 0.0
	for skill_id: Variant in course_skills:
		total += float(state["player"]["skills"].get(str(skill_id), 0.0))
	return total / float(course_skills.size())


func _first_course_event_on_or_after(state: Dictionary, course_id: String, target_date: String) -> Dictionary:
	var target: int = _date_serial_from_string(target_date)
	var best: Dictionary = {}
	var best_serial: int = 2147483647
	for event_value: Variant in state["calendar_state"].get("events", []):
		if not event_value is Dictionary:
			continue
		var event: Dictionary = event_value
		if str(event.get("course_id", "")) != course_id or str(event.get("type", "")) != "class" or str(event.get("section_id", "")) == "lab":
			continue
		var serial: int = _date_serial_from_string(str(event.get("date", "")))
		if serial >= target and serial < best_serial:
			best = event
			best_serial = serial
	return best


func _assessment(state: Dictionary, assessment_id: String) -> Dictionary:
	for assessment_value: Variant in state["player"]["education"].get("assessments", []):
		if assessment_value is Dictionary and str(assessment_value.get("id", "")) == assessment_id:
			return assessment_value
	return {}


func _calendar_event(state: Dictionary, event_id: String) -> Dictionary:
	for event_value: Variant in state["calendar_state"].get("events", []):
		if event_value is Dictionary and str(event_value.get("id", "")) == event_id:
			return event_value
	return {}


func _course(course_id: String) -> Dictionary:
	var value: Variant = _registry.get_content("courses", course_id)
	return value if value is Dictionary else {}


func _letter_grade(percent: float) -> String:
	for definition_value: Variant in _academic_rules().get("letter_grades", []):
		if definition_value is Dictionary and percent >= float(definition_value.get("minimum", 0.0)):
			return str(definition_value.get("grade", "F"))
	return "F"


func _academic_rules() -> Dictionary:
	return _education_package().get("academic_rules", {})


func _education_package() -> Dictionary:
	var value: Variant = _registry.get_package("westshore_education_system")
	return value if value is Dictionary else {}


func _event_serial_blocks(event: Dictionary) -> int:
	return _date_serial_from_string(str(event.get("date", ""))) * GameClockScript.BLOCKS.size() + maxi(0, GameClockScript.BLOCKS.find(str(event.get("block", "early_morning"))))


func _clock_serial_blocks(clock: Dictionary) -> int:
	return _date_serial_from_string(_date_string(clock)) * GameClockScript.BLOCKS.size() + maxi(0, GameClockScript.BLOCKS.find(str(clock.get("block", "early_morning"))))


func _date_serial_from_string(date: String) -> int:
	var parts: Dictionary = _date_parts(date)
	if parts.is_empty():
		return -1
	var days: int = (int(parts["year"]) - 1) * 365
	for month: int in range(1, int(parts["month"])):
		days += _days_in_month(month, int(parts["year"]))
	return days + int(parts["day"]) - 1


func _date_parts(date: String) -> Dictionary:
	var pieces: PackedStringArray = date.trim_prefix("Y").split("-")
	if pieces.size() != 3:
		return {}
	return {"year": int(pieces[0]), "month": int(pieces[1]), "day": int(pieces[2])}


func _advance_date_by(date: Dictionary, days: int) -> Dictionary:
	var result: Dictionary = date.duplicate(true)
	var direction: int = 1 if days >= 0 else -1
	for _index: int in absi(days):
		result["day"] = int(result["day"]) + direction
		if direction > 0 and int(result["day"]) > _days_in_month(int(result["month"]), int(result["year"])):
			result["day"] = 1
			result["month"] = int(result["month"]) + 1
			if int(result["month"]) > 12:
				result["month"] = 1
				result["year"] = int(result["year"]) + 1
		elif direction < 0 and int(result["day"]) < 1:
			result["month"] = int(result["month"]) - 1
			if int(result["month"]) < 1:
				result["month"] = 12
				result["year"] = int(result["year"]) - 1
			result["day"] = _days_in_month(int(result["month"]), int(result["year"]))
	return result


func _weekday_for_date(date: String) -> String:
	var opening_serial: int = _date_serial_from_string("Y1-08-20")
	var weekday_index: int = posmod(GameClockScript.WEEKDAYS.find("tuesday") + _date_serial_from_string(date) - opening_serial, GameClockScript.WEEKDAYS.size())
	return GameClockScript.WEEKDAYS[weekday_index]


func _days_in_month(month: int, year: int) -> int:
	if month in [4, 6, 9, 11]:
		return 30
	if month == 2:
		return 29 if year % 4 == 0 else 28
	return 31


func _date_string(clock: Dictionary) -> String:
	return "Y%d-%02d-%02d" % [clock.get("year", 1), clock.get("month", 1), clock.get("day", 1)]


func _date_string_from_parts(parts: Dictionary) -> String:
	return "Y%d-%02d-%02d" % [parts.get("year", 1), parts.get("month", 1), parts.get("day", 1)]


func _timestamp(state: Dictionary) -> String:
	return "Y%d-%02d-%02d:%s+%03d" % [state["clock"].get("year", 1), state["clock"].get("month", 1), state["clock"].get("day", 1), state["clock"].get("block", "early_morning"), state["clock"].get("minute_within_block", 0)]


func _location_label(location: String) -> String:
	var location_id: String = location.get_slice(".", 0)
	var room_id: String = location.get_slice(".", 1)
	var definition: Variant = _registry.get_location(location_id)
	if definition is Dictionary:
		for room_value: Variant in definition.get("rooms", []):
			if room_value is Dictionary and str(room_value.get("id", "")) == room_id:
				return str(room_value.get("name", room_id.replace("_", " ").capitalize()))
	return room_id.replace("_", " ").capitalize() if not room_id.is_empty() else location_id.replace("_", " ").capitalize()


func _round_one(value: float) -> float:
	return round(value * 10.0) / 10.0


func _success(state: Dictionary, data: Dictionary = {}) -> Dictionary:
	return {"ok": true, "state": state, "data": data, "errors": PackedStringArray()}


func _failure(message: String) -> Dictionary:
	return {"ok": false, "errors": PackedStringArray([message])}
