extends Node
## SettingsManager - Handles settings persistence and state

const SETTINGS_PATH := "user://settings.cfg"

# Default values
const DEFAULT_MUSIC_VOLUME := 0.8
const DEFAULT_SFX_VOLUME := 1.0
const DEFAULT_MUSIC_ENABLED := true
const DEFAULT_SFX_ENABLED := true
const DEFAULT_SCREEN_SHAKE := true
const DEFAULT_SHOW_WPM := true
const DEFAULT_SHOW_ACCURACY := true
const DEFAULT_TYPING_SOUNDS := true

# Current settings
var music_volume: float = DEFAULT_MUSIC_VOLUME
var sfx_volume: float = DEFAULT_SFX_VOLUME
var music_enabled: bool = DEFAULT_MUSIC_ENABLED
var sfx_enabled: bool = DEFAULT_SFX_ENABLED
var screen_shake: bool = DEFAULT_SCREEN_SHAKE
var show_wpm: bool = DEFAULT_SHOW_WPM
var show_accuracy: bool = DEFAULT_SHOW_ACCURACY
var typing_sounds: bool = DEFAULT_TYPING_SOUNDS

signal settings_changed

func _ready() -> void:
	load_settings()
	_apply_audio_settings()

func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	if err != OK:
		# No settings file yet, use defaults
		return

	music_volume = config.get_value("audio", "music_volume", DEFAULT_MUSIC_VOLUME)
	sfx_volume = config.get_value("audio", "sfx_volume", DEFAULT_SFX_VOLUME)
	music_enabled = config.get_value("audio", "music_enabled", DEFAULT_MUSIC_ENABLED)
	sfx_enabled = config.get_value("audio", "sfx_enabled", DEFAULT_SFX_ENABLED)
	typing_sounds = config.get_value("audio", "typing_sounds", DEFAULT_TYPING_SOUNDS)

	screen_shake = config.get_value("gameplay", "screen_shake", DEFAULT_SCREEN_SHAKE)
	show_wpm = config.get_value("gameplay", "show_wpm", DEFAULT_SHOW_WPM)
	show_accuracy = config.get_value("gameplay", "show_accuracy", DEFAULT_SHOW_ACCURACY)

func save_settings() -> void:
	var config := ConfigFile.new()

	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "music_enabled", music_enabled)
	config.set_value("audio", "sfx_enabled", sfx_enabled)
	config.set_value("audio", "typing_sounds", typing_sounds)

	config.set_value("gameplay", "screen_shake", screen_shake)
	config.set_value("gameplay", "show_wpm", show_wpm)
	config.set_value("gameplay", "show_accuracy", show_accuracy)

	var err := config.save(SETTINGS_PATH)
	if err != OK:
		push_warning("Failed to save settings: %s" % error_string(err))

func _apply_audio_settings() -> void:
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager == null:
		return

	audio_manager.set_music_volume(music_volume)
	audio_manager.set_sfx_volume(sfx_volume)
	audio_manager.set_music_enabled(music_enabled)
	audio_manager.set_sfx_enabled(sfx_enabled)

func set_music_volume(value: float) -> void:
	music_volume = clamp(value, 0.0, 1.0)
	_apply_audio_settings()
	settings_changed.emit()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clamp(value, 0.0, 1.0)
	_apply_audio_settings()
	settings_changed.emit()

func set_music_enabled(value: bool) -> void:
	music_enabled = value
	_apply_audio_settings()
	settings_changed.emit()

func set_sfx_enabled(value: bool) -> void:
	sfx_enabled = value
	_apply_audio_settings()
	settings_changed.emit()

func set_typing_sounds(value: bool) -> void:
	typing_sounds = value
	settings_changed.emit()

func set_screen_shake(value: bool) -> void:
	screen_shake = value
	settings_changed.emit()

func set_show_wpm(value: bool) -> void:
	show_wpm = value
	settings_changed.emit()

func set_show_accuracy(value: bool) -> void:
	show_accuracy = value
	settings_changed.emit()

func reset_to_defaults() -> void:
	music_volume = DEFAULT_MUSIC_VOLUME
	sfx_volume = DEFAULT_SFX_VOLUME
	music_enabled = DEFAULT_MUSIC_ENABLED
	sfx_enabled = DEFAULT_SFX_ENABLED
	screen_shake = DEFAULT_SCREEN_SHAKE
	show_wpm = DEFAULT_SHOW_WPM
	show_accuracy = DEFAULT_SHOW_ACCURACY
	typing_sounds = DEFAULT_TYPING_SOUNDS
	_apply_audio_settings()
	settings_changed.emit()
