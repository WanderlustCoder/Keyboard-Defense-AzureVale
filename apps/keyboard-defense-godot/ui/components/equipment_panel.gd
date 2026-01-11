class_name EquipmentPanel
extends PanelContainer
## Equipment Panel - Shows equipped items and inventory

signal closed
signal item_equipped(slot: String, item_id: String)
signal item_unequipped(slot: String)

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null
var _slots_container: VBoxContainer = null

# Equipment slots
const EQUIPMENT_SLOTS: Array[String] = ["weapon", "armor", "accessory", "ring", "charm"]

# Current profile reference
var _profile: Dictionary = {}


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(400, 500)

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
	title.text = "EQUIPMENT"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.3, 0.7, 0.9))
	header.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_close_btn = Button.new()
	_close_btn.text = "X"
	_close_btn.custom_minimum_size = Vector2(30, 30)
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

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

	_slots_container = VBoxContainer.new()
	_slots_container.add_theme_constant_override("separation", 6)
	_content_vbox.add_child(_slots_container)


func show_equipment(profile: Dictionary) -> void:
	_profile = profile
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _build_content() -> void:
	_clear_content()

	var equipment: Dictionary = _profile.get("equipment", {})
	var inventory: Array = _profile.get("inventory", [])

	# Equipment slots section
	var slots_header := Label.new()
	slots_header.text = "EQUIPPED"
	slots_header.add_theme_font_size_override("font_size", 14)
	slots_header.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3))
	_slots_container.add_child(slots_header)

	for slot in EQUIPMENT_SLOTS:
		var slot_container := _create_slot_row(slot, equipment.get(slot, ""))
		_slots_container.add_child(slot_container)

	# Inventory section
	var inv_header := Label.new()
	inv_header.text = "INVENTORY"
	inv_header.add_theme_font_size_override("font_size", 14)
	inv_header.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3))
	_content_vbox.add_child(inv_header)

	if inventory.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No items in inventory"
		empty_label.add_theme_font_size_override("font_size", 11)
		empty_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		_content_vbox.add_child(empty_label)
	else:
		for item in inventory:
			var item_row := _create_inventory_row(item)
			_content_vbox.add_child(item_row)


func _create_slot_row(slot: String, item_id: String) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	var slot_label := Label.new()
	slot_label.text = slot.capitalize() + ":"
	slot_label.add_theme_font_size_override("font_size", 11)
	slot_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	slot_label.custom_minimum_size = Vector2(80, 0)
	hbox.add_child(slot_label)

	var item_label := Label.new()
	if item_id != "":
		item_label.text = item_id.replace("_", " ").capitalize()
		item_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	else:
		item_label.text = "(empty)"
		item_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	item_label.add_theme_font_size_override("font_size", 11)
	item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(item_label)

	if item_id != "":
		var unequip_btn := Button.new()
		unequip_btn.text = "X"
		unequip_btn.custom_minimum_size = Vector2(24, 24)
		unequip_btn.pressed.connect(_on_unequip.bind(slot))
		hbox.add_child(unequip_btn)

	return hbox


func _create_inventory_row(item: Dictionary) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	var item_id: String = str(item.get("id", "unknown"))
	var item_slot: String = str(item.get("slot", "accessory"))

	var item_label := Label.new()
	item_label.text = item_id.replace("_", " ").capitalize()
	item_label.add_theme_font_size_override("font_size", 11)
	item_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(item_label)

	var slot_label := Label.new()
	slot_label.text = "[" + item_slot + "]"
	slot_label.add_theme_font_size_override("font_size", 10)
	slot_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	hbox.add_child(slot_label)

	var equip_btn := Button.new()
	equip_btn.text = "Equip"
	equip_btn.custom_minimum_size = Vector2(50, 24)
	equip_btn.pressed.connect(_on_equip.bind(item_slot, item_id))
	hbox.add_child(equip_btn)

	return hbox


func _clear_content() -> void:
	for child in _slots_container.get_children():
		child.queue_free()
	# Clear inventory items (skip slots container)
	for i in range(_content_vbox.get_child_count() - 1, 0, -1):
		var child := _content_vbox.get_child(i)
		if child != _slots_container:
			child.queue_free()


func _on_equip(slot: String, item_id: String) -> void:
	item_equipped.emit(slot, item_id)
	refresh()


func _on_unequip(slot: String) -> void:
	item_unequipped.emit(slot)
	refresh()


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
