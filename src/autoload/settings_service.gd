extends Node

signal settings_changed

const SETTINGS_PATH: String = "user://settings.cfg"
const TEXT_SCALES: Array = [1.0, 1.25, 1.5, 1.75]
const WINDOW_SIZES: PackedStringArray = ["1280x720", "1600x900", "1920x1080"]
const REMAPPABLE_ACTIONS: PackedStringArray = [
	"interact", "cancel", "phone",
	"quest_tracker", "city_map", "dialogue_history", "dialogue_skip", "pause", "quicksave", "quickload",
]

var text_scale: float = 1.0
var reduce_motion: bool = false
var high_contrast: bool = false
var screen_effects_enabled: bool = true
var camera_shake_enabled: bool = true
var dialogue_skip_mode: String = "hold"
var master_volume: float = 1.0
var music_volume: float = 0.8
var ambience_volume: float = 0.8
var ui_volume: float = 0.9
var voice_volume: float = 1.0
var display_mode: String = "windowed"
var window_size: String = "1280x720"
var vsync_enabled: bool = true

var _default_bindings: Dictionary = {}


func _ready() -> void:
	_capture_default_bindings()
	load_settings()
	apply_all()


func load_settings(path: String = SETTINGS_PATH) -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(path) != OK:
		return
	text_scale = _nearest_text_scale(float(config.get_value("accessibility", "text_scale", 1.0)))
	reduce_motion = bool(config.get_value("accessibility", "reduce_motion", false))
	high_contrast = bool(config.get_value("accessibility", "high_contrast", false))
	screen_effects_enabled = bool(config.get_value("accessibility", "screen_effects_enabled", true))
	camera_shake_enabled = bool(config.get_value("accessibility", "camera_shake_enabled", true))
	dialogue_skip_mode = str(config.get_value("accessibility", "dialogue_skip_mode", "hold"))
	if dialogue_skip_mode not in ["hold", "toggle"]:
		dialogue_skip_mode = "hold"
	master_volume = clampf(float(config.get_value("audio", "master", 1.0)), 0.0, 1.0)
	music_volume = clampf(float(config.get_value("audio", "music", 0.8)), 0.0, 1.0)
	ambience_volume = clampf(float(config.get_value("audio", "ambience", 0.8)), 0.0, 1.0)
	ui_volume = clampf(float(config.get_value("audio", "ui", 0.9)), 0.0, 1.0)
	voice_volume = clampf(float(config.get_value("audio", "voice", 1.0)), 0.0, 1.0)
	display_mode = str(config.get_value("display", "mode", "windowed"))
	if display_mode not in ["windowed", "fullscreen"]:
		display_mode = "windowed"
	window_size = str(config.get_value("display", "window_size", "1280x720"))
	if window_size not in WINDOW_SIZES:
		window_size = "1280x720"
	vsync_enabled = bool(config.get_value("display", "vsync", true))
	_load_control_bindings(config)


func save_settings(path: String = SETTINGS_PATH) -> Error:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("accessibility", "text_scale", text_scale)
	config.set_value("accessibility", "reduce_motion", reduce_motion)
	config.set_value("accessibility", "high_contrast", high_contrast)
	config.set_value("accessibility", "screen_effects_enabled", screen_effects_enabled)
	config.set_value("accessibility", "camera_shake_enabled", camera_shake_enabled)
	config.set_value("accessibility", "dialogue_skip_mode", dialogue_skip_mode)
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "ambience", ambience_volume)
	config.set_value("audio", "ui", ui_volume)
	config.set_value("audio", "voice", voice_volume)
	config.set_value("display", "mode", display_mode)
	config.set_value("display", "window_size", window_size)
	config.set_value("display", "vsync", vsync_enabled)
	for action: String in REMAPPABLE_ACTIONS:
		var serialized: Array = []
		for event: InputEvent in InputMap.action_get_events(action):
			var entry: Dictionary = _serialize_event(event)
			if not entry.is_empty():
				serialized.append(entry)
		config.set_value("controls", action, serialized)
	var error: Error = config.save(path)
	if error == OK:
		apply_all()
		settings_changed.emit()
	return error


func apply_all() -> void:
	ThemeDB.fallback_base_scale = text_scale
	apply_audio_settings()
	apply_display_settings()


func apply_audio_settings() -> void:
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("Ambience", ambience_volume)
	_set_bus_volume("UI", ui_volume)
	_set_bus_volume("Voice", voice_volume)


