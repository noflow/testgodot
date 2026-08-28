extends Control

const NavigationAccessScript: GDScript = preload("res://src/world/navigation_access.gd")
const NpcPresenceEngineScript: GDScript = preload("res://src/world/npc_presence_engine.gd")
const MONTH_NAMES: PackedStringArray = [
	"January", "February", "March", "April", "May", "June",
	"July", "August", "September", "October", "November", "December",
]

@onready var backdrop: ColorRect = %Backdrop
@onready var background_image: TextureRect = %BackgroundImage
@onready var smartphone: Control = %Smartphone
@onready var location_label: Label = %LocationLabel
@onready var room_label: Label = %RoomLabel
@onready var clock_label: Label = %ClockLabel
@onready var scene_title: Label = %SceneTitle
@onready var scene_description: Label = %SceneDescription
@onready var portrait_stage: HBoxContainer = %PortraitStage
@onready var encounter_text: RichTextLabel = %EncounterText
@onready var status_label: Label = %StatusLabel
@onready var room_buttons: VBoxContainer = %RoomButtons
@onready var action_title: Label = %ActionTitle
@onready var action_buttons: VBoxContainer = %ActionButtons
@onready var directional_navigation: PortAlderDirectionalNavigationUI = %DirectionalNavigation

var _location_id: String = ""
var _location: Dictionary = {}
var _rooms: Array = []
var _current_room_id: String = ""
var _navigation_access: RefCounted
var _presence_engine: RefCounted


func _ready() -> void:
	if not GameState.has_active_game():
		get_tree().change_scene_to_file(AppConstants.MAIN_MENU_SCENE)
		return
	if not SettingsService.settings_changed.is_connected(_apply_accessibility_settings):
		SettingsService.settings_changed.connect(_apply_accessibility_settings)
	_location_id = str(GameState.current_state["world_state"].get("current_location", "")).get_slice(".", 0)
	if _location_id == "hale_home":
		get_tree().change_scene_to_file(AppConstants.HALE_HOME_SCENE)
		return
	var definition: Variant = ContentRegistry.get_location(_location_id)
	if not definition is Dictionary:
		get_tree().change_scene_to_file(AppConstants.HALE_HOME_SCENE)
		return
	_location = definition
	_navigation_access = NavigationAccessScript.new(ContentRegistry)
	_presence_engine = NpcPresenceEngineScript.new(ContentRegistry)
	_sync_city_presence()
	_collect_accessible_rooms()
	_restore_arrival_room()
	smartphone.phone_opened.connect(_on_phone_opened)
	smartphone.phone_closed.connect(_on_phone_closed)
	smartphone.travel_completed.connect(_on_travel_completed)
	directional_navigation.direction_requested.connect(_on_navigation_direction_requested)
	location_label.text = str(_location.get("name", _location_id))
	status_label.text = "Use the scene arrows to move through connected paths, doors, and rooms."
	_render_location()
	_refresh_hud()
	_apply_accessibility_settings()


func _process(_delta: float) -> void:
	_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if directional_navigation.is_minimap_open():
		if event.is_action_pressed("cancel") or event.is_action_pressed("city_map"):
			directional_navigation.close_minimap()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("phone"):
			directional_navigation.close_minimap()
	if smartphone.is_open():
		if event.is_action_pressed("cancel") or event.is_action_pressed("phone"):
			smartphone.close_phone()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("phone"):
		smartphone.open_phone()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("city_map"):
		directional_navigation.toggle_minimap()
		get_viewport().set_input_as_handled()


func _collect_accessible_rooms() -> void:
	_rooms = _navigation_access.accessible_rooms(GameState.current_state, _location_id)
	if _rooms.is_empty():
		_rooms.append({"id": "main_area", "name": _location.get("name", _location_id)})


func _restore_arrival_room() -> void:
	var location_path: String = str(GameState.current_state["world_state"]["current_location"])
	var room_id: String = location_path.get_slice(".", 1)
	if _room_definition(room_id).is_empty():
		room_id = str(_rooms[0].get("id", "main_area"))
	_current_room_id = room_id
	_update_world_location(false)


func _select_room(room_id: String) -> void:
	if _room_definition(room_id).is_empty():
		return
	var changed: bool = room_id != _current_room_id
	_current_room_id = room_id
	_update_world_location(changed)
	_render_location()


func _set_current_room(room_id: String) -> void:
	_select_room(room_id)


