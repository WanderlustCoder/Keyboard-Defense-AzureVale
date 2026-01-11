class_name ExpeditionsReferencePanel
extends PanelContainer
## Expeditions Reference Panel - Shows worker expedition system

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Expedition states
const EXPEDITION_STATES: Array[Dictionary] = [
	{
		"id": "traveling",
		"name": "Traveling",
		"progress": "0-33%",
		"desc": "Workers are traveling to the destination",
		"color": Color(0.5, 0.7, 0.9)
	},
	{
		"id": "gathering",
		"name": "Gathering",
		"progress": "33-67%",
		"desc": "Workers are collecting resources",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"id": "returning",
		"name": "Returning",
		"progress": "67-100%",
		"desc": "Workers are returning with resources",
		"color": Color(0.8, 0.6, 0.3)
	},
	{
		"id": "complete",
		"name": "Complete",
		"progress": "100%",
		"desc": "Expedition finished, rewards granted",
		"color": Color(0.4, 0.9, 0.4)
	}
]

# Risk events
const RISK_EVENTS: Array[Dictionary] = [
	{
		"id": "worker_injury",
		"name": "Worker Injury",
		"effect": "A worker becomes temporarily unavailable",
		"severity": "Minor",
		"color": Color(0.8, 0.6, 0.3)
	},
	{
		"id": "resource_spoil",
		"name": "Resource Spoilage",
		"effect": "Some gathered resources are lost",
		"severity": "Minor",
		"color": Color(0.6, 0.5, 0.4)
	},
	{
		"id": "bandit_attack",
		"name": "Bandit Attack",
		"effect": "Gold is stolen by bandits",
		"severity": "Moderate",
		"color": Color(0.8, 0.4, 0.4)
	},
	{
		"id": "combat_encounter",
		"name": "Combat Encounter",
		"effect": "Hostile creatures reduce yields by 30%",
		"severity": "Moderate",
		"color": Color(0.96, 0.26, 0.21)
	},
	{
		"id": "cave_in",
		"name": "Cave-In",
		"effect": "Major incident reduces yields by 50%",
		"severity": "Severe",
		"color": Color(0.6, 0.2, 0.2)
	}
]

# Expedition mechanics
const EXPEDITION_MECHANICS: Array[Dictionary] = [
	{
		"name": "Worker Assignment",
		"desc": "Assign available workers to expeditions. More workers = better yields",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"name": "Worker Bonus",
		"desc": "Extra workers beyond minimum provide +40% yield per worker",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"name": "Duration",
		"desc": "Each expedition has a set duration. Progress shown in 3 phases",
		"color": Color(0.5, 0.7, 0.9)
	},
	{
		"name": "Risk Chance",
		"desc": "Each expedition has a risk chance for negative events",
		"color": Color(0.96, 0.26, 0.21)
	},
	{
		"name": "Cancellation",
		"desc": "Cancel for partial yields (50% of progress after traveling phase)",
		"color": Color(0.6, 0.5, 0.5)
	},
	{
		"name": "Requirements",
		"desc": "Some expeditions require specific buildings or minimum day",
		"color": Color(0.6, 0.5, 0.7)
	}
]

# Expedition tips
const EXPEDITION_TIPS: Array[String] = [
	"Send extra workers for bonus yields (+40% per extra worker)",
	"Only start expeditions during the day phase",
	"Higher-tier expeditions unlock as you progress through days",
	"Some expeditions require specific buildings to be constructed",
	"Cancel early if you need workers urgently (partial yields after 33%)",
	"Watch for risk events - some expeditions are more dangerous",
	"Expedition history tracks your last 10 completed expeditions"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(540, 660)

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
	title.text = "EXPEDITIONS"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.6, 0.4, 0.3))
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
	subtitle.text = "Send workers on resource-gathering expeditions"
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
	footer.text = "Use 'expedition' command to start expeditions"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_expeditions_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Mechanics
	_build_mechanics_section()

	# States
	_build_states_section()

	# Risk events
	_build_risks_section()

	# Tips
	_build_tips_section()


func _build_mechanics_section() -> void:
	var section := _create_section_panel("EXPEDITION MECHANICS", Color(0.5, 0.6, 0.7))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for mech in EXPEDITION_MECHANICS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(mech.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", mech.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(120, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(mech.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hbox.add_child(desc_label)


func _build_states_section() -> void:
	var section := _create_section_panel("EXPEDITION PHASES", Color(0.5, 0.7, 0.9))
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

		var progress_label := Label.new()
		progress_label.text = str(state.get("progress", ""))
		progress_label.add_theme_font_size_override("font_size", 9)
		progress_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		progress_label.custom_minimum_size = Vector2(60, 0)
		hbox.add_child(progress_label)

		var desc_label := Label.new()
		desc_label.text = str(state.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_risks_section() -> void:
	var section := _create_section_panel("RISK EVENTS", Color(0.8, 0.4, 0.4))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for risk in RISK_EVENTS:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 1)
		vbox.add_child(container)

		var header_hbox := HBoxContainer.new()
		header_hbox.add_theme_constant_override("separation", 10)
		container.add_child(header_hbox)

		var name_label := Label.new()
		name_label.text = str(risk.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", risk.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(130, 0)
		header_hbox.add_child(name_label)

		var severity_label := Label.new()
		severity_label.text = "[%s]" % risk.get("severity", "")
		severity_label.add_theme_font_size_override("font_size", 9)
		severity_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		header_hbox.add_child(severity_label)

		var effect_label := Label.new()
		effect_label.text = "  Effect: %s" % risk.get("effect", "")
		effect_label.add_theme_font_size_override("font_size", 9)
		effect_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		container.add_child(effect_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("EXPEDITION TIPS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in EXPEDITION_TIPS:
		var tip_label := Label.new()
		tip_label.text = "- " + tip
		tip_label.add_theme_font_size_override("font_size", 9)
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
