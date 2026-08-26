extends Control

const CHARACTERS_PER_SECOND: float = 55.0

@onready var scene_title: Label = %SceneTitle
@onready var background_image: TextureRect = %BackgroundImage
@onready var portrait_image: TextureRect = %PortraitImage
@onready var portrait_placeholder: Label = %PortraitPlaceholder
@onready var speaker_label: Label = %SpeakerLabel
@onready var line_label: Label = %LineLabel
@onready var choices_box: VBoxContainer = %ChoicesBox
@onready var continue_button: Button = %ContinueButton
@onready var auto_button: Button = %AutoButton
@onready var skip_button: Button = %SkipButton
@onready var history_panel: PanelContainer = %HistoryPanel
@onready var history_text: RichTextLabel = %HistoryText
@onready var error_label: Label = %ErrorLabel

var _full_text: String = ""
var _revealed_characters: float = 0.0
var _auto_enabled: bool = false
var _auto_wait: float = 0.0
var _skip_active: bool = false
var _skip_wait: float = 0.0


func _ready() -> void:
	SettingsService.settings_changed.connect(_apply_accessibility_settings)
	_apply_accessibility_settings()
	var resumed: Dictionary = DialogueService.resume()
	if not resumed.get("ok", false):
		_show_error(str(resumed.get("errors", ["No active conversation."])[0]))
		return
	_render_view(resumed["view"])


func _process(delta: float) -> void:
	if line_label.visible_characters >= 0 and line_label.visible_characters < _full_text.length():
		if SettingsService.reduce_motion or _skip_active:
			_reveal_line()
			return
		_revealed_characters += CHARACTERS_PER_SECOND * delta
		line_label.visible_characters = mini(int(_revealed_characters), _full_text.length())
		return
	if _auto_enabled and continue_button.visible and not history_panel.visible:
		_auto_wait += delta
		if _auto_wait >= 1.25:
			_auto_wait = 0.0
			_advance_dialogue()
	if _skip_active and continue_button.visible and not history_panel.visible:
		_skip_wait += delta
		if _skip_wait >= 0.16:
			_skip_wait = 0.0
			_advance_dialogue()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dialogue_history"):
		_toggle_history()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") and continue_button.visible and not history_panel.visible:
		_on_continue_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("dialogue_skip"):
		if SettingsService.dialogue_skip_mode == "toggle":
			_skip_active = not _skip_active
		else:
			_skip_active = true
		_update_skip_label()
		get_viewport().set_input_as_handled()
	elif event.is_action_released("dialogue_skip") and SettingsService.dialogue_skip_mode == "hold":
		_skip_active = false
		_update_skip_label()
		get_viewport().set_input_as_handled()


func _render_view(view: Dictionary) -> void:
	error_label.text = ""
	scene_title.text = _scene_heading()
	_render_artwork(view)
	var stage_direction: String = str(view.get("stage_direction", ""))
	var line: String = str(view.get("line", ""))
	if not stage_direction.is_empty():
		speaker_label.text = "NARRATION"
		_full_text = stage_direction
	else:
		speaker_label.text = str(view.get("speaker_name", "")).to_upper()
		_full_text = line
	line_label.text = _full_text
	line_label.visible_characters = -1 if SettingsService.reduce_motion else 0
	_revealed_characters = 0.0
	_auto_wait = 0.0
	_clear_choices()

	var choices: Array = view.get("choices", [])
	for choice: Variant in choices:
		if not choice is Dictionary:
			continue
		var button: Button = Button.new()
		button.text = str(choice.get("text", ""))
		button.custom_minimum_size = Vector2(0, 48)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_choice_pressed.bind(str(choice.get("id", ""))))
		choices_box.add_child(button)
	continue_button.visible = choices.is_empty()
	if not choices.is_empty() and choices_box.get_child_count() > 0:
		choices_box.get_child(0).grab_focus()
	elif continue_button.visible:
		continue_button.grab_focus()


func _render_artwork(view: Dictionary) -> void:
	var location_path: String = str(GameState.current_state.get("world_state", {}).get("current_location", "hale_home.player_bedroom"))
	var location_id: String = location_path.get_slice(".", 0)
	var room_id: String = location_path.get_slice(".", 1)
	VNAssetService.apply_background(background_image, location_id, room_id, str(view.get("background_variant", "")))
	var character_id: String = str(view.get("speaker_id", ""))
	if character_id.is_empty() or character_id == "player":
		for participant_value: Variant in view.get("participants", []):
			var participant: String = str(participant_value)
			if participant != "player":
				character_id = participant
				break
	var portrait_card: Control = $PortraitArea/PortraitCard
	if character_id.is_empty() or character_id == "player":
		portrait_card.visible = false
		return
	var character: Variant = ContentRegistry.get_character(character_id)
	var display_name: String = str(character.get("display_name", character_id)) if character is Dictionary else str(view.get("speaker_name", character_id.replace("_", " ").capitalize()))
	VNAssetService.apply_portrait(portrait_image, character_id, str(view.get("portrait_id", "default")))
	portrait_placeholder.text = display_name.to_upper()
	portrait_card.visible = portrait_image.texture != null


