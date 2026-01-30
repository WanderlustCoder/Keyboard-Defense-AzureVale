class_name LessonPracticePanel
extends PanelContainer
## Lesson Practice Panel - Select and practice any lesson.
## Shows graduation paths, lesson health, and mastery stats.

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")
const DesignSystem = preload("res://ui/design_system.gd")
const SimLessons = preload("res://sim/lessons.gd")
const LessonHealth = preload("res://game/lesson_health.gd")

# Path definitions
const PATHS: Array[Dictionary] = [
	{"id": "beginner", "name": "Beginner", "color": Color(0.4, 0.8, 0.4)},
	{"id": "intermediate", "name": "Intermediate", "color": Color(0.5, 0.7, 0.9)},
	{"id": "advanced", "name": "Advanced", "color": Color(0.8, 0.5, 0.9)},
	{"id": "coding", "name": "Programmer", "color": Color(1.0, 0.7, 0.3)}
]

const DIFFICULTY_OPTIONS: Array[Dictionary] = [
	{"id": "easy", "label": "Easy", "words": 5},
	{"id": "normal", "label": "Normal", "words": 8},
	{"id": "hard", "label": "Hard", "words": 12}
]

# UI elements
var _close_btn: Button = null
var _path_tabs: HBoxContainer = null
var _lesson_scroll: ScrollContainer = null
var _lesson_list: VBoxContainer = null
var _detail_panel: PanelContainer = null
var _detail_name: Label = null
var _detail_desc: Label = null
var _detail_stats: Label = null
var _detail_health: Label = null
var _difficulty_select: OptionButton = null
var _practice_btn: Button = null

var _current_path: String = "beginner"
var _selected_lesson_id: String = ""
var _progression: Node = null
var _game_controller: Node = null
var _lessons_data: Dictionary = {}
var _path_buttons: Dictionary = {}


