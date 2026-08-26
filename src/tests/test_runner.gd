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
const EducationEngineScript: GDScript = preload("res://src/education/education_engine.gd")
const EmploymentEngineScript: GDScript = preload("res://src/employment/employment_engine.gd")
const EconomyEngineScript: GDScript = preload("res://src/economy/economy_engine.gd")
const HousingEngineScript: GDScript = preload("res://src/housing/housing_engine.gd")
const SaveEngineScript: GDScript = preload("res://src/save/save_engine.gd")
const RelationshipEngineScript: GDScript = preload("res://src/relationships/relationship_engine.gd")

var _failures: PackedStringArray = []
var _tests_run: int = 0
var _registry: Node


func _initialize() -> void:
	_registry = ContentRegistryScript.new()
	root.add_child(_registry)
	call_deferred("_run_all")


func _run_all() -> void:
	_test_project_configuration()
	_test_persistent_settings_and_remapping()
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
	_test_playable_education_semester()
	_test_employment_applications_interviews_and_offers()
	_test_recurring_economy_and_shopping()
	_test_housing_qualification_contracts_and_moving()
	_test_save_round_trip_rotation_recovery_and_migration()
	_test_phone_messages_and_calendar()
	_test_relationship_dating_agreements_and_conflicts()
	_test_sandbox_quest_progression_and_tracking()
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
	_expect(InputMap.has_action("quicksave"), "Quicksave input action exists.")
	_expect(InputMap.has_action("quickload"), "Quickload input action exists.")
	_expect(InputMap.has_action("dialogue_skip"), "Dialogue skip input action exists.")
	_expect(ProjectSettings.has_setting("autoload/PhoneService"), "Phone service is configured as an autoload.")
	_expect(ProjectSettings.has_setting("autoload/RelationshipService"), "Relationship service is configured as an autoload.")
	_expect(not ProjectSettings.has_setting("autoload/ReviewService"), "No weekly-planning service can interrupt sandbox play.")
	_expect(ProjectSettings.has_setting("autoload/SettingsService"), "Persistent settings service is configured as an autoload.")
	_expect(ProjectSettings.has_setting("autoload/TravelService"), "Travel service is configured as an autoload.")
	_expect(ProjectSettings.has_setting("autoload/CityActionService"), "City action service is configured as an autoload.")
	_expect(ProjectSettings.has_setting("autoload/EducationService"), "Education service is configured as an autoload.")
	_expect(ProjectSettings.has_setting("autoload/EmploymentService"), "Employment service is configured as an autoload.")
	_expect(ProjectSettings.has_setting("autoload/EconomyService"), "Economy service is configured as an autoload.")
	_expect(ProjectSettings.has_setting("autoload/HousingService"), "Housing service is configured as an autoload.")
	_expect(ProjectSettings.has_setting("autoload/VNAssetService"), "Data-driven VN artwork service is configured as an autoload.")
	_expect(ProjectSettings.has_setting("autoload/SaveService"), "Save service is configured as an autoload.")


func _test_persistent_settings_and_remapping() -> void:
	var settings_service: Node = root.get_node_or_null("SettingsService")
	_expect(settings_service != null, "Persistent settings service is available at runtime.")
	if settings_service == null:
		return
	var test_path: String = "user://port_alder_settings_test.cfg"
	var absolute_path: String = ProjectSettings.globalize_path(test_path)
	if FileAccess.file_exists(absolute_path):
		DirAccess.remove_absolute(absolute_path)
	var originals: Dictionary = {
		"text_scale": settings_service.get("text_scale"),
		"reduce_motion": settings_service.get("reduce_motion"),
		"high_contrast": settings_service.get("high_contrast"),
		"screen_effects_enabled": settings_service.get("screen_effects_enabled"),
		"camera_shake_enabled": settings_service.get("camera_shake_enabled"),
		"dialogue_skip_mode": settings_service.get("dialogue_skip_mode"),
		"ui_volume": settings_service.get("ui_volume"),
		"window_size": settings_service.get("window_size"),
		"vsync_enabled": settings_service.get("vsync_enabled"),
	}
	var original_skip_events: Array = []
	for event: InputEvent in InputMap.action_get_events("dialogue_skip"):
		original_skip_events.append(event.duplicate())
	settings_service.set("text_scale", 1.5)
	settings_service.set("reduce_motion", true)
	settings_service.set("high_contrast", true)
	settings_service.set("screen_effects_enabled", false)
	settings_service.set("camera_shake_enabled", false)
	settings_service.set("dialogue_skip_mode", "toggle")
	settings_service.set("ui_volume", 0.4)
	settings_service.set("window_size", "1600x900")
	settings_service.set("vsync_enabled", false)
	var remapped_key: InputEventKey = InputEventKey.new()
	remapped_key.physical_keycode = KEY_P
	_expect(bool(settings_service.call("remap_action", "dialogue_skip", remapped_key)), "A supported dialogue action accepts a keyboard remap.")
	_expect(int(settings_service.call("save_settings", test_path)) == OK and FileAccess.file_exists(absolute_path), "Settings persist to a device-local configuration file.")

	settings_service.set("text_scale", 1.0)
	settings_service.set("reduce_motion", false)
	settings_service.set("high_contrast", false)
	settings_service.set("screen_effects_enabled", true)
	settings_service.set("camera_shake_enabled", true)
	settings_service.set("dialogue_skip_mode", "hold")
	settings_service.set("ui_volume", 1.0)
	settings_service.set("window_size", "1280x720")
	settings_service.set("vsync_enabled", true)
	settings_service.call("reset_control_bindings")
	settings_service.call("load_settings", test_path)
	_expect(float(settings_service.get("text_scale")) == 1.5 and bool(settings_service.get("reduce_motion")) and bool(settings_service.get("high_contrast")), "Saved large-text, reduced-motion, and high-contrast settings reload.")
	_expect(not bool(settings_service.get("screen_effects_enabled")) and not bool(settings_service.get("camera_shake_enabled")) and str(settings_service.get("dialogue_skip_mode")) == "toggle", "Saved visual-effect and dialogue-skip preferences reload.")
	_expect(is_equal_approx(float(settings_service.get("ui_volume")), 0.4) and str(settings_service.get("window_size")) == "1600x900" and not bool(settings_service.get("vsync_enabled")), "Saved audio and display preferences reload.")
	_expect("P" in str(settings_service.call("binding_label", "dialogue_skip")), "A saved keyboard remap reloads from serialized input data.")

	for key: Variant in originals:
		settings_service.set(str(key), originals[key])
	InputMap.action_erase_events("dialogue_skip")
	for event: InputEvent in original_skip_events:
		InputMap.action_add_event("dialogue_skip", event)
	settings_service.call("apply_all")
	if FileAccess.file_exists(absolute_path):
		DirAccess.remove_absolute(absolute_path)


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
		"res://content/systems/relationships.json",
		"res://content/systems/quest_progression.json",
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
		_expect(dialogue_instance.get_node_or_null("BackgroundImage") != null, "VN scene contains a data-driven background layer.")
		_expect(dialogue_instance.get_node_or_null("PortraitArea/PortraitCard/PortraitMargin/PortraitLayout/PortraitImage") != null, "VN scene contains a data-driven portrait layer.")
		_expect(dialogue_instance.get_node_or_null("DialogueMargin/DialoguePanel/PanelMargin/DialogueContent/SpeakerLabel") != null, "VN scene contains a speaker label.")
		_expect(dialogue_instance.get_node_or_null("DialogueMargin/DialoguePanel/PanelMargin/DialogueContent/ChoicesBox") != null, "VN scene contains dynamic dialogue choices.")
		_expect(dialogue_instance.get_node_or_null("DialogueMargin/DialoguePanel/PanelMargin/DialogueContent/Controls/SkipButton") != null, "VN scene exposes hold-or-toggle dialogue skipping.")
		_expect(dialogue_instance.get_node_or_null("DialogueMargin/DialoguePanel/PanelMargin/DialogueContent/Controls/ReplayButton") != null, "VN scene exposes a replay-current-line control.")
		dialogue_instance.free()
	var menu_scene: PackedScene = load("res://scenes/menus/main_menu.tscn")
	_expect(menu_scene != null, "Main menu scene loads with save controls.")
	if menu_scene != null:
		var menu_instance: Node = menu_scene.instantiate()
		_expect(menu_instance.get_node_or_null("LoadPanel/Margin/Layout/Scroll/SaveList") != null, "Main menu contains its dynamic load-slot list.")
		_expect(menu_instance.get_node_or_null("SettingsPanel/Panel/Margin/Layout/Columns/ActionScroll/SettingsActions") != null, "Main menu contains the complete reusable settings panel.")
		menu_instance.free()
	var settings_scene: PackedScene = load("res://scenes/menus/settings_panel.tscn")
	_expect(settings_scene != null, "Reusable settings panel scene loads.")
	if settings_scene != null:
		var settings_instance: Node = settings_scene.instantiate()
		_expect(settings_instance.get_node_or_null("Panel/Margin/Layout/Columns/SettingsSummary") != null, "Settings panel contains an accessible settings summary.")
		_expect(settings_instance.get_node_or_null("Panel/Margin/Layout/Columns/ActionScroll/SettingsActions") != null, "Settings panel contains dynamic accessibility, audio, display, and control actions.")
		settings_instance.free()


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
	_expect(instance.get_node_or_null("Player") == null, "Hale home has no movement-controlled player object.")
	_expect(instance.get_node_or_null("Backdrop") != null, "Hale home contains its static VN backdrop.")
	_expect(instance.get_node_or_null("BackgroundImage") != null, "Hale home contains its data-driven room artwork layer.")
	_expect(instance.get_node_or_null("Interface/Screen/Header/Margin/Layout/Top/RoomLabel") != null, "Hale home contains its VN location header.")
	_expect(instance.get_node_or_null("Interface/Screen/MainMargin/MainLayout/NavigationPanel/Margin/Layout/Scroll/RoomButtons") != null, "Hale home contains menu-driven room navigation.")
	_expect(instance.get_node_or_null("Interface/Screen/MainMargin/MainLayout/ActionPanel/Margin/Layout/Scroll/ActionButtons") != null, "Hale home contains persistent VN choices.")
	_expect(instance.get_node_or_null("Interface/Screen/MainMargin/MainLayout/ScenePanel/Margin/Layout/PortraitStage") != null, "Hale home contains its scheduled portrait stage.")
	_expect(instance.get_node_or_null("Interface/WardrobePanel") != null, "Hale home contains the wardrobe panel.")
	_expect(instance.get_node_or_null("Interface/QuestPanel") != null, "Hale home retains the quest tracker.")
	_expect(instance.get_node_or_null("Interface/Smartphone") != null, "Hale home contains the reusable smartphone.")
	instance.free()
	var city_scene: PackedScene = load("res://scenes/locations/city_location.tscn")
	_expect(city_scene != null, "Reusable city destination scene loads.")
	if city_scene != null:
		var city_instance: Node = city_scene.instantiate()
		_expect(city_instance.get_node_or_null("Player") == null, "City destination scene has no movement-controlled player object.")
		_expect(city_instance.get_node_or_null("Backdrop") != null, "City destination scene contains its static VN backdrop.")
		_expect(city_instance.get_node_or_null("BackgroundImage") != null, "City destination scene contains its data-driven background layer.")
		_expect(city_instance.get_node_or_null("Interface/Smartphone") != null, "City destination scene contains the reusable smartphone.")
		_expect(city_instance.get_node_or_null("Interface/MainMargin/MainLayout/NavigationPanel/Margin/Layout/Scroll/RoomButtons") != null, "City destination scene contains menu-driven area navigation.")
		_expect(city_instance.get_node_or_null("Interface/MainMargin/MainLayout/ActionPanel") != null, "City destination scene contains its VN activity choices.")
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
	_expect("under_this_roof" in state["quest_state"]["available"], "Elena's household quest becomes an optional offer after the opening.")
	_expect("under_this_roof" not in state["quest_state"]["active"], "Discovering Elena's quest does not accept it for the player.")
	_expect("one_year_ahead" not in state["quest_state"]["discovered"], "Lily's quest waits until its authored earliest block.")
	_expect("a_quiet_check_in" not in state["quest_state"]["discovered"], "Daniel's quest waits until Evening.")
	result = quests.accept_quest(state, "under_this_roof", "test.accept_household_rules")
	_expect(result.get("ok", false), "The player can accept Elena's discovered household offer.")
	state = result["state"]

	state["clock"]["block"] = "lunch"
	result = quests.sync_automatic_activations(state, "test.household_lunch")
	state = result["state"]
	_expect("one_year_ahead" in state["quest_state"]["available"], "Lily's story quest becomes available at Lunch when its trust gate is met.")
	result = quests.accept_quest(state, "one_year_ahead", "test.accept_lily_story")
	state = result["state"]
	_expect(result.get("ok", false) and "one_year_ahead" in state["quest_state"]["active"], "Accepting Lily's offer starts her story quest.")
	lily = schedules.resolve_character(state, "lily_hale")
	_expect(lily["present"] and lily["room"] == "kitchen", "Lily moves to the kitchen for her Lunch story scene.")
	state["world_state"]["current_location"] = "hale_home.kitchen"
	_expect(dialogue.can_begin(state, "lily_program_doubts")["ok"], "Lily's program conversation is available beside her in the kitchen.")

	state["clock"]["block"] = "evening"
	result = quests.sync_automatic_activations(state, "test.household_evening")
	state = result["state"]
	_expect("a_quiet_check_in" in state["quest_state"]["available"], "Daniel's first story becomes an available offer at Evening.")
	result = quests.accept_quest(state, "a_quiet_check_in", "test.accept_daniel_story")
	state = result["state"]
	_expect(result.get("ok", false) and "a_quiet_check_in" in state["quest_state"]["active"], "Accepting Daniel's offer starts his story quest.")
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
	_expect("first_rep" in state["quest_state"]["available"] and "first_rep" not in state["quest_state"]["active"], "Discovering Forge Fitness reveals Rachel's quest without accepting it.")
	result = quests.accept_quest(state, "first_rep", "test.accept_first_rep")
	state = result["state"]
	_expect(result.get("ok", false) and "first_rep" in state["quest_state"]["active"], "The player can accept Rachel's available quest.")
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
	_expect("build_a_training_rhythm" in state["quest_state"]["active"] and quests.get_progress(state, "build_a_training_rhythm").get("progress_text", "") == "0/5", "Finishing First Rep organically starts Rachel's counted 0/5 training stage.")
	_expect(int(state["relationships"]["rachel_morgan"].get("unlocked_chapter_level", 0)) == 2, "First Rep unlocks Rachel's second relationship chapter.")
	_expect(int(state["relationships"]["rachel_morgan"].get("relationship_level", 0)) == 2, "Authored quest chapter unlocks keep the relationship level synchronized.")


