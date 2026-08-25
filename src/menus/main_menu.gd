extends Control

@onready var continue_button: Button = %ContinueButton
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	continue_button.disabled = not _has_valid_save()
	%NewGameButton.grab_focus()


func _has_valid_save() -> bool:
	return FileAccess.file_exists("user://saves/autosave_0/save.json")


func _on_new_game_pressed() -> void:
	var state: Dictionary = GameState.start_new_game()
	if state.is_empty():
		_show_foundation_message("New game could not be created. Check Content for errors.")
		return
	var result: Dictionary = DialogueService.begin("opening_future_talk")
	if not result.get("ok", false):
		_show_foundation_message("Opening scene could not start: %s" % result.get("errors", ["Unknown error"])[0])
		return
	get_tree().change_scene_to_file(AppConstants.VN_DIALOGUE_SCENE)


func _on_continue_pressed() -> void:
	_show_foundation_message("Runtime loading arrives in Phase 1.")


func _on_load_game_pressed() -> void:
	_show_foundation_message("Save slots arrive in Phase 6.")


func _on_settings_pressed() -> void:
	_show_foundation_message("Settings data is active; the full screen arrives with the phone UI.")


func _on_content_pressed() -> void:
	var document_count: int = ContentRegistry.get_document_count()
	_show_foundation_message("Validated %d foundation and character documents." % document_count)


func _on_credits_pressed() -> void:
	_show_foundation_message("Port Alder Life Sim — First Week Foundations")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _show_foundation_message(message: String) -> void:
	status_label.text = message