func _ready() -> void:
	_progression = get_node_or_null("/root/ProgressionState")
	_game_controller = get_node_or_null("/root/GameController")
	_lessons_data = SimLessons.load_data()
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(700, 550)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "PRACTICE LESSONS"
	DesignSystem.style_label(title, "h2", Color(0.5, 0.8, 0.9))
	header.add_child(title)

	header.add_child(DesignSystem.create_spacer())

	_close_btn = Button.new()
	_close_btn.text = "X"
	_close_btn.custom_minimum_size = Vector2(32, 32)
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Path tabs
	_path_tabs = DesignSystem.create_hbox(DesignSystem.SPACE_SM)
	main_vbox.add_child(_path_tabs)

	for path in PATHS:
		var btn := Button.new()
		btn.text = path["name"]
		btn.custom_minimum_size = Vector2(100, 32)
		btn.pressed.connect(_on_path_selected.bind(path["id"]))
		_path_tabs.add_child(btn)
		_path_buttons[path["id"]] = btn

	# Content area (split: lesson list | detail panel)
	var content_hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_hbox)

	# Lesson list (left side)
	_lesson_scroll = ScrollContainer.new()
	_lesson_scroll.custom_minimum_size = Vector2(280, 0)
	_lesson_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lesson_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lesson_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_hbox.add_child(_lesson_scroll)

	_lesson_list = DesignSystem.create_vbox(DesignSystem.SPACE_SM)
	_lesson_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lesson_scroll.add_child(_lesson_list)

	# Detail panel (right side)
	_detail_panel = PanelContainer.new()
	_detail_panel.custom_minimum_size = Vector2(320, 0)
	_detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var detail_style := StyleBoxFlat.new()
	detail_style.bg_color = ThemeColors.BG_CARD
	detail_style.set_corner_radius_all(4)
	detail_style.set_content_margin_all(12)
	_detail_panel.add_theme_stylebox_override("panel", detail_style)
	content_hbox.add_child(_detail_panel)

	var detail_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_SM)
	_detail_panel.add_child(detail_vbox)

	_detail_name = Label.new()
	_detail_name.text = "Select a Lesson"
	DesignSystem.style_label(_detail_name, "h3", ThemeColors.TEXT)
	detail_vbox.add_child(_detail_name)

	_detail_desc = Label.new()
	_detail_desc.text = "Choose a lesson from the list to see details."
	_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	DesignSystem.style_label(_detail_desc, "body", ThemeColors.TEXT_DIM)
	detail_vbox.add_child(_detail_desc)

	# Stats section
	var stats_sep := HSeparator.new()
	detail_vbox.add_child(stats_sep)

	_detail_stats = Label.new()
	_detail_stats.text = ""
	DesignSystem.style_label(_detail_stats, "body_small", ThemeColors.TEXT_DIM)
	detail_vbox.add_child(_detail_stats)

	_detail_health = Label.new()
	_detail_health.text = ""
	DesignSystem.style_label(_detail_health, "body", ThemeColors.SUCCESS)
	detail_vbox.add_child(_detail_health)

	# Spacer
	detail_vbox.add_child(DesignSystem.create_spacer())

	# Difficulty selector
	var diff_hbox := DesignSystem.create_hbox(DesignSystem.SPACE_SM)
	detail_vbox.add_child(diff_hbox)

	var diff_label := Label.new()
	diff_label.text = "Difficulty:"
	DesignSystem.style_label(diff_label, "body", ThemeColors.TEXT)
	diff_hbox.add_child(diff_label)

	_difficulty_select = OptionButton.new()
	for opt in DIFFICULTY_OPTIONS:
		_difficulty_select.add_item(opt["label"])
	_difficulty_select.selected = 1  # Default to Normal
	diff_hbox.add_child(_difficulty_select)

	# Practice button
	_practice_btn = Button.new()
	_practice_btn.text = "Start Practice"
	_practice_btn.custom_minimum_size = Vector2(0, 40)
	_practice_btn.disabled = true
	_practice_btn.pressed.connect(_on_practice_pressed)
	detail_vbox.add_child(_practice_btn)

	# Footer hint
	var footer := Label.new()
	footer.text = "Complete lessons to track mastery and health"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_panel() -> void:
	_refresh_path_tabs()
	_refresh_lesson_list()
	show()


func _refresh_path_tabs() -> void:
	for path_id in _path_buttons.keys():
		var btn: Button = _path_buttons[path_id]
		var is_selected: bool = path_id == _current_path
		if is_selected:
			btn.modulate = Color(1, 1, 1, 1)
		else:
			btn.modulate = Color(0.7, 0.7, 0.7, 1)


func _refresh_lesson_list() -> void:
	# Clear existing
	for child in _lesson_list.get_children():
		child.queue_free()

	# Get lessons for current path
	var path_lessons := _get_path_lessons(_current_path)

	if path_lessons.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No lessons found for this path."
		DesignSystem.style_label(empty_label, "body", ThemeColors.TEXT_DIM)
		_lesson_list.add_child(empty_label)
		return

	for lesson_id in path_lessons:
		var card := _create_lesson_card(lesson_id)
		_lesson_list.add_child(card)


func _get_path_lessons(path_id: String) -> Array:
	var result: Array = []
	var paths: Dictionary = _lessons_data.get("graduation_paths", {})
	var path_data: Dictionary = paths.get(path_id, {})
	var stages: Array = path_data.get("stages", [])

	for stage in stages:
		if stage is Dictionary:
			var stage_lessons: Array = stage.get("lessons", [])
			for lesson_id in stage_lessons:
				if lesson_id not in result:
					result.append(lesson_id)

	return result


