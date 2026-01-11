class_name EquipmentItemsReferencePanel
extends PanelContainer
## Equipment & Items Reference Panel - Shows equipment slots, rarities, and consumables

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Equipment slots
const EQUIPMENT_SLOTS: Array[Dictionary] = [
	{"id": "headgear", "name": "Headgear", "desc": "Helms, hoods, crowns", "color": Color(0.6, 0.5, 0.8)},
	{"id": "armor", "name": "Armor", "desc": "Body protection", "color": Color(0.5, 0.6, 0.7)},
	{"id": "gloves", "name": "Gloves", "desc": "Hand and finger gear", "color": Color(0.5, 0.8, 0.5)},
	{"id": "boots", "name": "Boots", "desc": "Footwear", "color": Color(0.6, 0.5, 0.4)},
	{"id": "amulet", "name": "Amulet", "desc": "Neck jewelry", "color": Color(0.8, 0.6, 0.3)},
	{"id": "ring", "name": "Ring", "desc": "Finger jewelry", "color": Color(0.8, 0.7, 0.3)},
	{"id": "belt", "name": "Belt", "desc": "Waist gear with pouches", "color": Color(0.5, 0.5, 0.5)},
	{"id": "cape", "name": "Cape", "desc": "Back slot for cloaks", "color": Color(0.6, 0.4, 0.6)}
]

# Rarity tiers
const RARITY_TIERS: Array[Dictionary] = [
	{
		"id": "common",
		"name": "Common",
		"drop_weight": 60,
		"color": Color(1.0, 1.0, 1.0),
		"hex": "#FFFFFF",
		"desc": "Basic equipment with simple stats"
	},
	{
		"id": "uncommon",
		"name": "Uncommon",
		"drop_weight": 25,
		"color": Color(0.0, 1.0, 0.0),
		"hex": "#00FF00",
		"desc": "Better stats, occasional bonuses"
	},
	{
		"id": "rare",
		"name": "Rare",
		"drop_weight": 10,
		"color": Color(0.0, 0.53, 1.0),
		"hex": "#0088FF",
		"desc": "Strong stats with special effects"
	},
	{
		"id": "epic",
		"name": "Epic",
		"drop_weight": 4,
		"color": Color(0.67, 0.0, 1.0),
		"hex": "#AA00FF",
		"desc": "Powerful items with unique abilities"
	},
	{
		"id": "legendary",
		"name": "Legendary",
		"drop_weight": 1,
		"color": Color(1.0, 0.53, 0.0),
		"hex": "#FF8800",
		"desc": "Extremely rare items of great power"
	}
]

# Stat types
const STAT_TYPES: Array[Dictionary] = [
	{"name": "Defense", "desc": "Reduces damage taken by castle", "color": Color(0.5, 0.6, 0.7)},
	{"name": "Accuracy Bonus", "desc": "Increases typing accuracy tolerance", "color": Color(0.5, 0.8, 0.3)},
	{"name": "WPM Bonus", "desc": "Increases effective typing speed", "color": Color(0.5, 0.8, 1.0)},
	{"name": "Damage Bonus", "desc": "Increases damage dealt to enemies", "color": Color(0.96, 0.26, 0.21)},
	{"name": "Gold Bonus", "desc": "Increases gold earned from kills", "color": Color(1.0, 0.84, 0.0)},
	{"name": "Crit Chance", "desc": "Chance for critical hits", "color": Color(0.8, 0.4, 0.4)},
	{"name": "Crit Damage", "desc": "Extra damage on critical hits", "color": Color(0.9, 0.3, 0.3)}
]

# Consumable types
const CONSUMABLE_TYPES: Array[Dictionary] = [
	{
		"type": "potion",
		"name": "Potions",
		"desc": "Instant healing effects",
		"examples": "Health Potion (3 HP), Greater Health Potion (5 HP)",
		"color": Color(0.8, 0.2, 0.2)
	},
	{
		"type": "scroll",
		"name": "Scrolls",
		"desc": "Temporary buff effects",
		"examples": "Scroll of Power (+50% dmg), Scroll of Frost (freeze all)",
		"color": Color(0.5, 0.7, 0.9)
	},
	{
		"type": "food",
		"name": "Food",
		"desc": "Sustained buff effects",
		"examples": "Fresh Bread (regen), Hearty Feast (+10% all stats)",
		"color": Color(0.8, 0.6, 0.3)
	}
]

# Item tips
const ITEM_TIPS: Array[String] = [
	"Equipment can be found from enemy drops and boss kills",
	"Higher rarity items have better stats and special effects",
	"Boss enemies have a 50% drop chance vs 5-15% for normal enemies",
	"Boss drops are at least Uncommon rarity",
	"Consumables can be purchased from shops or found as loot",
	"Equipment stats stack - wear a full set for maximum bonus",
	"Legendary items have unique named effects"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(560, 680)

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
	title.text = "EQUIPMENT & ITEMS"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.67, 0.0, 1.0))
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
	subtitle.text = "8 equipment slots, 5 rarities, and consumable items"
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
	footer.text = "Find items from enemy drops and boss kills"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_equipment_items_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Equipment slots
	_build_slots_section()

	# Rarity tiers
	_build_rarity_section()

	# Stat types
	_build_stats_section()

	# Consumables
	_build_consumables_section()

	# Tips
	_build_tips_section()


func _build_slots_section() -> void:
	var section := _create_section_panel("EQUIPMENT SLOTS", Color(0.5, 0.6, 0.7))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Create two-column layout
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(grid)

	for slot in EQUIPMENT_SLOTS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		hbox.custom_minimum_size = Vector2(220, 0)
		grid.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(slot.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", slot.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(70, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(slot.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_rarity_section() -> void:
	var section := _create_section_panel("RARITY TIERS", Color(0.67, 0.0, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for rarity in RARITY_TIERS:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 1)
		vbox.add_child(container)

		var header_hbox := HBoxContainer.new()
		header_hbox.add_theme_constant_override("separation", 10)
		container.add_child(header_hbox)

		var name_label := Label.new()
		name_label.text = str(rarity.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.add_theme_color_override("font_color", rarity.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(90, 0)
		header_hbox.add_child(name_label)

		var weight_label := Label.new()
		weight_label.text = "%d%% drop" % rarity.get("drop_weight", 0)
		weight_label.add_theme_font_size_override("font_size", 9)
		weight_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		weight_label.custom_minimum_size = Vector2(60, 0)
		header_hbox.add_child(weight_label)

		var desc_label := Label.new()
		desc_label.text = str(rarity.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		header_hbox.add_child(desc_label)


func _build_stats_section() -> void:
	var section := _create_section_panel("STAT TYPES", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for stat in STAT_TYPES:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(stat.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", stat.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(110, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(stat.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_consumables_section() -> void:
	var section := _create_section_panel("CONSUMABLE ITEMS", Color(0.8, 0.5, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for cons in CONSUMABLE_TYPES:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 1)
		vbox.add_child(container)

		var header_hbox := HBoxContainer.new()
		header_hbox.add_theme_constant_override("separation", 10)
		container.add_child(header_hbox)

		var name_label := Label.new()
		name_label.text = str(cons.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", cons.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(70, 0)
		header_hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(cons.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		header_hbox.add_child(desc_label)

		var examples_label := Label.new()
		examples_label.text = "  Examples: %s" % cons.get("examples", "")
		examples_label.add_theme_font_size_override("font_size", 9)
		examples_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.5))
		examples_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		container.add_child(examples_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("ITEM TIPS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in ITEM_TIPS:
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
