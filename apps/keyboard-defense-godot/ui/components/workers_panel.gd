class_name WorkersPanel
extends PanelContainer
## Workers Panel - Shows worker assignments and production bonuses.
## Migrated to use DesignSystem and ThemeColors for consistency.

# Preload for test compatibility (when autoload isn't available)
const DesignSystem = preload("res://ui/design_system.gd")

signal closed

var _worker_summary: Dictionary = {}

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Production bonus constant
const WORKER_PRODUCTION_BONUS := 0.5  # +50% per worker
const WORKER_UPKEEP := 1  # Food per worker per day

# Building colors
const BUILDING_COLORS: Dictionary = {
	"farm": Color(0.5, 0.8, 0.3),
	"lumber": Color(0.6, 0.4, 0.2),
	"quarry": Color(0.6, 0.6, 0.7),
	"market": Color(1.0, 0.84, 0.0),
	"barracks": Color(0.9, 0.4, 0.4),
	"workshop": Color(0.8, 0.6, 0.4),
	"library": Color(0.6, 0.8, 1.0),
	"smithy": Color(0.7, 0.5, 0.3)
}


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 540)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "WORKER MANAGEMENT"
	DesignSystem.style_label(title, "h2", Color(0.8, 0.7, 0.5))
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
	subtitle.text = "Assign workers to boost building production"
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
	footer.text = "Type 'assign worker <building>' during day phase"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_workers(summary: Dictionary = {}) -> void:
	_worker_summary = summary
	_build_content()
	show()


func refresh(summary: Dictionary = {}) -> void:
	_worker_summary = summary
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Summary section
	_build_summary_section()

	# Mechanics reference
	_build_mechanics_section()

	# Assignments section
	_build_assignments_section()

	# Commands section
	_build_commands_section()


func _build_summary_section() -> void:
	var section := PanelContainer.new()

	var section_style := StyleBoxFlat.new()
	section_style.bg_color = Color(0.15, 0.18, 0.12, 0.9)
	section_style.border_color = Color(0.5, 0.6, 0.4, 0.7)
	section_style.set_border_width_all(2)
	section_style.set_corner_radius_all(6)
	section_style.set_content_margin_all(10)
	section.add_theme_stylebox_override("panel", section_style)

	_content_vbox.add_child(section)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 30)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	section.add_child(hbox)

	var total: int = int(_worker_summary.get("total_workers", 0))
	var max_workers: int = int(_worker_summary.get("max_workers", 10))
	var assigned: int = int(_worker_summary.get("assigned", 0))
	var available: int = int(_worker_summary.get("available", 0))
	var upkeep: int = int(_worker_summary.get("upkeep", 0))

	_add_summary_stat(hbox, "Total", "%d/%d" % [total, max_workers], Color(0.8, 0.7, 0.5))
	_add_summary_stat(hbox, "Assigned", str(assigned), Color(0.4, 0.9, 0.4))
	_add_summary_stat(hbox, "Available", str(available), Color(0.6, 0.8, 1.0))
	_add_summary_stat(hbox, "Food/Day", str(upkeep), Color(0.5, 0.8, 0.3))


func _add_summary_stat(parent: Control, label: String, value: String, color: Color) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	parent.add_child(vbox)

	var label_node := Label.new()
	label_node.text = label
	label_node.add_theme_font_size_override("font_size", 10)
	label_node.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label_node)

	var value_node := Label.new()
	value_node.text = value
	value_node.add_theme_font_size_override("font_size", 14)
	value_node.add_theme_color_override("font_color", color)
	value_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(value_node)


func _build_mechanics_section() -> void:
	var section := _create_section_panel("PRODUCTION BONUS", Color(0.4, 0.9, 0.4))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Bonus explanation
	var bonus_text := Label.new()
	bonus_text.text = "+%.0f%% production per worker assigned" % (WORKER_PRODUCTION_BONUS * 100)
	bonus_text.add_theme_font_size_override("font_size", 12)
	bonus_text.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	vbox.add_child(bonus_text)

	# Examples
	var examples: Array[String] = [
		"1 worker = +50% production",
		"2 workers = +100% production",
		"3 workers = +150% production"
	]

	for example in examples:
		var ex_label := Label.new()
		ex_label.text = "  " + example
		ex_label.add_theme_font_size_override("font_size", 10)
		ex_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		vbox.add_child(ex_label)

	# Upkeep note
	var upkeep_label := Label.new()
	upkeep_label.text = "Upkeep: %d food per worker per day" % WORKER_UPKEEP
	upkeep_label.add_theme_font_size_override("font_size", 11)
	upkeep_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3))
	vbox.add_child(upkeep_label)


