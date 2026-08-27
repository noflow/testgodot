extends Node

signal validation_completed(errors: PackedStringArray)
signal content_loaded(document_count: int, package_count: int)

const CONTENT_ROOT: String = "res://content"
const CHARACTER_ROOT: String = "res://characters"
const INDEXED_COLLECTIONS: PackedStringArray = [
	"locations", "districts", "quests", "conversations", "items",
	"jobs", "courses", "programs", "activities", "actions", "city_interactions",
	"phone_apps", "stores", "operations",
	"date_activities", "housing_listings", "vn_backgrounds",
]

var _documents: Dictionary = {}
var _packages: Dictionary = {}
var _characters: Dictionary = {}
var _indexes: Dictionary = {}
var _last_errors: PackedStringArray = []


func validate_foundation() -> PackedStringArray:
	_documents.clear()
	_packages.clear()
	_characters.clear()
	_indexes.clear()
	_last_errors.clear()

	for collection_name: String in INDEXED_COLLECTIONS:
		_indexes[collection_name] = {}

	_load_content_tree()
	_load_character_packages()
	for path: String in AppConstants.REQUIRED_FOUNDATION_FILES:
		_load_json_document(path)

	_build_indexes()
	_validate_required_files()
	_validate_character_packages()
	_validate_navigation_package()
	_validate_vertical_slice_manifest()
	_validate_sandbox_quest_package()
	_validate_housing_package()
	_validate_vn_art_assets()
	validation_completed.emit(_last_errors.duplicate())
	content_loaded.emit(_documents.size(), _packages.size())
	return _last_errors.duplicate()


func get_document(path: String) -> Variant:
	return _documents.get(path)


func get_package(package_id: String) -> Variant:
	return _packages.get(package_id)


func get_character(character_id: String) -> Variant:
	return _characters.get(character_id)


func get_location(location_id: String) -> Variant:
	return get_content("locations", location_id)


func get_content(collection_name: String, content_id: String) -> Variant:
	var collection: Dictionary = _indexes.get(collection_name, {})
	return collection.get(content_id)


func get_all(collection_name: String) -> Array:
	var collection: Dictionary = _indexes.get(collection_name, {})
	var ids: Array = collection.keys()
	ids.sort()
	var results: Array = []
	for content_id: Variant in ids:
		results.append(collection[content_id])
	return results


func get_loaded_package_ids() -> PackedStringArray:
	var ids: PackedStringArray = []
	for package_id: Variant in _packages.keys():
		ids.append(str(package_id))
	ids.sort()
	return ids


func get_last_errors() -> PackedStringArray:
	return _last_errors.duplicate()


func get_document_count() -> int:
	return _documents.size()


func get_package_count() -> int:
	return _packages.size()


func _load_content_tree() -> void:
	var paths: PackedStringArray = []
	_collect_files(CONTENT_ROOT, "json", paths)
	paths.sort()
	for path: String in paths:
		_load_json_document(path)


func _load_character_packages() -> void:
	var paths: PackedStringArray = []
	_collect_files(CHARACTER_ROOT, "character", paths)
	paths.sort()
	for path: String in paths:
		_load_json_document(path)


func _collect_files(directory_path: String, extension: String, results: PackedStringArray) -> void:
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		_last_errors.append("Missing content directory: %s" % directory_path)
		return

	directory.list_dir_begin()
	var entry_name: String = directory.get_next()
	while not entry_name.is_empty():
		if entry_name.begins_with("."):
			entry_name = directory.get_next()
			continue
		var entry_path: String = "%s/%s" % [directory_path, entry_name]
		if directory.current_is_dir():
			_collect_files(entry_path, extension, results)
		elif entry_name.get_extension() == extension:
			results.append(entry_path)
		entry_name = directory.get_next()
	directory.list_dir_end()


