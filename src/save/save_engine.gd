extends RefCounted
class_name PortAlderSaveEngine

const CURRENT_FORMAT_VERSION: int = 1
const PRIMARY_FILE: String = "save.json"
const TEMPORARY_FILE: String = "save.json.tmp"
const BACKUP_FILE: String = "save.json.bak"
const REQUIRED_SECTIONS: PackedStringArray = [
	"content_version", "metadata", "clock", "player", "npc_states", "relationships", "quest_state",
	"conversation_state", "calendar_state", "world_state", "household_state",
	"family_state", "simulation", "content_state",
]
const WEEKDAYS: PackedStringArray = [
	"monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday",
]
const BLOCKS: PackedStringArray = [
	"early_morning", "morning", "lunch", "afternoon", "evening", "late_evening", "night",
]

var _root_path: String


func _init(root_path: String = "user://saves") -> void:
	_root_path = ProjectSettings.globalize_path(root_path).trim_suffix("/")


func save_slot(state: Dictionary, slot_id: String, options: Dictionary = {}) -> Dictionary:
	var slot_error: String = _slot_id_error(slot_id)
	if not slot_error.is_empty():
		return _failure(slot_error)
	var validation: PackedStringArray = validate_state(state)
	if not validation.is_empty():
		return _failure("Save state is invalid: %s" % "; ".join(validation))

	var snapshot: Dictionary = state.duplicate(true)
	var now: String = str(options.get("timestamp_utc", Time.get_datetime_string_from_system(true, false)))
	var metadata: Dictionary = snapshot["metadata"]
	metadata["slot_id"] = slot_id
	metadata["updated_at_utc"] = now
	metadata["created_at_utc"] = str(metadata.get("created_at_utc", now))
	metadata["build_version"] = str(options.get("build_version", metadata.get("build_version", "unknown")))
	metadata["playtime_seconds"] = maxi(int(options.get("playtime_seconds", metadata.get("playtime_seconds", 0))), 0)
	snapshot["save_format_version"] = CURRENT_FORMAT_VERSION
	metadata["checksum"] = calculate_checksum(snapshot)

	var slot_path: String = _slot_path(slot_id)
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(slot_path)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		return _failure("Could not create the save directory for %s." % slot_id)

	var temporary_path: String = _file_path(slot_id, TEMPORARY_FILE)
	var primary_path: String = _file_path(slot_id, PRIMARY_FILE)
	var backup_path: String = _file_path(slot_id, BACKUP_FILE)
	var temporary_file: FileAccess = FileAccess.open(temporary_path, FileAccess.WRITE)
	if temporary_file == null:
		return _failure("Could not open the temporary save file for writing.")
	temporary_file.store_string(JSON.stringify(snapshot, "  ", true, true))
	temporary_file.flush()
	var write_error: Error = temporary_file.get_error()
	temporary_file.close()
	if write_error != OK:
		return _failure("The temporary save file could not be written completely.")

	var temporary_validation: Dictionary = _read_file(temporary_path, true)
	if not temporary_validation.get("ok", false):
		return _failure("The temporary save failed validation: %s" % _first_error(temporary_validation))

	if FileAccess.file_exists(primary_path):
		var current_validation: Dictionary = _read_file(primary_path, true)
		if current_validation.get("ok", false):
			if FileAccess.file_exists(backup_path):
				var remove_error: Error = DirAccess.remove_absolute(backup_path)
				if remove_error != OK:
					return _failure("The previous backup could not be rotated safely.")
			var backup_error: Error = DirAccess.rename_absolute(primary_path, backup_path)
			if backup_error != OK:
				return _failure("The current save could not be moved to its backup.")
		else:
			var quarantine_path: String = _next_quarantine_path(slot_id)
			var quarantine_error: Error = DirAccess.rename_absolute(primary_path, quarantine_path)
			if quarantine_error != OK:
				return _failure("The unreadable primary save could not be preserved before replacement.")

	var replace_error: Error = DirAccess.rename_absolute(temporary_path, primary_path)
	if replace_error != OK:
		if not FileAccess.file_exists(primary_path) and FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(backup_path, primary_path)
		return _failure("The validated save could not replace the current file.")

	return {
		"ok": true,
		"slot_id": slot_id,
		"state": snapshot,
		"summary": make_summary(snapshot, slot_id),
		"errors": PackedStringArray(),
	}


