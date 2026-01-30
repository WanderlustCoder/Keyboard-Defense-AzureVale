class_name ModalPanel
extends Control
## A modal panel component for dialogs, results, and menus.
## Displays centered over a semi-transparent overlay.
## Migrated to use DesignSystem and ThemeColors for consistency.

const ButtonFeedbackClass = preload("res://ui/components/button_feedback.gd")

const BUTTON_MIN_WIDTH := 120
const BACKDROP_COLOR := Color(0.0, 0.0, 0.0, 0.5)

@onready var overlay: ColorRect = $Overlay
@onready var panel: PanelContainer = $CenterContainer/Panel
@onready var title_label: Label = $CenterContainer/Panel/Content/TitleLabel
@onready var message_label: Label = $CenterContainer/Panel/Content/MessageLabel
@onready var button_container: HBoxContainer = $CenterContainer/Panel/Content/ButtonContainer

var _buttons: Array[Button] = []
var _modal_tween: Tween = null
var _backdrop: ColorRect = null
var _backdrop_tween: Tween = null

func _ready() -> void:
	_apply_styling()

func _exit_tree() -> void:
	if _modal_tween != null and _modal_tween.is_valid():
		_modal_tween.kill()
	if _backdrop_tween != null and _backdrop_tween.is_valid():
		_backdrop_tween.kill()
	if _backdrop != null and is_instance_valid(_backdrop):
		_backdrop.queue_free()

func _apply_styling() -> void:
	if title_label:
		title_label.add_theme_font_size_override("font_size", DesignSystem.FONT_H1)
		title_label.add_theme_color_override("font_color", ThemeColors.ACCENT)

## Set the modal title
func set_title(text: String) -> void:
	if title_label:
		title_label.text = text

## Set the modal message
func set_message(text: String) -> void:
	if message_label:
		message_label.text = text

## Clear all buttons
func clear_buttons() -> void:
	for btn in _buttons:
		btn.queue_free()
	_buttons.clear()

## Add a button with callback
func add_button(text: String, callback: Callable, primary: bool = false) -> Button:
	if button_container == null:
		push_error("ModalPanel.add_button(): button_container is null - modal not properly initialized")
		return null
	var btn := Button.new()
	btn.text = text
	btn.pressed.connect(callback)
	btn.custom_minimum_size = Vector2(BUTTON_MIN_WIDTH, 0)
	btn.focus_mode = Control.FOCUS_ALL

	if primary:
		btn.add_theme_color_override("font_color", ThemeColors.ACCENT)

	button_container.add_child(btn)
	_buttons.append(btn)

	# Apply press/release feedback animation
	ButtonFeedbackClass.apply_to_button(btn)

	return btn

## Show the modal with animation
func show_modal() -> void:
	_show_backdrop()

	if _modal_tween != null and _modal_tween.is_valid():
		_modal_tween.kill()
	visible = true

	if _is_reduced_motion():
		modulate.a = 1.0
		if panel:
			panel.scale = Vector2.ONE
	else:
		modulate.a = 0.0
		if panel:
			panel.pivot_offset = panel.size / 2
			panel.scale = Vector2(0.92, 0.92)
		_modal_tween = create_tween()
		_modal_tween.set_parallel(true)
		_modal_tween.set_ease(Tween.EASE_OUT)
		# Fade: faster so content is visible before scale settles
		_modal_tween.tween_property(self, "modulate:a", 1.0, DesignSystem.ANIM_NORMAL * 0.6).set_trans(Tween.TRANS_QUAD)
		# Scale: spring overshoot on the panel node
		if panel:
			_modal_tween.tween_property(panel, "scale", Vector2.ONE, DesignSystem.ANIM_NORMAL).set_trans(Tween.TRANS_BACK)

	# Focus first button for keyboard navigation
	if not _buttons.is_empty():
		_buttons[0].grab_focus()


## Hide the modal with animation
func hide_modal() -> void:
	_hide_backdrop()

	if _modal_tween != null and _modal_tween.is_valid():
		_modal_tween.kill()

	if _is_reduced_motion():
		visible = false
		return

	_modal_tween = create_tween()
	_modal_tween.set_parallel(true)
	_modal_tween.set_ease(Tween.EASE_IN)
	_modal_tween.set_trans(Tween.TRANS_QUAD)
	_modal_tween.tween_property(self, "modulate:a", 0.0, DesignSystem.ANIM_FAST)
	if panel:
		_modal_tween.tween_property(panel, "scale", Vector2(0.95, 0.95), DesignSystem.ANIM_FAST)
	_modal_tween.chain().tween_callback(func(): visible = false)


## Create and show backdrop overlay
func _create_backdrop() -> void:
	if _backdrop != null:
		return

	_backdrop = ColorRect.new()
	_backdrop.color = Color(0, 0, 0, 0)  # Start transparent
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP

	# Size to fill parent
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Insert behind this modal
	var parent := get_parent()
	if parent != null:
		parent.add_child(_backdrop)
		parent.move_child(_backdrop, get_index())


func _show_backdrop() -> void:
	_create_backdrop()

	if _backdrop_tween != null and _backdrop_tween.is_valid():
		_backdrop_tween.kill()

	_backdrop_tween = create_tween()
	_backdrop_tween.tween_property(_backdrop, "color", BACKDROP_COLOR, DesignSystem.ANIM_NORMAL)


func _hide_backdrop() -> void:
	if _backdrop == null:
		return

	if _backdrop_tween != null and _backdrop_tween.is_valid():
		_backdrop_tween.kill()

	_backdrop_tween = create_tween()
	_backdrop_tween.tween_property(_backdrop, "color", Color(0, 0, 0, 0), DesignSystem.ANIM_FAST)
	_backdrop_tween.tween_callback(func():
		if _backdrop != null and is_instance_valid(_backdrop):
			_backdrop.queue_free()
			_backdrop = null
	)

## Configure as a simple message dialog
func setup_message(title: String, message: String, button_text: String = "OK", callback: Callable = Callable()) -> void:
	set_title(title)
	set_message(message)
	clear_buttons()
	add_button(button_text, func():
		if callback.is_valid():
			callback.call()
		hide_modal()
	, true)

static func _is_reduced_motion() -> bool:
	var settings = Engine.get_main_loop().root.get_node_or_null("/root/SettingsManager")
	if settings != null and settings.get("reduced_motion") != null:
		return settings.reduced_motion
	return false

## Configure as a confirmation dialog
func setup_confirm(title: String, message: String, confirm_text: String = "Confirm", cancel_text: String = "Cancel", on_confirm: Callable = Callable(), on_cancel: Callable = Callable()) -> void:
	set_title(title)
	set_message(message)
	clear_buttons()
	add_button(cancel_text, func():
		if on_cancel.is_valid():
			on_cancel.call()
		hide_modal()
	)
	add_button(confirm_text, func():
		if on_confirm.is_valid():
			on_confirm.call()
		hide_modal()
	, true)
