class_name BuildingTypesReferencePanel
extends PanelContainer
## Building Types Reference Panel - Shows all building types with costs and effects.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Building categories
const BUILDING_CATEGORIES: Array[Dictionary] = [
	{
		"name": "Production",
		"desc": "Generate resources each day",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"name": "Defense",
		"desc": "Protect against enemies",
		"color": Color(0.6, 0.6, 0.6)
	},
	{
		"name": "Economy",
		"desc": "Generate gold income",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"name": "Military",
		"desc": "Combat support buildings",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"name": "Support",
		"desc": "Special effect buildings",
		"color": Color(0.7, 0.5, 0.9)
	},
	{
		"name": "Auto Defense",
		"desc": "Automatic attack towers",
		"color": Color(0.4, 0.8, 1.0)
	}
]

# Production buildings
const PRODUCTION_BUILDINGS: Array[Dictionary] = [
	{
		"id": "farm",
		"name": "Farm",
		"cost": "10 wood",
		"production": "+3 food/day",
		"workers": 1,
		"special": "+1 food if adjacent to water",
		"upgrades": "Lv2: +5 food, 2 workers | Lv3: +8 food, 3 workers",
		"color": Color(0.4, 0.7, 0.3)
	},
	{
		"id": "lumber",
		"name": "Lumber Mill",
		"cost": "5 wood, 2 food",
		"production": "+3 wood/day",
		"workers": 1,
		"special": "+1 wood if adjacent to forest",
		"upgrades": "Lv2: +5 wood, 2 workers | Lv3: +8 wood, 3 workers",
		"color": Color(0.6, 0.4, 0.2)
	},
	{
		"id": "quarry",
		"name": "Quarry",
		"cost": "5 wood, 2 food",
		"production": "+3 stone/day",
		"workers": 1,
		"special": "+1 stone if adjacent to mountain",
		"upgrades": "Lv2: +5 stone, 2 workers | Lv3: +8 stone, 3 workers",
		"color": Color(0.5, 0.5, 0.5)
	}
]

# Defense buildings
const DEFENSE_BUILDINGS: Array[Dictionary] = [
	{
		"id": "wall",
		"name": "Wall",
		"cost": "4 wood, 4 stone",
		"production": "-",
		"defense": 1,
		"workers": 0,
		"special": "Blocks enemy movement",
		"upgrades": "Lv2: +2 def, 20% slow | Lv3: +3 def, 30% slow, thorns",
		"color": Color(0.5, 0.5, 0.6)
	},
	{
		"id": "tower",
		"name": "Tower",
		"cost": "4 wood, 8 stone",
		"production": "-",
		"defense": 2,
		"workers": 0,
		"special": "+1 defense if adjacent to wall",
		"upgrades": "Lv2: rng 4, dmg 2, 2 shots | Lv3: rng 5, dmg 3, 15% slow",
		"color": Color(0.6, 0.6, 0.7)
	}
]

# Economy buildings
const ECONOMY_BUILDINGS: Array[Dictionary] = [
	{
		"id": "market",
		"name": "Market",
		"cost": "8 wood, 5 stone",
		"production": "+5 gold/day",
		"workers": 1,
		"special": "Enables trading at Lv3",
		"upgrades": "Lv2: +8g, +2g/adj bld | Lv3: +12g, +3g/adj, trade",
		"color": Color(1.0, 0.84, 0.0)
	}
]

# Military buildings
const MILITARY_BUILDINGS: Array[Dictionary] = [
	{
		"id": "barracks",
		"name": "Barracks",
		"cost": "10 wood, 8 stone",
		"production": "-",
		"defense": 1,
		"workers": 2,
		"special": "Combat training for workers",
		"upgrades": "Lv2: +10% typing, 3 workers | Lv3: +20% typing, +15% combo",
		"color": Color(0.9, 0.4, 0.4)
	}
]

