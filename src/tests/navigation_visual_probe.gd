extends Node

const NewGameStateFactoryScript: GDScript = preload("res://src/core/new_game_state_factory.gd")

var _active_scene: Node
var _factory: RefCounted


func _ready() -> void:
	call_deferred("_initialize")


func _initialize() -> void:
	var errors: PackedStringArray = ContentRegistry.validate_foundation()
	if not errors.is_empty():
		push_error("Navigation visual probe could not load game content: %s" % "; ".join(errors))
		return
	_factory = NewGameStateFactoryScript.new(ContentRegistry)
	_show_location("port_alder_galleria.main_atrium")


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.keycode == KEY_F1:
		_show_location("hale_home.player_bedroom")
	elif event.keycode == KEY_F2:
		_show_location("port_alder_galleria.main_atrium")
	elif event.keycode == KEY_F3:
		_show_location("alder_heights_bus_stop.shelter")
	elif event.keycode == KEY_F4:
		_show_location("maple_hall_dorm.lobby")


func _show_location(location_path: String) -> void:
	if _active_scene != null:
		_active_scene.free()
	var state: Dictionary = _factory.create_new_game({}, {"random_seed": 997})
	var location_id: String = location_path.get_slice(".", 0)
	for list_name: String in ["unlocked_locations", "discovered_locations"]:
		if location_id not in state["world_state"][list_name]:
			state["world_state"][list_name].append(location_id)
	state["world_state"]["current_location"] = location_path
	GameState.replace_state(state)
	var scene_path: String = AppConstants.HALE_HOME_SCENE if location_id == "hale_home" else AppConstants.CITY_LOCATION_SCENE
	_active_scene = (load(scene_path) as PackedScene).instantiate()
	add_child(_active_scene)
