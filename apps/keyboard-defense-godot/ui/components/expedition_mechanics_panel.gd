class_name ExpeditionMechanicsPanel
extends PanelContainer
## Expedition Mechanics Panel - Shows expedition system and states.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Expedition states (from SimExpeditions)
const EXPEDITION_STATES: Array[Dictionary] = [
	{
		"state": "traveling",
		"name": "Traveling",
		"desc": "Workers are traveling to the destination",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"state": "gathering",
		"name": "Gathering",
		"desc": "Workers are collecting resources",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"state": "returning",
		"name": "Returning",
		"desc": "Workers are bringing resources back",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"state": "complete",
		"name": "Complete",
		"desc": "Workers have returned with loot",
		"color": Color(0.4, 0.9, 0.4)
	},
	{
		"state": "failed",
		"name": "Failed",
		"desc": "Expedition was unsuccessful",
		"color": Color(0.9, 0.4, 0.4)
	}
]

# Expedition mechanics
const EXPEDITION_MECHANICS: Array[Dictionary] = [
	{
		"topic": "Worker Assignment",
		"desc": "Assign workers from your pool to expeditions",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"topic": "Duration",
		"desc": "Expeditions take multiple days to complete",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"topic": "Risk vs Reward",
		"desc": "Longer expeditions yield better rewards",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"topic": "Requirements",
		"desc": "Some expeditions require specific buildings",
		"color": Color(0.7, 0.5, 0.9)
	},
	{
		"topic": "Worker Bonus",
		"desc": "More workers means faster completion",
		"color": Color(1.0, 0.84, 0.0)
	}
]

# Expedition types
const EXPEDITION_TYPES: Array[Dictionary] = [
	{
		"name": "Logging Camp",
		"duration": "2 days",
		"workers": "1-3",
		"rewards": "Wood",
		"color": Color(0.6, 0.4, 0.2)
	},
	{
		"name": "Mining Expedition",
		"duration": "3 days",
		"workers": "2-4",
		"rewards": "Stone, Ore",
		"color": Color(0.5, 0.5, 0.6)
	},
	{
		"name": "Foraging Party",
		"duration": "1 day",
		"workers": "1-2",
		"rewards": "Food",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"name": "Treasure Hunt",
		"duration": "4 days",
		"workers": "3-5",
		"rewards": "Gold, Items",
		"color": Color(1.0, 0.84, 0.0)
	}
]

# Tips
const EXPEDITION_TIPS: Array[String] = [
	"Start expeditions early in the day",
	"Keep some workers for building production",
	"Higher worker counts reduce expedition time",
	"Failed expeditions still return workers safely",
	"Check the Map for new expedition locations"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 580)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "EXPEDITIONS"
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
	subtitle.text = "Send workers on resource gathering missions"
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
	footer.text = "Build a Tavern to unlock expeditions!"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_expedition_mechanics() -> void:
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

	# States section
	_build_states_section()

	# Types section
	_build_types_section()

	# Tips section
	_build_tips_section()


func _build_mechanics_section() -> void:
	var section := _create_section_panel("HOW EXPEDITIONS WORK", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in EXPEDITION_MECHANICS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var topic_label := Label.new()
		topic_label.text = str(info.get("topic", ""))
		topic_label.add_theme_font_size_override("font_size", 10)
		topic_label.add_theme_color_override("font_color", info.get("color", Color.WHITE))
		topic_label.custom_minimum_size = Vector2(120, 0)
		hbox.add_child(topic_label)

		var desc_label := Label.new()
		desc_label.text = str(info.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_states_section() -> void:
	var section := _create_section_panel("EXPEDITION STATES", Color(0.4, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for state in EXPEDITION_STATES:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(state.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", state.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(80, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(state.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_types_section() -> void:
	var section := _create_section_panel("EXPEDITION TYPES", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for exp_type in EXPEDITION_TYPES:
		var card := _create_type_card(exp_type)
		vbox.add_child(card)


func _create_type_card(exp_type: Dictionary) -> Control:
	var name: String = str(exp_type.get("name", ""))
	var duration: String = str(exp_type.get("duration", ""))
	var workers: String = str(exp_type.get("workers", ""))
	var rewards: String = str(exp_type.get("rewards", ""))
	var color: Color = exp_type.get("color", Color.WHITE)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var name_label := Label.new()
	name_label.text = name
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", color)
	name_label.custom_minimum_size = Vector2(110, 0)
	hbox.add_child(name_label)

	var dur_label := Label.new()
	dur_label.text = duration
	dur_label.add_theme_font_size_override("font_size", 9)
	dur_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	dur_label.custom_minimum_size = Vector2(55, 0)
	hbox.add_child(dur_label)

	var worker_label := Label.new()
	worker_label.text = workers + " workers"
	worker_label.add_theme_font_size_override("font_size", 9)
	worker_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.3))
	worker_label.custom_minimum_size = Vector2(70, 0)
	hbox.add_child(worker_label)

	var reward_label := Label.new()
	reward_label.text = rewards
	reward_label.add_theme_font_size_override("font_size", 9)
	reward_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	hbox.add_child(reward_label)

	return hbox


func _build_tips_section() -> void:
	var section := _create_section_panel("EXPEDITION TIPS", Color(0.7, 0.5, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in EXPEDITION_TIPS:
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