func _test_playable_education_semester() -> void:
	var simulation: RefCounted = SimulationEngineScript.new(_registry)
	var education: RefCounted = EducationEngineScript.new(_registry, simulation)
	var state: Dictionary = _create_enrolled_computer_state(1301)
	var result: Dictionary = education.sync_education(state)
	_expect(result.get("ok", false), "The education engine initializes an enrolled semester from the authored Westshore schedule.")
	state = result["state"]
	_expect(state["player"]["education"]["assessments"].size() == 24, "Four courses generate three assignments, one project, one midterm, and one final each.")
	var scheduled_exams: int = 0
	for event_value: Variant in state["calendar_state"].get("events", []):
		if event_value is Dictionary and str(event_value.get("type", "")) == "exam":
			scheduled_exams += 1
	_expect(scheduled_exams == 8, "Midterms and finals create eight required exam events in the Calendar.")
	_expect(str(state["player"]["education"]["semester"].get("phase", "")) == "pre_orientation", "The semester begins in its authored pre-orientation phase.")

	_set_test_date(state, "Y1-09-03", "tuesday", "afternoon")
	state["world_state"]["current_location"] = "westshore_campus.courtyard"
	var class_status: Dictionary = education.class_status(state)
	_expect(not class_status.get("ready", true) and "Classroom Wing" in str(class_status.get("reason", "")), "Class attendance is unavailable until the player enters the scheduled campus room.")
	state["world_state"]["current_location"] = "westshore_campus.classrooms"
	class_status = education.class_status(state)
	_expect(class_status.get("ready", false) and str(class_status.get("event", {}).get("course_id", "")) == "CST115", "The current campus room exposes the scheduled Tuesday-afternoon Computer Hardware class.")
	result = education.attend_class(state, "engaged")
	_expect(result.get("ok", false), "A scheduled class can be attended with a chosen participation approach.")
	state = result["state"]
	_expect(int(state["player"]["education"]["attendance"]["CST115"]["attended"]) == 1, "Class attendance is recorded in the persistent course register.")
	_expect(str(result.get("data", {}).get("record", {}).get("status", "")) == "present" and float(result.get("data", {}).get("performance", 0.0)) > 0.0, "Attendance stores punctuality and calculated classroom performance.")
	_expect(float(state["player"]["skill_experience"].get("computer_repair", 0.0)) > 0.0, "Attending class grants experience in the course's authored subject skills.")
	_expect(str(state["clock"]["block"]) == "evening", "A class consumes its scheduled activity block.")
	_set_test_date(state, "Y1-09-05", "thursday", "afternoon")
	state["clock"]["minute_within_block"] = 30
	state["world_state"]["current_location"] = "westshore_campus.classrooms"
	result = education.attend_class(state, "quiet_notes")
	_expect(result.get("ok", false) and str(result.get("data", {}).get("record", {}).get("status", "")) == "late", "Arriving after fifteen minutes but within the grace window records late attendance.")
	state = result["state"]
	_expect(int(state["player"]["education"]["attendance"]["CST115"]["late"]) == 1, "Late attendance uses its own persistent course counter.")

	_set_test_date(state, "Y1-09-13", "friday", "evening")
	state["world_state"]["current_location"] = "hale_home.player_bedroom"
	result = education.study_course(state, "CST115", "standard")
	_expect(result.get("ok", false), "An enrolled course can be studied from an approved home study location.")
	state = result["state"]
	_expect(float(state["player"]["education"]["course_preparation"]["CST115"]) == 12.0, "A standard study session adds persistent course preparation.")
	result = education.complete_assessment(state, "cst115-assignment-1", "thorough")
	_expect(result.get("ok", false), "Available coursework can be completed with a selected effort level.")
	state = result["state"]
	_expect(str(_employment_record(state["player"]["education"]["assessments"], "cst115-assignment-1").get("status", "")) == "completed", "Submitted coursework is resolved exactly once.")
	_expect(float(result.get("data", {}).get("result", {}).get("score", 0.0)) > 0.0 and float(state["player"]["education"]["grades"]["CST115"].get("graded_weight", 0.0)) >= 45.0, "Coursework receives a calculated score and immediately updates the weighted gradebook.")

	_set_test_date(state, "Y1-09-28", "saturday", "morning")
	result = education.sync_education(state)
	_expect(result.get("ok", false) and int(result.get("data", {}).get("missed_assessments", 0)) == 3, "Passing an unresolved shared deadline records the other three first assignments as missed.")
	state = result["state"]
	_expect(bool(state["player"]["flags"].get("academic_warning", false)), "Three unexcused course absences activate the authored academic warning.")

	var midterm: Dictionary = _employment_record(state["player"]["education"]["assessments"], "cst115-midterm")
	var midterm_event: Dictionary = _employment_record(state["calendar_state"]["events"], str(midterm.get("calendar_event_id", "")))
	_set_test_date(state, str(midterm.get("due_date", "Y1-10-15")), str(midterm_event.get("weekday", "tuesday")), str(midterm.get("block", "afternoon")))
	state["world_state"]["current_location"] = str(midterm.get("location", "westshore_campus.classrooms"))
	result = education.complete_assessment(state, "cst115-midterm", "exam")
	_expect(result.get("ok", false), "A midterm can be taken only in its scheduled campus block and room.")
	state = result["state"]
	_expect(str(_employment_record(state["player"]["education"]["assessments"], "cst115-midterm").get("status", "")) == "completed", "The midterm result resolves both the assessment and its required calendar event.")

	_set_test_date(state, "Y1-12-21", "saturday", "morning")
	result = education.sync_education(state)
	_expect(result.get("ok", false), "The education engine closes the semester after the authored term-complete date.")
	state = result["state"]
	_expect(str(state["player"]["education"]["semester"].get("status", "")) == "completed" and state["player"]["education"]["semester_history"].size() == 1, "Semester completion creates one immutable academic-history record.")
	_expect(bool(state["player"]["education"].get("registration_hold", false)) and str(state["player"]["education"].get("academic_standing", "")) == "suspension_review", "Severe failed-term performance creates a registration hold and suspension review.")

	var passing_state: Dictionary = _create_enrolled_computer_state(1302)
	result = education.sync_education(passing_state)
	passing_state = result["state"]
	for course_id_value: Variant in passing_state["player"]["education"]["courses"]:
		passing_state["player"]["education"]["attendance"][str(course_id_value)] = {"attended": 20, "late": 0, "absent": 0}
	for assessment_value: Variant in passing_state["player"]["education"]["assessments"]:
		if not assessment_value is Dictionary:
			continue
		assessment_value["status"] = "completed"
		assessment_value["score"] = 85.0
		passing_state["player"]["education"]["assessment_results"].append({
			"id": "result-%s" % assessment_value["id"], "assessment_id": assessment_value["id"], "course_id": assessment_value["course_id"],
			"type": assessment_value["type"], "score": 85.0, "status": "completed",
		})
	for calendar_event: Variant in passing_state["calendar_state"].get("events", []):
		if calendar_event is Dictionary and str(calendar_event.get("course_id", "")) in passing_state["player"]["education"]["courses"]:
			calendar_event["status"] = "completed"
	_set_test_date(passing_state, "Y1-12-21", "saturday", "morning")
	result = education.sync_education(passing_state)
	_expect(result.get("ok", false), "A fully resolved passing term also completes through the same semester processor.")
	passing_state = result["state"]
	_expect(int(passing_state["player"]["education"].get("credits_earned", 0)) == 12 and int(passing_state["player"]["education"].get("semesters_completed", 0)) == 1, "Passing four three-credit courses advances semester and credit progression.")
	_expect(str(passing_state["player"]["education"].get("academic_standing", "")) == "good_standing" and float(passing_state["player"]["reputations"].get("academic", 0.0)) > 0.0, "Strong term results preserve good standing and improve academic reputation.")


