extends Control

@onready var continue_button: Button = %ContinueButton
@onready var status_label: Label = %StatusLabel
@onready var load_panel: PanelContainer = %LoadPanel
@onready var save_list: VBoxContainer = %SaveList
@onready var load_status: Label = %LoadStatus
@onready var settings_panel: Control = %SettingsPanel


func _ready() -> void:
	SettingsService.settings_changed.connect(_apply_accessibility_settings)
	SettingsService.apply_accessibility(self)
	settings_panel.closed.connect(_on_settings_closed)
	continue_button.disabled = not SaveService.has_valid_save()
	%NewGameButton.grab_focus()


func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file(AppConstants.CHARACTER_CREATION_SCENE)


func _on_continue_pressed() -> void:
	var result: Dictionary = SaveService.load_latest()
	if not result.get("ok", false):
		_show_foundation_message(_first_error(result))
		continue_button.disabled = not SaveService.has_valid_save()
		return
	_resume_loaded_game()


func _on_load_game_pressed() -> void:
	_render_load_panel()
	load_panel.visible = true


func _on_settings_pressed() -> void:
	settings_panel.open_panel()


func _on_content_pressed() -> void:
	var document_count: int = ContentRegistry.get_document_count()
	_show_foundation_message("Validated %d foundation and character documents." % document_count)


func _on_background_gallery_pressed() -> void:
	get_tree().change_scene_to_file(AppConstants.BACKGROUND_GALLERY_SCENE)


func _on_credits_pressed() -> void:
	_show_foundation_message("Port Alder Life Sim — First Week Foundations")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _show_foundation_message(message: String) -> void:
	status_label.text = message


func _render_load_panel() -> void:
	for child: Node in save_list.get_children():
		save_list.remove_child(child)
		child.queue_free()
	var summaries: Array = SaveService.list_saves()
	load_status.text = "Select a save. Invalid files are left untouched and are not shown." if not summaries.is_empty() else "No valid saves are available yet."
	for summary_value: Variant in summaries:
		if not summary_value is Dictionary:
			continue
		var summary: Dictionary = summary_value
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(0, 78)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = "%s\n%s" % [
			SaveService.slot_label(str(summary.get("slot_id", ""))),
			SaveService.format_summary(summary, true),
		]
		button.pressed.connect(_load_selected_slot.bind(str(summary.get("slot_id", ""))))
		save_list.add_child(button)
	if save_list.get_child_count() > 0:
		save_list.get_child(0).grab_focus()


func _load_selected_slot(slot_id: String) -> void:
	var result: Dictionary = SaveService.load_slot(slot_id)
	if not result.get("ok", false):
		load_status.text = _first_error(result)
		return
	_resume_loaded_game()


func _resume_loaded_game() -> void:
	get_tree().change_scene_to_file(SaveService.resume_scene_path())


func _on_close_load_pressed() -> void:
	load_panel.visible = false
	%LoadGameButton.grab_focus()


func _on_settings_closed() -> void:
	%SettingsButton.grab_focus()


func _apply_accessibility_settings() -> void:
	SettingsService.apply_accessibility(self)


func _first_error(result: Dictionary) -> String:
	var errors: Variant = result.get("errors", [])
	if (errors is Array or errors is PackedStringArray) and not errors.is_empty():
		return str(errors[0])
	return "The save could not be loaded."
