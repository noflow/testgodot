extends RefCounted
class_name PortAlderNavigationAccess

const PRIVATE_LOCATION_TYPES: PackedStringArray = ["npc_residence", "npc_and_rentable_apartment"]
const EMPLOYEE_ROOM_ACCESS: PackedStringArray = ["employee", "licensed_worker"]
const EXPLICIT_GRANT_ROOM_ACCESS: PackedStringArray = [
	"invitation", "relationship_permission", "permission_required",
	"consenting_adult_appointment", "employee_or_appointment",
]

var _registry: Node


func _init(content_registry: Node) -> void:
	_registry = content_registry


func location_visibility_report(state: Dictionary, location_id: String) -> Dictionary:
	var location: Variant = _registry.get_location(location_id)
	if not location is Dictionary:
		return _denied("Unknown location: %s" % location_id)
	var discovery: Dictionary = location.get("discovery", {})
	var hidden: bool = bool(discovery.get("hidden_until_discovered", false))
	var known: bool = location_id in state.get("world_state", {}).get("discovered_locations", [])
	known = known or _current_location_root(state) == location_id or _has_property_access(state, location_id)
	if hidden and not known:
		return _denied("This private residence has not been discovered yet.")
	return _allowed()


func location_entry_report(state: Dictionary, location_id: String) -> Dictionary:
	var visibility: Dictionary = location_visibility_report(state, location_id)
	if not bool(visibility.get("allowed", false)):
		return visibility
	var world: Dictionary = state.get("world_state", {})
	var available: bool = location_id in world.get("unlocked_locations", [])
	available = available or _current_location_root(state) == location_id or _has_property_access(state, location_id)
	if not available:
		return _denied("This location has not been unlocked yet.")
	var location: Dictionary = _registry.get_location(location_id)
	var access: Dictionary = location.get("access", {})
	var private_residence: bool = str(location.get("type", "")) in PRIVATE_LOCATION_TYPES
	var invitation_required: bool = bool(access.get("requires_invitation", false))
	invitation_required = invitation_required or bool(access.get("requires_invitation_or_lease", false))
	invitation_required = invitation_required or bool(access.get("lease_or_invitation", false))
	if (private_residence or invitation_required) and not _private_location_permission(state, location_id):
		return _denied("An invitation, quest, or housing agreement is required before visiting this residence.")
	return _allowed()


func room_access_report(state: Dictionary, location_id: String, room_id: String) -> Dictionary:
	var location: Variant = _registry.get_location(location_id)
	if not location is Dictionary:
		return _denied("Unknown location: %s" % location_id)
	var room: Dictionary = _room_definition(location, room_id)
	if room.is_empty():
		return _denied("Unknown room: %s.%s" % [location_id, room_id])
	var entry: Dictionary = location_entry_report(state, location_id)
	if not bool(entry.get("allowed", false)) and _current_location_root(state) != location_id:
		return entry
	var room_path: String = "%s.%s" % [location_id, room_id]
	var access: String = str(room.get("access", ""))
	if _has_room_grant(state, room_path):
		return _allowed()
	if access == "restricted":
		return _denied("That room is private and unavailable.")
	if access in EMPLOYEE_ROOM_ACCESS:
		return _allowed() if _has_employment_access(state, location_id) else _denied("Employee access is required.")
	if access in EXPLICIT_GRANT_ROOM_ACCESS:
		if access == "employee_or_appointment" and _has_employment_access(state, location_id):
			return _allowed()
		return _denied("Permission is required before entering this room.")
	if access == "lease":
		return _allowed() if _has_property_access(state, location_id) else _denied("A lease or ownership agreement is required.")
	if access in ["player_private", "household"]:
		return _allowed() if str(state.get("player", {}).get("housing", {}).get("residence", "")) == location_id else _denied("Household access is required.")
	return _allowed()


func target_access_report(state: Dictionary, current_location_id: String, target: String) -> Dictionary:
	if target.is_empty():
		return _denied("No navigation target was authored.")
	var target_location_id: String = current_location_id
	var target_room_id: String = target
	if target.contains("."):
		target_location_id = target.get_slice(".", 0)
		target_room_id = target.get_slice(".", 1)
	return room_access_report(state, target_location_id, target_room_id)


func accessible_rooms(state: Dictionary, location_id: String) -> Array:
	var location: Variant = _registry.get_location(location_id)
	if not location is Dictionary:
		return []
	var result: Array = []
	for room_value: Variant in location.get("rooms", []):
		if not room_value is Dictionary:
			continue
		var room_id: String = str(room_value.get("id", ""))
		if bool(room_access_report(state, location_id, room_id).get("allowed", false)):
			result.append(room_value)
	return result


func _private_location_permission(state: Dictionary, location_id: String) -> bool:
	if _current_location_root(state) == location_id or _has_property_access(state, location_id):
		return true
	return location_id in state.get("world_state", {}).get("discovered_locations", [])


func _has_room_grant(state: Dictionary, room_path: String) -> bool:
	var world: Dictionary = state.get("world_state", {})
	if room_path in world.get("room_access_grants", []):
		return true
	var location_id: String = room_path.get_slice(".", 0)
	var access_record: Variant = world.get("location_access", {}).get(location_id)
	if access_record is Dictionary and room_path.get_slice(".", 1) in access_record.get("room_grants", []):
		return true
	return bool(state.get("player", {}).get("flags", {}).get("room_access.%s" % room_path, false))


func _has_property_access(state: Dictionary, location_id: String) -> bool:
	var housing: Dictionary = state.get("player", {}).get("housing", {})
	if str(housing.get("residence", "")) == location_id:
		return true
	for contract_value: Variant in housing.get("contracts", []):
		if contract_value is Dictionary and str(contract_value.get("location_id", "")) == location_id and str(contract_value.get("status", "active")) == "active":
			return true
	return false


func _has_employment_access(state: Dictionary, location_id: String) -> bool:
	for active_job_value: Variant in state.get("player", {}).get("employment", {}).get("active_jobs", []):
		if not active_job_value is Dictionary or str(active_job_value.get("status", "active")) != "active":
			continue
		var job: Variant = _registry.get_content("jobs", str(active_job_value.get("job_id", "")))
		if not job is Dictionary:
			continue
		var workplace: String = str(job.get("location", "")).get_slice(".", 0)
		if _resolve_location_alias(workplace) == location_id:
			return true
	return false


func _resolve_location_alias(location_id: String) -> String:
	var world_package: Variant = _registry.get_package("port_alder_all_locations")
	if world_package is Dictionary:
		return str(world_package.get("legacy_aliases", {}).get(location_id, location_id))
	return location_id


func _room_definition(location: Dictionary, room_id: String) -> Dictionary:
	for room_value: Variant in location.get("rooms", []):
		if room_value is Dictionary and str(room_value.get("id", "")) == room_id:
			return room_value
	return {}


func _current_location_root(state: Dictionary) -> String:
	return str(state.get("world_state", {}).get("current_location", "")).get_slice(".", 0)


func _allowed() -> Dictionary:
	return {"allowed": true, "reason": ""}


func _denied(reason: String) -> Dictionary:
	return {"allowed": false, "reason": reason}
