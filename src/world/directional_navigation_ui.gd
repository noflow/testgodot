extends Control
class_name PortAlderDirectionalNavigationUI

signal direction_requested(direction: String)

const DIRECTIONS: PackedStringArray = ["left", "up", "right", "down"]
const SYMBOLS: Dictionary = {
	"left": "◀",
	"up": "▲",
	"right": "▶",
	"down": "▼",
}

@onready var previous_room_arrow: Button = %PrevRoomArrow
@onready var outside_arrow: Button = %OutsideArrow
@onready var next_room_arrow: Button = %NextRoomArrow
@onready var down_room_arrow: Button = %DownRoomArrow
@onready var context_minimap: PortAlderContextMinimap = %ContextMiniMap

var _buttons: Dictionary = {}


func _ready() -> void:
	_buttons = {
		"left": previous_room_arrow,
		"up": outside_arrow,
		"right": next_room_arrow,
		"down": down_room_arrow,
	}
	for direction: String in DIRECTIONS:
		var button: Button = _buttons[direction]
		button.pressed.connect(_on_button_pressed.bind(direction))
	clear_all()
	refresh_accessibility()


func configure_destination(direction: String, destination_label: String, action_label: String = "Move to") -> void:
	var button: Button = button_for_direction(direction)
	if button == null:
		return
	var clean_label: String = destination_label.strip_edges()
	var has_destination: bool = not clean_label.is_empty()
	button.visible = has_destination
	button.disabled = not has_destination
	if not has_destination:
		button.text = ""
		button.tooltip_text = ""
		button.remove_meta("destination_label")
		return
	button.text = _button_text(direction, clean_label)
	button.tooltip_text = "%s %s" % [action_label, clean_label]
	button.set_meta("destination_label", clean_label)
	_fit_button_to_label(direction, button)


func clear_direction(direction: String) -> void:
	configure_destination(direction, "")


func clear_all() -> void:
	for direction: String in DIRECTIONS:
		clear_direction(direction)


func refresh_accessibility() -> void:
	for direction: String in DIRECTIONS:
		var button: Button = button_for_direction(direction)
		if button != null:
			SettingsService.apply_accessibility(button)
	context_minimap.refresh_accessibility()


func configure_minimap(location_id: String, current_room_id: String, navigation_override: Dictionary = {}, options: Dictionary = {}) -> void:
	context_minimap.configure_map(location_id, current_room_id, navigation_override, options)


func toggle_minimap() -> void:
	context_minimap.toggle_map()


func open_minimap() -> void:
	context_minimap.open_map()


func close_minimap() -> void:
	context_minimap.close_map()


func is_minimap_open() -> bool:
	return context_minimap.is_open()


func minimap_node_ids() -> PackedStringArray:
	return context_minimap.node_ids()


func minimap_nodes() -> Array:
	return context_minimap.map_nodes()


func minimap_edges() -> Array:
	return context_minimap.map_edges()


func button_for_direction(direction: String) -> Button:
	return _buttons.get(direction) as Button


func visible_directions() -> PackedStringArray:
	var visible: PackedStringArray = []
	for direction: String in DIRECTIONS:
		var button: Button = button_for_direction(direction)
		if button != null and button.visible and not button.disabled:
			visible.append(direction)
	return visible


func _button_text(direction: String, destination_label: String) -> String:
	if direction == "right":
		return "%s  %s" % [destination_label, SYMBOLS[direction]]
	return "%s  %s" % [SYMBOLS.get(direction, ""), destination_label]


func _fit_button_to_label(direction: String, button: Button) -> void:
	var font: Font = button.get_theme_font("font")
	var font_size: int = button.get_theme_font_size("font_size")
	var text_width: float = font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var width: float = clampf(ceilf(text_width) + 18.0, 52.0, 190.0)
	match direction:
		"up":
			button.offset_left = -width * 0.5
			button.offset_top = 10.0
			button.offset_right = width * 0.5
			button.offset_bottom = 42.0
		"left":
			button.offset_left = 10.0
			button.offset_top = -16.0
			button.offset_right = 10.0 + width
			button.offset_bottom = 16.0
		"right":
			button.offset_left = -10.0 - width
			button.offset_top = -16.0
			button.offset_right = -10.0
			button.offset_bottom = 16.0
		"down":
			button.offset_left = -width * 0.5
			button.offset_top = -42.0
			button.offset_right = width * 0.5
			button.offset_bottom = -10.0


func _on_button_pressed(direction: String) -> void:
	direction_requested.emit(direction)
