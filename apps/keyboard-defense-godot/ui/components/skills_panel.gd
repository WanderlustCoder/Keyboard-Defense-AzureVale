class_name SkillsPanel
extends PanelContainer
## Skills Panel - View and upgrade player skill trees

signal closed
signal skill_learned(tree_id: String, skill_id: String)

const ThemeColors = preload("res://ui/theme_colors.gd")
const SimSkills = preload("res://sim/skills.gd")
const TypingProfile = preload("res://game/typing_profile.gd")

var _profile: Dictionary = {}
var _learned_skills: Dictionary = {}
var _skill_points: int = 0
var _selected_tree: String = "speed"
var _selected_skill: String = ""

# UI elements
var _close_btn: Button = null
var _skill_points_label: Label = null
var _tree_tabs: HBoxContainer = null
var _tree_buttons: Dictionary = {}  # tree_id -> Button
var _tree_content: VBoxContainer = null
var _skill_buttons: Dictionary = {}  # skill_id -> Button
var _skill_detail_panel: PanelContainer = null
var _skill_detail_label: RichTextLabel = null
var _learn_btn: Button = null

# Tree colors
const TREE_COLORS: Dictionary = {
	"speed": Color(0.4, 0.8, 1.0),      # Cyan
	"accuracy": Color(1.0, 0.8, 0.3),   # Gold
	"defense": Color(0.4, 1.0, 0.4)     # Green
}


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(600, 500)

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

	# Header with title and close button
	var header := HBoxContainer.new()
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "SKILL TREES"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", ThemeColors.ACCENT)
	header.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_skill_points_label = Label.new()
	_skill_points_label.add_theme_font_size_override("font_size", 14)
	_skill_points_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	header.add_child(_skill_points_label)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(20, 0)
	header.add_child(spacer2)

	_close_btn = Button.new()
	_close_btn.text = "X"
	_close_btn.custom_minimum_size = Vector2(30, 30)
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Tree tabs
	_tree_tabs = HBoxContainer.new()
	_tree_tabs.add_theme_constant_override("separation", 5)
	main_vbox.add_child(_tree_tabs)

	for tree_id in SimSkills.get_all_trees():
		var tree: Dictionary = SimSkills.get_tree(tree_id)
		var tree_name: String = str(tree.get("name", tree_id.capitalize()))

		var btn := Button.new()
		btn.text = tree_name
		btn.custom_minimum_size = Vector2(150, 35)
		btn.pressed.connect(_on_tree_selected.bind(tree_id))
		_tree_tabs.add_child(btn)
		_tree_buttons[tree_id] = btn

	# Main content area (split into skills grid + detail panel)
	var content_hbox := HBoxContainer.new()
	content_hbox.add_theme_constant_override("separation", 10)
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_hbox)

	# Left side: skill tree content
	var tree_scroll := ScrollContainer.new()
	tree_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_hbox.add_child(tree_scroll)

	_tree_content = VBoxContainer.new()
	_tree_content.add_theme_constant_override("separation", 8)
	_tree_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree_scroll.add_child(_tree_content)

	# Right side: skill detail panel
	_skill_detail_panel = PanelContainer.new()
	_skill_detail_panel.custom_minimum_size = Vector2(220, 0)
	content_hbox.add_child(_skill_detail_panel)

	var detail_style := StyleBoxFlat.new()
	detail_style.bg_color = Color(0.05, 0.06, 0.09, 0.9)
	detail_style.border_color = ThemeColors.BORDER_DISABLED
	detail_style.set_border_width_all(1)
	detail_style.set_corner_radius_all(4)
	detail_style.set_content_margin_all(8)
	_skill_detail_panel.add_theme_stylebox_override("panel", detail_style)

	var detail_vbox := VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 8)
	_skill_detail_panel.add_child(detail_vbox)

	_skill_detail_label = RichTextLabel.new()
	_skill_detail_label.bbcode_enabled = true
	_skill_detail_label.fit_content = true
	_skill_detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_skill_detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_skill_detail_label.add_theme_font_size_override("normal_font_size", 12)
	detail_vbox.add_child(_skill_detail_label)

	_learn_btn = Button.new()
	_learn_btn.text = "Learn Skill"
	_learn_btn.visible = false
	_learn_btn.pressed.connect(_on_learn_pressed)
	detail_vbox.add_child(_learn_btn)

	_update_tree_tabs()


