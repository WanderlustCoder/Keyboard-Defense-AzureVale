class_name TowerReferencePanel
extends PanelContainer
## Tower Reference Panel - Shows tower types, stats, and abilities.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Tower categories (from SimTowerTypes) - domain-specific colors
const TOWER_CATEGORIES: Array[Dictionary] = [
	{
		"category": "basic",
		"name": "Basic Towers",
		"unlock": "Tutorial",
		"color": Color(0.7, 0.7, 0.7),
		"towers": [
			{"id": "tower_arrow", "name": "Arrow Tower", "damage": 10, "damage_type": "Physical", "ability": "Standard ranged attack", "cost": "4W 8S"},
			{"id": "tower_magic", "name": "Magic Tower", "damage": 15, "damage_type": "Magical", "ability": "Ignores armor", "cost": "6W 10S 10G"},
			{"id": "tower_frost", "name": "Frost Tower", "damage": 5, "damage_type": "Cold", "ability": "Slows enemies 25%", "cost": "5W 8S"},
			{"id": "tower_cannon", "name": "Cannon Tower", "damage": 25, "damage_type": "Physical", "ability": "Area damage (2x2)", "cost": "8W 15S 15G"}
		]
	},
	{
		"category": "advanced",
		"name": "Advanced Towers",
		"unlock": "Level 10",
		"color": Color(0.5, 0.8, 0.3),
		"towers": [
			{"id": "tower_multi", "name": "Multi-Shot", "damage": 8, "damage_type": "Physical", "ability": "Hits 3 targets", "cost": "10W 12S 20G"},
			{"id": "tower_arcane", "name": "Arcane Tower", "damage": 20, "damage_type": "Magical", "ability": "Chains to 3 enemies", "cost": "8W 15S 30G"},
			{"id": "tower_holy", "name": "Holy Tower", "damage": 18, "damage_type": "Holy", "ability": "+50% vs affixed", "cost": "10W 20S 25G"},
			{"id": "tower_siege", "name": "Siege Tower", "damage": 40, "damage_type": "Physical", "ability": "Huge AOE, slow fire (3x3)", "cost": "15W 25S 40G"}
		]
	},
	{
		"category": "specialist",
		"name": "Specialist Towers",
		"unlock": "Level 18",
		"color": Color(0.4, 0.8, 1.0),
		"towers": [
			{"id": "tower_poison", "name": "Poison Tower", "damage": 3, "damage_type": "Poison", "ability": "Stacking DoT, 10 stacks max", "cost": "12W 15S 35G"},
			{"id": "tower_tesla", "name": "Tesla Tower", "damage": 12, "damage_type": "Lightning", "ability": "Chains, +dmg vs wet", "cost": "10W 20S 45G"},
			{"id": "tower_summoner", "name": "Summoner", "damage": 0, "damage_type": "None", "ability": "Spawns allied units (2x2)", "cost": "15W 20S 50G"},
			{"id": "tower_support", "name": "Support Tower", "damage": 0, "damage_type": "None", "ability": "Buffs nearby towers +25%", "cost": "8W 15S 40G"},
			{"id": "tower_trap", "name": "Trap Layer", "damage": 15, "damage_type": "Physical", "ability": "Places triggered traps", "cost": "10W 10S 30G"}
		]
	},
	{
		"category": "legendary",
		"name": "Legendary Towers",
		"unlock": "Quest/Achievement",
		"color": Color(0.7, 0.5, 0.9),
		"towers": [
			{"id": "tower_wordsmith", "name": "Wordsmith", "damage": 30, "damage_type": "Pure", "ability": "Bonus dmg per letter typed (2x2)", "cost": "25W 30S 100G"},
			{"id": "tower_shrine", "name": "Shrine", "damage": 0, "damage_type": "None", "ability": "Global aura: all towers +15% (3x3)", "cost": "30W 40S 150G"},
			{"id": "tower_purifier", "name": "Purifier", "damage": 25, "damage_type": "Holy", "ability": "Removes affixes, +100% vs corrupted (2x2)", "cost": "20W 35S 120G"}
		]
	}
]