func _load_json_document(path: String) -> void:
	if _documents.has(path):
		return
	if not FileAccess.file_exists(path):
		_last_errors.append("Missing required file: %s" % path)
		return

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		_last_errors.append("Unable to read required file: %s" % path)
		return

	var json: JSON = JSON.new()
	var parse_error: Error = json.parse(file.get_as_text())
	if parse_error != OK:
		_last_errors.append(
			"Invalid JSON in %s at line %d: %s" % [path, json.get_error_line(), json.get_error_message()]
		)
		return

	if not json.data is Dictionary:
		_last_errors.append("Expected a JSON object at the root of: %s" % path)
		return

	_documents[path] = json.data


func _build_indexes() -> void:
	for path: Variant in _documents:
		var document: Dictionary = _documents[path]
		var package_id: String = str(document.get("package_id", ""))
		if not package_id.is_empty():
			if _packages.has(package_id):
				_last_errors.append("Duplicate package id %s in %s." % [package_id, path])
			else:
				_packages[package_id] = document

		if str(path).get_extension() == "character":
			var character_id: String = str(document.get("id", ""))
			if character_id.is_empty():
				_last_errors.append("Character package has no id: %s" % path)
			elif _characters.has(character_id):
				_last_errors.append("Duplicate character id: %s" % character_id)
			else:
				_characters[character_id] = document

		for collection_name: String in INDEXED_COLLECTIONS:
			var entries: Variant = document.get(collection_name, [])
			if not entries is Array:
				continue
			var index: Dictionary = _indexes[collection_name]
			for entry: Variant in entries:
				if not entry is Dictionary:
					continue
				var content_id: String = str(entry.get("id", ""))
				if content_id.is_empty():
					_last_errors.append("Entry without id in %s collection in %s." % [collection_name, path])
				elif index.has(content_id):
					_last_errors.append("Duplicate %s id: %s" % [collection_name, content_id])
				else:
					index[content_id] = entry


func _validate_required_files() -> void:
	for path: String in AppConstants.REQUIRED_FOUNDATION_FILES:
		if not _documents.has(path):
			_last_errors.append("Required foundation document did not load: %s" % path)


func _validate_character_packages() -> void:
	if _characters.size() != 15:
		_last_errors.append("Expected 15 opening character packages; found %d." % _characters.size())

	for character_id: Variant in _characters:
		var character: Dictionary = _characters[character_id]
		var home_location: String = str(character.get("home", {}).get("location_id", ""))
		if get_location(home_location) == null:
			_last_errors.append("Character %s has unknown home location %s." % [character_id, home_location])
		var schedule: Dictionary = character.get("schedule", {})
		for collection_name: String in ["fixed_commitments", "public_presence"]:
			for entry_value: Variant in schedule.get(collection_name, []):
				if not entry_value is Dictionary:
					_last_errors.append("Character %s has a non-object %s schedule entry." % [character_id, collection_name])
					continue
				_validate_character_schedule_location(str(character_id), collection_name, entry_value)
		if not schedule.get("public_presence", []).is_empty():
			var encounter: Variant = character.get("encounter")
			if not encounter is Dictionary:
				_last_errors.append("Character %s has public presence but no encounter authoring." % character_id)
			elif str(encounter.get("contact_policy", "after_introduction")) not in ["after_introduction", "never"]:
				_last_errors.append("Character %s has an unsupported contact policy." % character_id)


func _validate_character_schedule_location(character_id: String, collection_name: String, entry: Dictionary) -> void:
	var location_path: String = str(entry.get("location", ""))
	if location_path.is_empty():
		_last_errors.append("Character %s %s entry %s has no location." % [character_id, collection_name, entry.get("activity", "unknown")])
		return
	var location_id: String = location_path.get_slice(".", 0)
	var location: Variant = get_location(location_id)
	if not location is Dictionary:
		_last_errors.append("Character %s schedule references unknown location %s." % [character_id, location_path])
		return
	if not location_path.contains(".") and not entry.get("home_placement") is Dictionary:
		_last_errors.append("Character %s %s entry %s requires an exact room path." % [character_id, collection_name, entry.get("activity", "unknown")])
	if location_path.contains(".") and not _location_has_room(location, location_path.get_slice(".", 1)):
		_last_errors.append("Character %s schedule references unknown room %s." % [character_id, location_path])
	var home_placement: Variant = entry.get("home_placement")
	if home_placement is Dictionary and not str(home_placement.get("room", "")).is_empty() and not _location_has_room(location, str(home_placement.get("room", ""))):
		_last_errors.append("Character %s schedule has an unknown home-placement room in %s." % [character_id, location_id])


