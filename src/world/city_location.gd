extends Node2D

const MAP_RECT: Rect2 = Rect2(20, 92, 1560, 888)
const COLUMNS: int = 3

@onready var player: CharacterBody2D = %Player
@onready var smartphone: Control = %Smartphone
@onready var location_label: Label = %LocationLabel
@onready var room_label: Label = %RoomLabel
@onready var clock_label: Label = %ClockLabel
@onready var prompt_label: Label = %PromptLabel
@onready var status_label: Label = %StatusLabel

var _location_id: String = ""
var _location: Dictionary = {}
var _rooms: Array = []
var _room_rects: Dictionary = {}
var _current_room_id: String = ""


func _ready() -> void:
	if not GameState.has_active_game():
		get_tree().change_scene_to_file(AppConstants.MAIN_MENU_SCENE)
		return
	_location_id = str(GameState.current_state["world_state"].get("current_location", "")).get_slice(".", 0)
	if _location_id == "hale_home":
		get_tree().change_scene_to_file(AppConstants.HALE_HOME_SCENE)
		return
	var definition: Variant = ContentRegistry.get_location(_location_id)
	if not definition is Dictionary:
		get_tree().change_scene_to_file(AppConstants.HALE_HOME_SCENE)
		return
	_location = definition
	_collect_accessible_rooms()
	_layout_rooms()
	_restore_arrival_room()
	player.interact_requested.connect(_on_interact_requested)
	smartphone.phone_opened.connect(_on_phone_opened)
	smartphone.phone_closed.connect(_on_phone_closed)
	smartphone.travel_completed.connect(_on_travel_completed)
	location_label.text = str(_location.get("name", _location_id))
	status_label.text = "Explore the destination rooms or open the City Map to travel elsewhere."
	_refresh_hud()
	queue_redraw()


func _process(_delta: float) -> void:
	player.position.x = clampf(player.position.x, MAP_RECT.position.x + 24.0, MAP_RECT.end.x - 24.0)
	player.position.y = clampf(player.position.y, MAP_RECT.position.y + 24.0, MAP_RECT.end.y - 24.0)
	for room_id: Variant in _room_rects:
		if _room_rects[room_id].has_point(player.position):
			_set_current_room(str(room_id))
			break
	var room_rect: Rect2 = _room_rects.get(_current_room_id, Rect2())
	prompt_label.text = "E / A — Look around %s" % _room_name(_current_room_id) if player.position.distance_to(room_rect.get_center()) < 115.0 else ""
	_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if smartphone.is_open():
		if event.is_action_pressed("cancel") or event.is_action_pressed("phone"):
			smartphone.close_phone()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("phone"):
		smartphone.open_phone()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("city_map"):
		smartphone.open_phone("city_map")
		get_viewport().set_input_as_handled()


func _draw() -> void:
	draw_rect(MAP_RECT, Color("152b34"), true)
	for room_id: Variant in _room_rects:
		var rect: Rect2 = _room_rects[room_id]
		var active: bool = str(room_id) == _current_room_id
		var color: Color = Color("355149") if active else Color("293e45")
		draw_rect(rect, color, true)
		draw_rect(rect, Color("e9a86c") if active else Color("70898b"), false, 3.0 if active else 2.0)
		draw_string(
			ThemeDB.fallback_font,
			rect.position + Vector2(18, 34),
			_room_name(str(room_id)),
			HORIZONTAL_ALIGNMENT_LEFT,
			rect.size.x - 36,
			20,
			Color("eef6f5")
		)
		draw_circle(rect.get_center(), 11.0, Color("67c6c3"))
		draw_circle(rect.get_center(), 11.0, Color("eef6f5"), false, 2.0)


func _collect_accessible_rooms() -> void:
	for room: Variant in _location.get("rooms", []):
		if not room is Dictionary or str(room.get("access", "")) in ["employee", "restricted"]:
			continue
		_rooms.append(room)
	if _rooms.is_empty():
		_rooms.append({"id": "main_area", "name": _location.get("name", _location_id)})


func _layout_rooms() -> void:
	var row_count: int = ceili(float(_rooms.size()) / float(COLUMNS))
	var cell_width: float = MAP_RECT.size.x / float(COLUMNS)
	var cell_height: float = MAP_RECT.size.y / float(maxi(row_count, 1))
	for index: int in _rooms.size():
		var column: int = index % COLUMNS
		var row: int = index / COLUMNS
		var rect: Rect2 = Rect2(
			MAP_RECT.position + Vector2(column * cell_width + 8.0, row * cell_height + 8.0),
			Vector2(cell_width - 16.0, cell_height - 16.0)
		)
		_room_rects[str(_rooms[index].get("id", "room_%d" % index))] = rect


func _restore_arrival_room() -> void:
	var location_path: String = str(GameState.current_state["world_state"]["current_location"])
	var room_id: String = location_path.get_slice(".", 1)
	if not _room_rects.has(room_id):
		room_id = str(_rooms[0].get("id", "main_area"))
	_current_room_id = room_id
	player.position = _room_rects[room_id].get_center()
	room_label.text = _room_name(room_id)


func _set_current_room(room_id: String) -> void:
	if room_id == _current_room_id or not _room_rects.has(room_id):
		return
	_current_room_id = room_id
	room_label.text = _room_name(room_id)
	var next_state: Dictionary = GameState.current_state.duplicate(true)
	next_state["world_state"]["current_location"] = "%s.%s" % [_location_id, room_id]
	GameState.replace_state(next_state)
	queue_redraw()


func _on_interact_requested(_world_position: Vector2) -> void:
	var room: Dictionary = _room_definition(_current_room_id)
	var actions: Array = room.get("actions", [])
	var services: Array = _location.get("services", [])
	var available: Array = actions if not actions.is_empty() else services
	status_label.text = "%s • Available here: %s. Full destination activities arrive in the next milestone." % [
		_room_name(_current_room_id),
		_join_labels(available),
	]


func _refresh_hud() -> void:
	if not GameState.has_active_game():
		return
	var clock: Dictionary = GameState.current_state["clock"]
	clock_label.text = "%s • %s • Month %02d, Day %02d" % [
		str(clock.get("weekday", "")).capitalize(),
		str(clock.get("block", "")).replace("_", " ").capitalize(),
		int(clock.get("month", 1)),
		int(clock.get("day", 1)),
	]


func _room_definition(room_id: String) -> Dictionary:
	for room: Variant in _rooms:
		if room is Dictionary and str(room.get("id", "")) == room_id:
			return room
	return {}


func _room_name(room_id: String) -> String:
	var room: Dictionary = _room_definition(room_id)
	return str(room.get("name", room_id.replace("_", " ").capitalize()))


func _join_labels(values: Array) -> String:
	var labels: PackedStringArray = []
	for value: Variant in values:
		labels.append(str(value).replace("_", " ").capitalize())
	return ", ".join(labels) if not labels.is_empty() else "exploration"


func _on_phone_opened() -> void:
	player.movement_enabled = false


func _on_phone_closed() -> void:
	player.movement_enabled = true


func _on_travel_completed(destination: String) -> void:
	var destination_id: String = destination.get_slice(".", 0)
	get_tree().change_scene_to_file(AppConstants.HALE_HOME_SCENE if destination_id == "hale_home" else AppConstants.CITY_LOCATION_SCENE)