func _test_employment_applications_interviews_and_offers() -> void:
	var factory: RefCounted = NewGameStateFactoryScript.new(_registry)
	var simulation: RefCounted = SimulationEngineScript.new(_registry)
	var quests: RefCounted = QuestEngineScript.new(_registry, simulation)
	var employment: RefCounted = EmploymentEngineScript.new(_registry, simulation, quests)
	var state: Dictionary = factory.create_new_game({}, {"random_seed": 918})
	var result: Dictionary = quests.start_quest(state, "find_employment", "test.jobs.full_time")
	state = result["state"]
	result = employment.record_listings_viewed(state, "full_time")
	_expect(result.get("ok", false), "Opening the Jobs app records the full-time listing search.")
	state = result["state"]
	_expect(state["quest_state"]["objectives"]["find_employment"]["open_jobs"], "The Jobs app completes employment onboarding without requiring Harbor Centre.")
	_expect(state["quest_state"]["objectives"]["find_employment"]["review_requirements"], "Reviewing the full-time results completes the listing requirement.")
	var grocery: Dictionary = _registry.get_content("jobs", "grocery_stock_clerk")
	_expect(employment.qualification_report(state, grocery)["qualified"], "The starter grocery position is reachable with baseline reliability and stamina.")
	var companion: Dictionary = _registry.get_content("jobs", "licensed_professional_companion")
	_expect(not employment.qualification_report(state, companion)["qualified"], "Licensed adult self-employment stays locked behind licenses, health, and skill requirements.")

	result = employment.apply_to_job(state, "grocery_stock_clerk", "full_time")
	_expect(result.get("ok", false), "A qualified full-time grocery application can be submitted.")
	state = result["state"]
	result = employment.apply_to_job(state, "cinema_attendant", "part_time")
	_expect(result.get("ok", false), "A second qualified application can be submitted to satisfy the search quest.")
	state = result["state"]
	_expect(state["quest_state"]["objectives"]["find_employment"]["submit_applications"], "Two submitted applications complete the authored application objective.")
	_expect(state["player"]["employment"]["interviews"].size() == 2, "Qualified applications schedule separate calendar interviews.")
	var grocery_application: Dictionary = _employment_application_for_job(state, "grocery_stock_clerk")
	var grocery_interview: Dictionary = _employment_record(state["player"]["employment"]["interviews"], str(grocery_application["interview_id"]))
	_set_clock_to_employment_event(state, grocery_interview)
	result = employment.complete_interview(state, "grocery_stock_clerk", 20)
	_expect(result.get("ok", false), "The interactive interview scoring path completes at its scheduled time.")
	state = result["state"]
	grocery_application = _employment_application_for_job(state, "grocery_stock_clerk")
	_expect(str(grocery_application["stage"]) == "offer_received", "A strong interview produces a job offer.")
	_expect(state["quest_state"]["objectives"]["find_employment"]["attend_interview"], "Completing an interview advances the employment quest.")
	result = employment.accept_offer(state, "grocery_stock_clerk", "weekday_full_time")
	_expect(result.get("ok", false), "A full-time offer can be accepted with its authored forty-hour schedule.")
	state = result["state"]
	_expect(state["player"]["employment"]["employed"], "Accepting an offer changes the player's employment state.")
	_expect(state["player"]["employment"]["active_jobs"].size() == 1, "The accepted contract creates one active job record.")
	_expect(_calendar_event_type_count(state, "work") > 100, "Accepting a full-time contract creates six weeks of work-block calendar events.")
	_expect("find_employment" in state["quest_state"]["completed"], "A qualifying forty-hour contract completes the full-time employment quest.")
	_expect(state["player"]["housing"]["monthly_rent"] == 250, "Completing the employment path activates the Hale household rent rule.")
	var first_work_event: Dictionary = _first_scheduled_work_event(state, "grocery_stock_clerk")
	_set_clock_to_employment_event(state, first_work_event)
	var shift_status: Dictionary = employment.shift_status(state, "grocery_stock_clerk")
	_expect(shift_status.get("ready", false), "The first contracted workday becomes clock-in ready at its scheduled block.")
	state["player"]["employment"]["work_history"].append({
		"id": "test-prior-week-hours", "job_id": "test_second_job", "date": first_work_event.get("date", ""),
		"week_key": shift_status.get("shift", {}).get("week_key", ""), "hours_worked": 39.0,
	})
	var checking_before_shift: float = float(state["player"]["economy"]["accounts"]["checking"])
	result = employment.perform_shift(state, "grocery_stock_clerk", "ambitious")
	_expect(result.get("ok", false), "A scheduled shift can be played with a selected work approach.")
	state = result["state"]
	var played_shift: Dictionary = result.get("data", {}).get("shift", {})
	_expect(float(played_shift.get("hours_worked", 0.0)) == 8.0, "A grouped weekday full-time shift records eight paid hours.")
	_expect(float(played_shift.get("overtime_hours", 0.0)) == 7.0, "Hours above forty across jobs receive overtime treatment.")
	_expect(float(played_shift.get("gross_wages", 0.0)) == 207.0, "The overtime multiplier produces the expected gross wages.")
	_expect(_calendar_work_status_count(state, "grocery_stock_clerk", str(first_work_event.get("date", "")), "completed") == 4, "Clocking out completes every authored block in that workday.")
	_expect(float(state["player"]["economy"]["accounts"]["checking"]) == checking_before_shift, "Shift earnings accrue until payday instead of depositing immediately.")
	var active_job: Dictionary = _active_job_for_test(state, "grocery_stock_clerk")
	_expect(float(active_job.get("pending_pay", {}).get("gross_wages", 0.0)) == 207.0, "Completed shift wages accrue in the job's pending payroll.")
	active_job["next_payday"] = _test_clock_date(state)
	result = employment.sync_employment(state)
	_expect(result.get("ok", false), "Employment synchronization processes a due payday.")
	state = result["state"]
	active_job = _active_job_for_test(state, "grocery_stock_clerk")
	_expect(float(state["player"]["economy"]["accounts"]["checking"]) > checking_before_shift, "Net pay is deposited into checking on payday.")
	_expect(state["player"]["employment"].get("payroll_history", []).size() == 1, "Payday creates an immutable payroll history record.")
	var first_paycheck: Dictionary = state["player"]["employment"]["payroll_history"][0]
	_expect(is_equal_approx(float(first_paycheck.get("withholding", 0.0)), 16.56) and is_equal_approx(float(first_paycheck.get("net", 0.0)), 190.44), "Weekly payroll applies the authored eight-percent withholding bracket.")
	_expect(float(active_job.get("pending_pay", {}).get("gross_wages", -1.0)) == 0.0, "Payday clears accrued wages for the next period.")
	_expect(str(state["player"]["economy"]["ledger"][-1].get("category", "")) == "employment", "Payday creates an employment income ledger entry.")
	active_job["performance"] = 80.0
	active_job["probation_end_date"] = _test_clock_date(state)
	active_job["next_review_date"] = _test_clock_date(state)
	result = employment.process_career_review(state, "grocery_stock_clerk")
	_expect(result.get("ok", false), "A due ninety-day career review can be completed after probation.")
	state = result["state"]
	active_job = _active_job_for_test(state, "grocery_stock_clerk")
	_expect(float(active_job.get("hourly_pay", 0.0)) > 18.0, "Strong performance earns a data-driven percentage raise.")
	_expect(active_job.get("pending_promotion") is Dictionary, "Meeting the next role's requirements exposes a promotion opening.")
	result = employment.accept_promotion(state, "grocery_stock_clerk")
	_expect(result.get("ok", false), "An available authored promotion can be accepted.")
	state = result["state"]
	active_job = _active_job_for_test(state, "grocery_stock_clerk")
	_expect(str(active_job.get("title", "")) == "Senior Stock Clerk", "Promotion updates the player's current job title.")
	_expect(int(active_job.get("career_level", 0)) == 1, "Promotion advances the authored career level.")
	var next_promotion: Dictionary = employment.career_review_status(state, "grocery_stock_clerk").get("promotion", {})
	_expect(not next_promotion.get("eligible", false) and not next_promotion.get("missing", []).is_empty(), "The next promotion remains locked behind its authored leadership requirement.")

	state = factory.create_new_game({}, {"random_seed": 919})
	state["player"]["education"]["enrolled"] = true
	state["calendar_state"]["events"].append({
		"id": "test-class", "title": "Test Class", "type": "class", "date": "Y1-09-03",
		"weekday": "tuesday", "block": "afternoon", "status": "scheduled",
	})
	result = quests.start_quest(state, "find_part_time_employment", "test.jobs.part_time")
	state = result["state"]
	result = employment.record_listings_viewed(state, "part_time")
	state = result["state"]
	result = employment.save_availability(state)
	_expect(result.get("ok", false), "The Jobs app saves work availability around required classes.")
	state = result["state"]
	_expect(state["quest_state"]["objectives"]["find_part_time_employment"]["review_calendar"], "Saving availability advances the part-time quest.")
	result = employment.apply_to_job(state, "cinema_attendant", "part_time")
	_expect(result.get("ok", false), "A class-compatible cinema application can be submitted.")
	state = result["state"]
	var cinema_application: Dictionary = _employment_application_for_job(state, "cinema_attendant")
	var cinema_interview: Dictionary = _employment_record(state["player"]["employment"]["interviews"], str(cinema_application["interview_id"]))
	_set_clock_to_employment_event(state, cinema_interview)
	result = employment.complete_interview(state, "cinema_attendant", 20)
	state = result["state"]
	result = employment.accept_offer(state, "cinema_attendant", "weekday_evenings")
	_expect(result.get("ok", false), "A fifteen-hour cinema schedule can be accepted around college classes.")
	state = result["state"]
	_expect("find_part_time_employment" in state["quest_state"]["completed"], "A compatible part-time contract completes the college employment quest.")
	_expect(float(state["player"]["employment"]["active_jobs"][0]["weekly_hours"]) <= 24.0, "The accepted student job stays within the authored weekly-hour ceiling.")
	var missed_event: Dictionary = _first_scheduled_work_event(state, "cinema_attendant")
	_set_clock_to_employment_event(state, missed_event)
	state["clock"]["minute_within_block"] = 61
	var performance_before_miss: float = float(_active_job_for_test(state, "cinema_attendant").get("performance", 50.0))
	result = employment.sync_employment(state)
	_expect(result.get("ok", false), "Employment synchronization reconciles a passed clock-in window.")
	state = result["state"]
	var cinema_job: Dictionary = _active_job_for_test(state, "cinema_attendant")
	_expect(int(cinema_job.get("shifts_missed", 0)) == 1, "A shift more than sixty minutes late is recorded as missed.")
	_expect(float(cinema_job.get("performance", 50.0)) == performance_before_miss - 8.0, "A missed shift applies the authored performance consequence.")
	_expect(float(state["player"]["reputations"].get("professional", 0.0)) == -2.0, "A missed shift lowers professional reputation.")


