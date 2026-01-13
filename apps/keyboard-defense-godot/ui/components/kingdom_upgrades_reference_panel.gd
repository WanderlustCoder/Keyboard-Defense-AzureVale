class_name KingdomUpgradesReferencePanel
extends PanelContainer
## Kingdom Upgrades Reference Panel - Shows permanent kingdom upgrade trees.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Upgrade trees overview
const UPGRADE_TREES: Array[Dictionary] = [
	{
		"id": "scribe",
		"name": "Scribe Tree",
		"desc": "Typing power and critical strikes",
		"upgrades": 3,
		"color": Color(0.5, 0.7, 0.9)
	},
	{
		"id": "defense",
		"name": "Defense Tree",
		"desc": "Threat reduction and damage mitigation",
		"upgrades": 3,
		"color": Color(0.6, 0.6, 0.7)
	},
	{
		"id": "restoration",
		"name": "Restoration Tree",
		"desc": "Healing and castle health bonuses",
		"upgrades": 3,
		"color": Color(0.4, 0.8, 0.4)
	},
	{
		"id": "economy",
		"name": "Economy Tree",
		"desc": "Gold income and resource multipliers",
		"upgrades": 3,
		"color": Color(1.0, 0.84, 0.0)
	}
]

# Tier 1 upgrades (base tier, no requirements)
const TIER1_UPGRADES: Array[Dictionary] = [
	{
		"id": "scribe-hall",
		"name": "Scribe Hall",
		"tree": "Scribe",
		"cost": 20,
		"desc": "Letters strike with greater force",
		"effects": "+15% typing power",
		"color": Color(0.5, 0.7, 0.9)
	},
	{
		"id": "watchtower-bells",
		"name": "Watchtower Bells",
		"tree": "Defense",
		"cost": 25,
		"desc": "Slows incoming pressure between letters",
		"effects": "-10% threat rate",
		"color": Color(0.6, 0.6, 0.7)
	},
	{
		"id": "granary",
		"name": "Royal Granary",
		"tree": "Restoration",
		"cost": 18,
		"desc": "Improves recovery after mistakes",
		"effects": "+10% mistake forgiveness",
		"color": Color(0.4, 0.8, 0.4)
	},
	{
		"id": "treasury",
		"name": "Royal Treasury",
		"tree": "Economy",
		"cost": 22,
		"desc": "Generates gold each dawn and boosts defeat rewards",
		"effects": "+15% gold, +2 gold/day",
		"color": Color(1.0, 0.84, 0.0)
	}
]

# Tier 2 upgrades (require Tier 1)
const TIER2_UPGRADES: Array[Dictionary] = [
	{
		"id": "scribe-library",
		"name": "Scribe Library",
		"tree": "Scribe",
		"cost": 40,
		"requires": "Scribe Hall",
		"desc": "Advanced texts further amplify typing power",
		"effects": "+20% typing power",
		"color": Color(0.5, 0.7, 0.9)
	},
	{
		"id": "signal-tower",
		"name": "Signal Tower",
		"tree": "Defense",
		"cost": 45,
		"requires": "Watchtower Bells",
		"desc": "Early warning reduces threat buildup",
		"effects": "-15% threat rate",
		"color": Color(0.6, 0.6, 0.7)
	},
	{
		"id": "healer-quarter",
		"name": "Healer's Quarter",
		"tree": "Restoration",
		"cost": 38,
		"requires": "Royal Granary",
		"desc": "Healers restore castle after each wave",
		"effects": "+1 HP/wave healed",
		"color": Color(0.4, 0.8, 0.4)
	},
	{
		"id": "merchant-guild",
		"name": "Merchant Guild",
		"tree": "Economy",
		"cost": 42,
		"requires": "Royal Treasury",
		"desc": "Trade networks boost all resource gains",
		"effects": "+10% all resources",
		"color": Color(1.0, 0.84, 0.0)
	}
]

