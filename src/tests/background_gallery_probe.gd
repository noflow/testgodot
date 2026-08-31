extends Node


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
	for value: Variant in backgrounds:
		if not value is Dictionary:
			_fail("background registry contains a non-object entry")
			return
		var background: Dictionary = value
		var resolved: Dictionary = VNAssetService.resolve_background(str(background.get("location", "")), str(background.get("room", "")), "day")
		if resolved.get("texture") == null or bool(resolved.get("used_fallback", false)) or str(resolved.get("path", "")) != str(background.get("path", "")):
			_fail("production background did not resolve: %s" % background.get("id", "unknown"))
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
	if image == null or image.texture == null or counter == null or counter.text != "1 / 371" or location_option == null or location_option.item_count != 65 or room_option == null or room_option.item_count < 1:
		_fail("gallery did not initialize its first registered location and background")
		return
	gallery.call("_show_index", 370)
	await get_tree().process_frame
	if counter.text != "371 / 371" or image.texture == null:
		_fail("gallery could not display the final registered background")
		return
	print("PASS: Background Gallery resolves and reviews all 371 production backgrounds with a bounded texture cache.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	printerr("BACKGROUND GALLERY PROBE: %s" % message)
	get_tree().quit(1)
