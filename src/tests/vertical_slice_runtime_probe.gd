extends Node

const CharacterCreationValidatorScript: GDScript = preload("res://src/creation/character_creation_validator.gd")
const SaveEngineScript: GDScript = preload("res://src/save/save_engine.gd")
const PROBE_SAVE_ROOT: String = "user://port_alder_vertical_slice_probe"
const PROBE_SLOT: String = "connected_run"

var _failure_message: String = ""


func _ready() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	_cleanup_probe_save()
	var errors: PackedStringArray = ContentRegistry.validate_foundation()
	if not _check(errors.is_empty(), "content validation failed"):
		_finish_failure()
		return

	var choices: Dictionary = await _create_character_through_ui()
	if choices.is_empty():
		_finish_failure()
		return
	if not _start_created_character(choices):
		_finish_failure()
		return
	if not _complete_opening_college_branch():
		_finish_failure()
		return
	if not await _exercise_home_and_phone():
		_finish_failure()
		return
	if not await _travel_and_enroll():
		_finish_failure()
		return
	if not await _schedule_and_complete_emma_walk():
		_finish_failure()
		return
	if not await _save_reload_and_resume():
		_finish_failure()
		return

	_cleanup_probe_save()
	GameState.clear_state()
	print("PASS: Connected vertical slice completed creation, opening, home, phone, bus travel, enrollment, an NPC story, and save/reload.")
	get_tree().quit(0)


func _create_character_through_ui() -> Dictionary:
	var creation_scene: PackedScene = load("res://scenes/creation/character_creation.tscn")
	if not _check(creation_scene != null, "character-creation scene did not load"):
		return {}
	var creation: Control = creation_scene.instantiate()
	get_tree().root.add_child(creation)
	await get_tree().process_frame
	await get_tree().process_frame

	var first_name: LineEdit = creation.get_node("PageMargin/Page/CreationTabs/Identity/Fields/FirstName")
	var last_name: LineEdit = creation.get_node("PageMargin/Page/CreationTabs/Identity/Fields/LastName")
	first_name.text = "Journey"
	last_name.text = "Tester"
	var birth_month: OptionButton = creation.get_node("PageMargin/Page/CreationTabs/Identity/Fields/BirthFields/MonthField/BirthMonth")
	var birth_day: OptionButton = creation.get_node("PageMargin/Page/CreationTabs/Identity/Fields/BirthFields/DayField/BirthDay")
	if not _check(str(creation.call("_selected_birth_date")).is_empty(), "birthday was preselected before the player chose a month and day"):
		creation.free()
		return {}
	var birth_month_index: int = _option_index_for_id(birth_month, 8)
	if not _check(birth_month_index >= 0, "August was missing from the birthday month dropdown"):
		creation.free()
		return {}
	birth_month.select(birth_month_index)
	birth_month.emit_signal("item_selected", birth_month_index)
	var birthday_index: int = _option_index_for_id(birth_day, 21)
	if not _check(birthday_index >= 0, "August 21 was missing from the birthday day dropdown"):
		creation.free()
		return {}
	birth_day.select(birthday_index)
	birth_day.emit_signal("item_selected", birthday_index)

	for option_path: String in [
		"PageMargin/Page/CreationTabs/Appearance/Fields/Grid/FaceOption",
		"PageMargin/Page/CreationTabs/Appearance/Fields/Grid/EyeOption",
		"PageMargin/Page/CreationTabs/Appearance/Fields/Grid/SkinOption",
		"PageMargin/Page/CreationTabs/Appearance/Fields/Grid/HairOption",
		"PageMargin/Page/CreationTabs/Appearance/Fields/Grid/HeightOption",
		"PageMargin/Page/CreationTabs/Appearance/Fields/Grid/BodyOption",
	]:
		var appearance_option: OptionButton = creation.get_node(option_path)
		appearance_option.select(1)

	_select_multi_buttons(creation.get_node("PageMargin/Page/CreationTabs/Traits/Scroll/Fields/PositiveOptions"), 3)
	_select_multi_buttons(creation.get_node("PageMargin/Page/CreationTabs/Traits/Scroll/Fields/ChallengingOptions"), 3)
	_select_multi_buttons(creation.get_node("PageMargin/Page/CreationTabs/LifeDetails/Scroll/Fields/CoreOptions"), 3)
	_select_multi_buttons(creation.get_node("PageMargin/Page/CreationTabs/LifeDetails/Scroll/Fields/HobbyOptions"), 2)
	var archetype_grid: GridContainer = creation.get_node("PageMargin/Page/CreationTabs/LifeDetails/Scroll/Fields/ArchetypeOptions")
	var archetype_status: Label = creation.get_node("PageMargin/Page/CreationTabs/LifeDetails/Scroll/Fields/ArchetypeSelection")
	var archetype_button: Button = archetype_grid.get_child(0)
	archetype_button.set_pressed_no_signal(true)
	archetype_button.emit_signal("pressed")
	if not _check(archetype_button.text.begins_with("✓ ") and "The Planner" in archetype_status.text, "archetype selection did not show a clear visual confirmation"):
		creation.free()
		return {}
	var background_option: OptionButton = creation.get_node("PageMargin/Page/CreationTabs/BackgroundAndReview/Columns/BackgroundColumn/BackgroundOption")
	var background_index: int = _option_index_for_metadata(background_option, "standard_background")
	if not _check(background_index >= 0, "Standard financial background was missing"):
		creation.free()
		return {}
	background_option.select(background_index)
	background_option.emit_signal("item_selected", background_index)

	var choices: Dictionary = creation.call("_build_choices")
	var validator: RefCounted = CharacterCreationValidatorScript.new(ContentRegistry)
	var validation: Dictionary = validator.validate_choices(choices)
	if not _check(validation.get("valid", false), "UI-created character was rejected: %s" % "; ".join(validation.get("errors", []))):
		creation.free()
		return {}
	if not _check(str(choices.get("birth_date", "")) == "2007-08-21", "birthday dropdowns did not calculate the age-18 birth year"):
		creation.free()
		return {}
	if not _check(str(choices.get("archetype", "")) == "the_planner", "archetype button did not store its choice"):
		creation.free()
		return {}
	choices["birthday"] = validator.birthday_from_birth_date(str(choices["birth_date"]))
	creation.free()
	return choices


