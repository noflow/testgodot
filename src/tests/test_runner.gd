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
const NavigationAccessScript: GDScript = preload("res://src/world/navigation_access.gd")
const NavigationIntegrityValidatorScript: GDScript = preload("res://src/world/navigation_integrity_validator.gd")
const NpcPresenceEngineScript: GDScript = preload("res://src/world/npc_presence_engine.gd")
const HaleHomeNavigationScript: GDScript = preload("res://src/world/hale_home_navigation.gd")
const CityActionEngineScript: GDScript = preload("res://src/world/city_action_engine.gd")
const EducationEngineScript: GDScript = preload("res://src/education/education_engine.gd")
const EmploymentEngineScript: GDScript = preload("res://src/employment/employment_engine.gd")
const EconomyEngineScript: GDScript = preload("res://src/economy/economy_engine.gd")
const HousingEngineScript: GDScript = preload("res://src/housing/housing_engine.gd")
const SaveEngineScript: GDScript = preload("res://src/save/save_engine.gd")
const RelationshipEngineScript: GDScript = preload("res://src/relationships/relationship_engine.gd")
const ScreenwriterFixtureRegistryScript: GDScript = preload("res://src/tests/screenwriter_fixture_registry.gd")

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
	_test_navigation_integrity()
	_test_new_game_state_factory()
	_test_character_creation_validation()
	_test_clock_and_simulation_engine()
	_test_home_actions_and_wardrobe()
	_test_household_schedules_and_conversations()
	_test_city_travel_and_routes()
	_test_city_npc_presence_and_acquaintances()
	_test_city_institutions_and_fitness()
	_test_district_exploration_and_local_leads()
	_test_playable_education_semester()
	_test_employment_applications_interviews_and_offers()
	_test_recurring_economy_and_shopping()
	_test_housing_qualification_contracts_and_moving()
	_test_save_round_trip_rotation_recovery_and_migration()
	_test_phone_messages_and_calendar()
	_test_screenwriter_phone_bridge()
	_test_relationship_dating_agreements_and_conflicts()
	_test_sandbox_quest_progression_and_tracking()
	_test_opening_dialogue_branches()
	_test_screenwriter_dialogue_bridge()

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
		_expect(dialogue_instance.get_node_or_null("TransitionOverlay") != null, "VN scene contains its Director transition layer.")
		_expect(dialogue_instance.get_node_or_null("MusicPlayer") != null and dialogue_instance.get_node_or_null("AmbiencePlayer") != null and dialogue_instance.get_node_or_null("SfxPlayer") != null, "VN scene contains separate Director music, ambience, and sound-effect players.")
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
	_expect(not elena["present"] and elena["location"] == "st_maren_community_clinic.administrator_office", "Elena is at her clinic during Tuesday Morning.")
	_expect(not daniel["present"] and daniel["location"] == "port_alder_transit_depot.repair_bays", "Daniel is at the transit depot during Tuesday Morning.")
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
	_expect(not lily["present"] and lily["location"] == "westshore_campus.library", "Lily is unavailable during her Tuesday Evening library shift.")
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
	_expect(state["world_state"]["unlocked_locations"].size() == 13, "New games unlock thirteen essential opening destinations while optional districts and private NPC homes remain hidden.")
	_expect("cypress_hall_dorm" in state["world_state"]["unlocked_locations"] and "maple_hall_dorm" in state["world_state"]["unlocked_locations"] and "westshore_bookshop" in state["world_state"]["unlocked_locations"], "The complete public Westshore destination set is known at new game start.")
	var navigation: RefCounted = NavigationAccessScript.new(_registry)
	for district_hub_id: String in ["mariner_row_shopping_street", "greyport_street", "cedar_vale_street", "crown_point_boulevard"]:
		_expect(district_hub_id not in state["world_state"]["unlocked_locations"] and not bool(navigation.location_visibility_report(state, district_hub_id).get("allowed", false)), "Optional district begins hidden until organically discovered: %s" % district_hub_id)
	_expect(not bool(navigation.location_visibility_report(state, "rowan_family_home").get("allowed", false)), "Emma's home is invisible before a quest or invitation reveals it.")
	_expect(not bool(navigation.target_access_report(state, "alder_heights_residential_street", "rowan_family_home.porch").get("allowed", false)), "A hidden residence does not expose its street arrow.")
	_expect("harbor_centre_downtown" not in state["world_state"]["unlocked_locations"] and "port_alder_galleria" not in state["world_state"]["unlocked_locations"], "Harbor Centre and the Galleria begin as organic walking discoveries instead of phone-map shortcuts.")
	var downtown_access: Dictionary = navigation.target_access_report(state, "harbor_employment_centre", "harbor_centre_downtown.employment_block")
	_expect(downtown_access.get("allowed", false) and downtown_access.get("discover_on_entry", false), "The Employment Centre exit exposes adjacent public Harbor Centre space for discovery on entry.")
	var exploration_state: Dictionary = state.duplicate(true)
	exploration_state["world_state"]["current_location"] = "harbor_employment_centre.job_floor"
	var exploration_result: Dictionary = simulation.apply_operation(exploration_state, "world.discover_location", {"location_id": "harbor_centre_downtown", "discovery_source": "exploration"}, "test.harbor_exploration")
	exploration_state = exploration_result.get("state", exploration_state)
	var downtown_plan: Dictionary = travel.plan_routes(exploration_state, "harbor_centre_downtown")
	_expect(exploration_result.get("ok", false) and downtown_plan.get("ok", false) and _route_option(downtown_plan, "walking").get("minutes", 0) == 2, "Walking into Harbor Centre discovers it and connects its two-minute local route.")
	exploration_state["world_state"]["current_location"] = "harbor_centre_downtown.galleria_entrance"
	var galleria_access: Dictionary = navigation.target_access_report(exploration_state, "harbor_centre_downtown", "port_alder_galleria.street_entrance")
	_expect(galleria_access.get("allowed", false) and galleria_access.get("discover_on_entry", false), "The downtown street exposes the public Galleria only when the player reaches its entrance.")
	exploration_result = simulation.apply_operation(exploration_state, "world.discover_location", {"location_id": "port_alder_galleria", "discovery_source": "exploration"}, "test.galleria_exploration")
	exploration_state = exploration_result.get("state", exploration_state)
	var galleria_plan: Dictionary = travel.plan_routes(exploration_state, "port_alder_galleria")
	_expect(exploration_result.get("ok", false) and galleria_plan.get("ok", false) and _route_option(galleria_plan, "walking").get("minutes", 0) == 4, "Discovering the Galleria adds its four-minute downtown walking route to later trip planning.")
	var locked_private_plan: Dictionary = travel.plan_routes(state, "rowan_family_home")
	_expect(not locked_private_plan.get("ok", false), "A hidden residence cannot be reached through a direct route request.")
	var private_state: Dictionary = state.duplicate(true)
	var private_result: Dictionary = simulation.apply_operation(private_state, "world.unlock_location", {"location_id": "rowan_family_home"}, "test.private_address")
	private_state = private_result["state"]
	_expect(not bool(navigation.location_visibility_report(private_state, "rowan_family_home").get("allowed", false)), "Unlocking travel data alone does not reveal a hidden residence.")
	private_result = simulation.apply_operation(private_state, "world.discover_location", {"location_id": "rowan_family_home", "discovery_source": "invitation", "character_id": "emma_rowan"}, "test.home_invitation")
	private_state = private_result["state"]
	_expect(private_result.get("ok", false) and "rowan_family_home" in private_state["world_state"]["discovered_locations"], "An NPC invitation reveals and unlocks their residence.")
	_expect(bool(navigation.location_visibility_report(private_state, "rowan_family_home").get("allowed", false)), "A discovered residence becomes visible on navigation surfaces.")
	_expect(not bool(navigation.room_access_report(private_state, "rowan_family_home", "emma_bedroom").get("allowed", false)), "A home invitation does not automatically grant private-bedroom access.")
	var private_plan: Dictionary = travel.plan_routes(private_state, "rowan_family_home")
	_expect(private_plan.get("ok", false) and _route_option(private_plan, "walking").get("minutes", 0) == 4, "A revealed neighboring residence becomes reachable through the authored travel graph.")
	private_result = simulation.apply_operation(private_state, "world.discover_location", {"location_id": "rowan_family_home", "discovery_source": "invitation", "character_id": "emma_rowan", "room_ids": ["emma_bedroom"]}, "test.private_room_invitation")
	private_state = private_result["state"]
	_expect(bool(navigation.room_access_report(private_state, "rowan_family_home", "emma_bedroom").get("allowed", false)), "A separate authored room grant unlocks the invited private room.")
	_expect(not bool(navigation.room_access_report(state, "harborlight_cinema", "staff_room").get("allowed", false)), "Generic navigation cannot expose an employee-only room to a visitor.")
	for private_home_id: String in [
		"rowan_family_home", "westshore_shared_student_apartment", "jade_downtown_condo",
		"lee_family_apartment", "flores_family_townhouse", "greyport_shared_apartment",
		"donovan_family_apartment", "rachel_cedar_vale_townhouse",
		"hannah_medical_district_apartment", "olivia_crown_point_penthouse",
	]:
		var invited_state: Dictionary = state.duplicate(true)
		var invitation_result: Dictionary = simulation.apply_operation(invited_state, "world.discover_location", {
			"location_id": private_home_id,
			"discovery_source": "invitation",
		}, "test.private_home_route:%s" % private_home_id)
		invited_state = invitation_result.get("state", invited_state)
		var invited_plan: Dictionary = travel.plan_routes(invited_state, private_home_id)
		_expect(invitation_result.get("ok", false) and invited_plan.get("ok", false), "Discovered NPC residence has a connected route: %s" % private_home_id)

	var plan: Dictionary = travel.plan_routes(state, "westshore_administration_office")
	_expect(plan.get("ok", false), "The route planner connects Hale Home to Westshore Administration.")
	_expect(plan.get("options", []).size() == 4, "Westshore Administration offers walking, bus, taxi, and car comparisons.")
	var bus_route: Dictionary = _route_option(plan, "bus")
	_expect(bus_route["minutes"] == 32 and bus_route["cost"] == 3.0, "Bus planning includes the Morning wait and authored fare.")
	_expect(_route_option(plan, "walking")["minutes"] == 48, "Walking uses its authored forty-eight-minute route.")
	var bookshop_plan: Dictionary = travel.plan_routes(state, "westshore_bookshop")
	_expect(bookshop_plan.get("ok", false) and _route_option(bookshop_plan, "walking")["minutes"] == 49, "The route graph reaches the campus bookshop through Westshore.")
	var campus_state: Dictionary = state.duplicate(true)
	campus_state["world_state"]["current_location"] = "westshore_campus.transit_loop"
	var maple_plan: Dictionary = travel.plan_routes(campus_state, "maple_hall_dorm")
	_expect(maple_plan.get("ok", false) and _route_option(maple_plan, "walking")["minutes"] == 8, "The campus transit loop connects to Maple Hall on foot.")
	var after_hours_maple_state: Dictionary = campus_state.duplicate(true)
	after_hours_maple_state["clock"]["block"] = "late_evening"
	after_hours_maple_state["world_state"]["current_location"] = "maple_hall_dorm.lobby"
	var maple_exit_plan: Dictionary = travel.plan_routes(after_hours_maple_state, "westshore_campus.transit_loop")
	var closed_library_plan: Dictionary = travel.plan_routes(after_hours_maple_state, "westshore_campus.library")
	_expect(maple_exit_plan.get("ok", false) and _route_option(maple_exit_plan, "walking").get("available", false), "Maple Hall residents can always leave through the outdoor campus transit loop.")
	_expect(closed_library_plan.get("ok", false) and not _route_option(closed_library_plan, "walking").get("available", true), "After-hours dorm exits do not unlock closed campus interiors.")

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

	var lantern_state: Dictionary = factory.create_new_game({}, {"random_seed": 714})
	lantern_state["clock"]["weekday"] = "thursday"
	lantern_state["clock"]["block"] = "evening"
	lantern_state["world_state"]["current_location"] = "harborlight_cinema.lobby"
	for lantern_location_id: String in ["harborlight_cinema", "lantern_district_street", "la_brisa_kitchen", "lantern_gallery", "tideglass_club", "harbor_companion_cooperative"]:
		var lantern_discovery: Dictionary = simulation.apply_operation(lantern_state, "world.discover_location", {
			"location_id": lantern_location_id,
			"discovery_source": "exploration",
		}, "test.lantern_discovery:%s" % lantern_location_id)
		_expect(lantern_discovery.get("ok", false), "Lantern location supports organic walking discovery: %s" % lantern_location_id)
		lantern_state = lantern_discovery.get("state", lantern_state)
	var street_plan: Dictionary = travel.plan_routes(lantern_state, "lantern_district_street.cinema_block")
	_expect(street_plan.get("ok", false) and _route_option(street_plan, "walking").get("minutes", 0) == 1, "The cinema lobby connects to Lantern District Street with a one-minute walk.")
	var street_result: Dictionary = travel.execute_travel(lantern_state, "lantern_district_street.cinema_block", "walking", "test.lantern_street")
	_expect(street_result.get("ok", false) and str(street_result.get("state", {}).get("world_state", {}).get("current_location", "")) == "lantern_district_street.cinema_block", "Walking out of the cinema arrives on the authored Cinema Block.")
	lantern_state = street_result.get("state", lantern_state)
	for destination: Dictionary in [
		{"id": "la_brisa_kitchen", "minutes": 2},
		{"id": "lantern_gallery", "minutes": 3},
		{"id": "tideglass_club", "minutes": 3},
		{"id": "harbor_companion_cooperative", "minutes": 4},
	]:
		var venue_plan: Dictionary = travel.plan_routes(lantern_state, str(destination["id"]))
		_expect(venue_plan.get("ok", false) and _route_option(venue_plan, "walking").get("minutes", 0) == int(destination["minutes"]), "Lantern District Street has its authored walk to %s." % destination["id"])
	var lantern_access: RefCounted = NavigationAccessScript.new(_registry)
	_expect(bool(lantern_access.room_access_report(lantern_state, "harbor_companion_cooperative", "secure_reception").get("allowed", false)), "The cooperative's secure reception remains a public safety and licensing contact point.")
	_expect(not bool(lantern_access.room_access_report(lantern_state, "harbor_companion_cooperative", "consultation_room").get("allowed", false)) and not bool(lantern_access.room_access_report(lantern_state, "harbor_companion_cooperative", "staff_lounge").get("allowed", false)) and not bool(lantern_access.room_access_report(lantern_state, "harbor_companion_cooperative", "private_suite").get("allowed", false)), "Appointment, licensed-worker, and consenting-adult rooms remain inaccessible without their specific grants.")

	var bay_state: Dictionary = factory.create_new_game({}, {"random_seed": 715})
	bay_state["clock"]["block"] = "afternoon"
	bay_state["world_state"]["current_location"] = "alder_bay_park.waterfront_path"
	for bay_location_id: String in ["alder_bay_park", "alder_bay_beach", "port_alder_marina", "bayview_cafe"]:
		var bay_discovery: Dictionary = simulation.apply_operation(bay_state, "world.discover_location", {
			"location_id": bay_location_id,
			"discovery_source": "exploration",
		}, "test.alder_bay_discovery:%s" % bay_location_id)
		_expect(bay_discovery.get("ok", false), "Alder Bay location supports organic waterfront discovery: %s" % bay_location_id)
		bay_state = bay_discovery.get("state", bay_state)
	for bay_destination: Dictionary in [
		{"id": "alder_bay_beach", "minutes": 2},
		{"id": "bayview_cafe", "minutes": 4},
		{"id": "port_alder_marina", "minutes": 5},
	]:
		var bay_plan: Dictionary = travel.plan_routes(bay_state, str(bay_destination["id"]))
		_expect(bay_plan.get("ok", false) and _route_option(bay_plan, "walking").get("minutes", 0) == int(bay_destination["minutes"]), "Alder Bay Park has its authored waterfront walk to %s." % bay_destination["id"])
	var beach_result: Dictionary = travel.execute_travel(bay_state, "alder_bay_beach.boardwalk", "walking", "test.alder_bay_beach")
	_expect(beach_result.get("ok", false) and str(beach_result.get("state", {}).get("world_state", {}).get("current_location", "")) == "alder_bay_beach.boardwalk", "Walking to the beach arrives on its authored boardwalk entrance.")
	var bay_access: RefCounted = NavigationAccessScript.new(_registry)
	_expect(bool(bay_access.room_access_report(bay_state, "port_alder_marina", "promenade").get("allowed", false)) and not bool(bay_access.room_access_report(bay_state, "port_alder_marina", "marina_office").get("allowed", false)), "The marina promenade is public while its office requires employment or an appointment.")
	var rainy_bay_state: Dictionary = bay_state.duplicate(true)
	rainy_bay_state["world_state"]["weather"]["condition"] = "rain"
	var rainy_walk: Dictionary = travel.plan_routes(rainy_bay_state, "alder_bay_beach")
	_expect("Full weather exposure: rain" in _route_option(rainy_walk, "walking").get("warnings", PackedStringArray()), "Walking between Alder Bay outdoor locations warns about full rain exposure.")

	var mariner_state: Dictionary = factory.create_new_game({}, {"random_seed": 716})
	mariner_state["world_state"]["current_location"] = "hale_home.front_yard"
	var mariner_plan: Dictionary = travel.plan_routes(mariner_state, "mariner_row_shopping_street")
	_expect(not mariner_plan.get("ok", false), "Mariner Row cannot be selected before the player discovers it.")
	var wrong_mariner_source: Dictionary = simulation.apply_operation(mariner_state, "world.discover_location", {"location_id": "mariner_row_shopping_street", "discovery_source": "housing_listing"}, "test.mariner_wrong_source")
	_expect(not wrong_mariner_source.get("ok", false), "A discovery source not authored for Mariner Row cannot reveal it.")
	var mariner_hub_discovery: Dictionary = simulation.apply_operation(mariner_state, "world.discover_location", {"location_id": "mariner_row_shopping_street", "discovery_source": "store_listing"}, "test.mariner_listing")
	mariner_state = mariner_hub_discovery.get("state", mariner_state)
	mariner_plan = travel.plan_routes(mariner_state, "mariner_row_shopping_street")
	_expect(mariner_hub_discovery.get("ok", false) and mariner_plan.get("ok", false) and _route_option(mariner_plan, "walking").get("minutes", 0) == 35 and _route_option(mariner_plan, "bus") is Dictionary, "A shopping listing reveals Mariner Row and its walking and bus routes from home.")
	var mariner_result: Dictionary = travel.execute_travel(mariner_state, "mariner_row_shopping_street", "walking", "test.mariner_row")
	_expect(mariner_result.get("ok", false) and str(mariner_result.get("state", {}).get("world_state", {}).get("current_location", "")) == "mariner_row_shopping_street.transit_stop", "Travel to Mariner Row arrives at its authored transit stop.")
	mariner_state = mariner_result.get("state", mariner_state)
	for mariner_location_id: String in ["mariner_market", "northline_outfitters", "harbor_formalwear", "mariner_home_goods", "port_alder_auto"]:
		var mariner_discovery: Dictionary = simulation.apply_operation(mariner_state, "world.discover_location", {
			"location_id": mariner_location_id,
			"discovery_source": "exploration",
		}, "test.mariner_discovery:%s" % mariner_location_id)
		_expect(mariner_discovery.get("ok", false), "Mariner Row business supports organic storefront discovery: %s" % mariner_location_id)
		mariner_state = mariner_discovery.get("state", mariner_state)
	for mariner_destination: Dictionary in [
		{"id": "mariner_market", "minutes": 1},
		{"id": "northline_outfitters", "minutes": 2},
		{"id": "harbor_formalwear", "minutes": 2},
		{"id": "mariner_home_goods", "minutes": 3},
		{"id": "port_alder_auto", "minutes": 4},
	]:
		var business_plan: Dictionary = travel.plan_routes(mariner_state, str(mariner_destination["id"]))
		_expect(business_plan.get("ok", false) and _route_option(business_plan, "walking").get("minutes", 0) == int(mariner_destination["minutes"]), "Mariner Row street has its authored walk to %s." % mariner_destination["id"])
	var mariner_access: RefCounted = NavigationAccessScript.new(_registry)
	_expect(not bool(mariner_access.room_access_report(mariner_state, "mariner_market", "stockroom").get("allowed", false)), "Mariner Market's stockroom is hidden from ordinary shoppers.")
	var market_employee_state: Dictionary = mariner_state.duplicate(true)
	market_employee_state["player"]["employment"]["active_jobs"].append({"job_id": "grocery_stock_clerk", "status": "active"})
	_expect(bool(mariner_access.room_access_report(market_employee_state, "mariner_market", "stockroom").get("allowed", false)), "A Mariner Market employee can enter the stockroom through the same authored door.")
	var mariner_actions: RefCounted = CityActionEngineScript.new(_registry, simulation, quests)
	mariner_state["world_state"]["current_location"] = "mariner_market.grocery_floor"
	var market_interactions: Array = mariner_actions.interactions_for_room(mariner_state, "mariner_market", "grocery_floor")
	_expect(market_interactions.size() == 1 and str(market_interactions[0].get("store_id", "")) == "mariner_market" and bool(market_interactions[0].get("available", false)), "The physical Mariner Market floor opens its live data-driven storefront.")

	var medical_state: Dictionary = factory.create_new_game({}, {"random_seed": 717})
	medical_state["world_state"]["current_location"] = "hale_home.front_yard"
	var medical_plan: Dictionary = travel.plan_routes(medical_state, "st_maren_medical_center")
	_expect(medical_plan.get("ok", false) and _route_option(medical_plan, "walking").get("minutes", 0) == 42 and _route_option(medical_plan, "bus") is Dictionary, "St. Maren is an opening destination with walking and bus routes from home.")
	var medical_result: Dictionary = travel.execute_travel(medical_state, "st_maren_medical_center", "walking", "test.st_maren")
	_expect(medical_result.get("ok", false) and str(medical_result.get("state", {}).get("world_state", {}).get("current_location", "")) == "st_maren_medical_center.campus_transit_stop", "Travel to St. Maren arrives at its authored campus transit stop.")
	medical_state = medical_result.get("state", medical_state)
	for medical_location_id: String in ["st_maren_community_clinic", "st_maren_doctors_office", "harbor_wellness_therapy", "st_maren_sexual_health", "bay_pharmacy"]:
		var medical_discovery: Dictionary = simulation.apply_operation(medical_state, "world.discover_location", {
			"location_id": medical_location_id,
			"discovery_source": "exploration",
		}, "test.st_maren_discovery:%s" % medical_location_id)
		_expect(medical_discovery.get("ok", false), "St. Maren facility supports organic campus discovery: %s" % medical_location_id)
		medical_state = medical_discovery.get("state", medical_state)
	for medical_destination: Dictionary in [
		{"id": "st_maren_community_clinic", "minutes": 2},
		{"id": "st_maren_doctors_office", "minutes": 2},
		{"id": "harbor_wellness_therapy", "minutes": 3},
		{"id": "st_maren_sexual_health", "minutes": 3},
		{"id": "bay_pharmacy", "minutes": 2},
	]:
		var facility_plan: Dictionary = travel.plan_routes(medical_state, str(medical_destination["id"]))
		_expect(facility_plan.get("ok", false) and _route_option(facility_plan, "walking").get("minutes", 0) == int(medical_destination["minutes"]), "St. Maren campus has its authored walk to %s." % medical_destination["id"])
	var medical_access: RefCounted = NavigationAccessScript.new(_registry)
	_expect(bool(medical_access.room_access_report(medical_state, "st_maren_community_clinic", "reception").get("allowed", false)) and not bool(medical_access.room_access_report(medical_state, "st_maren_community_clinic", "exam_room").get("allowed", false)), "Clinic reception is public while examination rooms require an appointment.")
	_expect(not bool(medical_access.room_access_report(medical_state, "st_maren_medical_center", "staff_station").get("allowed", false)) and not bool(medical_access.room_access_report(medical_state, "st_maren_sexual_health", "testing_room").get("allowed", false)), "Hospital staff and private testing rooms remain hidden without the proper access grant.")
	var clinic_employee_state: Dictionary = medical_state.duplicate(true)
	clinic_employee_state["player"]["employment"]["active_jobs"].append({"job_id": "clinic_records_clerk", "status": "active"})
	_expect(bool(medical_access.room_access_report(clinic_employee_state, "st_maren_community_clinic", "records_office").get("allowed", false)), "A clinic employee can enter the records office through the existing job-location alias.")
	var appointment_state: Dictionary = medical_state.duplicate(true)
	appointment_state["world_state"]["room_access_grants"].append("st_maren_sexual_health.testing_room")
	_expect(bool(medical_access.room_access_report(appointment_state, "st_maren_sexual_health", "testing_room").get("allowed", false)), "A scheduled private-health appointment grants only its authored clinical room.")
	var medical_actions: RefCounted = CityActionEngineScript.new(_registry, simulation, quests)
	medical_state["world_state"]["current_location"] = "bay_pharmacy.sales_floor"
	var pharmacy_interactions: Array = medical_actions.interactions_for_room(medical_state, "bay_pharmacy", "sales_floor")
	_expect(pharmacy_interactions.size() == 1 and str(pharmacy_interactions[0].get("store_id", "")) == "bay_pharmacy" and bool(pharmacy_interactions[0].get("available", false)), "Bay Pharmacy exposes its live physical storefront from the sales floor.")

	var greyport_state: Dictionary = factory.create_new_game({}, {"random_seed": 718})
	greyport_state["world_state"]["current_location"] = "hale_home.front_yard"
	var greyport_plan: Dictionary = travel.plan_routes(greyport_state, "greyport_street")
	_expect(not greyport_plan.get("ok", false), "Greyport cannot be selected before the player discovers it.")
	var greyport_hub_discovery: Dictionary = simulation.apply_operation(greyport_state, "world.discover_location", {"location_id": "greyport_street", "discovery_source": "job_listing"}, "test.greyport_listing")
	greyport_state = greyport_hub_discovery.get("state", greyport_state)
	greyport_plan = travel.plan_routes(greyport_state, "greyport_street")
	_expect(greyport_hub_discovery.get("ok", false) and greyport_plan.get("ok", false) and _route_option(greyport_plan, "walking").get("minutes", 0) == 55 and _route_option(greyport_plan, "bus") is Dictionary, "A job listing reveals Greyport and its walking and bus routes from home.")
	var greyport_result: Dictionary = travel.execute_travel(greyport_state, "greyport_street", "walking", "test.greyport")
	_expect(greyport_result.get("ok", false) and str(greyport_result.get("state", {}).get("world_state", {}).get("current_location", "")) == "greyport_street.bus_exchange", "Travel to Greyport arrives at its authored bus exchange.")
	greyport_state = greyport_result.get("state", greyport_state)
	for greyport_location_id: String in ["greyport_studios", "greyport_distribution", "port_alder_transit_depot", "undertow_nightclub"]:
		var greyport_discovery: Dictionary = simulation.apply_operation(greyport_state, "world.discover_location", {
			"location_id": greyport_location_id,
			"discovery_source": "exploration",
		}, "test.greyport_discovery:%s" % greyport_location_id)
		_expect(greyport_discovery.get("ok", false), "Greyport destination supports organic street discovery: %s" % greyport_location_id)
		greyport_state = greyport_discovery.get("state", greyport_state)
	for greyport_destination: Dictionary in [
		{"id": "greyport_studios", "minutes": 2},
		{"id": "greyport_distribution", "minutes": 4},
		{"id": "port_alder_transit_depot", "minutes": 5},
	]:
		var greyport_destination_plan: Dictionary = travel.plan_routes(greyport_state, str(greyport_destination["id"]))
		_expect(greyport_destination_plan.get("ok", false) and _route_option(greyport_destination_plan, "walking").get("minutes", 0) == int(greyport_destination["minutes"]), "Greyport Main Street has its authored walk to %s." % greyport_destination["id"])
	var closed_undertow_plan: Dictionary = travel.plan_routes(greyport_state, "undertow_nightclub")
	_expect(closed_undertow_plan.get("ok", false) and not _route_option(closed_undertow_plan, "walking").get("available", true) and "Next opening:" in str(_route_option(closed_undertow_plan, "walking").get("reason", "")), "Undertow remains visible while closed and reports its next opening time.")
	greyport_state["clock"]["weekday"] = "friday"
	greyport_state["clock"]["block"] = "evening"
	var open_undertow_plan: Dictionary = travel.plan_routes(greyport_state, "undertow_nightclub")
	_expect(open_undertow_plan.get("ok", false) and _route_option(open_undertow_plan, "walking").get("available", false) and _route_option(open_undertow_plan, "walking").get("minutes", 0) == 3, "Undertow opens for its authored three-minute Greyport walk on Friday evening.")
	var greyport_access: RefCounted = NavigationAccessScript.new(_registry)
	_expect(bool(greyport_access.room_access_report(greyport_state, "greyport_distribution", "security").get("allowed", false)) and not bool(greyport_access.room_access_report(greyport_state, "greyport_distribution", "warehouse_floor").get("allowed", false)), "Warehouse security is public while the floor remains employee-only.")
	_expect(bool(greyport_access.room_access_report(greyport_state, "port_alder_transit_depot", "public_counter").get("allowed", false)) and not bool(greyport_access.room_access_report(greyport_state, "port_alder_transit_depot", "repair_bays").get("allowed", false)), "The transit public counter does not expose its repair bays.")
	_expect(bool(greyport_access.room_access_report(greyport_state, "greyport_studios", "lobby").get("allowed", false)) and not bool(greyport_access.room_access_report(greyport_state, "greyport_studios", "studio_unit").get("allowed", false)), "Greyport Studios keeps rentable interiors behind viewing or lease access.")
	var greyport_employee_state: Dictionary = greyport_state.duplicate(true)
	greyport_employee_state["player"]["employment"]["active_jobs"].append({"job_id": "warehouse_associate", "status": "active"})
	_expect(bool(greyport_access.room_access_report(greyport_employee_state, "greyport_distribution", "warehouse_floor").get("allowed", false)), "A warehouse employee can enter Greyport Distribution through the legacy job-location alias.")
	var club_employee_state: Dictionary = greyport_state.duplicate(true)
	club_employee_state["player"]["employment"]["active_jobs"].append({"job_id": "undertow_floor_staff", "status": "active"})
	_expect(not bool(greyport_access.room_access_report(greyport_state, "undertow_nightclub", "staff_room").get("allowed", false)) and bool(greyport_access.room_access_report(club_employee_state, "undertow_nightclub", "staff_room").get("allowed", false)), "Undertow's staff room opens only for active nightclub employees.")
	_expect(not bool(greyport_access.target_access_report(greyport_state, "greyport_street", "lee_family_apartment.front_door").get("allowed", false)), "Greyport's residential lane hides an NPC home until its address is discovered.")
	var invited_greyport_state: Dictionary = greyport_state.duplicate(true)
	var greyport_invitation: Dictionary = simulation.apply_operation(invited_greyport_state, "world.discover_location", {"location_id": "lee_family_apartment", "discovery_source": "invitation", "character_id": "marcus_lee"}, "test.greyport_invitation")
	invited_greyport_state = greyport_invitation.get("state", invited_greyport_state)
	_expect(bool(greyport_access.target_access_report(invited_greyport_state, "greyport_street", "lee_family_apartment.front_door").get("allowed", false)), "An invitation reveals the Lee apartment door on Greyport's north residential lane.")
	var greyport_actions: RefCounted = CityActionEngineScript.new(_registry, simulation, quests)
	greyport_state["world_state"]["current_location"] = "undertow_nightclub.dance_floor"
	var undertow_interactions: Array = greyport_actions.interactions_for_room(greyport_state, "undertow_nightclub", "dance_floor")
	var dance_result: Dictionary = greyport_actions.perform_activity(greyport_state, "dance_at_undertow")
	_expect(undertow_interactions.size() == 1 and bool(undertow_interactions[0].get("available", false)) and dance_result.get("ok", false) and float(dance_result.get("state", {}).get("player", {}).get("skill_experience", {}).get("dancing", 0.0)) > 0.0, "Undertow exposes a working dance-floor activity that advances time and Dancing skill.")

	var cedar_state: Dictionary = factory.create_new_game({}, {"random_seed": 719})
	cedar_state["world_state"]["current_location"] = "hale_home.front_yard"
	var cedar_plan: Dictionary = travel.plan_routes(cedar_state, "cedar_vale_street")
	_expect(not cedar_plan.get("ok", false), "Cedar Vale cannot be selected before the player discovers it.")
	var cedar_hub_discovery: Dictionary = simulation.apply_operation(cedar_state, "world.discover_location", {"location_id": "cedar_vale_street", "discovery_source": "housing_listing"}, "test.cedar_listing")
	cedar_state = cedar_hub_discovery.get("state", cedar_state)
	cedar_plan = travel.plan_routes(cedar_state, "cedar_vale_street")
	_expect(cedar_hub_discovery.get("ok", false) and cedar_plan.get("ok", false) and _route_option(cedar_plan, "walking").get("minutes", 0) == 40 and _route_option(cedar_plan, "bus") is Dictionary, "A housing listing reveals Cedar Vale and its walking and bus routes from home.")
	var cedar_result: Dictionary = travel.execute_travel(cedar_state, "cedar_vale_street", "walking", "test.cedar_vale")
	_expect(cedar_result.get("ok", false) and str(cedar_result.get("state", {}).get("world_state", {}).get("current_location", "")) == "cedar_vale_street.bus_stop", "Travel to Cedar Vale arrives at its authored bus stop.")
	cedar_state = cedar_result.get("state", cedar_state)
	for cedar_location_id: String in ["cedar_vale_townhouses", "cedar_vale_detached_homes", "cedar_vale_care_home", "cedar_vale_family_centre"]:
		var cedar_discovery: Dictionary = simulation.apply_operation(cedar_state, "world.discover_location", {
			"location_id": cedar_location_id,
			"discovery_source": "exploration",
		}, "test.cedar_discovery:%s" % cedar_location_id)
		_expect(cedar_discovery.get("ok", false), "Cedar Vale destination supports organic street discovery: %s" % cedar_location_id)
		cedar_state = cedar_discovery.get("state", cedar_state)
	for cedar_destination: Dictionary in [
		{"id": "cedar_vale_townhouses", "minutes": 1},
		{"id": "cedar_vale_detached_homes", "minutes": 3},
		{"id": "cedar_vale_care_home", "minutes": 3},
		{"id": "cedar_vale_family_centre", "minutes": 2},
	]:
		var cedar_destination_plan: Dictionary = travel.plan_routes(cedar_state, str(cedar_destination["id"]))
		_expect(cedar_destination_plan.get("ok", false) and _route_option(cedar_destination_plan, "walking").get("minutes", 0) == int(cedar_destination["minutes"]), "Cedar Vale Street has its authored walk to %s." % cedar_destination["id"])
	var cedar_access: RefCounted = NavigationAccessScript.new(_registry)
	_expect(bool(cedar_access.room_access_report(cedar_state, "cedar_vale_townhouses", "entry").get("allowed", false)) and not bool(cedar_access.room_access_report(cedar_state, "cedar_vale_townhouses", "living_room").get("allowed", false)), "The townhouse entry is public while its rentable interior requires a lease or viewing.")
	_expect(bool(cedar_access.room_access_report(cedar_state, "cedar_vale_detached_homes", "foyer").get("allowed", false)) and not bool(cedar_access.room_access_report(cedar_state, "cedar_vale_detached_homes", "living_room").get("allowed", false)), "The detached-home foyer is public while the property interior requires ownership or a viewing.")
	_expect(bool(cedar_access.room_access_report(cedar_state, "cedar_vale_care_home", "resident_lounge").get("allowed", false)) and not bool(cedar_access.room_access_report(cedar_state, "cedar_vale_care_home", "care_station").get("allowed", false)), "The care-home lounge is public while its care station remains employee-only.")
	_expect(bool(cedar_access.room_access_report(cedar_state, "cedar_vale_family_centre", "parent_group_room").get("allowed", false)) and not bool(cedar_access.room_access_report(cedar_state, "cedar_vale_family_centre", "childcare_room").get("allowed", false)) and not bool(cedar_access.room_access_report(cedar_state, "cedar_vale_family_centre", "counselor_office").get("allowed", false)), "The family-centre group room is public while childcare and counseling rooms require appointments.")
	var cedar_employee_state: Dictionary = cedar_state.duplicate(true)
	cedar_employee_state["player"]["employment"]["active_jobs"].append({"job_id": "cedar_care_support_worker", "status": "active"})
	_expect(bool(cedar_access.room_access_report(cedar_employee_state, "cedar_vale_care_home", "care_station").get("allowed", false)), "An active Cedar Vale care worker can enter the employee care station.")
	_expect(not bool(cedar_access.target_access_report(cedar_state, "cedar_vale_street", "rachel_cedar_vale_townhouse.front_door").get("allowed", false)), "Rachel's Cedar Vale home remains hidden until its address is discovered.")
	var invited_cedar_state: Dictionary = cedar_state.duplicate(true)
	var cedar_invitation: Dictionary = simulation.apply_operation(invited_cedar_state, "world.discover_location", {"location_id": "rachel_cedar_vale_townhouse", "discovery_source": "invitation", "character_id": "rachel_morgan"}, "test.cedar_invitation")
	invited_cedar_state = cedar_invitation.get("state", invited_cedar_state)
	_expect(bool(cedar_access.target_access_report(invited_cedar_state, "cedar_vale_street", "rachel_cedar_vale_townhouse.front_door").get("allowed", false)), "Rachel's invitation reveals only her Cedar Vale front door.")
	var cedar_actions: RefCounted = CityActionEngineScript.new(_registry, simulation, quests)
	cedar_state["world_state"]["current_location"] = "cedar_vale_family_centre.parent_group_room"
	var cedar_interactions: Array = cedar_actions.interactions_for_room(cedar_state, "cedar_vale_family_centre", "parent_group_room")
	var workshop_result: Dictionary = cedar_actions.perform_activity(cedar_state, "cedar_family_skills_workshop")
	_expect(cedar_interactions.size() == 1 and bool(cedar_interactions[0].get("available", false)) and workshop_result.get("ok", false) and float(workshop_result.get("state", {}).get("player", {}).get("skill_experience", {}).get("caregiving", 0.0)) > 0.0, "The family centre exposes a working workshop that advances time and Caregiving skill.")

	var crown_state: Dictionary = factory.create_new_game({}, {"random_seed": 720})
	crown_state["world_state"]["current_location"] = "hale_home.front_yard"
	var crown_plan: Dictionary = travel.plan_routes(crown_state, "crown_point_boulevard")
	_expect(not crown_plan.get("ok", false), "Crown Point cannot be selected before the player discovers it.")
	var crown_hub_discovery: Dictionary = simulation.apply_operation(crown_state, "world.discover_location", {"location_id": "crown_point_boulevard", "discovery_source": "job_listing"}, "test.crown_listing")
	crown_state = crown_hub_discovery.get("state", crown_state)
	crown_plan = travel.plan_routes(crown_state, "crown_point_boulevard")
	_expect(crown_hub_discovery.get("ok", false) and crown_plan.get("ok", false) and _route_option(crown_plan, "walking").get("minutes", 0) == 62 and _route_option(crown_plan, "bus") is Dictionary, "A job listing reveals Crown Point and its walking and bus routes from home.")
	var crown_result: Dictionary = travel.execute_travel(crown_state, "crown_point_boulevard", "walking", "test.crown_point")
	_expect(crown_result.get("ok", false) and str(crown_result.get("state", {}).get("world_state", {}).get("current_location", "")) == "crown_point_boulevard.boulevard_entry", "Travel to Crown Point arrives at its authored transit plaza.")
	crown_state = crown_result.get("state", crown_state)
	for crown_location_id: String in ["price_caldwell_law", "crown_point_condos", "crown_point_penthouses", "crown_point_hotel_spa"]:
		var crown_discovery: Dictionary = simulation.apply_operation(crown_state, "world.discover_location", {
			"location_id": crown_location_id,
			"discovery_source": "exploration",
		}, "test.crown_discovery:%s" % crown_location_id)
		_expect(crown_discovery.get("ok", false), "Crown Point destination supports organic boulevard discovery: %s" % crown_location_id)
		crown_state = crown_discovery.get("state", crown_state)
	for crown_destination: Dictionary in [
		{"id": "price_caldwell_law", "minutes": 1},
		{"id": "crown_point_condos", "minutes": 2},
		{"id": "crown_point_penthouses", "minutes": 3},
		{"id": "crown_point_hotel_spa", "minutes": 3},
	]:
		var crown_destination_plan: Dictionary = travel.plan_routes(crown_state, str(crown_destination["id"]))
		_expect(crown_destination_plan.get("ok", false) and _route_option(crown_destination_plan, "walking").get("minutes", 0) == int(crown_destination["minutes"]), "Crown Point Boulevard has its authored walk to %s." % crown_destination["id"])
	var crown_access: RefCounted = NavigationAccessScript.new(_registry)
	_expect(bool(crown_access.room_access_report(crown_state, "price_caldwell_law", "reception").get("allowed", false)) and not bool(crown_access.room_access_report(crown_state, "price_caldwell_law", "associate_floor").get("allowed", false)) and not bool(crown_access.room_access_report(crown_state, "price_caldwell_law", "conference_room").get("allowed", false)), "Price & Caldwell reception is public while its professional rooms require employment or an appointment.")
	_expect(bool(crown_access.room_access_report(crown_state, "crown_point_condos", "lobby").get("allowed", false)) and not bool(crown_access.room_access_report(crown_state, "crown_point_condos", "one_bedroom_condo").get("allowed", false)), "The condominium lobby is public while its homes and amenities require ownership or a viewing.")
	_expect(bool(crown_access.room_access_report(crown_state, "crown_point_penthouses", "private_elevator").get("allowed", false)) and not bool(crown_access.room_access_report(crown_state, "crown_point_penthouses", "great_room").get("allowed", false)), "The penthouse elevator lobby is public while the residence requires ownership or a viewing.")
	_expect(bool(crown_access.room_access_report(crown_state, "crown_point_hotel_spa", "restaurant").get("allowed", false)) and not bool(crown_access.room_access_report(crown_state, "crown_point_hotel_spa", "spa").get("allowed", false)) and not bool(crown_access.room_access_report(crown_state, "crown_point_hotel_spa", "staff_corridor").get("allowed", false)), "Hotel dining remains public while its spa and staff corridor require the appropriate booking or employment.")
	var crown_law_employee_state: Dictionary = crown_state.duplicate(true)
	crown_law_employee_state["player"]["employment"]["active_jobs"].append({"job_id": "price_caldwell_office_assistant", "status": "active"})
	_expect(bool(crown_access.room_access_report(crown_law_employee_state, "price_caldwell_law", "associate_floor").get("allowed", false)) and bool(crown_access.room_access_report(crown_law_employee_state, "price_caldwell_law", "records_room").get("allowed", false)), "A Price & Caldwell employee can enter the associate floor and records room.")
	var crown_hotel_employee_state: Dictionary = crown_state.duplicate(true)
	crown_hotel_employee_state["player"]["employment"]["active_jobs"].append({"job_id": "crown_point_hotel_guest_services", "status": "active"})
	_expect(bool(crown_access.room_access_report(crown_hotel_employee_state, "crown_point_hotel_spa", "staff_corridor").get("allowed", false)), "A Crown Point Hotel employee can enter the staff corridor.")
	_expect(not bool(crown_access.target_access_report(crown_state, "crown_point_boulevard", "olivia_crown_point_penthouse.private_elevator").get("allowed", false)), "Olivia's penthouse remains hidden until its address is discovered.")
	var invited_crown_state: Dictionary = crown_state.duplicate(true)
	var crown_invitation: Dictionary = simulation.apply_operation(invited_crown_state, "world.discover_location", {"location_id": "olivia_crown_point_penthouse", "discovery_source": "invitation", "character_id": "olivia_price"}, "test.crown_invitation")
	invited_crown_state = crown_invitation.get("state", invited_crown_state)
	_expect(bool(crown_access.target_access_report(invited_crown_state, "crown_point_boulevard", "olivia_crown_point_penthouse.private_elevator").get("allowed", false)), "Olivia's invitation reveals only her private elevator on Crown Point Boulevard.")
	var crown_actions: RefCounted = CityActionEngineScript.new(_registry, simulation, quests)
	crown_state["world_state"]["current_location"] = "crown_point_boulevard.harbor_overlook"
	var crown_interactions: Array = crown_actions.interactions_for_room(crown_state, "crown_point_boulevard", "harbor_overlook")
	var overlook_result: Dictionary = crown_actions.perform_activity(crown_state, "crown_point_harbor_overlook")
	_expect(crown_interactions.size() == 1 and bool(crown_interactions[0].get("available", false)) and overlook_result.get("ok", false) and float(overlook_result.get("state", {}).get("player", {}).get("skill_experience", {}).get("observation", 0.0)) > 0.0, "Crown Point's public overlook exposes a working activity that advances time and Observation skill.")


