class_name DamageCalcPanel
extends PanelContainer
## Damage Calculation Panel - Explains damage formulas and type interactions

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Damage type data (from SimDamageTypes)
const DAMAGE_TYPES: Array[Dictionary] = [
	{
		"type": "Physical",
		"description": "Reduced by armor",
		"color": Color(0.75, 0.75, 0.75),
		"notes": "Standard damage, affected by enemy armor value"
	},
	{
		"type": "Magical",
		"description": "Ignores armor",
		"color": Color(0.6, 0.2, 0.8),
		"notes": "Bypasses all armor, pure magic damage"
	},
	{
		"type": "Cold",
		"description": "Slows, 3x vs burning",
		"color": Color(0.53, 0.81, 0.92),
		"notes": "Applies slow effect, deals triple damage to burning enemies"
	},
	{
		"type": "Fire",
		"description": "DoT, 3x vs frozen",
		"color": Color(1.0, 0.27, 0.0),
		"notes": "Burns enemies over time, triple damage to frozen targets"
	},
	{
		"type": "Poison",
		"description": "DoT, stacks, ignores half armor",
		"color": Color(0.2, 0.8, 0.2),
		"notes": "Stacking DoT, armor only 50% effective"
	},
	{
		"type": "Lightning",
		"description": "Chains between enemies",
		"color": Color(1.0, 0.84, 0.0),
		"notes": "Jumps to nearby enemies, bonus vs wet targets"
	},
	{
		"type": "Holy",
		"description": "Bonus vs affixed/corrupted",
		"color": Color(1.0, 1.0, 0.9),
		"notes": "+50% damage to enemies with affixes or corruption"
	},
	{
		"type": "Pure",
		"description": "Ignores all resistances",
		"color": Color(1.0, 0.0, 1.0),
		"notes": "Bypasses armor AND all resistances"
	}
]

# Damage formula components
const DAMAGE_FORMULA: Dictionary = {
	"base": "Base Damage = Tower Damage x Combo Multiplier",
	"armor_reduction": "Effective Damage = max(1, Base - Armor)",
	"resistance": "Final = Effective x (1 - Resistance)",
	"minimum": "All damage has a minimum of 1"
}

# Armor and resistance info
const ARMOR_INFO: Array[Dictionary] = [
	{
		"source": "Armored affix",
		"effect": "+20% physical resistance",
		"color": Color(0.6, 0.6, 0.7)
	},
	{
		"source": "Ghostly affix",
		"effect": "+50% physical resistance",
		"color": Color(0.5, 0.5, 0.7)
	},
	{
		"source": "Frozen status",
		"effect": "-50% fire resistance (vulnerable)",
		"color": Color(0.4, 0.7, 0.9)
	},
	{
		"source": "Burning status",
		"effect": "-50% cold resistance (vulnerable)",
		"color": Color(0.9, 0.4, 0.2)
	}
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(520, 580)

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
	title.text = "DAMAGE SYSTEM"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
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
	subtitle.text = "How tower damage is calculated against enemies"
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
	footer.text = "Match damage types to enemy weaknesses for maximum effect"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_damage_calc() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Damage types section
	_build_damage_types_section()

	# Formula section
	_build_formula_section()

	# Armor/resistance section
	_build_resistance_section()


func _build_damage_types_section() -> void:
	var section := _create_section_panel("DAMAGE TYPES", Color(0.9, 0.4, 0.4))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for dmg_type in DAMAGE_TYPES:
		var card := _create_damage_type_card(dmg_type)
		vbox.add_child(card)


func _create_damage_type_card(dmg_type: Dictionary) -> Control:
	var type_name: String = str(dmg_type.get("type", ""))
	var description: String = str(dmg_type.get("description", ""))
	var notes: String = str(dmg_type.get("notes", ""))
	var color: Color = dmg_type.get("color", Color.WHITE)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	# Color indicator
	var color_rect := ColorRect.new()
	color_rect.custom_minimum_size = Vector2(8, 8)
	color_rect.color = color
	hbox.add_child(color_rect)

	# Name
	var name_label := Label.new()
	name_label.text = type_name
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", color)
	name_label.custom_minimum_size = Vector2(70, 0)
	hbox.add_child(name_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(desc_label)

	return hbox


func _build_formula_section() -> void:
	var section := _create_section_panel("DAMAGE FORMULA", Color(0.6, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var formulas: Array[String] = [
		DAMAGE_FORMULA.base,
		DAMAGE_FORMULA.armor_reduction,
		DAMAGE_FORMULA.resistance,
		DAMAGE_FORMULA.minimum
	]

	for i in range(formulas.size()):
		var formula_label := Label.new()
		formula_label.text = "%d. %s" % [i + 1, formulas[i]]
		formula_label.add_theme_font_size_override("font_size", 10)
		formula_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		formula_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(formula_label)


func _build_resistance_section() -> void:
	var section := _create_section_panel("ARMOR & RESISTANCES", Color(0.6, 0.6, 0.7))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for armor_info in ARMOR_INFO:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var source: String = str(armor_info.get("source", ""))
		var effect: String = str(armor_info.get("effect", ""))
		var color: Color = armor_info.get("color", Color.WHITE)

		var source_label := Label.new()
		source_label.text = source
		source_label.add_theme_font_size_override("font_size", 10)
		source_label.add_theme_color_override("font_color", color)
		source_label.custom_minimum_size = Vector2(110, 0)
		hbox.add_child(source_label)

		var effect_label := Label.new()
		effect_label.text = effect
		effect_label.add_theme_font_size_override("font_size", 10)
		effect_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(effect_label)

	# Resistance cap note
	var cap_note := Label.new()
	cap_note.text = "Max resistance: 90% | Max vulnerability: -100%"
	cap_note.add_theme_font_size_override("font_size", 9)
	cap_note.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	vbox.add_child(cap_note)


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
	vbox.add_theme_constant_override("separation", 6)
	container.add_child(vbox)

	var header := Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", color)
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
