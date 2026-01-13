class_name SynergyReferencePanel
extends PanelContainer
## Synergy Reference Panel - Shows tower synergy combinations and effects.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Synergy definitions (from SimSynergyDetector) - domain-specific colors
const SYNERGIES: Array[Dictionary] = [
	{
		"id": "fire_ice",
		"name": "Fire & Ice",
		"description": "Frozen enemies take 3x fire damage, burning enemies take 3x cold damage",
		"requirements": "Frost Tower + fire damage source",
		"proximity": 5,
		"color": Color(0.6, 0.3, 0.9)
	},
	{
		"id": "arrow_rain",
		"name": "Arrow Rain",
		"description": "Coordinated rain of arrows every 15s (2x damage)",
		"requirements": "3 Arrow Towers within range",
		"proximity": 6,
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"id": "arcane_support",
		"name": "Arcane Support",
		"description": "+50% accuracy scaling on Arcane Tower",
		"requirements": "Support Tower + Arcane Tower",
		"proximity": 4,
		"color": Color(0.7, 0.5, 0.9)
	},
	{
		"id": "holy_purification",
		"name": "Holy Purification",
		"description": "2x purify chance, purified enemies explode (20 dmg)",
		"requirements": "Holy Tower + Purifier Tower",
		"proximity": 5,
		"color": Color(1.0, 0.9, 0.5)
	},
	{
		"id": "chain_reaction",
		"name": "Chain Reaction",
		"description": "+3 chain jumps, no damage falloff",
		"requirements": "Tesla Tower + Magic Tower",
		"proximity": 4,
		"color": Color(0.4, 0.7, 1.0)
	},
	{
		"id": "kill_box",
		"name": "Kill Box",
		"description": "+25% damage to slowed enemies in zone",
		"requirements": "Frost + Cannon + Poison Towers",
		"proximity": 5,
		"color": Color(0.9, 0.4, 0.3)
	},
	{
		"id": "legion",
		"name": "Legion",
		"description": "+2 max summons, +20% summon stats",
		"requirements": "2 Summoner Towers within range",
		"proximity": 8,
		"color": Color(0.4, 0.9, 0.4)
	},
	{
		"id": "titan_slayer",
		"name": "Titan Slayer",
		"description": "50% faster charge, +100% boss damage",
		"requirements": "Siege + Support + Arcane Towers",
		"proximity": 5,
		"color": Color(0.9, 0.6, 0.3)
	}
]

# Synergy tips
const SYNERGY_TIPS: Array[String] = [
	"Synergies activate when required towers are within proximity range",
	"Synergy effects stack with other bonuses (upgrades, combo)",
	"Proximity is measured in tile distance (Manhattan)",
	"Plan tower placement to maximize synergy potential",
	"Some synergies trigger special attacks (Arrow Rain)",
	"Status effect synergies combo well with specialized towers"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_MD, 580)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "TOWER SYNERGIES"
	DesignSystem.style_label(title, "h2", Color(0.6, 0.3, 0.9))
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
	subtitle.text = "Tower combinations that create powerful effects"
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
	footer.text = "Place towers within proximity range to activate synergies"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_synergies() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Synergies section
	_build_synergies_section()

	# Tips section
	_build_tips_section()


func _build_synergies_section() -> void:
	var section := _create_section_panel("SYNERGY COMBINATIONS", Color(0.6, 0.3, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for synergy in SYNERGIES:
		var card := _create_synergy_card(synergy)
		vbox.add_child(card)


func _create_synergy_card(synergy: Dictionary) -> Control:
	var name_str: String = str(synergy.get("name", ""))
	var description: String = str(synergy.get("description", ""))
	var requirements: String = str(synergy.get("requirements", ""))
	var proximity: int = int(synergy.get("proximity", 5))
	var color: Color = synergy.get("color", Color.WHITE)

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

	# Header with name and proximity
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var name_label := Label.new()
	name_label.text = name_str
	DesignSystem.style_label(name_label, "body_small", color)
	header.add_child(name_label)

	header.add_child(DesignSystem.create_spacer())

	var prox_label := Label.new()
	prox_label.text = "Range: %d" % proximity
	DesignSystem.style_label(prox_label, "caption", ThemeColors.INFO)
	header.add_child(prox_label)

	# Requirements
	var req_label := Label.new()
	req_label.text = requirements
	DesignSystem.style_label(req_label, "caption", ThemeColors.RESOURCE_GOLD)
	req_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_vbox.add_child(req_label)

	# Effect description
	var desc_label := Label.new()
	desc_label.text = description
	DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_vbox.add_child(desc_label)

	return container


func _build_tips_section() -> void:
	var section := _create_section_panel("SYNERGY TIPS", ThemeColors.SUCCESS)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in SYNERGY_TIPS:
		var tip_label := Label.new()
		tip_label.text = "- " + tip
		DesignSystem.style_label(tip_label, "caption", ThemeColors.TEXT_DIM)
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
