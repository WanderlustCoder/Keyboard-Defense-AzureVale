class_name ActionTooltip
extends Control
## Floating tooltip for showing blocked action feedback with icon and text.
## Migrated to use DesignSystem and ThemeColors for consistency.

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
	style.bg_color = ThemeColors.BG_PANEL
	style.border_color = ThemeColors.ERROR.darkened(0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(DesignSystem.RADIUS_XS)
	style.set_content_margin_all(DesignSystem.SPACE_SM)
	_panel.add_theme_stylebox_override("panel", style)

	var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_SM)
	_panel.add_child(hbox)

	_icon_label = Label.new()
	_icon_label.add_theme_font_size_override("font_size", DesignSystem.FONT_BODY)
	_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(_icon_label)

	_text_label = Label.new()
	DesignSystem.style_label(_text_label, "body_small", ThemeColors.TEXT)
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
	_tween.tween_property(self, "modulate:a", 1.0, DesignSystem.ANIM_FAST)
	_tween.tween_property(self, "position:y", position.y - DesignSystem.SPACE_LG * 0.3, DesignSystem.ANIM_FAST)

	_tween.set_parallel(false)
	_tween.tween_interval(DesignSystem.ANIM_SLOW * 4)

	# Animate out
	_tween.set_parallel(true)
	_tween.tween_property(self, "modulate:a", 0.0, DesignSystem.ANIM_NORMAL)
	_tween.tween_property(self, "position:y", position.y - DesignSystem.SPACE_LG, DesignSystem.ANIM_NORMAL)

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
