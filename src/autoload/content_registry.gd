extends Node

signal validation_completed(errors: PackedStringArray)

var _documents: Dictionary = {}
var _last_errors: PackedStringArray = []


func validate_foundation() -> PackedStringArray:
	_documents.clear()
	_last_errors.clear()

	for path: String in AppConstants.REQUIRED_FOUNDATION_FILES:
		_load_json_document(path)

	_validate_character_packages()
	_validate_vertical_slice_manifest()
	validation_completed.emit(_last_errors.duplicate())
	return _last_errors.duplicate()


func get_document(path: String) -> Variant:
	return _documents.get(path)


func get_last_errors() -> PackedStringArray:
	return _last_errors.duplicate()


func get_document_count() -> int:
	return _documents.size()


func _load_json_document(path: String) -> void:
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


func _validate_character_packages() -> void:
	var directory: DirAccess = DirAccess.open("res://characters")
	if directory == null:
		_last_errors.append("Missing characters directory.")
		return

	var package_count: int = 0
	var character_ids: Dictionary = {}
	directory.list_dir_begin()
	var file_name: String = directory.get_next()
	while not file_name.is_empty():
		if not directory.current_is_dir() and file_name.get_extension() == "character":
			package_count += 1
			var path: String = "res://characters/%s" % file_name
			_load_json_document(path)
			var document: Variant = _documents.get(path)
			if document is Dictionary:
				var character_id: String = str(document.get("id", ""))
				if character_id.is_empty():
					_last_errors.append("Character package has no id: %s" % path)
				elif character_ids.has(character_id):
					_last_errors.append("Duplicate character id: %s" % character_id)
				else:
					character_ids[character_id] = path
		file_name = directory.get_next()
	directory.list_dir_end()

	if package_count != 15:
		_last_errors.append("Expected 15 opening character packages; found %d." % package_count)


func _validate_vertical_slice_manifest() -> void:
	var path: String = "res://content/vertical_slice/manifest.json"
	var manifest: Variant = _documents.get(path)
	if not manifest is Dictionary:
		return

	if int(manifest.get("format_version", 0)) != 1:
		_last_errors.append("Unsupported vertical-slice manifest version.")

	var build_name: String = str(manifest.get("build_name", ""))
	if build_name.is_empty():
		_last_errors.append("Vertical-slice manifest has no build name.")
