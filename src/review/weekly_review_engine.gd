extends RefCounted
class_name PortAlderWeeklyReviewEngine

const PACKAGE_ID: String = "port_alder_weekly_review_system"
const BLOCKS: PackedStringArray = [
	"early_morning", "morning", "lunch", "afternoon", "evening", "late_evening", "night",
]

var _registry: Node
var _simulation: RefCounted


func _init(content_registry: Node, simulation_engine: RefCounted) -> void:
	_registry = content_registry
	_simulation = simulation_engine


func review_status(state: Dictionary) -> Dictionary:
	if state.is_empty():
		return {"due": false, "pending": false, "reason": "No active game."}
	var review_state: Dictionary = _review_state_snapshot(state)
	var pending: Variant = review_state.get("pending")
	if pending is Dictionary:
		return {
			"due": true,
			"pending": true,
			"review_id": pending.get("id", ""),
			"reason": "Your weekly reflection is ready.",
		}
	var clock: Dictionary = state["clock"]
	var current_week: int = int(clock.get("week_number", 1))
	if int(review_state.get("last_completed_week", 0)) >= current_week:
		return {"due": false, "pending": false, "reason": "This week's review is complete."}
	var availability: Dictionary = _package().get("availability", {})
	var due: bool = (
		str(clock.get("weekday", "")) == str(availability.get("weekday", "sunday"))
		and BLOCKS.find(str(clock.get("block", ""))) >= BLOCKS.find(str(availability.get("opening_block", "evening")))
	)
	return {
		"due": due,
		"pending": false,
		"review_id": _review_id(clock),
		"reason": "Sunday Evening begins the weekly reflection." if due else "The weekly reflection opens Sunday Evening.",
	}


func synchronize(state: Dictionary) -> Dictionary:
	var status: Dictionary = review_status(state)
	if not bool(status.get("due", false)):
		return _success(state.duplicate(true), {"created": false, "status": status})
	var working: Dictionary = state.duplicate(true)
	_ensure_runtime_shape(working)
	if working["weekly_review_state"].get("pending") is Dictionary:
		return _success(working, {"created": false, "review": working["weekly_review_state"]["pending"].duplicate(true)})
	var review: Dictionary = {
		"id": _review_id(working["clock"]),
		"week_number": int(working["clock"].get("week_number", 1)),
		"start_date": str(working["simulation"].get("weekly_tracking", {}).get("start_date", _date_string(working["clock"]))),
		"end_date": _date_string(working["clock"]),
		"created_at": _timestamp(working["clock"]),
		"summary": build_summary(working),
		"priorities": [],
		"status": "pending",
		"tone": "reflective_not_judgmental",
	}
	working["weekly_review_state"]["pending"] = review
	return _success(working, {"created": true, "review": review.duplicate(true)})


func current_review(state: Dictionary) -> Dictionary:
	var pending: Variant = state.get("weekly_review_state", {}).get("pending")
	return pending.duplicate(true) if pending is Dictionary else {}


func priority_definitions() -> Array:
	return _package().get("review_priorities", []).duplicate(true)


func toggle_priority(state: Dictionary, priority_id: String) -> Dictionary:
	var definition: Dictionary = _definition_by_id(priority_definitions(), priority_id)
	if definition.is_empty():
		return _failure("Unknown weekly priority: %s" % priority_id)
	var working: Dictionary = state.duplicate(true)
	_ensure_runtime_shape(working)
	var pending: Variant = working["weekly_review_state"].get("pending")
	if not pending is Dictionary:
		return _failure("Open the weekly review before choosing priorities.")
	var priorities: Array = pending.get("priorities", [])
	if priority_id in priorities:
		priorities.erase(priority_id)
	else:
		var maximum: int = int(_package().get("maximum_priorities", 3))
		if priorities.size() >= maximum:
			return _failure("Choose up to %d priorities for next week." % maximum)
		priorities.append(priority_id)
	pending["priorities"] = priorities
	return _success(working, {"priorities": priorities.duplicate(true)})