func _update_world_location(record_event: bool) -> void:
	var path: String = "%s.%s" % [_location_id, _current_room_id]
	if str(GameState.current_state["world_state"].get("current_location", "")) != path:
		var next_state: Dictionary = GameState.current_state.duplicate(true)
		next_state["world_state"]["current_location"] = path
		GameState.replace_state(next_state)
	if record_event:
		QuestService.record_event("location_entered", {"location": path}, "city.room_selected")


func _render_location() -> void:
	if not is_node_ready():
		return
	room_label.text = _room_name(_current_room_id)
	scene_title.text = _room_name(_current_room_id).to_upper()
	scene_description.text = _room_description(_current_room_id)
	backdrop.color = _location_color(str(_location.get("type", "city_location")))
	VNAssetService.apply_background(background_image, _location_id, _current_room_id, str(GameState.current_state["clock"].get("block", "")))
	_rebuild_room_buttons()
	_refresh_directional_navigation()
	_rebuild_encounter_stage()
	_render_room_actions()


func _rebuild_room_buttons() -> void:
	_clear_container(room_buttons)
	for room_value: Variant in _rooms:
		if not room_value is Dictionary:
			continue
		var room: Dictionary = room_value
		var room_id: String = str(room.get("id", "main_area"))
		var button: Button = Button.new()
		button.text = "%s%s" % ["● " if room_id == _current_room_id else "", room.get("name", room_id.replace("_", " ").capitalize())]
		button.custom_minimum_size = Vector2(0, 45)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_select_room.bind(room_id))
		room_buttons.add_child(button)


func _refresh_directional_navigation() -> void:
	var current_index: int = _room_index(_current_room_id)
	var previous_id: String = _directional_target("left", current_index - 1)
	var next_id: String = _directional_target("right", current_index + 1)
	var up_id: String = _directional_target("up", -1)
	var down_id: String = _directional_target("down", -1)
	directional_navigation.clear_all()
	for entry: Dictionary in [
		{"direction": "left", "target": previous_id},
		{"direction": "up", "target": up_id},
		{"direction": "right", "target": next_id},
		{"direction": "down", "target": down_id},
	]:
		var target: String = str(entry["target"])
		if not target.is_empty():
			directional_navigation.configure_destination(str(entry["direction"]), _navigation_target_name(target))
	if up_id.is_empty() and _can_open_route_planner_here():
		directional_navigation.configure_destination("up", "Choose Bus Destination", "Open")
	directional_navigation.configure_minimap(_location_id, _current_room_id)
	directional_navigation.refresh_accessibility()


func _directional_target(direction: String, fallback_index: int) -> String:
	var room: Dictionary = _room_definition(_current_room_id)
	var navigation: Dictionary = room.get("navigation", {})
	if not navigation.is_empty():
		var authored_id: String = str(navigation.get(direction, ""))
		return authored_id if _valid_navigation_target(authored_id) else ""
	if direction in ["left", "right"] and fallback_index >= 0 and fallback_index < _rooms.size():
		return str(_rooms[fallback_index].get("id", ""))
	return ""


func _room_index(room_id: String) -> int:
	for index: int in _rooms.size():
		if str(_rooms[index].get("id", "")) == room_id:
			return index
	return -1


func _outside_room_id() -> String:
	var authored_id: String = str(_location.get("outside_room", ""))
	if not authored_id.is_empty() and not _room_definition(authored_id).is_empty():
		return authored_id
	return str(_rooms[0].get("id", "main_area")) if not _rooms.is_empty() else "main_area"


func _on_navigation_direction_requested(direction: String) -> void:
	if direction == "up":
		var target: String = _directional_target("up", -1)
		if not target.is_empty():
			_move_to_navigation_target(target)
		elif _can_open_route_planner_here():
			smartphone.open_phone("city_map")
			status_label.text = "Choose a destination from this transit point."
		return
	if direction == "left":
		_move_direction(direction, _room_index(_current_room_id) - 1)
	elif direction == "right":
		_move_direction(direction, _room_index(_current_room_id) + 1)
	elif direction == "down":
		_move_direction(direction, -1)


func _move_direction(direction: String, fallback_index: int) -> void:
	var target: String = _directional_target(direction, fallback_index)
	if not target.is_empty():
		_move_to_navigation_target(target)


