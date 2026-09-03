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
	var navigation_panel: Control = instance.get_node_or_null("Interface/Screen/MainMargin/MainLayout/NavigationPanel")
	var room_action_buttons: Container = instance.get_node_or_null("Interface/Screen/MainMargin/MainLayout/ActionPanel/Margin/Layout/Scroll/ActionButtons")
	var character_text: RichTextLabel = instance.get_node_or_null("Interface/Screen/MainMargin/MainLayout/ScenePanel/Margin/Layout/CharacterText")
	var scene_panel: PanelContainer = instance.get_node_or_null("Interface/Screen/MainMargin/MainLayout/ScenePanel")
	var scene_title: Label = instance.get_node_or_null("%SceneTitle")
	var scene_description: Label = instance.get_node_or_null("%SceneDescription")
	if instance.get_node_or_null("Player") != null or background_image == null or background_image.texture == null or phone == null or room_buttons == null or navigation_panel == null or room_action_buttons == null or character_text == null or scene_panel == null or scene_title == null or scene_description == null:
		printerr("PROBE: VN home backdrop, room navigation, choices, or phone were not created")
		get_tree().quit(1)
		return
	var scene_style: StyleBox = scene_panel.get_theme_stylebox("panel")
	var background_test_state: Dictionary = GameState.current_state.duplicate(true)
	for block: String in ["late_evening", "night", "early_morning"]:
		var clock_test_state: Dictionary = background_test_state.duplicate(true)
		clock_test_state["clock"]["block"] = block
		GameState.replace_state(clock_test_state)
		await get_tree().process_frame
		await get_tree().process_frame
		var suffix: String = "player_bedroom_night.png" if block in ["late_evening", "night"] else "player_bedroom.png"
		if not background_image.texture.resource_path.ends_with(suffix):
			printerr("PROBE: bedroom artwork did not follow the clock without leaving the room")
			get_tree().quit(1)
			return
	GameState.replace_state(background_test_state)
	await get_tree().process_frame
	await get_tree().process_frame
	if scene_title.visible or scene_description.visible or character_text.visible or not scene_style is StyleBoxFlat or (scene_style as StyleBoxFlat).bg_color.a > 0.001:
		printerr("PROBE: home stage still displayed the framed location or occupancy overlay")
		get_tree().quit(1)
		return
	if room_buttons.get_child_count() != 14 or navigation_panel.visible:
		printerr("PROBE: immersive home did not retain fourteen authored spaces while hiding quick room travel")
		get_tree().quit(1)
		return
	var previous_arrow: Button = _navigation_button(instance, "PrevRoomArrow")
	var outside_arrow: Button = _navigation_button(instance, "OutsideArrow")
	var down_arrow: Button = _navigation_button(instance, "DownRoomArrow")
	var next_arrow: Button = _navigation_button(instance, "NextRoomArrow")
	var directional_navigation: Node = instance.get_node_or_null("%DirectionalNavigation")
	var local_map_button: Button = instance.get_node_or_null("Interface/Screen/Footer/Margin/Layout/Buttons/MapButton")
	if previous_arrow == null or outside_arrow == null or down_arrow == null or next_arrow == null or previous_arrow.visible or outside_arrow.visible or next_arrow.visible or not down_arrow.visible or not _arrow_leads_to(down_arrow, "Upstairs Landing"):
		printerr("PROBE: bedroom did not show only its real exit to the upstairs landing")
		get_tree().quit(1)
		return
	if directional_navigation == null or local_map_button == null or "Local Map" not in local_map_button.text:
		printerr("PROBE: the shared contextual mini-map control was not available from the home footer")
		get_tree().quit(1)
		return
	local_map_button.pressed.emit()
	await get_tree().process_frame
	var home_map_overlay: Control = directional_navigation.get_node("ContextMiniMap/MiniMapOverlay")
	var home_map_scope: Label = directional_navigation.get_node("ContextMiniMap/MiniMapOverlay/MapPanel/Margin/Layout/Header/Titles/MiniMapScope")
	var home_map_current: Label = directional_navigation.get_node("ContextMiniMap/MiniMapOverlay/MapPanel/Margin/Layout/MiniMapCurrent")
	var home_map_nodes: PackedStringArray = directional_navigation.call("minimap_node_ids")
	if not home_map_overlay.visible or home_map_scope.text != "HOUSE MAP" or "Your Bedroom" not in home_map_current.text or "player_bedroom" not in home_map_nodes or "kitchen" not in home_map_nodes or "boundary:front_yard" not in home_map_nodes or "hale_block" in home_map_nodes:
		printerr("PROBE: the bedroom mini-map did not show the Hale house layout and exterior boundary")
		get_tree().quit(1)
		return
	directional_navigation.call("close_minimap")
	if str(GameState.current_state["world_state"]["current_location"]) != "hale_home.player_bedroom":
		printerr("PROBE: viewing the local house map teleported the player")
		get_tree().quit(1)
		return
	if not _navigation_layout_is_uniform(instance):
		printerr("PROBE: home directional controls were not aligned to the shared screen-edge compass")
		get_tree().quit(1)
		return
	down_arrow.pressed.emit()
	await get_tree().process_frame
	if str(GameState.current_state["world_state"]["current_location"]) != "hale_home.upstairs_landing" or not outside_arrow.visible or not _arrow_leads_to(outside_arrow, "Your Bedroom"):
		printerr("PROBE: player could not leave and return to the player bedroom from the landing")
		get_tree().quit(1)
		return
	outside_arrow.pressed.emit()
	down_arrow.pressed.emit()
	previous_arrow.pressed.emit()
	await get_tree().process_frame
	if str(GameState.current_state["world_state"]["current_location"]) != "hale_home.upstairs_hall":
		printerr("PROBE: upstairs landing did not connect the player bedroom to the bedroom hall")
		get_tree().quit(1)
		return
	previous_arrow.pressed.emit()
	await get_tree().process_frame
	if str(GameState.current_state["world_state"]["current_location"]) != "hale_home.lily_bedroom" or not _container_has_button_text(room_action_buttons, "Knock"):
		printerr("PROBE: left hallway arrow did not reach Lily's knock-first doorway")
		get_tree().quit(1)
		return
	next_arrow.pressed.emit()
	down_arrow.pressed.emit()
	await get_tree().process_frame
	if str(GameState.current_state["world_state"]["current_location"]) != "hale_home.family_bathroom":
		printerr("PROBE: bathroom was not reachable through the upstairs hall")
		get_tree().quit(1)
		return
	outside_arrow.pressed.emit()
	outside_arrow.pressed.emit()
	await get_tree().process_frame
	if str(GameState.current_state["world_state"]["current_location"]) != "hale_home.parents_bedroom" or not _container_has_button_text(room_action_buttons, "Knock"):
		printerr("PROBE: up hallway arrow did not reach the parents' knock-first doorway")
		get_tree().quit(1)
		return
	down_arrow.pressed.emit()
	next_arrow.pressed.emit()
	down_arrow.pressed.emit()
	await get_tree().process_frame
	if str(GameState.current_state["world_state"]["current_location"]) != "hale_home.entryway":
		printerr("PROBE: bedroom floor did not lead downstairs to the front entryway")
		get_tree().quit(1)
		return
	previous_arrow.pressed.emit()
	down_arrow.pressed.emit()
	next_arrow.pressed.emit()
	await get_tree().process_frame
	if str(GameState.current_state["world_state"]["current_location"]) != "hale_home.kitchen":
		printerr("PROBE: kitchen path did not require entryway, living room, and dining room traversal")
		get_tree().quit(1)
		return
	var daytime_state: Dictionary = GameState.current_state.duplicate(true)
	var night_state: Dictionary = daytime_state.duplicate(true)
	night_state["clock"]["block"] = "night"
	night_state["world_state"]["current_location"] = "hale_home.lily_bedroom"
	GameState.replace_state(night_state)
	instance.call("_sync_household_schedule", true)
	instance.call("_set_current_room", "lily_bedroom")
	await get_tree().process_frame
	if not _container_has_button_text(room_action_buttons, "Locked") or "locked" not in str(character_text.text).to_lower():
		printerr("PROBE: Lily's door did not become locked during its authored night block")
		get_tree().quit(1)
		return
	instance.call("_set_current_room", "parents_bedroom")
	await get_tree().process_frame
	if not _container_has_button_text(room_action_buttons, "Locked"):
		printerr("PROBE: parents' door did not become locked during its authored night block")
		get_tree().quit(1)
		return
	var override_state: Dictionary = GameState.current_state.duplicate(true)
	override_state["world_state"]["world_flags"]["hale_door_lock_overrides"] = {"parents_bedroom": false}
	GameState.replace_state(override_state)
	instance.call("_sync_household_schedule", true)
	instance.call("_set_current_room", "parents_bedroom")
	await get_tree().process_frame
	if _container_has_button_text(room_action_buttons, "Locked") or not _container_has_button_text(room_action_buttons, "Knock Before"):
		printerr("PROBE: story override could not unlock the parents' door for an authored scene")
		get_tree().quit(1)
		return
	var occupied_bathroom_state: Dictionary = GameState.current_state.duplicate(true)
	occupied_bathroom_state["world_state"]["world_flags"]["hale_bathroom_door_override"] = {"status": "occupied_locked", "occupant_id": "lily_hale"}
	GameState.replace_state(occupied_bathroom_state)
	instance.call("_sync_household_schedule", true)
	instance.call("_set_current_room", "family_bathroom")
	await get_tree().process_frame
	if not _container_has_button_text(room_action_buttons, "Occupied Bathroom Door") or not _container_has_button_text(room_action_buttons, "Wait 20 Minutes") or _container_has_button_text(room_action_buttons, "Take a Shower") or "locked" not in str(character_text.text).to_lower():
		printerr("PROBE: occupied family bathroom did not lock its door and block hygiene actions")
		get_tree().quit(1)
		return
	var available_bathroom_state: Dictionary = GameState.current_state.duplicate(true)
	available_bathroom_state["world_state"]["world_flags"]["hale_bathroom_door_override"] = {"status": "available"}
	GameState.replace_state(available_bathroom_state)
	instance.call("_sync_household_schedule", true)
	instance.call("_set_current_room", "family_bathroom")
	await get_tree().process_frame
	if not _container_has_button_text(room_action_buttons, "Take a Shower") or _container_has_button_text(room_action_buttons, "Bathroom Door"):
		printerr("PROBE: bathroom story override could not make hygiene actions available")
		get_tree().quit(1)
		return
	GameState.replace_state(daytime_state)
	instance.call("_sync_household_schedule", true)
	instance.call("_set_current_room", "kitchen")
	if not outside_arrow.disabled:
		printerr("PROBE: kitchen incorrectly exposed a direct outside shortcut")
		get_tree().quit(1)
		return
	previous_arrow.pressed.emit()
	outside_arrow.pressed.emit()
	next_arrow.pressed.emit()
	next_arrow.pressed.emit()
	await get_tree().process_frame
	if str(GameState.current_state["world_state"]["current_location"]) != "hale_home.front_yard" or not _arrow_leads_to(outside_arrow, "Hale Block"):
		printerr("PROBE: kitchen-to-outside path did not pass dining, living, entryway, and front yard")
		get_tree().quit(1)
		return
	local_map_button.pressed.emit()
	await get_tree().process_frame
	var outdoor_map_title: Label = directional_navigation.get_node("ContextMiniMap/MiniMapOverlay/MapPanel/Margin/Layout/Header/Titles/MiniMapTitle")
	var outdoor_map_nodes: PackedStringArray = directional_navigation.call("minimap_node_ids")
	if not home_map_overlay.visible or home_map_scope.text != "NEIGHBORHOOD MAP" or "OUTSIDE HALE HOME" not in outdoor_map_title.text or "hale_home.front_yard" not in outdoor_map_nodes or "hale_block" not in outdoor_map_nodes or "alder_heights_bus_stop.shelter" not in outdoor_map_nodes or "player_bedroom" in outdoor_map_nodes or "rowan_family_home.porch" in outdoor_map_nodes:
		printerr("PROBE: the front-yard mini-map did not switch to the discovered outdoor neighborhood context")
		get_tree().quit(1)
		return
	directional_navigation.call("close_minimap")
	down_arrow.pressed.emit()
	instance.call("_set_current_room", "player_bedroom")
	instance.call("_set_current_room", "living_room")
	await get_tree().process_frame
	var portrait_stage: HBoxContainer = instance.get_node("Interface/Screen/MainMargin/MainLayout/ScenePanel/Margin/Layout/PortraitStage")
	if character_text.visible or portrait_stage.get_child_count() != 1 or portrait_stage.get_child(0).get_child_count() != 1 or not _portrait_card_has_texture(portrait_stage.get_child(0)) or not _container_has_button_text(room_action_buttons, "Talk to Lily"):
		printerr("PROBE: Tuesday Morning did not render Lily as an unframed sprite on the background stage")
		get_tree().quit(1)
		return
	instance.call("_open_npc_panel", "lily_hale")
	var npc_action_buttons: Container = instance.get_node("Interface/Screen/MainMargin/MainLayout/ActionPanel/Margin/Layout/Scroll/ActionButtons")
	if npc_action_buttons.get_child_count() < 2:
		printerr("PROBE: household interaction did not expose authored dialogue")
		get_tree().quit(1)
		return
	instance.call("_render_room")
	GameState.current_state["world_state"]["current_location"] = "alder_heights_residential_street.hale_block"
	var exploration_result: Dictionary = CityActionService.perform("explore_hale_block")
	if not exploration_result.get("ok", false) or str(exploration_result.get("outcome", {}).get("id", "")) != "first_orientation":
		printerr("PROBE: Hale Block exploration did not resolve its first-visit outcome")
		get_tree().quit(1)
		return
	phone.open_phone()
	await get_tree().process_frame
	if not phone.visible or phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/Navigation/NavMargin/NavScroll/AppButtons").get_child_count() != 15:
		printerr("PROBE: phone did not open with all fifteen apps")
		get_tree().quit(1)
		return
	phone.call("_show_app", "notifications")
	await get_tree().process_frame
	var exploration_phone_content: RichTextLabel = phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/AppContent")
	if "Alder Heights Notes Started" not in exploration_phone_content.text:
		printerr("PROBE: exploration notification did not render in the Notifications app")
		get_tree().quit(1)
		return
	phone.call("_show_app", "city_map")
	await get_tree().process_frame
	if "LOCAL DISCOVERIES" not in exploration_phone_content.text or "Neighborhood Corner" not in exploration_phone_content.text:
		printerr("PROBE: exploration lead did not render in City Map notes")
		get_tree().quit(1)
		return
	GameState.current_state["world_state"]["current_location"] = "hale_home.living_room"
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
	phone.call("_show_app", "housing")
	await get_tree().process_frame
	if str(phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/AppTitle").text) != "HOUSING" or "PORT ALDER LISTINGS" not in str(phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/AppContent").text):
		printerr("PROBE: Housing app did not render the property market")
		get_tree().quit(1)
		return
	phone.call("_show_app", "education")
	await get_tree().process_frame
	if str(phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/AppTitle").text) != "EDUCATION":
		printerr("PROBE: Education app did not render the academic dashboard")
		get_tree().quit(1)
		return
	for app_id: String in ["character_profile", "contacts", "messages", "notifications", "calendar", "quests", "relationships", "city_map", "weather", "settings"]:
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
	var phone_status_label: Label = phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/PhoneStatus")
	if route_panel.visible or "front yard" not in str(phone_status_label.text).to_lower():
		printerr("PROBE: phone map bypassed the home's immersive room and doorway path")
		get_tree().quit(1)
		return
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


func _navigation_button(instance: Node, button_name: String) -> Button:
	var navigation: Node = instance.get_node_or_null("%DirectionalNavigation")
	if navigation == null:
		return null
	return navigation.get_node_or_null(button_name) as Button


func _navigation_layout_is_uniform(instance: Node) -> bool:
	var left: Button = _navigation_button(instance, "PrevRoomArrow")
	var up: Button = _navigation_button(instance, "OutsideArrow")
	var right: Button = _navigation_button(instance, "NextRoomArrow")
	var down: Button = _navigation_button(instance, "DownRoomArrow")
	if left == null or up == null or right == null or down == null:
		return false
	return (
		is_equal_approx(left.anchor_left, 0.0)
		and is_equal_approx(left.anchor_top, 0.5)
		and is_equal_approx(up.anchor_left, 0.5)
		and is_equal_approx(up.anchor_top, 0.0)
		and is_equal_approx(right.anchor_left, 1.0)
		and is_equal_approx(right.anchor_top, 0.5)
		and is_equal_approx(down.anchor_left, 0.5)
		and is_equal_approx(down.anchor_top, 1.0)
		and left.size.x <= 191.0
		and left.size.y <= 33.0
		and up.size.x <= 191.0
		and up.size.y <= 33.0
	)


func _arrow_leads_to(button: Button, destination_fragment: String) -> bool:
	return button != null and destination_fragment in str(button.get_meta("destination_label", ""))
