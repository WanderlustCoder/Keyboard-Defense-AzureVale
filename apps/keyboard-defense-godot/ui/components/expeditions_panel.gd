class_name ExpeditionsPanel
extends PanelContainer
## Expeditions Panel - Manage worker expeditions for resource gathering.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed
signal expedition_started(expedition_id: String, worker_count: int)
signal expedition_cancelled(expedition_id: int)

const SimExpeditions = preload("res://sim/expeditions.gd")

var _state: Variant = null  # GameState
var _available_workers: int = 0

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null
var _workers_label: Label = null

# State colors
const STATE_COLORS: Dictionary = {
	"traveling": Color(0.4, 0.7, 1.0),
	"gathering": Color(0.4, 0.9, 0.4),
	"returning": Color(1.0, 0.8, 0.4),
	"complete": Color(0.4, 0.9, 0.4),
	"failed": Color(0.9, 0.4, 0.4)
}


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 520)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "EXPEDITIONS"
	DesignSystem.style_label(title, "h2", Color(0.4, 0.7, 1.0))
	header.add_child(title)

	header.add_child(DesignSystem.create_spacer())

	_workers_label = Label.new()
	DesignSystem.style_label(_workers_label, "body", ThemeColors.TEXT_DIM)
	header.add_child(_workers_label)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(15, 0)
	header.add_child(spacer2)

	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.custom_minimum_size = Vector2(DesignSystem.SIZE_BUTTON_SM, DesignSystem.SIZE_BUTTON_SM)
	_style_close_button()
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "Send workers on expeditions to gather resources"
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
	footer.text = "Workers on expedition are unavailable for other tasks"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_expeditions(state: Variant) -> void:
	_state = state
	_available_workers = SimExpeditions.available_workers_for_expedition(state)
	_workers_label.text = "%d workers available" % _available_workers
	_build_content()
	show()


func refresh() -> void:
	if _state != null:
		_available_workers = SimExpeditions.available_workers_for_expedition(_state)
		_workers_label.text = "%d workers available" % _available_workers
		_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	if _state == null:
		return

	# Active expeditions section
	var active: Array = _state.active_expeditions
	if not active.is_empty():
		_build_active_section(active)

	# Available expeditions section
	var available: Array = SimExpeditions.get_available_expeditions(_state)
	if not available.is_empty():
		_build_available_section(available)
	elif active.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No expeditions available yet. Build more structures to unlock!"
		empty_label.add_theme_font_size_override("font_size", 12)
		empty_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_content_vbox.add_child(empty_label)

	# History section
	var history: Array = _state.expedition_history
	if not history.is_empty():
		_build_history_section(history)


func _build_active_section(active: Array) -> void:
	var section := _create_section_panel("ACTIVE EXPEDITIONS", Color(0.4, 0.9, 0.4))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for exp in active:
		var card := _create_active_expedition_card(exp)
		vbox.add_child(card)


