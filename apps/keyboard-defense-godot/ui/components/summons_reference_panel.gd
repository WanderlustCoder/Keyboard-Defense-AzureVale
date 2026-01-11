class_name SummonsReferencePanel
extends PanelContainer
## Summons Reference Panel - Shows summoned unit types and mechanics

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Summon types (from SimTowerTypes)
const SUMMON_TYPES: Array[Dictionary] = [
	{
		"id": "word_warrior",
		"name": "Word Warrior",
		"hp": 50,
		"damage": 8,
		"attack_speed": 1.0,
		"movement_speed": 1,
		"range": 1,
		"special": "",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"id": "letter_sprite",
		"name": "Letter Sprite",
		"hp": 25,
		"damage": 15,
		"attack_speed": 1.5,
		"movement_speed": 2,
		"range": 2,
		"special": "Flying",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"id": "grammar_golem",
		"name": "Grammar Golem",
		"hp": 150,
		"damage": 20,
		"attack_speed": 0.5,
		"movement_speed": 1,
		"range": 1,
		"special": "Taunt",
		"color": Color(0.7, 0.5, 0.9)
	}
]

# Summon mechanics
const SUMMON_MECHANICS: Array[Dictionary] = [
	{
		"topic": "Spawning",
		"desc": "Summoner Towers create summons that fight enemies",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"topic": "Max Summons",
		"desc": "Each tower can have up to 3 active summons",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"topic": "Duration",
		"desc": "Summons last 30 seconds before expiring",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"topic": "Combat",
		"desc": "Summons attack enemies automatically in range",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"topic": "Scaling",
		"desc": "Summon stats increase with tower level",
		"color": Color(0.7, 0.5, 0.9)
	}
]

# Special abilities
const SPECIAL_ABILITIES: Array[Dictionary] = [
	{
		"name": "Flying",
		"desc": "Can move over obstacles and has longer range",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"name": "Taunt",
		"desc": "Forces nearby enemies to target this summon",
		"color": Color(0.7, 0.5, 0.9)
	},
	{
		"name": "AoE",
		"desc": "Attacks damage all enemies in an area",
		"color": Color(0.9, 0.4, 0.4)
	}
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(500, 540)

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
	title.text = "SUMMONED UNITS"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.7, 0.5, 0.9))
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
	subtitle.text = "Allied units created by Summoner Towers"
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
	footer.text = "Build Summoner Towers to call allies to your defense!"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_summons_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Mechanics section
	_build_mechanics_section()

	# Summon types section
	_build_summon_types_section()

	# Special abilities section
	_build_abilities_section()


func _build_mechanics_section() -> void:
	var section := _create_section_panel("HOW SUMMONS WORK", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in SUMMON_MECHANICS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var topic_label := Label.new()
		topic_label.text = str(info.get("topic", ""))
		topic_label.add_theme_font_size_override("font_size", 10)
		topic_label.add_theme_color_override("font_color", info.get("color", Color.WHITE))
		topic_label.custom_minimum_size = Vector2(90, 0)
		hbox.add_child(topic_label)

		var desc_label := Label.new()
		desc_label.text = str(info.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_summon_types_section() -> void:
	var section := _create_section_panel("SUMMON TYPES", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for summon in SUMMON_TYPES:
		var card := _create_summon_card(summon)
		vbox.add_child(card)


func _create_summon_card(summon: Dictionary) -> Control:
	var name: String = str(summon.get("name", ""))
	var hp: int = int(summon.get("hp", 0))
	var damage: int = int(summon.get("damage", 0))
	var attack_speed: float = float(summon.get("attack_speed", 1.0))
	var movement: int = int(summon.get("movement_speed", 1))
	var range_val: int = int(summon.get("range", 1))
	var special: String = str(summon.get("special", ""))
	var color: Color = summon.get("color", Color.WHITE)

	var container := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = color.darkened(0.8)
	card_style.border_color = color.darkened(0.5)
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(4)
	card_style.set_content_margin_all(8)
	container.add_theme_stylebox_override("panel", card_style)

	var card_vbox := VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 4)
	container.add_child(card_vbox)

	# Name row
	var name_row := HBoxContainer.new()
	card_vbox.add_child(name_row)

	var name_label := Label.new()
	name_label.text = name
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", color)
	name_row.add_child(name_label)

	if not special.is_empty():
		var special_label := Label.new()
		special_label.text = " [%s]" % special
		special_label.add_theme_font_size_override("font_size", 10)
		special_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		name_row.add_child(special_label)

	# Stats row
	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 15)
	card_vbox.add_child(stats_row)

	var hp_label := Label.new()
	hp_label.text = "%d HP" % hp
	hp_label.add_theme_font_size_override("font_size", 10)
	hp_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	stats_row.add_child(hp_label)

	var dmg_label := Label.new()
	dmg_label.text = "%d DMG" % damage
	dmg_label.add_theme_font_size_override("font_size", 10)
	dmg_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
	stats_row.add_child(dmg_label)

	var speed_label := Label.new()
	speed_label.text = "%.1f/s" % attack_speed
	speed_label.add_theme_font_size_override("font_size", 10)
	speed_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	stats_row.add_child(speed_label)

	var range_label := Label.new()
	range_label.text = "R:%d" % range_val
	range_label.add_theme_font_size_override("font_size", 10)
	range_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	stats_row.add_child(range_label)

	return container


func _build_abilities_section() -> void:
	var section := _create_section_panel("SPECIAL ABILITIES", Color(0.4, 0.9, 0.4))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for ability in SPECIAL_ABILITIES:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(ability.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", ability.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(70, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(ability.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


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
