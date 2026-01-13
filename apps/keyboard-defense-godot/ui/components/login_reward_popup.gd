class_name LoginRewardPopup
extends PanelContainer
## Login Reward Popup - Shows daily login rewards to the player.
## Migrated to use DesignSystem and ThemeColors for consistency.

# Preload for test compatibility (when autoload isn't available)
const DesignSystem = preload("res://ui/design_system.gd")

signal claim_pressed(reward: Dictionary)
signal closed

const SimLoginRewards = preload("res://sim/login_rewards.gd")

var _reward: Dictionary = {}
var _streak: int = 0

# UI elements
var _title_label: Label = null
var _streak_label: Label = null
var _reward_text: RichTextLabel = null
var _progress_container: HBoxContainer = null
var _claim_btn: Button = null
var _animation_tween: Tween = null


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_MD, 320)

	# Background panel style
	var style := StyleBoxFlat.new()
	style.bg_color = ThemeColors.BG_PANEL
	style.border_color = Color(1.0, 0.84, 0.0)  # Gold border
	style.set_border_width_all(3)
	style.set_corner_radius_all(DesignSystem.RADIUS_LG)
	style.set_content_margin_all(DesignSystem.SPACE_LG)
	add_theme_stylebox_override("panel", style)

	var vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(vbox)

	# Title with icon
	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(title_row)

	var star_left := Label.new()
	star_left.text = "*"
	star_left.add_theme_font_size_override("font_size", 24)
	star_left.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	title_row.add_child(star_left)

	_title_label = Label.new()
	_title_label.text = "Daily Reward"
	_title_label.add_theme_font_size_override("font_size", 26)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	title_row.add_child(_title_label)

	var star_right := Label.new()
	star_right.text = "*"
	star_right.add_theme_font_size_override("font_size", 24)
	star_right.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	title_row.add_child(star_right)

	# Streak display
	_streak_label = Label.new()
	_streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_streak_label.add_theme_font_size_override("font_size", 16)
	_streak_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(_streak_label)

	# Separator
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Reward text (centered, with padding)
	var reward_center := CenterContainer.new()
	reward_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(reward_center)

	_reward_text = RichTextLabel.new()
	_reward_text.bbcode_enabled = true
	_reward_text.fit_content = true
	_reward_text.scroll_active = false
	_reward_text.custom_minimum_size = Vector2(300, 100)
	_reward_text.add_theme_font_size_override("normal_font_size", 16)
	reward_center.add_child(_reward_text)

	# Progress dots (day 1-7)
	var progress_label := Label.new()
	progress_label.text = "Weekly Progress"
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 12)
	progress_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(progress_label)

	_progress_container = HBoxContainer.new()
	_progress_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_progress_container.add_theme_constant_override("separation", 8)
	vbox.add_child(_progress_container)

	# Create 7 day indicators
	for i in range(7):
		var day_box := PanelContainer.new()
		day_box.custom_minimum_size = Vector2(36, 36)
		var day_style := StyleBoxFlat.new()
		day_style.bg_color = Color(0.2, 0.2, 0.25)
		day_style.set_corner_radius_all(4)
		day_box.add_theme_stylebox_override("panel", day_style)
		day_box.name = "Day%d" % (i + 1)

		var day_label := Label.new()
		day_label.text = str(i + 1)
		day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		day_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		day_label.add_theme_font_size_override("font_size", 14)
		day_label.name = "Label"
		day_box.add_child(day_label)

		_progress_container.add_child(day_box)

	# Separator
	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	# Claim button
	_claim_btn = Button.new()
	_claim_btn.text = "Claim Reward!"
	_claim_btn.custom_minimum_size = Vector2(200, 48)
	_claim_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_claim_btn.pressed.connect(_on_claim_pressed)
	vbox.add_child(_claim_btn)


func show_reward(reward: Dictionary, streak: int) -> void:
	_reward = reward
	_streak = streak
	_refresh_display()
	show()
	_play_entrance_animation()


func _refresh_display() -> void:
	# Update streak label
	var week: int = int(_reward.get("week", 1))
	if _streak == 1:
		_streak_label.text = "Day 1 - Start of a new streak!"
	elif week > 1:
		_streak_label.text = "Day %d - Week %d Streak!" % [_streak, week]
	else:
		_streak_label.text = "Day %d Streak" % _streak

	# Update reward text
	_reward_text.text = "[center]%s[/center]" % SimLoginRewards.format_reward_text(_reward)

	# Update progress dots
	var day_in_week: int = ((_streak - 1) % 7) + 1 if _streak > 0 else 0

	for i in range(7):
		var day_num: int = i + 1
		var day_box: PanelContainer = _progress_container.get_node("Day%d" % day_num)
		if day_box == null:
			continue

		var style: StyleBoxFlat = day_box.get_theme_stylebox("panel").duplicate()
		var label: Label = day_box.get_node("Label")

		if day_num < day_in_week:
			# Completed day
			style.bg_color = Color(0.3, 0.6, 0.3)  # Green
			style.border_color = Color(0.4, 0.8, 0.4)
			style.set_border_width_all(1)
			if label:
				label.add_theme_color_override("font_color", Color.WHITE)
		elif day_num == day_in_week:
			# Current day (today's reward)
			style.bg_color = Color(0.8, 0.6, 0.0)  # Gold
			style.border_color = Color(1.0, 0.84, 0.0)
			style.set_border_width_all(2)
			if label:
				label.add_theme_color_override("font_color", Color.WHITE)
		else:
			# Future day
			style.bg_color = Color(0.2, 0.2, 0.25)
			style.border_color = Color(0.3, 0.3, 0.35)
			style.set_border_width_all(1)
			if label:
				label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

		# Special indicators for bonus days
		if day_num == 3 or day_num == 5 or day_num == 7:
			if day_num > day_in_week:
				style.border_color = Color(0.4, 0.6, 0.8)  # Blue hint for bonus days

		day_box.add_theme_stylebox_override("panel", style)


func _play_entrance_animation() -> void:
	# Start small and scale up
	scale = Vector2(0.8, 0.8)
	modulate.a = 0.0

	if _animation_tween != null and _animation_tween.is_valid():
		_animation_tween.kill()

	_animation_tween = create_tween()
	_animation_tween.set_ease(Tween.EASE_OUT)
	_animation_tween.set_trans(Tween.TRANS_BACK)
	_animation_tween.set_parallel(true)
	_animation_tween.tween_property(self, "scale", Vector2.ONE, 0.3)
	_animation_tween.tween_property(self, "modulate:a", 1.0, 0.2)


func _on_claim_pressed() -> void:
	# Play claim animation
	if _animation_tween != null and _animation_tween.is_valid():
		_animation_tween.kill()

	_animation_tween = create_tween()
	_animation_tween.set_ease(Tween.EASE_IN)
	_animation_tween.set_trans(Tween.TRANS_BACK)
	_animation_tween.set_parallel(true)
	_animation_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
	_animation_tween.chain().tween_property(self, "scale", Vector2(0.8, 0.8), 0.2)
	_animation_tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	_animation_tween.tween_callback(_finish_claim)


func _finish_claim() -> void:
	hide()
	claim_pressed.emit(_reward)
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		_on_claim_pressed()
		get_viewport().set_input_as_handled()
