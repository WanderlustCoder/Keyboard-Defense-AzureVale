class_name UpgradesDetailReferencePanel
extends PanelContainer
## Upgrades Detail Reference Panel - Shows upgrade categories, effects, and purchase info.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Upgrade categories
const UPGRADE_CATEGORIES: Array[Dictionary] = [
	{
		"category": "Kingdom",
		"desc": "Global bonuses that affect your entire kingdom",
		"examples": "Castle health, resource production, threat reduction",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"category": "Unit",
		"desc": "Bonuses that affect towers and combat",
		"examples": "Tower damage, attack speed, critical chance",
		"color": Color(0.9, 0.6, 0.3)
	}
]

# Effect types
const EFFECT_TYPES: Array[Dictionary] = [
	{
		"effect": "typing_power",
		"name": "Typing Power",
		"desc": "Multiplier to damage dealt when typing words correctly",
		"base": "1.0",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"effect": "threat_rate_multiplier",
		"name": "Threat Rate",
		"desc": "Affects how quickly threat accumulates (negative = slower)",
		"base": "1.0",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"effect": "gold_multiplier",
		"name": "Gold Multiplier",
		"desc": "Increases gold earned from all sources",
		"base": "1.0",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"effect": "resource_multiplier",
		"name": "Resource Multiplier",
		"desc": "Increases wood, stone, food production",
		"base": "1.0",
		"color": Color(0.6, 0.4, 0.2)
	},
	{
		"effect": "damage_reduction",
		"name": "Damage Reduction",
		"desc": "Reduces damage taken by castle (capped at 75%)",
		"base": "0.0",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"effect": "castle_health_bonus",
		"name": "Castle Health",
		"desc": "Flat bonus to maximum castle HP",
		"base": "0",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"effect": "critical_chance",
		"name": "Critical Chance",
		"desc": "Chance for attacks to deal bonus damage (capped at 50%)",
		"base": "0.0",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"effect": "wave_heal",
		"name": "Wave Heal",
		"desc": "HP restored at the end of each wave",
		"base": "0",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"effect": "mistake_forgiveness",
		"name": "Mistake Forgiveness",
		"desc": "Reduces penalty for typing mistakes",
		"base": "0.0",
		"color": Color(0.7, 0.5, 0.9)
	},
	{
		"effect": "enemy_armor_reduction",
		"name": "Armor Reduction",
		"desc": "Reduces enemy armor values",
		"base": "0",
		"color": Color(0.8, 0.8, 0.8)
	},
	{
		"effect": "armor_pierce",
		"name": "Armor Pierce",
		"desc": "Ignores a flat amount of enemy armor",
		"base": "0",
		"color": Color(0.6, 0.6, 0.6)
	},
	{
		"effect": "enemy_speed_reduction",
		"name": "Enemy Slow",
		"desc": "Global slow applied to all enemies (capped at 50%)",
		"base": "0.0",
		"color": Color(0.4, 0.6, 0.9)
	},
	{
		"effect": "gold_income",
		"name": "Gold Income",
		"desc": "Passive gold earned at the start of each day",
		"base": "0",
		"color": Color(1.0, 0.84, 0.0)
	}
]

# Upgrade tiers
const UPGRADE_TIERS: Array[Dictionary] = [
	{
		"tier": 1,
		"name": "Basic",
		"desc": "Entry-level upgrades, no prerequisites",
		"cost_range": "50-150 gold",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"tier": 2,
		"name": "Advanced",
		"desc": "Require Tier 1 upgrades",
		"cost_range": "200-400 gold",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"tier": 3,
		"name": "Expert",
		"desc": "Require Tier 2 upgrades, powerful effects",
		"cost_range": "500+ gold",
		"color": Color(0.9, 0.6, 0.3)
	}
]

# Purchase mechanics
const PURCHASE_MECHANICS: Array[Dictionary] = [
	{
		"topic": "Gold Cost",
		"desc": "Upgrades are purchased with gold",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"topic": "Prerequisites",
		"desc": "Higher tier upgrades require earlier ones",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"topic": "Permanent",
		"desc": "Once purchased, upgrades persist",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"topic": "Stacking",
		"desc": "Multiple upgrades with same effect stack additively",
		"color": Color(0.7, 0.5, 0.9)
	}
]

# Tips
const UPGRADE_TIPS: Array[String] = [
	"Type UPGRADE KINGDOM or UPGRADE UNIT to view trees",
	"Kingdom upgrades provide global bonuses",
	"Unit upgrades focus on combat effectiveness",
	"Early game: prioritize resource multipliers",
	"Late game: damage reduction becomes essential"
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
	title.text = "UPGRADE SYSTEM"
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
	subtitle.text = "Permanent bonuses purchased with gold"
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
	footer.text = "Invest wisely to strengthen your kingdom"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_upgrades_detail_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Categories section
	_build_categories_section()

	# Tiers section
	_build_tiers_section()

	# Effects section
	_build_effects_section()

	# Mechanics section
	_build_mechanics_section()

	# Tips section
	_build_tips_section()


func _build_categories_section() -> void:
	var section := _create_section_panel("UPGRADE CATEGORIES", Color(0.4, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in UPGRADE_CATEGORIES:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 2)
		vbox.add_child(container)

		var name_label := Label.new()
		name_label.text = str(info.get("category", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", info.get("color", Color.WHITE))
		container.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = "  " + str(info.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		container.add_child(desc_label)

		var examples_label := Label.new()
		examples_label.text = "  Ex: " + str(info.get("examples", ""))
		examples_label.add_theme_font_size_override("font_size", 9)
		examples_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		container.add_child(examples_label)


func _build_tiers_section() -> void:
	var section := _create_section_panel("UPGRADE TIERS", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in UPGRADE_TIERS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var tier_label := Label.new()
		tier_label.text = "Tier %d" % info.get("tier", 0)
		tier_label.add_theme_font_size_override("font_size", 10)
		tier_label.add_theme_color_override("font_color", info.get("color", Color.WHITE))
		tier_label.custom_minimum_size = Vector2(50, 0)
		hbox.add_child(tier_label)

		var name_label := Label.new()
		name_label.text = str(info.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", info.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(70, 0)
		hbox.add_child(name_label)

		var cost_label := Label.new()
		cost_label.text = str(info.get("cost_range", ""))
		cost_label.add_theme_font_size_override("font_size", 9)
		cost_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		hbox.add_child(cost_label)


func _build_effects_section() -> void:
	var section := _create_section_panel("EFFECT TYPES", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in EFFECT_TYPES:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(info.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", info.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(120, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(info.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(desc_label)


func _build_mechanics_section() -> void:
	var section := _create_section_panel("PURCHASE MECHANICS", Color(0.7, 0.5, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in PURCHASE_MECHANICS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var topic_label := Label.new()
		topic_label.text = str(info.get("topic", ""))
		topic_label.add_theme_font_size_override("font_size", 10)
		topic_label.add_theme_color_override("font_color", info.get("color", Color.WHITE))
		topic_label.custom_minimum_size = Vector2(100, 0)
		hbox.add_child(topic_label)

		var desc_label := Label.new()
		desc_label.text = str(info.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("UPGRADE TIPS", Color(0.9, 0.4, 0.4))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in UPGRADE_TIPS:
		var tip_label := Label.new()
		tip_label.text = "- " + tip
		tip_label.add_theme_font_size_override("font_size", 10)
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
