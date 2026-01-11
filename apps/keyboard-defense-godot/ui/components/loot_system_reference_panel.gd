class_name LootSystemReferencePanel
extends PanelContainer
## Loot System Reference Panel - Shows loot quality tiers and drop mechanics

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Quality tiers
const QUALITY_TIERS: Array[Dictionary] = [
	{
		"id": "poor",
		"name": "Poor",
		"multiplier": 0.5,
		"accuracy_range": "0-60%",
		"desc": "Subpar performance, reduced rewards",
		"color": Color(0.5, 0.5, 0.5)
	},
	{
		"id": "normal",
		"name": "Normal",
		"multiplier": 1.0,
		"accuracy_range": "60-85%",
		"desc": "Standard drop rates and amounts",
		"color": Color(0.8, 0.8, 0.8)
	},
	{
		"id": "good",
		"name": "Good",
		"multiplier": 1.25,
		"accuracy_range": "85-95%",
		"desc": "Improved drops for solid accuracy",
		"color": Color(0.4, 0.8, 0.4)
	},
	{
		"id": "excellent",
		"name": "Excellent",
		"multiplier": 1.5,
		"accuracy_range": "95-99%",
		"desc": "Great rewards for excellent typing",
		"color": Color(0.4, 0.6, 1.0)
	},
	{
		"id": "perfect",
		"name": "Perfect",
		"multiplier": 2.0,
		"accuracy_range": "99-100%",
		"desc": "Maximum rewards plus bonus drops!",
		"color": Color(1.0, 0.84, 0.0)
	}
]

# Loot mechanics
const LOOT_MECHANICS: Array[Dictionary] = [
	{
		"name": "Accuracy Scaling",
		"desc": "Your typing accuracy determines loot quality tier",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"name": "Quality Multiplier",
		"desc": "All drop amounts are multiplied by tier multiplier (0.5x to 2.0x)",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"name": "Guaranteed Drops",
		"desc": "Some enemies always drop certain resources",
		"color": Color(0.8, 0.6, 1.0)
	},
	{
		"name": "Chance Drops",
		"desc": "Additional drops roll based on percentage chance",
		"color": Color(1.0, 0.6, 0.2)
	},
	{
		"name": "Perfect Bonus",
		"desc": "100% accuracy with no mistakes grants extra bonus loot",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"name": "Boss Loot",
		"desc": "Bosses have separate loot tables with better drops",
		"color": Color(0.96, 0.26, 0.21)
	}
]

# Drop types
const DROP_TYPES: Array[Dictionary] = [
	{
		"name": "Gold",
		"desc": "Currency for buildings, upgrades, and items",
		"icon": "coin",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"name": "Wood",
		"desc": "Basic construction material",
		"icon": "log",
		"color": Color(0.6, 0.4, 0.2)
	},
	{
		"name": "Stone",
		"desc": "Advanced construction material",
		"icon": "rock",
		"color": Color(0.5, 0.5, 0.5)
	},
	{
		"name": "Iron",
		"desc": "Metal for weapons and armor",
		"icon": "ingot",
		"color": Color(0.7, 0.7, 0.8)
	},
	{
		"name": "Crystals",
		"desc": "Rare magical resource for upgrades",
		"icon": "gem",
		"color": Color(0.8, 0.4, 1.0)
	},
	{
		"name": "Experience",
		"desc": "Increases player level",
		"icon": "star",
		"color": Color(0.4, 0.8, 1.0)
	}
]

# Tips
const LOOT_TIPS: Array[String] = [
	"Type accurately to maximize your loot rewards",
	"Perfect kills (100% accuracy, no mistakes) give 2x loot plus bonuses",
	"Boss enemies have their own loot tables with better rewards",
	"Loot is added to a queue and collected at wave end",
	"The quality tier is calculated per enemy based on that kill's accuracy"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(520, 660)

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
	title.text = "LOOT SYSTEM"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
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
	subtitle.text = "Typing accuracy determines loot quality and rewards"
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
	footer.text = "Type accurately for maximum rewards!"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_loot_system_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Quality tiers
	_build_quality_section()

	# Loot mechanics
	_build_mechanics_section()

	# Drop types
	_build_drops_section()

	# Tips
	_build_tips_section()


func _build_quality_section() -> void:
	var section := _create_section_panel("QUALITY TIERS", Color(0.6, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tier in QUALITY_TIERS:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 1)
		vbox.add_child(container)

		var header_hbox := HBoxContainer.new()
		header_hbox.add_theme_constant_override("separation", 10)
		container.add_child(header_hbox)

		var name_label := Label.new()
		name_label.text = str(tier.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", tier.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(70, 0)
		header_hbox.add_child(name_label)

		var accuracy_label := Label.new()
		accuracy_label.text = str(tier.get("accuracy_range", ""))
		accuracy_label.add_theme_font_size_override("font_size", 10)
		accuracy_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
		accuracy_label.custom_minimum_size = Vector2(60, 0)
		header_hbox.add_child(accuracy_label)

		var mult_label := Label.new()
		mult_label.text = "%.1fx" % tier.get("multiplier", 1.0)
		mult_label.add_theme_font_size_override("font_size", 10)
		mult_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.3))
		mult_label.custom_minimum_size = Vector2(40, 0)
		header_hbox.add_child(mult_label)

		var desc_label := Label.new()
		desc_label.text = str(tier.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		header_hbox.add_child(desc_label)


func _build_mechanics_section() -> void:
	var section := _create_section_panel("LOOT MECHANICS", Color(0.5, 0.7, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for mech in LOOT_MECHANICS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(mech.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", mech.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(120, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(mech.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hbox.add_child(desc_label)


func _build_drops_section() -> void:
	var section := _create_section_panel("DROP TYPES", Color(0.8, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Two-column layout
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(grid)

	for drop in DROP_TYPES:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 5)
		hbox.custom_minimum_size = Vector2(200, 0)
		grid.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(drop.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", drop.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(70, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(drop.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("LOOT TIPS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in LOOT_TIPS:
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