func _test_city_npc_presence_and_acquaintances() -> void:
	var factory: RefCounted = NewGameStateFactoryScript.new(_registry)
	var simulation: RefCounted = SimulationEngineScript.new(_registry)
	var presence: RefCounted = NpcPresenceEngineScript.new(_registry)
	var state: Dictionary = factory.create_new_game({}, {"random_seed": 790})
	var emma: Dictionary = presence.resolve_character(state, "emma_rowan")
	var chloe: Dictionary = presence.resolve_character(state, "chloe_bennett")
	var rachel: Dictionary = presence.resolve_character(state, "rachel_morgan")
	var hannah: Dictionary = presence.resolve_character(state, "hannah_brooks")
	_expect(str(emma.get("location", "")) == "westshore_campus.classrooms" and not emma.get("available_to_talk", true), "Emma's Tuesday class schedule places her in the authored campus room but keeps her busy.")
	_expect(str(chloe.get("location", "")) == "westshore_campus.art_studios" and not chloe.get("available_to_talk", true), "Chloe's studio commitment resolves to the art studios instead of a generic campus marker.")
	_expect(str(rachel.get("location", "")) == "forge_fitness.front_desk" and rachel.get("available_to_talk", false), "Rachel's public-presence schedule makes her available at the front desk between client sessions.")
	_expect(str(hannah.get("location", "")) == "st_maren_medical_center.staff_station" and not hannah.get("available_to_talk", true), "Hannah's four-on, three-off rotation starts with an authored nursing shift.")
	_expect(presence.present_in_room(state, "westshore_campus", "art_studios").size() == 1, "Room-level presence returns only NPCs scheduled in that exact VN scene.")
	var calendar_state: Dictionary = state.duplicate(true)
	calendar_state["calendar_state"]["events"].append({"id": "test-emma-meetup", "date": "Y1-08-20", "block": "morning", "status": "scheduled", "participants": ["emma_rowan"], "location": "alder_bay_park.lookout", "title": "Morning Meetup"})
	var calendar_emma: Dictionary = presence.resolve_character(calendar_state, "emma_rowan")
	_expect(str(calendar_emma.get("location", "")) == "alder_bay_park.lookout" and calendar_emma.get("available_to_talk", false), "A shared calendar event overrides Emma's ordinary class location for its scheduled meeting block.")
	var rotation_schedule_state: Dictionary = state.duplicate(true)
	rotation_schedule_state["player"]["phone"]["known_contacts"].append("hannah_brooks")
	rotation_schedule_state["player"]["phone"]["message_threads"]["hannah_brooks"] = {"character_id": "hannah_brooks", "messages": [], "last_read_sequence": 0}
	var rotation_result: Dictionary = simulation.apply_operation(rotation_schedule_state, "calendar.schedule", {"calendar_event": {"id": "test-hannah-date", "date": "Y1-08-20", "weekday": "tuesday", "block": "morning", "participants": ["hannah_brooks"], "location": "alder_bay_park.lookout"}}, "test.rotation_calendar")
	_expect(not rotation_result.get("ok", true) and "unavailable" in str(rotation_result.get("errors", [""])[0]), "Hannah's rotating nursing shift blocks conflicting calendar plans on rotation workdays.")
	_expect(str(state["relationships"]["rachel_morgan"].get("relationship_stage", "")) == "stranger", "An undiscovered NPC begins as a stranger rather than a preexisting acquaintance.")
	state["world_state"]["current_location"] = "forge_fitness.front_desk"
	var premature_contact: Dictionary = simulation.apply_operation(state, "npc.meet", {
		"character_id": "rachel_morgan", "interaction": "exchange_contact", "location": "forge_fitness.front_desk",
	}, "test.premature_npc_contact")
	_expect(not premature_contact.get("ok", true), "Phone contact cannot be obtained before the player introduces himself.")
	var result: Dictionary = simulation.apply_operation(state, "npc.meet", {
		"character_id": "rachel_morgan", "interaction": "introduction", "location": "forge_fitness.front_desk",
	}, "test.npc_introduction")
	_expect(result.get("ok", false), "A public introduction is stored through the atomic NPC meeting operation.")
	state = result.get("state", state)
	var rachel_state: Dictionary = _npc_state_for_test(state, "rachel_morgan")
	_expect(rachel_state.get("discovered", false) and "rachel_morgan" not in state["player"]["phone"]["known_contacts"], "Introducing yourself discovers the acquaintance without automatically granting a phone number.")
	_expect(str(state["relationships"]["rachel_morgan"].get("relationship_stage", "")) == "acquaintance", "The first meeting advances the relationship from stranger to acquaintance.")
	result = simulation.apply_operation(state, "npc.meet", {
		"character_id": "rachel_morgan", "interaction": "exchange_contact", "location": "forge_fitness.front_desk",
	}, "test.npc_contact")
	_expect(result.get("ok", false), "A discovered acquaintance can exchange contact information.")
	state = result.get("state", state)
	rachel_state = _npc_state_for_test(state, "rachel_morgan")
	_expect("rachel_morgan" in state["player"]["phone"]["known_contacts"] and state["player"]["phone"]["message_threads"].has("rachel_morgan") and rachel_state.get("phone_contact", false), "Contact exchange updates the NPC record, Contacts app, and empty message thread together.")
	var sync_result: Dictionary = presence.synchronize_npc_states(state)
	_expect(str(_npc_state_for_test(sync_result.get("state", state), "chloe_bennett").get("current_location", "")) == "westshore_campus.art_studios", "Presence synchronization saves the exact scheduled NPC room.")


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
	_expect("cedar_vale_street" in state["world_state"]["discovered_locations"] and "cedar_vale_street" in state["world_state"]["unlocked_locations"], "Rachel's completed assessment reveals Cedar Vale through an authored invitation without revealing her private home.")
	_expect("rachel_cedar_vale_townhouse" not in state["world_state"]["discovered_locations"], "Rachel's neighborhood invitation does not reveal her private townhouse address.")
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


