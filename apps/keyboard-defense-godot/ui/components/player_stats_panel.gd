class_name PlayerStatsPanel
extends PanelContainer
## Player Stats Panel - Shows all stat categories and personal records

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Stat categories (from SimPlayerStats)
const STAT_CATEGORIES: Dictionary = {
	"combat": {
		"name": "Combat",
		"color": Color(0.9, 0.4, 0.4),
		"stats": [
			{"key": "total_kills", "name": "Total Kills"},
			{"key": "total_boss_kills", "name": "Boss Kills"},
			{"key": "total_damage_dealt", "name": "Damage Dealt"},
			{"key": "total_damage_taken", "name": "Damage Taken"},
			{"key": "total_deaths", "name": "Deaths"}
		]
	},
	"typing": {
		"name": "Typing",
		"color": Color(0.4, 0.8, 1.0),
		"stats": [
			{"key": "total_words_typed", "name": "Words Typed"},
			{"key": "total_chars_typed", "name": "Characters Typed"},
			{"key": "total_typos", "name": "Typos Made"},
			{"key": "perfect_words", "name": "Perfect Words"}
		]
	},
	"economy": {
		"name": "Economy",
		"color": Color(1.0, 0.84, 0.0),
		"stats": [
			{"key": "total_gold_earned", "name": "Gold Earned"},
			{"key": "total_gold_spent", "name": "Gold Spent"},
			{"key": "items_purchased", "name": "Items Purchased"},
			{"key": "items_dropped", "name": "Items Dropped"}
		]
	},
	"progression": {
		"name": "Progression",
		"color": Color(0.5, 0.8, 0.3),
		"stats": [
			{"key": "days_survived", "name": "Days Survived"},
			{"key": "waves_completed", "name": "Waves Completed"},
			{"key": "quests_completed", "name": "Quests Completed"},
			{"key": "achievements_unlocked", "name": "Achievements Unlocked"}
		]
	},
	"combo": {
		"name": "Combo",
		"color": Color(0.9, 0.5, 0.9),
		"stats": [
			{"key": "total_combos_started", "name": "Combos Started"},
			{"key": "total_combos_broken", "name": "Combos Broken"},
			{"key": "combo_words_typed", "name": "Words in Combos"}
		]
	}
}

# Personal records
const RECORDS: Array[Dictionary] = [
	{"key": "highest_combo", "name": "Highest Combo", "color": Color(0.9, 0.5, 0.9)},
	{"key": "highest_day", "name": "Highest Day Reached", "color": Color(0.5, 0.8, 0.3)},
	{"key": "most_kills_wave", "name": "Most Kills in a Wave", "color": Color(0.9, 0.4, 0.4)},
	{"key": "most_gold_wave", "name": "Most Gold in a Wave", "color": Color(1.0, 0.84, 0.0)},
	{"key": "fastest_wave_time", "name": "Fastest Wave (seconds)", "color": Color(0.4, 0.8, 1.0)},
	{"key": "highest_accuracy", "name": "Highest Accuracy (%)", "color": Color(0.4, 0.9, 0.4)},
	{"key": "longest_streak", "name": "Longest Daily Streak", "color": Color(0.9, 0.6, 0.3)},
	{"key": "highest_wpm", "name": "Highest WPM", "color": Color(0.4, 0.8, 1.0)},
	{"key": "endless_highest_day", "name": "Endless Mode High Day", "color": Color(0.7, 0.5, 0.9)}
]

# Derived stats
const DERIVED_STATS: Array[Dictionary] = [
	{"name": "Overall Accuracy", "unit": "%", "color": Color(0.4, 0.9, 0.4)},
	{"name": "K/D Ratio", "unit": "", "color": Color(0.9, 0.4, 0.4)},
	{"name": "Combo Efficiency", "unit": "%", "color": Color(0.9, 0.5, 0.9)},
	{"name": "Avg Words/Session", "unit": "", "color": Color(0.4, 0.8, 1.0)},
	{"name": "Avg Gold/Wave", "unit": "", "color": Color(1.0, 0.84, 0.0)},
	{"name": "Avg Kills/Wave", "unit": "", "color": Color(0.9, 0.4, 0.4)}
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(520, 600)

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
	title.text = "PLAYER STATISTICS"
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
	subtitle.text = "Track your lifetime performance and achievements"
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
	footer.text = "Stats track your entire career - keep improving!"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_player_stats() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Records section first (most interesting)
	_build_records_section()

	# Derived stats section
	_build_derived_section()

	# Category sections
	for cat_key in STAT_CATEGORIES.keys():
		_build_category_section(cat_key)


func _build_records_section() -> void:
	var section := _create_section_panel("PERSONAL RECORDS", Color(1.0, 0.84, 0.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for record in RECORDS:
		var key: String = str(record.get("key", ""))
		var name: String = str(record.get("name", key))
		var color: Color = record.get("color", Color.WHITE)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = name
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		name_label.custom_minimum_size = Vector2(180, 0)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_label)

		var value_label := Label.new()
		value_label.text = "--"
		value_label.add_theme_font_size_override("font_size", 11)
		value_label.add_theme_color_override("font_color", color)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(value_label)


func _build_derived_section() -> void:
	var section := _create_section_panel("PERFORMANCE METRICS", Color(0.4, 0.9, 0.4))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for derived in DERIVED_STATS:
		var name: String = str(derived.get("name", ""))
		var unit: String = str(derived.get("unit", ""))
		var color: Color = derived.get("color", Color.WHITE)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = name
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		name_label.custom_minimum_size = Vector2(140, 0)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_label)

		var value_label := Label.new()
		value_label.text = "--%s" % unit
		value_label.add_theme_font_size_override("font_size", 11)
		value_label.add_theme_color_override("font_color", color)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(value_label)


func _build_category_section(cat_key: String) -> void:
	var category: Dictionary = STAT_CATEGORIES.get(cat_key, {})
	var name: String = str(category.get("name", cat_key))
	var color: Color = category.get("color", Color.WHITE)
	var stats: Array = category.get("stats", [])

	var section := _create_section_panel(name.to_upper() + " STATS", color)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for stat in stats:
		var stat_name: String = str(stat.get("name", ""))

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = stat_name
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		name_label.custom_minimum_size = Vector2(140, 0)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_label)

		var value_label := Label.new()
		value_label.text = "0"
		value_label.add_theme_font_size_override("font_size", 11)
		value_label.add_theme_color_override("font_color", color)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(value_label)


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


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