func _validate_navigation_package() -> void:
	var locations_by_id: Dictionary = {}
	for location_value: Variant in get_all("locations"):
		if location_value is Dictionary:
			locations_by_id[str(location_value.get("id", ""))] = location_value
	for location_id_value: Variant in locations_by_id:
		var location_id: String = str(location_id_value)
		var location: Dictionary = locations_by_id[location_id]
		var room_ids: PackedStringArray = []
		for room_value: Variant in location.get("rooms", []):
			if room_value is Dictionary:
				room_ids.append(str(room_value.get("id", "")))
		var outside_room: String = str(location.get("outside_room", ""))
		if not outside_room.is_empty() and outside_room not in room_ids:
			_last_errors.append("Location %s has an unknown outside room: %s." % [location_id, outside_room])
		for room_value: Variant in location.get("rooms", []):
			if not room_value is Dictionary:
				continue
			var room_id: String = str(room_value.get("id", ""))
			for direction_value: Variant in room_value.get("navigation", {}):
				var direction: String = str(direction_value)
				if direction not in ["left", "up", "right", "down"]:
					_last_errors.append("Room %s.%s has unsupported navigation direction %s." % [location_id, room_id, direction])
				var target: String = str(room_value.get("navigation", {}).get(direction, ""))
				var target_location_id: String = target.get_slice(".", 0) if target.contains(".") else location_id
				var target_room_id: String = target.get_slice(".", 1) if target.contains(".") else target
				var target_location: Variant = locations_by_id.get(target_location_id)
				if not target_location is Dictionary or not _location_has_room(target_location, target_room_id):
					_last_errors.append("Room %s.%s points to an unknown navigation target: %s." % [location_id, room_id, target])
		if location.get("mall") is Dictionary:
			_validate_mall_location(location_id, location, room_ids)
	for character_id_value: Variant in _characters:
		var character_id: String = str(character_id_value)
		var character: Dictionary = _characters[character_id]
		var home_location_id: String = str(character.get("home", {}).get("location_id", ""))
		if home_location_id == "hale_home":
			continue
		var home: Variant = locations_by_id.get(home_location_id)
		if not home is Dictionary:
			continue
		if character_id not in home.get("residents", []):
			_last_errors.append("Character %s is not listed as a resident of %s." % [character_id, home_location_id])
		var discovery: Variant = home.get("discovery")
		if not discovery is Dictionary or not bool(discovery.get("discoverable", false)) or not discovery.has("hidden_until_discovered"):
			_last_errors.append("NPC home %s must explicitly define discoverable visibility." % home_location_id)
		if str(home.get("outside_room", "")).is_empty():
			_last_errors.append("NPC home %s requires an authored entrance room." % home_location_id)


