class_name TypingFeedbackReferencePanel
extends PanelContainer
## Typing Feedback Reference Panel - Shows how typing input is processed and matched

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Input routing actions
const INPUT_ACTIONS: Array[Dictionary] = [
	{
		"action": "command",
		"name": "Command",
		"desc": "Input parsed as a valid command",
		"example": "BUILD, MOVE, NIGHT",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"action": "defend",
		"name": "Defend",
		"desc": "Input matches an enemy word exactly",
		"example": "Typing 'forest' kills enemy with word 'forest'",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"action": "incomplete",
		"name": "Incomplete",
		"desc": "Input is a prefix of an enemy word or command",
		"example": "'for' is prefix of 'forest' - keep typing",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"action": "miss",
		"name": "Miss",
		"desc": "Input doesn't match any enemy or command",
		"example": "Typing 'xyz' when no enemy has that word",
		"color": Color(0.9, 0.4, 0.4)
	}
]

# Matching mechanics
const MATCHING_MECHANICS: Array[Dictionary] = [
	{
		"topic": "Prefix Match",
		"desc": "Words that start with your typed text are candidates",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"topic": "Exact Match",
		"desc": "Complete word match triggers attack",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"topic": "Edit Distance",
		"desc": "Measures how different two strings are (for suggestions)",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"topic": "Case Insensitive",
		"desc": "All matching ignores uppercase/lowercase",
		"color": Color(0.7, 0.5, 0.9)
	},
	{
		"topic": "Auto-trim",
		"desc": "Leading/trailing spaces are stripped",
		"color": Color(0.9, 0.4, 0.4)
	}
]

# Candidate selection
const CANDIDATE_SELECTION: Array[Dictionary] = [
	{
		"priority": 1,
		"name": "Exact Match",
		"desc": "Words that exactly match your input",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"priority": 2,
		"name": "Prefix Match",
		"desc": "Words that start with your input",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"priority": 3,
		"name": "Best Prefix Length",
		"desc": "Among matches, longer prefixes are preferred",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"priority": 4,
		"name": "Closest Distance",
		"desc": "Enemies closer to base are targeted first",
		"color": Color(0.9, 0.4, 0.4)
	}
]

# Suggestions system
const SUGGESTIONS_INFO: Array[Dictionary] = [
	{
		"topic": "Top 3 Shown",
		"desc": "At most 3 suggestions are displayed",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"topic": "Sorted by Prefix",
		"desc": "Longer prefix matches shown first",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"topic": "Then by Distance",
		"desc": "Closer enemies prioritized in ties",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"topic": "Next Char Hints",
		"desc": "Shows which characters could continue the match",
		"color": Color(0.7, 0.5, 0.9)
	}
]

# Tips
const FEEDBACK_TIPS: Array[String] = [
	"Type the first few letters to see which enemies match",
	"Closer enemies are auto-targeted when multiple match",
	"Commands take priority over enemy words",
	"Case doesn't matter - 'FOREST' = 'forest'",
	"Watch the suggestion list to plan your next word"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(520, 620)

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
	title.text = "TYPING FEEDBACK"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
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
	subtitle.text = "How your typing input is processed"
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
	footer.text = "Type to attack enemies during defense phase"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_typing_feedback_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Input actions section
	_build_actions_section()

	# Matching mechanics section
	_build_mechanics_section()

	# Candidate selection section
	_build_candidates_section()

	# Suggestions section
	_build_suggestions_section()

	# Tips section
	_build_tips_section()


func _build_actions_section() -> void:
	var section := _create_section_panel("INPUT ROUTING", Color(0.4, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for action in INPUT_ACTIONS:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 2)
		vbox.add_child(container)

		var name_label := Label.new()
		name_label.text = str(action.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", action.get("color", Color.WHITE))
		container.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = "  " + str(action.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		container.add_child(desc_label)

		var example_label := Label.new()
		example_label.text = "  Ex: " + str(action.get("example", ""))
		example_label.add_theme_font_size_override("font_size", 9)
		example_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		container.add_child(example_label)


func _build_mechanics_section() -> void:
	var section := _create_section_panel("MATCHING MECHANICS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in MATCHING_MECHANICS:
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


func _build_candidates_section() -> void:
	var section := _create_section_panel("CANDIDATE PRIORITY", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in CANDIDATE_SELECTION:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var priority_label := Label.new()
		priority_label.text = "#%d" % info.get("priority", 0)
		priority_label.add_theme_font_size_override("font_size", 10)
		priority_label.add_theme_color_override("font_color", info.get("color", Color.WHITE))
		priority_label.custom_minimum_size = Vector2(30, 0)
		hbox.add_child(priority_label)

		var name_label := Label.new()
		name_label.text = str(info.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", info.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(110, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(info.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_suggestions_section() -> void:
	var section := _create_section_panel("SUGGESTIONS SYSTEM", Color(0.7, 0.5, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in SUGGESTIONS_INFO:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var topic_label := Label.new()
		topic_label.text = str(info.get("topic", ""))
		topic_label.add_theme_font_size_override("font_size", 10)
		topic_label.add_theme_color_override("font_color", info.get("color", Color.WHITE))
		topic_label.custom_minimum_size = Vector2(110, 0)
		hbox.add_child(topic_label)

		var desc_label := Label.new()
		desc_label.text = str(info.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("TYPING TIPS", Color(0.9, 0.4, 0.4))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in FEEDBACK_TIPS:
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
