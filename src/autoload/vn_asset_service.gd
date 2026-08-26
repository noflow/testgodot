extends Node

const ART_PACKAGE_ID: String = "port_alder_vn_art"
const DEFAULT_BACKGROUND_PATH: String = "res://assets/art/backgrounds/_shared/coastal_city.svg"
const DEFAULT_PORTRAIT_PATH: String = "res://assets/art/characters/_fallback_portrait.svg"

var _texture_cache: Dictionary = {}


func resolve_background(location_id: String, room_id: String, variant: String = "") -> Dictionary:
	var asset_id: String = "%s.%s" % [location_id, room_id]
	var definition: Variant = ContentRegistry.get_content("vn_backgrounds", asset_id)
	var path: String = ""
	var used_fallback: bool = false
	if definition is Dictionary:
		if not variant.is_empty():
			path = str(definition.get("variants", {}).get(variant, ""))
		if path.is_empty():
			path = str(definition.get("path", ""))
	if path.is_empty():
		path = _convention_background_path(location_id, room_id)
	if not _asset_exists(path):
		path = _fallback_path("background", DEFAULT_BACKGROUND_PATH)
		used_fallback = true
	return {
		"id": asset_id,
		"path": path,
		"texture": _load_texture(path),
		"used_fallback": used_fallback,
		"credit": definition.get("credit", "") if definition is Dictionary else "",
	}


func resolve_portrait(character_id: String, portrait_id: String = "default") -> Dictionary:
	var character: Variant = ContentRegistry.get_character(character_id)
	var selected: Dictionary = {}
	if character is Dictionary:
		for entry: Variant in character.get("asset_refs", {}).get("portraits", []):
			if entry is Dictionary and str(entry.get("id", "default")) == portrait_id:
				selected = entry
				break
		if selected.is_empty():
			for entry: Variant in character.get("asset_refs", {}).get("portraits", []):
				if entry is Dictionary and str(entry.get("id", "default")) == "default":
					selected = entry
					break
	var path: String = str(selected.get("path", ""))
	var used_fallback: bool = false
	if path.is_empty():
		path = _convention_portrait_path(character_id, portrait_id)
	if not _asset_exists(path):
		path = _fallback_path("portrait", DEFAULT_PORTRAIT_PATH)
		used_fallback = true
	elif path == _fallback_path("portrait", DEFAULT_PORTRAIT_PATH):
		used_fallback = true
	var accent_text: String = str(selected.get("accent", "67c6c3"))
	if accent_text.begins_with("#"):
		accent_text = accent_text.trim_prefix("#")
	return {
		"character_id": character_id,
		"portrait_id": portrait_id,
		"path": path,
		"texture": _load_texture(path),
		"accent": Color(accent_text) if Color.html_is_valid(accent_text) else Color("67c6c3"),
		"used_fallback": used_fallback,
		"anchor": str(selected.get("anchor", "center")),
	}


func apply_background(target: TextureRect, location_id: String, room_id: String, variant: String = "") -> Dictionary:
	var resolved: Dictionary = resolve_background(location_id, room_id, variant)
	target.texture = resolved.get("texture")
	target.visible = target.texture != null
	return resolved


func apply_portrait(target: TextureRect, character_id: String, portrait_id: String = "default") -> Dictionary:
	var resolved: Dictionary = resolve_portrait(character_id, portrait_id)
	target.texture = resolved.get("texture")
	target.self_modulate = resolved.get("accent", Color.WHITE) if bool(resolved.get("used_fallback", false)) else Color.WHITE
	target.visible = target.texture != null
	return resolved


func clear_cache() -> void:
	_texture_cache.clear()


func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _texture_cache.has(path):
		return _texture_cache[path]
	var resource: Resource = load(path) if ResourceLoader.exists(path) else null
	var texture: Texture2D = resource if resource is Texture2D else null
	_texture_cache[path] = texture
	return texture


func _asset_exists(path: String) -> bool:
	return not path.is_empty() and (ResourceLoader.exists(path) or FileAccess.file_exists(path))


func _convention_background_path(location_id: String, room_id: String) -> String:
	for extension: String in ["webp", "png", "jpg", "svg"]:
		var candidate: String = "res://assets/art/backgrounds/%s/%s.%s" % [location_id, room_id, extension]
		if _asset_exists(candidate):
			return candidate
	return ""


func _convention_portrait_path(character_id: String, portrait_id: String) -> String:
	for extension: String in ["webp", "png", "svg"]:
		var candidate: String = "res://assets/art/characters/%s/%s.%s" % [character_id, portrait_id, extension]
		if _asset_exists(candidate):
			return candidate
	return ""


func _fallback_path(asset_type: String, default_path: String) -> String:
	var package: Variant = ContentRegistry.get_package(ART_PACKAGE_ID)
	if package is Dictionary:
		var configured: String = str(package.get("fallbacks", {}).get(asset_type, ""))
		if _asset_exists(configured):
			return configured
	return default_path
