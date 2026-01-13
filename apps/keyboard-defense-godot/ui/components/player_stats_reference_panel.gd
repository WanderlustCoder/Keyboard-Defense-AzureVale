class_name PlayerStatsReferencePanel
extends PanelContainer
## Player Stats Reference Panel - Shows all tracked statistics and records.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Stat categories
const STAT_CATEGORIES: Array[Dictionary] = [
	{
		"id": "combat",
		"name": "Combat Stats",
		"desc": "Battle performance metrics",
		"color": Color(0.96, 0.26, 0.21)
	},
	{
		"id": "typing",
		"name": "Typing Stats",
		"desc": "Typing accuracy and volume",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"id": "economy",
		"name": "Economy Stats",
		"desc": "Gold and item tracking",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"id": "progression",
		"name": "Progression Stats",
		"desc": "Game progression milestones",
		"color": Color(0.4, 1.0, 0.4)
	},
	{
		"id": "time",
		"name": "Time Stats",
		"desc": "Play time tracking",
		"color": Color(0.6, 0.6, 0.8)
	},
	{
		"id": "combo",
		"name": "Combo Stats",
		"desc": "Combo streak tracking",
		"color": Color(1.0, 0.6, 0.2)
	}
]

# Combat stats
const COMBAT_STATS: Array[Dictionary] = [
	{"key": "total_kills", "name": "Total Kills", "desc": "Enemies defeated"},
	{"key": "total_boss_kills", "name": "Boss Kills", "desc": "Bosses defeated"},
	{"key": "total_damage_dealt", "name": "Damage Dealt", "desc": "Total damage inflicted"},
	{"key": "total_damage_taken", "name": "Damage Taken", "desc": "Total damage received"},
	{"key": "total_deaths", "name": "Deaths", "desc": "Times defeated"}
]

# Typing stats
const TYPING_STATS: Array[Dictionary] = [
	{"key": "total_words_typed", "name": "Words Typed", "desc": "Total words completed"},
	{"key": "total_chars_typed", "name": "Characters Typed", "desc": "Total keystrokes"},
	{"key": "total_typos", "name": "Typos Made", "desc": "Mistakes made"},
	{"key": "perfect_words", "name": "Perfect Words", "desc": "Words with 100% accuracy"}
]

# Economy stats
const ECONOMY_STATS: Array[Dictionary] = [
	{"key": "total_gold_earned", "name": "Gold Earned", "desc": "Lifetime gold income"},
	{"key": "total_gold_spent", "name": "Gold Spent", "desc": "Total gold used"},
	{"key": "items_purchased", "name": "Items Purchased", "desc": "Items bought"},
	{"key": "items_dropped", "name": "Items Dropped", "desc": "Items from loot"}
]

# Progression stats
const PROGRESSION_STATS: Array[Dictionary] = [
	{"key": "days_survived", "name": "Days Survived", "desc": "Total days completed"},
	{"key": "waves_completed", "name": "Waves Completed", "desc": "Defense waves won"},
	{"key": "quests_completed", "name": "Quests Completed", "desc": "Quests finished"},
	{"key": "challenges_completed", "name": "Challenges Done", "desc": "Challenges beaten"},
	{"key": "achievements_unlocked", "name": "Achievements", "desc": "Achievements earned"}
]

# Time and combo stats
const TIME_STATS: Array[Dictionary] = [
	{"key": "total_play_time", "name": "Play Time (min)", "desc": "Total minutes played"},
	{"key": "sessions_played", "name": "Sessions Played", "desc": "Game sessions started"}
]

const COMBO_STATS: Array[Dictionary] = [
	{"key": "total_combos_started", "name": "Combos Started", "desc": "Combo streaks begun"},
	{"key": "total_combos_broken", "name": "Combos Broken", "desc": "Streaks interrupted"},
	{"key": "combo_words_typed", "name": "Combo Words", "desc": "Words typed in combos"}
]

# Personal records
const RECORDS: Array[Dictionary] = [
	{"key": "highest_combo", "name": "Highest Combo", "desc": "Best combo streak", "color": Color(1.0, 0.6, 0.2)},
	{"key": "highest_day", "name": "Highest Day", "desc": "Furthest day reached", "color": Color(0.4, 1.0, 0.4)},
	{"key": "most_kills_wave", "name": "Most Kills/Wave", "desc": "Best wave performance", "color": Color(0.96, 0.26, 0.21)},
	{"key": "most_gold_wave", "name": "Most Gold/Wave", "desc": "Best gold in a wave", "color": Color(1.0, 0.84, 0.0)},
	{"key": "fastest_wave_time", "name": "Fastest Wave", "desc": "Quickest wave clear (sec)", "color": Color(0.4, 0.8, 1.0)},
	{"key": "highest_accuracy", "name": "Best Accuracy", "desc": "Highest accuracy (%)", "color": Color(0.4, 1.0, 0.4)},
	{"key": "longest_streak", "name": "Longest Streak", "desc": "Best daily login streak", "color": Color(0.8, 0.6, 1.0)},
	{"key": "highest_wpm", "name": "Highest WPM", "desc": "Best typing speed", "color": Color(0.4, 0.8, 1.0)},
	{"key": "endless_highest_day", "name": "Endless High Day", "desc": "Best endless mode day", "color": Color(1.0, 0.4, 0.4)}
]

