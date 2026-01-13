class_name BasePanel
extends PanelContainer
## Base class for all UI panels in Keyboard Defense.
## Provides consistent styling, header creation, animations, and lifecycle management.
## Extend this class instead of PanelContainer for all new panels.

signal closed
signal opened

## Panel title displayed in header
@export var panel_title: String = "Panel"

## Whether to show the close button in header
@export var show_close_button: bool = true

## Whether the panel can be closed with Escape key
@export var close_on_escape: bool = true

## Panel width (0 = auto)
@export var panel_width: int = 0

## Whether to animate open/close
@export var animate_transitions: bool = true

## Whether to enable keyboard navigation
@export var enable_keyboard_nav: bool = true

## Internal references
var _header: HBoxContainer
var _title_label: Label
var _close_button: Button
var _content: VBoxContainer
var _is_open: bool = false
var _open_tween: Tween
var _focusable_controls: Array[Control] = []
var _last_focused: Control


func _ready() -> void:
	_setup_panel()
	_build_structure()
	_build_content()
	_connect_signals()

	if animate_transitions:
		_prepare_for_animation()

	# Setup keyboard navigation after content is built
	if enable_keyboard_nav:
		call_deferred("_setup_keyboard_navigation")


func _input(event: InputEvent) -> void:
	if close_on_escape and event.is_action_pressed("ui_cancel") and visible:
		close_panel()
		get_viewport().set_input_as_handled()


## Override this in subclasses to build panel content
func _build_content() -> void:
	pass


## Override this to perform actions when panel opens
func _on_panel_opened() -> void:
	pass


## Override this to perform actions when panel closes
func _on_panel_closed() -> void:
	pass


## Opens the panel with optional animation
func open_panel() -> void:
	if _is_open:
		return

	_is_open = true
	visible = true

	if animate_transitions and not _should_reduce_motion():
		_animate_open()
	else:
		modulate.a = 1.0
		scale = Vector2.ONE

	_on_panel_opened()
	opened.emit()

	# Focus first control for keyboard navigation
	if enable_keyboard_nav:
		call_deferred("focus_first_control")


## Closes the panel with optional animation
func close_panel() -> void:
	if not _is_open:
		return

	_is_open = false

	if animate_transitions and not _should_reduce_motion():
		_animate_close()
	else:
		visible = false
		_on_panel_closed()
		closed.emit()


## Updates the panel title
func set_title(new_title: String) -> void:
	panel_title = new_title
	if _title_label:
		_title_label.text = new_title


## Returns the content container for adding child elements
func get_content_container() -> VBoxContainer:
	return _content


## Adds a section with a header label to the content
func add_section(label: String) -> VBoxContainer:
	var section := DesignSystem.create_vbox(DesignSystem.SPACE_SM)

	var header := Label.new()
	DesignSystem.style_label(header, "h3", ThemeColors.TEXT)
	header.text = label
	section.add_child(header)

	var content := DesignSystem.create_vbox(DesignSystem.SPACE_SM)
	section.add_child(content)

	_content.add_child(section)
	return content


## Adds a separator line to the content
func add_separator() -> void:
	var sep := DesignSystem.create_separator()
	_content.add_child(sep)


## Adds a horizontal button row to the content
func add_button_row(buttons: Array[Dictionary]) -> HBoxContainer:
	var row := DesignSystem.create_hbox(DesignSystem.SPACE_SM)
	row.alignment = BoxContainer.ALIGNMENT_END

	for btn_data in buttons:
		var btn := _create_styled_button(
			btn_data.get("text", "Button"),
			btn_data.get("style", "secondary"),
			btn_data.get("callback", Callable())
		)
		row.add_child(btn)

	_content.add_child(row)
	return row


## Creates a styled button with the given parameters
func create_button(text: String, style: String = "secondary", callback: Callable = Callable()) -> Button:
	return _create_styled_button(text, style, callback)


# =============================================================================
# PRIVATE METHODS
# =============================================================================

func _setup_panel() -> void:
	# Apply base styling
	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	# Set size constraints
	if panel_width > 0:
		custom_minimum_size.x = panel_width
	else:
		custom_minimum_size.x = DesignSystem.SIZE_PANEL_MD


func _build_structure() -> void:
	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_LG)
	add_child(main_vbox)

	# Header
	_header = _create_header()
	main_vbox.add_child(_header)

	# Separator after header
	var sep := DesignSystem.create_separator()
	main_vbox.add_child(sep)

	# Content container
	_content = DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(_content)