func complete_review(state: Dictionary, keep_priorities: bool = true) -> Dictionary:
	var working: Dictionary = state.duplicate(true)
	_ensure_runtime_shape(working)
	var pending_value: Variant = working["weekly_review_state"].get("pending")
	if not pending_value is Dictionary:
		return _failure("There is no weekly review waiting to be completed.")
	var record: Dictionary = pending_value.duplicate(true)
	if not keep_priorities:
		record["priorities"] = []
	var details: Array = []
	for priority_id_value: Variant in record.get("priorities", []):
		var definition: Dictionary = _definition_by_id(priority_definitions(), str(priority_id_value))
		if not definition.is_empty():
			details.append(definition)
	record["priority_details"] = details
	record["completed_at"] = _timestamp(working["clock"])
	record["status"] = "completed"
	record["reflection"] = "This review records what happened and what you want to protect next. It does not grade your life."
	record["next_week_scheduled_commitments"] = _next_week_commitment_count(working)
	var result: Dictionary = _simulation.apply_operation(
		working, "review.complete", {"review_record": record}, "weekly_review:%s" % record.get("id", "")
	)
	if not result.get("ok", false):
		return result
	return _success(result["state"], {
		"review": record,
		"message": "Weekly review saved. Your priorities are reminders, not a score.",
	})


func build_summary(state: Dictionary) -> Dictionary:
	var tracking: Dictionary = state.get("simulation", {}).get("weekly_tracking", {})
	var start_date: String = str(tracking.get("start_date", _date_string(state["clock"])))
	var end_date: String = _date_string(state["clock"])
	return {
		"direction": _direction_summary(state),
		"money": _money_summary(state, start_date, end_date),
		"time": _time_summary(state, start_date, end_date, tracking),
		"health": _health_summary(state, tracking),
		"relationships": _relationship_summary(state, start_date, end_date),
		"quests": _quest_summary(state),
	}


func _direction_summary(state: Dictionary) -> Dictionary:
	var player: Dictionary = state["player"]
	var education: Dictionary = player.get("education", {})
	var jobs: PackedStringArray = []
	for active_job_value: Variant in player.get("employment", {}).get("active_jobs", []):
		if active_job_value is Dictionary and str(active_job_value.get("status", "active")) == "active":
			jobs.append(str(active_job_value.get("title", active_job_value.get("job_id", "Job"))).replace("_", " ").capitalize())
	return {
		"life_path": str(player.get("life_path", "undecided")).replace("_", " ").capitalize(),
		"enrolled": bool(education.get("enrolled", false)),
		"program": str(education.get("program", "Not enrolled")).replace("_", " ").capitalize() if bool(education.get("enrolled", false)) else "Not enrolled",
		"course_count": education.get("courses", []).size(),
		"employed": bool(player.get("employment", {}).get("employed", false)),
		"jobs": jobs,
	}


func _money_summary(state: Dictionary, start_date: String, end_date: String) -> Dictionary:
	var income: float = 0.0
	var spending: float = 0.0
	var categories: Dictionary = {}
	for entry_value: Variant in state["player"]["economy"].get("ledger", []):
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		if not _date_in_range(str(entry.get("date", "")), start_date, end_date):
			continue
		var amount: float = float(entry.get("amount", 0.0))
		if amount >= 0.0:
			income += amount
		else:
			spending += -amount
			var category: String = str(entry.get("category", "other")).replace("_", " ").capitalize()
			categories[category] = float(categories.get(category, 0.0)) + -amount
	var balance: float = 0.0
	for account_value: Variant in state["player"]["economy"].get("accounts", {}).values():
		balance += float(account_value)
	return {
		"available_balance": snappedf(balance, 0.01),
		"income": snappedf(income, 0.01),
		"spending": snappedf(spending, 0.01),
		"spending_categories": categories,
		"tuition_balance": float(state["player"]["education"].get("tuition_balance", 0.0)),
		"student_debt": float(state["player"]["education"].get("student_debt", 0.0)),
		"rent_due": float(state["player"]["housing"].get("rent_balance", 0.0)),
	}


