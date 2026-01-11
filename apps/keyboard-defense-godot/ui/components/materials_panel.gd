class_name MaterialsPanel
extends PanelContainer
## Materials Panel - Shows crafting materials inventory

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")
const SimCrafting = preload("res://sim/crafting.gd")

var _materials: Dictionary = {}
var _player_level: int = 1

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null
var _total_label: Label = null

# Tier colors
const TIER_COLORS: Dictionary = {
	1: Color(0.8, 0.8, 0.8),      # Common - Gray/White
	2: Color(0.4, 0.9, 0.4),      # Uncommon - Green
	3: Color(0.4, 0.8, 1.0),      # Rare - Cyan
	4: Color(0.9, 0.4, 0.9)       # Epic - Magenta
}

const TIER_NAMES: Dictionary = {
	1: "Common",
	2: "Uncommon",
	3: "Rare",
	4: "Epic"
}


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(480, 420)

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
	title.text = "CRAFTING MATERIALS"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", ThemeColors.ACCENT)
	header.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_total_label = Label.new()
	_total_label.add_theme_font_size_override("font_size", 14)
	_total_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	header.add_child(_total_label)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(15, 0)
	header.add_child(spacer2)

	_close_btn = Button.new()
	_close_btn.text = "X"
	_close_btn.custom_minimum_size = Vector2(30, 30)
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "Collect materials from enemies to craft equipment!"
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
	_content_vbox.add_theme_constant_override("separation", 12)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_vbox)

	# Footer hint
	var footer := Label.new()
	footer.text = "Use 'recipes' to view available crafting recipes"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_materials(materials: Dictionary, player_level: int) -> void:
	_materials = materials
	_player_level = player_level
	_update_total_label()
	_build_content()
	show()


func _update_total_label() -> void:
	var total: int = 0
	for mat_id in _materials.keys():
		total += int(_materials.get(mat_id, 0))
	_total_label.text = "Total: %d items" % total


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	if _materials.is_empty():
		_build_empty_state()
	else:
		_build_materials_list()

	# Always show drop info
	var drop_info := _create_drop_info_panel()
	_content_vbox.add_child(drop_info)


func _build_empty_state() -> void:
	var empty_panel := PanelContainer.new()

	var empty_style := StyleBoxFlat.new()
	empty_style.bg_color = Color(0.06, 0.06, 0.08, 0.9)
	empty_style.border_color = ThemeColors.BORDER_DISABLED
	empty_style.set_border_width_all(1)
	empty_style.set_corner_radius_all(4)
	empty_style.set_content_margin_all(20)
	empty_panel.add_theme_stylebox_override("panel", empty_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	empty_panel.add_child(vbox)

	var empty_label := Label.new()
	empty_label.text = "No materials collected yet"
	empty_label.add_theme_font_size_override("font_size", 14)
	empty_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(empty_label)

	var hint_label := Label.new()
	hint_label.text = "Defeat enemies to collect crafting materials!"
	hint_label.add_theme_font_size_override("font_size", 12)
	hint_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint_label)

	_content_vbox.add_child(empty_panel)


func _build_materials_list() -> void:
	# Group materials by tier
	var by_tier: Dictionary = {}
	for mat_id in _materials.keys():
		var mat_info: Dictionary = SimCrafting.MATERIALS.get(mat_id, {"tier": 1})
		var tier: int = int(mat_info.get("tier", 1))
		if not by_tier.has(tier):
			by_tier[tier] = []
		by_tier[tier].append(mat_id)

	# Display each tier that has materials
	for tier in [4, 3, 2, 1]:  # Reverse order - epic first
		if not by_tier.has(tier):
			continue

		var tier_panel := _create_tier_panel(tier, by_tier[tier])
		_content_vbox.add_child(tier_panel)