func apply_display_settings() -> void:
	if DisplayServer.get_name().to_lower() == "headless":
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED)
	if display_mode == "fullscreen":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var parts: PackedStringArray = window_size.split("x")
	if parts.size() == 2:
		DisplayServer.window_set_size(Vector2i(int(parts[0]), int(parts[1])))


func apply_accessibility(root: Node) -> void:
	ThemeDB.fallback_base_scale = text_scale
	_apply_accessibility_node(root)


func set_audio_volume(channel: String, value: float) -> bool:
	value = clampf(value, 0.0, 1.0)
	match channel:
		"master": master_volume = value
		"music": music_volume = value
		"ambience": ambience_volume = value
		"ui": ui_volume = value
		"voice": voice_volume = value
		_: return false
	return true


func audio_volume(channel: String) -> float:
	match channel:
		"master": return master_volume
		"music": return music_volume
		"ambience": return ambience_volume
		"ui": return ui_volume
		"voice": return voice_volume
	return 0.0


func remap_action(action: String, event: InputEvent) -> bool:
	if action not in REMAPPABLE_ACTIONS or not InputMap.has_action(action):
		return false
	if not (event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion):
		return false
	for existing: InputEvent in InputMap.action_get_events(action):
		if _same_device_family(existing, event):
			InputMap.action_erase_event(action, existing)
	InputMap.action_add_event(action, event.duplicate())
	return true


func reset_control_bindings() -> void:
	for action: String in REMAPPABLE_ACTIONS:
		if not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		for event: InputEvent in _default_bindings.get(action, []):
			InputMap.action_add_event(action, event.duplicate())


func binding_label(action: String) -> String:
	var labels: PackedStringArray = []
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			labels.append(event.as_text_physical_keycode() if event.physical_keycode != 0 else event.as_text_keycode())
		elif event is InputEventJoypadButton:
			labels.append("Controller Button %d" % (event.button_index + 1))
		elif event is InputEventJoypadMotion:
			labels.append("Controller Axis %d %s" % [event.axis + 1, "+" if event.axis_value > 0 else "−"])
	return " / ".join(labels) if not labels.is_empty() else "Unbound"


func action_name(action: String) -> String:
	return action.replace("_", " ").capitalize()


func _apply_accessibility_node(node: Node) -> void:
	if node is Camera2D:
		if not node.has_meta("port_alder_smoothing_default"):
			node.set_meta("port_alder_smoothing_default", node.position_smoothing_enabled)
		node.position_smoothing_enabled = bool(node.get_meta("port_alder_smoothing_default")) and not reduce_motion
	if node is Label or node is Button or node is OptionButton or node is LineEdit or node is CheckBox:
		_apply_contrast_color(node, "font_color", high_contrast)
	if node is RichTextLabel:
		_apply_contrast_color(node, "default_color", high_contrast)
	if node is PanelContainer:
		_apply_contrast_panel(node, high_contrast)
	if node is BaseButton:
		_apply_focus_style(node, high_contrast)
	for child: Node in node.get_children():
		_apply_accessibility_node(child)


func _apply_contrast_color(control: Control, color_name: StringName, enabled: bool) -> void:
	var metadata_key: String = "port_alder_color_%s" % color_name
	if not control.has_meta(metadata_key):
		control.set_meta(metadata_key, {"had_override": control.has_theme_color_override(color_name), "value": control.get_theme_color(color_name)})
	var original: Dictionary = control.get_meta(metadata_key)
	if enabled:
		control.add_theme_color_override(color_name, Color("ffffff"))
	elif bool(original.get("had_override", false)):
		control.add_theme_color_override(color_name, original.get("value", Color.WHITE))
	else:
		control.remove_theme_color_override(color_name)


func _apply_contrast_panel(panel: PanelContainer, enabled: bool) -> void:
	const META_KEY: String = "port_alder_panel_style"
	if not panel.has_meta(META_KEY):
		panel.set_meta(META_KEY, {"had_override": panel.has_theme_stylebox_override("panel"), "value": panel.get_theme_stylebox("panel").duplicate()})
	var original: Dictionary = panel.get_meta(META_KEY)
	if enabled:
		var style: StyleBox = original.get("value").duplicate()
		if style is StyleBoxFlat:
			style.bg_color = Color("000000")
			style.border_color = Color("ffffff")
			style.border_width_left = maxi(style.border_width_left, 2)
			style.border_width_top = maxi(style.border_width_top, 2)
			style.border_width_right = maxi(style.border_width_right, 2)
			style.border_width_bottom = maxi(style.border_width_bottom, 2)
		panel.add_theme_stylebox_override("panel", style)
	elif bool(original.get("had_override", false)):
		panel.add_theme_stylebox_override("panel", original.get("value").duplicate())
	else:
		panel.remove_theme_stylebox_override("panel")


