extends SceneTree

const ContentRegistryScript: GDScript = preload("res://src/autoload/content_registry.gd")
const NewGameStateFactoryScript: GDScript = preload("res://src/core/new_game_state_factory.gd")
const SimulationEngineScript: GDScript = preload("res://src/simulation/simulation_engine.gd")
const QuestEngineScript: GDScript = preload("res://src/quests/quest_engine.gd")
const DialogueEngineScript: GDScript = preload("res://src/dialogue/dialogue_engine.gd")
const CharacterCreationValidatorScript: GDScript = preload("res://src/creation/character_creation_validator.gd")
const HomeActionEngineScript: GDScript = preload("res://src/world/home_action_engine.gd")
const PhoneEngineScript: GDScript = preload("res://src/phone/phone_engine.gd")
const HouseholdScheduleEngineScript: GDScript = preload("res://src/world/household_schedule_engine.gd")
const TravelEngineScript: GDScript = preload("res://src/world/travel_engine.gd")
const CityActionEngineScript: GDScript = preload("res://src/world/city_action_engine.gd")

var _failures: PackedStringArray = []
var _tests_run: int = 0
var _registry: Node


func _initialize() -> void:
	_registry = ContentRegistryScript.new()
	root.add_child(_registry)
	call_deferred("_run_all")


func _run_all() -> void:
	_test_project_configuration()
	_test_dialogue_ui_scenes()
	_test_character_creation_scene()
	_test_hale_home_scene()
	_test_required_json_documents()
	_test_character_packages()
	_test_vertical_slice_acceptance_suite()
	_test_content_registry()
	_test_new_game_state_factory()
	_test_character_creation_validation()
	_test_clock_and_simulation_engine()
	_test_home_actions_and_wardrobe()
	_test_household_schedules_and_conversations()
	_test_city_travel_and_routes()
	_test_city_institutions_and_fitness()
	_test_phone_messages_and_calendar()
	_test_opening_dialogue_branches()

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
	_expect(ProjectSettings.has_setting("autoload/PhoneService"), "Phone service is configured as an autoload.")
	_expect(ProjectSettings.has_setting("autoload/TravelService"), "Travel service is configured as an autoload.")
	_expect(ProjectSettings.has_setting("autoload/CityActionService"), "City action service is configured as an autoload.")


