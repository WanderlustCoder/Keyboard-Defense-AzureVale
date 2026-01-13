class_name ResourceNodesReferencePanel
extends PanelContainer
## Resource Nodes Reference Panel - Shows harvestable node types and mechanics.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Challenge types
const CHALLENGE_TYPES: Array[Dictionary] = [
	{
		"id": "word_burst",
		"name": "Word Burst",
		"desc": "Type X words within time limit",
		"example": "Type 4 words in 15 seconds",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"id": "speed_type",
		"name": "Speed Type",
		"desc": "Maintain target WPM across words",
		"example": "40 WPM across 5 words",
		"color": Color(1.0, 0.6, 0.2)
	},
	{
		"id": "accuracy_test",
		"name": "Accuracy Test",
		"desc": "Type words with minimum accuracy",
		"example": "6 words at 90%+ accuracy",
		"color": Color(0.4, 1.0, 0.4)
	}
]

# Performance tiers
const PERFORMANCE_TIERS: Array[Dictionary] = [
	{
		"name": "Poor",
		"multiplier": 0.5,
		"condition": "Failed challenge",
		"color": Color(0.5, 0.5, 0.5)
	},
	{
		"name": "Standard",
		"multiplier": 1.0,
		"condition": "Passed challenge",
		"color": Color(0.8, 0.8, 0.8)
	},
	{
		"name": "Good",
		"multiplier": 1.25,
		"condition": "95%+ accuracy OR 45+ WPM",
		"color": Color(0.4, 0.8, 0.4)
	},
	{
		"name": "Excellent",
		"multiplier": 1.5,
		"condition": "100% accuracy OR 60+ WPM",
		"color": Color(0.4, 0.6, 1.0)
	},
	{
		"name": "Perfect",
		"multiplier": 2.0,
		"condition": "100% accuracy + 60 WPM + time bonus",
		"color": Color(1.0, 0.84, 0.0)
	}
]

# Node mechanics
const NODE_MECHANICS: Array[Dictionary] = [
	{
		"name": "Discovery",
		"desc": "Nodes spawn on terrain tiles during exploration",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"name": "Harvesting",
		"desc": "Move to node and complete typing challenge to harvest",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"name": "Multi-Harvest",
		"desc": "Some nodes can be harvested multiple times",
		"color": Color(0.8, 0.6, 1.0)
	},
	{
		"name": "Depletion",
		"desc": "Nodes deplete after max harvests, removed from map",
		"color": Color(0.6, 0.4, 0.4)
	},
	{
		"name": "Respawn",
		"desc": "Depleted nodes may respawn after several days",
		"color": Color(0.5, 0.7, 0.5)
	},
	{
		"name": "Day Phase Only",
		"desc": "Can only harvest nodes during the day phase",
		"color": Color(1.0, 0.84, 0.0)
	}
]

# Common node types
const NODE_TYPES: Array[Dictionary] = [
	{
		"name": "Wood Grove",
		"yields": "Wood",
		"terrain": "Forest",
		"harvests": 3,
		"color": Color(0.6, 0.4, 0.2)
	},
	{
		"name": "Stone Deposit",
		"yields": "Stone",
		"terrain": "Mountain",
		"harvests": 2,
		"color": Color(0.5, 0.5, 0.5)
	},
	{
		"name": "Iron Vein",
		"yields": "Iron",
		"terrain": "Cave",
		"harvests": 2,
		"color": Color(0.7, 0.7, 0.8)
	},
	{
		"name": "Crystal Formation",
		"yields": "Crystals",
		"terrain": "Magic",
		"harvests": 1,
		"color": Color(0.8, 0.4, 1.0)
	},
	{
		"name": "Gold Vein",
		"yields": "Gold",
		"terrain": "Cave",
		"harvests": 1,
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"name": "Herb Patch",
		"yields": "Herbs",
		"terrain": "Plains",
		"harvests": 4,
		"color": Color(0.4, 0.8, 0.3)
	}
]

