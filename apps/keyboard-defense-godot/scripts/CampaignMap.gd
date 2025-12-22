extends Control

@onready var map_grid: GridContainer = $MapPanel/MapGrid
@onready var gold_label: Label = $TopBar/GoldLabel
@onready var summary_label: Label = $SummaryPanel/Content/SummaryLabel
@onready var modifiers_label: Label = $SummaryPanel/Content/ModifiersLabel
@onready var back_button: Button = $TopBar/BackButton
@onready var kingdom_button: Button = $TopBar/KingdomButton
@onready var progression = get_node("/root/ProgressionState")
@onready var game_controller = get_node("/root/GameController")

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	kingdom_button.pressed.connect(_on_kingdom_pressed)
	_refresh()

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
	for child in map_grid.get_children():
		child.queue_free()
	var nodes: Array = progression.get_map_nodes()
	for node in nodes:
		var node_id = str(node.get("id", ""))
		var label = str(node.get("label", ""))
		var lesson_id = str(node.get("lesson_id", ""))
		var lesson = progression.get_lesson(lesson_id)
		var lesson_label_text = str(lesson.get("label", "Training Drill"))
		var reward_gold = int(node.get("reward_gold", 0))
		var unlocked = progression.is_node_unlocked(node_id)
		var completed = progression.is_node_completed(node_id)
		var button = Button.new()
		button.text = ""
		button.disabled = not unlocked
		button.custom_minimum_size = Vector2(260, 96)
		button.pressed.connect(_on_node_pressed.bind(node_id))
		var content = VBoxContainer.new()
		content.anchor_right = 1.0
		content.anchor_bottom = 1.0
		content.offset_left = 8
		content.offset_top = 8
		content.offset_right = -8
		content.offset_bottom = -8
		content.add_theme_constant_override("separation", 4)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(content)

		var title = Label.new()
		title.text = label + (" (cleared)" if completed else "")
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.autowrap_mode = TextServer.AUTOWRAP_WORD
		title.max_lines_visible = 2
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		title.add_theme_font_size_override("font_size", 16)
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(title)

		var lesson_label = Label.new()
		lesson_label.text = "Lesson: %s" % lesson_label_text
		lesson_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lesson_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lesson_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		lesson_label.max_lines_visible = 2
		lesson_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		lesson_label.add_theme_font_size_override("font_size", 14)
		lesson_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(lesson_label)

		var reward_text = _format_reward_preview(reward_gold, completed)
		if reward_text != "":
			var reward_label = Label.new()
			reward_label.text = reward_text
			reward_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			reward_label.max_lines_visible = 1
			reward_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			reward_label.add_theme_font_size_override("font_size", 12)
			reward_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			content.add_child(reward_label)
		map_grid.add_child(button)

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
	game_controller.go_to_battle(node_id)

func _on_back_pressed() -> void:
	game_controller.go_to_menu()

func _on_kingdom_pressed() -> void:
	game_controller.go_to_kingdom()
