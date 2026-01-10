class_name ActionTooltip
extends Control
## Floating tooltip for showing blocked action feedback with icon and text

const ThemeColors = preload("res://ui/theme_colors.gd")

const TOOLTIP_DURATION := 2.0
const FADE_IN_DURATION := 0.15
const FADE_OUT_DURATION := 0.3
const FLOAT_DISTANCE := 20.0
const FONT_SIZE := 12
const ICON_SIZE := 16

var _panel: PanelContainer = null
var _icon_label: Label = null
var _text_label: Label = null
var _tween: Tween = null
var _start_position: Vector2 = Vector2.ZERO

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	_setup_ui()
	visible = false

func _setup_ui() -> void:
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.12, 0.9)
	style.border_color = Color(0.6, 0.3, 0.3, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(6)
	_panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	_panel.add_child(hbox)

	_icon_label = Label.new()
	_icon_label.add_theme_font_size_override("font_size", ICON_SIZE)
	_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(_icon_label)

	_text_label = Label.new()
	_text_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_text_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.8, 1.0))
	_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(_text_label)

	add_child(_panel)

## Show a blocked action tooltip at position
func show_blocked(pos: Vector2, reason: String, icon: String = "") -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()

	# Set content
	if icon.is_empty():
		_icon_label.text = ""
		_icon_label.visible = false
	else:
		_icon_label.text = icon
		_icon_label.visible = true

	_text_label.text = reason

	# Position centered above the given point
	_start_position = pos
	await get_tree().process_frame  # Wait for size calculation
	position = pos - Vector2(size.x * 0.5, size.y + 10)

	# Animate in
	visible = true
	modulate.a = 0.0

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "modulate:a", 1.0, FADE_IN_DURATION)
	_tween.tween_property(self, "position:y", position.y - FLOAT_DISTANCE * 0.3, FADE_IN_DURATION)

	_tween.set_parallel(false)
	_tween.tween_interval(TOOLTIP_DURATION - FADE_IN_DURATION - FADE_OUT_DURATION)

	# Animate out
	_tween.set_parallel(true)
	_tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_DURATION)
	_tween.tween_property(self, "position:y", position.y - FLOAT_DISTANCE, FADE_OUT_DURATION)

	_tween.set_parallel(false)
	_tween.tween_callback(_on_finished)

func _on_finished() -> void:
	visible = false

## Static helper to spawn a tooltip in a container
static func spawn_at(parent: Node, pos: Vector2, reason: String, icon: String = "") -> Control:
	var script := load("res://ui/components/action_tooltip.gd")
	var tooltip: Control = script.new()
	parent.add_child(tooltip)
	tooltip.show_blocked(pos, reason, icon)
	# Auto-cleanup after animation
	tooltip._tween.tween_callback(tooltip.queue_free)
	return tooltip

## Common blocked action icons
const ICON_LOCKED := ""
const ICON_NO_GOLD := ""
const ICON_NO_AP := ""
const ICON_WRONG_PHASE := ""
const ICON_ERROR := ""
