class_name LootQualityPanel
extends PanelContainer
## Loot Quality Panel - Shows how typing performance affects loot drops.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Quality tier data (from SimLoot)
const QUALITY_TIERS: Array[Dictionary] = [
	{
		"tier": "Perfect",
		"accuracy_range": "99%+",
		"multiplier": 2.0,
		"color": Color(1.0, 0.84, 0.0),
		"description": "Flawless typing with no mistakes",
		"bonus": "Perfect kill bonus drops"
	},
	{
		"tier": "Excellent",
		"accuracy_range": "95-99%",
		"multiplier": 1.5,
		"color": Color(0.7, 0.5, 0.9),
		"description": "Near-perfect accuracy",
		"bonus": "None"
	},
	{
		"tier": "Good",
		"accuracy_range": "85-95%",
		"multiplier": 1.25,
		"color": Color(0.4, 0.8, 1.0),
		"description": "Solid performance with few errors",
		"bonus": "None"
	},
	{
		"tier": "Normal",
		"accuracy_range": "60-85%",
		"multiplier": 1.0,
		"color": Color(0.5, 0.8, 0.3),
		"description": "Standard loot quality",
		"bonus": "None"
	},
	{
		"tier": "Poor",
		"accuracy_range": "<60%",
		"multiplier": 0.5,
		"color": Color(0.6, 0.6, 0.6),
		"description": "Reduced loot due to many mistakes",
		"bonus": "None"
	}
]

# Loot system info
const LOOT_INFO: Array[Dictionary] = [
	{
		"topic": "Guaranteed Drops",
		"description": "Some enemies always drop specific resources",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"topic": "Chance Drops",
		"description": "Random chance to drop additional items",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"topic": "Boss Loot",
		"description": "Bosses have special loot tables with rare items",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"topic": "Perfect Bonus",
		"description": "Extra drops for 100% accuracy kills",
		"color": Color(1.0, 0.84, 0.0)
	}
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 560)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "LOOT QUALITY"
	DesignSystem.style_label(title, "h2", Color(1.0, 0.84, 0.0))
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
	subtitle.text = "Better typing accuracy = better loot drops"
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
	footer.text = "Quality multiplier applies to all drop amounts"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_loot_quality() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Quality tiers section
	_build_tiers_section()

	# Loot info section
	_build_info_section()


func _build_tiers_section() -> void:
	var section := _create_section_panel("QUALITY TIERS", Color(1.0, 0.84, 0.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tier in QUALITY_TIERS:
		var card := _create_tier_card(tier)
		vbox.add_child(card)


func _create_tier_card(tier: Dictionary) -> Control:
	var tier_name: String = str(tier.get("tier", ""))
	var accuracy: String = str(tier.get("accuracy_range", ""))
	var multiplier: float = float(tier.get("multiplier", 1.0))
	var description: String = str(tier.get("description", ""))
	var bonus: String = str(tier.get("bonus", "None"))
	var color: Color = tier.get("color", Color.WHITE)

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = color.darkened(0.85)
	container_style.border_color = color.darkened(0.6)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(8)
	container.add_theme_stylebox_override("panel", container_style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 3)
	container.add_child(main_vbox)

	# Header row
	var header_hbox := HBoxContainer.new()
	main_vbox.add_child(header_hbox)

	var name_label := Label.new()
	name_label.text = tier_name
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", color)
	header_hbox.add_child(name_label)

	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(header_spacer)

	var mult_label := Label.new()
	mult_label.text = "x%.1f Loot" % multiplier
	mult_label.add_theme_font_size_override("font_size", 10)
	mult_label.add_theme_color_override("font_color", color)
	header_hbox.add_child(mult_label)

	# Stats row
	var stats_hbox := HBoxContainer.new()
	stats_hbox.add_theme_constant_override("separation", 15)
	main_vbox.add_child(stats_hbox)

	var acc_label := Label.new()
	acc_label.text = "Accuracy: " + accuracy
	acc_label.add_theme_font_size_override("font_size", 9)
	acc_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.3))
	stats_hbox.add_child(acc_label)

	if bonus != "None":
		var bonus_label := Label.new()
		bonus_label.text = "Bonus: " + bonus
		bonus_label.add_theme_font_size_override("font_size", 9)
		bonus_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		stats_hbox.add_child(bonus_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 9)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	main_vbox.add_child(desc_label)

	return container


func _build_info_section() -> void:
	var section := _create_section_panel("LOOT MECHANICS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in LOOT_INFO:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var topic: String = str(info.get("topic", ""))
		var description: String = str(info.get("description", ""))
		var color: Color = info.get("color", Color.WHITE)

		var topic_label := Label.new()
		topic_label.text = topic
		topic_label.add_theme_font_size_override("font_size", 10)
		topic_label.add_theme_color_override("font_color", color)
		topic_label.custom_minimum_size = Vector2(120, 0)
		hbox.add_child(topic_label)

		var desc_label := Label.new()
		desc_label.text = description
		desc_label.add_theme_font_size_override("font_size", 10)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


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
