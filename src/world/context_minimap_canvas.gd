extends Control
class_name PortAlderContextMinimapCanvas

const CURRENT_FILL: Color = Color("2d7777")
const ROOM_FILL: Color = Color("18363f")
const DESTINATION_FILL: Color = Color("3b3844")
const LOCKED_FILL: Color = Color("342f35")
const CURRENT_BORDER: Color = Color("e9a86c")
const ROOM_BORDER: Color = Color("67c6c3")
const LOCKED_BORDER: Color = Color("867b82")
const CONNECTION_COLOR: Color = Color(0.55, 0.75, 0.74, 0.78)
const TEXT_COLOR: Color = Color("eff8f7")
const MUTED_TEXT_COLOR: Color = Color("c0c9c8")

var _nodes: Array = []
var _edges: Array = []


func set_map_data(nodes: Array, edges: Array) -> void:
	_nodes = nodes.duplicate(true)
	_edges = edges.duplicate(true)
	queue_redraw()


func map_nodes() -> Array:
	return _nodes.duplicate(true)


func map_edges() -> Array:
	return _edges.duplicate(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if _nodes.is_empty():
		_draw_centered_text("No local map data is available.", Rect2(Vector2.ZERO, size), 16, MUTED_TEXT_COLOR)
		return
	var node_rects: Dictionary = _calculate_node_rects()
	for edge_value: Variant in _edges:
		if not edge_value is Dictionary:
			continue
		var edge: Dictionary = edge_value
		var from_id: String = str(edge.get("from", ""))
		var to_id: String = str(edge.get("to", ""))
		if not node_rects.has(from_id) or not node_rects.has(to_id):
			continue
		var start: Vector2 = (node_rects[from_id] as Rect2).get_center()
		var finish: Vector2 = (node_rects[to_id] as Rect2).get_center()
		draw_line(start, finish, CONNECTION_COLOR, 3.0, true)
		_draw_arrow_head(start, finish)
	for node_value: Variant in _nodes:
		if not node_value is Dictionary:
			continue
		var node: Dictionary = node_value
		var node_id: String = str(node.get("id", ""))
		if not node_rects.has(node_id):
			continue
		_draw_node(node_rects[node_id], node)


func _calculate_node_rects() -> Dictionary:
	var minimum: Vector2 = Vector2(INF, INF)
	var maximum: Vector2 = Vector2(-INF, -INF)
	for node_value: Variant in _nodes:
		if not node_value is Dictionary:
			continue
		var point: Vector2 = node_value.get("position", Vector2.ZERO)
		minimum.x = minf(minimum.x, point.x)
		minimum.y = minf(minimum.y, point.y)
		maximum.x = maxf(maximum.x, point.x)
		maximum.y = maxf(maximum.y, point.y)
	var columns: float = maxf(maximum.x - minimum.x + 1.0, 1.0)
	var rows: float = maxf(maximum.y - minimum.y + 1.0, 1.0)
	var available: Rect2 = Rect2(Vector2(24, 18), Vector2(maxf(size.x - 48.0, 1.0), maxf(size.y - 36.0, 1.0)))
	var cell_width: float = available.size.x / columns
	var cell_height: float = available.size.y / rows
	var node_width: float = clampf(cell_width * 0.78, 82.0, 174.0)
	var node_height: float = clampf(cell_height * 0.62, 48.0, 68.0)
	var result: Dictionary = {}
	for node_value: Variant in _nodes:
		if not node_value is Dictionary:
			continue
		var node: Dictionary = node_value
		var point: Vector2 = node.get("position", Vector2.ZERO)
		var center: Vector2 = Vector2(
			available.position.x + (point.x - minimum.x + 0.5) * cell_width,
			available.position.y + (point.y - minimum.y + 0.5) * cell_height
		)
		result[str(node.get("id", ""))] = Rect2(center - Vector2(node_width, node_height) * 0.5, Vector2(node_width, node_height))
	return result


func _draw_node(rect: Rect2, node: Dictionary) -> void:
	var current: bool = bool(node.get("current", false))
	var locked: bool = bool(node.get("locked", false))
	var destination: bool = str(node.get("kind", "room")) == "destination"
	var fill: Color = CURRENT_FILL if current else (LOCKED_FILL if locked else (DESTINATION_FILL if destination else ROOM_FILL))
	var border: Color = CURRENT_BORDER if current else (LOCKED_BORDER if locked else ROOM_BORDER)
	draw_style_box(_node_style(fill, border, 3 if current else 2), rect)
	var label: String = str(node.get("label", node.get("id", "Area")))
	var lines: PackedStringArray = _wrapped_lines(label, 20)
	if current:
		lines.insert(0, "YOU ARE HERE")
	elif locked:
		lines.append("LOCKED")
	var line_height: float = 15.0
	var start_y: float = rect.get_center().y - (float(lines.size()) * line_height) * 0.5 + 11.0
	for index: int in lines.size():
		var color: Color = CURRENT_BORDER if current and index == 0 else (MUTED_TEXT_COLOR if locked and index == lines.size() - 1 else TEXT_COLOR)
		_draw_centered_line(lines[index], rect.position.x + 5.0, start_y + float(index) * line_height, rect.size.x - 10.0, 12, color)


func _node_style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(7)
	return style


func _draw_arrow_head(start: Vector2, finish: Vector2) -> void:
	var vector: Vector2 = finish - start
	if vector.length() < 4.0:
		return
	var direction: Vector2 = vector.normalized()
	var center: Vector2 = start.lerp(finish, 0.58)
	var side: Vector2 = Vector2(-direction.y, direction.x)
	var points: PackedVector2Array = PackedVector2Array([
		center + direction * 6.0,
		center - direction * 5.0 + side * 4.0,
		center - direction * 5.0 - side * 4.0,
	])
	draw_colored_polygon(points, CONNECTION_COLOR)


func _wrapped_lines(text: String, maximum_characters: int) -> PackedStringArray:
	var words: PackedStringArray = text.replace("\n", " \n ").split(" ", false)
	var lines: PackedStringArray = []
	var current: String = ""
	for word: String in words:
		if word == "\n":
			if not current.is_empty():
				lines.append(current)
				current = ""
			continue
		var candidate: String = word if current.is_empty() else "%s %s" % [current, word]
		if candidate.length() > maximum_characters and not current.is_empty():
			lines.append(current)
			current = word
		else:
			current = candidate
	if not current.is_empty():
		lines.append(current)
	if lines.size() > 2:
		lines = PackedStringArray([lines[0], "%s…" % lines[1].left(maximum_characters - 1)])
	return lines


func _draw_centered_text(text: String, rect: Rect2, font_size: int, color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var position: Vector2 = Vector2(rect.get_center().x - width * 0.5, rect.get_center().y + float(font_size) * 0.35)
	draw_string(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_centered_line(text: String, left: float, baseline: float, width: float, font_size: int, color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, Vector2(left + maxf((width - text_width) * 0.5, 0.0), baseline), text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)
