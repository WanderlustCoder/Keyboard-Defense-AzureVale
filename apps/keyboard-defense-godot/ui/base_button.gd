class_name BaseButton
extends RefCounted
## Factory class for creating consistently styled buttons.
## Provides button variants: primary, secondary, danger, ghost, success.
## Use this instead of manually styling buttons throughout the codebase.

# =============================================================================
# BUTTON CREATION
# =============================================================================

## Creates a primary button (gold accent, high emphasis)
## Use for main actions: "Start Game", "Confirm", "Save"
static func primary(text: String, callback: Callable = Callable()) -> Button:
	return _create_button(text, "primary", callback)


## Creates a secondary button (default style, medium emphasis)
## Use for secondary actions: "Cancel", "Back", "Skip"
static func secondary(text: String, callback: Callable = Callable()) -> Button:
	return _create_button(text, "secondary", callback)


## Creates a danger button (red accent, destructive actions)
## Use for destructive actions: "Delete", "Reset", "Abandon"
static func danger(text: String, callback: Callable = Callable()) -> Button:
	return _create_button(text, "danger", callback)


## Creates a ghost button (transparent, minimal emphasis)
## Use for tertiary actions: close buttons, inline links, toolbars
static func ghost(text: String, callback: Callable = Callable()) -> Button:
	return _create_button(text, "ghost", callback)


## Creates a success button (green accent, positive actions)
## Use for positive confirmations: "Complete", "Accept", "Unlock"
static func success(text: String, callback: Callable = Callable()) -> Button:
	return _create_button(text, "success", callback)


## Creates a button with custom size
static func sized(text: String, style: String, size: String, callback: Callable = Callable()) -> Button:
	var btn := _create_button(text, style, callback)
	match size:
		"sm":
			btn.custom_minimum_size.y = DesignSystem.SIZE_BUTTON_SM
			btn.add_theme_font_size_override("font_size", DesignSystem.FONT_BODY_SMALL)
		"lg":
			btn.custom_minimum_size.y = DesignSystem.SIZE_BUTTON_LG
			btn.add_theme_font_size_override("font_size", DesignSystem.FONT_H3)
		_:  # md (default)
			btn.custom_minimum_size.y = DesignSystem.SIZE_BUTTON_MD
	return btn


## Creates an icon-only button (square, typically for toolbars)
static func icon(icon_text: String, style: String = "ghost", callback: Callable = Callable()) -> Button:
	var btn := _create_button(icon_text, style, callback)
	btn.custom_minimum_size = Vector2(DesignSystem.SIZE_BUTTON_SM, DesignSystem.SIZE_BUTTON_SM)
	btn.tooltip_text = icon_text
	return btn


# =============================================================================
# BUTTON MODIFICATION
# =============================================================================

