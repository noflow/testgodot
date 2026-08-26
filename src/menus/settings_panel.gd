extends Control

signal closed

@onready var summary: RichTextLabel = %SettingsSummary
@onready var actions: VBoxContainer = %SettingsActions
@onready var status: Label = %SettingsStatus

var _pending_remap_action: String = ""


func _ready() -> void:
	SettingsService.settings_changed.connect(_on_settings_changed)
	visible = false


func _input(event: InputEvent) -> void:
	if not visible or _pending_remap_action.is_empty():
		return
	if event is InputEventKey and not event.pressed:
		return
	if event is InputEventJoypadButton and not event.pressed:
		return
	if event is InputEventJoypadMotion and absf(event.axis_value) < 0.5:
		return
	if not (event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion):
		return
	var action: String = _pending_remap_action
	_pending_remap_action = ""
	if SettingsService.remap_action(action, event):
		var error: Error = SettingsService.save_settings()
		status.text = "%s is now %s." % [SettingsService.action_name(action), SettingsService.binding_label(action)] if error == OK else "The binding could not be saved."
	else:
		status.text = "That input cannot be assigned."
	_render()
	get_viewport().set_input_as_handled()


func open_panel() -> void:
	visible = true
	_pending_remap_action = ""
	status.text = "Settings save automatically on this device."
	_render()
	if actions.get_child_count() > 0:
		actions.get_child(0).grab_focus()


func close_panel() -> void:
	_pending_remap_action = ""
	visible = false
	closed.emit()


func _render() -> void:
	_clear_actions()
	var bindings: PackedStringArray = []
	for action: String in SettingsService.REMAPPABLE_ACTIONS:
		bindings.append("%s: %s" % [SettingsService.action_name(action), SettingsService.binding_label(action)])
	summary.text = "[font_size=24]ACCESSIBILITY[/font_size]\nText %d%% • Reduce motion %s • High contrast %s\nScreen-edge effects %s • Camera shake %s\nDialogue skip %s\n\n[font_size=24]AUDIO[/font_size]\nMaster %d%% • Music %d%% • Ambience %d%%\nUI %d%% • Voice %d%%\n\n[font_size=24]DISPLAY[/font_size]\n%s • %s • VSync %s\n\n[font_size=24]CONTROLS[/font_size]\n%s" % [
		int(SettingsService.text_scale * 100.0), _on_off(SettingsService.reduce_motion), _on_off(SettingsService.high_contrast),
		_on_off(SettingsService.screen_effects_enabled), _on_off(SettingsService.camera_shake_enabled), SettingsService.dialogue_skip_mode.capitalize(),
		int(SettingsService.master_volume * 100.0), int(SettingsService.music_volume * 100.0), int(SettingsService.ambience_volume * 100.0), int(SettingsService.ui_volume * 100.0), int(SettingsService.voice_volume * 100.0),
		SettingsService.display_mode.capitalize(), SettingsService.window_size, _on_off(SettingsService.vsync_enabled), "\n".join(bindings),
	]
	_add_button("Text Size — %d%%" % int(SettingsService.text_scale * 100.0), _cycle_text_size)
	_add_button("Reduce Motion — %s" % _on_off(SettingsService.reduce_motion), _toggle_bool.bind("reduce_motion"))
	_add_button("High Contrast — %s" % _on_off(SettingsService.high_contrast), _toggle_bool.bind("high_contrast"))
	_add_button("Screen-Edge Effects — %s" % _on_off(SettingsService.screen_effects_enabled), _toggle_bool.bind("screen_effects_enabled"))
	_add_button("Camera Shake — %s" % _on_off(SettingsService.camera_shake_enabled), _toggle_bool.bind("camera_shake_enabled"))
	_add_button("Dialogue Skip — %s" % SettingsService.dialogue_skip_mode.capitalize(), _toggle_skip_mode)
	for channel: String in ["master", "music", "ambience", "ui", "voice"]:
		_add_button("%s Volume −" % channel.capitalize(), _adjust_audio.bind(channel, -0.1))
		_add_button("%s Volume +" % channel.capitalize(), _adjust_audio.bind(channel, 0.1))
	_add_button("Display Mode — %s" % SettingsService.display_mode.capitalize(), _cycle_display_mode)
	_add_button("Window Size — %s" % SettingsService.window_size, _cycle_window_size)
	_add_button("VSync — %s" % _on_off(SettingsService.vsync_enabled), _toggle_bool.bind("vsync_enabled"))
	for action: String in SettingsService.REMAPPABLE_ACTIONS:
		_add_button("Remap %s" % SettingsService.action_name(action), _begin_remap.bind(action))
	_add_button("Reset Controls to Defaults", _reset_controls)
	call_deferred("_apply_accessibility")


func _cycle_text_size() -> void:
	var index: int = SettingsService.TEXT_SCALES.find(SettingsService.text_scale)
	SettingsService.text_scale = SettingsService.TEXT_SCALES[posmod(index + 1, SettingsService.TEXT_SCALES.size())]
	_save()


func _toggle_bool(property_name: String) -> void:
	SettingsService.set(property_name, not bool(SettingsService.get(property_name)))
	_save()


func _toggle_skip_mode() -> void:
	SettingsService.dialogue_skip_mode = "toggle" if SettingsService.dialogue_skip_mode == "hold" else "hold"
	_save()


func _adjust_audio(channel: String, amount: float) -> void:
	SettingsService.set_audio_volume(channel, SettingsService.audio_volume(channel) + amount)
	_save()


func _cycle_display_mode() -> void:
	SettingsService.display_mode = "fullscreen" if SettingsService.display_mode == "windowed" else "windowed"
	_save()


func _cycle_window_size() -> void:
	var index: int = SettingsService.WINDOW_SIZES.find(SettingsService.window_size)
	SettingsService.window_size = SettingsService.WINDOW_SIZES[posmod(index + 1, SettingsService.WINDOW_SIZES.size())]
	_save()


func _begin_remap(action: String) -> void:
	_pending_remap_action = action
	status.text = "Press a keyboard key or controller input for %s." % SettingsService.action_name(action)


func _reset_controls() -> void:
	SettingsService.reset_control_bindings()
	_save()


func _save() -> void:
	var error: Error = SettingsService.save_settings()
	status.text = "Settings saved." if error == OK else "Settings could not be saved."
	_render()


func _on_settings_changed() -> void:
	if visible:
		_render()
	_apply_accessibility()


func _apply_accessibility() -> void:
	SettingsService.apply_accessibility(self)


func _add_button(label: String, callback: Callable) -> void:
	var button: Button = Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(0, 42)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(callback)
	actions.add_child(button)


func _clear_actions() -> void:
	for child: Node in actions.get_children():
		actions.remove_child(child)
		child.queue_free()


func _on_off(value: bool) -> String:
	return "On" if value else "Off"
