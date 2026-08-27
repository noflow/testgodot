extends RefCounted
class_name PortAlderRelationshipEngine

const PACKAGE_ID: String = "port_alder_relationship_system"
const BLOCKS: PackedStringArray = [
	"early_morning", "morning", "lunch", "afternoon", "evening", "late_evening", "night",
]
const WEEKDAYS: PackedStringArray = [
	"monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday",
]
const PRIMARY_METERS: PackedStringArray = ["friendship", "love", "attraction", "lust"]

var _registry: Node
var _simulation: RefCounted


func _init(content_registry: Node, simulation_engine: RefCounted) -> void:
	_registry = content_registry
	_simulation = simulation_engine


func synchronize(state: Dictionary) -> Dictionary:
	var working: Dictionary = state.duplicate(true)
	_ensure_runtime_shape(working)
	var notices: PackedStringArray = []
	var events: Array = []
	var now_value: int = _clock_moment_value(working["clock"])
	for event_value: Variant in working["calendar_state"].get("events", []):
		if not event_value is Dictionary:
			continue
		var calendar_event: Dictionary = event_value
		if not bool(calendar_event.get("relationship_date", false)) or str(calendar_event.get("status", "scheduled")) != "scheduled":
			continue
		if _event_moment_value(calendar_event) >= now_value:
			continue
		var missed: Dictionary = _resolve_missed_date(working, calendar_event, events)
		if not missed.get("ok", false):
			return missed
		working = missed["state"]
		notices.append("%s noticed that you missed %s." % [
			_character_name(str(calendar_event.get("relationship_character_id", ""))),
			calendar_event.get("title", "your date"),
		])
	return _success(working, events, {"notices": notices})


func candidates(state: Dictionary) -> Array:
	var results: Array = []
	for character_id_value: Variant in state.get("player", {}).get("phone", {}).get("known_contacts", []):
		var character_id: String = str(character_id_value)
		var character: Variant = _registry.get_character(character_id)
		if not character is Dictionary:
			continue
		var profile: Dictionary = relationship_profile(state, character_id)
		profile["romance_compatible"] = _romance_compatible(character)
		results.append(profile)
	return results


func relationship_profile(state: Dictionary, character_id: String) -> Dictionary:
	var character: Variant = _registry.get_character(character_id)
	if not character is Dictionary:
		return {}
	var relationship: Dictionary = _relationship_snapshot(state, character_id)
	var completed_dates: int = _completed_date_count(relationship)
	var agreement: Dictionary = relationship.get("dating_agreement", {"status": "none", "type": "none"})
	var chapter_level: int = int(relationship.get("unlocked_chapter_level", 1))
	var chapter: Dictionary = _chapter_definition(character, chapter_level)
	var pending_date: Dictionary = _scheduled_date_for_character(state, character_id)
	return {
		"character_id": character_id,
		"display_name": character.get("display_name", character_id),
		"profile": character.get("profile", {}).duplicate(true),
		"meters": relationship,
		"relationship_stage": relationship.get("relationship_stage", "acquaintance"),
		"relationship_level": int(relationship.get("relationship_level", 1)),
		"chapter_level": chapter_level,
		"chapter": chapter,
		"agreement": agreement,
		"completed_dates": completed_dates,
		"pending_date": pending_date,
		"pending_agreement_proposal": relationship.get("pending_agreement_proposal"),
		"romance_compatible": _romance_compatible(character),
		"agreement_options": _agreement_options(character),
	}


func invitation_options(state: Dictionary, character_id: String, activity_id: String, maximum: int = 3) -> Array:
	var character: Variant = _registry.get_character(character_id)
	var activity: Variant = _registry.get_content("date_activities", activity_id)
	if not character is Dictionary or not activity is Dictionary:
		return []
	if not _basic_invitation_error(state, character_id).is_empty():
		return []
	var configured_maximum: int = int(_package().get("invitation_defaults", {}).get("maximum_options_per_activity", 3))
	maximum = clampi(maximum, 1, configured_maximum)
	var options: Array = []
	for offset: int in 14:
		var date_parts: Dictionary = _date_after_days(state["clock"], offset)
		for block_value: Variant in activity.get("allowed_blocks", []):
			var block: String = str(block_value)
			if offset == 0 and BLOCKS.find(block) <= BLOCKS.find(str(state["clock"]["block"])):
				continue
			if _npc_busy(character, _date_string_from_parts(date_parts), str(date_parts["weekday"]), block):
				continue
			if not _location_open(activity, str(date_parts["weekday"]), block):
				continue
			var option: Dictionary = {
				"date": _date_string_from_parts(date_parts),
				"weekday": date_parts["weekday"],
				"block": block,
				"activity_id": activity_id,
				"activity_name": activity.get("name", activity_id),
				"location": activity.get("location", ""),
				"preferred": _preferred_social_time(character, str(date_parts["weekday"]), block),
			}
			if _calendar_slot_available(state, character_id, option):
				options.append(option)
	options.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		if bool(left.get("preferred", false)) != bool(right.get("preferred", false)):
			return bool(left.get("preferred", false))
		return _option_moment_value(left) < _option_moment_value(right)
	)
	if options.size() > maximum:
		options.resize(maximum)
	return options