func _create_tier_panel(tier: int, material_ids: Array) -> Control:
	var color: Color = TIER_COLORS.get(tier, Color.WHITE)
	var tier_name: String = TIER_NAMES.get(tier, "Unknown")

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = color.darkened(0.85)
	container_style.border_color = color.darkened(0.5)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(6)
	container_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	container.add_child(vbox)

	# Header with tier name and count
	var header_hbox := HBoxContainer.new()
	vbox.add_child(header_hbox)

	var tier_label := Label.new()
	tier_label.text = "%s Materials" % tier_name
	tier_label.add_theme_font_size_override("font_size", 14)
	tier_label.add_theme_color_override("font_color", color)
	tier_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(tier_label)

	var count: int = 0
	for mat_id in material_ids:
		count += int(_materials.get(mat_id, 0))

	var count_label := Label.new()
	count_label.text = "(%d total)" % count
	count_label.add_theme_font_size_override("font_size", 12)
	count_label.add_theme_color_override("font_color", color.darkened(0.3))
	header_hbox.add_child(count_label)

	# Materials grid
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(grid)

	# Sort materials by name for consistent display
	var sorted_mats: Array = material_ids.duplicate()
	sorted_mats.sort_custom(func(a, b):
		var a_name: String = str(SimCrafting.MATERIALS.get(a, {}).get("name", a))
		var b_name: String = str(SimCrafting.MATERIALS.get(b, {}).get("name", b))
		return a_name < b_name
	)

	for mat_id in sorted_mats:
		var mat_info: Dictionary = SimCrafting.MATERIALS.get(mat_id, {})
		var mat_name: String = str(mat_info.get("name", mat_id))
		var qty: int = int(_materials.get(mat_id, 0))

		var mat_widget := _create_material_widget(mat_name, qty, color)
		grid.add_child(mat_widget)

	return container


func _create_material_widget(mat_name: String, quantity: int, color: Color) -> Control:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var name_label := Label.new()
	name_label.text = mat_name
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	name_label.custom_minimum_size = Vector2(140, 0)
	hbox.add_child(name_label)

	var qty_label := Label.new()
	qty_label.text = "x%d" % quantity
	qty_label.add_theme_font_size_override("font_size", 12)
	qty_label.add_theme_color_override("font_color", color)
	qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	qty_label.custom_minimum_size = Vector2(40, 0)
	hbox.add_child(qty_label)

	return hbox


func _create_drop_info_panel() -> Control:
	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = Color(0.06, 0.07, 0.1, 0.9)
	container_style.border_color = ThemeColors.BORDER_DISABLED
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	container.add_child(vbox)

	var header := Label.new()
	header.text = "MATERIAL SOURCES"
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(header)

	var sources: Array[Dictionary] = [
		{"source": "Regular Enemies", "tiers": "Common", "color": TIER_COLORS[1]},
		{"source": "Elite Enemies", "tiers": "Common, Uncommon", "color": TIER_COLORS[2]},
		{"source": "Bosses", "tiers": "Uncommon, Rare, Epic", "color": TIER_COLORS[3]},
		{"source": "Higher Days", "tiers": "Unlocks higher tiers", "color": Color(1.0, 0.84, 0.0)}
	]

	for source in sources:
		var source_hbox := HBoxContainer.new()
		source_hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(source_hbox)

		var source_label := Label.new()
		source_label.text = str(source.get("source", ""))
		source_label.add_theme_font_size_override("font_size", 10)
		source_label.add_theme_color_override("font_color", source.get("color", Color.WHITE))
		source_label.custom_minimum_size = Vector2(120, 0)
		source_hbox.add_child(source_label)

		var tier_label := Label.new()
		tier_label.text = str(source.get("tiers", ""))
		tier_label.add_theme_font_size_override("font_size", 10)
		tier_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		source_hbox.add_child(tier_label)

	# Tier unlock info
	var sep := Control.new()
	sep.custom_minimum_size = Vector2(0, 5)
	vbox.add_child(sep)

	var unlock_header := Label.new()
	unlock_header.text = "TIER UNLOCK DAYS"
	unlock_header.add_theme_font_size_override("font_size", 10)
	unlock_header.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(unlock_header)

	var unlock_hbox := HBoxContainer.new()
	unlock_hbox.add_theme_constant_override("separation", 15)
	vbox.add_child(unlock_hbox)

	var unlocks: Array[Dictionary] = [
		{"tier": "Uncommon", "day": 5, "color": TIER_COLORS[2]},
		{"tier": "Rare", "day": 12, "color": TIER_COLORS[3]},
		{"tier": "Epic", "day": 20, "color": TIER_COLORS[4]}
	]

	for unlock in unlocks:
		var unlock_chip := _create_unlock_chip(
			str(unlock.get("tier", "")),
			int(unlock.get("day", 0)),
			unlock.get("color", Color.WHITE)
		)
		unlock_hbox.add_child(unlock_chip)

	return container


func _create_unlock_chip(tier_name: String, unlock_day: int, color: Color) -> Control:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	var tier_label := Label.new()
	tier_label.text = tier_name
	tier_label.add_theme_font_size_override("font_size", 10)
	tier_label.add_theme_color_override("font_color", color)
	tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(tier_label)

	var day_label := Label.new()
	day_label.text = "Day %d+" % unlock_day
	day_label.add_theme_font_size_override("font_size", 9)
	day_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(day_label)

	return vbox


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
