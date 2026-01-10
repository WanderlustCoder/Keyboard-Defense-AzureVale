extends Control

const ThemeColors = preload("res://ui/theme_colors.gd")
const HOVER_SCALE := 1.05
const HOVER_DURATION := 0.1
const PRESS_SCALE := 0.95
const PRESS_DURATION := 0.05
const PULSE_COLOR := Color(0.9, 0.85, 0.4, 1.0)  # Golden highlight
const PULSE_DURATION := 0.3

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
var reduced_motion_toggle: CheckButton = null
var high_contrast_toggle: CheckButton = null
var large_text_toggle: CheckButton = null
var _button_tweens: Dictionary = {}  # button -> tween
var _label_tweens: Dictionary = {}  # label -> tween

func _ready() -> void:
	_connect_signals()
	_create_accessibility_section()
	_load_from_settings()
	_setup_button_hover_effects()

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

	# Accessibility settings
	if reduced_motion_toggle != null:
		reduced_motion_toggle.button_pressed = settings.reduced_motion
	if high_contrast_toggle != null:
		high_contrast_toggle.button_pressed = settings.high_contrast
	if large_text_toggle != null:
		large_text_toggle.button_pressed = settings.large_text

	_update_volume_labels()
	_updating_ui = false

func _update_volume_labels() -> void:
	music_value.text = "%d%%" % int(music_slider.value * 100)
	sfx_value.text = "%d%%" % int(sfx_slider.value * 100)

func _on_music_slider_changed(value: float) -> void:
	_update_volume_labels()
	if not _updating_ui:
		settings.set_music_volume(value)
		_pulse_label(music_value)

func _on_sfx_slider_changed(value: float) -> void:
	_update_volume_labels()
	if not _updating_ui:
		settings.set_sfx_volume(value)
		_pulse_label(sfx_value)
		# Play a test sound
		if audio_manager != null:
			audio_manager.play_ui_confirm()

func _on_music_toggle(pressed: bool) -> void:
	if not _updating_ui:
		settings.set_music_enabled(pressed)
		# Play feedback when enabling
		if audio_manager != null and pressed:
			audio_manager.play_ui_confirm()

func _on_sfx_toggle(pressed: bool) -> void:
	if not _updating_ui:
		settings.set_sfx_enabled(pressed)
		# Play feedback when enabling (this will test that SFX works)
		if audio_manager != null and pressed:
			audio_manager.play_ui_confirm()

func _on_typing_sounds_toggle(pressed: bool) -> void:
	if not _updating_ui:
		settings.set_typing_sounds(pressed)
		if audio_manager != null:
			audio_manager.play_ui_confirm()

func _on_screen_shake_toggle(pressed: bool) -> void:
	if not _updating_ui:
		settings.set_screen_shake(pressed)
		if audio_manager != null:
			audio_manager.play_ui_confirm()

func _on_show_wpm_toggle(pressed: bool) -> void:
	if not _updating_ui:
		settings.set_show_wpm(pressed)
		if audio_manager != null:
			audio_manager.play_ui_confirm()

func _on_show_accuracy_toggle(pressed: bool) -> void:
	if not _updating_ui:
		settings.set_show_accuracy(pressed)
		if audio_manager != null:
			audio_manager.play_ui_confirm()

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

func _create_accessibility_section() -> void:
	# Find the Content container to add accessibility section
	var content = $Panel/Content
	if content == null:
		return

	# Create accessibility section container
	var section = VBoxContainer.new()
	section.name = "AccessibilitySection"
	section.add_theme_constant_override("separation", 8)

	# Section header
	var header = Label.new()
	header.text = "Accessibility"
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", ThemeColors.ACCENT_BLUE)
	section.add_child(header)

	# Reduced Motion toggle
	reduced_motion_toggle = CheckButton.new()
	reduced_motion_toggle.text = "Reduced Motion"
	reduced_motion_toggle.tooltip_text = "Disable screen shake and reduce visual effects"
	reduced_motion_toggle.toggled.connect(_on_reduced_motion_toggle)
	section.add_child(reduced_motion_toggle)

	# High Contrast toggle
	high_contrast_toggle = CheckButton.new()
	high_contrast_toggle.text = "High Contrast"
	high_contrast_toggle.tooltip_text = "Increase contrast for better visibility"
	high_contrast_toggle.toggled.connect(_on_high_contrast_toggle)
	section.add_child(high_contrast_toggle)

	# Large Text toggle
	large_text_toggle = CheckButton.new()
	large_text_toggle.text = "Large Text"
	large_text_toggle.tooltip_text = "Increase text size throughout the game"
	large_text_toggle.toggled.connect(_on_large_text_toggle)
	section.add_child(large_text_toggle)

	# Insert before ButtonRow (last child)
	var button_row_idx = content.get_child_count() - 1
	content.add_child(section)
	content.move_child(section, button_row_idx)

