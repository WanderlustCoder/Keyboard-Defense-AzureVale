class_name SkillTreesReferencePanel
extends PanelContainer
## Skill Trees Reference Panel - Shows all 3 skill trees and their abilities

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

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
	custom_minimum_size = Vector2(560, 720)

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
	title.text = "SKILL TREES"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3))
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
	subtitle.text = "3 skill trees with 18 skills across 4 tiers"
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
	footer.text = "Spend skill points earned by leveling up"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


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
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 1)
		vbox.add_child(container)

		var header_hbox := HBoxContainer.new()
		header_hbox.add_theme_constant_override("separation", 10)
		container.add_child(header_hbox)

		var name_label := Label.new()
		name_label.text = str(tree.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.add_theme_color_override("font_color", tree.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(150, 0)
		header_hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(tree.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		header_hbox.add_child(desc_label)

		var focus_label := Label.new()
		focus_label.text = "  Focus: %s" % tree.get("focus", "")
		focus_label.add_theme_font_size_override("font_size", 9)
		focus_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.5))
		container.add_child(focus_label)


func _build_tree_section(title: String, color: Color, skills: Array[Dictionary]) -> void:
	var section := _create_section_panel(title, color)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Header row
	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 5)
	vbox.add_child(header_hbox)

	var headers := ["T", "Skill", "Cost", "Ranks", "Effect"]
	var widths := [20, 110, 35, 40, 240]
	for i in headers.size():
		var h := Label.new()
		h.text = headers[i]
		h.add_theme_font_size_override("font_size", 9)
		h.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		h.custom_minimum_size = Vector2(widths[i], 0)
		header_hbox.add_child(h)

	# Skills
	for skill in skills:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 1)
		vbox.add_child(container)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 5)
		container.add_child(row)

		# Tier
		var tier_label := Label.new()
		tier_label.text = str(skill.get("tier", 1))
		tier_label.add_theme_font_size_override("font_size", 10)
		tier_label.add_theme_color_override("font_color", _get_tier_color(int(skill.get("tier", 1))))
		tier_label.custom_minimum_size = Vector2(20, 0)
		row.add_child(tier_label)

		# Name
		var name_label := Label.new()
		name_label.text = str(skill.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", color)
		name_label.custom_minimum_size = Vector2(110, 0)
		row.add_child(name_label)

		# Cost
		var cost_label := Label.new()
		cost_label.text = str(skill.get("cost", 1))
		cost_label.add_theme_font_size_override("font_size", 10)
		cost_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		cost_label.custom_minimum_size = Vector2(35, 0)
		row.add_child(cost_label)

		# Max ranks
		var ranks_label := Label.new()
		ranks_label.text = "x%d" % skill.get("max_ranks", 1)
		ranks_label.add_theme_font_size_override("font_size", 10)
		ranks_label.add_theme_color_override("font_color", Color.WHITE)
		ranks_label.custom_minimum_size = Vector2(40, 0)
		row.add_child(ranks_label)

		# Effect
		var effect_label := Label.new()
		effect_label.text = str(skill.get("effect", ""))
		effect_label.add_theme_font_size_override("font_size", 9)
		effect_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		effect_label.custom_minimum_size = Vector2(240, 0)
		effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(effect_label)

		# Prerequisites
		var prereqs: String = str(skill.get("prereqs", "-"))
		if prereqs != "-":
			var prereq_label := Label.new()
			prereq_label.text = "     Requires: %s" % prereqs
			prereq_label.add_theme_font_size_override("font_size", 9)
			prereq_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
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
