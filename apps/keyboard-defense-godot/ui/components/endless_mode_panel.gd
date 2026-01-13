class_name EndlessModePanel
extends PanelContainer
## Endless Mode Panel - Shows endless mode info, high scores, milestones.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed
signal start_endless_mode

const SimEndlessMode = preload("res://sim/endless_mode.gd")

var _is_unlocked: bool = false
var _high_scores: Dictionary = {}
var _current_day: int = 0  # For unlock progress display
var _in_run: bool = false
var _run_day: int = 0
var _run_wave: int = 0
var _run_combo: int = 0
var _run_kills: int = 0

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null
var _start_btn: Button = null

# Colors
const MILESTONE_COLORS: Dictionary = {
	5: Color(0.6, 0.8, 0.6),      # Survivor - Light green
	10: Color(0.5, 0.7, 0.9),     # Enduring - Light blue
	15: Color(0.7, 0.6, 0.9),     # Persistent - Purple
	20: Color(1.0, 0.84, 0.0),    # Indomitable - Gold
	25: Color(1.0, 0.6, 0.3),     # Unstoppable - Orange
	30: Color(1.0, 0.4, 0.4),     # Legendary - Red
	40: Color(0.9, 0.3, 0.6),     # Mythic - Magenta
	50: Color(0.4, 1.0, 1.0),     # Godlike - Cyan
	75: Color(1.0, 1.0, 0.6),     # Transcendent - Light yellow
	100: Color(1.0, 1.0, 1.0)     # Eternal - White
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
	title.text = "ENDLESS MODE"
	DesignSystem.style_label(title, "h2", Color(1.0, 0.5, 0.3))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.custom_minimum_size = Vector2(DesignSystem.SIZE_BUTTON_SM, DesignSystem.SIZE_BUTTON_SM)
	_style_close_button()
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "Infinite scaling challenge - How far can you go?"
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

	# Start button (at bottom)
	_start_btn = Button.new()
	_start_btn.text = "START ENDLESS RUN"
	_start_btn.custom_minimum_size = Vector2(0, 40)
	_start_btn.pressed.connect(_on_start_pressed)
	main_vbox.add_child(_start_btn)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_endless_mode(is_unlocked: bool, high_scores: Dictionary, current_day: int) -> void:
	_is_unlocked = is_unlocked
	_high_scores = high_scores
	_current_day = current_day
	_in_run = false
	_build_content()
	_update_start_button()
	show()


func show_current_run(day: int, wave: int, combo: int, kills: int) -> void:
	_in_run = true
	_run_day = day
	_run_wave = wave
	_run_combo = combo
	_run_kills = kills
	_build_content()
	_update_start_button()
	show()


func _update_start_button() -> void:
	if _in_run:
		_start_btn.text = "CONTINUE RUN"
		_start_btn.disabled = false
	elif _is_unlocked:
		_start_btn.text = "START ENDLESS RUN"
		_start_btn.disabled = false
	else:
		_start_btn.text = "LOCKED - Reach Day %d" % SimEndlessMode.UNLOCK_DAY
		_start_btn.disabled = true


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	if not _is_unlocked:
		_build_locked_content()
	elif _in_run:
		_build_run_content()
	else:
		_build_unlocked_content()


func _build_locked_content() -> void:
	# Lock status panel
	var lock_panel := _create_lock_panel()
	_content_vbox.add_child(lock_panel)

	# Preview of what's coming
	var preview := _create_preview_panel()
	_content_vbox.add_child(preview)


func _create_lock_panel() -> Control:
	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = Color(0.1, 0.08, 0.06, 0.9)
	container_style.border_color = Color(0.6, 0.4, 0.2, 0.5)
	container_style.set_border_width_all(2)
	container_style.set_corner_radius_all(6)
	container_style.set_content_margin_all(15)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	container.add_child(vbox)

	var lock_label := Label.new()
	lock_label.text = "ENDLESS MODE LOCKED"
	lock_label.add_theme_font_size_override("font_size", 16)
	lock_label.add_theme_color_override("font_color", Color(0.8, 0.5, 0.3))
	lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lock_label)

	var req_label := Label.new()
	req_label.text = "Reach Day %d to unlock" % SimEndlessMode.UNLOCK_DAY
	req_label.add_theme_font_size_override("font_size", 14)
	req_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	req_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(req_label)

	# Progress bar
	var progress: float = float(_current_day) / float(SimEndlessMode.UNLOCK_DAY) * 100.0
	var progress_bar := ProgressBar.new()
	progress_bar.value = progress
	progress_bar.custom_minimum_size = Vector2(0, 20)
	progress_bar.show_percentage = true
	vbox.add_child(progress_bar)

	var progress_text := Label.new()
	progress_text.text = "Current progress: Day %d / %d" % [_current_day, SimEndlessMode.UNLOCK_DAY]
	progress_text.add_theme_font_size_override("font_size", 12)
	progress_text.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	progress_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(progress_text)

	# Alternative unlock
	var alt_label := Label.new()
	alt_label.text = "(Or complete %d waves total)" % SimEndlessMode.UNLOCK_WAVES
	alt_label.add_theme_font_size_override("font_size", 11)
	alt_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	alt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(alt_label)

	return container


