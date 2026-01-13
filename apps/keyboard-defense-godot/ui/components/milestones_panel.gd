class_name MilestonesPanel
extends PanelContainer
## Milestones Panel - Shows all milestone categories and progress toward next milestones.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

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
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_MD, 520)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "MILESTONES"
	DesignSystem.style_label(title, "h2", ThemeColors.RESOURCE_GOLD)
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
	subtitle.text = "Track your typing achievements and personal records"
	DesignSystem.style_label(subtitle, "caption", ThemeColors.TEXT_DIM)
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
	footer.text = "Personal bests are highlighted in gold"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


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
	section_style.set_corner_radius_all(DesignSystem.RADIUS_MD)
	section_style.set_content_margin_all(DesignSystem.SPACE_MD)
	section.add_theme_stylebox_override("panel", section_style)

	_content_vbox.add_child(section)

	var vbox := DesignSystem.create_vbox(DesignSystem.SPACE_SM)
	section.add_child(vbox)

	# Header row
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	vbox.add_child(header)

	var title_label := Label.new()
	title_label.text = title
	DesignSystem.style_label(title_label, "body_small", color)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)

	var value_label := Label.new()
	value_label.text = current_text
	DesignSystem.style_label(value_label, "body", ThemeColors.TEXT)
	header.add_child(value_label)

	# Progress bar and next milestone
	var next_milestone = next_info.get("next", -1)
	var progress: float = float(next_info.get("progress", 1.0))

	if next_milestone > 0:
		# Progress bar
		var bar_container := DesignSystem.create_hbox(DesignSystem.SPACE_SM)
		vbox.add_child(bar_container)

		var progress_bg := PanelContainer.new()
		progress_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		progress_bg.custom_minimum_size = Vector2(0, 16)
		bar_container.add_child(progress_bg)

		var bg_style := StyleBoxFlat.new()
		bg_style.bg_color = ThemeColors.BG_INPUT
		bg_style.set_corner_radius_all(DesignSystem.RADIUS_SM)
		progress_bg.add_theme_stylebox_override("panel", bg_style)

		# Note: We use a ColorRect for actual fill since Control can't draw by default
		var fill_rect := ColorRect.new()
		fill_rect.color = color.darkened(0.3)
		fill_rect.custom_minimum_size = Vector2(int(200 * min(1.0, progress)), 12)
		fill_rect.position = Vector2(2, 2)
		progress_bg.add_child(fill_rect)

		var next_label := Label.new()
		next_label.text = "Next: %s" % _format_milestone_value(category, next_milestone)
		DesignSystem.style_label(next_label, "caption", ThemeColors.TEXT_DIM)
		bar_container.add_child(next_label)
	else:
		var complete_label := Label.new()
		complete_label.text = "All milestones achieved!"
		DesignSystem.style_label(complete_label, "caption", ThemeColors.RESOURCE_GOLD)
		vbox.add_child(complete_label)

	# Milestone chips row
	var chips_row := DesignSystem.create_hbox(DesignSystem.SPACE_XS)
	vbox.add_child(chips_row)

	for milestone in milestones:
		var is_achieved: bool = _is_milestone_achieved(current_value, milestone)
		var chip := _create_milestone_chip(category, milestone, is_achieved, color)
		chips_row.add_child(chip)


func _create_milestone_chip(category: SimMilestones.Category, milestone, is_achieved: bool, color: Color) -> Control:
	var label := Label.new()
	label.text = _format_milestone_value(category, milestone)

	if is_achieved:
		DesignSystem.style_label(label, "caption", color)
	else:
		DesignSystem.style_label(label, "caption", ThemeColors.TEXT_DISABLED)

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
