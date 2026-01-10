class_name PracticeGoalsPanel
extends PanelContainer
## Practice Goals Panel - Shows different typing practice goals and their thresholds

signal closed
signal goal_selected(goal_id: String)

const ThemeColors = preload("res://ui/theme_colors.gd")
const PracticeGoals = preload("res://sim/practice_goals.gd")

var _current_goal: String = "balanced"
var _profile: Dictionary = {}

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Goal colors
const GOAL_COLORS: Dictionary = {
	"balanced": Color(0.4, 0.8, 0.6),
	"accuracy": Color(0.4, 0.8, 1.0),
	"backspace": Color(0.9, 0.6, 0.9),
	"speed": Color(1.0, 0.6, 0.3)
}

func _ready() -> void:
	_build_ui()
	hide()

func _build_ui() -> void:
	custom_minimum_size = Vector2(460, 480)

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
	title.text = "PRACTICE GOALS"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.4, 0.8, 0.6))
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
	subtitle.text = "Choose a goal focus to guide your practice sessions"
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
	footer.text = "Goals affect coach suggestions and trend analysis"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)

func show_practice_goals(profile: Dictionary = {}, current_goal: String = "balanced") -> void:
	_profile = profile
	_current_goal = current_goal
	_build_content()
	show()

func refresh() -> void:
	_build_content()

func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()

func _build_content() -> void:
	_clear_content()

	# Current goal section
	_build_current_goal_section()

	# Goals header
	var goals_header := Label.new()
	goals_header.text = "AVAILABLE GOALS"
	goals_header.add_theme_font_size_override("font_size", 14)
	goals_header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	_content_vbox.add_child(goals_header)

	# Build goal cards
	for goal_id in PracticeGoals.GOAL_ORDER:
		var card := _create_goal_card(goal_id)
		_content_vbox.add_child(card)

	# Tips section
	_build_tips_section()

func _build_current_goal_section() -> void:
	var color: Color = GOAL_COLORS.get(_current_goal, Color.WHITE)
	var label: String = PracticeGoals.goal_label(_current_goal)

	var section := PanelContainer.new()

	var section_style := StyleBoxFlat.new()
	section_style.bg_color = color.darkened(0.8)
	section_style.border_color = color.darkened(0.4)
	section_style.set_border_width_all(2)
	section_style.set_corner_radius_all(6)
	section_style.set_content_margin_all(12)
	section.add_theme_stylebox_override("panel", section_style)

	_content_vbox.add_child(section)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	section.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	vbox.add_child(header)

	var current_label := Label.new()
	current_label.text = "CURRENT GOAL:"
	current_label.add_theme_font_size_override("font_size", 10)
	current_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	header.add_child(current_label)

	var goal_label := Label.new()
	goal_label.text = label
	goal_label.add_theme_font_size_override("font_size", 16)
	goal_label.add_theme_color_override("font_color", color)
	header.add_child(goal_label)

	# Show current thresholds
	var thresholds: Dictionary = PracticeGoals.thresholds(_current_goal)
	var threshold_row := HBoxContainer.new()
	threshold_row.add_theme_constant_override("separation", 15)
	vbox.add_child(threshold_row)

	_add_threshold_chip(threshold_row, "Hit Rate", "%.0f%%" % (float(thresholds.get("min_hit_rate", 0)) * 100), Color(0.9, 0.9, 0.4))
	_add_threshold_chip(threshold_row, "Accuracy", "%.0f%%" % (float(thresholds.get("min_accuracy", 0)) * 100), Color(0.4, 0.9, 0.4))
	_add_threshold_chip(threshold_row, "Max BS", "%.0f%%" % (float(thresholds.get("max_backspace_rate", 0)) * 100), Color(0.9, 0.5, 0.5))

func _add_threshold_chip(parent: HBoxContainer, name: String, value: String, color: Color) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	parent.add_child(vbox)

	var name_label := Label.new()
	name_label.text = name
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(name_label)

	var value_label := Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", 12)
	value_label.add_theme_color_override("font_color", color)
	vbox.add_child(value_label)

