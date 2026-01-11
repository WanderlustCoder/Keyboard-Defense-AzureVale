class_name ResearchMechanicsPanel
extends PanelContainer
## Research Mechanics Panel - Shows research/tech tree system

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Research categories
const RESEARCH_CATEGORIES: Array[Dictionary] = [
	{
		"name": "Military",
		"desc": "Tower upgrades and combat bonuses",
		"icon": "sword",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"name": "Economy",
		"desc": "Resource production and gold bonuses",
		"icon": "coin",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"name": "Typing",
		"desc": "Word bonuses and combo improvements",
		"icon": "keyboard",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"name": "Defense",
		"desc": "Castle HP and damage reduction",
		"icon": "shield",
		"color": Color(0.5, 0.8, 0.3)
	}
]

# Research mechanics
const RESEARCH_MECHANICS: Array[Dictionary] = [
	{
		"topic": "Gold Cost",
		"desc": "Research requires gold investment upfront",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"topic": "Progress",
		"desc": "Research advances after each completed wave",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"topic": "Prerequisites",
		"desc": "Some research requires completing others first",
		"color": Color(0.7, 0.5, 0.9)
	},
	{
		"topic": "One at a Time",
		"desc": "Only one research can be active at once",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"topic": "Cancel Penalty",
		"desc": "Canceling research refunds only 50% of gold",
		"color": Color(0.9, 0.4, 0.4)
	}
]

# Sample research items
const SAMPLE_RESEARCH: Array[Dictionary] = [
	{
		"name": "Improved Arrows",
		"category": "Military",
		"cost": 100,
		"waves": 2,
		"effect": "+10% tower damage",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"name": "Gold Mining",
		"category": "Economy",
		"cost": 150,
		"waves": 3,
		"effect": "+15% gold from kills",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"name": "Word Mastery",
		"category": "Typing",
		"cost": 120,
		"waves": 2,
		"effect": "+5% combo bonus",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"name": "Stone Walls",
		"category": "Defense",
		"cost": 200,
		"waves": 4,
		"effect": "+2 max castle HP",
		"color": Color(0.5, 0.8, 0.3)
	}
]

# Tips
const RESEARCH_TIPS: Array[String] = [
	"Prioritize research that matches your playstyle",
	"Military research helps with difficult waves",
	"Economy research pays off over longer runs",
	"Check prerequisites before planning research",
	"Don't cancel research unless necessary"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(500, 580)

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
	title.text = "RESEARCH SYSTEM"
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
	subtitle.text = "Unlock permanent upgrades for your kingdom"
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
	footer.text = "Build a Library to unlock research!"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_research_mechanics() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Categories section
	_build_categories_section()

	# Mechanics section
	_build_mechanics_section()

	# Sample research section
	_build_samples_section()

	# Tips section
	_build_tips_section()


func _build_categories_section() -> void:
	var section := _create_section_panel("RESEARCH CATEGORIES", Color(0.7, 0.5, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for category in RESEARCH_CATEGORIES:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(category.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", category.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(70, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(category.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_mechanics_section() -> void:
	var section := _create_section_panel("HOW RESEARCH WORKS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in RESEARCH_MECHANICS:
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


func _build_samples_section() -> void:
	var section := _create_section_panel("EXAMPLE RESEARCH", Color(0.4, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for research in SAMPLE_RESEARCH:
		var card := _create_research_card(research)
		vbox.add_child(card)


func _create_research_card(research: Dictionary) -> Control:
	var name: String = str(research.get("name", ""))
	var cost: int = int(research.get("cost", 0))
	var waves: int = int(research.get("waves", 1))
	var effect: String = str(research.get("effect", ""))
	var color: Color = research.get("color", Color.WHITE)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var name_label := Label.new()
	name_label.text = name
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", color)
	name_label.custom_minimum_size = Vector2(100, 0)
	hbox.add_child(name_label)

	var cost_label := Label.new()
	cost_label.text = "%dg" % cost
	cost_label.add_theme_font_size_override("font_size", 9)
	cost_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	cost_label.custom_minimum_size = Vector2(40, 0)
	hbox.add_child(cost_label)

	var waves_label := Label.new()
	waves_label.text = "%d waves" % waves
	waves_label.add_theme_font_size_override("font_size", 9)
	waves_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	waves_label.custom_minimum_size = Vector2(55, 0)
	hbox.add_child(waves_label)

	var effect_label := Label.new()
	effect_label.text = effect
	effect_label.add_theme_font_size_override("font_size", 9)
	effect_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	hbox.add_child(effect_label)

	return hbox


func _build_tips_section() -> void:
	var section := _create_section_panel("RESEARCH TIPS", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in RESEARCH_TIPS:
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
