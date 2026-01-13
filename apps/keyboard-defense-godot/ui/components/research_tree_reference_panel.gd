class_name ResearchTreeReferencePanel
extends PanelContainer
## Research Tree Reference Panel - Shows all research options and tech tree.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Research categories
const RESEARCH_CATEGORIES: Array[Dictionary] = [
	{
		"id": "construction",
		"name": "Construction",
		"desc": "Improve building efficiency and durability",
		"color": Color(0.55, 0.27, 0.07)
	},
	{
		"id": "economy",
		"name": "Economy",
		"desc": "Boost resource production and trade",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"id": "military",
		"name": "Military",
		"desc": "Enhance combat effectiveness",
		"color": Color(0.96, 0.26, 0.21)
	},
	{
		"id": "mystical",
		"name": "Mystical",
		"desc": "Unlock special abilities and bonuses",
		"color": Color(0.61, 0.15, 0.69)
	}
]

# Construction research
const CONSTRUCTION_RESEARCH: Array[Dictionary] = [
	{
		"id": "masonry",
		"name": "Masonry",
		"desc": "Refined stonework reduces construction costs",
		"cost": 25,
		"waves": 2,
		"effects": "-10% stone costs",
		"requires": "-",
		"color": Color(0.55, 0.27, 0.07)
	},
	{
		"id": "architecture",
		"name": "Architecture",
		"desc": "Advanced planning allows more buildings per day",
		"cost": 40,
		"waves": 3,
		"effects": "+1 build limit/day",
		"requires": "Masonry",
		"color": Color(0.55, 0.27, 0.07)
	},
	{
		"id": "fortification",
		"name": "Fortification",
		"desc": "Reinforced walls provide extra defense",
		"cost": 50,
		"waves": 2,
		"effects": "+1 wall defense",
		"requires": "Masonry",
		"color": Color(0.55, 0.27, 0.07)
	},
	{
		"id": "engineering",
		"name": "Engineering",
		"desc": "Advanced techniques reduce all build costs",
		"cost": 75,
		"waves": 3,
		"effects": "-15% all build costs",
		"requires": "Architecture + Fortification",
		"color": Color(0.55, 0.27, 0.07)
	}
]

# Economy research
const ECONOMY_RESEARCH: Array[Dictionary] = [
	{
		"id": "efficient_farming",
		"name": "Efficient Farming",
		"desc": "Better techniques increase food production",
		"cost": 20,
		"waves": 2,
		"effects": "+20% food production",
		"requires": "-",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"id": "trade_routes",
		"name": "Trade Routes",
		"desc": "Established trade paths boost market income",
		"cost": 35,
		"waves": 2,
		"effects": "+30% gold production",
		"requires": "Efficient Farming",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"id": "taxation",
		"name": "Taxation",
		"desc": "Collect gold from each building owned",
		"cost": 45,
		"waves": 3,
		"effects": "+2 gold/building/day",
		"requires": "Trade Routes",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"id": "prosperity",
		"name": "Prosperity",
		"desc": "A thriving economy multiplies all resource gains",
		"cost": 80,
		"waves": 4,
		"effects": "+25% all resources",
		"requires": "Taxation",
		"color": Color(1.0, 0.84, 0.0)
	}
]

# Military research
const MILITARY_RESEARCH: Array[Dictionary] = [
	{
		"id": "archery_training",
		"name": "Archery Training",
		"desc": "Towers gain extended range",
		"cost": 30,
		"waves": 2,
		"effects": "+1 tower range",
		"requires": "-",
		"color": Color(0.96, 0.26, 0.21)
	},
	{
		"id": "steel_weapons",
		"name": "Steel Weapons",
		"desc": "Superior weapons increase typing power",
		"cost": 45,
		"waves": 3,
		"effects": "+15% typing power",
		"requires": "Archery Training",
		"color": Color(0.96, 0.26, 0.21)
	},
	{
		"id": "battle_tactics",
		"name": "Battle Tactics",
		"desc": "Strategic coordination amplifies combo bonuses",
		"cost": 55,
		"waves": 3,
		"effects": "+25% combo multiplier",
		"requires": "Steel Weapons",
		"color": Color(0.96, 0.26, 0.21)
	},
	{
		"id": "war_mastery",
		"name": "War Mastery",
		"desc": "Complete martial expertise grants all combat bonuses",
		"cost": 90,
		"waves": 4,
		"effects": "+10% typing, +1 tower dmg, +10% crit",
		"requires": "Battle Tactics",
		"color": Color(0.96, 0.26, 0.21)
	}
]