func _create_lesson_card(lesson_id: String) -> Control:
	var lesson: Dictionary = SimLessons.get_lesson(lesson_id)
	var label_text: String = lesson.get("label", lesson_id)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 48)

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = ThemeColors.BG_BUTTON
	card_style.set_corner_radius_all(4)
	card_style.set_content_margin_all(8)
	card.add_theme_stylebox_override("panel", card_style)

	var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_SM)
	card.add_child(hbox)

	# Health indicator
	var health_label := _get_health_label(lesson_id)
	var health_indicator := Label.new()
	health_indicator.text = health_label
	health_indicator.custom_minimum_size = Vector2(50, 0)
	var health_color := _get_health_color(health_label)
	DesignSystem.style_label(health_indicator, "body_small", health_color)
	hbox.add_child(health_indicator)

	# Lesson name
	var name_label := Label.new()
	name_label.text = label_text
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	DesignSystem.style_label(name_label, "body", ThemeColors.TEXT)
	hbox.add_child(name_label)

	# Select button
	var select_btn := Button.new()
	select_btn.text = ">"
	select_btn.custom_minimum_size = Vector2(32, 32)
	select_btn.pressed.connect(_on_lesson_selected.bind(lesson_id))
	hbox.add_child(select_btn)

	return card


func _get_health_label(lesson_id: String) -> String:
	if _progression == null:
		return "--"
	var mastery: Dictionary = _progression.get_lesson_mastery(lesson_id)
	var attempts := int(mastery.get("attempt_count", 0))
	if attempts < 2:
		return "--"
	# Simple health based on attempts for now
	# In full implementation, would use recent performance data
	return "OK"


func _get_health_color(label: String) -> Color:
	match label:
		"GOOD":
			return Color(0.3, 0.9, 0.5)
		"OK":
			return Color(0.9, 0.8, 0.2)
		"WARN":
			return Color(0.9, 0.4, 0.3)
		_:
			return ThemeColors.TEXT_DIM


func _on_path_selected(path_id: String) -> void:
	_current_path = path_id
	_selected_lesson_id = ""
	_refresh_path_tabs()
	_refresh_lesson_list()
	_update_detail_panel()


func _on_lesson_selected(lesson_id: String) -> void:
	_selected_lesson_id = lesson_id
	_update_detail_panel()


func _update_detail_panel() -> void:
	if _selected_lesson_id == "":
		_detail_name.text = "Select a Lesson"
		_detail_desc.text = "Choose a lesson from the list to see details."
		_detail_stats.text = ""
		_detail_health.text = ""
		_practice_btn.disabled = true
		return

	var lesson: Dictionary = SimLessons.get_lesson(_selected_lesson_id)
	var label_text: String = lesson.get("label", _selected_lesson_id)
	var desc: String = lesson.get("description", "No description available.")
	var mode: String = lesson.get("mode", "charset")

	_detail_name.text = label_text
	_detail_desc.text = desc

	# Get mastery stats
	if _progression != null:
		var mastery: Dictionary = _progression.get_lesson_mastery(_selected_lesson_id)
		var best_acc := float(mastery.get("best_accuracy", 0.0)) * 100.0
		var best_wpm := float(mastery.get("best_wpm", 0.0))
		var attempts := int(mastery.get("attempt_count", 0))
		var completions := int(mastery.get("completion_count", 0))

		if attempts > 0:
			_detail_stats.text = "Best: %.0f%% acc, %.0f WPM\nAttempts: %d | Completions: %d" % [
				best_acc, best_wpm, attempts, completions
			]
		else:
			_detail_stats.text = "No attempts yet"

		var health_label := _get_health_label(_selected_lesson_id)
		_detail_health.text = "Health: %s" % health_label
		_detail_health.add_theme_color_override("font_color", _get_health_color(health_label))
	else:
		_detail_stats.text = "Stats unavailable"
		_detail_health.text = ""

	_practice_btn.disabled = false


func _on_practice_pressed() -> void:
	if _selected_lesson_id == "" or _game_controller == null:
		return

	var diff_idx := _difficulty_select.selected
	var difficulty: String = DIFFICULTY_OPTIONS[diff_idx]["id"]

	hide()
	closed.emit()
	_game_controller.go_to_practice(_selected_lesson_id, {"difficulty": difficulty})


func _on_close_pressed() -> void:
	hide()
	closed.emit()
