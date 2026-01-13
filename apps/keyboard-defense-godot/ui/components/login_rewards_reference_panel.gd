class_name LoginRewardsReferencePanel
extends PanelContainer
## Login Rewards Reference Panel - Shows daily login rewards and bonuses.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

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
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_MD, 620)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "LOGIN REWARDS"
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
	subtitle.text = "Daily login rewards and streak bonuses"
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

	# Footer
	var footer := Label.new()
	footer.text = "Keep your streak alive for maximum rewards!"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


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
	var section := _create_section_panel("REWARD TIERS", ThemeColors.RESOURCE_GOLD)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tier in REWARD_TIERS:
		var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
		vbox.add_child(hbox)

		var day_label := Label.new()
		day_label.text = "Day %d" % tier.get("day", 0)
		DesignSystem.style_label(day_label, "caption", ThemeColors.INFO)
		day_label.custom_minimum_size = Vector2(50, 0)
		hbox.add_child(day_label)

		var gold_label := Label.new()
		gold_label.text = "+%d gold" % tier.get("gold", 0)
		DesignSystem.style_label(gold_label, "caption", ThemeColors.RESOURCE_GOLD)
		gold_label.custom_minimum_size = Vector2(70, 0)
		hbox.add_child(gold_label)

		var bonus: String = str(tier.get("bonus", ""))
		var bonus_label := Label.new()
		if bonus.is_empty():
			bonus_label.text = "-"
			DesignSystem.style_label(bonus_label, "caption", Color(0.4, 0.4, 0.4))
		else:
			bonus_label.text = _get_bonus_name(bonus)
			DesignSystem.style_label(bonus_label, "caption", _get_bonus_color(bonus))
		bonus_label.custom_minimum_size = Vector2(100, 0)
		hbox.add_child(bonus_label)

		var desc_label := Label.new()
		desc_label.text = str(tier.get("desc", ""))
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_bonuses_section() -> void:
	var section := _create_section_panel("BONUS ITEMS", Color(0.8, 0.6, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for bonus in BONUS_ITEMS:
		var container := DesignSystem.create_vbox(2)
		vbox.add_child(container)

		var header_hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
		container.add_child(header_hbox)

		var name_label := Label.new()
		name_label.text = str(bonus.get("name", ""))
		DesignSystem.style_label(name_label, "caption", bonus.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(100, 0)
		header_hbox.add_child(name_label)

		var unlock_label := Label.new()
		unlock_label.text = "Day %d+" % bonus.get("unlock_day", 0)
		DesignSystem.style_label(unlock_label, "caption", ThemeColors.SUCCESS)
		unlock_label.custom_minimum_size = Vector2(55, 0)
		header_hbox.add_child(unlock_label)

		var duration_label := Label.new()
		duration_label.text = str(bonus.get("duration", ""))
		DesignSystem.style_label(duration_label, "caption", Color(0.5, 0.5, 0.7))
		header_hbox.add_child(duration_label)

		var desc_label := Label.new()
		desc_label.text = "  " + str(bonus.get("desc", ""))
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		container.add_child(desc_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("LOGIN TIPS", ThemeColors.SUCCESS)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in LOGIN_TIPS:
		var tip_label := Label.new()
		tip_label.text = "- " + tip
		DesignSystem.style_label(tip_label, "caption", ThemeColors.TEXT_DIM)
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
	panel_style.set_corner_radius_all(DesignSystem.RADIUS_SM)
	panel_style.set_content_margin_all(DesignSystem.SPACE_MD)
	container.add_theme_stylebox_override("panel", panel_style)

	var vbox := DesignSystem.create_vbox(DesignSystem.SPACE_SM)
	container.add_child(vbox)

	var header := Label.new()
	header.text = title
	DesignSystem.style_label(header, "body_small", color)
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
