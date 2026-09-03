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
	var artwork_test_state: Dictionary = GameState.current_state.duplicate(true)
	var night_artwork_state: Dictionary = artwork_test_state.duplicate(true)
	night_artwork_state["clock"]["block"] = "late_evening"
	GameState.replace_state(night_artwork_state)
	await get_tree().process_frame
	await get_tree().process_frame
	if not background_image.texture.resource_path.ends_with("/advisor_office_night.png"):
		printerr("CITY PROBE: city artwork did not change to night without leaving the room")
		get_tree().quit(1)
		return
	GameState.replace_state(artwork_test_state)
	await get_tree().process_frame
	await get_tree().process_frame
	if not background_image.texture.resource_path.ends_with("/advisor_office.png"):
		printerr("CITY PROBE: city artwork did not return to day after restoring the clock")
		get_tree().quit(1)
		return
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
	var previous_arrow: Button = _navigation_button(instance, "PrevRoomArrow")
	var outside_arrow: Button = _navigation_button(instance, "OutsideArrow")
	var down_arrow: Button = _navigation_button(instance, "DownRoomArrow")
	var next_arrow: Button = _navigation_button(instance, "NextRoomArrow")
	var directional_navigation: Node = instance.get_node_or_null("%DirectionalNavigation")
	var local_map_button: Button = instance.get_node_or_null("Interface/Footer/Margin/Layout/Buttons/MapButton")
	if previous_arrow == null or outside_arrow == null or down_arrow == null or next_arrow == null or not _arrow_leads_to(previous_arrow, "Reception") or not _arrow_leads_to(next_arrow, "Financial Aid") or outside_arrow.visible or down_arrow.visible:
		printerr("CITY PROBE: data-driven directional area arrows were not initialized")
		get_tree().quit(1)
		return
	if not _navigation_layout_is_uniform(instance):
		printerr("CITY PROBE: city directional controls were not aligned to the shared screen-edge compass")
		get_tree().quit(1)
		return
	if directional_navigation == null or local_map_button == null or "Local Map" not in local_map_button.text:
		printerr("CITY PROBE: the contextual mini-map was not available from the city footer")
		get_tree().quit(1)
		return
	local_map_button.pressed.emit()
	await get_tree().process_frame
	var building_map_overlay: Control = directional_navigation.get_node("ContextMiniMap/MiniMapOverlay")
	var building_map_scope: Label = directional_navigation.get_node("ContextMiniMap/MiniMapOverlay/MapPanel/Margin/Layout/Header/Titles/MiniMapScope")
	var building_map_current: Label = directional_navigation.get_node("ContextMiniMap/MiniMapOverlay/MapPanel/Margin/Layout/MiniMapCurrent")
	var building_map_nodes: PackedStringArray = directional_navigation.call("minimap_node_ids")
	if not building_map_overlay.visible or building_map_scope.text != "BUILDING MAP" or "Advisor Office" not in building_map_current.text or "advisor_office" not in building_map_nodes or "financial_aid" not in building_map_nodes or "westshore_campus.courtyard" not in building_map_nodes or "library" in building_map_nodes:
		printerr("CITY PROBE: the Administration mini-map did not stay scoped to the building and its outside exit")
		get_tree().quit(1)
		return
	directional_navigation.call("close_minimap")
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
	if str(GameState.current_state["world_state"]["current_location"]) != "westshore_administration_office.reception" or outside_arrow.visible or not down_arrow.visible or not _arrow_leads_to(down_arrow, "Campus Courtyard"):
		printerr("CITY PROBE: player could not walk back through the advisor office to reception")
		get_tree().quit(1)
		return
	phone.open_phone("city_map")
	await get_tree().process_frame
	phone.call("_open_route_planner", "hale_home")
	await get_tree().process_frame
	if not phone.get_node("RoutePanel").visible or phone.get_node("RoutePanel/Margin/Layout/RouteOption").item_count != 4:
		printerr("CITY PROBE: reverse route planner did not populate")
		get_tree().quit(1)
		return
	phone.close_phone()
	for hidden_district_id: String in ["mariner_row_shopping_street", "greyport_street", "cedar_vale_street", "crown_point_boulevard"]:
		if hidden_district_id in GameState.current_state["world_state"]["unlocked_locations"]:
			printerr("CITY PROBE: an optional district was exposed before the player found a lead: %s" % hidden_district_id)
			get_tree().quit(1)
			return
	phone.open_phone("jobs")
	await get_tree().process_frame
	phone.call("_open_job_detail", "warehouse_associate")
	await get_tree().process_frame
	if "greyport_street" not in GameState.current_state["world_state"]["discovered_locations"] or "greyport_distribution" in GameState.current_state["world_state"]["unlocked_locations"] or "New district discovered: Greyport Main Street" not in str(phone_status_label.text):
		printerr("CITY PROBE: the Greyport job lead did not reveal only the neighborhood hub")
		get_tree().quit(1)
		return
	phone.close_phone()
	phone.open_phone("housing")
	await get_tree().process_frame
	phone.call("_open_housing_detail", "crown_point_one_bedroom_condo")
	await get_tree().process_frame
	if "crown_point_boulevard" not in GameState.current_state["world_state"]["discovered_locations"] or "crown_point_condos" in GameState.current_state["world_state"]["unlocked_locations"] or "New district discovered: Crown Point Boulevard" not in str(phone_status_label.text):
		printerr("CITY PROBE: the Crown Point housing lead bypassed neighborhood exploration")
		get_tree().quit(1)
		return
	phone.close_phone()
	GameState.current_state["player"]["phone"]["unlocked_apps"].append("shopping")
	phone.open_phone("shopping")
	await get_tree().process_frame
	phone.call("_open_store", "mariner_market")
	await get_tree().process_frame
	if "mariner_row_shopping_street" not in GameState.current_state["world_state"]["discovered_locations"] or "mariner_market" in GameState.current_state["world_state"]["unlocked_locations"] or "New district discovered: Mariner Row Shopping Street" not in str(phone_status_label.text):
		printerr("CITY PROBE: the Mariner Market listing did not reveal only Mariner Row")
		get_tree().quit(1)
		return
	phone.close_phone()
	phone.open_phone("city_map")
	await get_tree().process_frame
	var map_text: String = str(phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/AppContent").text)
	if "Undiscovered districts: 1" not in map_text or "Cedar Vale" in map_text:
		printerr("CITY PROBE: the City Map did not count the remaining hidden district without spoiling its name")
		get_tree().quit(1)
		return
	phone.close_phone()
	instance.queue_free()
	await get_tree().process_frame
	var bus_state: Dictionary = factory.create_new_game({}, {"random_seed": 996})
	bus_state["world_state"]["current_location"] = "alder_heights_bus_stop.shelter"
	bus_state["world_state"]["discovered_locations"].append("alder_heights_bus_stop")
	GameState.replace_state(bus_state)
	var bus_instance: Node = scene.instantiate()
	get_tree().root.add_child(bus_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var bus_up: Button = _navigation_button(bus_instance, "OutsideArrow")
	var bus_down: Button = _navigation_button(bus_instance, "DownRoomArrow")
	if bus_up == null or bus_down == null or not bus_up.visible or not _arrow_leads_to(bus_up, "Choose Bus Destination") or not bus_down.visible or not _arrow_leads_to(bus_down, "Neighborhood Corner"):
		printerr("CITY PROBE: the bus stop did not separate destination selection from its physical street exit")
		get_tree().quit(1)
		return
	bus_up.pressed.emit()
	await get_tree().process_frame
	var bus_phone: Node = bus_instance.get_node("Interface/Smartphone")
	if not bus_phone.visible or str(bus_phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/AppTitle").text) != "CITY MAP":
		printerr("CITY PROBE: the bus-stop destination arrow did not open the city map")
		get_tree().quit(1)
		return
	bus_phone.close_phone()
	bus_instance.queue_free()
	await get_tree().process_frame
	var maple_state: Dictionary = factory.create_new_game({}, {"random_seed": 998})
	maple_state["clock"]["block"] = "late_evening"
	maple_state["world_state"]["current_location"] = "maple_hall_dorm.lobby"
	maple_state["world_state"]["discovered_locations"].append("maple_hall_dorm")
	GameState.replace_state(maple_state)
	var maple_instance: Node = scene.instantiate()
	get_tree().root.add_child(maple_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var maple_exit_arrow: Button = _navigation_button(maple_instance, "OutsideArrow")
	var maple_exit_result: Dictionary = TravelService.travel("westshore_campus.transit_loop", "walking", "probe.maple_after_hours_exit")
	if maple_exit_arrow == null or not maple_exit_arrow.visible or not _arrow_leads_to(maple_exit_arrow, "College Campus") or not maple_exit_result.get("ok", false) or str(GameState.current_state["world_state"]["current_location"]) != "westshore_campus.transit_loop":
		printerr("CITY PROBE: Maple Hall could not exit to the outdoor campus transit loop after hours: arrow=%s visible=%s destination=%s errors=%s location=%s" % [
			maple_exit_arrow != null,
			maple_exit_arrow.visible if maple_exit_arrow != null else false,
			str(maple_exit_arrow.get_meta("destination_label", "")) if maple_exit_arrow != null else "",
			maple_exit_result.get("errors", []),
			GameState.current_state["world_state"]["current_location"],
		])
		get_tree().quit(1)
		return
	maple_instance.queue_free()
	await get_tree().process_frame
	var employment_state: Dictionary = factory.create_new_game({}, {"random_seed": 993})
	employment_state["world_state"]["current_location"] = "harbor_employment_centre.job_floor"
	GameState.replace_state(employment_state)
	var employment_instance: Node = scene.instantiate()
	get_tree().root.add_child(employment_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var downtown_arrow: Button = _navigation_button(employment_instance, "DownRoomArrow")
	if not downtown_arrow.visible or not _arrow_leads_to(downtown_arrow, "Employment Block"):
		printerr("CITY PROBE: an adjacent public Harbor Centre block was not offered for organic walking discovery")
		get_tree().quit(1)
		return
	employment_instance.queue_free()
	await get_tree().process_frame
	var mall_state: Dictionary = factory.create_new_game({}, {"random_seed": 994})
	for public_location_id: String in ["harbor_centre_downtown", "port_alder_galleria"]:
		mall_state["world_state"]["unlocked_locations"].append(public_location_id)
		mall_state["world_state"]["discovered_locations"].append(public_location_id)
	mall_state["world_state"]["current_location"] = "port_alder_galleria.main_atrium"
	GameState.replace_state(mall_state)
	var mall_instance: Node = scene.instantiate()
	get_tree().root.add_child(mall_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var mall_left: Button = _navigation_button(mall_instance, "PrevRoomArrow")
	var mall_up: Button = _navigation_button(mall_instance, "OutsideArrow")
	var mall_down: Button = _navigation_button(mall_instance, "DownRoomArrow")
	var mall_right: Button = _navigation_button(mall_instance, "NextRoomArrow")
	if not mall_left.visible or not _arrow_leads_to(mall_left, "Street Entrance") or not mall_up.visible or not _arrow_leads_to(mall_up, "Upper Atrium") or not mall_down.visible or not _arrow_leads_to(mall_down, "Lower Court") or not mall_right.visible or not _arrow_leads_to(mall_right, "Fashion Wing"):
		printerr("CITY PROBE: the Galleria atrium did not render its four authored navigation directions")
		get_tree().quit(1)
		return
	var mall_action_buttons: VBoxContainer = mall_instance.get_node("Interface/MainMargin/MainLayout/ActionPanel/Margin/Layout/Scroll/ActionButtons")
	if mall_action_buttons.get_child_count() != 1 or mall_action_buttons.get_child(0).disabled:
		printerr("CITY PROBE: the Galleria directory interaction was unavailable in the main atrium")
		get_tree().quit(1)
		return
	mall_action_buttons.get_child(0).pressed.emit()
	await get_tree().process_frame
	if mall_action_buttons.get_child_count() != 16 or str(mall_instance.get_node("%ActionTitle").text) != "PORT ALDER GALLERIA DIRECTORY":
		printerr("CITY PROBE: the Galleria directory did not list all sixteen storefront slots")
		get_tree().quit(1)
		return
	mall_instance.call("_set_current_room", "fashion_wing")
	await get_tree().process_frame
	if mall_action_buttons.get_child_count() != 1 or "Coastline Casuals" not in str(mall_action_buttons.get_child(0).text) or mall_action_buttons.get_child(0).disabled:
		printerr("CITY PROBE: the fashion wing did not expose its physical storefront interaction")
		get_tree().quit(1)
		return
	mall_action_buttons.get_child(0).pressed.emit()
	await get_tree().process_frame
	var mall_phone: Node = mall_instance.get_node("Interface/Smartphone")
	if not mall_phone.visible or str(mall_phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/AppTitle").text) != "COASTLINE CASUALS":
		printerr("CITY PROBE: the physical Galleria storefront did not open its in-person catalog")
		get_tree().quit(1)
		return
	mall_phone.close_phone()
	mall_instance.queue_free()
	await get_tree().process_frame
	var lantern_state: Dictionary = factory.create_new_game({}, {"random_seed": 997})
	lantern_state["clock"]["weekday"] = "thursday"
	lantern_state["clock"]["block"] = "evening"
	for lantern_location_id: String in ["lantern_district_street", "harborlight_cinema", "la_brisa_kitchen", "lantern_gallery", "tideglass_club", "harbor_companion_cooperative"]:
		if lantern_location_id not in lantern_state["world_state"]["unlocked_locations"]:
			lantern_state["world_state"]["unlocked_locations"].append(lantern_location_id)
		if lantern_location_id not in lantern_state["world_state"]["discovered_locations"]:
			lantern_state["world_state"]["discovered_locations"].append(lantern_location_id)
	lantern_state["world_state"]["current_location"] = "lantern_district_street.restaurant_lane"
	GameState.replace_state(lantern_state)
	var lantern_instance: Node = scene.instantiate()
	get_tree().root.add_child(lantern_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var lantern_left: Button = _navigation_button(lantern_instance, "PrevRoomArrow")
	var lantern_up: Button = _navigation_button(lantern_instance, "OutsideArrow")
	var lantern_down: Button = _navigation_button(lantern_instance, "DownRoomArrow")
	var lantern_right: Button = _navigation_button(lantern_instance, "NextRoomArrow")
	if not _arrow_leads_to(lantern_left, "Cinema Block") or not _arrow_leads_to(lantern_up, "La Brisa Kitchen") or not _arrow_leads_to(lantern_down, "Tideglass Club") or not _arrow_leads_to(lantern_right, "Gallery Walk"):
		printerr("CITY PROBE: Restaurant Lane did not expose its four authored Lantern District paths")
		get_tree().quit(1)
		return
	lantern_instance.call("_set_current_room", "gallery_walk")
	await get_tree().process_frame
	if not _arrow_leads_to(lantern_left, "Restaurant Lane") or not _arrow_leads_to(lantern_up, "Lantern Gallery") or lantern_down.visible or not _arrow_leads_to(lantern_right, "Harbor Companion Cooperative"):
		printerr("CITY PROBE: Gallery Walk did not connect only its real neighboring destinations")
		get_tree().quit(1)
		return
	lantern_instance.queue_free()
	await get_tree().process_frame
	lantern_state["world_state"]["current_location"] = "harborlight_cinema.concessions"
	GameState.replace_state(lantern_state)
	var cinema_instance: Node = scene.instantiate()
	get_tree().root.add_child(cinema_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var cinema_left: Button = _navigation_button(cinema_instance, "PrevRoomArrow")
	var cinema_up: Button = _navigation_button(cinema_instance, "OutsideArrow")
	var cinema_right: Button = _navigation_button(cinema_instance, "NextRoomArrow")
	if not _arrow_leads_to(cinema_left, "Cinema Lobby") or not _arrow_leads_to(cinema_up, "Side Auditorium") or cinema_right.visible:
		printerr("CITY PROBE: Cinema concessions exposed the staff room without employment access")
		get_tree().quit(1)
		return
	cinema_instance.queue_free()
	await get_tree().process_frame
	var bay_state: Dictionary = factory.create_new_game({}, {"random_seed": 999})
	bay_state["clock"]["block"] = "afternoon"
	for bay_location_id: String in ["alder_heights_residential_street", "alder_bay_park", "alder_bay_beach", "port_alder_marina", "bayview_cafe"]:
		if bay_location_id not in bay_state["world_state"]["unlocked_locations"]:
			bay_state["world_state"]["unlocked_locations"].append(bay_location_id)
		if bay_location_id not in bay_state["world_state"]["discovered_locations"]:
			bay_state["world_state"]["discovered_locations"].append(bay_location_id)
	bay_state["world_state"]["current_location"] = "alder_bay_park.waterfront_path"
	GameState.replace_state(bay_state)
	var park_instance: Node = scene.instantiate()
	get_tree().root.add_child(park_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var park_left: Button = _navigation_button(park_instance, "PrevRoomArrow")
	var park_up: Button = _navigation_button(park_instance, "OutsideArrow")
	var park_down: Button = _navigation_button(park_instance, "DownRoomArrow")
	var park_right: Button = _navigation_button(park_instance, "NextRoomArrow")
	if not _arrow_leads_to(park_left, "Neighborhood Corner") or not _arrow_leads_to(park_up, "Picnic Lawn") or not _arrow_leads_to(park_down, "Public Restrooms") or not _arrow_leads_to(park_right, "Alder Bay Beach"):
		printerr("CITY PROBE: Alder Bay waterfront path did not expose its four real directions")
		get_tree().quit(1)
		return
	park_instance.call("_set_current_room", "lookout")
	await get_tree().process_frame
	if park_left.visible or park_up.visible or not _arrow_leads_to(park_down, "Picnic Lawn") or not _arrow_leads_to(park_right, "Bayview Café"):
		printerr("CITY PROBE: Bay Lookout exposed a shortcut instead of its café and picnic paths")
		get_tree().quit(1)
		return
	park_instance.queue_free()
	await get_tree().process_frame
	bay_state["world_state"]["current_location"] = "alder_bay_beach.boardwalk"
	GameState.replace_state(bay_state)
	var beach_instance: Node = scene.instantiate()
	get_tree().root.add_child(beach_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var beach_left: Button = _navigation_button(beach_instance, "PrevRoomArrow")
	var beach_up: Button = _navigation_button(beach_instance, "OutsideArrow")
	var beach_down: Button = _navigation_button(beach_instance, "DownRoomArrow")
	var beach_right: Button = _navigation_button(beach_instance, "NextRoomArrow")
	if not _arrow_leads_to(beach_left, "Alder Bay Park") or not _arrow_leads_to(beach_up, "Changing Room") or not _arrow_leads_to(beach_down, "Shoreline") or not _arrow_leads_to(beach_right, "Port Alder Marina"):
		printerr("CITY PROBE: Alder Bay boardwalk did not connect the park, beach rooms, and marina")
		get_tree().quit(1)
		return
	beach_instance.queue_free()
	await get_tree().process_frame
	var mariner_state: Dictionary = factory.create_new_game({}, {"random_seed": 1001})
	mariner_state["clock"]["block"] = "morning"
	for mariner_location_id: String in ["mariner_row_shopping_street", "mariner_market", "northline_outfitters", "harbor_formalwear", "mariner_home_goods", "port_alder_auto"]:
		if mariner_location_id not in mariner_state["world_state"]["unlocked_locations"]:
			mariner_state["world_state"]["unlocked_locations"].append(mariner_location_id)
		if mariner_location_id not in mariner_state["world_state"]["discovered_locations"]:
			mariner_state["world_state"]["discovered_locations"].append(mariner_location_id)
	mariner_state["world_state"]["current_location"] = "mariner_row_shopping_street.transit_stop"
	GameState.replace_state(mariner_state)
	var mariner_instance: Node = scene.instantiate()
	get_tree().root.add_child(mariner_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var mariner_left: Button = _navigation_button(mariner_instance, "PrevRoomArrow")
	var mariner_up: Button = _navigation_button(mariner_instance, "OutsideArrow")
	var mariner_down: Button = _navigation_button(mariner_instance, "DownRoomArrow")
	var mariner_right: Button = _navigation_button(mariner_instance, "NextRoomArrow")
	if mariner_left.visible or not _arrow_leads_to(mariner_up, "Choose Bus Destination") or mariner_down.visible or not _arrow_leads_to(mariner_right, "Market Block"):
		printerr("CITY PROBE: Mariner Row transit stop did not separate bus selection from physical street movement")
		get_tree().quit(1)
		return
	mariner_up.pressed.emit()
	await get_tree().process_frame
	var mariner_phone: Node = mariner_instance.get_node("Interface/Smartphone")
	if not mariner_phone.visible or str(mariner_phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/AppTitle").text) != "CITY MAP":
		printerr("CITY PROBE: Mariner Row's transit arrow did not open destination selection")
		get_tree().quit(1)
		return
	mariner_phone.close_phone()
	mariner_instance.call("_set_current_room", "fashion_block")
	await get_tree().process_frame
	if not _arrow_leads_to(mariner_left, "Market Block") or not _arrow_leads_to(mariner_up, "Northline Outfitters") or not _arrow_leads_to(mariner_down, "Harbor Formalwear") or not _arrow_leads_to(mariner_right, "Home and Auto Block"):
		printerr("CITY PROBE: Mariner Row Fashion Block did not expose its four real shopping paths")
		get_tree().quit(1)
		return
	mariner_instance.queue_free()
	await get_tree().process_frame
	mariner_state["world_state"]["current_location"] = "mariner_market.grocery_floor"
	GameState.replace_state(mariner_state)
	var market_instance: Node = scene.instantiate()
	get_tree().root.add_child(market_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var market_actions: VBoxContainer = market_instance.get_node("Interface/MainMargin/MainLayout/ActionPanel/Margin/Layout/Scroll/ActionButtons")
	if market_actions.get_child_count() != 1 or "Shop at Mariner Market" not in str(market_actions.get_child(0).text) or market_actions.get_child(0).disabled:
		printerr("CITY PROBE: Mariner Market floor did not expose its physical storefront")
		get_tree().quit(1)
		return
	market_actions.get_child(0).pressed.emit()
	await get_tree().process_frame
	var market_phone: Node = market_instance.get_node("Interface/Smartphone")
	if not market_phone.visible or str(market_phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/AppTitle").text) != "MARINER MARKET":
		printerr("CITY PROBE: Mariner Market's physical storefront did not open its live catalog")
		get_tree().quit(1)
		return
	market_phone.close_phone()
	market_instance.call("_set_current_room", "checkout")
	await get_tree().process_frame
	var market_stockroom_arrow: Button = _navigation_button(market_instance, "OutsideArrow")
	var market_floor_arrow: Button = _navigation_button(market_instance, "NextRoomArrow")
	if market_stockroom_arrow.visible or not _arrow_leads_to(market_floor_arrow, "Grocery Floor"):
		printerr("CITY PROBE: Mariner Market checkout exposed its employee-only stockroom to a shopper")
		get_tree().quit(1)
		return
	market_instance.queue_free()
	await get_tree().process_frame
	var medical_state: Dictionary = factory.create_new_game({}, {"random_seed": 1002})
	medical_state["clock"]["block"] = "morning"
	for medical_location_id: String in ["st_maren_medical_center", "st_maren_community_clinic", "st_maren_doctors_office", "harbor_wellness_therapy", "st_maren_sexual_health", "bay_pharmacy"]:
		if medical_location_id not in medical_state["world_state"]["unlocked_locations"]:
			medical_state["world_state"]["unlocked_locations"].append(medical_location_id)
		if medical_location_id not in medical_state["world_state"]["discovered_locations"]:
			medical_state["world_state"]["discovered_locations"].append(medical_location_id)
	medical_state["world_state"]["current_location"] = "st_maren_medical_center.campus_transit_stop"
	GameState.replace_state(medical_state)
	var medical_instance: Node = scene.instantiate()
	get_tree().root.add_child(medical_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var medical_left: Button = _navigation_button(medical_instance, "PrevRoomArrow")
	var medical_up: Button = _navigation_button(medical_instance, "OutsideArrow")
	var medical_down: Button = _navigation_button(medical_instance, "DownRoomArrow")
	var medical_right: Button = _navigation_button(medical_instance, "NextRoomArrow")
	if medical_left.visible or not _arrow_leads_to(medical_up, "Choose Bus Destination") or medical_down.visible or not _arrow_leads_to(medical_right, "Medical Campus Plaza"):
		printerr("CITY PROBE: St. Maren transit stop did not separate destination selection from campus walking")
		get_tree().quit(1)
		return
	medical_up.pressed.emit()
	await get_tree().process_frame
	var medical_phone: Node = medical_instance.get_node("Interface/Smartphone")
	if not medical_phone.visible or str(medical_phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/AppTitle").text) != "CITY MAP":
		printerr("CITY PROBE: St. Maren's transit arrow did not open destination selection")
		get_tree().quit(1)
		return
	medical_phone.close_phone()
	medical_instance.call("_set_current_room", "campus_plaza")
	await get_tree().process_frame
	if not _arrow_leads_to(medical_left, "St. Maren Transit Stop") or not _arrow_leads_to(medical_up, "Main Reception") or not _arrow_leads_to(medical_down, "Emergency Department") or not _arrow_leads_to(medical_right, "Clinic Walk"):
		printerr("CITY PROBE: St. Maren plaza did not expose its four physical campus paths")
		get_tree().quit(1)
		return
	medical_instance.call("_set_current_room", "clinic_walk")
	await get_tree().process_frame
	if not _arrow_leads_to(medical_left, "Medical Campus Plaza") or not _arrow_leads_to(medical_up, "St. Maren Community Clinic") or not _arrow_leads_to(medical_down, "St. Maren Family Doctors") or not _arrow_leads_to(medical_right, "Wellness Walk"):
		printerr("CITY PROBE: Clinic Walk did not connect the clinic, family doctors, plaza, and Wellness Walk")
		get_tree().quit(1)
		return
	medical_instance.call("_set_current_room", "wellness_walk")
	await get_tree().process_frame
	if not _arrow_leads_to(medical_left, "Clinic Walk") or not _arrow_leads_to(medical_up, "Harbor Wellness Therapy") or not _arrow_leads_to(medical_down, "St. Maren Sexual Health Centre") or not _arrow_leads_to(medical_right, "Bay Pharmacy"):
		printerr("CITY PROBE: Wellness Walk did not connect therapy, sexual health, and the pharmacy")
		get_tree().quit(1)
		return
	medical_instance.queue_free()
	await get_tree().process_frame
	medical_state["world_state"]["current_location"] = "st_maren_community_clinic.waiting_room"
	GameState.replace_state(medical_state)
	var clinic_instance: Node = scene.instantiate()
	get_tree().root.add_child(clinic_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var clinic_left: Button = _navigation_button(clinic_instance, "PrevRoomArrow")
	var clinic_up: Button = _navigation_button(clinic_instance, "OutsideArrow")
	var clinic_down: Button = _navigation_button(clinic_instance, "DownRoomArrow")
	var clinic_right: Button = _navigation_button(clinic_instance, "NextRoomArrow")
	if not _arrow_leads_to(clinic_left, "Reception") or clinic_up.visible or clinic_down.visible or clinic_right.visible:
		printerr("CITY PROBE: clinic waiting room exposed private examination, records, or administration rooms without access")
		get_tree().quit(1)
		return
	clinic_instance.queue_free()
	await get_tree().process_frame
	medical_state["world_state"]["current_location"] = "bay_pharmacy.sales_floor"
	GameState.replace_state(medical_state)
	var pharmacy_instance: Node = scene.instantiate()
	get_tree().root.add_child(pharmacy_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var pharmacy_actions: VBoxContainer = pharmacy_instance.get_node("Interface/MainMargin/MainLayout/ActionPanel/Margin/Layout/Scroll/ActionButtons")
	if pharmacy_actions.get_child_count() != 1 or "Shop at Bay Pharmacy" not in str(pharmacy_actions.get_child(0).text) or pharmacy_actions.get_child(0).disabled:
		printerr("CITY PROBE: Bay Pharmacy sales floor did not expose its physical storefront")
		get_tree().quit(1)
		return
	pharmacy_actions.get_child(0).pressed.emit()
	await get_tree().process_frame
	var pharmacy_phone: Node = pharmacy_instance.get_node("Interface/Smartphone")
	if not pharmacy_phone.visible or str(pharmacy_phone.get_node("OuterMargin/PhoneFrame/FrameMargin/Layout/Body/ContentPanel/ContentMargin/ContentLayout/AppTitle").text) != "BAY PHARMACY":
		printerr("CITY PROBE: Bay Pharmacy's physical storefront did not open its live catalog")
		get_tree().quit(1)
		return
	pharmacy_phone.close_phone()
	pharmacy_instance.call("_set_current_room", "pharmacy_counter")
	await get_tree().process_frame
	var pharmacy_private_arrow: Button = _navigation_button(pharmacy_instance, "OutsideArrow")
	if pharmacy_private_arrow.visible:
		printerr("CITY PROBE: pharmacy counter exposed the private consultation room without permission")
		get_tree().quit(1)
		return
	pharmacy_instance.queue_free()
	await get_tree().process_frame
	var greyport_state: Dictionary = factory.create_new_game({}, {"random_seed": 1003})
	greyport_state["clock"]["weekday"] = "friday"
	greyport_state["clock"]["block"] = "evening"
	for greyport_location_id: String in ["greyport_street", "greyport_studios", "greyport_distribution", "port_alder_transit_depot", "undertow_nightclub"]:
		if greyport_location_id not in greyport_state["world_state"]["unlocked_locations"]:
			greyport_state["world_state"]["unlocked_locations"].append(greyport_location_id)
		if greyport_location_id not in greyport_state["world_state"]["discovered_locations"]:
			greyport_state["world_state"]["discovered_locations"].append(greyport_location_id)
	greyport_state["world_state"]["current_location"] = "greyport_street.bus_exchange"
	GameState.replace_state(greyport_state)
	var greyport_instance: Node = scene.instantiate()
	get_tree().root.add_child(greyport_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var greyport_left: Button = _navigation_button(greyport_instance, "PrevRoomArrow")
	var greyport_up: Button = _navigation_button(greyport_instance, "OutsideArrow")
	var greyport_down: Button = _navigation_button(greyport_instance, "DownRoomArrow")
	var greyport_right: Button = _navigation_button(greyport_instance, "NextRoomArrow")
	if greyport_left.visible or not _arrow_leads_to(greyport_up, "Choose Bus Destination") or greyport_down.visible or not _arrow_leads_to(greyport_right, "Apartment Block"):
		printerr("CITY PROBE: Greyport bus exchange did not separate destination selection from physical street movement")
		get_tree().quit(1)
		return
	greyport_instance.call("_set_current_room", "apartment_block")
	await get_tree().process_frame
	if not _arrow_leads_to(greyport_left, "Greyport Bus Exchange") or not _arrow_leads_to(greyport_up, "North Residential Lane") or not _arrow_leads_to(greyport_down, "South Residential Lane") or not _arrow_leads_to(greyport_right, "Industrial Corner"):
		printerr("CITY PROBE: Greyport Apartment Block did not expose its four physical street paths")
		get_tree().quit(1)
		return
	greyport_instance.call("_set_current_room", "north_residences")
	await get_tree().process_frame
	if greyport_left.visible or greyport_up.visible or not _arrow_leads_to(greyport_down, "Apartment Block") or greyport_right.visible:
		printerr("CITY PROBE: undiscovered Greyport homes appeared on North Residential Lane")
		get_tree().quit(1)
		return
	var greyport_home_discovery: Dictionary = SimulationService.apply_operation("world.discover_location", {
		"location_id": "lee_family_apartment",
		"discovery_source": "invitation",
		"character_id": "marcus_lee",
	}, "probe.greyport_home_invitation")
	greyport_instance.call("_render_location")
	await get_tree().process_frame
	if not greyport_home_discovery.get("ok", false) or not _arrow_leads_to(greyport_up, "Lee Family Apartment") or greyport_right.visible:
		printerr("CITY PROBE: a Greyport invitation did not reveal only the invited home")
		get_tree().quit(1)
		return
	greyport_instance.call("_set_current_room", "industrial_corner")
	await get_tree().process_frame
	if not _arrow_leads_to(greyport_left, "Apartment Block") or not _arrow_leads_to(greyport_up, "Greyport Distribution Warehouse") or not _arrow_leads_to(greyport_down, "Nightlife Alley") or not _arrow_leads_to(greyport_right, "Port Alder Transit Depot"):
		printerr("CITY PROBE: Greyport Industrial Corner did not connect its workplaces and nightlife lane")
		get_tree().quit(1)
		return
	greyport_instance.call("_set_current_room", "nightlife_alley")
	await get_tree().process_frame
	if greyport_left.visible or not _arrow_leads_to(greyport_up, "Industrial Corner") or greyport_down.visible or not _arrow_leads_to(greyport_right, "Undertow Nightclub"):
		printerr("CITY PROBE: Greyport Nightlife Alley exposed shortcuts beyond Undertow and Industrial Corner")
		get_tree().quit(1)
		return
	greyport_instance.queue_free()
	await get_tree().process_frame
	greyport_state = GameState.current_state.duplicate(true)
	greyport_state["world_state"]["current_location"] = "undertow_nightclub.dance_floor"
	GameState.replace_state(greyport_state)
	var undertow_instance: Node = scene.instantiate()
	get_tree().root.add_child(undertow_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var undertow_left: Button = _navigation_button(undertow_instance, "PrevRoomArrow")
	var undertow_up: Button = _navigation_button(undertow_instance, "OutsideArrow")
	var undertow_down: Button = _navigation_button(undertow_instance, "DownRoomArrow")
	var undertow_right: Button = _navigation_button(undertow_instance, "NextRoomArrow")
	if not _arrow_leads_to(undertow_left, "Bar") or undertow_up.visible or not _arrow_leads_to(undertow_down, "Club Entrance") or not _arrow_leads_to(undertow_right, "Lounge"):
		printerr("CITY PROBE: Undertow dance floor exposed its staff-only DJ booth or omitted a public room")
		get_tree().quit(1)
		return
	var undertow_actions: VBoxContainer = undertow_instance.get_node("Interface/MainMargin/MainLayout/ActionPanel/Margin/Layout/Scroll/ActionButtons")
	if undertow_actions.get_child_count() != 1 or "Dance at Undertow" not in str(undertow_actions.get_child(0).text) or undertow_actions.get_child(0).disabled:
		printerr("CITY PROBE: Undertow dance floor did not expose its live dancing activity")
		get_tree().quit(1)
		return
	undertow_actions.get_child(0).pressed.emit()
	await get_tree().process_frame
	if float(GameState.current_state["player"]["skill_experience"].get("dancing", 0.0)) <= 0.0:
		printerr("CITY PROBE: Undertow dancing did not advance the player's Dancing skill")
		get_tree().quit(1)
		return
	undertow_instance.call("_set_current_room", "bar")
	await get_tree().process_frame
	if undertow_up.visible or not _arrow_leads_to(undertow_right, "Dance Floor"):
		printerr("CITY PROBE: Undertow bar exposed its staff room to a guest")
		get_tree().quit(1)
		return
	undertow_instance.queue_free()
	await get_tree().process_frame
	greyport_state = GameState.current_state.duplicate(true)
	greyport_state["world_state"]["current_location"] = "greyport_distribution.security"
	GameState.replace_state(greyport_state)
	var warehouse_instance: Node = scene.instantiate()
	get_tree().root.add_child(warehouse_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var warehouse_left: Button = _navigation_button(warehouse_instance, "PrevRoomArrow")
	var warehouse_up: Button = _navigation_button(warehouse_instance, "OutsideArrow")
	var warehouse_down: Button = _navigation_button(warehouse_instance, "DownRoomArrow")
	var warehouse_right: Button = _navigation_button(warehouse_instance, "NextRoomArrow")
	if warehouse_left.visible or warehouse_up.visible or not _arrow_leads_to(warehouse_down, "Industrial Corner") or warehouse_right.visible:
		printerr("CITY PROBE: Greyport Distribution security exposed employee or supervisor rooms to a visitor")
		get_tree().quit(1)
		return
	warehouse_instance.queue_free()
	await get_tree().process_frame
	greyport_state["world_state"]["current_location"] = "greyport_studios.lobby"
	GameState.replace_state(greyport_state)
	var studios_instance: Node = scene.instantiate()
	get_tree().root.add_child(studios_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var studios_left: Button = _navigation_button(studios_instance, "PrevRoomArrow")
	var studios_up: Button = _navigation_button(studios_instance, "OutsideArrow")
	var studios_down: Button = _navigation_button(studios_instance, "DownRoomArrow")
	var studios_right: Button = _navigation_button(studios_instance, "NextRoomArrow")
	if studios_left.visible or studios_up.visible or not _arrow_leads_to(studios_down, "Apartment Block") or studios_right.visible:
		printerr("CITY PROBE: Greyport Studios lobby exposed unrented private rooms")
		get_tree().quit(1)
		return
	studios_instance.queue_free()
	await get_tree().process_frame
	var cedar_state: Dictionary = factory.create_new_game({}, {"random_seed": 1004})
	for cedar_location_id: String in ["cedar_vale_street", "cedar_vale_townhouses", "cedar_vale_detached_homes", "cedar_vale_care_home", "cedar_vale_family_centre"]:
		if cedar_location_id not in cedar_state["world_state"]["unlocked_locations"]:
			cedar_state["world_state"]["unlocked_locations"].append(cedar_location_id)
		if cedar_location_id not in cedar_state["world_state"]["discovered_locations"]:
			cedar_state["world_state"]["discovered_locations"].append(cedar_location_id)
	cedar_state["world_state"]["current_location"] = "cedar_vale_street.bus_stop"
	GameState.replace_state(cedar_state)
	var cedar_instance: Node = scene.instantiate()
	get_tree().root.add_child(cedar_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var cedar_left: Button = _navigation_button(cedar_instance, "PrevRoomArrow")
	var cedar_up: Button = _navigation_button(cedar_instance, "OutsideArrow")
	var cedar_down: Button = _navigation_button(cedar_instance, "DownRoomArrow")
	var cedar_right: Button = _navigation_button(cedar_instance, "NextRoomArrow")
	if cedar_left.visible or not _arrow_leads_to(cedar_up, "Choose Bus Destination") or cedar_down.visible or not _arrow_leads_to(cedar_right, "Townhouse Row"):
		printerr("CITY PROBE: Cedar Vale bus stop did not separate destination selection from physical neighborhood movement")
		get_tree().quit(1)
		return
	cedar_instance.call("_set_current_room", "townhouse_row")
	await get_tree().process_frame
	if not _arrow_leads_to(cedar_left, "Cedar Vale Bus Stop") or cedar_up.visible or not _arrow_leads_to(cedar_down, "Cedar Vale Townhouses") or not _arrow_leads_to(cedar_right, "Family Block"):
		printerr("CITY PROBE: Townhouse Row exposed Rachel's undiscovered home or omitted a public path")
		get_tree().quit(1)
		return
	var cedar_home_discovery: Dictionary = SimulationService.apply_operation("world.discover_location", {
		"location_id": "rachel_cedar_vale_townhouse",
		"discovery_source": "invitation",
		"character_id": "rachel_morgan",
	}, "probe.cedar_home_invitation")
	cedar_instance.call("_render_location")
	await get_tree().process_frame
	if not cedar_home_discovery.get("ok", false) or not _arrow_leads_to(cedar_up, "Rachel's Townhouse"):
		printerr("CITY PROBE: Rachel's invitation did not reveal her Cedar Vale home")
		get_tree().quit(1)
		return
	cedar_instance.call("_set_current_room", "family_block")
	await get_tree().process_frame
	if not _arrow_leads_to(cedar_left, "Townhouse Row") or not _arrow_leads_to(cedar_up, "Cedar Vale Care Home") or not _arrow_leads_to(cedar_down, "Cedar Vale Family Centre") or not _arrow_leads_to(cedar_right, "Detached Home Lane"):
		printerr("CITY PROBE: Cedar Vale Family Block did not connect its four physical neighborhood paths")
		get_tree().quit(1)
		return
	cedar_instance.queue_free()
	await get_tree().process_frame
	cedar_state = GameState.current_state.duplicate(true)
	cedar_state["world_state"]["current_location"] = "cedar_vale_townhouses.entry"
	GameState.replace_state(cedar_state)
	var townhouse_instance: Node = scene.instantiate()
	get_tree().root.add_child(townhouse_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var townhouse_left: Button = _navigation_button(townhouse_instance, "PrevRoomArrow")
	var townhouse_up: Button = _navigation_button(townhouse_instance, "OutsideArrow")
	var townhouse_down: Button = _navigation_button(townhouse_instance, "DownRoomArrow")
	var townhouse_right: Button = _navigation_button(townhouse_instance, "NextRoomArrow")
	if townhouse_left.visible or townhouse_up.visible or not _arrow_leads_to(townhouse_down, "Townhouse Row") or townhouse_right.visible:
		printerr("CITY PROBE: Cedar Vale townhouse entry exposed unrented private rooms")
		get_tree().quit(1)
		return
	townhouse_instance.queue_free()
	await get_tree().process_frame
	cedar_state["world_state"]["current_location"] = "cedar_vale_care_home.reception"
	GameState.replace_state(cedar_state)
	var care_instance: Node = scene.instantiate()
	get_tree().root.add_child(care_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var care_left: Button = _navigation_button(care_instance, "PrevRoomArrow")
	var care_up: Button = _navigation_button(care_instance, "OutsideArrow")
	var care_down: Button = _navigation_button(care_instance, "DownRoomArrow")
	var care_right: Button = _navigation_button(care_instance, "NextRoomArrow")
	if care_left.visible or care_up.visible or not _arrow_leads_to(care_down, "Family Block") or not _arrow_leads_to(care_right, "Resident Lounge"):
		printerr("CITY PROBE: Cedar Vale Care Home reception exposed its employee station or omitted a public path")
		get_tree().quit(1)
		return
	care_instance.queue_free()
	await get_tree().process_frame
	cedar_state["world_state"]["current_location"] = "cedar_vale_family_centre.parent_group_room"
	GameState.replace_state(cedar_state)
	var family_instance: Node = scene.instantiate()
	get_tree().root.add_child(family_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var family_left: Button = _navigation_button(family_instance, "PrevRoomArrow")
	var family_up: Button = _navigation_button(family_instance, "OutsideArrow")
	var family_down: Button = _navigation_button(family_instance, "DownRoomArrow")
	var family_right: Button = _navigation_button(family_instance, "NextRoomArrow")
	if not _arrow_leads_to(family_left, "Reception") or family_up.visible or family_down.visible or not _arrow_leads_to(family_right, "Family Centre Playground"):
		printerr("CITY PROBE: Cedar Vale Family Centre group room exposed private counseling or omitted a public path")
		get_tree().quit(1)
		return
	var family_actions: VBoxContainer = family_instance.get_node("Interface/MainMargin/MainLayout/ActionPanel/Margin/Layout/Scroll/ActionButtons")
	if family_actions.get_child_count() != 1 or "Family Skills Workshop" not in str(family_actions.get_child(0).text) or family_actions.get_child(0).disabled:
		printerr("CITY PROBE: Cedar Vale Family Centre did not expose its live workshop activity")
		get_tree().quit(1)
		return
	family_actions.get_child(0).pressed.emit()
	await get_tree().process_frame
	if float(GameState.current_state["player"]["skill_experience"].get("caregiving", 0.0)) <= 0.0:
		printerr("CITY PROBE: the family-skills workshop did not advance Caregiving skill")
		get_tree().quit(1)
		return
	family_instance.queue_free()
	await get_tree().process_frame
	var crown_state: Dictionary = factory.create_new_game({}, {"random_seed": 1005})
	for crown_location_id: String in ["crown_point_boulevard", "price_caldwell_law", "crown_point_condos", "crown_point_penthouses", "crown_point_hotel_spa"]:
		if crown_location_id not in crown_state["world_state"]["unlocked_locations"]:
			crown_state["world_state"]["unlocked_locations"].append(crown_location_id)
		if crown_location_id not in crown_state["world_state"]["discovered_locations"]:
			crown_state["world_state"]["discovered_locations"].append(crown_location_id)
	crown_state["world_state"]["current_location"] = "crown_point_boulevard.boulevard_entry"
	GameState.replace_state(crown_state)
	var crown_instance: Node = scene.instantiate()
	get_tree().root.add_child(crown_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var crown_left: Button = _navigation_button(crown_instance, "PrevRoomArrow")
	var crown_up: Button = _navigation_button(crown_instance, "OutsideArrow")
	var crown_down: Button = _navigation_button(crown_instance, "DownRoomArrow")
	var crown_right: Button = _navigation_button(crown_instance, "NextRoomArrow")
	if crown_left.visible or not _arrow_leads_to(crown_up, "Choose Bus Destination") or crown_down.visible or not _arrow_leads_to(crown_right, "Corporate Block"):
		printerr("CITY PROBE: Crown Point transit plaza did not separate destination selection from boulevard movement")
		get_tree().quit(1)
		return
	crown_instance.call("_set_current_room", "corporate_block")
	await get_tree().process_frame
	if not _arrow_leads_to(crown_left, "Crown Point Transit Plaza") or not _arrow_leads_to(crown_up, "Price & Caldwell Law") or crown_down.visible or not _arrow_leads_to(crown_right, "Residential Towers"):
		printerr("CITY PROBE: Crown Point Corporate Block did not connect the law office, transit plaza, and residential towers")
		get_tree().quit(1)
		return
	crown_instance.call("_set_current_room", "residential_towers")
	await get_tree().process_frame
	if not _arrow_leads_to(crown_left, "Corporate Block") or crown_up.visible or not _arrow_leads_to(crown_down, "Crown Point Condominiums") or not _arrow_leads_to(crown_right, "Penthouse Towers"):
		printerr("CITY PROBE: Residential Towers exposed Olivia's undiscovered penthouse or omitted a public property entrance")
		get_tree().quit(1)
		return
	var crown_home_discovery: Dictionary = SimulationService.apply_operation("world.discover_location", {
		"location_id": "olivia_crown_point_penthouse",
		"discovery_source": "invitation",
		"character_id": "olivia_price",
	}, "probe.crown_home_invitation")
	crown_instance.call("_render_location")
	await get_tree().process_frame
	if not crown_home_discovery.get("ok", false) or not _arrow_leads_to(crown_up, "Olivia's Penthouse"):
		printerr("CITY PROBE: Olivia's invitation did not reveal her Crown Point penthouse")
		get_tree().quit(1)
		return
	crown_instance.call("_set_current_room", "hotel_block")
	await get_tree().process_frame
	if not _arrow_leads_to(crown_left, "Penthouse Towers") or not _arrow_leads_to(crown_up, "Crown Point Hotel & Spa") or crown_down.visible or not _arrow_leads_to(crown_right, "Crown Point Harbor Overlook"):
		printerr("CITY PROBE: Crown Point Hotel Block did not connect its tower, hotel, and harbor overlook")
		get_tree().quit(1)
		return
	crown_instance.call("_set_current_room", "harbor_overlook")
	await get_tree().process_frame
	if not _arrow_leads_to(crown_left, "Hotel Block") or crown_up.visible or crown_down.visible or crown_right.visible:
		printerr("CITY PROBE: Crown Point Harbor Overlook exposed a nonexistent shortcut")
		get_tree().quit(1)
		return
	var crown_actions: VBoxContainer = crown_instance.get_node("Interface/MainMargin/MainLayout/ActionPanel/Margin/Layout/Scroll/ActionButtons")
	if crown_actions.get_child_count() != 1 or "Take In the Harbor View" not in str(crown_actions.get_child(0).text) or crown_actions.get_child(0).disabled:
		printerr("CITY PROBE: Crown Point overlook did not expose its live observation activity")
		get_tree().quit(1)
		return
	crown_actions.get_child(0).pressed.emit()
	await get_tree().process_frame
	if float(GameState.current_state["player"]["skill_experience"].get("observation", 0.0)) <= 0.0:
		printerr("CITY PROBE: Crown Point overlook did not advance Observation skill")
		get_tree().quit(1)
		return
	crown_instance.queue_free()
	await get_tree().process_frame
	crown_state = GameState.current_state.duplicate(true)
	crown_state["world_state"]["current_location"] = "price_caldwell_law.reception"
	GameState.replace_state(crown_state)
	var law_instance: Node = scene.instantiate()
	get_tree().root.add_child(law_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var law_left: Button = _navigation_button(law_instance, "PrevRoomArrow")
	var law_up: Button = _navigation_button(law_instance, "OutsideArrow")
	var law_down: Button = _navigation_button(law_instance, "DownRoomArrow")
	var law_right: Button = _navigation_button(law_instance, "NextRoomArrow")
	if law_left.visible or law_up.visible or not _arrow_leads_to(law_down, "Corporate Block") or law_right.visible:
		printerr("CITY PROBE: Price & Caldwell reception exposed professional rooms to a visitor")
		get_tree().quit(1)
		return
	law_instance.queue_free()
	await get_tree().process_frame
	crown_state["world_state"]["current_location"] = "crown_point_condos.lobby"
	GameState.replace_state(crown_state)
	var crown_condo_instance: Node = scene.instantiate()
	get_tree().root.add_child(crown_condo_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var crown_condo_left: Button = _navigation_button(crown_condo_instance, "PrevRoomArrow")
	var crown_condo_up: Button = _navigation_button(crown_condo_instance, "OutsideArrow")
	var crown_condo_down: Button = _navigation_button(crown_condo_instance, "DownRoomArrow")
	var crown_condo_right: Button = _navigation_button(crown_condo_instance, "NextRoomArrow")
	if crown_condo_left.visible or crown_condo_up.visible or not _arrow_leads_to(crown_condo_down, "Residential Towers") or crown_condo_right.visible:
		printerr("CITY PROBE: Crown Point condo lobby exposed unowned residences or amenities")
		get_tree().quit(1)
		return
	crown_condo_instance.queue_free()
	await get_tree().process_frame
	crown_state["world_state"]["current_location"] = "crown_point_hotel_spa.lobby"
	GameState.replace_state(crown_state)
	var crown_hotel_instance: Node = scene.instantiate()
	get_tree().root.add_child(crown_hotel_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var crown_hotel_left: Button = _navigation_button(crown_hotel_instance, "PrevRoomArrow")
	var crown_hotel_up: Button = _navigation_button(crown_hotel_instance, "OutsideArrow")
	var crown_hotel_down: Button = _navigation_button(crown_hotel_instance, "DownRoomArrow")
	var crown_hotel_right: Button = _navigation_button(crown_hotel_instance, "NextRoomArrow")
	if crown_hotel_left.visible or not _arrow_leads_to(crown_hotel_up, "Hotel Restaurant") or not _arrow_leads_to(crown_hotel_down, "Hotel Block") or not _arrow_leads_to(crown_hotel_right, "Hotel Bar"):
		printerr("CITY PROBE: Crown Point Hotel lobby exposed staff areas or omitted its public rooms")
		get_tree().quit(1)
		return
	crown_hotel_instance.call("_set_current_room", "bar")
	await get_tree().process_frame
	if not _arrow_leads_to(crown_hotel_left, "Hotel Lobby") or crown_hotel_up.visible or crown_hotel_down.visible or crown_hotel_right.visible:
		printerr("CITY PROBE: Crown Point Hotel bar exposed booking-only spa or ballroom rooms")
		get_tree().quit(1)
		return
	crown_hotel_instance.queue_free()
	await get_tree().process_frame
	var social_state: Dictionary = factory.create_new_game({}, {"random_seed": 995})
	social_state["clock"]["block"] = "evening"
	social_state["world_state"]["current_location"] = "westshore_campus.art_studios"
	GameState.replace_state(social_state)
	var social_instance: Node = scene.instantiate()
	get_tree().root.add_child(social_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var social_portraits: HBoxContainer = social_instance.get_node("%PortraitStage")
	var social_actions: VBoxContainer = social_instance.get_node("Interface/MainMargin/MainLayout/ActionPanel/Margin/Layout/Scroll/ActionButtons")
	if social_portraits.get_child_count() != 1 or social_actions.get_child_count() != 1 or "Someone New" not in str(social_actions.get_child(0).text) or social_actions.get_child(0).disabled:
		printerr("CITY PROBE: Chloe's scheduled open-studio presence did not render as an available VN encounter")
		get_tree().quit(1)
		return
	social_actions.get_child(0).pressed.emit()
	await get_tree().process_frame
	if social_actions.get_child_count() < 2 or "Introduce Yourself" not in str(social_actions.get_child(0).text):
		printerr("CITY PROBE: an undiscovered scheduled NPC did not offer an organic introduction")
		get_tree().quit(1)
		return
	social_actions.get_child(0).pressed.emit()
	await get_tree().process_frame
	var chloe_discovered: bool = false
	for npc_state_value: Variant in GameState.current_state.get("npc_states", []):
		if npc_state_value is Dictionary and str(npc_state_value.get("character_id", "")) == "chloe_bennett":
			chloe_discovered = bool(npc_state_value.get("discovered", false))
			break
	if not chloe_discovered or "chloe_bennett" in GameState.current_state["player"]["phone"]["known_contacts"]:
		printerr("CITY PROBE: introduction did not create an acquaintance separately from phone contact")
		get_tree().quit(1)
		return
	social_actions.get_child(0).pressed.emit()
	await get_tree().process_frame
	if "Ask to Exchange Numbers" not in str(social_actions.get_child(0).text):
		printerr("CITY PROBE: a discovered acquaintance did not offer contact exchange")
		get_tree().quit(1)
		return
	social_actions.get_child(0).pressed.emit()
	await get_tree().process_frame
	if "chloe_bennett" not in GameState.current_state["player"]["phone"]["known_contacts"] or not GameState.current_state["player"]["phone"]["message_threads"].has("chloe_bennett"):
		printerr("CITY PROBE: contact exchange did not update Contacts and Messages")
		get_tree().quit(1)
		return
	social_instance.queue_free()
	await get_tree().process_frame
	var hidden_state: Dictionary = factory.create_new_game({}, {"random_seed": 992})
	hidden_state["world_state"]["current_location"] = "alder_heights_residential_street.hale_block"
	GameState.replace_state(hidden_state)
	var street_instance: Node = scene.instantiate()
	get_tree().root.add_child(street_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var rowan_arrow: Button = _navigation_button(street_instance, "PrevRoomArrow")
	var street_phone: Node = street_instance.get_node("Interface/Smartphone")
	var street_navigation: Node = street_instance.get_node("%DirectionalNavigation")
	var street_local_map_button: Button = street_instance.get_node("Interface/Footer/Margin/Layout/Buttons/MapButton")
	if rowan_arrow.visible:
		printerr("CITY PROBE: Emma's undiscovered home exposed a street arrow")
		get_tree().quit(1)
		return
	street_local_map_button.pressed.emit()
	await get_tree().process_frame
	var street_map_scope: Label = street_navigation.get_node("ContextMiniMap/MiniMapOverlay/MapPanel/Margin/Layout/Header/Titles/MiniMapScope")
	var street_local_nodes: PackedStringArray = street_navigation.call("minimap_node_ids")
	if not street_navigation.call("is_minimap_open") or street_map_scope.text != "AREA MAP" or "hale_block" not in street_local_nodes or "neighborhood_corner" not in street_local_nodes or "hale_home.front_yard" not in street_local_nodes or "rowan_family_home.porch" in street_local_nodes:
		printerr("CITY PROBE: the Alder Heights local map spoiled an undiscovered private address")
		get_tree().quit(1)
		return
	street_navigation.call("close_minimap")
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
	if not discovery_result.get("ok", false) or not rowan_arrow.visible or not _arrow_leads_to(rowan_arrow, "Rowan Family Home"):
		printerr("CITY PROBE: invitation discovery did not reveal Emma's street arrow")
		get_tree().quit(1)
		return
	street_local_map_button.pressed.emit()
	await get_tree().process_frame
	street_local_nodes = street_navigation.call("minimap_node_ids")
	if "rowan_family_home.porch" not in street_local_nodes:
		printerr("CITY PROBE: the neighborhood mini-map did not add Emma's home after her invitation")
		get_tree().quit(1)
		return
	street_navigation.call("close_minimap")
	var scene_tree: SceneTree = get_tree()
	rowan_arrow.pressed.emit()
	if str(GameState.current_state["world_state"]["current_location"]) != "rowan_family_home.porch":
		printerr("CITY PROBE: revealed residence arrow did not arrive at the authored porch")
		scene_tree.quit(1)
		return
	print("PASS: Every city district rendered immersive arrows, including Crown Point careers, luxury housing, hotel access, dynamic NPCs, organic contacts, blocked shortcuts, and protected private homes.")
	scene_tree.quit(0)


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
