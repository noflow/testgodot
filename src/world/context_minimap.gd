extends Control
class_name PortAlderContextMinimap

const NavigationAccessScript: GDScript = preload("res://src/world/navigation_access.gd")
const DIRECTION_VECTORS: Dictionary = {
	"left": Vector2(-1, 0),
	"up": Vector2(0, -1),
	"right": Vector2(1, 0),
	"down": Vector2(0, 1),
}
const AREA_TYPES: PackedStringArray = [
	"outdoor_hub", "transport_hub", "transport_stop", "education_hub", "entertainment_hub",
	"shopping_hub", "luxury_hub", "outdoor_recreation", "waterfront_hub",
]

@onready var overlay: Control = %MiniMapOverlay
@onready var title_label: Label = %MiniMapTitle
@onready var scope_label: Label = %MiniMapScope
@onready var current_label: Label = %MiniMapCurrent
@onready var canvas: PortAlderContextMinimapCanvas = %MiniMapCanvas
@onready var close_button: Button = %CloseMiniMapButton

var _navigation_access: RefCounted
var _configured: bool = false
var _node_ids: PackedStringArray = []


func _ready() -> void:
	_navigation_access = NavigationAccessScript.new(ContentRegistry)
	close_button.pressed.connect(close_map)
	overlay.visible = false
	SettingsService.apply_accessibility(self)


func configure_map(location_id: String, current_room_id: String, navigation_override: Dictionary = {}, options: Dictionary = {}) -> void:
	if not is_node_ready() or not GameState.has_active_game():
		return
	var context_location_id: String = str(options.get("context_location_id", location_id))
	var location: Variant = ContentRegistry.get_location(context_location_id)
	if not location is Dictionary:
		_configured = false
		return
	var current_node_id: String = str(options.get("current_node_id", current_room_id))
	var graph: Dictionary = _build_graph(context_location_id, location, current_node_id, navigation_override, options)
	var nodes: Array = graph.get("nodes", [])
	var edges: Array = graph.get("edges", [])
	_assign_positions(nodes, edges, current_node_id, options.get("layout", {}))
	canvas.set_map_data(nodes, edges)
	_node_ids = PackedStringArray()
	for node_value: Variant in nodes:
		if node_value is Dictionary:
			_node_ids.append(str(node_value.get("id", "")))
	var location_name: String = str(options.get("title", location.get("name", context_location_id)))
	var location_type: String = str(location.get("type", ""))
	title_label.text = location_name.to_upper()
	scope_label.text = str(options.get("scope_label", "AREA MAP" if location_type in AREA_TYPES else "BUILDING MAP"))
	current_label.text = "Current position: %s" % _node_label(nodes, current_node_id)
	_configured = true
	close_map()


func toggle_map() -> void:
	if not _configured:
		return
	if overlay.visible:
		close_map()
	else:
		open_map()


func open_map() -> void:
	if not _configured:
		return
	overlay.visible = true
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	close_button.grab_focus()


func close_map() -> void:
	if not is_node_ready():
		return
	overlay.visible = false


func is_open() -> bool:
	return is_node_ready() and overlay.visible


func node_ids() -> PackedStringArray:
	return _node_ids.duplicate()


func map_nodes() -> Array:
	return canvas.map_nodes() if is_node_ready() else []


func map_edges() -> Array:
	return canvas.map_edges() if is_node_ready() else []


func refresh_accessibility() -> void:
	SettingsService.apply_accessibility(self)


