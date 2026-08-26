extends RefCounted
class_name PortAlderEmploymentEngine

const GameClockScript: GDScript = preload("res://src/simulation/game_clock.gd")
const FILTERS: PackedStringArray = ["all", "qualified", "part_time", "full_time"]
const INTERVIEW_BLOCKS: PackedStringArray = ["morning", "lunch", "afternoon", "evening"]
const DEFAULT_WORK_APPROACH: String = "steady"
const TRAIT_ATTRIBUTES: Dictionary = {
	"reliable": "reliability", "responsible": "responsibility", "disciplined": "discipline",
	"confident": "confidence", "charismatic": "charisma", "friendly": "charisma",
	"patient": "empathy", "organized": "responsibility", "helpful": "empathy",
	"energetic": "stamina", "observant": "focus", "analytical": "intelligence",
	"professional": "manners", "discreet": "manners", "careful": "responsibility",
	"perceptive": "emotional_intelligence", "assertive": "assertiveness",
}

var _registry: Node
var _simulation: RefCounted
var _quests: RefCounted


func _init(content_registry: Node, simulation_engine: RefCounted, quest_engine: RefCounted) -> void:
	_registry = content_registry
	_simulation = simulation_engine
	_quests = quest_engine


func get_listings(state: Dictionary, filter_id: String = "all") -> Array:
	if filter_id not in FILTERS:
		filter_id = "all"
	var listings: Array = []
	for value: Variant in _registry.get_all("jobs"):
		if not value is Dictionary:
			continue
		var job: Dictionary = value
		if filter_id in ["part_time", "full_time"] and filter_id not in job.get("employment_types", []):
			continue
		var qualification: Dictionary = qualification_report(state, job)
		if filter_id == "qualified" and not bool(qualification["qualified"]):
			continue
		listings.append({
			"job": job,
			"qualification": qualification,
			"application": _application_for_job(state, str(job.get("id", ""))),
			"compatible_schedules": compatible_schedules(state, str(job.get("id", "")), filter_id),
		})
	return listings


func qualification_report(state: Dictionary, job: Dictionary) -> Dictionary:
	var requirements: Dictionary = job.get("requirements", {})
	var met: PackedStringArray = []
	var missing: PackedStringArray = []
	var player: Dictionary = state["player"]
	for skill_id: Variant in requirements.get("skills", {}):
		var minimum: int = int(requirements["skills"][skill_id])
		var current: int = int(player.get("skills", {}).get(str(skill_id), 0))
		_record_requirement(current >= minimum, "%s %d/%d" % [_label(str(skill_id)), current, minimum], met, missing)
	var skills_any: Array = requirements.get("skills_any", [])
	if not skills_any.is_empty():
		var any_skill_met: bool = false
		var skill_labels: PackedStringArray = []
		for skill_requirement: Variant in skills_any:
			if not skill_requirement is Array or skill_requirement.size() != 2:
				continue
			var skill_id: String = str(skill_requirement[0])
			var minimum: int = int(skill_requirement[1])
			var current: int = int(player.get("skills", {}).get(skill_id, 0))
			any_skill_met = any_skill_met or current >= minimum
			skill_labels.append("%s %d/%d" % [_label(skill_id), current, minimum])
		_record_requirement(any_skill_met, "One skill: %s" % " or ".join(skill_labels), met, missing)
	var traits_any: Array = requirements.get("traits_any", [])
	if not traits_any.is_empty():
		var trait_met: bool = false
		for trait_id: Variant in traits_any:
			if _has_trait_quality(state, str(trait_id)):
				trait_met = true
				break
		_record_requirement(trait_met, "One trait: %s" % _joined_labels(traits_any), met, missing)
	for key: Variant in requirements:
		var requirement_key: String = str(key)
		if not requirement_key.begins_with("minimum_") or requirement_key == "minimum_age":
			continue
		var attribute_id: String = requirement_key.trim_prefix("minimum_")
		var minimum: int = int(requirements[key])
		var current: int = int(player.get("attributes", {}).get(attribute_id, 0))
		_record_requirement(current >= minimum, "%s %d/%d" % [_label(attribute_id), current, minimum], met, missing)
	if requirements.has("minimum_age"):
		var minimum_age: int = int(requirements["minimum_age"])
		var age: int = int(player["identity"].get("age", 0))
		_record_requirement(age >= minimum_age, "Age %d+" % minimum_age, met, missing)
	var education: String = str(requirements.get("education", "none"))
	if education == "actively_enrolled_at_westshore":
		_record_requirement(bool(player["education"].get("enrolled", false)), "Active Westshore enrollment", met, missing)
	elif education == "high_school_equivalent":
		_record_requirement(int(player["identity"].get("age", 0)) >= 18, "High-school equivalent", met, missing)
	if requirements.has("licenses"):
		for license_id: Variant in requirements["licenses"]:
			_record_requirement(str(license_id) in player["employment"].get("certifications", []), "License: %s" % _label(str(license_id)), met, missing)
	if requirements.has("health"):
		for health_requirement: Variant in requirements["health"]:
			_record_requirement(bool(player["flags"].get("health.%s" % health_requirement, false)), "Health: %s" % _label(str(health_requirement)), met, missing)
	if requirements.has("hard_requirement"):
		var hard_requirement: String = str(requirements["hard_requirement"])
		_record_requirement(bool(player["flags"].get("employment.%s" % hard_requirement, false)), _label(hard_requirement), met, missing)
	var total: int = met.size() + missing.size()
	return {
		"qualified": missing.is_empty(),
		"met": met,
		"missing": missing,
		"match_percent": 100 if total == 0 else int(round(float(met.size()) / float(total) * 100.0)),
		"trait_match": traits_any.is_empty() or _any_trait_quality(state, traits_any),
	}


func compatible_schedules(state: Dictionary, job_id: String, requested_type: String = "all") -> Array:
	var value: Variant = _registry.get_content("jobs", job_id)
	if not value is Dictionary:
		return []
	var compatible: Array = []
	for schedule: Variant in value.get("schedule_options", []):
		if not schedule is Dictionary:
			continue
		var weekly_hours_value: Variant = schedule.get("weekly_hours", 0)
		if not weekly_hours_value is int and not weekly_hours_value is float:
			continue
		var weekly_hours: float = float(weekly_hours_value)
		if requested_type == "full_time" and weekly_hours < 30.0:
			continue
		if requested_type == "part_time" and weekly_hours > 24.0:
			continue
		if _schedule_conflicts(state, schedule):
			continue
		compatible.append(schedule.duplicate(true))
	return compatible


func record_listings_viewed(state: Dictionary, filter_id: String) -> Dictionary:
	var listings: Array = get_listings(state, filter_id)
	var working: Dictionary = state.duplicate(true)
	if not working["player"]["employment"].has("discovered_jobs"):
		working["player"]["employment"]["discovered_jobs"] = []
	var employment_types: PackedStringArray = []
	for entry: Variant in listings:
		if not entry is Dictionary:
			continue
		var job: Dictionary = entry["job"]
		var job_id: String = str(job.get("id", ""))
		if job_id not in working["player"]["employment"]["discovered_jobs"]:
			working["player"]["employment"]["discovered_jobs"].append(job_id)
		for employment_type: Variant in job.get("employment_types", []):
			if str(employment_type) not in employment_types:
				employment_types.append(str(employment_type))
	var result: Dictionary = _quests.record_event(working, "job_board_opened", {}, "phone.jobs")
	if not result.get("ok", false):
		return result
	result = _quests.record_event(result["state"], "job_listings_viewed", {
		"count": listings.size(),
		"filter": filter_id,
		"employment_types": employment_types,
	}, "phone.jobs")
	return result


