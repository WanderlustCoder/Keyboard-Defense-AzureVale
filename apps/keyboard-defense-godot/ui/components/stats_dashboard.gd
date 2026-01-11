class_name StatsDashboard
extends PanelContainer
## Statistics Dashboard - Comprehensive view of player progress and stats

signal close_requested

const ThemeColors = preload("res://ui/theme_colors.gd")
const SimPlayerStats = preload("res://sim/player_stats.gd")
const TypingProfile = preload("res://game/typing_profile.gd")

enum Tab { OVERVIEW, TYPING, COMBAT, PROGRESSION, RECORDS }

var _current_tab: Tab = Tab.OVERVIEW
var _profile: Dictionary = {}

# UI elements
var _title_label: Label = null
var _close_btn: Button = null
var _tab_bar: HBoxContainer = null
var _content_scroll: ScrollContainer = null
var _content_container: VBoxContainer = null
var _tab_buttons: Array[Button] = []


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(650, 500)

	var style := StyleBoxFlat.new()
	style.bg_color = ThemeColors.BG_PANEL
	style.border_color = ThemeColors.ACCENT
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Header
	var header := HBoxContainer.new()
	vbox.add_child(header)

	_title_label = Label.new()
	_title_label.text = "Statistics"
	_title_label.add_theme_font_size_override("font_size", 22)
	_title_label.add_theme_color_override("font_color", ThemeColors.ACCENT)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)

	_close_btn = Button.new()
	_close_btn.text = "X"
	_close_btn.custom_minimum_size = Vector2(32, 32)
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Tab bar
	_tab_bar = HBoxContainer.new()
	_tab_bar.add_theme_constant_override("separation", 4)
	vbox.add_child(_tab_bar)

	var tab_names: Array[String] = ["Overview", "Typing", "Combat", "Progress", "Records"]
	for i in range(tab_names.size()):
		var btn := Button.new()
		btn.text = tab_names[i]
		btn.toggle_mode = true
		btn.button_pressed = (i == 0)
		btn.pressed.connect(_on_tab_pressed.bind(i))
		_tab_bar.add_child(btn)
		_tab_buttons.append(btn)

	# Separator
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Content area with scroll
	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(_content_scroll)

	_content_container = VBoxContainer.new()
	_content_container.add_theme_constant_override("separation", 8)
	_content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_container)

	# Footer hint
	var hint := Label.new()
	hint.text = "Press ESC to close. Use arrow keys to switch tabs."
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)


func show_stats(profile: Dictionary) -> void:
	_profile = profile
	_refresh_content()
	show()


func hide_stats() -> void:
	hide()
	close_requested.emit()


func _on_tab_pressed(tab_index: int) -> void:
	_current_tab = tab_index as Tab
	for i in range(_tab_buttons.size()):
		_tab_buttons[i].button_pressed = (i == tab_index)
	_refresh_content()


func _refresh_content() -> void:
	# Clear existing content
	for child in _content_container.get_children():
		child.queue_free()

	match _current_tab:
		Tab.OVERVIEW:
			_build_overview()
		Tab.TYPING:
			_build_typing_stats()
		Tab.COMBAT:
			_build_combat_stats()
		Tab.PROGRESSION:
			_build_progression_stats()
		Tab.RECORDS:
			_build_records()


func _build_overview() -> void:
	var stats: Dictionary = SimPlayerStats.get_stats(_profile)
	var derived: Dictionary = SimPlayerStats.calculate_derived_stats(_profile)

	# Player level and XP
	var level: int = TypingProfile.get_level(_profile)
	var xp: int = TypingProfile.get_xp(_profile)
	var xp_for_next: int = TypingProfile.xp_for_level(level + 1)
	_add_section_header("Player Level")
	_add_stat_row("Level", str(level), Color(1.0, 0.84, 0.0))
	_add_stat_row("Experience", "%d / %d" % [xp, xp_for_next])
	_add_progress_bar(float(xp) / float(xp_for_next) if xp_for_next > 0 else 0.0, Color(0.4, 0.8, 1.0))

	# Daily streak
	var streak: int = TypingProfile.get_daily_streak(_profile)
	var best_streak: int = TypingProfile.get_best_streak(_profile)
	_add_spacer()
	_add_section_header("Daily Streak")
	_add_stat_row("Current Streak", "%d days" % streak, Color(1.0, 0.84, 0.0) if streak >= 7 else Color.WHITE)
	_add_stat_row("Best Streak", "%d days" % best_streak)

	# Quick stats summary
	_add_spacer()
	_add_section_header("Quick Summary")
	_add_stat_row("Total Play Time", _format_time(int(stats.get("total_play_time", 0)) * 60))
	_add_stat_row("Sessions Played", str(int(stats.get("sessions_played", 0))))
	_add_stat_row("Words Typed", _format_number(int(stats.get("total_words_typed", 0))))
	_add_stat_row("Enemies Defeated", _format_number(int(stats.get("total_kills", 0))))
	_add_stat_row("Gold Earned", _format_number(int(stats.get("total_gold_earned", 0))), Color(1.0, 0.84, 0.0))

	# Accuracy
	var overall_accuracy: float = float(derived.get("overall_accuracy", 0))
	_add_spacer()
	_add_section_header("Overall Performance")
	_add_stat_row("Overall Accuracy", "%.1f%%" % overall_accuracy, _get_accuracy_color(overall_accuracy / 100.0))
	_add_stat_row("Highest WPM", str(int(stats.get("highest_wpm", 0))))
	_add_stat_row("Highest Combo", str(int(stats.get("highest_combo", 0))))


