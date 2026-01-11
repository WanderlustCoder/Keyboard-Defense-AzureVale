class_name BalanceReferencePanel
extends PanelContainer
## Balance Reference Panel - Explains game economy and pacing mechanics

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Resource cap data
const RESOURCE_CAPS: Array[Dictionary] = [
	{
		"day": "Day 5+",
		"caps": {"wood": 40, "stone": 20, "food": 25},
		"color": Color(0.6, 0.8, 0.4)
	},
	{
		"day": "Day 7+",
		"caps": {"wood": 50, "stone": 35, "food": 35},
		"color": Color(0.4, 0.8, 1.0)
	}
]

# Catch-up mechanics
const CATCHUP_MECHANICS: Array[Dictionary] = [
	{
		"name": "Stone Catch-up",
		"description": "After day 4, explore rewards favor stone if you have less than 10",
		"color": Color(0.6, 0.6, 0.7)
	},
	{
		"name": "Food Bonus",
		"description": "After day 4, gain +2 food if below 12 at dawn",
		"color": Color(0.5, 0.8, 0.3)
	}
]

# Typing bonuses
const TYPING_BONUSES: Array[Dictionary] = [
	{
		"name": "Combo Multiplier",
		"thresholds": [
			{"combo": 3, "bonus": "+10%"},
			{"combo": 5, "bonus": "+20%"},
			{"combo": 10, "bonus": "+30%"},
			{"combo": 20, "bonus": "+50%"},
			{"combo": 50, "bonus": "+100%"}
		],
		"color": Color(0.9, 0.6, 0.3)
	}
]

# Wave formula
const WAVE_FORMULA: Dictionary = {
	"description": "Wave HP scales with day: base + (day * multiplier)",
	"base_hp": 30,
	"hp_per_day": 15,
	"boss_multiplier": 3.0
}


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(500, 560)

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
	title.text = "BALANCE REFERENCE"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
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
	subtitle.text = "Game economy and pacing mechanics"
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
	footer.text = "Understanding balance helps optimize your strategy"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_balance_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Resource caps section
	_build_resource_caps_section()

	# Catch-up section
	_build_catchup_section()

	# Typing bonuses section
	_build_typing_section()

	# Wave scaling section
	_build_wave_section()


func _build_resource_caps_section() -> void:
	var section := _create_section_panel("RESOURCE CAPS", Color(0.6, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var desc := Label.new()
	desc.text = "Excess resources are trimmed at the start of each day:"
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(desc)

	for cap_info in RESOURCE_CAPS:
		var day_str: String = str(cap_info.get("day", ""))
		var caps: Dictionary = cap_info.get("caps", {})
		var color: Color = cap_info.get("color", Color.WHITE)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 15)
		vbox.add_child(hbox)

		var day_label := Label.new()
		day_label.text = day_str
		day_label.add_theme_font_size_override("font_size", 11)
		day_label.add_theme_color_override("font_color", color)
		day_label.custom_minimum_size = Vector2(70, 0)
		hbox.add_child(day_label)

		var caps_text: String = ""
		for resource in ["wood", "stone", "food"]:
			if caps.has(resource):
				if not caps_text.is_empty():
					caps_text += ", "
				caps_text += "%s: %d" % [resource.capitalize(), int(caps[resource])]

		var caps_label := Label.new()
		caps_label.text = caps_text
		caps_label.add_theme_font_size_override("font_size", 10)
		caps_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(caps_label)


func _build_catchup_section() -> void:
	var section := _create_section_panel("CATCH-UP MECHANICS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for mechanic in CATCHUP_MECHANICS:
		var name_str: String = str(mechanic.get("name", ""))
		var description: String = str(mechanic.get("description", ""))
		var color: Color = mechanic.get("color", Color.WHITE)

		var container := PanelContainer.new()
		var container_style := StyleBoxFlat.new()
		container_style.bg_color = color.darkened(0.85)
		container_style.border_color = color.darkened(0.6)
		container_style.set_border_width_all(1)
		container_style.set_corner_radius_all(4)
		container_style.set_content_margin_all(8)
		container.add_theme_stylebox_override("panel", container_style)
		vbox.add_child(container)

		var inner_vbox := VBoxContainer.new()
		inner_vbox.add_theme_constant_override("separation", 3)
		container.add_child(inner_vbox)

		var name_label := Label.new()
		name_label.text = name_str
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.add_theme_color_override("font_color", color)
		inner_vbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = description
		desc_label.add_theme_font_size_override("font_size", 10)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inner_vbox.add_child(desc_label)


func _build_typing_section() -> void:
	var section := _create_section_panel("COMBO DAMAGE BONUS", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var desc := Label.new()
	desc.text = "Consecutive hits increase tower damage:"
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(desc)

	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 15)
	grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(grid)

	for bonus_info in TYPING_BONUSES:
		var thresholds: Array = bonus_info.get("thresholds", [])
		for threshold in thresholds:
			var combo: int = int(threshold.get("combo", 0))
			var bonus: String = str(threshold.get("bonus", ""))

			var combo_label := Label.new()
			combo_label.text = "%d+" % combo
			combo_label.add_theme_font_size_override("font_size", 11)
			combo_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3))
			grid.add_child(combo_label)

	# Second row: bonuses
	for bonus_info in TYPING_BONUSES:
		var thresholds: Array = bonus_info.get("thresholds", [])
		for threshold in thresholds:
			var bonus: String = str(threshold.get("bonus", ""))

			var bonus_label := Label.new()
			bonus_label.text = bonus
			bonus_label.add_theme_font_size_override("font_size", 10)
			bonus_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
			grid.add_child(bonus_label)


func _build_wave_section() -> void:
	var section := _create_section_panel("WAVE SCALING", Color(0.9, 0.4, 0.4))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var formula_desc := Label.new()
	formula_desc.text = WAVE_FORMULA.get("description", "")
	formula_desc.add_theme_font_size_override("font_size", 11)
	formula_desc.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	formula_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(formula_desc)

	var stats_hbox := HBoxContainer.new()
	stats_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(stats_hbox)

	_add_stat_box(stats_hbox, "Base HP", str(WAVE_FORMULA.get("base_hp", 30)), Color(0.9, 0.4, 0.4))
	_add_stat_box(stats_hbox, "HP/Day", "+%d" % WAVE_FORMULA.get("hp_per_day", 15), Color(0.9, 0.6, 0.3))
	_add_stat_box(stats_hbox, "Boss", "x%.1f" % WAVE_FORMULA.get("boss_multiplier", 3.0), Color(0.9, 0.5, 0.9))

	# Example calculations
	var examples_label := Label.new()
	examples_label.text = "Examples: Day 1 = 45 HP, Day 5 = 105 HP, Day 10 = 180 HP"
	examples_label.add_theme_font_size_override("font_size", 10)
	examples_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	vbox.add_child(examples_label)


func _add_stat_box(parent: Control, label: String, value: String, color: Color) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	parent.add_child(vbox)

	var label_node := Label.new()
	label_node.text = label
	label_node.add_theme_font_size_override("font_size", 10)
	label_node.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(label_node)

	var value_node := Label.new()
	value_node.text = value
	value_node.add_theme_font_size_override("font_size", 12)
	value_node.add_theme_color_override("font_color", color)
	vbox.add_child(value_node)


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


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
