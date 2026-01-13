class_name CitizenCard
extends PanelContainer
## Displays an individual citizen with their stats, morale, and traits.
## Can be used in a list or as a detailed view.

signal citizen_clicked(citizen_id: int)
signal assign_clicked(citizen_id: int)
signal unassign_clicked(citizen_id: int)

const SimCitizens = preload("res://sim/citizens.gd")

## Current citizen data
var citizen_data: Dictionary = {}

## Whether to show assignment buttons
var show_assignment_controls: bool = false

## Whether the card is in compact mode
var compact_mode: bool = false

# Internal nodes
var _vbox: VBoxContainer
var _header_hbox: HBoxContainer
var _name_label: Label
var _title_label: Label
var _morale_bar: ProgressBar
var _morale_label: Label
var _skill_hbox: HBoxContainer
var _skill_label: Label
var _skill_progress: ProgressBar
var _assignment_label: Label
var _traits_hbox: HBoxContainer
var _button_hbox: HBoxContainer
var _assign_button: Button
var _unassign_button: Button


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# Card styling
	var style := DesignSystem.create_elevated_style(ThemeColors.BG_CARD, DesignSystem.SHADOW_SM)
	style.border_color = ThemeColors.BORDER
	style.set_border_width_all(1)
	add_theme_stylebox_override("panel", style)

	custom_minimum_size = Vector2(280, 0) if not compact_mode else Vector2(200, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	gui_input.connect(_on_gui_input)

	_vbox = DesignSystem.create_vbox(DesignSystem.SPACE_SM)
	add_child(_vbox)

	# Header row (name + skill icons)
	_header_hbox = DesignSystem.create_hbox(DesignSystem.SPACE_SM)
	_vbox.add_child(_header_hbox)

	# Name and title column
	var name_vbox := DesignSystem.create_vbox(2)
	name_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header_hbox.add_child(name_vbox)

	_name_label = Label.new()
	_name_label.text = "Citizen Name"
	DesignSystem.style_label(_name_label, "h3", ThemeColors.TEXT)
	name_vbox.add_child(_name_label)

	_title_label = Label.new()
	_title_label.text = "Profession"
	DesignSystem.style_label(_title_label, "caption", ThemeColors.TEXT_DIM)
	name_vbox.add_child(_title_label)

	# Skill level display
	_skill_hbox = DesignSystem.create_hbox(DesignSystem.SPACE_XS)
	_header_hbox.add_child(_skill_hbox)

	var skill_icon := Label.new()
	skill_icon.text = "★"
	DesignSystem.style_label(skill_icon, "body", ThemeColors.ACCENT)
	_skill_hbox.add_child(skill_icon)

	_skill_label = Label.new()
	_skill_label.text = "1"
	DesignSystem.style_label(_skill_label, "body", ThemeColors.TEXT)
	_skill_hbox.add_child(_skill_label)

	# Morale section
	var morale_section := DesignSystem.create_vbox(2)
	_vbox.add_child(morale_section)

	var morale_header := DesignSystem.create_hbox(DesignSystem.SPACE_SM)
	morale_section.add_child(morale_header)

	var morale_title := Label.new()
	morale_title.text = "Morale"
	morale_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	DesignSystem.style_label(morale_title, "caption", ThemeColors.TEXT_DIM)
	morale_header.add_child(morale_title)

	_morale_label = Label.new()
	_morale_label.text = "Content (50)"
	DesignSystem.style_label(_morale_label, "caption", ThemeColors.TEXT)
	morale_header.add_child(_morale_label)

	_morale_bar = ProgressBar.new()
	_morale_bar.custom_minimum_size.y = 8
	_morale_bar.show_percentage = false
	_morale_bar.min_value = 0
	_morale_bar.max_value = 100
	_morale_bar.value = 50
	_style_progress_bar(_morale_bar, ThemeColors.MORALE_NORMAL)
	morale_section.add_child(_morale_bar)

	# Skill progress (shown when not max level)
	var skill_section := DesignSystem.create_vbox(2)
	skill_section.name = "SkillSection"
	_vbox.add_child(skill_section)

	var skill_header := DesignSystem.create_hbox(DesignSystem.SPACE_SM)
	skill_section.add_child(skill_header)

	var skill_title := Label.new()
	skill_title.text = "Skill Progress"
	skill_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	DesignSystem.style_label(skill_title, "caption", ThemeColors.TEXT_DIM)
	skill_header.add_child(skill_title)

	_skill_progress = ProgressBar.new()
	_skill_progress.custom_minimum_size.y = 6
	_skill_progress.show_percentage = false
	_skill_progress.min_value = 0
	_skill_progress.max_value = 1
	_skill_progress.value = 0
	_style_progress_bar(_skill_progress, ThemeColors.ACCENT_BLUE)
	skill_section.add_child(_skill_progress)

	# Assignment display
	_assignment_label = Label.new()
	_assignment_label.text = "Unassigned"
	DesignSystem.style_label(_assignment_label, "body_small", ThemeColors.TEXT_DIM)
	_vbox.add_child(_assignment_label)

	# Traits row
	_traits_hbox = DesignSystem.create_hbox(DesignSystem.SPACE_XS)
	_traits_hbox.name = "TraitsRow"
	_vbox.add_child(_traits_hbox)

	# Assignment buttons (hidden by default)
	_button_hbox = DesignSystem.create_hbox(DesignSystem.SPACE_SM)
	_button_hbox.visible = false
	_vbox.add_child(_button_hbox)

	_assign_button = Button.new()
	_assign_button.text = "Assign"
	_assign_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(_assign_button, ThemeColors.SUCCESS)
	_assign_button.pressed.connect(_on_assign_pressed)
	_button_hbox.add_child(_assign_button)

	_unassign_button = Button.new()
	_unassign_button.text = "Unassign"
	_unassign_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(_unassign_button, ThemeColors.WARNING)
	_unassign_button.pressed.connect(_on_unassign_pressed)
	_button_hbox.add_child(_unassign_button)


func _style_progress_bar(bar: ProgressBar, fill_color: Color) -> void:
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = ThemeColors.BG_INPUT
	bg_style.set_corner_radius_all(DesignSystem.RADIUS_SM)
	bar.add_theme_stylebox_override("background", bg_style)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	fill_style.set_corner_radius_all(DesignSystem.RADIUS_SM)
	bar.add_theme_stylebox_override("fill", fill_style)


func _style_button(button: Button, color: Color) -> void:
	var normal := DesignSystem.create_button_style(color.darkened(0.4), color.darkened(0.2))
	var hover := DesignSystem.create_button_style(color.darkened(0.3), color)
	var pressed := DesignSystem.create_button_style(color.darkened(0.5), color.darkened(0.3))

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", ThemeColors.TEXT)
	button.add_theme_font_size_override("font_size", DesignSystem.FONT_BODY_SMALL)


## Update the card with citizen data
func set_citizen(citizen: Dictionary) -> void:
	citizen_data = citizen
	_update_display()


## Update all displayed information
func _update_display() -> void:
	if citizen_data.is_empty():
		return

	# Name and title
	_name_label.text = SimCitizens.get_full_name(citizen_data)
	_title_label.text = SimCitizens.get_title(citizen_data)

	# Skill level
	var skill_level: int = citizen_data.get("skill_level", 1)
	_skill_label.text = str(skill_level)

	# Morale
	var morale: float = citizen_data.get("morale", 50.0)
	_morale_bar.value = morale
	_morale_label.text = "%s (%d)" % [SimCitizens.get_morale_status(citizen_data), int(morale)]

	# Update morale bar color
	var morale_color := ThemeColors.get_morale_color(morale)
	_style_progress_bar(_morale_bar, morale_color)

	# Skill progress
	var skill_progress := SimCitizens.get_skill_progress(citizen_data)
	_skill_progress.value = skill_progress
	_skill_progress.get_parent().visible = skill_level < SimCitizens.MAX_SKILL

	# Assignment
	var building_idx: int = citizen_data.get("assigned_building", -1)
	if building_idx < 0:
		_assignment_label.text = "Unassigned"
		_assignment_label.add_theme_color_override("font_color", ThemeColors.WARNING)
	else:
		_assignment_label.text = "Assigned to Building #%d" % building_idx
		_assignment_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)

	# Traits
	_update_traits()

	# Button visibility
	_button_hbox.visible = show_assignment_controls
	if show_assignment_controls:
		_assign_button.visible = building_idx < 0
		_unassign_button.visible = building_idx >= 0


