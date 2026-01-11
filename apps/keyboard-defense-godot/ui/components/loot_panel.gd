class_name LootPanel
extends PanelContainer
## Loot Panel - Shows uncollected loot drops

signal closed
signal loot_collected(loot_id: String)

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Loot rarity colors
const RARITY_COLORS: Dictionary = {
	"common": Color(0.7, 0.7, 0.7),
	"uncommon": Color(0.3, 0.8, 0.3),
	"rare": Color(0.3, 0.5, 1.0),
	"epic": Color(0.7, 0.3, 0.9),
	"legendary": Color(1.0, 0.6, 0.1)
}

# Current state
var _state: Dictionary = {}


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(380, 400)

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
	title.text = "LOOT"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
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
	subtitle.text = "Dropped items to collect"
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	main_vbox.add_child(subtitle)

	# Content scroll
	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_content_scroll)

	_content_vbox = VBoxContainer.new()
	_content_vbox.add_theme_constant_override("separation", 8)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_vbox)


func show_loot(state) -> void:
	if state is Dictionary:
		_state = state
	else:
		# Handle GameState object
		_state = {
			"pending_loot": state.get("pending_loot") if state.has_method("get") else []
		}
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _build_content() -> void:
	_clear_content()

	var loot: Array = []
	if _state.has("pending_loot"):
		loot = _state["pending_loot"]
	elif _state.has("loot"):
		loot = _state["loot"]

	if loot.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No loot to collect"
		empty_label.add_theme_font_size_override("font_size", 12)
		empty_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_content_vbox.add_child(empty_label)

		var tip_label := Label.new()
		tip_label.text = "Defeat enemies to earn loot!"
		tip_label.add_theme_font_size_override("font_size", 10)
		tip_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_content_vbox.add_child(tip_label)
		return

	# Display each loot item
	for item in loot:
		var loot_panel := _create_loot_entry(item)
		_content_vbox.add_child(loot_panel)

	# Collect all button
	var collect_all_btn := Button.new()
	collect_all_btn.text = "Collect All"
	collect_all_btn.custom_minimum_size = Vector2(120, 32)
	collect_all_btn.pressed.connect(_on_collect_all_pressed)
	_content_vbox.add_child(collect_all_btn)


func _create_loot_entry(item: Dictionary) -> PanelContainer:
	var container := PanelContainer.new()

	var item_id: String = str(item.get("id", "unknown"))
	var item_name: String = str(item.get("name", item_id.replace("_", " ").capitalize()))
	var rarity: String = str(item.get("rarity", "common"))
	var item_type: String = str(item.get("type", "misc"))

	var rarity_color: Color = RARITY_COLORS.get(rarity, Color(0.7, 0.7, 0.7))

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = rarity_color.darkened(0.85)
	panel_style.border_color = rarity_color.darkened(0.5)
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
	name_label.text = item_name
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", rarity_color)
	info_vbox.add_child(name_label)

	var meta_hbox := HBoxContainer.new()
	meta_hbox.add_theme_constant_override("separation", 8)
	info_vbox.add_child(meta_hbox)

	var rarity_label := Label.new()
	rarity_label.text = rarity.capitalize()
	rarity_label.add_theme_font_size_override("font_size", 9)
	rarity_label.add_theme_color_override("font_color", rarity_color.darkened(0.3))
	meta_hbox.add_child(rarity_label)

	var type_label := Label.new()
	type_label.text = "[" + item_type + "]"
	type_label.add_theme_font_size_override("font_size", 9)
	type_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	meta_hbox.add_child(type_label)

	# Collect button
	var collect_btn := Button.new()
	collect_btn.text = "Take"
	collect_btn.custom_minimum_size = Vector2(50, 28)
	collect_btn.pressed.connect(_on_collect_pressed.bind(item_id))
	hbox.add_child(collect_btn)

	return container


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _on_collect_pressed(loot_id: String) -> void:
	loot_collected.emit(loot_id)
	refresh()


func _on_collect_all_pressed() -> void:
	var loot: Array = []
	if _state.has("pending_loot"):
		loot = _state["pending_loot"]
	elif _state.has("loot"):
		loot = _state["loot"]

	for item in loot:
		var item_id: String = str(item.get("id", ""))
		if item_id != "":
			loot_collected.emit(item_id)

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