func _build_assignments_section() -> void:
	var section := _create_section_panel("BUILDING ASSIGNMENTS", Color(0.8, 0.7, 0.5))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var assignments: Array = _worker_summary.get("assignments", [])

	if assignments.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No buildings with worker capacity"
		empty_label.add_theme_font_size_override("font_size", 11)
		empty_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		vbox.add_child(empty_label)
		return

	for assignment in assignments:
		var row := _create_assignment_row(assignment)
		vbox.add_child(row)


func _create_assignment_row(assignment: Dictionary) -> Control:
	var building_type: String = str(assignment.get("building_type", ""))
	var workers: int = int(assignment.get("workers", 0))
	var capacity: int = int(assignment.get("capacity", 0))
	var bonus: float = float(assignment.get("bonus", 0))
	var pos: Vector2i = assignment.get("position", Vector2i.ZERO)

	var container := PanelContainer.new()

	var color: Color = BUILDING_COLORS.get(building_type, Color(0.5, 0.5, 0.5))
	var has_workers: bool = workers > 0

	var container_style := StyleBoxFlat.new()
	if has_workers:
		container_style.bg_color = color.darkened(0.8)
		container_style.border_color = color.darkened(0.5)
	else:
		container_style.bg_color = Color(0.1, 0.1, 0.12, 0.7)
		container_style.border_color = Color(0.3, 0.3, 0.35)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(8)
	container.add_theme_stylebox_override("panel", container_style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	container.add_child(hbox)

	# Building name and position
	var name_vbox := VBoxContainer.new()
	name_vbox.add_theme_constant_override("separation", 0)
	name_vbox.custom_minimum_size = Vector2(100, 0)
	hbox.add_child(name_vbox)

	var name_label := Label.new()
	name_label.text = building_type.capitalize()
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", color if has_workers else ThemeColors.TEXT_DIM)
	name_vbox.add_child(name_label)

	var pos_label := Label.new()
	pos_label.text = "(%d, %d)" % [pos.x, pos.y]
	pos_label.add_theme_font_size_override("font_size", 9)
	pos_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	name_vbox.add_child(pos_label)

	# Worker count
	var count_label := Label.new()
	count_label.text = "%d/%d" % [workers, capacity]
	count_label.add_theme_font_size_override("font_size", 12)
	if workers >= capacity:
		count_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	elif workers > 0:
		count_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
	else:
		count_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	count_label.custom_minimum_size = Vector2(50, 0)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(count_label)

	# Production bonus
	var bonus_label := Label.new()
	if bonus > 0:
		bonus_label.text = "+%.0f%%" % (bonus * 100)
		bonus_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	else:
		bonus_label.text = "---"
		bonus_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	bonus_label.add_theme_font_size_override("font_size", 11)
	bonus_label.custom_minimum_size = Vector2(60, 0)
	bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(bonus_label)

	return container


func _build_commands_section() -> void:
	var section := _create_section_panel("WORKER COMMANDS", Color(0.6, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var commands: Array[Dictionary] = [
		{"cmd": "assign worker farm", "desc": "Add worker to farm"},
		{"cmd": "unassign worker farm", "desc": "Remove worker from farm"},
		{"cmd": "workers", "desc": "Show worker summary"}
	]

	for cmd_info in commands:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var cmd_label := Label.new()
		cmd_label.text = str(cmd_info.get("cmd", ""))
		cmd_label.add_theme_font_size_override("font_size", 10)
		cmd_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
		cmd_label.custom_minimum_size = Vector2(180, 0)
		hbox.add_child(cmd_label)

		var desc_label := Label.new()
		desc_label.text = str(cmd_info.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 10)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


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