func _build_typing_stats() -> void:
	var stats: Dictionary = SimPlayerStats.get_stats(_profile)
	var derived: Dictionary = SimPlayerStats.calculate_derived_stats(_profile)

	_add_section_header("Typing Volume")
	_add_stat_row("Total Words", _format_number(int(stats.get("total_words_typed", 0))))
	_add_stat_row("Total Characters", _format_number(int(stats.get("total_chars_typed", 0))))
	_add_stat_row("Perfect Words", _format_number(int(stats.get("perfect_words", 0))))

	_add_spacer()
	_add_section_header("Accuracy")
	var typos: int = int(stats.get("total_typos", 0))
	var overall_accuracy: float = float(derived.get("overall_accuracy", 0))
	_add_stat_row("Overall Accuracy", "%.1f%%" % overall_accuracy, _get_accuracy_color(overall_accuracy / 100.0))
	_add_stat_row("Total Typos", _format_number(typos), Color(1.0, 0.5, 0.5) if typos > 100 else Color.WHITE)
	_add_stat_row("Best Accuracy", "%d%%" % int(stats.get("highest_accuracy", 0)), Color(0.4, 1.0, 0.4))

	_add_spacer()
	_add_section_header("Speed")
	_add_stat_row("Highest WPM", str(int(stats.get("highest_wpm", 0))), Color(0.4, 0.8, 1.0))

	_add_spacer()
	_add_section_header("Combos")
	_add_stat_row("Highest Combo", str(int(stats.get("highest_combo", 0))), Color(1.0, 0.6, 0.2))
	_add_stat_row("Combos Started", _format_number(int(stats.get("total_combos_started", 0))))
	_add_stat_row("Combos Broken", _format_number(int(stats.get("total_combos_broken", 0))))
	_add_stat_row("Words in Combos", _format_number(int(stats.get("combo_words_typed", 0))))


func _build_combat_stats() -> void:
	var stats: Dictionary = SimPlayerStats.get_stats(_profile)

	_add_section_header("Enemies")
	_add_stat_row("Total Kills", _format_number(int(stats.get("total_kills", 0))), Color(1.0, 0.4, 0.4))
	_add_stat_row("Boss Kills", str(int(stats.get("total_boss_kills", 0))), Color(0.8, 0.4, 1.0))
	_add_stat_row("Most Kills (Wave)", str(int(stats.get("most_kills_wave", 0))))

	_add_spacer()
	_add_section_header("Damage")
	_add_stat_row("Damage Dealt", _format_number(int(stats.get("total_damage_dealt", 0))))
	_add_stat_row("Damage Taken", _format_number(int(stats.get("total_damage_taken", 0))), Color(1.0, 0.5, 0.5))
	_add_stat_row("Deaths", str(int(stats.get("total_deaths", 0))))

	_add_spacer()
	_add_section_header("Economy")
	_add_stat_row("Gold Earned", _format_number(int(stats.get("total_gold_earned", 0))), Color(1.0, 0.84, 0.0))
	_add_stat_row("Gold Spent", _format_number(int(stats.get("total_gold_spent", 0))))
	_add_stat_row("Most Gold (Wave)", str(int(stats.get("most_gold_wave", 0))), Color(1.0, 0.84, 0.0))
	_add_stat_row("Items Purchased", str(int(stats.get("items_purchased", 0))))


func _build_progression_stats() -> void:
	var stats: Dictionary = SimPlayerStats.get_stats(_profile)

	_add_section_header("Campaign Progress")
	_add_stat_row("Highest Day", str(int(stats.get("highest_day", 0))))
	_add_stat_row("Days Survived", _format_number(int(stats.get("days_survived", 0))))
	_add_stat_row("Waves Completed", _format_number(int(stats.get("waves_completed", 0))))

	_add_spacer()
	_add_section_header("Achievements")
	var achievements_count: int = int(stats.get("achievements_unlocked", 0))
	_add_stat_row("Achievements", str(achievements_count), Color(1.0, 0.84, 0.0) if achievements_count > 10 else Color.WHITE)
	_add_stat_row("Quests Completed", str(int(stats.get("quests_completed", 0))))
	_add_stat_row("Challenges Completed", str(int(stats.get("challenges_completed", 0))))

	_add_spacer()
	_add_section_header("Endless Mode")
	var endless_day: int = int(stats.get("endless_highest_day", 0))
	if endless_day > 0:
		_add_stat_row("Highest Day", str(endless_day), Color(0.8, 0.4, 1.0))
	else:
		_add_stat_row("Highest Day", "Not played yet", ThemeColors.TEXT_DIM)

	_add_spacer()
	_add_section_header("Time Played")
	_add_stat_row("Total Time", _format_time(int(stats.get("total_play_time", 0)) * 60))
	_add_stat_row("Sessions", str(int(stats.get("sessions_played", 0))))

	# Account age
	var first_played: int = int(stats.get("first_played", 0))
	if first_played > 0:
		var days_since: int = (int(Time.get_unix_time_from_system()) - first_played) / 86400
		_add_stat_row("Account Age", "%d days" % days_since)


