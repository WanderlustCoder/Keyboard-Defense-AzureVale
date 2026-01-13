class_name StatsPanel
extends PanelContainer
## Stats Panel - Displays comprehensive player statistics.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

const SimPlayerStats = preload("res://sim/player_stats.gd")

var _profile: Dictionary = {}
var _current_tab: String = "overview"

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null
var _tab_container: HBoxContainer = null
var _tab_buttons: Dictionary = {}

# Tab colors
const TAB_COLORS: Dictionary = {
	"overview": Color(1.0, 0.84, 0.0),
	"combat": Color(0.9, 0.3, 0.3),
	"typing": Color(0.4, 0.8, 1.0),
	"economy": Color(1.0, 0.8, 0.4),
	"progression": Color(0.4, 0.9, 0.4),
	"records": Color(0.9, 0.4, 0.9)
}

func _ready() -> void:
	_build_ui()
	hide()

func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 500)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "PLAYER STATISTICS"
	DesignSystem.style_label(title, "h2", ThemeColors.ACCENT)
	header.add_child(title)

	header.add_child(DesignSystem.create_spacer())

	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.custom_minimum_size = Vector2(DesignSystem.SIZE_BUTTON_SM, DesignSystem.SIZE_BUTTON_SM)
	_style_close_button()
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Tab buttons
	_tab_container = DesignSystem.create_hbox(DesignSystem.SPACE_XS)
	main_vbox.add_child(_tab_container)

	var tabs: Array[Dictionary] = [
		{"id": "overview", "label": "Overview"},
		{"id": "combat", "label": "Combat"},
		{"id": "typing", "label": "Typing"},
		{"id": "economy", "label": "Economy"},
		{"id": "progression", "label": "Progression"},
		{"id": "records", "label": "Records"}
	]

	for tab in tabs:
		var btn := Button.new()
		btn.text = str(tab.get("label", ""))
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(80, 26)
		btn.pressed.connect(_on_tab_selected.bind(str(tab.get("id", ""))))
		_tab_container.add_child(btn)
		_tab_buttons[str(tab.get("id", ""))] = btn

	# Content scroll
	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_content_scroll)

	_content_vbox = DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_vbox)

	# Footer hint
	var footer := Label.new()
	footer.text = "Stats update after each battle!"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)

func show_stats(profile: Dictionary, tab: String = "overview") -> void:
	_profile = profile
	_current_tab = tab if not tab.is_empty() else "overview"
	_update_tabs()
	_build_content()
	show()

func _update_tabs() -> void:
	for tab_id in _tab_buttons.keys():
		var btn: Button = _tab_buttons[tab_id]
		btn.button_pressed = tab_id == _current_tab

func _on_tab_selected(tab_id: String) -> void:
	_current_tab = tab_id
	_update_tabs()
	_build_content()

func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()

func _build_content() -> void:
	_clear_content()

	match _current_tab:
		"overview":
			_build_overview()
		"combat":
			_build_category_stats("combat")
		"typing":
			_build_typing_stats()
		"economy":
			_build_category_stats("economy")
		"progression":
			_build_category_stats("progression")
		"records":
			_build_records()

func _build_overview() -> void:
	var stats: Dictionary = SimPlayerStats.get_stats(_profile)
	var derived: Dictionary = SimPlayerStats.calculate_derived_stats(_profile)

	# Quick summary card
	var summary_panel := _create_section_panel("QUICK SUMMARY", TAB_COLORS["overview"])
	_content_vbox.add_child(summary_panel)

	var summary_grid := _create_stat_grid()
	summary_panel.get_child(0).add_child(summary_grid)

	_add_stat_row(summary_grid, "Total Kills", _format_number(int(stats.get("total_kills", 0))), Color(0.9, 0.3, 0.3))
	_add_stat_row(summary_grid, "Words Typed", _format_number(int(stats.get("total_words_typed", 0))), Color(0.4, 0.8, 1.0))
	_add_stat_row(summary_grid, "Gold Earned", _format_number(int(stats.get("total_gold_earned", 0))), Color(1.0, 0.84, 0.0))
	_add_stat_row(summary_grid, "Days Survived", _format_number(int(stats.get("days_survived", 0))), Color(0.4, 0.9, 0.4))

	# Performance card
	var perf_panel := _create_section_panel("PERFORMANCE", Color(0.4, 0.8, 1.0))
	_content_vbox.add_child(perf_panel)

	var perf_grid := _create_stat_grid()
	perf_panel.get_child(0).add_child(perf_grid)

	_add_stat_row(perf_grid, "Overall Accuracy", "%.1f%%" % float(derived.get("overall_accuracy", 0)), Color(0.4, 0.9, 0.4))
	_add_stat_row(perf_grid, "K/D Ratio", "%.2f" % float(derived.get("kd_ratio", 0)), Color(0.9, 0.3, 0.3))
	_add_stat_row(perf_grid, "Combo Efficiency", "%.1f%%" % float(derived.get("combo_efficiency", 0)), Color(0.9, 0.4, 0.9))
	_add_stat_row(perf_grid, "Avg Kills/Wave", "%.1f" % float(derived.get("avg_kills_per_wave", 0)), Color(0.9, 0.6, 0.3))

	# Top records card
	var records_panel := _create_section_panel("TOP RECORDS", Color(0.9, 0.4, 0.9))
	_content_vbox.add_child(records_panel)

	var records_grid := _create_stat_grid()
	records_panel.get_child(0).add_child(records_grid)

	_add_stat_row(records_grid, "Highest Combo", str(int(stats.get("highest_combo", 0))), Color(0.9, 0.4, 0.9))
	_add_stat_row(records_grid, "Highest Day", str(int(stats.get("highest_day", 0))), Color(0.4, 0.9, 0.4))
	_add_stat_row(records_grid, "Highest WPM", str(int(stats.get("highest_wpm", 0))), Color(0.4, 0.8, 1.0))
	_add_stat_row(records_grid, "Best Accuracy", "%.1f%%" % float(stats.get("highest_accuracy", 0)), Color(0.4, 0.9, 0.4))

	# Time played
	var time_panel := _create_section_panel("TIME PLAYED", Color(0.6, 0.6, 0.7))
	_content_vbox.add_child(time_panel)

	var time_grid := _create_stat_grid()
	time_panel.get_child(0).add_child(time_grid)

	var minutes: int = int(stats.get("total_play_time", 0))
	var hours: float = float(minutes) / 60.0
	var sessions: int = int(stats.get("sessions_played", 0))

	_add_stat_row(time_grid, "Total Play Time", "%.1f hours" % hours, Color(0.6, 0.6, 0.7))
	_add_stat_row(time_grid, "Sessions Played", str(sessions), Color(0.6, 0.6, 0.7))

