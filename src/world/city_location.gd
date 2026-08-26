extends Control

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

var _location_id: String = ""
var _location: Dictionary = {}
var _rooms: Array = []
var _current_room_id: String = ""


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
	_collect_accessible_rooms()
	_restore_arrival_room()
	smartphone.phone_opened.connect(_on_phone_opened)
	smartphone.phone_closed.connect(_on_phone_closed)
	smartphone.travel_completed.connect(_on_travel_completed)
	location_label.text = str(_location.get("name", _location_id))
	status_label.text = "Choose an area, activity, conversation, or a new destination."
	_render_location()
	_refresh_hud()
	_apply_accessibility_settings()


func _process(_delta: float) -> void:
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


func _collect_accessible_rooms() -> void:
	_rooms.clear()
	for room: Variant in _location.get("rooms", []):
		if not room is Dictionary or str(room.get("access", "")) in ["employee", "restricted"]:
			continue
		_rooms.append(room)
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


func _rebuild_encounter_stage() -> void:
	_clear_container(portrait_stage)
	var interactions: Array = CityActionService.interactions_for_room(_location_id, _current_room_id)
	var encounter_names: PackedStringArray = []
	var portrait_count: int = 0
	for interaction: Variant in interactions:
		if interaction is Dictionary and str(interaction.get("type", "activity")) == "conversation":
			encounter_names.append(str(interaction.get("name", "Conversation")))
			var character_id: String = str(interaction.get("character_id", ""))
			if not character_id.is_empty():
				var character: Variant = ContentRegistry.get_character(character_id)
				var display_name: String = str(character.get("display_name", character_id)) if character is Dictionary else character_id.replace("_", " ").capitalize()
				_add_portrait_card(character_id, display_name)
				portrait_count += 1
	if encounter_names.is_empty():
		encounter_text.text = "[center][font_size=24][color=#b8c7c7]The location is open for sandbox activities. Scheduled characters and future encounters can appear on this stage.[/color][/font_size][/center]"
	else:
		encounter_text.text = "[center][font_size=25][color=#e9a86c]STORY ENCOUNTER AVAILABLE[/color][/font_size]\n\n[font_size=24]%s[/font_size][/center]" % "\n".join(encounter_names)
	portrait_stage.visible = portrait_count > 0
	encounter_text.visible = portrait_count == 0


func _add_portrait_card(character_id: String, display_name: String) -> void:
	var card: VBoxContainer = VBoxContainer.new()
	card.custom_minimum_size = Vector2(180, 0)
	card.add_theme_constant_override("separation", 4)
	var portrait: TextureRect = TextureRect.new()
	portrait.custom_minimum_size = Vector2(180, 250)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	VNAssetService.apply_portrait(portrait, character_id)
	card.add_child(portrait)
	var name_label: Label = Label.new()
	name_label.text = display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color("eef6f5"))
	card.add_child(name_label)
	portrait_stage.add_child(card)


func _render_room_actions() -> void:
	_open_action_panel(CityActionService.interactions_for_room(_location_id, _current_room_id))


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
		var callback: Callable = _on_conversation_selected.bind(str(interaction.get("conversation_id", ""))) if str(interaction.get("type", "activity")) == "conversation" else _on_activity_selected.bind(str(interaction.get("id", "")))
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
	_render_location()
	_refresh_hud()


func _on_close_action_panel_pressed() -> void:
	_render_room_actions()


func _close_action_panel() -> void:
	_render_room_actions()


func _remember_city_position() -> void:
	_update_world_location(false)


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
	smartphone.open_phone("city_map")


func _on_phone_opened() -> void:
	pass


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
