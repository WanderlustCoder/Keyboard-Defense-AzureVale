class_name TokenShopPanel
extends PanelContainer
## Token Shop Panel - Spend challenge tokens on rewards.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed
signal item_purchased(item_id: String, cost: int)

# UI elements
var _close_btn: Button = null
var _balance_label: Label = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Shop items
const SHOP_ITEMS: Array[Dictionary] = [
	{
		"id": "gold_pack_small",
		"name": "Gold Pack (Small)",
		"description": "+100 gold",
		"cost": 5,
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"id": "gold_pack_large",
		"name": "Gold Pack (Large)",
		"description": "+500 gold",
		"cost": 20,
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"id": "xp_boost",
		"name": "XP Boost",
		"description": "+25% XP for 5 battles",
		"cost": 10,
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"id": "power_crystal",
		"name": "Power Crystal",
		"description": "+15% typing power for 3 battles",
		"cost": 15,
		"color": Color(0.8, 0.3, 0.9)
	},
	{
		"id": "lucky_charm",
		"name": "Lucky Charm",
		"description": "+10% critical chance for 3 battles",
		"cost": 12,
		"color": Color(0.3, 1.0, 0.5)
	},
	{
		"id": "revival_token",
		"name": "Revival Token",
		"description": "Continue once after game over",
		"cost": 25,
		"color": Color(1.0, 0.5, 0.5)
	},
	{
		"id": "mystery_box",
		"name": "Mystery Box",
		"description": "Random rare item",
		"cost": 30,
		"color": Color(0.9, 0.7, 0.3)
	}
]

# Current state
var _profile: Dictionary = {}
var _balance: int = 0


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_MD, 500)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "TOKEN SHOP"
	DesignSystem.style_label(title, "h2", Color(0.9, 0.7, 0.3))
	header.add_child(title)

	header.add_child(DesignSystem.create_spacer())

	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.custom_minimum_size = Vector2(DesignSystem.SIZE_BUTTON_SM, DesignSystem.SIZE_BUTTON_SM)
	_style_close_button()
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Balance display
	var balance_hbox := DesignSystem.create_hbox(DesignSystem.SPACE_SM)
	main_vbox.add_child(balance_hbox)

	var balance_icon := Label.new()
	balance_icon.text = "Tokens:"
	balance_icon.add_theme_font_size_override("font_size", 14)
	balance_icon.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3))
	balance_hbox.add_child(balance_icon)

	_balance_label = Label.new()
	_balance_label.text = "0"
	_balance_label.add_theme_font_size_override("font_size", 14)
	_balance_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	balance_hbox.add_child(_balance_label)

	# Content scroll
	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_content_scroll)

	_content_vbox = DesignSystem.create_vbox(DesignSystem.SPACE_SM)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_vbox)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_shop(profile: Dictionary, balance: int) -> void:
	_profile = profile
	_balance = balance
	_balance_label.text = str(balance)
	_build_content()
	show()


func update_balance(balance: int) -> void:
	_balance = balance
	_balance_label.text = str(balance)
	_build_content()


func refresh() -> void:
	_build_content()


func _build_content() -> void:
	_clear_content()

	for item in SHOP_ITEMS:
		var item_panel := _create_shop_item(item)
		_content_vbox.add_child(item_panel)


func _create_shop_item(item: Dictionary) -> PanelContainer:
	var container := PanelContainer.new()

	var item_color: Color = item.get("color", Color.WHITE)
	var cost: int = int(item.get("cost", 0))
	var can_afford := _balance >= cost

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = item_color.darkened(0.85)
	panel_style.border_color = item_color.darkened(0.5) if can_afford else Color(0.3, 0.3, 0.3)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", panel_style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	container.add_child(hbox)

	# Item info
	var info_vbox := VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 2)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var name_label := Label.new()
	name_label.text = str(item.get("name", ""))
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", item_color)
	info_vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = str(item.get("description", ""))
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	info_vbox.add_child(desc_label)

	# Cost and buy button
	var buy_vbox := VBoxContainer.new()
	buy_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(buy_vbox)

	var cost_label := Label.new()
	cost_label.text = "%d tokens" % cost
	cost_label.add_theme_font_size_override("font_size", 10)
	cost_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0) if can_afford else Color(1.0, 0.4, 0.4))
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	buy_vbox.add_child(cost_label)

	var buy_btn := Button.new()
	buy_btn.text = "Buy"
	buy_btn.custom_minimum_size = Vector2(60, 28)
	buy_btn.disabled = not can_afford
	buy_btn.pressed.connect(_on_buy_pressed.bind(str(item.get("id", "")), cost))
	buy_vbox.add_child(buy_btn)

	return container


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _on_buy_pressed(item_id: String, cost: int) -> void:
	if _balance >= cost:
		item_purchased.emit(item_id, cost)


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
