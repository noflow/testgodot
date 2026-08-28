extends RefCounted
class_name PortAlderTravelEngine

const TRANSPORT_PACKAGE: String = "port_alder_initial_transportation"
const TUTORIAL_QUEST: String = "getting_around_port_alder"
const GameClockScript: GDScript = preload("res://src/simulation/game_clock.gd")
const NavigationAccessScript: GDScript = preload("res://src/world/navigation_access.gd")

var _registry: Node
var _simulation: RefCounted
var _quests: RefCounted
var _navigation_access: RefCounted


func _init(content_registry: Node, simulation_engine: RefCounted, quest_engine: RefCounted) -> void:
	_registry = content_registry
	_simulation = simulation_engine
	_quests = quest_engine
	_navigation_access = NavigationAccessScript.new(content_registry)


func plan_routes(state: Dictionary, destination: String) -> Dictionary:
	var origin: String = _root_location(str(state.get("world_state", {}).get("current_location", "")))
	var destination_id: String = _root_location(destination)
	if _registry.get_location(destination_id) == null:
		return _failure("Unknown destination: %s" % destination_id)
	var access_report: Dictionary = _navigation_access.location_entry_report(state, destination_id)
	if not bool(access_report.get("allowed", false)):
		return _failure(str(access_report.get("reason", "That destination is unavailable.")))
	if destination_id not in state["world_state"].get("unlocked_locations", []):
		return _failure("Destination is not unlocked: %s" % destination_id)
	if origin == destination_id:
		return _failure("You are already at this destination.")
	var package: Variant = _registry.get_package(TRANSPORT_PACKAGE)
	if not package is Dictionary:
		return _failure("Transportation content is unavailable.")

	var options: Array = []
	for mode_definition: Variant in package.get("modes", []):
		if not mode_definition is Dictionary:
			continue
		var mode: String = str(mode_definition.get("id", ""))
		var path: Dictionary = _shortest_path(package, origin, destination_id, mode)
		if path.is_empty():
			continue
		var wait_minutes: int = _bus_wait_minutes(package, state) if mode == "bus" else 0
		var option: Dictionary = {
			"mode": mode,
			"name": mode.capitalize(),
			"origin": origin,
			"destination": destination_id,
			"arrival": _arrival_destination(state, destination_id),
			"minutes": int(path["minutes"]) + wait_minutes,
			"travel_minutes": int(path["minutes"]),
			"wait_minutes": wait_minutes,
			"cost": float(path["cost"]),
			"segments": path["segments"],
			"route_ids": path["route_ids"],
			"warnings": _travel_warnings(state, mode),
			"available": true,
			"reason": "",
		}
		var arrival_clock: Dictionary = _clock_after_minutes(state, int(option["minutes"]))
		option["arrival_weekday"] = arrival_clock["weekday"]
		option["arrival_block"] = arrival_clock["block"]
		option["arrival_minute_within_block"] = arrival_clock["minute_within_block"]
		var mode_error: String = _destination_access_error(state, destination_id, int(option["minutes"]), destination)
		if mode_error.is_empty():
			mode_error = _mode_error(state, package, option)
		if not mode_error.is_empty():
			option["available"] = false
			option["reason"] = mode_error
		option["account"] = _payment_account(state, float(option["cost"]))
		options.append(option)
	options.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return int(left["minutes"]) < int(right["minutes"]))
	if options.is_empty():
		return _failure("No authored route connects %s and %s yet." % [origin, destination_id])
	return {
		"ok": true,
		"origin": origin,
		"destination": destination_id,
		"destination_name": _location_name(destination_id),
		"options": options,
		"errors": PackedStringArray(),
	}