func _move_to_navigation_target(target: String) -> void:
	var access: Dictionary = _navigation_access.target_access_report(GameState.current_state, _location_id, target)
	if not bool(access.get("allowed", false)):
		status_label.text = str(access.get("reason", "That path is unavailable right now."))
		return
	if bool(access.get("discover_on_entry", false)) and target.contains("."):
		var discovery_result: Dictionary = SimulationService.apply_operation("world.discover_location", {
			"location_id": target.get_slice(".", 0),
			"discovery_source": "exploration",
		}, "world.directional_discovery")
		if not discovery_result.get("ok", false):
			status_label.text = str(discovery_result.get("errors", ["That destination could not be discovered."])[0])
			return
	if not target.contains("."):
		_select_room(target)
		return
	var destination_id: String = target.get_slice(".", 0)
	if destination_id == _location_id:
		_select_room(target.get_slice(".", 1))
		return
	var result: Dictionary = TravelService.travel(target, "walking", "world.directional_path")
	if not result.get("ok", false):
		status_label.text = str(result.get("errors", ["That path is unavailable right now."])[0])
		return
	var next_state: Dictionary = GameState.current_state.duplicate(true)
	next_state["world_state"]["current_location"] = target
	GameState.replace_state(next_state)
	get_tree().change_scene_to_file(AppConstants.HALE_HOME_SCENE if destination_id == "hale_home" else AppConstants.CITY_LOCATION_SCENE)


func _navigation_target_name(target: String) -> String:
	if not target.contains("."):
		return _room_name(target)
	var location_id: String = target.get_slice(".", 0)
	var room_id: String = target.get_slice(".", 1)
	var location: Variant = ContentRegistry.get_location(location_id)
	if location is Dictionary:
		var outside_room: String = str(location.get("outside_room", ""))
		if outside_room.is_empty() and not location.get("rooms", []).is_empty() and location.get("rooms", [])[0] is Dictionary:
			outside_room = str(location.get("rooms", [])[0].get("id", ""))
		if room_id == outside_room:
			var location_label: String = str(location.get("name", location_id)).trim_prefix("Westshore ")
			location_label = location_label.trim_suffix(" Dorm")
			return location_label
		for room: Variant in location.get("rooms", []):
			if room is Dictionary and str(room.get("id", "")) == room_id:
				return str(room.get("name", location.get("name", location_id)))
		return str(location.get("name", location_id))
	return target.replace("_", " ").capitalize()


func _valid_navigation_target(target: String) -> bool:
	if _navigation_access == null:
		return false
	return bool(_navigation_access.target_access_report(GameState.current_state, _location_id, target).get("allowed", false))


func _can_open_route_planner_here() -> bool:
	if _current_room_id != _outside_room_id():
		return false
	return str(_location.get("type", "")) == "transport_stop" or "route_planner" in _location.get("services", [])


func _rebuild_encounter_stage() -> void:
	_clear_container(portrait_stage)
	var interactions: Array = CityActionService.interactions_for_room(_location_id, _current_room_id)
	var encounter_names: PackedStringArray = []
	var portrait_ids: Dictionary = {}
	for interaction: Variant in interactions:
		if interaction is Dictionary and str(interaction.get("type", "activity")) == "conversation":
			encounter_names.append(str(interaction.get("name", "Conversation")))
			var character_id: String = str(interaction.get("character_id", ""))
			if not character_id.is_empty() and not portrait_ids.has(character_id):
				var character: Variant = ContentRegistry.get_character(character_id)
				var display_name: String = str(character.get("display_name", character_id)) if character is Dictionary else character_id.replace("_", " ").capitalize()
				_add_portrait_card(character_id, display_name)
				portrait_ids[character_id] = true
	for presence_value: Variant in _presence_engine.present_in_room(GameState.current_state, _location_id, _current_room_id):
		if not presence_value is Dictionary:
			continue
		var character_id: String = str(presence_value.get("character_id", ""))
		if character_id.is_empty() or portrait_ids.has(character_id):
			continue
		_add_portrait_card(character_id, str(presence_value.get("display_name", character_id)))
		portrait_ids[character_id] = true
	if encounter_names.is_empty():
		encounter_text.text = "[center][font_size=24][color=#b8c7c7]The location is open for sandbox activities. Scheduled characters and future encounters can appear on this stage.[/color][/font_size][/center]"
	else:
		encounter_text.text = "[center][font_size=25][color=#e9a86c]STORY ENCOUNTER AVAILABLE[/color][/font_size]\n\n[font_size=24]%s[/font_size][/center]" % "\n".join(encounter_names)
	portrait_stage.visible = true
	encounter_text.visible = false


