class_name HeaderBar
extends HBoxContainer
## Reusable header bar component for panels and sections.
## Provides consistent header styling with optional close button, icon, and subtitle.

signal close_requested

## Header title text
@export var title: String = "Header":
	set(value):
		title = value
		if _title_label:
			_title_label.text = value

## Optional subtitle below title
@export var subtitle: String = "":
	set(value):
		subtitle = value
		_update_subtitle()

## Whether to show close button
@export var show_close_button: bool = true:
	set(value):
		show_close_button = value
		if _close_button:
			_close_button.visible = value

## Icon text (emoji or single character)
@export var icon: String = "":
	set(value):
		icon = value
		_update_icon()

## Typography level for title: "h1", "h2", "h3", "display"
@export_enum("display", "h1", "h2", "h3") var title_level: String = "h1"

## Title color override (uses ThemeColors.TEXT by default)
@export var title_color: Color = Color.TRANSPARENT

# Internal references
var _icon_label: Label
var _title_container: VBoxContainer
var _title_label: Label
var _subtitle_label: Label
var _close_button: Button
var _spacer: Control


func _ready() -> void:
	_build_structure()
	_apply_styling()


## Updates the header title
func set_title(new_title: String) -> void:
	title = new_title


## Updates the subtitle
func set_subtitle(new_subtitle: String) -> void:
	subtitle = new_subtitle


## Shows or hides the close button
func set_close_visible(visible: bool) -> void:
	show_close_button = visible


## Sets the icon (emoji or character)
func set_icon(new_icon: String) -> void:
	icon = new_icon


## Adds a custom control to the right side (before close button)
func add_action(control: Control) -> void:
	if _close_button:
		move_child(control, _close_button.get_index())
	else:
		add_child(control)


## Creates a standard panel header with title and close button
static func create_panel_header(panel_title: String, on_close: Callable = Callable()) -> HeaderBar:
	var header := HeaderBar.new()
	header.title = panel_title
	header.title_level = "h1"
	header.show_close_button = true
	if on_close.is_valid():
		header.close_requested.connect(on_close)
	return header


## Creates a section header (smaller, no close button)
static func create_section_header(section_title: String, section_icon: String = "") -> HeaderBar:
	var header := HeaderBar.new()
	header.title = section_title
	header.title_level = "h3"
	header.show_close_button = false
	header.icon = section_icon
	return header


## Creates a subsection header with subtitle
static func create_subsection_header(main_title: String, sub_title: String) -> HeaderBar:
	var header := HeaderBar.new()
	header.title = main_title
	header.subtitle = sub_title
	header.title_level = "h2"
	header.show_close_button = false
	return header


# =============================================================================
# PRIVATE METHODS
# =============================================================================

func _build_structure() -> void:
	add_theme_constant_override("separation", DesignSystem.SPACE_MD)

	# Icon (optional)
	_icon_label = Label.new()
	_icon_label.visible = false
	_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_icon_label)

	# Title container (for title + optional subtitle)
	_title_container = VBoxContainer.new()
	_title_container.add_theme_constant_override("separation", DesignSystem.SPACE_XS)
	_title_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_title_container)

	# Title label
	_title_label = Label.new()
	_title_label.text = title
	_title_container.add_child(_title_label)

	# Subtitle label (hidden by default)
	_subtitle_label = Label.new()
	_subtitle_label.visible = false
	_title_container.add_child(_subtitle_label)

	# Spacer
	_spacer = Control.new()
	_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_spacer)

	# Close button
	_close_button = Button.new()
	_close_button.text = "✕"
	_close_button.custom_minimum_size = Vector2(DesignSystem.SIZE_BUTTON_SM, DesignSystem.SIZE_BUTTON_SM)
	_close_button.focus_mode = Control.FOCUS_NONE
	_close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_close_button.visible = show_close_button
	_close_button.pressed.connect(_on_close_pressed)
	add_child(_close_button)

	_update_icon()
	_update_subtitle()


func _apply_styling() -> void:
	# Title styling
	var font_size: int = DesignSystem.FONT_SIZES.get(title_level, DesignSystem.FONT_H1)
	_title_label.add_theme_font_size_override("font_size", font_size)

	var color := title_color if title_color.a > 0 else ThemeColors.TEXT
	_title_label.add_theme_color_override("font_color", color)

	# Subtitle styling
	_subtitle_label.add_theme_font_size_override("font_size", DesignSystem.FONT_BODY_SMALL)
	_subtitle_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)

	# Icon styling
	_icon_label.add_theme_font_size_override("font_size", font_size + 4)
	_icon_label.add_theme_color_override("font_color", ThemeColors.ACCENT)

	# Close button styling (ghost style)
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color.TRANSPARENT
	normal_style.set_corner_radius_all(DesignSystem.RADIUS_SM)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = ThemeColors.BG_BUTTON_HOVER
	hover_style.set_corner_radius_all(DesignSystem.RADIUS_SM)

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = ThemeColors.BG_BUTTON
	pressed_style.set_corner_radius_all(DesignSystem.RADIUS_SM)

	_close_button.add_theme_stylebox_override("normal", normal_style)
	_close_button.add_theme_stylebox_override("hover", hover_style)
	_close_button.add_theme_stylebox_override("pressed", pressed_style)
	_close_button.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	_close_button.add_theme_color_override("font_hover_color", ThemeColors.TEXT)
	_close_button.add_theme_font_size_override("font_size", DesignSystem.FONT_BODY)


func _update_icon() -> void:
	if not _icon_label:
		return
	_icon_label.text = icon
	_icon_label.visible = icon.length() > 0


func _update_subtitle() -> void:
	if not _subtitle_label:
		return
	_subtitle_label.text = subtitle
	_subtitle_label.visible = subtitle.length() > 0


func _on_close_pressed() -> void:
	close_requested.emit()