func _test_district_exploration_and_local_leads() -> void:
	var factory: RefCounted = NewGameStateFactoryScript.new(_registry)
	var simulation: RefCounted = SimulationEngineScript.new(_registry)
	var quests: RefCounted = QuestEngineScript.new(_registry, simulation)
	var city_actions: RefCounted = CityActionEngineScript.new(_registry, simulation, quests)
	var state: Dictionary = factory.create_new_game({}, {"random_seed": 818})
	state["world_state"]["current_location"] = "alder_heights_residential_street.hale_block"
	var room_interactions: Array = city_actions.interactions_for_room(state, "alder_heights_residential_street", "hale_block")
	_expect(_interaction_exists_for_test(room_interactions, "explore_hale_block"), "Hale Block exposes the authored Look Around exploration choice.")
	_expect(_interaction_exists_for_test(room_interactions, "walk_alder_heights_loop"), "Hale Block exposes the repeatable neighborhood walk.")

	var result: Dictionary = city_actions.perform_activity(state, "explore_hale_block")
	_expect(result.get("ok", false), "Looking around Hale Block resolves through the city activity engine.")
	state = result.get("state", state)
	_expect(str(result.get("outcome", {}).get("id", "")) == "first_orientation", "The first visit selects the one-time neighborhood orientation outcome.")
	var exploration: Dictionary = state["world_state"].get("exploration", {})
	_expect(exploration.get("history", []).size() == 1 and "explore_hale_block:first_orientation" in exploration.get("completed_outcomes", []), "Exploration history and completed outcomes persist in world state.")
	_expect(_exploration_lead_exists_for_test(exploration.get("discovered_leads", []), "alder_heights_neighborhood_corner"), "The first look saves a neighborhood lead for the City Map.")
	_expect(state["player"]["phone"].get("notifications", []).size() == 1 and not bool(state["player"]["phone"]["notifications"][0].get("read", true)), "The first discovery creates an unread phone notification.")
	_expect("get_to_know_alder_heights" in state["quest_state"].get("available", []) and "get_to_know_alder_heights" not in state["quest_state"].get("active", []), "Exploration offers the neighborhood quest without auto-starting it.")
	_expect("rowan_family_home" not in state["world_state"].get("discovered_locations", []), "Public exploration does not reveal Emma's private home.")

	result = city_actions.perform_activity(state, "explore_hale_block")
	_expect(result.get("ok", false) and str(result.get("outcome", {}).get("id", "")) == "morning_departures", "A repeat look selects the current morning context instead of replaying the first-visit result.")
	state = result.get("state", state)
	exploration = state["world_state"]["exploration"]
	_expect(exploration.get("history", []).size() == 2 and exploration.get("discovered_leads", []).size() == 1 and state["player"]["phone"].get("notifications", []).size() == 1, "Repeat exploration adds history without duplicating leads or notifications.")

	state["world_state"]["weather"]["condition"] = "heavy_rain"
	result = city_actions.perform_activity(state, "explore_hale_block")
	_expect(result.get("ok", false) and str(result.get("outcome", {}).get("id", "")) == "rain_on_the_block", "Weather-specific exploration outcomes take priority when their conditions match.")
	state = result.get("state", state)
	var time_before_walk: int = int(state["clock"].get("minute_within_block", 0))
	result = city_actions.perform_activity(state, "walk_alder_heights_loop")
	_expect(result.get("ok", false) and int(result["state"]["clock"].get("minute_within_block", 0)) != time_before_walk, "The Alder Heights loop is a repeatable timed neighborhood activity.")
	state = result.get("state", state)

	result = quests.accept_quest(state, "get_to_know_alder_heights", "test.exploration_accept")
	_expect(result.get("ok", false) and "get_to_know_alder_heights" in result["state"]["quest_state"].get("active", []), "The player may accept the discovered neighborhood quest from its offer.")
	state = result.get("state", state)
	for location_path: String in [
		"alder_heights_residential_street.neighborhood_corner",
		"alder_heights_bus_stop.shelter",
		"forge_fitness.front_desk",
		"alder_bay_park.waterfront_path",
	]:
		result = quests.record_event(state, "location_entered", {"location": location_path}, "test.exploration_route")
		state = result.get("state", state)
	_expect("get_to_know_alder_heights" in state["quest_state"].get("completed", []) and bool(state["player"]["flags"].get("exploration.alder_heights_oriented", false)), "Visiting the four public destinations completes the optional neighborhood quest.")
	_expect("rowan_family_home" not in state["world_state"].get("discovered_locations", []), "Completing the public route still keeps private residences hidden.")


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
	var mall_store: Dictionary = economy.store_listing(state, "coastline_casuals")
	_expect(str(mall_store.get("store", {}).get("location", "")) == "port_alder_galleria.fashion_wing" and mall_store.get("items", []).size() == 12, "The physical Galleria storefront exposes its twelve-item data-driven catalog.")
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
	_expect("port_alder_realty" in state["world_state"]["unlocked_locations"], "Housing synchronization keeps the public realty service available.")
	_expect("greyport_studios" not in state["world_state"]["unlocked_locations"] and "cedar_vale_townhouses" not in state["world_state"]["unlocked_locations"] and "crown_point_condos" not in state["world_state"]["unlocked_locations"], "Opening Housing does not reveal every listed property or bypass neighborhood discovery.")
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

	var cedar_rental_state: Dictionary = factory.create_new_game({}, {"random_seed": 1403})
	cedar_rental_state["player"]["economy"]["accounts"].merge({"wallet_cash": 0.0, "checking": 10000.0, "savings": 0.0}, true)
	cedar_rental_state["player"]["economy"]["credit_score"] = 700
	cedar_rental_state["player"]["employment"]["active_jobs"].append({"id": "cedar-rental-income", "status": "active", "hourly_pay": 40.0, "weekly_hours": 40.0})
	report = housing.qualification_report(cedar_rental_state, "cedar_vale_townhouse_rental")
	_expect(bool(report.get("qualified", false)) and float(report.get("upfront_cost", 0.0)) == 3725.0, "Income, credit, and funds qualify the player for the Cedar Vale townhouse's authored upfront cost.")
	result = housing.acquire(cedar_rental_state, "cedar_vale_townhouse_rental")
	cedar_rental_state = result.get("state", cedar_rental_state)
	var cedar_property_access: RefCounted = NavigationAccessScript.new(_registry)
	_expect(result.get("ok", false) and bool(cedar_property_access.room_access_report(cedar_rental_state, "cedar_vale_townhouses", "living_room").get("allowed", false)), "Signing the Cedar Vale townhouse lease unlocks its private VN rooms.")

	var cedar_purchase_state: Dictionary = factory.create_new_game({}, {"random_seed": 1404})
	cedar_purchase_state["player"]["economy"]["accounts"].merge({"wallet_cash": 0.0, "checking": 100000.0, "savings": 0.0}, true)
	cedar_purchase_state["player"]["economy"]["credit_score"] = 750
	cedar_purchase_state["player"]["employment"]["active_jobs"].append({"id": "cedar-purchase-income", "status": "active", "hourly_pay": 70.0, "weekly_hours": 40.0})
	report = housing.qualification_report(cedar_purchase_state, "cedar_vale_detached_purchase")
	_expect(bool(report.get("qualified", false)) and float(report.get("upfront_cost", 0.0)) == 87000.0, "Strong income, credit, and savings qualify the player for the Cedar Vale detached home's down payment and closing costs.")
	result = housing.acquire(cedar_purchase_state, "cedar_vale_detached_purchase")
	cedar_purchase_state = result.get("state", cedar_purchase_state)
	_expect(result.get("ok", false) and cedar_purchase_state["player"]["housing"]["owned_properties"].size() == 1 and bool(cedar_property_access.room_access_report(cedar_purchase_state, "cedar_vale_detached_homes", "living_room").get("allowed", false)), "Purchasing the Cedar Vale detached home records ownership and unlocks its complete interior.")

	var crown_condo_state: Dictionary = factory.create_new_game({}, {"random_seed": 1405})
	crown_condo_state["player"]["economy"]["accounts"].merge({"wallet_cash": 0.0, "checking": 250000.0, "savings": 0.0}, true)
	crown_condo_state["player"]["economy"]["credit_score"] = 780
	crown_condo_state["player"]["employment"]["active_jobs"].append({"id": "crown-condo-income", "status": "active", "hourly_pay": 100.0, "weekly_hours": 40.0})
	report = housing.qualification_report(crown_condo_state, "crown_point_one_bedroom_condo")
	_expect(bool(report.get("qualified", false)) and float(report.get("upfront_cost", 0.0)) == 209000.0, "High income, excellent credit, and savings qualify the player for the Crown Point condo's down payment and closing costs.")
	result = housing.acquire(crown_condo_state, "crown_point_one_bedroom_condo")
	crown_condo_state = result.get("state", crown_condo_state)
	var crown_property_access: RefCounted = NavigationAccessScript.new(_registry)
	_expect(result.get("ok", false) and bool(crown_property_access.room_access_report(crown_condo_state, "crown_point_condos", "one_bedroom_condo").get("allowed", false)) and bool(crown_property_access.room_access_report(crown_condo_state, "crown_point_condos", "gym").get("allowed", false)), "Purchasing the Crown Point condo unlocks its residence and building amenities.")

	var crown_penthouse_state: Dictionary = factory.create_new_game({}, {"random_seed": 1406})
	crown_penthouse_state["player"]["economy"]["accounts"].merge({"wallet_cash": 0.0, "checking": 900000.0, "savings": 0.0}, true)
	crown_penthouse_state["player"]["economy"]["credit_score"] = 820
	crown_penthouse_state["player"]["employment"]["active_jobs"].append({"id": "crown-penthouse-income", "status": "active", "hourly_pay": 260.0, "weekly_hours": 40.0})
	report = housing.qualification_report(crown_penthouse_state, "crown_point_penthouse_purchase")
	_expect(bool(report.get("qualified", false)) and float(report.get("upfront_cost", 0.0)) == 864000.0, "Exceptional income, credit, and liquid funds meet the penthouse's intentionally demanding qualification rules.")
	result = housing.acquire(crown_penthouse_state, "crown_point_penthouse_purchase")
	crown_penthouse_state = result.get("state", crown_penthouse_state)
	_expect(result.get("ok", false) and bool(crown_property_access.room_access_report(crown_penthouse_state, "crown_point_penthouses", "great_room").get("allowed", false)) and bool(crown_property_access.room_access_report(crown_penthouse_state, "crown_point_penthouses", "private_elevator").get("allowed", false)), "Purchasing the Crown Point penthouse unlocks its private elevator and complete residence.")


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
	_expect(instance.get_node_or_null("PageMargin/Page/CreationTabs/LifeDetails/Scroll/Fields/ArchetypeSelection") != null, "Creation scene contains a visible archetype selection confirmation.")
	_expect(instance.get_node_or_null("PageMargin/Page/CreationTabs/BackgroundAndReview/Columns/ReviewColumn/ReviewText") != null, "Creation scene contains confirmation review.")
	root.add_child(instance)
	var month_option: OptionButton = instance.get_node("PageMargin/Page/CreationTabs/Identity/Fields/BirthFields/MonthField/BirthMonth")
	var day_option: OptionButton = instance.get_node("PageMargin/Page/CreationTabs/Identity/Fields/BirthFields/DayField/BirthDay")
	var archetype_grid: GridContainer = instance.get_node("PageMargin/Page/CreationTabs/LifeDetails/Scroll/Fields/ArchetypeOptions")
	var archetype_status: Label = instance.get_node("PageMargin/Page/CreationTabs/LifeDetails/Scroll/Fields/ArchetypeSelection")
	_expect(month_option.item_count == 13 and month_option.get_selected_id() == 0, "Birthday dropdown requires an explicit choice and contains all twelve months.")
	_expect(day_option.item_count == 1 and day_option.get_selected_id() == 0 and day_option.disabled, "Birthday day dropdown waits for a month choice.")
	month_option.select(2)
	month_option.emit_signal("item_selected", 2)
	_expect(day_option.item_count == 30 and day_option.get_selected_id() == 0 and not day_option.disabled, "Choosing leap-year February exposes every valid day and still requires a day choice.")
	day_option.select(29)
	day_option.emit_signal("item_selected", 29)
	_expect(instance.call("_build_choices").get("birth_date", "") == "2008-02-29", "Birthday dropdowns calculate an age-18 leap-day birth date.")
	_expect(archetype_grid.get_child_count() == 6, "All authored archetypes are visible as selectable buttons.")
	if archetype_grid.get_child_count() > 0:
		var archetype_button: Button = archetype_grid.get_child(0)
		archetype_button.emit_signal("pressed")
		_expect(instance.call("_build_choices").get("archetype", "") == "the_planner", "Selecting an archetype button stores the choice.")
		_expect(archetype_button.text.begins_with("✓ ") and "The Planner" in archetype_status.text, "Selected archetype receives a clear checkmark and confirmation label.")
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
	_expect(tests.size() == 78, "Acceptance suite contains 78 cases.")
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
	_expect(_registry.get_document_count() == 42, "Registry loads all 42 runtime source documents.")
	_expect(_registry.get_package_count() == 26, "Registry indexes all 26 global packages.")
	_expect(_registry.get_all("locations").size() == 65, "Registry indexes all 65 locations.")
	_expect(_registry.get_all("districts").size() == 10, "Registry indexes all 10 districts.")
	_expect(_registry.get_character("elena_reyes_hale") is Dictionary, "Characters can be retrieved by id.")
	_expect(_registry.get_location("hale_home") is Dictionary, "Locations can be retrieved by id.")
	var westshore_campus: Dictionary = _registry.get_location("westshore_campus")
	var westshore_rooms: Dictionary = {}
	for room_value: Variant in westshore_campus.get("rooms", []):
		if room_value is Dictionary:
			westshore_rooms[str(room_value.get("id", ""))] = room_value
	_expect(westshore_rooms.size() == 10 and westshore_rooms.has("transit_loop"), "Westshore Campus exposes ten connected destinations including its transit loop.")
	_expect(str(westshore_rooms.get("courtyard", {}).get("navigation", {}).get("left", "")) == "westshore_administration_office.reception" and str(westshore_rooms.get("courtyard", {}).get("navigation", {}).get("right", "")) == "cafeteria", "The campus courtyard connects Administration and the Cafeteria through directional paths.")
	_expect(str(westshore_rooms.get("cafeteria", {}).get("navigation", {}).get("right", "")) == "westshore_bookshop.sales_floor" and str(westshore_rooms.get("transit_loop", {}).get("navigation", {}).get("left", "")) == "cypress_hall_dorm.lobby", "Westshore arrows reach the Bookshop and Cypress Hall lobby.")
	_expect(_registry.get_content("quests", "opening_future_choice") is Dictionary, "Quests can be retrieved by id.")
	_expect(_registry.get_all("operations").size() == 69, "Registry indexes all 69 simulation operations.")
	_expect(_registry.get_all("date_activities").size() == 5, "Registry indexes all five opening date activities, including Undertow and Crown Point dinner.")
	_expect(_registry.get_all("social_activities").size() == 5, "Registry indexes five reusable friendship and family hangouts.")
	_expect(_registry.get_all("vn_backgrounds").size() == 145, "Registry indexes 145 production VN backgrounds across twenty-seven completed locations.")
	var vn_art: Dictionary = _registry.get_package("port_alder_vn_art")
	_expect(vn_art.get("art_vocabulary", {}).get("background_variants", []).size() == 12 and vn_art.get("art_vocabulary", {}).get("portrait_expressions", []).size() == 14, "VN art defines shared background-variant and portrait-expression vocabularies.")
	var player_bedroom_art: Dictionary = _registry.get_content("vn_backgrounds", "hale_home.player_bedroom")
	_expect(str(player_bedroom_art.get("path", "")).ends_with("player_bedroom.png") and str(player_bedroom_art.get("status", "")) == "ready", "The opening bedroom resolves to its production background artwork.")
	var artwork_backlog: Dictionary = vn_art.get("production_backlog", {})
	var artwork_phases: Array = artwork_backlog.get("phases", [])
	var artwork_asset_count: int = 0
	for artwork_phase_value: Variant in artwork_phases:
		if artwork_phase_value is Dictionary:
			artwork_asset_count += artwork_phase_value.get("assets", []).size()
	_expect(str(artwork_backlog.get("mode", "")) == "room_art_first" and artwork_backlog.get("active_kinds", []) == ["background"], "VN art uses a room-first, background-only production queue.")
	_expect(artwork_phases.size() == 21 and artwork_asset_count == 145, "VN art provides twenty-one prioritized production phases covering 145 room backgrounds.")
	_expect(str(artwork_phases[0].get("id", "")) == "opening_morning" and int(artwork_phases[0].get("priority", 0)) == 1, "The Hale home opening is the first artwork production milestone.")
	_expect(artwork_backlog.get("room_scope", {}).get("completed_locations", []).size() == 27, "Room-first production records twenty-seven fully completed base-art locations.")
	var hale_production_backgrounds: int = 0
	var production_base_backgrounds: int = 0
	for background_value: Variant in _registry.get_all("vn_backgrounds"):
		if background_value is Dictionary:
			var background_id: String = str(background_value.get("id", ""))
			if background_id.begins_with("hale_home.") and str(background_value.get("path", "")).ends_with(".png") and str(background_value.get("status", "")) == "ready":
				hale_production_backgrounds += 1
			if str(background_value.get("path", "")).ends_with(".png") and str(background_value.get("status", "")) == "ready" and background_value.get("variants", {}).get("day", "") == background_value.get("path", ""):
				production_base_backgrounds += 1
	_expect(hale_production_backgrounds == 14, "Every Hale Home room and exterior has unique ready base-day production artwork.")
	_expect(production_base_backgrounds == 145, "Twenty-seven complete locations provide 145 unique ready base-day backgrounds.")
	_expect(vn_art.get("vn_audio", []).is_empty(), "VN audio remains deliberately disabled while the artwork pipeline is developed.")
	var elena_assets: Dictionary = _registry.get_character("elena_reyes_hale").get("asset_refs", {})
	_expect(elena_assets.get("portraits", []).size() == 2 and str(elena_assets["portraits"][0].get("path", "")).ends_with("elena_reyes_hale/default.png"), "Elena provides production default and neutral portraits for the opening scene.")
	var emma_assets: Dictionary = _registry.get_character("emma_rowan").get("asset_refs", {})
	_expect(not emma_assets.get("portraits", []).is_empty() and str(emma_assets["portraits"][0].get("id", "")) == "default", "Character packages declare their own default portrait artwork.")
	var quest_rules: Dictionary = _registry.get_package("port_alder_sandbox_quest_system")
	_expect(quest_rules.get("default_timing", "") == "open_ended", "Quest progression defaults to open-ended sandbox timing.")
	_expect(bool(quest_rules.get("tracker_rules", {}).get("player_controls_tracking", false)), "Sandbox rules give the player control of quest tracking.")
	_expect(bool(quest_rules.get("repeatable_quest_rules", {}).get("authored_requirements_rechecked_before_every_run", false)), "Repeatable quest runs recheck all authored requirements.")
	_expect(_registry.get_content("quests", "build_a_training_rhythm") is Dictionary and _registry.get_content("quests", "consistency_under_pressure") is Dictionary, "Registry indexes both counted stages of Rachel's repeatable training chain.")
	_expect(_registry.get_all("actions").size() == 10, "Registry indexes all 10 initial home actions.")
	_expect(_registry.get_all("city_interactions").size() == 26, "Registry indexes the foundation activities, storefronts, district exploration choices, and workshops.")
	_expect(_registry.get_all("stores").size() == 12, "Registry indexes seven city shops plus five opening Galleria storefronts.")
	var harbor_centre: Dictionary = _registry.get_location("harbor_centre_downtown")
	var harbor_rooms: Dictionary = {}
	for room_value: Variant in harbor_centre.get("rooms", []):
		if room_value is Dictionary:
			harbor_rooms[str(room_value.get("id", ""))] = room_value
	_expect(harbor_rooms.size() == 6 and str(harbor_rooms.get("employment_block", {}).get("navigation", {}).get("up", "")) == "harbor_employment_centre.job_floor", "Harbor Centre provides six walkable public blocks connected to the Employment Centre.")
	_expect(str(harbor_rooms.get("galleria_entrance", {}).get("navigation", {}).get("right", "")) == "port_alder_galleria.street_entrance", "Harbor Centre's authored street graph reaches the Galleria entrance.")
	var galleria: Dictionary = _registry.get_location("port_alder_galleria")
	var storefront_slots: Array = galleria.get("mall", {}).get("storefront_slots", [])
	var occupied_slots: int = storefront_slots.filter(func(slot: Variant) -> bool: return slot is Dictionary and str(slot.get("status", "")) == "occupied").size()
	var vacant_slots: int = storefront_slots.filter(func(slot: Variant) -> bool: return slot is Dictionary and str(slot.get("status", "")) == "vacant").size()
	_expect(galleria.get("rooms", []).size() == 14 and storefront_slots.size() == 16, "Port Alder Galleria has fourteen navigable areas and sixteen storefront slots.")
	_expect(occupied_slots == 5 and vacant_slots == 8, "The Galleria opens with five stores and reserves eight vacant expansion units.")
	_expect(_registry.get_all("phone_apps").size() == 15, "Registry indexes the foundation apps plus Notifications, Education, Jobs, Money, Housing, and Shopping.")
	var phone_rules: Dictionary = _registry.get_package("port_alder_phone_system")
	var movie_calendar_type: Dictionary = {}
	for event_type_value: Variant in phone_rules.get("calendar_event_types", []):
		if event_type_value is Dictionary and str(event_type_value.get("id", "")) == "movie":
			movie_calendar_type = event_type_value
			break
	_expect(str(movie_calendar_type.get("default_location", "")) == "harborlight_cinema.lobby", "Movie plans begin in the cinema lobby so participants can meet before entering an auditorium.")
	_expect(_registry.get_all("housing_listings").size() == 7, "Registry indexes seven housing choices from a student room through Crown Point's penthouse.")
	var district_hub_ids: Array[String] = []
	for location_value: Variant in _registry.get_all("locations"):
		if location_value is Dictionary and str(location_value.get("discovery", {}).get("tier", "")) == "district_hub":
			district_hub_ids.append(str(location_value.get("id", "")))
	_expect(district_hub_ids.size() == 4 and district_hub_ids.has("mariner_row_shopping_street") and district_hub_ids.has("greyport_street") and district_hub_ids.has("cedar_vale_street") and district_hub_ids.has("crown_point_boulevard"), "Four optional district hubs form the opening discovery layer.")
	for district_hub_id: String in district_hub_ids:
		var hub_discovery: Dictionary = _registry.get_location(district_hub_id).get("discovery", {})
		_expect(bool(hub_discovery.get("discoverable", false)) and bool(hub_discovery.get("hidden_until_discovered", false)) and not hub_discovery.get("sources", []).is_empty(), "District hub is hidden and declares authored discovery sources: %s" % district_hub_id)
	_expect(str(_registry.get_content("jobs", "warehouse_associate").get("discovery_location_id", "")) == "greyport_street" and str(_registry.get_content("jobs", "crown_point_hotel_guest_services").get("discovery_location_id", "")) == "crown_point_boulevard", "Job listings reveal their district hubs instead of exact workplaces.")
	_expect(str(_registry.get_content("housing_listings", "cedar_vale_townhouse_rental").get("discovery_location_id", "")) == "cedar_vale_street" and str(_registry.get_content("housing_listings", "crown_point_one_bedroom_condo").get("discovery_location_id", "")) == "crown_point_boulevard", "Housing listings reveal neighborhoods instead of exact properties.")
	_expect(str(_registry.get_content("stores", "mariner_market").get("discovery_location_id", "")) == "mariner_row_shopping_street", "Shopping listings can organically reveal Mariner Row.")
	var lantern_street: Dictionary = _registry.get_location("lantern_district_street")
	var lantern_street_rooms: Dictionary = {}
	for room_value: Variant in lantern_street.get("rooms", []):
		if room_value is Dictionary:
			lantern_street_rooms[str(room_value.get("id", ""))] = room_value
	_expect(str(lantern_street.get("outside_room", "")) == "cinema_block" and lantern_street_rooms.size() == 3, "Lantern District Street has an authored arrival point and three walkable sections.")
	_expect(str(lantern_street_rooms.get("restaurant_lane", {}).get("navigation", {}).get("up", "")) == "la_brisa_kitchen.dining_room" and str(lantern_street_rooms.get("restaurant_lane", {}).get("navigation", {}).get("down", "")) == "tideglass_club.entry", "Restaurant Lane physically connects La Brisa Kitchen and Tideglass Club.")
	_expect(str(lantern_street_rooms.get("gallery_walk", {}).get("navigation", {}).get("up", "")) == "lantern_gallery.main_gallery" and str(lantern_street_rooms.get("gallery_walk", {}).get("navigation", {}).get("right", "")) == "harbor_companion_cooperative.secure_reception", "Gallery Walk connects the gallery and the cooperative's public reception.")
	for lantern_location_id: String in ["harborlight_cinema", "la_brisa_kitchen", "lantern_gallery", "tideglass_club", "harbor_companion_cooperative"]:
		var lantern_location: Dictionary = _registry.get_location(lantern_location_id)
		var every_room_authored: bool = not str(lantern_location.get("outside_room", "")).is_empty()
		for room_value: Variant in lantern_location.get("rooms", []):
			every_room_authored = every_room_authored and room_value is Dictionary and not room_value.get("navigation", {}).is_empty()
		_expect(every_room_authored, "Every room has intentional navigation and an authored entrance: %s" % lantern_location_id)
	var alder_bay_park: Dictionary = _registry.get_location("alder_bay_park")
	var park_rooms: Dictionary = {}
	for room_value: Variant in alder_bay_park.get("rooms", []):
		if room_value is Dictionary:
			park_rooms[str(room_value.get("id", ""))] = room_value
	_expect(str(alder_bay_park.get("outside_room", "")) == "waterfront_path" and park_rooms.size() == 5, "Alder Bay Park has an authored waterfront arrival and five connected spaces.")
	_expect(str(park_rooms.get("waterfront_path", {}).get("navigation", {}).get("left", "")) == "alder_heights_residential_street.neighborhood_corner" and str(park_rooms.get("waterfront_path", {}).get("navigation", {}).get("right", "")) == "alder_bay_beach.boardwalk", "The waterfront path connects the home neighborhood to Alder Bay Beach.")
	_expect(str(park_rooms.get("lookout", {}).get("navigation", {}).get("right", "")) == "bayview_cafe.patio", "The Bay Lookout connects directly to Bayview Café's waterfront patio.")
	for alder_bay_location_id: String in ["alder_bay_park", "alder_bay_beach", "port_alder_marina", "bayview_cafe"]:
		var alder_bay_location: Dictionary = _registry.get_location(alder_bay_location_id)
		var every_bay_room_authored: bool = not str(alder_bay_location.get("outside_room", "")).is_empty()
		for room_value: Variant in alder_bay_location.get("rooms", []):
			every_bay_room_authored = every_bay_room_authored and room_value is Dictionary and not room_value.get("navigation", {}).is_empty()
		_expect(every_bay_room_authored, "Every Alder Bay room has intentional navigation and an authored entrance: %s" % alder_bay_location_id)
	var park_run_activity: Dictionary = _registry.get_content("activities", "park_run")
	_expect("alder_bay_park.waterfront_path" in park_run_activity.get("locations", []), "The repeatable park run uses the park's real authored waterfront path.")
	var mariner_street: Dictionary = _registry.get_location("mariner_row_shopping_street")
	var mariner_street_rooms: Dictionary = {}
	for room_value: Variant in mariner_street.get("rooms", []):
		if room_value is Dictionary:
			mariner_street_rooms[str(room_value.get("id", ""))] = room_value
	_expect(str(mariner_street.get("outside_room", "")) == "transit_stop" and "route_planner" in mariner_street.get("services", []) and mariner_street_rooms.size() == 4, "Mariner Row has an authored transit arrival, route planner, and three shopping blocks.")
	_expect(str(mariner_street_rooms.get("fashion_block", {}).get("navigation", {}).get("up", "")) == "northline_outfitters.sales_floor" and str(mariner_street_rooms.get("fashion_block", {}).get("navigation", {}).get("down", "")) == "harbor_formalwear.showroom", "Fashion Block physically connects Northline Outfitters and Harbor Formalwear.")
	_expect(str(mariner_street_rooms.get("home_and_auto_block", {}).get("navigation", {}).get("up", "")) == "mariner_home_goods.furniture_floor" and str(mariner_street_rooms.get("home_and_auto_block", {}).get("navigation", {}).get("right", "")) == "port_alder_auto.showroom", "Home and Auto Block connects both of its named businesses.")
	for mariner_location_id: String in ["mariner_row_shopping_street", "mariner_market", "northline_outfitters", "harbor_formalwear", "mariner_home_goods", "port_alder_auto"]:
		var mariner_location: Dictionary = _registry.get_location(mariner_location_id)
		var every_mariner_room_authored: bool = not str(mariner_location.get("outside_room", "")).is_empty()
		for room_value: Variant in mariner_location.get("rooms", []):
			every_mariner_room_authored = every_mariner_room_authored and room_value is Dictionary and not room_value.get("navigation", {}).is_empty()
		_expect(every_mariner_room_authored, "Every Mariner Row room has intentional navigation and an authored entrance: %s" % mariner_location_id)
	for mariner_store_interaction_id: String in ["shop_mariner_market", "shop_northline_outfitters", "shop_harbor_formalwear"]:
		_expect(_registry.get_content("city_interactions", mariner_store_interaction_id) is Dictionary, "Mariner Row physical storefront is registered: %s" % mariner_store_interaction_id)
	var medical_center: Dictionary = _registry.get_location("st_maren_medical_center")
	var medical_center_rooms: Dictionary = {}
	for room_value: Variant in medical_center.get("rooms", []):
		if room_value is Dictionary:
			medical_center_rooms[str(room_value.get("id", ""))] = room_value
	_expect(str(medical_center.get("outside_room", "")) == "campus_transit_stop" and "route_planner" in medical_center.get("services", []) and medical_center_rooms.size() == 13, "St. Maren has an authored transit arrival, route planner, campus paths, and hospital interior.")
	_expect(str(medical_center_rooms.get("campus_plaza", {}).get("navigation", {}).get("right", "")) == "clinic_walk" and str(medical_center_rooms.get("clinic_walk", {}).get("navigation", {}).get("right", "")) == "wellness_walk", "St. Maren's plaza connects its two pedestrian clinic paths.")
	_expect(str(medical_center_rooms.get("clinic_walk", {}).get("navigation", {}).get("up", "")) == "st_maren_community_clinic.reception" and str(medical_center_rooms.get("wellness_walk", {}).get("navigation", {}).get("down", "")) == "st_maren_sexual_health.private_reception", "The medical campus paths connect public reception areas without bypassing private rooms.")
	for medical_location_id: String in ["st_maren_medical_center", "st_maren_community_clinic", "st_maren_doctors_office", "harbor_wellness_therapy", "st_maren_sexual_health", "bay_pharmacy"]:
		var medical_location: Dictionary = _registry.get_location(medical_location_id)
		var every_medical_room_authored: bool = not str(medical_location.get("outside_room", "")).is_empty()
		for room_value: Variant in medical_location.get("rooms", []):
			every_medical_room_authored = every_medical_room_authored and room_value is Dictionary and not room_value.get("navigation", {}).is_empty()
		_expect(every_medical_room_authored, "Every St. Maren room has intentional navigation and an authored entrance: %s" % medical_location_id)
	_expect(_registry.get_content("city_interactions", "shop_bay_pharmacy") is Dictionary, "Bay Pharmacy's physical storefront is registered.")
	var therapy_activity: Dictionary = _registry.get_content("activities", "therapy_session")
	var doctor_activity: Dictionary = _registry.get_content("activities", "doctor_appointment")
	var screening_activity: Dictionary = _registry.get_content("activities", "sexual_health_screening")
	_expect("harbor_wellness_therapy.individual_office" in therapy_activity.get("locations", []) and "st_maren_community_clinic.exam_room" in doctor_activity.get("locations", []) and "st_maren_sexual_health.testing_room" in screening_activity.get("locations", []), "Medical activities reference their exact private appointment rooms instead of legacy placeholders.")
	var greyport_street: Dictionary = _registry.get_location("greyport_street")
	var greyport_street_rooms: Dictionary = {}
	for room_value: Variant in greyport_street.get("rooms", []):
		if room_value is Dictionary:
			greyport_street_rooms[str(room_value.get("id", ""))] = room_value
	_expect(str(greyport_street.get("outside_room", "")) == "bus_exchange" and "route_planner" in greyport_street.get("services", []) and greyport_street_rooms.size() == 6, "Greyport has an authored bus arrival and six connected street areas.")
	_expect(str(greyport_street_rooms.get("industrial_corner", {}).get("navigation", {}).get("up", "")) == "greyport_distribution.security" and str(greyport_street_rooms.get("industrial_corner", {}).get("navigation", {}).get("right", "")) == "port_alder_transit_depot.public_counter" and str(greyport_street_rooms.get("industrial_corner", {}).get("navigation", {}).get("down", "")) == "nightlife_alley", "Greyport's industrial corner connects both workplaces and Nightlife Alley.")
	_expect(str(greyport_street_rooms.get("north_residences", {}).get("navigation", {}).get("up", "")) == "lee_family_apartment.front_door" and str(greyport_street_rooms.get("south_residences", {}).get("navigation", {}).get("right", "")) == "greyport_shared_apartment.entry", "Greyport's residential lanes hold discoverable NPC and rentable addresses.")
	for greyport_location_id: String in ["greyport_street", "greyport_distribution", "port_alder_transit_depot", "greyport_studios", "undertow_nightclub"]:
		var greyport_location: Dictionary = _registry.get_location(greyport_location_id)
		var every_greyport_room_authored: bool = not str(greyport_location.get("outside_room", "")).is_empty()
		for room_value: Variant in greyport_location.get("rooms", []):
			every_greyport_room_authored = every_greyport_room_authored and room_value is Dictionary and not room_value.get("navigation", {}).is_empty()
		_expect(every_greyport_room_authored, "Every public Greyport room has intentional navigation and an authored entrance: %s" % greyport_location_id)
	var undertow: Dictionary = _registry.get_location("undertow_nightclub")
	_expect(undertow.get("rooms", []).size() == 9 and "night" in undertow.get("access", {}).get("open_blocks", []) and "intoxication_safety_checks" in undertow.get("content_rules", []), "Undertow is a nine-area adult nightclub with late hours and explicit safety rules.")
	var nightclub_date: Dictionary = _registry.get_content("date_activities", "nightclub_date")
	var nightclub_job: Dictionary = _registry.get_content("jobs", "undertow_floor_staff")
	_expect(str(nightclub_date.get("location", "")) == "undertow_nightclub.dance_floor" and "night" in nightclub_date.get("allowed_blocks", []), "Undertow is available as a scheduled evening or night date.")
	_expect(str(nightclub_job.get("location", "")) == "undertow_nightclub" and "part_time" in nightclub_job.get("employment_types", []) and nightclub_job.get("promotion_path", []).size() == 2, "Undertow offers a part-time night job with two promotion steps.")
	var cedar_street: Dictionary = _registry.get_location("cedar_vale_street")
	var cedar_street_rooms: Dictionary = {}
	for room_value: Variant in cedar_street.get("rooms", []):
		if room_value is Dictionary:
			cedar_street_rooms[str(room_value.get("id", ""))] = room_value
	_expect(str(cedar_street.get("outside_room", "")) == "bus_stop" and "route_planner" in cedar_street.get("services", []) and cedar_street_rooms.size() == 5, "Cedar Vale has an authored bus arrival, route planner, and five connected neighborhood spaces.")
	_expect(str(cedar_street_rooms.get("townhouse_row", {}).get("navigation", {}).get("up", "")) == "rachel_cedar_vale_townhouse.front_door" and str(cedar_street_rooms.get("townhouse_row", {}).get("navigation", {}).get("down", "")) == "cedar_vale_townhouses.entry", "Townhouse Row holds Rachel's discoverable address and the public townhouse listing entry.")
	_expect(str(cedar_street_rooms.get("family_block", {}).get("navigation", {}).get("up", "")) == "cedar_vale_care_home.reception" and str(cedar_street_rooms.get("family_block", {}).get("navigation", {}).get("down", "")) == "cedar_vale_family_centre.reception" and str(cedar_street_rooms.get("family_block", {}).get("navigation", {}).get("right", "")) == "detached_home_lane", "Cedar Vale's Family Block connects care, family services, and the detached-home lane.")
	for cedar_location_id: String in ["cedar_vale_street", "cedar_vale_townhouses", "cedar_vale_detached_homes", "cedar_vale_care_home", "cedar_vale_family_centre"]:
		var cedar_location: Dictionary = _registry.get_location(cedar_location_id)
		var every_cedar_room_authored: bool = not str(cedar_location.get("outside_room", "")).is_empty()
		for room_value: Variant in cedar_location.get("rooms", []):
			every_cedar_room_authored = every_cedar_room_authored and room_value is Dictionary and not room_value.get("navigation", {}).is_empty()
		_expect(every_cedar_room_authored, "Every public Cedar Vale room has intentional navigation and an authored entrance: %s" % cedar_location_id)
	var cedar_rental_listing: Dictionary = _registry.get_content("housing_listings", "cedar_vale_townhouse_rental")
	var cedar_purchase_listing: Dictionary = _registry.get_content("housing_listings", "cedar_vale_detached_purchase")
	_expect(str(cedar_rental_listing.get("location_id", "")) == "cedar_vale_townhouses" and str(cedar_rental_listing.get("tenure", "")) == "rental" and int(cedar_rental_listing.get("bedrooms", 0)) == 2, "Cedar Vale offers an authored two-bedroom townhouse rental.")
	_expect(str(cedar_purchase_listing.get("location_id", "")) == "cedar_vale_detached_homes" and str(cedar_purchase_listing.get("tenure", "")) == "purchase" and int(cedar_purchase_listing.get("bedrooms", 0)) == 3, "Cedar Vale offers an authored three-bedroom detached home purchase.")
	var cedar_workshop: Dictionary = _registry.get_content("city_interactions", "cedar_family_skills_workshop")
	var cedar_care_job: Dictionary = _registry.get_content("jobs", "cedar_care_support_worker")
	_expect(str(cedar_workshop.get("location", "")) == "cedar_vale_family_centre" and "parent_group_room" in cedar_workshop.get("rooms", []), "The family-skills workshop is registered in its exact public group room.")
	_expect(str(cedar_care_job.get("location", "")) == "cedar_vale_care_home" and "part_time" in cedar_care_job.get("employment_types", []) and cedar_care_job.get("promotion_path", []).size() == 2, "Cedar Vale Care Home offers part- and full-time work with two promotion steps.")
	var crown_boulevard: Dictionary = _registry.get_location("crown_point_boulevard")
	var crown_boulevard_rooms: Dictionary = {}
	for room_value: Variant in crown_boulevard.get("rooms", []):
		if room_value is Dictionary:
			crown_boulevard_rooms[str(room_value.get("id", ""))] = room_value
	_expect(str(crown_boulevard.get("outside_room", "")) == "boulevard_entry" and "route_planner" in crown_boulevard.get("services", []) and crown_boulevard_rooms.size() == 6, "Crown Point has an authored transit arrival, route planner, and six connected boulevard spaces.")
	_expect(str(crown_boulevard_rooms.get("corporate_block", {}).get("navigation", {}).get("up", "")) == "price_caldwell_law.reception" and str(crown_boulevard_rooms.get("residential_towers", {}).get("navigation", {}).get("down", "")) == "crown_point_condos.lobby", "Crown Point's corporate and residential blocks connect their public entrances.")
	_expect(str(crown_boulevard_rooms.get("residential_towers", {}).get("navigation", {}).get("up", "")) == "olivia_crown_point_penthouse.private_elevator" and str(crown_boulevard_rooms.get("penthouse_towers", {}).get("navigation", {}).get("up", "")) == "crown_point_penthouses.private_elevator", "Residential Towers preserves Olivia's discoverable home separately from the purchasable penthouse tower.")
	_expect(str(crown_boulevard_rooms.get("hotel_block", {}).get("navigation", {}).get("up", "")) == "crown_point_hotel_spa.lobby" and str(crown_boulevard_rooms.get("hotel_block", {}).get("navigation", {}).get("right", "")) == "harbor_overlook", "Hotel Block connects the hotel lobby and the public harbor overlook.")
	for crown_location_id: String in ["crown_point_boulevard", "price_caldwell_law", "crown_point_condos", "crown_point_penthouses", "crown_point_hotel_spa"]:
		var crown_location: Dictionary = _registry.get_location(crown_location_id)
		var every_crown_room_authored: bool = not str(crown_location.get("outside_room", "")).is_empty()
		for room_value: Variant in crown_location.get("rooms", []):
			every_crown_room_authored = every_crown_room_authored and room_value is Dictionary and not room_value.get("navigation", {}).is_empty()
		_expect(every_crown_room_authored, "Every public Crown Point room has intentional navigation and an authored entrance: %s" % crown_location_id)
	var crown_condo_listing: Dictionary = _registry.get_content("housing_listings", "crown_point_one_bedroom_condo")
	var crown_penthouse_listing: Dictionary = _registry.get_content("housing_listings", "crown_point_penthouse_purchase")
	_expect(str(crown_condo_listing.get("location_id", "")) == "crown_point_condos" and int(crown_condo_listing.get("purchase_price", 0)) == 950000, "Crown Point offers an authored premium one-bedroom condo purchase.")
	_expect(str(crown_penthouse_listing.get("location_id", "")) == "crown_point_penthouses" and int(crown_penthouse_listing.get("purchase_price", 0)) == 3200000, "The Crown Point penthouse is preserved as a demanding long-term wealth goal.")
	var crown_overlook_activity: Dictionary = _registry.get_content("city_interactions", "crown_point_harbor_overlook")
	var crown_dinner_date: Dictionary = _registry.get_content("date_activities", "crown_point_dinner")
	var crown_hotel_job: Dictionary = _registry.get_content("jobs", "crown_point_hotel_guest_services")
	var crown_law_job: Dictionary = _registry.get_content("jobs", "price_caldwell_office_assistant")
	_expect(str(crown_overlook_activity.get("location", "")) == "crown_point_boulevard" and "harbor_overlook" in crown_overlook_activity.get("rooms", []), "Crown Point's overlook activity is registered in its exact public boulevard room.")
	_expect(str(crown_dinner_date.get("location", "")) == "crown_point_hotel_spa.restaurant" and float(crown_dinner_date.get("cost", 0.0)) == 120.0, "Crown Point Hotel offers a formal luxury dinner date.")
	_expect(str(crown_hotel_job.get("location", "")) == "crown_point_hotel_spa" and crown_hotel_job.get("promotion_path", []).size() == 2 and str(crown_law_job.get("location", "")) == "price_caldwell_law" and crown_law_job.get("promotion_path", []).size() == 2, "Crown Point adds hotel and legal careers with two promotion steps each.")


