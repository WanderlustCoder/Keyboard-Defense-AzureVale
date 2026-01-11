class_name StatusEffectsReferencePanel
extends PanelContainer
## Status Effects Reference Panel - Shows all debuffs, DoTs, and special effects

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Movement effects
const MOVEMENT_EFFECTS: Array[Dictionary] = [
	{
		"id": "slow",
		"name": "Slowed",
		"desc": "Movement speed reduced (15-60% based on tier)",
		"duration": "2-5s by tier",
		"stacks": "Yes, diminishing returns (max 80%)",
		"color": Color(0.53, 0.81, 0.92)
	},
	{
		"id": "frozen",
		"name": "Frozen",
		"desc": "Completely immobilized, takes 1.5x damage",
		"duration": "1.5s",
		"stacks": "No, grants 5s immunity after",
		"color": Color(0.0, 0.75, 1.0)
	},
	{
		"id": "rooted",
		"name": "Rooted",
		"desc": "Held in place but can still attack",
		"duration": "2s",
		"stacks": "No",
		"color": Color(0.13, 0.55, 0.13)
	}
]

# Damage over time effects
const DOT_EFFECTS: Array[Dictionary] = [
	{
		"id": "burning",
		"name": "Burning",
		"desc": "Fire damage over time (3 dmg/tick)",
		"duration": "5s",
		"stacks": "Up to 5x, removed by frozen",
		"color": Color(1.0, 0.27, 0.0)
	},
	{
		"id": "poisoned",
		"name": "Poisoned",
		"desc": "Poison damage (2 dmg/tick), reduces healing 50%",
		"duration": "8s",
		"stacks": "Up to 10x, damage increases per stack",
		"color": Color(0.6, 0.2, 0.8)
	},
	{
		"id": "bleeding",
		"name": "Bleeding",
		"desc": "Physical damage (4 dmg every 2s)",
		"duration": "6s",
		"stacks": "Up to 3x, refreshed by movement",
		"color": Color(0.55, 0.0, 0.0)
	},
	{
		"id": "corrupting",
		"name": "Corrupting",
		"desc": "Corruption damage (5 dmg/s), reduces max HP 2%/tick",
		"duration": "10s",
		"stacks": "No",
		"color": Color(0.29, 0.0, 0.51)
	}
]

# Defensive reduction effects
const DEFENSE_EFFECTS: Array[Dictionary] = [
	{
		"id": "armor_broken",
		"name": "Armor Broken",
		"desc": "Armor reduced by 50%",
		"duration": "8s",
		"stacks": "No",
		"color": Color(0.5, 0.5, 0.5)
	},
	{
		"id": "exposed",
		"name": "Exposed",
		"desc": "Takes 25% increased damage from all sources",
		"duration": "5s",
		"stacks": "No",
		"color": Color(1.0, 0.41, 0.71)
	},
	{
		"id": "weakened",
		"name": "Weakened",
		"desc": "Deals 30% reduced damage",
		"duration": "6s",
		"stacks": "No",
		"color": Color(0.83, 0.83, 0.83)
	}
]

# Special effects
const SPECIAL_EFFECTS: Array[Dictionary] = [
	{
		"id": "marked",
		"name": "Marked",
		"desc": "All towers prioritize this target, +25% crit chance",
		"duration": "10s",
		"stacks": "No",
		"color": Color(1.0, 0.0, 0.0)
	},
	{
		"id": "purifying",
		"name": "Purifying",
		"desc": "Being cleansed, 1.5x bonus damage to corrupted",
		"duration": "3s (channeled)",
		"stacks": "No",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"id": "confused",
		"name": "Confused",
		"desc": "Moves erratically, 15% chance to attack allies",
		"duration": "3s",
		"stacks": "No",
		"color": Color(1.0, 1.0, 0.0)
	}
]

# Effect interactions
const EFFECT_INTERACTIONS: Array[Dictionary] = [
	{
		"interaction": "Frozen + Burning",
		"result": "Both effects are removed (mutual destruction)",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"interaction": "Frozen immunity",
		"result": "After frozen ends, 5s immunity to freeze",
		"color": Color(0.0, 0.75, 1.0)
	},
	{
		"interaction": "Exposed + Any damage",
		"result": "25% damage increase stacks with other multipliers",
		"color": Color(1.0, 0.41, 0.71)
	},
	{
		"interaction": "Corrupting + Max HP",
		"result": "Permanent HP reduction for battle duration",
		"color": Color(0.29, 0.0, 0.51)
	}
]

# Tips
const EFFECT_TIPS: Array[String] = [
	"Slow effects stack with diminishing returns up to 80%",
	"Frozen enemies take 50% extra damage from all sources",
	"Use poison on high-HP enemies for stacking damage",
	"Armor Broken is great against armored enemies",
	"Mark priority targets for focused tower fire"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(520, 620)

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
	title.text = "STATUS EFFECTS"
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
	subtitle.text = "Debuffs, DoTs, and special effects on enemies"
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
	footer.text = "13 status effects available"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_status_effects_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Movement effects section
	_build_effects_section("MOVEMENT EFFECTS", Color(0.53, 0.81, 0.92), MOVEMENT_EFFECTS)

	# DoT effects section
	_build_effects_section("DAMAGE OVER TIME", Color(1.0, 0.27, 0.0), DOT_EFFECTS)

	# Defense reduction section
	_build_effects_section("DEFENSIVE REDUCTION", Color(0.5, 0.5, 0.5), DEFENSE_EFFECTS)

	# Special effects section
	_build_effects_section("SPECIAL EFFECTS", Color(1.0, 0.0, 0.0), SPECIAL_EFFECTS)

	# Interactions section
	_build_interactions_section()

	# Tips section
	_build_tips_section()


func _build_effects_section(title: String, color: Color, effects: Array[Dictionary]) -> void:
	var section := _create_section_panel(title, color)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in effects:
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

		var details_label := Label.new()
		details_label.text = "  Duration: %s | Stacks: %s" % [info.get("duration", ""), info.get("stacks", "")]
		details_label.add_theme_font_size_override("font_size", 9)
		details_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		container.add_child(details_label)


func _build_interactions_section() -> void:
	var section := _create_section_panel("EFFECT INTERACTIONS", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in EFFECT_INTERACTIONS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var interaction_label := Label.new()
		interaction_label.text = str(info.get("interaction", ""))
		interaction_label.add_theme_font_size_override("font_size", 10)
		interaction_label.add_theme_color_override("font_color", info.get("color", Color.WHITE))
		interaction_label.custom_minimum_size = Vector2(130, 0)
		hbox.add_child(interaction_label)

		var result_label := Label.new()
		result_label.text = str(info.get("result", ""))
		result_label.add_theme_font_size_override("font_size", 9)
		result_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(result_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("EFFECT TIPS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in EFFECT_TIPS:
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
