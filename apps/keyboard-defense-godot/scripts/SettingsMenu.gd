extends Control

const ThemeColors = preload("res://ui/theme_colors.gd")

@onready var music_slider: HSlider = $Panel/Content/AudioSection/MusicRow/MusicSlider
@onready var music_value: Label = $Panel/Content/AudioSection/MusicRow/MusicValue
@onready var sfx_slider: HSlider = $Panel/Content/AudioSection/SFXRow/SFXSlider
@onready var sfx_value: Label = $Panel/Content/AudioSection/SFXRow/SFXValue
@onready var music_toggle: CheckButton = $Panel/Content/AudioSection/MusicToggle
@onready var sfx_toggle: CheckButton = $Panel/Content/AudioSection/SFXToggle
@onready var typing_sounds_toggle: CheckButton = $Panel/Content/AudioSection/TypingSoundsToggle

@onready var screen_shake_toggle: CheckButton = $Panel/Content/GameplaySection/ScreenShakeToggle
@onready var show_wpm_toggle: CheckButton = $Panel/Content/GameplaySection/ShowWPMToggle
@onready var show_accuracy_toggle: CheckButton = $Panel/Content/GameplaySection/ShowAccuracyToggle

@onready var back_button: Button = $Panel/Content/ButtonRow/BackButton
@onready var reset_button: Button = $Panel/Content/ButtonRow/ResetButton

@onready var settings = get_node("/root/SettingsManager")
@onready var audio_manager = get_node_or_null("/root/AudioManager")
@onready var game_controller = get_node("/root/GameController")

var _updating_ui := false

func _ready() -> void:
	_connect_signals()
	_load_from_settings()

func _connect_signals() -> void:
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	music_toggle.toggled.connect(_on_music_toggle)
	sfx_toggle.toggled.connect(_on_sfx_toggle)
	typing_sounds_toggle.toggled.connect(_on_typing_sounds_toggle)
	screen_shake_toggle.toggled.connect(_on_screen_shake_toggle)
	show_wpm_toggle.toggled.connect(_on_show_wpm_toggle)
	show_accuracy_toggle.toggled.connect(_on_show_accuracy_toggle)
	back_button.pressed.connect(_on_back_pressed)
	reset_button.pressed.connect(_on_reset_pressed)

func _load_from_settings() -> void:
	_updating_ui = true

	music_slider.value = settings.music_volume
	sfx_slider.value = settings.sfx_volume
	music_toggle.button_pressed = settings.music_enabled
	sfx_toggle.button_pressed = settings.sfx_enabled
	typing_sounds_toggle.button_pressed = settings.typing_sounds
	screen_shake_toggle.button_pressed = settings.screen_shake
	show_wpm_toggle.button_pressed = settings.show_wpm
	show_accuracy_toggle.button_pressed = settings.show_accuracy

	_update_volume_labels()
	_updating_ui = false

func _update_volume_labels() -> void:
	music_value.text = "%d%%" % int(music_slider.value * 100)
	sfx_value.text = "%d%%" % int(sfx_slider.value * 100)

func _on_music_slider_changed(value: float) -> void:
	_update_volume_labels()
	if not _updating_ui:
		settings.set_music_volume(value)

func _on_sfx_slider_changed(value: float) -> void:
	_update_volume_labels()
	if not _updating_ui:
		settings.set_sfx_volume(value)
		# Play a test sound
		if audio_manager != null:
			audio_manager.play_ui_confirm()

func _on_music_toggle(pressed: bool) -> void:
	if not _updating_ui:
		settings.set_music_enabled(pressed)

func _on_sfx_toggle(pressed: bool) -> void:
	if not _updating_ui:
		settings.set_sfx_enabled(pressed)

func _on_typing_sounds_toggle(pressed: bool) -> void:
	if not _updating_ui:
		settings.set_typing_sounds(pressed)

func _on_screen_shake_toggle(pressed: bool) -> void:
	if not _updating_ui:
		settings.set_screen_shake(pressed)

func _on_show_wpm_toggle(pressed: bool) -> void:
	if not _updating_ui:
		settings.set_show_wpm(pressed)

func _on_show_accuracy_toggle(pressed: bool) -> void:
	if not _updating_ui:
		settings.set_show_accuracy(pressed)

func _on_back_pressed() -> void:
	if audio_manager != null:
		audio_manager.play_ui_cancel()
	settings.save_settings()
	game_controller.go_to_menu()

func _on_reset_pressed() -> void:
	if audio_manager != null:
		audio_manager.play_ui_confirm()
	settings.reset_to_defaults()
	_load_from_settings()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		accept_event()