func _test_navigation_integrity() -> void:
	var validator: RefCounted = NavigationIntegrityValidatorScript.new(_registry)
	var report: Dictionary = validator.audit()
	var errors: PackedStringArray = report.get("errors", PackedStringArray())
	var stats: Dictionary = report.get("stats", {})
	_expect(errors.is_empty(), "Every enterable authored room has a valid target and an escape path: %s" % "; ".join(errors))
	_expect(int(stats.get("locations", 0)) == 65, "Navigation validation audits all 65 city locations.")
	_expect(int(stats.get("rooms", 0)) >= 250, "Navigation validation audits the complete authored room inventory.")
	_expect(int(stats.get("cross_location_links", 0)) >= 30, "Navigation validation checks the walkable links between locations.")
	_expect(int(stats.get("fallback_navigation_locations", 0)) == 1, "The only data fallback remaining is Hale Home's intentionally replaced runtime graph.")
	var runtime_graph_report: Dictionary = validator.audit_locations(_registry.get_all("locations"), {
		"hale_home": {
			"outside_room": HaleHomeNavigationScript.OUTSIDE_ROOM,
			"exits": HaleHomeNavigationScript.ROOM_EXITS,
			"replace_all_navigation": true,
		},
	})
	_expect(bool(runtime_graph_report.get("ok", false)), "The hardcoded Hale Home room graph and every city data graph pass the same integrity audit.")

	var bad_target_report: Dictionary = validator.audit_locations([
		{"id": "test_bad_target", "outside_room": "entry", "rooms": [
			{"id": "entry", "navigation": {"right": "missing_room"}},
		]},
	])
	_expect(not bool(bad_target_report.get("ok", true)) and _messages_contain(bad_target_report.get("errors", PackedStringArray()), "unknown local room"), "The validator rejects arrows that point to missing rooms.")

	var trapped_room_report: Dictionary = validator.audit_locations([
		{"id": "test_trap", "outside_room": "entry", "rooms": [
			{"id": "entry", "navigation": {"right": "private_room"}},
			{"id": "private_room", "access": "invitation", "navigation": {"right": "private_room"}},
		]},
	])
	_expect(not bool(trapped_room_report.get("ok", true)) and _messages_contain(trapped_room_report.get("errors", PackedStringArray()), "cannot return"), "The validator catches an invited or otherwise conditional room that can trap the player.")

	var restricted_room_report: Dictionary = validator.audit_locations([
		{"id": "test_locked_room", "outside_room": "entry", "rooms": [
			{"id": "entry"},
			{"id": "never_enterable", "access": "restricted", "navigation": {"right": "never_enterable"}},
		]},
	])
	_expect(bool(restricted_room_report.get("ok", false)), "A permanently restricted room is not falsely reported as a player trap.")


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
	_expect("notifications" in state["player"]["phone"]["unlocked_apps"], "The Notifications app is available from the start.")
	_expect("shopping" not in state["player"]["phone"]["unlocked_apps"], "Shopping remains tied to the authored wardrobe tutorial unlock.")
	_expect(state["relationships"].size() == 15, "Relationship defaults initialize for every opening character.")
	_expect(state["relationships"]["emma_rowan"].get("dating_history", []) is Array, "Relationship runtime state initializes date history.")
	_expect(state["relationships"]["emma_rowan"].get("dating_agreement", {}).get("status", "") == "none", "Relationships begin without an assumed dating agreement.")
	_expect(state["world_state"]["weather"]["condition"] == "partly_cloudy", "Opening weather initializes from the calendar.")
	_expect(state["world_state"].get("exploration", {}).get("history", []).is_empty(), "A new game initializes empty persistent exploration history.")
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
	marcus_plan["location"] = "harborlight_cinema.auditorium"
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