func ask_out(
	state: Dictionary,
	character_id: String,
	activity_id: String,
	date: String,
	weekday: String,
	block: String,
	disclose_to_partners: bool = true
) -> Dictionary:
	var invitation_error: String = _basic_invitation_error(state, character_id)
	if not invitation_error.is_empty():
		return _failure(invitation_error)
	var character: Dictionary = _registry.get_character(character_id)
	var activity: Variant = _registry.get_content("date_activities", activity_id)
	if not activity is Dictionary:
		return _failure("Unknown date activity: %s" % activity_id)
	if block not in activity.get("allowed_blocks", []):
		return _failure("%s is unavailable during %s." % [activity.get("name", "That date"), block.replace("_", " ")])
	if not _valid_date_string(date) or weekday not in WEEKDAYS:
		return _failure("Choose a valid calendar date.")
	var date_parts: PackedStringArray = date.trim_prefix("Y").split("-")
	var target_day: int = _date_serial_days(int(date_parts[0]), int(date_parts[1]), int(date_parts[2]))
	var current_day: int = _date_serial_days(int(state["clock"]["year"]), int(state["clock"]["month"]), int(state["clock"]["day"]))
	var day_offset: int = target_day - current_day
	if day_offset < 0 or day_offset >= 14:
		return _failure("Date invitations can be planned up to fourteen days ahead.")
	var expected_weekday: String = WEEKDAYS[posmod(WEEKDAYS.find(str(state["clock"]["weekday"])) + day_offset, WEEKDAYS.size())]
	if weekday != expected_weekday:
		return _failure("The selected date and weekday do not match.")
	if _date_moment_value(date, block) <= _clock_moment_value(state["clock"]):
		return _failure("Choose a future date and activity block.")
	if _npc_busy(character, date, weekday, block):
		return _failure("%s is working, studying, or otherwise unavailable then." % character.get("display_name", character_id))
	if not _location_open(activity, weekday, block):
		return _failure("The date location is closed at that time.")
	var option: Dictionary = {"date": date, "weekday": weekday, "block": block}
	if not _calendar_slot_available(state, character_id, option):
		return _failure("That time conflicts with an existing calendar commitment.")

	var working: Dictionary = state.duplicate(true)
	_ensure_runtime_shape(working)
	var events: Array = []
	var result: Dictionary = _apply(working, "time.advance", {"minutes": 5}, "relationship.invitation", events)
	if not result.get("ok", false):
		return result
	working = result["state"]
	var invitation_id: String = "dating-invite-%s-%08d" % [character_id, int(working["simulation"].get("next_event_sequence", 1))]
	result = _apply(working, "phone.append_message", {
		"character_id": character_id,
		"message": {
			"id": invitation_id,
			"sender": "player",
			"text": "Would you like to go on a %s with me on %s %s?" % [
				str(activity.get("name", activity_id)).to_lower(), weekday.capitalize(), block.replace("_", " "),
			],
			"tone": ["romantic", "direct"],
		},
	}, "relationship.invitation", events)
	if not result.get("ok", false):
		return result
	working = result["state"]

	var score: float = _invitation_score(working, character, activity, block)
	var threshold: float = float(_dating_preferences(character).get(
		"invitation_threshold",
		_package().get("invitation_defaults", {}).get("minimum_score", 31)
	))
	var accepted: bool = score >= threshold
	var relationship: Dictionary = working["relationships"][character_id]
	var invitation_record: Dictionary = {
		"id": invitation_id,
		"activity_id": activity_id,
		"date": date,
		"weekday": weekday,
		"block": block,
		"score": snappedf(score, 0.1),
		"threshold": threshold,
		"accepted": accepted,
		"asked_on": _date_string(working["clock"]),
	}
	relationship["invitation_history"].append(invitation_record)
	if not accepted:
		result = _apply(working, "phone.append_message", {
			"character_id": character_id,
			"message": {
				"id": "%s-response" % invitation_id,
				"sender": character_id,
				"text": "Thank you for asking, but I am not ready to call this a date.",
				"reply_to": invitation_id,
			},
		}, "relationship.invitation_response", events)
		if not result.get("ok", false):
			return result
		working = result["state"]
		return _success(working, events, {
			"accepted": false,
			"score": score,
			"threshold": threshold,
			"response": "%s is not ready to accept a date invitation." % character.get("display_name", character_id),
		})

	var disclosed_to: Array = _active_partner_ids(working, character_id) if disclose_to_partners else []
	var date_event_id: String = "date-%s-%08d" % [character_id, int(working["simulation"].get("next_event_sequence", 1))]
	var calendar_event: Dictionary = {
		"id": date_event_id,
		"title": "%s with %s" % [activity.get("name", "Date"), character.get("display_name", character_id)],
		"type": "date",
		"relationship_date": true,
		"relationship_character_id": character_id,
		"activity_id": activity_id,
		"date": date,
		"weekday": weekday,
		"block": block,
		"participants": [character_id],
		"location": activity.get("location", ""),
		"source": "relationship.invitation",
		"disclosed_to": disclosed_to,
		"required": false,
	}
	result = _apply(working, "calendar.schedule", {"calendar_event": calendar_event}, "relationship.invitation", events)
	if not result.get("ok", false):
		return result
	working = result["state"]
	result = _apply(working, "phone.append_message", {
		"character_id": character_id,
		"message": {
			"id": "%s-response" % invitation_id,
			"sender": character_id,
			"text": "Yes. I added it to my calendar.",
			"reply_to": invitation_id,
		},
	}, "relationship.invitation_response", events)
	if not result.get("ok", false):
		return result
	working = result["state"]
	relationship = working["relationships"][character_id]
	relationship["romantic_interest_known"] = true
	return _success(working, events, {
		"accepted": true,
		"score": score,
		"threshold": threshold,
		"event_id": date_event_id,
		"calendar_event": _event_by_id(working, date_event_id),
		"warnings": _agreement_warnings(working, character_id, disclose_to_partners),
		"response": "%s accepted. The date is on your calendar." % character.get("display_name", character_id),
	})


func date_status(state: Dictionary, character_id: String) -> Dictionary:
	var event: Dictionary = _scheduled_date_for_character(state, character_id)
	if event.is_empty():
		return {"scheduled": false, "ready": false, "reason": "No date is scheduled."}
	var now: int = _clock_moment_value(state["clock"])
	var scheduled: int = _event_moment_value(event)
	var location_matches: bool = str(state["world_state"].get("current_location", "")) == str(event.get("location", ""))
	if scheduled > now:
		return {
			"scheduled": true, "ready": false, "event": event,
			"reason": "Scheduled for %s • %s at %s." % [
				event.get("date", ""), str(event.get("block", "")).replace("_", " ").capitalize(), _location_name(str(event.get("location", ""))),
			],
		}
	if scheduled < now:
		return {"scheduled": true, "ready": false, "event": event, "reason": "This date is overdue and will resolve as a missed plan."}
	if not location_matches:
		return {
			"scheduled": true, "ready": false, "event": event,
			"reason": "The date is now. Meet at %s." % _location_name(str(event.get("location", ""))),
		}
	return {"scheduled": true, "ready": true, "event": event, "reason": "Both of you are here. Choose how to approach the date."}


