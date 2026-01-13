class_name SkillTreeReferencePanel
extends PanelContainer
## Skill Tree Reference Panel - Shows all skill trees and abilities.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Skill trees (from SimSkills)
const SKILL_TREES: Array[Dictionary] = [
	{
		"id": "speed",
		"name": "Way of the Swift",
		"description": "Master the art of rapid typing",
		"color": Color(1.0, 0.84, 0.0),
		"skills": [
			{"name": "Quick Start", "tier": 1, "max": 3, "effect": "+2 WPM per rank"},
			{"name": "Momentum", "tier": 1, "max": 3, "effect": "Combo grants +1% damage per rank"},
			{"name": "Burst Typing", "tier": 2, "max": 2, "effect": "First 3 words +20% damage/rank"},
			{"name": "Chain Killer", "tier": 2, "max": 2, "effect": "+10% dmg for quick kills/rank"},
			{"name": "Overdrive", "tier": 3, "max": 1, "effect": "Active: +50% dmg for 10s (60s CD)"},
			{"name": "Speed Demon", "tier": 4, "max": 1, "effect": "Passive: +15% dmg, -5% accuracy"}
		]
	},
	{
		"id": "accuracy",
		"name": "Way of Precision",
		"description": "Master the art of perfect typing",
		"color": Color(0.4, 0.8, 1.0),
		"skills": [
			{"name": "Steady Hands", "tier": 1, "max": 3, "effect": "+5% crit chance per rank"},
			{"name": "Focus", "tier": 1, "max": 3, "effect": "Mistake penalty -10% per rank"},
			{"name": "Critical Strike", "tier": 2, "max": 2, "effect": "Crit damage +50% per rank"},
			{"name": "Quick Recovery", "tier": 2, "max": 2, "effect": "Mistakes don't break combo (8s CD)"},
			{"name": "Perfect Form", "tier": 3, "max": 1, "effect": "Active: 100% crit for 8s (90s CD)"},
			{"name": "Precision Master", "tier": 4, "max": 1, "effect": "Passive: 10+ combo = +50% dmg"}
		]
	},
	{
		"id": "defense",
		"name": "Way of the Guardian",
		"description": "Master the art of survival",
		"color": Color(0.5, 0.8, 0.3),
		"skills": [
			{"name": "Fortify", "tier": 1, "max": 3, "effect": "Castle -5% damage taken/rank"},
			{"name": "Regeneration", "tier": 1, "max": 3, "effect": "Castle +1 HP per wave/rank"},
			{"name": "Thick Walls", "tier": 2, "max": 2, "effect": "+10% gold from kills/rank"},
			{"name": "Slowing Aura", "tier": 2, "max": 2, "effect": "Nearby enemies -10% speed/rank"},
			{"name": "Last Stand", "tier": 3, "max": 1, "effect": "Active: Block dmg 5s (120s CD)"},
			{"name": "Guardian Spirit", "tier": 4, "max": 1, "effect": "Passive: Survive lethal hit once"}
		]
	}
]

# Skill point info
const SKILL_INFO: Array[Dictionary] = [
	{
		"topic": "Skill Points",
		"description": "Earned by leveling up (1 point per level)",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"topic": "Skill Tiers",
		"description": "Higher tier skills require prerequisite skills",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"topic": "Active Skills",
		"description": "Manually triggered with cooldowns (type skill name)",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"topic": "Passive Skills",
		"description": "Always active once learned",
		"color": Color(0.5, 0.8, 0.3)
	}
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 660)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "SKILL TREES"
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
	subtitle.text = "Invest skill points to unlock powerful abilities"
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
	footer.text = "Use 'skills' panel to spend points"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_skill_trees() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Info section
	_build_info_section()

	# Skill trees
	for tree in SKILL_TREES:
		_build_tree_section(tree)


func _build_info_section() -> void:
	var section := _create_section_panel("SKILL SYSTEM", Color(0.7, 0.5, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in SKILL_INFO:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var topic: String = str(info.get("topic", ""))
		var description: String = str(info.get("description", ""))
		var color: Color = info.get("color", Color.WHITE)

		var topic_label := Label.new()
		topic_label.text = topic
		topic_label.add_theme_font_size_override("font_size", 10)
		topic_label.add_theme_color_override("font_color", color)
		topic_label.custom_minimum_size = Vector2(90, 0)
		hbox.add_child(topic_label)

		var desc_label := Label.new()
		desc_label.text = description
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_tree_section(tree: Dictionary) -> void:
	var tree_name: String = str(tree.get("name", ""))
	var description: String = str(tree.get("description", ""))
	var color: Color = tree.get("color", Color.WHITE)
	var skills: Array = tree.get("skills", [])

	var section := _create_section_panel(tree_name, color)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Description
	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(desc_label)

	# Skills grid
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(grid)

	for skill in skills:
		var skill_name: String = str(skill.get("name", ""))
		var tier: int = int(skill.get("tier", 1))
		var max_ranks: int = int(skill.get("max", 1))
		var effect: String = str(skill.get("effect", ""))

		# Tier indicator
		var tier_label := Label.new()
		tier_label.text = "T%d" % tier
		tier_label.add_theme_font_size_override("font_size", 9)
		tier_label.add_theme_color_override("font_color", _get_tier_color(tier))
		tier_label.custom_minimum_size = Vector2(25, 0)
		grid.add_child(tier_label)

		# Skill name with max ranks
		var name_label := Label.new()
		name_label.text = "%s (%d)" % [skill_name, max_ranks]
		name_label.add_theme_font_size_override("font_size", 9)
		name_label.add_theme_color_override("font_color", color)
		name_label.custom_minimum_size = Vector2(130, 0)
		grid.add_child(name_label)

		# Effect
		var effect_label := Label.new()
		effect_label.text = effect
		effect_label.add_theme_font_size_override("font_size", 8)
		effect_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		grid.add_child(effect_label)


func _get_tier_color(tier: int) -> Color:
	match tier:
		1:
			return Color(0.7, 0.7, 0.7)
		2:
			return Color(0.5, 0.8, 0.3)
		3:
			return Color(0.4, 0.8, 1.0)
		4:
			return Color(0.7, 0.5, 0.9)
		_:
			return Color.WHITE


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