func _add_portrait_card(character_id: String, _display_name: String) -> void:
	var card: VBoxContainer = VBoxContainer.new()
	card.custom_minimum_size = Vector2(230, 360)
	var portrait: TextureRect = TextureRect.new()
	portrait.custom_minimum_size = Vector2(230, 360)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	VNAssetService.apply_portrait(portrait, character_id)
	card.add_child(portrait)
	portrait_stage.add_child(card)


func _render_room_actions() -> void:
	var interactions: Array = CityActionService.interactions_for_room(_location_id, _current_room_id)
	interactions.append_array(_presence_engine.interactions_for_room(GameState.current_state, _location_id, _current_room_id))
	_open_action_panel(interactions)


func _on_interact_requested(_world_position: Vector2 = Vector2.ZERO) -> void:
	_render_room_actions()


func _open_action_panel(interactions: Array) -> void:
	_clear_container(action_buttons)
	action_title.text = "CHOICES • %s" % _room_name(_current_room_id)
	for interaction: Variant in interactions:
		if not interaction is Dictionary:
			continue
		var available: bool = bool(interaction.get("available", false))
		var reason: String = str(interaction.get("unavailable_reason", ""))
		if str(interaction.get("type", "activity")) == "conversation" and available:
			var dialogue_availability: Dictionary = DialogueService.can_begin(str(interaction.get("conversation_id", "")))
			available = bool(dialogue_availability.get("ok", false))
			reason = str(dialogue_availability.get("reason", "")) if not available else ""
		var label: String = "%s\n%s" % [interaction.get("name", interaction.get("id", "Activity")), interaction.get("description", "")]
		if not available:
			label += "\nUnavailable: %s" % (reason if not reason.is_empty() else "Requirements not met")
		var callback: Callable
		match str(interaction.get("type", "activity")):
			"conversation":
				callback = _on_conversation_selected.bind(str(interaction.get("conversation_id", "")))
			"store":
				callback = _on_store_selected.bind(str(interaction.get("store_id", "")))
			"mall_directory":
				callback = _on_mall_directory_selected
			"npc_presence":
				callback = _on_npc_presence_selected.bind(str(interaction.get("character_id", "")))
			_:
				callback = _on_activity_selected.bind(str(interaction.get("id", "")))
		_add_choice_button(label, callback, available)
	if action_buttons.get_child_count() == 0:
		var room: Dictionary = _room_definition(_current_room_id)
		var labels: Array = room.get("actions", [])
		if labels.is_empty():
			labels = _location.get("services", [])
		_add_choice_button("No authored activity is available here yet.\nPlanned uses: %s" % _join_labels(labels), Callable(), false)
	SettingsService.apply_accessibility(action_buttons)


func _add_choice_button(label: String, callback: Callable, enabled: bool = true) -> Button:
	var button: Button = Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(0, 60)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.disabled = not enabled
	if enabled:
		button.pressed.connect(callback)
	action_buttons.add_child(button)
	return button


func _on_conversation_selected(conversation_id: String) -> void:
	_update_world_location(false)
	var owner_character_id: String = _conversation_character_id(conversation_id)
	if not owner_character_id.is_empty():
		var owner_presence: Dictionary = _presence_engine.resolve_character(GameState.current_state, owner_character_id)
		if owner_presence.get("present", false) and not owner_presence.get("discovered", false) and str(owner_presence.get("location", "")) == "%s.%s" % [_location_id, _current_room_id]:
			SimulationService.apply_operation("npc.meet", {
				"character_id": owner_character_id,
				"interaction": "introduction",
				"location": "%s.%s" % [_location_id, _current_room_id],
			}, "city.story_introduction")
	var result: Dictionary = DialogueService.begin(conversation_id)
	if not result.get("ok", false):
		status_label.text = str(result.get("errors", ["That conversation is unavailable."])[0])
		_render_room_actions()
		return
	get_tree().change_scene_to_file(AppConstants.VN_DIALOGUE_SCENE)


func _on_activity_selected(interaction_id: String) -> void:
	var result: Dictionary = CityActionService.perform(interaction_id)
	if result.get("ok", false):
		status_label.text = "%s completed. Time, stats, and quest progress were updated." % result["interaction"].get("name", interaction_id)
	else:
		status_label.text = str(result.get("errors", ["That activity could not be completed."])[0])
	_sync_city_presence()
	_render_location()
	_refresh_hud()


func _on_store_selected(store_id: String) -> void:
	if store_id.is_empty():
		status_label.text = "This storefront has not opened yet."
		return
	smartphone.open_storefront(store_id)