func _build_available_section(available: Array) -> void:
	var section := _create_section_panel("AVAILABLE EXPEDITIONS", Color(0.4, 0.7, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for exp in available:
		var card := _create_available_expedition_card(exp)
		vbox.add_child(card)


func _build_history_section(history: Array) -> void:
	var section := _create_section_panel("RECENT HISTORY", Color(0.6, 0.6, 0.7))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Show most recent 5
	var to_show: Array = history.duplicate()
	to_show.reverse()
	if to_show.size() > 5:
		to_show.resize(5)

	for entry in to_show:
		var row := _create_history_row(entry)
		vbox.add_child(row)


func _create_active_expedition_card(exp: Dictionary) -> Control:
	var exp_id: int = int(exp.get("id", 0))
	var type_id: String = str(exp.get("expedition_type_id", ""))
	var definition: Dictionary = SimExpeditions.get_expedition_definition(type_id)
	var label: String = str(definition.get("label", type_id))
	var state_str: String = str(exp.get("state", ""))
	var progress: float = float(exp.get("progress", 0))
	var remaining: float = float(exp.get("duration_remaining", 0))
	var workers: int = int(exp.get("workers_assigned", 0))

	var state_color: Color = STATE_COLORS.get(state_str, Color.WHITE)

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = state_color.darkened(0.85)
	container_style.border_color = state_color.darkened(0.5)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	container.add_child(vbox)

	# Header row
	var header := HBoxContainer.new()
	vbox.add_child(header)

	var name_label := Label.new()
	name_label.text = label
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", state_color)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)

	var workers_chip := _create_chip("%d workers" % workers, Color(0.6, 0.6, 0.7))
	header.add_child(workers_chip)

	# State and time row
	var state_row := HBoxContainer.new()
	state_row.add_theme_constant_override("separation", 15)
	vbox.add_child(state_row)

	var state_label := Label.new()
	state_label.text = _get_state_label(state_str)
	state_label.add_theme_font_size_override("font_size", 12)
	state_label.add_theme_color_override("font_color", state_color)
	state_row.add_child(state_label)

	var time_label := Label.new()
	time_label.text = _format_duration(remaining)
	time_label.add_theme_font_size_override("font_size", 12)
	time_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	state_row.add_child(time_label)

	# Progress bar
	var progress_container := _create_progress_bar(progress, state_color)
	vbox.add_child(progress_container)

	# Cancel button
	var btn_row := HBoxContainer.new()
	vbox.add_child(btn_row)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(spacer)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(70, 24)
	cancel_btn.pressed.connect(_on_cancel_pressed.bind(exp_id))
	btn_row.add_child(cancel_btn)

	return container


func _create_available_expedition_card(exp: Dictionary) -> Control:
	var exp_id: String = str(exp.get("id", ""))
	var label: String = str(exp.get("label", exp_id))
	var desc: String = str(exp.get("description", ""))
	var min_workers: int = int(exp.get("min_workers", 1))
	var max_workers: int = int(exp.get("max_workers", 1))
	var duration: float = float(exp.get("duration_seconds", 180))
	var base_yield: Dictionary = exp.get("base_yield", {})
	var risk: float = float(exp.get("risk_chance", 0))
	var requires: Array = exp.get("requires", [])

	var can_start: bool = _available_workers >= min_workers

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	if can_start:
		container_style.bg_color = Color(0.08, 0.1, 0.06, 0.9)
		container_style.border_color = Color(0.4, 0.6, 0.3)
	else:
		container_style.bg_color = Color(0.06, 0.07, 0.1, 0.9)
		container_style.border_color = Color(0.3, 0.3, 0.35)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	container.add_child(vbox)

	# Header row
	var header := HBoxContainer.new()
	vbox.add_child(header)

	var name_label := Label.new()
	name_label.text = label
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0) if can_start else Color(0.5, 0.5, 0.55))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)

	var duration_chip := _create_chip(_format_duration(duration), Color(0.6, 0.6, 0.7))
	header.add_child(duration_chip)

	# Description
	if not desc.is_empty():
		var desc_label := Label.new()
		desc_label.text = desc
		desc_label.add_theme_font_size_override("font_size", 11)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(desc_label)

	# Info row: workers, yield, risk
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 15)
	vbox.add_child(info_row)

	var workers_text: String = "%d-%d workers" % [min_workers, max_workers] if min_workers != max_workers else "%d worker(s)" % min_workers
	var workers_chip := _create_chip(workers_text, Color(0.6, 0.6, 0.7))
	info_row.add_child(workers_chip)

	# Yields
	for resource in base_yield.keys():
		var amount: int = int(base_yield[resource])
		var yield_chip := _create_chip("+%d %s" % [amount, resource], Color(0.4, 0.9, 0.4))
		info_row.add_child(yield_chip)

	# Risk
	if risk > 0:
		var risk_percent: int = int(risk * 100)
		var risk_chip := _create_chip("%d%% risk" % risk_percent, Color(0.9, 0.6, 0.3))
		info_row.add_child(risk_chip)

	# Start button row with worker selector
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_row)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(spacer)

	if not can_start:
		var need_label := Label.new()
		need_label.text = "Need %d workers" % min_workers
		need_label.add_theme_font_size_override("font_size", 10)
		need_label.add_theme_color_override("font_color", Color(0.9, 0.5, 0.5))
		btn_row.add_child(need_label)

	# Worker count spinner (simplified - just buttons)
	var worker_count: int = clampi(min_workers, min_workers, mini(max_workers, _available_workers))

	if can_start and min_workers != max_workers:
		var minus_btn := Button.new()
		minus_btn.text = "-"
		minus_btn.custom_minimum_size = Vector2(24, 24)
		btn_row.add_child(minus_btn)

		var count_label := Label.new()
		count_label.text = str(worker_count)
		count_label.add_theme_font_size_override("font_size", 12)
		count_label.add_theme_color_override("font_color", Color.WHITE)
		count_label.custom_minimum_size = Vector2(20, 0)
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn_row.add_child(count_label)

		var plus_btn := Button.new()
		plus_btn.text = "+"
		plus_btn.custom_minimum_size = Vector2(24, 24)
		btn_row.add_child(plus_btn)

		# Connect spinner buttons
		minus_btn.pressed.connect(func():
			var new_count: int = maxi(min_workers, int(count_label.text) - 1)
			count_label.text = str(new_count)
		)
		plus_btn.pressed.connect(func():
			var new_count: int = mini(mini(max_workers, _available_workers), int(count_label.text) + 1)
			count_label.text = str(new_count)
		)

		var start_btn := Button.new()
		start_btn.text = "Start"
		start_btn.custom_minimum_size = Vector2(60, 26)
		start_btn.pressed.connect(func():
			expedition_started.emit(exp_id, int(count_label.text))
		)
		btn_row.add_child(start_btn)
	elif can_start:
		var start_btn := Button.new()
		start_btn.text = "Start (%d)" % worker_count
		start_btn.custom_minimum_size = Vector2(80, 26)
		start_btn.pressed.connect(func():
			expedition_started.emit(exp_id, worker_count)
		)
		btn_row.add_child(start_btn)

	return container