func execute_travel(state: Dictionary, destination: String, mode: String, source: String) -> Dictionary:
	var plan: Dictionary = plan_routes(state, destination)
	if not plan.get("ok", false):
		return plan
	var selected: Dictionary = {}
	for option: Variant in plan["options"]:
		if option is Dictionary and str(option.get("mode", "")) == mode:
			selected = option
			break
	if selected.is_empty():
		return _failure("The selected transportation mode has no route.")
	if not bool(selected.get("available", false)):
		return _failure(str(selected.get("reason", "That route is unavailable.")))

	var working: Dictionary = state
	var destination_was_discovered: bool = str(selected["destination"]) in state["world_state"].get("discovered_locations", [])
	var events: Array = []
	if str(selected["origin"]) == "hale_home" and TUTORIAL_QUEST not in working["quest_state"]["active"] and TUTORIAL_QUEST not in working["quest_state"]["completed"]:
		var tutorial_result: Dictionary = start_transportation_tutorial(working, "%s.tutorial" % source)
		if not tutorial_result.get("ok", false):
			return tutorial_result
		working = tutorial_result["state"]
		tutorial_result = record_map_viewed(working, "%s.tutorial" % source)
		if not tutorial_result.get("ok", false):
			return tutorial_result
		working = tutorial_result["state"]
		var planned_modes: PackedStringArray = []
		for planned_option: Variant in plan["options"]:
			if planned_option is Dictionary:
				planned_modes.append(str(planned_option.get("mode", "")))
		tutorial_result = record_routes_viewed(working, str(selected["destination"]), planned_modes, "%s.tutorial" % source)
		if not tutorial_result.get("ok", false):
			return tutorial_result
		working = tutorial_result["state"]
	var result: Dictionary = _simulation.apply_operation(
		working,
		"travel.begin",
		{
			"origin": selected["origin"],
			"destination": selected["destination"],
			"mode": mode,
			"route": selected.duplicate(true),
		},
		source
	)
	if not result.get("ok", false):
		return result
	working = result["state"]
	events.append(result["event"])
	result = _simulation.apply_operation(
		working,
		"travel.complete",
		{
			"origin": selected["origin"],
			"destination": selected["arrival"],
			"mode": mode,
			"minutes": selected["minutes"],
			"delay": 0,
			"cost": selected["cost"],
			"account": selected["account"],
			"route_ids": selected["route_ids"],
		},
		source
	)
	if not result.get("ok", false):
		return result
	working = result["state"]
	events.append(result["event"])
	if not destination_was_discovered:
		result = _quests.record_event(working, "location_discovered", {
			"location": selected["destination"],
		}, "%s.discovery" % source)
		if not result.get("ok", false):
			return result
		working = result["state"]
	for quest_event: Dictionary in [
		{"event": "location_entered", "location": selected["destination"]},
		{"event": "trip_completed", "mode": mode, "location": selected["destination"]},
	]:
		var event_name: String = str(quest_event["event"])
		quest_event.erase("event")
		result = _quests.record_event(working, event_name, quest_event, "%s.%s" % [source, event_name])
		if not result.get("ok", false):
			return result
		working = result["state"]
	result = _complete_matching_objectives(working, selected["destination"], mode, source, events)
	if not result.get("ok", false):
		return result
	return {
		"ok": true,
		"state": result["state"],
		"events": events,
		"route": selected,
		"destination": selected["arrival"],
		"errors": PackedStringArray(),
	}


func start_transportation_tutorial(state: Dictionary, source: String) -> Dictionary:
	if TUTORIAL_QUEST in state["quest_state"]["active"] or TUTORIAL_QUEST in state["quest_state"]["completed"]:
		return _unchanged(state)
	var result: Dictionary = _quests.start_quest(state, TUTORIAL_QUEST, source)
	if not result.get("ok", false):
		return result
	return {"ok": true, "state": result["state"], "changed": true, "errors": PackedStringArray()}


func record_map_viewed(state: Dictionary, source: String) -> Dictionary:
	return _complete_tutorial_objectives(state, ["open_city_map"], source)


func record_routes_viewed(state: Dictionary, destination: String, modes: PackedStringArray, source: String) -> Dictionary:
	var objectives: PackedStringArray = []
	if destination == "westshore_campus" and "walking" in modes and "bus" in modes:
		objectives.append("compare_routes")
	if "taxi" in modes and "car" in modes:
		objectives.append("review_other_modes")
	return _complete_tutorial_objectives(state, objectives, source)


