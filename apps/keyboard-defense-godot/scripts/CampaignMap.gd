extends Control
## Campaign Map - Node selection and progression display.
## Migrated to use DesignSystem and ThemeColors for consistency.

# Hover animation settings
const HOVER_SCALE := 1.05
const HOVER_DURATION := 0.12
const PULSE_DURATION := 1.2

# Track cards for animations
var _card_tweens: Dictionary = {}  # node_id -> Tween
var _card_refs: Dictionary = {}  # node_id -> Control

@onready var map_grid: GridContainer = $MapPanel/ScrollContainer/MapGrid
@onready var gold_label: Label = $TopBar/GoldLabel
@onready var summary_label: Label = $SummaryPanel/Content/SummaryLabel
@onready var modifiers_label: Label = $SummaryPanel/Content/ModifiersLabel
@onready var back_button: Button = $TopBar/BackButton
@onready var kingdom_button: Button = $TopBar/KingdomButton
@onready var progression = get_node("/root/ProgressionState")
@onready var game_controller = get_node("/root/GameController")
@onready var audio_manager = get_node_or_null("/root/AudioManager")

func _ready() -> void:
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)
	if kingdom_button != null:
		kingdom_button.pressed.connect(_on_kingdom_pressed)
	_refresh()
	if audio_manager != null:
		audio_manager.switch_to_kingdom_music()

func _refresh() -> void:
	gold_label.text = "Gold: %d" % progression.gold
	modifiers_label.text = _format_modifiers(progression.get_combat_modifiers())
	_build_map()
	_update_summary()

func _format_modifiers(modifiers: Dictionary) -> String:
	var parts: Array = []
	var typing_bonus = int(round((float(modifiers.get("typing_power", 1.0)) - 1.0) * 100.0))
	if typing_bonus != 0:
		parts.append("Typing Power %+d%%" % typing_bonus)
	var threat_bonus = int(round((1.0 - float(modifiers.get("threat_rate_multiplier", 1.0))) * 100.0))
	if threat_bonus != 0:
		parts.append("Threat Slow %+d%%" % threat_bonus)
	var forgiveness = int(round(float(modifiers.get("mistake_forgiveness", 0.0)) * 100.0))
	if forgiveness != 0:
		parts.append("Mistake Forgiveness %+d%%" % forgiveness)
	var castle_bonus = int(modifiers.get("castle_health_bonus", 0))
	if castle_bonus != 0:
		parts.append("Castle +%d" % castle_bonus)
	if parts.is_empty():
		return "Training bonuses: None yet. Upgrade to boost your typing impact."
	return "Training bonuses: " + ", ".join(parts)

func _build_map() -> void:
	# Clear old card references
	_card_refs.clear()
	for tween in _card_tweens.values():
		if tween != null and tween.is_valid():
			tween.kill()
	_card_tweens.clear()

	for child in map_grid.get_children():
		child.queue_free()
	var nodes: Array = progression.get_map_nodes()
	for node in nodes:
		var node_id = str(node.get("id", ""))
		var label = str(node.get("label", ""))
		var lesson_id = str(node.get("lesson_id", ""))
		var lesson = progression.get_lesson(lesson_id)
		var lesson_label_text = str(lesson.get("name", "Training Drill"))
		var reward_gold = int(node.get("reward_gold", 0))
		var unlocked = progression.is_node_unlocked(node_id)
		var completed = progression.is_node_completed(node_id)
		var requires: Array = node.get("requires", [])

		var card = _create_node_card(node_id, label, lesson_id, lesson_label_text, reward_gold, unlocked, completed, requires)
		map_grid.add_child(card)
		_card_refs[node_id] = card

		# Animate unlocked but not completed nodes with subtle pulse
		if unlocked and not completed:
			_start_unlock_pulse(card, node_id)

func _get_missing_requirement(requires: Array) -> String:
	# Find the first uncompleted requirement and return its label
	for req_id in requires:
		if not progression.is_node_completed(req_id):
			var req_node = progression.map_nodes.get(req_id, {})
			return str(req_node.get("label", req_id))
	return ""

