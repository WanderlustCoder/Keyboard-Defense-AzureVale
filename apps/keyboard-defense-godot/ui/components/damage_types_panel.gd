class_name DamageTypesPanel
extends PanelContainer
## Damage Types Panel - Reference for the damage type system

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")
const SimTowerTypes = preload("res://sim/tower_types.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Damage type definitions with full info
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
	custom_minimum_size = Vector2(500, 520)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.12, 0.98)
	style.border_color = ThemeColors.BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	add_theme_stylebox_override("panel", style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	add_child(main_vbox)

	# Header
	var header := HBoxContainer.new()
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "DAMAGE TYPES"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
	header.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_close_btn = Button.new()
	_close_btn.text = "X"
	_close_btn.custom_minimum_size = Vector2(30, 30)
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "How different damage types interact with enemies"
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	main_vbox.add_child(subtitle)

	# Content scroll
	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_content_scroll)

	_content_vbox = VBoxContainer.new()
	_content_vbox.add_theme_constant_override("separation", 10)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_vbox)

	# Footer
	var footer := Label.new()
	footer.text = "Combine damage types for synergy bonuses"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)

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
	var section := _create_section_panel("ELEMENTAL COMBOS", Color(0.9, 0.7, 0.4))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var combos: Array[Dictionary] = [
		{"name": "Fire & Ice", "desc": "Cold slows enemies, Fire deals 3x to frozen", "color": Color(0.9, 0.5, 0.3)},
		{"name": "Chain Reaction", "desc": "Lightning + AoE = massive multi-target damage", "color": Color(1.0, 0.84, 0.0)},
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
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", container_style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 6)
	container.add_child(main_vbox)

	# Header row
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	main_vbox.add_child(header)

	# Icon
	var icon_panel := _create_type_icon(icon, color)
	header.add_child(icon_panel)

	# Name and description
	var info_vbox := VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 2)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(info_vbox)

	var name_label := Label.new()
	name_label.text = type_name
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", color)
	info_vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(desc_label)

	# Strengths/Weaknesses row
	var details_row := HBoxContainer.new()
	details_row.add_theme_constant_override("separation", 20)
	main_vbox.add_child(details_row)

	# Strengths
	var strengths_vbox := VBoxContainer.new()
	strengths_vbox.add_theme_constant_override("separation", 2)
	strengths_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_row.add_child(strengths_vbox)

	for strength in strengths:
		var s_label := Label.new()
		s_label.text = "+ " + str(strength)
		s_label.add_theme_font_size_override("font_size", 10)
		s_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		strengths_vbox.add_child(s_label)

	# Weaknesses
	var weaknesses_vbox := VBoxContainer.new()
	weaknesses_vbox.add_theme_constant_override("separation", 2)
	weaknesses_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_row.add_child(weaknesses_vbox)

	for weakness in weaknesses:
		var w_label := Label.new()
		w_label.text = "- " + str(weakness)
		w_label.add_theme_font_size_override("font_size", 10)
		w_label.add_theme_color_override("font_color", Color(0.9, 0.5, 0.5))
		weaknesses_vbox.add_child(w_label)

	# Towers using this type
	if not towers.is_empty():
		var towers_row := HBoxContainer.new()
		towers_row.add_theme_constant_override("separation", 5)
		main_vbox.add_child(towers_row)

		var towers_title := Label.new()
		towers_title.text = "Towers:"
		towers_title.add_theme_font_size_override("font_size", 10)
		towers_title.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		towers_row.add_child(towers_title)

		var towers_text := Label.new()
		towers_text.text = ", ".join(towers)
		towers_text.add_theme_font_size_override("font_size", 10)
		towers_text.add_theme_color_override("font_color", color.lightened(0.2))
		towers_row.add_child(towers_text)

	return container

func _create_type_icon(icon_text: String, color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(44, 44)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = color.darkened(0.7)
	panel_style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", panel_style)

	var label := Label.new()
	label.text = icon_text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
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
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	container.add_child(vbox)

	var header := Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", color)
	vbox.add_child(header)

	return container

func _create_combo_row(combo: Dictionary) -> Control:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	var name_label := Label.new()
	name_label.text = str(combo.get("name", ""))
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", combo.get("color", Color.WHITE))
	name_label.custom_minimum_size = Vector2(100, 0)
	hbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = str(combo.get("desc", ""))
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
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