func _test_recurring_economy_and_shopping() -> void:
	var factory: RefCounted = NewGameStateFactoryScript.new(_registry)
	var simulation: RefCounted = SimulationEngineScript.new(_registry)
	var economy: RefCounted = EconomyEngineScript.new(_registry, simulation)
	var state: Dictionary = factory.create_new_game({}, {"random_seed": 1201})
	var granola_before: int = _stack_quantity(state, "kitchen_storage", "food_granola_bar")
	var wallet_before: float = float(state["player"]["economy"]["accounts"]["wallet_cash"])
	var result: Dictionary = economy.purchase(state, "mariner_market", "food_granola_bar", 1)
	_expect(result.get("ok", false), "An open data-driven store can sell an in-stock item.")
	state = result["state"]
	_expect(_stack_quantity(state, "kitchen_storage", "food_granola_bar") == granola_before + 1, "Purchased food is delivered to kitchen storage.")
	_expect(is_equal_approx(float(state["player"]["economy"]["accounts"]["wallet_cash"]), wallet_before - 2.5), "Tax-exempt groceries use the authored base price and payment priority.")
	_expect(state["player"]["economy"]["receipts"].size() == 1 and float(state["player"]["economy"]["receipts"][0]["tax"]) == 0.0, "Purchases save an itemized phone receipt with grocery tax exemption.")
	_expect(float(economy.current_budget_summary(state).get("purchases", 0.0)) == 2.5, "The live weekly budget includes store spending.")
	state["player"]["education"]["enrolled"] = true
	var bookshop: Dictionary = economy.store_listing(state, "westshore_bookshop")
	_expect(float(bookshop.get("discount_percent", 0.0)) == 10.0, "Active students receive the authored Westshore store discount.")
	_expect(float(bookshop.get("items", [])[0].get("price", {}).get("total", 0.0)) == 3.85, "Store quotes apply student discount before the authored seven-percent sales tax.")
	var failed_state: Dictionary = factory.create_new_game({}, {"random_seed": 1202})
	failed_state["player"]["economy"]["accounts"].merge({"wallet_cash": 0.0, "checking": 0.0, "savings": 0.0, "credit_card": -1000.0}, true)
	var failed_quantity: int = _stack_quantity(failed_state, "kitchen_storage", "food_granola_bar")
	result = economy.purchase(failed_state, "mariner_market", "food_granola_bar", 1)
	_expect(not result.get("ok", true) and _stack_quantity(failed_state, "kitchen_storage", "food_granola_bar") == failed_quantity, "A declined purchase does not mutate inventory or financial state.")

	state = factory.create_new_game({}, {"random_seed": 1203})
	state["player"]["education"]["enrolled"] = true
	state["player"]["education"]["enrollment_date"] = "Y1-08-20"
	_set_test_date(state, "Y1-08-27", "tuesday")
	var checking_before_allowance: float = float(state["player"]["economy"]["accounts"]["checking"])
	result = economy.sync_economy(state)
	_expect(result.get("ok", false), "The economy synchronizes every elapsed due date.")
	state = result["state"]
	_expect(float(state["player"]["economy"]["accounts"]["checking"]) == checking_before_allowance + 100.0, "A standard-background student receives the authored weekly allowance.")
	_expect(str(state["player"]["economy"]["ledger"][-1].get("date", "")) == "Y1-08-26", "Catch-up processing preserves the allowance's actual due date in the ledger.")
	_expect(state["player"]["economy"]["weekly_summaries"].size() == 1, "Monday processing closes and stores the previous weekly budget summary.")
	_expect(float(state["player"]["economy"]["weekly_summaries"][0].get("ending_balance", 0.0)) == 1500.0, "A catch-up weekly summary reconstructs its historical ending balance without later transactions.")
	var recurring_count: int = state["player"]["economy"]["recurring_transactions"].size()
	result = economy.sync_economy(state)
	state = result["state"]
	_expect(state["player"]["economy"]["recurring_transactions"].size() == recurring_count, "Repeated synchronization never duplicates a recurring transaction.")

	state = factory.create_new_game({}, {"random_seed": 1204})
	state["player"]["housing"]["monthly_rent"] = 250.0
	state["player"]["economy"]["accounts"].merge({"wallet_cash": 0.0, "checking": 0.0, "savings": 0.0, "credit_card": 0.0}, true)
	_set_test_date(state, "Y1-09-01", "sunday")
	var trust_before_rent: float = float(state["relationships"]["elena_reyes_hale"]["trust"])
	result = economy.sync_economy(state)
	_expect(result.get("ok", false), "An unaffordable rent due date is processed as a missed obligation.")
	state = result["state"]
	_expect(float(state["player"]["housing"]["rent_balance"]) == 250.0, "Missed household rent becomes an outstanding balance.")
	_expect(float(state["relationships"]["elena_reyes_hale"]["trust"]) == trust_before_rent - 2.0, "Missing rent applies Elena's authored trust consequence.")
	result = economy.pay_outstanding_rent(state)
	_expect(result.get("ok", false), "Outstanding rent can be paid later using the available payment priority.")
	state = result["state"]
	_expect(float(state["player"]["housing"]["rent_balance"]) == 0.0 and float(state["player"]["economy"]["accounts"]["credit_card"]) == -250.0, "A manual rent payment clears arrears and records credit-card debt when needed.")

	state = factory.create_new_game({}, {"random_seed": 1205})
	state["player"]["economy"]["accounts"]["credit_card"] = -100.0
	state["player"]["economy"]["last_sync_date"] = "Y1-09-14"
	_set_test_date(state, "Y1-09-15", "sunday")
	var credit_before: int = int(state["player"]["economy"]["credit_score"])
	result = economy.sync_economy(state)
	state = result["state"]
	_expect(float(state["player"]["economy"]["accounts"]["credit_card"]) == -75.0 and float(state["player"]["economy"]["accounts"]["checking"]) == 600.0, "The monthly credit-card minimum transfers from checking to the card.")
	_expect(int(state["player"]["economy"]["credit_score"]) == credit_before + 3, "An on-time card minimum improves credit score.")

	state = factory.create_new_game({}, {"random_seed": 1206})
	state["player"]["economy"]["debts"].append({"id": "student-loan-test", "type": "student_loan", "principal": 4000.0, "balance": 4000.0})
	state["player"]["education"]["student_debt"] = 4000.0
	state["player"]["economy"]["last_sync_date"] = "Y1-08-31"
	_set_test_date(state, "Y1-09-01", "sunday")
	result = economy.sync_economy(state)
	state = result["state"]
	_expect(float(state["player"]["education"]["student_debt"]) == 4015.0, "Monthly student-loan interest accrues at the authored annual rate.")

	state = factory.create_new_game({}, {"random_seed": 1207})
	state["player"]["education"]["load"] = "full_time"
	state["player"]["education"]["tuition_plan"] = "aid_pending"
	state["player"]["flags"]["education.financial_aid_resolved"] = true
	result = economy.sync_economy(state)
	state = result["state"]
	_expect(float(state["player"]["education"]["financial_aid_award"]) == 1600.0 and float(state["player"]["education"]["tuition_balance"]) == 2400.0, "Resolved aid applies the authored award for the player's financial background.")
	result = economy.pay_tuition(state, 100.0)
	_expect(result.get("ok", false), "An outstanding tuition balance accepts a partial payment.")
	state = result["state"]
	_expect(float(state["player"]["education"]["tuition_balance"]) == 2300.0, "Partial tuition payments reduce the balance without rewriting prior ledger entries.")
	_expect(str(state["player"]["economy"]["ledger"][-1].get("category", "")) == "tuition", "Tuition payments use their dedicated immutable ledger category.")


func _test_housing_qualification_contracts_and_moving() -> void:
	var factory: RefCounted = NewGameStateFactoryScript.new(_registry)
	var simulation: RefCounted = SimulationEngineScript.new(_registry)
	var housing: RefCounted = HousingEngineScript.new(_registry, simulation)
	var economy: RefCounted = EconomyEngineScript.new(_registry, simulation)
	var state: Dictionary = factory.create_new_game({}, {"random_seed": 1401})
	state["player"]["phone"]["unlocked_apps"].erase("housing")
	var sync_result: Dictionary = housing.sync_housing(state)
	state = sync_result["state"]
	_expect("housing" in state["player"]["phone"]["unlocked_apps"] and state["player"]["housing"].get("contracts", []) is Array, "Opening the phone upgrades an older runtime state with Housing access and contract storage.")
	var report: Dictionary = housing.qualification_report(state, "cypress_student_room")
	_expect(not bool(report.get("qualified", true)) and "enrollment" in str(report.get("failures", [])).to_lower(), "The student dorm clearly rejects a player who is not enrolled.")
	state["player"]["education"]["enrolled"] = true
	state["player"]["education"]["enrollment_date"] = "Y1-08-20"
	state["player"]["housing"]["monthly_rent"] = 250.0
	state["player"]["housing"]["monthly_housing_cost"] = 250.0
	report = housing.qualification_report(state, "cypress_student_room")
	_expect(bool(report.get("qualified", false)) and float(report.get("upfront_cost", 0.0)) == 1450.0, "Enrollment, credit, and liquid funds qualify the player for the authored dorm upfront cost.")
	var result: Dictionary = housing.acquire(state, "cypress_student_room")
	_expect(result.get("ok", false), "A qualified player can sign the Cypress Hall lease.")
	state = result["state"]
	_expect(state["player"]["housing"]["contracts"].size() == 1 and state["player"]["housing"]["leases"].size() == 1, "Dorm acquisition creates one durable contract and lease.")
	_expect(is_equal_approx(float(state["player"]["economy"]["accounts"]["wallet_cash"]) + float(state["player"]["economy"]["accounts"]["checking"]) + float(state["player"]["economy"]["accounts"]["savings"]), 50.0), "Housing acquisition splits the upfront cost across the authored cash-account priority.")
	result = housing.move_to(state, "cypress_student_room")
	_expect(result.get("ok", false), "The player can move into an acquired dorm room.")
	state = result["state"]
	_expect(state["player"]["housing"]["residence"] == "cypress_hall_dorm" and state["world_state"]["current_location"] == "cypress_hall_dorm.available_room", "Moving changes the active residence and exact VN room.")
	_expect(state["household_state"]["members"] == ["player"] and state["player"]["housing"]["move_history"].size() == 1, "Moving creates an independent household and durable move history.")
	_expect(_inventory_container_for_test(state, "wardrobe_storage").get("access", "") == "cypress_hall_dorm.available_room", "Moving redirects wardrobe access to the new residence.")
	result = housing.return_to_family_home(state)
	_expect(result.get("ok", false), "The player can move back to the family home without cancelling the lease.")
	state = result["state"]
	_expect(state["player"]["housing"]["residence"] == "hale_home" and state["household_state"]["members"].size() == 4, "Returning home restores the Hale household snapshot.")
	_expect(float(state["player"]["housing"]["monthly_rent"]) == 250.0, "Returning home restores the existing family rent agreement (actual $%.2f)." % float(state["player"]["housing"]["monthly_rent"]))
	_expect(state["player"]["housing"]["contracts"].size() == 1 and _inventory_container_for_test(state, "wardrobe_storage").get("access", "") == "hale_home.player_bedroom", "Returning home preserves the lease and restores family-home storage access.")

	state = factory.create_new_game({}, {"random_seed": 1402})
	state["player"]["economy"]["accounts"].merge({"wallet_cash": 0.0, "checking": 50000.0, "savings": 0.0}, true)
	state["player"]["economy"]["credit_score"] = 700
	state["player"]["employment"]["active_jobs"].append({"id": "housing-income", "status": "active", "hourly_pay": 30.0, "weekly_hours": 40.0})
	report = housing.qualification_report(state, "harbor_view_starter_condo")
	_expect(bool(report.get("qualified", false)) and float(report.get("monthly_income", 0.0)) == 5200.0, "Documented job income, credit, and savings qualify the player for the starter condo.")
	result = housing.acquire(state, "harbor_view_starter_condo")
	_expect(result.get("ok", false), "A qualified player can purchase the starter condo.")
	state = result["state"]
	_expect(state["player"]["housing"]["owned_properties"].size() == 1 and float(state["player"]["housing"]["contracts"][0]["mortgage_balance"]) == 256500.0, "Condo purchase records ownership and the financed mortgage balance.")
	result = housing.move_to(state, "harbor_view_starter_condo")
	state = result["state"]
	_expect(result.get("ok", false) and state["world_state"]["current_location"] == "harbor_view_condos.bedroom", "The owned condo exposes its authored rooms through the VN location scene.")
	var principal_before: float = float(state["player"]["housing"]["contracts"][0]["mortgage_balance"])
	_set_test_date(state, "Y1-09-01", "sunday")
	result = economy.sync_economy(state)
	_expect(result.get("ok", false), "The economy processes an acquired property's first monthly payment.")
	state = result["state"]
	_expect(float(state["player"]["housing"]["contracts"][0]["mortgage_balance"]) < principal_before, "An on-time mortgage payment reduces principal after interest.")
	_expect(state["player"]["housing"]["payment_history"].size() == 1 and str(state["player"]["housing"]["payment_history"][0]["status"]) == "paid", "Housing payment history records the monthly result exactly once.")
	var recurring_count: int = state["player"]["economy"]["recurring_transactions"].size()
	result = economy.sync_economy(state)
	_expect(result["state"]["player"]["economy"]["recurring_transactions"].size() == recurring_count, "Repeated economy synchronization never duplicates a housing payment.")


