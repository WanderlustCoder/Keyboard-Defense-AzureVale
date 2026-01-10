class_name TipNotification
extends PanelContainer
## Tip Notification - Shows contextual typing tips during gameplay

signal tip_dismissed

const StoryManager = preload("res://game/story_manager.gd")

## How long tips stay visible (seconds)
const DEFAULT_DISPLAY_TIME: float = 8.0
## Minimum time between tips (seconds)
const TIP_COOLDOWN: float = 30.0

var _tip_label: Label = null
var _category_label: Label = null
var _dismiss_btn: Button = null
var _display_timer: Timer = null
var _last_tip_time: float = 0.0
var _current_tip: String = ""
var _animation_tween: Tween = null

func _ready() -> void:
	_build_ui()
	hide()

func _build_ui() -> void:
	custom_minimum_size = Vector2(350, 80)

	# Style the panel
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.18, 0.95)
	style.border_color = Color(0.4, 0.6, 0.8, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	add_child(hbox)

	# Icon (lightbulb)
	var icon := Label.new()
	icon.text = "i"
	icon.add_theme_font_size_override("font_size", 18)
	icon.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon)

	# Content area
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	# Category label (small, dim)
	_category_label = Label.new()
	_category_label.add_theme_font_size_override("font_size", 10)
	_category_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
	vbox.add_child(_category_label)

	# Tip text
	_tip_label = Label.new()
	_tip_label.add_theme_font_size_override("font_size", 13)
	_tip_label.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95))
	_tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_tip_label)

	# Dismiss button
	_dismiss_btn = Button.new()
	_dismiss_btn.text = "X"
	_dismiss_btn.flat = true
	_dismiss_btn.custom_minimum_size = Vector2(24, 24)
	_dismiss_btn.add_theme_font_size_override("font_size", 12)
	_dismiss_btn.pressed.connect(_on_dismiss_pressed)
	hbox.add_child(_dismiss_btn)

	# Display timer
	_display_timer = Timer.new()
	_display_timer.one_shot = true
	_display_timer.timeout.connect(_on_timer_timeout)
	add_child(_display_timer)

## Show a tip for a specific context
func show_tip_for_context(context: String, force: bool = false) -> bool:
	# Check cooldown unless forced
	var current_time: float = Time.get_unix_time_from_system()
	if not force and (current_time - _last_tip_time) < TIP_COOLDOWN:
		return false

	var tip: String = StoryManager.get_contextual_tip(context)
	if tip.is_empty():
		return false

	_show_tip(tip, _get_category_display(context))
	return true

## Show a specific tip directly
func show_tip(tip_text: String, category: String = "") -> void:
	_show_tip(tip_text, category)

## Show a random tip from a category
func show_random_tip(category: String = "") -> bool:
	var tip: String = StoryManager.get_random_typing_tip(category)
	if tip.is_empty():
		return false

	_show_tip(tip, _get_category_display(category))
	return true

func _show_tip(text: String, category: String) -> void:
	_current_tip = text
	_tip_label.text = text
	_category_label.text = category.to_upper() if not category.is_empty() else "TIP"
	_last_tip_time = Time.get_unix_time_from_system()

	# Animate in
	modulate.a = 0.0
	position.x += 50
	show()

	if _animation_tween != null and _animation_tween.is_valid():
		_animation_tween.kill()

	_animation_tween = create_tween()
	_animation_tween.set_ease(Tween.EASE_OUT)
	_animation_tween.set_trans(Tween.TRANS_CUBIC)
	_animation_tween.set_parallel(true)
	_animation_tween.tween_property(self, "modulate:a", 1.0, 0.3)
	_animation_tween.tween_property(self, "position:x", position.x - 50, 0.3)

	# Start auto-dismiss timer
	_display_timer.start(DEFAULT_DISPLAY_TIME)

func dismiss() -> void:
	if not visible:
		return

	_display_timer.stop()

	if _animation_tween != null and _animation_tween.is_valid():
		_animation_tween.kill()

	_animation_tween = create_tween()
	_animation_tween.set_ease(Tween.EASE_IN)
	_animation_tween.set_trans(Tween.TRANS_CUBIC)
	_animation_tween.set_parallel(true)
	_animation_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	_animation_tween.tween_property(self, "position:x", position.x + 50, 0.2)
	_animation_tween.tween_callback(_finish_dismiss)

func _finish_dismiss() -> void:
	hide()
	tip_dismissed.emit()

func _on_dismiss_pressed() -> void:
	dismiss()

func _on_timer_timeout() -> void:
	dismiss()

func _get_category_display(context: String) -> String:
	var displays: Dictionary = {
		"error": "Recovery",
		"slow": "Rhythm",
		"tired": "Posture",
		"start": "Warm Up",
		"home_row": "Home Row",
		"speed": "Advanced",
		"accuracy": "Technique",
		"mental": "Mindset",
		"practice": "Practice",
		"stuck": "Help",
		"posture": "Posture",
		"technique": "Technique",
		"rhythm": "Rhythm",
		"errors": "Recovery",
		"warm_up": "Warm Up",
		"advanced": "Advanced",
		"troubleshooting": "Help"
	}
	return displays.get(context, "Tip")

## Check if we're in cooldown
func is_on_cooldown() -> bool:
	var current_time: float = Time.get_unix_time_from_system()
	return (current_time - _last_tip_time) < TIP_COOLDOWN

## Reset cooldown (useful for testing or special events)
func reset_cooldown() -> void:
	_last_tip_time = 0.0

func _input(event: InputEvent) -> void:
	if not visible:
		return

	# Dismiss on any key press (allows player to quickly dismiss)
	if event is InputEventKey and event.is_pressed():
		dismiss()
		# Don't consume the input - let it pass through to gameplay
