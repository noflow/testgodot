extends Node

const NewGameStateFactoryScript: GDScript = preload("res://src/core/new_game_state_factory.gd")


func _ready() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	var errors: PackedStringArray = ContentRegistry.validate_foundation()
	if not errors.is_empty():
		printerr("CITY PROBE: content validation failed")
		get_tree().quit(1)
		return
	var factory: RefCounted = NewGameStateFactoryScript.new(ContentRegistry)
	var state: Dictionary = factory.create_new_game({}, {"random_seed": 991})
	state["world_state"]["current_location"] = "westshore_administration_office.advisor_office"
	state["world_state"]["discovered_locations"].append("westshore_administration_office")
	state["quest_state"]["active"].append("enroll_at_westshore")
	state["quest_state"]["objectives"]["enroll_at_westshore"] = {"travel_to_administration": true}
	GameState.replace_state(state)
	var scene: PackedScene = load("res://scenes/locations/city_location.tscn")
	var instance: Node = scene.instantiate()
	get_tree().root.add_child(instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var phone: Node = instance.get_node_or_null("Interface/Smartphone")
	var background_image: TextureRect = instance.get_node_or_null("BackgroundImage")
	var room_buttons: Container = instance.get_node_or_null("Interface/MainMargin/MainLayout/NavigationPanel/Margin/Layout/Scroll/RoomButtons")
	var navigation_panel: Control = instance.get_node_or_null("Interface/MainMargin/MainLayout/NavigationPanel")
	var scene_panel: PanelContainer = instance.get_node_or_null("Interface/MainMargin/MainLayout/ScenePanel")
	var scene_title: Label = instance.get_node_or_null("%SceneTitle")
	var scene_description: Label = instance.get_node_or_null("%SceneDescription")
	var encounter_text: RichTextLabel = instance.get_node_or_null("%EncounterText")
	if phone == null or instance.get_node_or_null("Player") != null or background_image == null or background_image.texture == null or room_buttons == null or navigation_panel == null or scene_panel == null or scene_title == null or scene_description == null or encounter_text == null:
		printerr("CITY PROBE: VN backdrop, area navigation, or smartphone is missing")
		get_tree().quit(1)
		return
	var scene_style: StyleBox = scene_panel.get_theme_stylebox("panel")
	if scene_title.visible or scene_description.visible or encounter_text.visible or not scene_style is StyleBoxFlat or (scene_style as StyleBoxFlat).bg_color.a > 0.001:
		printerr("CITY PROBE: destination stage still displayed the framed location or encounter overlay")
		get_tree().quit(1)
		return
	if str(instance.get_node("Interface/Header/Margin/Layout/Top/LocationLabel").text) != "Westshore Administration Office" or navigation_panel.visible:
		printerr("CITY PROBE: destination data did not render")
		get_tree().quit(1)
		return
	instance.call("_on_interact_requested", Vector2.ZERO)
	await get_tree().process_frame
	var action_panel: Control = instance.get_node("Interface/MainMargin/MainLayout/ActionPanel")
	var action_buttons: VBoxContainer = instance.get_node("Interface/MainMargin/MainLayout/ActionPanel/Margin/Layout/Scroll/ActionButtons")
	if not action_panel.visible or room_buttons.get_child_count() == 0 or action_buttons.get_child_count() != 1 or action_buttons.get_child(0).disabled:
		printerr("CITY PROBE: enrollment activity did not populate")
		get_tree().quit(1)
		return
	instance.call("_close_action_panel")
	var previous_arrow: Button = instance.get_node_or_null("%PrevRoomArrow")
	var outside_arrow: Button = instance.get_node_or_null("%OutsideArrow")
	var down_arrow: Button = instance.get_node_or_null("%DownRoomArrow")
	var next_arrow: Button = instance.get_node_or_null("%NextRoomArrow")
	if previous_arrow == null or outside_arrow == null or down_arrow == null or next_arrow == null or "Reception" not in previous_arrow.text or "Financial Aid" not in next_arrow.text or outside_arrow.visible or down_arrow.visible:
		printerr("CITY PROBE: data-driven directional area arrows were not initialized")
		get_tree().quit(1)
		return
	next_arrow.pressed.emit()
	await get_tree().process_frame
	if str(GameState.current_state["world_state"]["current_location"]) != "westshore_administration_office.financial_aid":
		printerr("CITY PROBE: right arrow did not move to the next data-driven area")
		get_tree().quit(1)
		return
	if outside_arrow.visible:
		printerr("CITY PROBE: an interior office exposed an instant exit shortcut")
		get_tree().quit(1)
		return
	phone.open_phone("city_map")
	await get_tree().process_frame
	phone.call("_open_route_planner", "hale_home")
	await get_tree().process_frame
	var phone_status_label: Label = phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/PhoneStatus")
	if phone.get_node("RoutePanel").visible or "entrance" not in str(phone_status_label.text).to_lower():
		printerr("CITY PROBE: the phone map bypassed an interior room")
		get_tree().quit(1)
		return
	phone.close_phone()
	previous_arrow.pressed.emit()
	previous_arrow.pressed.emit()
	await get_tree().process_frame
	if str(GameState.current_state["world_state"]["current_location"]) != "westshore_administration_office.reception" or "Transit" not in outside_arrow.text:
		printerr("CITY PROBE: player could not walk back through the advisor office to reception")
		get_tree().quit(1)
		return
	outside_arrow.pressed.emit()
	await get_tree().process_frame
	if not phone.visible or str(phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/AppTitle").text) != "CITY MAP":
		printerr("CITY PROBE: reception transit arrow did not open destination selection")
		get_tree().quit(1)
		return
	phone.close_phone()
	phone.open_phone("city_map")
	await get_tree().process_frame
	phone.call("_open_route_planner", "hale_home")
	await get_tree().process_frame
	if not phone.get_node("RoutePanel").visible or phone.get_node("RoutePanel/Margin/Layout/RouteOption").item_count != 4:
		printerr("CITY PROBE: reverse route planner did not populate")
		get_tree().quit(1)
		return
	phone.close_phone()
	instance.queue_free()
	await get_tree().process_frame
	var hidden_state: Dictionary = factory.create_new_game({}, {"random_seed": 992})
	hidden_state["world_state"]["current_location"] = "alder_heights_residential_street.hale_block"
	GameState.replace_state(hidden_state)
	var street_instance: Node = scene.instantiate()
	get_tree().root.add_child(street_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var rowan_arrow: Button = street_instance.get_node("%PrevRoomArrow")
	var street_phone: Node = street_instance.get_node("Interface/Smartphone")
	if rowan_arrow.visible:
		printerr("CITY PROBE: Emma's undiscovered home exposed a street arrow")
		get_tree().quit(1)
		return
	street_phone.open_phone("city_map")
	await get_tree().process_frame
	var street_map_text: RichTextLabel = street_phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/AppContent")
	if "Rowan Family Home" in str(street_map_text.text):
		printerr("CITY PROBE: Emma's undiscovered home appeared on the phone map")
		get_tree().quit(1)
		return
	street_phone.close_phone()
	var discovery_result: Dictionary = SimulationService.apply_operation("world.discover_location", {
		"location_id": "rowan_family_home",
		"discovery_source": "invitation",
		"character_id": "emma_rowan",
	}, "probe.emma_home_invitation")
	street_instance.call("_render_location")
	await get_tree().process_frame
	if not discovery_result.get("ok", false) or not rowan_arrow.visible or "Rowan Family Home" not in rowan_arrow.text:
		printerr("CITY PROBE: invitation discovery did not reveal Emma's street arrow")
		get_tree().quit(1)
		return
	var scene_tree: SceneTree = get_tree()
	rowan_arrow.pressed.emit()
	if str(GameState.current_state["world_state"]["current_location"]) != "rowan_family_home.porch":
		printerr("CITY PROBE: revealed residence arrow did not arrive at the authored porch")
		scene_tree.quit(1)
		return
	print("PASS: City destination rendered immersive arrows, blocked shortcuts, hid undiscovered NPC homes, and revealed invited residences.")
	scene_tree.quit(0)
