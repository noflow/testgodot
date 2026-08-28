extends RefCounted
class_name PortAlderNavigationIntegrityValidator

const DIRECTIONS: PackedStringArray = ["left", "up", "right", "down"]
const PERMANENTLY_INACCESSIBLE_ROOM_ACCESS: PackedStringArray = ["restricted"]

var _registry: Node


func _init(content_registry: Node = null) -> void:
	_registry = content_registry


func audit() -> Dictionary:
	if _registry == null:
		return _report_with_error("Navigation validation requires a content registry.")
	return audit_locations(_registry.get_all("locations"))


func audit_locations(locations: Array, navigation_overrides: Dictionary = {}) -> Dictionary:
	var errors: PackedStringArray = []
	var warnings: PackedStringArray = []
	var records: Dictionary = {}
	var stats: Dictionary = {
		"locations": 0,
		"rooms": 0,
		"enterable_rooms": 0,
		"conditional_rooms": 0,
		"authored_navigation_locations": 0,
		"fallback_navigation_locations": 0,
		"authored_links": 0,
		"local_links": 0,
		"cross_location_links": 0,
		"hidden_locations": 0,
	}

	_build_location_records(locations, navigation_overrides, records, errors, warnings, stats)
	_validate_navigation_targets(records, errors, stats)
	_validate_local_escape_paths(records, errors)
	_validate_cross_location_arrivals(records, errors)
	return {
		"ok": errors.is_empty(),
		"errors": errors,
		"warnings": warnings,
		"stats": stats,
	}


func _build_location_records(
	locations: Array,
	navigation_overrides: Dictionary,
	records: Dictionary,
	errors: PackedStringArray,
	warnings: PackedStringArray,
	stats: Dictionary
) -> void:
	for location_value: Variant in locations:
		if not location_value is Dictionary:
			errors.append("Location collection contains a non-object entry.")
			continue
		var location: Dictionary = location_value
		var location_id: String = str(location.get("id", "")).strip_edges()
		if location_id.is_empty():
			errors.append("Location entry has no id.")
			continue
		if records.has(location_id):
			errors.append("Duplicate navigation location id: %s." % location_id)
			continue

		var location_override: Dictionary = navigation_overrides.get(location_id, {})
		var overridden_exits: Dictionary = location_override.get("exits", {})
		var room_values: Variant = location.get("rooms", [])
		if not room_values is Array or room_values.is_empty():
			errors.append("Location %s has no room definitions." % location_id)
			records[location_id] = _empty_record(location)
			continue

		var room_by_id: Dictionary = {}
		var room_order: PackedStringArray = []
		var enterable_order: PackedStringArray = []
		var has_authored_navigation: bool = false
		for room_value: Variant in room_values:
			if not room_value is Dictionary:
				errors.append("Location %s contains a non-object room entry." % location_id)
				continue
			var room: Dictionary = room_value.duplicate(true) if not location_override.is_empty() else room_value
			var room_id: String = str(room.get("id", "")).strip_edges()
			if room_id.is_empty():
				errors.append("Location %s contains a room without an id." % location_id)
				continue
			if room_by_id.has(room_id):
				errors.append("Location %s has duplicate room id %s." % [location_id, room_id])
				continue
			if overridden_exits.has(room_id):
				room["navigation"] = overridden_exits[room_id]
			elif bool(location_override.get("replace_all_navigation", false)):
				room.erase("navigation")
			room_by_id[room_id] = room
			room_order.append(room_id)
			stats["rooms"] = int(stats["rooms"]) + 1
			var access: String = str(room.get("access", ""))
			if not access.is_empty():
				stats["conditional_rooms"] = int(stats["conditional_rooms"]) + 1
			if access not in PERMANENTLY_INACCESSIBLE_ROOM_ACCESS:
				enterable_order.append(room_id)
				stats["enterable_rooms"] = int(stats["enterable_rooms"]) + 1
			if room.has("navigation") and not room.get("navigation") is Dictionary:
				errors.append("Room %s.%s navigation must be an object." % [location_id, room_id])
			elif room.get("navigation", {}) is Dictionary and not room.get("navigation", {}).is_empty():
				has_authored_navigation = true

		var outside_room: String = str(location_override.get("outside_room", location.get("outside_room", ""))).strip_edges()
		if not outside_room.is_empty() and not room_by_id.has(outside_room):
			errors.append("Location %s names unknown outside room %s." % [location_id, outside_room])
		if outside_room.is_empty() and not enterable_order.is_empty():
			outside_room = enterable_order[0]
		if not outside_room.is_empty() and outside_room not in enterable_order:
			errors.append("Location %s outside room %s is permanently inaccessible." % [location_id, outside_room])

		records[location_id] = {
			"definition": location,
			"room_by_id": room_by_id,
			"room_order": room_order,
			"enterable_order": enterable_order,
			"outside_room": outside_room,
		}
		stats["locations"] = int(stats["locations"]) + 1
		if bool(location.get("discovery", {}).get("hidden_until_discovered", false)):
			stats["hidden_locations"] = int(stats["hidden_locations"]) + 1
		if has_authored_navigation:
			stats["authored_navigation_locations"] = int(stats["authored_navigation_locations"]) + 1
		else:
			stats["fallback_navigation_locations"] = int(stats["fallback_navigation_locations"]) + 1
			if enterable_order.size() > 1:
				warnings.append("Location %s still uses ordered left/right fallback navigation." % location_id)


