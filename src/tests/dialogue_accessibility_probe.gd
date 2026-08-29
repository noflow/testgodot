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
	var background_image: TextureRect = dialogue.get_node("BackgroundImage")
	var portrait_image: TextureRect = dialogue.get_node("PortraitArea/PortraitCard/PortraitMargin/PortraitLayout/PortraitImage")
	var portrait_area: CenterContainer = dialogue.get_node("PortraitArea")
	var portrait_card: Control = dialogue.get_node("PortraitArea/PortraitCard")
	var transition_overlay: ColorRect = dialogue.get_node("TransitionOverlay")
	var music_player: AudioStreamPlayer = dialogue.get_node("MusicPlayer")
	var ambience_player: AudioStreamPlayer = dialogue.get_node("AmbiencePlayer")
	var sfx_player: AudioStreamPlayer = dialogue.get_node("SfxPlayer")
	var skip: Button = dialogue.get_node("DialogueMargin/DialoguePanel/PanelMargin/DialogueContent/Controls/SkipButton")
	if background_image.texture == null or portrait_image.texture == null:
		_fail("dialogue did not resolve its location background and Elena portrait")
		return
	if not is_equal_approx(ThemeDB.fallback_base_scale, 1.75) or line.visible_characters != -1:
		_fail("175% text or reduced-motion instant line reveal did not apply")
		return
	if line.get_theme_color("font_color") != Color.WHITE or "Toggle" not in skip.text:
		_fail("high contrast or toggle-mode skip did not apply")
		return
	if not _controls_fit(dialogue.get_node("DialogueMargin/DialoguePanel/PanelMargin/DialogueContent/Controls")):
		_fail("175% dialogue utility controls extend outside the viewport")
		return
	dialogue.call("_render_view", {
		"speaker_id": "elena_reyes_hale",
		"speaker_name": "Elena Reyes-Hale",
		"participants": ["elena_reyes_hale", "player"],
		"portrait_id": "default",
		"expression": "warm",
		"background_variant": "",
		"portrait_position": "right",
		"transition": "fade",
		"music_cue": "missing_music_fixture",
		"ambience_cue": "missing_ambience_fixture",
		"sfx_cue": "missing_sfx_fixture",
		"line": "Presentation cues are active.",
		"stage_direction": "",
		"choices": [],
	})
	await get_tree().process_frame
	if not is_equal_approx(portrait_area.anchor_left, 0.44) or not is_equal_approx(portrait_area.anchor_right, 1.0) or not portrait_card.visible:
		_fail("right-position Director cue did not move the visible portrait stage")
		return
	if str(transition_overlay.get_meta("transition", "")) != "fade" or transition_overlay.modulate.a != 0.0:
		_fail("reduced motion did not safely resolve the authored fade transition")
		return
	if str(music_player.get_meta("cue_id", "")) != "missing_music_fixture" or str(ambience_player.get_meta("cue_id", "")) != "missing_ambience_fixture" or str(sfx_player.get_meta("cue_id", "")) != "missing_sfx_fixture":
		_fail("Director audio cue ids did not reach their runtime players")
		return
	if bool(music_player.get_meta("cue_resolved", true)) or bool(ambience_player.get_meta("cue_resolved", true)) or bool(sfx_player.get_meta("cue_resolved", true)):
		_fail("missing Director audio assets did not fail safely without starting playback")
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
	print("PASS: VN dialogue keeps Director staging/audio cues, 175% text, choices, focus contrast, reduced motion, replay, and skip controls usable.")
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
