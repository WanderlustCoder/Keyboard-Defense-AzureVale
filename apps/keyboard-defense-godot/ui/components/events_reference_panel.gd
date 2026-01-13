class_name EventsReferencePanel
extends PanelContainer
## Events Reference Panel - Shows event system mechanics and effect types.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Event types
const EVENT_TYPES: Array[Dictionary] = [
	{
		"name": "Resource Events",
		"desc": "Add or remove gold, wood, stone, food",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"name": "Combat Events",
		"desc": "Spawn extra enemies or trigger battles",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"name": "Buff Events",
		"desc": "Apply temporary bonuses or penalties",
		"color": Color(0.4, 0.9, 0.4)
	},
	{
		"name": "Story Events",
		"desc": "Progress the narrative with choices",
		"color": Color(0.7, 0.5, 0.9)
	}
]

# Effect types
const EFFECT_TYPES: Array[Dictionary] = [
	{
		"name": "resource_add",
		"desc": "Gain or lose resources",
		"example": "+50 gold, -10 wood",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"name": "buff_apply",
		"desc": "Temporary stat modifier",
		"example": "+20% damage for 3 days",
		"color": Color(0.4, 0.9, 0.4)
	},
	{
		"name": "damage_castle",
		"desc": "Lose castle HP",
		"example": "-2 HP",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"name": "heal_castle",
		"desc": "Restore castle HP",
		"example": "+1 HP",
		"color": Color(0.5, 0.9, 0.3)
	},
	{
		"name": "threat_add",
		"desc": "Increase threat level",
		"example": "+10 threat",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"name": "ap_add",
		"desc": "Gain or lose action points",
		"example": "+2 AP",
		"color": Color(0.4, 0.8, 1.0)
	}
]

# Event mechanics
const EVENT_MECHANICS: Array[Dictionary] = [
	{
		"topic": "POI Triggers",
		"desc": "Events trigger when interacting with map locations",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"topic": "Choices",
		"desc": "Most events offer 2-4 choices with different outcomes",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"topic": "Typing Input",
		"desc": "Some choices require typing specific words",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"topic": "Cooldowns",
		"desc": "Events may have cooldowns before appearing again",
		"color": Color(0.7, 0.5, 0.9)
	},
	{
		"topic": "Conditions",
		"desc": "Events may require certain day ranges or resources",
		"color": Color(0.9, 0.9, 0.4)
	}
]

# Tips for events
const EVENT_TIPS: Array[String] = [
	"Read choice descriptions carefully before deciding",
	"Some events have hidden benefits or risks",
	"Resource events are more generous in early game",
	"Story events can unlock new areas and features",
	"High-risk choices often have high rewards"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_MD, 580)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "EVENT SYSTEM"
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
	subtitle.text = "Interactive encounters on the map"
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
	footer.text = "Explore POIs to discover events!"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_events_reference() -> void:
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

	# Event types section
	_build_types_section()

	# Effect types section
	_build_effects_section()

	# Tips section
	_build_tips_section()


func _build_mechanics_section() -> void:
	var section := _create_section_panel("HOW EVENTS WORK", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in EVENT_MECHANICS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var topic_label := Label.new()
		topic_label.text = str(info.get("topic", ""))
		topic_label.add_theme_font_size_override("font_size", 10)
		topic_label.add_theme_color_override("font_color", info.get("color", Color.WHITE))
		topic_label.custom_minimum_size = Vector2(100, 0)
		hbox.add_child(topic_label)

		var desc_label := Label.new()
		desc_label.text = str(info.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_types_section() -> void:
	var section := _create_section_panel("EVENT CATEGORIES", Color(0.7, 0.5, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for event_type in EVENT_TYPES:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(event_type.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", event_type.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(120, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(event_type.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_effects_section() -> void:
	var section := _create_section_panel("EFFECT TYPES", Color(0.4, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for effect in EFFECT_TYPES:
		var card := _create_effect_card(effect)
		vbox.add_child(card)


func _create_effect_card(effect: Dictionary) -> Control:
	var name: String = str(effect.get("name", ""))
	var desc: String = str(effect.get("desc", ""))
	var example: String = str(effect.get("example", ""))
	var color: Color = effect.get("color", Color.WHITE)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var name_label := Label.new()
	name_label.text = name
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.add_theme_color_override("font_color", color)
	name_label.custom_minimum_size = Vector2(90, 0)
	hbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = desc
	desc_label.add_theme_font_size_override("font_size", 9)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	desc_label.custom_minimum_size = Vector2(140, 0)
	hbox.add_child(desc_label)

	var example_label := Label.new()
	example_label.text = example
	example_label.add_theme_font_size_override("font_size", 9)
	example_label.add_theme_color_override("font_color", color.lightened(0.3))
	hbox.add_child(example_label)

	return hbox


func _build_tips_section() -> void:
	var section := _create_section_panel("EVENT TIPS", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in EVENT_TIPS:
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