func _start_created_character(choices: Dictionary) -> bool:
	var state: Dictionary = GameState.start_new_game(choices, {"random_seed": 260826, "save_id": "connected-vertical-slice"})
	if not _check(not state.is_empty(), "character creation did not produce runtime state"):
		return false
	if not _check(str(state["player"]["identity"]["first_name"]) == "Journey", "runtime state lost the chosen name"):
		return false
	if not _check(str(state["player"]["identity"]["birthday"]) == "08-21" and int(state["player"]["identity"]["age"]) == 18, "runtime state lost the generated age-18 birthday"):
		return false
	return _check(str(state["player"]["selected_traits"]["archetype"]) == "the_planner", "runtime state lost the selected archetype")


func _complete_opening_college_branch() -> bool:
	var result: Dictionary = DialogueService.begin("opening_future_talk")
	if not _view_is(result, "door_opens", "opening dialogue did not begin in the bedroom"):
		return false
	result = DialogueService.advance()
	if not _view_is(result, "elena_good_morning", "opening did not reach Elena's greeting"):
		return false
	result = DialogueService.advance()
	if not _view_is(result, "player_wakeup_response", "opening did not reach the first player response"):
		return false
	result = DialogueService.choose("ready")
	if not _view_is(result, "elena_future", "opening response did not continue to the future discussion"):
		return false
	result = DialogueService.advance()
	if not _view_is(result, "elena_terms", "opening did not explain rent and allowance terms"):
		return false
	result = DialogueService.advance()
	if not _view_is(result, "future_choice", "opening did not reach the life-path choice"):
		return false
	result = DialogueService.choose("choose_college")
	if not _view_is(result, "elena_college_reply", "college branch did not reach Elena's response"):
		return false
	result = DialogueService.advance()
	if not _view_is(result, "elena_closing", "college branch did not reach the closing line"):
		return false
	result = DialogueService.advance()
	if not _check(result.get("ok", false) and result.get("ended", false), "opening conversation did not end cleanly"):
		return false
	var state: Dictionary = GameState.current_state
	if not _check(str(state["player"]["life_path"]) == "college" and "enroll_at_westshore" in state["quest_state"]["active"], "college choice did not activate enrollment"):
		return false
	if not _check(bool(state["player"]["flags"].get("sandbox.active", false)), "opening did not unlock the sandbox"):
		return false
	return _check("quests" in state["player"]["phone"]["unlocked_apps"], "opening did not unlock the Quest app")


