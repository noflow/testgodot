extends Node

const NewGameStateFactoryScript: GDScript = preload("res://src/core/new_game_state_factory.gd")


func _ready() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	var errors: PackedStringArray = ContentRegistry.validate_foundation()
	if not errors.is_empty():
		_fail("content validation failed before gallery review")
		return
	var backgrounds: Array = ContentRegistry.get_all("vn_backgrounds")
	if backgrounds.size() != 371:
		_fail("expected 371 registered backgrounds, found %d" % backgrounds.size())
		return
	if not _check_clock_variants():
		return
	for value: Variant in backgrounds:
		if not value is Dictionary:
			_fail("background registry contains a non-object entry")
			return
		var background: Dictionary = value
		var resolved: Dictionary = VNAssetService.resolve_background(str(background.get("location", "")), str(background.get("room", "")), "day")
		if resolved.get("texture") == null or bool(resolved.get("used_fallback", false)) or str(resolved.get("path", "")) != str(background.get("path", "")):
			_fail("production background did not resolve: %s" % background.get("id", "unknown"))
			return
		for variant: String in background.get("variants", {}):
			var variant_result: Dictionary = VNAssetService.resolve_background(str(background.get("location", "")), str(background.get("room", "")), variant)
			if variant_result.get("texture") == null or str(variant_result.get("path", "")) != str(background["variants"][variant]):
				_fail("registered variant did not resolve: %s.%s" % [background["id"], variant])
				return
	var cache: Dictionary = VNAssetService.get("_texture_cache")
	if cache.size() > VNAssetService.MAX_TEXTURE_CACHE_ENTRIES:
		_fail("background review exceeded the bounded texture cache")
		return

	var gallery_scene: PackedScene = load(AppConstants.BACKGROUND_GALLERY_SCENE)
	if gallery_scene == null:
		_fail("background gallery scene did not load")
		return
	var gallery: Control = gallery_scene.instantiate()
	get_tree().root.add_child(gallery)
	await get_tree().process_frame
	await get_tree().process_frame
	var image: TextureRect = gallery.get_node_or_null("%BackgroundImage")
	var counter: Label = gallery.get_node_or_null("%CounterLabel")
	var location_option: OptionButton = gallery.get_node_or_null("%LocationOption")
	var room_option: OptionButton = gallery.get_node_or_null("%RoomOption")
	var variant_option: OptionButton = gallery.get_node_or_null("%VariantOption")
	if image == null or image.texture == null or counter == null or counter.text != "1 / 371" or location_option == null or location_option.item_count != 65 or room_option == null or room_option.item_count < 1:
		_fail("gallery did not initialize its first registered location and background")
		return
	if variant_option == null or variant_option.item_count != 2 or str(variant_option.get_selected_metadata()) != "day":
		_fail("gallery did not initialize its day/night selector")
		return
	var paired_index: int = backgrounds.find(ContentRegistry.get_content("vn_backgrounds", "hale_home.player_bedroom"))
	gallery.call("_show_index", paired_index)
	variant_option.select(1)
	variant_option.item_selected.emit(1)
	await get_tree().process_frame
	var path: Label = gallery.get_node("%PathLabel")
	var status: Label = gallery.get_node("%StatusLabel")
	if not path.text.ends_with("/player_bedroom_night.png") or status.text != "Night background loaded":
		_fail("gallery night selection did not load matching artwork")
		return
	gallery.call("_on_next_pressed")
	if variant_option.selected != 1:
		_fail("gallery lost the night selection when moving rooms")
		return
	for index: int in backgrounds.size():
		if not backgrounds[index].get("variants", {}).has("night"):
			gallery.call("_show_index", index)
			if "unavailable" not in status.text or path.text != str(backgrounds[index]["path"]):
				_fail("gallery did not identify a missing night variant and show its base")
				return
			break
	gallery.call("_show_index", 370)
	await get_tree().process_frame
	if counter.text != "371 / 371" or image.texture == null:
		_fail("gallery could not display the final registered background")
		return
	print("PASS: Background Gallery resolves all 371 rooms and registered variants, clock mapping, and day/night previews with a bounded texture cache.")
	get_tree().quit(0)


func _check_clock_variants() -> bool:
	var original_state: Dictionary = GameState.current_state.duplicate(true)
	var factory: RefCounted = NewGameStateFactoryScript.new(ContentRegistry)
	var state: Dictionary = factory.create_new_game({}, {"random_seed": 912})
	var expected: Dictionary = {
		"early_morning": "day", "morning": "day", "lunch": "day", "afternoon": "day",
		"evening": "day", "late_evening": "night", "night": "night",
	}
	for block: String in expected:
		state["clock"]["block"] = block
		GameState.replace_state(state.duplicate(true))
		for room: String in ["player_bedroom", "upstairs_landing", "entryway"]:
			var automatic: Dictionary = VNAssetService.resolve_background("hale_home", room)
			var explicit: Dictionary = VNAssetService.resolve_background("hale_home", room, str(expected[block]))
			var from_block: Dictionary = VNAssetService.resolve_background("hale_home", room, block)
			if automatic.get("resolved_variant") != expected[block] or automatic.get("path") != explicit.get("path") or from_block.get("path") != explicit.get("path"):
				_fail("clock variant mismatch for %s during %s" % [room, block])
				return false
	var day: Dictionary = VNAssetService.resolve_background("hale_home", "player_bedroom", "day")
	if not str(day.get("path", "")).ends_with("/player_bedroom.png"):
		_fail("explicit day override was ignored at night")
		return false
	var bedroom: Dictionary = ContentRegistry.get_content("vn_backgrounds", "hale_home.player_bedroom")
	var original_variants: Dictionary = bedroom["variants"].duplicate(true)
	# Temporary fixtures test authored-block priority and a broken optional path.
	bedroom["variants"]["late_evening"] = original_variants["day"]
	var exact: Dictionary = VNAssetService.resolve_background("hale_home", "player_bedroom", "late_evening")
	bedroom["variants"]["late_evening"] = "res://assets/art/backgrounds/missing_variant_fixture.png"
	var block_fallback: Dictionary = VNAssetService.resolve_background("hale_home", "player_bedroom", "late_evening")
	bedroom["variants"]["night"] = "res://assets/art/backgrounds/missing_variant_fixture.png"
	var base_fallback: Dictionary = VNAssetService.resolve_background("hale_home", "player_bedroom", "night")
	bedroom["variants"] = original_variants
	GameState.replace_state(original_state)
	if exact.get("resolved_variant") != "late_evening" or exact.get("path") != original_variants["day"] or block_fallback.get("path") != original_variants["night"]:
		_fail("exact block priority or missing-block fallback failed")
		return false
	if base_fallback.get("path") != original_variants["day"] or base_fallback.get("used_fallback") or base_fallback.get("resolved_variant") != "base":
		_fail("broken night variant did not safely fall back to the room's base art")
		return false
	return true


func _fail(message: String) -> void:
	printerr("BACKGROUND GALLERY PROBE: %s" % message)
	get_tree().quit(1)
