class_name DamageCalcPanel
extends PanelContainer
## Damage Calculation Panel - Explains damage formulas and type interactions.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Damage type data (domain-specific colors kept as constant)
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

# Armor and resistance info (domain-specific colors)
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
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_MD + 40, 580)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "DAMAGE SYSTEM"
	DesignSystem.style_label(title, "h2", ThemeColors.ERROR)
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
	subtitle.text = "How tower damage is calculated against enemies"
	DesignSystem.style_label(subtitle, "caption", ThemeColors.TEXT_DIM)
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
	footer.text = "Match damage types to enemy weaknesses for maximum effect"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


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
	var section := _create_section_panel("DAMAGE TYPES", ThemeColors.ERROR)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for dmg_type in DAMAGE_TYPES:
		var card := _create_damage_type_card(dmg_type)
		vbox.add_child(card)


func _create_damage_type_card(dmg_type: Dictionary) -> Control:
	var type_name: String = str(dmg_type.get("type", ""))
	var description: String = str(dmg_type.get("description", ""))
	var color: Color = dmg_type.get("color", Color.WHITE)

	var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)

	# Color indicator
	var color_rect := ColorRect.new()
	color_rect.custom_minimum_size = Vector2(DesignSystem.SPACE_SM, DesignSystem.SPACE_SM)
	color_rect.color = color
	hbox.add_child(color_rect)

	# Name
	var name_label := Label.new()
	name_label.text = type_name
	DesignSystem.style_label(name_label, "caption", color)
	name_label.custom_minimum_size = Vector2(70, 0)
	hbox.add_child(name_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = description
	DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(desc_label)

	return hbox


func _build_formula_section() -> void:
	var section := _create_section_panel("DAMAGE FORMULA", ThemeColors.INFO)
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
		DesignSystem.style_label(formula_label, "caption", ThemeColors.TEXT_DIM)
		formula_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(formula_label)


func _build_resistance_section() -> void:
	var section := _create_section_panel("ARMOR & RESISTANCES", ThemeColors.TEXT_DIM)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for armor_info in ARMOR_INFO:
		var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
		vbox.add_child(hbox)

		var source: String = str(armor_info.get("source", ""))
		var effect: String = str(armor_info.get("effect", ""))
		var color: Color = armor_info.get("color", Color.WHITE)

		var source_label := Label.new()
		source_label.text = source
		DesignSystem.style_label(source_label, "caption", color)
		source_label.custom_minimum_size = Vector2(110, 0)
		hbox.add_child(source_label)

		var effect_label := Label.new()
		effect_label.text = effect
		DesignSystem.style_label(effect_label, "caption", ThemeColors.TEXT_DIM)
		hbox.add_child(effect_label)

	# Resistance cap note
	var cap_note := Label.new()
	cap_note.text = "Max resistance: 90% | Max vulnerability: -100%"
	DesignSystem.style_label(cap_note, "caption", ThemeColors.TEXT_DIM)
	vbox.add_child(cap_note)


func _create_section_panel(title: String, color: Color) -> PanelContainer:
	var container := PanelContainer.new()

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = color.darkened(0.85)
	panel_style.border_color = color.darkened(0.5)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(DesignSystem.RADIUS_MD)
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