func show_skills(profile: Dictionary) -> void:
	_profile = profile
	_learned_skills = TypingProfile.get_learned_skills(profile)
	_skill_points = TypingProfile.get_skill_points(profile)
	_selected_skill = ""
	_update_skill_points_display()
	_update_tree_tabs()
	_build_tree_content()
	_clear_detail()
	show()


func _update_skill_points_display() -> void:
	_skill_points_label.text = "Skill Points: %d" % _skill_points


func _update_tree_tabs() -> void:
	for tree_id in _tree_buttons.keys():
		var btn: Button = _tree_buttons[tree_id]
		var color: Color = TREE_COLORS.get(tree_id, Color.WHITE)
		if tree_id == _selected_tree:
			btn.add_theme_color_override("font_color", color)
		else:
			btn.remove_theme_color_override("font_color")


func _clear_tree_content() -> void:
	for child in _tree_content.get_children():
		child.queue_free()
	_skill_buttons.clear()


func _clear_detail() -> void:
	_skill_detail_label.text = "[color=#888888]Select a skill to view details[/color]"
	_learn_btn.visible = false


func _build_tree_content() -> void:
	_clear_tree_content()

	var tree_data: Dictionary = SimSkills.get_tree(_selected_tree)
	var skills: Dictionary = tree_data.get("skills", {})
	var tree_color: Color = TREE_COLORS.get(_selected_tree, Color.WHITE)

	# Group skills by tier
	var skills_by_tier: Dictionary = {}
	for skill_id in skills.keys():
		var skill: Dictionary = skills[skill_id]
		var tier: int = int(skill.get("tier", 1))
		if not skills_by_tier.has(tier):
			skills_by_tier[tier] = []
		skills_by_tier[tier].append({"id": skill_id, "data": skill})

	# Sort tiers
	var tiers: Array = skills_by_tier.keys()
	tiers.sort()

	# Build UI for each tier
	for tier in tiers:
		# Tier header
		var tier_label := Label.new()
		tier_label.text = "Tier %d" % tier
		tier_label.add_theme_font_size_override("font_size", 14)
		tier_label.add_theme_color_override("font_color", tree_color)
		_tree_content.add_child(tier_label)

		# Skills in this tier
		var tier_hbox := HFlowContainer.new()
		tier_hbox.add_theme_constant_override("h_separation", 8)
		tier_hbox.add_theme_constant_override("v_separation", 8)
		_tree_content.add_child(tier_hbox)

		for skill_data in skills_by_tier[tier]:
			var skill_id: String = str(skill_data.get("id", ""))
			var skill: Dictionary = skill_data.get("data", {})
			var btn := _create_skill_button(skill_id, skill, tree_color)
			tier_hbox.add_child(btn)
			_skill_buttons[skill_id] = btn

		# Spacer between tiers
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 5)
		_tree_content.add_child(spacer)


func _create_skill_button(skill_id: String, skill: Dictionary, tree_color: Color) -> Button:
	var name: String = str(skill.get("name", skill_id))
	var max_ranks: int = int(skill.get("max_ranks", 1))
	var current_rank: int = SimSkills.get_skill_rank(_selected_tree, skill_id, _learned_skills)
	var can_learn: bool = SimSkills.can_learn_skill(_selected_tree, skill_id, _learned_skills)
	var is_maxed: bool = current_rank >= max_ranks

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(140, 50)
	btn.pressed.connect(_on_skill_selected.bind(skill_id))

	# Create button content
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	btn.add_child(vbox)

	var name_label := Label.new()
	name_label.text = name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(name_label)

	var rank_label := Label.new()
	rank_label.text = "%d/%d" % [current_rank, max_ranks]
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(rank_label)

	# Color based on state
	if is_maxed:
		# Fully learned - gold/bright
		name_label.add_theme_color_override("font_color", tree_color)
		rank_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	elif current_rank > 0:
		# Partially learned - normal color
		name_label.add_theme_color_override("font_color", tree_color.lightened(0.3))
		rank_label.add_theme_color_override("font_color", Color.WHITE)
	elif can_learn:
		# Available to learn - dimmer
		name_label.add_theme_color_override("font_color", Color.WHITE)
		rank_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	else:
		# Locked - gray
		name_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		rank_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))

	return btn