# Mystical research
const MYSTICAL_RESEARCH: Array[Dictionary] = [
	{
		"id": "healing_aura",
		"name": "Healing Aura",
		"desc": "Mystical energy heals the castle after each wave",
		"cost": 35,
		"waves": 2,
		"effects": "+1 HP/wave healed",
		"requires": "-",
		"color": Color(0.61, 0.15, 0.69)
	},
	{
		"id": "time_dilation",
		"name": "Time Dilation",
		"desc": "Bend time to extend the planning phase",
		"cost": 50,
		"waves": 3,
		"effects": "+10s planning time",
		"requires": "Healing Aura",
		"color": Color(0.61, 0.15, 0.69)
	},
	{
		"id": "word_mastery",
		"name": "Word Mastery",
		"desc": "Perfect words deal critical damage",
		"cost": 60,
		"waves": 3,
		"effects": "Perfect words crit, +50% crit dmg",
		"requires": "Healing Aura",
		"color": Color(0.61, 0.15, 0.69)
	},
	{
		"id": "arcane_supremacy",
		"name": "Arcane Supremacy",
		"desc": "Ultimate magical power grants all mystical bonuses",
		"cost": 100,
		"waves": 5,
		"effects": "+2 heal, +3 HP, +20% typing, 15% mistake forgive",
		"requires": "Time Dilation + Word Mastery",
		"color": Color(0.61, 0.15, 0.69)
	}
]

# Research tips
const RESEARCH_TIPS: Array[String] = [
	"Research costs gold and takes multiple waves to complete",
	"Each category has a tier 4 capstone with powerful effects",
	"Construction tree reduces costs, Military boosts combat",
	"Economy tree multiplies resource gains long-term",
	"Mystical tree provides unique abilities and survivability",
	"Plan your research path based on your playstyle"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 640)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "RESEARCH TREE"
	DesignSystem.style_label(title, "h2", Color(0.61, 0.15, 0.69))
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
	subtitle.text = "16 technologies across 4 categories"
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
	footer.text = "Type 'research [name]' during planning phase"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_research_tree_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Categories overview
	_build_categories_section()

	# Construction research
	_build_research_section("CONSTRUCTION", Color(0.55, 0.27, 0.07), CONSTRUCTION_RESEARCH)

	# Economy research
	_build_research_section("ECONOMY", Color(1.0, 0.84, 0.0), ECONOMY_RESEARCH)

	# Military research
	_build_research_section("MILITARY", Color(0.96, 0.26, 0.21), MILITARY_RESEARCH)

	# Mystical research
	_build_research_section("MYSTICAL", Color(0.61, 0.15, 0.69), MYSTICAL_RESEARCH)

	# Tips
	_build_tips_section()


func _build_categories_section() -> void:
	var section := _create_section_panel("CATEGORIES", Color(0.6, 0.6, 0.8))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for cat in RESEARCH_CATEGORIES:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(cat.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", cat.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(90, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(cat.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_research_section(title: String, color: Color, research: Array[Dictionary]) -> void:
	var section := _create_section_panel(title, color)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tech in research:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 1)
		vbox.add_child(container)

		# Name and cost
		var header_hbox := HBoxContainer.new()
		header_hbox.add_theme_constant_override("separation", 10)
		container.add_child(header_hbox)

		var name_label := Label.new()
		name_label.text = str(tech.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", tech.get("color", color))
		name_label.custom_minimum_size = Vector2(120, 0)
		header_hbox.add_child(name_label)

		var cost_label := Label.new()
		cost_label.text = "%dg" % tech.get("cost", 0)
		cost_label.add_theme_font_size_override("font_size", 9)
		cost_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		cost_label.custom_minimum_size = Vector2(35, 0)
		header_hbox.add_child(cost_label)

		var waves_label := Label.new()
		waves_label.text = "%d waves" % tech.get("waves", 1)
		waves_label.add_theme_font_size_override("font_size", 9)
		waves_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
		header_hbox.add_child(waves_label)

		# Effects
		var effects_label := Label.new()
		effects_label.text = "  Effect: " + str(tech.get("effects", ""))
		effects_label.add_theme_font_size_override("font_size", 9)
		effects_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.3))
		effects_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		container.add_child(effects_label)

		# Requirements
		var requires: String = str(tech.get("requires", "-"))
		if requires != "-":
			var req_label := Label.new()
			req_label.text = "  Requires: " + requires
			req_label.add_theme_font_size_override("font_size", 9)
			req_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			container.add_child(req_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("RESEARCH TIPS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in RESEARCH_TIPS:
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