func _complete_tutorial_objectives(state: Dictionary, objective_ids: PackedStringArray, source: String) -> Dictionary:
	if TUTORIAL_QUEST not in state["quest_state"]["active"]:
		return _unchanged(state)
	var working: Dictionary = state
	var changed: bool = false
	for objective_id: String in objective_ids:
		if bool(working["quest_state"].get("objectives", {}).get(TUTORIAL_QUEST, {}).get(objective_id, false)):
			continue
		var result: Dictionary = _quests.complete_objective(working, TUTORIAL_QUEST, objective_id, source)
		if not result.get("ok", false):
			return result
		working = result["state"]
		changed = true
	return {"ok": true, "state": working, "changed": changed, "errors": PackedStringArray()}


func _complete_matching_objectives(
	state: Dictionary,
	destination: String,
	mode: String,
	source: String,
	events: Array
) -> Dictionary:
	var working: Dictionary = state
	for quest_id_value: Variant in working["quest_state"].get("active", []).duplicate():
		var quest_id: String = str(quest_id_value)
		var quest: Variant = _registry.get_content("quests", quest_id)
		if not quest is Dictionary:
			continue
		for objective: Variant in quest.get("objectives", []):
			if not objective is Dictionary:
				continue
			var objective_id: String = str(objective.get("id", ""))
			if bool(working["quest_state"].get("objectives", {}).get(quest_id, {}).get(objective_id, false)):
				continue
			var completion: Dictionary = objective.get("completion", {})
			var matches_location: bool = str(completion.get("event", "")) == "location_entered" and str(completion.get("location", "")) == destination
			var matches_trip: bool = str(completion.get("event", "")) == "trip_completed" and str(completion.get("mode", "")) == mode
			if not matches_location and not matches_trip:
				continue
			var result: Dictionary = _quests.complete_objective(working, quest_id, objective_id, source)
			if not result.get("ok", false):
				return result
			working = result["state"]
	if TUTORIAL_QUEST in working["quest_state"]["active"] and _all_objectives_complete(working, TUTORIAL_QUEST):
		var completion_result: Dictionary = _quests.complete_quest(working, TUTORIAL_QUEST, source)
		if not completion_result.get("ok", false):
			return completion_result
		working = completion_result["state"]
	return {"ok": true, "state": working, "events": events, "errors": PackedStringArray()}


func _shortest_path(package: Dictionary, origin: String, destination: String, mode: String) -> Dictionary:
	var edges: Array = _travel_edges(package, mode)
	var distances: Dictionary = {origin: 0}
	var previous: Dictionary = {}
	var visited: Dictionary = {}
	while true:
		var current: String = ""
		for node: Variant in distances:
			if visited.has(node):
				continue
			if current.is_empty() or int(distances[node]) < int(distances[current]):
				current = str(node)
		if current.is_empty():
			break
		if current == destination:
			break
		visited[current] = true
		for edge: Variant in edges:
			if not edge is Dictionary or str(edge.get("from", "")) != current:
				continue
			var neighbor: String = str(edge.get("to", ""))
			var next_distance: int = int(distances[current]) + int(edge.get("minutes", 0))
			if not distances.has(neighbor) or next_distance < int(distances[neighbor]):
				distances[neighbor] = next_distance
				previous[neighbor] = {"node": current, "edge": edge}
	if not distances.has(destination):
		return {}
	var segments: Array = []
	var cursor: String = destination
	while cursor != origin:
		if not previous.has(cursor):
			return {}
		var step: Dictionary = previous[cursor]
		segments.push_front(step["edge"].duplicate(true))
		cursor = str(step["node"])
	if mode != "walking" and not _segments_use_mode(segments, mode):
		return {}
	var total_cost: float = 0.0
	var route_ids: PackedStringArray = []
	for segment: Dictionary in segments:
		total_cost += float(segment.get("cost", 0.0))
		var route_id: String = str(segment.get("route_id", ""))
		if not route_id.is_empty() and route_id not in route_ids:
			route_ids.append(route_id)
	return {"minutes": distances[destination], "cost": total_cost, "segments": segments, "route_ids": route_ids}


