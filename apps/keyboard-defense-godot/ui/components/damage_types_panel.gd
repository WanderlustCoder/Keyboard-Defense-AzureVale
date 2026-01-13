class_name DamageTypesPanel
extends PanelContainer
## Damage Types Panel - Reference for the damage type system.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

const SimTowerTypes = preload("res://sim/tower_types.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Damage type definitions with full info (domain-specific colors)
const DAMAGE_TYPE_INFO: Array = [
	{
		"type": SimTowerTypes.DamageType.PHYSICAL,
		"name": "Physical",
		"icon": "PHY",
		"color": Color(0.75, 0.75, 0.75),
		"description": "Standard damage reduced by enemy armor",
		"strengths": ["Common, reliable damage"],
		"weaknesses": ["Reduced by armor", "Ineffective vs armored enemies"],
		"towers": ["Arrow Tower", "Cannon Tower", "Multi-Shot Tower", "Siege Tower"]
	},
	{
		"type": SimTowerTypes.DamageType.MAGICAL,
		"name": "Magical",
		"icon": "MAG",
		"color": Color(0.6, 0.2, 0.8),
		"description": "Arcane damage that ignores armor completely",
		"strengths": ["Ignores armor", "Consistent damage"],
		"weaknesses": ["No bonus effects", "Lower base damage"],
		"towers": ["Magic Tower", "Arcane Tower"]
	},
	{
		"type": SimTowerTypes.DamageType.COLD,
		"name": "Cold",
		"icon": "CLD",
		"color": Color(0.53, 0.81, 0.92),
		"description": "Frost damage that slows enemies",
		"strengths": ["Slows enemies", "3x damage vs burning"],
		"weaknesses": ["20% reduced base damage"],
		"towers": ["Frost Tower"]
	},
	{
		"type": SimTowerTypes.DamageType.FIRE,
		"name": "Fire",
		"icon": "FIR",
		"color": Color(1.0, 0.27, 0.0),
		"description": "Burning damage that deals damage over time",
		"strengths": ["DoT stacks", "3x damage vs frozen"],
		"weaknesses": ["Ignores only half armor"],
		"towers": ["Flame Tower"]
	},
	{
		"type": SimTowerTypes.DamageType.POISON,
		"name": "Poison",
		"icon": "PSN",
		"color": Color(0.2, 0.8, 0.2),
		"description": "Toxic damage that stacks and ignores half armor",
		"strengths": ["Stacking DoT", "Ignores half armor"],
		"weaknesses": ["Slow initial damage"],
		"towers": ["Poison Tower"]
	},
	{
		"type": SimTowerTypes.DamageType.LIGHTNING,
		"name": "Lightning",
		"icon": "LTN",
		"color": Color(1.0, 0.84, 0.0),
		"description": "Electric damage that chains between enemies",
		"strengths": ["Chains to multiple targets", "Bonus vs wet enemies"],
		"weaknesses": ["Damage falls off with each jump"],
		"towers": ["Tesla Tower"]
	},
	{
		"type": SimTowerTypes.DamageType.HOLY,
		"name": "Holy",
		"icon": "HLY",
		"color": Color(1.0, 1.0, 0.9),
		"description": "Sacred damage effective against corrupted foes",
		"strengths": ["50% bonus vs affixed enemies", "50% bonus vs corrupted"],
		"weaknesses": ["Normal damage vs regular enemies"],
		"towers": ["Holy Tower", "Shrine Tower"]
	},
	{
		"type": SimTowerTypes.DamageType.PURE,
		"name": "Pure",
		"icon": "PUR",
		"color": Color(1.0, 0.0, 1.0),
		"description": "True damage that ignores all defenses",
		"strengths": ["Ignores armor", "Ignores resistances"],
		"weaknesses": ["Very rare", "Often lower base damage"],
		"towers": ["Legendary Purifier"]
	}
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 520)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "DAMAGE TYPES"
	DesignSystem.style_label(title, "h2", ThemeColors.WARNING)
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
	subtitle.text = "How different damage types interact with enemies"
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
	footer.text = "Combine damage types for synergy bonuses"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_damage_types() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Build cards for each damage type
	for type_info in DAMAGE_TYPE_INFO:
		var card := _create_damage_type_card(type_info)
		_content_vbox.add_child(card)

	# Synergy combos section
	_build_synergy_combos_section()


func _build_synergy_combos_section() -> void:
	var section := _create_section_panel("ELEMENTAL COMBOS", ThemeColors.WARNING)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var combos: Array[Dictionary] = [
		{"name": "Fire & Ice", "desc": "Cold slows enemies, Fire deals 3x to frozen", "color": Color(0.9, 0.5, 0.3)},
		{"name": "Chain Reaction", "desc": "Lightning + AoE = massive multi-target damage", "color": ThemeColors.RESOURCE_GOLD},
		{"name": "Holy Purification", "desc": "Holy + Poison cleanses then burns corrupted", "color": Color(1.0, 1.0, 0.9)},
		{"name": "Arcane Support", "desc": "Magic towers buff nearby tower damage", "color": Color(0.6, 0.2, 0.8)}
	]

	for combo in combos:
		var row := _create_combo_row(combo)
		vbox.add_child(row)


func _create_damage_type_card(type_info: Dictionary) -> Control:
	var type_name: String = str(type_info.get("name", ""))
	var icon: String = str(type_info.get("icon", "?"))
	var color: Color = type_info.get("color", Color.WHITE)
	var description: String = str(type_info.get("description", ""))
	var strengths: Array = type_info.get("strengths", [])
	var weaknesses: Array = type_info.get("weaknesses", [])
	var towers: Array = type_info.get("towers", [])

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = color.darkened(0.85)
	container_style.border_color = color.darkened(0.5)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(DesignSystem.RADIUS_XS)
	container_style.set_content_margin_all(DesignSystem.SPACE_MD)
	container.add_theme_stylebox_override("panel", container_style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_SM)
	container.add_child(main_vbox)

	# Header row
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	# Icon
	var icon_panel := _create_type_icon(icon, color)
	header.add_child(icon_panel)

	# Name and description
	var info_vbox := DesignSystem.create_vbox(2)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(info_vbox)

	var name_label := Label.new()
	name_label.text = type_name
	DesignSystem.style_label(name_label, "body", color)
	info_vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = description
	DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(desc_label)

	# Strengths/Weaknesses row
	var details_row := DesignSystem.create_hbox(DesignSystem.SPACE_LG)
	main_vbox.add_child(details_row)

	# Strengths
	var strengths_vbox := DesignSystem.create_vbox(2)
	strengths_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_row.add_child(strengths_vbox)

	for strength in strengths:
		var s_label := Label.new()
		s_label.text = "+ " + str(strength)
		DesignSystem.style_label(s_label, "caption", ThemeColors.SUCCESS)
		strengths_vbox.add_child(s_label)

	# Weaknesses
	var weaknesses_vbox := DesignSystem.create_vbox(2)
	weaknesses_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_row.add_child(weaknesses_vbox)

	for weakness in weaknesses:
		var w_label := Label.new()
		w_label.text = "- " + str(weakness)
		DesignSystem.style_label(w_label, "caption", ThemeColors.ERROR)
		weaknesses_vbox.add_child(w_label)

	# Towers using this type
	if not towers.is_empty():
		var towers_row := DesignSystem.create_hbox(DesignSystem.SPACE_XS)
		main_vbox.add_child(towers_row)

		var towers_title := Label.new()
		towers_title.text = "Towers:"
		DesignSystem.style_label(towers_title, "caption", ThemeColors.TEXT_DIM)
		towers_row.add_child(towers_title)

		var towers_text := Label.new()
		towers_text.text = ", ".join(towers)
		DesignSystem.style_label(towers_text, "caption", color.lightened(0.2))
		towers_row.add_child(towers_text)

	return container


func _create_type_icon(icon_text: String, color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(44, 44)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = color.darkened(0.7)
	panel_style.set_corner_radius_all(DesignSystem.RADIUS_XS)
	panel.add_theme_stylebox_override("panel", panel_style)

	var label := Label.new()
	label.text = icon_text
	DesignSystem.style_label(label, "body", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(label)

	return panel


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


func _create_combo_row(combo: Dictionary) -> Control:
	var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)

	var name_label := Label.new()
	name_label.text = str(combo.get("name", ""))
	DesignSystem.style_label(name_label, "caption", combo.get("color", Color.WHITE))
	name_label.custom_minimum_size = Vector2(100, 0)
	hbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = str(combo.get("desc", ""))
	DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
	hbox.add_child(desc_label)

	return hbox


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
