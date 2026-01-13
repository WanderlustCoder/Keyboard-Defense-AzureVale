class_name BuildingsReferencePanel
extends PanelContainer
## Buildings Reference Panel - Shows all building types and their stats.
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
		"desc": "Protect against enemy attacks",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"name": "Economy",
		"desc": "Generate gold and enable trade",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"name": "Military",
		"desc": "Combat bonuses and troop support",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"name": "Support",
		"desc": "Special effects and bonuses",
		"color": Color(0.7, 0.5, 0.9)
	},
	{
		"name": "Auto Defense",
		"desc": "Towers that attack automatically",
		"color": Color(0.9, 0.6, 0.3)
	}
]

# Building data (from SimBuildings)
const BUILDINGS: Array[Dictionary] = [
	{
		"id": "farm",
		"name": "Farm",
		"category": "production",
		"cost": {"wood": 10},
		"production": {"food": 3},
		"worker_slots": 1,
		"bonus": "+1 food near water",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"id": "lumber",
		"name": "Lumber Mill",
		"category": "production",
		"cost": {"wood": 5, "food": 2},
		"production": {"wood": 3},
		"worker_slots": 1,
		"bonus": "+1 wood near forest",
		"color": Color(0.6, 0.4, 0.2)
	},
	{
		"id": "quarry",
		"name": "Quarry",
		"category": "production",
		"cost": {"wood": 5, "food": 2},
		"production": {"stone": 3},
		"worker_slots": 1,
		"bonus": "+1 stone near mountain",
		"color": Color(0.5, 0.5, 0.6)
	},
	{
		"id": "wall",
		"name": "Wall",
		"category": "defense",
		"cost": {"wood": 4, "stone": 4},
		"defense": 1,
		"worker_slots": 0,
		"bonus": "Blocks enemy paths",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"id": "tower",
		"name": "Tower",
		"category": "defense",
		"cost": {"wood": 4, "stone": 8},
		"defense": 2,
		"worker_slots": 0,
		"bonus": "+1 defense near walls, upgradeable",
		"color": Color(0.4, 0.7, 1.0)
	},
	{
		"id": "market",
		"name": "Market",
		"category": "economy",
		"cost": {"wood": 8, "stone": 5},
		"production": {"gold": 5},
		"worker_slots": 1,
		"bonus": "Enables trade at level 3",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"id": "barracks",
		"name": "Barracks",
		"category": "military",
		"cost": {"wood": 10, "stone": 8},
		"defense": 1,
		"worker_slots": 2,
		"bonus": "+typing power at higher levels",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"id": "temple",
		"name": "Temple",
		"category": "support",
		"cost": {"stone": 15, "gold": 20},
		"worker_slots": 1,
		"bonus": "Heal 1 HP per wave",
		"color": Color(0.7, 0.5, 0.9)
	},
	{
		"id": "workshop",
		"name": "Workshop",
		"category": "support",
		"cost": {"wood": 12, "stone": 6},
		"worker_slots": 2,
		"bonus": "-10% build costs",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"id": "sentry",
		"name": "Sentry",
		"category": "auto_defense",
		"cost": {"wood": 6, "stone": 10, "gold": 30},
		"defense": 1,
		"bonus": "3 damage, 3 range, 1.5s cooldown",
		"color": Color(0.4, 0.9, 0.4)
	},
	{
		"id": "spark",
		"name": "Spark Tower",
		"category": "auto_defense",
		"cost": {"wood": 4, "stone": 8, "gold": 50},
		"bonus": "2 AOE damage, 2 range, 2s cooldown",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"id": "flame",
		"name": "Flame Tower",
		"category": "auto_defense",
		"cost": {"wood": 8, "stone": 6, "gold": 60},
		"bonus": "4 damage, 2 range, 0.8s cooldown, burn",
		"color": Color(0.9, 0.4, 0.2)
	}
]

