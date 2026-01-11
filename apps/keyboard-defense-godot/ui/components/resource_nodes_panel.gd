class_name ResourceNodesPanel
extends PanelContainer
## Resource Nodes Panel - Shows discovered resource nodes for typing challenges

signal closed
signal harvest_requested(pos: Vector2i)

const ThemeColors = preload("res://ui/theme_colors.gd")
const SimResourceNodes = preload("res://sim/resource_nodes.gd")

var _state: RefCounted = null

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null
var _node_count_label: Label = null

# Node type colors
const NODE_COLORS: Dictionary = {
	"ore_vein": Color(0.6, 0.6, 0.7),
	"crystal_deposit": Color(0.7, 0.9, 1.0),
	"herb_patch": Color(0.4, 0.8, 0.4),
	"ancient_tree": Color(0.6, 0.4, 0.2),
	"mana_spring": Color(0.6, 0.4, 0.9),
	"gold_mine": Color(1.0, 0.84, 0.0),
	"food_cache": Color(0.9, 0.7, 0.4)
}

# Challenge type icons
const CHALLENGE_ICONS: Dictionary = {
	"word_burst": "BURST",
	"speed_type": "SPEED",
	"accuracy_test": "ACC"
}


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(480, 440)

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
	title.text = "RESOURCE NODES"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	header.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_node_count_label = Label.new()
	_node_count_label.add_theme_font_size_override("font_size", 14)
	_node_count_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	header.add_child(_node_count_label)

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
	subtitle.text = "Points of interest with typing challenges for resources"
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
	footer.text = "Complete typing challenges to harvest resources"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_nodes(state: RefCounted) -> void:
	_state = state
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	if _state == null:
		_build_empty_state()
		return

	var nodes: Array = SimResourceNodes.get_discovered_nodes(_state)
	_node_count_label.text = "%d discovered" % nodes.size()

	if nodes.is_empty():
		_build_empty_state()
	else:
		_build_node_list(nodes)

	# Performance tips
	_build_performance_info()

	# Respawn info
	_build_respawn_info()


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
	empty_label.text = "No resource nodes discovered"
	empty_label.add_theme_font_size_override("font_size", 14)
	empty_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(empty_label)

	var hint_label := Label.new()
	hint_label.text = "Explore the map to discover resource nodes! Look for sparkling terrain tiles."
	hint_label.add_theme_font_size_override("font_size", 12)
	hint_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(hint_label)

	_content_vbox.add_child(empty_panel)


func _build_node_list(nodes: Array) -> void:
	# Group by availability
	var available: Array = []
	var depleted: Array = []

	for node in nodes:
		var harvests: int = int(node.get("harvests_remaining", 0))
		if harvests > 0:
			available.append(node)
		else:
			depleted.append(node)

	# Available nodes section
	if not available.is_empty():
		var section := _create_section_panel("AVAILABLE NODES", Color(0.4, 0.9, 0.4))
		_content_vbox.add_child(section)

		var vbox: VBoxContainer = section.get_child(0)
		for node in available:
			var card := _create_node_card(node, true)
			vbox.add_child(card)

	# Depleted nodes section
	if not depleted.is_empty():
		var section := _create_section_panel("DEPLETED (RESPAWNING)", Color(0.5, 0.5, 0.55))
		_content_vbox.add_child(section)

		var vbox: VBoxContainer = section.get_child(0)
		for node in depleted:
			var card := _create_node_card(node, false)
			vbox.add_child(card)


