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
	if instance.get_node_or_null("RoomAreas/PlayerBedroom") == null or instance.get_node_or_null("Walls") == null or phone == null:
		printerr("PROBE: runtime rooms, walls, or phone were not created")
		get_tree().quit(1)
		return
	phone.open_phone()
	await get_tree().process_frame
	if not phone.visible or phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/Navigation/NavMargin/NavScroll/AppButtons").get_child_count() != 9:
		printerr("PROBE: phone did not open with all nine apps")
		get_tree().quit(1)
		return
	for app_id: String in ["character_profile", "contacts", "messages", "calendar", "quests", "relationships", "city_map", "weather", "settings"]:
		phone.call("_show_app", app_id)
		await get_tree().process_frame
		if str(phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/AppTitle").text).is_empty():
			printerr("PROBE: phone app did not render: %s" % app_id)
			get_tree().quit(1)
			return
	phone.call("_open_scheduler", "emma_rowan")
	await get_tree().process_frame
	if not phone.get_node("SchedulerPanel").visible or phone.get_node("SchedulerPanel/Margin/Layout/DayOption").item_count != 7:
		printerr("PROBE: calendar scheduler did not populate")
		get_tree().quit(1)
		return
	phone.close_phone()
	print("PASS: Hale home runtime created rooms, walls, HUD, active player state, and all nine phone apps.")
	get_tree().quit(0)
