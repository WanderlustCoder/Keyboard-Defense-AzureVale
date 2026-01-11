class_name MilestonesReferencePanel
extends PanelContainer
## Milestones Reference Panel - Shows all achievement milestones and thresholds

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Milestone categories
const MILESTONE_CATEGORIES: Array[Dictionary] = [
	{
		"id": "wpm",
		"name": "WPM Milestones",
		"desc": "Words per minute typing speed",
		"icon": "speed",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"id": "accuracy",
		"name": "Accuracy Milestones",
		"desc": "Typing accuracy percentage",
		"icon": "target",
		"color": Color(0.4, 1.0, 0.4)
	},
	{
		"id": "combo",
		"name": "Combo Milestones",
		"desc": "Maximum combo streak",
		"icon": "fire",
		"color": Color(1.0, 0.6, 0.2)
	},
	{
		"id": "kills",
		"name": "Kill Milestones",
		"desc": "Cumulative enemies defeated",
		"icon": "sword",
		"color": Color(1.0, 0.4, 0.4)
	},
	{
		"id": "words",
		"name": "Word Milestones",
		"desc": "Cumulative words typed",
		"icon": "book",
		"color": Color(0.8, 0.6, 1.0)
	},
	{
		"id": "streak",
		"name": "Streak Milestones",
		"desc": "Consecutive daily play",
		"icon": "calendar",
		"color": Color(1.0, 0.84, 0.0)
	}
]

# WPM milestones
const WPM_MILESTONES: Array[Dictionary] = [
	{"value": 20, "title": "First Steps", "desc": "20 WPM reached"},
	{"value": 30, "title": "Getting Faster", "desc": "30 WPM"},
	{"value": 40, "title": "Solid Speed", "desc": "40 WPM achieved"},
	{"value": 50, "title": "Professional Speed", "desc": "50 WPM"},
	{"value": 60, "title": "Expert Typist", "desc": "60 WPM"},
	{"value": 70, "title": "Speed Demon", "desc": "70 WPM"},
	{"value": 80, "title": "Blazing Fast", "desc": "80 WPM"},
	{"value": 90, "title": "Incredible", "desc": "90 WPM"},
	{"value": 100, "title": "Century Club", "desc": "100 WPM"},
	{"value": 120, "title": "Superhuman", "desc": "120 WPM"},
	{"value": 150, "title": "Legendary", "desc": "150 WPM"}
]

# Accuracy milestones
const ACCURACY_MILESTONES: Array[Dictionary] = [
	{"value": 80, "title": "Solid Accuracy", "desc": "80%+"},
	{"value": 85, "title": "Sharp Shooter", "desc": "85%+"},
	{"value": 90, "title": "Precision Master", "desc": "90%+"},
	{"value": 95, "title": "Near Perfect", "desc": "95%+"},
	{"value": 98, "title": "Surgical Precision", "desc": "98%+"},
	{"value": 99, "title": "Almost Flawless", "desc": "99%+"},
	{"value": 100, "title": "PERFECT", "desc": "100% Accuracy"}
]

# Combo milestones
const COMBO_MILESTONES: Array[Dictionary] = [
	{"value": 5, "title": "Combo Started", "desc": "5 streak"},
	{"value": 10, "title": "Double Digits", "desc": "10 combo"},
	{"value": 15, "title": "On Fire", "desc": "15 combo"},
	{"value": 20, "title": "Unstoppable", "desc": "20 combo"},
	{"value": 25, "title": "Dominating", "desc": "25 combo"},
	{"value": 30, "title": "Legendary Streak", "desc": "30 combo"},
	{"value": 40, "title": "Godlike", "desc": "40 combo"},
	{"value": 50, "title": "Impossible", "desc": "50 combo"},
	{"value": 75, "title": "Mythical", "desc": "75 combo"},
	{"value": 100, "title": "IMMORTAL", "desc": "100 combo"}
]

# Kill milestones
const KILL_MILESTONES: Array[Dictionary] = [
	{"value": 50, "title": "First Blood", "desc": "50 enemies"},
	{"value": 100, "title": "Centurion", "desc": "100 enemies"},
	{"value": 250, "title": "Warrior", "desc": "250 enemies"},
	{"value": 500, "title": "Champion", "desc": "500 enemies"},
	{"value": 1000, "title": "Slayer", "desc": "1,000 enemies"},
	{"value": 2500, "title": "Destroyer", "desc": "2,500 enemies"},
	{"value": 5000, "title": "Annihilator", "desc": "5,000 enemies"},
	{"value": 10000, "title": "LEGEND", "desc": "10,000 enemies"}
]

