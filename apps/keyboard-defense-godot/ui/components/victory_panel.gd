extends PanelContainer
class_name VictoryPanel
## Victory conditions panel showing progress toward all victory paths.
## Migrated to use ThemeColors autoload.

signal closed
signal victory_selected(victory_type: String)

const SimVictory = preload("res://sim/victory.gd")

var _state_ref = null

@onready var title_label: Label = $VBox/Header/TitleLabel
@onready var close_button: Button = $VBox/Header/CloseButton
@onready var conditions_list: VBoxContainer = $VBox/Content/ConditionsList
@onready var summary_label: Label = $VBox/Footer/SummaryLabel

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	_setup_styling()

func _setup_styling() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = ThemeColors.PANEL_BG
	panel_style.border_color = ThemeColors.BORDER_DEFAULT
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(4)
	panel_style.set_content_margin_all(12)
	add_theme_stylebox_override("panel", panel_style)

func update_display(state) -> void:
	_state_ref = state
	_refresh_conditions_list()
	_refresh_summary()

func _refresh_conditions_list() -> void:
	# Clear existing entries
	for child in conditions_list.get_children():
		child.queue_free()

	if _state_ref == null:
		return

	var summary := SimVictory.get_victory_summary(_state_ref)
	var progress: Dictionary = summary.get("progress", {})
	var achieved: Array = summary.get("achieved", [])

	for victory_type in SimVictory.get_victory_types():
		var info := SimVictory.get_victory_info(victory_type)
		var prog: Dictionary = progress.get(victory_type, {})
		var is_achieved := achieved.has(victory_type)

		var entry := _create_condition_entry(victory_type, info, prog, is_achieved)
		conditions_list.add_child(entry)

func _create_condition_entry(victory_type: String, info: Dictionary, progress: Dictionary, achieved: bool) -> Control:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)

	# Header row with name and status
	var header := HBoxContainer.new()

	# Victory icon/indicator
	var indicator := ColorRect.new()
	indicator.custom_minimum_size = Vector2(8, 8)
	var color_str: String = str(info.get("color", "#888888"))
	indicator.color = Color.from_string(color_str, Color.GRAY)
	if achieved:
		indicator.color = Color(0.3, 0.9, 0.4)  # Green for achieved
	header.add_child(indicator)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size.x = 8
	header.add_child(spacer)

	# Victory name
	var name_label := Label.new()
	name_label.text = str(info.get("name", victory_type.capitalize()))
	name_label.add_theme_font_size_override("font_size", 14)
	if achieved:
		name_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
	else:
		name_label.add_theme_color_override("font_color", ThemeColors.TEXT_PRIMARY)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)

	# Achievement badge
	if achieved:
		var badge := Label.new()
		badge.text = "ACHIEVED"
		badge.add_theme_font_size_override("font_size", 10)
		badge.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
		header.add_child(badge)

	container.add_child(header)

	# Description
	var desc := Label.new()
	desc.text = str(info.get("description", ""))
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", ThemeColors.TEXT_SECONDARY)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(desc)

	# Progress bar
	if not achieved:
		var progress_container := HBoxContainer.new()

		var progress_bar := ProgressBar.new()
		progress_bar.custom_minimum_size = Vector2(200, 16)
		progress_bar.max_value = 100.0
		progress_bar.value = float(progress.get("percent", 0.0))
		progress_bar.show_percentage = false
		progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Style the progress bar
		var bar_bg := StyleBoxFlat.new()
		bar_bg.bg_color = Color(0.15, 0.15, 0.2)
		bar_bg.set_corner_radius_all(2)
		progress_bar.add_theme_stylebox_override("background", bar_bg)

		var bar_fill := StyleBoxFlat.new()
		bar_fill.bg_color = Color.from_string(str(info.get("color", "#4CAF50")), Color.GREEN)
		bar_fill.set_corner_radius_all(2)
		progress_bar.add_theme_stylebox_override("fill", bar_fill)

		progress_container.add_child(progress_bar)

		# Progress text
		var progress_text := Label.new()
		var current: int = int(progress.get("current", 0))
		var target: int = int(progress.get("target", 1))
		progress_text.text = " %d / %d" % [current, target]
		progress_text.add_theme_font_size_override("font_size", 11)
		progress_text.add_theme_color_override("font_color", ThemeColors.TEXT_SECONDARY)
		progress_text.custom_minimum_size.x = 60
		progress_container.add_child(progress_text)

		container.add_child(progress_container)

	# Separator
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 8)
	container.add_child(sep)

	return container

func _refresh_summary() -> void:
	if _state_ref == null:
		summary_label.text = ""
		return

	var summary := SimVictory.get_victory_summary(_state_ref)
	var achieved_count: int = int(summary.get("achieved_count", 0))
	var total: int = int(summary.get("total_conditions", 5))

	if achieved_count > 0:
		summary_label.text = "Victory achieved! %d of %d conditions complete." % [achieved_count, total]
		summary_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
	else:
		var closest_type: String = str(summary.get("closest_type", ""))
		var closest_percent: float = float(summary.get("closest_percent", 0.0))
		if not closest_type.is_empty():
			var info := SimVictory.get_victory_info(closest_type)
			summary_label.text = "Closest victory: %s (%.0f%%)" % [info.get("name", closest_type), closest_percent]
		else:
			summary_label.text = "Work toward a victory condition to win!"
		summary_label.add_theme_color_override("font_color", ThemeColors.TEXT_SECONDARY)

func _on_close_pressed() -> void:
	closed.emit()
	hide()
