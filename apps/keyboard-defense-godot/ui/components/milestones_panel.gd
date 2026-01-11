class_name MilestonesPanel
extends PanelContainer
## Milestones Panel - Shows all milestone categories and progress toward next milestones

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")
const SimMilestones = preload("res://sim/milestones.gd")

var _profile: Dictionary = {}

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(480, 520)

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
	title.text = "MILESTONES"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
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
	subtitle.text = "Track your typing achievements and personal records"
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
	footer.text = "Personal bests are highlighted in gold"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_milestones(profile: Dictionary = {}) -> void:
	_profile = profile
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Get player stats from profile
	var best_wpm: int = int(_profile.get("best_wpm", 0))
	var best_accuracy: float = float(_profile.get("best_accuracy", 0.0))
	var best_combo: int = int(_profile.get("best_combo", 0))
	var lifetime_stats: Dictionary = _profile.get("lifetime_stats", {})
	var total_kills: int = int(lifetime_stats.get("total_kills", 0))
	var total_words: int = int(lifetime_stats.get("words_typed", 0))
	var current_streak: int = int(_profile.get("daily_streak", 0))

	# WPM milestones
	_build_category_section(
		SimMilestones.Category.WPM,
		"TYPING SPEED",
		"%d WPM" % best_wpm,
		best_wpm,
		SimMilestones.WPM_MILESTONES
	)

	# Accuracy milestones
	_build_category_section(
		SimMilestones.Category.ACCURACY,
		"ACCURACY",
		"%.1f%%" % (best_accuracy * 100.0),
		best_accuracy * 100.0,
		SimMilestones.ACCURACY_MILESTONES
	)

	# Combo milestones
	_build_category_section(
		SimMilestones.Category.COMBO,
		"BEST COMBO",
		"x%d" % best_combo,
		best_combo,
		SimMilestones.COMBO_MILESTONES
	)

	# Kill milestones
	_build_category_section(
		SimMilestones.Category.KILLS,
		"ENEMIES SLAIN",
		_format_number(total_kills),
		total_kills,
		SimMilestones.KILL_MILESTONES
	)

	# Word milestones
	_build_category_section(
		SimMilestones.Category.WORDS,
		"WORDS TYPED",
		_format_number(total_words),
		total_words,
		SimMilestones.WORD_MILESTONES
	)

	# Streak milestones
	_build_category_section(
		SimMilestones.Category.STREAK,
		"DAILY STREAK",
		"%d days" % current_streak,
		current_streak,
		SimMilestones.STREAK_MILESTONES
	)


func _build_category_section(category: SimMilestones.Category, title: String, current_text: String, current_value, milestones: Array) -> void:
	var color: Color = SimMilestones.get_category_color(category)
	var next_info: Dictionary = SimMilestones.get_next_milestone(category, current_value)

	var section := PanelContainer.new()

	var section_style := StyleBoxFlat.new()
	section_style.bg_color = color.darkened(0.85)
	section_style.border_color = color.darkened(0.5)
	section_style.set_border_width_all(1)
	section_style.set_corner_radius_all(6)
	section_style.set_content_margin_all(10)
	section.add_theme_stylebox_override("panel", section_style)

	_content_vbox.add_child(section)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	section.add_child(vbox)

	# Header row
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	vbox.add_child(header)

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 13)
	title_label.add_theme_color_override("font_color", color)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)

	var value_label := Label.new()
	value_label.text = current_text
	value_label.add_theme_font_size_override("font_size", 16)
	value_label.add_theme_color_override("font_color", Color.WHITE)
	header.add_child(value_label)

	# Progress bar and next milestone
	var next_milestone = next_info.get("next", -1)
	var progress: float = float(next_info.get("progress", 1.0))

	if next_milestone > 0:
		# Progress bar
		var bar_container := HBoxContainer.new()
		bar_container.add_theme_constant_override("separation", 8)
		vbox.add_child(bar_container)

		var progress_bg := PanelContainer.new()
		progress_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		progress_bg.custom_minimum_size = Vector2(0, 16)
		bar_container.add_child(progress_bg)

		var bg_style := StyleBoxFlat.new()
		bg_style.bg_color = Color(0.1, 0.1, 0.12)
		bg_style.set_corner_radius_all(3)
		progress_bg.add_theme_stylebox_override("panel", bg_style)

		var progress_fill := Control.new()
		progress_fill.custom_minimum_size = Vector2(int(200 * progress), 12)
		progress_fill.position = Vector2(2, 2)
		progress_bg.add_child(progress_fill)

		var fill_style := StyleBoxFlat.new()
		fill_style.bg_color = color.darkened(0.3)
		fill_style.set_corner_radius_all(2)
		progress_fill.add_theme_stylebox_override("panel", fill_style)

		# Note: We use a ColorRect for actual fill since Control can't draw by default
		var fill_rect := ColorRect.new()
		fill_rect.color = color.darkened(0.3)
		fill_rect.custom_minimum_size = Vector2(int(200 * min(1.0, progress)), 12)
		fill_rect.position = Vector2(2, 2)
		progress_bg.add_child(fill_rect)

		var next_label := Label.new()
		next_label.text = "Next: %s" % _format_milestone_value(category, next_milestone)
		next_label.add_theme_font_size_override("font_size", 11)
		next_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		bar_container.add_child(next_label)
	else:
		var complete_label := Label.new()
		complete_label.text = "All milestones achieved!"
		complete_label.add_theme_font_size_override("font_size", 11)
		complete_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		vbox.add_child(complete_label)

	# Milestone chips row
	var chips_row := HBoxContainer.new()
	chips_row.add_theme_constant_override("separation", 4)
	vbox.add_child(chips_row)

	for milestone in milestones:
		var is_achieved: bool = _is_milestone_achieved(current_value, milestone)
		var chip := _create_milestone_chip(category, milestone, is_achieved, color)
		chips_row.add_child(chip)


func _create_milestone_chip(category: SimMilestones.Category, milestone, is_achieved: bool, color: Color) -> Control:
	var label := Label.new()
	label.text = _format_milestone_value(category, milestone)
	label.add_theme_font_size_override("font_size", 9)

	if is_achieved:
		label.add_theme_color_override("font_color", color)
	else:
		label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))

	return label


func _format_milestone_value(category: SimMilestones.Category, value) -> String:
	match category:
		SimMilestones.Category.WPM:
			return "%d" % value
		SimMilestones.Category.ACCURACY:
			return "%.0f%%" % value
		SimMilestones.Category.COMBO:
			return "x%d" % value
		SimMilestones.Category.KILLS:
			return _format_number(int(value))
		SimMilestones.Category.WORDS:
			return _format_number(int(value))
		SimMilestones.Category.STREAK:
			return "%dd" % value
		_:
			return str(value)


func _is_milestone_achieved(current_value, milestone) -> bool:
	return float(current_value) >= float(milestone)


func _format_number(num: int) -> String:
	if num >= 10000:
		return "%.1fK" % (num / 1000.0)
	elif num >= 1000:
		return "%.1fK" % (num / 1000.0)
	return str(num)


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