func load_slot(slot_id: String) -> Dictionary:
	var slot_error: String = _slot_id_error(slot_id)
	if not slot_error.is_empty():
		return _failure(slot_error)
	var primary: Dictionary = _read_file(_file_path(slot_id, PRIMARY_FILE), true)
	if primary.get("ok", false):
		primary = _persist_migration(primary, slot_id)
		if not primary.get("ok", false):
			return primary
		primary["slot_id"] = slot_id
		primary["recovered_from_backup"] = false
		primary["summary"] = make_summary(primary["state"], slot_id)
		return primary
	var backup: Dictionary = _read_file(_file_path(slot_id, BACKUP_FILE), true)
	if backup.get("ok", false):
		backup = _persist_migration(backup, slot_id)
		if not backup.get("ok", false):
			return backup
		backup["slot_id"] = slot_id
		backup["recovered_from_backup"] = true
		backup["warning"] = "The primary save was unreadable; its validated backup was loaded."
		backup["summary"] = make_summary(backup["state"], slot_id, true)
		return backup
	return _failure("%s is not recoverable. Primary: %s Backup: %s" % [
		slot_id, _first_error(primary), _first_error(backup),
	])


func slot_exists(slot_id: String) -> bool:
	return FileAccess.file_exists(_file_path(slot_id, PRIMARY_FILE)) or FileAccess.file_exists(_file_path(slot_id, BACKUP_FILE))


func list_valid_saves(slot_ids: Array) -> Array:
	var summaries: Array = []
	for slot_id_value: Variant in slot_ids:
		var slot_id: String = str(slot_id_value)
		if not slot_exists(slot_id):
			continue
		var result: Dictionary = load_slot(slot_id)
		if result.get("ok", false):
			summaries.append(result["summary"])
	summaries.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return str(left.get("updated_at_utc", "")) > str(right.get("updated_at_utc", ""))
	)
	return summaries


func choose_rotation_slot(slot_ids: Array) -> String:
	var oldest_slot: String = ""
	var oldest_timestamp: String = ""
	for slot_id_value: Variant in slot_ids:
		var slot_id: String = str(slot_id_value)
		if not slot_exists(slot_id):
			return slot_id
		var result: Dictionary = load_slot(slot_id)
		if not result.get("ok", false):
			return slot_id
		var timestamp: String = str(result["state"]["metadata"].get("updated_at_utc", ""))
		if oldest_slot.is_empty() or timestamp < oldest_timestamp:
			oldest_slot = slot_id
			oldest_timestamp = timestamp
	return oldest_slot


func make_summary(state: Dictionary, slot_id: String, recovered: bool = false) -> Dictionary:
	var player: Dictionary = state.get("player", {})
	var identity: Dictionary = player.get("identity", {})
	var clock: Dictionary = state.get("clock", {})
	var accounts: Dictionary = player.get("economy", {}).get("accounts", {})
	var available_money: float = float(accounts.get("wallet_cash", 0.0)) + float(accounts.get("checking", 0.0))
	var education: Dictionary = player.get("education", {})
	var employment: Dictionary = player.get("employment", {})
	var active_job_name: String = "None"
	for job_value: Variant in employment.get("active_jobs", []):
		if job_value is Dictionary and str(job_value.get("status", "active")) == "active":
			active_job_name = str(job_value.get("title", job_value.get("job_id", "Job"))).replace("_", " ").capitalize()
			break
	return {
		"slot_id": slot_id,
		"player_name": "%s %s" % [identity.get("first_name", "Unknown"), identity.get("last_name", "Player")],
		"game_date": "Y%d-%02d-%02d" % [int(clock.get("year", 1)), int(clock.get("month", 1)), int(clock.get("day", 1))],
		"weekday": str(clock.get("weekday", "")),
		"block": str(clock.get("block", "")),
		"current_location": str(state.get("world_state", {}).get("current_location", "unknown")),
		"money": available_money,
		"program": str(education.get("program", "None")) if bool(education.get("enrolled", false)) else "None",
		"job": active_job_name,
		"life_path": str(player.get("life_path", "Undecided")),
		"playtime_seconds": int(state.get("metadata", {}).get("playtime_seconds", 0)),
		"updated_at_utc": str(state.get("metadata", {}).get("updated_at_utc", "")),
		"build_version": str(state.get("metadata", {}).get("build_version", "")),
		"recovered_from_backup": recovered,
	}


