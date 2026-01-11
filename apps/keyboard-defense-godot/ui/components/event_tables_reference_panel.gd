class_name EventTablesReferencePanel
extends PanelContainer
## Event Tables Reference Panel - Shows event selection mechanics

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Event selection mechanics
const SELECTION_MECHANICS: Array[Dictionary] = [
	{
		"topic": "Weighted Selection",
		"desc": "Events have weights - higher weight = more likely",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"topic": "Condition Checks",
		"desc": "Events can require specific conditions to trigger",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"topic": "Cooldowns",
		"desc": "Events can have cooldown periods before repeating",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"topic": "Flags",
		"desc": "Events can set flags that affect future events",
		"color": Color(0.7, 0.5, 0.9)
	}
]

# Condition types
const CONDITION_TYPES: Array[Dictionary] = [
	{
		"type": "day_range",
		"name": "Day Range",
		"desc": "Event only triggers on certain days (min-max)",
		"example": "Day 5-10 only",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"type": "resource_min",
		"name": "Resource Minimum",
		"desc": "Requires having at least X of a resource",
		"example": "At least 50 gold",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"type": "flag_set",
		"name": "Flag Set",
		"desc": "Requires a specific flag to be true",
		"example": "Has completed tutorial",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"type": "flag_not_set",
		"name": "Flag Not Set",
		"desc": "Requires a flag to NOT be set",
		"example": "Haven't seen intro event",
		"color": Color(0.9, 0.4, 0.4)
	}
]

# Event tables
const EVENT_TABLES: Array[Dictionary] = [
	{
		"name": "Daily Events",
		"desc": "Random events that can occur each day",
		"trigger": "Start of day",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"name": "POI Events",
		"desc": "Events triggered when visiting points of interest",
		"trigger": "POI interaction",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"name": "Wave Events",
		"desc": "Special events during enemy waves",
		"trigger": "Wave start/end",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"name": "Story Events",
		"desc": "Main story progression events",
		"trigger": "Day milestones",
		"color": Color(0.7, 0.5, 0.9)
	}
]

# Tips
const EVENT_TIPS: Array[String] = [
	"Events are randomly selected but weighted by probability",
	"Some events only appear under specific conditions",
	"Cooldowns prevent the same event from repeating too soon",
	"Flags track your choices across events",
	"Different tables trigger at different game moments"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(520, 580)

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
	title.text = "EVENT SELECTION"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.7, 0.5, 0.9))
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
	subtitle.text = "How random events are selected"
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
	footer.text = "Events add variety to each playthrough!"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_event_tables() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Selection mechanics section
	_build_mechanics_section()

	# Event tables section
	_build_tables_section()

	# Conditions section
	_build_conditions_section()

	# Tips section
	_build_tips_section()


func _build_mechanics_section() -> void:
	var section := _create_section_panel("HOW EVENTS ARE SELECTED", Color(0.4, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in SELECTION_MECHANICS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var topic_label := Label.new()
		topic_label.text = str(info.get("topic", ""))
		topic_label.add_theme_font_size_override("font_size", 10)
		topic_label.add_theme_color_override("font_color", info.get("color", Color.WHITE))
		topic_label.custom_minimum_size = Vector2(130, 0)
		hbox.add_child(topic_label)

		var desc_label := Label.new()
		desc_label.text = str(info.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_tables_section() -> void:
	var section := _create_section_panel("EVENT TABLES", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for table in EVENT_TABLES:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 2)
		vbox.add_child(container)

		var name_row := HBoxContainer.new()
		name_row.add_theme_constant_override("separation", 8)
		container.add_child(name_row)

		var name_label := Label.new()
		name_label.text = str(table.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", table.get("color", Color.WHITE))
		name_row.add_child(name_label)

		var trigger_label := Label.new()
		trigger_label.text = "[%s]" % table.get("trigger", "")
		trigger_label.add_theme_font_size_override("font_size", 9)
		trigger_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		name_row.add_child(trigger_label)

		var desc_label := Label.new()
		desc_label.text = "  " + str(table.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		container.add_child(desc_label)


func _build_conditions_section() -> void:
	var section := _create_section_panel("CONDITION TYPES", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for cond in CONDITION_TYPES:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 2)
		vbox.add_child(container)

		var name_label := Label.new()
		name_label.text = str(cond.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", cond.get("color", Color.WHITE))
		container.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = "  " + str(cond.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		container.add_child(desc_label)

		var example_label := Label.new()
		example_label.text = "  Ex: " + str(cond.get("example", ""))
		example_label.add_theme_font_size_override("font_size", 9)
		example_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		container.add_child(example_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("EVENT TIPS", Color(0.7, 0.5, 0.9))
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
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	container.add_child(vbox)

	var header := Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", color)
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
