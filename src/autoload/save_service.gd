extends Node

signal save_completed(slot_id: String, summary: Dictionary)
signal save_failed(slot_id: String, errors: PackedStringArray)
signal load_completed(slot_id: String, recovered_from_backup: bool)
signal load_failed(slot_id: String, errors: PackedStringArray)

const SaveEngineScript: GDScript = preload("res://src/save/save_engine.gd")
const SAVE_ROOT: String = "user://saves"
const MANUAL_SLOT_COUNT: int = 8
const AUTOSAVE_SLOT_COUNT: int = 3
const QUICKSAVE_SLOT: String = "quicksave"

var _engine: RefCounted
var _last_state: Dictionary = {}
var _loading: bool = false
var _autosave_pending: bool = false
var _pending_autosave_reasons: PackedStringArray = []
var _base_playtime_seconds: int = 0
var _session_started_ticks: int = -1
var _automatic_writes_enabled: bool = true


func _ready() -> void:
	_engine = SaveEngineScript.new(SAVE_ROOT)
	_automatic_writes_enabled = OS.get_environment("PORT_ALDER_DISABLE_AUTOSAVE") != "1"
	GameState.new_game_created.connect(_on_new_game_created)
	GameState.state_replaced.connect(_on_state_replaced)
	GameState.state_cleared.connect(_on_state_cleared)
	if GameState.has_active_game():
		_begin_play_session(GameState.current_state)
		_last_state = GameState.current_state.duplicate(true)


func _unhandled_input(event: InputEvent) -> void:
	if not GameState.has_active_game():
		return
	if event.is_action_pressed("quicksave"):
		quicksave()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("quickload"):
		var result: Dictionary = quickload()
		if result.get("ok", false):
			call_deferred("_resume_after_hotload")
		get_viewport().set_input_as_handled()


func save_manual(slot_number: int, allow_overwrite: bool = false) -> Dictionary:
	if slot_number < 1 or slot_number > MANUAL_SLOT_COUNT:
		return _failure("Manual save slot must be between 1 and %d." % MANUAL_SLOT_COUNT)
	var slot_id: String = "manual_%d" % slot_number
	if _engine.slot_exists(slot_id) and not allow_overwrite:
		return _failure("%s already contains a save. Confirm before overwriting it." % slot_label(slot_id))
	return _write_slot(slot_id)


func quicksave() -> Dictionary:
	return _write_slot(QUICKSAVE_SLOT)


func autosave(reason: String = "checkpoint") -> Dictionary:
	if not GameState.has_active_game():
		return _failure("There is no active game to autosave.")
	var slot_id: String = _engine.choose_rotation_slot(autosave_slot_ids())
	var result: Dictionary = _write_slot(slot_id)
	if result.get("ok", false):
		result["reason"] = reason
	return result


func request_autosave(reason: String) -> void:
	if not _automatic_writes_enabled or _loading or not GameState.has_active_game():
		return
	if reason not in _pending_autosave_reasons:
		_pending_autosave_reasons.append(reason)
	if _autosave_pending:
		return
	_autosave_pending = true
	call_deferred("_flush_pending_autosave")


func load_slot(slot_id: String) -> Dictionary:
	var result: Dictionary = _engine.load_slot(slot_id)
	if not result.get("ok", false):
		var errors: PackedStringArray = result.get("errors", PackedStringArray(["Save could not be loaded."]))
		load_failed.emit(slot_id, errors)
		return result
	var compatibility_errors: PackedStringArray = _content_compatibility_errors(result["state"])
	if not compatibility_errors.is_empty():
		var failed: Dictionary = {"ok": false, "errors": compatibility_errors}
		load_failed.emit(slot_id, compatibility_errors)
		return failed
	_loading = true
	GameState.replace_state(result["state"].duplicate(true))
	_loading = false
	_begin_play_session(GameState.current_state)
	_last_state = GameState.current_state.duplicate(true)
	load_completed.emit(slot_id, bool(result.get("recovered_from_backup", false)))
	return result


func quickload() -> Dictionary:
	return load_slot(QUICKSAVE_SLOT)


func load_latest() -> Dictionary:
	var summaries: Array = list_saves()
	if summaries.is_empty():
		return _failure("No valid save is available.")
	for summary_value: Variant in summaries:
		if not summary_value is Dictionary:
			continue
		var result: Dictionary = load_slot(str(summary_value.get("slot_id", "")))
		if result.get("ok", false):
			return result
	return _failure("No compatible save could be loaded.")


func list_saves() -> Array:
	return _engine.list_valid_saves(all_slot_ids())


func summary_for_slot(slot_id: String) -> Dictionary:
	if not _engine.slot_exists(slot_id):
		return {}
	var result: Dictionary = _engine.load_slot(slot_id)
	return result.get("summary", {}) if result.get("ok", false) else {}


