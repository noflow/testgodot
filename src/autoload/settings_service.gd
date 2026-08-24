extends Node

const SETTINGS_PATH: String = "user://settings.cfg"

var text_scale: float = 1.0
var reduce_motion: bool = false
var high_contrast: bool = false
var master_volume: float = 1.0
var music_volume: float = 0.8
var ambience_volume: float = 0.8
var ui_volume: float = 0.9
var voice_volume: float = 1.0


func _ready() -> void:
	load_settings()
	apply_audio_settings()


func load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return

	text_scale = clampf(config.get_value("accessibility", "text_scale", 1.0), 1.0, 1.75)
	reduce_motion = config.get_value("accessibility", "reduce_motion", false)
	high_contrast = config.get_value("accessibility", "high_contrast", false)
	master_volume = clampf(config.get_value("audio", "master", 1.0), 0.0, 1.0)
	music_volume = clampf(config.get_value("audio", "music", 0.8), 0.0, 1.0)
	ambience_volume = clampf(config.get_value("audio", "ambience", 0.8), 0.0, 1.0)
	ui_volume = clampf(config.get_value("audio", "ui", 0.9), 0.0, 1.0)
	voice_volume = clampf(config.get_value("audio", "voice", 1.0), 0.0, 1.0)


func save_settings() -> Error:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("accessibility", "text_scale", text_scale)
	config.set_value("accessibility", "reduce_motion", reduce_motion)
	config.set_value("accessibility", "high_contrast", high_contrast)
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "ambience", ambience_volume)
	config.set_value("audio", "ui", ui_volume)
	config.set_value("audio", "voice", voice_volume)
	return config.save(SETTINGS_PATH)


func apply_audio_settings() -> void:
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("Ambience", ambience_volume)
	_set_bus_volume("UI", ui_volume)
	_set_bus_volume("Voice", voice_volume)


func _set_bus_volume(bus_name: String, linear_volume: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(linear_volume, 0.0001)))
	AudioServer.set_bus_mute(bus_index, linear_volume <= 0.0)

