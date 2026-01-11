class_name TypingMetricsPanel
extends PanelContainer
## Typing Metrics Panel - Explains WPM calculation and combo system

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Metric definitions (from SimTypingMetrics)
const WPM_FORMULA: Dictionary = {
	"description": "WPM = (Characters / 5) / Minutes",
	"chars_per_word": 5,
	"window_seconds": 10,
	"note": "Uses 10-second rolling window for real-time calculation"
}

const COMBO_THRESHOLDS: Array[Dictionary] = [
	{"combo": 3, "multiplier": 1.1, "label": "+10%"},
	{"combo": 5, "multiplier": 1.25, "label": "+25%"},
	{"combo": 10, "multiplier": 1.5, "label": "+50%"},
	{"combo": 20, "multiplier": 2.0, "label": "x2"},
	{"combo": 50, "multiplier": 2.5, "label": "x2.5"}
]

const ACCURACY_INFO: Dictionary = {
	"formula": "Accuracy = Correct / (Correct + Errors)",
	"description": "Tracks total correct characters vs errors per battle",
	"perfect_streak": "Perfect words (no errors) build a streak for bonus damage"
}

const METRICS_TRACKED: Array[Dictionary] = [
	{
		"name": "Rolling WPM",
		"description": "Words per minute calculated from last 10 seconds",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"name": "Accuracy",
		"description": "Percentage of correctly typed characters",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"name": "Combo Count",
		"description": "Consecutive correct characters (resets on error)",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"name": "Perfect Streak",
		"description": "Consecutive words completed without errors",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"name": "Unique Letters",
		"description": "Different letters typed in last 10 seconds",
		"color": Color(0.7, 0.5, 0.9)
	},
	{
		"name": "Max Combo",
		"description": "Highest combo achieved this battle",
		"color": Color(0.9, 0.4, 0.4)
	}
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(500, 580)

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
	title.text = "TYPING METRICS"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
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
	subtitle.text = "How typing performance is measured and rewarded"
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
	footer.text = "Improve your typing to increase tower damage"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_typing_metrics() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# WPM section
	_build_wpm_section()

	# Combo section
	_build_combo_section()

	# Tracked metrics section
	_build_metrics_section()


func _build_wpm_section() -> void:
	var section := _create_section_panel("WPM CALCULATION", Color(0.4, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Formula
	var formula_label := Label.new()
	formula_label.text = WPM_FORMULA.description
	formula_label.add_theme_font_size_override("font_size", 12)
	formula_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	vbox.add_child(formula_label)

	# Details
	var details_grid := GridContainer.new()
	details_grid.columns = 2
	details_grid.add_theme_constant_override("h_separation", 20)
	details_grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(details_grid)

	_add_detail_row(details_grid, "Chars per Word:", str(WPM_FORMULA.chars_per_word))
	_add_detail_row(details_grid, "Window:", "%d seconds" % WPM_FORMULA.window_seconds)

	# Note
	var note_label := Label.new()
	note_label.text = WPM_FORMULA.note
	note_label.add_theme_font_size_override("font_size", 10)
	note_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(note_label)

	# Accuracy info
	var acc_header := Label.new()
	acc_header.text = "Accuracy"
	acc_header.add_theme_font_size_override("font_size", 11)
	acc_header.add_theme_color_override("font_color", Color(0.5, 0.8, 0.3))
	vbox.add_child(acc_header)

	var acc_formula := Label.new()
	acc_formula.text = ACCURACY_INFO.formula
	acc_formula.add_theme_font_size_override("font_size", 10)
	acc_formula.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(acc_formula)


func _add_detail_row(grid: GridContainer, label: String, value: String) -> void:
	var label_node := Label.new()
	label_node.text = label
	label_node.add_theme_font_size_override("font_size", 10)
	label_node.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	grid.add_child(label_node)

	var value_node := Label.new()
	value_node.text = value
	value_node.add_theme_font_size_override("font_size", 10)
	value_node.add_theme_color_override("font_color", Color.WHITE)
	grid.add_child(value_node)


func _build_combo_section() -> void:
	var section := _create_section_panel("COMBO MULTIPLIERS", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var desc := Label.new()
	desc.text = "Consecutive correct characters increase tower damage:"
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(desc)

	# Combo threshold grid
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 15)
	grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(grid)

	# First row: combo thresholds
	for threshold in COMBO_THRESHOLDS:
		var combo_label := Label.new()
		combo_label.text = "%d+" % threshold.combo
		combo_label.add_theme_font_size_override("font_size", 11)
		combo_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3))
		combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(combo_label)

	# Second row: multipliers
	for threshold in COMBO_THRESHOLDS:
		var mult_label := Label.new()
		mult_label.text = threshold.label
		mult_label.add_theme_font_size_override("font_size", 10)
		mult_label.add_theme_color_override("font_color", Color.WHITE)
		mult_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(mult_label)

	# Reset warning
	var reset_label := Label.new()
	reset_label.text = "Combo resets to 0 on any typing error"
	reset_label.add_theme_font_size_override("font_size", 10)
	reset_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
	vbox.add_child(reset_label)


func _build_metrics_section() -> void:
	var section := _create_section_panel("TRACKED METRICS", Color(0.7, 0.5, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for metric in METRICS_TRACKED:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var name_str: String = str(metric.get("name", ""))
		var description: String = str(metric.get("description", ""))
		var color: Color = metric.get("color", Color.WHITE)

		var name_label := Label.new()
		name_label.text = name_str
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", color)
		name_label.custom_minimum_size = Vector2(100, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = description
		desc_label.add_theme_font_size_override("font_size", 10)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(desc_label)


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
	vbox.add_theme_constant_override("separation", 8)
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