# Derived stats
const DERIVED_STATS: Array[Dictionary] = [
	{"name": "Overall Accuracy", "formula": "(chars - typos) / chars", "color": Color(0.4, 1.0, 0.4)},
	{"name": "K/D Ratio", "formula": "kills / deaths", "color": Color(0.96, 0.26, 0.21)},
	{"name": "Combo Efficiency", "formula": "(started - broken) / started", "color": Color(1.0, 0.6, 0.2)},
	{"name": "Avg Words/Session", "formula": "words / sessions", "color": Color(0.4, 0.8, 1.0)},
	{"name": "Avg Gold/Wave", "formula": "gold earned / waves", "color": Color(1.0, 0.84, 0.0)},
	{"name": "Avg Kills/Wave", "formula": "kills / waves", "color": Color(0.96, 0.26, 0.21)}
]

# Tips
const STATS_TIPS: Array[String] = [
	"Use 'stats' command to view your current statistics",
	"Use 'stats full' for a detailed breakdown",
	"Records are tracked automatically during gameplay",
	"Derived stats calculate from your tracked metrics",
	"Session stats are saved when you exit the game"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 740)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "PLAYER STATISTICS"
	DesignSystem.style_label(title, "h2", ThemeColors.INFO)
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
	subtitle.text = "20 tracked stats, 9 records, 6 derived metrics"
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
	footer.text = "Track your progress and beat your records"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_player_stats_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Categories overview
	_build_categories_section()

	# Tracked stats
	_build_stats_section("COMBAT STATS", Color(0.96, 0.26, 0.21), COMBAT_STATS)
	_build_stats_section("TYPING STATS", Color(0.4, 0.8, 1.0), TYPING_STATS)
	_build_stats_section("ECONOMY STATS", Color(1.0, 0.84, 0.0), ECONOMY_STATS)
	_build_stats_section("PROGRESSION STATS", Color(0.4, 1.0, 0.4), PROGRESSION_STATS)

	# Records
	_build_records_section()

	# Derived stats
	_build_derived_section()

	# Tips
	_build_tips_section()


func _build_categories_section() -> void:
	var section := _create_section_panel("STAT CATEGORIES", Color(0.5, 0.6, 0.8))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Two-column layout
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", DesignSystem.SPACE_LG)
	grid.add_theme_constant_override("v_separation", DesignSystem.SPACE_XS)
	vbox.add_child(grid)

	for cat in STAT_CATEGORIES:
		var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_XS)
		hbox.custom_minimum_size = Vector2(220, 0)
		grid.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(cat.get("name", ""))
		DesignSystem.style_label(name_label, "caption", cat.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(100, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(cat.get("desc", ""))
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_stats_section(title: String, color: Color, stats: Array[Dictionary]) -> void:
	var section := _create_section_panel(title, color)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Two-column layout
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", DesignSystem.SPACE_MD)
	grid.add_theme_constant_override("v_separation", 2)
	vbox.add_child(grid)

	for stat in stats:
		var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_XS)
		hbox.custom_minimum_size = Vector2(220, 0)
		grid.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(stat.get("name", ""))
		DesignSystem.style_label(name_label, "caption", color.lightened(0.2))
		name_label.custom_minimum_size = Vector2(100, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(stat.get("desc", ""))
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_records_section() -> void:
	var section := _create_section_panel("PERSONAL RECORDS", ThemeColors.RESOURCE_GOLD)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Two-column layout
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", DesignSystem.SPACE_MD)
	grid.add_theme_constant_override("v_separation", DesignSystem.SPACE_XS)
	vbox.add_child(grid)

	for record in RECORDS:
		var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_XS)
		hbox.custom_minimum_size = Vector2(220, 0)
		grid.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(record.get("name", ""))
		DesignSystem.style_label(name_label, "caption", record.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(100, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(record.get("desc", ""))
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_derived_section() -> void:
	var section := _create_section_panel("DERIVED STATS", Color(0.6, 0.5, 0.8))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for stat in DERIVED_STATS:
		var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(stat.get("name", ""))
		DesignSystem.style_label(name_label, "caption", stat.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(120, 0)
		hbox.add_child(name_label)

		var formula_label := Label.new()
		formula_label.text = str(stat.get("formula", ""))
		DesignSystem.style_label(formula_label, "caption", ThemeColors.TEXT_DIM)
		hbox.add_child(formula_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("STATS INFO", ThemeColors.SUCCESS)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in STATS_TIPS:
		var tip_label := Label.new()
		tip_label.text = "- " + tip
		DesignSystem.style_label(tip_label, "caption", ThemeColors.TEXT_DIM)
		tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(tip_label)


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
