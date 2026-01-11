class_name RunSummaryPanel
extends PanelContainer
## Run Summary Panel - Shows comprehensive stats at end of a run

signal continue_pressed
signal new_run_pressed
signal main_menu_pressed

const ThemeColors = preload("res://ui/theme_colors.gd")

var _stats: Dictionary = {}
var _is_victory: bool = false

# UI elements
var _title_label: Label = null
var _subtitle_label: Label = null
var _grade_label: Label = null
var _left_stats: VBoxContainer = null
var _right_stats: VBoxContainer = null
var _achievements_container: VBoxContainer = null
var _continue_btn: Button = null
var _new_run_btn: Button = null
var _menu_btn: Button = null


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(600, 500)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Header
	var header := HBoxContainer.new()
	vbox.add_child(header)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 28)
	title_box.add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.add_theme_font_size_override("font_size", 14)
	_subtitle_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	title_box.add_child(_subtitle_label)

	_grade_label = Label.new()
	_grade_label.add_theme_font_size_override("font_size", 48)
	_grade_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_grade_label)

	# Separator
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Stats area - two columns
	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 30)
	stats_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(stats_row)

	# Left column - Combat stats
	var left_box := VBoxContainer.new()
	left_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_row.add_child(left_box)

	var left_header := Label.new()
	left_header.text = "COMBAT"
	left_header.add_theme_font_size_override("font_size", 14)
	left_header.add_theme_color_override("font_color", ThemeColors.ACCENT)
	left_box.add_child(left_header)

	_left_stats = VBoxContainer.new()
	_left_stats.add_theme_constant_override("separation", 4)
	left_box.add_child(_left_stats)

	# Right column - Typing stats
	var right_box := VBoxContainer.new()
	right_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_row.add_child(right_box)

	var right_header := Label.new()
	right_header.text = "TYPING"
	right_header.add_theme_font_size_override("font_size", 14)
	right_header.add_theme_color_override("font_color", ThemeColors.ACCENT)
	right_box.add_child(right_header)

	_right_stats = VBoxContainer.new()
	_right_stats.add_theme_constant_override("separation", 4)
	right_box.add_child(_right_stats)

	# Achievements section (if any unlocked)
	var ach_header := Label.new()
	ach_header.text = "ACHIEVEMENTS UNLOCKED"
	ach_header.add_theme_font_size_override("font_size", 14)
	ach_header.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	vbox.add_child(ach_header)

	_achievements_container = VBoxContainer.new()
	_achievements_container.add_theme_constant_override("separation", 4)
	vbox.add_child(_achievements_container)

	# Separator
	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	# Buttons
	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 12)
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(button_row)

	_new_run_btn = Button.new()
	_new_run_btn.text = "New Run"
	_new_run_btn.custom_minimum_size = Vector2(120, 40)
	_new_run_btn.pressed.connect(_on_new_run_pressed)
	button_row.add_child(_new_run_btn)

	_continue_btn = Button.new()
	_continue_btn.text = "Continue"
	_continue_btn.custom_minimum_size = Vector2(120, 40)
	_continue_btn.pressed.connect(_on_continue_pressed)
	button_row.add_child(_continue_btn)

	_menu_btn = Button.new()
	_menu_btn.text = "Main Menu"
	_menu_btn.custom_minimum_size = Vector2(120, 40)
	_menu_btn.pressed.connect(_on_menu_pressed)
	button_row.add_child(_menu_btn)


func show_summary(stats: Dictionary, victory: bool = false) -> void:
	_stats = stats
	_is_victory = victory
	_refresh_display()
	show()
	if victory:
		_continue_btn.grab_focus()
	else:
		_new_run_btn.grab_focus()


func hide_summary() -> void:
	hide()


