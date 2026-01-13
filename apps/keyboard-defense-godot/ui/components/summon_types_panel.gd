class_name SummonTypesPanel
extends PanelContainer
## Summon Types Panel - Shows summoned unit types and their abilities.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Summon type data (from SimSummonedUnits/SimTowerTypes)
const SUMMON_TYPES: Array[Dictionary] = [
	{
		"type": "skeleton",
		"name": "Skeleton Warrior",
		"description": "Basic melee summon that attacks nearby enemies",
		"color": Color(0.7, 0.7, 0.6),
		"stats": {"hp": 50, "damage": 8, "duration": 30},
		"abilities": []
	},
	{
		"type": "ghost",
		"name": "Spectral Shade",
		"description": "Flying summon that ignores terrain",
		"color": Color(0.6, 0.8, 0.9),
		"stats": {"hp": 30, "damage": 6, "duration": 25},
		"abilities": ["Flying"]
	},
	{
		"type": "golem",
		"name": "Stone Golem",
		"description": "Tanky summon with taunt to draw enemy attacks",
		"color": Color(0.6, 0.5, 0.4),
		"stats": {"hp": 120, "damage": 5, "duration": 40},
		"abilities": ["Taunt"]
	},
	{
		"type": "imp",
		"name": "Fire Imp",
		"description": "Fast attacker with area damage",
		"color": Color(0.9, 0.4, 0.2),
		"stats": {"hp": 25, "damage": 12, "duration": 20},
		"abilities": ["AoE Attack"]
	},
	{
		"type": "wraith",
		"name": "Shadow Wraith",
		"description": "Ethereal summon with life drain",
		"color": Color(0.4, 0.3, 0.5),
		"stats": {"hp": 40, "damage": 10, "duration": 30},
		"abilities": ["Flying", "Life Drain"]
	}
]

# Summon system info
const SUMMON_INFO: Array[Dictionary] = [
	{
		"topic": "Max Summons",
		"description": "3 summons per Summoner tower (5 with Legion synergy)",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"topic": "Duration",
		"description": "Summons fade after their duration expires",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"topic": "Tower Level",
		"description": "Higher level = +10 HP, +2 damage per level",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"topic": "Legion Synergy",
		"description": "+2 max summons, +20% damage for all summons",
		"color": Color(0.7, 0.5, 0.9)
	}
]

# Summon abilities
const SUMMON_ABILITIES: Array[Dictionary] = [
	{
		"ability": "Flying",
		"effect": "Ignores terrain, can pass over obstacles",
		"color": Color(0.6, 0.8, 0.9)
	},
	{
		"ability": "Taunt",
		"effect": "Forces nearby enemies to attack this summon",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"ability": "AoE Attack",
		"effect": "Attacks hit all enemies in a small radius",
		"color": Color(0.9, 0.4, 0.2)
	},
	{
		"ability": "Life Drain",
		"effect": "Heals when dealing damage to enemies",
		"color": Color(0.4, 0.8, 0.4)
	}
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 620)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "SUMMONED UNITS"
	DesignSystem.style_label(title, "h2", Color(0.7, 0.5, 0.9))
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
	subtitle.text = "Creatures summoned by Summoner towers to fight enemies"
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
	footer.text = "Build Summoner towers to call these allies"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_summon_types() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Summon types section
	_build_types_section()

	# Abilities section
	_build_abilities_section()

	# Info section
	_build_info_section()


func _build_types_section() -> void:
	var section := _create_section_panel("SUMMON TYPES", Color(0.7, 0.5, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for summon_type in SUMMON_TYPES:
		var card := _create_type_card(summon_type)
		vbox.add_child(card)


func _create_type_card(summon_type: Dictionary) -> Control:
	var name_str: String = str(summon_type.get("name", ""))
	var description: String = str(summon_type.get("description", ""))
	var color: Color = summon_type.get("color", Color.WHITE)
	var stats: Dictionary = summon_type.get("stats", {})
	var abilities: Array = summon_type.get("abilities", [])

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = color.darkened(0.85)
	container_style.border_color = color.darkened(0.6)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(8)
	container.add_theme_stylebox_override("panel", container_style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 3)
	container.add_child(main_vbox)

	# Name
	var name_label := Label.new()
	name_label.text = name_str
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", color)
	main_vbox.add_child(name_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 9)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	main_vbox.add_child(desc_label)

	# Stats row
	var stats_hbox := HBoxContainer.new()
	stats_hbox.add_theme_constant_override("separation", 15)
	main_vbox.add_child(stats_hbox)

	var hp: int = int(stats.get("hp", 0))
	var damage: int = int(stats.get("damage", 0))
	var duration: int = int(stats.get("duration", 0))

	var hp_label := Label.new()
	hp_label.text = "HP: %d" % hp
	hp_label.add_theme_font_size_override("font_size", 9)
	hp_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.3))
	stats_hbox.add_child(hp_label)

	var dmg_label := Label.new()
	dmg_label.text = "DMG: %d" % damage
	dmg_label.add_theme_font_size_override("font_size", 9)
	dmg_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
	stats_hbox.add_child(dmg_label)

	var dur_label := Label.new()
	dur_label.text = "Duration: %ds" % duration
	dur_label.add_theme_font_size_override("font_size", 9)
	dur_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	stats_hbox.add_child(dur_label)

	# Abilities
	if not abilities.is_empty():
		var ability_label := Label.new()
		ability_label.text = "Abilities: " + ", ".join(abilities)
		ability_label.add_theme_font_size_override("font_size", 9)
		ability_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3))
		main_vbox.add_child(ability_label)

	return container


func _build_abilities_section() -> void:
	var section := _create_section_panel("SUMMON ABILITIES", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for ability_info in SUMMON_ABILITIES:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var ability: String = str(ability_info.get("ability", ""))
		var effect: String = str(ability_info.get("effect", ""))
		var color: Color = ability_info.get("color", Color.WHITE)

		var ability_label := Label.new()
		ability_label.text = ability
		ability_label.add_theme_font_size_override("font_size", 10)
		ability_label.add_theme_color_override("font_color", color)
		ability_label.custom_minimum_size = Vector2(90, 0)
		hbox.add_child(ability_label)

		var effect_label := Label.new()
		effect_label.text = effect
		effect_label.add_theme_font_size_override("font_size", 10)
		effect_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(effect_label)


func _build_info_section() -> void:
	var section := _create_section_panel("SUMMON MECHANICS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in SUMMON_INFO:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var topic: String = str(info.get("topic", ""))
		var description: String = str(info.get("description", ""))
		var color: Color = info.get("color", Color.WHITE)

		var topic_label := Label.new()
		topic_label.text = topic
		topic_label.add_theme_font_size_override("font_size", 10)
		topic_label.add_theme_color_override("font_color", color)
		topic_label.custom_minimum_size = Vector2(100, 0)
		hbox.add_child(topic_label)

		var desc_label := Label.new()
		desc_label.text = description
		desc_label.add_theme_font_size_override("font_size", 10)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


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
