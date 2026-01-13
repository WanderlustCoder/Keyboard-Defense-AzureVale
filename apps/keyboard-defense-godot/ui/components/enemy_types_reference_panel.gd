class_name EnemyTypesReferencePanel
extends PanelContainer
## Enemy Types Reference Panel - Shows all enemy types, bosses, and affixes.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Basic enemy types
const ENEMY_KINDS: Array[Dictionary] = [
	{
		"id": "raider",
		"name": "Raider",
		"glyph": "r",
		"speed": 1,
		"armor": 0,
		"hp_bonus": 0,
		"special": "Standard enemy, no special abilities",
		"gold": 2,
		"color": Color(0.8, 0.4, 0.4)
	},
	{
		"id": "scout",
		"name": "Scout",
		"glyph": "s",
		"speed": 2,
		"armor": 0,
		"hp_bonus": -1,
		"special": "Fast but fragile",
		"gold": 1,
		"color": Color(0.4, 0.8, 0.4)
	},
	{
		"id": "armored",
		"name": "Armored",
		"glyph": "a",
		"speed": 1,
		"armor": 1,
		"hp_bonus": 1,
		"special": "Armor reduces physical damage",
		"gold": 3,
		"color": Color(0.6, 0.6, 0.6)
	},
	{
		"id": "swarm",
		"name": "Swarm",
		"glyph": "w",
		"speed": 3,
		"armor": 0,
		"hp_bonus": -2,
		"special": "Very fast, very fragile, comes in groups",
		"gold": 1,
		"color": Color(0.5, 0.7, 0.4)
	},
	{
		"id": "tank",
		"name": "Tank",
		"glyph": "T",
		"speed": 1,
		"armor": 2,
		"hp_bonus": 3,
		"special": "High armor and HP, slow movement",
		"gold": 4,
		"color": Color(0.5, 0.5, 0.6)
	},
	{
		"id": "berserker",
		"name": "Berserker",
		"glyph": "B",
		"speed": 2,
		"armor": 0,
		"hp_bonus": 1,
		"special": "Fast with moderate HP",
		"gold": 3,
		"color": Color(0.9, 0.4, 0.3)
	},
	{
		"id": "phantom",
		"name": "Phantom",
		"glyph": "P",
		"speed": 1,
		"armor": 0,
		"hp_bonus": 0,
		"special": "50% chance to evade first hit",
		"gold": 3,
		"color": Color(0.6, 0.5, 0.9)
	},
	{
		"id": "champion",
		"name": "Champion",
		"glyph": "C",
		"speed": 1,
		"armor": 1,
		"hp_bonus": 2,
		"special": "Elite enemy with armor and extra HP",
		"gold": 5,
		"color": Color(0.9, 0.7, 0.3)
	},
	{
		"id": "healer",
		"name": "Healer",
		"glyph": "H",
		"speed": 1,
		"armor": 0,
		"hp_bonus": 0,
		"special": "Heals nearby enemies each tick",
		"gold": 4,
		"color": Color(0.4, 0.9, 0.5)
	},
	{
		"id": "elite",
		"name": "Elite",
		"glyph": "E",
		"speed": 1,
		"armor": 1,
		"hp_bonus": 1,
		"special": "Always has a random affix",
		"gold": 6,
		"color": Color(0.9, 0.5, 0.9)
	}
]

# Boss enemies
const BOSS_KINDS: Array[Dictionary] = [
	{
		"id": "forest_guardian",
		"name": "Forest Guardian",
		"glyph": "G",
		"day": 5,
		"region": "Evergrove",
		"speed": 1,
		"armor": 1,
		"hp_bonus": 8,
		"special": "Regenerates 2 HP per tick",
		"gold": 25,
		"color": Color(0.13, 0.55, 0.13)
	},
	{
		"id": "stone_golem",
		"name": "Stone Golem",
		"glyph": "S",
		"day": 10,
		"region": "Stonepass",
		"speed": 1,
		"armor": 4,
		"hp_bonus": 12,
		"special": "Very high armor, slow but durable",
		"gold": 40,
		"color": Color(0.5, 0.5, 0.5)
	},
	{
		"id": "fen_seer",
		"name": "Fen Seer",
		"glyph": "F",
		"day": 15,
		"region": "Mistfen",
		"speed": 1,
		"armor": 1,
		"hp_bonus": 10,
		"special": "30% evasion, summons phantoms every 3 ticks",
		"gold": 55,
		"color": Color(0.4, 0.6, 0.7)
	},
	{
		"id": "sunlord",
		"name": "Sunlord",
		"glyph": "L",
		"day": 20,
		"region": "Sunfields",
		"speed": 2,
		"armor": 2,
		"hp_bonus": 15,
		"special": "Enraged - fast and deadly, extra damage",
		"gold": 75,
		"color": Color(1.0, 0.84, 0.0)
	}
]