func complete_date(
	state: Dictionary,
	event_id: String,
	approach_id: String,
	options: Dictionary = {}
) -> Dictionary:
	var event: Dictionary = _event_by_id(state, event_id)
	if event.is_empty() or not bool(event.get("relationship_date", false)):
		return _failure("Unknown scheduled date: %s" % event_id)
	if str(event.get("status", "")) != "scheduled":
		return _failure("This date is no longer scheduled.")
	if _event_moment_value(event) != _clock_moment_value(state["clock"]):
		return _failure("The date can only begin during its scheduled activity block.")
	if str(state["world_state"].get("current_location", "")) != str(event.get("location", "")):
		return _failure("Meet at %s before starting the date." % _location_name(str(event.get("location", ""))))
	var character_id: String = str(event.get("relationship_character_id", ""))
	var character: Variant = _registry.get_character(character_id)
	var activity: Variant = _registry.get_content("date_activities", str(event.get("activity_id", "")))
	var approach: Dictionary = _definition_by_id(_package().get("date_approaches", []), approach_id)
	if not character is Dictionary or not activity is Dictionary or approach.is_empty():
		return _failure("The date content is unavailable.")
	var current_relationship: Dictionary = _relationship_snapshot(state, character_id)
	if float(current_relationship.get("comfort", 0.0)) < float(approach.get("minimum_comfort", 0.0)):
		return _failure("%s is not comfortable enough for that approach yet." % character.get("display_name", character_id))

	var working: Dictionary = state.duplicate(true)
	_ensure_runtime_shape(working)
	var events: Array = []
	var cost: float = float(activity.get("cost", 0.0))
	if cost > 0.0:
		var account_id: String = _payment_account(working, cost)
		if account_id.is_empty():
			return _failure("You need $%.2f available before this date can begin." % cost)
		var payment: Dictionary = _apply(working, "economy.transaction", {
			"account": account_id,
			"amount": -cost,
			"type": "debit",
			"category": "dating",
			"description": "%s with %s" % [activity.get("name", "Date"), character.get("display_name", character_id)],
		}, "relationship.date:%s" % event_id, events)
		if not payment.get("ok", false):
			return payment
		working = payment["state"]
	var result: Dictionary = _apply(working, "calendar.arrival", {"event_id": event_id}, "relationship.date:%s" % event_id, events)
	if not result.get("ok", false):
		return result
	working = result["state"]
	result = _apply(working, "time.advance", {"minutes": int(activity.get("duration_minutes", 60))}, "relationship.date:%s" % event_id, events)
	if not result.get("ok", false):
		return result
	working = result["state"]
	for need_id: Variant in activity.get("need_effects", {}):
		result = _apply(working, "need.adjust", {
			"need": str(need_id), "amount": activity["need_effects"][need_id],
		}, "relationship.date:%s" % event_id, events)
		if not result.get("ok", false):
			return result
		working = result["state"]
	var meter_effects: Dictionary = approach.get("meter_effects", {}).duplicate(true)
	if str(activity.get("id", "")) in _dating_preferences(character).get("preferred_activities", []):
		meter_effects["compatibility"] = float(meter_effects.get("compatibility", 0.0)) + 2.0
		meter_effects["satisfaction"] = float(meter_effects.get("satisfaction", 0.0)) + 2.0
	if _preferred_social_time(character, str(event.get("weekday", "")), str(event.get("block", ""))):
		meter_effects["comfort"] = float(meter_effects.get("comfort", 0.0)) + 1.0
	for meter: Variant in meter_effects:
		result = _apply(working, "relationship.adjust_meter", {
			"character_id": character_id,
			"meter": str(meter),
			"amount": meter_effects[meter],
			"reason": "completed_date",
		}, "relationship.date:%s" % event_id, events)
		if not result.get("ok", false):
			return result
		working = result["state"]

	var witness_result: Dictionary = _resolve_witnesses(working, character_id, activity, event, options, events)
	if not witness_result.get("ok", false):
		return witness_result
	working = witness_result["state"]
	var reactions: Array = witness_result.get("reactions", [])
	var date_record: Dictionary = {
		"id": event_id,
		"calendar_event_id": event_id,
		"activity_id": activity.get("id", ""),
		"approach_id": approach_id,
		"date": event.get("date", ""),
		"block": event.get("block", ""),
		"location": event.get("location", ""),
		"cost": cost,
		"outcome": "completed",
		"witness_reactions": reactions,
	}
	result = _apply(working, "relationship.record_date", {
		"character_id": character_id, "date_record": date_record,
	}, "relationship.date:%s" % event_id, events)
	if not result.get("ok", false):
		return result
	working = result["state"]
	result = _apply(working, "memory.create", {
		"character_id": character_id,
		"memory_id": "completed_%s" % event_id,
		"importance": 55,
		"tags": ["date", str(activity.get("id", "")), approach_id],
	}, "relationship.date:%s" % event_id, events)
	if not result.get("ok", false):
		return result
	working = result["state"]
	var chapter_updates: Array = _update_chapter_progress(working, character_id)
	var proposal: Variant = _maybe_create_npc_proposal(working, character_id)
	return _success(working, events, {
		"date_record": date_record,
		"witness_reactions": reactions,
		"chapter_updates": chapter_updates,
		"npc_proposal": proposal,
		"summary": "%s went well. %s" % [
			activity.get("name", "The date"),
			"%d relationship conflict(s) followed." % reactions.size() if not reactions.is_empty() else "You grew closer.",
		],
	})


func cancel_date(state: Dictionary, event_id: String) -> Dictionary:
	var event: Dictionary = _event_by_id(state, event_id)
	if event.is_empty() or not bool(event.get("relationship_date", false)):
		return _failure("Unknown scheduled date.")
	if str(event.get("status", "")) != "scheduled":
		return _failure("That date cannot be cancelled now.")
	var character_id: String = str(event.get("relationship_character_id", ""))
	var working: Dictionary = state.duplicate(true)
	_ensure_runtime_shape(working)
	var events: Array = []
	var notice_blocks: int = _event_moment_value(event) - _clock_moment_value(working["clock"])
	var result: Dictionary = _apply(working, "calendar.cancel_or_reschedule", {
		"event_id": event_id, "cancel": true, "notice_blocks": notice_blocks,
	}, "relationship.cancel_date", events)
	if not result.get("ok", false):
		return result
	working = result["state"]
	var late: bool = notice_blocks <= 1
	for effect: Dictionary in (
		[{"meter": "trust", "amount": -5}, {"meter": "resentment", "amount": 3}]
		if late else [{"meter": "trust", "amount": -1}]
	):
		result = _apply(working, "relationship.adjust_meter", {
			"character_id": character_id, "meter": effect["meter"], "amount": effect["amount"], "reason": "cancelled_date",
		}, "relationship.cancel_date", events)
		if not result.get("ok", false):
			return result
		working = result["state"]
	result = _apply(working, "relationship.record_date", {
		"character_id": character_id,
		"date_record": {
			"id": event_id, "calendar_event_id": event_id, "activity_id": event.get("activity_id", ""),
			"date": event.get("date", ""), "block": event.get("block", ""), "outcome": "cancelled",
			"late_notice": late,
		},
	}, "relationship.cancel_date", events)
	if not result.get("ok", false):
		return result
	return _success(result["state"], events, {
		"late_notice": late,
		"message": "The late cancellation damaged trust." if late else "The date was cancelled with reasonable notice.",
	})


