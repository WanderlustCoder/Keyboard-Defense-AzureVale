class_name TowerCombatReferencePanel
extends PanelContainer
## Tower Combat Reference Panel - Shows tower attack mechanics and targeting

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Target types
const TARGET_TYPES: Array[Dictionary] = [
	{
		"type": "single",
		"name": "Single Target",
		"desc": "Attacks one enemy at a time",
		"towers": "Arrow, Magic, Holy, Poison, Frost",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"type": "multi",
		"name": "Multi Target",
		"desc": "Attacks multiple enemies simultaneously",
		"towers": "Multi-Shot Tower",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"type": "aoe",
		"name": "Area of Effect",
		"desc": "Damages all enemies in a radius",
		"towers": "Cannon Tower",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"type": "chain",
		"name": "Chain Lightning",
		"desc": "Jumps between nearby enemies",
		"towers": "Tesla Tower",
		"color": Color(0.7, 0.5, 0.9)
	},
	{
		"type": "adaptive",
		"name": "Adaptive",
		"desc": "Changes attack mode based on situation",
		"towers": "Legendary Towers",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"type": "none",
		"name": "Non-Attacking",
		"desc": "Provides utility instead of damage",
		"towers": "Support, Summoner, Trap Tower",
		"color": Color(0.6, 0.6, 0.6)
	}
]

# Attack effects
const ATTACK_EFFECTS: Array[Dictionary] = [
	{
		"effect": "Slow",
		"desc": "Reduces enemy movement speed",
		"source": "Frost Tower",
		"scaling": "+5% slow per level",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"effect": "Poison",
		"desc": "Deals damage over time (stacks)",
		"source": "Poison Tower",
		"scaling": "+1 stack per hit",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"effect": "Purify",
		"desc": "Chance to remove enemy affixes",
		"source": "Holy Tower",
		"scaling": "+3% chance per level",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"effect": "Support Buff",
		"desc": "Increases nearby tower damage",
		"source": "Support Tower",
		"scaling": "+5% buff per level",
		"color": Color(0.9, 0.6, 0.3)
	}
]

# Adaptive modes
const ADAPTIVE_MODES: Array[Dictionary] = [
	{
		"mode": "Alpha",
		"desc": "Single target focus - maximum damage to one enemy",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"mode": "Epsilon",
		"desc": "Chain all - hits every enemy in range",
		"color": Color(0.7, 0.5, 0.9)
	},
	{
		"mode": "Omega",
		"desc": "Heal on kill - restores 1 castle HP when killing",
		"color": Color(0.5, 0.8, 0.3)
	}
]

# Special tower systems
const SPECIAL_SYSTEMS: Array[Dictionary] = [
	{
		"system": "Summoner",
		"desc": "Creates units that fight enemies",
		"mechanic": "Max summons increases with level",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"system": "Traps",
		"desc": "Places explosive traps on the path",
		"mechanic": "Triggers when enemy steps on it",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"system": "Synergies",
		"desc": "Tower combinations grant bonuses",
		"mechanic": "Chain Reaction: Tesla + Magic = better chains",
		"color": Color(0.7, 0.5, 0.9)
	}
]

# Damage scaling
const DAMAGE_SCALING: Array[Dictionary] = [
	{
		"factor": "Base Damage",
		"desc": "Tower's base attack value",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"factor": "Level Bonus",
		"desc": "+3 damage per tower level",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"factor": "Support Buff",
		"desc": "% increase from nearby Support towers",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"factor": "Damage Type",
		"desc": "Physical, Magic, Lightning, Pure",
		"color": Color(0.9, 0.4, 0.4)
	}
]