func _exercise_home_and_phone() -> bool:
	var home_scene: PackedScene = load("res://scenes/locations/hale_home.tscn")
	var home: Node = home_scene.instantiate()
	get_tree().root.add_child(home)
	await get_tree().process_frame
	await get_tree().process_frame
	if not _check(home.get_node_or_null("Player") == null and home.get_node_or_null("Backdrop") != null and home.get_node_or_null("Interface/Smartphone") != null, "Hale home did not create its VN backdrop and phone"):
		home.free()
		return false
	home.call("_set_current_room", "family_bathroom")
	var hygiene_before: float = float(GameState.current_state["player"]["needs"]["hygiene"])
	var shower_result: Dictionary = HomeActionService.perform("shower")
	if not _check(shower_result.get("ok", false), "shower action failed in the connected run"):
		home.free()
		return false
	if not _check(float(GameState.current_state["player"]["needs"]["hygiene"]) > hygiene_before, "shower did not improve Hygiene"):
		home.free()
		return false

	var phone: Control = home.get_node("Interface/Smartphone")
	phone.open_phone("quests")
	await get_tree().process_frame
	var app_title: Label = phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/AppTitle")
	var app_content: RichTextLabel = phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/AppContent")
	if not _check(phone.visible and app_title.text == "QUESTS" and "Enroll at Westshore" in app_content.text, "Quest app did not render the selected opening path"):
		home.free()
		return false
	phone.call("_show_app", "calendar")
	await get_tree().process_frame
	if not _check(app_title.text == "CALENDAR" and "Opening Future Talk" in app_content.text, "Calendar app did not retain the completed opening appointment"):
		home.free()
		return false
	phone.close_phone()
	home.free()
	return true


func _travel_and_enroll() -> bool:
	var route_plan: Dictionary = TravelService.plan_routes("westshore_administration_office")
	if not _check(route_plan.get("ok", false) and _route_available(route_plan, "bus"), "bus route to Westshore Administration was unavailable"):
		return false
	var travel_result: Dictionary = TravelService.travel("westshore_administration_office", "bus", "probe.connected_run")
	if not _check(travel_result.get("ok", false), "bus travel to Westshore Administration failed"):
		return false
	if not _check(str(GameState.current_state["world_state"]["current_location"]).begins_with("westshore_administration_office."), "bus travel arrived at the wrong destination"):
		return false

	var city_scene: PackedScene = load("res://scenes/locations/city_location.tscn")
	var city: Node = city_scene.instantiate()
	get_tree().root.add_child(city)
	await get_tree().process_frame
	await get_tree().process_frame
	var location_label: Label = city.get_node("Interface/Header/Margin/Layout/Top/LocationLabel")
	if not _check(location_label.text == "Westshore Administration Office", "Westshore destination scene did not render after travel"):
		city.free()
		return false
	city.free()

	var result: Dictionary = DialogueService.begin("westshore_enrollment_advisor")
	if not _view_is(result, "advisor_welcome", "enrollment advisor conversation did not begin"):
		return false
	result = DialogueService.advance()
	if not _view_is(result, "advisor_options", "advisor did not offer enrollment options"):
		return false
	result = DialogueService.choose("ready")
	if not _view_is(result, "program_choice", "advisor did not reach program selection"):
		return false
	result = DialogueService.choose("computers")
	if not _view_is(result, "load_choice", "Computer Systems selection did not reach course load information"):
		return false
	result = DialogueService.advance()
	if not _view_is(result, "load_response", "advisor did not offer course loads"):
		return false
	result = DialogueService.choose("part_time")
	if not _view_is(result, "tuition_part_time", "part-time selection did not reach tuition information"):
		return false
	result = DialogueService.advance()
	if not _view_is(result, "tuition_part_time_choice", "advisor did not offer tuition plans"):
		return false
	result = DialogueService.choose("aid_part_time")
	if not _view_is(result, "enrolled", "financial-aid choice did not create enrollment"):
		return false
	result = DialogueService.advance()
	if not _check(result.get("ok", false) and result.get("ended", false), "enrollment conversation did not end cleanly"):
		return false

	var education: Dictionary = GameState.current_state["player"]["education"]
	if not _check(bool(education.get("enrolled", false)) and str(education.get("program", "")) == "computer_systems", "Westshore did not store the selected program"):
		return false
	if not _check(education.get("courses", []).size() == 2 and _calendar_event_count("class") > 0, "part-time enrollment did not create two courses and class calendar events"):
		return false
	return _check("enroll_at_westshore" in GameState.current_state["quest_state"]["completed"], "enrollment quest did not complete")


