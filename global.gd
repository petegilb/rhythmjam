extends Node

var hard_mode := false

# Audio/visual sync calibration, in seconds
var audio_calibration := 0.0

const SETTINGS_PATH := "user://settings.cfg"

func _ready() -> void:
	_load_settings()

func set_audio_calibration(value: float) -> void:
	audio_calibration = value
	_save_settings()

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		audio_calibration = cfg.get_value("audio", "calibration", 0.0)

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "calibration", audio_calibration)
	cfg.save(SETTINGS_PATH)