func _create_node_card(node_id: String, label: String, lesson_id: String, lesson_name: String, reward_gold: int, unlocked: bool, completed: bool, requires: Array = []) -> Control:
	var text_color := ThemeColors.TEXT if unlocked else ThemeColors.TEXT_DIM

	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(240, 88)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.pivot_offset = Vector2(120, 44)  # Center pivot for scaling

	var card_style = StyleBoxFlat.new()
	card_style.bg_color = ThemeColors.BG_CARD if unlocked else ThemeColors.BG_CARD_DISABLED
	if completed:
		card_style.border_color = ThemeColors.ACCENT
		card_style.set_border_width_all(3)  # Thicker border for completed
	elif unlocked:
		card_style.border_color = ThemeColors.BORDER_HIGHLIGHT
		card_style.set_border_width_all(2)
	else:
		card_style.border_color = ThemeColors.BORDER_DISABLED
		card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(6)
	card_style.set_content_margin_all(8)
	card.add_theme_stylebox_override("panel", card_style)

	if unlocked:
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card.gui_input.connect(_on_card_input.bind(node_id))
		card.mouse_entered.connect(_on_card_hover_enter.bind(node_id))
		card.mouse_exited.connect(_on_card_hover_exit.bind(node_id))
	else:
		card.mouse_default_cursor_shape = Control.CURSOR_ARROW

	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	card.add_child(content)

	# Title row with completion badge
	var title_row = HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(title_row)

	if completed:
		var badge = Label.new()
		badge.text = "✓ "
		badge.add_theme_font_size_override("font_size", 16)
		badge.add_theme_color_override("font_color", ThemeColors.ACCENT)
		title_row.add_child(badge)

	var title = Label.new()
	title.text = label
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", text_color)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	title.max_lines_visible = 1
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_row.add_child(title)

	var lesson_label = Label.new()
	lesson_label.text = "Lesson: %s" % lesson_name
	lesson_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lesson_label.add_theme_font_size_override("font_size", 13)
	lesson_label.add_theme_color_override("font_color", text_color)
	lesson_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	lesson_label.max_lines_visible = 1
	lesson_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	content.add_child(lesson_label)

	# Health indicator (only for unlocked nodes)
	if unlocked and lesson_id != "":
		var health_label_text := _get_lesson_health_label(lesson_id)
		if health_label_text != "--":
			var health_row = HBoxContainer.new()
			health_row.alignment = BoxContainer.ALIGNMENT_CENTER
			content.add_child(health_row)

			var health_text = Label.new()
			health_text.text = "Health: "
			health_text.add_theme_font_size_override("font_size", 11)
			health_text.add_theme_color_override("font_color", text_color)
			health_row.add_child(health_text)

			var health_value = Label.new()
			health_value.text = health_label_text
			health_value.add_theme_font_size_override("font_size", 11)
			health_value.add_theme_color_override("font_color", _get_health_color(health_label_text))
			health_row.add_child(health_value)

	if reward_gold > 0 and unlocked:
		var reward_label = Label.new()
		if completed:
			reward_label.text = "Reward: %dg (first clear)" % reward_gold
		else:
			reward_label.text = "Reward: %dg" % reward_gold
		reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reward_label.add_theme_font_size_override("font_size", 12)
		reward_label.add_theme_color_override("font_color", ThemeColors.ACCENT if not completed else text_color)
		content.add_child(reward_label)

	# Show unlock requirement for locked nodes
	if not unlocked and not requires.is_empty():
		var missing_req := _get_missing_requirement(requires)
		if missing_req != "":
			var unlock_label = Label.new()
			unlock_label.text = "🔒 Complete: %s" % missing_req
			unlock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			unlock_label.add_theme_font_size_override("font_size", 11)
			unlock_label.add_theme_color_override("font_color", ThemeColors.WARNING)
			unlock_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			unlock_label.max_lines_visible = 1
			unlock_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			content.add_child(unlock_label)

	return card

