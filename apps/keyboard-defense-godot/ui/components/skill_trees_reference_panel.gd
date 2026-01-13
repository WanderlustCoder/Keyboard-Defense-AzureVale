class_name SkillTreesReferencePanel
extends PanelContainer
## Skill Trees Reference Panel - Shows all 3 skill trees and their abilities.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Skill trees
const SKILL_TREES: Array[Dictionary] = [
	{
		"id": "speed",
		"name": "Way of the Swift",
		"icon": "lightning",
		"desc": "Master the art of rapid typing",
		"focus": "Damage bonuses, burst damage, speed",
		"color": Color(0.5, 0.8, 1.0)
	},
	{
		"id": "accuracy",
		"name": "Way of Precision",
		"icon": "crosshair",
		"desc": "Master the art of perfect typing",
		"focus": "Critical hits, mistake reduction, combos",
		"color": Color(0.8, 0.6, 0.3)
	},
	{
		"id": "defense",
		"name": "Way of the Guardian",
		"icon": "shield",
		"desc": "Master the art of survival",
		"focus": "Damage reduction, healing, gold",
		"color": Color(0.5, 0.8, 0.3)
	}
]

# Speed tree skills
const SPEED_SKILLS: Array[Dictionary] = [
	{
		"id": "swift_start",
		"name": "Quick Start",
		"tier": 1,
		"cost": 1,
		"max_ranks": 3,
		"effect": "+2 WPM per rank",
		"prereqs": "-"
	},
	{
		"id": "momentum",
		"name": "Momentum",
		"tier": 1,
		"cost": 1,
		"max_ranks": 3,
		"effect": "Combo grants +1% damage per rank",
		"prereqs": "-"
	},
	{
		"id": "burst_typing",
		"name": "Burst Typing",
		"tier": 2,
		"cost": 2,
		"max_ranks": 2,
		"effect": "First 3 words deal +20% damage per rank",
		"prereqs": "Quick Start"
	},
	{
		"id": "chain_killer",
		"name": "Chain Killer",
		"tier": 2,
		"cost": 2,
		"max_ranks": 2,
		"effect": "+10% damage for kills within 2s per rank",
		"prereqs": "Momentum"
	},
	{
		"id": "overdrive",
		"name": "Overdrive",
		"tier": 3,
		"cost": 3,
		"max_ranks": 1,
		"effect": "Active: +50% damage for 10s (60s cooldown)",
		"prereqs": "Burst Typing + Chain Killer"
	},
	{
		"id": "speed_demon",
		"name": "Speed Demon",
		"tier": 4,
		"cost": 5,
		"max_ranks": 1,
		"effect": "Passive: +15% damage, -5% accuracy tolerance",
		"prereqs": "Overdrive"
	}
]

# Accuracy tree skills
const ACCURACY_SKILLS: Array[Dictionary] = [
	{
		"id": "steady_hands",
		"name": "Steady Hands",
		"tier": 1,
		"cost": 1,
		"max_ranks": 3,
		"effect": "+5% crit chance per rank",
		"prereqs": "-"
	},
	{
		"id": "focus",
		"name": "Focus",
		"tier": 1,
		"cost": 1,
		"max_ranks": 3,
		"effect": "Mistake penalty reduced 10% per rank",
		"prereqs": "-"
	},
	{
		"id": "critical_strike",
		"name": "Critical Strike",
		"tier": 2,
		"cost": 2,
		"max_ranks": 2,
		"effect": "Crit damage +50% per rank",
		"prereqs": "Steady Hands"
	},
	{
		"id": "recovery",
		"name": "Quick Recovery",
		"tier": 2,
		"cost": 2,
		"max_ranks": 2,
		"effect": "Mistakes don't break combo (once per 8s, -2s per rank)",
		"prereqs": "Focus"
	},
	{
		"id": "perfect_form",
		"name": "Perfect Form",
		"tier": 3,
		"cost": 3,
		"max_ranks": 1,
		"effect": "Active: 100% crit chance for 8s (90s cooldown)",
		"prereqs": "Critical Strike + Quick Recovery"
	},
	{
		"id": "precision_master",
		"name": "Precision Master",
		"tier": 4,
		"cost": 5,
		"max_ranks": 1,
		"effect": "Passive: Perfect combos (10+) deal +50% damage",
		"prereqs": "Perfect Form"
	}
]

# Defense tree skills
const DEFENSE_SKILLS: Array[Dictionary] = [
	{
		"id": "fortify",
		"name": "Fortify",
		"tier": 1,
		"cost": 1,
		"max_ranks": 3,
		"effect": "Castle takes 5% less damage per rank",
		"prereqs": "-"
	},
	{
		"id": "regeneration",
		"name": "Regeneration",
		"tier": 1,
		"cost": 1,
		"max_ranks": 3,
		"effect": "Castle heals 1 HP per wave per rank",
		"prereqs": "-"
	},
	{
		"id": "thick_walls",
		"name": "Thick Walls",
		"tier": 2,
		"cost": 2,
		"max_ranks": 2,
		"effect": "+10% gold from kills per rank",
		"prereqs": "Fortify"
	},
	{
		"id": "slowing_aura",
		"name": "Slowing Aura",
		"tier": 2,
		"cost": 2,
		"max_ranks": 2,
		"effect": "Enemies near castle slowed 10% per rank",
		"prereqs": "Regeneration"
	},
	{
		"id": "last_stand",
		"name": "Last Stand",
		"tier": 3,
		"cost": 3,
		"max_ranks": 1,
		"effect": "Active: Block all damage for 5s (120s cooldown)",
		"prereqs": "Thick Walls + Slowing Aura"
	},
	{
		"id": "guardian_spirit",
		"name": "Guardian Spirit",
		"tier": 4,
		"cost": 5,
		"max_ranks": 1,
		"effect": "Passive: Survive one lethal hit per battle (1 HP)",
		"prereqs": "Last Stand"
	}
]

