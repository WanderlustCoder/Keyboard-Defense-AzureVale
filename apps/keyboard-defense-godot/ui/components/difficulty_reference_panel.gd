class_name DifficultyReferencePanel
extends PanelContainer
## Difficulty Reference Panel - Shows all difficulty modes and their modifiers

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Difficulty modes (from SimDifficulty)
const DIFFICULTY_MODES: Array[Dictionary] = [
	{
		"id": "story",
		"name": "Story Mode",
		"desc": "Experience the tale of Keystonia at your own pace",
		"icon": "book",
		"enemy_health": 0.6,
		"enemy_damage": 0.5,
		"wave_size": 0.7,
		"gold_earned": 1.0,
		"recommended": "New typists, story enthusiasts",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"id": "adventure",
		"name": "Adventure Mode",
		"desc": "The intended experience - balanced challenge",
		"icon": "sword",
		"enemy_health": 1.0,
		"enemy_damage": 1.0,
		"wave_size": 1.0,
		"gold_earned": 1.0,
		"recommended": "Most players, 40-60 WPM",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"id": "champion",
		"name": "Champion Mode",
		"desc": "For experienced defenders - enemies hit harder",
		"icon": "crown",
		"enemy_health": 1.4,
		"enemy_damage": 1.5,
		"wave_size": 1.3,
		"gold_earned": 1.3,
		"recommended": "Skilled typists, 70+ WPM",
		"unlock": "Complete Act 3",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"id": "nightmare",
		"name": "Nightmare Mode",
		"desc": "The ultimate test - only the fastest survive",
		"icon": "skull",
		"enemy_health": 2.0,
		"enemy_damage": 2.0,
		"wave_size": 1.5,
		"gold_earned": 1.75,
		"recommended": "Elite typists, 100+ WPM",
		"unlock": "Complete Champion Mode",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"id": "zen",
		"name": "Zen Mode",
		"desc": "No pressure - pure typing practice",
		"icon": "lotus",
		"enemy_health": 0.0,
		"enemy_damage": 0.0,
		"wave_size": 0.0,
		"gold_earned": 0.25,
		"recommended": "Warm-up, focused practice",
		"color": Color(0.7, 0.5, 0.9)
	}
]

# Modifier explanations
const MODIFIER_INFO: Array[Dictionary] = [
	{"name": "Enemy HP", "desc": "Multiplier for enemy health points", "color": Color(0.4, 0.9, 0.4)},
	{"name": "Enemy Damage", "desc": "Multiplier for damage enemies deal", "color": Color(0.9, 0.4, 0.4)},
	{"name": "Wave Size", "desc": "Multiplier for enemies per wave", "color": Color(0.9, 0.6, 0.3)},
	{"name": "Gold Earned", "desc": "Multiplier for gold from kills", "color": Color(1.0, 0.84, 0.0)}
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(520, 600)

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
	title.text = "DIFFICULTY MODES"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3))
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
	subtitle.text = "Choose your challenge level"
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
	footer.text = "Change difficulty in Settings before starting a run"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_difficulty_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Modifier legend
	_build_legend_section()

	# Difficulty modes
	_build_modes_section()


func _build_legend_section() -> void:
	var section := _create_section_panel("STAT MODIFIERS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in MODIFIER_INFO:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(info.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", info.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(100, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(info.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_modes_section() -> void:
	var section := _create_section_panel("ALL MODES", Color(0.4, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for mode in DIFFICULTY_MODES:
		var card := _create_mode_card(mode)
		vbox.add_child(card)


func _create_mode_card(mode: Dictionary) -> Control:
	var name: String = str(mode.get("name", ""))
	var desc: String = str(mode.get("desc", ""))
	var recommended: String = str(mode.get("recommended", ""))
	var unlock: String = str(mode.get("unlock", ""))
	var color: Color = mode.get("color", Color.WHITE)

	var enemy_hp: float = float(mode.get("enemy_health", 1.0))
	var enemy_dmg: float = float(mode.get("enemy_damage", 1.0))
	var wave_size: float = float(mode.get("wave_size", 1.0))
	var gold: float = float(mode.get("gold_earned", 1.0))

	var container := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = color.darkened(0.8)
	card_style.border_color = color.darkened(0.5)
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(4)
	card_style.set_content_margin_all(8)
	container.add_theme_stylebox_override("panel", card_style)

	var card_vbox := VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 4)
	container.add_child(card_vbox)

	# Name row
	var name_row := HBoxContainer.new()
	card_vbox.add_child(name_row)

	var name_label := Label.new()
	name_label.text = name
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", color)
	name_row.add_child(name_label)

	if not unlock.is_empty():
		var unlock_label := Label.new()
		unlock_label.text = " [%s]" % unlock
		unlock_label.add_theme_font_size_override("font_size", 9)
		unlock_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		name_row.add_child(unlock_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = desc
	desc_label.add_theme_font_size_override("font_size", 9)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	card_vbox.add_child(desc_label)

	# Stats row
	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 12)
	card_vbox.add_child(stats_row)

	var hp_label := Label.new()
	hp_label.text = "HP:%.0f%%" % (enemy_hp * 100)
	hp_label.add_theme_font_size_override("font_size", 9)
	hp_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	stats_row.add_child(hp_label)

	var dmg_label := Label.new()
	dmg_label.text = "DMG:%.0f%%" % (enemy_dmg * 100)
	dmg_label.add_theme_font_size_override("font_size", 9)
	dmg_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
	stats_row.add_child(dmg_label)

	var wave_label := Label.new()
	wave_label.text = "Wave:%.0f%%" % (wave_size * 100)
	wave_label.add_theme_font_size_override("font_size", 9)
	wave_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3))
	stats_row.add_child(wave_label)

	var gold_label := Label.new()
	gold_label.text = "Gold:%.0f%%" % (gold * 100)
	gold_label.add_theme_font_size_override("font_size", 9)
	gold_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	stats_row.add_child(gold_label)

	# Recommended row
	var rec_label := Label.new()
	rec_label.text = "For: " + recommended
	rec_label.add_theme_font_size_override("font_size", 9)
	rec_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	card_vbox.add_child(rec_label)

	return container


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
