extends Node

var _base_registry: Node
var _fixtures: Dictionary


func _init(base_registry: Node, fixtures: Dictionary) -> void:
	_base_registry = base_registry
	_fixtures = fixtures.duplicate(true)


func get_content(collection_name: String, content_id: String) -> Variant:
	var collection: Dictionary = _fixtures.get(collection_name, {})
	if collection.has(content_id):
		return collection[content_id]
	return _base_registry.get_content(collection_name, content_id)


func get_all(collection_name: String) -> Array:
	var results: Array = _base_registry.get_all(collection_name)
	for fixture: Variant in _fixtures.get(collection_name, {}).values():
		results.append(fixture)
	return results


func get_character(character_id: String) -> Variant:
	return _base_registry.get_character(character_id)


func get_location(location_id: String) -> Variant:
	return _base_registry.get_location(location_id)


func get_package(package_id: String) -> Variant:
	return _base_registry.get_package(package_id)


func get_document(path: String) -> Variant:
	return _base_registry.get_document(path)


func get_loaded_package_ids() -> PackedStringArray:
	return _base_registry.get_loaded_package_ids()
