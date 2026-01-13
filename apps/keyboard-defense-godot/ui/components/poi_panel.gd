class_name PoiPanel
extends PanelContainer
## POI Panel - Shows discovered points of interest on the map.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed
signal poi_selected(poi_id: String)

const SimPoi = preload("res://sim/poi.gd")

var _state: RefCounted = null

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null
var _poi_count_label: Label = null
var _show_all_toggle: CheckButton = null
var _show_all: bool = false

# POI type colors
const POI_COLORS: Dictionary = {
	"shrine": Color(1.0, 0.9, 0.6),
	"chest": Color(1.0, 0.84, 0.0),
	"cave": Color(0.5, 0.4, 0.3),
	"ruins": Color(0.6, 0.6, 0.7),
	"camp": Color(0.9, 0.5, 0.3),
	"spring": Color(0.4, 0.8, 1.0),
	"monument": Color(0.9, 0.9, 0.9),
	"portal": Color(0.7, 0.4, 0.9),
	"merchant": Color(0.4, 0.9, 0.4),
	"arena": Color(0.9, 0.3, 0.3)
}

# POI type icons
const POI_ICONS: Dictionary = {
	"shrine": "SHR",
	"chest": "CHT",
	"cave": "CAV",
	"ruins": "RUN",
	"camp": "CMP",
	"spring": "SPR",
	"monument": "MON",
	"portal": "PRT",
	"merchant": "MRC",
	"arena": "ARN"
}


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_MD, 440)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "POINTS OF INTEREST"
	DesignSystem.style_label(title, "h2", Color(0.4, 0.8, 1.0))
	header.add_child(title)

	header.add_child(DesignSystem.create_spacer())

	_poi_count_label = Label.new()
	DesignSystem.style_label(_poi_count_label, "body", ThemeColors.TEXT_DIM)
	header.add_child(_poi_count_label)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(15, 0)
	header.add_child(spacer2)

	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.custom_minimum_size = Vector2(DesignSystem.SIZE_BUTTON_SM, DesignSystem.SIZE_BUTTON_SM)
	_style_close_button()
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Subtitle row with toggle
	var subtitle_row := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(subtitle_row)

	var subtitle := Label.new()
	subtitle.text = "Discovered locations with special events"
	DesignSystem.style_label(subtitle, "body_small", ThemeColors.TEXT_DIM)
	subtitle_row.add_child(subtitle)

	subtitle_row.add_child(DesignSystem.create_spacer())

	_show_all_toggle = CheckButton.new()
	_show_all_toggle.text = "Show All"
	_show_all_toggle.add_theme_font_size_override("font_size", 11)
	_show_all_toggle.toggled.connect(_on_show_all_toggled)
	subtitle_row.add_child(_show_all_toggle)

	# Content scroll
	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_content_scroll)

	_content_vbox = DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_vbox)

	# Footer
	var footer := Label.new()
	footer.text = "Explore the map to discover new POIs"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_pois(state: RefCounted) -> void:
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

	var discovered_ids: Array = SimPoi.get_discovered_pois(_state)
	var all_active: Dictionary = _state.active_pois

	_poi_count_label.text = "%d discovered" % discovered_ids.size()

	if discovered_ids.is_empty() and not _show_all:
		_build_empty_state()
		return

	# Group POIs
	var active_pois: Array = []
	var interacted_pois: Array = []
	var undiscovered_pois: Array = []

	for poi_id in all_active.keys():
		var poi_state: Dictionary = all_active[poi_id]
		var discovered: bool = bool(poi_state.get("discovered", false))
		var interacted: bool = bool(poi_state.get("interacted", false))

		if interacted:
			interacted_pois.append(poi_id)
		elif discovered:
			active_pois.append(poi_id)
		else:
			undiscovered_pois.append(poi_id)

	# Active/discovered section
	if not active_pois.is_empty():
		var section := _create_section_panel("AVAILABLE", Color(0.4, 0.9, 0.4))
		_content_vbox.add_child(section)

		var vbox: VBoxContainer = section.get_child(0)
		for poi_id in active_pois:
			var card := _create_poi_card(poi_id, true)
			vbox.add_child(card)

	# Interacted/completed section
	if not interacted_pois.is_empty():
		var section := _create_section_panel("COMPLETED", Color(0.5, 0.5, 0.55))
		_content_vbox.add_child(section)

		var vbox: VBoxContainer = section.get_child(0)
		for poi_id in interacted_pois:
			var card := _create_poi_card(poi_id, false)
			vbox.add_child(card)

	# Undiscovered section (if show all)
	if _show_all and not undiscovered_pois.is_empty():
		var section := _create_section_panel("UNDISCOVERED", Color(0.4, 0.4, 0.5))
		_content_vbox.add_child(section)

		var vbox: VBoxContainer = section.get_child(0)
		for poi_id in undiscovered_pois:
			var card := _create_poi_card(poi_id, false, true)
			vbox.add_child(card)

	# POI types reference
	_build_poi_types_reference()


func _build_empty_state() -> void:
	_poi_count_label.text = "0 discovered"

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
	empty_label.text = "No points of interest discovered"
	empty_label.add_theme_font_size_override("font_size", 14)
	empty_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(empty_label)

	var hint_label := Label.new()
	hint_label.text = "Explore the map to find shrines, chests, and other special locations!"
	hint_label.add_theme_font_size_override("font_size", 12)
	hint_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(hint_label)

	_content_vbox.add_child(empty_panel)


