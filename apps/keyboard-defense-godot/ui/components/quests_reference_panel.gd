class_name QuestsReferencePanel
extends PanelContainer
## Quests Reference Panel - Shows quest types, objectives, and rewards

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Quest types
const QUEST_TYPES: Array[Dictionary] = [
	{
		"id": "daily",
		"name": "Daily Quests",
		"desc": "Reset each day, 3 available",
		"refresh": "Daily",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"id": "weekly",
		"name": "Weekly Quests",
		"desc": "Reset each week, 2 available",
		"refresh": "Weekly",
		"color": Color(0.8, 0.6, 1.0)
	},
	{
		"id": "challenge",
		"name": "Challenge Quests",
		"desc": "One-time harder objectives with great rewards",
		"refresh": "Never",
		"color": Color(1.0, 0.84, 0.0)
	}
]

# Daily quest examples
const DAILY_QUESTS: Array[Dictionary] = [
	{"name": "Monster Slayer", "obj": "Defeat 10 enemies", "gold": 25, "xp": 20},
	{"name": "Monster Hunter", "obj": "Defeat 25 enemies", "gold": 50, "xp": 40},
	{"name": "Combo Starter", "obj": "Reach 10 combo", "gold": 30, "xp": 25},
	{"name": "Combo Master", "obj": "Reach 20 combo", "gold": 60, "xp": 50},
	{"name": "Wave Survivor", "obj": "Complete 3 waves", "gold": 20, "xp": 15},
	{"name": "Wave Champion", "obj": "Complete 5 waves", "gold": 40, "xp": 30},
	{"name": "Precision Typer", "obj": "90%+ accuracy in a wave", "gold": 35, "xp": 30},
	{"name": "Untouchable", "obj": "No damage taken in a wave", "gold": 50, "xp": 40},
	{"name": "Gold Collector", "obj": "Earn 100 gold", "gold": 25, "xp": 20},
	{"name": "Wordsmith", "obj": "Type 50 words correctly", "gold": 30, "xp": 25},
	{"name": "Boss Slayer", "obj": "Defeat a boss", "gold": 75, "xp": 60},
	{"name": "Spellcaster", "obj": "Use 3 special commands", "gold": 40, "xp": 35}
]

# Weekly quest examples
const WEEKLY_QUESTS: Array[Dictionary] = [
	{"name": "Weekly Warrior", "obj": "Defeat 100 enemies", "gold": 200, "xp": 150, "item": "potion"},
	{"name": "Combo Legend", "obj": "Reach 50 combo", "gold": 300, "xp": 200, "item": "scroll"},
	{"name": "Dedicated Defender", "obj": "Survive 5 days", "gold": 250, "xp": 175, "item": ""},
	{"name": "Perfect Week", "obj": "10 waves at 95%+", "gold": 400, "xp": 300, "item": "scroll"},
	{"name": "Boss Hunter", "obj": "Defeat 3 bosses", "gold": 350, "xp": 250, "item": "potion"},
	{"name": "Treasure Hoarder", "obj": "Earn 500 gold total", "gold": 150, "xp": 100, "item": ""}
]

# Challenge quests
const CHALLENGE_QUESTS: Array[Dictionary] = [
	{"name": "Legendary Combo", "obj": "Reach 100 combo", "gold": 500, "xp": 400, "item": "ring_combo"},
	{"name": "Invincible", "obj": "Complete a day without damage", "gold": 750, "xp": 500, "item": "cape_shadow"},
	{"name": "Speed Demon", "obj": "Complete a wave in <30 sec", "gold": 400, "xp": 300, "item": "boots_swift"},
	{"name": "Veteran Defender", "obj": "Defeat 1000 enemies total", "gold": 1000, "xp": 750, "item": "amulet_power"},
	{"name": "Endurance Test", "obj": "Survive to day 20", "gold": 800, "xp": 600, "item": "armor_chain"}
]

