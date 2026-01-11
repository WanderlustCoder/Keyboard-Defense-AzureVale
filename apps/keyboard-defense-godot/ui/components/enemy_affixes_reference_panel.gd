class_name EnemyAffixesReferencePanel
extends PanelContainer
## Enemy Affixes Reference Panel - Shows all enemy modifiers and their effects

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Affix tiers
const AFFIX_TIERS: Array[Dictionary] = [
	{
		"tier": 1,
		"name": "Common Affixes",
		"unlock": "Always available",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"tier": 2,
		"name": "Advanced Affixes",
		"unlock": "Available after Day 4",
		"color": Color(0.5, 0.7, 0.9)
	},
	{
		"tier": 3,
		"name": "Deadly Affixes",
		"unlock": "Available after Day 7",
		"color": Color(0.8, 0.2, 0.2)
	}
]

# All affixes
const AFFIXES: Array[Dictionary] = [
	{
		"id": "swift",
		"name": "Swift",
		"tier": 1,
		"glyph": "+",
		"desc": "Moves faster than normal",
		"effect": "+1 speed",
		"counter": "High DPS towers, slow effects",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"id": "armored",
		"name": "Armored",
		"tier": 1,
		"glyph": "#",
		"desc": "Additional armor plating",
		"effect": "+1 armor",
		"counter": "Magical damage, armor penetration",
		"color": Color(0.6, 0.6, 0.7)
	},
	{
		"id": "resilient",
		"name": "Resilient",
		"tier": 1,
		"glyph": "*",
		"desc": "Extra health pool",
		"effect": "+2 HP",
		"counter": "Sustained damage, DoT effects",
		"color": Color(0.8, 0.5, 0.5)
	},
	{
		"id": "shielded",
		"name": "Shielded",
		"tier": 2,
		"glyph": "O",
		"desc": "First hit is absorbed",
		"effect": "Immune to first attack",
		"counter": "Multi-hit attacks, fast towers",
		"color": Color(0.5, 0.7, 0.9)
	},
	{
		"id": "splitting",
		"name": "Splitting",
		"tier": 2,
		"glyph": "~",
		"desc": "Spawns smaller enemies on death",
		"effect": "+1 HP, spawns 2 minions",
		"counter": "AoE damage, prioritize before death",
		"color": Color(0.7, 0.5, 0.7)
	},
	{
		"id": "regenerating",
		"name": "Regenerating",
		"tier": 2,
		"glyph": "^",
		"desc": "Slowly heals over time",
		"effect": "+1 HP every 3 ticks",
		"counter": "Burst damage, focus fire",
		"color": Color(0.4, 0.8, 0.4)
	},
	{
		"id": "enraged",
		"name": "Enraged",
		"tier": 2,
		"glyph": "!",
		"desc": "Speed increases when damaged",
		"effect": "+1 HP, +1 speed on first hit",
		"counter": "One-shot kills, heavy burst",
		"color": Color(0.96, 0.26, 0.21)
	},
	{
		"id": "vampiric",
		"name": "Vampiric",
		"tier": 3,
		"glyph": "V",
		"desc": "Heals when dealing damage",
		"effect": "Lifesteal on castle damage",
		"counter": "Kill before reaching castle",
		"color": Color(0.6, 0.2, 0.4)
	}
]

# Affix mechanics
const AFFIX_MECHANICS: Array[Dictionary] = [
	{
		"name": "Affix Spawn Chance",
		"desc": "Elite enemies always have affixes. Regular enemies gain 5% chance per day after day 4",
		"color": Color(0.5, 0.7, 0.9)
	},
	{
		"name": "Champion Affixes",
		"desc": "Champion enemies have 75% chance to spawn with an affix",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"name": "Glyph Indicators",
		"desc": "Affixed enemies display a glyph symbol next to their word",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"name": "Holy Damage Bonus",
		"desc": "Holy damage type deals +50% damage to affixed enemies",
		"color": Color(1.0, 1.0, 0.9)
	}
]

# Tips
const AFFIX_TIPS: Array[String] = [
	"Learn affix glyphs to quickly identify threats: + Swift, # Armored, O Shielded",
	"Prioritize Vampiric enemies - they heal when damaging your castle",
	"Shielded enemies waste your first hit - use fast towers to break shields",
	"Splitting enemies are dangerous in groups - kill them early",
	"Regenerating enemies require focus fire to prevent healing",
	"Enraged enemies speed up when hit - try to one-shot them"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(540, 640)

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
	title.text = "ENEMY AFFIXES"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4))
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
	subtitle.text = "8 affixes across 3 tiers that modify enemy behavior"
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
	footer.text = "Watch for glyph indicators on enemy words"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_enemy_affixes_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Mechanics
	_build_mechanics_section()

	# Affixes by tier
	for tier_info in AFFIX_TIERS:
		_build_tier_section(tier_info)

	# Tips
	_build_tips_section()


func _build_mechanics_section() -> void:
	var section := _create_section_panel("AFFIX MECHANICS", Color(0.5, 0.6, 0.7))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for mech in AFFIX_MECHANICS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(mech.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", mech.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(130, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(mech.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hbox.add_child(desc_label)


func _build_tier_section(tier_info: Dictionary) -> void:
	var tier: int = int(tier_info.get("tier", 1))
	var color: Color = tier_info.get("color", Color.WHITE)
	var section := _create_section_panel("TIER %d - %s" % [tier, str(tier_info.get("name", ""))], color)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Unlock info
	var unlock_label := Label.new()
	unlock_label.text = str(tier_info.get("unlock", ""))
	unlock_label.add_theme_font_size_override("font_size", 9)
	unlock_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(unlock_label)

	# Affixes in this tier
	for affix in AFFIXES:
		if int(affix.get("tier", 0)) != tier:
			continue

		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 1)
		vbox.add_child(container)

		# Name and glyph
		var header_hbox := HBoxContainer.new()
		header_hbox.add_theme_constant_override("separation", 10)
		container.add_child(header_hbox)

		var glyph_label := Label.new()
		glyph_label.text = "[%s]" % affix.get("glyph", "?")
		glyph_label.add_theme_font_size_override("font_size", 11)
		glyph_label.add_theme_color_override("font_color", affix.get("color", Color.WHITE))
		glyph_label.custom_minimum_size = Vector2(30, 0)
		header_hbox.add_child(glyph_label)

		var name_label := Label.new()
		name_label.text = str(affix.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.add_theme_color_override("font_color", affix.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(100, 0)
		header_hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(affix.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		header_hbox.add_child(desc_label)

		# Effect
		var effect_label := Label.new()
		effect_label.text = "     Effect: %s" % affix.get("effect", "")
		effect_label.add_theme_font_size_override("font_size", 9)
		effect_label.add_theme_color_override("font_color", Color(0.96, 0.26, 0.21))
		container.add_child(effect_label)

		# Counter
		var counter_label := Label.new()
		counter_label.text = "     Counter: %s" % affix.get("counter", "")
		counter_label.add_theme_font_size_override("font_size", 9)
		counter_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.3))
		container.add_child(counter_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("AFFIX TIPS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in AFFIX_TIPS:
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