func _build_graph(context_location_id: String, location: Dictionary, current_node_id: String, navigation_override: Dictionary, options: Dictionary) -> Dictionary:
	var nodes: Array = []
	var edges: Array = []
	var node_lookup: Dictionary = {}
	var label_overrides: Dictionary = options.get("label_overrides", {})
	var forced_locked_room_ids: Array = options.get("locked_room_ids", [])
	var included_room_ids: Array = options.get("room_ids", [])
	if included_room_ids.is_empty():
		for room_value: Variant in location.get("rooms", []):
			if room_value is Dictionary:
				included_room_ids.append(str(room_value.get("id", "")))
	var room_lookup: Dictionary = {}
	for room_value: Variant in location.get("rooms", []):
		if room_value is Dictionary:
			room_lookup[str(room_value.get("id", ""))] = room_value
	for room_id_value: Variant in included_room_ids:
		var room_id: String = str(room_id_value)
		var room: Dictionary = room_lookup.get(room_id, {})
		if room.is_empty():
			continue
		var access: Dictionary = _navigation_access.room_access_report(GameState.current_state, context_location_id, room_id)
		var locked: bool = not bool(access.get("allowed", false)) or room_id in forced_locked_room_ids
		_add_node(nodes, node_lookup, room_id, str(label_overrides.get(room_id, room.get("name", room_id.replace("_", " ").capitalize()))), "room", locked, room_id == current_node_id)
	for room_id_value: Variant in included_room_ids:
		var room_id: String = str(room_id_value)
		var room: Dictionary = room_lookup.get(room_id, {})
		if room.is_empty():
			continue
		var navigation: Dictionary = navigation_override.get(room_id, room.get("navigation", {}))
		for direction: String in DIRECTION_VECTORS:
			var target: String = str(navigation.get(direction, ""))
			if target.is_empty():
				continue
			var target_id: String = _target_node_id(context_location_id, target, included_room_ids)
			if target_id.is_empty():
				continue
			if not node_lookup.has(target_id):
				var target_details: Dictionary = _external_target_details(context_location_id, target, target_id, label_overrides)
				if not bool(target_details.get("visible", false)):
					continue
				_add_node(nodes, node_lookup, target_id, str(target_details.get("label", target_id)), "destination", bool(target_details.get("locked", false)), target_id == current_node_id)
			if node_lookup.has(target_id):
				_add_edge(edges, room_id, target_id, direction)
	if not node_lookup.has(current_node_id):
		var current_details: Dictionary = _external_target_details(context_location_id, current_node_id, current_node_id, label_overrides)
		_add_node(nodes, node_lookup, current_node_id, str(current_details.get("label", current_node_id.replace("_", " ").capitalize())), "destination", false, true)
	return {"nodes": nodes, "edges": edges}


func _target_node_id(context_location_id: String, target: String, included_room_ids: Array) -> String:
	if not target.contains("."):
		return target if target in included_room_ids else "boundary:%s" % target
	var target_location_id: String = target.get_slice(".", 0)
	var target_room_id: String = target.get_slice(".", 1)
	if target_location_id == context_location_id:
		return target_room_id if target_room_id in included_room_ids else "boundary:%s" % target_room_id
	return target


func _external_target_details(context_location_id: String, target: String, target_id: String, label_overrides: Dictionary) -> Dictionary:
	if label_overrides.has(target_id):
		return {"visible": true, "locked": false, "label": str(label_overrides[target_id])}
	if target_id.begins_with("boundary:"):
		var local_room_id: String = target_id.trim_prefix("boundary:")
		var context_location: Dictionary = ContentRegistry.get_location(context_location_id)
		var local_room: Dictionary = _room_definition(context_location, local_room_id)
		return {"visible": true, "locked": false, "label": str(label_overrides.get(local_room_id, local_room.get("name", local_room_id.replace("_", " ").capitalize())))}
	if not target.contains("."):
		return {"visible": true, "locked": false, "label": target.replace("_", " ").capitalize()}
	var target_location_id: String = target.get_slice(".", 0)
	var target_location: Variant = ContentRegistry.get_location(target_location_id)
	if not target_location is Dictionary:
		return {"visible": false}
	var visibility: Dictionary = _navigation_access.location_visibility_report(GameState.current_state, target_location_id)
	if not bool(visibility.get("allowed", false)):
		return {"visible": false}
	var access: Dictionary = _navigation_access.target_access_report(GameState.current_state, context_location_id, target)
	var known: bool = target_location_id in GameState.current_state.get("world_state", {}).get("unlocked_locations", [])
	known = known or target_location_id in GameState.current_state.get("world_state", {}).get("discovered_locations", [])
	known = known or target_location_id == str(GameState.current_state.get("world_state", {}).get("current_location", "")).get_slice(".", 0)
	if not bool(access.get("allowed", false)) and not known:
		return {"visible": false}
	return {
		"visible": true,
		"locked": not bool(access.get("allowed", false)),
		"label": str(label_overrides.get(target, target_location.get("name", target_location_id))),
	}


func _add_node(nodes: Array, lookup: Dictionary, node_id: String, label: String, kind: String, locked: bool, current: bool) -> void:
	if node_id.is_empty() or lookup.has(node_id):
		return
	var node: Dictionary = {"id": node_id, "label": label, "kind": kind, "locked": locked, "current": current}
	lookup[node_id] = node
	nodes.append(node)


