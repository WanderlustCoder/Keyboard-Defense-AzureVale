class_name BalanceReferencePanel
extends PanelContainer
## Balance Reference Panel - Explains game economy and pacing mechanics.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

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
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_MD, 560)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "BALANCE REFERENCE"
	DesignSystem.style_label(title, "h2", ThemeColors.INFO)
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
	subtitle.text = "Game economy and pacing mechanics"
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
	footer.text = "Understanding balance helps optimize your strategy"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


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
	var section := _create_section_panel("RESOURCE CAPS", ThemeColors.INFO)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var desc := Label.new()
	desc.text = "Excess resources are trimmed at the start of each day:"
	DesignSystem.style_label(desc, "caption", ThemeColors.TEXT_DIM)
	vbox.add_child(desc)

	for cap_info in RESOURCE_CAPS:
		var day_str: String = str(cap_info.get("day", ""))
		var caps: Dictionary = cap_info.get("caps", {})
		var color: Color = cap_info.get("color", Color.WHITE)

		var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_LG)
		vbox.add_child(hbox)

		var day_label := Label.new()
		day_label.text = day_str
		DesignSystem.style_label(day_label, "caption", color)
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
		DesignSystem.style_label(caps_label, "caption", ThemeColors.TEXT_DIM)
		hbox.add_child(caps_label)


func _build_catchup_section() -> void:
	var section := _create_section_panel("CATCH-UP MECHANICS", ThemeColors.SUCCESS)
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
		container_style.set_corner_radius_all(DesignSystem.RADIUS_XS)
		container_style.set_content_margin_all(DesignSystem.SPACE_SM)
		container.add_theme_stylebox_override("panel", container_style)
		vbox.add_child(container)

		var inner_vbox := DesignSystem.create_vbox(2)
		container.add_child(inner_vbox)

		var name_label := Label.new()
		name_label.text = name_str
		DesignSystem.style_label(name_label, "caption", color)
		inner_vbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = description
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inner_vbox.add_child(desc_label)


func _build_typing_section() -> void:
	var section := _create_section_panel("COMBO DAMAGE BONUS", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var desc := Label.new()
	desc.text = "Consecutive hits increase tower damage:"
	DesignSystem.style_label(desc, "caption", ThemeColors.TEXT_DIM)
	vbox.add_child(desc)

	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", DesignSystem.SPACE_LG)
	grid.add_theme_constant_override("v_separation", DesignSystem.SPACE_XS)
	vbox.add_child(grid)

	for bonus_info in TYPING_BONUSES:
		var thresholds: Array = bonus_info.get("thresholds", [])
		for threshold in thresholds:
			var combo: int = int(threshold.get("combo", 0))

			var combo_label := Label.new()
			combo_label.text = "%d+" % combo
			DesignSystem.style_label(combo_label, "caption", Color(0.9, 0.6, 0.3))
			grid.add_child(combo_label)

	# Second row: bonuses
	for bonus_info in TYPING_BONUSES:
		var thresholds: Array = bonus_info.get("thresholds", [])
		for threshold in thresholds:
			var bonus: String = str(threshold.get("bonus", ""))

			var bonus_label := Label.new()
			bonus_label.text = bonus
			DesignSystem.style_label(bonus_label, "caption", ThemeColors.TEXT_DIM)
			grid.add_child(bonus_label)


func _build_wave_section() -> void:
	var section := _create_section_panel("WAVE SCALING", ThemeColors.ERROR)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var formula_desc := Label.new()
	formula_desc.text = WAVE_FORMULA.get("description", "")
	DesignSystem.style_label(formula_desc, "caption", ThemeColors.TEXT_DIM)
	formula_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(formula_desc)

	var stats_hbox := DesignSystem.create_hbox(DesignSystem.SPACE_XL)
	vbox.add_child(stats_hbox)

	_add_stat_box(stats_hbox, "Base HP", str(WAVE_FORMULA.get("base_hp", 30)), ThemeColors.ERROR)
	_add_stat_box(stats_hbox, "HP/Day", "+%d" % WAVE_FORMULA.get("hp_per_day", 15), Color(0.9, 0.6, 0.3))
	_add_stat_box(stats_hbox, "Boss", "x%.1f" % WAVE_FORMULA.get("boss_multiplier", 3.0), Color(0.9, 0.5, 0.9))

	# Example calculations
	var examples_label := Label.new()
	examples_label.text = "Examples: Day 1 = 45 HP, Day 5 = 105 HP, Day 10 = 180 HP"
	DesignSystem.style_label(examples_label, "caption", ThemeColors.TEXT_DIM)
	vbox.add_child(examples_label)


func _add_stat_box(parent: Control, label: String, value: String, color: Color) -> void:
	var vbox := DesignSystem.create_vbox(0)
	parent.add_child(vbox)

	var label_node := Label.new()
	label_node.text = label
	DesignSystem.style_label(label_node, "caption", ThemeColors.TEXT_DIM)
	vbox.add_child(label_node)

	var value_node := Label.new()
	value_node.text = value
	DesignSystem.style_label(value_node, "body_small", color)
	vbox.add_child(value_node)


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


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
