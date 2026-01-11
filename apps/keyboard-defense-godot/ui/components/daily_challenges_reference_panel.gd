class_name DailyChallengesReferencePanel
extends PanelContainer
## Daily Challenges Reference Panel - Shows challenge types, rewards, and token shop

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Challenge types
const CHALLENGE_TYPES: Array[Dictionary] = [
	{
		"id": "speed_demon",
		"name": "Speed Demon",
		"desc": "Enemies +50% faster, you +25% damage",
		"goal": "Survive 5 waves",
		"tokens": 2,
		"color": Color(0.5, 0.8, 1.0)
	},
	{
		"id": "glass_cannon",
		"name": "Glass Cannon",
		"desc": "5 HP castle, triple damage",
		"goal": "Survive 3 waves",
		"tokens": 3,
		"color": Color(0.96, 0.26, 0.21)
	},
	{
		"id": "swarm_survival",
		"name": "Swarm Survival",
		"desc": "2x enemies, half HP each",
		"goal": "Kill 50 enemies",
		"tokens": 2,
		"color": Color(0.6, 0.5, 0.7)
	},
	{
		"id": "precision_strike",
		"name": "Precision Strike",
		"desc": "Any typo ends the run",
		"goal": "Type 30 words",
		"tokens": 4,
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"id": "combo_master",
		"name": "Combo Master",
		"desc": "Combo bonus doubled",
		"goal": "Reach 25 combo",
		"tokens": 3,
		"color": Color(1.0, 0.55, 0.0)
	},
	{
		"id": "iron_fortress",
		"name": "Iron Fortress",
		"desc": "No healing between waves, 15 HP",
		"goal": "Survive 7 waves",
		"tokens": 3,
		"color": Color(0.5, 0.6, 0.7)
	},
	{
		"id": "time_attack",
		"name": "Time Attack",
		"desc": "45s per wave or lose HP",
		"goal": "Survive 5 waves",
		"tokens": 3,
		"color": Color(0.8, 0.6, 0.3)
	},
	{
		"id": "word_marathon",
		"name": "Word Marathon",
		"desc": "Marathon mode enabled",
		"goal": "100 words without combo break",
		"tokens": 5,
		"color": Color(0.6, 0.4, 0.8)
	},
	{
		"id": "boss_rush",
		"name": "Boss Rush",
		"desc": "Boss every wave, 2x gold",
		"goal": "Defeat 3 bosses",
		"tokens": 5,
		"color": Color(0.8, 0.2, 0.2)
	},
	{
		"id": "minimalist",
		"name": "Minimalist",
		"desc": "No buildings, no items",
		"goal": "Survive 4 waves",
		"tokens": 2,
		"color": Color(0.5, 0.5, 0.5)
	},
	{
		"id": "long_words",
		"name": "Lexicon Master",
		"desc": "All words 8+ characters",
		"goal": "Type 25 words",
		"tokens": 3,
		"color": Color(0.6, 0.5, 0.8)
	},
	{
		"id": "gold_rush",
		"name": "Gold Rush",
		"desc": "3x gold, enemies +50% HP",
		"goal": "Earn 500 gold",
		"tokens": 2,
		"color": Color(1.0, 0.84, 0.0)
	}
]

# Streak bonuses
const STREAK_BONUSES: Array[Dictionary] = [
	{"days": 3, "tokens": 2, "name": "3-Day Streak"},
	{"days": 7, "tokens": 5, "name": "Weekly Warrior"},
	{"days": 14, "tokens": 10, "name": "Fortnight Fighter"},
	{"days": 30, "tokens": 25, "name": "Monthly Master"},
	{"days": 100, "tokens": 100, "name": "Century Champion"}
]

# Token shop items
const TOKEN_SHOP_ITEMS: Array[Dictionary] = [
	{
		"name": "Champion's Cape",
		"cost": 25,
		"effect": "+15% gold, +10% XP",
		"type": "Equipment",
		"color": Color(0.6, 0.4, 0.6)
	},
	{
		"name": "Challenger's Ring",
		"cost": 30,
		"effect": "+20% crit chance, +50% crit damage",
		"type": "Equipment",
		"color": Color(0.8, 0.6, 0.3)
	},
	{
		"name": "Daily Victor Amulet",
		"cost": 35,
		"effect": "+25% damage, +5% dodge",
		"type": "Equipment",
		"color": Color(0.67, 0.0, 1.0)
	},
	{
		"name": "Potion Bundle",
		"cost": 10,
		"effect": "5 health potions",
		"type": "Consumables",
		"color": Color(0.8, 0.2, 0.2)
	},
	{
		"name": "Scroll Bundle",
		"cost": 15,
		"effect": "3 damage scrolls",
		"type": "Consumables",
		"color": Color(0.5, 0.7, 0.9)
	}
]