func _time_summary(state: Dictionary, start_date: String, end_date: String, tracking: Dictionary) -> Dictionary:
	var completed: int = 0
	var missed: int = 0
	var cancelled: int = 0
	var late: int = 0
	for event_value: Variant in state["calendar_state"].get("events", []):
		if not event_value is Dictionary or not _date_in_range(str(event_value.get("date", "")), start_date, end_date):
			continue
		match str(event_value.get("status", "scheduled")):
			"completed": completed += 1
			"missed": missed += 1
			"cancelled": cancelled += 1
		if int(event_value.get("late_minutes", 0)) > 0:
			late += 1
	var elapsed_minutes: int = int(tracking.get("elapsed_minutes", 0))
	var days: int = maxi(1, _date_value(end_date) - _date_value(start_date) + 1)
	return {
		"elapsed_hours": snappedf(float(elapsed_minutes) / 60.0, 0.1),
		"completed_commitments": completed,
		"missed_commitments": missed,
		"cancelled_commitments": cancelled,
		"late_arrivals": late,
		"sleep_sessions": int(tracking.get("sleep_sessions", 0)),
		"sleep_hours_per_day": snappedf(float(tracking.get("sleep_minutes", 0)) / 60.0 / days, 0.1),
		"nap_hours": snappedf(float(tracking.get("nap_minutes", 0)) / 60.0, 0.1),
	}


func _health_summary(state: Dictionary, tracking: Dictionary) -> Dictionary:
	var elapsed: float = float(tracking.get("elapsed_minutes", 0))
	var weighted: Dictionary = tracking.get("need_weighted_totals", {})
	var needs: Dictionary = state["player"]["needs"]
	var averages: Dictionary = {}
	for need_id: String in ["energy", "hygiene", "mood", "stress"]:
		averages[need_id] = snappedf(float(weighted.get(need_id, float(needs.get(need_id, 0.0)) * maxf(elapsed, 1.0))) / maxf(elapsed, 1.0), 0.1)
	return {
		"averages": averages,
		"current_energy": float(needs.get("energy", 0.0)),
		"current_hygiene": float(needs.get("hygiene", 0.0)),
		"weather_exposure_hours": snappedf(float(tracking.get("weather_exposure_minutes", 0)) / 60.0, 0.1),
		"workouts": int(tracking.get("workouts", 0)),
		"inebriation_incidents": int(tracking.get("inebriation_incidents", 0)),
		"active_conditions": state["player"].get("health", {}).get("conditions", []).size(),
	}


func _relationship_summary(state: Dictionary, start_date: String, end_date: String) -> Dictionary:
	var meter_changes: Dictionary = {}
	for event_value: Variant in state.get("simulation", {}).get("recent_event_log", []):
		if not event_value is Dictionary or str(event_value.get("operation", "")) != "relationship.adjust_meter":
			continue
		var event_date: String = str(event_value.get("game_timestamp", "")).get_slice(":", 0)
		if not _date_in_range(event_date, start_date, end_date):
			continue
		var payload: Dictionary = event_value.get("payload", {})
		var character_id: String = str(payload.get("character_id", ""))
		var meter: String = str(payload.get("meter", ""))
		var key: String = "%s:%s" % [character_id, meter]
		meter_changes[key] = float(meter_changes.get(key, 0.0)) + float(payload.get("amount", 0.0))
	var closest: Array = []
	for character_id_value: Variant in state["player"]["phone"].get("known_contacts", []):
		var character_id: String = str(character_id_value)
		var relationship: Dictionary = state["relationships"].get(character_id, {})
		closest.append({
			"character_id": character_id,
			"name": _character_name(character_id),
			"bond": maxi(int(relationship.get("friendship", 0)), int(relationship.get("love", 0))),
			"stage": relationship.get("relationship_stage", "acquaintance"),
		})
	closest.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return int(left.get("bond", 0)) > int(right.get("bond", 0)))
	if closest.size() > 3:
		closest.resize(3)
	var dates_kept: int = 0
	var dates_broken: int = 0
	var chapters: int = 0
	for relationship_value: Variant in state.get("relationships", {}).values():
		if not relationship_value is Dictionary:
			continue
		for record_value: Variant in relationship_value.get("dating_history", []):
			if record_value is Dictionary and _date_in_range(str(record_value.get("date", "")), start_date, end_date):
				if str(record_value.get("outcome", "")) == "completed": dates_kept += 1
				elif str(record_value.get("outcome", "")) in ["cancelled", "no_show"]: dates_broken += 1
		for chapter_value: Variant in relationship_value.get("chapter_notifications", []):
			if chapter_value is Dictionary and _date_in_range(str(chapter_value.get("unlocked_on", "")), start_date, end_date):
				chapters += 1
	return {
		"known_contacts": state["player"]["phone"].get("known_contacts", []).size(),
		"closest": closest,
		"meter_changes": meter_changes,
		"dates_kept": dates_kept,
		"dates_broken": dates_broken,
		"chapters_unlocked": chapters,
	}


