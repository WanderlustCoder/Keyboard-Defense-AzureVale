class_name ModalPanel
extends Control
## A modal panel component for dialogs, results, and menus.
## Displays centered over a semi-transparent overlay.

const ThemeColors = preload("res://ui/theme_colors.gd")

const TITLE_FONT_SIZE := 24
const BUTTON_MIN_WIDTH := 120
const FADE_IN_DURATION := 0.2
const FADE_OUT_DURATION := 0.15

@onready var overlay: ColorRect = $Overlay
@onready var panel: PanelContainer = $CenterContainer/Panel
@onready var title_label: Label = $CenterContainer/Panel/Content/TitleLabel
@onready var message_label: Label = $CenterContainer/Panel/Content/MessageLabel
@onready var button_container: HBoxContainer = $CenterContainer/Panel/Content/ButtonContainer

var _buttons: Array[Button] = []
var _modal_tween: Tween = null

func _ready() -> void:
	_apply_styling()

func _exit_tree() -> void:
	if _modal_tween != null and _modal_tween.is_valid():
		_modal_tween.kill()

func _apply_styling() -> void:
	if title_label:
		title_label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
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
	return btn

## Show the modal with animation
func show_modal() -> void:
	if _modal_tween != null and _modal_tween.is_valid():
		_modal_tween.kill()
	visible = true
	modulate.a = 0.0
	_modal_tween = create_tween()
	_modal_tween.tween_property(self, "modulate:a", 1.0, FADE_IN_DURATION)
	# Focus first button for keyboard navigation
	if not _buttons.is_empty():
		_buttons[0].grab_focus()

## Hide the modal with animation
func hide_modal() -> void:
	if _modal_tween != null and _modal_tween.is_valid():
		_modal_tween.kill()
	_modal_tween = create_tween()
	_modal_tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_DURATION)
	_modal_tween.tween_callback(func(): visible = false)

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