# Tips
const COMBAT_TIPS: Array[String] = [
	"Place Support towers near damage towers for +15% damage",
	"Tesla towers with synergies chain to more enemies",
	"Poison stacks - multiple hits deal increasing DoT",
	"Holy towers prioritize bosses and affixed enemies",
	"Traps are great for chokepoints on the path",
	"Adaptive towers switch modes based on battlefield state"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(540, 640)

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
	title.text = "TOWER COMBAT"
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
	subtitle.text = "How towers attack and deal damage"
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
	footer.text = "Towers auto-attack during defense phase"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_tower_combat_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Target types section
	_build_target_types_section()

	# Attack effects section
	_build_effects_section()

	# Adaptive modes section
	_build_adaptive_section()

	# Special systems section
	_build_special_section()

	# Damage scaling section
	_build_scaling_section()

	# Tips section
	_build_tips_section()


func _build_target_types_section() -> void:
	var section := _create_section_panel("TARGET TYPES", Color(0.4, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in TARGET_TYPES:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 2)
		vbox.add_child(container)

		var name_label := Label.new()
		name_label.text = str(info.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", info.get("color", Color.WHITE))
		container.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = "  " + str(info.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		container.add_child(desc_label)

		var towers_label := Label.new()
		towers_label.text = "  Towers: " + str(info.get("towers", ""))
		towers_label.add_theme_font_size_override("font_size", 9)
		towers_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		container.add_child(towers_label)


func _build_effects_section() -> void:
	var section := _create_section_panel("ATTACK EFFECTS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for effect in ATTACK_EFFECTS:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 2)
		vbox.add_child(container)

		var header_row := HBoxContainer.new()
		header_row.add_theme_constant_override("separation", 10)
		container.add_child(header_row)

		var name_label := Label.new()
		name_label.text = str(effect.get("effect", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", effect.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(70, 0)
		header_row.add_child(name_label)

		var source_label := Label.new()
		source_label.text = "[%s]" % effect.get("source", "")
		source_label.add_theme_font_size_override("font_size", 9)
		source_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		header_row.add_child(source_label)

		var desc_label := Label.new()
		desc_label.text = "  " + str(effect.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		container.add_child(desc_label)

		var scaling_label := Label.new()
		scaling_label.text = "  Scaling: " + str(effect.get("scaling", ""))
		scaling_label.add_theme_font_size_override("font_size", 9)
		scaling_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		container.add_child(scaling_label)


func _build_adaptive_section() -> void:
	var section := _create_section_panel("ADAPTIVE MODES", Color(1.0, 0.84, 0.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for mode in ADAPTIVE_MODES:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var mode_label := Label.new()
		mode_label.text = str(mode.get("mode", ""))
		mode_label.add_theme_font_size_override("font_size", 10)
		mode_label.add_theme_color_override("font_color", mode.get("color", Color.WHITE))
		mode_label.custom_minimum_size = Vector2(60, 0)
		hbox.add_child(mode_label)

		var desc_label := Label.new()
		desc_label.text = str(mode.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_special_section() -> void:
	var section := _create_section_panel("SPECIAL SYSTEMS", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for sys in SPECIAL_SYSTEMS:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 2)
		vbox.add_child(container)

		var name_label := Label.new()
		name_label.text = str(sys.get("system", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", sys.get("color", Color.WHITE))
		container.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = "  " + str(sys.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		container.add_child(desc_label)

		var mechanic_label := Label.new()
		mechanic_label.text = "  " + str(sys.get("mechanic", ""))
		mechanic_label.add_theme_font_size_override("font_size", 9)
		mechanic_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		container.add_child(mechanic_label)


func _build_scaling_section() -> void:
	var section := _create_section_panel("DAMAGE CALCULATION", Color(0.9, 0.4, 0.4))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var formula_label := Label.new()
	formula_label.text = "Final = (Base + Level) x Support x TypeMod"
	formula_label.add_theme_font_size_override("font_size", 10)
	formula_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vbox.add_child(formula_label)

	for factor in DAMAGE_SCALING:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var factor_label := Label.new()
		factor_label.text = str(factor.get("factor", ""))
		factor_label.add_theme_font_size_override("font_size", 10)
		factor_label.add_theme_color_override("font_color", factor.get("color", Color.WHITE))
		factor_label.custom_minimum_size = Vector2(100, 0)
		hbox.add_child(factor_label)

		var desc_label := Label.new()
		desc_label.text = str(factor.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("COMBAT TIPS", Color(0.7, 0.5, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in COMBAT_TIPS:
		var tip_label := Label.new()
		tip_label.text = "- " + tip
		tip_label.add_theme_font_size_override("font_size", 10)
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
