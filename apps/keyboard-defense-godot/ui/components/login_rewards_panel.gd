class_name LoginRewardsPanel
extends PanelContainer
## Login Rewards Panel - Shows daily login rewards calendar and streak progress.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed
signal reward_claimed(reward: Dictionary)

const SimLoginRewards = preload("res://sim/login_rewards.gd")

var _current_streak: int = 0
var _today_reward: Dictionary = {}
var _can_claim: bool = false

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null
var _claim_btn: Button = null

# Day colors (domain-specific)
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
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_MD, 520)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "DAILY LOGIN REWARDS"
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
	subtitle.text = "Log in daily to earn rewards and build your streak!"
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
	footer.text = "Rewards reset at midnight"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


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
	var section := _create_section_panel("CURRENT STREAK", ThemeColors.RESOURCE_GOLD)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Streak display
	var streak_row := DesignSystem.create_hbox(DesignSystem.SPACE_LG)
	streak_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(streak_row)

	var streak_label := Label.new()
	streak_label.text = str(_current_streak)
	DesignSystem.style_label(streak_label, "display", ThemeColors.RESOURCE_GOLD)
	streak_row.add_child(streak_label)

	var days_label := Label.new()
	days_label.text = "day streak" if _current_streak == 1 else "day streak"
	DesignSystem.style_label(days_label, "body_small", ThemeColors.TEXT_DIM)
	streak_row.add_child(days_label)

	# Progress to next milestone
	var progress: Dictionary = SimLoginRewards.get_streak_progress(_current_streak)
	var days_to_milestone: int = int(progress.get("days_to_milestone", 0))
	var milestone_name: String = str(progress.get("milestone_name", ""))

	if days_to_milestone > 0:
		var progress_label := Label.new()
		progress_label.text = "%d day%s until %s" % [days_to_milestone, "s" if days_to_milestone != 1 else "", milestone_name]
		DesignSystem.style_label(progress_label, "caption", ThemeColors.RARITY_EPIC)
		progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(progress_label)


func _build_calendar_section() -> void:
	var section := _create_section_panel("WEEKLY REWARDS", ThemeColors.INFO)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Create 7-day grid
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", DesignSystem.SPACE_SM)
	grid.add_theme_constant_override("v_separation", DesignSystem.SPACE_SM)
	vbox.add_child(grid)

	# Day headers
	var day_names: Array[String] = ["1", "2", "3", "4", "5", "6", "7"]
	for day_name in day_names:
		var header := Label.new()
		header.text = "Day " + day_name
		DesignSystem.style_label(header, "caption", ThemeColors.TEXT_DIM)
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
	panel_style.set_corner_radius_all(DesignSystem.RADIUS_SM)
	panel.add_theme_stylebox_override("panel", panel_style)

	var vbox := DesignSystem.create_vbox(2)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	# Gold amount
	var gold_label := Label.new()
	gold_label.text = str(tier.get("gold", 0))
	if is_claimed:
		DesignSystem.style_label(gold_label, "caption", ThemeColors.TEXT_DISABLED)
	else:
		DesignSystem.style_label(gold_label, "caption", ThemeColors.RESOURCE_GOLD)
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(gold_label)

	# Bonus indicator
	var bonus: String = str(tier.get("bonus", ""))
	if not bonus.is_empty():
		var bonus_label := Label.new()
		bonus_label.text = "+"
		DesignSystem.style_label(bonus_label, "caption", ThemeColors.RARITY_EPIC)
		bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(bonus_label)

	# Checkmark if claimed
	if is_claimed:
		var check := Label.new()
		check.text = "ok"
		DesignSystem.style_label(check, "caption", ThemeColors.SUCCESS)
		check.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(check)

	return panel


func _build_todays_reward_section() -> void:
	var section := PanelContainer.new()

	var section_style := StyleBoxFlat.new()
	section_style.bg_color = ThemeColors.SUCCESS.darkened(0.8)
	section_style.border_color = ThemeColors.RESOURCE_GOLD.darkened(0.3)
	section_style.set_border_width_all(2)
	section_style.set_corner_radius_all(DesignSystem.RADIUS_MD)
	section_style.set_content_margin_all(DesignSystem.SPACE_MD)
	section.add_theme_stylebox_override("panel", section_style)

	_content_vbox.add_child(section)

	var vbox := DesignSystem.create_vbox(DesignSystem.SPACE_SM)
	section.add_child(vbox)

	var header := Label.new()
	header.text = "TODAY'S REWARD"
	DesignSystem.style_label(header, "body_small", ThemeColors.RESOURCE_GOLD)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)

	# Reward preview
	var reward_text := Label.new()
	reward_text.text = SimLoginRewards.format_reward_text(_today_reward)
	DesignSystem.style_label(reward_text, "caption", ThemeColors.TEXT)
	reward_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(reward_text)

	# Claim button
	_claim_btn = Button.new()
	_claim_btn.text = "CLAIM REWARD"
	_claim_btn.custom_minimum_size = Vector2(160, DesignSystem.SIZE_BUTTON_MD)
	_style_claim_button()
	_claim_btn.pressed.connect(_on_claim_pressed)

	# Center the button
	var btn_container := DesignSystem.create_hbox(0)
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_child(_claim_btn)
	vbox.add_child(btn_container)


func _style_claim_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.SUCCESS.darkened(0.3), ThemeColors.SUCCESS)
	var hover := DesignSystem.create_button_style(ThemeColors.SUCCESS.darkened(0.1), ThemeColors.SUCCESS.lightened(0.2))
	_claim_btn.add_theme_stylebox_override("normal", normal)
	_claim_btn.add_theme_stylebox_override("hover", hover)
	_claim_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func _build_bonus_reference_section() -> void:
	var section := _create_section_panel("BONUS REWARDS", ThemeColors.RARITY_EPIC)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for bonus_id in SimLoginRewards.BONUS_ITEMS.keys():
		var bonus_info: Dictionary = SimLoginRewards.BONUS_ITEMS[bonus_id]
		var row := _create_bonus_row(bonus_id, bonus_info)
		vbox.add_child(row)


func _create_bonus_row(bonus_id: String, bonus_info: Dictionary) -> Control:
	var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)

	var name_label := Label.new()
	name_label.text = str(bonus_info.get("name", bonus_id))
	DesignSystem.style_label(name_label, "caption", ThemeColors.RARITY_EPIC)
	name_label.custom_minimum_size = Vector2(100, 0)
	hbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = str(bonus_info.get("description", ""))
	DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
	hbox.add_child(desc_label)

	return hbox


func _create_section_panel(title: String, color: Color) -> PanelContainer:
	var container := PanelContainer.new()

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = color.darkened(0.85)
	panel_style.border_color = color.darkened(0.5)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(DesignSystem.RADIUS_MD)
	panel_style.set_content_margin_all(DesignSystem.SPACE_MD)
	container.add_theme_stylebox_override("panel", panel_style)

	var vbox := DesignSystem.create_vbox(DesignSystem.SPACE_SM)
	container.add_child(vbox)

	var header := Label.new()
	header.text = title
	DesignSystem.style_label(header, "body_small", color)
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
