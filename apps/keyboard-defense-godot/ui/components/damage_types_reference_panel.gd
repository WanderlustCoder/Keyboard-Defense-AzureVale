class_name DamageTypesReferencePanel
extends PanelContainer
## Damage Types Reference Panel - Shows all damage types and their mechanics

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Damage types
const DAMAGE_TYPES: Array[Dictionary] = [
	{
		"id": "physical",
		"name": "Physical",
		"desc": "Standard damage, reduced by armor",
		"mechanic": "Armor reduces damage 1:1",
		"strong_vs": "-",
		"weak_vs": "Armored enemies, Ghosts",
		"hex": "#C0C0C0",
		"color": Color(0.75, 0.75, 0.75)
	},
	{
		"id": "magical",
		"name": "Magical",
		"desc": "Arcane damage that ignores armor completely",
		"mechanic": "Bypasses all armor",
		"strong_vs": "Armored enemies",
		"weak_vs": "-",
		"hex": "#9932CC",
		"color": Color(0.6, 0.2, 0.8)
	},
	{
		"id": "fire",
		"name": "Fire",
		"desc": "Burns enemies, deals damage over time",
		"mechanic": "Applies Burning DoT, 3x damage to Frozen",
		"strong_vs": "Frozen enemies",
		"weak_vs": "Cancels Frozen status",
		"hex": "#FF4500",
		"color": Color(1.0, 0.27, 0.0)
	},
	{
		"id": "cold",
		"name": "Cold",
		"desc": "Slows enemies, reduced base damage",
		"mechanic": "Applies Slow, -20% damage, 3x vs Burning",
		"strong_vs": "Burning enemies, Fast enemies",
		"weak_vs": "Reduced raw damage",
		"hex": "#87CEEB",
		"color": Color(0.53, 0.81, 0.92)
	},
	{
		"id": "lightning",
		"name": "Lightning",
		"desc": "Chains between enemies",
		"mechanic": "Jumps to nearby targets, +30% in water",
		"strong_vs": "Groups, Wet/Water enemies",
		"weak_vs": "Single targets",
		"hex": "#FFD700",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"id": "poison",
		"name": "Poison",
		"desc": "Stacking DoT that ignores half armor",
		"mechanic": "Stacks up to 10x, -50% healing received",
		"strong_vs": "High HP enemies, Healers",
		"weak_vs": "Low HP swarms",
		"hex": "#32CD32",
		"color": Color(0.2, 0.8, 0.2)
	},
	{
		"id": "holy",
		"name": "Holy",
		"desc": "Divine damage, extra effective vs special enemies",
		"mechanic": "+50% damage to Affixed and Corrupted",
		"strong_vs": "Bosses, Affixed enemies",
		"weak_vs": "Normal enemies",
		"hex": "#FFFFFF",
		"color": Color(1.0, 1.0, 0.9)
	},
	{
		"id": "pure",
		"name": "Pure",
		"desc": "Ignores all defenses and resistances",
		"mechanic": "Bypasses armor and all resistances",
		"strong_vs": "Everything",
		"weak_vs": "Rare and expensive",
		"hex": "#FF00FF",
		"color": Color(1.0, 0.0, 1.0)
	}
]

# Elemental interactions
const ELEMENTAL_INTERACTIONS: Array[Dictionary] = [
	{
		"combo": "Fire vs Frozen",
		"effect": "3x damage, removes Frozen",
		"color": Color(1.0, 0.27, 0.0)
	},
	{
		"combo": "Cold vs Burning",
		"effect": "3x damage, removes Burning",
		"color": Color(0.53, 0.81, 0.92)
	},
	{
		"combo": "Fire + Frozen",
		"effect": "Cancel each other out",
		"color": Color(0.6, 0.4, 0.5)
	},
	{
		"combo": "Lightning + Water",
		"effect": "+20-30% damage bonus",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"combo": "Holy + Corrupted",
		"effect": "+50% damage bonus",
		"color": Color(1.0, 1.0, 0.9)
	}
]