func _create_preview_panel() -> Control:
	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = Color(0.06, 0.07, 0.1, 0.9)
	container_style.border_color = ThemeColors.BORDER_DISABLED
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(12)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	container.add_child(vbox)

	var header := Label.new()
	header.text = "WHAT AWAITS..."
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(header)

	var features: Array[String] = [
		"Infinite scaling challenge",
		"High score tracking",
		"Milestone rewards with gold and XP",
		"Progressive difficulty modifiers",
		"Test the limits of your typing skills"
	]

	for feature in features:
		var f_label := Label.new()
		f_label.text = "* %s" % feature
		f_label.add_theme_font_size_override("font_size", 11)
		f_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		vbox.add_child(f_label)

	return container


func _build_unlocked_content() -> void:
	# High scores
	var scores_panel := _create_high_scores_panel()
	_content_vbox.add_child(scores_panel)

	# Milestones
	var milestones_panel := _create_milestones_panel()
	_content_vbox.add_child(milestones_panel)

	# Modifiers info
	var modifiers_panel := _create_modifiers_info_panel()
	_content_vbox.add_child(modifiers_panel)

	# Scaling info
	var scaling_panel := _create_scaling_info_panel()
	_content_vbox.add_child(scaling_panel)


func _build_run_content() -> void:
	# Current run status
	var run_panel := _create_current_run_panel()
	_content_vbox.add_child(run_panel)

	# Scaling for current day
	var scaling_panel := _create_current_scaling_panel()
	_content_vbox.add_child(scaling_panel)

	# Active modifiers
	var active_mods := SimEndlessMode.get_active_modifiers(_run_day)
	if not active_mods.is_empty():
		var mods_panel := _create_active_modifiers_panel(active_mods)
		_content_vbox.add_child(mods_panel)

	# Next milestone
	var next_panel := _create_next_milestone_panel()
	_content_vbox.add_child(next_panel)


func _create_high_scores_panel() -> Control:
	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = Color(0.1, 0.12, 0.18, 0.9)
	container_style.border_color = Color(1.0, 0.84, 0.0, 0.5)
	container_style.set_border_width_all(2)
	container_style.set_corner_radius_all(6)
	container_style.set_content_margin_all(12)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	container.add_child(vbox)

	var header := Label.new()
	header.text = "HIGH SCORES"
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	vbox.add_child(header)

	var scores_grid := GridContainer.new()
	scores_grid.columns = 3
	scores_grid.add_theme_constant_override("h_separation", 30)
	scores_grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(scores_grid)

	# Score entries
	var score_entries: Array[Dictionary] = [
		{"label": "Highest Day", "key": "highest_day", "color": Color(1.0, 0.9, 0.3)},
		{"label": "Highest Wave", "key": "highest_wave", "color": Color(0.4, 0.8, 1.0)},
		{"label": "Best Combo", "key": "best_combo", "color": Color(1.0, 0.5, 0.3)},
		{"label": "Total Kills", "key": "total_kills", "color": Color(1.0, 0.4, 0.4)},
		{"label": "Total Runs", "key": "total_runs", "color": Color(0.7, 0.5, 0.9)},
		{"label": "Fastest Day", "key": "fastest_day", "color": Color(0.4, 1.0, 0.6)}
	]

	for entry in score_entries:
		var name_label := Label.new()
		name_label.text = str(entry.get("label", ""))
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		scores_grid.add_child(name_label)

	# Values in second row
	for entry in score_entries:
		var value: Variant = _high_scores.get(str(entry.get("key", "")), 0)
		var value_label := Label.new()

		if str(entry.get("key", "")) == "fastest_day":
			if float(value) < 999.0 and float(value) > 0:
				value_label.text = "%.1fs" % float(value)
			else:
				value_label.text = "-"
		else:
			value_label.text = str(int(value))

		value_label.add_theme_font_size_override("font_size", 18)
		value_label.add_theme_color_override("font_color", entry.get("color", Color.WHITE))
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		scores_grid.add_child(value_label)

	return container


