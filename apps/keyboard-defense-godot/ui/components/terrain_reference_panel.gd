class_name TerrainReferencePanel
extends PanelContainer
## Terrain Reference Panel - Shows terrain types and map mechanics.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Terrain types
const TERRAIN_TYPES: Array[Dictionary] = [
	{
		"id": "plains",
		"name": "Plains",
		"symbol": ".",
		"chance": "45%",
		"buildable": true,
		"passable": true,
		"bonus": "No special effects",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"id": "forest",
		"name": "Forest",
		"symbol": "f",
		"chance": "30%",
		"buildable": true,
		"passable": true,
		"bonus": "+1 wood to adjacent Lumber Mill",
		"color": Color(0.2, 0.6, 0.2)
	},
	{
		"id": "mountain",
		"name": "Mountain",
		"symbol": "m",
		"chance": "15%",
		"buildable": true,
		"passable": true,
		"bonus": "+1 stone to adjacent Quarry",
		"color": Color(0.5, 0.5, 0.6)
	},
	{
		"id": "water",
		"name": "Water",
		"symbol": "~",
		"chance": "10%",
		"buildable": false,
		"passable": false,
		"bonus": "+1 food to adjacent Farm",
		"color": Color(0.2, 0.5, 0.9)
	}
]

# Map symbols
const MAP_SYMBOLS: Array[Dictionary] = [
	{"symbol": "B", "name": "Base", "desc": "Your castle - defend it!", "color": Color(1.0, 0.84, 0.0)},
	{"symbol": "@", "name": "Cursor", "desc": "Your current position", "color": Color(0.9, 0.9, 0.9)},
	{"symbol": "?", "name": "Unknown", "desc": "Undiscovered territory", "color": Color(0.4, 0.4, 0.4)},
	{"symbol": "F", "name": "Farm", "desc": "Produces food", "color": Color(0.5, 0.8, 0.3)},
	{"symbol": "L", "name": "Lumber", "desc": "Produces wood", "color": Color(0.6, 0.4, 0.2)},
	{"symbol": "Q", "name": "Quarry", "desc": "Produces stone", "color": Color(0.5, 0.5, 0.6)},
	{"symbol": "W", "name": "Wall", "desc": "Blocks enemies", "color": Color(0.4, 0.8, 1.0)},
	{"symbol": "T", "name": "Tower", "desc": "Attacks enemies", "color": Color(0.9, 0.4, 0.4)}
]

# Map mechanics
const MAP_MECHANICS: Array[Dictionary] = [
	{
		"topic": "Discovery",
		"desc": "Move cursor to reveal adjacent tiles",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"topic": "Buildable",
		"desc": "Can only build on discovered, non-water tiles",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"topic": "Pathfinding",
		"desc": "Enemies find paths around walls to your base",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"topic": "Adjacency",
		"desc": "Buildings near terrain get production bonuses",
		"color": Color(1.0, 0.84, 0.0)
	}
]

# Tips
const MAP_TIPS: Array[String] = [
	"Place Farms near water for +1 food bonus",
	"Place Lumber Mills near forests for +1 wood bonus",
	"Place Quarries near mountains for +1 stone bonus",
	"Walls block enemy paths - use strategically",
	"Towers near walls get +1 defense",
	"Always leave a path to your base or enemies stack up"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 600)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "TERRAIN & MAP"
	DesignSystem.style_label(title, "h2", Color(0.5, 0.8, 0.3))
	header.add_child(title)

	header.add_child(DesignSystem.create_spacer())

	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.custom_minimum_size = Vector2(DesignSystem.SIZE_BUTTON_SM, DesignSystem.SIZE_BUTTON_SM)
	_style_close_button()
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "Understanding the world of Keystonia"
	DesignSystem.style_label(subtitle, "body_small", ThemeColors.TEXT_DIM)
	main_vbox.add_child(subtitle)

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
	footer.text = "Type MOVE to navigate the map"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_terrain_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Terrain types section
	_build_terrain_section()

	# Map symbols section
	_build_symbols_section()

	# Mechanics section
	_build_mechanics_section()

	# Tips section
	_build_tips_section()


func _build_terrain_section() -> void:
	var section := _create_section_panel("TERRAIN TYPES", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for terrain in TERRAIN_TYPES:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 2)
		vbox.add_child(container)

		var name_row := HBoxContainer.new()
		name_row.add_theme_constant_override("separation", 8)
		container.add_child(name_row)

		var symbol_label := Label.new()
		symbol_label.text = "[%s]" % terrain.get("symbol", "?")
		symbol_label.add_theme_font_size_override("font_size", 10)
		symbol_label.add_theme_color_override("font_color", terrain.get("color", Color.WHITE))
		symbol_label.custom_minimum_size = Vector2(30, 0)
		name_row.add_child(symbol_label)

		var name_label := Label.new()
		name_label.text = str(terrain.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", terrain.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(70, 0)
		name_row.add_child(name_label)

		var chance_label := Label.new()
		chance_label.text = str(terrain.get("chance", ""))
		chance_label.add_theme_font_size_override("font_size", 9)
		chance_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		chance_label.custom_minimum_size = Vector2(40, 0)
		name_row.add_child(chance_label)

		var build_text: String = "Buildable" if terrain.get("buildable", false) else "Not buildable"
		var pass_text: String = "Passable" if terrain.get("passable", false) else "Blocked"
		var flags_label := Label.new()
		flags_label.text = "%s, %s" % [build_text, pass_text]
		flags_label.add_theme_font_size_override("font_size", 9)
		flags_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		name_row.add_child(flags_label)

		var bonus_label := Label.new()
		bonus_label.text = "  " + str(terrain.get("bonus", ""))
		bonus_label.add_theme_font_size_override("font_size", 9)
		bonus_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		container.add_child(bonus_label)


func _build_symbols_section() -> void:
	var section := _create_section_panel("MAP SYMBOLS", Color(0.4, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for sym in MAP_SYMBOLS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var symbol_label := Label.new()
		symbol_label.text = "[%s]" % sym.get("symbol", "?")
		symbol_label.add_theme_font_size_override("font_size", 10)
		symbol_label.add_theme_color_override("font_color", sym.get("color", Color.WHITE))
		symbol_label.custom_minimum_size = Vector2(30, 0)
		hbox.add_child(symbol_label)

		var name_label := Label.new()
		name_label.text = str(sym.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", sym.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(60, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(sym.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_mechanics_section() -> void:
	var section := _create_section_panel("MAP MECHANICS", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in MAP_MECHANICS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var topic_label := Label.new()
		topic_label.text = str(info.get("topic", ""))
		topic_label.add_theme_font_size_override("font_size", 10)
		topic_label.add_theme_color_override("font_color", info.get("color", Color.WHITE))
		topic_label.custom_minimum_size = Vector2(90, 0)
		hbox.add_child(topic_label)

		var desc_label := Label.new()
		desc_label.text = str(info.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("MAP TIPS", Color(0.7, 0.5, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in MAP_TIPS:
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


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
