class_name BestiaryReferencePanel
extends PanelContainer
## Bestiary Reference Panel - Shows enemy types, stats, and tactics.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Enemy categories (from SimBestiary) - domain-specific colors
const ENEMY_CATEGORIES: Array[Dictionary] = [
	{
		"category": "common",
		"name": "Common Enemies",
		"color": Color(0.7, 0.7, 0.7),
		"description": "Standard foes that form the bulk of enemy forces",
		"enemies": [
			{"id": "raider", "name": "Raider", "threat": 1, "tactics": "Basic enemy. Build combo quickly.", "weakness": "No armor"},
			{"id": "scout", "name": "Scout", "threat": 2, "tactics": "Fast but fragile. Prioritize!", "weakness": "Low HP"},
			{"id": "armored", "name": "Armored", "threat": 2, "tactics": "Armor reduces damage. Build combo.", "weakness": "Slow"},
			{"id": "swarm", "name": "Swarm", "threat": 2, "tactics": "Type quickly to clear.", "weakness": "Minimal HP"}
		]
	},
	{
		"category": "uncommon",
		"name": "Uncommon Enemies",
		"color": Color(0.5, 0.8, 0.3),
		"description": "Dangerous foes with special abilities",
		"enemies": [
			{"id": "tank", "name": "Tank", "threat": 3, "tactics": "High armor/HP. Focus strongest attacks.", "weakness": "Extremely slow"},
			{"id": "berserker", "name": "Berserker", "threat": 3, "tactics": "Fast, moderate HP. Kill quickly.", "weakness": "No armor"},
			{"id": "phantom", "name": "Phantom", "threat": 3, "tactics": "50% first hit evade. Follow up!", "weakness": "Vulnerable after evade"}
		]
	},
	{
		"category": "rare",
		"name": "Rare Enemies",
		"color": Color(0.4, 0.8, 1.0),
		"description": "Elite foes that pose significant threats",
		"enemies": [
			{"id": "champion", "name": "Champion", "threat": 4, "tactics": "Tough all-rounder. Prioritize if close.", "weakness": "No special gimmicks"},
			{"id": "healer", "name": "Healer", "threat": 4, "tactics": "Heals others. Target FIRST!", "weakness": "Fragile"},
			{"id": "elite", "name": "Elite", "threat": 5, "tactics": "Random affix. Adapt strategy!", "weakness": "Depends on affix"}
		]
	}
]

# Boss info (from SimBestiary) - domain-specific colors
const BOSSES: Array[Dictionary] = [
	{
		"id": "forest_guardian",
		"name": "Forest Guardian",
		"region": "Evergrove",
		"day": 5,
		"threat": 7,
		"tactics": "Regenerates HP. Hit hard and fast!",
		"weakness": "Slow movement",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"id": "stone_golem",
		"name": "Stone Golem",
		"region": "Stonepass",
		"day": 10,
		"threat": 8,
		"tactics": "Extreme armor. Max combo attacks only.",
		"weakness": "Very slow",
		"color": Color(0.6, 0.6, 0.7)
	},
	{
		"id": "fen_seer",
		"name": "Fen Seer",
		"region": "Mistfen",
		"day": 15,
		"threat": 8,
		"tactics": "Summons adds, evades. Clear adds first.",
		"weakness": "Moderate HP",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"id": "sunlord",
		"name": "Sunlord",
		"region": "Sunfields",
		"day": 20,
		"threat": 9,
		"tactics": "Enrages over time. End fight quickly!",
		"weakness": "Less armored",
		"color": Color(1.0, 0.84, 0.0)
	}
]

# Threat level info
const THREAT_INFO: Array[Dictionary] = [
	{
		"level": "1-2",
		"name": "Low",
		"description": "Standard threats, easily manageable",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"level": "3-4",
		"name": "Medium",
		"description": "Requires attention and proper targeting",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"level": "5+",
		"name": "High",
		"description": "Dangerous - prioritize or use special abilities",
		"color": Color(0.9, 0.4, 0.4)
	}
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 680)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "ENEMY BESTIARY"
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
	subtitle.text = "Know your enemies - their strengths and weaknesses"
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
	footer.text = "Defeat enemies to unlock their bestiary entries"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_bestiary() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Threat level info
	_build_threat_section()

	# Enemy categories
	for cat_data in ENEMY_CATEGORIES:
		_build_category_section(cat_data)

	# Bosses section
	_build_boss_section()