func can_propose_agreement(state: Dictionary, character_id: String) -> Dictionary:
	var character: Variant = _registry.get_character(character_id)
	if not character is Dictionary or not _romance_compatible(character):
		return {"ok": false, "reason": "A dating agreement is unavailable."}
	var relationship: Dictionary = _relationship_snapshot(state, character_id)
	if str(relationship.get("relationship_stage", "")) == "ended":
		return {"ok": false, "reason": "This relationship has ended."}
	if str(relationship.get("dating_agreement", {}).get("status", "none")) == "active":
		return {"ok": false, "reason": "You already have an active agreement."}
	if _completed_date_count(relationship) < 2:
		return {"ok": false, "reason": "Spend more time dating before defining the relationship."}
	if float(relationship.get("trust", 0.0)) < 25.0:
		return {"ok": false, "reason": "More trust is needed before this conversation."}
	return {"ok": true, "reason": "You can discuss what this relationship means.", "options": _agreement_options(character)}


func propose_agreement(state: Dictionary, character_id: String, agreement_type: String) -> Dictionary:
	var readiness: Dictionary = can_propose_agreement(state, character_id)
	if not bool(readiness.get("ok", false)):
		return _failure(str(readiness.get("reason", "The agreement conversation is unavailable.")))
	if agreement_type not in ["casual", "exclusive", "open"]:
		return _failure("Unknown agreement type.")
	var character: Dictionary = _registry.get_character(character_id)
	var relationship: Dictionary = _relationship_snapshot(state, character_id)
	var supported: Array = _agreement_options(character)
	var score: float = (
		float(relationship.get("trust", 0.0)) * 0.25
		+ float(relationship.get("love", 0.0)) * 0.20
		+ float(relationship.get("commitment", 0.0)) * 0.15
		+ float(relationship.get("friendship", 0.0)) * 0.20
		+ float(relationship.get("compatibility", 0.0)) * 0.10
		+ float(relationship.get("satisfaction", 0.0)) * 0.10
	)
	var preference_bonus: float = 15.0 if agreement_type in supported else -25.0
	var threshold: float = 36.0 if agreement_type == "exclusive" else 32.0
	var accepted: bool = score + preference_bonus >= threshold
	var working: Dictionary = state.duplicate(true)
	_ensure_runtime_shape(working)
	var events: Array = []
	var history: Dictionary = {
		"type": agreement_type, "proposed_by": "player", "date": _date_string(working["clock"]),
		"accepted": accepted, "score": snappedf(score + preference_bonus, 0.1),
	}
	working["relationships"][character_id]["agreement_history"].append(history)
	if not accepted:
		return _success(working, events, {
			"accepted": false,
			"message": "%s is not comfortable with that agreement." % character.get("display_name", character_id),
		})
	var result: Dictionary = _establish_agreement(working, character_id, agreement_type, "player", events)
	if not result.get("ok", false):
		return result
	var chapter_updates: Array = _update_chapter_progress(result["state"], character_id)
	return _success(result["state"], events, {
		"accepted": true,
		"agreement": result["state"]["relationships"][character_id]["dating_agreement"],
		"chapter_updates": chapter_updates,
		"message": "%s agreed to %s." % [character.get("display_name", character_id), _agreement_name(agreement_type)],
	})


func respond_to_npc_proposal(state: Dictionary, character_id: String, accept: bool) -> Dictionary:
	var relationship: Dictionary = _relationship_snapshot(state, character_id)
	var proposal: Variant = relationship.get("pending_agreement_proposal")
	if not proposal is Dictionary:
		return _failure("There is no relationship proposal waiting for an answer.")
	var working: Dictionary = state.duplicate(true)
	_ensure_runtime_shape(working)
	var events: Array = []
	var agreement_type: String = str(proposal.get("type", "casual"))
	working["relationships"][character_id]["pending_agreement_proposal"] = null
	working["relationships"][character_id]["agreement_history"].append({
		"type": agreement_type, "proposed_by": "npc", "date": _date_string(working["clock"]), "accepted": accept,
	})
	if not accept:
		var decline: Dictionary = _apply(working, "relationship.adjust_meter", {
			"character_id": character_id, "meter": "commitment", "amount": -2, "reason": "agreement_declined",
		}, "relationship.agreement_response", events)
		if not decline.get("ok", false):
			return decline
		return _success(decline["state"], events, {"accepted": false, "message": "You declined the proposal honestly."})
	var result: Dictionary = _establish_agreement(working, character_id, agreement_type, "npc", events)
	if not result.get("ok", false):
		return result
	var chapter_updates: Array = _update_chapter_progress(result["state"], character_id)
	return _success(result["state"], events, {
		"accepted": true,
		"agreement": result["state"]["relationships"][character_id]["dating_agreement"],
		"chapter_updates": chapter_updates,
		"message": "You agreed to %s." % _agreement_name(agreement_type),
	})


func is_date_event(state: Dictionary, event_id: String) -> bool:
	var event: Dictionary = _event_by_id(state, event_id)
	return not event.is_empty() and bool(event.get("relationship_date", false))


func active_partner_ids(state: Dictionary, excluding_character: String = "") -> Array:
	return _active_partner_ids(state, excluding_character)


func _resolve_missed_date(state: Dictionary, calendar_event: Dictionary, events: Array) -> Dictionary:
	var working: Dictionary = state.duplicate(true)
	var character_id: String = str(calendar_event.get("relationship_character_id", ""))
	for event_value: Variant in working["calendar_state"]["events"]:
		if event_value is Dictionary and str(event_value.get("id", "")) == str(calendar_event.get("id", "")):
			event_value["status"] = "missed"
			event_value["missed_at"] = _date_string(working["clock"])
			break
	var result: Dictionary
	for effect: Dictionary in [
		{"meter": "trust", "amount": -7}, {"meter": "resentment", "amount": 5}, {"meter": "satisfaction", "amount": -6},
	]:
		result = _apply(working, "relationship.adjust_meter", {
			"character_id": character_id, "meter": effect["meter"], "amount": effect["amount"], "reason": "date_no_show",
		}, "relationship.missed_date", events)
		if not result.get("ok", false):
			return result
		working = result["state"]
	result = _apply(working, "attribute.adjust", {
		"attribute": "reliability", "amount": -2,
	}, "relationship.missed_date", events)
	if not result.get("ok", false):
		return result
	working = result["state"]
	result = _apply(working, "relationship.record_date", {
		"character_id": character_id,
		"date_record": {
			"id": calendar_event.get("id", ""), "calendar_event_id": calendar_event.get("id", ""),
			"activity_id": calendar_event.get("activity_id", ""), "date": calendar_event.get("date", ""),
			"block": calendar_event.get("block", ""), "outcome": "no_show",
		},
	}, "relationship.missed_date", events)
	return result


