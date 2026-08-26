extends RefCounted
class_name PortAlderCharacterCreationValidator

const CREATION_PACKAGE: String = "port_alder_character_creation"
const ECONOMY_PACKAGE: String = "port_alder_economy_system"

var _registry: Node


func _init(content_registry: Node) -> void:
	_registry = content_registry


func validate_choices(choices: Dictionary) -> Dictionary:
	var errors: PackedStringArray = []
	var fields: Dictionary = {}
	var config: Dictionary = _registry.get_package(CREATION_PACKAGE)
	var rules: Dictionary = config.get("rules", {})

	_validate_name("first_name", "First name", choices, errors, fields)
	_validate_name("last_name", "Last name", choices, errors, fields)
	_validate_birth_date(str(choices.get("birth_date", "")), config, errors, fields)
	_validate_appearance(choices.get("appearance", {}), config, errors, fields)
	_validate_selection("positive_traits", "positive traits", choices, config.get("positive_traits", []), int(rules.get("positive_traits", 3)), errors, fields)
	_validate_selection("challenging_traits", "challenging traits", choices, config.get("challenging_traits", []), int(rules.get("challenging_traits", 3)), errors, fields)
	_validate_selection("core_values", "core values", choices, config.get("core_values", []), int(rules.get("core_values", 3)), errors, fields)
	_validate_selection("hobbies", "hobbies", choices, config.get("hobbies", []), int(rules.get("hobbies", 2)), errors, fields)
	_validate_single_choice("archetype", "starting archetype", choices, config.get("archetypes", []), errors, fields)
	_validate_single_choice(
		"financial_background",
		"financial background",
		choices,
		_registry.get_package(ECONOMY_PACKAGE).get("starting_budgets", []),
		errors,
		fields
	)

	return {"valid": errors.is_empty(), "errors": errors, "fields": fields}


func age_on_opening_date(birth_date: String) -> int:
	var parsed: Dictionary = _parse_date(birth_date)
	if parsed.is_empty():
		return -1
	var config: Dictionary = _registry.get_package(CREATION_PACKAGE)
	var opening: Dictionary = config.get("opening_reference_date", {})
	var age: int = int(opening.get("year", 0)) - int(parsed["year"])
	if [int(opening.get("month", 0)), int(opening.get("day", 0))] < [int(parsed["month"]), int(parsed["day"])]:
		age -= 1
	return age


func birthday_from_birth_date(birth_date: String) -> String:
	var parsed: Dictionary = _parse_date(birth_date)
	return "" if parsed.is_empty() else "%02d-%02d" % [parsed["month"], parsed["day"]]


func birth_date_for_birthday(month: int, day: int) -> String:
	var config: Dictionary = _registry.get_package(CREATION_PACKAGE)
	var opening: Dictionary = config.get("opening_reference_date", {})
	var required_age: int = int(config.get("rules", {}).get("required_age", 18))
	var birth_year: int = int(opening.get("year", 0)) - required_age
	var opening_birthday: Array[int] = [int(opening.get("month", 0)), int(opening.get("day", 0))]
	if [month, day] > opening_birthday:
		birth_year -= 1
	if month < 1 or month > 12 or day < 1 or day > _days_in_month(month, birth_year):
		return ""
	var birth_date: String = "%04d-%02d-%02d" % [birth_year, month, day]
	return birth_date if age_on_opening_date(birth_date) == required_age else ""


func valid_birth_days(month: int) -> PackedInt32Array:
	var result: PackedInt32Array = []
	for day: int in range(1, 32):
		if not birth_date_for_birthday(month, day).is_empty():
			result.append(day)
	return result


func _validate_name(
	field: String,
	label: String,
	choices: Dictionary,
	errors: PackedStringArray,
	fields: Dictionary
) -> void:
	var value: String = str(choices.get(field, "")).strip_edges()
	if value.is_empty():
		_add_error(field, "%s is required." % label, errors, fields)
	elif value.length() > 24:
		_add_error(field, "%s must be 24 characters or fewer." % label, errors, fields)


func _validate_birth_date(
	birth_date: String,
	config: Dictionary,
	errors: PackedStringArray,
	fields: Dictionary
) -> void:
	if _parse_date(birth_date).is_empty():
		_add_error("birth_date", "Birth date must use YYYY-MM-DD and be a real calendar date.", errors, fields)
		return
	var required_age: int = int(config.get("rules", {}).get("required_age", 18))
	if age_on_opening_date(birth_date) != required_age:
		_add_error("birth_date", "The protagonist must be exactly %d on August 20, 2026." % required_age, errors, fields)


func _validate_appearance(
	appearance: Variant,
	config: Dictionary,
	errors: PackedStringArray,
	fields: Dictionary
) -> void:
	if not appearance is Dictionary:
		appearance = {}
	for field: String in ["face", "eye_color", "skin_tone", "hairstyle", "height", "body_type"]:
		var valid_ids: Array = _ids(config.get("appearance_options", {}).get(field, []))
		if str(appearance.get(field, "")) not in valid_ids:
			_add_error(field, "%s is required." % field.replace("_", " ").capitalize(), errors, fields)


func _validate_selection(
	field: String,
	label: String,
	choices: Dictionary,
	definitions: Array,
	required_count: int,
	errors: PackedStringArray,
	fields: Dictionary
) -> void:
	var selection: Variant = choices.get(field, [])
	if not selection is Array:
		selection = []
	var unique: Dictionary = {}
	var valid_ids: Array = _ids(definitions)
	for value: Variant in selection:
		unique[str(value)] = true
	if unique.size() != required_count:
		_add_error(field, "Choose exactly %d %s." % [required_count, label], errors, fields)
		return
	for value: Variant in unique:
		if value not in valid_ids:
			_add_error(field, "Selection contains an unknown %s." % label, errors, fields)
			return


func _validate_single_choice(
	field: String,
	label: String,
	choices: Dictionary,
	definitions: Array,
	errors: PackedStringArray,
	fields: Dictionary
) -> void:
	if str(choices.get(field, "")) not in _ids(definitions):
		_add_error(field, "Choose a %s." % label, errors, fields)


func _parse_date(value: String) -> Dictionary:
	var parts: PackedStringArray = value.split("-")
	if parts.size() != 3 or not parts[0].is_valid_int() or not parts[1].is_valid_int() or not parts[2].is_valid_int():
		return {}
	var year: int = int(parts[0])
	var month: int = int(parts[1])
	var day: int = int(parts[2])
	if year < 1 or month < 1 or month > 12 or day < 1 or day > _days_in_month(month, year):
		return {}
	return {"year": year, "month": month, "day": day}


func _days_in_month(month: int, year: int) -> int:
	if month in [4, 6, 9, 11]:
		return 30
	if month == 2:
		return 29 if year % 400 == 0 or (year % 4 == 0 and year % 100 != 0) else 28
	return 31


func _ids(definitions: Array) -> Array:
	var result: Array = []
	for definition: Variant in definitions:
		if definition is Dictionary:
			result.append(str(definition.get("id", "")))
	return result


func _add_error(
	field: String,
	message: String,
	errors: PackedStringArray,
	fields: Dictionary
) -> void:
	errors.append(message)
	fields[field] = message