func _apply_focus_style(button: BaseButton, enabled: bool) -> void:
	const META_KEY: String = "port_alder_focus_style"
	if not button.has_meta(META_KEY):
		button.set_meta(META_KEY, {"had_override": button.has_theme_stylebox_override("focus"), "value": button.get_theme_stylebox("focus").duplicate()})
	var original: Dictionary = button.get_meta(META_KEY)
	if enabled:
		var focus: StyleBoxFlat = StyleBoxFlat.new()
		focus.bg_color = Color(0, 0, 0, 0)
		focus.border_color = Color("ffe36e")
		focus.set_border_width_all(4)
		focus.set_expand_margin_all(2.0)
		button.add_theme_stylebox_override("focus", focus)
	elif bool(original.get("had_override", false)):
		button.add_theme_stylebox_override("focus", original.get("value").duplicate())
	else:
		button.remove_theme_stylebox_override("focus")


func _capture_default_bindings() -> void:
	for action: String in REMAPPABLE_ACTIONS:
		var events: Array = []
		if InputMap.has_action(action):
			for event: InputEvent in InputMap.action_get_events(action):
				events.append(event.duplicate())
		_default_bindings[action] = events


func _load_control_bindings(config: ConfigFile) -> void:
	for action: String in REMAPPABLE_ACTIONS:
		if not InputMap.has_action(action) or not config.has_section_key("controls", action):
			continue
		var entries: Variant = config.get_value("controls", action, [])
		if not entries is Array:
			continue
		var events: Array = []
		for entry: Variant in entries:
			if entry is Dictionary:
				var event: InputEvent = _deserialize_event(entry)
				if event != null:
					events.append(event)
		if events.is_empty():
			continue
		InputMap.action_erase_events(action)
		for event: InputEvent in events:
			InputMap.action_add_event(action, event)


func _serialize_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {"type": "key", "keycode": event.keycode, "physical_keycode": event.physical_keycode, "shift": event.shift_pressed, "ctrl": event.ctrl_pressed, "alt": event.alt_pressed, "meta": event.meta_pressed}
	if event is InputEventJoypadButton:
		return {"type": "joy_button", "button": event.button_index}
	if event is InputEventJoypadMotion:
		return {"type": "joy_motion", "axis": event.axis, "value": event.axis_value}
	return {}


func _deserialize_event(entry: Dictionary) -> InputEvent:
	match str(entry.get("type", "")):
		"key":
			var key: InputEventKey = InputEventKey.new()
			key.keycode = int(entry.get("keycode", 0))
			key.physical_keycode = int(entry.get("physical_keycode", 0))
			key.shift_pressed = bool(entry.get("shift", false))
			key.ctrl_pressed = bool(entry.get("ctrl", false))
			key.alt_pressed = bool(entry.get("alt", false))
			key.meta_pressed = bool(entry.get("meta", false))
			return key
		"joy_button":
			var button: InputEventJoypadButton = InputEventJoypadButton.new()
			button.button_index = int(entry.get("button", 0))
			return button
		"joy_motion":
			var motion: InputEventJoypadMotion = InputEventJoypadMotion.new()
			motion.axis = int(entry.get("axis", 0))
			motion.axis_value = float(entry.get("value", 0.0))
			return motion
	return null


func _same_device_family(left: InputEvent, right: InputEvent) -> bool:
	if left is InputEventKey and right is InputEventKey:
		return true
	return (left is InputEventJoypadButton or left is InputEventJoypadMotion) and (right is InputEventJoypadButton or right is InputEventJoypadMotion)


func _nearest_text_scale(value: float) -> float:
	var nearest: float = 1.0
	var distance: float = INF
	for option: float in TEXT_SCALES:
		if absf(option - value) < distance:
			nearest = option
			distance = absf(option - value)
	return nearest


func _set_bus_volume(bus_name: String, linear_volume: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(linear_volume, 0.0001)))
	AudioServer.set_bus_mute(bus_index, linear_volume <= 0.0)