func _resolve_witnesses(
	state: Dictionary,
	date_character_id: String,
	activity: Dictionary,
	date_event: Dictionary,
	options: Dictionary,
	events: Array
) -> Dictionary:
	var working: Dictionary = state
	var reactions: Array = []
	var forced: Array = options.get("force_witnesses", [])
	for witness_id_value: Variant in _active_partner_ids(working, date_character_id):
		var witness_id: String = str(witness_id_value)
		var witnessed: bool = witness_id in forced
		if forced.is_empty():
			var roll: int = posmod(("%s:%s:%s:%s" % [
				date_event.get("id", ""), witness_id, activity.get("id", ""), working["world_state"].get("random_seed", 0),
			]).hash(), 100)
			witnessed = roll < int(activity.get("witness_chance", 0))
		if not witnessed:
			continue
		var reaction_result: Dictionary = _apply_witness_reaction(working, witness_id, date_character_id, date_event, events)
		if not reaction_result.get("ok", false):
			return reaction_result
		working = reaction_result["state"]
		reactions.append(reaction_result["reaction"])
	return {"ok": true, "state": working, "reactions": reactions, "events": events, "errors": PackedStringArray()}


func _apply_witness_reaction(
	state: Dictionary,
	witness_id: String,
	date_character_id: String,
	date_event: Dictionary,
	events: Array
) -> Dictionary:
	var witness: Dictionary = _registry.get_character(witness_id)
	var relationship: Dictionary = state["relationships"][witness_id]
	var agreement: Dictionary = relationship.get("dating_agreement", {})
	var agreement_type: String = str(agreement.get("type", "none")) if str(agreement.get("status", "none")) == "active" else "none"
	var disclosed: bool = witness_id in date_event.get("disclosed_to", [])
	var jealousy_trait: int = int(witness.get("personality", {}).get("jealousy", 35))
	var preferences: Dictionary = _dating_preferences(witness)
	var openness: String = str(preferences.get("openness_reaction", "uneasy"))
	var rules: Dictionary = _package().get("conflict_rules", {})
	var severe: int = int(rules.get("severe_jealousy", 65))
	var moderate: int = int(rules.get("moderate_jealousy", 40))
	var outcome: String = "not_bothered"
	var relationship_ended: bool = false
	var deltas: Dictionary = {}
	var line_key: String = "undefined_jealousy"
	if agreement_type == "exclusive":
		line_key = "exclusive_violation"
		if jealousy_trait >= severe:
			outcome = "relationship_ended"
			relationship_ended = true
			deltas = {"trust": -28, "love": -18, "resentment": 24, "jealousy": 30, "satisfaction": -25}
		else:
			outcome = "exclusive_confrontation"
			deltas = {"trust": -18, "love": -8, "resentment": 15, "jealousy": 22, "satisfaction": -15}
	elif agreement_type == "open" and disclosed:
		line_key = "open_disclosed"
		if openness == "likes_it":
			outcome = "liked_it"
			deltas = {"trust": 3, "satisfaction": 4, "attraction": 2}
		elif openness in ["supportive", "amused"]:
			outcome = "did_not_mind"
			deltas = {"trust": 2, "satisfaction": 1}
		else:
			outcome = "accepted_but_jealous"
			deltas = {"trust": 1, "jealousy": 5, "satisfaction": -1}
	elif agreement_type == "open" and not disclosed:
		outcome = "nondisclosure_conflict"
		var trust_penalty: int = int(rules.get("private_open_date_trust_penalty", 9))
		deltas = {"trust": -trust_penalty, "resentment": 8, "jealousy": 12, "satisfaction": -8}
		if jealousy_trait >= 75:
			outcome = "relationship_ended"
			relationship_ended = true
	elif openness == "likes_it" and jealousy_trait < moderate:
		outcome = "liked_it"
		deltas = {"satisfaction": 3, "attraction": 2}
	elif jealousy_trait >= 75:
		outcome = "relationship_ended"
		relationship_ended = true
		deltas = {"trust": -20, "love": -12, "resentment": 20, "jealousy": 25, "satisfaction": -20}
	elif jealousy_trait >= moderate:
		outcome = "jealous_confrontation"
		deltas = {"trust": -7, "resentment": 7, "jealousy": 15, "satisfaction": -8}
	else:
		outcome = "did_not_mind"
		deltas = {"jealousy": 2, "satisfaction": 1}

	var working: Dictionary = state
	var result: Dictionary
	for meter: Variant in deltas:
		result = _apply(working, "relationship.adjust_meter", {
			"character_id": witness_id, "meter": str(meter), "amount": deltas[meter], "reason": "witnessed_other_date",
		}, "relationship.witnessed_conflict", events)
		if not result.get("ok", false):
			return result
		working = result["state"]
	var conflict_id: String = "conflict-%s-%s-%08d" % [
		witness_id, date_character_id, int(working["simulation"].get("next_event_sequence", 1)),
	]
	var reaction_line: String = str(preferences.get("reaction_lines", {}).get(line_key, _default_reaction_line(witness, outcome)))
	var conflict_record: Dictionary = {
		"id": conflict_id,
		"type": "witnessed_other_date",
		"witness": witness_id,
		"other_date_character": date_character_id,
		"date_event_id": date_event.get("id", ""),
		"agreement_type": agreement_type,
		"disclosed": disclosed,
		"outcome": outcome,
		"relationship_ended": relationship_ended,
		"reaction_line": reaction_line,
		"date": _date_string(working["clock"]),
	}
	result = _apply(working, "relationship.record_conflict", {
		"character_id": witness_id, "conflict_record": conflict_record,
	}, "relationship.witnessed_conflict", events)
	if not result.get("ok", false):
		return result
	return {
		"ok": true,
		"state": result["state"],
		"reaction": {
			"character_id": witness_id,
			"character_name": witness.get("display_name", witness_id),
			"outcome": outcome,
			"relationship_ended": relationship_ended,
			"line": reaction_line,
		},
		"errors": PackedStringArray(),
	}