func _validate_mall_location(location_id: String, location: Dictionary, room_ids: PackedStringArray) -> void:
	var mall: Dictionary = location.get("mall", {})
	var slots_value: Variant = mall.get("storefront_slots", [])
	if not slots_value is Array or slots_value.is_empty():
		_last_errors.append("Mall %s requires at least one storefront slot." % location_id)
		return
	var units: Dictionary = {}
	var occupied_store_ids: Dictionary = {}
	for slot_value: Variant in slots_value:
		if not slot_value is Dictionary:
			_last_errors.append("Mall %s has a storefront slot that is not an object." % location_id)
			continue
		var unit: String = str(slot_value.get("unit", ""))
		if unit.is_empty():
			_last_errors.append("Mall %s has a storefront slot without a unit id." % location_id)
		elif units.has(unit):
			_last_errors.append("Mall %s has duplicate storefront unit %s." % [location_id, unit])
		else:
			units[unit] = true
		var room_id: String = str(slot_value.get("room", ""))
		if room_id not in room_ids:
			_last_errors.append("Mall %s unit %s references unknown room %s." % [location_id, unit, room_id])
		var status: String = str(slot_value.get("status", ""))
		if status not in ["occupied", "coming_soon", "rotating", "vacant"]:
			_last_errors.append("Mall %s unit %s has unsupported status %s." % [location_id, unit, status])
		if status != "occupied":
			continue
		var store_id: String = str(slot_value.get("store_id", ""))
		var store: Variant = get_content("stores", store_id)
		if store_id.is_empty() or not store is Dictionary:
			_last_errors.append("Mall %s occupied unit %s references unknown store %s." % [location_id, unit, store_id])
			continue
		if occupied_store_ids.has(store_id):
			_last_errors.append("Mall %s assigns store %s to more than one occupied unit." % [location_id, store_id])
		occupied_store_ids[store_id] = true
		var store_location: String = str(store.get("location", ""))
		var expected_store_location: String = "%s.%s" % [location_id, room_id]
		if store_location != expected_store_location:
			_last_errors.append("Mall %s unit %s store %s is assigned to %s instead of %s." % [location_id, unit, store_id, store_location, expected_store_location])
		var interaction_found: bool = false
		for interaction_value: Variant in get_all("city_interactions"):
			if not interaction_value is Dictionary:
				continue
			if str(interaction_value.get("type", "")) == "store" and str(interaction_value.get("store_id", "")) == store_id and str(interaction_value.get("location", "")) == location_id and room_id in interaction_value.get("rooms", []):
				interaction_found = true
				break
		if not interaction_found:
			_last_errors.append("Mall %s occupied unit %s has no matching room storefront interaction." % [location_id, unit])
	var directory_found: bool = false
	for interaction_value: Variant in get_all("city_interactions"):
		if interaction_value is Dictionary and str(interaction_value.get("type", "")) == "mall_directory" and str(interaction_value.get("location", "")) == location_id:
			directory_found = true
			break
	if not directory_found:
		_last_errors.append("Mall %s requires at least one mall-directory interaction." % location_id)


func _location_has_room(location: Dictionary, room_id: String) -> bool:
	for room_value: Variant in location.get("rooms", []):
		if room_value is Dictionary and str(room_value.get("id", "")) == room_id:
			return true
	return false


func _validate_vertical_slice_manifest() -> void:
	var manifest: Variant = get_package("vertical_slice_scope")
	if not manifest is Dictionary:
		_last_errors.append("Vertical-slice manifest package did not load.")
		return

	if int(manifest.get("format_version", 0)) != 1:
		_last_errors.append("Unsupported vertical-slice manifest version.")

	var build_name: String = str(manifest.get("build_name", ""))
	if build_name.is_empty():
		_last_errors.append("Vertical-slice manifest has no build name.")

	for character_id: Variant in manifest.get("required_characters", []):
		if get_character(str(character_id)) == null:
			_last_errors.append("Vertical slice requires unknown character: %s" % character_id)
	for location_id: Variant in manifest.get("required_locations", []):
		if get_location(str(location_id)) == null:
			_last_errors.append("Vertical slice requires unknown location: %s" % location_id)