func _on_mall_directory_selected() -> void:
	_clear_container(action_buttons)
	action_title.text = "PORT ALDER GALLERIA DIRECTORY"
	var mall: Dictionary = _location.get("mall", {})
	for slot_value: Variant in mall.get("storefront_slots", []):
		if not slot_value is Dictionary:
			continue
		var slot: Dictionary = slot_value
		var status: String = str(slot.get("status", "vacant"))
		var name: String = str(slot.get("name", "Available Storefront"))
		var label: String = "%s • %s\n%s — %s" % [
			slot.get("unit", "Unit"), str(slot.get("level", "Mall")).replace("_", " ").capitalize(),
			name, status.replace("_", " ").capitalize(),
		]
		_add_choice_button(label, Callable(), false)
	SettingsService.apply_accessibility(action_buttons)


func _on_npc_presence_selected(character_id: String) -> void:
	var character: Variant = ContentRegistry.get_character(character_id)
	var presence: Dictionary = _presence_engine.resolve_character(GameState.current_state, character_id)
	if not character is Dictionary or not presence.get("present", false):
		status_label.text = "That person is no longer here."
		_render_location()
		return
	_clear_container(action_buttons)
	action_title.text = str(character.get("display_name", character_id)).to_upper() if bool(presence.get("discovered", false)) else "SOMEONE NEW"
	for conversation_value: Variant in _presence_engine.available_conversations(character_id):
		if not conversation_value is Dictionary:
			continue
		var conversation_id: String = str(conversation_value.get("id", ""))
		if DialogueService.can_begin(conversation_id).get("ok", false):
			_add_choice_button("Story Conversation • %s" % conversation_value.get("title", conversation_id.replace("_", " ").capitalize()), _on_conversation_selected.bind(conversation_id))
	if not bool(presence.get("discovered", false)):
		_add_choice_button("Introduce Yourself\nBegin an acquaintance naturally.", _on_npc_introduction_selected.bind(character_id))
	else:
		if not bool(presence.get("phone_contact", false)) and _presence_engine.contact_exchange_allowed(character_id):
			_add_choice_button("Ask to Exchange Numbers\nAdd each other to phone contacts.", _on_npc_contact_selected.bind(character_id))
		_add_choice_button("Chat for a Few Minutes\n%s" % presence.get("activity_label", "Spend a little time together"), _on_npc_ambient_chat_selected.bind(character_id))
	_add_choice_button("Back to Room Choices", _render_room_actions)
	SettingsService.apply_accessibility(action_buttons)


func _on_npc_introduction_selected(character_id: String) -> void:
	var line: String = _presence_engine.introduction_line(GameState.current_state, character_id)
	var result: Dictionary = SimulationService.apply_operation("npc.meet", {
		"character_id": character_id,
		"interaction": "introduction",
		"location": "%s.%s" % [_location_id, _current_room_id],
	}, "city.npc_introduction")
	if not result.get("ok", false):
		status_label.text = str(result.get("errors", ["The introduction could not begin."])[0])
		return
	QuestService.record_event("npc_encounter_started", {"character": character_id, "location": _location_id}, "city.npc_introduction")
	TimeService.advance_minutes(5, "city.npc_introduction:%s" % character_id)
	_sync_city_presence()
	status_label.text = "%s: “%s”" % [_character_first_name(character_id), line]
	_render_location()


func _on_npc_contact_selected(character_id: String) -> void:
	var line: String = _presence_engine.contact_line(GameState.current_state, character_id)
	var result: Dictionary = SimulationService.apply_operation("npc.meet", {
		"character_id": character_id,
		"interaction": "exchange_contact",
		"location": "%s.%s" % [_location_id, _current_room_id],
	}, "city.npc_contact_exchange")
	if not result.get("ok", false):
		status_label.text = str(result.get("errors", ["Contact information could not be exchanged."])[0])
		return
	TimeService.advance_minutes(5, "city.npc_contact_exchange:%s" % character_id)
	_sync_city_presence()
	status_label.text = "%s: “%s”" % [_character_first_name(character_id), line]
	_render_location()


func _on_npc_ambient_chat_selected(character_id: String) -> void:
	var line: String = _presence_engine.ambient_line(GameState.current_state, character_id, _location_id)
	var result: Dictionary = SimulationService.apply_operation("npc.meet", {
		"character_id": character_id,
		"interaction": "ambient_chat",
		"location": "%s.%s" % [_location_id, _current_room_id],
	}, "city.npc_ambient_chat")
	if not result.get("ok", false):
		status_label.text = str(result.get("errors", ["The conversation could not begin."])[0])
		return
	TimeService.advance_minutes(10, "city.npc_ambient_chat:%s" % character_id)
	_sync_city_presence()
	status_label.text = "%s: “%s”" % [_character_first_name(character_id), line]
	_render_location()


