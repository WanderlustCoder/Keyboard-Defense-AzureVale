class_name MilestonePopup
extends Control
## Milestone Popup - Celebrates player achievements with animated notifications.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal dismissed

const SimMilestones = preload("res://sim/milestones.gd")

var _panel: PanelContainer = null
var _icon_label: Label = null
var _message_label: Label = null
var _value_label: Label = null
var _progress_bar: ProgressBar = null
var _animation_tween: Tween = null
var _dismiss_timer: Timer = null
var _queue: Array[Dictionary] = []
var _is_showing: bool = false

const DISPLAY_TIME: float = 3.0


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	# Full screen control for positioning
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Panel container
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(280, 70)
	_panel.position = Vector2(-300, 80)
	add_child(_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.18, 0.95)
	style.border_color = Color(1.0, 0.84, 0.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	_panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	_panel.add_child(hbox)

	# Icon
	_icon_label = Label.new()
	_icon_label.text = "*"
	_icon_label.add_theme_font_size_override("font_size", 28)
	_icon_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(_icon_label)

	# Text content
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	_message_label = Label.new()
	_message_label.add_theme_font_size_override("font_size", 14)
	_message_label.add_theme_color_override("font_color", Color.WHITE)
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_message_label)

	_value_label = Label.new()
	_value_label.add_theme_font_size_override("font_size", 11)
	_value_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(_value_label)

	# Progress to next milestone (optional)
	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(0, 6)
	_progress_bar.value = 0
	_progress_bar.show_percentage = false
	_progress_bar.visible = false
	vbox.add_child(_progress_bar)

	# Dismiss timer
	_dismiss_timer = Timer.new()
	_dismiss_timer.one_shot = true
	_dismiss_timer.timeout.connect(_on_dismiss_timeout)
	add_child(_dismiss_timer)


func show_milestone(milestone: Dictionary) -> void:
	_queue.append(milestone)
	_process_queue()


func _process_queue() -> void:
	if _is_showing or _queue.is_empty():
		return

	var milestone: Dictionary = _queue.pop_front()
	_display_milestone(milestone)


func _display_milestone(milestone: Dictionary) -> void:
	_is_showing = true

	var category = milestone.get("category", SimMilestones.Category.WPM)
	var message: String = str(milestone.get("message", "Milestone!"))
	var value = milestone.get("value", 0)
	var is_pb: bool = bool(milestone.get("is_personal_best", false))

	# Set icon based on category
	_icon_label.text = _get_category_icon(category)
	_icon_label.add_theme_color_override("font_color", SimMilestones.get_category_color(category))

	# Set message
	_message_label.text = message

	# Set value/sublabel
	if is_pb:
		_value_label.text = "Personal Best!"
		_value_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	else:
		_value_label.text = "Milestone Reached"
		_value_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)

	# Update panel border color to match category
	var style: StyleBoxFlat = _panel.get_theme_stylebox("panel").duplicate()
	style.border_color = SimMilestones.get_category_color(category)
	_panel.add_theme_stylebox_override("panel", style)

	# Animate in
	show()
	_panel.position.x = 50  # Start off-screen right
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.8, 0.8)

	if _animation_tween != null and _animation_tween.is_valid():
		_animation_tween.kill()

	_animation_tween = create_tween()
	_animation_tween.set_ease(Tween.EASE_OUT)
	_animation_tween.set_trans(Tween.TRANS_BACK)
	_animation_tween.set_parallel(true)
	_animation_tween.tween_property(_panel, "position:x", -300, 0.4)
	_animation_tween.tween_property(_panel, "modulate:a", 1.0, 0.3)
	_animation_tween.tween_property(_panel, "scale", Vector2.ONE, 0.3)

	# Start dismiss timer
	_dismiss_timer.start(DISPLAY_TIME)


func _on_dismiss_timeout() -> void:
	_animate_out()


func _animate_out() -> void:
	if _animation_tween != null and _animation_tween.is_valid():
		_animation_tween.kill()

	_animation_tween = create_tween()
	_animation_tween.set_ease(Tween.EASE_IN)
	_animation_tween.set_trans(Tween.TRANS_CUBIC)
	_animation_tween.set_parallel(true)
	_animation_tween.tween_property(_panel, "position:x", 50, 0.3)
	_animation_tween.tween_property(_panel, "modulate:a", 0.0, 0.2)
	_animation_tween.tween_callback(_finish_dismiss)


func _finish_dismiss() -> void:
	_is_showing = false
	hide()
	dismissed.emit()

	# Process next in queue if any
	if not _queue.is_empty():
		await get_tree().create_timer(0.2).timeout
		_process_queue()


func _get_category_icon(category) -> String:
	match category:
		SimMilestones.Category.WPM:
			return ">"  # Speed arrow
		SimMilestones.Category.ACCURACY:
			return "o"  # Target
		SimMilestones.Category.COMBO:
			return "!"  # Exclamation
		SimMilestones.Category.KILLS:
			return "x"  # Cross
		SimMilestones.Category.WORDS:
			return "#"  # Text
		SimMilestones.Category.STREAK:
			return "*"  # Star
		_:
			return "*"


## Quick dismiss (clicking anywhere)
func _input(event: InputEvent) -> void:
	if not visible or not _is_showing:
		return

	if event is InputEventMouseButton and event.pressed:
		_dismiss_timer.stop()
		_animate_out()