# Enemy affixes
const AFFIXES: Array[Dictionary] = [
	{
		"id": "swift",
		"name": "Swift",
		"effect": "+1 speed",
		"unlock_day": 1,
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"id": "armored",
		"name": "Armored",
		"effect": "+1 armor",
		"unlock_day": 1,
		"color": Color(0.6, 0.6, 0.6)
	},
	{
		"id": "resilient",
		"name": "Resilient",
		"effect": "+2 HP",
		"unlock_day": 1,
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"id": "shielded",
		"name": "Shielded",
		"effect": "First hit immunity",
		"unlock_day": 1,
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"id": "thorny",
		"name": "Thorny",
		"effect": "Reflects 1 damage when hit",
		"unlock_day": 6,
		"color": Color(0.6, 0.4, 0.2)
	},
	{
		"id": "ghostly",
		"name": "Ghostly",
		"effect": "50% damage reduction",
		"unlock_day": 7,
		"color": Color(0.7, 0.7, 0.9)
	},
	{
		"id": "splitting",
		"name": "Splitting",
		"effect": "Spawns smaller enemies on death",
		"unlock_day": 8,
		"color": Color(0.8, 0.5, 0.3)
	},
	{
		"id": "regenerating",
		"name": "Regenerating",
		"effect": "+1 HP per tick",
		"unlock_day": 9,
		"color": Color(0.3, 0.9, 0.4)
	},
	{
		"id": "commanding",
		"name": "Commanding",
		"effect": "Buffs nearby allies",
		"unlock_day": 9,
		"color": Color(0.9, 0.7, 0.3)
	},
	{
		"id": "enraged",
		"name": "Enraged",
		"effect": "Increased damage",
		"unlock_day": 10,
		"color": Color(0.9, 0.3, 0.3)
	},
	{
		"id": "vampiric",
		"name": "Vampiric",
		"effect": "Heals on dealing damage",
		"unlock_day": 10,
		"color": Color(0.55, 0.0, 0.0)
	},
	{
		"id": "explosive",
		"name": "Explosive",
		"effect": "Deals damage on death",
		"unlock_day": 12,
		"color": Color(1.0, 0.5, 0.0)
	}
]

# Enemy unlock days
const ENEMY_UNLOCKS: Array[Dictionary] = [
	{"day": 1, "enemies": "Raider"},
	{"day": 3, "enemies": "Scout"},
	{"day": 4, "enemies": "Swarm"},
	{"day": 5, "enemies": "Armored, Berserker"},
	{"day": 6, "enemies": "Tank, Phantom"},
	{"day": 7, "enemies": "Champion, Healer"},
	{"day": 8, "enemies": "Elite"}
]

# Combat tips
const ENEMY_TIPS: Array[String] = [
	"Phantoms evade the first hit - use multi-hit towers",
	"Healers should be priority targets to prevent enemy recovery",
	"Elites always have affixes - prepare for surprises",
	"Tanks are vulnerable to armor-piercing magical damage",
	"Use freeze effects to halt fast enemies like scouts and swarms",
	"Bosses have special mechanics - read their abilities carefully"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 640)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "ENEMY BESTIARY"
	DesignSystem.style_label(title, "h2", Color(0.9, 0.4, 0.4))
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
	subtitle.text = "10 enemy types, 4 bosses, 12 affixes"
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
	footer.text = "Know your enemy to plan your defense"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_enemy_types_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Enemy types section
	_build_enemy_kinds_section()

	# Bosses section
	_build_bosses_section()

	# Affixes section
	_build_affixes_section()

	# Unlock progression
	_build_unlocks_section()

	# Combat tips
	_build_tips_section()


