extends Node

const NewGameStateFactoryScript: GDScript = preload("res://src/core/new_game_state_factory.gd")


func _ready() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	var errors: PackedStringArray = ContentRegistry.validate_foundation()
	if not errors.is_empty():
		_fail("content validation failed")
		return
	var factory: RefCounted = NewGameStateFactoryScript.new(ContentRegistry)
	GameState.replace_state(factory.create_new_game({}, {"random_seed": 911}))
	var begin_result: Dictionary = DialogueService.begin("opening_future_talk")
	if not begin_result.get("ok", false):
		_fail("opening dialogue could not begin")
		return

	var original_scale: float = SettingsService.text_scale
	var original_contrast: bool = SettingsService.high_contrast
	var original_motion: bool = SettingsService.reduce_motion
	var original_skip: String = SettingsService.dialogue_skip_mode
	SettingsService.text_scale = 1.75
	SettingsService.high_contrast = true
	SettingsService.reduce_motion = true
	SettingsService.dialogue_skip_mode = "toggle"

	var scene: PackedScene = load("res://scenes/dialogue/vn_dialogue.tscn")
	var dialogue: Control = scene.instantiate()
	get_tree().root.add_child(dialogue)
	await get_tree().process_frame
	await get_tree().process_frame
	var line: Label = dialogue.get_node("DialogueMargin/DialoguePanel/PanelMargin/DialogueContent/LineLabel")
	var skip: Button = dialogue.get_node("DialogueMargin/DialoguePanel/PanelMargin/DialogueContent/Controls/SkipButton")
	if not is_equal_approx(ThemeDB.fallback_base_scale, 1.75) or line.visible_characters != -1:
		_fail("175% text or reduced-motion instant line reveal did not apply")
		return
	if line.get_theme_color("font_color") != Color.WHITE or "Toggle" not in skip.text:
		_fail("high contrast or toggle-mode skip did not apply")
		return
	if not _controls_fit(dialogue.get_node("DialogueMargin/DialoguePanel/PanelMargin/DialogueContent/Controls")):
		_fail("175% dialogue utility controls extend outside the viewport")
		return

	dialogue.call("_on_continue_pressed")
	await get_tree().process_frame
	dialogue.call("_on_continue_pressed")
	await get_tree().process_frame
	var choices: Container = dialogue.get_node("DialogueMargin/DialoguePanel/PanelMargin/DialogueContent/ChoicesBox")
	if choices.get_child_count() < 2:
		_fail("175%% authored dialogue choices are missing (found %d)" % choices.get_child_count())
		return
	if not _controls_fit(choices):
		for child: Node in choices.get_children():
			if child is Control:
				printerr("PROBE BOUNDS: %s %s viewport %s" % [child.name, child.get_global_rect(), get_viewport().get_visible_rect()])
		_fail("175% authored dialogue choices extend outside the viewport")
		return
	dialogue.call("_on_skip_button_down")
	if "(On)" not in skip.text:
		_fail("toggle-mode dialogue skip did not remain active after release")
		return
	dialogue.call("_on_skip_button_down")
	SettingsService.reduce_motion = false
	dialogue.call("_on_replay_pressed")
	if line.visible_characters != 0:
		_fail("replay-current-line did not restart the visible line")
		return
	SettingsService.reduce_motion = true

	SettingsService.text_scale = original_scale
	SettingsService.high_contrast = original_contrast
	SettingsService.reduce_motion = original_motion
	SettingsService.dialogue_skip_mode = original_skip
	print("PASS: VN dialogue keeps 175% text, choices, focus contrast, reduced motion, replay, and skip controls usable.")
	get_tree().quit(0)


func _controls_fit(container: Container) -> bool:
	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	for child: Node in container.get_children():
		if child is Control and child.visible:
			var rect: Rect2 = child.get_global_rect()
			if rect.position.x < viewport_rect.position.x or rect.position.y < viewport_rect.position.y:
				return false
			if rect.end.x > viewport_rect.end.x + 0.5 or rect.end.y > viewport_rect.end.y + 0.5:
				return false
	return true


func _fail(message: String) -> void:
	printerr("PROBE: %s" % message)
	get_tree().quit(1)
