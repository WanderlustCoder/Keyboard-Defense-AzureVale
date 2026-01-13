class_name ResearchTreePanel
extends PanelContainer
## Research Tree Panel - Shows tech tree and research progress.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed
signal research_selected(research_id: String)

var _research_tree: Dictionary = {}
var _current_gold: int = 0

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Category colors
const CATEGORY_COLORS: Dictionary = {
	"construction": Color(0.8, 0.6, 0.4),
	"economy": Color(1.0, 0.84, 0.0),
	"military": Color(0.9, 0.4, 0.4),
	"mystical": Color(0.7, 0.5, 0.9)
}

func _ready() -> void:
	_build_ui()
	hide()

func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 560)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "RESEARCH TREE"
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
	subtitle.text = "Unlock powerful upgrades by investing gold and time"
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
	footer.text = "Research advances after each wave"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)

func show_research_tree(tree: Dictionary, gold: int = 0) -> void:
	_research_tree = tree
	_current_gold = gold
	_build_content()
	show()

func refresh(tree: Dictionary, gold: int = 0) -> void:
	_research_tree = tree
	_current_gold = gold
	_build_content()

func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()

func _build_content() -> void:
	_clear_content()

	# Summary section
	_build_summary_section()

	# Build each category
	for category in ["construction", "economy", "military", "mystical"]:
		if _research_tree.has(category) and not _research_tree[category].is_empty():
			_build_category_section(category)

func _build_summary_section() -> void:
	var section := PanelContainer.new()

	var section_style := StyleBoxFlat.new()
	section_style.bg_color = Color(0.1, 0.12, 0.18, 0.9)
	section_style.border_color = Color(0.7, 0.5, 0.9, 0.5)
	section_style.set_border_width_all(2)
	section_style.set_corner_radius_all(6)
	section_style.set_content_margin_all(10)
	section.add_theme_stylebox_override("panel", section_style)

	_content_vbox.add_child(section)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 30)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	section.add_child(hbox)

	# Count stats
	var completed: int = 0
	var total: int = 0
	var available: int = 0
	var active: String = ""

	for category in _research_tree.keys():
		for research in _research_tree[category]:
			total += 1
			if bool(research.get("completed", false)):
				completed += 1
			elif bool(research.get("active", false)):
				active = str(research.get("label", ""))
			elif bool(research.get("available", false)):
				available += 1

	# Progress
	_add_summary_stat(hbox, "Completed", "%d/%d" % [completed, total], Color(0.4, 0.9, 0.4))
	_add_summary_stat(hbox, "Available", str(available), Color(0.6, 0.8, 1.0))
	_add_summary_stat(hbox, "Gold", str(_current_gold), Color(1.0, 0.84, 0.0))

	if not active.is_empty():
		_add_summary_stat(hbox, "Researching", active, Color(0.7, 0.5, 0.9))

func _add_summary_stat(parent: Control, label: String, value: String, color: Color) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	parent.add_child(vbox)

	var label_node := Label.new()
	label_node.text = label
	label_node.add_theme_font_size_override("font_size", 10)
	label_node.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label_node)

	var value_node := Label.new()
	value_node.text = value
	value_node.add_theme_font_size_override("font_size", 14)
	value_node.add_theme_color_override("font_color", color)
	value_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(value_node)

func _build_category_section(category: String) -> void:
	var color: Color = CATEGORY_COLORS.get(category, Color.WHITE)
	var section := _create_section_panel(category.to_upper(), color)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var research_list: Array = _research_tree.get(category, [])
	for research in research_list:
		var card := _create_research_card(research)
		vbox.add_child(card)

func _create_research_card(research: Dictionary) -> Control:
	var research_id: String = str(research.get("id", ""))
	var label: String = str(research.get("label", research_id))
	var description: String = str(research.get("description", ""))
	var cost: Dictionary = research.get("cost", {})
	var gold_cost: int = int(cost.get("gold", 0))
	var waves: int = int(research.get("waves_to_complete", 1))
	var requires: Array = research.get("requires", [])

	var completed: bool = bool(research.get("completed", false))
	var active: bool = bool(research.get("active", false))
	var available: bool = bool(research.get("available", false))
	var can_afford: bool = bool(research.get("can_afford", false))

	var container := PanelContainer.new()

	var bg_color: Color
	var border_color: Color
	if completed:
		bg_color = Color(0.2, 0.35, 0.2, 0.9)
		border_color = Color(0.4, 0.7, 0.4)
	elif active:
		bg_color = Color(0.25, 0.2, 0.35, 0.9)
		border_color = Color(0.7, 0.5, 0.9)
	elif available and can_afford:
		bg_color = Color(0.15, 0.2, 0.3, 0.9)
		border_color = Color(0.4, 0.6, 0.8)
	else:
		bg_color = Color(0.1, 0.1, 0.12, 0.7)
		border_color = Color(0.3, 0.3, 0.35)

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = bg_color
	container_style.border_color = border_color
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(8)
	container.add_theme_stylebox_override("panel", container_style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 4)
	container.add_child(main_vbox)

	# Header row
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	main_vbox.add_child(header)

	var name_label := Label.new()
	name_label.text = label
	name_label.add_theme_font_size_override("font_size", 12)
	if completed:
		name_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	elif active:
		name_label.add_theme_color_override("font_color", Color(0.7, 0.5, 0.9))
	else:
		name_label.add_theme_color_override("font_color", Color.WHITE)
	header.add_child(name_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	# Status indicator
	var status_label := Label.new()
	if completed:
		status_label.text = "DONE"
		status_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	elif active:
		status_label.text = "IN PROGRESS"
		status_label.add_theme_color_override("font_color", Color(0.7, 0.5, 0.9))
	elif available and can_afford:
		status_label.text = "AVAILABLE"
		status_label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	elif available:
		status_label.text = "NEED GOLD"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	else:
		status_label.text = "LOCKED"
		status_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	status_label.add_theme_font_size_override("font_size", 10)
	header.add_child(status_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_vbox.add_child(desc_label)

	# Stats row
	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 15)
	main_vbox.add_child(stats_row)

	# Cost
	if not completed:
		var cost_label := Label.new()
		cost_label.text = "%d gold" % gold_cost
		cost_label.add_theme_font_size_override("font_size", 10)
		cost_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0) if can_afford else Color(0.7, 0.4, 0.4))
		stats_row.add_child(cost_label)

	# Duration
	var waves_label := Label.new()
	waves_label.text = "%d wave%s" % [waves, "s" if waves != 1 else ""]
	waves_label.add_theme_font_size_override("font_size", 10)
	waves_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
	stats_row.add_child(waves_label)

	# Prerequisites
	if not requires.is_empty() and not completed:
		var req_label := Label.new()
		req_label.text = "Requires: " + ", ".join(requires)
		req_label.add_theme_font_size_override("font_size", 9)
		req_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		main_vbox.add_child(req_label)

	return container

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
