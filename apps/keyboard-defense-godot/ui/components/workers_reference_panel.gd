class_name WorkersReferencePanel
extends PanelContainer
## Workers Reference Panel - Shows worker system mechanics and assignments.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Worker mechanics
const WORKER_MECHANICS: Array[Dictionary] = [
	{
		"id": "production_bonus",
		"name": "Production Bonus",
		"value": "+50%",
		"desc": "Each worker assigned increases building production by 50%",
		"example": "Farm (3 food) + 1 worker = 4.5 → 4 food",
		"color": Color(0.4, 0.7, 0.3)
	},
	{
		"id": "upkeep_cost",
		"name": "Upkeep Cost",
		"value": "1 food/day",
		"desc": "Each assigned worker consumes 1 food per day",
		"example": "3 workers = 3 food/day upkeep",
		"color": Color(0.96, 0.26, 0.21)
	},
	{
		"id": "starvation",
		"name": "Starvation",
		"value": "Workers lost",
		"desc": "If food runs out, workers are removed starting from buildings with most workers",
		"example": "0 food + 3 workers → workers removed until fed",
		"color": Color(0.8, 0.3, 0.3)
	}
]

# Worker capacity by building type
const WORKER_CAPACITY: Array[Dictionary] = [
	{
		"building": "Farm",
		"lv1": 1,
		"lv2": 2,
		"lv3": 3,
		"production": "Food",
		"color": Color(0.4, 0.7, 0.3)
	},
	{
		"building": "Lumber Mill",
		"lv1": 1,
		"lv2": 2,
		"lv3": 3,
		"production": "Wood",
		"color": Color(0.55, 0.27, 0.07)
	},
	{
		"building": "Quarry",
		"lv1": 1,
		"lv2": 2,
		"lv3": 3,
		"production": "Stone",
		"color": Color(0.5, 0.5, 0.6)
	},
	{
		"building": "Market",
		"lv1": 1,
		"lv2": 2,
		"lv3": 2,
		"production": "Gold",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"building": "Barracks",
		"lv1": 2,
		"lv2": 3,
		"lv3": 4,
		"production": "Defense",
		"color": Color(0.8, 0.4, 0.4)
	},
	{
		"building": "Workshop",
		"lv1": 1,
		"lv2": 2,
		"lv3": 3,
		"production": "Tech",
		"color": Color(0.6, 0.4, 0.8)
	}
]

# Worker commands
const WORKER_COMMANDS: Array[Dictionary] = [
	{
		"command": "assign [building]",
		"desc": "Assign an available worker to a building",
		"example": "assign farm",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"command": "unassign [building]",
		"desc": "Remove a worker from a building",
		"example": "unassign quarry",
		"color": Color(0.8, 0.5, 0.3)
	},
	{
		"command": "workers",
		"desc": "View worker summary and assignments",
		"example": "workers",
		"color": Color(0.5, 0.6, 0.8)
	}
]

# Worker tips
const WORKER_TIPS: Array[String] = [
	"Workers multiply production - prioritize food buildings to sustain upkeep",
	"Assigning workers to farms helps pay for their own food upkeep",
	"Higher building levels support more workers and boost production",
	"Balance worker assignments to avoid resource shortages",
	"Unassigned workers don't cost food but also don't produce",
	"Watch your food reserves before assigning too many workers"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 580)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "WORKER SYSTEM"
	DesignSystem.style_label(title, "h2", Color(0.4, 0.7, 0.3))
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
	subtitle.text = "Worker assignment and production bonuses"
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
	footer.text = "Type 'workers' during planning phase"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_workers_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Mechanics overview
	_build_mechanics_section()

	# Worker capacity by building
	_build_capacity_section()

	# Commands
	_build_commands_section()

	# Tips
	_build_tips_section()


func _build_mechanics_section() -> void:
	var section := _create_section_panel("MECHANICS", Color(0.4, 0.7, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for mech in WORKER_MECHANICS:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 2)
		vbox.add_child(container)

		# Name and value
		var header_hbox := HBoxContainer.new()
		header_hbox.add_theme_constant_override("separation", 10)
		container.add_child(header_hbox)

		var name_label := Label.new()
		name_label.text = str(mech.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.add_theme_color_override("font_color", mech.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(120, 0)
		header_hbox.add_child(name_label)

		var value_label := Label.new()
		value_label.text = str(mech.get("value", ""))
		value_label.add_theme_font_size_override("font_size", 11)
		value_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		header_hbox.add_child(value_label)

		# Description
		var desc_label := Label.new()
		desc_label.text = "  " + str(mech.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		container.add_child(desc_label)

		# Example
		var example_label := Label.new()
		example_label.text = "  Ex: " + str(mech.get("example", ""))
		example_label.add_theme_font_size_override("font_size", 9)
		example_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
		container.add_child(example_label)


func _build_capacity_section() -> void:
	var section := _create_section_panel("WORKER CAPACITY BY BUILDING", Color(0.5, 0.6, 0.8))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Header row
	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 5)
	vbox.add_child(header_hbox)

	var headers := ["Building", "Lv1", "Lv2", "Lv3", "Produces"]
	var widths := [100, 30, 30, 30, 70]
	for i in headers.size():
		var h := Label.new()
		h.text = headers[i]
		h.add_theme_font_size_override("font_size", 9)
		h.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
		h.custom_minimum_size = Vector2(widths[i], 0)
		header_hbox.add_child(h)

	# Building rows
	for building in WORKER_CAPACITY:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 5)
		vbox.add_child(row)

		var name_label := Label.new()
		name_label.text = str(building.get("building", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", building.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(100, 0)
		row.add_child(name_label)

		for level in ["lv1", "lv2", "lv3"]:
			var lv_label := Label.new()
			lv_label.text = str(building.get(level, 0))
			lv_label.add_theme_font_size_override("font_size", 10)
			lv_label.add_theme_color_override("font_color", Color.WHITE)
			lv_label.custom_minimum_size = Vector2(30, 0)
			row.add_child(lv_label)

		var prod_label := Label.new()
		prod_label.text = str(building.get("production", ""))
		prod_label.add_theme_font_size_override("font_size", 10)
		prod_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.3))
		prod_label.custom_minimum_size = Vector2(70, 0)
		row.add_child(prod_label)


func _build_commands_section() -> void:
	var section := _create_section_panel("COMMANDS", Color(0.5, 0.7, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for cmd in WORKER_COMMANDS:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 1)
		vbox.add_child(container)

		var cmd_label := Label.new()
		cmd_label.text = str(cmd.get("command", ""))
		cmd_label.add_theme_font_size_override("font_size", 10)
		cmd_label.add_theme_color_override("font_color", cmd.get("color", Color.WHITE))
		container.add_child(cmd_label)

		var desc_label := Label.new()
		desc_label.text = "  " + str(cmd.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		container.add_child(desc_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("TIPS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in WORKER_TIPS:
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