# Objective types
const OBJECTIVE_TYPES: Array[Dictionary] = [
	{"type": "kills", "name": "Enemy Kills", "desc": "Defeat a certain number of enemies", "color": Color(0.96, 0.26, 0.21)},
	{"type": "max_combo", "name": "Max Combo", "desc": "Reach a specific combo streak", "color": Color(1.0, 0.6, 0.2)},
	{"type": "waves", "name": "Waves Completed", "desc": "Complete a number of defense waves", "color": Color(0.4, 0.8, 1.0)},
	{"type": "accuracy", "name": "Accuracy", "desc": "Finish a wave with high accuracy", "color": Color(0.4, 1.0, 0.4)},
	{"type": "no_damage", "name": "No Damage", "desc": "Complete wave/day without taking damage", "color": Color(0.8, 0.6, 1.0)},
	{"type": "gold_earned", "name": "Gold Earned", "desc": "Earn a certain amount of gold", "color": Color(1.0, 0.84, 0.0)},
	{"type": "words_typed", "name": "Words Typed", "desc": "Type words correctly", "color": Color(0.6, 0.8, 1.0)},
	{"type": "boss_kills", "name": "Boss Kills", "desc": "Defeat boss enemies", "color": Color(0.8, 0.2, 0.2)},
	{"type": "spells_used", "name": "Spells Used", "desc": "Use special commands in combat", "color": Color(0.6, 0.4, 1.0)}
]

# Tips
const QUEST_TIPS: Array[String] = [
	"Daily quests refresh at midnight - complete them for easy rewards",
	"Weekly quests have larger rewards but take more effort",
	"Challenge quests can only be completed once but give unique items",
	"Some quests reward items in addition to gold and XP",
	"Progress toward quests is tracked automatically during gameplay"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(560, 720)

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
	title.text = "QUESTS"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.8, 0.6, 1.0))
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
	subtitle.text = "23 total quests: 12 daily, 6 weekly, 5 challenge"
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
	footer.text = "Complete quests for gold, XP, and items"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_quests_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Quest types overview
	_build_types_section()

	# Daily quests
	_build_quest_list_section("DAILY QUESTS (12)", Color(0.4, 0.8, 1.0), DAILY_QUESTS)

	# Weekly quests
	_build_quest_list_section("WEEKLY QUESTS (6)", Color(0.8, 0.6, 1.0), WEEKLY_QUESTS)

	# Challenge quests
	_build_quest_list_section("CHALLENGE QUESTS (5)", Color(1.0, 0.84, 0.0), CHALLENGE_QUESTS)

	# Objective types
	_build_objectives_section()

	# Tips
	_build_tips_section()


func _build_types_section() -> void:
	var section := _create_section_panel("QUEST TYPES", Color(0.5, 0.6, 0.8))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for quest_type in QUEST_TYPES:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(quest_type.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", quest_type.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(110, 0)
		hbox.add_child(name_label)

		var refresh_label := Label.new()
		refresh_label.text = "[%s]" % quest_type.get("refresh", "")
		refresh_label.add_theme_font_size_override("font_size", 9)
		refresh_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		refresh_label.custom_minimum_size = Vector2(60, 0)
		hbox.add_child(refresh_label)

		var desc_label := Label.new()
		desc_label.text = str(quest_type.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_quest_list_section(title: String, color: Color, quests: Array[Dictionary]) -> void:
	var section := _create_section_panel(title, color)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Create two-column layout
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 3)
	vbox.add_child(grid)

	for quest in quests:
		var container := HBoxContainer.new()
		container.add_theme_constant_override("separation", 5)
		container.custom_minimum_size = Vector2(240, 0)
		grid.add_child(container)

		var name_label := Label.new()
		name_label.text = str(quest.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 9)
		name_label.add_theme_color_override("font_color", color.lightened(0.2))
		name_label.custom_minimum_size = Vector2(100, 0)
		container.add_child(name_label)

		var reward_label := Label.new()
		var reward_text: String = "%dg %dxp" % [quest.get("gold", 0), quest.get("xp", 0)]
		var item: String = str(quest.get("item", ""))
		if not item.is_empty():
			reward_text += " +item"
		reward_label.text = reward_text
		reward_label.add_theme_font_size_override("font_size", 8)
		reward_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		container.add_child(reward_label)


func _build_objectives_section() -> void:
	var section := _create_section_panel("OBJECTIVE TYPES", Color(0.5, 0.7, 0.6))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Two-column layout
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 15)
	grid.add_theme_constant_override("v_separation", 3)
	vbox.add_child(grid)

	for obj in OBJECTIVE_TYPES:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 5)
		hbox.custom_minimum_size = Vector2(230, 0)
		grid.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(obj.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 9)
		name_label.add_theme_color_override("font_color", obj.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(85, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(obj.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 8)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("QUEST TIPS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in QUEST_TIPS:
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