func _on_reduced_motion_toggle(pressed: bool) -> void:
	if not _updating_ui:
		settings.set_reduced_motion(pressed)
		# If reduced motion is enabled, also disable screen shake
		if pressed:
			screen_shake_toggle.button_pressed = false
			settings.set_screen_shake(false)
		if audio_manager != null:
			audio_manager.play_ui_confirm()

func _on_high_contrast_toggle(pressed: bool) -> void:
	if not _updating_ui:
		settings.set_high_contrast(pressed)
		if audio_manager != null:
			audio_manager.play_ui_confirm()

func _on_large_text_toggle(pressed: bool) -> void:
	if not _updating_ui:
		settings.set_large_text(pressed)
		if audio_manager != null:
			audio_manager.play_ui_confirm()

func _setup_button_hover_effects() -> void:
	# Setup hover for action buttons
	var buttons: Array[Button] = [back_button, reset_button]
	for btn in buttons:
		if btn == null:
			continue
		btn.pivot_offset = btn.size / 2.0
		btn.mouse_entered.connect(_on_button_hover_enter.bind(btn))
		btn.mouse_exited.connect(_on_button_hover_exit.bind(btn))
		btn.button_down.connect(_on_button_press_down.bind(btn))
		btn.button_up.connect(_on_button_press_up.bind(btn))

func _on_button_hover_enter(btn: Button) -> void:
	if settings.reduced_motion:
		return
	_tween_button_scale(btn, HOVER_SCALE, HOVER_DURATION)
	if audio_manager != null:
		audio_manager.play_ui_hover()

func _on_button_hover_exit(btn: Button) -> void:
	if settings.reduced_motion:
		return
	_tween_button_scale(btn, 1.0, HOVER_DURATION)

func _on_button_press_down(btn: Button) -> void:
	if settings.reduced_motion:
		return
	_tween_button_scale(btn, PRESS_SCALE, PRESS_DURATION)

func _on_button_press_up(btn: Button) -> void:
	if settings.reduced_motion:
		return
	var target_scale := HOVER_SCALE if btn.get_global_rect().has_point(btn.get_global_mouse_position()) else 1.0
	_tween_button_scale(btn, target_scale, HOVER_DURATION)

func _tween_button_scale(btn: Button, target_scale: float, duration: float) -> void:
	if _button_tweens.has(btn):
		var old_tween = _button_tweens[btn]
		if old_tween != null and old_tween.is_valid():
			old_tween.kill()
	btn.pivot_offset = btn.size / 2.0
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(btn, "scale", Vector2(target_scale, target_scale), duration)
	_button_tweens[btn] = tween

func _pulse_label(label: Label) -> void:
	if settings.reduced_motion:
		return
	# Kill existing tween for this label
	if _label_tweens.has(label):
		var old_tween = _label_tweens[label]
		if old_tween != null and old_tween.is_valid():
			old_tween.kill()

	# Store original color
	var original_color := ThemeColors.TEXT_NORMAL

	# Create pulse tween
	var tween := create_tween()
	label.add_theme_color_override("font_color", PULSE_COLOR)
	tween.tween_property(label, "theme_override_colors/font_color", original_color, PULSE_DURATION)
	tween.set_ease(Tween.EASE_OUT)
	_label_tweens[label] = tween
