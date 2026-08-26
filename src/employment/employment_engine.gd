extends RefCounted
class_name PortAlderEmploymentEngine

const GameClockScript: GDScript = preload("res://src/simulation/game_clock.gd")
const FILTERS: PackedStringArray = ["all", "qualified", "part_time", "full_time"]
const INTERVIEW_BLOCKS: PackedStringArray = ["morning", "lunch", "afternoon", "evening"]
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
		"probation_ends_after_days": 30,
		"performance": 50,
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
				state["calendar_state"]["events"].append({
					"id": "work-%s-%s-%03d" % [active_job["job_id"], block, offset],
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
	for _index: int in days:
		date = _advance_date(date)
	return date


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


func _clock_serial_minutes(clock: Dictionary) -> int:
	return _date_serial_days(int(clock["year"]), int(clock["month"]), int(clock["day"])) * 1440 + _block_start_minutes(str(clock["block"])) + int(clock["minute_within_block"])


func _event_serial_minutes(date: String, block: String) -> int:
	var parts: PackedStringArray = date.trim_prefix("Y").split("-")
	if parts.size() != 3:
		return 0
	return _date_serial_days(int(parts[0]), int(parts[1]), int(parts[2])) * 1440 + _block_start_minutes(block)


func _date_serial_days(year: int, month: int, day: int) -> int:
	var days: int = (year - 1) * 365
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


func _success(state: Dictionary, data: Dictionary = {}) -> Dictionary:
	return {"ok": true, "state": state, "data": data, "errors": PackedStringArray()}


func _failure(message: String) -> Dictionary:
	return {"ok": false, "errors": PackedStringArray([message])}