func _build_category_stats(category: String) -> void:
	var stats: Dictionary = SimPlayerStats.get_stats(_profile)
	var color: Color = TAB_COLORS.get(category, Color.WHITE)
	var title: String = category.to_upper() + " STATISTICS"

	var panel := _create_section_panel(title, color)
	_content_vbox.add_child(panel)

	var grid := _create_stat_grid()
	panel.get_child(0).add_child(grid)

	for stat_key in SimPlayerStats.STATS.keys():
		var stat_info: Dictionary = SimPlayerStats.STATS[stat_key]
		if str(stat_info.get("category", "")) == category:
			var name: String = str(stat_info.get("name", stat_key))
			var value: int = int(stats.get(stat_key, 0))
			_add_stat_row(grid, name, _format_number(value), color)

	# Add derived stats for specific categories
	var derived: Dictionary = SimPlayerStats.calculate_derived_stats(_profile)

	if category == "economy":
		var sep := _create_separator()
		panel.get_child(0).add_child(sep)

		var derived_label := Label.new()
		derived_label.text = "AVERAGES"
		derived_label.add_theme_font_size_override("font_size", 12)
		derived_label.add_theme_color_override("font_color", color.darkened(0.2))
		panel.get_child(0).add_child(derived_label)

		var derived_grid := _create_stat_grid()
		panel.get_child(0).add_child(derived_grid)

		_add_stat_row(derived_grid, "Avg Gold/Wave", "%.1f" % float(derived.get("avg_gold_per_wave", 0)), color)
		_add_stat_row(derived_grid, "Avg Words/Session", "%.1f" % float(derived.get("avg_words_per_session", 0)), color)

func _build_typing_stats() -> void:
	var stats: Dictionary = SimPlayerStats.get_stats(_profile)
	var derived: Dictionary = SimPlayerStats.calculate_derived_stats(_profile)
	var color: Color = TAB_COLORS["typing"]

	# Main typing stats
	var typing_panel := _create_section_panel("TYPING STATISTICS", color)
	_content_vbox.add_child(typing_panel)

	var typing_grid := _create_stat_grid()
	typing_panel.get_child(0).add_child(typing_grid)

	for stat_key in SimPlayerStats.STATS.keys():
		var stat_info: Dictionary = SimPlayerStats.STATS[stat_key]
		if str(stat_info.get("category", "")) == "typing":
			var name: String = str(stat_info.get("name", stat_key))
			var value: int = int(stats.get(stat_key, 0))
			_add_stat_row(typing_grid, name, _format_number(value), color)

	# Accuracy analysis
	var accuracy_panel := _create_section_panel("ACCURACY ANALYSIS", Color(0.4, 0.9, 0.4))
	_content_vbox.add_child(accuracy_panel)

	var accuracy_grid := _create_stat_grid()
	accuracy_panel.get_child(0).add_child(accuracy_grid)

	var total_chars: int = int(stats.get("total_chars_typed", 0))
	var typos: int = int(stats.get("total_typos", 0))
	var correct_chars: int = total_chars - typos

	_add_stat_row(accuracy_grid, "Overall Accuracy", "%.1f%%" % float(derived.get("overall_accuracy", 0)), Color(0.4, 0.9, 0.4))
	_add_stat_row(accuracy_grid, "Correct Characters", _format_number(correct_chars), Color(0.4, 0.9, 0.4))
	_add_stat_row(accuracy_grid, "Errors Made", _format_number(typos), Color(0.9, 0.4, 0.4))

	# Combo stats
	var combo_panel := _create_section_panel("COMBO STATISTICS", Color(0.9, 0.4, 0.9))
	_content_vbox.add_child(combo_panel)

	var combo_grid := _create_stat_grid()
	combo_panel.get_child(0).add_child(combo_grid)

	for stat_key in SimPlayerStats.STATS.keys():
		var stat_info: Dictionary = SimPlayerStats.STATS[stat_key]
		if str(stat_info.get("category", "")) == "combo":
			var name: String = str(stat_info.get("name", stat_key))
			var value: int = int(stats.get(stat_key, 0))
			_add_stat_row(combo_grid, name, _format_number(value), Color(0.9, 0.4, 0.9))

	_add_stat_row(combo_grid, "Combo Efficiency", "%.1f%%" % float(derived.get("combo_efficiency", 0)), Color(0.9, 0.4, 0.9))