func _update_traits() -> void:
	# Clear existing trait chips
	for child in _traits_hbox.get_children():
		child.queue_free()

	var traits: Array = citizen_data.get("traits", [])
	if traits.is_empty():
		var no_traits := Label.new()
		no_traits.text = "No traits"
		DesignSystem.style_label(no_traits, "caption", ThemeColors.TEXT_DISABLED)
		_traits_hbox.add_child(no_traits)
		return

	for trait_id in traits:
		var trait_info := SimCitizens.get_trait_info(trait_id)
		var chip := _create_trait_chip(trait_info)
		_traits_hbox.add_child(chip)


func _create_trait_chip(trait_info: Dictionary) -> PanelContainer:
	var chip := PanelContainer.new()

	# Color based on trait category
	var bg_color: Color
	var text_color: Color
	match trait_info.get("category", "neutral"):
		"positive":
			bg_color = ThemeColors.SUCCESS.darkened(0.6)
			text_color = ThemeColors.SUCCESS
		"negative":
			bg_color = ThemeColors.ERROR.darkened(0.6)
			text_color = ThemeColors.ERROR
		_:
			bg_color = ThemeColors.INFO.darkened(0.6)
			text_color = ThemeColors.INFO

	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(DesignSystem.RADIUS_SM)
	style.content_margin_left = DesignSystem.SPACE_SM
	style.content_margin_right = DesignSystem.SPACE_SM
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	chip.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = trait_info.get("name", "Unknown")
	DesignSystem.style_label(label, "caption", text_color)
	chip.add_child(label)

	# Tooltip
	chip.tooltip_text = trait_info.get("description", "")

	return chip


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var citizen_id: int = citizen_data.get("id", -1)
		if citizen_id >= 0:
			citizen_clicked.emit(citizen_id)


func _on_assign_pressed() -> void:
	var citizen_id: int = citizen_data.get("id", -1)
	if citizen_id >= 0:
		assign_clicked.emit(citizen_id)


func _on_unassign_pressed() -> void:
	var citizen_id: int = citizen_data.get("id", -1)
	if citizen_id >= 0:
		unassign_clicked.emit(citizen_id)


## Enable or disable assignment controls
func set_assignment_controls(enabled: bool) -> void:
	show_assignment_controls = enabled
	if _button_hbox:
		_button_hbox.visible = enabled
		_update_display()


## Set compact mode (smaller card)
func set_compact(compact: bool) -> void:
	compact_mode = compact
	if is_inside_tree():
		custom_minimum_size = Vector2(200, 0) if compact else Vector2(280, 0)


## Create a citizen card with data
static func create(citizen: Dictionary, compact: bool = false) -> CitizenCard:
	var card := CitizenCard.new()
	card.compact_mode = compact
	# Set citizen after ready
	card.ready.connect(func(): card.set_citizen(citizen))
	return card