# Building tips
const BUILDING_TIPS: Array[String] = [
	"Place farms near water for bonus food",
	"Place lumber mills near forests for bonus wood",
	"Place quarries near mountains for bonus stone",
	"Walls block enemy paths - use strategically",
	"Towers are more effective when adjacent to walls",
	"Upgrade buildings to increase their effectiveness",
	"Auto-defense towers attack without typing"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_MD, 620)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "BUILDINGS"
	DesignSystem.style_label(title, "h2", ThemeColors.SUCCESS)
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
	subtitle.text = "Construct buildings to grow your kingdom"
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
	footer.text = "Type BUILD <name> to construct"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_buildings_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Categories section
	_build_categories_section()

	# Buildings section
	_build_buildings_section()

	# Tips section
	_build_tips_section()


func _build_categories_section() -> void:
	var section := _create_section_panel("BUILDING CATEGORIES", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for category in BUILDING_CATEGORIES:
		var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(category.get("name", ""))
		DesignSystem.style_label(name_label, "caption", category.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(90, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(category.get("desc", ""))
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_buildings_section() -> void:
	var section := _create_section_panel("ALL BUILDINGS", Color(0.4, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for building in BUILDINGS:
		var card := _create_building_card(building)
		vbox.add_child(card)


func _create_building_card(building: Dictionary) -> Control:
	var name: String = str(building.get("name", ""))
	var cost: Dictionary = building.get("cost", {})
	var production: Dictionary = building.get("production", {})
	var defense: int = int(building.get("defense", 0))
	var worker_slots: int = int(building.get("worker_slots", 0))
	var bonus: String = str(building.get("bonus", ""))
	var color: Color = building.get("color", Color.WHITE)

	var container := DesignSystem.create_vbox(2)

	# Name row
	var name_row := DesignSystem.create_hbox(DesignSystem.SPACE_SM)
	container.add_child(name_row)

	var name_label := Label.new()
	name_label.text = name
	DesignSystem.style_label(name_label, "caption", color)
	name_label.custom_minimum_size = Vector2(100, 0)
	name_row.add_child(name_label)

	# Cost
	var cost_parts: Array[String] = []
	for res in cost.keys():
		cost_parts.append("%d %s" % [cost[res], res])
	var cost_text: String = ", ".join(cost_parts) if not cost_parts.is_empty() else "Free"

	var cost_label := Label.new()
	cost_label.text = cost_text
	DesignSystem.style_label(cost_label, "caption", ThemeColors.RESOURCE_GOLD)
	name_row.add_child(cost_label)

	# Stats row
	var stats_row := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	container.add_child(stats_row)

	# Production
	if not production.is_empty():
		var prod_parts: Array[String] = []
		for res in production.keys():
			prod_parts.append("+%d %s" % [production[res], res])
		var prod_label := Label.new()
		prod_label.text = ", ".join(prod_parts)
		DesignSystem.style_label(prod_label, "caption", ThemeColors.SUCCESS)
		stats_row.add_child(prod_label)

	# Defense
	if defense > 0:
		var def_label := Label.new()
		def_label.text = "+%d defense" % defense
		DesignSystem.style_label(def_label, "caption", ThemeColors.INFO)
		stats_row.add_child(def_label)

	# Worker slots
	if worker_slots > 0:
		var worker_label := Label.new()
		worker_label.text = "%d worker slots" % worker_slots
		DesignSystem.style_label(worker_label, "caption", Color(0.9, 0.6, 0.3))
		stats_row.add_child(worker_label)

	# Bonus
	if bonus != "":
		var bonus_label := Label.new()
		bonus_label.text = bonus
		DesignSystem.style_label(bonus_label, "caption", ThemeColors.TEXT_DIM)
		container.add_child(bonus_label)

	return container


func _build_tips_section() -> void:
	var section := _create_section_panel("BUILDING TIPS", Color(0.9, 0.6, 0.3))
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
