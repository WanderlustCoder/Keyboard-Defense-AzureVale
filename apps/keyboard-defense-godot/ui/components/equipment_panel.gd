class_name EquipmentPanel
extends PanelContainer
## Equipment Panel - Shows equipped items and inventory.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed
signal item_equipped(slot: String, item_id: String)
signal item_unequipped(slot: String)

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
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_SM, 500)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "EQUIPMENT"
	DesignSystem.style_label(title, "h2", ThemeColors.INFO)
	header.add_child(title)

	header.add_child(DesignSystem.create_spacer())

	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.custom_minimum_size = Vector2(DesignSystem.SIZE_BUTTON_SM, DesignSystem.SIZE_BUTTON_SM)
	_style_close_button()
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Content scroll
	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_content_scroll)

	_content_vbox = DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_vbox)

	_slots_container = DesignSystem.create_vbox(DesignSystem.SPACE_SM)
	_content_vbox.add_child(_slots_container)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


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
	DesignSystem.style_label(slots_header, "body_small", ThemeColors.RESOURCE_GOLD)
	_slots_container.add_child(slots_header)

	for slot in EQUIPMENT_SLOTS:
		var slot_container := _create_slot_row(slot, equipment.get(slot, ""))
		_slots_container.add_child(slot_container)

	# Inventory section
	var inv_header := Label.new()
	inv_header.text = "INVENTORY"
	DesignSystem.style_label(inv_header, "body_small", ThemeColors.RESOURCE_GOLD)
	_content_vbox.add_child(inv_header)

	if inventory.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No items in inventory"
		DesignSystem.style_label(empty_label, "caption", ThemeColors.TEXT_DIM)
		_content_vbox.add_child(empty_label)
	else:
		for item in inventory:
			var item_row := _create_inventory_row(item)
			_content_vbox.add_child(item_row)


func _create_slot_row(slot: String, item_id: String) -> HBoxContainer:
	var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)

	var slot_label := Label.new()
	slot_label.text = slot.capitalize() + ":"
	DesignSystem.style_label(slot_label, "caption", ThemeColors.TEXT_DIM)
	slot_label.custom_minimum_size = Vector2(80, 0)
	hbox.add_child(slot_label)

	var item_label := Label.new()
	if item_id != "":
		item_label.text = item_id.replace("_", " ").capitalize()
		DesignSystem.style_label(item_label, "caption", ThemeColors.SUCCESS)
	else:
		item_label.text = "(empty)"
		DesignSystem.style_label(item_label, "caption", ThemeColors.TEXT_DIM)
	item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(item_label)

	if item_id != "":
		var unequip_btn := Button.new()
		unequip_btn.text = "✕"
		unequip_btn.custom_minimum_size = Vector2(24, 24)
		_style_small_button(unequip_btn, true)
		unequip_btn.pressed.connect(_on_unequip.bind(slot))
		hbox.add_child(unequip_btn)

	return hbox


func _create_inventory_row(item: Dictionary) -> HBoxContainer:
	var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)

	var item_id: String = str(item.get("id", "unknown"))
	var item_slot: String = str(item.get("slot", "accessory"))

	var item_label := Label.new()
	item_label.text = item_id.replace("_", " ").capitalize()
	DesignSystem.style_label(item_label, "caption", ThemeColors.TEXT)
	item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(item_label)

	var slot_label := Label.new()
	slot_label.text = "[" + item_slot + "]"
	DesignSystem.style_label(slot_label, "caption", ThemeColors.TEXT_DIM)
	hbox.add_child(slot_label)

	var equip_btn := Button.new()
	equip_btn.text = "Equip"
	equip_btn.custom_minimum_size = Vector2(50, 24)
	_style_small_button(equip_btn, false)
	equip_btn.pressed.connect(_on_equip.bind(item_slot, item_id))
	hbox.add_child(equip_btn)

	return hbox


func _style_small_button(btn: Button, is_danger: bool) -> void:
	var normal: StyleBoxFlat
	var hover: StyleBoxFlat

	if is_danger:
		normal = DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
		hover = DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	else:
		normal = DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
		hover = DesignSystem.create_button_style(ThemeColors.BG_BUTTON_HOVER, ThemeColors.BORDER_HIGHLIGHT)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_color_override("font_color", ThemeColors.TEXT)


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