func _test_screenwriter_phone_bridge() -> void:
	var maya: Dictionary = _registry.get_character("maya_chen").duplicate(true)
	maya["text_messages"] = [
		{
			"id": "maya_bridge_offer",
			"direction": "incoming",
			"sender": "maya_chen",
			"introduces_contact": true,
			"trigger": {"sandbox_activated": true, "days": ["tuesday"], "blocks": ["morning"]},
			"conditions": [{"meter_at_least": ["maya_chen", "trust", 0]}],
			"text": "Could you help me test the message bridge?",
			"quick_replies": [
				{"id": "locked", "text": "Use a locked reply.", "conditions": [{"flag": "phone.bridge_locked"}]},
				{
					"id": "accept",
					"text": "Yes, I can help.",
					"tone": ["supportive"],
					"effects": [
						{"operation": "start_quest", "quest": "screenwriter_phone_quest"},
						{"operation": "complete_objective", "quest": "screenwriter_phone_quest", "objective": "accept_offer"},
						{"operation": "set_flag", "key": "phone.maya_accepted", "value": true},
						{"operation": "add_meter", "character": "maya_chen", "meter": "trust", "value": 2},
					],
				},
			],
		},
		{
			"id": "maya_reply_selected_followup",
			"direction": "incoming",
			"sender": "maya_chen",
			"trigger": {"reply_selected": ["maya_bridge_offer", "accept"]},
			"text": "I knew I could count on that answer.",
			"quick_replies": [],
		},
		{
			"id": "maya_any_reply_followup",
			"direction": "incoming",
			"sender": "maya_chen",
			"trigger": {"message_replied": ["maya_chen", "maya_bridge_offer"]},
			"text": "Your reply came through clearly.",
			"quick_replies": [],
		},
		{
			"id": "maya_player_update",
			"direction": "outgoing",
			"sender": "player",
			"trigger": {"quest_started": "screenwriter_phone_quest"},
			"conditions": [{"flag": "phone.maya_accepted"}],
			"text": "The outgoing-message test is complete.",
			"effects": [
				{"operation": "complete_objective", "quest": "screenwriter_phone_quest", "objective": "send_update"},
				{"operation": "complete_quest", "quest": "screenwriter_phone_quest"},
				{"operation": "set_value", "key": "phone.bridge_result", "value": "passed"},
			],
		},
		{
			"id": "maya_sent_followup",
			"direction": "incoming",
			"sender": "maya_chen",
			"trigger": {"message_sent": "maya_player_update"},
			"text": "I received your update.",
			"quick_replies": [],
		},
	]
	var quest: Dictionary = {
		"id": "screenwriter_phone_quest",
		"category": "character_story",
		"title": "Screenwriter Phone Bridge",
		"summary": "Exercise every authored phone direction.",
		"discovery": {"source": "phone_message", "policy": "auto_start"},
		"activation": {},
		"objectives": [
			{"id": "accept_offer", "text": "Accept Maya's offer.", "completion": {"event": "text_replied", "thread": "maya_bridge_offer", "reply": "accept"}},
			{"id": "send_update", "text": "Send Maya an update.", "completion": {"event": "text_sent", "character": "maya_chen", "message": "maya_player_update"}},
		],
		"branches": [],
		"completion_effects": [],
		"failure": {"mode": "retryable"},
	}
	var bridge_registry: Node = ScreenwriterFixtureRegistryScript.new(_registry, {
		"characters": {"maya_chen": maya},
		"quests": {"screenwriter_phone_quest": quest},
	})
	root.add_child(bridge_registry)
	var factory: RefCounted = NewGameStateFactoryScript.new(bridge_registry)
	var simulation: RefCounted = SimulationEngineScript.new(bridge_registry)
	var phone: RefCounted = PhoneEngineScript.new(bridge_registry, simulation)
	var state: Dictionary = factory.create_new_game({}, {"random_seed": 5150})
	state["player"]["flags"]["sandbox.active"] = true
	_expect("maya_chen" not in state["player"]["phone"]["known_contacts"], "Screenwriter phone fixture begins with Maya undiscovered as a contact.")
	var result: Dictionary = phone.sync_triggered_messages(state)
	_expect(result.get("ok", false), "Screenwriter incoming phone triggers synchronize.")
	state = result.get("state", state)
	_expect("maya_chen" in state["player"]["phone"]["known_contacts"] and _thread_message_count(state, "maya_chen") == 1, "An introducing message creates its contact and thread before delivery.")
	_expect(phone.available_outgoing_messages(state, "maya_chen").is_empty(), "Quest-gated outgoing text stays hidden before its authored reply effect.")
	var available_replies: Array = phone.available_replies(state, "maya_chen", "maya_bridge_offer")
	_expect(available_replies.size() == 1 and str(available_replies[0].get("id", "")) == "accept" and int(available_replies[0].get("index", -1)) == 1, "Reply conditions hide locked choices while preserving their authored indexes.")
	var minute_before_locked_reply: int = int(state["clock"]["minute_within_block"])
	result = phone.reply_to_message(state, "maya_chen", "maya_bridge_offer", 0)
	_expect(not result.get("ok", true) and int(state["clock"]["minute_within_block"]) == minute_before_locked_reply, "A locked phone reply fails without consuming time.")
	var trust_before: float = float(state["relationships"]["maya_chen"]["trust"])
	result = phone.reply_to_message(state, "maya_chen", "maya_bridge_offer", 1)
	_expect(result.get("ok", false), "A visible Screenwriter reply applies its authored effects.")
	state = result.get("state", state)
	_expect("screenwriter_phone_quest" in state["quest_state"]["active"] and bool(state["quest_state"]["objectives"]["screenwriter_phone_quest"]["accept_offer"]), "A reply can start a quest and complete its first objective.")
	_expect(float(state["relationships"]["maya_chen"]["trust"]) == trust_before + 2.0 and bool(state["player"]["flags"].get("phone.maya_accepted", false)), "Reply meter and flag effects persist.")
	_expect(_thread_message_count(state, "maya_chen") == 4, "Specific-reply and any-reply follow-ups arrive immediately after the player answers.")
	var outgoing: Array = phone.available_outgoing_messages(state, "maya_chen")
	_expect(outgoing.size() == 1 and str(outgoing[0].get("id", "")) == "maya_player_update", "A quest-gated player-authored outgoing text becomes available organically.")
	result = phone.send_outgoing_message(state, "maya_chen", "maya_player_update")
	_expect(result.get("ok", false), "The player can send a Screenwriter-authored outgoing message.")
	state = result.get("state", state)
	_expect("screenwriter_phone_quest" in state["quest_state"]["completed"], "Outgoing message effects can complete objectives and their quest.")
	_expect(str(state.get("phone", {}).get("bridge_result", "")) == "passed" and _thread_message_count(state, "maya_chen") == 6, "Outgoing state effects persist and message-sent follow-ups arrive in the same synchronization.")
	result = phone.send_outgoing_message(state, "maya_chen", "maya_player_update")
	_expect(not result.get("ok", true), "A one-shot authored outgoing message cannot be sent twice.")
	bridge_registry.queue_free()


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

	var social_state: Dictionary = factory.create_new_game({}, {"random_seed": 224, "save_id": "social-activity-test"})
	_expect(relationships.social_invitation_options(social_state, "emma_rowan", "cafe_catchup", 1).is_empty(), "Hangout locations stay hidden until their destination is unlocked.")
	social_state["world_state"]["unlocked_locations"].append("bayview_cafe")
	_expect(not relationships.social_invitation_options(social_state, "emma_rowan", "cafe_catchup", 1).is_empty(), "Discovering a destination makes its social activity available.")
	var social_options: Array = relationships.social_invitation_options(social_state, "emma_rowan", "waterfront_hangout", 2)
	_expect(not social_options.is_empty(), "Known contacts offer social times outside their authored commitments.")
	_expect(not relationships.social_invitation_options(social_state, "elena_reyes_hale", "waterfront_hangout", 1).is_empty(), "Family and non-romantic relationships can use the hangout system.")
	if not social_options.is_empty():
		var social_option: Dictionary = social_options[0]
		result = relationships.invite_to_social_activity(
			social_state, "emma_rowan", "waterfront_hangout",
			str(social_option["date"]), str(social_option["weekday"]), str(social_option["block"])
		)
		_expect(result.get("ok", false) and result.get("data", {}).get("accepted", false), "A friendship invitation can be accepted without being treated as a date.")
		if result.get("ok", false) and result.get("data", {}).get("accepted", false):
			social_state = result["state"]
			var social_event: Dictionary = result["data"]["calendar_event"]
			_expect(bool(social_event.get("relationship_social_activity", false)) and not bool(social_event.get("relationship_date", false)), "Accepted hangouts receive their own calendar-event identity.")
			var conflicting_options: Array = relationships.social_invitation_options(social_state, "marcus_lee", "waterfront_hangout", 2)
			var reused_relationship_slot: bool = false
			for conflicting_value: Variant in conflicting_options:
				if conflicting_value is Dictionary and str(conflicting_value.get("date", "")) == str(social_event.get("date", "")) and str(conflicting_value.get("block", "")) == str(social_event.get("block", "")):
					reused_relationship_slot = true
			_expect(not reused_relationship_slot, "A date or hangout reserves that player calendar block against other relationship plans.")
			_set_test_date(social_state, str(social_event["date"]), str(social_event["weekday"]), str(social_event["block"]))
			social_state["world_state"]["current_location"] = str(social_event["location"])
			var friendship_before_hangout: float = float(social_state["relationships"]["emma_rowan"]["friendship"])
			result = relationships.complete_social_activity(social_state, str(social_event["id"]), "listen")
			_expect(result.get("ok", false), "A scheduled hangout can begin at its authored room and time.")
			if result.get("ok", false):
				social_state = result["state"]
				_expect(_calendar_event_status(social_state, str(social_event["id"])) == "completed", "Completing a hangout closes its calendar event.")
				_expect(social_state["relationships"]["emma_rowan"]["social_history"].size() == 1, "Completed hangouts persist separately from romantic date history.")
				_expect(float(social_state["relationships"]["emma_rowan"]["friendship"]) > friendship_before_hangout, "The chosen social approach changes relationship support meters.")
				_expect(int(social_state["relationships"]["emma_rowan"]["unlocked_chapter_level"]) == 2, "Shared social time can unlock a due-diligence relationship chapter.")
				_expect(social_state["relationships"]["emma_rowan"]["pending_milestones"].size() == 1, "A newly unlocked relationship chapter waits for the player to begin it.")
				result = relationships.begin_milestone(social_state, "emma_rowan", 2)
				_expect(result.get("ok", false), "The player can begin a ready relationship story arc at their own pace.")
				social_state = result.get("state", social_state)
				_expect(social_state["relationships"]["emma_rowan"]["pending_milestones"].is_empty(), "Beginning a story arc clears its pending milestone without erasing history.")

	var missed_social_state: Dictionary = factory.create_new_game({}, {"random_seed": 225})
	social_options = relationships.social_invitation_options(missed_social_state, "emma_rowan", "waterfront_hangout", 1)
	if not social_options.is_empty():
		var missed_social_option: Dictionary = social_options[0]
		result = relationships.invite_to_social_activity(
			missed_social_state, "emma_rowan", "waterfront_hangout",
			str(missed_social_option["date"]), str(missed_social_option["weekday"]), str(missed_social_option["block"])
		)
		if result.get("ok", false) and result.get("data", {}).get("accepted", false):
			missed_social_state = result["state"]
			var missed_social_event: Dictionary = result["data"]["calendar_event"]
			var social_trust_before: float = float(missed_social_state["relationships"]["emma_rowan"]["trust"])
			_set_test_date(missed_social_state, str(missed_social_event["date"]), str(missed_social_event["weekday"]), "night")
			result = relationships.synchronize(missed_social_state)
			missed_social_state = result.get("state", missed_social_state)
			_expect(result.get("ok", false) and _calendar_event_status(missed_social_state, str(missed_social_event["id"])) == "missed", "An overdue social activity resolves as a no-show.")
			_expect(float(missed_social_state["relationships"]["emma_rowan"]["trust"]) == social_trust_before - 5.0, "Missing a hangout applies its own authored trust consequence.")


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

	var completion_state: Dictionary = factory.create_new_game({}, {"random_seed": 235})
	completion_state["player"]["flags"]["sandbox.active"] = true
	result = quests.sync_automatic_activations(completion_state, "test.character_quest_discovery")
	completion_state = result.get("state", completion_state)
	result = quests.accept_quest(completion_state, "before_everything_changes", "test.character_quest_accept")
	completion_state = result.get("state", completion_state)
	completion_state["player"]["flags"]["emma.walk_friendship_focus"] = true
	var emma_friendship_before: float = float(completion_state["relationships"]["emma_rowan"]["friendship"])
	var emma_trust_before: float = float(completion_state["relationships"]["emma_rowan"]["trust"])
	result = quests.complete_quest(completion_state, "before_everything_changes", "test.character_quest_complete")
	completion_state = result.get("state", completion_state)
	var emma_memory_found: bool = false
	for memory_value: Variant in completion_state["relationships"]["emma_rowan"].get("memories", []):
		if memory_value is Dictionary and str(memory_value.get("id", "")) == "walked_alder_bay_before_college":
			emma_memory_found = true
			break
	_expect(result.get("ok", false) and emma_memory_found, "Character-quest completion creates its authored relationship memory.")
	_expect(int(completion_state["relationships"]["emma_rowan"].get("unlocked_chapter_level", 1)) == 2, "Character-quest completion unlocks its authored relationship chapter.")
	_expect(float(completion_state["relationships"]["emma_rowan"]["friendship"]) == emma_friendship_before + 6.0 and float(completion_state["relationships"]["emma_rowan"]["trust"]) == emma_trust_before + 3.0, "Flag-selected character quest branches apply every authored relationship effect.")

	var marcus_state: Dictionary = factory.create_new_game({}, {"random_seed": 236})
	marcus_state["player"]["flags"]["sandbox.active"] = true
	result = quests.sync_automatic_activations(marcus_state, "test.marcus_discovery")
	marcus_state = result.get("state", marcus_state)
	result = quests.accept_quest(marcus_state, "one_last_summer_movie", "test.marcus_accept")
	marcus_state = result.get("state", marcus_state)
	marcus_state["player"]["flags"]["marcus.showed_rough_cut"] = true
	var marcus_trust_before: float = float(marcus_state["relationships"]["marcus_lee"]["trust"])
	result = quests.complete_quest(marcus_state, "one_last_summer_movie", "test.marcus_complete")
	marcus_state = result.get("state", marcus_state)
	_expect(result.get("ok", false) and "marcus_student_film" in marcus_state["quest_state"]["active"], "A character quest branch can start its authored follow-up quest.")
	_expect(float(marcus_state["relationships"]["marcus_lee"]["trust"]) == marcus_trust_before + 4.0, "A follow-up branch also applies its authored meter effect.")

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