func _test_character_creation_scene() -> void:
	var creation_scene: PackedScene = load("res://scenes/creation/character_creation.tscn")
	_expect(creation_scene != null, "Character creation scene loads.")
	if creation_scene == null:
		return
	var instance: Node = creation_scene.instantiate()
	_expect(instance.get_node_or_null("PageMargin/Page/CreationTabs/Identity/Fields/FirstName") != null, "Creation scene contains identity fields.")
	_expect(instance.get_node_or_null("PageMargin/Page/CreationTabs/Identity/Fields/BirthFields/MonthField/BirthMonth") != null, "Creation scene contains a birthday month dropdown.")
	_expect(instance.get_node_or_null("PageMargin/Page/CreationTabs/Identity/Fields/BirthFields/DayField/BirthDay") != null, "Creation scene contains a birthday day dropdown.")
	_expect(instance.get_node_or_null("PageMargin/Page/CreationTabs/Appearance/Fields/Grid/FaceOption") != null, "Creation scene contains appearance options.")
	_expect(instance.get_node_or_null("PageMargin/Page/CreationTabs/Traits/Scroll/Fields/PositiveOptions") != null, "Creation scene contains trait selection.")
	_expect(instance.get_node_or_null("PageMargin/Page/CreationTabs/LifeDetails/Scroll/Fields/ArchetypeOptions") != null, "Creation scene contains direct archetype choices.")
	_expect(instance.get_node_or_null("PageMargin/Page/CreationTabs/BackgroundAndReview/Columns/ReviewColumn/ReviewText") != null, "Creation scene contains confirmation review.")
	root.add_child(instance)
	var month_option: OptionButton = instance.get_node("PageMargin/Page/CreationTabs/Identity/Fields/BirthFields/MonthField/BirthMonth")
	var day_option: OptionButton = instance.get_node("PageMargin/Page/CreationTabs/Identity/Fields/BirthFields/DayField/BirthDay")
	var archetype_grid: GridContainer = instance.get_node("PageMargin/Page/CreationTabs/LifeDetails/Scroll/Fields/ArchetypeOptions")
	_expect(month_option.item_count == 12, "Birthday dropdown contains all twelve months.")
	_expect(day_option.item_count == 31 and day_option.get_selected_id() == 17, "Birthday day dropdown starts with the valid March day range.")
	_expect(archetype_grid.get_child_count() == 6, "All authored archetypes are visible as selectable buttons.")
	if archetype_grid.get_child_count() > 0:
		var archetype_button: Button = archetype_grid.get_child(0)
		archetype_button.emit_signal("pressed")
		_expect(instance.call("_build_choices").get("archetype", "") == "the_planner", "Selecting an archetype button stores the choice.")
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
	_expect(tests.size() == 65, "Acceptance suite contains 65 cases.")
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
	_expect(_registry.get_document_count() == 43, "Registry loads all 43 source documents.")
	_expect(_registry.get_package_count() == 26, "Registry indexes all 26 global packages.")
	_expect(_registry.get_all("locations").size() == 62, "Registry indexes all 62 locations.")
	_expect(_registry.get_all("districts").size() == 10, "Registry indexes all 10 districts.")
	_expect(_registry.get_character("elena_reyes_hale") is Dictionary, "Characters can be retrieved by id.")
	_expect(_registry.get_location("hale_home") is Dictionary, "Locations can be retrieved by id.")
	_expect(_registry.get_content("quests", "opening_future_choice") is Dictionary, "Quests can be retrieved by id.")
	_expect(_registry.get_all("operations").size() == 65, "Registry indexes all 65 simulation operations.")
	_expect(_registry.get_all("date_activities").size() == 3, "Registry indexes all three opening date activities.")
	_expect(_registry.get_all("vn_backgrounds").size() == 15, "Registry indexes the initial fifteen VN background assignments.")
	var emma_assets: Dictionary = _registry.get_character("emma_rowan").get("asset_refs", {})
	_expect(not emma_assets.get("portraits", []).is_empty() and str(emma_assets["portraits"][0].get("id", "")) == "default", "Character packages declare their own default portrait artwork.")
	var quest_rules: Dictionary = _registry.get_package("port_alder_sandbox_quest_system")
	_expect(quest_rules.get("default_timing", "") == "open_ended", "Quest progression defaults to open-ended sandbox timing.")
	_expect(bool(quest_rules.get("tracker_rules", {}).get("player_controls_tracking", false)), "Sandbox rules give the player control of quest tracking.")
	_expect(bool(quest_rules.get("repeatable_quest_rules", {}).get("authored_requirements_rechecked_before_every_run", false)), "Repeatable quest runs recheck all authored requirements.")
	_expect(_registry.get_content("quests", "build_a_training_rhythm") is Dictionary and _registry.get_content("quests", "consistency_under_pressure") is Dictionary, "Registry indexes both counted stages of Rachel's repeatable training chain.")
	_expect(_registry.get_all("actions").size() == 10, "Registry indexes all 10 initial home actions.")
	_expect(_registry.get_all("city_interactions").size() == 9, "Registry indexes all nine opening city interactions.")
	_expect(_registry.get_all("phone_apps").size() == 14, "Registry indexes the foundation apps plus Education, Jobs, Money, Housing, and Shopping.")
	_expect(_registry.get_all("housing_listings").size() == 3, "Registry indexes the dorm, affordable studio, and starter condo listings.")


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
	_expect("jobs" in state["player"]["phone"]["unlocked_apps"], "The Jobs app is available from the start.")
	_expect("money" in state["player"]["phone"]["unlocked_apps"], "The Money app is available from the start.")
	_expect("housing" in state["player"]["phone"]["unlocked_apps"], "The Housing app is available from the start.")
	_expect("shopping" not in state["player"]["phone"]["unlocked_apps"], "Shopping remains tied to the authored wardrobe tutorial unlock.")
	_expect(state["relationships"].size() == 15, "Relationship defaults initialize for every opening character.")
	_expect(state["relationships"]["emma_rowan"].get("dating_history", []) is Array, "Relationship runtime state initializes date history.")
	_expect(state["relationships"]["emma_rowan"].get("dating_agreement", {}).get("status", "") == "none", "Relationships begin without an assumed dating agreement.")
	_expect(state["world_state"]["weather"]["condition"] == "partly_cloudy", "Opening weather initializes from the calendar.")
	_expect(state["content_state"]["loaded_packages"].size() == 26, "Runtime state records its loaded content manifest.")
	_expect(state["content_state"]["package_manifest"].size() == 26, "Runtime state records versioned manifest details for every loaded package.")
	_expect(str(state["content_state"]["package_manifest"][0].get("checksum", "")).length() == 64, "Content manifest entries include SHA-256 package checksums.")
	_expect(state["world_state"]["random_seed"] == 12345, "Runtime random seed can be reproduced.")
	_expect(state["quest_state"].get("discovered", []) == ["opening_future_choice"], "Only the opening quest is discovered in a fresh game.")
	_expect(state["quest_state"].get("available", []).is_empty(), "A fresh game has no unsolicited quest offers.")
	_expect(state["quest_state"].get("discovery_history", []).size() == 1, "Initial quest discovery has durable provenance.")
	_expect(state["quest_state"].get("tracked", []).is_empty(), "A new game does not assign or pin quests for the player.")
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
	_expect(validator.birth_date_for_birthday(8, 20) == "2008-08-20", "Opening-day birthday produces the correct age-18 birth year.")
	_expect(validator.birth_date_for_birthday(8, 21) == "2007-08-21", "A birthday after opening day rolls into the prior birth year.")
	_expect(validator.birth_date_for_birthday(2, 29) == "2008-02-29", "Leap day is available as a valid age-18 birthday.")
	var selectable_birthdays: int = 0
	var all_birthdays_are_eighteen: bool = true
	for month: int in range(1, 13):
		for day: int in validator.valid_birth_days(month):
			selectable_birthdays += 1
			var generated_birth_date: String = validator.birth_date_for_birthday(month, day)
			if validator.age_on_opening_date(generated_birth_date) != 18:
				all_birthdays_are_eighteen = false
	_expect(selectable_birthdays == 366 and all_birthdays_are_eighteen, "Every real month/day choice, including February 29, generates an age-18 birth date.")

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