func _build_enemy_kinds_section() -> void:
	var section := _create_section_panel("ENEMY TYPES", Color(0.9, 0.4, 0.4))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for enemy in ENEMY_KINDS:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 1)
		vbox.add_child(container)

		# Name and glyph
		var header_hbox := HBoxContainer.new()
		header_hbox.add_theme_constant_override("separation", 8)
		container.add_child(header_hbox)

		var glyph_label := Label.new()
		glyph_label.text = "[%s]" % enemy.get("glyph", "?")
		glyph_label.add_theme_font_size_override("font_size", 10)
		glyph_label.add_theme_color_override("font_color", enemy.get("color", Color.WHITE))
		glyph_label.custom_minimum_size = Vector2(25, 0)
		header_hbox.add_child(glyph_label)

		var name_label := Label.new()
		name_label.text = str(enemy.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", enemy.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(80, 0)
		header_hbox.add_child(name_label)

		# Stats
		var speed_val: int = int(enemy.get("speed", 1))
		var armor_val: int = int(enemy.get("armor", 0))
		var hp_bonus: int = int(enemy.get("hp_bonus", 0))
		var gold: int = int(enemy.get("gold", 1))

		var stats_text: String = "SPD:%d ARM:%d HP:%+d" % [speed_val, armor_val, hp_bonus]
		var stats_label := Label.new()
		stats_label.text = stats_text
		stats_label.add_theme_font_size_override("font_size", 9)
		stats_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
		header_hbox.add_child(stats_label)

		var gold_label := Label.new()
		gold_label.text = "%dg" % gold
		gold_label.add_theme_font_size_override("font_size", 9)
		gold_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		header_hbox.add_child(gold_label)

		# Special ability
		var special_label := Label.new()
		special_label.text = "     " + str(enemy.get("special", ""))
		special_label.add_theme_font_size_override("font_size", 9)
		special_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		container.add_child(special_label)


func _build_bosses_section() -> void:
	var section := _create_section_panel("BOSSES", Color(0.9, 0.5, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for boss in BOSS_KINDS:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 1)
		vbox.add_child(container)

		# Name and day
		var header_hbox := HBoxContainer.new()
		header_hbox.add_theme_constant_override("separation", 8)
		container.add_child(header_hbox)

		var glyph_label := Label.new()
		glyph_label.text = "[%s]" % boss.get("glyph", "!")
		glyph_label.add_theme_font_size_override("font_size", 10)
		glyph_label.add_theme_color_override("font_color", boss.get("color", Color.WHITE))
		glyph_label.custom_minimum_size = Vector2(25, 0)
		header_hbox.add_child(glyph_label)

		var name_label := Label.new()
		name_label.text = str(boss.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", boss.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(110, 0)
		header_hbox.add_child(name_label)

		var day_label := Label.new()
		day_label.text = "Day %d" % boss.get("day", 0)
		day_label.add_theme_font_size_override("font_size", 9)
		day_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3))
		day_label.custom_minimum_size = Vector2(45, 0)
		header_hbox.add_child(day_label)

		var region_label := Label.new()
		region_label.text = "(%s)" % boss.get("region", "")
		region_label.add_theme_font_size_override("font_size", 9)
		region_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
		header_hbox.add_child(region_label)

		# Stats
		var stats_hbox := HBoxContainer.new()
		stats_hbox.add_theme_constant_override("separation", 12)
		container.add_child(stats_hbox)

		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(25, 0)
		stats_hbox.add_child(spacer)

		var speed_val: int = int(boss.get("speed", 1))
		var armor_val: int = int(boss.get("armor", 0))
		var hp_bonus: int = int(boss.get("hp_bonus", 0))
		var gold: int = int(boss.get("gold", 25))

		var stats_label := Label.new()
		stats_label.text = "SPD:%d ARM:%d HP:+%d" % [speed_val, armor_val, hp_bonus]
		stats_label.add_theme_font_size_override("font_size", 9)
		stats_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
		stats_hbox.add_child(stats_label)

		var gold_label := Label.new()
		gold_label.text = "%dg" % gold
		gold_label.add_theme_font_size_override("font_size", 9)
		gold_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		stats_hbox.add_child(gold_label)

		# Special ability
		var special_label := Label.new()
		special_label.text = "     " + str(boss.get("special", ""))
		special_label.add_theme_font_size_override("font_size", 9)
		special_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		special_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		container.add_child(special_label)


func _build_affixes_section() -> void:
	var section := _create_section_panel("AFFIXES", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var desc := Label.new()
	desc.text = "Elite enemies and some variants have random affixes:"
	desc.add_theme_font_size_override("font_size", 10)
	desc.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(desc)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 2)
	vbox.add_child(grid)

	for affix in AFFIXES:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 6)
		grid.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(affix.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 9)
		name_label.add_theme_color_override("font_color", affix.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(80, 0)
		hbox.add_child(name_label)

		var day_label := Label.new()
		day_label.text = "D%d+" % affix.get("unlock_day", 1)
		day_label.add_theme_font_size_override("font_size", 9)
		day_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		hbox.add_child(day_label)

		var effect_label := Label.new()
		effect_label.text = str(affix.get("effect", ""))
		effect_label.add_theme_font_size_override("font_size", 9)
		effect_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		grid.add_child(effect_label)


func _build_unlocks_section() -> void:
	var section := _create_section_panel("ENEMY PROGRESSION", Color(0.4, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for unlock in ENEMY_UNLOCKS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var day_label := Label.new()
		day_label.text = "Day %d:" % unlock.get("day", 1)
		day_label.add_theme_font_size_override("font_size", 9)
		day_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3))
		day_label.custom_minimum_size = Vector2(50, 0)
		hbox.add_child(day_label)

		var enemies_label := Label.new()
		enemies_label.text = str(unlock.get("enemies", ""))
		enemies_label.add_theme_font_size_override("font_size", 9)
		enemies_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(enemies_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("COMBAT TIPS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in ENEMY_TIPS:
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