## Applies a style to an existing button
static func apply_style(btn: Button, style: String) -> void:
	var normal_style: StyleBoxFlat
	var hover_style: StyleBoxFlat
	var pressed_style: StyleBoxFlat
	var disabled_style: StyleBoxFlat
	var focus_style: StyleBoxFlat

	match style:
		"primary":
			normal_style = _create_stylebox(ThemeColors.ACCENT.darkened(0.2), ThemeColors.ACCENT)
			hover_style = _create_stylebox(ThemeColors.ACCENT.darkened(0.1), ThemeColors.ACCENT.lightened(0.1))
			pressed_style = _create_stylebox(ThemeColors.ACCENT.darkened(0.3), ThemeColors.ACCENT, true)
			focus_style = _create_stylebox(ThemeColors.ACCENT.darkened(0.2), ThemeColors.ACCENT.lightened(0.2))
			btn.add_theme_color_override("font_color", ThemeColors.BG_DARK)
			btn.add_theme_color_override("font_hover_color", ThemeColors.BG_DARK)
			btn.add_theme_color_override("font_pressed_color", ThemeColors.BG_DARK)
			btn.add_theme_color_override("font_focus_color", ThemeColors.BG_DARK)

		"danger":
			normal_style = _create_stylebox(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
			hover_style = _create_stylebox(ThemeColors.ERROR.darkened(0.2), ThemeColors.ERROR.lightened(0.1))
			pressed_style = _create_stylebox(ThemeColors.ERROR.darkened(0.4), ThemeColors.ERROR, true)
			focus_style = _create_stylebox(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR.lightened(0.2))
			btn.add_theme_color_override("font_color", ThemeColors.TEXT)
			btn.add_theme_color_override("font_hover_color", ThemeColors.TEXT)

		"success":
			normal_style = _create_stylebox(ThemeColors.SUCCESS.darkened(0.3), ThemeColors.SUCCESS)
			hover_style = _create_stylebox(ThemeColors.SUCCESS.darkened(0.2), ThemeColors.SUCCESS.lightened(0.1))
			pressed_style = _create_stylebox(ThemeColors.SUCCESS.darkened(0.4), ThemeColors.SUCCESS, true)
			focus_style = _create_stylebox(ThemeColors.SUCCESS.darkened(0.3), ThemeColors.SUCCESS.lightened(0.2))
			btn.add_theme_color_override("font_color", ThemeColors.BG_DARK)
			btn.add_theme_color_override("font_hover_color", ThemeColors.BG_DARK)
			btn.add_theme_color_override("font_pressed_color", ThemeColors.BG_DARK)

		"ghost":
			normal_style = StyleBoxFlat.new()
			normal_style.bg_color = Color.TRANSPARENT
			normal_style.set_corner_radius_all(DesignSystem.RADIUS_SM)
			normal_style.content_margin_left = DesignSystem.SPACE_SM
			normal_style.content_margin_right = DesignSystem.SPACE_SM
			normal_style.content_margin_top = DesignSystem.SPACE_XS
			normal_style.content_margin_bottom = DesignSystem.SPACE_XS
			hover_style = _create_stylebox(ThemeColors.BG_BUTTON_HOVER, Color.TRANSPARENT)
			pressed_style = _create_stylebox(ThemeColors.BG_BUTTON, Color.TRANSPARENT, true)
			focus_style = _create_stylebox(Color.TRANSPARENT, ThemeColors.BORDER_FOCUS)
			btn.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
			btn.add_theme_color_override("font_hover_color", ThemeColors.TEXT)
			btn.add_theme_color_override("font_pressed_color", ThemeColors.TEXT)

		"secondary", _:
			normal_style = _create_stylebox(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
			hover_style = _create_stylebox(ThemeColors.BG_BUTTON_HOVER, ThemeColors.BORDER_HIGHLIGHT)
			pressed_style = _create_stylebox(ThemeColors.BG_BUTTON, ThemeColors.BORDER, true)
			focus_style = _create_stylebox(ThemeColors.BG_BUTTON, ThemeColors.BORDER_FOCUS)
			btn.add_theme_color_override("font_color", ThemeColors.TEXT)
			btn.add_theme_color_override("font_hover_color", ThemeColors.TEXT)

	disabled_style = _create_stylebox(ThemeColors.BG_CARD_DISABLED, ThemeColors.BORDER_DISABLED)
	btn.add_theme_color_override("font_disabled_color", ThemeColors.TEXT_DISABLED)

	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_stylebox_override("disabled", disabled_style)
	btn.add_theme_stylebox_override("focus", focus_style)


## Sets button to disabled state with appropriate styling
static func set_disabled(btn: Button, disabled: bool) -> void:
	btn.disabled = disabled
	if disabled:
		btn.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
	else:
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


## Sets button loading state (disabled with loading indicator)
static func set_loading(btn: Button, loading: bool, original_text: String = "") -> void:
	btn.disabled = loading
	if loading:
		btn.text = "..."
		btn.mouse_default_cursor_shape = Control.CURSOR_BUSY
	else:
		if original_text:
			btn.text = original_text
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


# =============================================================================
# BUTTON GROUPS
# =============================================================================

## Creates a horizontal row of buttons
static func row(buttons: Array[Dictionary], spacing: int = DesignSystem.SPACE_SM) -> HBoxContainer:
	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", spacing)

	for btn_data in buttons:
		var btn := _create_button(
			btn_data.get("text", "Button"),
			btn_data.get("style", "secondary"),
			btn_data.get("callback", Callable())
		)
		if btn_data.has("disabled"):
			set_disabled(btn, btn_data.disabled)
		container.add_child(btn)

	return container


## Creates an action bar with primary action on right, secondary on left
static func action_bar(
	primary_text: String,
	primary_callback: Callable,
	secondary_text: String = "",
	secondary_callback: Callable = Callable()
) -> HBoxContainer:
	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", DesignSystem.SPACE_SM)

	if secondary_text:
		var sec_btn := secondary(secondary_text, secondary_callback)
		container.add_child(sec_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(spacer)

	var pri_btn := primary(primary_text, primary_callback)
	container.add_child(pri_btn)

	return container


## Creates a button group for toggle selection
static func toggle_group(options: Array[String], selected: int = 0, on_change: Callable = Callable()) -> HBoxContainer:
	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", 0)

	var button_group := ButtonGroup.new()

	for i in range(options.size()):
		var btn := Button.new()
		btn.text = options[i]
		btn.toggle_mode = true
		btn.button_group = button_group
		btn.button_pressed = (i == selected)
		btn.custom_minimum_size.y = DesignSystem.SIZE_BUTTON_MD

		# Style as toggle button
		var is_first := (i == 0)
		var is_last := (i == options.size() - 1)
		_apply_toggle_style(btn, is_first, is_last)

		if on_change.is_valid():
			var idx := i
			btn.pressed.connect(func(): on_change.call(idx))

		container.add_child(btn)

	return container


# =============================================================================
# PRIVATE HELPERS
# =============================================================================

static func _create_button(text: String, style: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size.y = DesignSystem.SIZE_BUTTON_MD
	btn.focus_mode = Control.FOCUS_ALL
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	apply_style(btn, style)
	btn.add_theme_font_size_override("font_size", DesignSystem.FONT_BODY)

	if callback.is_valid():
		btn.pressed.connect(callback)

	return btn


static func _create_stylebox(
	bg_color: Color,
	border_color: Color,
	pressed: bool = false
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color if not pressed else bg_color.darkened(0.1)
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(DesignSystem.RADIUS_SM)
	style.content_margin_left = DesignSystem.SPACE_LG
	style.content_margin_right = DesignSystem.SPACE_LG
	style.content_margin_top = DesignSystem.SPACE_SM
	style.content_margin_bottom = DesignSystem.SPACE_SM
	return style


static func _apply_toggle_style(btn: Button, is_first: bool, is_last: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = ThemeColors.BG_BUTTON
	normal.border_color = ThemeColors.BORDER
	normal.set_border_width_all(1)
	normal.content_margin_left = DesignSystem.SPACE_MD
	normal.content_margin_right = DesignSystem.SPACE_MD
	normal.content_margin_top = DesignSystem.SPACE_SM
	normal.content_margin_bottom = DesignSystem.SPACE_SM

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = ThemeColors.ACCENT.darkened(0.2)
	pressed.border_color = ThemeColors.ACCENT
	pressed.set_border_width_all(1)
	pressed.content_margin_left = DesignSystem.SPACE_MD
	pressed.content_margin_right = DesignSystem.SPACE_MD
	pressed.content_margin_top = DesignSystem.SPACE_SM
	pressed.content_margin_bottom = DesignSystem.SPACE_SM

	var hover := StyleBoxFlat.new()
	hover.bg_color = ThemeColors.BG_BUTTON_HOVER
	hover.border_color = ThemeColors.BORDER_HIGHLIGHT
	hover.set_border_width_all(1)
	hover.content_margin_left = DesignSystem.SPACE_MD
	hover.content_margin_right = DesignSystem.SPACE_MD
	hover.content_margin_top = DesignSystem.SPACE_SM
	hover.content_margin_bottom = DesignSystem.SPACE_SM

	# Handle rounded corners for first/last buttons in group
	var radius := DesignSystem.RADIUS_SM
	if is_first:
		normal.corner_radius_top_left = radius
		normal.corner_radius_bottom_left = radius
		pressed.corner_radius_top_left = radius
		pressed.corner_radius_bottom_left = radius
		hover.corner_radius_top_left = radius
		hover.corner_radius_bottom_left = radius
	if is_last:
		normal.corner_radius_top_right = radius
		normal.corner_radius_bottom_right = radius
		pressed.corner_radius_top_right = radius
		pressed.corner_radius_bottom_right = radius
		hover.corner_radius_top_right = radius
		hover.corner_radius_bottom_right = radius

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("hover_pressed", pressed)

	btn.add_theme_color_override("font_color", ThemeColors.TEXT)
	btn.add_theme_color_override("font_hover_color", ThemeColors.TEXT)
	btn.add_theme_color_override("font_pressed_color", ThemeColors.BG_DARK)
	btn.add_theme_font_size_override("font_size", DesignSystem.FONT_BODY)
