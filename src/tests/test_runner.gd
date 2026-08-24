extends SceneTree

var _failures: PackedStringArray = []
var _tests_run: int = 0


func _initialize() -> void:
	call_deferred("_run_all")


func _run_all() -> void:
	_test_project_configuration()
	_test_required_json_documents()
	_test_character_packages()
	_test_vertical_slice_acceptance_suite()

	if _failures.is_empty():
		print("PASS: %d foundation tests completed." % _tests_run)
		quit(0)
		return

	printerr("FAIL: %d of %d foundation tests failed:" % [_failures.size(), _tests_run])
	for failure: String in _failures:
		printerr("- %s" % failure)
	quit(1)


func _test_project_configuration() -> void:
	_expect(
		ProjectSettings.get_setting("application/run/main_scene", "") == "res://scenes/boot/boot.tscn",
		"Boot scene is configured as the main scene."
	)
	_expect(InputMap.has_action("interact"), "Interact input action exists.")
	_expect(InputMap.has_action("phone"), "Phone input action exists.")
	_expect(InputMap.has_action("quest_tracker"), "Quest tracker input action exists.")
	_expect(InputMap.has_action("city_map"), "City map input action exists.")


func _test_required_json_documents() -> void:
	var paths: PackedStringArray = [
		"res://content/vertical_slice/manifest.json",
		"res://content/runtime/new_game_state.json",
		"res://content/systems/simulation_events.json",
		"res://content/systems/save_system.json",
		"res://schemas/save_game.schema.json",
	]
	for path: String in paths:
		var document: Variant = _parse_json(path)
		_expect(document is Dictionary, "JSON object parses: %s" % path)


func _test_character_packages() -> void:
	var directory: DirAccess = DirAccess.open("res://characters")
	_expect(directory != null, "Character directory opens.")
	if directory == null:
		return

	var ids: Dictionary = {}
	var count: int = 0
	directory.list_dir_begin()
	var file_name: String = directory.get_next()
	while not file_name.is_empty():
		if not directory.current_is_dir() and file_name.get_extension() == "character":
			count += 1
			var document: Variant = _parse_json("res://characters/%s" % file_name)
			if document is Dictionary:
				var character_id: String = str(document.get("id", ""))
				_expect(not character_id.is_empty(), "%s has a character id." % file_name)
				_expect(not ids.has(character_id), "Character id is unique: %s" % character_id)
				ids[character_id] = true
		file_name = directory.get_next()
	directory.list_dir_end()
	_expect(count == 15, "Exactly 15 opening character packages load.")


func _test_vertical_slice_acceptance_suite() -> void:
	var path: String = "res://tests/acceptance/vertical_slice.json"
	var suite: Variant = _parse_json(path)
	_expect(suite is Dictionary, "Acceptance suite parses.")
	if not suite is Dictionary:
		return

	var tests: Array = suite.get("tests", [])
	_expect(tests.size() == 53, "Acceptance suite contains 53 cases.")
	var ids: Dictionary = {}
	for test_case: Variant in tests:
		if test_case is Dictionary:
			var test_id: String = str(test_case.get("id", ""))
			_expect(not test_id.is_empty(), "Acceptance test has an id.")
			_expect(not ids.has(test_id), "Acceptance test id is unique: %s" % test_id)
			ids[test_id] = true


func _parse_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var json: JSON = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return null
	return json.data


func _expect(condition: bool, description: String) -> void:
	_tests_run += 1
	if not condition:
		_failures.append(description)