func _establish_agreement(
	state: Dictionary,
	character_id: String,
	agreement_type: String,
	initiated_by: String,
	events: Array
) -> Dictionary:
	var working: Dictionary = state
	var definition: Dictionary = _definition_by_id(_package().get("agreement_types", []), agreement_type)
	var agreement: Dictionary = {
		"type": agreement_type,
		"name": definition.get("name", agreement_type.capitalize()),
		"status": "active",
		"initiated_by": initiated_by,
		"other_dates_allowed": definition.get("other_dates_allowed", false),
		"disclosure_required": definition.get("disclosure_required", true),
		"established_on": _date_string(working["clock"]),
	}
	var result: Dictionary = _apply(working, "relationship.set_agreement", {
		"character_id": character_id,
		"agreement": agreement,
		"mutual_acknowledgment": true,
	}, "relationship.agreement", events)
	if not result.get("ok", false):
		return result
	working = result["state"]
	for effect: Dictionary in [
		{"meter": "commitment", "amount": 8},
		{"meter": "trust", "amount": 3},
		{"meter": "love", "amount": 2},
	]:
		result = _apply(working, "relationship.adjust_meter", {
			"character_id": character_id, "meter": effect["meter"], "amount": effect["amount"], "reason": "dating_agreement",
		}, "relationship.agreement", events)
		if not result.get("ok", false):
			return result
		working = result["state"]
	return {"ok": true, "state": working, "events": events, "errors": PackedStringArray()}


func _update_chapter_progress(state: Dictionary, character_id: String) -> Array:
	var relationship: Dictionary = state["relationships"][character_id]
	var character: Dictionary = _registry.get_character(character_id)
	var completed_dates: int = _completed_date_count(relationship)
	var bond: float = maxf(float(relationship.get("friendship", 0.0)), float(relationship.get("love", 0.0)))
	var agreement_active: bool = str(relationship.get("dating_agreement", {}).get("status", "none")) == "active"
	var current_level: int = int(relationship.get("unlocked_chapter_level", 1))
	var updates: Array = []
	for requirement_value: Variant in _package().get("chapter_due_diligence", []):
		if not requirement_value is Dictionary:
			continue
		var requirement: Dictionary = requirement_value
		var level: int = int(requirement.get("level", 1))
		if level <= current_level:
			continue
		if completed_dates < int(requirement.get("completed_dates", 0)):
			continue
		if bond < float(requirement.get("bond", 0.0)) or float(relationship.get("trust", 0.0)) < float(requirement.get("trust", 0.0)):
			continue
		if bool(requirement.get("agreement_required", false)) and not agreement_active:
			continue
		var chapter: Dictionary = _chapter_definition(character, level)
		var notification: Dictionary = {
			"level": level,
			"chapter_id": chapter.get("id", ""),
			"title": chapter.get("title", "Relationship Chapter %d" % level),
			"unlocked_on": _date_string(state["clock"]),
		}
		relationship["unlocked_chapter_level"] = level
		relationship["relationship_level"] = level
		relationship["chapter_notifications"].append(notification)
		updates.append(notification)
		current_level = level
	return updates


func _maybe_create_npc_proposal(state: Dictionary, character_id: String) -> Variant:
	var relationship: Dictionary = state["relationships"][character_id]
	if relationship.get("pending_agreement_proposal") is Dictionary:
		return relationship["pending_agreement_proposal"]
	if str(relationship.get("dating_agreement", {}).get("status", "none")) == "active":
		return null
	if _completed_date_count(relationship) < 2 or float(relationship.get("trust", 0.0)) < 30.0:
		return null
	var character: Dictionary = _registry.get_character(character_id)
	var agreement_options: Array = _agreement_options(character)
	if agreement_options.is_empty():
		return null
	var agreement_type: String = str(_dating_preferences(character).get("npc_initiated_agreement", agreement_options[0]))
	var proposal: Dictionary = {
		"type": agreement_type,
		"proposed_by": character_id,
		"date": _date_string(state["clock"]),
		"message": "%s wants to discuss %s." % [character.get("display_name", character_id), _agreement_name(agreement_type)],
	}
	relationship["pending_agreement_proposal"] = proposal
	return proposal


func _invitation_score(state: Dictionary, character: Dictionary, activity: Dictionary, block: String) -> float:
	var relationship: Dictionary = _relationship_snapshot(state, str(character.get("id", "")))
	var attributes: Dictionary = state["player"].get("attributes", {})
	var score: float = (
		float(relationship.get("friendship", 0.0)) * 0.35
		+ float(relationship.get("attraction", 0.0)) * 0.40
		+ float(relationship.get("trust", 0.0)) * 0.15
		+ float(attributes.get("charisma", 0.0)) * 0.05
		+ float(attributes.get("confidence", 0.0)) * 0.05
		- float(relationship.get("resentment", 0.0)) * 0.50
	)
	var defaults: Dictionary = _package().get("invitation_defaults", {})
	if str(activity.get("id", "")) in _dating_preferences(character).get("preferred_activities", []):
		score += float(defaults.get("preferred_activity_bonus", 8))
	if _preferred_social_time(character, "", block):
		score += float(defaults.get("preferred_block_bonus", 4))
	var rejected_count: int = 0
	for record: Variant in relationship.get("invitation_history", []):
		if record is Dictionary and not bool(record.get("accepted", false)):
			rejected_count += 1
	score -= float(rejected_count) * float(defaults.get("repeat_rejection_penalty", 5))
	return score


func _basic_invitation_error(state: Dictionary, character_id: String) -> String:
	var character: Variant = _registry.get_character(character_id)
	if not character is Dictionary:
		return "Unknown relationship character."
	if character_id not in state["player"]["phone"].get("known_contacts", []):
		return "Meet this person and exchange contact information first."
	if not _romance_compatible(character):
		return "A romantic invitation is not available with this character."
	var relationship: Dictionary = _relationship_snapshot(state, character_id)
	if str(relationship.get("relationship_stage", "")) == "ended":
		return "This relationship has ended."
	if not _scheduled_date_for_character(state, character_id).is_empty():
		return "You already have a date scheduled together."
	return ""


func _romance_compatible(character: Dictionary) -> bool:
	var profile: Dictionary = character.get("profile", {})
	if int(profile.get("age", 0)) < 18 or not bool(profile.get("romance_eligible", false)):
		return false
	if bool(character.get("boundaries", {}).get("family_only", false)):
		return false
	var orientation: String = str(profile.get("orientation", ""))
	var gender: String = str(profile.get("gender_identity", ""))
	match orientation:
		"bisexual":
			return true
		"straight":
			return gender in ["female", "trans_female"]
		"gay":
			return gender in ["male", "trans_male"]
		"lesbian":
			return false
		"asexual":
			return true
	return false


func _agreement_options(character: Dictionary) -> Array:
	var explicit: Variant = _dating_preferences(character).get("agreement_options")
	if explicit is Array and not explicit.is_empty():
		return explicit.duplicate(true)
	var preference: String = str(character.get("boundaries", {}).get("dating_agreement_preference", "open_to_discussion"))
	if "exclusive" in preference and "open" not in preference:
		return ["casual", "exclusive"] if "once_serious" in preference or "after_discussion" in preference else ["exclusive"]
	if "casual" in preference:
		return ["casual", "open", "exclusive"]
	return ["casual", "open", "exclusive"]


