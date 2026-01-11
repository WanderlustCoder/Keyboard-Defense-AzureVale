class_name LoginRewardsReferencePanel
extends PanelContainer
## Login Rewards Reference Panel - Shows daily login rewards and bonuses

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Reward tiers
const REWARD_TIERS: Array[Dictionary] = [
	{"day": 1, "gold": 10, "bonus": "", "desc": "Welcome back!"},
	{"day": 2, "gold": 15, "bonus": "", "desc": "Keep it going!"},
	{"day": 3, "gold": 20, "bonus": "power_boost", "desc": "First bonus unlock"},
	{"day": 4, "gold": 25, "bonus": "", "desc": "Building momentum"},
	{"day": 5, "gold": 30, "bonus": "", "desc": "Halfway to week 1"},
	{"day": 6, "gold": 40, "bonus": "accuracy_boost", "desc": "Almost there!"},
	{"day": 7, "gold": 50, "bonus": "xp_boost", "desc": "Full week!"},
	{"day": 14, "gold": 75, "bonus": "combo_boost", "desc": "Two weeks strong"},
	{"day": 21, "gold": 100, "bonus": "gold_boost", "desc": "Three week hero"},
	{"day": 30, "gold": 150, "bonus": "mega_boost", "desc": "Monthly master"}
]

# Bonus items
const BONUS_ITEMS: Array[Dictionary] = [
	{
		"id": "power_boost",
		"name": "Power Boost",
		"desc": "10% increased typing power for 3 battles",
		"icon": "lightning",
		"duration": "3 battles",
		"unlock_day": 3,
		"color": Color(1.0, 0.8, 0.2)
	},
	{
		"id": "accuracy_boost",
		"name": "Accuracy Boost",
		"desc": "5% mistake forgiveness for 3 battles",
		"icon": "shield",
		"duration": "3 battles",
		"unlock_day": 6,
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"id": "xp_boost",
		"name": "XP Boost",
		"desc": "20% bonus gold for 5 battles",
		"icon": "star",
		"duration": "5 battles",
		"unlock_day": 7,
		"color": Color(0.8, 0.6, 1.0)
	},
	{
		"id": "combo_boost",
		"name": "Combo Boost",
		"desc": "Combos charge 20% faster for 3 battles",
		"icon": "flame",
		"duration": "3 battles",
		"unlock_day": 14,
		"color": Color(1.0, 0.5, 0.2)
	},
	{
		"id": "gold_boost",
		"name": "Gold Rush",
		"desc": "50% bonus gold for 3 battles",
		"icon": "crown",
		"duration": "3 battles",
		"unlock_day": 21,
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"id": "mega_boost",
		"name": "Mega Boost",
		"desc": "All stats +10% for 5 battles",
		"icon": "crown",
		"duration": "5 battles",
		"unlock_day": 30,
		"color": Color(0.8, 0.2, 0.8)
	}
]

# Tips
const LOGIN_TIPS: Array[String] = [
	"Log in daily to maintain your streak and earn better rewards",
	"Bonuses stack if you have multiple active at once",
	"Missing a day resets your streak back to Day 1",
	"The Mega Boost at Day 30 gives the best overall bonus",
	"Bonus effects activate at the start of your next battle"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(500, 620)

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
	title.text = "LOGIN REWARDS"
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
	subtitle.text = "Daily login rewards and streak bonuses"
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
	footer.text = "Keep your streak alive for maximum rewards!"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_login_rewards_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Reward tiers
	_build_tiers_section()

	# Bonus items
	_build_bonuses_section()

	# Tips
	_build_tips_section()


func _build_tiers_section() -> void:
	var section := _create_section_panel("REWARD TIERS", Color(1.0, 0.84, 0.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tier in REWARD_TIERS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var day_label := Label.new()
		day_label.text = "Day %d" % tier.get("day", 0)
		day_label.add_theme_font_size_override("font_size", 10)
		day_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
		day_label.custom_minimum_size = Vector2(50, 0)
		hbox.add_child(day_label)

		var gold_label := Label.new()
		gold_label.text = "+%d gold" % tier.get("gold", 0)
		gold_label.add_theme_font_size_override("font_size", 10)
		gold_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		gold_label.custom_minimum_size = Vector2(70, 0)
		hbox.add_child(gold_label)

		var bonus: String = str(tier.get("bonus", ""))
		var bonus_label := Label.new()
		if bonus.is_empty():
			bonus_label.text = "-"
			bonus_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			bonus_label.text = _get_bonus_name(bonus)
			bonus_label.add_theme_color_override("font_color", _get_bonus_color(bonus))
		bonus_label.add_theme_font_size_override("font_size", 10)
		bonus_label.custom_minimum_size = Vector2(100, 0)
		hbox.add_child(bonus_label)

		var desc_label := Label.new()
		desc_label.text = str(tier.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_bonuses_section() -> void:
	var section := _create_section_panel("BONUS ITEMS", Color(0.8, 0.6, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for bonus in BONUS_ITEMS:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 2)
		vbox.add_child(container)

		var header_hbox := HBoxContainer.new()
		header_hbox.add_theme_constant_override("separation", 10)
		container.add_child(header_hbox)

		var name_label := Label.new()
		name_label.text = str(bonus.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", bonus.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(100, 0)
		header_hbox.add_child(name_label)

		var unlock_label := Label.new()
		unlock_label.text = "Day %d+" % bonus.get("unlock_day", 0)
		unlock_label.add_theme_font_size_override("font_size", 9)
		unlock_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5))
		unlock_label.custom_minimum_size = Vector2(55, 0)
		header_hbox.add_child(unlock_label)

		var duration_label := Label.new()
		duration_label.text = str(bonus.get("duration", ""))
		duration_label.add_theme_font_size_override("font_size", 9)
		duration_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.7))
		header_hbox.add_child(duration_label)

		var desc_label := Label.new()
		desc_label.text = "  " + str(bonus.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		container.add_child(desc_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("LOGIN TIPS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in LOGIN_TIPS:
		var tip_label := Label.new()
		tip_label.text = "- " + tip
		tip_label.add_theme_font_size_override("font_size", 9)
		tip_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(tip_label)


func _get_bonus_name(bonus_id: String) -> String:
	for bonus in BONUS_ITEMS:
		if bonus.get("id", "") == bonus_id:
			return str(bonus.get("name", bonus_id))
	return bonus_id


func _get_bonus_color(bonus_id: String) -> Color:
	for bonus in BONUS_ITEMS:
		if bonus.get("id", "") == bonus_id:
			return bonus.get("color", Color.WHITE)
	return Color.WHITE


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