func save_availability(state: Dictionary) -> Dictionary:
	var working: Dictionary = state.duplicate(true)
	var profile: Dictionary = {}
	for weekday: String in GameClockScript.WEEKDAYS:
		profile[weekday] = []
		for block: String in GameClockScript.BLOCKS:
			if not _required_calendar_slot_exists(working, weekday, block):
				profile[weekday].append(block)
	working["player"]["employment"]["availability_profile"] = profile
	return _quests.record_event(working, "availability_profile_saved", {}, "phone.jobs.availability")


func apply_to_job(state: Dictionary, job_id: String, requested_type: String) -> Dictionary:
	var value: Variant = _registry.get_content("jobs", job_id)
	if not value is Dictionary:
		return _failure("Unknown job listing: %s" % job_id)
	var job: Dictionary = value
	if requested_type not in ["part_time", "full_time"]:
		requested_type = _default_requested_type(state, job)
	if requested_type not in job.get("employment_types", []):
		return _failure("This listing does not offer %s work." % _label(requested_type))
	var qualification: Dictionary = qualification_report(state, job)
	if not bool(qualification["qualified"]):
		return _failure("Requirements not met: %s" % "; ".join(qualification["missing"]))
	var schedules: Array = compatible_schedules(state, job_id, requested_type)
	if schedules.is_empty():
		return _failure("No %s schedule fits your required classes or current jobs." % _label(requested_type))
	if not _application_for_job(state, job_id).is_empty():
		return _failure("You already have an active application for this job.")

	var working: Dictionary = state
	var result: Dictionary = _simulation.apply_operation(working, "time.advance", {"minutes": 20}, "phone.jobs.apply:%s" % job_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	var slot: Dictionary = _find_interview_slot(working)
	if slot.is_empty():
		return _failure("No interview time is available during the next two weeks.")
	var sequence: int = working["player"]["employment"].get("applications", []).size() + 1
	var application_id: String = "application-%s-%03d" % [job_id, sequence]
	var interview_id: String = "interview-%s-%03d" % [job_id, sequence]
	var calendar_event_id: String = "calendar-%s" % interview_id
	var interview: Dictionary = {
		"id": interview_id,
		"application_id": application_id,
		"job_id": job_id,
		"status": "scheduled",
		"date": slot["date"],
		"weekday": slot["weekday"],
		"block": slot["block"],
		"calendar_event_id": calendar_event_id,
	}
	var application: Dictionary = {
		"id": application_id,
		"job_id": job_id,
		"requested_type": requested_type,
		"stage": "interview_scheduled",
		"submitted_at": _timestamp(working),
		"resume_snapshot": _resume_snapshot(working),
		"availability_snapshot": working["player"]["employment"].get("availability_profile", {}).duplicate(true),
		"qualification_snapshot": qualification.duplicate(true),
		"interview_id": interview_id,
	}
	result = _simulation.apply_operation(working, "calendar.schedule", {"calendar_event": {
		"id": calendar_event_id,
		"title": "Video Interview — %s" % job.get("title", job_id),
		"type": "interview",
		"source": "employment.application",
		"date": slot["date"],
		"weekday": slot["weekday"],
		"block": slot["block"],
		"location": "phone",
		"participants": [],
	}}, "phone.jobs.apply:%s" % job_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	result = _simulation.apply_operation(working, "employment.apply", {
		"job_id": job_id,
		"application": application,
		"interview": interview,
	}, "phone.jobs.apply:%s" % job_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	var submitted: Array = working["player"]["employment"].get("applications", [])
	var event_result: Dictionary = _quests.record_event(working, "job_applications_submitted", {
		"count": submitted.size(),
		"filter": requested_type,
		"employment_types": job.get("employment_types", []).duplicate(true),
	}, "phone.jobs.apply:%s" % job_id)
	if not event_result.get("ok", false):
		return event_result
	return _success(event_result["state"], {"job": job, "application": application})


func interview_ready(state: Dictionary, job_id: String) -> Dictionary:
	var application: Dictionary = _application_for_job(state, job_id)
	if application.is_empty() or str(application.get("stage", "")) != "interview_scheduled":
		return {"ready": false, "reason": "No interview is scheduled."}
	var interview: Dictionary = _record_by_id(state["player"]["employment"].get("interviews", []), str(application.get("interview_id", "")))
	if interview.is_empty():
		return {"ready": false, "reason": "Interview details are missing."}
	var scheduled_minutes: int = _event_serial_minutes(str(interview.get("date", "")), str(interview.get("block", "morning")))
	var current_minutes: int = _clock_serial_minutes(state["clock"])
	return {
		"ready": current_minutes >= scheduled_minutes,
		"reason": "Scheduled for %s • %s." % [interview.get("date", ""), _label(str(interview.get("block", "")))],
		"interview": interview,
	}


func complete_interview(state: Dictionary, job_id: String, answer_quality: int) -> Dictionary:
	var ready: Dictionary = interview_ready(state, job_id)
	if not bool(ready.get("ready", false)):
		return _failure(str(ready.get("reason", "The interview is not ready.")))
	var application: Dictionary = _application_for_job(state, job_id)
	var interview: Dictionary = ready["interview"]
	var job: Dictionary = _registry.get_content("jobs", job_id)
	var qualification: Dictionary = qualification_report(state, job)
	var score_breakdown: Dictionary = {
		"requirements_match": 30 if qualification["qualified"] else int(round(float(qualification["match_percent"]) * 0.3)),
		"answer_quality": clampi(answer_quality, 0, 20),
		"reliability_and_punctuality": _punctuality_score(state, interview),
		"manners_and_presentation": mini(10, int(round(float(state["player"]["attributes"].get("manners", 0)) / 5.0))),
		"relevant_traits": 10 if bool(qualification.get("trait_match", false)) else 0,
		"reputation_and_referral": _reputation_and_referral_score(state, job),
		"weather_appropriate_clean_outfit": _interview_outfit_score(state),
	}
	var total_score: int = 0
	for component: Variant in score_breakdown.values():
		total_score += int(component)
	var outcome: String = "rejected"
	var arrived_in_time: bool = int(score_breakdown["reliability_and_punctuality"]) > 0
	if float(state["player"]["needs"].get("inebriation", 0.0)) < 25.0 and arrived_in_time:
		if total_score >= 82:
			outcome = "strong_offer"
		elif total_score >= 65:
			outcome = "standard_offer"
		elif total_score >= 55:
			outcome = "waitlisted"
	var schedules: Array = compatible_schedules(state, job_id, str(application.get("requested_type", "all")))
	var offer: Variant = null
	if outcome in ["standard_offer", "strong_offer"] and not schedules.is_empty():
		var schedule_ids: PackedStringArray = []
		for schedule: Variant in schedules:
			if schedule is Dictionary:
				schedule_ids.append(str(schedule.get("id", "")))
		offer = {
			"status": "offered",
			"outcome": outcome,
			"hourly_pay": float(job.get("hourly_pay", 0.0)),
			"eligible_schedule_ids": schedule_ids,
			"offered_at": _timestamp(state),
		}
	var working: Dictionary = state
	var result: Dictionary = _simulation.apply_operation(working, "time.advance", {"minutes": 60}, "phone.jobs.interview:%s" % job_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	result = _simulation.apply_operation(working, "employment.interview", {
		"job_id": job_id,
		"application_id": application["id"],
		"interview_id": interview["id"],
		"score": total_score,
		"score_breakdown": score_breakdown,
		"outcome": outcome,
		"offer": offer,
	}, "phone.jobs.interview:%s" % job_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	result = _simulation.apply_operation(working, "calendar.arrival", {
		"event_id": interview["calendar_event_id"],
	}, "phone.jobs.interview:%s" % job_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	result = _quests.record_event(working, "job_interview_completed", {
		"job_id": job_id, "outcome": outcome, "score": total_score,
	}, "phone.jobs.interview:%s" % job_id)
	if not result.get("ok", false):
		return result
	return _success(result["state"], {"job": job, "score": total_score, "score_breakdown": score_breakdown, "outcome": outcome})


func accept_offer(state: Dictionary, job_id: String, schedule_id: String) -> Dictionary:
	var application: Dictionary = _application_for_job(state, job_id)
	if application.is_empty() or str(application.get("stage", "")) != "offer_received":
		return _failure("There is no active offer for this job.")
	var job: Dictionary = _registry.get_content("jobs", job_id)
	var schedule: Dictionary = _schedule_by_id(compatible_schedules(state, job_id, str(application.get("requested_type", "all"))), schedule_id)
	if schedule.is_empty() or schedule_id not in application.get("offer", {}).get("eligible_schedule_ids", []):
		return _failure("That work schedule is no longer compatible.")
	var start: Dictionary = _date_after_days(state["clock"], 1)
	var start_date: String = _date_string_from_parts(start)
	var employment_rules: Dictionary = _employment_rules()
	var probation_days: int = int(employment_rules.get("probation_days", 30))
	var review_days: int = int(employment_rules.get("raises", {}).get("review_interval_days", 90))
	var active_job: Dictionary = {
		"id": "active-%s" % job_id,
		"job_id": job_id,
		"title": job.get("title", job_id),
		"employer": job.get("employer", ""),
		"location": job.get("location", ""),
		"employment_type": application.get("requested_type", "part_time"),
		"schedule_id": schedule_id,
		"schedule": schedule.duplicate(true),
		"weekly_hours": schedule.get("weekly_hours", 0),
		"hourly_pay": job.get("hourly_pay", 0.0),
		"start_date": start_date,
		"hired_at": _timestamp(state),
		"probation_ends_after_days": probation_days,
		"probation_end_date": _date_string_from_parts(_advance_date_by(start, probation_days)),
		"next_payday": _date_string_from_parts(_next_weekday_after(start, "friday")),
		"next_review_date": _date_string_from_parts(_advance_date_by(start, review_days)),
		"performance": 50,
		"career_level": 0,
		"review_count": 0,
		"pending_promotion": null,
		"pending_pay": {"hours": 0.0, "overtime_hours": 0.0, "gross_wages": 0.0, "tips": 0.0},
		"hours_worked_total": 0.0,
		"shifts_completed": 0,
		"shifts_missed": 0,
		"late_shifts": 0,
		"lifetime_gross": 0.0,
		"lifetime_net": 0.0,
		"shift_history": [],
		"payroll_history": [],
		"career_history": [],
		"review_history": [],
		"status": "active",
	}
	var result: Dictionary = _simulation.apply_operation(state, "employment.accept_offer", {
		"job_id": job_id,
		"application_id": application["id"],
		"schedule_id": schedule_id,
		"start_date": start_date,
		"active_job": active_job,
	}, "phone.jobs.accept:%s" % job_id)
	if not result.get("ok", false):
		return result
	var working: Dictionary = result["state"]
	_create_work_calendar(working, active_job, schedule, start, 42)
	var event_payload: Dictionary = {
		"job_id": job_id,
		"hours": float(schedule.get("weekly_hours", 0.0)),
		"schedule_id": schedule_id,
	}
	result = _quests.record_event(working, "employment_contract_accepted", event_payload, "phone.jobs.accept:%s" % job_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	result = _quests.record_event(working, "compatible_employment_contract_accepted", event_payload, "phone.jobs.accept:%s" % job_id)
	if not result.get("ok", false):
		return result
	return _success(result["state"], {"job": job, "active_job": active_job})


func sync_employment(state: Dictionary) -> Dictionary:
	var working: Dictionary = state.duplicate(true)
	var notices: PackedStringArray = []
	for active_job_value: Variant in working["player"]["employment"].get("active_jobs", []):
		if active_job_value is Dictionary and str(active_job_value.get("status", "active")) == "active":
			_ensure_future_work_calendar(working, active_job_value)
	var missed_groups: Array = _past_due_shift_groups(working)
	for group_value: Variant in missed_groups:
		if not group_value is Dictionary:
			continue
		var group: Dictionary = group_value
		var job_id: String = str(group.get("job_id", ""))
		var active_job: Dictionary = _active_job(working, job_id)
		if active_job.is_empty():
			continue
		var performance_before: float = float(active_job.get("performance", 50.0))
		var shift_record: Dictionary = {
			"id": "shift-%s-%s" % [job_id, str(group.get("date", "")).replace("-", "")],
			"job_id": job_id,
			"date": group.get("date", ""),
			"week_key": group.get("week_key", ""),
			"calendar_event_ids": group.get("calendar_event_ids", []).duplicate(),
			"attendance": "absent",
			"minutes_late": 0,
			"approach": "none",
			"scheduled_hours": group.get("scheduled_hours", 0.0),
			"hours_worked": 0.0,
			"overtime_hours": 0.0,
			"gross_wages": 0.0,
			"tips": 0.0,
			"performance_before": performance_before,
			"performance_after": maxf(0.0, performance_before - 8.0),
			"performance_factors": {"attendance": 0, "punctuality": 0, "task_quality": 0},
			"recorded_at": _timestamp(working),
		}
		var shift_result: Dictionary = _simulation.apply_operation(working, "employment.shift", {
			"job_id": job_id, "shift_record": shift_record,
		}, "employment.missed_shift:%s" % job_id)
		if not shift_result.get("ok", false):
			return shift_result
		working = shift_result["state"]
		var reputation_result: Dictionary = _simulation.apply_operation(working, "reputation.adjust", {
			"category": "professional", "amount": -2, "reason": "missed_shift",
		}, "employment.missed_shift:%s" % job_id)
		if not reputation_result.get("ok", false):
			return reputation_result
		working = reputation_result["state"]
		notices.append("Missed %s shift on %s; performance fell by 8." % [active_job.get("title", job_id), group.get("date", "")])
	var payday_result: Dictionary = _process_due_paydays(working)
	if not payday_result.get("ok", false):
		return payday_result
	working = payday_result["state"]
	for notice: Variant in payday_result.get("data", {}).get("notices", []):
		notices.append(str(notice))
	return _success(working, {"notices": notices, "missed_shifts": missed_groups.size()})


func shift_status(state: Dictionary, job_id: String) -> Dictionary:
	var active_job: Dictionary = _active_job(state, job_id)
	if active_job.is_empty():
		return {"ready": false, "reason": "This job is not active."}
	var group: Dictionary = _next_shift_group(state, job_id)
	if group.is_empty():
		return {"ready": false, "reason": "No scheduled shifts are currently on the Calendar."}
	var current_minutes: int = _clock_serial_minutes(state["clock"])
	var start_minutes: int = int(group["start_minutes"])
	var grace: Dictionary = _employment_rules().get("shift_clock_in", {})
	var maximum_late: int = int(grace.get("maximum_late_minutes", 60))
	var minutes_until: int = start_minutes - current_minutes
	var minutes_late: int = maxi(0, current_minutes - start_minutes)
	var ready: bool = minutes_until <= 0 and minutes_late <= maximum_late
	var reason: String = "Next shift: %s • %s." % [group.get("date", ""), _label(str(group.get("start_block", "")))]
	if ready:
		reason = "Clock in now." if minutes_late == 0 else "Clock in now — %d minutes late." % minutes_late
	elif minutes_until > 0 and str(group.get("date", "")) == _date_string(state["clock"]):
		reason = "Shift begins in %d minutes during %s." % [minutes_until, _label(str(group.get("start_block", "")))]
	elif minutes_late > maximum_late:
		reason = "The clock-in window has passed. This shift will be recorded as missed."
	return {
		"ready": ready,
		"reason": reason,
		"job": active_job,
		"shift": group,
		"minutes_late": minutes_late,
		"minutes_until": minutes_until,
	}


func perform_shift(state: Dictionary, job_id: String, approach_id: String = DEFAULT_WORK_APPROACH) -> Dictionary:
	var synced: Dictionary = sync_employment(state)
	if not synced.get("ok", false):
		return synced
	var working: Dictionary = synced["state"]
	var status: Dictionary = shift_status(working, job_id)
	if not bool(status.get("ready", false)):
		return _failure(str(status.get("reason", "This shift is not ready.")))
	if float(working["player"]["needs"].get("inebriation", 0.0)) >= 25.0:
		return _failure("You cannot safely clock in while impaired.")
	if float(working["player"]["needs"].get("energy", 0.0)) < 10.0:
		return _failure("You need at least 10 Energy to complete a work shift.")
	var approach: Dictionary = _work_approach(approach_id)
	if approach.is_empty():
		return _failure("Unknown work approach: %s" % approach_id)
	var active_job: Dictionary = status["job"]
	var group: Dictionary = status["shift"]
	var job: Dictionary = _registry.get_content("jobs", job_id)
	var scheduled_hours: float = float(group.get("scheduled_hours", 0.0))
	var minutes_late: int = int(status.get("minutes_late", 0))
	var hours_worked: float = maxf(0.0, scheduled_hours - float(minutes_late) / 60.0)
	var week_hours_before: float = _hours_worked_in_week(working, str(group.get("week_key", "")))
	var overtime_threshold: float = float(_registry.get_package("port_alder_employment_system").get("economy", {}).get("overtime_after_weekly_hours", 40.0))
	var regular_hours: float = minf(hours_worked, maxf(0.0, overtime_threshold - week_hours_before))
	var overtime_hours: float = maxf(0.0, hours_worked - regular_hours)
	var overtime_multiplier: float = float(_registry.get_package("port_alder_employment_system").get("economy", {}).get("overtime_multiplier", 1.5))
	var hourly_pay: float = float(active_job.get("hourly_pay", job.get("hourly_pay", 0.0)))
	var gross_wages: float = _round_money(regular_hours * hourly_pay + overtime_hours * hourly_pay * overtime_multiplier)

	var energy: float = float(working["player"]["needs"].get("energy", 0.0))
	var focus: float = float(working["player"]["attributes"].get("focus", 0.0))
	var reliability: float = float(working["player"]["attributes"].get("reliability", 0.0))
	var relevant_skill: float = _work_skill_score(working, job)
	var grace_minutes: int = int(_employment_rules().get("shift_clock_in", {}).get("on_time_grace_minutes", 15))
	var punctuality: int = 100 if minutes_late <= grace_minutes else (75 if minutes_late <= 30 else 50)
	var attendance: String = "present" if minutes_late <= grace_minutes else "late"
	var quality_modifier: float = float(approach.get("quality_modifier", 0.0))
	if approach_id == "ambitious" and energy < 40.0:
		quality_modifier -= 15.0
	var task_quality: int = clampi(int(round(relevant_skill * 0.30 + focus * 0.25 + energy * 0.25 + reliability * 0.20 + quality_modifier)), 0, 100)
	var feedback: int = clampi(int(round((float(working["player"]["attributes"].get("charisma", 0.0)) + float(working["player"]["attributes"].get("manners", 0.0))) * 0.5 + float(approach.get("feedback_modifier", 0.0)))), 0, 100)
	var shift_score: float = 100.0 * 0.20 + float(punctuality) * 0.15 + float(task_quality) * 0.35 + relevant_skill * 0.10 + energy * 0.10 + float(feedback) * 0.10
	var performance_before: float = float(active_job.get("performance", 50.0))
	var performance_after: float = clampf(performance_before * 0.80 + shift_score * 0.20, 0.0, 100.0)
	var tips: float = 0.0
	if job.has("expected_tips_per_hour"):
		tips = _round_money(float(job.get("expected_tips_per_hour", 0.0)) * hours_worked * (0.75 + float(task_quality) / 200.0))
	var shift_record: Dictionary = {
		"id": "shift-%s-%s" % [job_id, str(group.get("date", "")).replace("-", "")],
		"job_id": job_id,
		"date": group.get("date", ""),
		"week_key": group.get("week_key", ""),
		"calendar_event_ids": group.get("calendar_event_ids", []).duplicate(),
		"attendance": attendance,
		"minutes_late": minutes_late,
		"approach": approach_id,
		"scheduled_hours": _round_hours(scheduled_hours),
		"hours_worked": _round_hours(hours_worked),
		"regular_hours": _round_hours(regular_hours),
		"overtime_hours": _round_hours(overtime_hours),
		"hourly_pay": hourly_pay,
		"gross_wages": gross_wages,
		"tips": tips,
		"performance_before": performance_before,
		"performance_after": performance_after,
		"performance_factors": {
			"attendance": 100, "punctuality": punctuality, "task_quality": task_quality,
			"relevant_skill": relevant_skill, "energy": energy, "focus": focus,
			"customer_or_team_feedback": feedback,
		},
		"clocked_in_at": _timestamp(working),
	}
	var duration_minutes: int = maxi(1, int(round(hours_worked * 60.0)))
	var result: Dictionary = _simulation.apply_operation(working, "time.advance", {"minutes": duration_minutes}, "employment.shift:%s" % job_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	shift_record["completed_at"] = _timestamp(working)
	result = _simulation.apply_operation(working, "employment.shift", {
		"job_id": job_id, "shift_record": shift_record,
	}, "employment.shift:%s" % job_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	var primary_skill: String = _primary_work_skill(job)
	result = _simulation.apply_operation(working, "skill.add_experience", {
		"skill": primary_skill,
		"experience": hours_worked * (5.0 + float(task_quality) / 10.0),
		"activity_difficulty": maxi(10, int(relevant_skill)),
	}, "employment.shift:%s" % job_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	var need_changes: Dictionary = {
		"energy": -hours_worked * float(approach.get("energy_cost_per_hour", 1.5)),
		"hunger": hours_worked * 1.2,
		"hydration": hours_worked * 1.5,
		"hygiene": -hours_worked * 0.7,
		"stress": float(approach.get("stress_change", 0.0)),
	}
	for need_id: Variant in need_changes:
		result = _simulation.apply_operation(working, "need.adjust", {
			"need": str(need_id), "amount": need_changes[need_id],
		}, "employment.shift:%s" % job_id)
		if not result.get("ok", false):
			return result
		working = result["state"]
	if task_quality >= 65:
		result = _simulation.apply_operation(working, "reputation.adjust", {
			"category": "professional", "amount": 1, "reason": "strong_work_shift",
		}, "employment.shift:%s" % job_id)
		if not result.get("ok", false):
			return result
		working = result["state"]
	return _success(working, {"shift": shift_record, "approach": approach, "notices": synced.get("data", {}).get("notices", [])})


func career_review_status(state: Dictionary, job_id: String) -> Dictionary:
	var active_job: Dictionary = _active_job(state, job_id)
	if active_job.is_empty():
		return {"due": false, "reason": "This job is not active."}
	var due_date: String = str(active_job.get("next_review_date", ""))
	var due: bool = not due_date.is_empty() and _date_serial_from_string(_date_string(state["clock"])) >= _date_serial_from_string(due_date)
	var probation_end: String = str(active_job.get("probation_end_date", ""))
	var probation_complete: bool = probation_end.is_empty() or _date_serial_from_string(_date_string(state["clock"])) >= _date_serial_from_string(probation_end)
	var promotion_report: Dictionary = _promotion_report(state, active_job)
	return {
		"due": due,
		"due_date": due_date,
		"probation_complete": probation_complete,
		"performance": active_job.get("performance", 50.0),
		"promotion": promotion_report,
		"pending_promotion": active_job.get("pending_promotion"),
		"reason": "Review available now." if due else "Next review: %s." % due_date,
	}


func process_career_review(state: Dictionary, job_id: String) -> Dictionary:
	var status: Dictionary = career_review_status(state, job_id)
	if not bool(status.get("due", false)):
		return _failure(str(status.get("reason", "A career review is not due.")))
	if not bool(status.get("probation_complete", false)):
		return _failure("Probation must end before a career review.")
	var working: Dictionary = state.duplicate(true)
	var active_job: Dictionary = _active_job(working, job_id)
	var performance: float = float(active_job.get("performance", 50.0))
	var raises: Dictionary = _employment_rules().get("raises", {})
	var percent_range: Array = raises.get("typical_percent_range", [2, 8])
	var minimum_percent: int = int(percent_range[0]) if not percent_range.is_empty() else 2
	var maximum_percent: int = int(percent_range[1]) if percent_range.size() > 1 else 8
	var raise_percent: int = 0
	var old_pay: float = float(active_job.get("hourly_pay", 0.0))
	var new_pay: float = old_pay
	if performance >= 60.0:
		raise_percent = clampi(minimum_percent + int(floor((performance - 60.0) / 5.0)), minimum_percent, maximum_percent)
		new_pay = _round_money(old_pay * (1.0 + float(raise_percent) / 100.0))
		var raise_result: Dictionary = _simulation.apply_operation(working, "employment.promote_or_raise", {
			"job_id": job_id,
			"change_type": "raise",
			"change_id": "raise-%s-%03d" % [job_id, int(active_job.get("review_count", 0)) + 1],
			"new_title": active_job.get("title", job_id),
			"new_pay": new_pay,
		}, "employment.career_review:%s" % job_id)
		if not raise_result.get("ok", false):
			return raise_result
		working = raise_result["state"]
	active_job = _active_job(working, job_id)
	var promotion_report: Dictionary = _promotion_report(working, active_job)
	if bool(promotion_report.get("eligible", false)):
		active_job["pending_promotion"] = promotion_report.get("step", {}).duplicate(true)
	var interval_days: int = int(raises.get("review_interval_days", 90))
	var review_record: Dictionary = {
		"id": "review-%s-%03d" % [job_id, int(active_job.get("review_count", 0)) + 1],
		"date": _date_string(working["clock"]),
		"performance": performance,
		"raise_percent": raise_percent,
		"old_pay": old_pay,
		"new_pay": new_pay,
		"promotion_opening": bool(promotion_report.get("eligible", false)),
	}
	active_job["review_count"] = int(active_job.get("review_count", 0)) + 1
	if not active_job.has("review_history"):
		active_job["review_history"] = []
	active_job["review_history"].append(review_record)
	active_job["next_review_date"] = _date_string_from_parts(_date_after_days(working["clock"], interval_days))
	return _success(working, {"review": review_record, "promotion": promotion_report})


func accept_promotion(state: Dictionary, job_id: String) -> Dictionary:
	var active_job: Dictionary = _active_job(state, job_id)
	if active_job.is_empty():
		return _failure("This job is not active.")
	var pending_value: Variant = active_job.get("pending_promotion")
	if not pending_value is Dictionary:
		return _failure("There is no promotion opening to accept.")
	var pending: Dictionary = pending_value
	var authored_pay: float = float(pending.get("hourly_pay", active_job.get("hourly_pay", 0.0)))
	var new_pay: float = maxf(authored_pay, _round_money(float(active_job.get("hourly_pay", 0.0)) * 1.03))
	var result: Dictionary = _simulation.apply_operation(state, "employment.promote_or_raise", {
		"job_id": job_id,
		"change_type": "promotion",
		"change_id": "promotion-%s-%03d" % [job_id, int(active_job.get("career_level", 0)) + 1],
		"new_title": pending.get("title", active_job.get("title", job_id)),
		"new_pay": new_pay,
	}, "employment.promotion:%s" % job_id)
	if not result.get("ok", false):
		return result
	return _success(result["state"], {"title": pending.get("title", ""), "hourly_pay": new_pay})


func _schedule_conflicts(state: Dictionary, schedule: Dictionary) -> bool:
	for weekday: Variant in schedule.get("days", []):
		for block: Variant in schedule.get("blocks", []):
			if _required_calendar_slot_exists(state, str(weekday), str(block)):
				return true
	return false


func _required_calendar_slot_exists(state: Dictionary, weekday: String, block: String) -> bool:
	for calendar_event: Variant in state["calendar_state"].get("events", []):
		if not calendar_event is Dictionary or str(calendar_event.get("status", "scheduled")) != "scheduled":
			continue
		if str(calendar_event.get("type", "")) not in ["class", "work"]:
			continue
		if str(calendar_event.get("weekday", "")) == weekday and str(calendar_event.get("block", "")) == block:
			return true
	return false


func _find_interview_slot(state: Dictionary) -> Dictionary:
	for offset: int in range(1, 15):
		var date: Dictionary = _date_after_days(state["clock"], offset)
		for block: String in INTERVIEW_BLOCKS:
			if not _calendar_slot_exists(state, _date_string_from_parts(date), block):
				return {"date": _date_string_from_parts(date), "weekday": date["weekday"], "block": block}
	return {}


func _calendar_slot_exists(state: Dictionary, date: String, block: String) -> bool:
	for calendar_event: Variant in state["calendar_state"].get("events", []):
		if calendar_event is Dictionary and str(calendar_event.get("status", "scheduled")) == "scheduled" and str(calendar_event.get("date", "")) == date and str(calendar_event.get("block", "")) == block:
			return true
	return false


func _create_work_calendar(state: Dictionary, active_job: Dictionary, schedule: Dictionary, start: Dictionary, days: int) -> void:
	var date: Dictionary = start.duplicate(true)
	for offset: int in days:
		if str(date["weekday"]) in schedule.get("days", []):
			for block: Variant in schedule.get("blocks", []):
				var event_id: String = "work-%s-%s-%s" % [active_job["job_id"], _date_string_from_parts(date).replace("-", ""), block]
				if not _record_by_id(state["calendar_state"].get("events", []), event_id).is_empty():
					continue
				state["calendar_state"]["events"].append({
					"id": event_id,
					"title": "%s Shift" % active_job["title"],
					"job_id": active_job["job_id"],
					"type": "work",
					"source": "employment.contract",
					"date": _date_string_from_parts(date),
					"weekday": date["weekday"],
					"block": block,
					"location": active_job.get("location", ""),
					"participants": [],
					"status": "scheduled",
				})
		date = _advance_date(date)


func _ensure_future_work_calendar(state: Dictionary, active_job: Dictionary) -> void:
	var job_id: String = str(active_job.get("job_id", ""))
	var last_serial: int = -1
	for calendar_event: Variant in state["calendar_state"].get("events", []):
		if not calendar_event is Dictionary or str(calendar_event.get("job_id", "")) != job_id or str(calendar_event.get("type", "")) != "work":
			continue
		last_serial = maxi(last_serial, _date_serial_from_string(str(calendar_event.get("date", ""))))
	var current_serial: int = _date_serial_days(int(state["clock"]["year"]), int(state["clock"]["month"]), int(state["clock"]["day"]))
	if last_serial >= current_serial + 14:
		return
	var start: Dictionary = _date_after_days(state["clock"], 0)
	if last_serial >= current_serial:
		start = _parts_from_date_serial(last_serial + 1)
	var end_serial: int = current_serial + 42
	var days: int = maxi(0, end_serial - _date_serial_days(int(start["year"]), int(start["month"]), int(start["day"])) + 1)
	if days > 0:
		_create_work_calendar(state, active_job, active_job.get("schedule", {}), start, days)


func _past_due_shift_groups(state: Dictionary) -> Array:
	var groups: Dictionary = {}
	var current_minutes: int = _clock_serial_minutes(state["clock"])
	var maximum_late: int = int(_employment_rules().get("shift_clock_in", {}).get("maximum_late_minutes", 60))
	for calendar_event: Variant in state["calendar_state"].get("events", []):
		if not calendar_event is Dictionary or str(calendar_event.get("type", "")) != "work" or str(calendar_event.get("status", "scheduled")) != "scheduled":
			continue
		var job_id: String = str(calendar_event.get("job_id", ""))
		if _active_job(state, job_id).is_empty():
			continue
		var date: String = str(calendar_event.get("date", ""))
		var key: String = "%s|%s" % [job_id, date]
		if not groups.has(key):
			groups[key] = {"job_id": job_id, "date": date, "events": []}
		groups[key]["events"].append(calendar_event)
	var due: Array = []
	for key: Variant in groups:
		var group: Dictionary = _finalize_shift_group(state, groups[key])
		if current_minutes > int(group.get("start_minutes", 0)) + maximum_late:
			due.append(group)
	return due


func _next_shift_group(state: Dictionary, job_id: String) -> Dictionary:
	var groups: Dictionary = {}
	for calendar_event: Variant in state["calendar_state"].get("events", []):
		if not calendar_event is Dictionary or str(calendar_event.get("type", "")) != "work" or str(calendar_event.get("job_id", "")) != job_id or str(calendar_event.get("status", "scheduled")) != "scheduled":
			continue
		var date: String = str(calendar_event.get("date", ""))
		if not groups.has(date):
			groups[date] = {"job_id": job_id, "date": date, "events": []}
		groups[date]["events"].append(calendar_event)
	var earliest: Dictionary = {}
	for date: Variant in groups:
		var group: Dictionary = _finalize_shift_group(state, groups[date])
		if earliest.is_empty() or int(group["start_minutes"]) < int(earliest["start_minutes"]):
			earliest = group
	return earliest


func _finalize_shift_group(state: Dictionary, raw_group: Dictionary) -> Dictionary:
	var active_job: Dictionary = _active_job(state, str(raw_group.get("job_id", "")))
	var schedule: Dictionary = active_job.get("schedule", {})
	var days_per_week: int = maxi(1, schedule.get("days", []).size())
	var scheduled_hours: float = float(active_job.get("weekly_hours", 0.0)) / float(days_per_week)
	var start_block: String = "night"
	var start_index: int = GameClockScript.BLOCKS.size()
	var calendar_event_ids: PackedStringArray = []
	for event_value: Variant in raw_group.get("events", []):
		if not event_value is Dictionary:
			continue
		var block: String = str(event_value.get("block", "night"))
		var block_index: int = GameClockScript.BLOCKS.find(block)
		if block_index >= 0 and block_index < start_index:
			start_index = block_index
			start_block = block
		calendar_event_ids.append(str(event_value.get("id", "")))
	var date: String = str(raw_group.get("date", ""))
	return {
		"job_id": raw_group.get("job_id", ""),
		"date": date,
		"start_block": start_block,
		"start_minutes": _event_serial_minutes(date, start_block),
		"scheduled_hours": _round_hours(scheduled_hours),
		"calendar_event_ids": calendar_event_ids,
		"week_key": _week_key_for_date(date),
	}


func _process_due_paydays(state: Dictionary) -> Dictionary:
	var working: Dictionary = state
	var notices: PackedStringArray = []
	var job_ids: PackedStringArray = []
	for active_job_value: Variant in working["player"]["employment"].get("active_jobs", []):
		if active_job_value is Dictionary and str(active_job_value.get("status", "active")) == "active":
			job_ids.append(str(active_job_value.get("job_id", "")))
	for job_id: String in job_ids:
		var guard: int = 0
		while guard < 104:
			guard += 1
			var active_job: Dictionary = _active_job(working, job_id)
			var payday: String = str(active_job.get("next_payday", ""))
			if payday.is_empty() or _date_serial_from_string(payday) > _date_serial_from_string(_date_string(working["clock"])):
				break
			var next_payday: String = _date_string_from_parts(_advance_date_by(_date_parts(payday), 7))
			var pending: Dictionary = active_job.get("pending_pay", {})
			var gross: float = _round_money(float(pending.get("gross_wages", 0.0)))
			var tips: float = _round_money(float(pending.get("tips", 0.0)))
			var taxable: float = gross + tips
			if taxable <= 0.0:
				active_job["next_payday"] = next_payday
				continue
			var withholding_rate: float = _withholding_rate(taxable)
			var withholding: float = _round_money(taxable * withholding_rate)
			var net: float = _round_money(taxable - withholding)
			var pay_record: Dictionary = {
				"id": "payday-%s-%s" % [job_id, payday.replace("-", "")],
				"job_id": job_id,
				"pay_date": payday,
				"hours": _round_hours(float(pending.get("hours", 0.0))),
				"overtime_hours": _round_hours(float(pending.get("overtime_hours", 0.0))),
				"gross": gross,
				"tips": tips,
				"withholding_rate": withholding_rate,
				"withholding": withholding,
				"net": net,
			}
			var result: Dictionary = _simulation.apply_operation(working, "economy.payday", {
				"job_id": job_id, "pay_record": pay_record, "next_payday": next_payday,
			}, "employment.payday:%s" % job_id)
			if not result.get("ok", false):
				return result
			working = result["state"]
			notices.append("Payday from %s: $%.2f net deposited to checking." % [active_job.get("employer", job_id), net])
	return _success(working, {"notices": notices})


func _withholding_rate(taxable: float) -> float:
	var brackets: Array = _registry.get_package("port_alder_economy_system").get("income_rules", {}).get("withholding_brackets", [])
	for bracket: Variant in brackets:
		if not bracket is Dictionary:
			continue
		var maximum: Variant = bracket.get("weekly_gross_max")
		if maximum == null or taxable <= float(maximum):
			return float(bracket.get("rate", 0.0))
	return 0.0


func _promotion_report(state: Dictionary, active_job: Dictionary) -> Dictionary:
	var job: Variant = _registry.get_content("jobs", str(active_job.get("job_id", "")))
	if not job is Dictionary:
		return {"available": false, "eligible": false, "missing": PackedStringArray()}
	var career_level: int = int(active_job.get("career_level", 0))
	var path: Array = job.get("promotion_path", [])
	if career_level >= path.size():
		return {"available": false, "eligible": false, "missing": PackedStringArray(), "reason": "Top authored career level reached."}
	var step: Dictionary = path[career_level]
	var missing: PackedStringArray = []
	var required_performance: float = float(step.get("requires_performance", 0.0))
	if float(active_job.get("performance", 0.0)) < required_performance:
		missing.append("Performance %.0f/%.0f" % [active_job.get("performance", 0.0), required_performance])
	var skill_requirement: Array = step.get("requires_skill", [])
	if skill_requirement.size() == 2:
		var skill_id: String = str(skill_requirement[0])
		var required_skill: int = int(skill_requirement[1])
		var current_skill: int = int(state["player"].get("skills", {}).get(skill_id, 0))
		if current_skill < required_skill:
			missing.append("%s %d/%d" % [_label(skill_id), current_skill, required_skill])
	if step.has("requires_reputation"):
		var required_reputation: int = int(step["requires_reputation"])
		var current_reputation: int = int(state["player"].get("reputations", {}).get("professional", 0))
		if current_reputation < required_reputation:
			missing.append("Professional reputation %d/%d" % [current_reputation, required_reputation])
	return {
		"available": true,
		"eligible": missing.is_empty(),
		"step": step,
		"missing": missing,
		"reason": "Eligible when an opening appears." if missing.is_empty() else "; ".join(missing),
	}


func _work_approach(approach_id: String) -> Dictionary:
	for approach: Variant in _employment_rules().get("work_approaches", []):
		if approach is Dictionary and str(approach.get("id", "")) == approach_id:
			return approach
	return {}


func _employment_rules() -> Dictionary:
	return _registry.get_package("port_alder_employment_system").get("employment_rules", {})


func _active_job(state: Dictionary, job_id: String) -> Dictionary:
	for active_job: Variant in state["player"]["employment"].get("active_jobs", []):
		if active_job is Dictionary and str(active_job.get("job_id", "")) == job_id and str(active_job.get("status", "active")) == "active":
			return active_job
	return {}


func _hours_worked_in_week(state: Dictionary, week_key: String) -> float:
	var hours: float = 0.0
	for shift: Variant in state["player"]["employment"].get("work_history", []):
		if shift is Dictionary and str(shift.get("week_key", "")) == week_key:
			hours += float(shift.get("hours_worked", 0.0))
	return hours


func _work_skill_score(state: Dictionary, job: Dictionary) -> float:
	var requirements: Dictionary = job.get("requirements", {})
	var values: Array = []
	for skill_id: Variant in requirements.get("skills", {}):
		values.append(minf(100.0, float(state["player"].get("skills", {}).get(str(skill_id), 0.0)) * 2.0))
	for skill_requirement: Variant in requirements.get("skills_any", []):
		if skill_requirement is Array and not skill_requirement.is_empty():
			values.append(minf(100.0, float(state["player"].get("skills", {}).get(str(skill_requirement[0]), 0.0)) * 2.0))
	if values.is_empty():
		return (float(state["player"]["attributes"].get("focus", 0.0)) + float(state["player"]["attributes"].get("stamina", 0.0))) * 0.5
	var total: float = 0.0
	for value: Variant in values:
		total += float(value)
	return total / float(values.size())


func _primary_work_skill(job: Dictionary) -> String:
	var skills: Dictionary = job.get("requirements", {}).get("skills", {})
	for skill_id: Variant in skills:
		return str(skill_id)
	var skills_any: Array = job.get("requirements", {}).get("skills_any", [])
	if not skills_any.is_empty() and skills_any[0] is Array and not skills_any[0].is_empty():
		return str(skills_any[0][0])
	var job_id: String = str(job.get("id", ""))
	if job_id in ["restaurant_dishwasher", "restaurant_server"]:
		return "hospitality"
	if job_id in ["grocery_stock_clerk", "warehouse_associate"]:
		return "organization"
	return "customer_service"


func _application_for_job(state: Dictionary, job_id: String) -> Dictionary:
	for application: Variant in state["player"]["employment"].get("applications", []):
		if application is Dictionary and str(application.get("job_id", "")) == job_id and str(application.get("stage", "")) not in ["declined", "withdrawn"]:
			return application
	return {}


func _resume_snapshot(state: Dictionary) -> Dictionary:
	var skills: Dictionary = state["player"].get("skills", {})
	var attributes: Dictionary = state["player"].get("attributes", {})
	var quality: int = clampi(
		20 + int(skills.get("writing", 0)) + int(skills.get("administration", 0)) + int(attributes.get("focus", 0)) / 4 + int(attributes.get("responsibility", 0)) / 4,
		0, 100
	)
	return {"quality": quality, "education": state["player"]["education"].duplicate(true), "skills": skills.duplicate(true)}


func _punctuality_score(state: Dictionary, interview: Dictionary) -> int:
	var scheduled: int = _event_serial_minutes(str(interview.get("date", "")), str(interview.get("block", "morning")))
	var difference: int = _clock_serial_minutes(state["clock"]) - scheduled
	if difference <= 15:
		return 15
	if difference <= 30:
		return 7
	return 0


func _reputation_and_referral_score(state: Dictionary, job: Dictionary) -> int:
	var score: int = mini(5, maxi(0, int(state["player"].get("reputations", {}).get("professional", 0)) / 10))
	var referral: String = str(job.get("referral_character", ""))
	if not referral.is_empty() and referral in state["player"]["phone"].get("known_contacts", []):
		score += 5
	return mini(score, 10)


func _interview_outfit_score(state: Dictionary) -> int:
	var outfit: Dictionary = state["player"]["inventory"].get("equipped_outfit", {})
	if float(state["player"]["needs"].get("hygiene", 0.0)) < 50.0:
		return 0
	var scores: Dictionary = {"warmth": 0, "rain_protection": 0, "wind_protection": 0}
	for slot: String in ["shirt", "pants", "shoes"]:
		var item_id: String = str(outfit.get(slot, ""))
		if item_id.is_empty() or _item_cleanliness(state, item_id) < 50:
			return 0
	for item_id_value: Variant in outfit.values():
		var item: Variant = _registry.get_content("items", str(item_id_value))
		if not item is Dictionary:
			continue
		for score_id: Variant in scores:
			scores[score_id] = int(scores[score_id]) + int(item.get(score_id, 0))
	var clothing: Dictionary = state["world_state"].get("weather", {}).get("clothing", {})
	if int(scores["warmth"]) < int(clothing.get("minimum_warmth", 0)):
		return 0
	if int(scores["rain_protection"]) < int(clothing.get("rain_protection", 0)):
		return 0
	if int(scores["wind_protection"]) < int(clothing.get("wind_protection", 0)):
		return 0
	return 5


func _item_cleanliness(state: Dictionary, item_id: String) -> int:
	for container: Variant in state["player"]["inventory"].get("containers", []):
		if not container is Dictionary:
			continue
		for stack: Variant in container.get("items", []):
			if stack is Dictionary and str(stack.get("item_id", "")) == item_id:
				return int(stack.get("item_state", {}).get("cleanliness", 100))
	return 100


func _has_trait_quality(state: Dictionary, trait_id: String) -> bool:
	if trait_id in state["player"]["selected_traits"].get("positive", []):
		return true
	var attribute_id: String = str(TRAIT_ATTRIBUTES.get(trait_id, trait_id))
	return float(state["player"].get("attributes", {}).get(attribute_id, 0.0)) >= 35.0


func _any_trait_quality(state: Dictionary, traits: Array) -> bool:
	for trait_id: Variant in traits:
		if _has_trait_quality(state, str(trait_id)):
			return true
	return false


func _default_requested_type(state: Dictionary, job: Dictionary) -> String:
	var search_filter: String = str(state["player"]["employment"].get("search_filter", ""))
	if search_filter in job.get("employment_types", []):
		return search_filter
	return str(job.get("employment_types", ["part_time"])[0])


func _schedule_by_id(schedules: Array, schedule_id: String) -> Dictionary:
	for schedule: Variant in schedules:
		if schedule is Dictionary and str(schedule.get("id", "")) == schedule_id:
			return schedule
	return {}


func _record_by_id(records: Array, record_id: String) -> Dictionary:
	for record: Variant in records:
		if record is Dictionary and str(record.get("id", "")) == record_id:
			return record
	return {}


func _record_requirement(passed: bool, label: String, met: PackedStringArray, missing: PackedStringArray) -> void:
	if passed:
		met.append(label)
	else:
		missing.append(label)


func _joined_labels(values: Array) -> String:
	var labels: PackedStringArray = []
	for value: Variant in values:
		labels.append(_label(str(value)))
	return ", ".join(labels)


func _label(value: String) -> String:
	return value.replace("_", " ").capitalize()


func _timestamp(state: Dictionary) -> String:
	return "Y%d-%02d-%02d:%s+%03d" % [state["clock"]["year"], state["clock"]["month"], state["clock"]["day"], state["clock"]["block"], state["clock"]["minute_within_block"]]


func _date_after_days(clock: Dictionary, days: int) -> Dictionary:
	var date: Dictionary = {"year": int(clock["year"]), "month": int(clock["month"]), "day": int(clock["day"]), "weekday": str(clock["weekday"])}
	return _advance_date_by(date, days)


func _advance_date_by(date: Dictionary, days: int) -> Dictionary:
	var advanced: Dictionary = date.duplicate(true)
	for _index: int in days:
		advanced = _advance_date(advanced)
	return advanced


func _next_weekday_after(date: Dictionary, weekday: String) -> Dictionary:
	var candidate: Dictionary = _advance_date(date)
	while str(candidate.get("weekday", "")) != weekday:
		candidate = _advance_date(candidate)
	return candidate


func _advance_date(date: Dictionary) -> Dictionary:
	var next: Dictionary = date.duplicate(true)
	next["day"] = int(next["day"]) + 1
	if int(next["day"]) > _days_in_month(int(next["month"]), int(next["year"])):
		next["day"] = 1
		next["month"] = int(next["month"]) + 1
		if int(next["month"]) > 12:
			next["month"] = 1
			next["year"] = int(next["year"]) + 1
	var weekday_index: int = GameClockScript.WEEKDAYS.find(str(date["weekday"]))
	next["weekday"] = GameClockScript.WEEKDAYS[(weekday_index + 1) % GameClockScript.WEEKDAYS.size()]
	return next


func _date_string_from_parts(date: Dictionary) -> String:
	return "Y%d-%02d-%02d" % [date["year"], date["month"], date["day"]]


func _date_string(clock: Dictionary) -> String:
	return "Y%d-%02d-%02d" % [clock["year"], clock["month"], clock["day"]]


func _date_parts(date: String) -> Dictionary:
	var parts: PackedStringArray = date.trim_prefix("Y").split("-")
	if parts.size() != 3:
		return {"year": 1, "month": 1, "day": 1, "weekday": "monday"}
	var serial: int = _date_serial_days(int(parts[0]), int(parts[1]), int(parts[2]))
	return {
		"year": int(parts[0]), "month": int(parts[1]), "day": int(parts[2]),
		"weekday": _weekday_for_serial(serial),
	}


func _date_serial_from_string(date: String) -> int:
	var parts: PackedStringArray = date.trim_prefix("Y").split("-")
	if parts.size() != 3:
		return -1
	return _date_serial_days(int(parts[0]), int(parts[1]), int(parts[2]))


func _parts_from_date_serial(serial: int) -> Dictionary:
	var remaining: int = maxi(0, serial)
	var year: int = 1
	while remaining >= (366 if year % 4 == 0 else 365):
		remaining -= 366 if year % 4 == 0 else 365
		year += 1
	var month: int = 1
	while remaining >= _days_in_month(month, year):
		remaining -= _days_in_month(month, year)
		month += 1
	return {"year": year, "month": month, "day": remaining + 1, "weekday": _weekday_for_serial(serial)}


func _weekday_for_serial(serial: int) -> String:
	var opening_serial: int = _date_serial_days(1, 8, 20)
	var opening_index: int = GameClockScript.WEEKDAYS.find("tuesday")
	return GameClockScript.WEEKDAYS[posmod(opening_index + serial - opening_serial, GameClockScript.WEEKDAYS.size())]


func _week_key_for_date(date: String) -> String:
	var parts: Dictionary = _date_parts(date)
	var serial: int = _date_serial_from_string(date)
	return "Y%d-W%03d" % [parts["year"], int(floor(float(serial) / 7.0)) + 1]


func _clock_serial_minutes(clock: Dictionary) -> int:
	return _date_serial_days(int(clock["year"]), int(clock["month"]), int(clock["day"])) * 1440 + _block_start_minutes(str(clock["block"])) + int(clock["minute_within_block"])


func _event_serial_minutes(date: String, block: String) -> int:
	var parts: PackedStringArray = date.trim_prefix("Y").split("-")
	if parts.size() != 3:
		return 0
	return _date_serial_days(int(parts[0]), int(parts[1]), int(parts[2])) * 1440 + _block_start_minutes(block)


func _date_serial_days(year: int, month: int, day: int) -> int:
	var days: int = 0
	for previous_year: int in range(1, year):
		days += 366 if previous_year % 4 == 0 else 365
	for previous_month: int in range(1, month):
		days += _days_in_month(previous_month, year)
	return days + day - 1


func _days_in_month(month: int, year: int) -> int:
	if month in [4, 6, 9, 11]:
		return 30
	if month == 2:
		return 29 if year % 4 == 0 else 28
	return 31


func _block_start_minutes(block: String) -> int:
	var minutes: int = 0
	for candidate: String in GameClockScript.BLOCKS:
		if candidate == block:
			break
		minutes += int(GameClockScript.BLOCK_MINUTES[candidate])
	return minutes


func _round_money(value: float) -> float:
	return round(value * 100.0) / 100.0


func _round_hours(value: float) -> float:
	return round(value * 100.0) / 100.0


func _success(state: Dictionary, data: Dictionary = {}) -> Dictionary:
	return {"ok": true, "state": state, "data": data, "errors": PackedStringArray()}


func _failure(message: String) -> Dictionary:
	return {"ok": false, "errors": PackedStringArray([message])}
