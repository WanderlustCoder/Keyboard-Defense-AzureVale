class_name DailyChallengePanel
extends PanelContainer
## Daily Challenge Panel - Shows daily challenge info, progress, and streaks

signal closed
signal start_challenge

const ThemeColors = preload("res://ui/theme_colors.gd")
const SimDailyChallenges = preload("res://sim/daily_challenges.gd")

var _challenge: Dictionary = {}
var _is_in_run: bool = false
var _run_progress: int = 0
var _token_balance: int = 0

# UI elements
var _close_btn: Button = null
var _content_vbox: VBoxContainer = null
var _start_btn: Button = null
var _token_label: Label = null

# Challenge icon colors
const ICON_COLORS: Dictionary = {
	"fast": Color(0.4, 0.8, 1.0),
	"power": Color(1.0, 0.4, 0.4),
	"swarm": Color(0.4, 0.9, 0.4),
	"target": Color(1.0, 0.84, 0.0),
	"combo": Color(1.0, 0.6, 0.3),
	"shield": Color(0.6, 0.6, 0.8),
	"clock": Color(0.8, 0.4, 1.0),
	"keyboard": Color(0.7, 0.7, 0.7),
	"skull": Color(0.8, 0.2, 0.2),
	"simple": Color(0.5, 0.5, 0.5),
	"book": Color(0.4, 0.6, 0.8),
	"gold": Color(1.0, 0.84, 0.0)
}


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(520, 480)

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
	title.text = "DAILY CHALLENGE"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	header.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_token_label = Label.new()
	_token_label.add_theme_font_size_override("font_size", 14)
	_token_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	header.add_child(_token_label)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(15, 0)
	header.add_child(spacer2)

	_close_btn = Button.new()
	_close_btn.text = "X"
	_close_btn.custom_minimum_size = Vector2(30, 30)
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Content area
	_content_vbox = VBoxContainer.new()
	_content_vbox.add_theme_constant_override("separation", 12)
	_content_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(_content_vbox)

	# Start button
	_start_btn = Button.new()
	_start_btn.text = "START CHALLENGE"
	_start_btn.custom_minimum_size = Vector2(0, 40)
	_start_btn.pressed.connect(_on_start_pressed)
	main_vbox.add_child(_start_btn)


func show_challenge(challenge: Dictionary, in_run: bool, run_progress: int, token_balance: int) -> void:
	_challenge = challenge
	_is_in_run = in_run
	_run_progress = run_progress
	_token_balance = token_balance
	_token_label.text = "%d Tokens" % token_balance
	_build_content()
	_update_start_button()
	show()


func _update_start_button() -> void:
	var completed_today: bool = bool(_challenge.get("completed_today", false))

	if _is_in_run:
		_start_btn.text = "CONTINUE CHALLENGE"
		_start_btn.disabled = false
	elif completed_today:
		_start_btn.text = "COMPLETED TODAY"
		_start_btn.disabled = true
	else:
		_start_btn.text = "START CHALLENGE"
		_start_btn.disabled = false


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Challenge card
	var challenge_card := _create_challenge_card()
	_content_vbox.add_child(challenge_card)

	# Progress panel (if in run or completed)
	if _is_in_run:
		var progress_panel := _create_progress_panel()
		_content_vbox.add_child(progress_panel)

	# Streak info
	var streak_panel := _create_streak_panel()
	_content_vbox.add_child(streak_panel)

	# Streak bonuses preview
	var bonus_panel := _create_streak_bonuses_panel()
	_content_vbox.add_child(bonus_panel)


