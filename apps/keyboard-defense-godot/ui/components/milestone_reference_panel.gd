class_name MilestoneReferencePanel
extends PanelContainer
## Milestone Reference Panel - Shows milestone thresholds and rewards.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Milestone categories (from SimMilestones) - domain-specific colors
const MILESTONE_CATEGORIES: Array[Dictionary] = [
	{
		"name": "WPM Milestones",
		"color": Color(0.4, 0.8, 1.0),
		"thresholds": [
			{"value": 20, "label": "First Steps"},
			{"value": 30, "label": "Getting Faster"},
			{"value": 40, "label": "Solid Speed"},
			{"value": 50, "label": "Professional"},
			{"value": 60, "label": "Expert Typist"},
			{"value": 70, "label": "Speed Demon"},
			{"value": 80, "label": "Blazing Fast"},
			{"value": 100, "label": "Century Club"},
			{"value": 150, "label": "Legendary"}
		]
	},
	{
		"name": "Accuracy Milestones",
		"color": Color(0.5, 0.8, 0.3),
		"thresholds": [
			{"value": "80%", "label": "Solid Accuracy"},
			{"value": "85%", "label": "Sharp Shooter"},
			{"value": "90%", "label": "Precision Master"},
			{"value": "95%", "label": "Near Perfect"},
			{"value": "98%", "label": "Surgical Precision"},
			{"value": "100%", "label": "PERFECT"}
		]
	},
	{
		"name": "Combo Milestones",
		"color": Color(0.9, 0.6, 0.3),
		"thresholds": [
			{"value": 5, "label": "Combo Started"},
			{"value": 10, "label": "Double Digits"},
			{"value": 20, "label": "Unstoppable"},
			{"value": 30, "label": "Legendary Streak"},
			{"value": 50, "label": "Impossible"},
			{"value": 100, "label": "IMMORTAL"}
		]
	},
	{
		"name": "Kill Milestones",
		"color": Color(0.9, 0.4, 0.4),
		"thresholds": [
			{"value": "50", "label": "First Blood"},
			{"value": "100", "label": "Centurion"},
			{"value": "500", "label": "Champion"},
			{"value": "1,000", "label": "Slayer"},
			{"value": "5,000", "label": "Annihilator"},
			{"value": "10,000", "label": "LEGEND"}
		]
	},
	{
		"name": "Word Milestones",
		"color": Color(0.7, 0.5, 0.9),
		"thresholds": [
			{"value": "100", "label": "Scribe"},
			{"value": "500", "label": "Writer"},
			{"value": "1,000", "label": "Author"},
			{"value": "5,000", "label": "Master Scribe"},
			{"value": "10,000", "label": "Wordsmith"},
			{"value": "50,000", "label": "LEGEND OF WORDS"}
		]
	},
	{
		"name": "Streak Milestones",
		"color": Color(1.0, 0.84, 0.0),
		"thresholds": [
			{"value": "3 days", "label": "Three-Day Streak"},
			{"value": "7 days", "label": "Weekly Warrior"},
			{"value": "14 days", "label": "Two Week Champion"},
			{"value": "30 days", "label": "Monthly Master"},
			{"value": "90 days", "label": "Quarterly Champion"},
			{"value": "365 days", "label": "YEAR OF MASTERY"}
		]
	}
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_MD, 580)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "MILESTONES"
	DesignSystem.style_label(title, "h2", ThemeColors.RESOURCE_GOLD)
	header.add_child(title)

	header.add_child(DesignSystem.create_spacer())

	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.custom_minimum_size = Vector2(DesignSystem.SIZE_BUTTON_SM, DesignSystem.SIZE_BUTTON_SM)
	_style_close_button()
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "Personal records and achievements to strive for"
	DesignSystem.style_label(subtitle, "body_small", ThemeColors.TEXT_DIM)
	main_vbox.add_child(subtitle)

	# Content scroll
	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_content_scroll)

	_content_vbox = DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_vbox)

	# Footer
	var footer := Label.new()
	footer.text = "Milestones are tracked automatically as you play"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_milestones() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	for category in MILESTONE_CATEGORIES:
		var section := _create_category_section(category)
		_content_vbox.add_child(section)


func _create_category_section(category: Dictionary) -> Control:
	var name_str: String = str(category.get("name", ""))
	var color: Color = category.get("color", Color.WHITE)
	var thresholds: Array = category.get("thresholds", [])

	var section := _create_section_panel(name_str, color)
	var vbox: VBoxContainer = section.get_child(0)

	# Create grid for thresholds
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", DesignSystem.SPACE_XL)
	grid.add_theme_constant_override("v_separation", DesignSystem.SPACE_XS)
	vbox.add_child(grid)

	for threshold in thresholds:
		var value = threshold.get("value", "")
		var label_str: String = str(threshold.get("label", ""))

		var value_label := Label.new()
		value_label.text = str(value)
		DesignSystem.style_label(value_label, "caption", color)
		value_label.custom_minimum_size = Vector2(55, 0)
		grid.add_child(value_label)

		var arrow := Label.new()
		arrow.text = "->"
		DesignSystem.style_label(arrow, "caption", ThemeColors.TEXT_DIM)
		grid.add_child(arrow)

		var name_label := Label.new()
		name_label.text = label_str
		DesignSystem.style_label(name_label, "caption", ThemeColors.TEXT_DIM)
		grid.add_child(name_label)

	return section


func _create_section_panel(title: String, color: Color) -> PanelContainer:
	var container := PanelContainer.new()

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = color.darkened(0.85)
	panel_style.border_color = color.darkened(0.5)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(DesignSystem.RADIUS_SM)
	panel_style.set_content_margin_all(DesignSystem.SPACE_MD)
	container.add_theme_stylebox_override("panel", panel_style)

	var vbox := DesignSystem.create_vbox(DesignSystem.SPACE_SM)
	container.add_child(vbox)

	var header := Label.new()
	header.text = title
	DesignSystem.style_label(header, "caption", color)
	vbox.add_child(header)

	return container


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