# Damage type info - domain-specific colors
const DAMAGE_TYPES: Array[Dictionary] = [
	{"type": "Physical", "description": "Reduced by armor", "color": Color(0.7, 0.7, 0.7)},
	{"type": "Magical", "description": "Ignores armor", "color": Color(0.4, 0.8, 1.0)},
	{"type": "Cold", "description": "Slows, reduced damage", "color": Color(0.5, 0.8, 1.0)},
	{"type": "Poison", "description": "DoT, stacks, ignores 50% armor", "color": Color(0.6, 0.2, 0.8)},
	{"type": "Lightning", "description": "Chains, bonus vs wet", "color": Color(1.0, 1.0, 0.3)},
	{"type": "Holy", "description": "Bonus vs affixed/corrupted", "color": Color(1.0, 0.84, 0.0)},
	{"type": "Fire", "description": "DoT, bonus vs frozen", "color": Color(0.9, 0.4, 0.2)},
	{"type": "Pure", "description": "Ignores all resistances", "color": Color(1.0, 1.0, 1.0)}
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
	title.text = "TOWER REFERENCE"
	DesignSystem.style_label(title, "h2", ThemeColors.INFO)
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
	subtitle.text = "Defense towers - build strategically to maximize effectiveness"
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
	footer.text = "Type 'build <tower>' during planning phase"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_tower_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Damage types section
	_build_damage_types_section()

	# Tower categories
	for cat_data in TOWER_CATEGORIES:
		_build_category_section(cat_data)


func _build_damage_types_section() -> void:
	var section := _create_section_panel("DAMAGE TYPES", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", DesignSystem.SPACE_LG)
	grid.add_theme_constant_override("v_separation", 2)
	vbox.add_child(grid)

	for dt in DAMAGE_TYPES:
		var type_name: String = str(dt.get("type", ""))
		var description: String = str(dt.get("description", ""))
		var color: Color = dt.get("color", Color.WHITE)

		var name_label := Label.new()
		name_label.text = type_name
		DesignSystem.style_label(name_label, "caption", color)
		name_label.custom_minimum_size = Vector2(70, 0)
		grid.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = description
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
		grid.add_child(desc_label)


func _build_category_section(cat_data: Dictionary) -> void:
	var cat_name: String = str(cat_data.get("name", ""))
	var unlock: String = str(cat_data.get("unlock", ""))
	var color: Color = cat_data.get("color", Color.WHITE)
	var towers: Array = cat_data.get("towers", [])

	var section := _create_section_panel(cat_name, color)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Unlock info
	var unlock_label := Label.new()
	unlock_label.text = "Unlock: " + unlock
	DesignSystem.style_label(unlock_label, "caption", ThemeColors.RESOURCE_GOLD)
	vbox.add_child(unlock_label)

	# Towers grid
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", DesignSystem.SPACE_SM)
	grid.add_theme_constant_override("v_separation", DesignSystem.SPACE_XS)
	vbox.add_child(grid)

	for tower in towers:
		var tower_name: String = str(tower.get("name", ""))
		var damage: int = int(tower.get("damage", 0))
		var damage_type: String = str(tower.get("damage_type", ""))
		var ability: String = str(tower.get("ability", ""))
		var cost: String = str(tower.get("cost", ""))

		# Name
		var name_label := Label.new()
		name_label.text = tower_name
		DesignSystem.style_label(name_label, "caption", color)
		name_label.custom_minimum_size = Vector2(85, 0)
		grid.add_child(name_label)

		# Damage
		var dmg_label := Label.new()
		dmg_label.text = str(damage) if damage > 0 else "-"
		DesignSystem.style_label(dmg_label, "caption", ThemeColors.ERROR)
		dmg_label.custom_minimum_size = Vector2(25, 0)
		grid.add_child(dmg_label)

		# Damage type
		var type_label := Label.new()
		type_label.text = damage_type
		DesignSystem.style_label(type_label, "caption", _get_damage_type_color(damage_type))
		type_label.custom_minimum_size = Vector2(55, 0)
		grid.add_child(type_label)

		# Ability
		var ability_label := Label.new()
		ability_label.text = ability
		DesignSystem.style_label(ability_label, "caption", ThemeColors.TEXT_DIM)
		ability_label.custom_minimum_size = Vector2(160, 0)
		grid.add_child(ability_label)

		# Cost
		var cost_label := Label.new()
		cost_label.text = cost
		DesignSystem.style_label(cost_label, "caption", ThemeColors.RESOURCE_GOLD)
		grid.add_child(cost_label)


func _get_damage_type_color(damage_type: String) -> Color:
	for dt in DAMAGE_TYPES:
		if str(dt.get("type", "")) == damage_type:
			return dt.get("color", Color.WHITE)
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