func _validate_navigation_targets(records: Dictionary, errors: PackedStringArray, stats: Dictionary) -> void:
	for location_id_value: Variant in records:
		var location_id: String = str(location_id_value)
		var record: Dictionary = records[location_id]
		for room_id_value: Variant in record.get("room_by_id", {}):
			var room_id: String = str(room_id_value)
			var room: Dictionary = record["room_by_id"][room_id]
			var navigation: Variant = room.get("navigation", {})
			if not navigation is Dictionary:
				continue
			for direction_value: Variant in navigation:
				var direction: String = str(direction_value)
				if direction not in DIRECTIONS:
					errors.append("Room %s.%s uses unsupported direction %s." % [location_id, room_id, direction])
					continue
				var target: String = str(navigation[direction_value]).strip_edges()
				stats["authored_links"] = int(stats["authored_links"]) + 1
				if target.is_empty():
					errors.append("Room %s.%s has an empty %s navigation target." % [location_id, room_id, direction])
					continue
				if not target.contains("."):
					stats["local_links"] = int(stats["local_links"]) + 1
					if not record.get("room_by_id", {}).has(target):
						errors.append("Room %s.%s points %s to unknown local room %s." % [location_id, room_id, direction, target])
					continue
				stats["cross_location_links"] = int(stats["cross_location_links"]) + 1
				var target_parts: PackedStringArray = target.split(".", false)
				if target_parts.size() != 2:
					errors.append("Room %s.%s has malformed cross-location target %s." % [location_id, room_id, target])
					continue
				var target_location_id: String = target_parts[0]
				var target_room_id: String = target_parts[1]
				if not records.has(target_location_id):
					errors.append("Room %s.%s points to unknown location %s." % [location_id, room_id, target_location_id])
				elif not records[target_location_id].get("room_by_id", {}).has(target_room_id):
					errors.append("Room %s.%s points to unknown room %s." % [location_id, room_id, target])


func _validate_local_escape_paths(records: Dictionary, errors: PackedStringArray) -> void:
	for location_id_value: Variant in records:
		var location_id: String = str(location_id_value)
		var record: Dictionary = records[location_id]
		var outside_room: String = str(record.get("outside_room", ""))
		var enterable_order: PackedStringArray = record.get("enterable_order", PackedStringArray())
		if enterable_order.is_empty() or outside_room.is_empty():
			continue
		var local_graph: Dictionary = _effective_local_graph(record)
		for room_id: String in enterable_order:
			if not _can_reach(room_id, outside_room, local_graph):
				errors.append("Enterable room %s.%s cannot return to outside room %s." % [location_id, room_id, outside_room])


func _validate_cross_location_arrivals(records: Dictionary, errors: PackedStringArray) -> void:
	for location_id_value: Variant in records:
		var location_id: String = str(location_id_value)
		var record: Dictionary = records[location_id]
		for room_id_value: Variant in record.get("room_by_id", {}):
			var room_id: String = str(room_id_value)
			var room: Dictionary = record["room_by_id"][room_id]
			var navigation: Variant = room.get("navigation", {})
			if not navigation is Dictionary:
				continue
			for target_value: Variant in navigation.values():
				var target: String = str(target_value)
				if not target.contains("."):
					continue
				var target_parts: PackedStringArray = target.split(".", false)
				if target_parts.size() != 2 or not records.has(target_parts[0]):
					continue
				var destination: Dictionary = records[target_parts[0]]
				if not destination.get("room_by_id", {}).has(target_parts[1]):
					continue
				if target_parts[1] not in destination.get("enterable_order", PackedStringArray()):
					errors.append("Cross-location link %s.%s arrives in permanently inaccessible room %s." % [location_id, room_id, target])
					continue
				var destination_outside: String = str(destination.get("outside_room", ""))
				if not destination_outside.is_empty() and not _can_reach(target_parts[1], destination_outside, _effective_local_graph(destination)):
					errors.append("Cross-location link %s.%s arrives at %s without a route back to %s." % [location_id, room_id, target, destination_outside])


func _effective_local_graph(record: Dictionary) -> Dictionary:
	var graph: Dictionary = {}
	var enterable_order: PackedStringArray = record.get("enterable_order", PackedStringArray())
	var room_by_id: Dictionary = record.get("room_by_id", {})
	for room_id: String in enterable_order:
		var neighbors: PackedStringArray = []
		var room: Dictionary = room_by_id.get(room_id, {})
		var navigation: Variant = room.get("navigation", {})
		if navigation is Dictionary and not navigation.is_empty():
			for target_value: Variant in navigation.values():
				var target: String = str(target_value)
				if not target.contains(".") and target in enterable_order and target not in neighbors:
					neighbors.append(target)
		else:
			var room_index: int = enterable_order.find(room_id)
			if room_index > 0:
				neighbors.append(enterable_order[room_index - 1])
			if room_index >= 0 and room_index + 1 < enterable_order.size():
				neighbors.append(enterable_order[room_index + 1])
		graph[room_id] = neighbors
	return graph


func _can_reach(start: String, destination: String, graph: Dictionary) -> bool:
	if start == destination:
		return true
	var pending: Array[String] = [start]
	var visited: Dictionary = {start: true}
	while not pending.is_empty():
		var current: String = pending.pop_front()
		for next_value: Variant in graph.get(current, PackedStringArray()):
			var next_room: String = str(next_value)
			if next_room == destination:
				return true
			if not visited.has(next_room):
				visited[next_room] = true
				pending.append(next_room)
	return false


func _empty_record(location: Dictionary) -> Dictionary:
	return {
		"definition": location,
		"room_by_id": {},
		"room_order": PackedStringArray(),
		"enterable_order": PackedStringArray(),
		"outside_room": "",
	}


func _report_with_error(message: String) -> Dictionary:
	return {
		"ok": false,
		"errors": PackedStringArray([message]),
		"warnings": PackedStringArray(),
		"stats": {},
	}