# Tier 3 upgrades (require Tier 2, capstone)
const TIER3_UPGRADES: Array[Dictionary] = [
	{
		"id": "arcane-archive",
		"name": "Arcane Archive",
		"tree": "Scribe",
		"cost": 80,
		"requires": "Scribe Library",
		"desc": "Ancient knowledge unleashes devastating strikes",
		"effects": "+30% typing power, +10% crit chance",
		"color": Color(0.5, 0.7, 0.9)
	},
	{
		"id": "fortress-walls",
		"name": "Fortress Walls",
		"tree": "Defense",
		"cost": 85,
		"requires": "Signal Tower",
		"desc": "Impenetrable walls reduce all incoming damage",
		"effects": "-20% damage taken",
		"color": Color(0.6, 0.6, 0.7)
	},
	{
		"id": "sanctuary",
		"name": "Sacred Sanctuary",
		"tree": "Restoration",
		"cost": 75,
		"requires": "Healer's Quarter",
		"desc": "Divine protection heals and shields the castle",
		"effects": "+2 HP/wave, +2 max castle HP",
		"color": Color(0.4, 0.8, 0.4)
	},
	{
		"id": "grand-exchange",
		"name": "Grand Exchange",
		"tree": "Economy",
		"cost": 90,
		"requires": "Merchant Guild",
		"desc": "Global trade networks maximize all gains",
		"effects": "+25% gold, +15% resources, +5 gold/day",
		"color": Color(1.0, 0.84, 0.0)
	}
]

# Upgrade tips
const UPGRADE_TIPS: Array[String] = [
	"Kingdom upgrades are permanent and persist across runs",
	"Each tree has 3 tiers - you must unlock prerequisites first",
	"Tier 3 upgrades are capstones with powerful combined effects",
	"Scribe tree boosts damage, Defense reduces threat and damage",
	"Restoration tree provides healing, Economy boosts income",
	"Purchase upgrades from the Kingdom Hub between runs"
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
	title.text = "KINGDOM UPGRADES"
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
	subtitle.text = "12 permanent upgrades across 4 trees"
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
	footer.text = "Purchase from Kingdom Hub between runs"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_kingdom_upgrades_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Trees overview
	_build_trees_overview_section()

	# Tier 1
	_build_tier_section("TIER 1 - FOUNDATIONS", Color(0.5, 0.6, 0.7), TIER1_UPGRADES)

	# Tier 2
	_build_tier_section("TIER 2 - ADVANCEMENTS", Color(0.6, 0.7, 0.8), TIER2_UPGRADES)

	# Tier 3
	_build_tier_section("TIER 3 - CAPSTONES", Color(0.8, 0.6, 0.9), TIER3_UPGRADES)

	# Tips
	_build_tips_section()


func _build_trees_overview_section() -> void:
	var section := _create_section_panel("UPGRADE TREES", Color(0.6, 0.6, 0.8))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tree in UPGRADE_TREES:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(tree.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", tree.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(110, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(tree.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_tier_section(title: String, color: Color, upgrades: Array[Dictionary]) -> void:
	var section := _create_section_panel(title, color)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for upgrade in upgrades:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 1)
		vbox.add_child(container)

		# Name, tree, and cost
		var header_hbox := HBoxContainer.new()
		header_hbox.add_theme_constant_override("separation", 10)
		container.add_child(header_hbox)

		var name_label := Label.new()
		name_label.text = str(upgrade.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", upgrade.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(130, 0)
		header_hbox.add_child(name_label)

		var tree_label := Label.new()
		tree_label.text = "[%s]" % upgrade.get("tree", "")
		tree_label.add_theme_font_size_override("font_size", 9)
		tree_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		tree_label.custom_minimum_size = Vector2(70, 0)
		header_hbox.add_child(tree_label)

		var cost_label := Label.new()
		cost_label.text = "%dg" % upgrade.get("cost", 0)
		cost_label.add_theme_font_size_override("font_size", 9)
		cost_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		header_hbox.add_child(cost_label)

		# Description
		var desc_label := Label.new()
		desc_label.text = "  " + str(upgrade.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		container.add_child(desc_label)

		# Effects
		var effects_label := Label.new()
		effects_label.text = "  Effect: " + str(upgrade.get("effects", ""))
		effects_label.add_theme_font_size_override("font_size", 9)
		effects_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.3))
		container.add_child(effects_label)

		# Requirements
		var requires: String = str(upgrade.get("requires", ""))
		if requires != "":
			var req_label := Label.new()
			req_label.text = "  Requires: " + requires
			req_label.add_theme_font_size_override("font_size", 9)
			req_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			container.add_child(req_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("UPGRADE TIPS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in UPGRADE_TIPS:
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
