class_name ResearchPanel
extends BasePanel
## Research panel showing the tech tree organized by category.
## Allows starting and canceling research projects.

const SimResearch = preload("res://sim/research.gd")

signal research_selected(research_id: String)
signal research_cancelled

var _state: RefCounted  # GameState
var _category_containers: Dictionary = {}
var _research_cards: Dictionary = {}
var _current_research_card: Control
var _progress_bar: ProgressBar
var _progress_label: Label


func _init() -> void:
	panel_title = "Research"
	panel_width = DesignSystem.SIZE_PANEL_LG


func _build_content() -> void:
	# Current research section
	_build_current_research_section()
	add_separator()

	# Category tabs
	_build_category_sections()


func set_state(state: RefCounted) -> void:
	_state = state
	refresh()


func refresh() -> void:
	if not _state:
		return

	var research := SimResearch.instance()
	var tree: Dictionary = research.get_research_tree(_state)
	var summary: Dictionary = research.get_research_summary(_state)

	# Update current research display
	_update_current_research(summary, research)

	# Update all research cards
	for category in tree.keys():
		for item in tree[category]:
			var card: Control = _research_cards.get(item.id)
			if card:
				_update_research_card(card, item)


func _build_current_research_section() -> void:
	var section := add_section("Current Research")

	_current_research_card = _create_current_research_display()
	section.add_child(_current_research_card)


