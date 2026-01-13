class_name KingdomDashboard
extends Control
## Kingdom management dashboard showing resources, workers, buildings, and research.
## Toggled with Tab during planning phase.
## Migrated to use ThemeColors autoload.

const GameState = preload("res://sim/types.gd")
const SimBuildings = preload("res://sim/buildings.gd")
const SimWorkers = preload("res://sim/workers.gd")
const SimResearch = preload("res://sim/research.gd")
const SimTrade = preload("res://sim/trade.gd")
const SimMap = preload("res://sim/map.gd")

signal worker_assigned(building_index: int)
signal worker_unassigned(building_index: int)
signal upgrade_requested(building_index: int)
signal research_started(research_id: String)
signal trade_executed(from: String, to: String, amount: int)
signal build_requested(building_type: String)
signal closed

const PANEL_WIDTH := 500
const PANEL_HEIGHT := 450
const SECTION_SPACING := 12
const ITEM_SPACING := 6
const FADE_DURATION := 0.15

var _state: GameState = null
var _tween: Tween = null
var _research_instance: SimResearch = null

# UI References
var _overlay: ColorRect
var _panel: PanelContainer
var _scroll: ScrollContainer
var _content: VBoxContainer
var _tabs: TabContainer

# Section containers
var _resources_section: VBoxContainer
var _workers_section: VBoxContainer
var _buildings_section: VBoxContainer
var _build_section: VBoxContainer
var _research_section: VBoxContainer
var _trade_section: VBoxContainer

func _ready() -> void:
	_build_ui()
	_research_instance = SimResearch.instance()
	visible = false

func _build_ui() -> void:
	# Overlay
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.6)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	# Center container
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# Main panel
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = ThemeColors.BG_PANEL
	panel_style.border_color = ThemeColors.BORDER
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.set_content_margin_all(12)
	_panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(_panel)

	# Panel content
	var panel_vbox := VBoxContainer.new()
	panel_vbox.add_theme_constant_override("separation", SECTION_SPACING)
	_panel.add_child(panel_vbox)

	# Header
	var header := HBoxContainer.new()
	panel_vbox.add_child(header)

	var title := Label.new()
	title.text = "KINGDOM OVERVIEW"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", ThemeColors.ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(32, 32)
	close_btn.pressed.connect(_on_close_pressed)
	header.add_child(close_btn)

	# Tab container
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_vbox.add_child(_tabs)

	# Create tabs
	_create_resources_tab()
	_create_build_tab()
	_create_workers_tab()
	_create_buildings_tab()
	_create_research_tab()
	_create_trade_tab()

func _create_resources_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "Resources"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_child(scroll)

	_resources_section = VBoxContainer.new()
	_resources_section.add_theme_constant_override("separation", ITEM_SPACING)
	scroll.add_child(_resources_section)

func _create_build_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "Build"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_child(scroll)

	_build_section = VBoxContainer.new()
	_build_section.add_theme_constant_override("separation", ITEM_SPACING)
	scroll.add_child(_build_section)

func _create_workers_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "Workers"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_child(scroll)

	_workers_section = VBoxContainer.new()
	_workers_section.add_theme_constant_override("separation", ITEM_SPACING)
	scroll.add_child(_workers_section)

func _create_buildings_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "Buildings"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_child(scroll)

	_buildings_section = VBoxContainer.new()
	_buildings_section.add_theme_constant_override("separation", ITEM_SPACING)
	scroll.add_child(_buildings_section)

func _create_research_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "Research"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_child(scroll)

	_research_section = VBoxContainer.new()
	_research_section.add_theme_constant_override("separation", ITEM_SPACING)
	scroll.add_child(_research_section)

func _create_trade_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "Trade"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_child(scroll)

	_trade_section = VBoxContainer.new()
	_trade_section.add_theme_constant_override("separation", ITEM_SPACING)
	scroll.add_child(_trade_section)

func update_state(state: GameState) -> void:
	_state = state
	if visible:
		_refresh_all()

func show_dashboard() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	visible = true
	modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)
	_refresh_all()

func hide_dashboard() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	_tween.tween_callback(func(): visible = false)
	closed.emit()

func _on_close_pressed() -> void:
	hide_dashboard()

func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed:
		if event.keycode == KEY_TAB or event.keycode == KEY_ESCAPE:
			hide_dashboard()
			get_viewport().set_input_as_handled()

