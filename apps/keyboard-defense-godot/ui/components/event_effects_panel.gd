class_name EventEffectsPanel
extends PanelContainer
## Event Effects Panel - Reference for event effect types.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Effect type definitions
const EFFECT_TYPES: Array[Dictionary] = [
	{
		"type": "resource_add",
		"name": "Add Resources",
		"description": "Adds or removes resources (wood, stone, food, gold)",
		"color": Color(0.5, 0.8, 0.3),
		"example": "+5 wood, +3 food"
	},
	{
		"type": "buff_apply",
		"name": "Apply Buff",
		"description": "Grants a temporary buff for a number of days",
		"color": Color(0.4, 0.8, 1.0),
		"example": "Production +50% for 3 days"
	},
	{
		"type": "damage_castle",
		"name": "Castle Damage",
		"description": "Deals damage directly to your castle HP",
		"color": Color(0.9, 0.4, 0.4),
		"example": "-2 Castle HP"
	},
	{
		"type": "heal_castle",
		"name": "Castle Heal",
		"description": "Restores HP to your castle (up to max)",
		"color": Color(0.4, 0.9, 0.4),
		"example": "+1 Castle HP"
	},
	{
		"type": "threat_add",
		"name": "Modify Threat",
		"description": "Increases or decreases current threat level",
		"color": Color(0.9, 0.5, 0.3),
		"example": "+10 Threat"
	},
	{
		"type": "ap_add",
		"name": "Action Points",
		"description": "Grants or removes action points",
		"color": Color(1.0, 0.84, 0.0),
		"example": "+2 AP"
	},
	{
		"type": "set_flag",
		"name": "Set Flag",
		"description": "Sets a persistent flag for story/quest tracking",
		"color": Color(0.7, 0.5, 0.9),
		"example": "explored_ruins = true"
	},
	{
		"type": "clear_flag",
		"name": "Clear Flag",
		"description": "Removes a previously set flag",
		"color": Color(0.5, 0.5, 0.6),
		"example": "Remove explored_ruins"
	}
]

# Common buffs
const COMMON_BUFFS: Array[Dictionary] = [
	{
		"id": "production_boost",
		"name": "Production Boost",
		"description": "+50% resource production",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"id": "combat_vigor",
		"name": "Combat Vigor",
		"description": "+25% tower damage",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"id": "trade_bonus",
		"name": "Trade Bonus",
		"description": "+20% trade value",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"id": "scout_sense",
		"name": "Scout Sense",
		"description": "Reveals POIs in a wider area",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"id": "arcane_insight",
		"name": "Arcane Insight",
		"description": "+1 research progress per day",
		"color": Color(0.7, 0.5, 0.9)
	}
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 540)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "EVENT EFFECTS"
	DesignSystem.style_label(title, "h2", Color(0.7, 0.5, 0.9))
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
	subtitle.text = "Types of effects that events can trigger"
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
	footer.text = "Events are triggered at POIs and during exploration"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_event_effects() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Effect types section
	_build_effects_section()

	# Common buffs section
	_build_buffs_section()

	# Tips section
	_build_tips_section()


func _build_effects_section() -> void:
	var section := _create_section_panel("EFFECT TYPES", Color(0.7, 0.5, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for effect_info in EFFECT_TYPES:
		var card := _create_effect_card(effect_info)
		vbox.add_child(card)


func _create_effect_card(effect_info: Dictionary) -> Control:
	var name_str: String = str(effect_info.get("name", ""))
	var description: String = str(effect_info.get("description", ""))
	var example: String = str(effect_info.get("example", ""))
	var color: Color = effect_info.get("color", Color.WHITE)

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = color.darkened(0.85)
	container_style.border_color = color.darkened(0.6)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(8)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	container.add_child(vbox)

	# Name
	var name_label := Label.new()
	name_label.text = name_str
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", color)
	vbox.add_child(name_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	# Example
	if not example.is_empty():
		var example_label := Label.new()
		example_label.text = "Example: " + example
		example_label.add_theme_font_size_override("font_size", 9)
		example_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
		vbox.add_child(example_label)

	return container


func _build_buffs_section() -> void:
	var section := _create_section_panel("COMMON BUFFS", Color(0.4, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for buff_info in COMMON_BUFFS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var name_str: String = str(buff_info.get("name", ""))
		var description: String = str(buff_info.get("description", ""))
		var color: Color = buff_info.get("color", Color.WHITE)

		var name_label := Label.new()
		name_label.text = name_str
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", color)
		name_label.custom_minimum_size = Vector2(120, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = description
		desc_label.add_theme_font_size_override("font_size", 10)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("TIPS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var tips: Array[String] = [
		"Positive effects often require typing a phrase correctly",
		"Failed attempts may trigger negative effects instead",
		"Buffs stack with upgrades and building bonuses",
		"Some events have chain effects that unlock new events"
	]

	for tip in tips:
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
