class_name ShopPanel
extends PanelContainer
## Shop Panel - Purchase items and consumables

signal closed
signal item_purchased(item_id: String)

const ThemeColors = preload("res://ui/theme_colors.gd")
const SimItems = preload("res://sim/items.gd")

var _gold: int = 0
var _selected_item: String = ""

# UI elements
var _close_btn: Button = null
var _gold_label: Label = null
var _items_scroll: ScrollContainer = null
var _items_vbox: VBoxContainer = null
var _item_buttons: Dictionary = {}  # item_id -> Button
var _detail_panel: PanelContainer = null
var _detail_label: RichTextLabel = null
var _buy_btn: Button = null


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(550, 450)

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

	# Header with title, gold, and close button
	var header := HBoxContainer.new()
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "SHOP"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", ThemeColors.ACCENT)
	header.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 16)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	header.add_child(_gold_label)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(20, 0)
	header.add_child(spacer2)

	_close_btn = Button.new()
	_close_btn.text = "X"
	_close_btn.custom_minimum_size = Vector2(30, 30)
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Main content (items list + detail panel)
	var content_hbox := HBoxContainer.new()
	content_hbox.add_theme_constant_override("separation", 10)
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_hbox)

	# Left: Items list
	_items_scroll = ScrollContainer.new()
	_items_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_items_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_hbox.add_child(_items_scroll)

	_items_vbox = VBoxContainer.new()
	_items_vbox.add_theme_constant_override("separation", 8)
	_items_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items_scroll.add_child(_items_vbox)

	# Right: Detail panel
	_detail_panel = PanelContainer.new()
	_detail_panel.custom_minimum_size = Vector2(200, 0)
	content_hbox.add_child(_detail_panel)

	var detail_style := StyleBoxFlat.new()
	detail_style.bg_color = Color(0.05, 0.06, 0.09, 0.9)
	detail_style.border_color = ThemeColors.BORDER_DISABLED
	detail_style.set_border_width_all(1)
	detail_style.set_corner_radius_all(4)
	detail_style.set_content_margin_all(8)
	_detail_panel.add_theme_stylebox_override("panel", detail_style)

	var detail_vbox := VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 8)
	_detail_panel.add_child(detail_vbox)

	_detail_label = RichTextLabel.new()
	_detail_label.bbcode_enabled = true
	_detail_label.fit_content = true
	_detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_label.add_theme_font_size_override("normal_font_size", 12)
	detail_vbox.add_child(_detail_label)

	_buy_btn = Button.new()
	_buy_btn.text = "Buy"
	_buy_btn.visible = false
	_buy_btn.pressed.connect(_on_buy_pressed)
	detail_vbox.add_child(_buy_btn)


func show_shop(gold: int) -> void:
	_gold = gold
	_selected_item = ""
	_update_gold_display()
	_build_items_list()
	_clear_detail()
	show()


func update_gold(gold: int) -> void:
	_gold = gold
	_update_gold_display()
	# Refresh buy button state
	if not _selected_item.is_empty():
		_show_item_detail(_selected_item)


func _update_gold_display() -> void:
	_gold_label.text = "Gold: %d" % _gold


func _clear_items() -> void:
	for child in _items_vbox.get_children():
		child.queue_free()
	_item_buttons.clear()


func _clear_detail() -> void:
	_detail_label.text = "[color=#888888]Select an item to view details[/color]"
	_buy_btn.visible = false


func _build_items_list() -> void:
	_clear_items()

	# Group items by type
	var items_by_type: Dictionary = {
		"potion": [],
		"scroll": [],
		"food": []
	}

	for item_id in SimItems.CONSUMABLES.keys():
		var item: Dictionary = SimItems.CONSUMABLES[item_id]
		var type: String = str(item.get("type", "misc"))
		if not items_by_type.has(type):
			items_by_type[type] = []
		items_by_type[type].append(item_id)

	# Type display names
	var type_names: Dictionary = {
		"potion": "Potions",
		"scroll": "Scrolls",
		"food": "Food"
	}

	# Build sections
	for type in ["potion", "scroll", "food"]:
		var items: Array = items_by_type.get(type, [])
		if items.is_empty():
			continue

		# Category header
		var header := Label.new()
		header.text = type_names.get(type, type.capitalize())
		header.add_theme_font_size_override("font_size", 14)
		header.add_theme_color_override("font_color", ThemeColors.ACCENT)
		_items_vbox.add_child(header)

		# Items in category
		for item_id in items:
			var btn := _create_item_button(item_id)
			_items_vbox.add_child(btn)
			_item_buttons[item_id] = btn

		# Spacer
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 5)
		_items_vbox.add_child(spacer)