func _create_milestones_panel() -> Control:
	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = Color(0.06, 0.07, 0.1, 0.9)
	container_style.border_color = ThemeColors.BORDER
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	container.add_child(vbox)

	var header := Label.new()
	header.text = "MILESTONES"
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", ThemeColors.ACCENT)
	vbox.add_child(header)

	var highest_day: int = int(_high_scores.get("highest_day", 0))
	var milestones := SimEndlessMode.get_all_milestones()

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(grid)

	for milestone_day in milestones:
		var reward: Dictionary = SimEndlessMode.MILESTONES.get(milestone_day, {})
		var is_achieved: bool = highest_day >= milestone_day
		var color: Color = MILESTONE_COLORS.get(milestone_day, Color.WHITE)

		# Day
		var day_label := Label.new()
		day_label.text = "Day %d" % milestone_day
		day_label.add_theme_font_size_override("font_size", 11)
		if is_achieved:
			day_label.add_theme_color_override("font_color", color)
		else:
			day_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		grid.add_child(day_label)

		# Name
		var name_label := Label.new()
		name_label.text = str(reward.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 11)
		if is_achieved:
			name_label.add_theme_color_override("font_color", color)
		else:
			name_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		grid.add_child(name_label)

		# Rewards
		var rewards_label := Label.new()
		rewards_label.text = "%dg / %dxp" % [int(reward.get("gold", 0)), int(reward.get("xp", 0))]
		rewards_label.add_theme_font_size_override("font_size", 10)
		if is_achieved:
			rewards_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.5))
		else:
			rewards_label.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
		grid.add_child(rewards_label)

		# Status
		var status_label := Label.new()
		if is_achieved:
			status_label.text = "ACHIEVED"
			status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		else:
			status_label.text = ""
		status_label.add_theme_font_size_override("font_size", 10)
		grid.add_child(status_label)

	return container


func _create_modifiers_info_panel() -> Control:
	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = Color(0.08, 0.06, 0.04, 0.9)
	container_style.border_color = Color(1.0, 0.5, 0.3, 0.5)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	container.add_child(vbox)

	var header := Label.new()
	header.text = "DIFFICULTY MODIFIERS"
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3))
	vbox.add_child(header)

	var highest_day: int = int(_high_scores.get("highest_day", 0))

	for mod_id in SimEndlessMode.ENDLESS_MODIFIERS.keys():
		var mod: Dictionary = SimEndlessMode.ENDLESS_MODIFIERS[mod_id]
		var start_day: int = int(mod.get("start_day", 999))
		var is_experienced: bool = highest_day >= start_day

		var mod_hbox := HBoxContainer.new()
		mod_hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(mod_hbox)

		var day_label := Label.new()
		day_label.text = "Day %d:" % start_day
		day_label.add_theme_font_size_override("font_size", 10)
		day_label.custom_minimum_size = Vector2(50, 0)
		if is_experienced:
			day_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
		else:
			day_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		mod_hbox.add_child(day_label)

		var desc_label := Label.new()
		desc_label.text = str(mod.get("description", mod_id))
		desc_label.add_theme_font_size_override("font_size", 10)
		desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if is_experienced:
			desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		else:
			desc_label.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
		mod_hbox.add_child(desc_label)

	return container


