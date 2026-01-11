class_name TowerTypesReferencePanel
extends PanelContainer
## Tower Types Reference Panel - Shows all tower types with stats and abilities

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Tower categories
const TOWER_CATEGORIES: Array[Dictionary] = [
	{
		"name": "Basic",
		"desc": "Available from tutorial",
		"unlock": "Tutorial",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"name": "Advanced",
		"desc": "Unlock at level 10+",
		"unlock": "Level 10",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"name": "Specialist",
		"desc": "Unlock at level 18+",
		"unlock": "Level 18",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"name": "Legendary",
		"desc": "Quest/achievement unlock, limited to 1 per game",
		"unlock": "Quest/Achievement",
		"color": Color(0.9, 0.5, 0.9)
	}
]

# Basic towers
const BASIC_TOWERS: Array[Dictionary] = [
	{
		"id": "tower_arrow",
		"name": "Arrow Tower",
		"damage": 10,
		"range": 4,
		"speed": "1.0",
		"damage_type": "Physical",
		"target": "Single",
		"special": "Standard ranged attack",
		"cost": "4 wood, 8 stone",
		"color": Color(0.7, 0.6, 0.5)
	},
	{
		"id": "tower_magic",
		"name": "Magic Tower",
		"damage": 15,
		"range": 5,
		"speed": "0.7",
		"damage_type": "Magical",
		"target": "Single",
		"special": "Ignores armor",
		"cost": "6 wood, 10 stone, 10 gold",
		"color": Color(0.6, 0.4, 0.9)
	},
	{
		"id": "tower_frost",
		"name": "Frost Tower",
		"damage": 5,
		"range": 3,
		"speed": "0.8",
		"damage_type": "Cold",
		"target": "Single",
		"special": "25% slow for 2s",
		"cost": "5 wood, 8 stone",
		"color": Color(0.53, 0.81, 0.92)
	},
	{
		"id": "tower_cannon",
		"name": "Cannon Tower",
		"damage": 25,
		"range": 4,
		"speed": "0.4",
		"damage_type": "Physical",
		"target": "AOE (1 tile)",
		"special": "Splash damage, 2x2 footprint",
		"cost": "8 wood, 15 stone, 15 gold",
		"color": Color(0.5, 0.5, 0.5)
	}
]

# Advanced towers
const ADVANCED_TOWERS: Array[Dictionary] = [
	{
		"id": "tower_multi",
		"name": "Multi-Shot Tower",
		"damage": 8,
		"range": 4,
		"speed": "0.8",
		"damage_type": "Physical",
		"target": "Multi (3)",
		"special": "Hits 3 targets simultaneously",
		"cost": "10 wood, 15 stone, 50 gold",
		"color": Color(0.8, 0.6, 0.4)
	},
	{
		"id": "tower_arcane",
		"name": "Arcane Tower",
		"damage": 20,
		"range": 5,
		"speed": "0.6",
		"damage_type": "Magical",
		"target": "Single",
		"special": "Damage scales with accuracy",
		"cost": "8 wood, 12 stone, 75 gold",
		"color": Color(0.4, 0.2, 0.8)
	},
	{
		"id": "tower_holy",
		"name": "Holy Tower",
		"damage": 18,
		"range": 4,
		"speed": "0.7",
		"damage_type": "Holy",
		"target": "Single",
		"special": "5% affix purify, +50% vs corrupted",
		"cost": "20 stone, 100 gold",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"id": "tower_siege",
		"name": "Siege Tower",
		"damage": 100,
		"range": 6,
		"speed": "0.15",
		"damage_type": "Physical",
		"target": "Single",
		"special": "Charges 5s, +10%/word typed (max 2x)",
		"cost": "15 wood, 25 stone, 125 gold",
		"color": Color(0.4, 0.4, 0.4)
	}
]