func _update_summary() -> void:
	var summary = progression.get_last_summary()
	if summary.is_empty():
		summary_label.text = "Complete a battle to unlock more routes."
		return
	var accuracy = int(round(float(summary.get("accuracy", 0.0)) * 100.0))
	var wpm = int(round(float(summary.get("wpm", 0.0))))
	var gold_awarded = int(summary.get("gold_awarded", 0))
	var tier := str(summary.get("performance_tier", ""))
	var bonus := int(summary.get("performance_bonus", 0))
	var node_label = str(summary.get("node_label", "Last Battle"))
	var tier_text := ""
	if tier != "":
		tier_text = " [%s]" % tier
	var bonus_text := ""
	if bonus > 0:
		bonus_text = " (+%dg bonus)" % bonus
	summary_label.text = "%s%s: %d%% acc, %d WPM, +%dg%s" % [node_label, tier_text, accuracy, wpm, gold_awarded, bonus_text]

func _format_reward_preview(reward_gold: int, completed: bool) -> String:
	if reward_gold <= 0:
		return ""
	if completed:
		return "Reward: %dg (first clear)" % reward_gold
	return "Reward: %dg" % reward_gold

func _on_node_pressed(node_id: String) -> void:
	if audio_manager != null:
		audio_manager.play_ui_confirm()
	game_controller.go_to_battle(node_id)

func _on_card_input(event: InputEvent, node_id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_node_pressed(node_id)
		accept_event()

func _on_back_pressed() -> void:
	if audio_manager != null:
		audio_manager.play_ui_cancel()
	game_controller.go_to_menu()

func _on_kingdom_pressed() -> void:
	if audio_manager != null:
		audio_manager.play_ui_confirm()
	game_controller.go_to_kingdom()

func _on_card_hover_enter(node_id: String) -> void:
	var card = _card_refs.get(node_id)
	if card == null:
		return

	# Kill any existing tween for this card
	if _card_tweens.has(node_id):
		var old_tween = _card_tweens[node_id]
		if old_tween != null and old_tween.is_valid():
			old_tween.kill()

	# Scale up with smooth tween
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(card, "scale", Vector2(HOVER_SCALE, HOVER_SCALE), HOVER_DURATION)
	_card_tweens[node_id] = tween

	# Play subtle hover sound
	if audio_manager != null:
		audio_manager.play_ui_hover()

func _on_card_hover_exit(node_id: String) -> void:
	var card = _card_refs.get(node_id)
	if card == null:
		return

	# Kill any existing tween for this card
	if _card_tweens.has(node_id):
		var old_tween = _card_tweens[node_id]
		if old_tween != null and old_tween.is_valid():
			old_tween.kill()

	# Scale back to normal
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), HOVER_DURATION)
	_card_tweens[node_id] = tween

func _start_unlock_pulse(card: Control, node_id: String) -> void:
	# Subtle glow pulse for unlocked but not completed nodes
	var tween = create_tween()
	tween.set_loops()  # Infinite loop
	tween.tween_property(card, "modulate", Color(1.1, 1.1, 1.15, 1.0), PULSE_DURATION * 0.5)
	tween.tween_property(card, "modulate", Color(1.0, 1.0, 1.0, 1.0), PULSE_DURATION * 0.5)
	# Store reference (will be killed when map rebuilds)
	_card_tweens[node_id + "_pulse"] = tween

func _get_lesson_health_label(lesson_id: String) -> String:
	# Get health label based on lesson mastery
	var mastery: Dictionary = progression.get_lesson_mastery(lesson_id)
	var attempts := int(mastery.get("attempt_count", 0))
	if attempts < 2:
		return "--"
	# Simple health based on completion rate for now
	var completions := int(mastery.get("completion_count", 0))
	var rate := float(completions) / float(attempts) if attempts > 0 else 0.0
	if rate >= 0.8:
		return "GOOD"
	elif rate >= 0.5:
		return "OK"
	else:
		return "WARN"

func _get_health_color(label: String) -> Color:
	match label:
		"GOOD":
			return Color(0.3, 0.9, 0.5)
		"OK":
			return Color(0.9, 0.8, 0.2)
		"WARN":
			return Color(0.9, 0.4, 0.3)
		_:
			return ThemeColors.TEXT_DIM