func _agreement_warnings(state: Dictionary, character_id: String, disclosed: bool) -> PackedStringArray:
	var warnings: PackedStringArray = []
	for partner_id_value: Variant in _active_partner_ids(state, character_id):
		var partner_id: String = str(partner_id_value)
		var agreement: Dictionary = state["relationships"][partner_id].get("dating_agreement", {})
		var agreement_type: String = str(agreement.get("type", "none")) if str(agreement.get("status", "none")) == "active" else "undefined"
		if agreement_type == "exclusive":
			warnings.append("This date violates your exclusive agreement with %s." % _character_name(partner_id))
		elif agreement_type == "open" and not disclosed:
			warnings.append("%s expects disclosure about other dates." % _character_name(partner_id))
		elif agreement_type == "undefined":
			warnings.append("You and %s have not defined whether other dates are acceptable." % _character_name(partner_id))
	return warnings


func _active_partner_ids(state: Dictionary, excluding_character: String) -> Array:
	var ids: Array = []
	for character_id_value: Variant in state.get("relationships", {}):
		var character_id: String = str(character_id_value)
		if character_id == excluding_character:
			continue
		var relationship: Dictionary = state["relationships"][character_id]
		var stage: String = str(relationship.get("relationship_stage", ""))
		var agreement_active: bool = str(relationship.get("dating_agreement", {}).get("status", "none")) == "active"
		if stage in ["dating", "committed"] or agreement_active:
			ids.append(character_id)
	return ids


func _calendar_slot_available(state: Dictionary, character_id: String, option: Dictionary) -> bool:
	for event_value: Variant in state["calendar_state"].get("events", []):
		if not event_value is Dictionary or str(event_value.get("status", "scheduled")) != "scheduled":
			continue
		var event: Dictionary = event_value
		if str(event.get("date", "")) != str(option.get("date", "")) or str(event.get("block", "")) != str(option.get("block", "")):
			continue
		if str(event.get("type", "")) in ["class", "exam", "work", "interview"] or character_id in event.get("participants", []):
			return false
	return true


func _npc_busy(character: Dictionary, date: String, weekday: String, block: String) -> bool:
	for commitment: Variant in character.get("schedule", {}).get("fixed_commitments", []):
		if commitment is Dictionary and bool(commitment.get("unavailable", false)) and _schedule_day_matches(commitment.get("days", []), date, weekday) and block in commitment.get("blocks", []):
			return true
	return false


func _schedule_day_matches(days: Array, date: String, weekday: String) -> bool:
	if weekday in days or "all" in days:
		return true
	var parts: PackedStringArray = date.trim_prefix("Y").split("-")
	if parts.size() != 3:
		return false
	var serial: int = _date_serial_days(int(parts[0]), int(parts[1]), int(parts[2]))
	var opening_serial: int = _date_serial_days(1, 8, 20)
	var rotation_day: int = posmod(serial - opening_serial, 7) + 1
	if "rotation_day_%d" % rotation_day in days:
		return true
	if rotation_day == 5 and "first_day_off" in days:
		return true
	if rotation_day == 6 and "second_day_off" in days:
		return true
	return rotation_day == 7 and "third_day_off" in days


func _location_open(activity: Dictionary, weekday: String, block: String) -> bool:
	var location: Variant = _registry.get_location(str(activity.get("location", "")).get_slice(".", 0))
	if not location is Dictionary:
		return false
	var access: Dictionary = location.get("access", {})
	if access.has("open_days") and weekday not in access["open_days"]:
		return false
	if access.has("open_blocks") and block not in access["open_blocks"]:
		return false
	return true


func _preferred_social_time(character: Dictionary, weekday: String, block: String) -> bool:
	var preferences: Array = character.get("schedule", {}).get("preferred_social_blocks", [])
	return block in preferences or (not weekday.is_empty() and "%s_%s" % [weekday, block] in preferences)


func _payment_account(state: Dictionary, amount: float) -> String:
	var accounts: Dictionary = state["player"]["economy"].get("accounts", {})
	for account_id: String in ["wallet_cash", "checking"]:
		if float(accounts.get(account_id, 0.0)) >= amount:
			return account_id
	return ""


func _scheduled_date_for_character(state: Dictionary, character_id: String) -> Dictionary:
	var found: Dictionary = {}
	for event_value: Variant in state.get("calendar_state", {}).get("events", []):
		if not event_value is Dictionary:
			continue
		var event: Dictionary = event_value
		if not bool(event.get("relationship_date", false)) or str(event.get("relationship_character_id", "")) != character_id or str(event.get("status", "scheduled")) != "scheduled":
			continue
		if found.is_empty() or _event_moment_value(event) < _event_moment_value(found):
			found = event
	return found


func _event_by_id(state: Dictionary, event_id: String) -> Dictionary:
	for event_value: Variant in state.get("calendar_state", {}).get("events", []):
		if event_value is Dictionary and str(event_value.get("id", "")) == event_id:
			return event_value
	return {}


func _ensure_runtime_shape(state: Dictionary) -> void:
	for character_id: Variant in state.get("relationships", {}):
		var relationship: Dictionary = state["relationships"][character_id]
		var character: Variant = _registry.get_character(str(character_id))
		var stage: String = "acquaintance"
		if character is Dictionary:
			var role: String = str(character.get("profile", {}).get("role", ""))
			if role in ["mother", "father", "older_sister"]:
				stage = "family"
			elif int(relationship.get("friendship", 0)) >= 35:
				stage = "friend"
		relationship["relationship_stage"] = str(relationship.get("relationship_stage", stage))
		relationship["relationship_level"] = int(relationship.get("relationship_level", 1))
		relationship["unlocked_chapter_level"] = int(relationship.get("unlocked_chapter_level", 1))
		relationship["dating_agreement"] = relationship.get("dating_agreement", {"status": "none", "type": "none"})
		for collection: String in ["invitation_history", "dating_history", "agreement_history", "conflict_history", "chapter_notifications"]:
			if not relationship.get(collection) is Array:
				relationship[collection] = []
		if not relationship.has("pending_agreement_proposal"):
			relationship["pending_agreement_proposal"] = null
		relationship["romantic_interest_known"] = bool(relationship.get("romantic_interest_known", false))


