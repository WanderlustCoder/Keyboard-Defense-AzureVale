class_name TargetingModesPanel
extends PanelContainer
## Targeting Modes Panel - Shows tower targeting priorities and attack patterns.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Target priority definitions
const TARGET_PRIORITIES: Array[Dictionary] = [
	{
		"name": "Closest to Base",
		"description": "Targets enemies nearest to your castle. Best for general defense.",
		"color": Color(0.9, 0.4, 0.4),
		"towers": ["Arrow", "Magic", "Frost"]
	},
	{
		"name": "Highest HP",
		"description": "Targets tankiest enemies first. Good against bosses and elites.",
		"color": Color(0.8, 0.6, 0.3),
		"towers": ["Siege"]
	},
	{
		"name": "Lowest HP",
		"description": "Finishes off weakened enemies. Reduces enemy count quickly.",
		"color": Color(0.4, 0.9, 0.4),
		"towers": ["Multi-Shot"]
	},
	{
		"name": "Boss Priority",
		"description": "Always targets bosses and affixed enemies first.",
		"color": Color(0.9, 0.5, 0.9),
		"towers": ["Holy", "Purifier"]
	},
	{
		"name": "Marked Enemies",
		"description": "Prioritizes enemies with the marked debuff.",
		"color": Color(1.0, 0.84, 0.0),
		"towers": ["Special abilities"]
	}
]

# Attack patterns
const ATTACK_PATTERNS: Array[Dictionary] = [
	{
		"name": "Single Target",
		"description": "Hits one enemy per attack. High damage focus.",
		"color": Color(0.4, 0.6, 0.9),
		"towers": ["Arrow", "Magic", "Holy"]
	},
	{
		"name": "Multi-Shot",
		"description": "Hits 2-4 enemies simultaneously. Lower damage per target.",
		"color": Color(0.4, 0.9, 0.9),
		"towers": ["Multi-Shot Tower"]
	},
	{
		"name": "Area of Effect",
		"description": "Damages all enemies in a radius around impact point.",
		"color": Color(0.9, 0.6, 0.3),
		"towers": ["Cannon", "Siege"]
	},
	{
		"name": "Chain Lightning",
		"description": "Jumps between nearby enemies. Extra chains at high combos.",
		"color": Color(0.4, 0.9, 0.9),
		"towers": ["Tesla"]
	},
	{
		"name": "Adaptive",
		"description": "Changes mode based on battle situation (typing, enemy count, HP).",
		"color": Color(0.7, 0.5, 0.9),
		"towers": ["Letter Spirit Shrine"]
	}
]

# Tower-specific targeting notes
const TOWER_NOTES: Array[Dictionary] = [
	{
		"tower": "Arrow Tower",
		"note": "Fast attack, single target. Small accuracy bonus."
	},
	{
		"tower": "Magic Tower",
		"note": "Moderate range, moderate accuracy bonus."
	},
	{
		"tower": "Frost Tower",
		"note": "Slows enemies. Effectiveness scales with accuracy."
	},
	{
		"tower": "Tesla Tower",
		"note": "Chains to +1/+2/+3 targets at 10/20/50 combo."
	},
	{
		"tower": "Cannon/Siege",
		"note": "AoE splash damage. Best against clusters."
	},
	{
		"tower": "Holy Tower",
		"note": "Prioritizes bosses. +10% per perfect word streak."
	},
	{
		"tower": "Wordsmith's Forge",
		"note": "Scales with WPM and accuracy. Best for fast typists."
	},
	{
		"tower": "Letter Spirit Shrine",
		"note": "Alpha/Epsilon/Omega modes based on typing variety."
	}
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 560)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "TOWER TARGETING"
	DesignSystem.style_label(title, "h2", Color(0.6, 0.8, 1.0))
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
	subtitle.text = "How towers select and attack enemies"
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
	footer.text = "Different towers use different strategies"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_targeting_modes() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Target priorities section
	_build_priorities_section()

	# Attack patterns section
	_build_patterns_section()

	# Tower notes section
	_build_notes_section()


func _build_priorities_section() -> void:
	var section := _create_section_panel("TARGET PRIORITIES", Color(0.9, 0.5, 0.5))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for priority in TARGET_PRIORITIES:
		var row := _create_info_row(priority)
		vbox.add_child(row)


func _build_patterns_section() -> void:
	var section := _create_section_panel("ATTACK PATTERNS", Color(0.4, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for pattern in ATTACK_PATTERNS:
		var row := _create_info_row(pattern)
		vbox.add_child(row)


func _create_info_row(info: Dictionary) -> Control:
	var name_str: String = str(info.get("name", ""))
	var description: String = str(info.get("description", ""))
	var color: Color = info.get("color", Color.WHITE)
	var towers: Array = info.get("towers", [])

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = color.darkened(0.85)
	container_style.border_color = color.darkened(0.6)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(8)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	container.add_child(vbox)

	# Name
	var name_label := Label.new()
	name_label.text = name_str
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", color)
	vbox.add_child(name_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	# Towers using this
	if not towers.is_empty():
		var towers_label := Label.new()
		towers_label.text = "Used by: " + ", ".join(towers)
		towers_label.add_theme_font_size_override("font_size", 9)
		towers_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
		vbox.add_child(towers_label)

	return container


func _build_notes_section() -> void:
	var section := _create_section_panel("TOWER-SPECIFIC NOTES", Color(0.9, 0.7, 0.4))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for note_info in TOWER_NOTES:
		var tower_name: String = str(note_info.get("tower", ""))
		var note: String = str(note_info.get("note", ""))

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var tower_label := Label.new()
		tower_label.text = tower_name
		tower_label.add_theme_font_size_override("font_size", 10)
		tower_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.4))
		tower_label.custom_minimum_size = Vector2(130, 0)
		hbox.add_child(tower_label)

		var note_label := Label.new()
		note_label.text = note
		note_label.add_theme_font_size_override("font_size", 10)
		note_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(note_label)


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
	DesignSystem.style_label(header, "body_small", color)
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