func _create_item_button(item_id: String) -> Button:
	var item: Dictionary = SimItems.CONSUMABLES.get(item_id, {})
	var name: String = str(item.get("name", item_id))
	var price: int = int(item.get("price", 0))
	var rarity: String = str(item.get("rarity", "common"))
	var color: Color = SimItems.get_rarity_color(rarity)
	var can_afford: bool = _gold >= price

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 40)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(_on_item_selected.bind(item_id))

	# Custom button content
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	btn.add_child(hbox)

	var name_label := Label.new()
	name_label.text = name
	name_label.add_theme_color_override("font_color", color)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)

	var price_label := Label.new()
	price_label.text = "%d gold" % price
	if can_afford:
		price_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	else:
		price_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	hbox.add_child(price_label)

	return btn


func _show_item_detail(item_id: String) -> void:
	var item: Dictionary = SimItems.CONSUMABLES.get(item_id, {})
	if item.is_empty():
		_clear_detail()
		return

	var name: String = str(item.get("name", item_id))
	var desc: String = str(item.get("description", ""))
	var price: int = int(item.get("price", 0))
	var rarity: String = str(item.get("rarity", "common"))
	var color: String = SimItems.RARITY_COLORS.get(rarity, "#FFFFFF")
	var type: String = str(item.get("type", "misc")).capitalize()
	var can_afford: bool = _gold >= price

	var lines: Array[String] = []
	lines.append("[color=%s]%s[/color]" % [color, name])
	lines.append("[color=gray]%s (%s)[/color]" % [type, rarity.capitalize()])
	lines.append("")

	# Effect details
	var effect: Dictionary = item.get("effect", {})
	if not effect.is_empty():
		var effect_type: String = str(effect.get("type", ""))
		var effect_value: Variant = effect.get("value", 0)
		var duration: float = float(effect.get("duration", 0))

		lines.append("[color=orange]Effect:[/color]")
		match effect_type:
			"heal":
				lines.append("  Restore %d castle HP" % int(effect_value))
			"damage_buff":
				lines.append("  +%.0f%% damage" % (float(effect_value) * 100))
				if duration > 0:
					lines.append("  Duration: %.0f seconds" % duration)
			"gold_buff":
				lines.append("  +%.0f%% gold from kills" % (float(effect_value) * 100))
				if duration > 0:
					lines.append("  Duration: %.0f seconds" % duration)
			"freeze_all":
				lines.append("  Freeze all enemies")
				if duration > 0:
					lines.append("  Duration: %.1f seconds" % duration)
			"regen":
				lines.append("  Regenerate %d HP per wave" % int(effect_value))
				if duration > 0:
					lines.append("  Duration: %.0f seconds" % duration)
			"all_buff":
				lines.append("  +%.0f%% all stats" % (float(effect_value) * 100))
				if duration > 0:
					lines.append("  Duration: %.0f seconds" % duration)
			_:
				lines.append("  %s: %s" % [effect_type, str(effect_value)])
		lines.append("")

	lines.append("%s" % desc)
	lines.append("")

	# Price
	if can_afford:
		lines.append("Price: [color=lime]%d gold[/color]" % price)
	else:
		lines.append("Price: [color=red]%d gold[/color] (Need %d more)" % [price, price - _gold])

	_detail_label.text = "\n".join(lines)

	# Update buy button
	_buy_btn.text = "Buy (%d gold)" % price
	_buy_btn.visible = true
	_buy_btn.disabled = not can_afford


func _on_item_selected(item_id: String) -> void:
	_selected_item = item_id
	_show_item_detail(item_id)


func _on_buy_pressed() -> void:
	if _selected_item.is_empty():
		return

	var item: Dictionary = SimItems.CONSUMABLES.get(_selected_item, {})
	var price: int = int(item.get("price", 0))

	if _gold < price:
		return

	# Emit purchase signal (actual gold deduction handled externally)
	item_purchased.emit(_selected_item)


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
