class_name PracticeModesPanel
extends PanelContainer
## Practice Modes Panel - Shows practice goal modes and thresholds

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Practice goal definitions (from PracticeGoals)
const PRACTICE_GOALS: Array[Dictionary] = [
	{
		"id": "balanced",
		"name": "Balanced",
		"description": "Keep a steady balance of accuracy and pace",
		"color": Color(0.5, 0.8, 0.3),
		"thresholds": {
			"min_hit_rate": 0.55,
			"min_accuracy": 0.78,
			"max_backspace_rate": 0.20,
			"max_incomplete_rate": 0.30
		}
	},
	{
		"id": "accuracy",
		"name": "Accuracy",
		"description": "Prioritize correct words over speed",
		"color": Color(0.4, 0.8, 1.0),
		"thresholds": {
			"min_hit_rate": 0.45,
			"min_accuracy": 0.85,
			"max_backspace_rate": 0.25,
			"max_incomplete_rate": 0.35
		}
	},
	{
		"id": "backspace",
		"name": "Clean Keystrokes",
		"description": "Reduce corrections and commit to clean input",
		"color": Color(0.9, 0.6, 0.3),
		"thresholds": {
			"min_hit_rate": 0.50,
			"min_accuracy": 0.75,
			"max_backspace_rate": 0.12,
			"max_incomplete_rate": 0.30
		}
	},
	{
		"id": "speed",
		"name": "Speed",
		"description": "Maintain a fast pace with steady hits",
		"color": Color(0.9, 0.4, 0.4),
		"thresholds": {
			"min_hit_rate": 0.70,
			"min_accuracy": 0.75,
			"max_backspace_rate": 0.25,
			"max_incomplete_rate": 0.25
		}
	}
]

# Threshold explanations
const THRESHOLD_INFO: Array[Dictionary] = [
	{
		"name": "Hit Rate",
		"description": "Percentage of words successfully completed",
		"direction": "min",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"name": "Accuracy",
		"description": "Correct characters vs total keystrokes",
		"direction": "min",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"name": "Backspace Rate",
		"description": "Corrections made while typing",
		"direction": "max",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"name": "Incomplete Rate",
		"description": "Words started but not finished",
		"direction": "max",
		"color": Color(0.9, 0.4, 0.4)
	}
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(520, 580)

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
	title.text = "PRACTICE MODES"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.5, 0.8, 0.3))
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
	subtitle.text = "Focus modes with different performance thresholds"
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
	footer.text = "Type 'goal <mode>' to change your practice focus"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_practice_modes() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Practice modes section
	_build_modes_section()

	# Threshold explanations
	_build_thresholds_section()


func _build_modes_section() -> void:
	var section := _create_section_panel("PRACTICE GOALS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for goal in PRACTICE_GOALS:
		var card := _create_goal_card(goal)
		vbox.add_child(card)


func _create_goal_card(goal: Dictionary) -> Control:
	var name_str: String = str(goal.get("name", ""))
	var description: String = str(goal.get("description", ""))
	var color: Color = goal.get("color", Color.WHITE)
	var thresholds: Dictionary = goal.get("thresholds", {})

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = color.darkened(0.85)
	container_style.border_color = color.darkened(0.6)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(8)
	container.add_theme_stylebox_override("panel", container_style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 4)
	container.add_child(main_vbox)

	# Header
	var name_label := Label.new()
	name_label.text = name_str
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", color)
	main_vbox.add_child(name_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	main_vbox.add_child(desc_label)

	# Thresholds
	var thresh_grid := GridContainer.new()
	thresh_grid.columns = 4
	thresh_grid.add_theme_constant_override("h_separation", 10)
	thresh_grid.add_theme_constant_override("v_separation", 2)
	main_vbox.add_child(thresh_grid)

	# Format thresholds
	var hit_rate: float = float(thresholds.get("min_hit_rate", 0))
	var accuracy: float = float(thresholds.get("min_accuracy", 0))
	var backspace: float = float(thresholds.get("max_backspace_rate", 0))
	var incomplete: float = float(thresholds.get("max_incomplete_rate", 0))

	_add_threshold_item(thresh_grid, "Hit", "%.0f%%" % (hit_rate * 100), Color(0.5, 0.8, 0.3))
	_add_threshold_item(thresh_grid, "Acc", "%.0f%%" % (accuracy * 100), Color(0.4, 0.8, 1.0))
	_add_threshold_item(thresh_grid, "BS", "<%.0f%%" % (backspace * 100), Color(0.9, 0.6, 0.3))
	_add_threshold_item(thresh_grid, "Inc", "<%.0f%%" % (incomplete * 100), Color(0.9, 0.4, 0.4))

	return container


func _add_threshold_item(grid: GridContainer, label: String, value: String, color: Color) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 2)

	var label_node := Label.new()
	label_node.text = label + ":"
	label_node.add_theme_font_size_override("font_size", 9)
	label_node.add_theme_color_override("font_color", color.darkened(0.3))
	hbox.add_child(label_node)

	var value_node := Label.new()
	value_node.text = value
	value_node.add_theme_font_size_override("font_size", 9)
	value_node.add_theme_color_override("font_color", color)
	hbox.add_child(value_node)

	grid.add_child(hbox)


func _build_thresholds_section() -> void:
	var section := _create_section_panel("THRESHOLD METRICS", Color(0.4, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in THRESHOLD_INFO:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var name_str: String = str(info.get("name", ""))
		var description: String = str(info.get("description", ""))
		var direction: String = str(info.get("direction", "min"))
		var color: Color = info.get("color", Color.WHITE)

		var name_label := Label.new()
		name_label.text = name_str
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", color)
		name_label.custom_minimum_size = Vector2(100, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = description
		desc_label.add_theme_font_size_override("font_size", 10)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(desc_label)

		var dir_label := Label.new()
		dir_label.text = "(%s)" % direction
		dir_label.add_theme_font_size_override("font_size", 9)
		dir_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		hbox.add_child(dir_label)


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