func _add_edge(edges: Array, from_id: String, to_id: String, direction: String) -> void:
	for edge_value: Variant in edges:
		if edge_value is Dictionary and str(edge_value.get("from", "")) == from_id and str(edge_value.get("to", "")) == to_id:
			return
	edges.append({"from": from_id, "to": to_id, "direction": direction})


func _assign_positions(nodes: Array, edges: Array, current_node_id: String, layout_override: Variant) -> void:
	var positions: Dictionary = {}
	if layout_override is Dictionary:
		for node_id_value: Variant in layout_override:
			var point_value: Variant = layout_override[node_id_value]
			if point_value is Vector2:
				positions[str(node_id_value)] = point_value
			elif point_value is Array and point_value.size() >= 2:
				positions[str(node_id_value)] = Vector2(float(point_value[0]), float(point_value[1]))
	var adjacency: Dictionary = {}
	for edge_value: Variant in edges:
		if not edge_value is Dictionary:
			continue
		var from_id: String = str(edge_value.get("from", ""))
		var to_id: String = str(edge_value.get("to", ""))
		var delta: Vector2 = DIRECTION_VECTORS.get(str(edge_value.get("direction", "right")), Vector2.RIGHT)
		if not adjacency.has(from_id):
			adjacency[from_id] = []
		if not adjacency.has(to_id):
			adjacency[to_id] = []
		adjacency[from_id].append({"id": to_id, "delta": delta})
		adjacency[to_id].append({"id": from_id, "delta": -delta})
	var node_ids: PackedStringArray = []
	for node_value: Variant in nodes:
		if node_value is Dictionary:
			node_ids.append(str(node_value.get("id", "")))
	var root_id: String = current_node_id if current_node_id in node_ids else (node_ids[0] if not node_ids.is_empty() else "")
	if not root_id.is_empty() and not positions.has(root_id):
		positions[root_id] = Vector2.ZERO
	var queue: Array[String] = []
	if not root_id.is_empty():
		queue.append(root_id)
	var visited: Dictionary = {}
	while not queue.is_empty():
		var node_id: String = queue.pop_front()
		if visited.has(node_id):
			continue
		visited[node_id] = true
		for neighbor_value: Variant in adjacency.get(node_id, []):
			if not neighbor_value is Dictionary:
				continue
			var neighbor_id: String = str(neighbor_value.get("id", ""))
			if not positions.has(neighbor_id):
				positions[neighbor_id] = _nearest_free_position(positions[node_id] + neighbor_value.get("delta", Vector2.RIGHT), positions)
			queue.append(neighbor_id)
	var disconnected_x: float = _maximum_x(positions) + 2.0
	var disconnected_index: int = 0
	for node_id: String in node_ids:
		if not positions.has(node_id):
			positions[node_id] = Vector2(disconnected_x + float(disconnected_index % 2), float(disconnected_index / 2))
			disconnected_index += 1
	for node_value: Variant in nodes:
		if node_value is Dictionary:
			node_value["position"] = positions.get(str(node_value.get("id", "")), Vector2.ZERO)


func _nearest_free_position(desired: Vector2, positions: Dictionary) -> Vector2:
	if not _position_is_used(desired, positions):
		return desired
	for radius: int in range(1, 6):
		for offset: Vector2 in [Vector2(radius, 0), Vector2(-radius, 0), Vector2(0, radius), Vector2(0, -radius), Vector2(radius, radius), Vector2(-radius, radius)]:
			var candidate: Vector2 = desired + offset
			if not _position_is_used(candidate, positions):
				return candidate
	return desired + Vector2(1, 1)


func _position_is_used(point: Vector2, positions: Dictionary) -> bool:
	for existing: Variant in positions.values():
		if existing is Vector2 and (existing as Vector2).is_equal_approx(point):
			return true
	return false


func _maximum_x(positions: Dictionary) -> float:
	var maximum: float = 0.0
	for point: Variant in positions.values():
		if point is Vector2:
			maximum = maxf(maximum, point.x)
	return maximum


func _node_label(nodes: Array, node_id: String) -> String:
	for node_value: Variant in nodes:
		if node_value is Dictionary and str(node_value.get("id", "")) == node_id:
			return str(node_value.get("label", node_id))
	return node_id.replace("_", " ").capitalize()


func _room_definition(location: Dictionary, room_id: String) -> Dictionary:
	for room_value: Variant in location.get("rooms", []):
		if room_value is Dictionary and str(room_value.get("id", "")) == room_id:
			return room_value
	return {}
