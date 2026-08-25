extends SceneTree

const ContentRegistryScript: GDScript = preload("res://src/autoload/content_registry.gd")
const NewGameStateFactoryScript: GDScript = preload("res://src/core/new_game_state_factory.gd")
const SimulationEngineScript: GDScript = preload("res://src/simulation/simulation_engine.gd")

var _failures: PackedStringArray = []
var _tests_run: int = 0
var _registry: Node


func _initialize() -> void:
	_registry = ContentRegistryScript.new()
	root.add_child(_registry)
	call_deferred("_run_all")


func _run_all() -> void:
	_test_project_configuration()
	_test_required_json_documents()
	_test_character_packages()
	_test_vertical_slice_acceptance_suite()
	_test_content_registry()
	_test_new_game_state_factory()
	_test_clock_and_simulation_engine()

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
		"res://content/opening/opening_week.json",
		"res://content/world/all_locations.json",
		"res://content/systems/economy.json",
		"res://content/systems/inventory.json",
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


func _test_content_registry() -> void:
	var errors: PackedStringArray = _registry.validate_foundation()
	_expect(errors.is_empty(), "Complete content registry validates without errors.")
	_expect(_registry.get_document_count() == 35, "Registry loads all 35 source documents.")
	_expect(_registry.get_package_count() == 18, "Registry indexes all 18 global packages.")
	_expect(_registry.get_all("locations").size() == 61, "Registry indexes all 61 locations.")
	_expect(_registry.get_all("districts").size() == 10, "Registry indexes all 10 districts.")
	_expect(_registry.get_character("elena_reyes_hale") is Dictionary, "Characters can be retrieved by id.")
	_expect(_registry.get_location("hale_home") is Dictionary, "Locations can be retrieved by id.")
	_expect(_registry.get_content("quests", "opening_future_choice") is Dictionary, "Quests can be retrieved by id.")
	_expect(_registry.get_all("operations").size() == 52, "Registry indexes all 52 simulation operations.")


func _test_new_game_state_factory() -> void:
	var factory: RefCounted = NewGameStateFactoryScript.new(_registry)
	var choices: Dictionary = {
		"first_name": "Morgan",
		"last_name": "Hale",
		"birthday": "03-17",
		"appearance": {
			"face": "face_02",
			"eye_color": "green",
			"skin_tone": "light",
			"hairstyle": "curly_01",
			"height": "tall",
			"body_type": "athletic",
		},
		"positive_traits": ["kind", "driven", "funny", "ignored_fourth"],
		"challenging_traits": ["stubborn", "anxious", "messy"],
		"financial_background": "standard_background",
	}
	var options: Dictionary = {
		"save_id": "test-save",
		"slot_id": "manual_1",
		"timestamp_utc": "2026-08-24T12:00:00Z",
		"random_seed": 12345,
	}
	var state: Dictionary = factory.create_new_game(choices, options)
	_expect(not state.is_empty(), "New-game factory creates a runtime state.")
	_expect(state["metadata"]["save_id"] == "test-save", "New-game metadata resolves save id.")
	_expect(state["player"]["identity"]["first_name"] == "Morgan", "Player identity resolves character choices.")
	_expect(state["player"]["selected_traits"]["positive"].size() == 3, "Positive trait selection is limited to three.")
	_expect(state["player"]["economy"]["accounts"]["checking"] == 625, "Financial background resolves account balances.")
	_expect(state["player"]["inventory"]["containers"].size() == 5, "Inventory containers initialize from content.")
	_expect(state["player"]["inventory"]["starting_loadout"].size() == 13, "Starting loadout resolves from financial background.")
	var initialized_stacks: int = 0
	for container: Variant in state["player"]["inventory"]["containers"]:
		initialized_stacks += container.get("items", []).size()
	_expect(initialized_stacks == 13, "Starting items are distributed into accessible storage containers.")
	_expect(state["relationships"].size() == 15, "Relationship defaults initialize for every opening character.")
	_expect(state["world_state"]["weather"]["condition"] == "partly_cloudy", "Opening weather initializes from the calendar.")
	_expect(state["content_state"]["loaded_packages"].size() == 18, "Runtime state records its loaded content manifest.")
	_expect(state["world_state"]["random_seed"] == 12345, "Runtime random seed can be reproduced.")
	_expect(not _contains_placeholder(state), "Runtime state contains no unresolved template placeholders.")
	for npc_state: Variant in state["npc_states"]:
		_expect(
			_registry.get_location(str(npc_state["current_location"])) is Dictionary,
			"NPC starts at a registered location: %s" % npc_state["character_id"]
		)


