class_name ExpeditionReferencePanel
extends PanelContainer
## Expedition Reference Panel - Shows expedition mechanics and rewards

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Expedition states (from SimExpeditions)
const EXPEDITION_STATES: Array[Dictionary] = [
	{
		"state": "idle",
		"name": "Idle",
		"description": "Worker is available for assignment",
		"color": Color(0.5, 0.5, 0.6)
	},
	{
		"state": "traveling",
		"name": "Traveling",
		"description": "Worker is en route to the expedition site",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"state": "gathering",
		"name": "Gathering",
		"description": "Worker is collecting resources at the site",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"state": "returning",
		"name": "Returning",
		"description": "Worker is returning with collected resources",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"state": "complete",
		"name": "Complete",
		"description": "Expedition finished successfully, rewards available",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"state": "failed",
		"name": "Failed",
		"description": "Expedition failed due to danger or abandonment",
		"color": Color(0.9, 0.4, 0.4)
	}
]

# Expedition types
const EXPEDITION_TYPES: Array[Dictionary] = [
	{
		"type": "resource_gather",
		"name": "Resource Gathering",
		"description": "Collect basic materials from nearby areas",
		"duration": "Short (1-2 waves)",
		"risk": "Low",
		"rewards": "Wood, Stone, Iron",
		"color": Color(0.6, 0.5, 0.4)
	},
	{
		"type": "scouting",
		"name": "Scouting Mission",
		"description": "Explore new territories and reveal map areas",
		"duration": "Medium (3-5 waves)",
		"risk": "Medium",
		"rewards": "Map Intel, Enemy Info",
		"color": Color(0.4, 0.6, 0.8)
	},
	{
		"type": "treasure_hunt",
		"name": "Treasure Hunt",
		"description": "Search for hidden caches and artifacts",
		"duration": "Long (5-8 waves)",
		"risk": "High",
		"rewards": "Gold, Rare Items",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"type": "rescue",
		"name": "Rescue Mission",
		"description": "Save stranded villagers or lost workers",
		"duration": "Variable",
		"risk": "Medium-High",
		"rewards": "New Workers, Reputation",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"type": "trade_route",
		"name": "Trade Route",
		"description": "Establish commerce with distant settlements",
		"duration": "Long (8-10 waves)",
		"risk": "Low",
		"rewards": "Trade Goods, Gold",
		"color": Color(0.5, 0.8, 0.3)
	}
]

# Risk factors
const RISK_FACTORS: Array[Dictionary] = [
	{
		"factor": "Distance",
		"effect": "Longer travel = more danger exposure",
		"color": Color(0.6, 0.6, 0.7)
	},
	{
		"factor": "Worker Level",
		"effect": "Higher level = better success chance",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"factor": "Equipment",
		"effect": "Better gear reduces failure rate",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"factor": "Territory Threat",
		"effect": "Hostile areas increase danger",
		"color": Color(0.9, 0.4, 0.4)
	}
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(540, 600)

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
	subtitle.text = "Send workers on missions to gather resources and intel"
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
	footer.text = "Assign workers via the Workers panel"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_expeditions() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Expedition types section
	_build_types_section()

	# States section
	_build_states_section()

	# Risk factors section
	_build_risk_section()


func _build_types_section() -> void:
	var section := _create_section_panel("EXPEDITION TYPES", Color(0.4, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for exp_type in EXPEDITION_TYPES:
		var card := _create_type_card(exp_type)
		vbox.add_child(card)


func _create_type_card(exp_type: Dictionary) -> Control:
	var name_str: String = str(exp_type.get("name", ""))
	var description: String = str(exp_type.get("description", ""))
	var duration: String = str(exp_type.get("duration", ""))
	var risk: String = str(exp_type.get("risk", ""))
	var rewards: String = str(exp_type.get("rewards", ""))
	var color: Color = exp_type.get("color", Color.WHITE)

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = color.darkened(0.85)
	container_style.border_color = color.darkened(0.6)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(8)
	container.add_theme_stylebox_override("panel", container_style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 3)
	container.add_child(main_vbox)

	# Name
	var name_label := Label.new()
	name_label.text = name_str
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", color)
	main_vbox.add_child(name_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	main_vbox.add_child(desc_label)

	# Stats row
	var stats_hbox := HBoxContainer.new()
	stats_hbox.add_theme_constant_override("separation", 15)
	main_vbox.add_child(stats_hbox)

	var dur_label := Label.new()
	dur_label.text = "Duration: " + duration
	dur_label.add_theme_font_size_override("font_size", 9)
	dur_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
	stats_hbox.add_child(dur_label)

	var risk_color := Color(0.5, 0.8, 0.3)
	if risk == "Medium" or risk == "Medium-High":
		risk_color = Color(0.9, 0.6, 0.3)
	elif risk == "High":
		risk_color = Color(0.9, 0.4, 0.4)

	var risk_label := Label.new()
	risk_label.text = "Risk: " + risk
	risk_label.add_theme_font_size_override("font_size", 9)
	risk_label.add_theme_color_override("font_color", risk_color)
	stats_hbox.add_child(risk_label)

	# Rewards
	var reward_label := Label.new()
	reward_label.text = "Rewards: " + rewards
	reward_label.add_theme_font_size_override("font_size", 9)
	reward_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	main_vbox.add_child(reward_label)

	return container


func _build_states_section() -> void:
	var section := _create_section_panel("EXPEDITION STATES", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for state_info in EXPEDITION_STATES:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var state_name: String = str(state_info.get("name", ""))
		var description: String = str(state_info.get("description", ""))
		var color: Color = state_info.get("color", Color.WHITE)

		var name_label := Label.new()
		name_label.text = state_name
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", color)
		name_label.custom_minimum_size = Vector2(80, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = description
		desc_label.add_theme_font_size_override("font_size", 10)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_risk_section() -> void:
	var section := _create_section_panel("RISK FACTORS", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for risk_info in RISK_FACTORS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var factor: String = str(risk_info.get("factor", ""))
		var effect: String = str(risk_info.get("effect", ""))
		var color: Color = risk_info.get("color", Color.WHITE)

		var factor_label := Label.new()
		factor_label.text = factor
		factor_label.add_theme_font_size_override("font_size", 10)
		factor_label.add_theme_color_override("font_color", color)
		factor_label.custom_minimum_size = Vector2(100, 0)
		hbox.add_child(factor_label)

		var effect_label := Label.new()
		effect_label.text = effect
		effect_label.add_theme_font_size_override("font_size", 10)
		effect_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(effect_label)


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