func _create_current_research_display() -> Control:
	var container := PanelContainer.new()
	var style := DesignSystem.create_elevated_style(ThemeColors.BG_CARD)
	container.add_theme_stylebox_override("panel", style)

	var vbox := DesignSystem.create_vbox(DesignSystem.SPACE_SM)
	container.add_child(vbox)

	# Header row with name and cancel button
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	vbox.add_child(header)

	var title := Label.new()
	title.name = "Title"
	title.text = "No active research"
	DesignSystem.style_label(title, "h3", ThemeColors.TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var cancel_btn := BaseButton.ghost("Cancel", _on_cancel_pressed)
	cancel_btn.name = "CancelButton"
	cancel_btn.visible = false
	header.add_child(cancel_btn)

	# Progress bar
	_progress_bar = ProgressBar.new()
	_progress_bar.name = "ProgressBar"
	_progress_bar.custom_minimum_size.y = 8
	_progress_bar.show_percentage = false
	_progress_bar.visible = false

	var progress_style := StyleBoxFlat.new()
	progress_style.bg_color = ThemeColors.BG_INPUT
	progress_style.set_corner_radius_all(DesignSystem.RADIUS_SM)
	_progress_bar.add_theme_stylebox_override("background", progress_style)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = ThemeColors.ACCENT
	fill_style.set_corner_radius_all(DesignSystem.RADIUS_SM)
	_progress_bar.add_theme_stylebox_override("fill", fill_style)

	vbox.add_child(_progress_bar)

	# Progress label
	_progress_label = Label.new()
	_progress_label.name = "ProgressLabel"
	_progress_label.text = ""
	_progress_label.visible = false
	DesignSystem.style_label(_progress_label, "caption", ThemeColors.TEXT_DIM)
	vbox.add_child(_progress_label)

	# Description
	var desc := Label.new()
	desc.name = "Description"
	desc.text = "Start research from the categories below."
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	DesignSystem.style_label(desc, "body_small", ThemeColors.TEXT_DIM)
	vbox.add_child(desc)

	return container


func _update_current_research(summary: Dictionary, research: SimResearch) -> void:
	var title: Label = _current_research_card.get_node("VBoxContainer/HBoxContainer/Title")
	var cancel_btn: Button = _current_research_card.get_node("VBoxContainer/HBoxContainer/CancelButton")
	var desc: Label = _current_research_card.get_node("VBoxContainer/Description")

	if summary.active_research.is_empty():
		title.text = "No active research"
		cancel_btn.visible = false
		_progress_bar.visible = false
		_progress_label.visible = false
		desc.text = "Start research from the categories below."
		desc.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	else:
		var info: Dictionary = research.get_research(summary.active_research)
		title.text = summary.active_label
		cancel_btn.visible = true
		_progress_bar.visible = true
		_progress_bar.value = summary.progress_percent * 100
		_progress_label.visible = true
		_progress_label.text = "%d / %d waves" % [summary.progress, summary.waves_needed]
		desc.text = str(info.get("description", ""))
		desc.add_theme_color_override("font_color", ThemeColors.TEXT)


func _build_category_sections() -> void:
	var research := SimResearch.instance()
	var categories: Dictionary = _get_category_metadata()

	for category_id in ["construction", "economy", "military", "mystical"]:
		var meta: Dictionary = categories.get(category_id, {})
		var section := add_section(meta.get("label", category_id.capitalize()))

		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", DesignSystem.SPACE_MD)
		grid.add_theme_constant_override("v_separation", DesignSystem.SPACE_MD)
		section.add_child(grid)

		_category_containers[category_id] = grid

		# Build placeholder cards (will be populated in refresh)
		var all_research: Array = research.get_all_research()
		for item in all_research:
			if str(item.get("category", "")) == category_id:
				var card := _create_research_card(item)
				grid.add_child(card)
				_research_cards[str(item.get("id", ""))] = card


func _create_research_card(data: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(250, 0)

	var vbox := DesignSystem.create_vbox(DesignSystem.SPACE_XS)
	card.add_child(vbox)

	# Header with name and cost
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_SM)
	vbox.add_child(header)

	var name_label := Label.new()
	name_label.name = "Name"
	name_label.text = str(data.get("label", ""))
	DesignSystem.style_label(name_label, "body", ThemeColors.TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)

	var cost_label := Label.new()
	cost_label.name = "Cost"
	var cost: int = int(data.get("cost", {}).get("gold", 0))
	cost_label.text = "%dg" % cost
	DesignSystem.style_label(cost_label, "caption", ThemeColors.RESOURCE_GOLD)
	header.add_child(cost_label)

	# Description
	var desc := Label.new()
	desc.name = "Description"
	desc.text = str(data.get("description", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	DesignSystem.style_label(desc, "caption", ThemeColors.TEXT_DIM)
	vbox.add_child(desc)

	# Waves to complete
	var waves_label := Label.new()
	waves_label.name = "Waves"
	var waves: int = int(data.get("waves_to_complete", 1))
	waves_label.text = "%d waves" % waves
	DesignSystem.style_label(waves_label, "caption", ThemeColors.TEXT_DIM)
	vbox.add_child(waves_label)

	# Status indicator
	var status := Label.new()
	status.name = "Status"
	status.text = ""
	DesignSystem.style_label(status, "caption", ThemeColors.SUCCESS)
	status.visible = false
	vbox.add_child(status)

	# Make it clickable
	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_research_card_clicked(str(data.get("id", "")))
	)
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	return card


func _update_research_card(card: Control, data: Dictionary) -> void:
	var name_label: Label = card.get_node("VBoxContainer/HBoxContainer/Name")
	var cost_label: Label = card.get_node("VBoxContainer/HBoxContainer/Cost")
	var status: Label = card.get_node("VBoxContainer/Status")

	var style: StyleBoxFlat

	if data.completed:
		# Completed state
		style = DesignSystem.create_elevated_style(ThemeColors.BG_CARD, DesignSystem.SHADOW_SM)
		style.border_color = ThemeColors.SUCCESS
		style.set_border_width_all(2)
		name_label.add_theme_color_override("font_color", ThemeColors.SUCCESS)
		cost_label.visible = false
		status.text = "Completed"
		status.add_theme_color_override("font_color", ThemeColors.SUCCESS)
		status.visible = true
		card.mouse_default_cursor_shape = Control.CURSOR_ARROW
	elif data.active:
		# Currently researching
		style = DesignSystem.create_elevated_style(ThemeColors.BG_CARD, DesignSystem.SHADOW_MD)
		style.border_color = ThemeColors.ACCENT
		style.set_border_width_all(2)
		name_label.add_theme_color_override("font_color", ThemeColors.ACCENT)
		cost_label.visible = false
		status.text = "In Progress"
		status.add_theme_color_override("font_color", ThemeColors.ACCENT)
		status.visible = true
		card.mouse_default_cursor_shape = Control.CURSOR_ARROW
	elif data.available:
		# Available to research
		style = DesignSystem.create_elevated_style(ThemeColors.BG_CARD, DesignSystem.SHADOW_SM)
		if data.can_afford:
			style.border_color = ThemeColors.BORDER_HIGHLIGHT
			name_label.add_theme_color_override("font_color", ThemeColors.TEXT)
			cost_label.add_theme_color_override("font_color", ThemeColors.RESOURCE_GOLD)
		else:
			style.border_color = ThemeColors.BORDER
			name_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
			cost_label.add_theme_color_override("font_color", ThemeColors.ERROR)
		style.set_border_width_all(1)
		cost_label.visible = true
		status.visible = false
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		# Locked (prerequisites not met)
		style = DesignSystem.create_elevated_style(ThemeColors.BG_CARD_DISABLED, DesignSystem.SHADOW_SM)
		style.border_color = ThemeColors.BORDER_DISABLED
		style.set_border_width_all(1)
		name_label.add_theme_color_override("font_color", ThemeColors.TEXT_DISABLED)
		cost_label.add_theme_color_override("font_color", ThemeColors.TEXT_DISABLED)
		cost_label.visible = true
		status.text = "Locked"
		status.add_theme_color_override("font_color", ThemeColors.TEXT_DISABLED)
		status.visible = true
		card.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN

	card.add_theme_stylebox_override("panel", style)


func _get_category_metadata() -> Dictionary:
	# Load from research.json categories
	var file := FileAccess.open("res://data/research.json", FileAccess.READ)
	if file:
		var json := JSON.new()
		var error := json.parse(file.get_as_text())
		file.close()
		if error == OK:
			return json.data.get("categories", {})
	return {}


func _on_research_card_clicked(research_id: String) -> void:
	if not _state:
		return

	var research := SimResearch.instance()
	var check: Dictionary = research.can_start_research(_state, research_id)

	if check.ok:
		research_selected.emit(research_id)


func _on_cancel_pressed() -> void:
	research_cancelled.emit()
