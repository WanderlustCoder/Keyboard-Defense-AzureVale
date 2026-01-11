class_name CraftingReferencePanel
extends PanelContainer
## Crafting Reference Panel - Shows materials and recipe overview

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Material tiers (from SimCrafting)
const MATERIAL_TIERS: Array[Dictionary] = [
	{
		"tier": 1,
		"name": "Common",
		"color": Color(0.7, 0.7, 0.7),
		"source": "Regular enemies",
		"materials": [
			{"id": "scrap_metal", "name": "Scrap Metal"},
			{"id": "leather_scraps", "name": "Leather Scraps"},
			{"id": "crystal_shard", "name": "Crystal Shard"},
			{"id": "herb_common", "name": "Common Herb"}
		]
	},
	{
		"tier": 2,
		"name": "Uncommon",
		"color": Color(0.5, 0.8, 0.3),
		"source": "Elite enemies",
		"materials": [
			{"id": "iron_ingot", "name": "Iron Ingot"},
			{"id": "quality_leather", "name": "Quality Leather"},
			{"id": "crystal_cluster", "name": "Crystal Cluster"},
			{"id": "herb_rare", "name": "Rare Herb"}
		]
	},
	{
		"tier": 3,
		"name": "Rare",
		"color": Color(0.4, 0.8, 1.0),
		"source": "Bosses",
		"materials": [
			{"id": "steel_ingot", "name": "Steel Ingot"},
			{"id": "enchanted_leather", "name": "Enchanted Leather"},
			{"id": "mana_crystal", "name": "Mana Crystal"},
			{"id": "essence_power", "name": "Essence of Power"}
		]
	},
	{
		"tier": 4,
		"name": "Epic",
		"color": Color(0.7, 0.5, 0.9),
		"source": "Rare boss drops",
		"materials": [
			{"id": "keysteel", "name": "Keysteel"},
			{"id": "dragon_leather", "name": "Dragon Leather"},
			{"id": "word_crystal", "name": "Word Crystal"}
		]
	}
]

# Recipe categories
const RECIPE_CATEGORIES: Array[Dictionary] = [
	{
		"category": "consumable",
		"name": "Consumables",
		"color": Color(0.5, 0.8, 0.3),
		"description": "Potions, scrolls, and elixirs for temporary bonuses",
		"examples": ["Health Potion", "Scroll of Power", "Speed Elixir", "Combo Potion"]
	},
	{
		"category": "equipment",
		"name": "Equipment",
		"color": Color(0.4, 0.8, 1.0),
		"description": "Armor and accessories with permanent stat bonuses",
		"examples": ["Leather Cap", "Iron Chestplate", "Typist's Gloves", "Accuracy Amulet"]
	},
	{
		"category": "material",
		"name": "Material Upgrades",
		"color": Color(0.9, 0.6, 0.3),
		"description": "Refine lower-tier materials into higher-tier ones",
		"examples": ["Refine Iron (5 Scrap -> 1 Iron)", "Forge Steel (3 Iron -> 1 Steel)"]
	}
]

# Equipment tiers
const EQUIPMENT_TIERS: Array[Dictionary] = [
	{
		"tier": 1,
		"name": "Basic",
		"unlock": "Default",
		"color": Color(0.7, 0.7, 0.7),
		"items": ["Leather Cap", "Leather Vest", "Leather Gloves", "Simple Ring"]
	},
	{
		"tier": 2,
		"name": "Standard",
		"unlock": "Level 10",
		"color": Color(0.5, 0.8, 0.3),
		"items": ["Iron Helm", "Iron Chestplate", "Typist's Gloves", "Accuracy Amulet"]
	},
	{
		"tier": 3,
		"name": "Advanced",
		"unlock": "Level 18",
		"color": Color(0.4, 0.8, 1.0),
		"items": ["Steel Helm", "Steel Chestplate", "Ring of Power", "Combo Amulet"]
	},
	{
		"tier": 4,
		"name": "Legendary",
		"unlock": "Level 30",
		"color": Color(0.7, 0.5, 0.9),
		"items": ["Crown of Words", "Wordweave Mantle"]
	}
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
	title.text = "CRAFTING SYSTEM"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3))
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
	subtitle.text = "Combine materials to create equipment and consumables"
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
	footer.text = "Use 'craft <recipe>' to craft items"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_crafting_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Materials section
	_build_materials_section()

	# Recipe categories section
	_build_categories_section()

	# Equipment tiers section
	_build_equipment_section()


func _build_materials_section() -> void:
	var section := _create_section_panel("MATERIAL TIERS", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tier_info in MATERIAL_TIERS:
		var card := _create_tier_card(tier_info)
		vbox.add_child(card)


func _create_tier_card(tier_info: Dictionary) -> Control:
	var tier_name: String = str(tier_info.get("name", ""))
	var source: String = str(tier_info.get("source", ""))
	var color: Color = tier_info.get("color", Color.WHITE)
	var materials: Array = tier_info.get("materials", [])

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = color.darkened(0.85)
	container_style.border_color = color.darkened(0.6)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(6)
	container.add_theme_stylebox_override("panel", container_style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 2)
	container.add_child(main_vbox)

	# Header
	var header_hbox := HBoxContainer.new()
	main_vbox.add_child(header_hbox)

	var name_label := Label.new()
	name_label.text = tier_name
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", color)
	header_hbox.add_child(name_label)

	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(header_spacer)

	var source_label := Label.new()
	source_label.text = "Source: " + source
	source_label.add_theme_font_size_override("font_size", 9)
	source_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	header_hbox.add_child(source_label)

	# Materials list
	var mat_names: Array[String] = []
	for mat in materials:
		mat_names.append(str(mat.get("name", "")))

	var mats_label := Label.new()
	mats_label.text = ", ".join(mat_names)
	mats_label.add_theme_font_size_override("font_size", 9)
	mats_label.add_theme_color_override("font_color", color.lightened(0.3))
	mats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_vbox.add_child(mats_label)

	return container


func _build_categories_section() -> void:
	var section := _create_section_panel("RECIPE CATEGORIES", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for cat_info in RECIPE_CATEGORIES:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var name_str: String = str(cat_info.get("name", ""))
		var description: String = str(cat_info.get("description", ""))
		var color: Color = cat_info.get("color", Color.WHITE)

		var name_label := Label.new()
		name_label.text = name_str
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", color)
		name_label.custom_minimum_size = Vector2(120, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = description
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_equipment_section() -> void:
	var section := _create_section_panel("EQUIPMENT TIERS", Color(0.4, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for eq_tier in EQUIPMENT_TIERS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var tier_name: String = str(eq_tier.get("name", ""))
		var unlock: String = str(eq_tier.get("unlock", ""))
		var color: Color = eq_tier.get("color", Color.WHITE)
		var items: Array = eq_tier.get("items", [])

		var name_label := Label.new()
		name_label.text = tier_name
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", color)
		name_label.custom_minimum_size = Vector2(70, 0)
		hbox.add_child(name_label)

		var unlock_label := Label.new()
		unlock_label.text = unlock
		unlock_label.add_theme_font_size_override("font_size", 9)
		unlock_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		unlock_label.custom_minimum_size = Vector2(60, 0)
		hbox.add_child(unlock_label)

		var items_label := Label.new()
		items_label.text = ", ".join(items)
		items_label.add_theme_font_size_override("font_size", 9)
		items_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(items_label)


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