func _scene_heading() -> String:
	var clock: Dictionary = GameState.current_state.get("clock", {})
	var location_path: String = str(GameState.current_state.get("world_state", {}).get("current_location", ""))
	var room_name: String = location_path.get_slice(".", 1).replace("_", " ").capitalize()
	if room_name.is_empty():
		var location: Variant = ContentRegistry.get_location(location_path.get_slice(".", 0))
		room_name = str(location.get("name", location_path)) if location is Dictionary else location_path.replace("_", " ").capitalize()
	return "MONTH %02d, DAY %02d • %s %s • %s" % [
		int(clock.get("month", 1)),
		int(clock.get("day", 1)),
		str(clock.get("weekday", "")).to_upper(),
		str(clock.get("block", "")).replace("_", " ").to_upper(),
		room_name.to_upper(),
	]


func _on_continue_pressed() -> void:
	if line_label.visible_characters >= 0 and line_label.visible_characters < _full_text.length():
		_reveal_line()
		return
	_advance_dialogue()


func _advance_dialogue() -> void:
	_handle_result(DialogueService.advance())


func _on_choice_pressed(choice_id: String) -> void:
	_reveal_line()
	_handle_result(DialogueService.choose(choice_id))


func _handle_result(result: Dictionary) -> void:
	if not result.get("ok", false):
		_show_error(str(result.get("errors", ["Dialogue could not continue."])[0]))
		return
	if result.get("ended", false):
		var location_id: String = str(GameState.current_state.get("world_state", {}).get("current_location", "hale_home")).get_slice(".", 0)
		get_tree().change_scene_to_file(
			AppConstants.HALE_HOME_SCENE if location_id == "hale_home" else AppConstants.CITY_LOCATION_SCENE
		)
		return
	_render_view(result["view"])


func _on_auto_pressed() -> void:
	_auto_enabled = not _auto_enabled
	auto_button.text = "Auto: On" if _auto_enabled else "Auto: Off"
	_auto_wait = 0.0


func _on_skip_button_down() -> void:
	if SettingsService.dialogue_skip_mode == "toggle":
		_skip_active = not _skip_active
	else:
		_skip_active = true
	_update_skip_label()


func _on_skip_button_up() -> void:
	if SettingsService.dialogue_skip_mode == "hold":
		_skip_active = false
		_update_skip_label()


func _on_replay_pressed() -> void:
	_skip_active = false
	_revealed_characters = 0.0
	line_label.visible_characters = 0
	_auto_wait = 0.0
	_update_skip_label()


func _on_history_pressed() -> void:
	_toggle_history()


func _toggle_history() -> void:
	history_panel.visible = not history_panel.visible
	if history_panel.visible:
		var lines: PackedStringArray = []
		for entry: Variant in GameState.current_state["conversation_state"].get("history", []):
			if entry is Dictionary:
				var speaker: String = str(entry.get("speaker", "narration")).replace("_", " ").capitalize()
				lines.append("[b]%s[/b]\n%s" % [speaker, entry.get("text", "")])
		history_text.text = "\n\n".join(lines)


func _reveal_line() -> void:
	_revealed_characters = _full_text.length()
	line_label.visible_characters = -1


func _clear_choices() -> void:
	for child: Node in choices_box.get_children():
		choices_box.remove_child(child)
		child.queue_free()


func _show_error(message: String) -> void:
	error_label.text = message


func _apply_accessibility_settings() -> void:
	SettingsService.apply_accessibility(self)
	var scale: float = SettingsService.text_scale
	var dialogue_margin: MarginContainer = $DialogueMargin
	var portrait_area: CenterContainer = $PortraitArea
	dialogue_margin.offset_top = -minf(640.0, 295.0 * scale)
	portrait_area.offset_bottom = -minf(600.0, 260.0 * scale)
	if SettingsService.reduce_motion:
		_reveal_line()
	_update_skip_label()


func _update_skip_label() -> void:
	if not is_instance_valid(skip_button):
		return
	var mode: String = SettingsService.dialogue_skip_mode.capitalize()
	skip_button.text = "Skip: %s%s" % [mode, " (On)" if _skip_active else ""]