func _refresh_all() -> void:
	if _state == null:
		return
	_refresh_resources()
	_refresh_build()
	_refresh_workers()
	_refresh_buildings()
	_refresh_research()
	_refresh_trade()

func _refresh_resources() -> void:
	_clear_children(_resources_section)
	if _state == null:
		return

	# Header
	var header := _create_section_header("Resource Summary")
	_resources_section.add_child(header)

	# Current resources
	var current_box := _create_info_box()
	_resources_section.add_child(current_box)

	var production: Dictionary = SimWorkers.daily_production_with_workers(_state)
	var upkeep: int = SimWorkers.daily_upkeep(_state)

	_add_resource_row(current_box, "Wood", int(_state.resources.get("wood", 0)), int(production.get("wood", 0)))
	_add_resource_row(current_box, "Stone", int(_state.resources.get("stone", 0)), int(production.get("stone", 0)))
	_add_resource_row(current_box, "Food", int(_state.resources.get("food", 0)), int(production.get("food", 0)) - upkeep, upkeep)
	_add_resource_row(current_box, "Gold", _state.gold, int(production.get("gold", 0)))

	# Defense rating
	var defense: int = SimBuildings.total_defense(_state)
	var defense_label := Label.new()
	defense_label.text = "Defense Rating: %d" % defense
	defense_label.add_theme_color_override("font_color", ThemeColors.ACCENT_CYAN)
	_resources_section.add_child(defense_label)

func _refresh_build() -> void:
	_clear_children(_build_section)
	if _state == null:
		return

	var header := _create_section_header("Construct Buildings")
	_build_section.add_child(header)

	# Hint text
	var hint := Label.new()
	hint.text = "Click to build, or type 'build [name]' in command bar"
	hint.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	hint.add_theme_font_size_override("font_size", 12)
	_build_section.add_child(hint)

	# Get available buildings from SimBuildings
	var available: Array = SimBuildings.get_available_buildings(_state)

	if available.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No buildings available to construct."
		empty_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		_build_section.add_child(empty_label)
		return

	for building_id in available:
		var row := _create_build_row(building_id)
		_build_section.add_child(row)