# Support buildings
const SUPPORT_BUILDINGS: Array[Dictionary] = [
	{
		"id": "temple",
		"name": "Temple",
		"cost": "15 stone, 20 gold",
		"production": "-",
		"workers": 1,
		"special": "+1 HP healed after each wave",
		"upgrades": "Lv2: +2 heal, +10% morale | Lv3: +3 heal, +20% morale, +2 castle HP",
		"color": Color(1.0, 0.9, 0.5)
	},
	{
		"id": "workshop",
		"name": "Workshop",
		"cost": "12 wood, 6 stone",
		"production": "-",
		"workers": 2,
		"special": "-10% build costs",
		"upgrades": "Lv2: -15% build, -10% upgrade | Lv3: -20% build, -15% upgrade, +1 tower dmg",
		"color": Color(0.7, 0.5, 0.3)
	}
]

# Auto-defense buildings
const AUTO_DEFENSE_BUILDINGS: Array[Dictionary] = [
	{
		"id": "sentry",
		"name": "Sentry",
		"cost": "6 wood, 10 stone, 30 gold",
		"production": "-",
		"defense": 1,
		"workers": 0,
		"special": "Auto-attacks: 3 dmg, 3 range, 1.5s CD, nearest target",
		"color": Color(0.4, 0.6, 0.8)
	},
	{
		"id": "spark",
		"name": "Spark Tower",
		"cost": "4 wood, 8 stone, 50 gold",
		"production": "-",
		"defense": 0,
		"workers": 0,
		"special": "Auto-attacks: 2 dmg, 2 range AOE (radius 2), 2s CD",
		"color": Color(0.8, 0.8, 0.2)
	},
	{
		"id": "flame",
		"name": "Flame Spire",
		"cost": "8 wood, 6 stone, 60 gold",
		"production": "-",
		"defense": 0,
		"workers": 0,
		"special": "Auto-attacks: 4 dmg, 2 range, 0.8s CD, applies burn",
		"color": Color(1.0, 0.4, 0.2)
	}
]

# Terrain bonuses
const TERRAIN_BONUSES: Array[Dictionary] = [
	{
		"building": "Farm",
		"terrain": "Water (adjacent)",
		"bonus": "+1 food/day",
		"color": Color(0.4, 0.7, 1.0)
	},
	{
		"building": "Lumber Mill",
		"terrain": "Forest (adjacent)",
		"bonus": "+1 wood/day",
		"color": Color(0.3, 0.6, 0.3)
	},
	{
		"building": "Quarry",
		"terrain": "Mountain (adjacent)",
		"bonus": "+1 stone/day",
		"color": Color(0.5, 0.5, 0.5)
	},
	{
		"building": "Tower",
		"terrain": "Wall (adjacent)",
		"bonus": "+1 defense",
		"color": Color(0.6, 0.6, 0.7)
	}
]

# Building tips
const BUILDING_TIPS: Array[String] = [
	"Place production buildings adjacent to matching terrain for bonuses",
	"Walls can create chokepoints to funnel enemies",
	"Towers next to walls gain +1 defense",
	"Markets at Lv3 enable trading resources for gold",
	"Workshop reduces costs for all construction",
	"Auto-defense towers attack automatically during waves"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 640)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "BUILDING TYPES"
	DesignSystem.style_label(title, "h2", Color(0.6, 0.4, 0.2))
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
	subtitle.text = "12 building types across 6 categories"
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
	footer.text = "Type 'build [name]' during planning phase"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_building_types_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Production buildings
	_build_buildings_section("PRODUCTION", Color(0.5, 0.8, 0.3), PRODUCTION_BUILDINGS)

	# Defense buildings
	_build_buildings_section("DEFENSE", Color(0.6, 0.6, 0.6), DEFENSE_BUILDINGS)

	# Economy buildings
	_build_buildings_section("ECONOMY", Color(1.0, 0.84, 0.0), ECONOMY_BUILDINGS)

	# Military buildings
	_build_buildings_section("MILITARY", Color(0.9, 0.4, 0.4), MILITARY_BUILDINGS)

	# Support buildings
	_build_buildings_section("SUPPORT", Color(0.7, 0.5, 0.9), SUPPORT_BUILDINGS)

	# Auto-defense buildings
	_build_buildings_section("AUTO-DEFENSE", Color(0.4, 0.8, 1.0), AUTO_DEFENSE_BUILDINGS)

	# Terrain bonuses
	_build_terrain_section()

	# Tips
	_build_tips_section()