func validate_state(state: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	if int(state.get("save_format_version", -1)) < 0:
		errors.append("save_format_version is missing")
	for section: String in REQUIRED_SECTIONS:
		if not state.has(section):
			errors.append("required section is missing: %s" % section)
	if not errors.is_empty():
		return errors
	if not state["metadata"] is Dictionary or not state["clock"] is Dictionary or not state["player"] is Dictionary:
		errors.append("metadata, clock, and player must be objects")
		return errors
	if not state["npc_states"] is Array or not state["relationships"] is Dictionary:
		errors.append("NPC and relationship state have invalid types")
		return errors
	for section: String in ["quest_state", "conversation_state", "calendar_state", "world_state", "household_state", "family_state", "simulation", "content_state"]:
		if not state[section] is Dictionary:
			errors.append("required section must be an object: %s" % section)
	if state.has("weekly_review_state") and not state["weekly_review_state"] is Dictionary:
		errors.append("weekly_review_state must be an object when present")
	if not errors.is_empty():
		return errors
	if not state["content_version"] is String or str(state["content_version"]).is_empty():
		errors.append("content_version must be a non-empty string")
	var clock: Dictionary = state["clock"]
	if int(clock.get("month", 0)) not in range(1, 13):
		errors.append("clock month is outside 1-12")
	if int(clock.get("day", 0)) not in range(1, 32):
		errors.append("clock day is outside 1-31")
	if str(clock.get("weekday", "")) not in WEEKDAYS:
		errors.append("clock weekday is invalid")
	if str(clock.get("block", "")) not in BLOCKS:
		errors.append("clock activity block is invalid")
	if int(clock.get("minute_within_block", -1)) not in range(0, 120):
		errors.append("clock minute is outside 0-119")
	var metadata: Dictionary = state["metadata"]
	for field: String in ["save_id", "slot_id", "created_at_utc", "updated_at_utc", "playtime_seconds", "build_version", "active_mods"]:
		if not metadata.has(field):
			errors.append("metadata field is missing: %s" % field)
	if int(metadata.get("playtime_seconds", -1)) < 0:
		errors.append("playtime cannot be negative")
	var player: Dictionary = state["player"]
	for section: String in ["identity", "needs", "attributes", "skills", "education", "employment", "economy", "inventory", "phone"]:
		if not player.get(section) is Dictionary:
			errors.append("player section is missing or invalid: %s" % section)
	if player.get("needs") is Dictionary:
		for need_id: Variant in player["needs"]:
			var need_value: Variant = player["needs"][need_id]
			if (not need_value is int and not need_value is float) or float(need_value) < 0.0 or float(need_value) > 100.0:
				errors.append("player need is outside 0-100: %s" % need_id)
	if player.get("skills") is Dictionary:
		for skill_id: Variant in player["skills"]:
			var skill_value: Variant = player["skills"][skill_id]
			if (not skill_value is int and not skill_value is float) or float(skill_value) < 0.0 or float(skill_value) > 250.0:
				errors.append("player skill is outside 0-250: %s" % skill_id)
	for character_id: Variant in state["relationships"]:
		if not state["relationships"][character_id] is Dictionary:
			errors.append("relationship state is invalid: %s" % character_id)
			continue
		for meter: String in ["friendship", "love", "attraction", "lust", "trust", "respect", "resentment", "jealousy", "comfort", "commitment", "compatibility", "satisfaction"]:
			var meter_value: Variant = state["relationships"][character_id].get(meter)
			if (not meter_value is int and not meter_value is float) or float(meter_value) < 0.0 or float(meter_value) > 100.0:
				errors.append("relationship meter is outside 0-100: %s.%s" % [character_id, meter])
	var simulation: Dictionary = state.get("simulation", {})
	if not simulation.get("pending_events", []).is_empty():
		errors.append("a simulation transaction is still pending")
	if simulation.get("recent_event_log", []).size() > 500:
		errors.append("recent simulation event log exceeds 500 entries")
	if state.get("weekly_review_state") is Dictionary:
		var review_state: Dictionary = state["weekly_review_state"]
		if not review_state.get("history", []) is Array or not review_state.get("selected_priorities", []) is Array:
			errors.append("weekly review history and priorities must be arrays")
		elif review_state.get("selected_priorities", []).size() > 3:
			errors.append("weekly review contains more than three selected priorities")
		if review_state.get("pending") != null and not review_state.get("pending") is Dictionary:
			errors.append("pending weekly review must be an object or null")
		if int(review_state.get("last_completed_week", 0)) < 0:
			errors.append("last completed weekly review cannot be negative")
	var content_state: Dictionary = state["content_state"]
	if not content_state.get("loaded_packages", []) is Array:
		errors.append("loaded content package ids must be an array")
	if not content_state.get("package_manifest", []) is Array:
		errors.append("content package manifest must be an array")
	return errors


func calculate_checksum(state: Dictionary) -> String:
	var checksum_source: Dictionary = state.duplicate(true)
	if checksum_source.get("metadata") is Dictionary:
		checksum_source["metadata"].erase("checksum")
	# Normalize through JSON once before hashing. Godot may deserialize whole-number
	# floats as integers; hashing the normalized representation keeps the checksum
	# stable across a write/read round trip without ignoring any state field.
	var normalized: Variant = JSON.parse_string(JSON.stringify(checksum_source, "", true, true))
	return JSON.stringify(normalized, "", true, true).sha256_text()


func _read_file(path: String, verify_checksum: bool) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _failure("File does not exist.")
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _failure("File could not be opened.")
	var json: JSON = JSON.new()
	var parse_error: Error = json.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		return _failure("JSON parse error on line %d: %s" % [json.get_error_line(), json.get_error_message()])
	if not json.data is Dictionary:
		return _failure("Save root is not an object.")
	var state: Dictionary = json.data
	var source_version: int = int(state.get("save_format_version", 0))
	if source_version > CURRENT_FORMAT_VERSION:
		return _failure("Save format %d is newer than supported format %d." % [source_version, CURRENT_FORMAT_VERSION])
	if verify_checksum and source_version >= 1:
		var stored_checksum: String = str(state.get("metadata", {}).get("checksum", ""))
		if stored_checksum.is_empty() or stored_checksum != calculate_checksum(state):
			return _failure("Checksum verification failed.")
	var migration_result: Dictionary = _migrate_to_current(state)
	if not migration_result.get("ok", false):
		return migration_result
	state = migration_result["state"]
	var validation: PackedStringArray = validate_state(state)
	if not validation.is_empty():
		return _failure("Save validation failed: %s" % "; ".join(validation))
	return {
		"ok": true,
		"state": state,
		"migrated_from_version": source_version if source_version < CURRENT_FORMAT_VERSION else null,
		"migration_log": migration_result.get("migration_log", []),
		"errors": PackedStringArray(),
	}


func _migrate_to_current(source: Dictionary) -> Dictionary:
	var state: Dictionary = source.duplicate(true)
	var version: int = int(state.get("save_format_version", 0))
	var migration_log: Array = []
	while version < CURRENT_FORMAT_VERSION:
		match version:
			0:
				state = _migrate_v0_to_v1(state)
				migration_log.append({"id": "create_initial_runtime_shape", "from": 0, "to": 1})
				version = 1
			_:
				return _failure("No migration exists from save format %d." % version)
	return {"ok": true, "state": state, "migration_log": migration_log, "errors": PackedStringArray()}


func _migrate_v0_to_v1(source: Dictionary) -> Dictionary:
	var state: Dictionary = source.duplicate(true)
	state["save_format_version"] = 1
	state["content_version"] = str(state.get("content_version", "legacy-prealpha"))
	if not state.get("metadata") is Dictionary:
		state["metadata"] = {}
	var metadata: Dictionary = state["metadata"]
	var timestamp: String = str(metadata.get("updated_at_utc", Time.get_datetime_string_from_system(true, false)))
	metadata["save_id"] = str(metadata.get("save_id", "migrated_%d" % Time.get_unix_time_from_system()))
	metadata["slot_id"] = str(metadata.get("slot_id", "legacy"))
	metadata["created_at_utc"] = str(metadata.get("created_at_utc", timestamp))
	metadata["updated_at_utc"] = timestamp
	metadata["playtime_seconds"] = maxi(int(metadata.get("playtime_seconds", 0)), 0)
	metadata["build_version"] = str(metadata.get("build_version", "legacy"))
	metadata["active_mods"] = metadata.get("active_mods", [])
	metadata["checksum"] = str(metadata.get("checksum", "legacy-unverified"))
	if not state.has("content_state"):
		state["content_state"] = {"loaded_packages": [], "package_manifest": [], "missing_optional_packages": [], "disabled_content_ids": []}
	elif not state["content_state"].has("package_manifest"):
		state["content_state"]["package_manifest"] = []
	metadata["migration_log"] = metadata.get("migration_log", [])
	metadata["migration_log"].append({"id": "create_initial_runtime_shape", "from": 0, "to": 1})
	return state


func _persist_migration(result: Dictionary, slot_id: String) -> Dictionary:
	if result.get("migrated_from_version") == null:
		return result
	var source_version: int = int(result["migrated_from_version"])
	var migration_log: Array = result.get("migration_log", []).duplicate(true)
	var migrated_state: Dictionary = result["state"]
	var persisted: Dictionary = save_slot(migrated_state, slot_id, {
		"build_version": migrated_state.get("metadata", {}).get("build_version", "legacy"),
		"playtime_seconds": migrated_state.get("metadata", {}).get("playtime_seconds", 0),
	})
	if not persisted.get("ok", false):
		return _failure("Save migrated in memory but could not be preserved safely: %s" % _first_error(persisted))
	return {
		"ok": true,
		"state": persisted["state"],
		"migrated_from_version": source_version,
		"migration_log": migration_log,
		"errors": PackedStringArray(),
	}


func _slot_id_error(slot_id: String) -> String:
	if slot_id.is_empty() or slot_id.length() > 48:
		return "Save slot id is empty or too long."
	for character: String in slot_id:
		if not character.to_lower() in "abcdefghijklmnopqrstuvwxyz0123456789_-":
			return "Save slot id contains unsupported characters."
	return ""


func _slot_path(slot_id: String) -> String:
	return "%s/%s" % [_root_path, slot_id]


func _file_path(slot_id: String, file_name: String) -> String:
	return "%s/%s" % [_slot_path(slot_id), file_name]


func _next_quarantine_path(slot_id: String) -> String:
	var base_path: String = _file_path(slot_id, "save.json.corrupt")
	if not FileAccess.file_exists(base_path):
		return base_path
	var suffix: int = 1
	while FileAccess.file_exists("%s.%d" % [base_path, suffix]):
		suffix += 1
	return "%s.%d" % [base_path, suffix]


func _first_error(result: Dictionary) -> String:
	var errors: Variant = result.get("errors", [])
	if (errors is Array or errors is PackedStringArray) and not errors.is_empty():
		return str(errors[0])
	return "Unknown save error."


func _failure(message: String) -> Dictionary:
	return {"ok": false, "errors": PackedStringArray([message])}