func _relationship_snapshot(state: Dictionary, character_id: String) -> Dictionary:
	var relationship: Dictionary = state.get("relationships", {}).get(character_id, {}).duplicate(true)
	if relationship.is_empty():
		return relationship
	var character: Variant = _registry.get_character(character_id)
	var stage: String = "friend" if int(relationship.get("friendship", 0)) >= 35 else "acquaintance"
	if character is Dictionary and str(character.get("profile", {}).get("role", "")) in ["mother", "father", "older_sister"]:
		stage = "family"
	relationship["relationship_stage"] = relationship.get("relationship_stage", stage)
	relationship["dating_agreement"] = relationship.get("dating_agreement", {"status": "none", "type": "none"})
	for collection: String in ["invitation_history", "dating_history", "agreement_history", "conflict_history", "chapter_notifications"]:
		relationship[collection] = relationship.get(collection, [])
	relationship["pending_agreement_proposal"] = relationship.get("pending_agreement_proposal")
	relationship["unlocked_chapter_level"] = int(relationship.get("unlocked_chapter_level", 1))
	return relationship


func _completed_date_count(relationship: Dictionary) -> int:
	var count: int = 0
	for record: Variant in relationship.get("dating_history", []):
		if record is Dictionary and str(record.get("outcome", "")) == "completed":
			count += 1
	return count


func _dating_preferences(character: Dictionary) -> Dictionary:
	var preferences: Variant = character.get("dating_preferences")
	if preferences is Dictionary:
		return preferences
	var jealousy: int = int(character.get("personality", {}).get("jealousy", 35))
	return {
		"invitation_threshold": 31,
		"preferred_activities": [],
		"agreement_options": _derived_agreement_options(character),
		"npc_initiated_agreement": "exclusive" if "exclusive" in str(character.get("boundaries", {}).get("dating_agreement_preference", "")) else "casual",
		"conflict_style": "direct" if jealousy >= 50 else "calm",
		"openness_reaction": "uneasy" if jealousy >= 40 else "supportive",
		"reaction_lines": {},
	}


func _derived_agreement_options(character: Dictionary) -> Array:
	var preference: String = str(character.get("boundaries", {}).get("dating_agreement_preference", ""))
	if "exclusive" in preference and "open" not in preference:
		return ["casual", "exclusive"]
	return ["casual", "open", "exclusive"]


func _default_reaction_line(character: Dictionary, outcome: String) -> String:
	var name: String = str(character.get("display_name", "They"))
	match outcome:
		"relationship_ended":
			return "%s decides the broken expectations ended the relationship." % name
		"exclusive_confrontation":
			return "%s confronts you about violating the exclusive agreement." % name
		"nondisclosure_conflict":
			return "%s is less upset about the date than about being kept uninformed." % name
		"liked_it":
			return "%s is intrigued and appreciates the honesty." % name
		"did_not_mind":
			return "%s does not treat the other date as a threat." % name
		"accepted_but_jealous":
			return "%s accepts the agreement but admits the moment brought up jealousy." % name
		_:
			return "%s wants an honest conversation about what seeing the date meant." % name


func _chapter_definition(character: Dictionary, level: int) -> Dictionary:
	for chapter: Variant in character.get("relationship_chapters", []):
		if chapter is Dictionary and int(chapter.get("level", 0)) == level:
			return chapter
	return {}


func _agreement_name(agreement_type: String) -> String:
	var definition: Dictionary = _definition_by_id(_package().get("agreement_types", []), agreement_type)
	return str(definition.get("name", agreement_type.replace("_", " ").capitalize()))


func _definition_by_id(entries: Array, definition_id: String) -> Dictionary:
	for entry: Variant in entries:
		if entry is Dictionary and str(entry.get("id", "")) == definition_id:
			return entry
	return {}


func _package() -> Dictionary:
	var value: Variant = _registry.get_package(PACKAGE_ID)
	return value if value is Dictionary else {}


func _character_name(character_id: String) -> String:
	var character: Variant = _registry.get_character(character_id)
	return str(character.get("display_name", character_id)) if character is Dictionary else character_id


func _location_name(location_path: String) -> String:
	var location_id: String = location_path.get_slice(".", 0)
	var location: Variant = _registry.get_location(location_id)
	var name: String = str(location.get("name", location_id)) if location is Dictionary else location_id
	var room: String = location_path.get_slice(".", 1).replace("_", " ").capitalize()
	return "%s — %s" % [name, room] if not room.is_empty() else name


func _date_after_days(clock: Dictionary, offset: int) -> Dictionary:
	var year: int = int(clock["year"])
	var month: int = int(clock["month"])
	var day: int = int(clock["day"])
	for _step: int in offset:
		day += 1
		if day > _days_in_month(month, year):
			day = 1
			month += 1
			if month > 12:
				month = 1
				year += 1
	var weekday_index: int = posmod(WEEKDAYS.find(str(clock["weekday"])) + offset, WEEKDAYS.size())
	return {"year": year, "month": month, "day": day, "weekday": WEEKDAYS[weekday_index]}


func _date_string(clock: Dictionary) -> String:
	return "Y%d-%02d-%02d" % [clock["year"], clock["month"], clock["day"]]


func _date_string_from_parts(parts: Dictionary) -> String:
	return "Y%d-%02d-%02d" % [parts["year"], parts["month"], parts["day"]]


func _clock_moment_value(clock: Dictionary) -> int:
	return _date_moment_value(_date_string(clock), str(clock["block"]))


func _event_moment_value(event: Dictionary) -> int:
	return _date_moment_value(str(event.get("date", "")), str(event.get("block", "")))


func _option_moment_value(option: Dictionary) -> int:
	return _date_moment_value(str(option.get("date", "")), str(option.get("block", "")))


func _date_moment_value(date: String, block: String) -> int:
	var parts: PackedStringArray = date.trim_prefix("Y").split("-")
	if parts.size() != 3:
		return -1
	var days: int = _date_serial_days(int(parts[0]), int(parts[1]), int(parts[2]))
	return days * BLOCKS.size() + maxi(BLOCKS.find(block), 0)


func _valid_date_string(date: String) -> bool:
	var parts: PackedStringArray = date.trim_prefix("Y").split("-")
	if parts.size() != 3 or not parts[0].is_valid_int() or not parts[1].is_valid_int() or not parts[2].is_valid_int():
		return false
	var year: int = int(parts[0])
	var month: int = int(parts[1])
	var day: int = int(parts[2])
	return year >= 1 and month >= 1 and month <= 12 and day >= 1 and day <= _days_in_month(month, year)


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


func _apply(
	state: Dictionary,
	operation: String,
	payload: Dictionary,
	source: String,
	events: Array
) -> Dictionary:
	var result: Dictionary = _simulation.apply_operation(state, operation, payload, source)
	if result.get("ok", false):
		events.append(result["event"])
	return result


func _success(state: Dictionary, events: Array = [], data: Dictionary = {}) -> Dictionary:
	return {"ok": true, "state": state, "events": events, "data": data, "errors": PackedStringArray()}


func _failure(message: String) -> Dictionary:
	return {"ok": false, "errors": PackedStringArray([message])}