# Tips
const NODE_TIPS: Array[String] = [
	"Performance in typing challenges directly affects resource yield",
	"Perfect harvests (2x yield) require 100% accuracy plus speed bonus",
	"Failed challenges still give 50% resources - never a total loss",
	"Look for rare Crystal and Gold nodes for valuable resources",
	"Multi-harvest nodes are efficient - prioritize finding them"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_MD, 700)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "RESOURCE NODES"
	DesignSystem.style_label(title, "h2", ThemeColors.SUCCESS)
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
	subtitle.text = "Harvest resources through typing challenges"
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
	footer.text = "Type accurately for maximum resource yield"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_resource_nodes_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Challenge types
	_build_challenges_section()

	# Performance tiers
	_build_performance_section()

	# Node types
	_build_node_types_section()

	# Mechanics
	_build_mechanics_section()

	# Tips
	_build_tips_section()


func _build_challenges_section() -> void:
	var section := _create_section_panel("CHALLENGE TYPES", ThemeColors.INFO)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for challenge in CHALLENGE_TYPES:
		var container := DesignSystem.create_vbox(1)
		vbox.add_child(container)

		var header_hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
		container.add_child(header_hbox)

		var name_label := Label.new()
		name_label.text = str(challenge.get("name", ""))
		DesignSystem.style_label(name_label, "caption", challenge.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(100, 0)
		header_hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(challenge.get("desc", ""))
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
		header_hbox.add_child(desc_label)

		var example_label := Label.new()
		example_label.text = "  Example: " + str(challenge.get("example", ""))
		DesignSystem.style_label(example_label, "caption", ThemeColors.TEXT_DIM)
		container.add_child(example_label)


func _build_performance_section() -> void:
	var section := _create_section_panel("PERFORMANCE TIERS", Color(0.6, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tier in PERFORMANCE_TIERS:
		var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(tier.get("name", ""))
		DesignSystem.style_label(name_label, "caption", tier.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(70, 0)
		hbox.add_child(name_label)

		var mult_label := Label.new()
		mult_label.text = "%.1fx" % tier.get("multiplier", 1.0)
		DesignSystem.style_label(mult_label, "caption", ThemeColors.SUCCESS)
		mult_label.custom_minimum_size = Vector2(40, 0)
		hbox.add_child(mult_label)

		var cond_label := Label.new()
		cond_label.text = str(tier.get("condition", ""))
		DesignSystem.style_label(cond_label, "caption", ThemeColors.TEXT_DIM)
		hbox.add_child(cond_label)


func _build_node_types_section() -> void:
	var section := _create_section_panel("NODE TYPES", ThemeColors.SUCCESS)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Two-column layout
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", DesignSystem.SPACE_LG)
	grid.add_theme_constant_override("v_separation", DesignSystem.SPACE_XS)
	vbox.add_child(grid)

	for node in NODE_TYPES:
		var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_XS)
		hbox.custom_minimum_size = Vector2(220, 0)
		grid.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(node.get("name", ""))
		DesignSystem.style_label(name_label, "caption", node.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(100, 0)
		hbox.add_child(name_label)

		var info_label := Label.new()
		info_label.text = "%s (%dx)" % [node.get("yields", ""), node.get("harvests", 1)]
		DesignSystem.style_label(info_label, "caption", ThemeColors.TEXT_DIM)
		hbox.add_child(info_label)


func _build_mechanics_section() -> void:
	var section := _create_section_panel("NODE MECHANICS", Color(0.5, 0.6, 0.7))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for mech in NODE_MECHANICS:
		var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(mech.get("name", ""))
		DesignSystem.style_label(name_label, "caption", mech.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(100, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(mech.get("desc", ""))
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hbox.add_child(desc_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("HARVESTING TIPS", ThemeColors.SUCCESS)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in NODE_TIPS:
		var tip_label := Label.new()
		tip_label.text = "- " + tip
		DesignSystem.style_label(tip_label, "caption", ThemeColors.TEXT_DIM)
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
