class_name AffixReferencePanel
extends PanelContainer
## Affix Reference Panel - Shows enemy affixes and their effects.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Affix data (from SimAffixes and SimBestiary) - domain-specific colors
const AFFIX_TIERS: Array[Dictionary] = [
	{
		"tier": 1,
		"name": "Common Affixes",
		"unlock": "Always available",
		"color": Color(0.7, 0.7, 0.7),
		"affixes": [
			{"id": "swift", "name": "Swift", "glyph": "+", "effect": "+1 Speed", "description": "Moves faster than normal"},
			{"id": "armored", "name": "Armored", "glyph": "#", "effect": "+1 Armor", "description": "Additional armor plating"},
			{"id": "resilient", "name": "Resilient", "glyph": "*", "effect": "+2 HP", "description": "Extra health pool"}
		]
	},
	{
		"tier": 2,
		"name": "Uncommon Affixes",
		"unlock": "Day 4+",
		"color": Color(0.5, 0.8, 0.3),
		"affixes": [
			{"id": "shielded", "name": "Shielded", "glyph": "O", "effect": "First hit immunity", "description": "First hit is absorbed"},
			{"id": "splitting", "name": "Splitting", "glyph": "~", "effect": "Spawn on death", "description": "Spawns smaller enemies on death"},
			{"id": "regenerating", "name": "Regenerating", "glyph": "^", "effect": "Heals 1 HP/tick", "description": "Slowly heals over time"},
			{"id": "enraged", "name": "Enraged", "glyph": "!", "effect": "Speed up on damage", "description": "Speed increases when damaged"}
		]
	},
	{
		"tier": 3,
		"name": "Rare Affixes",
		"unlock": "Day 7+",
		"color": Color(0.7, 0.5, 0.9),
		"affixes": [
			{"id": "vampiric", "name": "Vampiric", "glyph": "V", "effect": "Heals on hit", "description": "Heals when dealing damage"},
			{"id": "thorny", "name": "Thorny", "glyph": "T", "effect": "Reflects 1 damage", "description": "Covered in spines that hurt attackers"},
			{"id": "ghostly", "name": "Ghostly", "glyph": "G", "effect": "50% damage reduction", "description": "Partially phased out of reality"},
			{"id": "commanding", "name": "Commanding", "glyph": "C", "effect": "Buffs nearby enemies", "description": "Empowers nearby allies"},
			{"id": "explosive", "name": "Explosive", "glyph": "X", "effect": "Damage on death", "description": "Detonates violently on death"}
		]
	}
]

# Affix general info
const AFFIX_INFO: Array[Dictionary] = [
	{
		"topic": "Affix Chance",
		"description": "Elite enemies always have affixes. Regular enemies gain chance after Day 5",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"topic": "Glyph Display",
		"description": "Affixed enemies show a special symbol next to their word",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"topic": "Counter Tactics",
		"description": "Observe the affix type and adjust your targeting priority",
		"color": Color(0.5, 0.8, 0.3)
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
	title.text = "ENEMY AFFIXES"
	DesignSystem.style_label(title, "h2", ThemeColors.ERROR)
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
	subtitle.text = "Special modifiers that enhance enemy abilities"
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
	footer.text = "Watch for glyphs next to enemy words"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_affix_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Info section
	_build_info_section()

	# Affix tiers
	for tier_data in AFFIX_TIERS:
		_build_tier_section(tier_data)


func _build_info_section() -> void:
	var section := _create_section_panel("HOW AFFIXES WORK", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in AFFIX_INFO:
		var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
		vbox.add_child(hbox)

		var topic: String = str(info.get("topic", ""))
		var description: String = str(info.get("description", ""))
		var color: Color = info.get("color", Color.WHITE)

		var topic_label := Label.new()
		topic_label.text = topic
		DesignSystem.style_label(topic_label, "caption", color)
		topic_label.custom_minimum_size = Vector2(100, 0)
		hbox.add_child(topic_label)

		var desc_label := Label.new()
		desc_label.text = description
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_tier_section(tier_data: Dictionary) -> void:
	var tier_name: String = str(tier_data.get("name", ""))
	var unlock: String = str(tier_data.get("unlock", ""))
	var color: Color = tier_data.get("color", Color.WHITE)
	var affixes: Array = tier_data.get("affixes", [])

	var section := _create_section_panel(tier_name, color)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Unlock info
	var unlock_label := Label.new()
	unlock_label.text = "Unlock: " + unlock
	DesignSystem.style_label(unlock_label, "caption", ThemeColors.RESOURCE_GOLD)
	vbox.add_child(unlock_label)

	# Affixes grid
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", DesignSystem.SPACE_MD)
	grid.add_theme_constant_override("v_separation", DesignSystem.SPACE_XS)
	vbox.add_child(grid)

	for affix in affixes:
		var affix_name: String = str(affix.get("name", ""))
		var glyph: String = str(affix.get("glyph", ""))
		var effect: String = str(affix.get("effect", ""))
		var description: String = str(affix.get("description", ""))

		# Glyph
		var glyph_label := Label.new()
		glyph_label.text = "[%s]" % glyph
		DesignSystem.style_label(glyph_label, "caption", color)
		glyph_label.custom_minimum_size = Vector2(30, 0)
		grid.add_child(glyph_label)

		# Name
		var name_label := Label.new()
		name_label.text = affix_name
		DesignSystem.style_label(name_label, "caption", color.lightened(0.2))
		name_label.custom_minimum_size = Vector2(85, 0)
		grid.add_child(name_label)

		# Effect
		var effect_label := Label.new()
		effect_label.text = effect
		DesignSystem.style_label(effect_label, "caption", Color(0.9, 0.6, 0.3))
		effect_label.custom_minimum_size = Vector2(110, 0)
		grid.add_child(effect_label)

		# Description
		var desc_label := Label.new()
		desc_label.text = description
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
		grid.add_child(desc_label)


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
