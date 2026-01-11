class_name SynergiesDetailReferencePanel
extends PanelContainer
## Synergies Detail Reference Panel - Shows tower synergy combinations and effects

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# All synergy definitions
const SYNERGIES: Array[Dictionary] = [
	{
		"id": "fire_ice",
		"name": "Fire & Ice",
		"desc": "Frozen enemies take 3x fire damage, burning enemies take 3x cold damage",
		"requires": "Frost Tower + fire damage source",
		"proximity": 5,
		"effects": ["frozen_fire_mult: 3.0", "burning_cold_mult: 3.0"],
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"id": "arrow_rain",
		"name": "Arrow Rain",
		"desc": "3 Arrow Towers coordinate a devastating rain of arrows every 15s",
		"requires": "3x Arrow Towers",
		"proximity": 6,
		"effects": ["coordinated_attack_interval: 15s", "coordinated_attack_mult: 2.0x"],
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"id": "arcane_support",
		"name": "Arcane Support",
		"desc": "Support Tower boosts Arcane Tower accuracy scaling by 50%",
		"requires": "Support Tower + Arcane Tower",
		"proximity": 4,
		"effects": ["accuracy_scaling_bonus: +50%"],
		"color": Color(0.7, 0.5, 0.9)
	},
	{
		"id": "holy_purification",
		"name": "Holy Purification",
		"desc": "2x purify chance, purified enemies explode for 20 damage",
		"requires": "Holy Tower + Purifier Tower",
		"proximity": 5,
		"effects": ["purify_chance_mult: 2.0x", "purify_explosion: 20 damage"],
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"id": "chain_reaction",
		"name": "Chain Reaction",
		"desc": "+3 chain jumps, no damage falloff on chains",
		"requires": "Tesla Tower + Magic Tower",
		"proximity": 4,
		"effects": ["extra_chain_jumps: +3", "no_chain_falloff: true"],
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"id": "kill_box",
		"name": "Kill Box",
		"desc": "+25% damage to slowed enemies in the zone",
		"requires": "Frost + Cannon + Poison Towers",
		"proximity": 5,
		"effects": ["slow_damage_bonus: +25%"],
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"id": "legion",
		"name": "Legion",
		"desc": "+2 max summons, +20% summon stats",
		"requires": "2x Summoner Towers",
		"proximity": 8,
		"effects": ["max_summons_bonus: +2", "summon_stat_bonus: +20%"],
		"color": Color(0.8, 0.5, 0.8)
	},
	{
		"id": "titan_slayer",
		"name": "Titan Slayer",
		"desc": "50% faster charge, +100% boss damage",
		"requires": "Siege + Support + Arcane Towers",
		"proximity": 5,
		"effects": ["charge_speed_bonus: +50%", "boss_damage_bonus: +100%"],
		"color": Color(0.9, 0.7, 0.3)
	}
]

# Synergy mechanics
const SYNERGY_MECHANICS: Array[Dictionary] = [
	{
		"topic": "Proximity Check",
		"desc": "Towers must be within Manhattan distance to activate",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"topic": "Auto-Detection",
		"desc": "Synergies are detected automatically when towers are placed",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"topic": "Stacking",
		"desc": "Multiple synergies can be active simultaneously",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"topic": "UI Indicator",
		"desc": "Active synergies shown in synergy panel during battle",
		"color": Color(0.7, 0.5, 0.9)
	}
]

# Tips
const SYNERGY_TIPS: Array[String] = [
	"Place synergistic towers close together for bonuses",
	"Some synergies require specific tower counts (e.g., 3 Arrow Towers)",
	"Synergies can dramatically increase damage output",
	"Plan your tower layout to maximize synergy potential",
	"Titan Slayer is excellent for boss fights"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(520, 620)

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
	title.text = "TOWER SYNERGIES"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.7, 0.5, 0.9))
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
	subtitle.text = "Tower combinations that grant bonus effects"
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
	footer.text = "8 synergies available"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_synergies_detail_reference() -> void:
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

	# Mechanics section
	_build_mechanics_section()

	# Tips section
	_build_tips_section()


func _build_synergies_section() -> void:
	var section := _create_section_panel("ALL SYNERGIES", Color(0.7, 0.5, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for synergy in SYNERGIES:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 2)
		vbox.add_child(container)

		# Name and proximity
		var header_hbox := HBoxContainer.new()
		header_hbox.add_theme_constant_override("separation", 10)
		container.add_child(header_hbox)

		var name_label := Label.new()
		name_label.text = str(synergy.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", synergy.get("color", Color.WHITE))
		header_hbox.add_child(name_label)

		var prox_label := Label.new()
		prox_label.text = "(range: %d)" % synergy.get("proximity", 0)
		prox_label.add_theme_font_size_override("font_size", 9)
		prox_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		header_hbox.add_child(prox_label)

		# Description
		var desc_label := Label.new()
		desc_label.text = "  " + str(synergy.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		container.add_child(desc_label)

		# Requirements
		var req_label := Label.new()
		req_label.text = "  Requires: " + str(synergy.get("requires", ""))
		req_label.add_theme_font_size_override("font_size", 9)
		req_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		container.add_child(req_label)

		# Effects
		var effects: Array = synergy.get("effects", [])
		for effect in effects:
			var effect_label := Label.new()
			effect_label.text = "    + " + str(effect)
			effect_label.add_theme_font_size_override("font_size", 9)
			effect_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.3))
			container.add_child(effect_label)

		# Add spacing between synergies
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 4)
		vbox.add_child(spacer)


func _build_mechanics_section() -> void:
	var section := _create_section_panel("SYNERGY MECHANICS", Color(0.4, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in SYNERGY_MECHANICS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var topic_label := Label.new()
		topic_label.text = str(info.get("topic", ""))
		topic_label.add_theme_font_size_override("font_size", 10)
		topic_label.add_theme_color_override("font_color", info.get("color", Color.WHITE))
		topic_label.custom_minimum_size = Vector2(110, 0)
		hbox.add_child(topic_label)

		var desc_label := Label.new()
		desc_label.text = str(info.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("SYNERGY TIPS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in SYNERGY_TIPS:
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
