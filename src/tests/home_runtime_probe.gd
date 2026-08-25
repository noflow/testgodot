extends Node

const NewGameStateFactoryScript: GDScript = preload("res://src/core/new_game_state_factory.gd")


func _ready() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	var errors: PackedStringArray = ContentRegistry.validate_foundation()
	if not errors.is_empty():
		printerr("PROBE: content validation failed")
		get_tree().quit(1)
		return
	var factory: RefCounted = NewGameStateFactoryScript.new(ContentRegistry)
	GameState.replace_state(factory.create_new_game({}, {"random_seed": 909}))
	var scene: PackedScene = load("res://scenes/locations/hale_home.tscn")
	var instance: Node = scene.instantiate()
	get_tree().root.add_child(instance)
	await get_tree().process_frame
	await get_tree().process_frame
	if instance.get_node_or_null("RoomAreas/PlayerBedroom") == null or instance.get_node_or_null("Walls") == null:
		printerr("PROBE: runtime rooms or walls were not created")
		get_tree().quit(1)
		return
	print("PASS: Hale home runtime created rooms, walls, HUD, and active player state.")
	get_tree().quit(0)