func _on_close_action_panel_pressed() -> void:
	_render_room_actions()


func _close_action_panel() -> void:
	_render_room_actions()


func _remember_city_position() -> void:
	_update_world_location(false)


func _sync_city_presence() -> void:
	if _presence_engine == null or not GameState.has_active_game():
		return
	var result: Dictionary = _presence_engine.synchronize_npc_states(GameState.current_state)
	if result.get("changed", false):
		GameState.replace_state(result["state"])


func _character_first_name(character_id: String) -> String:
	var character: Variant = ContentRegistry.get_character(character_id)
	return str(character.get("display_name", character_id)).get_slice(" ", 0) if character is Dictionary else character_id.replace("_", " ").capitalize()


func _conversation_character_id(conversation_id: String) -> String:
	for npc_state_value: Variant in GameState.current_state.get("npc_states", []):
		if not npc_state_value is Dictionary:
			continue
		var character_id: String = str(npc_state_value.get("character_id", ""))
		var character: Variant = ContentRegistry.get_character(character_id)
		if not character is Dictionary:
			continue
		for conversation_value: Variant in character.get("conversations", []):
			if conversation_value is Dictionary and str(conversation_value.get("id", "")) == conversation_id:
				return character_id
	return ""


func _refresh_hud() -> void:
	if not GameState.has_active_game() or not is_node_ready():
		return
	var clock: Dictionary = GameState.current_state["clock"]
	var month_index: int = clampi(int(clock.get("month", 1)) - 1, 0, MONTH_NAMES.size() - 1)
	clock_label.text = "%s • %s • %s %d" % [str(clock.get("weekday", "")).capitalize(), str(clock.get("block", "")).replace("_", " ").capitalize(), MONTH_NAMES[month_index], int(clock.get("day", 1))]


func _room_definition(room_id: String) -> Dictionary:
	for room: Variant in _rooms:
		if room is Dictionary and str(room.get("id", "")) == room_id:
			return room
	return {}


func _room_name(room_id: String) -> String:
	var room: Dictionary = _room_definition(room_id)
	return str(room.get("name", room_id.replace("_", " ").capitalize()))


func _room_description(room_id: String) -> String:
	var room: Dictionary = _room_definition(room_id)
	var uses: Array = room.get("actions", [])
	if uses.is_empty():
		uses = _location.get("services", [])
	var district_name: String = str(_location.get("district", "Port Alder")).replace("_", " ").capitalize()
	return "%s is part of %s. This visual-novel location can host %s." % [_room_name(room_id), district_name, _join_labels(uses).to_lower()]


func _join_labels(values: Array) -> String:
	var labels: PackedStringArray = []
	for value: Variant in values:
		labels.append(str(value).replace("_", " ").capitalize())
	return ", ".join(labels) if not labels.is_empty() else "exploration and future encounters"


func _location_color(type_id: String) -> Color:
	if "outdoor" in type_id or type_id in ["waterfront_hub", "luxury_hub"]:
		return Color("234c4c")
	if type_id in ["hospital", "medical_clinic", "doctors_office", "therapy_office", "sexual_health_clinic", "pharmacy"]:
		return Color("294657")
	if "school" in type_id or "college" in type_id or "administration" in type_id:
		return Color("303f58")
	if "residence" in type_id or "housing" in type_id or "apartment" in type_id or "condo" in type_id:
		return Color("4a3d45")
	if "store" in type_id or "shopping" in type_id:
		return Color("4a4633")
	return Color("263c4b")


func _on_phone_button_pressed() -> void:
	smartphone.open_phone()


func _on_map_button_pressed() -> void:
	directional_navigation.toggle_minimap()


func _on_phone_opened() -> void:
	directional_navigation.close_minimap()


func _on_phone_closed() -> void:
	_refresh_hud()


func _on_travel_completed(destination: String) -> void:
	var destination_id: String = destination.get_slice(".", 0)
	get_tree().change_scene_to_file(AppConstants.HALE_HOME_SCENE if destination_id == "hale_home" else AppConstants.CITY_LOCATION_SCENE)


func _clear_container(container: Container) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _apply_accessibility_settings() -> void:
	SettingsService.apply_accessibility(self)
