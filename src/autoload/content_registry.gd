extends Node

signal validation_completed(errors: PackedStringArray)
signal content_loaded(document_count: int, package_count: int)

const CONTENT_ROOT: String = "res://content"
const CHARACTER_ROOT: String = "res://characters"
const INDEXED_COLLECTIONS: PackedStringArray = [
	"locations", "districts", "quests", "conversations", "items",
	"jobs", "courses", "programs", "activities", "actions", "phone_apps", "stores", "operations",
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
	_validate_vertical_slice_manifest()
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