func _build_buildings_section(title: String, color: Color, buildings: Array[Dictionary]) -> void:
	var section := _create_section_panel(title, color)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for building in buildings:
		var container := DesignSystem.create_vbox(1)
		vbox.add_child(container)

		# Name and cost
		var header_hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
		container.add_child(header_hbox)

		var name_label := Label.new()
		name_label.text = str(building.get("name", ""))
		DesignSystem.style_label(name_label, "caption", building.get("color", color))
		name_label.custom_minimum_size = Vector2(90, 0)
		header_hbox.add_child(name_label)

		var cost_label := Label.new()
		cost_label.text = str(building.get("cost", ""))
		DesignSystem.style_label(cost_label, "caption", ThemeColors.TEXT_DIM)
		header_hbox.add_child(cost_label)

		# Stats row
		var stats_hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
		container.add_child(stats_hbox)

		var prod: String = str(building.get("production", "-"))
		if prod != "-":
			_add_stat_label(stats_hbox, "Prod", prod, ThemeColors.SUCCESS)

		if building.has("defense") and int(building.get("defense", 0)) > 0:
			_add_stat_label(stats_hbox, "Def", str(building.get("defense", 0)), ThemeColors.INFO)

		var workers: int = int(building.get("workers", 0))
		if workers > 0:
			_add_stat_label(stats_hbox, "Workers", str(workers), Color(0.9, 0.6, 0.3))

		# Special ability
		var special_label := Label.new()
		special_label.text = "  " + str(building.get("special", ""))
		DesignSystem.style_label(special_label, "caption", ThemeColors.TEXT_DIM)
		special_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		container.add_child(special_label)

		# Upgrades (if available)
		if building.has("upgrades"):
			var upgrade_label := Label.new()
			upgrade_label.text = "  Upgrades: " + str(building.get("upgrades", ""))
			DesignSystem.style_label(upgrade_label, "caption", Color(0.5, 0.5, 0.5))
			upgrade_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			container.add_child(upgrade_label)


func _add_stat_label(parent: Control, label: String, value: String, color: Color) -> void:
	var hbox := DesignSystem.create_hbox(2)
	parent.add_child(hbox)

	var label_node := Label.new()
	label_node.text = label + ":"
	DesignSystem.style_label(label_node, "caption", Color(0.5, 0.5, 0.5))
	hbox.add_child(label_node)

	var value_node := Label.new()
	value_node.text = value
	DesignSystem.style_label(value_node, "caption", color)
	hbox.add_child(value_node)


func _build_terrain_section() -> void:
	var section := _create_section_panel("TERRAIN BONUSES", Color(0.4, 0.7, 0.4))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for bonus in TERRAIN_BONUSES:
		var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_SM)
		vbox.add_child(hbox)

		var building_label := Label.new()
		building_label.text = str(bonus.get("building", ""))
		DesignSystem.style_label(building_label, "caption", bonus.get("color", Color.WHITE))
		building_label.custom_minimum_size = Vector2(80, 0)
		hbox.add_child(building_label)

		var terrain_label := Label.new()
		terrain_label.text = str(bonus.get("terrain", ""))
		DesignSystem.style_label(terrain_label, "caption", ThemeColors.TEXT_DIM)
		terrain_label.custom_minimum_size = Vector2(110, 0)
		hbox.add_child(terrain_label)

		var bonus_label := Label.new()
		bonus_label.text = str(bonus.get("bonus", ""))
		DesignSystem.style_label(bonus_label, "caption", ThemeColors.SUCCESS)
		hbox.add_child(bonus_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("BUILDING TIPS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in BUILDING_TIPS:
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
