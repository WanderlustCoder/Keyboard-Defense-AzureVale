class_name ItemsReferencePanel
extends PanelContainer
## Items Reference Panel - Shows equipment and consumables

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Rarity info
const RARITY_INFO: Array[Dictionary] = [
	{
		"name": "Common",
		"drop_weight": 60,
		"color": Color(1.0, 1.0, 1.0)
	},
	{
		"name": "Uncommon",
		"drop_weight": 25,
		"color": Color(0.0, 1.0, 0.0)
	},
	{
		"name": "Rare",
		"drop_weight": 10,
		"color": Color(0.0, 0.53, 1.0)
	},
	{
		"name": "Epic",
		"drop_weight": 4,
		"color": Color(0.67, 0.0, 1.0)
	},
	{
		"name": "Legendary",
		"drop_weight": 1,
		"color": Color(1.0, 0.53, 0.0)
	}
]

# Equipment slots
const EQUIPMENT_SLOTS: Array[Dictionary] = [
	{"slot": "headgear", "name": "Headgear", "desc": "Helmets and hoods", "color": Color(0.4, 0.8, 1.0)},
	{"slot": "armor", "name": "Armor", "desc": "Body protection", "color": Color(0.5, 0.5, 0.6)},
	{"slot": "gloves", "name": "Gloves", "desc": "Hand equipment", "color": Color(0.9, 0.6, 0.3)},
	{"slot": "boots", "name": "Boots", "desc": "Footwear", "color": Color(0.6, 0.4, 0.2)},
	{"slot": "amulet", "name": "Amulet", "desc": "Neck jewelry", "color": Color(1.0, 0.84, 0.0)},
	{"slot": "ring", "name": "Ring", "desc": "Finger jewelry", "color": Color(0.9, 0.5, 0.9)},
	{"slot": "belt", "name": "Belt", "desc": "Waist equipment", "color": Color(0.5, 0.8, 0.3)},
	{"slot": "cape", "name": "Cape", "desc": "Back equipment", "color": Color(0.9, 0.4, 0.4)}
]

# Sample equipment
const SAMPLE_EQUIPMENT: Array[Dictionary] = [
	{
		"name": "Crown of Clarity",
		"slot": "headgear",
		"rarity": "epic",
		"stats": "+8% accuracy, +5 defense",
		"effect": "Clear Mind: Scramble immunity",
		"color": Color(0.67, 0.0, 1.0)
	},
	{
		"name": "Grandmaster's Gauntlets",
		"slot": "gloves",
		"rarity": "epic",
		"stats": "+10% accuracy, +5 WPM",
		"effect": "Perfection: +10% crit chance",
		"color": Color(0.67, 0.0, 1.0)
	},
	{
		"name": "Heart of Keystonia",
		"slot": "amulet",
		"rarity": "legendary",
		"stats": "+20% damage, +10% accuracy, +15% gold",
		"effect": "Kingdom's Blessing: +10% all stats",
		"color": Color(1.0, 0.53, 0.0)
	},
	{
		"name": "Royal Mantle",
		"slot": "cape",
		"rarity": "legendary",
		"stats": "+10 defense, +20% gold",
		"effect": "Regal Presence: +15% enemy slow",
		"color": Color(1.0, 0.53, 0.0)
	}
]

# Consumable types
const CONSUMABLES: Array[Dictionary] = [
	{
		"name": "Health Potion",
		"type": "Potion",
		"effect": "Restore 3 castle HP",
		"price": 50,
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"name": "Scroll of Power",
		"type": "Scroll",
		"effect": "+50% damage for 30 seconds",
		"price": 75,
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"name": "Scroll of Frost",
		"type": "Scroll",
		"effect": "Freeze all enemies for 3 seconds",
		"price": 150,
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"name": "Scroll of Wealth",
		"type": "Scroll",
		"effect": "Double gold for 60 seconds",
		"price": 200,
		"color": Color(1.0, 0.84, 0.0)
	}
]

# Item tips
const ITEM_TIPS: Array[String] = [
	"Higher rarity items have better stats and special effects",
	"Boss enemies have a 50% chance to drop equipment",
	"Boss drops are at least Uncommon rarity",
	"Equip items to gain permanent stat bonuses",
	"Consumables can turn the tide in tough battles"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(520, 620)

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
	title.text = "ITEMS & EQUIPMENT"
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
	subtitle.text = "Equip gear to boost your typing power"
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
	footer.text = "Type EQUIP to manage your gear"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_items_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Rarity section
	_build_rarity_section()

	# Equipment slots section
	_build_slots_section()

	# Notable items section
	_build_notable_section()

	# Consumables section
	_build_consumables_section()

	# Tips section
	_build_tips_section()


func _build_rarity_section() -> void:
	var section := _create_section_panel("ITEM RARITIES", Color(0.67, 0.0, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for rarity in RARITY_INFO:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(rarity.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", rarity.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(80, 0)
		hbox.add_child(name_label)

		var weight_label := Label.new()
		weight_label.text = "%d%% drop chance" % rarity.get("drop_weight", 0)
		weight_label.add_theme_font_size_override("font_size", 9)
		weight_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(weight_label)


func _build_slots_section() -> void:
	var section := _create_section_panel("EQUIPMENT SLOTS", Color(0.4, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for slot in EQUIPMENT_SLOTS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

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


func _build_notable_section() -> void:
	var section := _create_section_panel("NOTABLE EQUIPMENT", Color(1.0, 0.53, 0.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for item in SAMPLE_EQUIPMENT:
		var card := _create_item_card(item)
		vbox.add_child(card)


func _create_item_card(item: Dictionary) -> Control:
	var name: String = str(item.get("name", ""))
	var rarity: String = str(item.get("rarity", ""))
	var stats: String = str(item.get("stats", ""))
	var effect: String = str(item.get("effect", ""))
	var color: Color = item.get("color", Color.WHITE)

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)

	# Name row
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	container.add_child(name_row)

	var name_label := Label.new()
	name_label.text = name
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", color)
	name_row.add_child(name_label)

	var rarity_label := Label.new()
	rarity_label.text = "(%s)" % rarity.capitalize()
	rarity_label.add_theme_font_size_override("font_size", 9)
	rarity_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	name_row.add_child(rarity_label)

	# Stats
	if stats != "":
		var stats_label := Label.new()
		stats_label.text = "  " + stats
		stats_label.add_theme_font_size_override("font_size", 9)
		stats_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		container.add_child(stats_label)

	# Effect
	if effect != "":
		var effect_label := Label.new()
		effect_label.text = "  " + effect
		effect_label.add_theme_font_size_override("font_size", 9)
		effect_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		container.add_child(effect_label)

	return container


func _build_consumables_section() -> void:
	var section := _create_section_panel("CONSUMABLES", Color(0.9, 0.4, 0.4))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for consumable in CONSUMABLES:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(consumable.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", consumable.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(120, 0)
		hbox.add_child(name_label)

		var price_label := Label.new()
		price_label.text = "%dg" % consumable.get("price", 0)
		price_label.add_theme_font_size_override("font_size", 9)
		price_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		price_label.custom_minimum_size = Vector2(40, 0)
		hbox.add_child(price_label)

		var effect_label := Label.new()
		effect_label.text = str(consumable.get("effect", ""))
		effect_label.add_theme_font_size_override("font_size", 9)
		effect_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(effect_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("ITEM TIPS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in ITEM_TIPS:
		var tip_label := Label.new()
		tip_label.text = "- " + tip
		tip_label.add_theme_font_size_override("font_size", 10)
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
