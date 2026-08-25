extends Control

const CHARACTERS_PER_SECOND: float = 55.0

@onready var scene_title: Label = %SceneTitle
@onready var speaker_label: Label = %SpeakerLabel
@onready var line_label: Label = %LineLabel
@onready var choices_box: VBoxContainer = %ChoicesBox
@onready var continue_button: Button = %ContinueButton
@onready var auto_button: Button = %AutoButton
@onready var history_panel: PanelContainer = %HistoryPanel
@onready var history_text: RichTextLabel = %HistoryText
@onready var error_label: Label = %ErrorLabel

var _full_text: String = ""
var _revealed_characters: float = 0.0
var _auto_enabled: bool = false
var _auto_wait: float = 0.0


func _ready() -> void:
	var resumed: Dictionary = DialogueService.resume()
	if not resumed.get("ok", false):
		_show_error(str(resumed.get("errors", ["No active conversation."])[0]))
		return
	_render_view(resumed["view"])


func _process(delta: float) -> void:
	if line_label.visible_characters < _full_text.length():
		_revealed_characters += CHARACTERS_PER_SECOND * delta
		line_label.visible_characters = mini(int(_revealed_characters), _full_text.length())
		return
	if _auto_enabled and continue_button.visible and not history_panel.visible:
		_auto_wait += delta
		if _auto_wait >= 1.25:
			_auto_wait = 0.0
			_advance_dialogue()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dialogue_history"):
		_toggle_history()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") and continue_button.visible and not history_panel.visible:
		_on_continue_pressed()
		get_viewport().set_input_as_handled()


func _render_view(view: Dictionary) -> void:
	error_label.text = ""
	scene_title.text = "AUGUST 20 • TUESDAY MORNING • PLAYER BEDROOM"
	var stage_direction: String = str(view.get("stage_direction", ""))
	var line: String = str(view.get("line", ""))
	if not stage_direction.is_empty():
		speaker_label.text = "NARRATION"
		_full_text = stage_direction
	else:
		speaker_label.text = str(view.get("speaker_name", "")).to_upper()
		_full_text = line
	line_label.text = _full_text
	line_label.visible_characters = 0
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


func _on_continue_pressed() -> void:
	if line_label.visible_characters < _full_text.length():
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
		get_tree().change_scene_to_file(AppConstants.SANDBOX_SCENE)
		return
	_render_view(result["view"])


func _on_auto_pressed() -> void:
	_auto_enabled = not _auto_enabled
	auto_button.text = "Auto: On" if _auto_enabled else "Auto: Off"
	_auto_wait = 0.0


func _on_skip_pressed() -> void:
	if line_label.visible_characters < _full_text.length():
		_reveal_line()
	elif continue_button.visible:
		_advance_dialogue()


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