# Word milestones
const WORD_MILESTONES: Array[Dictionary] = [
	{"value": 100, "title": "Scribe", "desc": "100 words"},
	{"value": 500, "title": "Writer", "desc": "500 words"},
	{"value": 1000, "title": "Author", "desc": "1,000 words"},
	{"value": 2500, "title": "Novelist", "desc": "2,500 words"},
	{"value": 5000, "title": "Master Scribe", "desc": "5,000 words"},
	{"value": 10000, "title": "Wordsmith", "desc": "10,000 words"},
	{"value": 25000, "title": "Literary Master", "desc": "25,000 words"},
	{"value": 50000, "title": "LEGEND OF WORDS", "desc": "50,000 words"}
]

# Streak milestones
const STREAK_MILESTONES: Array[Dictionary] = [
	{"value": 3, "title": "Three-Day Streak", "desc": "3 days"},
	{"value": 7, "title": "Weekly Warrior", "desc": "7 days"},
	{"value": 14, "title": "Two Week Champion", "desc": "14 days"},
	{"value": 21, "title": "Three Week Hero", "desc": "21 days"},
	{"value": 30, "title": "Monthly Master", "desc": "30 days"},
	{"value": 60, "title": "Two Month Titan", "desc": "60 days"},
	{"value": 90, "title": "Quarterly Champion", "desc": "90 days"},
	{"value": 180, "title": "Half Year Hero", "desc": "180 days"},
	{"value": 365, "title": "YEAR OF MASTERY", "desc": "365 days"}
]

# Milestone tips
const MILESTONE_TIPS: Array[String] = [
	"Personal bests are celebrated even between milestones",
	"WPM, Accuracy, and Combo milestones track your best performance",
	"Kill and Word milestones are cumulative across all sessions",
	"Streak milestones require consecutive days of play",
	"Gold badge appears on your profile when reaching major milestones"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(520, 720)

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
	title.text = "MILESTONES"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
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
	subtitle.text = "6 categories with 53 total milestones to achieve"
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
	footer.text = "Track your progress and celebrate achievements"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_milestones_reference() -> void:
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

	# Each milestone category
	_build_milestone_section("WPM MILESTONES", Color(0.4, 0.8, 1.0), WPM_MILESTONES, "WPM")
	_build_milestone_section("ACCURACY MILESTONES", Color(0.4, 1.0, 0.4), ACCURACY_MILESTONES, "%")
	_build_milestone_section("COMBO MILESTONES", Color(1.0, 0.6, 0.2), COMBO_MILESTONES, "x")
	_build_milestone_section("KILL MILESTONES", Color(1.0, 0.4, 0.4), KILL_MILESTONES, "")
	_build_milestone_section("WORD MILESTONES", Color(0.8, 0.6, 1.0), WORD_MILESTONES, "")
	_build_milestone_section("STREAK MILESTONES", Color(1.0, 0.84, 0.0), STREAK_MILESTONES, "days")

	# Tips
	_build_tips_section()


func _build_categories_section() -> void:
	var section := _create_section_panel("MILESTONE CATEGORIES", Color(0.6, 0.6, 0.8))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for cat in MILESTONE_CATEGORIES:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(cat.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", cat.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(140, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(cat.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_milestone_section(title: String, color: Color, milestones: Array[Dictionary], suffix: String) -> void:
	var section := _create_section_panel(title, color)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Create two-column layout
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 15)
	grid.add_theme_constant_override("v_separation", 2)
	vbox.add_child(grid)

	for milestone in milestones:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 5)
		hbox.custom_minimum_size = Vector2(200, 0)
		grid.add_child(hbox)

		var value_label := Label.new()
		if suffix == "%":
			value_label.text = "%d%%" % milestone.get("value", 0)
		elif suffix == "x":
			value_label.text = "x%d" % milestone.get("value", 0)
		elif suffix.is_empty():
			value_label.text = _format_number(int(milestone.get("value", 0)))
		else:
			value_label.text = "%d %s" % [milestone.get("value", 0), suffix]
		value_label.add_theme_font_size_override("font_size", 9)
		value_label.add_theme_color_override("font_color", color)
		value_label.custom_minimum_size = Vector2(55, 0)
		hbox.add_child(value_label)

		var title_label := Label.new()
		title_label.text = str(milestone.get("title", ""))
		title_label.add_theme_font_size_override("font_size", 9)
		title_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(title_label)


func _format_number(num: int) -> String:
	if num >= 1000:
		return "%d,%03d" % [num / 1000, num % 1000]
	return str(num)


func _build_tips_section() -> void:
	var section := _create_section_panel("MILESTONE INFO", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in MILESTONE_TIPS:
		var tip_label := Label.new()
		tip_label.text = "- " + tip
		tip_label.add_theme_font_size_override("font_size", 9)
		tip_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(tip_label)


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
