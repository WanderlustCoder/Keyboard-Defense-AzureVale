extends PanelContainer
class_name SettingsPanel
## Settings panel for audio and gameplay options

signal close_requested

# References to controls
var _music_slider: HSlider
var _sfx_slider: HSlider
var _music_toggle: CheckButton
var _sfx_toggle: CheckButton
var _typing_sounds_toggle: CheckButton
var _screen_shake_toggle: CheckButton
var _show_wpm_toggle: CheckButton
var _show_accuracy_toggle: CheckButton
var _close_button: Button

var _settings_manager: Node

func _ready() -> void:
	_settings_manager = get_node_or_null("/root/SettingsManager")
	_build_ui()
	_load_current_settings()
	visible = false

func _build_ui() -> void:
	custom_minimum_size = Vector2(400, 450)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 12)
	add_child(content)

	# Header
	var header := HBoxContainer.new()
	content.add_child(header)

	var title := Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_close_button = Button.new()
	_close_button.text = "X"
	_close_button.custom_minimum_size = Vector2(32, 32)
	_close_button.pressed.connect(_on_close_pressed)
	header.add_child(_close_button)

	# Separator
	content.add_child(HSeparator.new())

	# Audio Section
	var audio_label := Label.new()
	audio_label.text = "Audio"
	audio_label.add_theme_font_size_override("font_size", 18)
	content.add_child(audio_label)

	# Music Volume
	var music_row := _create_slider_row("Music Volume")
	_music_slider = music_row.get_node("Slider") as HSlider
	_music_slider.value_changed.connect(_on_music_volume_changed)
	content.add_child(music_row)

	# SFX Volume
	var sfx_row := _create_slider_row("SFX Volume")
	_sfx_slider = sfx_row.get_node("Slider") as HSlider
	_sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	content.add_child(sfx_row)

	# Music Enabled
	_music_toggle = _create_toggle_row("Music Enabled")
	_music_toggle.toggled.connect(_on_music_toggled)
	content.add_child(_music_toggle.get_parent())

	# SFX Enabled
	_sfx_toggle = _create_toggle_row("Sound Effects")
	_sfx_toggle.toggled.connect(_on_sfx_toggled)
	content.add_child(_sfx_toggle.get_parent())

	# Typing Sounds
	_typing_sounds_toggle = _create_toggle_row("Typing Sounds")
	_typing_sounds_toggle.toggled.connect(_on_typing_sounds_toggled)
	content.add_child(_typing_sounds_toggle.get_parent())

	# Separator
	content.add_child(HSeparator.new())

	# Gameplay Section
	var gameplay_label := Label.new()
	gameplay_label.text = "Gameplay"
	gameplay_label.add_theme_font_size_override("font_size", 18)
	content.add_child(gameplay_label)

	# Screen Shake
	_screen_shake_toggle = _create_toggle_row("Screen Shake")
	_screen_shake_toggle.toggled.connect(_on_screen_shake_toggled)
	content.add_child(_screen_shake_toggle.get_parent())

	# Show WPM
	_show_wpm_toggle = _create_toggle_row("Show WPM")
	_show_wpm_toggle.toggled.connect(_on_show_wpm_toggled)
	content.add_child(_show_wpm_toggle.get_parent())

	# Show Accuracy
	_show_accuracy_toggle = _create_toggle_row("Show Accuracy")
	_show_accuracy_toggle.toggled.connect(_on_show_accuracy_toggled)
	content.add_child(_show_accuracy_toggle.get_parent())

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)

	# Save button
	var save_button := Button.new()
	save_button.text = "Save & Close"
	save_button.pressed.connect(_on_save_pressed)
	content.add_child(save_button)

func _create_slider_row(label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(120, 0)
	row.add_child(label)

	var slider := HSlider.new()
	slider.name = "Slider"
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(150, 0)
	row.add_child(slider)

	var value_label := Label.new()
	value_label.name = "ValueLabel"
	value_label.custom_minimum_size = Vector2(40, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)

	# Update value label when slider changes
	slider.value_changed.connect(func(val: float):
		value_label.text = "%d%%" % int(val * 100)
	)

	return row

func _create_toggle_row(label_text: String) -> CheckButton:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var toggle := CheckButton.new()
	row.add_child(toggle)

	return toggle

func _load_current_settings() -> void:
	if _settings_manager == null:
		return

	_music_slider.value = _settings_manager.music_volume
	_sfx_slider.value = _settings_manager.sfx_volume
	_music_toggle.button_pressed = _settings_manager.music_enabled
	_sfx_toggle.button_pressed = _settings_manager.sfx_enabled
	_typing_sounds_toggle.button_pressed = _settings_manager.typing_sounds
	_screen_shake_toggle.button_pressed = _settings_manager.screen_shake
	_show_wpm_toggle.button_pressed = _settings_manager.show_wpm
	_show_accuracy_toggle.button_pressed = _settings_manager.show_accuracy

func show_settings() -> void:
	_load_current_settings()
	visible = true

func hide_settings() -> void:
	visible = false

func _on_music_volume_changed(value: float) -> void:
	if _settings_manager:
		_settings_manager.set_music_volume(value)

func _on_sfx_volume_changed(value: float) -> void:
	if _settings_manager:
		_settings_manager.set_sfx_volume(value)

func _on_music_toggled(pressed: bool) -> void:
	if _settings_manager:
		_settings_manager.set_music_enabled(pressed)

func _on_sfx_toggled(pressed: bool) -> void:
	if _settings_manager:
		_settings_manager.set_sfx_enabled(pressed)

func _on_typing_sounds_toggled(pressed: bool) -> void:
	if _settings_manager:
		_settings_manager.set_typing_sounds(pressed)

func _on_screen_shake_toggled(pressed: bool) -> void:
	if _settings_manager:
		_settings_manager.set_screen_shake(pressed)

func _on_show_wpm_toggled(pressed: bool) -> void:
	if _settings_manager:
		_settings_manager.set_show_wpm(pressed)

func _on_show_accuracy_toggled(pressed: bool) -> void:
	if _settings_manager:
		_settings_manager.set_show_accuracy(pressed)

func _on_save_pressed() -> void:
	if _settings_manager:
		_settings_manager.save_settings()
	close_requested.emit()
	hide_settings()

func _on_close_pressed() -> void:
	close_requested.emit()
	hide_settings()

func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_close_pressed()
			get_viewport().set_input_as_handled()
