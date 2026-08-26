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
	GameState.replace_state(state)
	var scene: PackedScene = load("res://scenes/locations/hale_home.tscn")
	var instance: Node = scene.instantiate()
	get_tree().root.add_child(instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var phone: Node = instance.get_node_or_null("Interface/Smartphone")
	var household_actors: Node = instance.get_node_or_null("HouseholdActors")
	if instance.get_node_or_null("RoomAreas/PlayerBedroom") == null or instance.get_node_or_null("Walls") == null or phone == null or household_actors == null:
		printerr("PROBE: runtime rooms, walls, household actors, or phone were not created")
		get_tree().quit(1)
		return
	if household_actors.get_child_count() != 1 or household_actors.get_node_or_null("LilyHale") == null:
		printerr("PROBE: Tuesday Morning schedule did not place only Lily at home")
		get_tree().quit(1)
		return
	instance.call("_set_current_room", "living_room")
	var lily_interaction: Dictionary = instance.call("_find_nearest_interaction", Vector2(315, 600))
	if str(lily_interaction.get("character_id", "")) != "lily_hale":
		printerr("PROBE: Lily did not expose a direct proximity interaction")
		get_tree().quit(1)
		return
	instance.call("_open_npc_panel", "lily_hale")
	var npc_action_panel: Control = instance.get_node("Interface/ActionPanel")
	var npc_action_buttons: Container = instance.get_node("Interface/ActionPanel/Margin/Layout/Scroll/ActionButtons")
	if not npc_action_panel.visible or npc_action_buttons.get_child_count() == 0:
		printerr("PROBE: household interaction did not expose authored dialogue")
		get_tree().quit(1)
		return
	instance.call("_on_close_panel_pressed")
	phone.open_phone()
	await get_tree().process_frame
	if not phone.visible or phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/Navigation/NavMargin/NavScroll/AppButtons").get_child_count() != 12:
		printerr("PROBE: phone did not open with all twelve apps")
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
	for app_id: String in ["character_profile", "contacts", "messages", "calendar", "quests", "relationships", "city_map", "weather", "settings"]:
		phone.call("_show_app", app_id)
		await get_tree().process_frame
		if str(phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/AppTitle").text).is_empty():
			printerr("PROBE: phone app did not render: %s" % app_id)
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
	if household_actors.get_child_count() != 2 or household_actors.get_node_or_null("ElenaReyesHale") == null or household_actors.get_node_or_null("DanielHale") == null:
		printerr("PROBE: Tuesday Evening schedule did not bring Elena and Daniel home")
		get_tree().quit(1)
		return
	print("PASS: Hale home runtime created rooms, scheduled family actors, HUD, active player state, and all twelve phone apps.")
	get_tree().quit(0)