func _create_goal_card(goal_id: String) -> Control:
	var label: String = PracticeGoals.goal_label(goal_id)
	var description: String = PracticeGoals.goal_description(goal_id)
	var thresholds: Dictionary = PracticeGoals.thresholds(goal_id)
	var color: Color = GOAL_COLORS.get(goal_id, Color.WHITE)
	var is_current: bool = goal_id == _current_goal

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	if is_current:
		container_style.bg_color = color.darkened(0.75)
		container_style.border_color = color
		container_style.set_border_width_all(2)
	else:
		container_style.bg_color = color.darkened(0.9)
		container_style.border_color = color.darkened(0.6)
		container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", container_style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 6)
	container.add_child(main_vbox)

	# Header row
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	main_vbox.add_child(header)

	# Name
	var name_label := Label.new()
	name_label.text = label
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", color)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)

	# Current indicator
	if is_current:
		var current_badge := Label.new()
		current_badge.text = "ACTIVE"
		current_badge.add_theme_font_size_override("font_size", 10)
		current_badge.add_theme_color_override("font_color", color)
		header.add_child(current_badge)
	else:
		# Select button
		var select_btn := Button.new()
		select_btn.text = "Select"
		select_btn.custom_minimum_size = Vector2(60, 24)
		select_btn.pressed.connect(_on_goal_selected.bind(goal_id))
		header.add_child(select_btn)

	# Description
	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_vbox.add_child(desc_label)

	# Thresholds row
	var thresholds_row := HBoxContainer.new()
	thresholds_row.add_theme_constant_override("separation", 12)
	main_vbox.add_child(thresholds_row)

	var hit_rate: float = float(thresholds.get("min_hit_rate", 0)) * 100
	var accuracy: float = float(thresholds.get("min_accuracy", 0)) * 100
	var backspace: float = float(thresholds.get("max_backspace_rate", 0)) * 100
	var incomplete: float = float(thresholds.get("max_incomplete_rate", 0)) * 100

	var hit_chip := _create_stat_chip("Hit: %.0f%%" % hit_rate, Color(0.9, 0.9, 0.4))
	thresholds_row.add_child(hit_chip)

	var acc_chip := _create_stat_chip("Acc: %.0f%%" % accuracy, Color(0.4, 0.9, 0.4))
	thresholds_row.add_child(acc_chip)

	var bs_chip := _create_stat_chip("BS: <%.0f%%" % backspace, Color(0.9, 0.5, 0.5))
	thresholds_row.add_child(bs_chip)

	var inc_chip := _create_stat_chip("Inc: <%.0f%%" % incomplete, Color(0.7, 0.5, 0.9))
	thresholds_row.add_child(inc_chip)

	return container

func _create_stat_chip(text: String, color: Color) -> Control:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", color)
	return label

func _build_tips_section() -> void:
	var section := PanelContainer.new()

	var section_style := StyleBoxFlat.new()
	section_style.bg_color = Color(0.12, 0.15, 0.18, 0.8)
	section_style.border_color = Color(0.3, 0.4, 0.5)
	section_style.set_border_width_all(1)
	section_style.set_corner_radius_all(6)
	section_style.set_content_margin_all(10)
	section.add_theme_stylebox_override("panel", section_style)

	_content_vbox.add_child(section)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	section.add_child(vbox)

	var header := Label.new()
	header.text = "UNDERSTANDING GOALS"
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
	vbox.add_child(header)

	var tips: Array[Dictionary] = [
		{"label": "Hit Rate", "desc": "% of enemy waves you successfully defeat"},
		{"label": "Accuracy", "desc": "% of words typed without errors"},
		{"label": "Backspace Rate", "desc": "% of keystrokes that are corrections"},
		{"label": "Incomplete Rate", "desc": "% of words abandoned mid-typing"}
	]

	for tip in tips:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vbox.add_child(row)

		var label := Label.new()
		label.text = tip.get("label", "")
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
		label.custom_minimum_size = Vector2(90, 0)
		row.add_child(label)

		var desc := Label.new()
		desc.text = tip.get("desc", "")
		desc.add_theme_font_size_override("font_size", 10)
		desc.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		row.add_child(desc)

func _on_goal_selected(goal_id: String) -> void:
	_current_goal = goal_id
	goal_selected.emit(goal_id)
	_build_content()

func _on_close_pressed() -> void:
	hide()
	closed.emit()

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
