class_name LoginRewardsPanel
extends PanelContainer
## Login Rewards Panel - Shows daily login rewards calendar and streak progress

signal closed
signal reward_claimed(reward: Dictionary)

const ThemeColors = preload("res://ui/theme_colors.gd")
const SimLoginRewards = preload("res://sim/login_rewards.gd")

var _current_streak: int = 0
var _today_reward: Dictionary = {}
var _can_claim: bool = false

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null
var _claim_btn: Button = null

# Day colors
const DAY_COLORS: Dictionary = {
	"claimed": Color(0.3, 0.5, 0.3),
	"today": Color(0.8, 0.7, 0.2),
	"upcoming": Color(0.3, 0.35, 0.4),
	"bonus": Color(0.7, 0.5, 0.9)
}


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
	title.text = "DAILY LOGIN REWARDS"
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
	subtitle.text = "Log in daily to earn rewards and build your streak!"
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
	_content_vbox.add_theme_constant_override("separation", 12)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_vbox)

	# Footer
	var footer := Label.new()
	footer.text = "Rewards reset at midnight"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_login_rewards(streak: int = 0, can_claim: bool = false) -> void:
	_current_streak = streak
	_can_claim = can_claim
	_today_reward = SimLoginRewards.calculate_reward(streak + 1 if can_claim else streak)
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Streak progress section
	_build_streak_section()

	# Weekly calendar section
	_build_calendar_section()

	# Today's reward section
	if _can_claim:
		_build_todays_reward_section()

	# Bonus items reference
	_build_bonus_reference_section()


func _build_streak_section() -> void:
	var section := _create_section_panel("CURRENT STREAK", Color(1.0, 0.84, 0.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Streak display
	var streak_row := HBoxContainer.new()
	streak_row.add_theme_constant_override("separation", 20)
	streak_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(streak_row)

	var streak_label := Label.new()
	streak_label.text = str(_current_streak)
	streak_label.add_theme_font_size_override("font_size", 36)
	streak_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	streak_row.add_child(streak_label)

	var days_label := Label.new()
	days_label.text = "day streak" if _current_streak == 1 else "day streak"
	days_label.add_theme_font_size_override("font_size", 14)
	days_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	streak_row.add_child(days_label)

	# Progress to next milestone
	var progress: Dictionary = SimLoginRewards.get_streak_progress(_current_streak)
	var days_to_milestone: int = int(progress.get("days_to_milestone", 0))
	var milestone_name: String = str(progress.get("milestone_name", ""))

	if days_to_milestone > 0:
		var progress_label := Label.new()
		progress_label.text = "%d day%s until %s" % [days_to_milestone, "s" if days_to_milestone != 1 else "", milestone_name]
		progress_label.add_theme_font_size_override("font_size", 12)
		progress_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.9))
		progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(progress_label)


