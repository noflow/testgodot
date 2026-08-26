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
	var room_buttons: Container = instance.get_node_or_null("Interface/MainMargin/MainLayout/NavigationPanel/Margin/Layout/Scroll/RoomButtons")
	if phone == null or instance.get_node_or_null("Player") != null or instance.get_node_or_null("Backdrop") == null or room_buttons == null:
		printerr("CITY PROBE: VN backdrop, area navigation, or smartphone is missing")
		get_tree().quit(1)
		return
	if str(instance.get_node("Interface/Header/Margin/Layout/Top/LocationLabel").text) != "Westshore Administration Office":
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
	phone.open_phone("city_map")
	await get_tree().process_frame
	phone.call("_open_route_planner", "hale_home")
	await get_tree().process_frame
	if not phone.get_node("RoutePanel").visible or phone.get_node("RoutePanel/Margin/Layout/RouteOption").item_count != 4:
		printerr("CITY PROBE: reverse route planner did not populate")
		get_tree().quit(1)
		return
	print("PASS: City destination rendered data-driven VN areas, institutional choices, and reverse travel routes.")
	get_tree().quit(0)