func has_valid_save() -> bool:
	return not list_saves().is_empty()


func has_slot(slot_id: String) -> bool:
	return _engine.slot_exists(slot_id)


func all_slot_ids() -> Array:
	var ids: Array = [QUICKSAVE_SLOT]
	ids.append_array(autosave_slot_ids())
	for index: int in range(1, MANUAL_SLOT_COUNT + 1):
		ids.append("manual_%d" % index)
	return ids


func autosave_slot_ids() -> Array:
	var ids: Array = []
	for index: int in AUTOSAVE_SLOT_COUNT:
		ids.append("autosave_%d" % index)
	return ids


func slot_label(slot_id: String) -> String:
	if slot_id == QUICKSAVE_SLOT:
		return "Quicksave"
	if slot_id.begins_with("autosave_"):
		return "Autosave %d" % (int(slot_id.trim_prefix("autosave_")) + 1)
	if slot_id.begins_with("manual_"):
		return "Manual Slot %d" % int(slot_id.trim_prefix("manual_"))
	return slot_id.replace("_", " ").capitalize()


func resume_scene_path() -> String:
	if not GameState.has_active_game():
		return AppConstants.MAIN_MENU_SCENE
	if GameState.current_state.get("conversation_state", {}).get("active") is Dictionary:
		return AppConstants.VN_DIALOGUE_SCENE
	var location_id: String = str(GameState.current_state.get("world_state", {}).get("current_location", "hale_home")).get_slice(".", 0)
	return AppConstants.HALE_HOME_SCENE if location_id == "hale_home" else AppConstants.CITY_LOCATION_SCENE


func format_summary(summary: Dictionary, compact: bool = false) -> String:
	if summary.is_empty():
		return "Empty"
	var duration: String = _format_playtime(int(summary.get("playtime_seconds", 0)))
	var location: String = str(summary.get("current_location", "unknown")).replace("_", " ").replace(".", " — ").capitalize()
	var first_line: String = "%s • %s • %s" % [summary.get("player_name", "Player"), summary.get("game_date", ""), str(summary.get("block", "")).replace("_", " ").capitalize()]
	if compact:
		return "%s\n%s • %s" % [first_line, location, duration]
	return "%s\n%s • $%.2f available • %s\nProgram: %s • Job: %s%s" % [
		first_line, location, float(summary.get("money", 0.0)), duration,
		str(summary.get("program", "None")).replace("_", " ").capitalize(), summary.get("job", "None"),
		" • BACKUP RECOVERY" if bool(summary.get("recovered_from_backup", false)) else "",
	]


func _write_slot(slot_id: String) -> Dictionary:
	if not GameState.has_active_game():
		return _failure("There is no active game to save.")
	if not GameState.current_state.get("simulation", {}).get("pending_events", []).is_empty():
		return _failure("Saving is waiting for the current transaction to finish.")
	var result: Dictionary = _engine.save_slot(GameState.current_state, slot_id, {
		"build_version": AppConstants.APP_VERSION,
		"playtime_seconds": _current_playtime_seconds(),
	})
	if result.get("ok", false):
		save_completed.emit(slot_id, result["summary"])
	else:
		var errors: PackedStringArray = result.get("errors", PackedStringArray(["Save failed."]))
		save_failed.emit(slot_id, errors)
	return result


func _flush_pending_autosave() -> void:
	_autosave_pending = false
	if _pending_autosave_reasons.is_empty() or _loading or not GameState.has_active_game():
		_pending_autosave_reasons.clear()
		return
	var reason: String = ", ".join(_pending_autosave_reasons)
	_pending_autosave_reasons.clear()
	autosave(reason)


func _resume_after_hotload() -> void:
	get_tree().change_scene_to_file(resume_scene_path())


func _on_new_game_created(state: Dictionary) -> void:
	_begin_play_session(state)
	_last_state = state.duplicate(true)
	request_autosave("new_game")


func _on_state_replaced(state: Dictionary) -> void:
	if _loading:
		return
	if _last_state.is_empty():
		_last_state = state.duplicate(true)
		return
	var reasons: PackedStringArray = _autosave_reasons(_last_state, state)
	_last_state = state.duplicate(true)
	for reason: String in reasons:
		request_autosave(reason)


func _on_state_cleared() -> void:
	_last_state.clear()
	_pending_autosave_reasons.clear()
	_autosave_pending = false
	_base_playtime_seconds = 0
	_session_started_ticks = -1