func _create_node_card(node: Dictionary, can_harvest: bool) -> Control:
	var node_type: String = str(node.get("node_type", ""))
	var node_id: String = str(node.get("node_id", ""))
	var pos_x: int = int(node.get("pos_x", 0))
	var pos_y: int = int(node.get("pos_y", 0))
	var harvests: int = int(node.get("harvests_remaining", 0))
	var max_harvests: int = int(node.get("max_harvests", 1))
	var base_yield: Dictionary = node.get("base_yield", {})

	var definition: Dictionary = SimResourceNodes.get_node_type_definition(node_type)
	var display_name: String = str(definition.get("name", node_type.replace("_", " ").capitalize()))
	var challenge: Dictionary = definition.get("challenge", {})
	var challenge_type: String = str(challenge.get("type", "word_burst"))

	var color: Color = NODE_COLORS.get(node_type, Color(0.6, 0.7, 0.6))
	if not can_harvest:
		color = color.darkened(0.4)

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = color.darkened(0.8)
	container_style.border_color = color.darkened(0.4) if can_harvest else ThemeColors.BORDER_DISABLED
	container_style.set_border_width_all(1 if can_harvest else 1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", container_style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 6)
	container.add_child(main_vbox)

	# Header row
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	main_vbox.add_child(header)

	# Icon
	var icon_panel := _create_node_icon(node_type, color)
	header.add_child(icon_panel)

	# Name and location
	var info_vbox := VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 2)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(info_vbox)

	var name_label := Label.new()
	name_label.text = display_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", color if can_harvest else color.darkened(0.3))
	info_vbox.add_child(name_label)

	var loc_label := Label.new()
	loc_label.text = "Location: (%d, %d)" % [pos_x, pos_y]
	loc_label.add_theme_font_size_override("font_size", 11)
	loc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	info_vbox.add_child(loc_label)

	# Harvest count
	var harvest_vbox := VBoxContainer.new()
	harvest_vbox.add_theme_constant_override("separation", 2)
	header.add_child(harvest_vbox)

	var harvest_label := Label.new()
	harvest_label.text = "%d/%d" % [harvests, max_harvests]
	harvest_label.add_theme_font_size_override("font_size", 16)
	harvest_label.add_theme_color_override("font_color", color if can_harvest else ThemeColors.TEXT_DIM)
	harvest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	harvest_vbox.add_child(harvest_label)

	var uses_label := Label.new()
	uses_label.text = "harvests"
	uses_label.add_theme_font_size_override("font_size", 10)
	uses_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	uses_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	harvest_vbox.add_child(uses_label)

	# Details row
	var details := HBoxContainer.new()
	details.add_theme_constant_override("separation", 20)
	main_vbox.add_child(details)

	# Yields
	var yields_hbox := HBoxContainer.new()
	yields_hbox.add_theme_constant_override("separation", 8)
	details.add_child(yields_hbox)

	var yields_title := Label.new()
	yields_title.text = "Yields:"
	yields_title.add_theme_font_size_override("font_size", 11)
	yields_title.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	yields_hbox.add_child(yields_title)

	for resource in base_yield.keys():
		var amount: int = int(base_yield[resource])
		var res_label := Label.new()
		res_label.text = "%d %s" % [amount, resource]
		res_label.add_theme_font_size_override("font_size", 11)
		res_label.add_theme_color_override("font_color", _get_resource_color(resource))
		yields_hbox.add_child(res_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_child(spacer)

	# Challenge type
	var challenge_label := Label.new()
	var challenge_icon: String = CHALLENGE_ICONS.get(challenge_type, "TYPE")
	challenge_label.text = "[%s]" % challenge_icon
	challenge_label.add_theme_font_size_override("font_size", 11)
	challenge_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4) if can_harvest else ThemeColors.TEXT_DIM)
	details.add_child(challenge_label)

	# Harvest button (only if can harvest)
	if can_harvest:
		var btn_row := HBoxContainer.new()
		main_vbox.add_child(btn_row)

		var btn_spacer := Control.new()
		btn_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_row.add_child(btn_spacer)

		var harvest_btn := Button.new()
		harvest_btn.text = "HARVEST"
		harvest_btn.custom_minimum_size = Vector2(100, 28)
		harvest_btn.pressed.connect(func(): _on_harvest_pressed(Vector2i(pos_x, pos_y)))
		btn_row.add_child(harvest_btn)
	else:
		# Respawn info
		var respawn_label := Label.new()
		var last_day: int = int(node.get("last_harvested_day", 0))
		var respawn_days: int = int(node.get("respawn_days", 5))
		var current_day: int = _state.day if _state != null else 0
		var days_left: int = max(0, (last_day + respawn_days) - current_day)
		respawn_label.text = "Respawns in %d days" % days_left
		respawn_label.add_theme_font_size_override("font_size", 11)
		respawn_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		respawn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		main_vbox.add_child(respawn_label)

	return container


func _create_node_icon(node_type: String, color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(40, 40)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = color.darkened(0.6)
	panel_style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", panel_style)

	var icon_text: String = _get_node_icon(node_type)

	var label := Label.new()
	label.text = icon_text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(label)

	return panel


func _get_node_icon(node_type: String) -> String:
	match node_type:
		"ore_vein":
			return "ORE"
		"crystal_deposit":
			return "CRY"
		"herb_patch":
			return "HRB"
		"ancient_tree":
			return "TRE"
		"mana_spring":
			return "MNA"
		"gold_mine":
			return "GLD"
		"food_cache":
			return "FD"
		_:
			return "NOD"


func _get_resource_color(resource: String) -> Color:
	match resource:
		"gold":
			return Color(1.0, 0.84, 0.0)
		"wood":
			return Color(0.6, 0.4, 0.2)
		"stone":
			return Color(0.7, 0.7, 0.75)
		"food":
			return Color(0.4, 0.8, 0.3)
		"iron":
			return Color(0.5, 0.5, 0.6)
		"mana":
			return Color(0.5, 0.4, 0.9)
		"crystal":
			return Color(0.7, 0.9, 1.0)
		_:
			return Color(0.7, 0.7, 0.7)


func _build_performance_info() -> void:
	var section := _create_section_panel("HARVEST QUALITY", Color(0.4, 0.6, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var tiers: Array[Dictionary] = [
		{"label": "Perfect (100% acc, fast)", "mult": "200%", "color": Color(1.0, 0.8, 0.2)},
		{"label": "Excellent (95%+ acc)", "mult": "150%", "color": Color(0.4, 0.6, 1.0)},
		{"label": "Good (pass challenge)", "mult": "100%", "color": Color(0.4, 0.9, 0.4)},
		{"label": "Failed", "mult": "50%", "color": Color(0.6, 0.6, 0.6)}
	]

	for tier in tiers:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		vbox.add_child(row)

		var label := Label.new()
		label.text = str(tier.get("label", ""))
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		var mult := Label.new()
		mult.text = str(tier.get("mult", ""))
		mult.add_theme_font_size_override("font_size", 11)
		mult.add_theme_color_override("font_color", tier.get("color", Color.WHITE))
		row.add_child(mult)


func _build_respawn_info() -> void:
	if _state == null:
		return

	var harvested_count: int = _state.harvested_nodes.size()
	if harvested_count == 0:
		return

	var section := _create_section_panel("RESPAWN QUEUE", Color(0.5, 0.5, 0.55))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var info_label := Label.new()
	info_label.text = "%d depleted nodes waiting to respawn" % harvested_count
	info_label.add_theme_font_size_override("font_size", 11)
	info_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(info_label)


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
	vbox.add_theme_constant_override("separation", 8)
	container.add_child(vbox)

	var header := Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", color)
	vbox.add_child(header)

	return container


func _on_harvest_pressed(pos: Vector2i) -> void:
	harvest_requested.emit(pos)


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
