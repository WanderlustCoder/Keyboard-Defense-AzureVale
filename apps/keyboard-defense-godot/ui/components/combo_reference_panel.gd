class_name ComboReferencePanel
extends PanelContainer
## Combo Reference Panel - Shows combo tiers, bonuses, and mechanics.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Combo tiers (from SimCombo) - domain-specific colors
const COMBO_TIERS: Array[Dictionary] = [
	{"tier": 1, "name": "Warming Up", "min_combo": 3, "damage_bonus": 5, "gold_bonus": 5, "color": "#90EE90"},
	{"tier": 2, "name": "On Fire", "min_combo": 5, "damage_bonus": 10, "gold_bonus": 10, "color": "#FFD700"},
	{"tier": 3, "name": "Blazing", "min_combo": 10, "damage_bonus": 20, "gold_bonus": 15, "color": "#FF8C00"},
	{"tier": 4, "name": "Inferno", "min_combo": 25, "damage_bonus": 35, "gold_bonus": 25, "color": "#FF4500"},
	{"tier": 5, "name": "Legendary", "min_combo": 50, "damage_bonus": 50, "gold_bonus": 40, "color": "#FF00FF"},
	{"tier": 6, "name": "Mythic", "min_combo": 100, "damage_bonus": 75, "gold_bonus": 60, "color": "#00FFFF"},
	{"tier": 7, "name": "GODLIKE", "min_combo": 200, "damage_bonus": 100, "gold_bonus": 100, "color": "#FFFFFF"}
]

# Combo mechanics info
const COMBO_MECHANICS: Array[Dictionary] = [
	{
		"topic": "Building Combo",
		"description": "Each word typed correctly increases combo by 1",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"topic": "Breaking Combo",
		"description": "Mistyping or letting an enemy reach the castle resets combo",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"topic": "Damage Bonus",
		"description": "Higher combo = more damage per hit",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"topic": "Gold Bonus",
		"description": "Higher combo = more gold from kills",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"topic": "Tier Announcements",
		"description": "Screen flashes and announces when reaching new tiers",
		"color": Color(0.7, 0.5, 0.9)
	}
]

# Combo tips
const COMBO_TIPS: Array[Dictionary] = [
	{
		"tip": "Focus on accuracy over speed to maintain combo",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"tip": "Use the COMBO special command to instantly gain +10 combo",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"tip": "Quick Recovery skill can save your combo from mistakes",
		"color": Color(0.7, 0.5, 0.9)
	},
	{
		"tip": "High combo is essential for defeating bosses quickly",
		"color": Color(0.9, 0.6, 0.3)
	}
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_MD, 600)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "COMBO SYSTEM"
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
	subtitle.text = "Chain kills for massive damage and gold bonuses"
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
	footer.text = "Keep typing accurately to maintain your combo!"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_combo_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Mechanics section
	_build_mechanics_section()

	# Tiers section
	_build_tiers_section()

	# Tips section
	_build_tips_section()


func _build_mechanics_section() -> void:
	var section := _create_section_panel("HOW COMBO WORKS", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in COMBO_MECHANICS:
		var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
		vbox.add_child(hbox)

		var topic: String = str(info.get("topic", ""))
		var description: String = str(info.get("description", ""))
		var color: Color = info.get("color", Color.WHITE)

		var topic_label := Label.new()
		topic_label.text = topic
		DesignSystem.style_label(topic_label, "caption", color)
		topic_label.custom_minimum_size = Vector2(120, 0)
		hbox.add_child(topic_label)

		var desc_label := Label.new()
		desc_label.text = description
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_tiers_section() -> void:
	var section := _create_section_panel("COMBO TIERS", ThemeColors.RESOURCE_GOLD)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Header row
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	vbox.add_child(header)

	var h_name := Label.new()
	h_name.text = "Tier"
	DesignSystem.style_label(h_name, "caption", ThemeColors.TEXT_DIM)
	h_name.custom_minimum_size = Vector2(90, 0)
	header.add_child(h_name)

	var h_combo := Label.new()
	h_combo.text = "Combo"
	DesignSystem.style_label(h_combo, "caption", ThemeColors.TEXT_DIM)
	h_combo.custom_minimum_size = Vector2(60, 0)
	header.add_child(h_combo)

	var h_dmg := Label.new()
	h_dmg.text = "Damage"
	DesignSystem.style_label(h_dmg, "caption", ThemeColors.TEXT_DIM)
	h_dmg.custom_minimum_size = Vector2(60, 0)
	header.add_child(h_dmg)

	var h_gold := Label.new()
	h_gold.text = "Gold"
	DesignSystem.style_label(h_gold, "caption", ThemeColors.TEXT_DIM)
	header.add_child(h_gold)

	# Tier rows
	for tier in COMBO_TIERS:
		var row := _create_tier_row(tier)
		vbox.add_child(row)


func _create_tier_row(tier: Dictionary) -> Control:
	var tier_name: String = str(tier.get("name", ""))
	var min_combo: int = int(tier.get("min_combo", 0))
	var damage_bonus: int = int(tier.get("damage_bonus", 0))
	var gold_bonus: int = int(tier.get("gold_bonus", 0))
	var color: Color = Color.from_string(str(tier.get("color", "#FFFFFF")), Color.WHITE)

	var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)

	var name_label := Label.new()
	name_label.text = tier_name
	DesignSystem.style_label(name_label, "caption", color)
	name_label.custom_minimum_size = Vector2(90, 0)
	hbox.add_child(name_label)

	var combo_label := Label.new()
	combo_label.text = "x%d+" % min_combo
	DesignSystem.style_label(combo_label, "caption", ThemeColors.INFO)
	combo_label.custom_minimum_size = Vector2(60, 0)
	hbox.add_child(combo_label)

	var dmg_label := Label.new()
	dmg_label.text = "+%d%%" % damage_bonus
	DesignSystem.style_label(dmg_label, "caption", ThemeColors.ERROR)
	dmg_label.custom_minimum_size = Vector2(60, 0)
	hbox.add_child(dmg_label)

	var gold_label := Label.new()
	gold_label.text = "+%d%%" % gold_bonus
	DesignSystem.style_label(gold_label, "caption", ThemeColors.RESOURCE_GOLD)
	hbox.add_child(gold_label)

	return hbox


func _build_tips_section() -> void:
	var section := _create_section_panel("COMBO TIPS", ThemeColors.INFO)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip_info in COMBO_TIPS:
		var tip: String = str(tip_info.get("tip", ""))
		var color: Color = tip_info.get("color", Color.WHITE)

		var tip_label := Label.new()
		tip_label.text = "- " + tip
		DesignSystem.style_label(tip_label, "caption", color)
		tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(tip_label)


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
