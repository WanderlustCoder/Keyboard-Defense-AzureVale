class_name WaveCompositionPanel
extends PanelContainer
## Wave Composition Panel - Shows wave themes and modifiers.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Wave themes (from SimWaveComposer)
const WAVE_THEMES: Array[Dictionary] = [
	{
		"id": "standard",
		"name": "Standard Assault",
		"description": "Balanced mix of enemies",
		"color": Color(0.6, 0.6, 0.7)
	},
	{
		"id": "swarm",
		"name": "Swarming Tide",
		"description": "Many weak enemies (x1.5 count, x0.6 HP)",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"id": "elite",
		"name": "Elite Vanguard",
		"description": "Fewer but stronger (x0.6 count, x1.5 HP, x1.5 gold)",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"id": "speedy",
		"name": "Swift Raiders",
		"description": "Fast-moving enemies (x1.4 speed)",
		"color": Color(0.4, 0.9, 0.9)
	},
	{
		"id": "tanky",
		"name": "Iron Wall",
		"description": "Slow but durable (x0.7 speed, x1.8 HP)",
		"color": Color(0.6, 0.6, 0.7)
	},
	{
		"id": "magic",
		"name": "Arcane Invasion",
		"description": "Magical creatures (specters, elementals)",
		"color": Color(0.7, 0.5, 0.9)
	},
	{
		"id": "undead",
		"name": "Undead Uprising",
		"description": "Risen horrors (x0.7 gold)",
		"color": Color(0.5, 0.5, 0.6)
	},
	{
		"id": "burning",
		"name": "Infernal Tide",
		"description": "Fire-aligned enemies (30% burning affix)",
		"color": Color(0.9, 0.4, 0.2)
	},
	{
		"id": "frozen",
		"name": "Frozen Legion",
		"description": "Ice-aligned enemies (30% frozen affix)",
		"color": Color(0.4, 0.7, 0.9)
	}
]

# Wave modifiers
const WAVE_MODIFIERS: Array[Dictionary] = [
	{
		"id": "armored",
		"name": "Armored Assault",
		"description": "40% enemies have armor",
		"color": Color(0.6, 0.6, 0.7)
	},
	{
		"id": "swift",
		"name": "Swift Advance",
		"description": "x1.3 movement speed",
		"color": Color(0.4, 0.9, 0.9)
	},
	{
		"id": "enraged",
		"name": "Enraged Horde",
		"description": "x1.5 enemy damage",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"id": "toxic",
		"name": "Toxic Menace",
		"description": "25% toxic affix",
		"color": Color(0.5, 0.9, 0.3)
	},
	{
		"id": "shielded",
		"name": "Shield Wall",
		"description": "20% shielded affix",
		"color": Color(0.6, 0.8, 1.0)
	},
	{
		"id": "vampiric",
		"name": "Blood Drinkers",
		"description": "15% vampiric affix",
		"color": Color(0.9, 0.3, 0.5)
	},
	{
		"id": "treasure",
		"name": "Treasure Carriers",
		"description": "x2.0 gold drops",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"id": "double_trouble",
		"name": "Double Trouble",
		"description": "x2.0 count, x0.5 HP",
		"color": Color(0.9, 0.6, 0.3)
	}
]

# Special waves
const SPECIAL_WAVES: Array[Dictionary] = [
	{
		"id": "ambush",
		"name": "Ambush!",
		"description": "Enemies spawn from multiple directions",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"id": "boss_rush",
		"name": "Boss Rush",
		"description": "Multiple mini-bosses attack",
		"color": Color(0.9, 0.5, 0.9)
	}
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 560)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "WAVE COMPOSITION"
	DesignSystem.style_label(title, "h2", Color(0.9, 0.4, 0.4))
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
	subtitle.text = "Wave themes and modifiers that affect enemy spawns"
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
	footer.text = "Wave themes are revealed at the start of each night"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_wave_composition() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Wave themes section
	_build_themes_section()

	# Wave modifiers section
	_build_modifiers_section()

	# Special waves section
	_build_special_section()


func _build_themes_section() -> void:
	var section := _create_section_panel("WAVE THEMES", Color(0.9, 0.4, 0.4))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for theme in WAVE_THEMES:
		var card := _create_info_card(theme)
		vbox.add_child(card)


func _build_modifiers_section() -> void:
	var section := _create_section_panel("WAVE MODIFIERS", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for modifier in WAVE_MODIFIERS:
		var card := _create_info_card(modifier)
		vbox.add_child(card)


func _build_special_section() -> void:
	var section := _create_section_panel("SPECIAL WAVES", Color(0.9, 0.5, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for special in SPECIAL_WAVES:
		var card := _create_info_card(special)
		vbox.add_child(card)


func _create_info_card(info: Dictionary) -> Control:
	var name_str: String = str(info.get("name", ""))
	var description: String = str(info.get("description", ""))
	var color: Color = info.get("color", Color.WHITE)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	var name_label := Label.new()
	name_label.text = name_str
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", color)
	name_label.custom_minimum_size = Vector2(130, 0)
	hbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