func _create_history_row(entry: Dictionary) -> Control:
	var type_id: String = str(entry.get("expedition_type_id", ""))
	var definition: Dictionary = SimExpeditions.get_expedition_definition(type_id)
	var label: String = str(definition.get("label", type_id))
	var day: int = int(entry.get("day_completed", 0))
	var workers: int = int(entry.get("workers", 0))
	var yields: Dictionary = entry.get("yields", {})
	var had_risk: bool = bool(entry.get("had_risk", false))

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	var name_label := Label.new()
	name_label.text = label
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	name_label.custom_minimum_size = Vector2(120, 0)
	hbox.add_child(name_label)

	var day_label := Label.new()
	day_label.text = "Day %d" % day
	day_label.add_theme_font_size_override("font_size", 10)
	day_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	day_label.custom_minimum_size = Vector2(50, 0)
	hbox.add_child(day_label)

	# Yields
	var yield_parts: Array[String] = []
	for resource in yields.keys():
		if int(yields[resource]) > 0:
			yield_parts.append("+%d %s" % [int(yields[resource]), resource])

	var yield_label := Label.new()
	yield_label.text = ", ".join(yield_parts) if not yield_parts.is_empty() else "No yield"
	yield_label.add_theme_font_size_override("font_size", 10)
	yield_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4) if not yield_parts.is_empty() else Color(0.5, 0.5, 0.55))
	yield_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(yield_label)

	if had_risk:
		var risk_label := Label.new()
		risk_label.text = "RISK"
		risk_label.add_theme_font_size_override("font_size", 9)
		risk_label.add_theme_color_override("font_color", Color(0.9, 0.5, 0.3))
		hbox.add_child(risk_label)

	return hbox


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


func _create_chip(text: String, color: Color) -> Control:
	var chip := PanelContainer.new()

	var chip_style := StyleBoxFlat.new()
	chip_style.bg_color = color.darkened(0.7)
	chip_style.set_corner_radius_all(3)
	chip_style.set_content_margin_all(4)
	chip.add_theme_stylebox_override("panel", chip_style)

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", color)
	chip.add_child(label)

	return chip


func _create_progress_bar(progress: float, color: Color) -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(0, 8)

	var bg := ColorRect.new()
	bg.color = Color(0.15, 0.15, 0.18)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(bg)

	var fill := ColorRect.new()
	fill.color = color
	fill.anchor_right = clampf(progress, 0.0, 1.0)
	fill.anchor_bottom = 1.0
	container.add_child(fill)

	return container


func _get_state_label(state_str: String) -> String:
	match state_str:
		"traveling":
			return "Traveling..."
		"gathering":
			return "Gathering resources"
		"returning":
			return "Returning home"
		"complete":
			return "Complete!"
		"failed":
			return "Failed"
		_:
			return "Unknown"


func _format_duration(seconds: float) -> String:
	var mins := int(seconds) / 60
	var secs := int(seconds) % 60
	if mins > 0:
		return "%dm %ds" % [mins, secs]
	return "%ds" % secs


func _on_cancel_pressed(expedition_id: int) -> void:
	expedition_cancelled.emit(expedition_id)


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