func _build_threat_section() -> void:
	var section := _create_section_panel("THREAT LEVELS", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in THREAT_INFO:
		var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
		vbox.add_child(hbox)

		var level: String = str(info.get("level", ""))
		var name_str: String = str(info.get("name", ""))
		var description: String = str(info.get("description", ""))
		var color: Color = info.get("color", Color.WHITE)

		var level_label := Label.new()
		level_label.text = level
		DesignSystem.style_label(level_label, "caption", color)
		level_label.custom_minimum_size = Vector2(35, 0)
		hbox.add_child(level_label)

		var name_label := Label.new()
		name_label.text = name_str
		DesignSystem.style_label(name_label, "caption", color)
		name_label.custom_minimum_size = Vector2(60, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = description
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_category_section(cat_data: Dictionary) -> void:
	var cat_name: String = str(cat_data.get("name", ""))
	var description: String = str(cat_data.get("description", ""))
	var color: Color = cat_data.get("color", Color.WHITE)
	var enemies: Array = cat_data.get("enemies", [])

	var section := _create_section_panel(cat_name, color)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Description
	var desc_label := Label.new()
	desc_label.text = description
	DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
	vbox.add_child(desc_label)

	# Enemies grid
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", DesignSystem.SPACE_SM)
	grid.add_theme_constant_override("v_separation", DesignSystem.SPACE_XS)
	vbox.add_child(grid)

	for enemy in enemies:
		var enemy_name: String = str(enemy.get("name", ""))
		var threat: int = int(enemy.get("threat", 1))
		var tactics: String = str(enemy.get("tactics", ""))
		var weakness: String = str(enemy.get("weakness", ""))

		# Name
		var name_label := Label.new()
		name_label.text = enemy_name
		DesignSystem.style_label(name_label, "caption", color)
		name_label.custom_minimum_size = Vector2(70, 0)
		grid.add_child(name_label)

		# Threat
		var threat_label := Label.new()
		threat_label.text = "*".repeat(threat)
		DesignSystem.style_label(threat_label, "caption", _get_threat_color(threat))
		threat_label.custom_minimum_size = Vector2(45, 0)
		grid.add_child(threat_label)

		# Tactics
		var tactics_label := Label.new()
		tactics_label.text = tactics
		DesignSystem.style_label(tactics_label, "caption", ThemeColors.INFO)
		tactics_label.custom_minimum_size = Vector2(180, 0)
		grid.add_child(tactics_label)

		# Weakness
		var weakness_label := Label.new()
		weakness_label.text = weakness
		DesignSystem.style_label(weakness_label, "caption", ThemeColors.SUCCESS)
		grid.add_child(weakness_label)


func _build_boss_section() -> void:
	var section := _create_section_panel("BOSSES", Color(0.7, 0.5, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for boss in BOSSES:
		var card := _create_boss_card(boss)
		vbox.add_child(card)


func _create_boss_card(boss: Dictionary) -> Control:
	var boss_name: String = str(boss.get("name", ""))
	var region: String = str(boss.get("region", ""))
	var day: int = int(boss.get("day", 0))
	var threat: int = int(boss.get("threat", 5))
	var tactics: String = str(boss.get("tactics", ""))
	var weakness: String = str(boss.get("weakness", ""))
	var color: Color = boss.get("color", Color.WHITE)

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = color.darkened(0.85)
	container_style.border_color = color.darkened(0.6)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(DesignSystem.RADIUS_XS)
	container_style.set_content_margin_all(DesignSystem.SPACE_SM)
	container.add_theme_stylebox_override("panel", container_style)

	var main_vbox := DesignSystem.create_vbox(2)
	container.add_child(main_vbox)

	# Header row
	var header_hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header_hbox)

	var name_label := Label.new()
	name_label.text = boss_name
	DesignSystem.style_label(name_label, "caption", color)
	header_hbox.add_child(name_label)

	header_hbox.add_child(DesignSystem.create_spacer())

	var region_label := Label.new()
	region_label.text = "%s (Day %d)" % [region, day]
	DesignSystem.style_label(region_label, "caption", ThemeColors.RESOURCE_GOLD)
	header_hbox.add_child(region_label)

	var threat_label := Label.new()
	threat_label.text = " " + "*".repeat(threat)
	DesignSystem.style_label(threat_label, "caption", ThemeColors.ERROR)
	header_hbox.add_child(threat_label)

	# Info row
	var info_hbox := DesignSystem.create_hbox(DesignSystem.SPACE_LG)
	main_vbox.add_child(info_hbox)

	var tactics_label := Label.new()
	tactics_label.text = tactics
	DesignSystem.style_label(tactics_label, "caption", ThemeColors.INFO)
	info_hbox.add_child(tactics_label)

	var weakness_label := Label.new()
	weakness_label.text = "Weakness: " + weakness
	DesignSystem.style_label(weakness_label, "caption", ThemeColors.SUCCESS)
	info_hbox.add_child(weakness_label)

	return container


func _get_threat_color(threat: int) -> Color:
	if threat <= 2:
		return ThemeColors.SUCCESS
	elif threat <= 4:
		return ThemeColors.RESOURCE_GOLD
	else:
		return ThemeColors.ERROR


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