# Skill tips
const SKILL_TIPS: Array[String] = [
	"Spend skill points earned by leveling up",
	"Each tree has 4 tiers - unlock prerequisites first",
	"Tier 3 skills are Active abilities with cooldowns",
	"Tier 4 skills are powerful Capstone passives",
	"Focus one tree or spread points across all three",
	"Speed tree is best for aggressive DPS builds",
	"Accuracy tree excels at critical hit builds",
	"Defense tree helps survive difficult content"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 720)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "SKILL TREES"
	DesignSystem.style_label(title, "h2", Color(0.8, 0.6, 0.3))
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
	subtitle.text = "3 skill trees with 18 skills across 4 tiers"
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
	footer.text = "Spend skill points earned by leveling up"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_skill_trees_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Tree overview
	_build_trees_overview()

	# Speed tree
	_build_tree_section("WAY OF THE SWIFT", Color(0.5, 0.8, 1.0), SPEED_SKILLS)

	# Accuracy tree
	_build_tree_section("WAY OF PRECISION", Color(0.8, 0.6, 0.3), ACCURACY_SKILLS)

	# Defense tree
	_build_tree_section("WAY OF THE GUARDIAN", Color(0.5, 0.8, 0.3), DEFENSE_SKILLS)

	# Tips
	_build_tips_section()


func _build_trees_overview() -> void:
	var section := _create_section_panel("SKILL TREE OVERVIEW", Color(0.6, 0.5, 0.7))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tree in SKILL_TREES:
		var container := DesignSystem.create_vbox(1)
		vbox.add_child(container)

		var header_hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
		container.add_child(header_hbox)

		var name_label := Label.new()
		name_label.text = str(tree.get("name", ""))
		DesignSystem.style_label(name_label, "caption", tree.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(150, 0)
		header_hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(tree.get("desc", ""))
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
		header_hbox.add_child(desc_label)

		var focus_label := Label.new()
		focus_label.text = "  Focus: %s" % tree.get("focus", "")
		DesignSystem.style_label(focus_label, "caption", Color(0.5, 0.6, 0.5))
		container.add_child(focus_label)


func _build_tree_section(title: String, color: Color, skills: Array[Dictionary]) -> void:
	var section := _create_section_panel(title, color)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Header row
	var header_hbox := DesignSystem.create_hbox(DesignSystem.SPACE_XS)
	vbox.add_child(header_hbox)

	var headers := ["T", "Skill", "Cost", "Ranks", "Effect"]
	var widths := [20, 110, 35, 40, 240]
	for i in headers.size():
		var h := Label.new()
		h.text = headers[i]
		DesignSystem.style_label(h, "caption", Color(0.5, 0.5, 0.6))
		h.custom_minimum_size = Vector2(widths[i], 0)
		header_hbox.add_child(h)

	# Skills
	for skill in skills:
		var container := DesignSystem.create_vbox(1)
		vbox.add_child(container)

		var row := DesignSystem.create_hbox(DesignSystem.SPACE_XS)
		container.add_child(row)

		# Tier
		var tier_label := Label.new()
		tier_label.text = str(skill.get("tier", 1))
		DesignSystem.style_label(tier_label, "caption", _get_tier_color(int(skill.get("tier", 1))))
		tier_label.custom_minimum_size = Vector2(20, 0)
		row.add_child(tier_label)

		# Name
		var name_label := Label.new()
		name_label.text = str(skill.get("name", ""))
		DesignSystem.style_label(name_label, "caption", color)
		name_label.custom_minimum_size = Vector2(110, 0)
		row.add_child(name_label)

		# Cost
		var cost_label := Label.new()
		cost_label.text = str(skill.get("cost", 1))
		DesignSystem.style_label(cost_label, "caption", ThemeColors.RESOURCE_GOLD)
		cost_label.custom_minimum_size = Vector2(35, 0)
		row.add_child(cost_label)

		# Max ranks
		var ranks_label := Label.new()
		ranks_label.text = "x%d" % skill.get("max_ranks", 1)
		DesignSystem.style_label(ranks_label, "caption", Color.WHITE)
		ranks_label.custom_minimum_size = Vector2(40, 0)
		row.add_child(ranks_label)

		# Effect
		var effect_label := Label.new()
		effect_label.text = str(skill.get("effect", ""))
		DesignSystem.style_label(effect_label, "caption", ThemeColors.TEXT_DIM)
		effect_label.custom_minimum_size = Vector2(240, 0)
		effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(effect_label)

		# Prerequisites
		var prereqs: String = str(skill.get("prereqs", "-"))
		if prereqs != "-":
			var prereq_label := Label.new()
			prereq_label.text = "     Requires: %s" % prereqs
			DesignSystem.style_label(prereq_label, "caption", Color(0.5, 0.5, 0.5))
			container.add_child(prereq_label)


func _get_tier_color(tier: int) -> Color:
	match tier:
		1: return Color(0.5, 0.8, 0.3)
		2: return Color(0.5, 0.7, 0.9)
		3: return Color(0.8, 0.5, 0.8)
		4: return Color(1.0, 0.84, 0.0)
		_: return Color.WHITE


func _build_tips_section() -> void:
	var section := _create_section_panel("SKILL TIPS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in SKILL_TIPS:
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