func _create_challenge_card() -> Control:
	var name: String = str(_challenge.get("name", "Unknown"))
	var desc: String = str(_challenge.get("description", ""))
	var icon: String = str(_challenge.get("icon", ""))
	var goal: Dictionary = _challenge.get("goal", {})
	var rewards: Dictionary = _challenge.get("rewards", {})
	var modifiers: Dictionary = _challenge.get("modifiers", {})
	var completed_today: bool = bool(_challenge.get("completed_today", false))

	var icon_color: Color = ICON_COLORS.get(icon, Color.WHITE)

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	if completed_today:
		container_style.bg_color = Color(0.1, 0.15, 0.1, 0.9)
		container_style.border_color = Color(0.4, 0.8, 0.4)
	else:
		container_style.bg_color = Color(0.12, 0.1, 0.06, 0.9)
		container_style.border_color = Color(1.0, 0.84, 0.0, 0.5)
	container_style.set_border_width_all(2)
	container_style.set_corner_radius_all(6)
	container_style.set_content_margin_all(15)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	container.add_child(vbox)

	# Name and status
	var header_hbox := HBoxContainer.new()
	vbox.add_child(header_hbox)

	var name_label := Label.new()
	name_label.text = name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", icon_color)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(name_label)

	if completed_today:
		var status_label := Label.new()
		status_label.text = "COMPLETE"
		status_label.add_theme_font_size_override("font_size", 12)
		status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		header_hbox.add_child(status_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = desc
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	# Modifiers (if any interesting ones)
	if not modifiers.is_empty():
		var mods_panel := _create_modifiers_display(modifiers)
		vbox.add_child(mods_panel)

	# Goal
	var goal_type: String = str(goal.get("type", ""))
	var target: int = int(goal.get("target", 0))
	var goal_text: String = SimDailyChallenges._format_goal(goal_type, target)

	var goal_label := Label.new()
	goal_label.text = "Goal: %s" % goal_text
	goal_label.add_theme_font_size_override("font_size", 14)
	goal_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	vbox.add_child(goal_label)

	# Rewards
	var rewards_hbox := HBoxContainer.new()
	rewards_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(rewards_hbox)

	var rewards_label := Label.new()
	rewards_label.text = "Rewards:"
	rewards_label.add_theme_font_size_override("font_size", 12)
	rewards_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	rewards_hbox.add_child(rewards_label)

	if int(rewards.get("gold", 0)) > 0:
		var gold_chip := _create_reward_chip("%d gold" % int(rewards.get("gold", 0)), Color(1.0, 0.84, 0.0))
		rewards_hbox.add_child(gold_chip)

	if int(rewards.get("xp", 0)) > 0:
		var xp_chip := _create_reward_chip("%d XP" % int(rewards.get("xp", 0)), Color(0.4, 0.8, 1.0))
		rewards_hbox.add_child(xp_chip)

	if int(rewards.get("tokens", 0)) > 0:
		var token_chip := _create_reward_chip("%d tokens" % int(rewards.get("tokens", 0)), Color(0.8, 0.4, 1.0))
		rewards_hbox.add_child(token_chip)

	return container


func _create_modifiers_display(modifiers: Dictionary) -> Control:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	for key in modifiers.keys():
		var value = modifiers[key]
		var mod_text: String = _format_modifier(key, value)
		if not mod_text.is_empty():
			var mod_chip := _create_modifier_chip(mod_text)
			hbox.add_child(mod_chip)

	return hbox


func _format_modifier(key: String, value: Variant) -> String:
	match key:
		"enemy_speed":
			if float(value) > 1.0:
				return "Enemy Speed +%.0f%%" % ((float(value) - 1.0) * 100)
			return ""
		"player_damage":
			if float(value) > 1.0:
				return "Damage +%.0f%%" % ((float(value) - 1.0) * 100)
			return ""
		"max_hp":
			return "Max HP: %d" % int(value)
		"enemy_hp":
			if float(value) != 1.0:
				return "Enemy HP x%.1f" % float(value)
			return ""
		"enemy_count":
			if float(value) > 1.0:
				return "Enemy Count x%.0f" % float(value)
			return ""
		"combo_bonus":
			return "Combo Bonus x%.0f" % float(value)
		"gold_mult":
			return "Gold x%.0f" % float(value)
		"typo_ends_run":
			return "No Typos!"
		"no_buildings":
			return "No Buildings"
		"no_items":
			return "No Items"
		"min_word_length":
			return "Words %d+ chars" % int(value)
		"boss_every_wave":
			return "Boss Every Wave"
		"no_wave_heal":
			return "No Healing"
		"wave_time_limit":
			return "%ds Time Limit" % int(value)
		"marathon_mode":
			return "Marathon Mode"
		_:
			return ""


func _create_modifier_chip(text: String) -> Control:
	var container := PanelContainer.new()

	var chip_style := StyleBoxFlat.new()
	chip_style.bg_color = Color(0.15, 0.1, 0.05, 0.8)
	chip_style.set_corner_radius_all(3)
	chip_style.set_content_margin_all(4)
	container.add_theme_stylebox_override("panel", chip_style)

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
	container.add_child(label)

	return container


func _create_reward_chip(text: String, color: Color) -> Control:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", color)
	return label


func _create_progress_panel() -> Control:
	var goal: Dictionary = _challenge.get("goal", {})
	var target: int = int(goal.get("target", 0))

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = Color(0.1, 0.12, 0.18, 0.9)
	container_style.border_color = Color(0.4, 0.8, 1.0, 0.5)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(12)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	container.add_child(vbox)

	var header := Label.new()
	header.text = "CURRENT PROGRESS"
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	vbox.add_child(header)

	var progress_hbox := HBoxContainer.new()
	progress_hbox.add_theme_constant_override("separation", 15)
	vbox.add_child(progress_hbox)

	var progress_label := Label.new()
	progress_label.text = "%d / %d" % [_run_progress, target]
	progress_label.add_theme_font_size_override("font_size", 24)
	progress_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	progress_hbox.add_child(progress_label)

	var progress_bar := ProgressBar.new()
	progress_bar.value = float(_run_progress) / float(maxi(1, target)) * 100.0
	progress_bar.custom_minimum_size = Vector2(200, 16)
	progress_bar.show_percentage = false
	progress_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	progress_hbox.add_child(progress_bar)

	return container


func _create_streak_panel() -> Control:
	var current_streak: int = int(_challenge.get("current_streak", 0))
	var completed_today: bool = bool(_challenge.get("completed_today", false))

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	if current_streak >= 7:
		container_style.bg_color = Color(0.12, 0.08, 0.15, 0.9)
		container_style.border_color = Color(0.8, 0.4, 1.0, 0.5)
	elif current_streak >= 3:
		container_style.bg_color = Color(0.12, 0.12, 0.06, 0.9)
		container_style.border_color = Color(1.0, 0.6, 0.3, 0.5)
	else:
		container_style.bg_color = Color(0.06, 0.07, 0.1, 0.9)
		container_style.border_color = ThemeColors.BORDER
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", container_style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	container.add_child(hbox)

	# Streak display
	var streak_vbox := VBoxContainer.new()
	streak_vbox.add_theme_constant_override("separation", 2)
	streak_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(streak_vbox)

	var streak_header := Label.new()
	streak_header.text = "CURRENT STREAK"
	streak_header.add_theme_font_size_override("font_size", 10)
	streak_header.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	streak_vbox.add_child(streak_header)

	var streak_value := Label.new()
	streak_value.text = "%d days" % current_streak
	streak_value.add_theme_font_size_override("font_size", 20)
	if current_streak >= 7:
		streak_value.add_theme_color_override("font_color", Color(0.8, 0.4, 1.0))
	elif current_streak >= 3:
		streak_value.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
	else:
		streak_value.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	streak_vbox.add_child(streak_value)

	# Status
	var status_vbox := VBoxContainer.new()
	status_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(status_vbox)

	var status_header := Label.new()
	status_header.text = "TODAY"
	status_header.add_theme_font_size_override("font_size", 10)
	status_header.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	status_vbox.add_child(status_header)

	var status_value := Label.new()
	if completed_today:
		status_value.text = "DONE"
		status_value.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	else:
		status_value.text = "PENDING"
		status_value.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	status_value.add_theme_font_size_override("font_size", 16)
	status_vbox.add_child(status_value)

	return container


func _create_streak_bonuses_panel() -> Control:
	var current_streak: int = int(_challenge.get("current_streak", 0))

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
	header.text = "STREAK BONUSES"
	header.add_theme_font_size_override("font_size", 10)
	header.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(header)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 15)
	grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(grid)

	var milestones: Array[int] = [3, 7, 14, 30, 100]
	for milestone in milestones:
		var bonus: Dictionary = SimDailyChallenges.STREAK_BONUSES.get(milestone, {})
		var tokens: int = int(bonus.get("tokens", 0))
		var name: String = str(bonus.get("name", ""))
		var is_achieved: bool = current_streak >= milestone

		var day_label := Label.new()
		day_label.text = "%d days" % milestone
		day_label.add_theme_font_size_override("font_size", 10)
		if is_achieved:
			day_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		else:
			day_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		grid.add_child(day_label)

		var name_label := Label.new()
		name_label.text = name
		name_label.add_theme_font_size_override("font_size", 10)
		if is_achieved:
			name_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		else:
			name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		grid.add_child(name_label)

		var token_label := Label.new()
		token_label.text = "+%d tokens" % tokens
		token_label.add_theme_font_size_override("font_size", 10)
		if is_achieved:
			token_label.add_theme_color_override("font_color", Color(0.8, 0.4, 1.0))
		else:
			token_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		grid.add_child(token_label)

	return container


func _on_start_pressed() -> void:
	if not bool(_challenge.get("completed_today", false)):
		start_challenge.emit()
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