func _schedule_and_complete_emma_walk() -> bool:
	QuestService.sync_automatic_activations("probe.connected_run")
	QuestService.sync_availability("probe.connected_run")
	if not _check("before_everything_changes" in GameState.current_state["quest_state"].get("available", []), "Emma's story offer did not become available after the opening"):
		return false
	var accept_result: Dictionary = QuestService.accept_quest("before_everything_changes")
	if not _check(accept_result.get("ok", false), "Emma's story offer could not be accepted"):
		return false
	var message_result: Dictionary = PhoneService.sync_messages()
	if not _check(message_result.get("ok", false), "Emma's invitation message did not synchronize"):
		return false

	var phone_scene: PackedScene = load("res://scenes/phone/smartphone.tscn")
	var phone: Control = phone_scene.instantiate()
	get_tree().root.add_child(phone)
	await get_tree().process_frame
	phone.open_phone("messages")
	phone.call("_open_message_thread", "emma_rowan")
	phone.call("_reply_to_message", "emma_walk_invitation", 0)
	await get_tree().process_frame
	var scheduler: Control = phone.get_node("SchedulerPanel")
	if not _check(scheduler.visible, "replying to Emma did not open the calendar scheduler"):
		phone.free()
		return false
	var contact_option: OptionButton = phone.get_node("SchedulerPanel/Margin/Layout/ContactOption")
	var type_option: OptionButton = phone.get_node("SchedulerPanel/Margin/Layout/TypeOption")
	var day_option: OptionButton = phone.get_node("SchedulerPanel/Margin/Layout/DayOption")
	var block_option: OptionButton = phone.get_node("SchedulerPanel/Margin/Layout/BlockOption")
	if not _check(str(contact_option.get_selected_metadata()) == "emma_rowan", "scheduler did not retain Emma as the participant"):
		phone.free()
		return false
	_select_dictionary_metadata(type_option, "id", "hangout")
	day_option.select(0)
	_select_option_metadata(block_option, "evening")
	phone.call("_on_confirm_schedule_pressed")
	await get_tree().process_frame
	var emma_event: Dictionary = _scheduled_event_for("emma_rowan")
	if not _check(not emma_event.is_empty(), "phone scheduler did not create Emma's calendar event"):
		phone.free()
		return false
	if not _check(bool(GameState.current_state["quest_state"]["objectives"]["before_everything_changes"].get("schedule_walk", false)), "calendar scheduling did not advance Emma's quest"):
		phone.free()
		return false
	phone.close_phone()
	phone.free()

	var route_plan: Dictionary = TravelService.plan_routes("alder_bay_park")
	var route_mode: String = _first_available_route_mode(route_plan, ["walking", "bus", "taxi"])
	if not _check(route_plan.get("ok", false) and not route_mode.is_empty(), "no route connected Westshore Administration to Alder Bay Park"):
		return false
	var travel_result: Dictionary = TravelService.travel("alder_bay_park", route_mode, "probe.emma_walk")
	if not _check(travel_result.get("ok", false), "travel to Emma's waterfront meeting failed"):
		return false
	var guard: int = 0
	while str(GameState.current_state["clock"]["block"]) != "evening" and guard < 7:
		var advance_result: Dictionary = TimeService.advance_blocks(1, "probe.wait_for_emma")
		if not _check(advance_result.get("ok", false), "time could not advance to Emma's appointment"):
			return false
		guard += 1
	if not _check(str(GameState.current_state["clock"]["block"]) == "evening", "clock did not reach Emma's scheduled block"):
		return false
	if not _check(str(GameState.current_state["world_state"]["current_location"]) == "alder_bay_park.waterfront_path", "player was not at Emma's exact meeting room"):
		return false

	var unscheduled_state: Dictionary = GameState.current_state.duplicate(true)
	for event_value: Variant in unscheduled_state["calendar_state"]["events"]:
		if event_value is Dictionary and str(event_value.get("id", "")) == str(emma_event.get("id", "")):
			event_value["status"] = "cancelled"
	var original_state: Dictionary = GameState.current_state
	GameState.replace_state(unscheduled_state)
	var blocked_result: Dictionary = DialogueService.begin("emma_alder_bay_walk")
	if not _check(not blocked_result.get("ok", false), "Emma's scheduled scene incorrectly began without a current calendar plan"):
		return false
	GameState.replace_state(original_state)

	var friendship_before: float = float(GameState.current_state["relationships"]["emma_rowan"]["friendship"])
	var result: Dictionary = DialogueService.begin("emma_alder_bay_walk")
	if not _view_is(result, "park_intro", "Emma's scheduled waterfront scene did not begin"):
		return false
	result = DialogueService.advance()
	if not _view_is(result, "emma_greeting", "Emma's scene did not reach her greeting"):
		return false
	result = DialogueService.advance()
	if not _view_is(result, "greeting_choice", "Emma's scene did not reach the greeting choice"):
		return false
	result = DialogueService.choose("warm")
	if not _view_is(result, "walk_start", "warm response did not begin the waterfront discussion"):
		return false
	result = DialogueService.advance()
	if not _view_is(result, "future_response", "Emma's scene did not reach the future choice"):
		return false
	result = DialogueService.choose("promise")
	if not _view_is(result, "emma_relieved", "friendship response did not reach Emma's reply"):
		return false
	result = DialogueService.advance()
	if not _view_is(result, "walk_end", "Emma's scene did not reach its ending"):
		return false
	result = DialogueService.advance()
	if not _check(result.get("ok", false) and result.get("ended", false), "Emma's waterfront scene did not finish cleanly"):
		return false
	if not _check("before_everything_changes" in GameState.current_state["quest_state"]["completed"], "Emma's story quest did not complete"):
		return false
	if not _check(float(GameState.current_state["relationships"]["emma_rowan"]["friendship"]) > friendship_before, "Emma's authored relationship effects did not apply"):
		return false
	return _check(_calendar_status(str(emma_event.get("id", ""))) == "completed", "Emma's completed scene did not complete its calendar appointment")