func _create_header() -> HBoxContainer:
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)

	# Title
	_title_label = Label.new()
	DesignSystem.style_label(_title_label, "h1", ThemeColors.TEXT)
	_title_label.text = panel_title
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)

	# Close button
	if show_close_button:
		_close_button = Button.new()
		_close_button.text = "X"
		_close_button.custom_minimum_size = Vector2(DesignSystem.SIZE_BUTTON_SM, DesignSystem.SIZE_BUTTON_SM)
		_close_button.focus_mode = Control.FOCUS_NONE
		_apply_button_style(_close_button, "ghost")
		header.add_child(_close_button)

	return header


func _connect_signals() -> void:
	if _close_button:
		_close_button.pressed.connect(close_panel)


func _prepare_for_animation() -> void:
	modulate.a = 0.0
	scale = Vector2(0.95, 0.95)
	pivot_offset = size / 2


func _animate_open() -> void:
	if _open_tween:
		_open_tween.kill()

	_open_tween = create_tween()
	_open_tween.set_parallel(true)
	_open_tween.set_ease(Tween.EASE_OUT)
	_open_tween.set_trans(Tween.TRANS_QUAD)

	_open_tween.tween_property(self, "modulate:a", 1.0, DesignSystem.ANIM_NORMAL)
	_open_tween.tween_property(self, "scale", Vector2.ONE, DesignSystem.ANIM_NORMAL)


func _animate_close() -> void:
	if _open_tween:
		_open_tween.kill()

	_open_tween = create_tween()
	_open_tween.set_parallel(true)
	_open_tween.set_ease(Tween.EASE_IN)
	_open_tween.set_trans(Tween.TRANS_QUAD)

	_open_tween.tween_property(self, "modulate:a", 0.0, DesignSystem.ANIM_FAST)
	_open_tween.tween_property(self, "scale", Vector2(0.95, 0.95), DesignSystem.ANIM_FAST)

	_open_tween.chain().tween_callback(func():
		visible = false
		_on_panel_closed()
		closed.emit()
	)


func _create_styled_button(text: String, style: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size.y = DesignSystem.SIZE_BUTTON_MD
	_apply_button_style(btn, style)

	if callback.is_valid():
		btn.pressed.connect(callback)

	return btn


func _apply_button_style(btn: Button, style: String) -> void:
	var normal_style: StyleBoxFlat
	var hover_style: StyleBoxFlat
	var pressed_style: StyleBoxFlat
	var disabled_style: StyleBoxFlat

	match style:
		"primary":
			normal_style = DesignSystem.create_button_style(ThemeColors.ACCENT.darkened(0.2), ThemeColors.ACCENT)
			hover_style = DesignSystem.create_button_style(ThemeColors.ACCENT.darkened(0.1), ThemeColors.ACCENT)
			pressed_style = DesignSystem.create_button_style(ThemeColors.ACCENT.darkened(0.3), ThemeColors.ACCENT, true)
			btn.add_theme_color_override("font_color", ThemeColors.BG_DARK)
			btn.add_theme_color_override("font_hover_color", ThemeColors.BG_DARK)
			btn.add_theme_color_override("font_pressed_color", ThemeColors.BG_DARK)

		"danger":
			normal_style = DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
			hover_style = DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.2), ThemeColors.ERROR)
			pressed_style = DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.4), ThemeColors.ERROR, true)
			btn.add_theme_color_override("font_color", ThemeColors.TEXT)

		"ghost":
			normal_style = StyleBoxFlat.new()
			normal_style.bg_color = Color.TRANSPARENT
			hover_style = DesignSystem.create_button_style(ThemeColors.BG_BUTTON_HOVER, Color.TRANSPARENT)
			pressed_style = DesignSystem.create_button_style(ThemeColors.BG_BUTTON, Color.TRANSPARENT, true)
			btn.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
			btn.add_theme_color_override("font_hover_color", ThemeColors.TEXT)

		"secondary", _:
			normal_style = DesignSystem.create_button_style()
			hover_style = DesignSystem.create_button_style(ThemeColors.BG_BUTTON_HOVER, ThemeColors.BORDER_HIGHLIGHT)
			pressed_style = DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER, true)

	disabled_style = DesignSystem.create_button_style(ThemeColors.BG_CARD_DISABLED, ThemeColors.BORDER_DISABLED)

	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_stylebox_override("disabled", disabled_style)

	btn.add_theme_font_size_override("font_size", DesignSystem.FONT_BODY)


