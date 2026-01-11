class_name WaveSummaryPanel
extends PanelContainer
## Wave Summary Panel - Shows performance summary after each wave

signal continue_pressed
signal retry_pressed

const ThemeColors = preload("res://ui/theme_colors.gd")
const StoryManager = preload("res://game/story_manager.gd")

var _stats: Dictionary = {}

# UI elements
var _title_label: Label = null
var _grade_label: Label = null
var _stats_container: VBoxContainer = null
var _tip_label: RichTextLabel = null
var _continue_btn: Button = null
var _retry_btn: Button = null


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(400, 350)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Header with title and grade
	var header := HBoxContainer.new()
	vbox.add_child(header)

	_title_label = Label.new()
	_title_label.text = "Wave Complete!"
	_title_label.add_theme_font_size_override("font_size", 22)
	_title_label.add_theme_color_override("font_color", ThemeColors.ACCENT)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)

	_grade_label = Label.new()
	_grade_label.add_theme_font_size_override("font_size", 32)
	_grade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_grade_label)

	# Separator
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Stats container
	_stats_container = VBoxContainer.new()
	_stats_container.add_theme_constant_override("separation", 6)
	_stats_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_stats_container)

	# Separator
	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	# Tip
	_tip_label = RichTextLabel.new()
	_tip_label.bbcode_enabled = true
	_tip_label.fit_content = true
	_tip_label.scroll_active = false
	_tip_label.custom_minimum_size = Vector2(0, 50)
	vbox.add_child(_tip_label)

	# Buttons
	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 10)
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(button_row)

	_continue_btn = Button.new()
	_continue_btn.text = "Continue (Space)"
	_continue_btn.custom_minimum_size = Vector2(140, 36)
	_continue_btn.pressed.connect(_on_continue_pressed)
	button_row.add_child(_continue_btn)

	_retry_btn = Button.new()
	_retry_btn.text = "Retry Wave"
	_retry_btn.custom_minimum_size = Vector2(120, 36)
	_retry_btn.pressed.connect(_on_retry_pressed)
	_retry_btn.visible = false  # Hidden by default
	button_row.add_child(_retry_btn)


func show_summary(stats: Dictionary) -> void:
	_stats = stats
	_refresh_display()
	show()
	_continue_btn.grab_focus()


func hide_summary() -> void:
	hide()


func _refresh_display() -> void:
	_clear_stats()

	var wave: int = int(_stats.get("wave", 1))
	var day: int = int(_stats.get("day", 1))
	var won: bool = bool(_stats.get("won", true))

	# Title
	if won:
		_title_label.text = "Wave %d Complete!" % wave
		_title_label.add_theme_color_override("font_color", ThemeColors.ACCENT)
	else:
		_title_label.text = "Wave %d Failed" % wave
		_title_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

	# Calculate grade
	var grade: String = _calculate_grade()
	var grade_color: Color = _get_grade_color(grade)
	_grade_label.text = grade
	_grade_label.add_theme_color_override("font_color", grade_color)

	# Stats display
	_add_stat_row("Words Typed", str(int(_stats.get("words_typed", 0))))
	_add_stat_row("Accuracy", "%.1f%%" % (float(_stats.get("accuracy", 0.0)) * 100.0))
	_add_stat_row("WPM", str(int(_stats.get("wpm", 0))))
	_add_stat_row("Best Combo", str(int(_stats.get("best_combo", 0))))
	_add_stat_row("Enemies Defeated", str(int(_stats.get("kills", 0))))
	_add_stat_row("Gold Earned", "+%d" % int(_stats.get("gold_earned", 0)), Color(1.0, 0.84, 0.0))

	# Time
	var time_seconds: float = float(_stats.get("time", 0.0))
	var time_str: String = "%d:%02d" % [int(time_seconds) / 60, int(time_seconds) % 60]
	_add_stat_row("Time", time_str)

	# Damage taken (if any)
	var damage: int = int(_stats.get("damage_taken", 0))
	if damage > 0:
		_add_stat_row("Damage Taken", str(damage), Color(1.0, 0.4, 0.4))

	# New records (if any)
	var new_record_combo: bool = bool(_stats.get("new_record_combo", false))
	var new_record_wpm: bool = bool(_stats.get("new_record_wpm", false))
	if new_record_combo or new_record_wpm:
		_add_spacer()
		if new_record_wpm:
			_add_stat_row("NEW RECORD!", "WPM", Color(1.0, 0.84, 0.0))
		if new_record_combo:
			_add_stat_row("NEW RECORD!", "Combo", Color(1.0, 0.84, 0.0))

	# Contextual tip based on performance
	var tip: String = _get_contextual_tip()
	if not tip.is_empty():
		_tip_label.text = "[color=gray]Tip: %s[/color]" % tip
	else:
		_tip_label.text = ""

	# Show retry button only if failed
	_retry_btn.visible = not won


func _clear_stats() -> void:
	for child in _stats_container.get_children():
		child.queue_free()


func _add_stat_row(label: String, value: String, value_color: Color = Color.WHITE) -> void:
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

	_stats_container.add_child(row)


func _add_spacer() -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	_stats_container.add_child(spacer)


func _calculate_grade() -> String:
	var accuracy: float = float(_stats.get("accuracy", 0.0))
	var wpm: float = float(_stats.get("wpm", 0.0))
	var combo: int = int(_stats.get("best_combo", 0))
	var damage_taken: int = int(_stats.get("damage_taken", 0))
	var won: bool = bool(_stats.get("won", true))

	if not won:
		return "F"

	# Calculate score (0-100 scale)
	var score: float = 0.0

	# Accuracy (40 points max)
	score += minf(accuracy * 40.0, 40.0)

	# WPM (30 points max) - scale from 0-60 WPM
	score += minf((wpm / 60.0) * 30.0, 30.0)

	# Combo (20 points max) - scale from 0-20 combo
	score += minf((float(combo) / 20.0) * 20.0, 20.0)

	# No damage bonus (10 points)
	if damage_taken == 0:
		score += 10.0

	# Grade thresholds
	if score >= 95:
		return "S"
	elif score >= 85:
		return "A"
	elif score >= 75:
		return "B"
	elif score >= 60:
		return "C"
	elif score >= 45:
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


func _get_contextual_tip() -> String:
	var accuracy: float = float(_stats.get("accuracy", 0.0))
	var wpm: float = float(_stats.get("wpm", 0.0))
	var combo: int = int(_stats.get("best_combo", 0))

	var context: String = ""

	# Determine what needs improvement
	if accuracy < 0.7:
		context = "error"
	elif accuracy < 0.85:
		context = "accuracy"
	elif wpm < 20:
		context = "slow"
	elif combo < 5:
		context = "rhythm"
	else:
		context = "advanced"

	return StoryManager.get_contextual_tip(context)


func _on_continue_pressed() -> void:
	hide_summary()
	continue_pressed.emit()


func _on_retry_pressed() -> void:
	hide_summary()
	retry_pressed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		_on_continue_pressed()
		get_viewport().set_input_as_handled()