func _autosave_reasons(previous: Dictionary, current: Dictionary) -> PackedStringArray:
	var reasons: PackedStringArray = []
	if _date_key(previous) != _date_key(current):
		reasons.append("new_day")
	if current.get("quest_state", {}).get("completed", []).size() > previous.get("quest_state", {}).get("completed", []).size():
		reasons.append("quest_completed")
	if current.get("conversation_state", {}).get("completed", []).size() > previous.get("conversation_state", {}).get("completed", []).size():
		reasons.append("conversation_completed")
	var previous_conversation: Variant = previous.get("conversation_state", {}).get("active")
	var current_conversation: Variant = current.get("conversation_state", {}).get("active")
	if current_conversation is Dictionary and not previous_conversation is Dictionary:
		reasons.append("conversation_started")
	if _education_signature(previous) != _education_signature(current):
		reasons.append("education_changed")
	if _employment_signature(previous) != _employment_signature(current):
		reasons.append("employment_changed")
	if _family_signature(previous) != _family_signature(current):
		reasons.append("family_changed")
	if _agreement_signature(previous) != _agreement_signature(current):
		reasons.append("relationship_agreement_changed")
	if current.get("weekly_review_state", {}).get("history", []).size() > previous.get("weekly_review_state", {}).get("history", []).size():
		reasons.append("weekly_review_completed")
	var old_location: String = str(previous.get("world_state", {}).get("current_location", "")).get_slice(".", 0)
	var new_location: String = str(current.get("world_state", {}).get("current_location", "")).get_slice(".", 0)
	if old_location != new_location:
		reasons.append("travel_completed")
	return reasons


func _education_signature(state: Dictionary) -> String:
	var education: Dictionary = state.get("player", {}).get("education", {})
	return JSON.stringify({
		"enrolled": education.get("enrolled", false),
		"program": education.get("program"),
		"semester_number": education.get("semester_number", 0),
		"semesters_completed": education.get("semesters_completed", 0),
		"registration_hold": education.get("registration_hold", false),
	}, "", true)


func _employment_signature(state: Dictionary) -> String:
	var employment: Dictionary = state.get("player", {}).get("employment", {})
	return JSON.stringify({
		"employed": employment.get("employed", false),
		"active_jobs": employment.get("active_jobs", []),
		"application_count": employment.get("applications", []).size(),
	}, "", true)


func _family_signature(state: Dictionary) -> String:
	var family: Dictionary = state.get("family_state", {})
	return JSON.stringify({
		"pregnancies": family.get("pregnancies", []),
		"children": family.get("children", []),
	}, "", true)


func _agreement_signature(state: Dictionary) -> String:
	var agreements: Dictionary = {}
	for character_id: Variant in state.get("relationships", {}):
		var relationship: Dictionary = state["relationships"][character_id]
		agreements[character_id] = {
			"status": relationship.get("status"),
			"dating_agreement": relationship.get("dating_agreement"),
			"agreements": relationship.get("agreements", []),
		}
	return JSON.stringify(agreements, "", true)


func _content_compatibility_errors(state: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	var content_state: Dictionary = state.get("content_state", {})
	var manifest: Array = content_state.get("package_manifest", [])
	if manifest.is_empty():
		for package_id_value: Variant in content_state.get("loaded_packages", []):
			var package_id: String = str(package_id_value)
			if ContentRegistry.get_package(package_id) == null:
				errors.append("Required content package is missing: %s" % package_id)
		return errors
	var active_mods: Array = state.get("metadata", {}).get("active_mods", [])
	for entry_value: Variant in manifest:
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		var package_id: String = str(entry.get("content_id", ""))
		var current_package: Variant = ContentRegistry.get_package(package_id)
		if not current_package is Dictionary:
			if bool(entry.get("required", true)):
				errors.append("Required content package is missing: %s" % package_id)
			continue
		if package_id in active_mods:
			var current_checksum: String = JSON.stringify(current_package, "", true, true).sha256_text()
			if current_checksum != str(entry.get("checksum", "")):
				errors.append("Mod content changed without a compatible migration: %s" % package_id)
	return errors


func _begin_play_session(state: Dictionary) -> void:
	_base_playtime_seconds = maxi(int(state.get("metadata", {}).get("playtime_seconds", 0)), 0)
	_session_started_ticks = Time.get_ticks_msec()


func _current_playtime_seconds() -> int:
	if _session_started_ticks < 0:
		return _base_playtime_seconds
	return _base_playtime_seconds + maxi(int((Time.get_ticks_msec() - _session_started_ticks) / 1000), 0)


func _date_key(state: Dictionary) -> String:
	var clock: Dictionary = state.get("clock", {})
	return "%d-%02d-%02d" % [int(clock.get("year", 0)), int(clock.get("month", 0)), int(clock.get("day", 0))]


func _format_playtime(seconds: int) -> String:
	var hours: int = seconds / 3600
	var minutes: int = (seconds % 3600) / 60
	return "%dh %02dm" % [hours, minutes]


func _failure(message: String) -> Dictionary:
	return {"ok": false, "errors": PackedStringArray([message])}