func _build_records() -> void:
	var stats: Dictionary = SimPlayerStats.get_stats(_profile)
	var color: Color = TAB_COLORS["records"]

	# Personal records
	var records_panel := _create_section_panel("PERSONAL RECORDS", color)
	_content_vbox.add_child(records_panel)

	var records_grid := _create_stat_grid()
	records_panel.get_child(0).add_child(records_grid)

	for record_key in SimPlayerStats.RECORDS.keys():
		var record_info: Dictionary = SimPlayerStats.RECORDS[record_key]
		var name: String = str(record_info.get("name", record_key))
		var value: int = int(stats.get(record_key, 0))
		var lower_is_better: bool = bool(record_info.get("lower_is_better", false))

		var display_value: String
		if lower_is_better and value >= 999999:
			display_value = "--"
		else:
			display_value = _format_number(value)

		_add_stat_row(records_grid, name, display_value, color)

	# Milestones
	var milestones_panel := _create_section_panel("MILESTONES", Color(1.0, 0.84, 0.0))
	_content_vbox.add_child(milestones_panel)

	var milestones_vbox := VBoxContainer.new()
	milestones_vbox.add_theme_constant_override("separation", 6)
	milestones_panel.get_child(0).add_child(milestones_vbox)

	var kills: int = int(stats.get("total_kills", 0))
	var words: int = int(stats.get("total_words_typed", 0))
	var days: int = int(stats.get("days_survived", 0))

	_add_milestone_row(milestones_vbox, "Kills", kills, [100, 500, 1000, 5000, 10000])
	_add_milestone_row(milestones_vbox, "Words", words, [500, 2000, 5000, 10000, 25000])
	_add_milestone_row(milestones_vbox, "Days", days, [10, 25, 50, 100, 200])

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
	DesignSystem.style_label(header, "body", color)
	vbox.add_child(header)

	return container

func _create_stat_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 4)
	return grid

func _add_stat_row(grid: GridContainer, stat_name: String, value: String, color: Color) -> void:
	var name_label := Label.new()
	name_label.text = stat_name
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	name_label.custom_minimum_size = Vector2(180, 0)
	grid.add_child(name_label)

	var value_label := Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", 12)
	value_label.add_theme_color_override("font_color", color)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size = Vector2(100, 0)
	grid.add_child(value_label)

func _add_milestone_row(container: VBoxContainer, category: String, current: int, thresholds: Array) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	container.add_child(hbox)

	var cat_label := Label.new()
	cat_label.text = category
	cat_label.add_theme_font_size_override("font_size", 11)
	cat_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	cat_label.custom_minimum_size = Vector2(50, 0)
	hbox.add_child(cat_label)

	for threshold in thresholds:
		var milestone_chip := _create_milestone_chip(int(threshold), current >= int(threshold))
		hbox.add_child(milestone_chip)

func _create_milestone_chip(threshold: int, achieved: bool) -> Control:
	var chip := PanelContainer.new()

	var chip_style := StyleBoxFlat.new()
	if achieved:
		chip_style.bg_color = Color(0.2, 0.4, 0.2, 0.8)
		chip_style.border_color = Color(0.4, 0.8, 0.4)
	else:
		chip_style.bg_color = Color(0.1, 0.1, 0.12, 0.8)
		chip_style.border_color = Color(0.3, 0.3, 0.35)
	chip_style.set_border_width_all(1)
	chip_style.set_corner_radius_all(3)
	chip_style.set_content_margin_all(4)
	chip.add_theme_stylebox_override("panel", chip_style)

	var label := Label.new()
	label.text = _format_threshold(threshold)
	label.add_theme_font_size_override("font_size", 10)
	if achieved:
		label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	else:
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	chip.add_child(label)

	return chip

func _format_threshold(value: int) -> String:
	if value >= 1000:
		return "%dk" % (value / 1000)
	return str(value)

func _create_separator() -> Control:
	var sep := Control.new()
	sep.custom_minimum_size = Vector2(0, 8)
	return sep

func _format_number(value: int) -> String:
	var s: String = str(abs(value))
	var result: String = ""
	var count: int = 0

	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1

	if value < 0:
		result = "-" + result

	return result

func _on_close_pressed() -> void:
	hide()
	closed.emit()

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