func _save_reload_and_resume() -> bool:
	var save_engine: RefCounted = SaveEngineScript.new(PROBE_SAVE_ROOT)
	var expected_state: Dictionary = GameState.current_state.duplicate(true)
	var save_result: Dictionary = save_engine.save_slot(GameState.current_state, PROBE_SLOT, {
		"timestamp_utc": "2026-08-26T12:00:00",
		"build_version": "connected-probe",
		"playtime_seconds": 1800,
	})
	if not _check(save_result.get("ok", false), "connected runtime state could not be saved"):
		return false
	GameState.clear_state()
	var load_result: Dictionary = save_engine.load_slot(PROBE_SLOT)
	if not _check(load_result.get("ok", false), "connected runtime save could not be loaded"):
		return false
	GameState.replace_state(load_result["state"].duplicate(true))
	var loaded: Dictionary = GameState.current_state
	if not _check(str(loaded["player"]["identity"]["first_name"]) == str(expected_state["player"]["identity"]["first_name"]), "save/load lost player identity"):
		return false
	if not _check(str(loaded["player"]["education"]["program"]) == "computer_systems" and bool(loaded["player"]["education"]["enrolled"]), "save/load lost Westshore enrollment"):
		return false
	if not _check("before_everything_changes" in loaded["quest_state"]["completed"], "save/load lost Emma's completed quest"):
		return false
	if not _check(str(loaded["world_state"]["current_location"]) == "alder_bay_park.waterfront_path", "save/load lost the current city room"):
		return false
	if not _check(SaveService.resume_scene_path() == AppConstants.CITY_LOCATION_SCENE, "loaded city save selected the wrong resume scene"):
		return false

	var resume_scene: PackedScene = load(SaveService.resume_scene_path())
	var resumed_city: Node = resume_scene.instantiate()
	get_tree().root.add_child(resumed_city)
	await get_tree().process_frame
	await get_tree().process_frame
	var location_label: Label = resumed_city.get_node("Interface/Header/Margin/Layout/Top/LocationLabel")
	var resumed_correctly: bool = _check(location_label.text == "Alder Bay Park", "loaded save did not render its saved destination")
	resumed_city.free()
	return resumed_correctly


