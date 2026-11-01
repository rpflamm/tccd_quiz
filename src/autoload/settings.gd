extends Node
## User settings stored in user://settings.cfg.

signal changed

const PATH := "user://settings.cfg"

var music_volume := 0.6
var sfx_volume := 0.8
var fullscreen := false
var screen_shake := true
var reduced_motion := false
var scoring := "all_or_nothing"     # or "partial" (exam simulation only)
var practice_count := 10


func _ready() -> void:
	load_settings()
	apply()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	music_volume = cfg.get_value("audio", "music", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)
	fullscreen = cfg.get_value("video", "fullscreen", fullscreen)
	screen_shake = cfg.get_value("video", "screen_shake", screen_shake)
	reduced_motion = cfg.get_value("video", "reduced_motion", reduced_motion)
	scoring = cfg.get_value("game", "scoring", scoring)
	practice_count = cfg.get_value("game", "practice_count", practice_count)


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("video", "screen_shake", screen_shake)
	cfg.set_value("video", "reduced_motion", reduced_motion)
	cfg.set_value("game", "scoring", scoring)
	cfg.set_value("game", "practice_count", practice_count)
	cfg.save(PATH)
	apply()
	changed.emit()


func apply() -> void:
	_set_bus("Music", music_volume)
	_set_bus("SFX", sfx_volume)
	if OS.get_name() != "Web" and not DisplayServer.get_name() == "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)


func toggle_fullscreen() -> void:
	fullscreen = not fullscreen
	save()


func _set_bus(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(idx, linear <= 0.001)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		toggle_fullscreen()
