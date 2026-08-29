extends Node

const ART_PACKAGE_ID: String = "port_alder_vn_art"
const DEFAULT_BACKGROUND_PATH: String = "res://assets/art/backgrounds/_shared/coastal_city.svg"
const DEFAULT_PORTRAIT_PATH: String = "res://assets/art/characters/_fallback_portrait.svg"

var _texture_cache: Dictionary = {}
var _audio_cache: Dictionary = {}


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


func has_portrait(character_id: String, portrait_id: String) -> bool:
	if portrait_id.is_empty():
		return false
	var character: Variant = ContentRegistry.get_character(character_id)
	if not character is Dictionary:
		return false
	for entry: Variant in character.get("asset_refs", {}).get("portraits", []):
		if entry is Dictionary and str(entry.get("id", "default")) == portrait_id:
			return true
	return false


func resolve_audio(cue_id: String, cue_type: String = "sfx", character_id: String = "") -> Dictionary:
	var clean_id: String = cue_id.strip_edges()
	var default_bus: String = _default_audio_bus(cue_type)
	if clean_id.is_empty():
		return {"id": "", "path": "", "stream": null, "bus": default_bus, "loop": false, "resolved": false}
	if clean_id.to_lower() in ["none", "stop", "silence"]:
		return {"id": clean_id, "path": "", "stream": null, "bus": default_bus, "loop": false, "resolved": true, "stop": true}

	var definition: Dictionary = {}
	if not character_id.is_empty():
		var character: Variant = ContentRegistry.get_character(character_id)
		if character is Dictionary:
			for entry: Variant in character.get("asset_refs", {}).get("audio", []):
				if entry is Dictionary and str(entry.get("id", "")) == clean_id:
					definition = entry
					break
	if definition.is_empty():
		var global_definition: Variant = ContentRegistry.get_content("vn_audio", clean_id)
		if global_definition is Dictionary:
			definition = global_definition

	var path: String = clean_id if clean_id.begins_with("res://") else str(definition.get("path", ""))
	var stream: AudioStream = _load_audio(path)
	var bus: String = str(definition.get("bus", default_bus))
	if AudioServer.get_bus_index(bus) < 0:
		bus = default_bus
	return {
		"id": clean_id,
		"path": path,
		"stream": stream,
		"bus": bus,
		"loop": bool(definition.get("loop", cue_type in ["music", "ambience"])),
		"resolved": stream != null,
		"credit": str(definition.get("credit", "")),
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


func apply_audio(target: AudioStreamPlayer, cue_id: String, cue_type: String = "sfx", character_id: String = "", restart: bool = false) -> Dictionary:
	var resolved: Dictionary = resolve_audio(cue_id, cue_type, character_id)
	target.set_meta("cue_id", str(resolved.get("id", "")))
	target.set_meta("cue_path", str(resolved.get("path", "")))
	target.set_meta("cue_resolved", bool(resolved.get("resolved", false)))
	target.set_meta("cue_loop", bool(resolved.get("loop", false)))
	if bool(resolved.get("stop", false)):
		target.stop()
		target.stream = null
		return resolved
	var stream: AudioStream = resolved.get("stream")
	if stream == null:
		return resolved
	target.bus = str(resolved.get("bus", _default_audio_bus(cue_type)))
	if target.stream == stream and target.playing and not restart:
		return resolved
	target.stream = stream
	target.play()
	return resolved


func clear_cache() -> void:
	_texture_cache.clear()
	_audio_cache.clear()


func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _texture_cache.has(path):
		return _texture_cache[path]
	var resource: Resource = load(path) if ResourceLoader.exists(path) else null
	var texture: Texture2D = resource if resource is Texture2D else null
	_texture_cache[path] = texture
	return texture


func _load_audio(path: String) -> AudioStream:
	if path.is_empty():
		return null
	if _audio_cache.has(path):
		return _audio_cache[path]
	var resource: Resource = load(path) if ResourceLoader.exists(path) else null
	var stream: AudioStream = resource if resource is AudioStream else null
	_audio_cache[path] = stream
	return stream


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


func _default_audio_bus(cue_type: String) -> String:
	match cue_type:
		"music":
			return "Music"
		"ambience":
			return "Ambience"
		_:
			return "UI"