func _test_relationship_dating_agreements_and_conflicts() -> void:
	var factory: RefCounted = NewGameStateFactoryScript.new(_registry)
	var simulation: RefCounted = SimulationEngineScript.new(_registry)
	var relationships: RefCounted = RelationshipEngineScript.new(_registry, simulation)
	var state: Dictionary = factory.create_new_game({}, {"random_seed": 221, "save_id": "relationship-test"})

	var options: Array = relationships.invitation_options(state, "emma_rowan", "waterfront_walk", 3)
	_expect(not options.is_empty(), "Emma offers date times around her authored school schedule.")
	var contains_school_conflict: bool = false
	for option_value: Variant in options:
		if option_value is Dictionary and str(option_value.get("weekday", "")) == "tuesday" and str(option_value.get("block", "")) == "afternoon":
			contains_school_conflict = true
	_expect(not contains_school_conflict, "Date invitations exclude an NPC's unavailable school blocks.")
	if options.is_empty():
		return
	var option: Dictionary = options[0]
	var result: Dictionary = relationships.ask_out(
		state, "emma_rowan", "waterfront_walk", str(option["date"]), str(option["weekday"]), str(option["block"]), true
	)
	_expect(result.get("ok", false) and result.get("data", {}).get("accepted", false), "A compatible character can accept a scored date invitation.")
	if not result.get("ok", false) or not result.get("data", {}).get("accepted", false):
		return
	state = result["state"]
	var emma_event: Dictionary = result["data"]["calendar_event"]
	_expect(bool(emma_event.get("relationship_date", false)), "An accepted invitation creates a tagged calendar date.")
	_set_test_date(state, str(emma_event["date"]), str(emma_event["weekday"]), str(emma_event["block"]))
	state["world_state"]["current_location"] = str(emma_event["location"])
	var friendship_before: float = float(state["relationships"]["emma_rowan"]["friendship"])
	result = relationships.complete_date(state, str(emma_event["id"]), "attentive")
	_expect(result.get("ok", false), "A scheduled date can begin at the correct time and room.")
	if not result.get("ok", false):
		return
	state = result["state"]
	_expect(_calendar_event_status(state, str(emma_event["id"])) == "completed", "Completing a date closes its calendar event.")
	_expect(state["relationships"]["emma_rowan"]["dating_history"].size() == 1, "A completed date is recorded in relationship history.")
	_expect(float(state["relationships"]["emma_rowan"]["friendship"]) > friendship_before, "The chosen date approach changes relationship meters.")
	_expect(state["relationships"]["emma_rowan"]["relationship_stage"] == "dating", "A completed date organically advances the relationship stage.")
	_expect(int(state["relationships"]["emma_rowan"]["unlocked_chapter_level"]) == 2, "Due diligence unlocks Emma's second authored relationship chapter.")

	state["relationships"]["emma_rowan"]["dating_history"].append({"id": "second-emma-date", "outcome": "completed"})
	result = relationships.propose_agreement(state, "emma_rowan", "exclusive")
	_expect(result.get("ok", false) and result.get("data", {}).get("accepted", false), "Trust and shared dates unlock a mutual exclusivity conversation.")
	state = result.get("state", state)
	_expect(state["relationships"]["emma_rowan"]["dating_agreement"].get("type", "") == "exclusive", "Accepted dating agreements persist their negotiated type.")

	options = relationships.invitation_options(state, "marcus_lee", "movie_date", 2)
	_expect(not options.is_empty(), "Marcus offers movie dates outside his work and class schedule.")
	if not options.is_empty():
		option = options[0]
		result = relationships.ask_out(
			state, "marcus_lee", "movie_date", str(option["date"]), str(option["weekday"]), str(option["block"]), false
		)
		_expect(result.get("ok", false) and result.get("data", {}).get("accepted", false), "A second romantic interest can accept a date while another agreement exists.")
		if result.get("ok", false) and result.get("data", {}).get("accepted", false):
			state = result["state"]
			var marcus_event: Dictionary = result["data"]["calendar_event"]
			state["relationships"]["claire_donovan"]["relationship_stage"] = "committed"
			state["relationships"]["claire_donovan"]["dating_agreement"] = {"status": "active", "type": "exclusive"}
			_set_test_date(state, str(marcus_event["date"]), str(marcus_event["weekday"]), str(marcus_event["block"]))
			state["world_state"]["current_location"] = str(marcus_event["location"])
			result = relationships.complete_date(state, str(marcus_event["id"]), "attentive", {"force_witnesses": ["claire_donovan"]})
			_expect(result.get("ok", false), "A public date resolves an authored witness reaction.")
			state = result.get("state", state)
			_expect(state["relationships"]["claire_donovan"]["relationship_stage"] == "ended", "A highly jealous partner can end an exclusive relationship after witnessing another date.")
			_expect(state["relationships"]["claire_donovan"]["conflict_history"].size() == 1, "Witnessed dating conflicts retain their reaction and outcome history.")

	var open_state: Dictionary = factory.create_new_game({}, {"random_seed": 222})
	open_state["relationships"]["marcus_lee"]["relationship_stage"] = "committed"
	open_state["relationships"]["marcus_lee"]["dating_agreement"] = {"status": "active", "type": "open"}
	options = relationships.invitation_options(open_state, "emma_rowan", "waterfront_walk", 1)
	if not options.is_empty():
		option = options[0]
		result = relationships.ask_out(open_state, "emma_rowan", "waterfront_walk", str(option["date"]), str(option["weekday"]), str(option["block"]), true)
		if result.get("ok", false) and result.get("data", {}).get("accepted", false):
			open_state = result["state"]
			var disclosed_event: Dictionary = result["data"]["calendar_event"]
			_set_test_date(open_state, str(disclosed_event["date"]), str(disclosed_event["weekday"]), str(disclosed_event["block"]))
			open_state["world_state"]["current_location"] = str(disclosed_event["location"])
			result = relationships.complete_date(open_state, str(disclosed_event["id"]), "attentive", {"force_witnesses": ["marcus_lee"]})
			open_state = result.get("state", open_state)
			var marcus_conflicts: Array = open_state["relationships"]["marcus_lee"]["conflict_history"]
			_expect(result.get("ok", false) and not marcus_conflicts.is_empty() and marcus_conflicts.back().get("outcome", "") == "liked_it", "A disclosed open agreement can produce a character-specific positive reaction.")

	var missed_state: Dictionary = factory.create_new_game({}, {"random_seed": 223})
	options = relationships.invitation_options(missed_state, "emma_rowan", "waterfront_walk", 1)
	if not options.is_empty():
		option = options[0]
		result = relationships.ask_out(missed_state, "emma_rowan", "waterfront_walk", str(option["date"]), str(option["weekday"]), str(option["block"]), true)
		if result.get("ok", false) and result.get("data", {}).get("accepted", false):
			missed_state = result["state"]
			var missed_event: Dictionary = result["data"]["calendar_event"]
			var trust_before_no_show: float = float(missed_state["relationships"]["emma_rowan"]["trust"])
			_set_test_date(missed_state, str(missed_event["date"]), str(missed_event["weekday"]), "night")
			result = relationships.synchronize(missed_state)
			missed_state = result.get("state", missed_state)
			_expect(result.get("ok", false) and _calendar_event_status(missed_state, str(missed_event["id"])) == "missed", "An overdue scheduled date resolves as a no-show.")
			_expect(float(missed_state["relationships"]["emma_rowan"]["trust"]) == trust_before_no_show - 7.0, "Missing a date applies the authored trust consequence.")


