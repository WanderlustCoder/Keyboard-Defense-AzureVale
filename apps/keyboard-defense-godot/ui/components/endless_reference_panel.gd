class_name EndlessReferencePanel
extends PanelContainer
## Endless Mode Reference Panel - Shows scaling, milestones, and modifiers

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Scaling data (from SimEndlessMode)
const SCALING_INFO: Array[Dictionary] = [
	{
		"stat": "Enemy HP",
		"per_day": "+8%",
		"color": Color(0.9, 0.4, 0.4),
		"description": "Enemies become harder to kill"
	},
	{
		"stat": "Enemy Speed",
		"per_day": "+2%",
		"color": Color(0.9, 0.6, 0.3),
		"description": "Enemies move faster toward castle"
	},
	{
		"stat": "Enemy Count",
		"per_day": "+5%",
		"color": Color(0.7, 0.5, 0.9),
		"description": "More enemies spawn per wave"
	},
	{
		"stat": "Enemy Damage",
		"per_day": "+4%",
		"color": Color(0.9, 0.4, 0.4),
		"description": "Enemies deal more damage"
	}
]

# Milestones (from SimEndlessMode)
const MILESTONES: Array[Dictionary] = [
	{"day": 5, "name": "Survivor", "gold": 50, "xp": 100},
	{"day": 10, "name": "Enduring", "gold": 150, "xp": 300},
	{"day": 15, "name": "Persistent", "gold": 300, "xp": 600},
	{"day": 20, "name": "Indomitable", "gold": 500, "xp": 1000},
	{"day": 25, "name": "Unstoppable", "gold": 750, "xp": 1500},
	{"day": 30, "name": "Legendary", "gold": 1000, "xp": 2000},
	{"day": 40, "name": "Mythic", "gold": 1500, "xp": 3000},
	{"day": 50, "name": "Godlike", "gold": 2500, "xp": 5000},
	{"day": 75, "name": "Transcendent", "gold": 5000, "xp": 10000},
	{"day": 100, "name": "Eternal", "gold": 10000, "xp": 25000}
]

# Modifiers (from SimEndlessMode)
const MODIFIERS: Array[Dictionary] = [
	{
		"id": "veteran_enemies",
		"name": "Veteran Enemies",
		"start_day": 8,
		"description": "Enemies gain +10% armor",
		"color": Color(0.6, 0.6, 0.7)
	},
	{
		"id": "elite_spawn",
		"name": "Elite Spawn",
		"start_day": 12,
		"description": "Elite enemies spawn 15% more often",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"id": "swarm_mode",
		"name": "Swarm Mode",
		"start_day": 16,
		"description": "20% chance for swarm waves (2x enemies)",
		"color": Color(0.7, 0.5, 0.9)
	},
	{
		"id": "boss_rush",
		"name": "Boss Rush",
		"start_day": 20,
		"description": "Mini-bosses appear every 3 waves",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"id": "affix_surge",
		"name": "Affix Surge",
		"start_day": 25,
		"description": "40% of enemies gain random affixes",
		"color": Color(0.9, 0.4, 0.8)
	},
	{
		"id": "nightmare",
		"name": "Nightmare",
		"start_day": 30,
		"description": "2x HP, 1.5x damage - true challenge",
		"color": Color(0.8, 0.2, 0.2)
	}
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(540, 640)

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
	title.text = "ENDLESS MODE"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
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
	subtitle.text = "Infinite scaling challenge - how long can you survive?"
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	main_vbox.add_child(subtitle)

	# Unlock info
	var unlock := Label.new()
	unlock.text = "Unlock: Reach Day 15 or complete 45 waves"
	unlock.add_theme_font_size_override("font_size", 11)
	unlock.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	main_vbox.add_child(unlock)

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
	footer.text = "Survive as long as possible for eternal glory"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_endless_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Scaling section
	_build_scaling_section()

	# Modifiers section
	_build_modifiers_section()

	# Milestones section
	_build_milestones_section()


func _build_scaling_section() -> void:
	var section := _create_section_panel("DIFFICULTY SCALING", Color(0.9, 0.4, 0.4))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in SCALING_INFO:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var stat: String = str(info.get("stat", ""))
		var per_day: String = str(info.get("per_day", ""))
		var color: Color = info.get("color", Color.WHITE)

		var stat_label := Label.new()
		stat_label.text = stat
		stat_label.add_theme_font_size_override("font_size", 10)
		stat_label.add_theme_color_override("font_color", color)
		stat_label.custom_minimum_size = Vector2(100, 0)
		hbox.add_child(stat_label)

		var rate_label := Label.new()
		rate_label.text = per_day + "/day"
		rate_label.add_theme_font_size_override("font_size", 10)
		rate_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3))
		rate_label.custom_minimum_size = Vector2(70, 0)
		hbox.add_child(rate_label)

		var desc_label := Label.new()
		desc_label.text = str(info.get("description", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_modifiers_section() -> void:
	var section := _create_section_panel("SPECIAL MODIFIERS", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for mod in MODIFIERS:
		var card := _create_modifier_card(mod)
		vbox.add_child(card)


func _create_modifier_card(mod: Dictionary) -> Control:
	var name_str: String = str(mod.get("name", ""))
	var start_day: int = int(mod.get("start_day", 0))
	var description: String = str(mod.get("description", ""))
	var color: Color = mod.get("color", Color.WHITE)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	var day_label := Label.new()
	day_label.text = "Day %d+" % start_day
	day_label.add_theme_font_size_override("font_size", 9)
	day_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	day_label.custom_minimum_size = Vector2(55, 0)
	hbox.add_child(day_label)

	var name_label := Label.new()
	name_label.text = name_str
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", color)
	name_label.custom_minimum_size = Vector2(110, 0)
	hbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 9)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	hbox.add_child(desc_label)

	return hbox


func _build_milestones_section() -> void:
	var section := _create_section_panel("MILESTONES & REWARDS", Color(1.0, 0.84, 0.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Create grid for milestones
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 15)
	grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(grid)

	# Header row
	var headers: Array[String] = ["Day", "Title", "Gold", "XP"]
	for h in headers:
		var header := Label.new()
		header.text = h
		header.add_theme_font_size_override("font_size", 10)
		header.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		grid.add_child(header)

	# Milestone rows
	for milestone in MILESTONES:
		var day: int = int(milestone.get("day", 0))
		var name_str: String = str(milestone.get("name", ""))
		var gold: int = int(milestone.get("gold", 0))
		var xp: int = int(milestone.get("xp", 0))

		var day_label := Label.new()
		day_label.text = str(day)
		day_label.add_theme_font_size_override("font_size", 9)
		day_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		grid.add_child(day_label)

		var name_label := Label.new()
		name_label.text = name_str
		name_label.add_theme_font_size_override("font_size", 9)
		name_label.add_theme_color_override("font_color", _get_milestone_color(day))
		grid.add_child(name_label)

		var gold_label := Label.new()
		gold_label.text = str(gold)
		gold_label.add_theme_font_size_override("font_size", 9)
		gold_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		grid.add_child(gold_label)

		var xp_label := Label.new()
		xp_label.text = str(xp)
		xp_label.add_theme_font_size_override("font_size", 9)
		xp_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		grid.add_child(xp_label)


func _get_milestone_color(day: int) -> Color:
	if day >= 75:
		return Color(1.0, 0.84, 0.0)  # Gold
	elif day >= 40:
		return Color(0.7, 0.5, 0.9)  # Purple
	elif day >= 20:
		return Color(0.9, 0.6, 0.3)  # Orange
	else:
		return Color(0.5, 0.8, 0.3)  # Green


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