func _validate_sandbox_quest_package() -> void:
	var package: Variant = get_package("port_alder_sandbox_quest_system")
	if not package is Dictionary:
		_last_errors.append("Sandbox quest-progression package did not load.")
		return
	if str(package.get("default_timing", "")) != "open_ended":
		_last_errors.append("Sandbox quests must default to open-ended timing.")
	if str(package.get("default_discovery_policy", "")) != "offer":
		_last_errors.append("Sandbox quests must default to optional offers.")
	var discovery_policies: PackedStringArray = []
	for policy_value: Variant in package.get("discovery_policies", []):
		if policy_value is Dictionary:
			discovery_policies.append(str(policy_value.get("id", "")))
	for required_policy: String in ["offer", "auto_start"]:
		if required_policy not in discovery_policies:
			_last_errors.append("Sandbox quests are missing the %s discovery policy." % required_policy)
	var gate_ids: PackedStringArray = []
	for gate_value: Variant in package.get("supported_gates", []):
		if gate_value is Dictionary:
			gate_ids.append(str(gate_value.get("id", "")))
	for required_gate: String in ["attribute", "skill", "relationship", "prior_choice", "location", "life_direction"]:
		if required_gate not in gate_ids:
			_last_errors.append("Sandbox quests are missing the %s gate." % required_gate)
	var all_quests: Array = get_all("quests")
	var timed_quest_count: int = 0
	for quest_value: Variant in all_quests:
		if not quest_value is Dictionary:
			continue
		var quest_id: String = str(quest_value.get("id", "unknown"))
		var discovery: Variant = quest_value.get("discovery")
		if not discovery is Dictionary:
			_last_errors.append("Quest must explicitly declare how it is discovered: %s" % quest_id)
		else:
			if str(discovery.get("policy", "")) not in discovery_policies:
				_last_errors.append("Quest has an invalid discovery policy: %s" % quest_id)
			if str(discovery.get("source", "")) not in package.get("discovery_sources", []):
				_last_errors.append("Quest has an invalid discovery source: %s" % quest_id)
		for requirement_value: Variant in quest_value.get("requirements", []):
			if not requirement_value is Dictionary:
				_last_errors.append("Quest requirement must be an object: %s" % quest_id)
				continue
			if str(requirement_value.get("type", "")) not in gate_ids:
				_last_errors.append("Quest has an unsupported gate type: %s" % quest_id)
			if str(requirement_value.get("visibility", "visible")) not in ["visible", "hidden"]:
				_last_errors.append("Quest gate visibility must be visible or hidden: %s" % quest_id)
		var repeatable: Variant = quest_value.get("repeatable")
		if repeatable != null:
			if not repeatable is Dictionary:
				_last_errors.append("Repeatable quest settings must be an object: %s" % quest_id)
			else:
				if int(repeatable.get("target_completions", 0)) < 2:
					_last_errors.append("Repeatable quest target must be at least two: %s" % quest_id)
				if str(repeatable.get("restart_policy", "")) not in package.get("repeatable_quest_rules", {}).get("restart_policies", []):
					_last_errors.append("Repeatable quest restart policy is invalid: %s" % quest_id)
				if int(repeatable.get("cooldown_blocks", -1)) < 0:
					_last_errors.append("Repeatable quest cooldown cannot be negative: %s" % quest_id)
				if str(repeatable.get("progress_label", "")).is_empty():
					_last_errors.append("Repeatable quest requires a progress label: %s" % quest_id)
		var failure: Variant = quest_value.get("failure")
		if failure is Dictionary and failure.has("deadline"):
			timed_quest_count += 1
			var timing: Variant = quest_value.get("timing")
			if not timing is Dictionary or str(timing.get("mode", "")) not in package.get("deadline_modes", []):
				_last_errors.append("Timed quest must declare an approved timing mode: %s" % quest_value.get("id", "unknown"))
			elif str(timing.get("reason", "")).is_empty() or str(timing.get("deadline_visibility", "")) != "shown_with_quest":
				_last_errors.append("Timed quest must show its deadline and narrative reason: %s" % quest_value.get("id", "unknown"))
			elif not timing.get("warnings", []) is Array or timing.get("warnings", []).is_empty():
				_last_errors.append("Timed quest must author at least one deadline warning: %s" % quest_value.get("id", "unknown"))
	var timed_maximum: int = int(package.get("deadline_rules", {}).get("recommended_timed_maximum_percent", 15))
	if not all_quests.is_empty() and timed_quest_count * 100 > all_quests.size() * timed_maximum:
		_last_errors.append("Timed quests exceed the sandbox authoring target of %d%%." % timed_maximum)