func _test_sandbox_quest_progression_and_tracking() -> void:
	var factory: RefCounted = NewGameStateFactoryScript.new(_registry)
	var simulation: RefCounted = SimulationEngineScript.new(_registry)
	var quests: RefCounted = QuestEngineScript.new(_registry, simulation)
	var state: Dictionary = factory.create_new_game({}, {"random_seed": 230, "save_id": "sandbox-quest-test"})
	var rules: Dictionary = _registry.get_package("port_alder_sandbox_quest_system")
	_expect(rules.get("default_timing", "") == "open_ended", "Quests are open-ended unless an author explicitly declares supported timing.")
	_expect(bool(rules.get("path_rules", {}).get("no_weekly_quest_assignment", false)), "Sandbox rules forbid weekly quest assignment.")
	_expect(bool(rules.get("deadline_rules", {}).get("silent_expiration_forbidden", false)), "Sandbox rules forbid silent quest expiration.")
	_expect(int(rules.get("deadline_rules", {}).get("recommended_timed_maximum_percent", 0)) == 15, "Timed quests are capped at a rare authoring target.")

	var result: Dictionary = simulation.apply_operation(state, "quest.set_tracked", {
		"quest_id": "opening_future_choice", "tracked": true,
	}, "test.quest_tracker")
	_expect(result.get("ok", false), "The player can track a discovered active quest.")
	state = result.get("state", state)
	_expect(state["quest_state"].get("tracked", []) == ["opening_future_choice"], "Tracked quest state is saved independently from active progression.")

	result = simulation.apply_operation(state, "time.advance", {"blocks": 70}, "test.sandbox_time")
	_expect(result.get("ok", false), "Sandbox time can advance beyond the opening week without a planning gate.")
	state = result.get("state", state)
	_expect("opening_future_choice" in state["quest_state"]["active"], "An open-ended quest remains active after unrelated weeks pass.")
	_expect("opening_future_choice" in state["quest_state"]["tracked"], "Time passing does not change the player's tracking choice.")
	_expect(not state.has("weekly_review_state"), "Runtime state contains no forced weekly-review system.")

	result = simulation.apply_operation(state, "quest.set_tracked", {
		"quest_id": "opening_future_choice", "tracked": false,
	}, "test.quest_tracker")
	_expect(result.get("ok", false), "The player can untrack a quest without abandoning it.")
	state = result.get("state", state)
	_expect(state["quest_state"].get("tracked", []).is_empty() and "opening_future_choice" in state["quest_state"]["active"], "Untracked quests continue normally.")

	result = simulation.apply_operation(state, "quest.set_tracked", {
		"quest_id": "enroll_at_westshore", "tracked": true,
	}, "test.quest_tracker")
	_expect(not result.get("ok", true), "Undiscovered or inactive quests cannot be exposed by the tracker.")

	var gated_state: Dictionary = factory.create_new_game({}, {"random_seed": 232})
	gated_state["player"]["attributes"]["health"] = 10
	result = quests.record_event(gated_state, "location_discovered", {"location": "forge_fitness"}, "test.discovery")
	gated_state = result.get("state", gated_state)
	_expect("first_rep" in gated_state["quest_state"]["discovered"] and "first_rep" not in gated_state["quest_state"]["available"], "Exploration can reveal a quest while an authored stat gate keeps it unavailable.")
	var report: Dictionary = quests.gate_report(gated_state, "first_rep")
	_expect(not report.get("met", true) and "Health 20" in str(report.get("visible_failures", [""])[0]), "Visible stat gates explain exactly what the player needs.")
	gated_state["player"]["attributes"]["health"] = 50
	result = quests.sync_availability(gated_state, "test.health_recovered")
	gated_state = result.get("state", gated_state)
	_expect("first_rep" in gated_state["quest_state"]["available"], "Meeting a stat gate makes a discovered quest available without rediscovery.")
	result = quests.postpone_quest(gated_state, "first_rep", "test.postpone")
	gated_state = result.get("state", gated_state)
	_expect("first_rep" in gated_state["quest_state"]["postponed"] and "first_rep" not in gated_state["quest_state"]["available"], "Postponing keeps the quest discovered without accepting it.")
	result = quests.sync_availability(gated_state, "test.postponed_sync")
	gated_state = result.get("state", gated_state)
	_expect("first_rep" not in gated_state["quest_state"]["available"], "A postponed quest is not offered again until the player reconsiders it.")
	result = quests.reconsider_quest(gated_state, "first_rep", "test.reconsider")
	gated_state = result.get("state", gated_state)
	_expect("first_rep" in gated_state["quest_state"]["available"] and "first_rep" not in gated_state["quest_state"]["postponed"], "Reconsidering restores a still-qualified offer.")
	result = quests.accept_quest(gated_state, "first_rep", "test.accept")
	gated_state = result.get("state", gated_state)
	_expect("first_rep" in gated_state["quest_state"]["active"] and "first_rep" not in gated_state["quest_state"]["available"], "Accepting moves an offer into active progression.")
	_expect(gated_state["quest_state"]["decision_history"].size() == 3 and gated_state["quest_state"]["decision_history"].back().get("source", "") == "test.accept", "Postpone, reconsider, and accept decisions retain their source in saved history.")

	var declined_state: Dictionary = factory.create_new_game({}, {"random_seed": 233})
	declined_state["player"]["flags"]["sandbox.active"] = true
	result = quests.sync_automatic_activations(declined_state, "test.sandbox_discovery")
	declined_state = result.get("state", declined_state)
	_expect("before_everything_changes" in declined_state["quest_state"]["available"], "A sandbox event can reveal an organically gated relationship offer.")
	result = quests.decline_quest(declined_state, "before_everything_changes", "test.decline")
	declined_state = result.get("state", declined_state)
	_expect("before_everything_changes" in declined_state["quest_state"]["deferred"] and "before_everything_changes" not in declined_state["quest_state"]["active"], "Declining defers a quest instead of silently starting or failing it.")
	_expect(declined_state["quest_state"]["decision_history"].back().get("decision", "") == "declined", "Declining records a durable player decision.")

	var repeat_state: Dictionary = factory.create_new_game({}, {"random_seed": 234})
	repeat_state["player"]["flags"]["fitness.gym_access"] = true
	repeat_state["player"]["skills"]["fitness_training"] = 10
	result = quests.start_quest(repeat_state, "build_a_training_rhythm", "test.repeatable_start")
	repeat_state = result.get("state", repeat_state)
	_expect(result.get("ok", false) and "build_a_training_rhythm" in repeat_state["quest_state"]["active"], "A qualified counted quest can begin its first run.")
	for completion_number: int in range(1, 6):
		result = quests.record_event(repeat_state, "activity_completed", {"tag": "forge_workout", "activity": "strength_workout"}, "test.repeatable_workout")
		repeat_state = result.get("state", repeat_state)
		var repeat_progress: Dictionary = quests.get_progress(repeat_state, "build_a_training_rhythm")
		_expect(result.get("ok", false) and int(repeat_progress.get("completion_count", -1)) == completion_number, "Counted quest saves valid completion %d/5." % completion_number)
		if completion_number < 5:
			_expect("build_a_training_rhythm" not in repeat_state["quest_state"]["completed"] and repeat_state["quest_state"]["objectives"].get("build_a_training_rhythm", {}).is_empty(), "A nonfinal counted run resets its objectives without marking the chain stage complete.")
			_expect(int(repeat_progress.get("cooldown_remaining_blocks", 0)) == 1, "A counted quest exposes its authored one-block cooldown.")
			repeat_state["player"]["flags"]["fitness.gym_access"] = false
			result = simulation.apply_operation(repeat_state, "time.advance", {"blocks": 1}, "test.repeatable_cooldown")
			repeat_state = result.get("state", repeat_state)
			result = quests.sync_automatic_activations(repeat_state, "test.repeatable_requirement_check")
			repeat_state = result.get("state", repeat_state)
			_expect("build_a_training_rhythm" not in repeat_state["quest_state"]["active"], "A repeatable quest cannot restart when another authored requirement is no longer met.")
			repeat_state["player"]["flags"]["fitness.gym_access"] = true
			result = quests.sync_automatic_activations(repeat_state, "test.repeatable_requirement_restored")
			repeat_state = result.get("state", repeat_state)
			_expect("build_a_training_rhythm" in repeat_state["quest_state"]["active"], "A repeatable quest restarts after its cooldown when every requirement is met again.")
	_expect("build_a_training_rhythm" in repeat_state["quest_state"]["completed"], "The counted stage becomes terminal exactly at 5/5.")
	_expect("consistency_under_pressure" in repeat_state["quest_state"]["active"], "The next quest-chain stage unlocks only after the prior counted target is reached.")
	_expect(repeat_state["quest_state"]["repeatable_progress"]["build_a_training_rhythm"]["completion_history"].size() == 5, "Every counted run retains a durable completion-history entry.")


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


func _test_save_round_trip_rotation_recovery_and_migration() -> void:
	var test_root: String = "user://port_alder_save_engine_tests"
	var slot_ids: Array = ["manual_1", "autosave_0", "autosave_1", "autosave_2", "legacy"]
	_cleanup_save_test_root(test_root, slot_ids)
	var engine: RefCounted = SaveEngineScript.new(test_root)
	var factory: RefCounted = NewGameStateFactoryScript.new(_registry)
	var state: Dictionary = factory.create_new_game({"first_name": "Save", "last_name": "Tester"}, {"random_seed": 2026})
	state["conversation_state"]["active"] = {
		"conversation_id": "opening_future_talk",
		"node_id": "future_choice",
		"applied_nodes": ["elena_opening", "future_choice"],
		"choice_history": [],
		"participants": ["player", "elena_reyes_hale"],
	}
	state["world_state"]["pending_travel"] = {
		"origin": "hale_home",
		"destination": "alder_bay_park",
		"mode": "walking",
		"minutes": 16,
		"remaining_minutes": 9,
		"cost": 0,
		"route_ids": ["hale_home_to_alder_bay_park"],
	}
	state["quest_state"]["tracked"] = ["opening_future_choice"]
	state["quest_state"]["discovered"].append("first_rep")
	state["quest_state"]["postponed"].append("first_rep")
	state["quest_state"]["discovery_history"].append({"quest_id": "first_rep", "source": "save_test", "discovered_on": "Y1-08-20"})
	state["quest_state"]["decision_history"].append({"quest_id": "first_rep", "decision": "postponed", "source": "save_test", "date": "Y1-08-20"})
	state["quest_state"]["repeatable_progress"]["build_a_training_rhythm"] = {
		"completions": 2,
		"target_completions": 5,
		"chain_id": "rachel_training_path",
		"stage": 1,
		"last_completed_at": "Y1-08-20:afternoon+000",
		"last_completed_block": 1627,
		"cooldown_until_block": 1628,
		"completion_history": [
			{"completion": 1, "completed_at": "Y1-08-20:lunch+000", "branch_id": null},
			{"completion": 2, "completed_at": "Y1-08-20:afternoon+000", "branch_id": null},
		],
	}
	state["player"]["housing"]["contracts"].append({
		"id": "housing-save-test", "listing_id": "greyport_affordable_studio", "tenure": "rental", "status": "active",
		"outstanding_balance": 125.0, "mortgage_balance": 0.0, "payment_history": [{"status": "missed", "amount": 125.0}],
	})
	state["player"]["housing"]["move_history"].append({"id": "move-save-test", "from": "hale_home", "to": "greyport_studios"})

	var result: Dictionary = engine.save_slot(state, "manual_1", {
		"timestamp_utc": "2026-08-25T10:00:00",
		"build_version": "test-build",
		"playtime_seconds": 3661,
	})
	_expect(result.get("ok", false), "A complete runtime snapshot saves to a manual slot.")
	_expect(FileAccess.file_exists("%s/manual_1/save.json" % test_root), "A validated save becomes the primary slot file.")
	var loaded: Dictionary = engine.load_slot("manual_1")
	_expect(loaded.get("ok", false), "A saved runtime snapshot loads successfully.")
	_expect(loaded.get("state", {}).get("player", {}).get("identity", {}).get("first_name", "") == "Save", "Save/load round-trip preserves player identity.")
	_expect(int(loaded.get("state", {}).get("metadata", {}).get("playtime_seconds", 0)) == 3661, "Save/load round-trip preserves accumulated playtime.")
	_expect(str(loaded.get("state", {}).get("metadata", {}).get("checksum", "")).length() == 64, "Save snapshots carry a SHA-256 checksum.")
	_expect(loaded.get("summary", {}).get("current_location", "") == "hale_home.player_bedroom", "Slot preview metadata reports the saved location.")
	_expect(loaded.get("state", {}).get("conversation_state", {}).get("active", {}).get("node_id", "") == "future_choice", "Save/load round-trip preserves the exact waiting VN node.")
	_expect(int(loaded.get("state", {}).get("world_state", {}).get("pending_travel", {}).get("remaining_minutes", 0)) == 9, "Save/load round-trip preserves an in-progress trip context.")
	_expect(loaded.get("state", {}).get("quest_state", {}).get("tracked", []) == ["opening_future_choice"], "Save/load round-trip preserves the player's tracked quests.")
	_expect(loaded.get("state", {}).get("quest_state", {}).get("postponed", []) == ["first_rep"], "Save/load round-trip preserves postponed discoveries.")
	_expect(loaded.get("state", {}).get("quest_state", {}).get("decision_history", []).back().get("decision", "") == "postponed", "Save/load round-trip preserves quest decision history.")
	_expect(int(loaded.get("state", {}).get("quest_state", {}).get("repeatable_progress", {}).get("build_a_training_rhythm", {}).get("completions", 0)) == 2, "Save/load round-trip preserves independent repeatable quest counters.")
	_expect(loaded.get("state", {}).get("quest_state", {}).get("repeatable_progress", {}).get("build_a_training_rhythm", {}).get("completion_history", []).size() == 2, "Save/load round-trip preserves repeatable quest completion history.")
	_expect(loaded.get("state", {}).get("player", {}).get("housing", {}).get("contracts", []).size() == 1 and float(loaded.get("state", {}).get("player", {}).get("housing", {}).get("contracts", [])[0].get("outstanding_balance", 0.0)) == 125.0, "Save/load round-trip preserves housing contracts and arrears.")
	_expect(loaded.get("state", {}).get("player", {}).get("housing", {}).get("move_history", []).size() == 1, "Save/load round-trip preserves housing move history.")

	var original_checking: float = float(state["player"]["economy"]["accounts"]["checking"])
	state["player"]["economy"]["accounts"]["checking"] = original_checking + 77.0
	result = engine.save_slot(state, "manual_1", {
		"timestamp_utc": "2026-08-25T10:05:00",
		"build_version": "test-build",
		"playtime_seconds": 3700,
	})
	_expect(result.get("ok", false), "Overwriting a slot safely writes a new snapshot.")
	_expect(FileAccess.file_exists("%s/manual_1/save.json.bak" % test_root), "A prior valid save remains as the slot backup.")
	var corrupt_file: FileAccess = FileAccess.open("%s/manual_1/save.json" % test_root, FileAccess.WRITE)
	if corrupt_file != null:
		corrupt_file.store_string("{corrupted")
		corrupt_file.close()
	loaded = engine.load_slot("manual_1")
	_expect(loaded.get("ok", false) and loaded.get("recovered_from_backup", false), "A corrupt primary save recovers from its validated backup.")
	_expect(is_equal_approx(float(loaded.get("state", {}).get("player", {}).get("economy", {}).get("accounts", {}).get("checking", -1.0)), original_checking), "Backup recovery returns the prior complete snapshot.")
	result = engine.save_slot(state, "manual_1", {
		"timestamp_utc": "2026-08-25T10:06:00",
		"build_version": "test-build",
	})
	_expect(result.get("ok", false), "A new validated save can replace an unreadable primary.")
	_expect(FileAccess.file_exists("%s/manual_1/save.json.corrupt" % test_root), "An unreadable primary is quarantined instead of silently deleted.")
	loaded = engine.load_slot("manual_1")
	_expect(loaded.get("ok", false) and not loaded.get("recovered_from_backup", true), "The replacement becomes the new valid primary while the prior backup remains available.")

	for index: int in 3:
		result = engine.save_slot(factory.create_new_game({}, {"random_seed": 300 + index}), "autosave_%d" % index, {
			"timestamp_utc": "2026-08-25T10:0%d:00" % index,
			"build_version": "test-build",
		})
		_expect(result.get("ok", false), "Autosave rotation slot %d accepts a snapshot." % (index + 1))
	_expect(engine.choose_rotation_slot(["autosave_0", "autosave_1", "autosave_2"]) == "autosave_0", "Autosave rotation selects the oldest of three occupied slots.")
	result = engine.save_slot(factory.create_new_game({}, {"random_seed": 400}), "autosave_0", {
		"timestamp_utc": "2026-08-25T10:10:00",
		"build_version": "test-build",
	})
	_expect(result.get("ok", false), "The oldest autosave can rotate to the newest snapshot.")
	_expect(engine.choose_rotation_slot(["autosave_0", "autosave_1", "autosave_2"]) == "autosave_1", "Autosave rotation advances to the next-oldest slot.")

	var invalid_state: Dictionary = state.duplicate(true)
	invalid_state.erase("player")
	_expect(not engine.save_slot(invalid_state, "invalid_slot").get("ok", true), "Invalid in-memory state is rejected before any save write.")
	var invalid_tracking_state: Dictionary = state.duplicate(true)
	invalid_tracking_state["quest_state"]["tracked"] = ["enroll_at_westshore"]
	_expect(not engine.save_slot(invalid_tracking_state, "invalid_tracking_slot").get("ok", true), "Save validation rejects a tracked quest that is not active.")

	var legacy_state: Dictionary = factory.create_new_game({}, {"random_seed": 501})
	legacy_state["save_format_version"] = 0
	legacy_state["metadata"].erase("checksum")
	legacy_state.erase("content_state")
	var legacy_directory: String = ProjectSettings.globalize_path("%s/legacy" % test_root)
	DirAccess.make_dir_recursive_absolute(legacy_directory)
	var legacy_file: FileAccess = FileAccess.open("%s/legacy/save.json" % test_root, FileAccess.WRITE)
	if legacy_file != null:
		legacy_file.store_string(JSON.stringify(legacy_state, "  ", true, true))
		legacy_file.close()
	loaded = engine.load_slot("legacy")
	_expect(loaded.get("ok", false), "A baseline version-zero save migrates forward after safely backing up its source file.")
	_expect(int(loaded.get("state", {}).get("save_format_version", 0)) == 1, "Migration advances exactly to save format version one.")
	_expect(not loaded.get("state", {}).get("metadata", {}).get("migration_log", []).is_empty(), "Migration records its applied step in loaded state.")
	_expect(loaded.get("state", {}).has("content_state"), "Migration supplies the version-one content-state section.")
	_expect(FileAccess.file_exists("%s/legacy/save.json.bak" % test_root), "Migration preserves the original version-zero file as the slot backup.")
	var legacy_backup: Variant = _parse_json("%s/legacy/save.json.bak" % test_root)
	_expect(legacy_backup is Dictionary and int(legacy_backup.get("save_format_version", -1)) == 0, "Migration backup remains in its original version-zero format.")
	var reloaded_migration: Dictionary = engine.load_slot("legacy")
	_expect(reloaded_migration.get("ok", false) and reloaded_migration.get("migrated_from_version") == null, "A persisted migration is not applied a second time.")
	var save_service: Node = root.get_node_or_null("SaveService")
	_expect(save_service != null and save_service.MANUAL_SLOT_COUNT == 8 and save_service.AUTOSAVE_SLOT_COUNT == 3, "Runtime save service exposes eight manual and three rotating autosave slots.")
	var changed_state: Dictionary = state.duplicate(true)
	changed_state["clock"]["day"] = int(changed_state["clock"]["day"]) + 1
	changed_state["quest_state"]["completed"].append("save_trigger_test")
	changed_state["world_state"]["current_location"] = "alder_bay_park.waterfront_path"
	var trigger_reasons: PackedStringArray = save_service._autosave_reasons(state, changed_state) if save_service != null else PackedStringArray()
	_expect("new_day" in trigger_reasons and "quest_completed" in trigger_reasons and "travel_completed" in trigger_reasons, "Autosave detection covers day boundaries, quest completion, and travel.")
	_cleanup_save_test_root(test_root, slot_ids)