func _travel_edges(package: Dictionary, mode: String) -> Array:
	var edges: Array = []
	for link: Variant in package.get("local_links", []):
		if not link is Dictionary:
			continue
		var link_mode: String = str(link.get("mode", ""))
		if link_mode != mode and not (mode != "walking" and link_mode == "walking"):
			continue
		_append_bidirectional_edge(edges, {
			"from": link.get("from"), "to": link.get("to"), "mode": link_mode,
			"minutes": link.get("minutes", 0), "cost": link.get("cost", 0),
			"route_id": "local:%s:%s" % [link.get("from", ""), link.get("to", "")],
		})
	for route: Variant in package.get("routes", []):
		if not route is Dictionary:
			continue
		for option: Variant in route.get("options", []):
			if option is Dictionary and str(option.get("mode", "")) == mode:
				_append_bidirectional_edge(edges, {
					"from": route.get("from"), "to": route.get("to"), "mode": mode,
					"minutes": option.get("minutes", 0), "cost": option.get("cost", 0),
					"route_id": route.get("id", ""),
				})
	return edges


func _append_bidirectional_edge(edges: Array, edge: Dictionary) -> void:
	edges.append(edge)
	var reverse: Dictionary = edge.duplicate(true)
	reverse["from"] = edge["to"]
	reverse["to"] = edge["from"]
	edges.append(reverse)


func _segments_use_mode(segments: Array, mode: String) -> bool:
	for segment: Variant in segments:
		if segment is Dictionary and str(segment.get("mode", "")) == mode:
			return true
	return false


func _mode_error(state: Dictionary, package: Dictionary, option: Dictionary) -> String:
	var mode: String = str(option["mode"])
	if mode == "bus" and package.get("schedule_rules", {}).get("bus", {}).get(str(state["clock"]["block"])) == null:
		return "Bus service is closed during this activity block."
	if mode == "car":
		if not bool(state["player"]["transportation"].get("license", false)):
			return "A driver's license is required."
		var permission: String = str(state["player"]["transportation"].get("family_car_permission", ""))
		var owned: Array = state["player"]["transportation"].get("owned_vehicles", [])
		if owned.is_empty() and permission in ["", "none", "denied"]:
			return "No vehicle is available."
		var permission_date: String = str(state["world_state"].get("world_flags", {}).get("family_car_permission_date", ""))
		var current_date: String = "Y%d-%02d-%02d" % [state["clock"]["year"], state["clock"]["month"], state["clock"]["day"]]
		if owned.is_empty() and permission != "regular_shared_access" and permission_date != current_date:
			return "Ask for permission to use the family car today."
		if float(state["player"]["needs"].get("inebriation", 0.0)) >= 25.0:
			return "Driving is blocked while impaired."
	if float(option.get("cost", 0.0)) > 0.0 and _payment_account(state, float(option["cost"])).is_empty():
		return "You do not have enough available money for this route."
	return ""


func _destination_access_error(state: Dictionary, destination: String, travel_minutes: int, requested_destination: String = "") -> String:
	var location: Dictionary = _registry.get_location(destination)
	var access: Dictionary = location.get("access", {})
	if bool(access.get("always_open", false)) or bool(access.get("always_open_to_player", false)) or _is_after_hours_outdoor_connector(location, requested_destination):
		return ""
	var arrival_clock: Dictionary = _clock_after_minutes(state, travel_minutes)
	if _access_is_open(access, arrival_clock):
		return ""
	return "%s will be closed on arrival. Next opening: %s." % [
		location.get("name", destination),
		_next_opening_label(access, arrival_clock),
	]


func _is_after_hours_outdoor_connector(location: Dictionary, requested_destination: String) -> bool:
	if not requested_destination.contains(".") or str(location.get("type", "")) != "education_hub":
		return false
	return requested_destination.get_slice(".", 1) == str(location.get("outside_room", ""))