func _select_multi_buttons(container: Container, count: int) -> void:
	for index: int in mini(count, container.get_child_count()):
		var button: BaseButton = container.get_child(index)
		button.set_pressed_no_signal(true)
		button.emit_signal("toggled", true)


func _option_index_for_id(option: OptionButton, item_id: int) -> int:
	for index: int in option.item_count:
		if option.get_item_id(index) == item_id:
			return index
	return -1


func _option_index_for_metadata(option: OptionButton, value: String) -> int:
	for index: int in option.item_count:
		if str(option.get_item_metadata(index)) == value:
			return index
	return -1


func _select_option_metadata(option: OptionButton, value: String) -> void:
	var index: int = _option_index_for_metadata(option, value)
	if index >= 0:
		option.select(index)


func _select_dictionary_metadata(option: OptionButton, key: String, value: String) -> void:
	for index: int in option.item_count:
		var metadata: Variant = option.get_item_metadata(index)
		if metadata is Dictionary and str(metadata.get(key, "")) == value:
			option.select(index)
			return


func _view_is(result: Dictionary, node_id: String, message: String) -> bool:
	return _check(result.get("ok", false) and str(result.get("view", {}).get("node_id", "")) == node_id, message)


func _route_available(plan: Dictionary, mode: String) -> bool:
	for option_value: Variant in plan.get("options", []):
		if option_value is Dictionary and str(option_value.get("mode", "")) == mode:
			return bool(option_value.get("available", false))
	return false


func _first_available_route_mode(plan: Dictionary, preferences: Array[String]) -> String:
	for preferred_mode: String in preferences:
		if _route_available(plan, preferred_mode):
			return preferred_mode
	return ""


func _calendar_event_count(event_type: String) -> int:
	var count: int = 0
	for event_value: Variant in GameState.current_state["calendar_state"].get("events", []):
		if event_value is Dictionary and str(event_value.get("type", "")) == event_type:
			count += 1
	return count


func _scheduled_event_for(character_id: String) -> Dictionary:
	for event_value: Variant in GameState.current_state["calendar_state"].get("events", []):
		if event_value is Dictionary and str(event_value.get("status", "")) == "scheduled" and character_id in event_value.get("participants", []):
			return event_value
	return {}


func _calendar_status(event_id: String) -> String:
	for event_value: Variant in GameState.current_state["calendar_state"].get("events", []):
		if event_value is Dictionary and str(event_value.get("id", "")) == event_id:
			return str(event_value.get("status", ""))
	return ""


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	if _failure_message.is_empty():
		_failure_message = message
	return false


func _finish_failure() -> void:
	_cleanup_probe_save()
	printerr("CONNECTED PROBE: %s" % (_failure_message if not _failure_message.is_empty() else "unknown failure"))
	get_tree().quit(1)


func _cleanup_probe_save() -> void:
	var slot_path: String = ProjectSettings.globalize_path("%s/%s" % [PROBE_SAVE_ROOT, PROBE_SLOT])
	for file_name: String in ["save.json.tmp", "save.json", "save.json.bak", "save.json.corrupt"]:
		var file_path: String = "%s/%s" % [slot_path, file_name]
		if FileAccess.file_exists(file_path):
			DirAccess.remove_absolute(file_path)
	if DirAccess.dir_exists_absolute(slot_path):
		DirAccess.remove_absolute(slot_path)
	var root_path: String = ProjectSettings.globalize_path(PROBE_SAVE_ROOT)
	if DirAccess.dir_exists_absolute(root_path):
		DirAccess.remove_absolute(root_path)