# Armor mechanics
const ARMOR_MECHANICS: Array[Dictionary] = [
	{
		"name": "Physical vs Armor",
		"desc": "Armor reduces physical damage 1:1 (min 1 damage)",
		"color": Color(0.75, 0.75, 0.75)
	},
	{
		"name": "Magical Bypass",
		"desc": "Magical damage completely ignores armor",
		"color": Color(0.6, 0.2, 0.8)
	},
	{
		"name": "Poison Penetration",
		"desc": "Poison ignores 50% of armor",
		"color": Color(0.2, 0.8, 0.2)
	},
	{
		"name": "Pure Bypass",
		"desc": "Pure damage ignores armor and all resistances",
		"color": Color(1.0, 0.0, 1.0)
	},
	{
		"name": "Armor Broken Status",
		"desc": "Reduces enemy armor by 50%",
		"color": Color(0.5, 0.5, 0.5)
	}
]

# Damage tips
const DAMAGE_TIPS: Array[String] = [
	"Use Magical or Pure damage against heavily armored enemies",
	"Fire and Cold counter each other - use strategically",
	"Lightning is best against groups of enemies",
	"Poison stacks make it great for sustained damage on bosses",
	"Holy damage is ideal for affixed and corrupted enemies",
	"Combine status effects for maximum damage multipliers"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(560, 700)

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
	title.add_theme_color_override("font_color", Color(0.96, 0.26, 0.21))
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
	subtitle.text = "8 damage types with unique mechanics and interactions"
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
	footer.text = "Towers deal specific damage types"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_damage_types_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Damage types
	_build_damage_types_section()

	# Elemental interactions
	_build_interactions_section()

	# Armor mechanics
	_build_armor_section()

	# Tips
	_build_tips_section()


func _build_damage_types_section() -> void:
	var section := _create_section_panel("DAMAGE TYPES", Color(0.96, 0.26, 0.21))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for dtype in DAMAGE_TYPES:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 1)
		vbox.add_child(container)

		# Name and description
		var header_hbox := HBoxContainer.new()
		header_hbox.add_theme_constant_override("separation", 10)
		container.add_child(header_hbox)

		var name_label := Label.new()
		name_label.text = str(dtype.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.add_theme_color_override("font_color", dtype.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(80, 0)
		header_hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(dtype.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		header_hbox.add_child(desc_label)

		# Mechanic
		var mech_label := Label.new()
		mech_label.text = "  Mechanic: " + str(dtype.get("mechanic", ""))
		mech_label.add_theme_font_size_override("font_size", 9)
		mech_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.3))
		container.add_child(mech_label)

		# Strong vs / Weak vs
		var vs_hbox := HBoxContainer.new()
		vs_hbox.add_theme_constant_override("separation", 15)
		container.add_child(vs_hbox)

		var strong: String = str(dtype.get("strong_vs", "-"))
		if strong != "-":
			var strong_label := Label.new()
			strong_label.text = "  Strong: " + strong
			strong_label.add_theme_font_size_override("font_size", 9)
			strong_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
			vs_hbox.add_child(strong_label)

		var weak: String = str(dtype.get("weak_vs", "-"))
		if weak != "-":
			var weak_label := Label.new()
			weak_label.text = "Weak: " + weak
			weak_label.add_theme_font_size_override("font_size", 9)
			weak_label.add_theme_color_override("font_color", Color(0.7, 0.5, 0.5))
			vs_hbox.add_child(weak_label)


func _build_interactions_section() -> void:
	var section := _create_section_panel("ELEMENTAL INTERACTIONS", Color(0.6, 0.5, 0.8))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for interaction in ELEMENTAL_INTERACTIONS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var combo_label := Label.new()
		combo_label.text = str(interaction.get("combo", ""))
		combo_label.add_theme_font_size_override("font_size", 10)
		combo_label.add_theme_color_override("font_color", interaction.get("color", Color.WHITE))
		combo_label.custom_minimum_size = Vector2(120, 0)
		hbox.add_child(combo_label)

		var effect_label := Label.new()
		effect_label.text = str(interaction.get("effect", ""))
		effect_label.add_theme_font_size_override("font_size", 9)
		effect_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(effect_label)


func _build_armor_section() -> void:
	var section := _create_section_panel("ARMOR MECHANICS", Color(0.5, 0.5, 0.6))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for armor in ARMOR_MECHANICS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(armor.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", armor.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(130, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(armor.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hbox.add_child(desc_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("DAMAGE TIPS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in DAMAGE_TIPS:
		var tip_label := Label.new()
		tip_label.text = "- " + tip
		tip_label.add_theme_font_size_override("font_size", 9)
		tip_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(tip_label)


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