func _create_scaling_info_panel() -> Control:
	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = Color(0.06, 0.07, 0.1, 0.9)
	container_style.border_color = ThemeColors.BORDER_DISABLED
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	container.add_child(vbox)

	var header := Label.new()
	header.text = "SCALING PER DAY"
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(header)

	var scales_hbox := HBoxContainer.new()
	scales_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(scales_hbox)

	var scales: Array[Dictionary] = [
		{"name": "HP", "value": SimEndlessMode.HP_SCALE_PER_DAY * 100, "color": Color(1.0, 0.4, 0.4)},
		{"name": "Speed", "value": SimEndlessMode.SPEED_SCALE_PER_DAY * 100, "color": Color(0.4, 0.8, 1.0)},
		{"name": "Count", "value": SimEndlessMode.COUNT_SCALE_PER_DAY * 100, "color": Color(1.0, 0.9, 0.3)},
		{"name": "Damage", "value": SimEndlessMode.DAMAGE_SCALE_PER_DAY * 100, "color": Color(1.0, 0.5, 0.3)}
	]

	for scale in scales:
		var s_vbox := VBoxContainer.new()
		s_vbox.add_theme_constant_override("separation", 2)
		scales_hbox.add_child(s_vbox)

		var s_name := Label.new()
		s_name.text = str(scale.get("name", ""))
		s_name.add_theme_font_size_override("font_size", 10)
		s_name.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		s_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s_vbox.add_child(s_name)

		var s_value := Label.new()
		s_value.text = "+%.0f%%" % float(scale.get("value", 0))
		s_value.add_theme_font_size_override("font_size", 14)
		s_value.add_theme_color_override("font_color", scale.get("color", Color.WHITE))
		s_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s_vbox.add_child(s_value)

	return container


func _create_current_run_panel() -> Control:
	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = Color(0.1, 0.15, 0.1, 0.9)
	container_style.border_color = Color(0.4, 1.0, 0.4, 0.5)
	container_style.set_border_width_all(2)
	container_style.set_corner_radius_all(6)
	container_style.set_content_margin_all(15)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	container.add_child(vbox)

	var header := Label.new()
	header.text = "CURRENT RUN"
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)

	var stats_hbox := HBoxContainer.new()
	stats_hbox.add_theme_constant_override("separation", 30)
	vbox.add_child(stats_hbox)

	var stats: Array[Dictionary] = [
		{"name": "DAY", "value": str(_run_day), "color": Color(1.0, 0.9, 0.3)},
		{"name": "WAVE", "value": str(_run_wave), "color": Color(0.4, 0.8, 1.0)},
		{"name": "COMBO", "value": str(_run_combo), "color": Color(1.0, 0.5, 0.3)},
		{"name": "KILLS", "value": str(_run_kills), "color": Color(1.0, 0.4, 0.4)}
	]

	for stat in stats:
		var s_vbox := VBoxContainer.new()
		s_vbox.add_theme_constant_override("separation", 2)
		s_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stats_hbox.add_child(s_vbox)

		var s_name := Label.new()
		s_name.text = str(stat.get("name", ""))
		s_name.add_theme_font_size_override("font_size", 11)
		s_name.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		s_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s_vbox.add_child(s_name)

		var s_value := Label.new()
		s_value.text = str(stat.get("value", ""))
		s_value.add_theme_font_size_override("font_size", 24)
		s_value.add_theme_color_override("font_color", stat.get("color", Color.WHITE))
		s_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s_vbox.add_child(s_value)

	return container