# Specialist towers
const SPECIALIST_TOWERS: Array[Dictionary] = [
	{
		"id": "tower_poison",
		"name": "Venomspire",
		"damage": 3,
		"range": 4,
		"speed": "1.2",
		"damage_type": "Poison",
		"target": "Single",
		"special": "5 DoT/tick for 5s, stacks 10x",
		"cost": "10 wood, 15 stone, 100 gold",
		"color": Color(0.6, 0.2, 0.8)
	},
	{
		"id": "tower_tesla",
		"name": "Tesla Coil",
		"damage": 12,
		"range": 3,
		"speed": "0.5",
		"damage_type": "Lightning",
		"target": "Chain (5)",
		"special": "Chains 5 targets, 80% falloff",
		"cost": "8 wood, 20 stone, 110 gold",
		"color": Color(0.8, 0.8, 0.2)
	},
	{
		"id": "tower_summoner",
		"name": "Summoning Circle",
		"damage": 0,
		"range": 0,
		"speed": "-",
		"damage_type": "Physical",
		"target": "Summon",
		"special": "Spawns up to 3 allied units",
		"cost": "25 stone, 150 gold",
		"color": Color(0.7, 0.5, 0.9)
	},
	{
		"id": "tower_support",
		"name": "Command Post",
		"damage": 0,
		"range": 0,
		"speed": "-",
		"damage_type": "-",
		"target": "Aura (3)",
		"special": "+15% damage, +10% speed to nearby towers",
		"cost": "12 wood, 18 stone, 120 gold",
		"color": Color(0.4, 0.8, 0.4)
	},
	{
		"id": "tower_trap",
		"name": "Trap Nexus",
		"damage": 30,
		"range": 5,
		"speed": "-",
		"damage_type": "Physical",
		"target": "Trap",
		"special": "Places 3 traps, 10s recharge",
		"cost": "10 wood, 12 stone, 90 gold",
		"color": Color(0.8, 0.4, 0.2)
	}
]

# Legendary towers
const LEGENDARY_TOWERS: Array[Dictionary] = [
	{
		"id": "tower_legendary_wordsmith",
		"name": "Wordsmith's Forge",
		"damage": 25,
		"range": 5,
		"speed": "1.0",
		"damage_type": "Pure",
		"target": "Adaptive",
		"special": "WPM scaling, 50-word forge (200 dmg), 10 perfect strike (500 dmg)",
		"cost": "30 wood, 50 stone, 500 gold",
		"color": Color(1.0, 0.5, 0.0)
	},
	{
		"id": "tower_legendary_shrine",
		"name": "Letter Spirit Shrine",
		"damage": 50,
		"range": 6,
		"speed": "0.5",
		"damage_type": "Holy",
		"target": "Adaptive",
		"special": "+5%/unique letter (max +130%), 3 spirit modes",
		"cost": "60 stone, 600 gold",
		"color": Color(0.8, 0.6, 1.0)
	},
	{
		"id": "tower_legendary_purifier",
		"name": "Corruption Purifier",
		"damage": 40,
		"range": 5,
		"speed": "0.6",
		"damage_type": "Holy",
		"target": "Single",
		"special": "25% purify, +100% vs corrupted, type 'CORRUPTION END' for 500 dmg",
		"cost": "45 stone, 750 gold",
		"color": Color(0.9, 0.9, 0.5)
	}
]