func _validate_housing_package() -> void:
	var package: Variant = get_package("port_alder_housing_system")
	if not package is Dictionary:
		_last_errors.append("Housing system package did not load.")
		return
	var listings: Array = get_all("housing_listings")
	if listings.size() < 3:
		_last_errors.append("Housing system requires at least three starter listings.")
	for listing_value: Variant in listings:
		if not listing_value is Dictionary:
			continue
		var listing: Dictionary = listing_value
		var listing_id: String = str(listing.get("id", "unknown"))
		var tenure: String = str(listing.get("tenure", ""))
		if tenure not in ["rental", "purchase"]:
			_last_errors.append("Housing listing has invalid tenure: %s" % listing_id)
		var location_id: String = str(listing.get("location_id", ""))
		var location: Variant = get_location(location_id)
		if not location is Dictionary:
			_last_errors.append("Housing listing has unknown location: %s" % listing_id)
			continue
		var room_ids: PackedStringArray = []
		for room_value: Variant in location.get("rooms", []):
			if room_value is Dictionary:
				room_ids.append(str(room_value.get("id", "")))
		for room_field: String in ["residence_room", "arrival_room"]:
			if str(listing.get(room_field, "")) not in room_ids:
				_last_errors.append("Housing listing %s has unknown %s." % [listing_id, room_field])
		if tenure == "rental" and float(listing.get("monthly_rent", 0.0)) <= 0.0:
			_last_errors.append("Rental listing has no monthly rent: %s" % listing_id)
		if tenure == "purchase" and (float(listing.get("purchase_price", 0.0)) <= 0.0 or float(listing.get("monthly_mortgage", 0.0)) <= 0.0):
			_last_errors.append("Purchase listing has invalid price or mortgage: %s" % listing_id)
		if not listing.get("storage_access") is Dictionary:
			_last_errors.append("Housing listing has no storage-access mapping: %s" % listing_id)
		else:
			for container_id: Variant in listing["storage_access"]:
				var storage_room: String = str(listing["storage_access"][container_id])
				if storage_room not in room_ids:
					_last_errors.append("Housing listing %s maps %s to unknown room %s." % [listing_id, container_id, storage_room])


func _validate_vn_art_assets() -> void:
	var package: Variant = get_package("port_alder_vn_art")
	if not package is Dictionary:
		_last_errors.append("VN artwork package did not load.")
		return
	for fallback_type: String in ["background", "portrait"]:
		var fallback_path: String = str(package.get("fallbacks", {}).get(fallback_type, ""))
		if fallback_path.is_empty() or not FileAccess.file_exists(fallback_path):
			_last_errors.append("VN artwork is missing its %s fallback: %s" % [fallback_type, fallback_path])
	for background_value: Variant in get_all("vn_backgrounds"):
		if not background_value is Dictionary:
			continue
		var background: Dictionary = background_value
		var path: String = str(background.get("path", ""))
		if path.is_empty() or not FileAccess.file_exists(path):
			_last_errors.append("VN background %s has a missing asset: %s" % [background.get("id", "unknown"), path])
		for variant_name: Variant in background.get("variants", {}):
			var variant_path: String = str(background["variants"][variant_name])
			if not FileAccess.file_exists(variant_path):
				_last_errors.append("VN background %s variant %s is missing: %s" % [background.get("id", "unknown"), variant_name, variant_path])
	for character_id_value: Variant in _characters:
		var character_id: String = str(character_id_value)
		var character: Dictionary = _characters[character_id]
		var portrait_ids: PackedStringArray = []
		for portrait_value: Variant in character.get("asset_refs", {}).get("portraits", []):
			if not portrait_value is Dictionary:
				_last_errors.append("Character %s portrait reference must be an object." % character_id)
				continue
			var portrait: Dictionary = portrait_value
			var portrait_id: String = str(portrait.get("id", ""))
			var portrait_path: String = str(portrait.get("path", ""))
			if portrait_id.is_empty() or portrait_id in portrait_ids:
				_last_errors.append("Character %s has a missing or duplicate portrait id." % character_id)
			else:
				portrait_ids.append(portrait_id)
			if portrait_path.is_empty() or not FileAccess.file_exists(portrait_path):
				_last_errors.append("Character %s portrait %s is missing: %s" % [character_id, portrait_id, portrait_path])