func _create_build_row(building_id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var info: Dictionary = SimBuildings.get_building_info(building_id)
	var cost: Dictionary = info.get("cost", {})
	var can_afford: bool = SimBuildings.can_afford(_state, cost)

	# Building name
	var name_label := Label.new()
	name_label.text = building_id.capitalize()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not can_afford:
		name_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	row.add_child(name_label)

	# Cost display
	var cost_text := _format_cost(cost)
	var cost_label := Label.new()
	cost_label.text = cost_text
	if can_afford:
		cost_label.add_theme_color_override("font_color", ThemeColors.ACCENT)
	else:
		cost_label.add_theme_color_override("font_color", ThemeColors.ERROR)
	row.add_child(cost_label)

	# Build button
	var build_btn := Button.new()
	build_btn.text = "Build"
	build_btn.custom_minimum_size = Vector2(60, 0)
	build_btn.disabled = not can_afford
	build_btn.pressed.connect(func(): _on_build_pressed(building_id))
	row.add_child(build_btn)

	return row

func _on_build_pressed(building_id: String) -> void:
	build_requested.emit(building_id)
	hide_dashboard()

func _refresh_workers() -> void:
	_clear_children(_workers_section)
	if _state == null:
		return

	var summary: Dictionary = SimWorkers.get_worker_summary(_state)

	# Header with counts
	var header := _create_section_header("Workers: %d/%d assigned" % [summary.assigned, summary.total_workers])
	_workers_section.add_child(header)

	var avail_label := Label.new()
	avail_label.text = "Available: %d | Upkeep: %d food/day" % [summary.available, summary.upkeep]
	avail_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	_workers_section.add_child(avail_label)

	# Worker assignments
	for assignment in summary.assignments:
		var row := _create_worker_row(assignment)
		_workers_section.add_child(row)

func _create_worker_row(assignment: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var name_label := Label.new()
	name_label.text = "%s (%d,%d)" % [str(assignment.building_type).capitalize(), assignment.position.x, assignment.position.y]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var count_label := Label.new()
	count_label.text = "%d/%d" % [assignment.workers, assignment.capacity]
	count_label.add_theme_color_override("font_color", ThemeColors.ACCENT)
	row.add_child(count_label)

	var minus_btn := Button.new()
	minus_btn.text = "-"
	minus_btn.custom_minimum_size = Vector2(28, 28)
	minus_btn.disabled = assignment.workers <= 0
	minus_btn.pressed.connect(func(): _on_unassign_worker(assignment.index))
	row.add_child(minus_btn)

	var plus_btn := Button.new()
	plus_btn.text = "+"
	plus_btn.custom_minimum_size = Vector2(28, 28)
	plus_btn.disabled = assignment.workers >= assignment.capacity or SimWorkers.available_workers(_state) <= 0
	plus_btn.pressed.connect(func(): _on_assign_worker(assignment.index))
	row.add_child(plus_btn)

	return row

func _on_assign_worker(building_index: int) -> void:
	if SimWorkers.assign_worker(_state, building_index):
		worker_assigned.emit(building_index)
		_refresh_all()

func _on_unassign_worker(building_index: int) -> void:
	if SimWorkers.unassign_worker(_state, building_index):
		worker_unassigned.emit(building_index)
		_refresh_all()

func _refresh_buildings() -> void:
	_clear_children(_buildings_section)
	if _state == null:
		return

	var header := _create_section_header("Buildings")
	_buildings_section.add_child(header)

	# Group buildings by type
	var by_type: Dictionary = {}
	for key in _state.structures.keys():
		var building_type: String = str(_state.structures[key])
		if not by_type.has(building_type):
			by_type[building_type] = []
		by_type[building_type].append(int(key))

	for building_type in by_type.keys():
		var indices: Array = by_type[building_type]
		for idx in indices:
			var row := _create_building_row(building_type, idx)
			_buildings_section.add_child(row)

func _create_building_row(building_type: String, index: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var level: int = SimBuildings.structure_level(_state, index)
	var pos: Vector2i = SimMap.pos_from_index(index, _state.map_w)

	var name_label := Label.new()
	name_label.text = "%s Lv%d (%d,%d)" % [building_type.capitalize(), level, pos.x, pos.y]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var preview: Dictionary = SimBuildings.get_building_upgrade_preview(_state, index)
	if preview.can_upgrade:
		var cost_text: String = _format_cost(preview.cost)
		var upgrade_btn := Button.new()
		upgrade_btn.text = "Upgrade (%s)" % cost_text
		upgrade_btn.pressed.connect(func(): _on_upgrade_building(index))
		row.add_child(upgrade_btn)
	elif preview.current_level >= SimBuildings.max_level(building_type):
		var max_label := Label.new()
		max_label.text = "MAX"
		max_label.add_theme_color_override("font_color", ThemeColors.ACCENT)
		row.add_child(max_label)

	return row

func _on_upgrade_building(index: int) -> void:
	if SimBuildings.apply_upgrade(_state, index):
		upgrade_requested.emit(index)
		_refresh_all()

func _refresh_research() -> void:
	_clear_children(_research_section)
	if _state == null or _research_instance == null:
		return

	var summary: Dictionary = _research_instance.get_research_summary(_state)

	# Header
	var header := _create_section_header("Research (%d/%d completed)" % [summary.completed_count, summary.total_count])
	_research_section.add_child(header)

	# Current research
	if not summary.active_research.is_empty():
		var active_box := _create_info_box()
		_research_section.add_child(active_box)

		var active_label := Label.new()
		active_label.text = "Researching: %s" % summary.active_label
		active_label.add_theme_color_override("font_color", ThemeColors.ACCENT)
		active_box.add_child(active_label)

		var progress_bar := ProgressBar.new()
		progress_bar.value = summary.progress_percent * 100.0
		progress_bar.custom_minimum_size = Vector2(0, 20)
		active_box.add_child(progress_bar)

		var progress_label := Label.new()
		progress_label.text = "%d/%d waves" % [summary.progress, summary.waves_needed]
		progress_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		active_box.add_child(progress_label)

	# Available research
	var available: Array = _research_instance.get_available_research(_state)
	if available.size() > 0:
		var avail_header := Label.new()
		avail_header.text = "Available Research:"
		avail_header.add_theme_color_override("font_color", ThemeColors.TEXT)
		_research_section.add_child(avail_header)

		for item in available:
			var row := _create_research_row(item)
			_research_section.add_child(row)

func _create_research_row(item: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var name_label := Label.new()
	name_label.text = str(item.get("label", ""))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var cost: int = int(item.get("cost", {}).get("gold", 0))
	var cost_label := Label.new()
	cost_label.text = "%dg" % cost
	cost_label.add_theme_color_override("font_color", ThemeColors.ACCENT)
	row.add_child(cost_label)

	var can_afford: bool = _state.gold >= cost
	var research_btn := Button.new()
	research_btn.text = "Start"
	research_btn.disabled = not can_afford or not _state.active_research.is_empty()
	research_btn.pressed.connect(func(): _on_start_research(str(item.get("id", ""))))
	row.add_child(research_btn)

	return row

func _on_start_research(research_id: String) -> void:
	if _research_instance.start_research(_state, research_id):
		research_started.emit(research_id)
		_refresh_all()

func _refresh_trade() -> void:
	_clear_children(_trade_section)
	if _state == null:
		return

	var summary: Dictionary = SimTrade.get_trade_summary(_state)

	var header := _create_section_header("Trade")
	_trade_section.add_child(header)

	if not summary.enabled:
		var disabled_label := Label.new()
		disabled_label.text = "Requires Level 3 Market to trade"
		disabled_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		_trade_section.add_child(disabled_label)
		return

	# Current rates
	var rates_label := Label.new()
	rates_label.text = "Today's Exchange Rates:"
	_trade_section.add_child(rates_label)

	var rates_box := _create_info_box()
	_trade_section.add_child(rates_box)

	var rates: Dictionary = summary.rates
	_add_rate_row(rates_box, "Wood -> Stone", rates.get("wood_to_stone", 0))
	_add_rate_row(rates_box, "Stone -> Wood", rates.get("stone_to_wood", 0))
	_add_rate_row(rates_box, "Wood -> Gold", rates.get("wood_to_gold", 0))
	_add_rate_row(rates_box, "Food -> Gold", rates.get("food_to_gold", 0))

	# Suggested trades
	var suggestions: Array = SimTrade.get_suggested_trades(_state)
	if suggestions.size() > 0:
		var suggest_label := Label.new()
		suggest_label.text = "Suggested Trades:"
		suggest_label.add_theme_color_override("font_color", ThemeColors.TEXT)
		_trade_section.add_child(suggest_label)

		for suggestion in suggestions:
			var row := _create_trade_row(suggestion)
			_trade_section.add_child(row)

func _create_trade_row(suggestion: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var desc_label := Label.new()
	desc_label.text = "%d %s -> %d %s" % [suggestion.amount, suggestion.from, suggestion.receive, suggestion.to]
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(desc_label)

	var trade_btn := Button.new()
	trade_btn.text = "Trade"
	trade_btn.pressed.connect(func(): _on_execute_trade(suggestion.from, suggestion.to, suggestion.amount))
	row.add_child(trade_btn)

	return row

func _on_execute_trade(from: String, to: String, amount: int) -> void:
	var result: Dictionary = SimTrade.execute_trade(_state, from, to, amount)
	if result.ok:
		trade_executed.emit(from, to, amount)
		_refresh_all()

# Helper functions

func _clear_children(container: Control) -> void:
	for child in container.get_children():
		child.queue_free()

func _create_section_header(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", ThemeColors.ACCENT)
	return label

func _create_info_box() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	return box

func _add_resource_row(container: VBoxContainer, name: String, current: int, income: int, upkeep: int = 0) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	container.add_child(row)

	var name_label := Label.new()
	name_label.text = name + ":"
	name_label.custom_minimum_size = Vector2(60, 0)
	row.add_child(name_label)

	var value_label := Label.new()
	value_label.text = str(current)
	value_label.add_theme_color_override("font_color", ThemeColors.TEXT)
	value_label.custom_minimum_size = Vector2(50, 0)
	row.add_child(value_label)

	var income_text: String
	if upkeep > 0:
		income_text = "(+%d -%d = %+d/day)" % [income + upkeep, upkeep, income]
	else:
		income_text = "(%+d/day)" % income

	var income_label := Label.new()
	income_label.text = income_text
	if income > 0:
		income_label.add_theme_color_override("font_color", ThemeColors.SUCCESS)
	elif income < 0:
		income_label.add_theme_color_override("font_color", ThemeColors.ERROR)
	else:
		income_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	row.add_child(income_label)

func _add_rate_row(container: VBoxContainer, label_text: String, rate: float) -> void:
	var row := HBoxContainer.new()
	container.add_child(row)

	var label := Label.new()
	label.text = "%s: %.2f" % [label_text, rate]
	label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	row.add_child(label)

func _format_cost(cost: Dictionary) -> String:
	var parts: Array = []
	for key in cost.keys():
		parts.append("%d%s" % [int(cost[key]), key[0]])
	return ", ".join(parts)