func _test_screenwriter_dialogue_bridge() -> void:
	var bridge_conversation: Dictionary = {
		"id": "screenwriter_bridge_fixture",
		"type": "standard_topic",
		"start_node": "setup",
		"activation": {"days": ["tuesday"], "block": "morning"},
		"condition": {"flag": "screenwriter.bridge_enabled"},
		"presentation": {
			"transition": "fade",
			"music": "bridge_theme",
			"ambience": "quiet_cafe",
			"notes": "Keep the camera intimate.",
		},
		"completion_effects": [
			{"operation": "add_meter", "character": "emma_rowan", "meter": "trust", "value": 3},
			{"operation": "complete_activity", "value": "screenwriter_bridge_activity"},
			{"operation": "set_flag", "key": "screenwriter.bridge_completed", "value": true},
		],
		"nodes": {
			"setup": {
				"speaker": "emma_rowan",
				"line": "This line uses the Screenwriter interchange contract.",
				"expression": "warm",
				"portrait": "default",
				"background_variant": "rain",
				"position": "left",
				"transition": "dissolve",
				"sfx": "cup_down",
				"effects": [
					{"operation": "create_memory", "character": "emma_rowan", "value": "bridge_memory"},
					{"operation": "add_character_stat", "character": "emma_rowan", "key": "courage", "value": 5},
					{"operation": "add_player_value", "section": "attributes", "key": "confidence", "value": 2},
				],
				"next": "automatic_gate",
			},
			"automatic_gate": {
				"branches": [
					{
						"id": "impossible",
						"text": "The created memory is missing.",
						"conditions": [{"memory_missing": ["emma_rowan", "bridge_memory"]}],
						"effects": [{"operation": "set_flag", "key": "screenwriter.wrong_branch", "value": true}],
						"next": "ending",
					},
					{
						"id": "qualified",
						"text": "Every authored condition passes.",
						"conditions": [
							{"meter_at_least": ["emma_rowan", "friendship", 1]},
							{"meter_at_most": ["emma_rowan", "friendship", 100]},
							{"character_stat_at_least": ["emma_rowan", "courage", 5]},
							{"character_stat_at_most": ["emma_rowan", "courage", 5]},
							{"chapter_at_least": ["emma_rowan", 1]},
							{"memory_exists": ["emma_rowan", "bridge_memory"]},
							{"flag": "screenwriter.bridge_enabled"},
							{"flag_not": "screenwriter.bridge_blocked"},
							{"value_equals": ["player.life_path", "college"]},
						],
						"effects": [{"operation": "unlock_relationship_chapter", "character": "emma_rowan", "level": 2}],
						"next": "ending",
					},
					{"id": "fallback", "text": "Fallback", "effects": [{"operation": "set_flag", "key": "screenwriter.wrong_branch", "value": true}], "next": "ending"},
				],
			},
			"ending": {"speaker": "emma_rowan", "line": "The automatic branch resolved.", "position": "right", "music": "bridge_ending"},
		},
	}
	var unknown_condition_conversation: Dictionary = {
		"id": "screenwriter_unknown_condition_fixture",
		"type": "standard_topic",
		"start_node": "choice",
		"activation": {},
		"nodes": {
			"choice": {
				"speaker": "player",
				"choices": [{"id": "unsafe", "text": "This must remain hidden.", "conditions": [{"future_unhandled_gate": true}]}],
			},
		},
	}
	var bridge_registry: Node = ScreenwriterFixtureRegistryScript.new(_registry, {
		"conversations": {
			"screenwriter_bridge_fixture": bridge_conversation,
			"screenwriter_unknown_condition_fixture": unknown_condition_conversation,
		},
		"activities": {
			"screenwriter_bridge_activity": {
				"id": "screenwriter_bridge_activity",
				"kind": "social_activity",
				"character": "emma_rowan",
				"counter_key": "activity.screenwriter_bridge_activity.count",
			},
		},
	})
	root.add_child(bridge_registry)
	var factory: RefCounted = NewGameStateFactoryScript.new(bridge_registry)
	var simulation: RefCounted = SimulationEngineScript.new(bridge_registry)
	var quests: RefCounted = QuestEngineScript.new(bridge_registry, simulation)
	var dialogue: RefCounted = DialogueEngineScript.new(bridge_registry, simulation, quests)
	var state: Dictionary = factory.create_new_game({"first_name": "Bridge"}, {"random_seed": 314})
	state["player"]["flags"]["screenwriter.bridge_enabled"] = true
	state["player"]["life_path"] = "college"
	state["clock"]["weekday"] = "monday"
	_expect(not dialogue.can_begin(state, "screenwriter_bridge_fixture")["ok"], "Screenwriter conversation day gates reject unavailable weekdays.")
	state["clock"]["weekday"] = "tuesday"
	var confidence_before: float = float(state["player"]["attributes"]["confidence"])
	var trust_before: float = float(state["relationships"]["emma_rowan"]["trust"])
	var result: Dictionary = dialogue.begin(state, "screenwriter_bridge_fixture")
	_expect(result.get("ok", false) and result.get("view", {}).get("node_id", "") == "setup", "Screenwriter-format conversation activation and first node load.")
	var opening_view: Dictionary = result.get("view", {})
	_expect(str(opening_view.get("expression", "")) == "warm" and str(opening_view.get("background_variant", "")) == "rain" and str(opening_view.get("portrait_position", "")) == "left", "Screenwriter expressions, background variants, and portrait positions reach the VN view.")
	_expect(str(opening_view.get("transition", "")) == "dissolve" and str(opening_view.get("music_cue", "")) == "bridge_theme" and str(opening_view.get("ambience_cue", "")) == "quiet_cafe" and str(opening_view.get("sfx_cue", "")) == "cup_down", "Node presentation overrides merge with conversation-level audio and transition defaults.")
	_expect(str(opening_view.get("director_notes", "")) == "Keep the camera intimate.", "Conversation direction notes survive into the runtime view for diagnostics.")
	state = result.get("state", state)
	_expect(float(state["player"]["attributes"]["confidence"]) == confidence_before + 2.0, "Screenwriter player-value effects use the simulation attribute range.")
	_expect(float(state["relationships"]["emma_rowan"]["character_stats"].get("courage", 0)) == 5.0, "Screenwriter custom character stats persist in relationship state.")
	result = dialogue.advance(state)
	state = result.get("state", state)
	_expect(result.get("ok", false) and result.get("view", {}).get("node_id", "") == "ending", "Screenwriter automatic stat branches resolve without showing a blank node.")
	var ending_view: Dictionary = result.get("view", {})
	_expect(str(ending_view.get("portrait_position", "")) == "right" and str(ending_view.get("transition", "")) == "fade" and str(ending_view.get("music_cue", "")) == "bridge_ending" and str(ending_view.get("ambience_cue", "")) == "quiet_cafe" and str(ending_view.get("sfx_cue", "")) == "", "Later nodes can override one cue while inheriting the rest of the scene direction.")
	_expect(not bool(state["player"]["flags"].get("screenwriter.wrong_branch", false)), "Automatic branches choose the first matching authored condition set.")
	_expect(int(state["relationships"]["emma_rowan"]["unlocked_chapter_level"]) == 2, "Screenwriter chapter-unlock effects synchronize relationship level state.")
	result = dialogue.advance(state)
	state = result.get("state", state)
	_expect(result.get("ok", false) and result.get("ended", false), "Screenwriter-format conversation finishes cleanly.")
	_expect(float(state["relationships"]["emma_rowan"]["trust"]) == trust_before + 3.0, "Conversation completion effects apply exactly once.")
	_expect(int(state["conversation_state"].get("activity_progress", {}).get("screenwriter_bridge_activity", {}).get("count", 0)) == 1, "Explicit activity success records its persistent counter.")
	_expect(bool(state["player"]["flags"].get("screenwriter.bridge_completed", false)), "Screenwriter completion flags persist in player state.")
	result = dialogue.begin(state, "screenwriter_unknown_condition_fixture")
	_expect(result.get("ok", false) and result.get("view", {}).get("choices", []).is_empty(), "Unknown imported condition types fail closed instead of exposing locked choices.")
	bridge_registry.queue_free()


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


func _npc_state_for_test(state: Dictionary, character_id: String) -> Dictionary:
	for npc_state: Variant in state.get("npc_states", []):
		if npc_state is Dictionary and str(npc_state.get("character_id", "")) == character_id:
			return npc_state
	return {}


func _route_option(plan: Dictionary, mode: String) -> Dictionary:
	for option: Variant in plan.get("options", []):
		if option is Dictionary and str(option.get("mode", "")) == mode:
			return option
	return {}


func _interaction_exists_for_test(interactions: Array, interaction_id: String) -> bool:
	for interaction_value: Variant in interactions:
		if interaction_value is Dictionary and str(interaction_value.get("id", "")) == interaction_id:
			return true
	return false


func _exploration_lead_exists_for_test(leads: Array, lead_id: String) -> bool:
	for lead_value: Variant in leads:
		if lead_value is Dictionary and str(lead_value.get("id", "")) == lead_id:
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


func _messages_contain(messages: Variant, fragment: String) -> bool:
	if not messages is Array and not messages is PackedStringArray:
		return false
	for message: Variant in messages:
		if fragment in str(message):
			return true
	return false


func _expect(condition: bool, description: String) -> void:
	_tests_run += 1
	if not condition:
		_failures.append(description)