func _build_records() -> void:
	var stats: Dictionary = SimPlayerStats.get_stats(_profile)

	_add_section_header("Personal Records")

	# Typing records
	_add_stat_row("Highest WPM", str(int(stats.get("highest_wpm", 0))), Color(0.4, 0.8, 1.0))
	_add_stat_row("Best Accuracy", "%d%%" % int(stats.get("highest_accuracy", 0)), Color(0.4, 1.0, 0.4))
	_add_stat_row("Longest Combo", str(int(stats.get("highest_combo", 0))), Color(1.0, 0.6, 0.2))

	_add_spacer()
	_add_section_header("Combat Records")
	_add_stat_row("Highest Day", str(int(stats.get("highest_day", 0))))
	_add_stat_row("Most Kills (Wave)", str(int(stats.get("most_kills_wave", 0))))
	_add_stat_row("Most Gold (Wave)", str(int(stats.get("most_gold_wave", 0))), Color(1.0, 0.84, 0.0))

	# Fastest wave
	var fastest: int = int(stats.get("fastest_wave_time", 999999))
	if fastest < 999999:
		_add_stat_row("Fastest Wave", "%.1f sec" % fastest, Color(0.4, 0.8, 1.0))
	else:
		_add_stat_row("Fastest Wave", "N/A", ThemeColors.TEXT_DIM)

	_add_spacer()
	_add_section_header("Streak Records")
	var best_streak: int = TypingProfile.get_best_streak(_profile)
	_add_stat_row("Best Daily Streak", "%d days" % best_streak, Color(1.0, 0.84, 0.0) if best_streak >= 7 else Color.WHITE)

	_add_spacer()
	_add_section_header("Endless Mode")
	var endless_day: int = int(stats.get("endless_highest_day", 0))
	if endless_day > 0:
		_add_stat_row("Highest Day", str(endless_day), Color(0.8, 0.4, 1.0))
	else:
		_add_stat_row("Highest Day", "Not attempted", ThemeColors.TEXT_DIM)


# UI helper functions

func _add_section_header(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", ThemeColors.ACCENT)
	_content_container.add_child(label)


func _add_stat_row(label_text: String, value_text: String, value_color: Color = Color.WHITE) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.add_theme_color_override("font_color", value_color)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)

	_content_container.add_child(row)


func _add_progress_bar(progress: float, color: Color = Color.WHITE) -> void:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 8)
	bar.value = progress * 100.0
	bar.show_percentage = false

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = color
	fill_style.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.2, 0.25)
	bg_style.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg_style)

	_content_container.add_child(bar)


func _add_spacer() -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	_content_container.add_child(spacer)


func _format_number(num: int) -> String:
	if num >= 1000000:
		return "%.1fM" % (float(num) / 1000000.0)
	elif num >= 1000:
		return "%.1fK" % (float(num) / 1000.0)
	else:
		return str(num)


func _format_time(seconds: int) -> String:
	if seconds < 60:
		return "%d sec" % seconds
	elif seconds < 3600:
		return "%d min" % (seconds / 60)
	else:
		var hours: int = seconds / 3600
		var mins: int = (seconds % 3600) / 60
		return "%dh %dm" % [hours, mins]


func _get_accuracy_color(accuracy: float) -> Color:
	if accuracy >= 0.98:
		return Color(1.0, 0.84, 0.0)  # Gold
	elif accuracy >= 0.95:
		return Color(0.4, 1.0, 0.4)  # Green
	elif accuracy >= 0.85:
		return Color(0.4, 0.8, 1.0)  # Blue
	elif accuracy >= 0.70:
		return Color(1.0, 1.0, 1.0)  # White
	else:
		return Color(1.0, 0.5, 0.5)  # Red


func _on_close_pressed() -> void:
	hide_stats()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		hide_stats()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		var new_tab: int = int(_current_tab) - 1
		if new_tab < 0:
			new_tab = Tab.RECORDS
		_on_tab_pressed(new_tab)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		var new_tab: int = int(_current_tab) + 1
		if new_tab > Tab.RECORDS:
			new_tab = Tab.OVERVIEW
		_on_tab_pressed(new_tab)
		get_viewport().set_input_as_handled()