# Challenge tips
const CHALLENGE_TIPS: Array[String] = [
	"A new challenge is available every day at midnight",
	"Complete consecutive days to build a streak for bonus tokens",
	"Each challenge can only be completed once per day",
	"Tokens earned can be spent in the exclusive Token Shop",
	"Token Shop items are unique and can't be found elsewhere",
	"Century Champion (100 days) awards 100 bonus tokens!"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(560, 720)

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
	title.text = "DAILY CHALLENGES"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.55, 0.0))
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
	subtitle.text = "12 rotating challenges with token rewards"
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
	footer.text = "New challenge available daily at midnight"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_daily_challenges_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Challenge types
	_build_challenges_section()

	# Streak bonuses
	_build_streaks_section()

	# Token shop
	_build_shop_section()

	# Tips
	_build_tips_section()


func _build_challenges_section() -> void:
	var section := _create_section_panel("CHALLENGE TYPES", Color(1.0, 0.55, 0.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Header row
	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 5)
	vbox.add_child(header_hbox)

	var headers := ["Challenge", "Modifier", "Goal", "Tokens"]
	var widths := [110, 160, 130, 50]
	for i in headers.size():
		var h := Label.new()
		h.text = headers[i]
		h.add_theme_font_size_override("font_size", 9)
		h.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		h.custom_minimum_size = Vector2(widths[i], 0)
		header_hbox.add_child(h)

	# Challenge rows
	for challenge in CHALLENGE_TYPES:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 5)
		vbox.add_child(row)

		var name_label := Label.new()
		name_label.text = str(challenge.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 9)
		name_label.add_theme_color_override("font_color", challenge.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(110, 0)
		row.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(challenge.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		desc_label.custom_minimum_size = Vector2(160, 0)
		row.add_child(desc_label)

		var goal_label := Label.new()
		goal_label.text = str(challenge.get("goal", ""))
		goal_label.add_theme_font_size_override("font_size", 9)
		goal_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.3))
		goal_label.custom_minimum_size = Vector2(130, 0)
		row.add_child(goal_label)

		var tokens_label := Label.new()
		tokens_label.text = str(challenge.get("tokens", 0))
		tokens_label.add_theme_font_size_override("font_size", 9)
		tokens_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		tokens_label.custom_minimum_size = Vector2(50, 0)
		row.add_child(tokens_label)


func _build_streaks_section() -> void:
	var section := _create_section_panel("STREAK BONUSES", Color(1.0, 0.84, 0.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for streak in STREAK_BONUSES:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var days_label := Label.new()
		days_label.text = "%d days" % streak.get("days", 0)
		days_label.add_theme_font_size_override("font_size", 10)
		days_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.3))
		days_label.custom_minimum_size = Vector2(70, 0)
		hbox.add_child(days_label)

		var name_label := Label.new()
		name_label.text = str(streak.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		name_label.custom_minimum_size = Vector2(150, 0)
		hbox.add_child(name_label)

		var tokens_label := Label.new()
		tokens_label.text = "+%d bonus tokens" % streak.get("tokens", 0)
		tokens_label.add_theme_font_size_override("font_size", 9)
		tokens_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(tokens_label)


func _build_shop_section() -> void:
	var section := _create_section_panel("TOKEN SHOP", Color(0.67, 0.0, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for item in TOKEN_SHOP_ITEMS:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 1)
		vbox.add_child(container)

		var header_hbox := HBoxContainer.new()
		header_hbox.add_theme_constant_override("separation", 10)
		container.add_child(header_hbox)

		var name_label := Label.new()
		name_label.text = str(item.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", item.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(150, 0)
		header_hbox.add_child(name_label)

		var cost_label := Label.new()
		cost_label.text = "%d tokens" % item.get("cost", 0)
		cost_label.add_theme_font_size_override("font_size", 9)
		cost_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		cost_label.custom_minimum_size = Vector2(70, 0)
		header_hbox.add_child(cost_label)

		var type_label := Label.new()
		type_label.text = "[%s]" % item.get("type", "")
		type_label.add_theme_font_size_override("font_size", 9)
		type_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		header_hbox.add_child(type_label)

		var effect_label := Label.new()
		effect_label.text = "  Effect: %s" % item.get("effect", "")
		effect_label.add_theme_font_size_override("font_size", 9)
		effect_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.3))
		container.add_child(effect_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("CHALLENGE TIPS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in CHALLENGE_TIPS:
		var tip_label := Label.new()
		tip_label.text = "- " + tip
		tip_label.add_theme_font_size_override("font_size", 9)
		tip_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(tip_label)


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
	vbox.add_theme_constant_override("separation", 6)
	container.add_child(vbox)

	var header := Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", color)
	vbox.add_child(header)

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
