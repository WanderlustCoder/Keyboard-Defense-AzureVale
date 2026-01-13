class_name TrapsReferencePanel
extends PanelContainer
## Traps Reference Panel - Shows trap types and mechanics.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Trap types (from SimTowerTypes)
const TRAP_TYPES: Array[Dictionary] = [
	{
		"id": "explosive",
		"name": "Explosive Trap",
		"damage": 30,
		"radius": 1.0,
		"effect": "",
		"desc": "High damage, single trigger",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"id": "frost",
		"name": "Frost Trap",
		"damage": 10,
		"radius": 1.5,
		"effect": "Slow 50% for 3s",
		"desc": "Low damage but slows enemies",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"id": "poison",
		"name": "Poison Trap",
		"damage": 5,
		"radius": 1.0,
		"effect": "Poison 10 dmg/s for 5s",
		"desc": "DoT damage over time",
		"color": Color(0.5, 0.9, 0.3)
	},
	{
		"id": "stun",
		"name": "Stun Trap",
		"damage": 15,
		"radius": 0.5,
		"effect": "Stun for 2s",
		"desc": "Small area but stops enemies",
		"color": Color(0.9, 0.9, 0.4)
	}
]

# Trap mechanics
const TRAP_MECHANICS: Array[Dictionary] = [
	{
		"topic": "Placement",
		"desc": "Use the Trapper Tower to place traps on the map",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"topic": "Trigger",
		"desc": "Traps activate when enemies walk over them",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"topic": "One-Time",
		"desc": "Most traps are consumed after triggering once",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"topic": "Radius",
		"desc": "Traps affect all enemies within their radius",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"topic": "Stacking",
		"desc": "Multiple traps can be placed in the same area",
		"color": Color(0.7, 0.5, 0.9)
	}
]

# Trap strategies
const TRAP_TIPS: Array[String] = [
	"Place frost traps at choke points to slow groups",
	"Stack explosive traps for burst damage on bosses",
	"Poison traps work best on high-HP enemies",
	"Stun traps can interrupt dangerous abilities",
	"Combine trap types for maximum effectiveness"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 520)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "TRAP SYSTEM"
	DesignSystem.style_label(title, "h2", Color(0.9, 0.6, 0.3))
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
	subtitle.text = "Deployable hazards placed by Trapper Towers"
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
	footer.text = "Build Trapper Towers to deploy traps!"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_traps_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Mechanics section
	_build_mechanics_section()

	# Trap types section
	_build_trap_types_section()

	# Tips section
	_build_tips_section()


func _build_mechanics_section() -> void:
	var section := _create_section_panel("HOW TRAPS WORK", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in TRAP_MECHANICS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var topic_label := Label.new()
		topic_label.text = str(info.get("topic", ""))
		topic_label.add_theme_font_size_override("font_size", 10)
		topic_label.add_theme_color_override("font_color", info.get("color", Color.WHITE))
		topic_label.custom_minimum_size = Vector2(80, 0)
		hbox.add_child(topic_label)

		var desc_label := Label.new()
		desc_label.text = str(info.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_trap_types_section() -> void:
	var section := _create_section_panel("TRAP TYPES", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for trap in TRAP_TYPES:
		var card := _create_trap_card(trap)
		vbox.add_child(card)


func _create_trap_card(trap: Dictionary) -> Control:
	var name: String = str(trap.get("name", ""))
	var damage: int = int(trap.get("damage", 0))
	var radius: float = float(trap.get("radius", 1.0))
	var effect: String = str(trap.get("effect", ""))
	var desc: String = str(trap.get("desc", ""))
	var color: Color = trap.get("color", Color.WHITE)

	var container := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = color.darkened(0.8)
	card_style.border_color = color.darkened(0.5)
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(4)
	card_style.set_content_margin_all(8)
	container.add_theme_stylebox_override("panel", card_style)

	var card_vbox := VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 4)
	container.add_child(card_vbox)

	# Name and description row
	var name_row := HBoxContainer.new()
	card_vbox.add_child(name_row)

	var name_label := Label.new()
	name_label.text = name
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", color)
	name_row.add_child(name_label)

	var desc_spacer := Control.new()
	desc_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(desc_spacer)

	var desc_label := Label.new()
	desc_label.text = desc
	desc_label.add_theme_font_size_override("font_size", 9)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	name_row.add_child(desc_label)

	# Stats row
	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 15)
	card_vbox.add_child(stats_row)

	var dmg_label := Label.new()
	dmg_label.text = "%d DMG" % damage
	dmg_label.add_theme_font_size_override("font_size", 10)
	dmg_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
	stats_row.add_child(dmg_label)

	var radius_label := Label.new()
	radius_label.text = "%.1f radius" % radius
	radius_label.add_theme_font_size_override("font_size", 10)
	radius_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	stats_row.add_child(radius_label)

	if not effect.is_empty():
		var effect_label := Label.new()
		effect_label.text = effect
		effect_label.add_theme_font_size_override("font_size", 10)
		effect_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		stats_row.add_child(effect_label)

	return container


func _build_tips_section() -> void:
	var section := _create_section_panel("TRAP STRATEGIES", Color(0.4, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in TRAP_TIPS:
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