func _test_clock_and_simulation_engine() -> void:
	var factory: RefCounted = NewGameStateFactoryScript.new(_registry)
	var engine: RefCounted = SimulationEngineScript.new(_registry)
	var state: Dictionary = factory.create_new_game({}, {"random_seed": 44, "save_id": "simulation-test"})

	var initial_hunger: float = state["player"]["needs"]["hunger"]
	var result: Dictionary = engine.apply_operation(state, "time.advance", {"blocks": 1}, "test.clock")
	_expect(result.get("ok", false), "Clock advances by a complete activity block.")
	state = result["state"]
	_expect(state["clock"]["block"] == "morning", "Early Morning advances to Morning.")
	_expect(state["clock"]["minute_within_block"] == 0, "Block advance starts at minute zero.")
	_expect(state["player"]["needs"]["hunger"] > initial_hunger, "Time passage applies passive need changes.")

	result = engine.apply_operation(state, "time.advance", {"minutes": 60}, "test.short_action")
	state = result["state"]
	_expect(state["clock"]["block"] == "morning" and state["clock"]["minute_within_block"] == 60, "Short actions consume minutes inside a block.")

	result = engine.apply_operation(state, "need.adjust", {"need": "hygiene", "amount": 1000}, "test.shower")
	state = result["state"]
	_expect(state["player"]["needs"]["hygiene"] == 100.0, "Needs clamp at 100.")
	result = engine.apply_operation(state, "attribute.adjust", {"attribute": "strength", "amount": 300}, "test.workout")
	state = result["state"]
	_expect(state["player"]["attributes"]["strength"] == 250.0, "Attributes clamp at level 250.")

	result = engine.apply_operation(state, "skill.add_experience", {"skill": "cooking", "experience": 200, "activity_difficulty": 10}, "test.cooking")
	state = result["state"]
	_expect(state["player"]["skills"]["cooking"] == 1, "Progressive skill experience raises levels.")
	_expect(state["player"]["skill_experience"]["cooking"] == 100.0, "Unused skill experience carries toward the next level.")
	state["player"]["skills"]["cooking"] = 249
	state["player"]["skill_experience"]["cooking"] = 0
	result = engine.apply_operation(state, "skill.add_experience", {"skill": "cooking", "experience": 100000, "activity_difficulty": 250}, "test.mastery_gate")
	state = result["state"]
	_expect(state["player"]["skills"]["cooking"] == 249, "Level 250 remains locked without a mastery challenge.")
	result = engine.apply_operation(state, "skill.add_experience", {"skill": "cooking", "experience": 100000, "activity_difficulty": 250, "mastery_completed": true}, "test.mastery")
	state = result["state"]
	_expect(state["player"]["skills"]["cooking"] == 250, "A completed mastery challenge can award level 250.")

	var original_love: float = state["relationships"]["emma_rowan"]["love"]
	result = engine.apply_operation(state, "relationship.adjust_meter", {"character_id": "emma_rowan", "meter": "love", "amount": 7, "reason": "test"}, "test.relationship")
	state = result["state"]
	_expect(state["relationships"]["emma_rowan"]["love"] == original_love + 7.0, "Relationship meters change through atomic events.")

	result = engine.apply_operation(state, "economy.transaction", {"account": "checking", "amount": -100, "type": "debit", "category": "test", "description": "Test purchase"}, "test.purchase")
	state = result["state"]
	_expect(state["player"]["economy"]["accounts"]["checking"] == 525.0, "Transactions update account balances.")
	_expect(state["player"]["economy"]["ledger"].size() == 1, "Transactions append ledger entries.")
	var balance_before_rejection: float = state["player"]["economy"]["accounts"]["checking"]
	result = engine.apply_operation(state, "economy.transaction", {"account": "checking", "amount": -9999}, "test.rejected_purchase")
	_expect(not result.get("ok", true), "Insufficient-funds transactions are rejected.")
	_expect(state["player"]["economy"]["accounts"]["checking"] == balance_before_rejection, "Rejected operations do not mutate the source state.")

	result = engine.apply_operation(state, "inventory.remove", {"container_id": "wardrobe_storage", "item_id": "shirt_basic_white", "quantity": 1}, "test.wardrobe")
	state = result["state"]
	_expect(result.get("ok", false), "Owned inventory can be removed from a container.")
	result = engine.apply_operation(state, "inventory.add", {"container_id": "carried_inventory", "item_id": "shirt_basic_white", "quantity": 1, "item_state": {}}, "test.wardrobe")
	state = result["state"]
	_expect(result.get("ok", false), "Known inventory can be added to a container.")
	result = engine.apply_operation(state, "inventory.add", {"container_id": "carried_inventory", "item_id": "drink_water_bottle", "quantity": 100}, "test.over_capacity")
	_expect(not result.get("ok", true), "Inventory additions that exceed container capacity are rejected.")

	result = engine.apply_operation(state, "quest.start", {"quest_id": "enroll_at_westshore"}, "test.quest")
	state = result["state"]
	_expect("enroll_at_westshore" in state["quest_state"]["active"], "A known quest can be started.")
	result = engine.apply_operation(state, "quest.objective_complete", {"quest_id": "enroll_at_westshore", "objective_id": "travel_to_administration"}, "test.quest")
	state = result["state"]
	_expect(state["quest_state"]["objectives"]["enroll_at_westshore"]["travel_to_administration"], "A valid active quest objective can complete.")

	result = engine.apply_operation(state, "world.unlock_location", {"location_id": "westshore_administration_office"}, "test.map")
	state = result["state"]
	_expect("westshore_administration_office" in state["world_state"]["unlocked_locations"], "A registered location can be unlocked.")
	result = engine.apply_operation(state, "travel.complete", {"destination": "westshore_administration_office.reception", "minutes": 30, "delay": 5, "cost": 2.5, "account": "wallet_cash"}, "test.travel")
	state = result["state"]
	_expect(state["world_state"]["current_location"] == "westshore_administration_office.reception", "Travel changes the current room.")
	_expect(state["player"]["economy"]["accounts"]["wallet_cash"] == 72.5, "Travel charges its declared cost.")
	result = engine.apply_operation(state, "travel.complete", {"destination": "westshore_administration_office.missing_room", "minutes": 10}, "test.invalid_travel")
	_expect(not result.get("ok", true), "Travel rejects rooms missing from the destination registry.")

	var calendar_state: Dictionary = factory.create_new_game({}, {"random_seed": 55})
	result = engine.apply_operation(calendar_state, "time.advance", {"blocks": 7}, "test.day_rollover")
	calendar_state = result["state"]
	_expect(calendar_state["clock"]["day"] == 21 and calendar_state["clock"]["weekday"] == "wednesday", "Seven blocks advance to the next calendar day.")
	_expect(calendar_state["simulation"]["last_daily_tick"] == "Y1-08-21", "Day rollover records the daily tick.")
	calendar_state["clock"].merge({"month": 8, "day": 31, "weekday": "sunday", "block": "night", "minute_within_block": 0}, true)
	result = engine.apply_operation(calendar_state, "time.advance", {"blocks": 1}, "test.month_rollover")
	calendar_state = result["state"]
	_expect(calendar_state["clock"]["month"] == 9 and calendar_state["clock"]["day"] == 1, "Month rollover uses the real calendar.")
	_expect(calendar_state["clock"]["season"] == "autumn", "September changes the season to autumn.")
	_expect(calendar_state["clock"]["week_number"] == 2, "Sunday rollover increments the game week.")
	_expect(calendar_state["simulation"]["last_monthly_tick"] == "Y1-09", "Month rollover records the monthly tick.")
	_expect(calendar_state["simulation"]["last_weekly_tick"] == 2, "Week rollover records the weekly tick.")

	_expect(state["simulation"]["recent_event_log"].size() == state["simulation"]["next_event_sequence"] - 1, "Successful operations produce one monotonic event each.")


func _contains_placeholder(value: Variant) -> bool:
	if value is String:
		return value.begins_with("$")
	if value is Array:
		for child: Variant in value:
			if _contains_placeholder(child):
				return true
	if value is Dictionary:
		for child: Variant in value.values():
			if _contains_placeholder(child):
				return true
	return false


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