## Check if reduced motion is enabled
func _should_reduce_motion() -> bool:
	var settings := _get_settings_manager()
	if settings:
		return settings.reduced_motion
	return false


# =============================================================================
# KEYBOARD NAVIGATION
# =============================================================================

## Setup keyboard navigation for all focusable controls in the panel
func _setup_keyboard_navigation() -> void:
	_focusable_controls.clear()
	_collect_focusable_controls(self, _focusable_controls)

	if _focusable_controls.is_empty():
		return

	# Link focus neighbors
	for i in range(_focusable_controls.size()):
		var current := _focusable_controls[i]
		var prev_idx := (i - 1) if i > 0 else (_focusable_controls.size() - 1)
		var next_idx := (i + 1) % _focusable_controls.size()

		var prev_control := _focusable_controls[prev_idx]
		var next_control := _focusable_controls[next_idx]

		current.focus_neighbor_top = current.get_path_to(prev_control)
		current.focus_neighbor_bottom = current.get_path_to(next_control)
		current.focus_mode = Control.FOCUS_ALL

		# Apply focus indicator styling
		_apply_focus_style(current)

	# Connect focus changed for screen reader hints
	for control in _focusable_controls:
		if not control.focus_entered.is_connected(_on_control_focused):
			control.focus_entered.connect(_on_control_focused.bind(control))


## Collect all focusable controls recursively
func _collect_focusable_controls(node: Node, result: Array[Control]) -> void:
	if node is Control:
		var control := node as Control
		if _is_focusable(control) and control.visible:
			result.append(control)

	for child in node.get_children():
		_collect_focusable_controls(child, result)


## Check if control should be focusable
func _is_focusable(control: Control) -> bool:
	if not control.visible:
		return false
	if control is Button:
		return true
	if control is CheckBox:
		return true
	if control is CheckButton:
		return true
	if control is OptionButton:
		return true
	if control is SpinBox:
		return true
	if control is LineEdit:
		return true
	if control is TextEdit:
		return true
	if control is HSlider or control is VSlider:
		return true
	if control is TabBar:
		return true
	if control is ItemList:
		return true
	if control is Tree:
		return true
	return false


## Apply focus indicator style to a control
func _apply_focus_style(control: Control) -> void:
	var settings := _get_settings_manager()
	var high_contrast := settings.high_contrast if settings else false
	var focus_indicators := settings.focus_indicators if settings else true

	if not focus_indicators:
		return

	var focus_color := ThemeColors.HC_ACCENT if high_contrast else ThemeColors.BORDER_FOCUS
	var stylebox := StyleBoxFlat.new()
	stylebox.draw_center = false
	stylebox.border_width_left = 3
	stylebox.border_width_right = 3
	stylebox.border_width_top = 3
	stylebox.border_width_bottom = 3
	stylebox.border_color = focus_color
	stylebox.set_expand_margin_all(2.0)
	control.add_theme_stylebox_override("focus", stylebox)


## Called when a control receives focus
func _on_control_focused(control: Control) -> void:
	_last_focused = control


## Focus the first focusable control when panel opens
func focus_first_control() -> void:
	if _focusable_controls.is_empty():
		return
	_focusable_controls[0].grab_focus()


## Focus the last focused control, or first if none
func restore_focus() -> void:
	if is_instance_valid(_last_focused) and _last_focused.visible:
		_last_focused.grab_focus()
	else:
		focus_first_control()


## Get screen reader hint for focused control (if enabled)
func get_focus_hint(control: Control) -> String:
	var settings := _get_settings_manager()
	if not settings or not settings.screen_reader_hints:
		return ""

	if control is Button:
		return Accessibility.button_hint(control.text)
	if control is CheckBox or control is CheckButton:
		var checked := control.button_pressed if control is CheckBox else (control as CheckButton).button_pressed
		return Accessibility.checkbox_hint(control.text, checked)
	if control is HSlider or control is VSlider:
		var slider := control as Range
		return Accessibility.slider_hint("", slider.value, slider.min_value, slider.max_value)
	return ""


## Get the SettingsManager if available
func _get_settings_manager() -> Node:
	return get_node_or_null("/root/SettingsManager")


func _exit_tree() -> void:
	if _open_tween:
		_open_tween.kill()
