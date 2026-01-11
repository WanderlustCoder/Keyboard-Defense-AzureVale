class_name ComboSystemReferencePanel
extends PanelContainer
## Combo System Reference Panel - Shows combo tiers and bonuses

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Combo tiers
const COMBO_TIERS: Array[Dictionary] = [
	{
		"tier": 1,
		"name": "Warming Up",
		"min_combo": 3,
		"damage_bonus": 5,
		"gold_bonus": 5,
		"announcement": "Getting started!",
		"color": Color(0.56, 0.93, 0.56)
	},
	{
		"tier": 2,
		"name": "On Fire",
		"min_combo": 5,
		"damage_bonus": 10,
		"gold_bonus": 10,
		"announcement": "ON FIRE!",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"tier": 3,
		"name": "Blazing",
		"min_combo": 10,
		"damage_bonus": 20,
		"gold_bonus": 15,
		"announcement": "BLAZING!",
		"color": Color(1.0, 0.55, 0.0)
	},
	{
		"tier": 4,
		"name": "Inferno",
		"min_combo": 25,
		"damage_bonus": 35,
		"gold_bonus": 25,
		"announcement": "INFERNO! - Damage increased!",
		"color": Color(1.0, 0.27, 0.0)
	},
	{
		"tier": 5,
		"name": "Legendary",
		"min_combo": 50,
		"damage_bonus": 50,
		"gold_bonus": 40,
		"announcement": "LEGENDARY! - Unstoppable!",
		"color": Color(1.0, 0.0, 1.0)
	},
	{
		"tier": 6,
		"name": "Mythic",
		"min_combo": 100,
		"damage_bonus": 75,
		"gold_bonus": 60,
		"announcement": "MYTHIC! - True mastery!",
		"color": Color(0.0, 1.0, 1.0)
	},
	{
		"tier": 7,
		"name": "GODLIKE",
		"min_combo": 200,
		"damage_bonus": 100,
		"gold_bonus": 100,
		"announcement": "GODLIKE!!! - KEYBOARD MASTER!",
		"color": Color(1.0, 1.0, 1.0)
	}
]

# Combo mechanics
const COMBO_MECHANICS: Array[Dictionary] = [
	{
		"name": "Building Combo",
		"desc": "Each correctly typed word increases your combo by 1",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"name": "Breaking Combo",
		"desc": "Mistakes, typos, or taking too long resets combo to 0",
		"color": Color(0.96, 0.26, 0.21)
	},
	{
		"name": "Damage Bonus",
		"desc": "Higher combo tiers multiply your typing damage",
		"color": Color(0.5, 0.7, 0.9)
	},
	{
		"name": "Gold Bonus",
		"desc": "Higher combo tiers multiply gold earned from kills",
		"color": Color(1.0, 0.84, 0.0)
	}
]

# Combo tips
const COMBO_TIPS: Array[String] = [
	"Focus on accuracy first - maintaining combo beats raw speed",
	"Use easier lessons to build high combos before boss waves",
	"The COMBO special command instantly adds +10 combo",
	"Tier 4 (Inferno) at 25 combo gives +35% damage - a big power spike",
	"GODLIKE tier doubles both damage and gold - worth pursuing!",
	"Consider using Zen mode to practice maintaining long combos"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(520, 600)

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
	title.text = "COMBO SYSTEM"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.55, 0.0))
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
	subtitle.text = "7 combo tiers with damage and gold bonuses"
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
	footer.text = "Build combo by typing words without mistakes"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_combo_system_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Mechanics
	_build_mechanics_section()

	# Combo tiers
	_build_tiers_section()

	# Tips
	_build_tips_section()


func _build_mechanics_section() -> void:
	var section := _create_section_panel("HOW COMBOS WORK", Color(0.5, 0.7, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for mech in COMBO_MECHANICS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(mech.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", mech.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(110, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(mech.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hbox.add_child(desc_label)


func _build_tiers_section() -> void:
	var section := _create_section_panel("COMBO TIERS", Color(1.0, 0.55, 0.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Header row
	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 5)
	vbox.add_child(header_hbox)

	var headers := ["Tier", "Name", "Min", "Dmg+", "Gold+"]
	var widths := [35, 100, 40, 45, 45]
	for i in headers.size():
		var h := Label.new()
		h.text = headers[i]
		h.add_theme_font_size_override("font_size", 9)
		h.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		h.custom_minimum_size = Vector2(widths[i], 0)
		header_hbox.add_child(h)

	# Tier rows
	for tier in COMBO_TIERS:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 1)
		vbox.add_child(container)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 5)
		container.add_child(row)

		var tier_label := Label.new()
		tier_label.text = "T%d" % tier.get("tier", 0)
		tier_label.add_theme_font_size_override("font_size", 10)
		tier_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
		tier_label.custom_minimum_size = Vector2(35, 0)
		row.add_child(tier_label)

		var name_label := Label.new()
		name_label.text = str(tier.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", tier.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(100, 0)
		row.add_child(name_label)

		var min_label := Label.new()
		min_label.text = "x%d" % tier.get("min_combo", 0)
		min_label.add_theme_font_size_override("font_size", 10)
		min_label.add_theme_color_override("font_color", Color.WHITE)
		min_label.custom_minimum_size = Vector2(40, 0)
		row.add_child(min_label)

		var dmg_label := Label.new()
		dmg_label.text = "+%d%%" % tier.get("damage_bonus", 0)
		dmg_label.add_theme_font_size_override("font_size", 10)
		dmg_label.add_theme_color_override("font_color", Color(0.96, 0.26, 0.21))
		dmg_label.custom_minimum_size = Vector2(45, 0)
		row.add_child(dmg_label)

		var gold_label := Label.new()
		gold_label.text = "+%d%%" % tier.get("gold_bonus", 0)
		gold_label.add_theme_font_size_override("font_size", 10)
		gold_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		gold_label.custom_minimum_size = Vector2(45, 0)
		row.add_child(gold_label)

		# Announcement
		var ann_label := Label.new()
		ann_label.text = "  " + str(tier.get("announcement", ""))
		ann_label.add_theme_font_size_override("font_size", 9)
		ann_label.add_theme_color_override("font_color", tier.get("color", Color.WHITE).darkened(0.3))
		container.add_child(ann_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("COMBO TIPS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in COMBO_TIPS:
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