func _access_is_open(access: Dictionary, clock: Dictionary) -> bool:
	var open_days: Array = access.get("open_days", [])
	if not open_days.is_empty() and str(clock["weekday"]) not in open_days:
		return false
	var open_blocks: Array = access.get("open_blocks", [])
	if not open_blocks.is_empty() and str(clock["block"]) not in open_blocks:
		return false
	return str(clock["block"]) not in access.get("closed_blocks", [])


func _next_opening_label(access: Dictionary, from_clock: Dictionary) -> String:
	var candidate: Dictionary = from_clock.duplicate(true)
	var clock_rules: RefCounted = GameClockScript.new()
	for _step: int in 56:
		clock_rules.advance(candidate, {"blocks": 1})
		if _access_is_open(access, candidate):
			return "%s %s" % [str(candidate["weekday"]).capitalize(), str(candidate["block"]).replace("_", " ").capitalize()]
	return "schedule unavailable"


func _clock_after_minutes(state: Dictionary, minutes: int) -> Dictionary:
	var result: Dictionary = state["clock"].duplicate(true)
	if minutes > 0:
		var clock_rules: RefCounted = GameClockScript.new()
		clock_rules.advance(result, {"minutes": minutes})
	return result


func _travel_warnings(state: Dictionary, mode: String) -> PackedStringArray:
	var warnings: PackedStringArray = []
	if mode == "walking":
		var condition: String = str(state["world_state"].get("weather", {}).get("condition", "clear"))
		if condition in ["rain", "heavy_rain", "snow", "storm"]:
			warnings.append("Full weather exposure: %s" % condition.replace("_", " "))
		if float(state["player"]["needs"].get("energy", 100.0)) < 25.0:
			warnings.append("Low energy may make this walk tiring")
	if mode == "car" and float(state["player"]["needs"].get("fatigue", 0.0)) >= 75.0:
		warnings.append("Severe fatigue makes driving risky")
	return warnings


func _bus_wait_minutes(package: Dictionary, state: Dictionary) -> int:
	var value: Variant = package.get("schedule_rules", {}).get("bus", {}).get(str(state["clock"]["block"]))
	return 0 if value == null else int(value)


func _payment_account(state: Dictionary, cost: float) -> String:
	if cost <= 0.0:
		return "wallet_cash"
	for account: String in ["wallet_cash", "checking", "savings"]:
		if float(state["player"]["economy"]["accounts"].get(account, 0.0)) >= cost:
			return account
	return ""


func _arrival_destination(state: Dictionary, location_id: String) -> String:
	if location_id == "hale_home":
		return "hale_home.front_yard"
	var location: Variant = _registry.get_location(location_id)
	if not location is Dictionary or location.get("rooms", []).is_empty():
		return location_id
	var outside_room: String = str(location.get("outside_room", ""))
	if not outside_room.is_empty() and bool(_navigation_access.room_access_report(state, location_id, outside_room).get("allowed", false)):
		return "%s.%s" % [location_id, outside_room]
	for room: Variant in location.get("rooms", []):
		if room is Dictionary and bool(_navigation_access.room_access_report(state, location_id, str(room.get("id", ""))).get("allowed", false)):
			return "%s.%s" % [location_id, room.get("id", "")]
	return location_id


func _all_objectives_complete(state: Dictionary, quest_id: String) -> bool:
	var quest: Dictionary = _registry.get_content("quests", quest_id)
	for objective: Variant in quest.get("objectives", []):
		if objective is Dictionary and not bool(state["quest_state"].get("objectives", {}).get(quest_id, {}).get(str(objective.get("id", "")), false)):
			return false
	return true


func _root_location(location_path: String) -> String:
	return location_path.get_slice(".", 0)


func _location_name(location_id: String) -> String:
	var location: Variant = _registry.get_location(location_id)
	return str(location.get("name", location_id)) if location is Dictionary else location_id.replace("_", " ").capitalize()


func _unchanged(state: Dictionary) -> Dictionary:
	return {"ok": true, "state": state, "changed": false, "errors": PackedStringArray()}


func _failure(message: String) -> Dictionary:
	return {"ok": false, "errors": PackedStringArray([message])}
