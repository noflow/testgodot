extends RefCounted
class_name NewGameStateFactory

const TEMPLATE_PATH: String = "res://content/runtime/new_game_state.json"
const ECONOMY_PACKAGE: String = "port_alder_economy_system"
const INVENTORY_PACKAGE: String = "port_alder_inventory_system"
const OPENING_WEEK_PACKAGE: String = "opening_week_calendar"

var _registry: Node


func _init(content_registry: Node) -> void:
	_registry = content_registry


func create_new_game(player_choices: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var template_document: Variant = _registry.get_document(TEMPLATE_PATH)
	if not template_document is Dictionary:
		return {}
	var source_template: Variant = template_document.get("new_game_template")
	if not source_template is Dictionary:
		return {}

	var state: Dictionary = source_template.duplicate(true)
	var random_seed: int = int(options.get("random_seed", _generate_seed()))
	state["world_state"]["random_seed"] = random_seed
	_apply_metadata(state, options)
	_apply_player_choices(state, player_choices)
	_apply_trait_modifiers(state)
	_apply_hidden_health(state, random_seed)
	_apply_financial_background(state, player_choices)
	_apply_inventory(state, player_choices)
	_apply_opening_weather(state)
	_apply_relationship_defaults(state)
	_apply_content_manifest(state)
	state["calendar_state"]["events"][0]["id"] = "opening_future_talk_y1_08_20"
	return state


func _apply_metadata(state: Dictionary, options: Dictionary) -> void:
	var timestamp: String = str(options.get("timestamp_utc", Time.get_datetime_string_from_system(true, false)))
	var metadata: Dictionary = state["metadata"]
	metadata["save_id"] = str(options.get("save_id", _generate_save_id()))
	metadata["slot_id"] = str(options.get("slot_id", "autosave_0"))
	metadata["created_at_utc"] = timestamp
	metadata["updated_at_utc"] = timestamp
	metadata["build_version"] = AppConstants.APP_VERSION
	metadata["checksum"] = null


func _apply_player_choices(state: Dictionary, choices: Dictionary) -> void:
	var player: Dictionary = state["player"]
	var identity: Dictionary = player["identity"]
	identity["first_name"] = str(choices.get("first_name", "Alex"))
	identity["last_name"] = str(choices.get("last_name", "Hale"))
	var birth_date: String = str(choices.get("birth_date", ""))
	identity["birthday"] = str(choices.get("birthday", birth_date.right(5) if birth_date.length() == 10 else "08-20"))
	identity["birth_date_reference"] = birth_date if not birth_date.is_empty() else null

	var appearance_defaults: Dictionary = {
		"face": "face_01",
		"eye_color": "brown",
		"skin_tone": "medium",
		"hairstyle": "short_01",
		"height": "average",
		"body_type": "average",
	}
	var appearance: Dictionary = player["appearance"]
	var selected_appearance: Dictionary = choices.get("appearance", {})
	for field: Variant in appearance_defaults:
		appearance[field] = str(selected_appearance.get(field, appearance_defaults[field]))

	var selected_traits: Dictionary = player["selected_traits"]
	selected_traits["positive"] = _copy_array(choices.get("positive_traits", []), 3)
	selected_traits["challenging"] = _copy_array(choices.get("challenging_traits", []), 3)
	selected_traits["core_values"] = _copy_array(choices.get("core_values", []))
	selected_traits["hobbies"] = _copy_array(choices.get("hobbies", []))
	selected_traits["archetype"] = str(choices.get("archetype", "undecided"))


func _apply_trait_modifiers(state: Dictionary) -> void:
	var creation_package: Variant = _registry.get_package("port_alder_character_creation")
	if not creation_package is Dictionary:
		return
	var player: Dictionary = state["player"]
	for collection_name: String in ["positive_traits", "challenging_traits"]:
		for trait_id: Variant in player["selected_traits"].get(collection_name.trim_suffix("_traits"), []):
			var trait_definition: Dictionary = _find_by_id(creation_package.get(collection_name, []), str(trait_id))
			for path: Variant in trait_definition.get("modifiers", {}):
				var parts: PackedStringArray = str(path).split(".")
				if parts.size() != 2 or not player.has(parts[0]) or not player[parts[0]].has(parts[1]):
					continue
				var maximum: float = 100.0 if parts[0] == "needs" else 250.0
				player[parts[0]][parts[1]] = clampf(
					float(player[parts[0]][parts[1]]) + float(trait_definition["modifiers"][path]),
					0.0,
					maximum
				)


func _apply_financial_background(state: Dictionary, choices: Dictionary) -> void:
	var background_id: String = str(choices.get("financial_background", "standard_background"))
	var economy_package: Variant = _registry.get_package(ECONOMY_PACKAGE)
	if not economy_package is Dictionary:
		return
	var background: Dictionary = _find_by_id(economy_package.get("starting_budgets", []), background_id)
	if background.is_empty():
		background_id = "standard_background"
		background = _find_by_id(economy_package.get("starting_budgets", []), background_id)

	var player: Dictionary = state["player"]
	player["economy"]["financial_background"] = background_id
	player["economy"]["accounts"] = background.get("accounts", {}).duplicate(true)
	player["transportation"]["family_car_permission"] = background.get("family_car_access", "permission_required")
	player["flags"]["weekly_school_allowance"] = background.get("weekly_school_allowance", 0)


func _apply_hidden_health(state: Dictionary, random_seed: int) -> void:
	var generator: RandomNumberGenerator = RandomNumberGenerator.new()
	generator.seed = random_seed
	var player: Dictionary = state["player"]
	player["health"]["immunity_profile"] = {
		"baseline": generator.randi_range(40, 70),
		"seasonal_variation": generator.randi_range(-8, 8),
	}
	player["health"]["recovery_profile"] = {
		"baseline": generator.randi_range(40, 70),
		"sleep_sensitivity": generator.randi_range(35, 75),
	}
	var fertility_tiers: PackedStringArray = ["low", "typical", "typical", "high", "super_fertile"]
	player["reproductive_health"]["fertility_tier"] = fertility_tiers[generator.randi_range(0, fertility_tiers.size() - 1)]
	player["reproductive_health"]["sti_status"] = []


func _apply_inventory(state: Dictionary, choices: Dictionary) -> void:
	var inventory_package: Variant = _registry.get_package(INVENTORY_PACKAGE)
	if not inventory_package is Dictionary:
		return
	var background_id: String = state["player"]["economy"]["financial_background"]
	var loadout: Dictionary = _find_by_key(inventory_package.get("starting_loadouts", []), "budget", background_id)
	var player_inventory: Dictionary = state["player"]["inventory"]
	player_inventory["containers"] = inventory_package.get("containers", []).duplicate(true)
	player_inventory["starting_loadout"] = loadout.get("items", []).duplicate(true)
	player_inventory["equipped_outfit"] = choices.get("equipped_outfit", {}).duplicate(true)
	for container: Variant in player_inventory["containers"]:
		if container is Dictionary:
			container["items"] = []
	for entry: Variant in player_inventory["starting_loadout"]:
		if not entry is Dictionary:
			continue
		var item_id: String = str(entry.get("item", ""))
		var item: Variant = _registry.get_content("items", item_id)
		var container_id: String = "carried_inventory"
		if item is Dictionary:
			match str(item.get("category", "")):
				"clothing":
					container_id = "wardrobe_storage"
				"food", "drink":
					container_id = "kitchen_storage"
				"hygiene", "medicine":
					container_id = "bathroom_storage"
		_add_starting_item(player_inventory["containers"], container_id, item_id, int(entry.get("quantity", 1)))


func _apply_opening_weather(state: Dictionary) -> void:
	var opening_week: Variant = _registry.get_package(OPENING_WEEK_PACKAGE)
	if not opening_week is Dictionary:
		return
	var days: Array = opening_week.get("days", [])
	if not days.is_empty() and days[0] is Dictionary:
		state["world_state"]["weather"] = days[0].get("weather", {}).duplicate(true)


func _apply_relationship_defaults(state: Dictionary) -> void:
	var relationships: Dictionary = {}
	for npc_state: Variant in state.get("npc_states", []):
		if not npc_state is Dictionary:
			continue
		var character_id: String = str(npc_state.get("character_id", ""))
		var character: Variant = _registry.get_character(character_id)
		if character is Dictionary:
			relationships[character_id] = character.get("relationship_defaults", {}).duplicate(true)
	state["relationships"] = relationships


func _apply_content_manifest(state: Dictionary) -> void:
	state["content_state"]["loaded_packages"] = Array(_registry.get_loaded_package_ids())


func _find_by_id(entries: Array, content_id: String) -> Dictionary:
	return _find_by_key(entries, "id", content_id)


func _find_by_key(entries: Array, key: String, expected: String) -> Dictionary:
	for entry: Variant in entries:
		if entry is Dictionary and str(entry.get(key, "")) == expected:
			return entry
	return {}


func _add_starting_item(containers: Array, container_id: String, item_id: String, quantity: int) -> void:
	for container: Variant in containers:
		if container is Dictionary and str(container.get("id", "")) == container_id:
			container["items"].append({"item_id": item_id, "quantity": quantity, "item_state": {}})
			return


func _copy_array(value: Variant, maximum_size: int = -1) -> Array:
	if not value is Array:
		return []
	var result: Array = value.duplicate(true)
	if maximum_size >= 0:
		result.resize(mini(result.size(), maximum_size))
	return result


func _generate_seed() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0) ^ randi()


func _generate_save_id() -> String:
	return "save-%x-%x" % [int(Time.get_unix_time_from_system()), randi()]
