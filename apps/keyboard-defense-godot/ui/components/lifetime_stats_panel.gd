class_name LifetimeStatsPanel
extends PanelContainer
## Lifetime Stats Panel - Shows comprehensive player statistics and records

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")
const SimPlayerStats = preload("res://sim/player_stats.gd")

var _profile: Dictionary = {}

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Category colors
const CATEGORY_COLORS: Dictionary = {
	"combat": Color(0.9, 0.4, 0.4),
	"typing": Color(0.4, 0.8, 1.0),
	"economy": Color(1.0, 0.84, 0.0),
	"progression": Color(0.6, 0.9, 0.4),
	"time": Color(0.7, 0.6, 0.9),
	"combo": Color(1.0, 0.6, 0.3),
	"records": Color(0.9, 0.5, 0.9)
}


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(500, 560)

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
	title.text = "LIFETIME STATISTICS"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
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
	subtitle.text = "Your all-time performance and records"
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
	footer.text = "Stats are saved automatically"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_lifetime_stats(profile: Dictionary = {}) -> void:
	_profile = profile
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	var stats: Dictionary = SimPlayerStats.get_stats(_profile)
	var derived: Dictionary = SimPlayerStats.calculate_derived_stats(_profile)

	# Summary section
	_build_summary_section(stats, derived)

	# Combat section
	_build_category_section("combat", "COMBAT", stats)

	# Typing section
	_build_category_section("typing", "TYPING", stats, derived)

	# Economy section
	_build_category_section("economy", "ECONOMY", stats, derived)

	# Progression section
	_build_category_section("progression", "PROGRESSION", stats)

	# Combo section
	_build_category_section("combo", "COMBOS", stats, derived)

	# Records section
	_build_records_section(stats)

	# Time section
	_build_time_section(stats, derived)


func _build_summary_section(stats: Dictionary, derived: Dictionary) -> void:
	var section := PanelContainer.new()

	var section_style := StyleBoxFlat.new()
	section_style.bg_color = Color(0.1, 0.15, 0.2, 0.9)
	section_style.border_color = Color(0.4, 0.8, 1.0, 0.5)
	section_style.set_border_width_all(2)
	section_style.set_corner_radius_all(6)
	section_style.set_content_margin_all(12)
	section.add_theme_stylebox_override("panel", section_style)

	_content_vbox.add_child(section)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 8)
	section.add_child(grid)

	# Key summary stats
	_add_summary_stat(grid, "Total Kills", _format_number(int(stats.get("total_kills", 0))), Color(0.9, 0.4, 0.4))
	_add_summary_stat(grid, "Words Typed", _format_number(int(stats.get("total_words_typed", 0))), Color(0.4, 0.8, 1.0))
	_add_summary_stat(grid, "Gold Earned", _format_number(int(stats.get("total_gold_earned", 0))), Color(1.0, 0.84, 0.0))
	_add_summary_stat(grid, "K/D Ratio", "%.2f" % float(derived.get("kd_ratio", 0)), Color(0.9, 0.5, 0.5))
	_add_summary_stat(grid, "Accuracy", "%.1f%%" % float(derived.get("overall_accuracy", 100)), Color(0.4, 0.9, 0.4))
	_add_summary_stat(grid, "Combo Eff", "%.1f%%" % float(derived.get("combo_efficiency", 100)), Color(1.0, 0.6, 0.3))


func _add_summary_stat(grid: GridContainer, label: String, value: String, color: Color) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	grid.add_child(vbox)

	var label_node := Label.new()
	label_node.text = label
	label_node.add_theme_font_size_override("font_size", 9)
	label_node.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label_node)

	var value_node := Label.new()
	value_node.text = value
	value_node.add_theme_font_size_override("font_size", 16)
	value_node.add_theme_color_override("font_color", color)
	value_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(value_node)


func _build_category_section(category: String, title: String, stats: Dictionary, derived: Dictionary = {}) -> void:
	var color: Color = CATEGORY_COLORS.get(category, Color.WHITE)

	var section := _create_section_panel(title, color)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Add stats for this category
	for stat_key in SimPlayerStats.STATS.keys():
		var stat_info: Dictionary = SimPlayerStats.STATS[stat_key]
		if str(stat_info.get("category", "")) == category:
			var stat_name: String = str(stat_info.get("name", stat_key))
			var stat_value: int = int(stats.get(stat_key, 0))
			var row := _create_stat_row(stat_name, _format_number(stat_value), color)
			vbox.add_child(row)

	# Add derived stats for certain categories
	if category == "typing" and derived.has("overall_accuracy"):
		var row := _create_stat_row("Overall Accuracy", "%.1f%%" % float(derived.get("overall_accuracy", 0)), Color(0.4, 0.9, 0.4))
		vbox.add_child(row)

	if category == "economy" and derived.has("avg_gold_per_wave"):
		var row := _create_stat_row("Avg Gold/Wave", "%.1f" % float(derived.get("avg_gold_per_wave", 0)), Color(1.0, 0.84, 0.0))
		vbox.add_child(row)

	if category == "combo" and derived.has("combo_efficiency"):
		var row := _create_stat_row("Combo Efficiency", "%.1f%%" % float(derived.get("combo_efficiency", 0)), Color(0.4, 0.9, 0.4))
		vbox.add_child(row)


func _build_records_section(stats: Dictionary) -> void:
	var color: Color = CATEGORY_COLORS.get("records", Color.WHITE)

	var section := _create_section_panel("PERSONAL RECORDS", color)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for record_key in SimPlayerStats.RECORDS.keys():
		var record_info: Dictionary = SimPlayerStats.RECORDS[record_key]
		var record_name: String = str(record_info.get("name", record_key))
		var lower_is_better: bool = bool(record_info.get("lower_is_better", false))
		var record_value: int = int(stats.get(record_key, 999999 if lower_is_better else 0))

		var value_text: String
		if lower_is_better and record_value >= 999999:
			value_text = "--"
		else:
			value_text = _format_number(record_value)

		var row := _create_stat_row(record_name, value_text, color)
		vbox.add_child(row)


func _build_time_section(stats: Dictionary, derived: Dictionary) -> void:
	var color: Color = CATEGORY_COLORS.get("time", Color.WHITE)

	var section := _create_section_panel("TIME PLAYED", color)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var sessions: int = int(stats.get("sessions_played", 0))
	var minutes: int = int(stats.get("total_play_time", 0))
	var hours: float = float(derived.get("play_time_hours", 0))

	var sessions_row := _create_stat_row("Sessions Played", str(sessions), color)
	vbox.add_child(sessions_row)

	var time_row := _create_stat_row("Total Time", "%.1f hours" % hours, color)
	vbox.add_child(time_row)

	if sessions > 0:
		var avg_session: float = float(minutes) / float(sessions)
		var avg_row := _create_stat_row("Avg Session", "%.0f minutes" % avg_session, color)
		vbox.add_child(avg_row)


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
	vbox.add_theme_constant_override("separation", 6)
	container.add_child(vbox)

	var header := Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", color)
	vbox.add_child(header)

	return container


func _create_stat_row(label: String, value: String, color: Color) -> Control:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	var label_node := Label.new()
	label_node.text = label
	label_node.add_theme_font_size_override("font_size", 11)
	label_node.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	label_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label_node)

	var value_node := Label.new()
	value_node.text = value
	value_node.add_theme_font_size_override("font_size", 12)
	value_node.add_theme_color_override("font_color", color)
	hbox.add_child(value_node)

	return hbox


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