func _refresh_display() -> void:
	_clear_stats()

	var day_reached: int = int(_stats.get("day_reached", 1))
	var waves_cleared: int = int(_stats.get("waves_cleared", 0))

	# Title and subtitle
	if _is_victory:
		_title_label.text = "VICTORY!"
		_title_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		_subtitle_label.text = "The kingdom is saved!"
		_continue_btn.visible = true
	else:
		_title_label.text = "DEFEAT"
		_title_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		_subtitle_label.text = "The castle has fallen on Day %d" % day_reached
		_continue_btn.visible = false

	# Grade
	var grade: String = _calculate_grade()
	var grade_color: Color = _get_grade_color(grade)
	_grade_label.text = grade
	_grade_label.add_theme_color_override("font_color", grade_color)

	# Left column - Combat stats
	_add_stat(_left_stats, "Day Reached", str(day_reached))
	_add_stat(_left_stats, "Waves Cleared", str(waves_cleared))
	_add_stat(_left_stats, "Enemies Defeated", str(int(_stats.get("total_kills", 0))))
	_add_stat(_left_stats, "Bosses Slain", str(int(_stats.get("boss_kills", 0))))
	_add_stat(_left_stats, "Damage Dealt", str(int(_stats.get("damage_dealt", 0))))
	_add_stat(_left_stats, "Damage Taken", str(int(_stats.get("damage_taken", 0))), Color(1.0, 0.5, 0.5) if int(_stats.get("damage_taken", 0)) > 0 else Color.WHITE)

	# Gold with color
	var total_gold: int = int(_stats.get("gold_earned", 0))
	_add_stat(_left_stats, "Gold Earned", str(total_gold), Color(1.0, 0.84, 0.0))

	# Right column - Typing stats
	_add_stat(_right_stats, "Words Typed", str(int(_stats.get("words_typed", 0))))
	_add_stat(_right_stats, "Best Accuracy", "%.1f%%" % (float(_stats.get("best_accuracy", 0)) * 100.0))
	_add_stat(_right_stats, "Average Accuracy", "%.1f%%" % (float(_stats.get("avg_accuracy", 0)) * 100.0))
	_add_stat(_right_stats, "Best WPM", str(int(_stats.get("best_wpm", 0))))
	_add_stat(_right_stats, "Best Combo", str(int(_stats.get("best_combo", 0))))

	# XP and level
	var xp_gained: int = int(_stats.get("xp_gained", 0))
	var levels_gained: int = int(_stats.get("levels_gained", 0))
	if xp_gained > 0:
		_add_stat(_right_stats, "XP Earned", "+%d" % xp_gained, Color(0.5, 1.0, 0.5))
	if levels_gained > 0:
		_add_stat(_right_stats, "Levels Gained", "+%d" % levels_gained, Color(0.5, 1.0, 0.5))

	# Time played
	var play_time: float = float(_stats.get("play_time", 0))
	var time_str: String = _format_time(play_time)
	_add_stat(_right_stats, "Time Played", time_str)

	# Achievements unlocked during this run
	var achievements: Array = _stats.get("achievements_unlocked", [])
	if achievements.is_empty():
		_achievements_container.get_parent().get_child(_achievements_container.get_index() - 1).visible = false
		_achievements_container.visible = false
	else:
		_achievements_container.get_parent().get_child(_achievements_container.get_index() - 1).visible = true
		_achievements_container.visible = true
		for ach_name in achievements:
			var ach_label := Label.new()
			ach_label.text = "  - " + str(ach_name)
			ach_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
			_achievements_container.add_child(ach_label)


func _clear_stats() -> void:
	for child in _left_stats.get_children():
		child.queue_free()
	for child in _right_stats.get_children():
		child.queue_free()
	for child in _achievements_container.get_children():
		child.queue_free()


func _add_stat(container: VBoxContainer, label: String, value: String, value_color: Color = Color.WHITE) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label_node := Label.new()
	label_node.text = label
	label_node.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	label_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label_node)

	var value_node := Label.new()
	value_node.text = value
	value_node.add_theme_color_override("font_color", value_color)
	value_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_node)

	container.add_child(row)


func _format_time(seconds: float) -> String:
	var total_seconds: int = int(seconds)
	var hours: int = total_seconds / 3600
	var minutes: int = (total_seconds % 3600) / 60
	var secs: int = total_seconds % 60

	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, secs]
	else:
		return "%d:%02d" % [minutes, secs]


func _calculate_grade() -> String:
	var day_reached: int = int(_stats.get("day_reached", 1))
	var best_accuracy: float = float(_stats.get("best_accuracy", 0))
	var best_wpm: float = float(_stats.get("best_wpm", 0))
	var best_combo: int = int(_stats.get("best_combo", 0))
	var boss_kills: int = int(_stats.get("boss_kills", 0))

	# Base score from day reached (up to 40 points for day 20)
	var score: float = minf(float(day_reached) * 2.0, 40.0)

	# Accuracy bonus (up to 20 points)
	score += best_accuracy * 20.0

	# WPM bonus (up to 20 points for 60+ WPM)
	score += minf((best_wpm / 60.0) * 20.0, 20.0)

	# Combo bonus (up to 10 points for 20+ combo)
	score += minf((float(best_combo) / 20.0) * 10.0, 10.0)

	# Boss kills bonus (up to 10 points for 4 bosses)
	score += minf(float(boss_kills) * 2.5, 10.0)

	# Victory bonus
	if _is_victory:
		score += 10.0

	# Grade thresholds
	if score >= 95:
		return "S"
	elif score >= 85:
		return "A"
	elif score >= 70:
		return "B"
	elif score >= 55:
		return "C"
	elif score >= 40:
		return "D"
	else:
		return "F"


func _get_grade_color(grade: String) -> Color:
	match grade:
		"S":
			return Color(1.0, 0.84, 0.0)  # Gold
		"A":
			return Color(0.4, 1.0, 0.4)   # Green
		"B":
			return Color(0.4, 0.8, 1.0)   # Blue
		"C":
			return Color(0.8, 0.8, 0.8)   # Gray
		"D":
			return Color(1.0, 0.6, 0.2)   # Orange
		_:
			return Color(1.0, 0.4, 0.4)   # Red


func _on_continue_pressed() -> void:
	hide_summary()
	continue_pressed.emit()


func _on_new_run_pressed() -> void:
	hide_summary()
	new_run_pressed.emit()


func _on_menu_pressed() -> void:
	hide_summary()
	main_menu_pressed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_menu_pressed()
		get_viewport().set_input_as_handled()