func _cleanup_save_test_root(root_path: String, slot_ids: Array) -> void:
	for slot_id_value: Variant in slot_ids:
		var slot_path: String = ProjectSettings.globalize_path("%s/%s" % [root_path, slot_id_value])
		for file_name: String in ["save.json.tmp", "save.json", "save.json.bak", "save.json.corrupt"]:
			var file_path: String = "%s/%s" % [slot_path, file_name]
			if FileAccess.file_exists(file_path):
				DirAccess.remove_absolute(file_path)
		if DirAccess.dir_exists_absolute(slot_path):
			DirAccess.remove_absolute(slot_path)
	var absolute_root: String = ProjectSettings.globalize_path(root_path)
	if DirAccess.dir_exists_absolute(absolute_root):
		DirAccess.remove_absolute(absolute_root)


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


func _inventory_container_for_test(state: Dictionary, container_id: String) -> Dictionary:
	for container_value: Variant in state["player"]["inventory"].get("containers", []):
		if container_value is Dictionary and str(container_value.get("id", "")) == container_id:
			return container_value
	return {}


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


func _calendar_event_type_count(state: Dictionary, event_type: String) -> int:
	var count: int = 0
	for calendar_event: Variant in state["calendar_state"].get("events", []):
		if calendar_event is Dictionary and str(calendar_event.get("type", "")) == event_type:
			count += 1
	return count


func _first_scheduled_work_event(state: Dictionary, job_id: String) -> Dictionary:
	var first: Dictionary = {}
	for calendar_event: Variant in state["calendar_state"].get("events", []):
		if not calendar_event is Dictionary or str(calendar_event.get("type", "")) != "work" or str(calendar_event.get("job_id", "")) != job_id or str(calendar_event.get("status", "scheduled")) != "scheduled":
			continue
		if first.is_empty() or str(calendar_event.get("date", "")) < str(first.get("date", "")) or (str(calendar_event.get("date", "")) == str(first.get("date", "")) and _test_block_index(str(calendar_event.get("block", ""))) < _test_block_index(str(first.get("block", "")))):
			first = calendar_event
	return first


func _calendar_work_status_count(state: Dictionary, job_id: String, date: String, status: String) -> int:
	var count: int = 0
	for calendar_event: Variant in state["calendar_state"].get("events", []):
		if calendar_event is Dictionary and str(calendar_event.get("type", "")) == "work" and str(calendar_event.get("job_id", "")) == job_id and str(calendar_event.get("date", "")) == date and str(calendar_event.get("status", "")) == status:
			count += 1
	return count


func _active_job_for_test(state: Dictionary, job_id: String) -> Dictionary:
	for active_job: Variant in state["player"]["employment"].get("active_jobs", []):
		if active_job is Dictionary and str(active_job.get("job_id", "")) == job_id:
			return active_job
	return {}


func _create_enrolled_computer_state(random_seed: int) -> Dictionary:
	var factory: RefCounted = NewGameStateFactoryScript.new(_registry)
	var simulation: RefCounted = SimulationEngineScript.new(_registry)
	var quests: RefCounted = QuestEngineScript.new(_registry, simulation)
	var dialogue: RefCounted = DialogueEngineScript.new(_registry, simulation, quests)
	var state: Dictionary = factory.create_new_game({}, {"random_seed": random_seed})
	var result: Dictionary = quests.start_quest(state, "enroll_at_westshore", "test.education_setup")
	state = result["state"]
	state["world_state"]["current_location"] = "westshore_administration_office.advisor_office"
	result = quests.record_event(state, "location_entered", {"location": "westshore_administration_office"}, "test.education_setup")
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
	return result.get("state", {})


func _test_clock_date(state: Dictionary) -> String:
	return "Y%d-%02d-%02d" % [state["clock"]["year"], state["clock"]["month"], state["clock"]["day"]]


func _set_test_date(state: Dictionary, date: String, weekday: String, block: String = "morning") -> void:
	var parts: PackedStringArray = date.trim_prefix("Y").split("-")
	state["clock"]["year"] = int(parts[0])
	state["clock"]["month"] = int(parts[1])
	state["clock"]["day"] = int(parts[2])
	state["clock"]["weekday"] = weekday
	state["clock"]["block"] = block
	state["clock"]["minute_within_block"] = 0


func _test_block_index(block: String) -> int:
	return ["early_morning", "morning", "lunch", "afternoon", "evening", "late_evening", "night"].find(block)


func _employment_application_for_job(state: Dictionary, job_id: String) -> Dictionary:
	for application: Variant in state["player"]["employment"].get("applications", []):
		if application is Dictionary and str(application.get("job_id", "")) == job_id:
			return application
	return {}


func _employment_record(records: Array, record_id: String) -> Dictionary:
	for record: Variant in records:
		if record is Dictionary and str(record.get("id", "")) == record_id:
			return record
	return {}


func _set_clock_to_employment_event(state: Dictionary, event: Dictionary) -> void:
	var parts: PackedStringArray = str(event.get("date", "Y1-08-20")).trim_prefix("Y").split("-")
	state["clock"]["year"] = int(parts[0])
	state["clock"]["month"] = int(parts[1])
	state["clock"]["day"] = int(parts[2])
	state["clock"]["weekday"] = str(event.get("weekday", "wednesday"))
	state["clock"]["block"] = str(event.get("block", "morning"))
	state["clock"]["minute_within_block"] = 0


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