# Damage types
const DAMAGE_TYPES: Array[Dictionary] = [
	{"name": "Physical", "desc": "Reduced by armor", "color": Color(0.7, 0.6, 0.5)},
	{"name": "Magical", "desc": "Ignores armor", "color": Color(0.6, 0.4, 0.9)},
	{"name": "Cold", "desc": "Slows, reduced damage", "color": Color(0.53, 0.81, 0.92)},
	{"name": "Poison", "desc": "DoT, stacks, ignores half armor", "color": Color(0.6, 0.2, 0.8)},
	{"name": "Lightning", "desc": "Chains, bonus vs wet", "color": Color(0.8, 0.8, 0.2)},
	{"name": "Holy", "desc": "Bonus vs affixed/corrupted", "color": Color(1.0, 0.84, 0.0)},
	{"name": "Fire", "desc": "DoT, bonus vs frozen", "color": Color(1.0, 0.27, 0.0)},
	{"name": "Pure", "desc": "Ignores all resistances", "color": Color(1.0, 1.0, 1.0)}
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(560, 640)

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
	title.text = "TOWER TYPES"
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
	subtitle.text = "16 tower types across 4 categories"
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
	footer.text = "Type 'build [tower]' during planning phase"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_tower_types_reference() -> void:
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

	# Basic towers
	_build_tower_section("BASIC TOWERS", Color(0.5, 0.8, 0.3), BASIC_TOWERS)

	# Advanced towers
	_build_tower_section("ADVANCED TOWERS", Color(0.4, 0.8, 1.0), ADVANCED_TOWERS)

	# Specialist towers
	_build_tower_section("SPECIALIST TOWERS", Color(0.9, 0.6, 0.3), SPECIALIST_TOWERS)

	# Legendary towers
	_build_tower_section("LEGENDARY TOWERS", Color(0.9, 0.5, 0.9), LEGENDARY_TOWERS)

	# Damage types reference
	_build_damage_types_section()


func _build_categories_section() -> void:
	var section := _create_section_panel("CATEGORIES", Color(0.6, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for cat in TOWER_CATEGORIES:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(cat.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", cat.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(70, 0)
		hbox.add_child(name_label)

		var unlock_label := Label.new()
		unlock_label.text = "[%s]" % cat.get("unlock", "")
		unlock_label.add_theme_font_size_override("font_size", 9)
		unlock_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
		unlock_label.custom_minimum_size = Vector2(100, 0)
		hbox.add_child(unlock_label)

		var desc_label := Label.new()
		desc_label.text = str(cat.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_tower_section(title: String, color: Color, towers: Array[Dictionary]) -> void:
	var section := _create_section_panel(title, color)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tower in towers:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 1)
		vbox.add_child(container)

		# Tower name and damage type
		var header_hbox := HBoxContainer.new()
		header_hbox.add_theme_constant_override("separation", 8)
		container.add_child(header_hbox)

		var name_label := Label.new()
		name_label.text = str(tower.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", tower.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(130, 0)
		header_hbox.add_child(name_label)

		var dmg_type_label := Label.new()
		dmg_type_label.text = "[%s]" % tower.get("damage_type", "")
		dmg_type_label.add_theme_font_size_override("font_size", 9)
		dmg_type_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		header_hbox.add_child(dmg_type_label)

		# Stats row
		var stats_hbox := HBoxContainer.new()
		stats_hbox.add_theme_constant_override("separation", 12)
		container.add_child(stats_hbox)

		var damage_val: String = str(tower.get("damage", 0))
		if damage_val == "0":
			damage_val = "-"
		_add_stat_label(stats_hbox, "DMG", damage_val, Color(0.9, 0.4, 0.4))

		_add_stat_label(stats_hbox, "RNG", str(tower.get("range", 0)), Color(0.4, 0.8, 1.0))
		_add_stat_label(stats_hbox, "SPD", str(tower.get("speed", "")), Color(0.9, 0.6, 0.3))
		_add_stat_label(stats_hbox, "TGT", str(tower.get("target", "")), Color(0.7, 0.5, 0.9))

		# Special ability
		var special_label := Label.new()
		special_label.text = "  " + str(tower.get("special", ""))
		special_label.add_theme_font_size_override("font_size", 9)
		special_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		special_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		container.add_child(special_label)

		# Cost
		var cost_label := Label.new()
		cost_label.text = "  Cost: " + str(tower.get("cost", ""))
		cost_label.add_theme_font_size_override("font_size", 9)
		cost_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		container.add_child(cost_label)


func _add_stat_label(parent: Control, label: String, value: String, color: Color) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 2)
	parent.add_child(hbox)

	var label_node := Label.new()
	label_node.text = label + ":"
	label_node.add_theme_font_size_override("font_size", 9)
	label_node.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	hbox.add_child(label_node)

	var value_node := Label.new()
	value_node.text = value
	value_node.add_theme_font_size_override("font_size", 9)
	value_node.add_theme_color_override("font_color", color)
	hbox.add_child(value_node)


func _build_damage_types_section() -> void:
	var section := _create_section_panel("DAMAGE TYPES", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 3)
	vbox.add_child(grid)

	for dmg_type in DAMAGE_TYPES:
		var name_label := Label.new()
		name_label.text = str(dmg_type.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 9)
		name_label.add_theme_color_override("font_color", dmg_type.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(70, 0)
		grid.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(dmg_type.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		grid.add_child(desc_label)


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