func _test_required_json_documents() -> void:
	var paths: PackedStringArray = [
		"res://content/vertical_slice/manifest.json",
		"res://content/runtime/new_game_state.json",
		"res://content/systems/character_creation.json",
		"res://content/systems/home_interactions.json",
		"res://content/systems/city_interactions.json",
		"res://content/systems/phone.json",
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


func _test_dialogue_ui_scenes() -> void:
	_expect(ProjectSettings.has_setting("autoload/DialogueService"), "Dialogue service is configured as an autoload.")
	_expect(ProjectSettings.has_setting("autoload/QuestService"), "Quest service is configured as an autoload.")
	var dialogue_scene: PackedScene = load("res://scenes/dialogue/vn_dialogue.tscn")
	_expect(dialogue_scene != null, "VN dialogue scene loads.")
	if dialogue_scene != null:
		var dialogue_instance: Node = dialogue_scene.instantiate()
		_expect(dialogue_instance.get_node_or_null("DialogueMargin/DialoguePanel/PanelMargin/DialogueContent/SpeakerLabel") != null, "VN scene contains a speaker label.")
		_expect(dialogue_instance.get_node_or_null("DialogueMargin/DialoguePanel/PanelMargin/DialogueContent/ChoicesBox") != null, "VN scene contains dynamic dialogue choices.")
		dialogue_instance.free()


func _test_hale_home_scene() -> void:
	var phone_scene: PackedScene = load("res://scenes/phone/smartphone.tscn")
	_expect(phone_scene != null, "Reusable smartphone scene loads.")
	if phone_scene != null:
		var phone_instance: Node = phone_scene.instantiate()
		_expect(phone_instance.get_node_or_null("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/Navigation/NavMargin/NavScroll/AppButtons") != null, "Phone scene contains its reusable app navigation.")
		_expect(phone_instance.get_node_or_null("SchedulerPanel/Margin/Layout/ContactOption") != null, "Phone scene contains its calendar scheduler.")
		_expect(phone_instance.get_node_or_null("RoutePanel/Margin/Layout/RouteOption") != null, "Phone scene contains its route confirmation panel.")
		phone_instance.free()
	var home_scene: PackedScene = load("res://scenes/locations/hale_home.tscn")
	_expect(home_scene != null, "Playable Hale home scene loads.")
	_expect(AppConstants.SANDBOX_SCENE == AppConstants.HALE_HOME_SCENE, "The opening enters the Hale home sandbox.")
	if home_scene == null:
		return
	var instance: Node = home_scene.instantiate()
	_expect(instance.get_node_or_null("Player") != null, "Hale home contains a collision-enabled player.")
	_expect(instance.get_node_or_null("HouseholdActors") != null, "Hale home contains a reusable household actor layer.")
	_expect(instance.get_node_or_null("Interface/TopMargin/TopLayout/Header/RoomLabel") != null, "Hale home contains its room HUD.")
	_expect(instance.get_node_or_null("Interface/ActionPanel") != null, "Hale home contains the home-action panel.")
	_expect(instance.get_node_or_null("Interface/WardrobePanel") != null, "Hale home contains the wardrobe panel.")
	_expect(instance.get_node_or_null("Interface/QuestPanel") != null, "Hale home retains the quest tracker.")
	_expect(instance.get_node_or_null("Interface/Smartphone") != null, "Hale home contains the reusable smartphone.")
	instance.free()
	var actor_scene: PackedScene = load("res://scenes/world/household_npc_actor.tscn")
	_expect(actor_scene != null, "Reusable household NPC actor scene loads.")
	var city_scene: PackedScene = load("res://scenes/locations/city_location.tscn")
	_expect(city_scene != null, "Reusable city destination scene loads.")
	if city_scene != null:
		var city_instance: Node = city_scene.instantiate()
		_expect(city_instance.get_node_or_null("Player") != null, "City destination scene contains the top-down player.")
		_expect(city_instance.get_node_or_null("Interface/Smartphone") != null, "City destination scene contains the reusable smartphone.")
		_expect(city_instance.get_node_or_null("Interface/ActionPanel") != null, "City destination scene contains its room activity panel.")
		city_instance.free()


func _test_household_schedules_and_conversations() -> void:
	var factory: RefCounted = NewGameStateFactoryScript.new(_registry)
	var simulation: RefCounted = SimulationEngineScript.new(_registry)
	var quests: RefCounted = QuestEngineScript.new(_registry, simulation)
	var dialogue: RefCounted = DialogueEngineScript.new(_registry, simulation, quests)
	var schedules: RefCounted = HouseholdScheduleEngineScript.new(_registry)
	var state: Dictionary = factory.create_new_game({}, {"random_seed": 412})

	var elena: Dictionary = schedules.resolve_character(state, "elena_reyes_hale")
	var daniel: Dictionary = schedules.resolve_character(state, "daniel_hale")
	var lily: Dictionary = schedules.resolve_character(state, "lily_hale")
	_expect(not elena["present"] and elena["location"] == "st_maren_community_clinic", "Elena is at her clinic during Tuesday Morning.")
	_expect(not daniel["present"] and daniel["location"] == "port_alder_transit_depot", "Daniel is at the transit depot during Tuesday Morning.")
	_expect(lily["present"] and lily["room"] == "living_room", "Lily is physically present in the living room Tuesday Morning.")

	var result: Dictionary = quests.complete_quest(state, "opening_future_choice", "test.household_opening_complete")
	_expect(result.get("ok", false), "Completing the opening quest synchronizes immediate character-story activations.")
	state = result["state"]
	_expect("under_this_roof" in state["quest_state"]["active"], "Elena's household quest activates after the opening.")
	_expect("one_year_ahead" not in state["quest_state"]["active"], "Lily's quest waits until its authored earliest block.")
	_expect("a_quiet_check_in" not in state["quest_state"]["active"], "Daniel's quest waits until Evening.")

	state["clock"]["block"] = "lunch"
	result = quests.sync_automatic_activations(state, "test.household_lunch")
	state = result["state"]
	_expect("one_year_ahead" in state["quest_state"]["active"], "Lily's story quest activates at Lunch.")
	lily = schedules.resolve_character(state, "lily_hale")
	_expect(lily["present"] and lily["room"] == "kitchen", "Lily moves to the kitchen for her Lunch story scene.")
	state["world_state"]["current_location"] = "hale_home.kitchen"
	_expect(dialogue.can_begin(state, "lily_program_doubts")["ok"], "Lily's program conversation is available beside her in the kitchen.")

	state["clock"]["block"] = "evening"
	result = quests.sync_automatic_activations(state, "test.household_evening")
	state = result["state"]
	_expect("a_quiet_check_in" in state["quest_state"]["active"], "Daniel's first story quest activates at Evening.")
	elena = schedules.resolve_character(state, "elena_reyes_hale")
	daniel = schedules.resolve_character(state, "daniel_hale")
	lily = schedules.resolve_character(state, "lily_hale")
	_expect(elena["present"] and elena["room"] == "kitchen", "Elena returns home to the kitchen Tuesday Evening.")
	_expect(daniel["present"] and daniel["room"] == "living_room", "Daniel returns home to the living room Tuesday Evening.")
	_expect(not lily["present"] and lily["location"] == "westshore_campus", "Lily is unavailable during her Tuesday Evening library shift.")
	state["world_state"]["current_location"] = "hale_home.living_room"
	_expect(dialogue.can_begin(state, "daniel_quiet_check_in")["ok"], "Daniel's quiet check-in is available in the living room.")
	state["world_state"]["current_location"] = "hale_home.kitchen"
	_expect(dialogue.can_begin(state, "household_rules_talk")["ok"], "A home-wide location requirement accepts Elena's specific kitchen room.")

	result = schedules.synchronize_npc_states(state, ["elena_reyes_hale", "daniel_hale", "lily_hale"])
	_expect(result["changed"], "Schedule synchronization updates persistent NPC locations.")
	state = result["state"]
	_expect(_npc_location(state, "daniel_hale") == "hale_home.living_room", "Daniel's live NPC state records his current home room.")


func _test_city_travel_and_routes() -> void:
	var factory: RefCounted = NewGameStateFactoryScript.new(_registry)
	var simulation: RefCounted = SimulationEngineScript.new(_registry)
	var quests: RefCounted = QuestEngineScript.new(_registry, simulation)
	var travel: RefCounted = TravelEngineScript.new(_registry, simulation, quests)
	var state: Dictionary = factory.create_new_game({}, {"random_seed": 712})
	_expect(state["world_state"]["unlocked_locations"].size() == 9, "New games unlock the nine connected opening destinations.")

	var plan: Dictionary = travel.plan_routes(state, "westshore_administration_office")
	_expect(plan.get("ok", false), "The route planner connects Hale Home to Westshore Administration.")
	_expect(plan.get("options", []).size() == 4, "Westshore Administration offers walking, bus, taxi, and car comparisons.")
	var bus_route: Dictionary = _route_option(plan, "bus")
	_expect(bus_route["minutes"] == 32 and bus_route["cost"] == 3.0, "Bus planning includes the Morning wait and authored fare.")
	_expect(_route_option(plan, "walking")["minutes"] == 48, "Walking uses its authored forty-eight-minute route.")

	var closed_plan: Dictionary = travel.plan_routes(state, "harborlight_cinema")
	_expect(closed_plan.get("ok", false), "Closed destinations still expose route comparisons.")
	_expect(not _route_option(closed_plan, "walking")["available"], "Cinema travel is blocked while the destination is closed Tuesday Morning.")
	_expect("Next opening:" in str(_route_option(closed_plan, "walking")["reason"]), "Closed route details identify the destination's next opening block.")

	plan = travel.plan_routes(state, "alder_bay_park")
	_expect(not _route_option(plan, "car")["available"], "Shared family-car travel requires permission for the current day.")
	state["world_state"]["world_flags"]["family_car_permission_date"] = "Y1-08-20"
	plan = travel.plan_routes(state, "alder_bay_park")
	_expect(_route_option(plan, "car")["available"], "Daily family-car permission enables driving routes.")
	state["player"]["needs"]["inebriation"] = 30
	plan = travel.plan_routes(state, "alder_bay_park")
	_expect(not _route_option(plan, "car")["available"] and "impaired" in str(_route_option(plan, "car")["reason"]), "Car travel is blocked while the player is impaired.")
	state["player"]["needs"]["inebriation"] = 0

	var result: Dictionary = quests.start_quest(state, "enroll_at_westshore", "test.travel_quest")
	state = result["state"]
	result = travel.execute_travel(state, "westshore_administration_office", "walking", "test.travel")
	_expect(result.get("ok", false), "A confirmed walking route completes atomically.")
	state = result["state"]
	_expect(state["world_state"]["current_location"] == "westshore_administration_office.reception", "Travel arrives in the destination's first accessible room.")
	_expect(state["world_state"]["pending_travel"] == null, "Completed travel clears the pending trip.")
	_expect(state["world_state"]["last_trip"]["mode"] == "walking", "Travel records a durable last-trip summary.")
	_expect(state["quest_state"]["objectives"]["enroll_at_westshore"]["travel_to_administration"], "Arriving at Administration completes its active quest objective.")
	plan = travel.plan_routes(state, "hale_home")
	_expect(plan.get("ok", false) and _route_option(plan, "walking")["minutes"] == 48, "Authored routes work in reverse back to Hale Home.")

	state = factory.create_new_game({}, {"random_seed": 713})
	result = travel.start_transportation_tutorial(state, "test.first_exit")
	state = result["state"]
	result = travel.record_map_viewed(state, "test.map")
	state = result["state"]
	result = travel.record_routes_viewed(state, "westshore_campus", ["walking", "bus", "taxi", "car"], "test.routes")
	state = result["state"]
	result = travel.execute_travel(state, "westshore_campus", "bus", "test.bus")
	_expect(result.get("ok", false), "The transportation tutorial accepts a confirmed bus trip.")
	state = result["state"]
	_expect("getting_around_port_alder" in state["quest_state"]["completed"], "Viewing routes and taking the bus completes transportation onboarding.")
	_expect("transportation" in state["player"]["phone"]["unlocked_apps"], "Transportation onboarding unlocks its future phone app.")


func _test_city_institutions_and_fitness() -> void:
	var factory: RefCounted = NewGameStateFactoryScript.new(_registry)
	var simulation: RefCounted = SimulationEngineScript.new(_registry)
	var quests: RefCounted = QuestEngineScript.new(_registry, simulation)
	var dialogue: RefCounted = DialogueEngineScript.new(_registry, simulation, quests)
	var city_actions: RefCounted = CityActionEngineScript.new(_registry, simulation, quests)
	var state: Dictionary = factory.create_new_game({}, {"random_seed": 814})

	var result: Dictionary = quests.start_quest(state, "enroll_at_westshore", "test.enrollment")
	state = result["state"]
	state["world_state"]["current_location"] = "westshore_administration_office.advisor_office"
	result = quests.record_event(state, "location_entered", {"location": "westshore_administration_office"}, "test.enrollment")
	state = result["state"]
	result = dialogue.begin(state, "westshore_enrollment_advisor")
	state = result["state"]
	result = dialogue.advance(state)
	state = result["state"]
	result = dialogue.choose(state, "ready")
	state = result["state"]
	result = dialogue.choose(state, "computers")
	state = result["state"]
	result = dialogue.advance(state)
	state = result["state"]
	result = dialogue.choose(state, "full_time")
	state = result["state"]
	result = dialogue.advance(state)
	state = result["state"]
	result = dialogue.choose(state, "loan")
	_expect(result.get("ok", false), "Westshore's full enrollment conversation reaches schedule confirmation.")
	state = result["state"]
	_expect(state["player"]["education"]["enrolled"], "Enrollment records Westshore as the active institution.")
	_expect(state["player"]["education"]["courses"].size() == 4, "Full-time enrollment selects four first-semester courses.")
	_expect(state["calendar_state"]["events"].size() > 50, "Enrollment creates the semester's recurring class calendar events.")
	_expect("enroll_at_westshore" in state["quest_state"]["completed"], "Authored enrollment events complete every enrollment objective.")
	_expect(state["player"]["education"]["student_debt"] == 4000.0, "The student-loan tuition choice records education debt.")
	_expect("education" in state["player"]["phone"]["unlocked_apps"], "Completing enrollment unlocks the Education phone app.")
	result = dialogue.advance(state)
	_expect(result.get("ok", false) and result.get("ended", false), "The enrollment VN scene closes normally after state changes.")

	state = factory.create_new_game({}, {"random_seed": 817})
	result = quests.start_quest(state, "enroll_at_westshore", "test.part_time_enrollment")
	state = result["state"]
	state["world_state"]["current_location"] = "westshore_administration_office.advisor_office"
	result = quests.record_event(state, "location_entered", {"location": "westshore_administration_office"}, "test.part_time_enrollment")
	state = result["state"]
	result = dialogue.begin(state, "westshore_enrollment_advisor")
	state = result["state"]
	result = dialogue.advance(state)
	state = result["state"]
	result = dialogue.choose(state, "ready")
	state = result["state"]
	result = dialogue.choose(state, "arts")
	state = result["state"]
	result = dialogue.advance(state)
	state = result["state"]
	result = dialogue.choose(state, "part_time")
	state = result["state"]
	result = dialogue.advance(state)
	state = result["state"]
	result = dialogue.choose(state, "loan_part_time")
	_expect(result.get("ok", false), "The advisor provides the separate part-time tuition path.")
	state = result["state"]
	_expect(state["player"]["education"]["courses"].size() == 2 and state["player"]["education"]["student_debt"] == 2200.0, "Part-time enrollment selects two courses and records the lower tuition amount.")

	state = factory.create_new_game({}, {"random_seed": 815})
	result = quests.start_quest(state, "find_employment", "test.employment")
	state = result["state"]
	state["world_state"]["current_location"] = "harbor_employment_centre.counselor_desk"
	result = dialogue.begin(state, "harbor_employment_orientation")
	state = result["state"]
	result = dialogue.advance(state)
	state = result["state"]
	result = dialogue.choose(state, "full_time")
	state = result["state"]
	_expect(state["quest_state"]["objectives"]["find_employment"]["open_jobs"], "Employment orientation completes the job-board onboarding objective.")
	result = dialogue.advance(state)
	state = result["state"]
	_expect(result.get("ended", false), "Employment orientation closes before returning to the job floor.")
	state["world_state"]["current_location"] = "harbor_employment_centre.job_floor"
	result = city_actions.perform_activity(state, "browse_harbor_job_board")
	_expect(result.get("ok", false), "The Harbor job board is a playable timed activity.")
	state = result["state"]
	_expect(state["player"]["employment"]["discovered_jobs"].size() == 4, "Browsing stores four discovered entry-level jobs.")
	_expect(state["quest_state"]["objectives"]["find_employment"]["review_requirements"], "Reviewing four jobs advances the full-time employment quest.")

	state = factory.create_new_game({}, {"random_seed": 816})
	state["world_state"]["current_location"] = "forge_fitness.front_desk"
	result = quests.record_event(state, "location_discovered", {"location": "forge_fitness"}, "test.forge")
	state = result["state"]
	_expect("first_rep" in state["quest_state"]["active"], "Discovering Forge Fitness activates Rachel's First Rep quest.")
	result = dialogue.begin(state, "rachel_fitness_assessment")
	state = result["state"]
	_expect(state["quest_state"]["objectives"]["first_rep"]["visit_gym"], "Beginning Rachel's scene records the first NPC encounter.")
	result = dialogue.advance(state)
	state = result["state"]
	result = dialogue.advance(state)
	state = result["state"]
	result = dialogue.choose(state, "honest")
	state = result["state"]
	result = dialogue.advance(state)
	state = result["state"]
	result = dialogue.choose(state, "disclose")
	state = result["state"]
	result = dialogue.advance(state)
	state = result["state"]
	result = dialogue.choose(state, "balanced")
	_expect(result.get("ok", false), "Rachel's fitness assessment accepts a balanced training goal.")
	state = result["state"]
	_expect(bool(state["player"]["flags"].get("fitness.gym_access", false)), "Rachel's completed assessment grants gym access.")
	_expect(_calendar_template_exists(state, "beginner_forge_workout"), "Rachel adds a usable beginner workout to the calendar.")
	result = dialogue.advance(state)
	state = result["state"]
	state["world_state"]["current_location"] = "forge_fitness.strength_floor"
	var strength_before: float = state["player"]["attributes"]["strength"]
	result = city_actions.perform_activity(state, "beginner_forge_workout")
	_expect(result.get("ok", false), "Rachel's beginner workout can be completed on the gym floor.")
	state = result["state"]
	_expect(state["player"]["attributes"]["strength"] > strength_before, "The beginner workout increases physical attributes.")
	_expect("first_rep" in state["quest_state"]["completed"], "Completing the workout finishes Rachel's First Rep quest.")
	_expect(int(state["relationships"]["rachel_morgan"].get("unlocked_chapter_level", 0)) == 2, "First Rep unlocks Rachel's second relationship chapter.")


func _test_character_creation_scene() -> void:
	var creation_scene: PackedScene = load("res://scenes/creation/character_creation.tscn")
	_expect(creation_scene != null, "Character creation scene loads.")
	if creation_scene == null:
		return
	var instance: Node = creation_scene.instantiate()
	_expect(instance.get_node_or_null("PageMargin/Page/CreationTabs/Identity/Fields/FirstName") != null, "Creation scene contains identity fields.")
	_expect(instance.get_node_or_null("PageMargin/Page/CreationTabs/Appearance/Fields/Grid/FaceOption") != null, "Creation scene contains appearance options.")
	_expect(instance.get_node_or_null("PageMargin/Page/CreationTabs/Traits/Scroll/Fields/PositiveOptions") != null, "Creation scene contains trait selection.")
	_expect(instance.get_node_or_null("PageMargin/Page/CreationTabs/BackgroundAndReview/Columns/ReviewText") != null, "Creation scene contains confirmation review.")
	instance.free()


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
	_expect(_registry.get_document_count() == 39, "Registry loads all 39 source documents.")
	_expect(_registry.get_package_count() == 22, "Registry indexes all 22 global packages.")
	_expect(_registry.get_all("locations").size() == 61, "Registry indexes all 61 locations.")
	_expect(_registry.get_all("districts").size() == 10, "Registry indexes all 10 districts.")
	_expect(_registry.get_character("elena_reyes_hale") is Dictionary, "Characters can be retrieved by id.")
	_expect(_registry.get_location("hale_home") is Dictionary, "Locations can be retrieved by id.")
	_expect(_registry.get_content("quests", "opening_future_choice") is Dictionary, "Quests can be retrieved by id.")
	_expect(_registry.get_all("operations").size() == 55, "Registry indexes all 55 simulation operations.")
	_expect(_registry.get_all("actions").size() == 10, "Registry indexes all 10 initial home actions.")
	_expect(_registry.get_all("city_interactions").size() == 9, "Registry indexes all nine opening city interactions.")
	_expect(_registry.get_all("phone_apps").size() == 9, "Registry indexes all nine required phone apps.")


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
	_expect(initialized_stacks == 16, "Starting items and shared Hale household supplies initialize in storage.")
	_expect(_stack_quantity(state, "kitchen_storage", "drink_water_bottle") == 6, "The family kitchen adds water to the player's starting supply.")
	_expect(_stack_quantity(state, "kitchen_storage", "food_pasta_ingredients") == 2, "The family kitchen starts with two cookable meals.")
	_expect(state["player"]["inventory"]["equipped_outfit"].get("shirt") == "shirt_basic_white", "A playable default outfit is equipped at new-game creation.")
	_expect(state["player"]["phone"]["message_threads"].size() == 5, "New-game phone state creates one thread per known contact.")
	_expect("weather" in state["player"]["phone"]["unlocked_apps"], "The weather app is available from the start.")
	_expect(state["relationships"].size() == 15, "Relationship defaults initialize for every opening character.")
	_expect(state["world_state"]["weather"]["condition"] == "partly_cloudy", "Opening weather initializes from the calendar.")
	_expect(state["content_state"]["loaded_packages"].size() == 22, "Runtime state records its loaded content manifest.")
	_expect(state["world_state"]["random_seed"] == 12345, "Runtime random seed can be reproduced.")
	_expect(not _contains_placeholder(state), "Runtime state contains no unresolved template placeholders.")
	for npc_state: Variant in state["npc_states"]:
		_expect(
			_registry.get_location(str(npc_state["current_location"])) is Dictionary,
			"NPC starts at a registered location: %s" % npc_state["character_id"]
		)


func _test_character_creation_validation() -> void:
	var validator: RefCounted = CharacterCreationValidatorScript.new(_registry)
	var missing: Dictionary = validator.validate_choices({})
	_expect(not missing["valid"], "Incomplete character creation is rejected.")
	_expect(missing["fields"].has("first_name") and missing["fields"].has("financial_background"), "Incomplete creation identifies missing fields.")

	var valid_choices: Dictionary = {
		"first_name": "Morgan",
		"last_name": "Hale",
		"birth_date": "2008-03-17",
		"appearance": {
			"face": "face_02",
			"eye_color": "green",
			"skin_tone": "medium",
			"hairstyle": "curly_01",
			"height": "tall",
			"body_type": "athletic",
		},
		"positive_traits": ["kind", "driven", "funny"],
		"challenging_traits": ["anxious", "messy", "stubborn"],
		"core_values": ["family", "independence", "compassion"],
		"archetype": "the_planner",
		"hobbies": ["cooking", "fitness"],
		"financial_background": "standard_background",
	}
	var validation: Dictionary = validator.validate_choices(valid_choices)
	_expect(validation["valid"], "A complete age-18 character passes validation.")
	_expect(validator.age_on_opening_date(valid_choices["birth_date"]) == 18, "Birth date resolves to age 18 on opening day.")
	_expect(validator.birthday_from_birth_date(valid_choices["birth_date"]) == "03-17", "Birth date resolves to the annual birthday.")

	var wrong_age: Dictionary = valid_choices.duplicate(true)
	wrong_age["birth_date"] = "2009-03-17"
	validation = validator.validate_choices(wrong_age)
	_expect(not validation["valid"] and validation["fields"].has("birth_date"), "A birth date producing age 17 is rejected.")
	var too_many_traits: Dictionary = valid_choices.duplicate(true)
	too_many_traits["positive_traits"].append("reliable")
	validation = validator.validate_choices(too_many_traits)
	_expect(not validation["valid"] and validation["fields"].has("positive_traits"), "A fourth positive trait is rejected.")

	valid_choices["birthday"] = validator.birthday_from_birth_date(valid_choices["birth_date"])
	var factory: RefCounted = NewGameStateFactoryScript.new(_registry)
	var state: Dictionary = factory.create_new_game(valid_choices, {"random_seed": 101})
	_expect(state["player"]["identity"]["age"] == 18, "Created protagonist starts at age 18.")
	_expect(state["player"]["identity"]["birthday"] == "03-17", "Created protagonist stores the chosen birthday.")
	_expect(state["player"]["identity"]["gender_identity"] == "male", "Created protagonist is male.")
	_expect(state["player"]["selected_traits"]["core_values"].size() == 3, "Created protagonist stores three core values.")
	_expect(state["player"]["selected_traits"]["hobbies"].size() == 2, "Created protagonist stores two hobbies.")
	_expect(state["player"]["attributes"]["empathy"] == 48.0, "Positive trait applies its starting attribute bonus.")
	_expect(state["player"]["needs"]["stress"] == 32.0, "Challenging trait applies its starting need modifier.")
	_expect(state["player"]["economy"]["accounts"]["checking"] == 625, "Standard background initializes its checking balance.")


func _test_clock_and_simulation_engine() -> void:
	var factory: RefCounted = NewGameStateFactoryScript.new(_registry)
	var engine: RefCounted = SimulationEngineScript.new(_registry)
	var state: Dictionary = factory.create_new_game({}, {"random_seed": 44, "save_id": "simulation-test"})
	state["clock"]["block"] = "early_morning"

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


func _test_home_actions_and_wardrobe() -> void:
	var factory: RefCounted = NewGameStateFactoryScript.new(_registry)
	var simulation: RefCounted = SimulationEngineScript.new(_registry)
	var home_actions: RefCounted = HomeActionEngineScript.new(_registry, simulation)
	var state: Dictionary = factory.create_new_game({}, {"random_seed": 66, "save_id": "home-action-test"})

	var hygiene_before: float = state["player"]["needs"]["hygiene"]
	var result: Dictionary = home_actions.perform_action(state, "shower")
	_expect(result.get("ok", false), "The bathroom shower action completes.")
	state = result["state"]
	_expect(state["clock"]["minute_within_block"] == 30, "A shower consumes thirty in-game minutes.")
	_expect(state["player"]["needs"]["hygiene"] > hygiene_before, "A shower improves player hygiene.")
	_expect(result["events"].size() == 3, "A shower records each simulation operation as an event.")

	var hunger_before: float = state["player"]["needs"]["hunger"]
	result = home_actions.perform_action(state, "cook_basic_meal")
	_expect(result.get("ok", false), "A basic meal can be cooked from pantry ingredients.")
	state = result["state"]
	_expect(_stack_quantity(state, "kitchen_storage", "food_pasta_ingredients") == 1, "Cooking consumes exactly one ingredient stack unit.")
	_expect(state["player"]["needs"]["hunger"] < hunger_before, "A cooked meal relieves hunger.")
	_expect(state["player"]["skills"]["cooking"] == 1, "Cooking awards enough experience for the first cooking level.")

	result = home_actions.perform_action(state, "cook_basic_meal")
	_expect(result.get("ok", false), "The second stocked meal can be cooked.")
	state = result["state"]
	var rejected_clock: Dictionary = state["clock"].duplicate(true)
	var rejected_event_count: int = state["simulation"]["recent_event_log"].size()
	result = home_actions.perform_action(state, "cook_basic_meal")
	_expect(not result.get("ok", true), "Cooking is rejected when the pantry has no ingredients.")
	_expect(state["clock"] == rejected_clock, "A rejected multi-step home action does not consume time.")
	_expect(state["simulation"]["recent_event_log"].size() == rejected_event_count, "A rejected multi-step home action does not commit partial events.")

	_set_stack_cleanliness(state, "wardrobe_storage", "shirt_basic_white", 18)
	result = home_actions.perform_action(state, "do_laundry")
	_expect(result.get("ok", false), "Laundry completes when detergent is available.")
	state = result["state"]
	_expect(_stack_quantity(state, "garage_storage", "household_detergent") == 1, "Laundry consumes exactly one detergent unit.")
	_expect(_stack_cleanliness(state, "wardrobe_storage", "shirt_basic_white") == 100, "Laundry restores stored clothing cleanliness.")

	result = simulation.apply_operation(
		state,
		"inventory.equip",
		{"item_id": "shirt_oxford_blue", "wardrobe_slot": "shirt"},
		"test.wardrobe"
	)
	_expect(result.get("ok", false), "An owned shirt can be equipped from the wardrobe.")
	state = result["state"]
	_expect(state["player"]["inventory"]["equipped_outfit"]["shirt"] == "shirt_oxford_blue", "Equipping updates the correct outfit slot.")
	result = simulation.apply_operation(
		state,
		"inventory.equip",
		{"item_id": "shoes_dress_black", "wardrobe_slot": "shirt"},
		"test.invalid_wardrobe"
	)
	_expect(not result.get("ok", true), "Wardrobe equipment rejects a mismatched clothing slot.")
	_expect(state["player"]["inventory"]["equipped_outfit"]["shirt"] == "shirt_oxford_blue", "Rejected equipment leaves the outfit unchanged.")


func _test_phone_messages_and_calendar() -> void:
	var factory: RefCounted = NewGameStateFactoryScript.new(_registry)
	var simulation: RefCounted = SimulationEngineScript.new(_registry)
	var phone: RefCounted = PhoneEngineScript.new(_registry, simulation)
	var state: Dictionary = factory.create_new_game({}, {"random_seed": 144, "save_id": "phone-test"})
	state["player"]["flags"]["sandbox.active"] = true

	var result: Dictionary = phone.sync_triggered_messages(state)
	_expect(result.get("ok", false), "Phone synchronization loads triggered authored messages.")
	state = result["state"]
	_expect(result["events"].size() == 5, "Sandbox activation receives one authored message from each known opening contact.")
	_expect(state["player"]["phone"]["unread_threads"].size() == 5, "New incoming character messages mark all five threads unread.")
	_expect(_thread_message_count(state, "elena_reyes_hale") == 1, "Elena's authored opening phone message enters her thread.")
	result = phone.sync_triggered_messages(state)
	_expect(result.get("ok", false) and result["events"].is_empty(), "Phone trigger synchronization does not duplicate delivered messages.")
	state = result["state"]

	var comfort_before: float = state["relationships"]["elena_reyes_hale"]["comfort"]
	result = phone.reply_to_message(state, "elena_reyes_hale", "elena_phone_ready", 0)
	_expect(result.get("ok", false), "An authored quick reply can be sent from Elena's thread.")
	state = result["state"]
	_expect(state["clock"]["minute_within_block"] == 5, "Sending a phone reply consumes five in-game minutes.")
	_expect(_thread_message_count(state, "elena_reyes_hale") == 2, "The player reply is stored in the correct message thread.")
	_expect(state["relationships"]["elena_reyes_hale"]["comfort"] == comfort_before + 1.0, "A phone reply applies its authored relationship effect.")
	var event_count_before_duplicate: int = state["simulation"]["recent_event_log"].size()
	result = phone.reply_to_message(state, "elena_reyes_hale", "elena_phone_ready", 1)
	_expect(not result.get("ok", true), "The same incoming message cannot be answered twice.")
	_expect(state["simulation"]["recent_event_log"].size() == event_count_before_duplicate, "A rejected duplicate reply leaves event state unchanged.")
	result = phone.mark_thread_read(state, "elena_reyes_hale")
	_expect(result.get("ok", false), "A known phone thread can be marked read.")
	state = result["state"]
	_expect("elena_reyes_hale" not in state["player"]["phone"]["unread_threads"], "Reading a thread clears its unread marker.")

	var unavailable_plan: Dictionary = {
		"title": "Morning walk with Emma",
		"type": "hangout",
		"date": "Y1-08-20",
		"weekday": "tuesday",
		"block": "morning",
		"participants": ["emma_rowan"],
		"location": "alder_bay_park.waterfront_path",
	}
	result = simulation.apply_operation(state, "calendar.schedule", {"calendar_event": unavailable_plan}, "test.phone_calendar")
	_expect(not result.get("ok", true), "Calendar scheduling rejects an NPC's fixed school commitment.")

	var emma_plan: Dictionary = unavailable_plan.duplicate(true)
	emma_plan.merge({"title": "Evening walk with Emma", "block": "evening"}, true)
	result = simulation.apply_operation(state, "calendar.schedule", {"calendar_event": emma_plan}, "test.phone_calendar")
	_expect(result.get("ok", false), "Calendar scheduling accepts an available NPC block.")
	state = result["state"]
	_expect(state["calendar_state"]["events"].size() == 2, "A confirmed phone plan is added to the runtime calendar.")
	var emma_event_id: String = str(state["calendar_state"]["events"][-1]["id"])

	var marcus_plan: Dictionary = emma_plan.duplicate(true)
	marcus_plan["title"] = "Movie with Marcus"
	marcus_plan["type"] = "movie"
	marcus_plan["participants"] = ["marcus_lee"]
	marcus_plan["location"] = "harborlight_cinema.auditorium_1"
	result = simulation.apply_operation(state, "calendar.schedule", {"calendar_event": marcus_plan}, "test.phone_calendar")
	_expect(result.get("ok", false), "Optional plans may be double-booked with a visible warning.")
	state = result["state"]
	_expect(state["calendar_state"]["conflicts"].size() == 1, "Double-booked optional plans create a calendar conflict warning.")

	var work_plan: Dictionary = emma_plan.duplicate(true)
	work_plan["title"] = "Required shift"
	work_plan["type"] = "work"
	work_plan["participants"] = []
	result = simulation.apply_operation(state, "calendar.schedule", {"calendar_event": work_plan}, "test.phone_calendar")
	_expect(not result.get("ok", true), "Work, class, and interview conflicts block calendar confirmation.")

	result = simulation.apply_operation(state, "calendar.cancel_or_reschedule", {"event_id": emma_event_id, "cancel": true}, "test.phone_calendar")
	_expect(result.get("ok", false), "A scheduled phone plan can be cancelled.")
	state = result["state"]
	_expect(_calendar_event_status(state, emma_event_id) == "cancelled", "Calendar cancellation records the event's cancelled status.")
	_expect(state["calendar_state"]["conflicts"][0]["status"] == "resolved", "Cancelling an overlapping plan resolves its conflict warning.")

	result = simulation.apply_operation(state, "time.advance", {"blocks": 7}, "test.weather_rollover")
	_expect(result.get("ok", false), "Phone test clock advances into the next opening-week day.")
	state = result["state"]
	_expect(state["clock"]["day"] == 21, "Seven activity-block advances cross into Wednesday from the current morning block.")
	_expect(state["world_state"]["weather"]["condition"] == "rain", "Day advancement loads Wednesday's authored rain forecast into live state.")


func _test_opening_dialogue_branches() -> void:
	var factory: RefCounted = NewGameStateFactoryScript.new(_registry)
	var simulation: RefCounted = SimulationEngineScript.new(_registry)
	var quests: RefCounted = QuestEngineScript.new(_registry, simulation)
	var dialogue: RefCounted = DialogueEngineScript.new(_registry, simulation, quests)

	var state: Dictionary = factory.create_new_game({"first_name": "Morgan"}, {"random_seed": 77})
	_expect(state["clock"]["block"] == "morning", "A new game begins Tuesday Morning for Elena's scene.")
	_expect("quests" not in state["player"]["phone"]["unlocked_apps"], "Quest tracker begins locked.")
	var result: Dictionary = dialogue.begin(state, "opening_future_talk")
	_expect(result.get("ok", false), "Elena's opening conversation begins from content.")
	state = result["state"]
	_expect(result["view"]["node_id"] == "door_opens", "Opening scene begins with Elena entering the bedroom.")
	result = dialogue.advance(state)
	state = result["state"]
	result = dialogue.advance(state)
	state = result["state"]
	var comfort_before: float = state["relationships"]["elena_reyes_hale"]["comfort"]
	result = dialogue.choose(state, "joke")
	state = result["state"]
	_expect(state["relationships"]["elena_reyes_hale"]["comfort"] == comfort_before + 1.0, "Playful wake-up response raises Elena Comfort exactly once.")
	_expect(result["view"]["node_id"] == "elena_joke_reply", "Playful response reaches Elena's authored reply.")
	var resumed: Dictionary = dialogue.resume(state)
	_expect(resumed["view"]["node_id"] == "elena_joke_reply", "Dialogue resume restores the exact active node.")
	_expect(resumed["state"]["relationships"]["elena_reyes_hale"]["comfort"] == comfort_before + 1.0, "Dialogue resume does not replay choice effects.")

	var branch_cases: Array = [
		{
			"choice": "choose_college",
			"life_path": "college",
			"required_quests": ["enroll_at_westshore"],
			"allowance": true,
			"rent": 0,
		},
		{
			"choice": "choose_employment",
			"life_path": "employment",
			"required_quests": ["find_employment"],
			"allowance": false,
			"rent": 250,
		},
		{
			"choice": "choose_both",
			"life_path": "college_and_employment",
			"required_quests": ["enroll_at_westshore", "find_part_time_employment"],
			"allowance": true,
			"rent": 0,
		},
	]
	for branch: Dictionary in branch_cases:
		state = factory.create_new_game({}, {"random_seed": 88})
		result = dialogue.begin(state, "opening_future_talk")
		state = result["state"]
		result = dialogue.advance(state)
		state = result["state"]
		result = dialogue.advance(state)
		state = result["state"]
		result = dialogue.choose(state, "ready")
		state = result["state"]
		result = dialogue.advance(state)
		state = result["state"]
		result = dialogue.advance(state)
		state = result["state"]
		_expect(result["view"]["node_id"] == "future_choice", "Opening dialogue reaches the life-path choice.")
		_expect(state["quest_state"]["objectives"]["opening_future_choice"]["hear_elena_out"], "Hearing Elena completes the first opening objective.")

		result = dialogue.choose(state, branch["choice"])
		state = result["state"]
		_expect(state["player"]["life_path"] == branch["life_path"], "Life-path choice stores %s." % branch["life_path"])
		for quest_id: String in branch["required_quests"]:
			_expect(quest_id in state["quest_state"]["active"], "Life path starts quest %s." % quest_id)
		_expect(state["player"]["flags"]["weekly_allowance_active"] == branch["allowance"], "Life path applies its allowance rule.")
		_expect(state["player"]["housing"]["monthly_rent"] == branch["rent"], "Life path applies its rent rule.")

		result = dialogue.advance(state)
		state = result["state"]
		_expect(result["view"]["node_id"] == "elena_closing", "Life-path response reaches Elena's closing line.")
		_expect("opening_future_choice" in state["quest_state"]["completed"], "Opening quest completes at Elena's closing line.")
		_expect(bool(state["player"]["flags"].get("sandbox.active", false)), "Opening completion activates the sandbox.")
		_expect("quests" in state["player"]["phone"]["unlocked_apps"], "Opening completion unlocks the quest tracker.")
		result = dialogue.advance(state)
		state = result["state"]
		_expect(result.get("ended", false), "Elena's opening conversation ends cleanly.")
		_expect(state["conversation_state"]["active"] == null, "Finished dialogue clears active conversation state.")
		_expect(_calendar_event_status(state, "opening_future_talk_y1_08_20") == "completed", "Finishing Elena's scene marks its calendar event complete.")
		_expect("conversation:opening_future_talk" in state["conversation_state"]["once_only_flags"], "Opening dialogue records its once-only flag.")
		result = dialogue.begin(state, "opening_future_talk")
		_expect(not result.get("ok", true), "Elena's opening conversation cannot run twice.")


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


func _stack_quantity(state: Dictionary, container_id: String, item_id: String) -> int:
	for container: Variant in state["player"]["inventory"].get("containers", []):
		if not container is Dictionary or str(container.get("id", "")) != container_id:
			continue
		for stack: Variant in container.get("items", []):
			if stack is Dictionary and str(stack.get("item_id", "")) == item_id:
				return int(stack.get("quantity", 0))
	return 0


func _set_stack_cleanliness(state: Dictionary, container_id: String, item_id: String, cleanliness: int) -> void:
	for container: Variant in state["player"]["inventory"].get("containers", []):
		if not container is Dictionary or str(container.get("id", "")) != container_id:
			continue
		for stack: Variant in container.get("items", []):
			if stack is Dictionary and str(stack.get("item_id", "")) == item_id:
				stack["item_state"]["cleanliness"] = cleanliness
				return


func _stack_cleanliness(state: Dictionary, container_id: String, item_id: String) -> int:
	for container: Variant in state["player"]["inventory"].get("containers", []):
		if not container is Dictionary or str(container.get("id", "")) != container_id:
			continue
		for stack: Variant in container.get("items", []):
			if stack is Dictionary and str(stack.get("item_id", "")) == item_id:
				return int(stack.get("item_state", {}).get("cleanliness", -1))
	return -1


func _thread_message_count(state: Dictionary, character_id: String) -> int:
	return state["player"]["phone"].get("message_threads", {}).get(character_id, {}).get("messages", []).size()


func _calendar_event_status(state: Dictionary, event_id: String) -> String:
	for calendar_event: Variant in state["calendar_state"].get("events", []):
		if calendar_event is Dictionary and str(calendar_event.get("id", "")) == event_id:
			return str(calendar_event.get("status", ""))
	return ""


func _calendar_template_exists(state: Dictionary, template_id: String) -> bool:
	for calendar_event: Variant in state["calendar_state"].get("events", []):
		if calendar_event is Dictionary and str(calendar_event.get("template_id", "")) == template_id:
			return true
	return false


func _npc_location(state: Dictionary, character_id: String) -> String:
	for npc_state: Variant in state.get("npc_states", []):
		if npc_state is Dictionary and str(npc_state.get("character_id", "")) == character_id:
			return str(npc_state.get("current_location", ""))
	return ""


func _route_option(plan: Dictionary, mode: String) -> Dictionary:
	for option: Variant in plan.get("options", []):
		if option is Dictionary and str(option.get("mode", "")) == mode:
			return option
	return {}


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