func _create_current_scaling_panel() -> Control:
	var scaling: Dictionary = SimEndlessMode.get_scaling(_run_day)

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = Color(0.06, 0.07, 0.1, 0.9)
	container_style.border_color = ThemeColors.BORDER
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	container.add_child(vbox)

	var header := Label.new()
	header.text = "CURRENT SCALING (Day %d)" % _run_day
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(header)

	var scales_hbox := HBoxContainer.new()
	scales_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(scales_hbox)

	var scales: Array[Dictionary] = [
		{"name": "HP", "key": "hp_mult", "color": Color(1.0, 0.4, 0.4)},
		{"name": "Speed", "key": "speed_mult", "color": Color(0.4, 0.8, 1.0)},
		{"name": "Count", "key": "count_mult", "color": Color(1.0, 0.9, 0.3)},
		{"name": "Damage", "key": "damage_mult", "color": Color(1.0, 0.5, 0.3)}
	]

	for scale in scales:
		var mult: float = float(scaling.get(str(scale.get("key", "")), 1.0))

		var s_vbox := VBoxContainer.new()
		s_vbox.add_theme_constant_override("separation", 2)
		scales_hbox.add_child(s_vbox)

		var s_name := Label.new()
		s_name.text = str(scale.get("name", ""))
		s_name.add_theme_font_size_override("font_size", 10)
		s_name.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		s_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s_vbox.add_child(s_name)

		var s_value := Label.new()
		s_value.text = "x%.2f" % mult
		s_value.add_theme_font_size_override("font_size", 14)
		s_value.add_theme_color_override("font_color", scale.get("color", Color.WHITE))
		s_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s_vbox.add_child(s_value)

	return container


func _create_active_modifiers_panel(active_mods: Array[String]) -> Control:
	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = Color(0.1, 0.06, 0.04, 0.9)
	container_style.border_color = Color(1.0, 0.4, 0.2, 0.5)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	container.add_child(vbox)

	var header := Label.new()
	header.text = "ACTIVE MODIFIERS (%d)" % active_mods.size()
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3))
	vbox.add_child(header)

	for mod_id in active_mods:
		var mod: Dictionary = SimEndlessMode.get_modifier(mod_id)

		var mod_label := Label.new()
		mod_label.text = "* %s" % str(mod.get("description", mod_id))
		mod_label.add_theme_font_size_override("font_size", 11)
		mod_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.4))
		vbox.add_child(mod_label)

	return container


func _create_next_milestone_panel() -> Control:
	var highest_day: int = int(_high_scores.get("highest_day", 0))
	var current_best: int = maxi(_run_day, highest_day)
	var next_milestone: int = 0
	var milestones := SimEndlessMode.get_all_milestones()

	for m in milestones:
		if m > current_best:
			next_milestone = m
			break

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = Color(0.08, 0.08, 0.04, 0.9)
	container_style.border_color = Color(1.0, 0.84, 0.0, 0.4)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	container.add_child(vbox)

	if next_milestone > 0:
		var reward: Dictionary = SimEndlessMode.MILESTONES.get(next_milestone, {})
		var color: Color = MILESTONE_COLORS.get(next_milestone, Color.WHITE)

		var header := Label.new()
		header.text = "NEXT MILESTONE"
		header.add_theme_font_size_override("font_size", 12)
		header.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		vbox.add_child(header)

		var milestone_hbox := HBoxContainer.new()
		milestone_hbox.add_theme_constant_override("separation", 15)
		vbox.add_child(milestone_hbox)

		var day_label := Label.new()
		day_label.text = "Day %d" % next_milestone
		day_label.add_theme_font_size_override("font_size", 18)
		day_label.add_theme_color_override("font_color", color)
		milestone_hbox.add_child(day_label)

		var name_label := Label.new()
		name_label.text = str(reward.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.add_theme_color_override("font_color", color)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		milestone_hbox.add_child(name_label)

		var rewards_label := Label.new()
		rewards_label.text = "%d gold / %d XP" % [int(reward.get("gold", 0)), int(reward.get("xp", 0))]
		rewards_label.add_theme_font_size_override("font_size", 12)
		rewards_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.5))
		milestone_hbox.add_child(rewards_label)

		# Progress to next milestone
		var progress: float = float(_run_day) / float(next_milestone) * 100.0
		var progress_label := Label.new()
		progress_label.text = "Progress: %d / %d days (%.0f%%)" % [_run_day, next_milestone, progress]
		progress_label.add_theme_font_size_override("font_size", 11)
		progress_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		vbox.add_child(progress_label)
	else:
		var complete_label := Label.new()
		complete_label.text = "ALL MILESTONES ACHIEVED!"
		complete_label.add_theme_font_size_override("font_size", 14)
		complete_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		complete_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(complete_label)

	return container


func _on_start_pressed() -> void:
	if _is_unlocked:
		start_endless_mode.emit()
		hide()
		closed.emit()


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