func _show_skill_detail(skill_id: String) -> void:
	var skill: Dictionary = SimSkills.get_skill(_selected_tree, skill_id)
	if skill.is_empty():
		_clear_detail()
		return

	var name: String = str(skill.get("name", skill_id))
	var effect: String = str(skill.get("effect", ""))
	var cost: int = int(skill.get("cost", 1))
	var max_ranks: int = int(skill.get("max_ranks", 1))
	var current_rank: int = SimSkills.get_skill_rank(_selected_tree, skill_id, _learned_skills)
	var can_learn: bool = SimSkills.can_learn_skill(_selected_tree, skill_id, _learned_skills)
	var is_maxed: bool = current_rank >= max_ranks
	var is_active: bool = SimSkills.is_active_skill(_selected_tree, skill_id)

	var tree_color: Color = TREE_COLORS.get(_selected_tree, Color.WHITE)
	var lines: Array[String] = []

	lines.append("[color=%s]%s[/color]" % [tree_color.to_html(), name])
	lines.append("[color=gray]Rank: %d/%d[/color]" % [current_rank, max_ranks])
	lines.append("")

	# Skill type
	if is_active:
		lines.append("[color=yellow]Active Skill[/color]")
		var cooldown: float = float(skill.get("cooldown", 60.0))
		var duration: float = float(skill.get("duration", 5.0))
		lines.append("Duration: %.1fs | Cooldown: %.0fs" % [duration, cooldown])
		lines.append("")
	else:
		lines.append("[color=cyan]Passive Skill[/color]")
		lines.append("")

	# Effect description
	lines.append("[color=orange]Effect:[/color]")
	lines.append(effect)
	lines.append("")

	# Cost
	lines.append("Cost: [color=cyan]%d[/color] skill point(s)" % cost)

	# Prerequisites
	var prereqs: Array[String] = SimSkills.get_skill_prerequisites(_selected_tree, skill_id)
	if not prereqs.is_empty():
		lines.append("")
		lines.append("[color=gray]Requires:[/color]")
		for prereq_id in prereqs:
			var prereq_name: String = SimSkills.get_skill_name(_selected_tree, prereq_id)
			var prereq_rank: int = SimSkills.get_skill_rank(_selected_tree, prereq_id, _learned_skills)
			if prereq_rank > 0:
				lines.append("  [color=lime]%s[/color]" % prereq_name)
			else:
				lines.append("  [color=red]%s[/color]" % prereq_name)

	_skill_detail_label.text = "\n".join(lines)

	# Show learn button if applicable
	if is_maxed:
		_learn_btn.visible = false
	elif can_learn and _skill_points >= cost:
		_learn_btn.text = "Learn (%d points)" % cost
		_learn_btn.visible = true
		_learn_btn.disabled = false
	elif can_learn:
		_learn_btn.text = "Need %d points" % cost
		_learn_btn.visible = true
		_learn_btn.disabled = true
	else:
		_learn_btn.text = "Prerequisites not met"
		_learn_btn.visible = true
		_learn_btn.disabled = true


func _on_tree_selected(tree_id: String) -> void:
	_selected_tree = tree_id
	_selected_skill = ""
	_update_tree_tabs()
	_build_tree_content()
	_clear_detail()


func _on_skill_selected(skill_id: String) -> void:
	_selected_skill = skill_id
	_show_skill_detail(skill_id)


func _on_learn_pressed() -> void:
	if _selected_skill.is_empty():
		return

	var skill: Dictionary = SimSkills.get_skill(_selected_tree, _selected_skill)
	var cost: int = int(skill.get("cost", 1))
	var max_ranks: int = int(skill.get("max_ranks", 1))
	var current_rank: int = SimSkills.get_skill_rank(_selected_tree, _selected_skill, _learned_skills)
	var can_learn: bool = SimSkills.can_learn_skill(_selected_tree, _selected_skill, _learned_skills)

	if not can_learn or _skill_points < cost or current_rank >= max_ranks:
		return

	# Learn the skill
	_learned_skills = SimSkills.learn_skill(_selected_tree, _selected_skill, _learned_skills)
	_skill_points -= cost

	# Save to profile
	TypingProfile.set_learned_skills(_profile, _learned_skills)
	TypingProfile.set_skill_points(_profile, _skill_points)
	TypingProfile.save_profile(_profile)

	# Emit signal
	skill_learned.emit(_selected_tree, _selected_skill)

	# Refresh display
	_update_skill_points_display()
	_build_tree_content()
	_show_skill_detail(_selected_skill)


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
