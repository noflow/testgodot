extends Control

@onready var background_image: TextureRect = %BackgroundImage
@onready var location_option: OptionButton = %LocationOption
@onready var room_option: OptionButton = %RoomOption
@onready var variant_option: OptionButton = %VariantOption
@onready var title_label: Label = %TitleLabel
@onready var counter_label: Label = %CounterLabel
@onready var path_label: Label = %PathLabel
@onready var status_label: Label = %StatusLabel
@onready var previous_button: Button = %PreviousButton
@onready var next_button: Button = %NextButton

var _backgrounds: Array = []
var _location_ids: PackedStringArray = []
var _current_index: int = 0
var _syncing_selectors: bool = false


func _ready() -> void:
	if not SettingsService.settings_changed.is_connected(_apply_accessibility_settings):
		SettingsService.settings_changed.connect(_apply_accessibility_settings)
	_collect_backgrounds()
	_populate_location_options()
	variant_option.add_item("Day")
	variant_option.set_item_metadata(0, "day")
	variant_option.add_item("Night")
	variant_option.set_item_metadata(1, "night")
	variant_option.select(0)
	if _backgrounds.is_empty():
		_show_empty_state()
	else:
		_show_index(0)
	_apply_accessibility_settings()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()


func _collect_backgrounds() -> void:
	_backgrounds.clear()
	_location_ids.clear()
	for value: Variant in ContentRegistry.get_all("vn_backgrounds"):
		if not value is Dictionary:
			continue
		var background: Dictionary = value
		if str(background.get("status", "")) != "ready":
			continue
		var location_id: String = str(background.get("location", ""))
		var room_id: String = str(background.get("room", ""))
		if location_id.is_empty() or room_id.is_empty():
			continue
		_backgrounds.append(background)
		if location_id not in _location_ids:
			_location_ids.append(location_id)


func _populate_location_options() -> void:
	location_option.clear()
	for location_id: String in _location_ids:
		location_option.add_item(_location_name(location_id))
		location_option.set_item_metadata(location_option.item_count - 1, location_id)


func _populate_room_options(location_id: String) -> void:
	room_option.clear()
	for index: int in _backgrounds.size():
		var background: Dictionary = _backgrounds[index]
		if str(background.get("location", "")) != location_id:
			continue
		var room_id: String = str(background.get("room", ""))
		room_option.add_item(_room_name(location_id, room_id))
		room_option.set_item_metadata(room_option.item_count - 1, index)


func _show_index(index: int) -> void:
	if _backgrounds.is_empty():
		_show_empty_state()
		return
	_current_index = posmod(index, _backgrounds.size())
	var background: Dictionary = _backgrounds[_current_index]
	var location_id: String = str(background.get("location", ""))
	var room_id: String = str(background.get("room", ""))
	_syncing_selectors = true
	_select_location_option(location_id)
	_populate_room_options(location_id)
	_select_room_option(_current_index)
	_syncing_selectors = false

	var variant: String = str(variant_option.get_selected_metadata())
	var resolved: Dictionary = VNAssetService.resolve_background(location_id, room_id, variant)
	background_image.texture = resolved.get("texture")
	background_image.visible = background_image.texture != null
	title_label.text = "%s  •  %s" % [_location_name(location_id), _room_name(location_id, room_id)]
	counter_label.text = "%d / %d" % [_current_index + 1, _backgrounds.size()]
	path_label.text = str(resolved.get("path", background.get("path", "")))
	if bool(resolved.get("used_fallback", false)):
		status_label.text = "Fallback displayed — production asset could not load."
	elif str(resolved.get("resolved_variant", "base")) != variant:
		status_label.text = "%s variant unavailable — showing base/day background." % variant.capitalize()
	else:
		status_label.text = "%s background loaded" % variant.capitalize()
	previous_button.disabled = _backgrounds.size() < 2
	next_button.disabled = _backgrounds.size() < 2


func _select_location_option(location_id: String) -> void:
	for index: int in location_option.item_count:
		if str(location_option.get_item_metadata(index)) == location_id:
			location_option.select(index)
			return


func _select_room_option(background_index: int) -> void:
	for index: int in room_option.item_count:
		if int(room_option.get_item_metadata(index)) == background_index:
			room_option.select(index)
			return


func _on_location_selected(index: int) -> void:
	if _syncing_selectors or index < 0:
		return
	var location_id: String = str(location_option.get_item_metadata(index))
	for background_index: int in _backgrounds.size():
		if str(_backgrounds[background_index].get("location", "")) == location_id:
			_show_index(background_index)
			return


func _on_room_selected(index: int) -> void:
	if _syncing_selectors or index < 0:
		return
	_show_index(int(room_option.get_item_metadata(index)))


func _on_variant_selected(index: int) -> void:
	if index >= 0:
		_show_index(_current_index)


func _on_previous_pressed() -> void:
	_show_index(_current_index - 1)


func _on_next_pressed() -> void:
	_show_index(_current_index + 1)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(AppConstants.MAIN_MENU_SCENE)


func _location_name(location_id: String) -> String:
	var location: Variant = ContentRegistry.get_location(location_id)
	return str(location.get("name", location_id.replace("_", " ").capitalize())) if location is Dictionary else location_id.replace("_", " ").capitalize()


func _room_name(location_id: String, room_id: String) -> String:
	var location: Variant = ContentRegistry.get_location(location_id)
	if location is Dictionary:
		for room_value: Variant in location.get("rooms", []):
			if room_value is Dictionary and str(room_value.get("id", "")) == room_id:
				return str(room_value.get("name", room_id.replace("_", " ").capitalize()))
	return room_id.replace("_", " ").capitalize()


func _show_empty_state() -> void:
	background_image.visible = false
	title_label.text = "NO PRODUCTION BACKGROUNDS"
	counter_label.text = "0 / 0"
	path_label.text = "The VN artwork registry is empty."
	status_label.text = "No backgrounds available"
	previous_button.disabled = true
	next_button.disabled = true


func _apply_accessibility_settings() -> void:
	SettingsService.apply_accessibility(self)