func _build_calendar_section() -> void:
	var section := _create_section_panel("WEEKLY REWARDS", Color(0.6, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Create 7-day grid
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(grid)

	# Day headers
	var day_names: Array[String] = ["1", "2", "3", "4", "5", "6", "7"]
	for day_name in day_names:
		var header := Label.new()
		header.text = "Day " + day_name
		header.add_theme_font_size_override("font_size", 10)
		header.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.custom_minimum_size = Vector2(55, 0)
		grid.add_child(header)

	# Reward tiles
	var day_in_week: int = ((_current_streak - 1) % 7) + 1 if _current_streak > 0 else 0

	for i in range(7):
		var tier: Dictionary = SimLoginRewards.REWARD_TIERS[i]
		var is_claimed: bool = (i + 1) <= day_in_week and not _can_claim
		var is_today: bool = (i + 1) == day_in_week + 1 if _can_claim else false
		var has_bonus: bool = not str(tier.get("bonus", "")).is_empty()

		var tile := _create_day_tile(i + 1, tier, is_claimed, is_today, has_bonus)
		grid.add_child(tile)


func _create_day_tile(day: int, tier: Dictionary, is_claimed: bool, is_today: bool, has_bonus: bool) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(55, 50)

	var bg_color: Color
	if is_claimed:
		bg_color = DAY_COLORS.get("claimed", Color.GRAY)
	elif is_today:
		bg_color = DAY_COLORS.get("today", Color.YELLOW).darkened(0.5)
	elif has_bonus:
		bg_color = DAY_COLORS.get("bonus", Color.PURPLE).darkened(0.7)
	else:
		bg_color = DAY_COLORS.get("upcoming", Color.GRAY)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = bg_color
	panel_style.border_color = bg_color.lightened(0.3) if is_today else bg_color.lightened(0.1)
	panel_style.set_border_width_all(2 if is_today else 1)
	panel_style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	# Gold amount
	var gold_label := Label.new()
	gold_label.text = str(tier.get("gold", 0))
	gold_label.add_theme_font_size_override("font_size", 12)
	gold_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0) if not is_claimed else Color(0.5, 0.5, 0.5))
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(gold_label)

	# Bonus indicator
	var bonus: String = str(tier.get("bonus", ""))
	if not bonus.is_empty():
		var bonus_label := Label.new()
		bonus_label.text = "+"
		bonus_label.add_theme_font_size_override("font_size", 10)
		bonus_label.add_theme_color_override("font_color", Color(0.7, 0.5, 0.9))
		bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(bonus_label)

	# Checkmark if claimed
	if is_claimed:
		var check := Label.new()
		check.text = "ok"
		check.add_theme_font_size_override("font_size", 9)
		check.add_theme_color_override("font_color", Color(0.4, 0.7, 0.4))
		check.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(check)

	return panel


func _build_todays_reward_section() -> void:
	var section := PanelContainer.new()

	var section_style := StyleBoxFlat.new()
	section_style.bg_color = Color(0.2, 0.25, 0.15, 0.9)
	section_style.border_color = Color(1.0, 0.84, 0.0, 0.7)
	section_style.set_border_width_all(2)
	section_style.set_corner_radius_all(6)
	section_style.set_content_margin_all(12)
	section.add_theme_stylebox_override("panel", section_style)

	_content_vbox.add_child(section)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	section.add_child(vbox)

	var header := Label.new()
	header.text = "TODAY'S REWARD"
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)

	# Reward preview
	var reward_text := Label.new()
	reward_text.text = SimLoginRewards.format_reward_text(_today_reward)
	reward_text.add_theme_font_size_override("font_size", 12)
	reward_text.add_theme_color_override("font_color", Color.WHITE)
	reward_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(reward_text)

	# Claim button
	_claim_btn = Button.new()
	_claim_btn.text = "CLAIM REWARD"
	_claim_btn.custom_minimum_size = Vector2(160, 40)
	_claim_btn.pressed.connect(_on_claim_pressed)
	vbox.add_child(_claim_btn)

	# Center the button
	var btn_container := HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_container)
	vbox.move_child(_claim_btn, vbox.get_child_count() - 1)
	_claim_btn.reparent(btn_container)


func _build_bonus_reference_section() -> void:
	var section := _create_section_panel("BONUS REWARDS", Color(0.7, 0.5, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for bonus_id in SimLoginRewards.BONUS_ITEMS.keys():
		var bonus_info: Dictionary = SimLoginRewards.BONUS_ITEMS[bonus_id]
		var row := _create_bonus_row(bonus_id, bonus_info)
		vbox.add_child(row)


func _create_bonus_row(bonus_id: String, bonus_info: Dictionary) -> Control:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	var name_label := Label.new()
	name_label.text = str(bonus_info.get("name", bonus_id))
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color(0.7, 0.5, 0.9))
	name_label.custom_minimum_size = Vector2(100, 0)
	hbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = str(bonus_info.get("description", ""))
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	hbox.add_child(desc_label)

	return hbox


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


func _on_claim_pressed() -> void:
	if _can_claim:
		reward_claimed.emit(_today_reward)
		_can_claim = false
		_build_content()


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
