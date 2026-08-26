extends Node

const NewGameStateFactoryScript: GDScript = preload("res://src/core/new_game_state_factory.gd")


func _ready() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	var errors: PackedStringArray = ContentRegistry.validate_foundation()
	if not errors.is_empty():
		printerr("PROBE: content validation failed")
		get_tree().quit(1)
		return
	var factory: RefCounted = NewGameStateFactoryScript.new(ContentRegistry)
	var state: Dictionary = factory.create_new_game({}, {"random_seed": 909})
	state["player"]["flags"]["sandbox.active"] = true
	state["player"]["phone"]["unlocked_apps"].append("quests")
	state["player"]["phone"]["unlocked_apps"].append("education")
	GameState.replace_state(state)
	var scene: PackedScene = load("res://scenes/locations/hale_home.tscn")
	var instance: Node = scene.instantiate()
	get_tree().root.add_child(instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var phone: Node = instance.get_node_or_null("Interface/Smartphone")
	var background_image: TextureRect = instance.get_node_or_null("BackgroundImage")
	var room_buttons: Container = instance.get_node_or_null("Interface/Screen/MainMargin/MainLayout/NavigationPanel/Margin/Layout/Scroll/RoomButtons")
	var room_action_buttons: Container = instance.get_node_or_null("Interface/Screen/MainMargin/MainLayout/ActionPanel/Margin/Layout/Scroll/ActionButtons")
	if instance.get_node_or_null("Player") != null or background_image == null or background_image.texture == null or phone == null or room_buttons == null or room_action_buttons == null:
		printerr("PROBE: VN home backdrop, room navigation, choices, or phone were not created")
		get_tree().quit(1)
		return
	if room_buttons.get_child_count() != 12:
		printerr("PROBE: VN home did not expose all twelve authored rooms")
		get_tree().quit(1)
		return
	instance.call("_set_current_room", "living_room")
	await get_tree().process_frame
	var character_text: RichTextLabel = instance.get_node("Interface/Screen/MainMargin/MainLayout/ScenePanel/Margin/Layout/CharacterText")
	var portrait_stage: HBoxContainer = instance.get_node("Interface/Screen/MainMargin/MainLayout/ScenePanel/Margin/Layout/PortraitStage")
	if "Lily Hale" not in character_text.text or portrait_stage.get_child_count() != 1 or not _portrait_card_has_texture(portrait_stage.get_child(0)) or not _container_has_button_text(room_action_buttons, "Talk to Lily"):
		printerr("PROBE: Tuesday Morning schedule did not expose Lily on the living-room VN stage")
		get_tree().quit(1)
		return
	instance.call("_open_npc_panel", "lily_hale")
	var npc_action_buttons: Container = instance.get_node("Interface/Screen/MainMargin/MainLayout/ActionPanel/Margin/Layout/Scroll/ActionButtons")
	if npc_action_buttons.get_child_count() < 2:
		printerr("PROBE: household interaction did not expose authored dialogue")
		get_tree().quit(1)
		return
	instance.call("_render_room")
	phone.open_phone()
	await get_tree().process_frame
	if not phone.visible or phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/Navigation/NavMargin/NavScroll/AppButtons").get_child_count() != 13:
		printerr("PROBE: phone did not open with all thirteen apps")
		get_tree().quit(1)
		return
	phone.call("_show_app", "jobs")
	await get_tree().process_frame
	if str(phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/AppTitle").text) != "JOBS" or phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/ActionScroll/AppActions").get_child_count() < 10:
		printerr("PROBE: Jobs app did not render the employment catalog")
		get_tree().quit(1)
		return
	phone.call("_show_app", "money")
	await get_tree().process_frame
	if str(phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/AppTitle").text) != "MONEY":
		printerr("PROBE: Money app did not render the live budget")
		get_tree().quit(1)
		return
	phone.call("_show_app", "education")
	await get_tree().process_frame
	if str(phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/AppTitle").text) != "EDUCATION":
		printerr("PROBE: Education app did not render the academic dashboard")
		get_tree().quit(1)
		return
	for app_id: String in ["character_profile", "contacts", "messages", "calendar", "quests", "relationships", "city_map", "weather", "settings"]:
		phone.call("_show_app", app_id)
		await get_tree().process_frame
		if str(phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/AppTitle").text).is_empty():
			printerr("PROBE: phone app did not render: %s" % app_id)
			get_tree().quit(1)
			return
	phone.call("_show_app", "settings")
	await get_tree().process_frame
	var settings_content: RichTextLabel = phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/AppContent")
	var settings_actions: Container = phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/ActionScroll/AppActions")
	if settings_actions.get_child_count() < 34 or "Screen-edge effects" not in settings_content.text or "CONTROLS" not in settings_content.text:
		printerr("PROBE: Settings app did not expose its accessibility, audio, display, save, and remapping controls")
		get_tree().quit(1)
		return
	var original_scale: float = SettingsService.text_scale
	var original_contrast: bool = SettingsService.high_contrast
	SettingsService.text_scale = 1.75
	SettingsService.high_contrast = true
	SettingsService.apply_accessibility(phone)
	var settings_title: Label = phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/AppTitle")
	if not is_equal_approx(ThemeDB.fallback_base_scale, 1.75) or settings_title.get_theme_color("font_color") != Color.WHITE:
		printerr("PROBE: large-text or high-contrast accessibility did not apply to the live phone")
		get_tree().quit(1)
		return
	SettingsService.text_scale = original_scale
	SettingsService.high_contrast = original_contrast
	SettingsService.apply_accessibility(phone)
	var menu_settings_scene: PackedScene = load("res://scenes/menus/settings_panel.tscn")
	var menu_settings: Control = menu_settings_scene.instantiate()
	get_tree().root.add_child(menu_settings)
	await get_tree().process_frame
	menu_settings.call("open_panel")
	await get_tree().process_frame
	var menu_settings_summary: RichTextLabel = menu_settings.get_node("Panel/Margin/Layout/Columns/SettingsSummary")
	var menu_settings_actions: Container = menu_settings.get_node("Panel/Margin/Layout/Columns/ActionScroll/SettingsActions")
	if not menu_settings.visible or menu_settings_actions.get_child_count() != 30 or "ACCESSIBILITY" not in menu_settings_summary.text or "CONTROLS" not in menu_settings_summary.text:
		printerr("PROBE: reusable main-menu settings panel did not render every settings category")
		get_tree().quit(1)
		return
	menu_settings.call("close_panel")
	menu_settings.queue_free()
	phone.call("_show_app", "relationships")
	phone.call("_open_relationship_detail", "emma_rowan")
	await get_tree().process_frame
	var relationship_content: RichTextLabel = phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/AppContent")
	var relationship_actions: Container = phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/ActionScroll/AppActions")
	if "Before Everything Changes" not in relationship_content.text or relationship_actions.get_child_count() < 2:
		printerr("PROBE: Emma's relationship detail did not expose her chapter and invitation actions")
		get_tree().quit(1)
		return
	var invitation_button: Button = relationship_actions.get_child(1)
	invitation_button.pressed.emit()
	await get_tree().process_frame
	var relationship_date_found: bool = false
	for calendar_event: Variant in GameState.current_state["calendar_state"].get("events", []):
		if calendar_event is Dictionary and bool(calendar_event.get("relationship_date", false)) and str(calendar_event.get("relationship_character_id", "")) == "emma_rowan":
			relationship_date_found = true
			break
	if not relationship_date_found:
		printerr("PROBE: relationship invitation did not create Emma's calendar date")
		get_tree().quit(1)
		return
	phone.call("_open_route_planner", "alder_bay_park")
	await get_tree().process_frame
	var route_panel: Control = phone.get_node("RoutePanel")
	var route_option: OptionButton = phone.get_node("RoutePanel/Margin/Layout/RouteOption")
	if not route_panel.visible or route_option.item_count != 4 or phone.get_node("RoutePanel/Margin/Layout/Buttons/ConfirmTravelButton").disabled:
		printerr("PROBE: city map route confirmation did not populate four available modes")
		get_tree().quit(1)
		return
	phone.call("_on_close_route_pressed")
	phone.call("_open_scheduler", "emma_rowan")
	await get_tree().process_frame
	if not phone.get_node("SchedulerPanel").visible or phone.get_node("SchedulerPanel/Margin/Layout/DayOption").item_count != 7:
		printerr("PROBE: calendar scheduler did not populate")
		get_tree().quit(1)
		return
	phone.close_phone()
	TimeService.advance_blocks(3, "probe.household_evening")
	await get_tree().process_frame
	await get_tree().process_frame
	var resolutions: Dictionary = instance.get("_npc_resolutions")
	if not bool(resolutions.get("elena_reyes_hale", {}).get("present", false)) or not bool(resolutions.get("daniel_hale", {}).get("present", false)):
		printerr("PROBE: Tuesday Evening schedule did not make Elena and Daniel available at home")
		get_tree().quit(1)
		return
	var tracking_result: Dictionary = QuestService.set_tracked("opening_future_choice", true)
	phone.open_phone("quests")
	await get_tree().process_frame
	var app_title: Label = phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/AppTitle")
	var quest_content: RichTextLabel = phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/AppContent")
	var quest_actions: Container = phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/ActionScroll/AppActions")
	if not tracking_result.get("ok", false) or not phone.visible or app_title.text != "QUESTS" or "AVAILABLE OFFERS" not in quest_content.text or "TRACKED" not in quest_content.text or quest_actions.get_child_count() < 4:
		printerr("PROBE: player-controlled quest tracking did not render in the phone")
		get_tree().quit(1)
		return
	phone.call("_decide_quest", "postpone", "before_everything_changes")
	await get_tree().process_frame
	if "before_everything_changes" not in GameState.current_state["quest_state"].get("postponed", []) or "before_everything_changes" in GameState.current_state["quest_state"].get("active", []):
		printerr("PROBE: phone could not postpone a discovered quest without starting it")
		get_tree().quit(1)
		return
	phone.call("_decide_quest", "reconsider", "before_everything_changes")
	await get_tree().process_frame
	if "before_everything_changes" not in GameState.current_state["quest_state"].get("available", []):
		printerr("PROBE: phone could not reconsider a postponed quest offer")
		get_tree().quit(1)
		return
	phone.close_phone()
	instance.call("_toggle_quest_panel")
	await get_tree().process_frame
	var tracker_panel: Control = instance.get_node("Interface/QuestPanel")
	var tracker_text: RichTextLabel = instance.get_node("Interface/QuestPanel/Margin/Layout/QuestText")
	if not tracker_panel.visible or "Choose Your Direction" not in tracker_text.text:
		printerr("PROBE: HUD tracker did not show the quest the player pinned")
		get_tree().quit(1)
		return
	instance.call("_toggle_quest_panel")
	var sunday_state: Dictionary = GameState.current_state.duplicate(true)
	sunday_state["clock"].merge({"year": 1, "month": 8, "day": 25, "weekday": "sunday", "block": "evening", "minute_within_block": 0}, true)
	GameState.replace_state(sunday_state)
	await get_tree().process_frame
	await get_tree().process_frame
	if phone.visible or GameState.current_state.has("weekly_review_state"):
		printerr("PROBE: Sunday Evening interrupted sandbox play with a weekly-planning flow")
		get_tree().quit(1)
		return
	print("PASS: Hale home runtime created VN room navigation, scheduled character encounters, all phone apps, accessibility controls, and sandbox quest tracking.")
	get_tree().quit(0)


func _container_has_button_text(container: Container, fragment: String) -> bool:
	for child: Node in container.get_children():
		if child is Button and fragment in child.text:
			return true
	return false


func _portrait_card_has_texture(card: Node) -> bool:
	for child: Node in card.get_children():
		if child is TextureRect:
			return child.texture != null
	return false
