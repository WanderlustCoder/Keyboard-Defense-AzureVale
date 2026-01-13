class_name ThreatGauge
extends Control
## Animated threat meter showing kingdom danger level.
## Changes color and pulses as threat increases.

signal threat_critical
signal threat_warning

## Maximum threat value for scaling
@export var max_threat: float = 100.0

## Threshold for warning state (0-1)
@export var warning_threshold: float = 0.5

## Threshold for critical state (0-1)
@export var critical_threshold: float = 0.8

## Current threat value
var threat_value: float = 0.0:
	set(value):
		var old_value := threat_value
		threat_value = clampf(value, 0.0, max_threat)
		_update_display()
		_check_thresholds(old_value)

# Internal references
var _bar_container: Control
var _fill_bar: ColorRect
var _glow_effect: ColorRect
var _label: Label
var _icon: Label
var _pulse_tween: Tween
var _is_critical: bool = false
var _is_warning: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(150, 32)
	_build_display()
	_update_display()


func _build_display() -> void:
	# Main container
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", DesignSystem.SPACE_SM)
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(hbox)

	# Threat icon
	_icon = Label.new()
	_icon.text = "!"
	_icon.add_theme_font_size_override("font_size", DesignSystem.FONT_H3)
	_icon.add_theme_color_override("font_color", ThemeColors.THREAT)
	_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(_icon)

	# Bar container
	_bar_container = Control.new()
	_bar_container.custom_minimum_size = Vector2(100, 16)
	_bar_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(_bar_container)

	# Background bar
	var bg_bar := ColorRect.new()
	bg_bar.color = ThemeColors.BG_INPUT
	bg_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bar_container.add_child(bg_bar)

	# Glow effect (behind fill)
	_glow_effect = ColorRect.new()
	_glow_effect.color = ThemeColors.GLOW_ERROR
	_glow_effect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_glow_effect.modulate.a = 0.0
	_bar_container.add_child(_glow_effect)

	# Fill bar
	_fill_bar = ColorRect.new()
	_fill_bar.color = ThemeColors.THREAT
	_fill_bar.anchor_right = 0.0
	_fill_bar.anchor_bottom = 1.0
	_fill_bar.offset_right = 0
	_bar_container.add_child(_fill_bar)

	# Value label
	_label = Label.new()
	_label.text = "0%"
	_label.add_theme_font_size_override("font_size", DesignSystem.FONT_CAPTION)
	_label.add_theme_color_override("font_color", ThemeColors.TEXT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.custom_minimum_size.x = 35
	hbox.add_child(_label)


func _update_display() -> void:
	if not _fill_bar:
		return

	var ratio: float = threat_value / max_threat

	# Update fill width
	_fill_bar.anchor_right = ratio

	# Update label
	_label.text = "%d%%" % int(ratio * 100)

	# Update color based on level
	var fill_color: Color
	if ratio >= critical_threshold:
		fill_color = ThemeColors.ERROR
		_icon.add_theme_color_override("font_color", ThemeColors.ERROR)
	elif ratio >= warning_threshold:
		fill_color = ThemeColors.WARNING
		_icon.add_theme_color_override("font_color", ThemeColors.WARNING)
	else:
		fill_color = ThemeColors.THREAT
		_icon.add_theme_color_override("font_color", ThemeColors.THREAT)

	_fill_bar.color = fill_color


func _check_thresholds(old_value: float) -> void:
	var old_ratio: float = old_value / max_threat
	var new_ratio: float = threat_value / max_threat

	# Check critical threshold crossing
	if new_ratio >= critical_threshold and old_ratio < critical_threshold:
		_is_critical = true
		_start_critical_pulse()
		threat_critical.emit()
	elif new_ratio < critical_threshold and _is_critical:
		_is_critical = false
		_stop_pulse()

	# Check warning threshold crossing
	if new_ratio >= warning_threshold and old_ratio < warning_threshold:
		_is_warning = true
		if not _is_critical:
			_start_warning_pulse()
		threat_warning.emit()
	elif new_ratio < warning_threshold and _is_warning:
		_is_warning = false
		if not _is_critical:
			_stop_pulse()


func _start_critical_pulse() -> void:
	_stop_pulse()

	_pulse_tween = create_tween()
	_pulse_tween.set_loops()

	# Fast, intense pulse
	_pulse_tween.tween_property(_glow_effect, "modulate:a", 0.6, 0.2)
	_pulse_tween.tween_property(_glow_effect, "modulate:a", 0.2, 0.2)

	# Icon pulse
	var icon_tween := create_tween()
	icon_tween.set_loops()
	icon_tween.tween_property(_icon, "scale", Vector2(1.2, 1.2), 0.2)
	icon_tween.tween_property(_icon, "scale", Vector2.ONE, 0.2)


func _start_warning_pulse() -> void:
	_stop_pulse()

	_pulse_tween = create_tween()
	_pulse_tween.set_loops()

	# Slower, gentler pulse
	_pulse_tween.tween_property(_glow_effect, "modulate:a", 0.3, 0.5)
	_pulse_tween.tween_property(_glow_effect, "modulate:a", 0.0, 0.5)


func _stop_pulse() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null

	_glow_effect.modulate.a = 0.0
	_icon.scale = Vector2.ONE


## Update threat from game state
func update_from_state(state: RefCounted) -> void:
	threat_value = state.threat_level * 100.0  # Assuming 0-1 range


## Set threat directly as percentage (0-100)
func set_threat_percent(percent: float) -> void:
	threat_value = percent


## Animate threat change smoothly
func animate_to(target_value: float, duration: float = DesignSystem.ANIM_NORMAL) -> void:
	var tween := create_tween()
	tween.tween_property(self, "threat_value", target_value, duration)


## Create a threat gauge with label
static func create_labeled(label_text: String = "Threat") -> VBoxContainer:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", DesignSystem.SPACE_XS)

	var label := Label.new()
	label.text = label_text
	DesignSystem.style_label(label, "caption", ThemeColors.TEXT_DIM)
	container.add_child(label)

	var gauge := ThreatGauge.new()
	container.add_child(gauge)

	return container


## Create a compact inline threat gauge
static func create_compact() -> ThreatGauge:
	var gauge := ThreatGauge.new()
	gauge.custom_minimum_size = Vector2(80, 20)
	return gauge
