class_name DailyChallengesPanel
extends PanelContainer
## Daily Challenges Panel - Shows all available daily challenge types and rewards.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Daily challenge definitions (domain-specific colors for challenge themes)
const DAILY_CHALLENGES: Array[Dictionary] = [
	{
		"id": "speed_demon",
		"name": "Speed Demon",
		"description": "Enemies move 50% faster. Survive the onslaught!",
		"color": Color(0.9, 0.4, 0.4),
		"modifiers": {"enemy_speed": 1.5},
		"goal": "Complete 10 waves",
		"reward": {"gold": 500, "xp": 200}
	},
	{
		"id": "glass_cannon",
		"name": "Glass Cannon",
		"description": "Towers deal 2x damage but cost 2x gold",
		"color": Color(1.0, 0.84, 0.0),
		"modifiers": {"tower_damage": 2.0, "tower_cost": 2.0},
		"goal": "Defeat 100 enemies",
		"reward": {"gold": 400, "xp": 150}
	},
	{
		"id": "swarm_survival",
		"name": "Swarm Survival",
		"description": "Double enemy count, half enemy health",
		"color": Color(0.5, 0.8, 0.3),
		"modifiers": {"enemy_count": 2.0, "enemy_health": 0.5},
		"goal": "Survive 15 waves",
		"reward": {"gold": 600, "xp": 250}
	},
	{
		"id": "precision_strike",
		"name": "Precision Strike",
		"description": "Only accuracy above 95% counts as hits",
		"color": Color(0.4, 0.8, 1.0),
		"modifiers": {"accuracy_threshold": 0.95},
		"goal": "50 perfect words",
		"reward": {"gold": 450, "xp": 180}
	},
	{
		"id": "combo_master",
		"name": "Combo Master",
		"description": "Combo multiplier caps at x5 but builds faster",
		"color": Color(0.9, 0.6, 0.3),
		"modifiers": {"combo_cap": 5.0, "combo_rate": 2.0},
		"goal": "Reach 50 combo",
		"reward": {"gold": 550, "xp": 220}
	},
	{
		"id": "iron_fortress",
		"name": "Iron Fortress",
		"description": "Towers have +100% HP but -25% damage",
		"color": Color(0.6, 0.6, 0.7),
		"modifiers": {"tower_health": 2.0, "tower_damage": 0.75},
		"goal": "No tower destroyed",
		"reward": {"gold": 500, "xp": 200}
	},
	{
		"id": "time_attack",
		"name": "Time Attack",
		"description": "Complete waves as fast as possible",
		"color": Color(0.9, 0.4, 0.8),
		"modifiers": {"time_bonus": true},
		"goal": "Under 5 min total",
		"reward": {"gold": 700, "xp": 300}
	},
	{
		"id": "word_marathon",
		"name": "Word Marathon",
		"description": "Extended waves with longer words",
		"color": Color(0.7, 0.5, 0.9),
		"modifiers": {"word_length": 1.5, "wave_duration": 1.5},
		"goal": "Type 500 words",
		"reward": {"gold": 600, "xp": 250}
	},
	{
		"id": "boss_rush",
		"name": "Boss Rush",
		"description": "Every 3rd wave is a boss wave",
		"color": Color(0.8, 0.2, 0.2),
		"modifiers": {"boss_frequency": 3},
		"goal": "Defeat 5 bosses",
		"reward": {"gold": 800, "xp": 350}
	},
	{
		"id": "minimalist",
		"name": "Minimalist",
		"description": "Only 3 tower slots available",
		"color": Color(0.5, 0.7, 0.5),
		"modifiers": {"tower_slots": 3},
		"goal": "Complete 8 waves",
		"reward": {"gold": 550, "xp": 220}
	},
	{
		"id": "long_words",
		"name": "Long Words Only",
		"description": "All words are 8+ characters",
		"color": Color(0.6, 0.8, 1.0),
		"modifiers": {"min_word_length": 8},
		"goal": "Type 100 long words",
		"reward": {"gold": 500, "xp": 200}
	},
	{
		"id": "gold_rush",
		"name": "Gold Rush",
		"description": "2x gold from kills, but 2x tower costs",
		"color": Color(1.0, 0.84, 0.0),
		"modifiers": {"gold_multiplier": 2.0, "tower_cost": 2.0},
		"goal": "Earn 2000 gold",
		"reward": {"gold": 400, "xp": 150}
	}
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 620)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "DAILY CHALLENGES"
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
	subtitle.text = "Special challenge modes that rotate daily"
	DesignSystem.style_label(subtitle, "body_small", ThemeColors.TEXT_DIM)
	main_vbox.add_child(subtitle)

	# Content scroll
	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_content_scroll)

	_content_vbox = DesignSystem.create_vbox(DesignSystem.SPACE_SM)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_vbox)

	# Footer
	var footer := Label.new()
	footer.text = "New challenges appear each day at midnight"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_daily_challenges() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	for challenge in DAILY_CHALLENGES:
		var card := _create_challenge_card(challenge)
		_content_vbox.add_child(card)


func _create_challenge_card(challenge: Dictionary) -> Control:
	var name_str: String = str(challenge.get("name", ""))
	var description: String = str(challenge.get("description", ""))
	var goal: String = str(challenge.get("goal", ""))
	var color: Color = challenge.get("color", Color.WHITE)
	var reward: Dictionary = challenge.get("reward", {})

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = color.darkened(0.85)
	container_style.border_color = color.darkened(0.6)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(DesignSystem.RADIUS_XS)
	container_style.set_content_margin_all(DesignSystem.SPACE_SM)
	container.add_theme_stylebox_override("panel", container_style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_XS)
	container.add_child(main_vbox)

	# Header row with name and goal
	var header_hbox := DesignSystem.create_hbox(DesignSystem.SPACE_SM)
	main_vbox.add_child(header_hbox)

	var name_label := Label.new()
	name_label.text = name_str
	DesignSystem.style_label(name_label, "caption", color)
	header_hbox.add_child(name_label)

	header_hbox.add_child(DesignSystem.create_spacer())

	var goal_label := Label.new()
	goal_label.text = "Goal: " + goal
	DesignSystem.style_label(goal_label, "caption", ThemeColors.SUCCESS)
	header_hbox.add_child(goal_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = description
	DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_vbox.add_child(desc_label)

	# Rewards row
	var reward_hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(reward_hbox)

	var gold_amt: int = int(reward.get("gold", 0))
	var xp_amt: int = int(reward.get("xp", 0))

	if gold_amt > 0:
		var gold_label := Label.new()
		gold_label.text = "Gold: %d" % gold_amt
		DesignSystem.style_label(gold_label, "caption", ThemeColors.RESOURCE_GOLD)
		reward_hbox.add_child(gold_label)

	if xp_amt > 0:
		var xp_label := Label.new()
		xp_label.text = "XP: %d" % xp_amt
		DesignSystem.style_label(xp_label, "caption", ThemeColors.INFO)
		reward_hbox.add_child(xp_label)

	return container


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