func _quest_summary(state: Dictionary) -> Dictionary:
	return {
		"completed": state["quest_state"].get("completed", []).duplicate(true),
		"active": state["quest_state"].get("active", []).duplicate(true),
		"deferred": state["quest_state"].get("deferred", []).duplicate(true),
		"failed": state["quest_state"].get("failed", []).duplicate(true),
		"branch_changes": state["quest_state"].get("branch_history", []).size(),
	}


func _next_week_commitment_count(state: Dictionary) -> int:
	var current: int = _date_value(_date_string(state["clock"]))
	var count: int = 0
	for event_value: Variant in state["calendar_state"].get("events", []):
		if event_value is Dictionary:
			var event_day: int = _date_value(str(event_value.get("date", "")))
			if event_day > current and event_day <= current + 7 and str(event_value.get("status", "scheduled")) == "scheduled":
				count += 1
	return count


func _ensure_runtime_shape(state: Dictionary) -> void:
	if not state.get("weekly_review_state") is Dictionary:
		state["weekly_review_state"] = {"pending": null, "history": [], "selected_priorities": [], "last_completed_week": 0}
	var review_state: Dictionary = state["weekly_review_state"]
	if not review_state.get("history") is Array:
		review_state["history"] = []
	if not review_state.get("selected_priorities") is Array:
		review_state["selected_priorities"] = []
	if not review_state.has("pending"):
		review_state["pending"] = null
	if not review_state.has("last_completed_week"):
		review_state["last_completed_week"] = 0


func _review_state_snapshot(state: Dictionary) -> Dictionary:
	var value: Variant = state.get("weekly_review_state")
	return value if value is Dictionary else {"pending": null, "history": [], "selected_priorities": [], "last_completed_week": 0}


func _package() -> Dictionary:
	var value: Variant = _registry.get_package(PACKAGE_ID)
	return value if value is Dictionary else {}


func _definition_by_id(entries: Array, definition_id: String) -> Dictionary:
	for entry_value: Variant in entries:
		if entry_value is Dictionary and str(entry_value.get("id", "")) == definition_id:
			return entry_value.duplicate(true)
	return {}


func _review_id(clock: Dictionary) -> String:
	return "weekly-review-Y%d-W%03d" % [int(clock.get("year", 1)), int(clock.get("week_number", 1))]


func _character_name(character_id: String) -> String:
	var character: Variant = _registry.get_character(character_id)
	return str(character.get("display_name", character_id)) if character is Dictionary else character_id


func _date_in_range(date: String, start_date: String, end_date: String) -> bool:
	var value: int = _date_value(date)
	return value >= _date_value(start_date) and value <= _date_value(end_date)


func _date_value(date: String) -> int:
	var parts: PackedStringArray = date.trim_prefix("Y").split("-")
	if parts.size() != 3:
		return -1
	return int(parts[0]) * 372 + int(parts[1]) * 31 + int(parts[2])


func _date_string(clock: Dictionary) -> String:
	return "Y%d-%02d-%02d" % [clock.get("year", 1), clock.get("month", 1), clock.get("day", 1)]


func _timestamp(clock: Dictionary) -> String:
	return "%s:%s+%03d" % [_date_string(clock), clock.get("block", "morning"), clock.get("minute_within_block", 0)]


func _success(state: Dictionary, data: Dictionary = {}) -> Dictionary:
	return {"ok": true, "state": state, "data": data, "errors": PackedStringArray()}


func _failure(message: String) -> Dictionary:
	return {"ok": false, "errors": PackedStringArray([message])}