func _create_poi_card(poi_id: String, can_interact: bool, hidden: bool = false) -> Control:
	var poi_def: Dictionary = SimPoi.get_poi(poi_id)
	var poi_state: Dictionary = _state.active_pois.get(poi_id, {}) if _state != null else {}

	var poi_name: String = str(poi_def.get("name", poi_id.capitalize()))
	var poi_type: String = str(poi_def.get("type", "unknown"))
	var description: String = str(poi_def.get("description", "A mysterious location"))
	var biome: String = str(poi_def.get("biome", "any"))
	var pos: Vector2i = poi_state.get("pos", Vector2i.ZERO) if typeof(poi_state.get("pos")) == TYPE_VECTOR2I else Vector2i.ZERO

	var color: Color = POI_COLORS.get(poi_type, Color(0.6, 0.6, 0.7))
	if hidden:
		color = color.darkened(0.5)
	elif not can_interact:
		color = color.darkened(0.3)

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = color.darkened(0.85)
	container_style.border_color = color.darkened(0.5) if can_interact else ThemeColors.BORDER_DISABLED
	container_style.set_border_width_all(1)
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
	var icon: String = POI_ICONS.get(poi_type, "POI")
	var icon_panel := _create_poi_icon(icon, color)
	header.add_child(icon_panel)

	# Name and type
	var info_vbox := VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 2)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(info_vbox)

	var name_label := Label.new()
	name_label.text = poi_name if not hidden else "???"
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", color if not hidden else ThemeColors.TEXT_DIM)
	info_vbox.add_child(name_label)

	var type_label := Label.new()
	type_label.text = poi_type.capitalize() + " | " + biome.capitalize()
	type_label.add_theme_font_size_override("font_size", 11)
	type_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	info_vbox.add_child(type_label)

	# Location
	if not hidden:
		var loc_label := Label.new()
		loc_label.text = "(%d, %d)" % [pos.x, pos.y]
		loc_label.add_theme_font_size_override("font_size", 12)
		loc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		header.add_child(loc_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = description if not hidden else "Location not yet discovered"
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_vbox.add_child(desc_label)

	# Interact button
	if can_interact:
		var btn_row := HBoxContainer.new()
		main_vbox.add_child(btn_row)

		var btn_spacer := Control.new()
		btn_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_row.add_child(btn_spacer)

		var interact_btn := Button.new()
		interact_btn.text = "INTERACT"
		interact_btn.custom_minimum_size = Vector2(100, 28)
		interact_btn.pressed.connect(func(): _on_poi_interact(poi_id))
		btn_row.add_child(interact_btn)

	return container


func _create_poi_icon(icon_text: String, color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(40, 40)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = color.darkened(0.7)
	panel_style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", panel_style)

	var label := Label.new()
	label.text = icon_text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(label)

	return panel


func _build_poi_types_reference() -> void:
	var section := _create_section_panel("POI TYPES", Color(0.5, 0.5, 0.55))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var types: Array[Dictionary] = [
		{"type": "shrine", "desc": "Grants temporary buffs"},
		{"type": "chest", "desc": "Contains gold and items"},
		{"type": "merchant", "desc": "Buy and sell items"},
		{"type": "portal", "desc": "Fast travel between areas"},
		{"type": "arena", "desc": "Combat challenge for rewards"}
	]

	for type_info in types:
		var row := _create_type_row(type_info)
		vbox.add_child(row)


func _create_type_row(type_info: Dictionary) -> Control:
	var poi_type: String = str(type_info.get("type", ""))
	var desc: String = str(type_info.get("desc", ""))
	var color: Color = POI_COLORS.get(poi_type, Color(0.6, 0.6, 0.7))
	var icon: String = POI_ICONS.get(poi_type, "POI")

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	var icon_label := Label.new()
	icon_label.text = "[%s]" % icon
	icon_label.add_theme_font_size_override("font_size", 11)
	icon_label.add_theme_color_override("font_color", color)
	icon_label.custom_minimum_size = Vector2(50, 0)
	hbox.add_child(icon_label)

	var name_label := Label.new()
	name_label.text = poi_type.capitalize()
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", color)
	name_label.custom_minimum_size = Vector2(80, 0)
	hbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = desc
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	hbox.add_child(desc_label)

	return hbox


func _create_section_panel(title: String, color: Color) -> PanelContainer:
	var container := PanelContainer.new()

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = color.darkened(0.85)
	panel_style.border_color = color.darkened(0.5)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(DesignSystem.RADIUS_SM)
	panel_style.set_content_margin_all(DesignSystem.SPACE_MD)
	container.add_theme_stylebox_override("panel", panel_style)

	var vbox := DesignSystem.create_vbox(DesignSystem.SPACE_SM)
	container.add_child(vbox)

	var header := Label.new()
	header.text = title
	DesignSystem.style_label(header, "body_small", color)
	vbox.add_child(header)

	return container


func _on_show_all_toggled(toggled: bool) -> void:
	_show_all = toggled
	_build_content()


func _on_poi_interact(poi_id: String) -> void:
	poi_selected.emit(poi_id)


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
