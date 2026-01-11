class_name DifficultyModesReferencePanel
extends PanelContainer
## Difficulty Modes Reference Panel - Shows all difficulty modes and modifiers

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Difficulty modes
const DIFFICULTY_MODES: Array[Dictionary] = [
	{
		"id": "story",
		"name": "Story Mode",
		"icon": "book",
		"desc": "Experience the tale of Keystonia at your own pace",
		"recommended": "New typists, story enthusiasts",
		"unlock": "Always available",
		"enemy_hp": 60,
		"enemy_dmg": 50,
		"enemy_spd": 80,
		"wave_size": 70,
		"gold": 100,
		"typo_forgive": 2,
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"id": "adventure",
		"name": "Adventure Mode",
		"icon": "sword",
		"desc": "The intended experience. Balanced challenge that rewards skill",
		"recommended": "Most players, 40-60 WPM",
		"unlock": "Always available",
		"enemy_hp": 100,
		"enemy_dmg": 100,
		"enemy_spd": 100,
		"wave_size": 100,
		"gold": 100,
		"typo_forgive": 1,
		"color": Color(0.5, 0.7, 0.9)
	},
	{
		"id": "champion",
		"name": "Champion Mode",
		"icon": "crown",
		"desc": "For experienced defenders. Enemies hit harder, margins are thin",
		"recommended": "Skilled typists, 70+ WPM",
		"unlock": "Complete Act 3",
		"enemy_hp": 140,
		"enemy_dmg": 150,
		"enemy_spd": 120,
		"wave_size": 130,
		"gold": 130,
		"typo_forgive": 0,
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"id": "nightmare",
		"name": "Nightmare Mode",
		"icon": "skull",
		"desc": "The ultimate test. Only the fastest survive",
		"recommended": "Elite typists, 100+ WPM",
		"unlock": "Complete Champion",
		"enemy_hp": 200,
		"enemy_dmg": 200,
		"enemy_spd": 140,
		"wave_size": 150,
		"gold": 175,
		"typo_forgive": 0,
		"color": Color(0.8, 0.2, 0.2)
	},
	{
		"id": "zen",
		"name": "Zen Mode",
		"icon": "lotus",
		"desc": "No pressure. Pure typing practice with no enemies",
		"recommended": "Warm-up, focused practice",
		"unlock": "Always available",
		"enemy_hp": 0,
		"enemy_dmg": 0,
		"enemy_spd": 0,
		"wave_size": 0,
		"gold": 25,
		"typo_forgive": 99,
		"color": Color(0.6, 0.4, 0.8)
	}
]

# Mode modifiers explanation
const MODIFIER_INFO: Array[Dictionary] = [
	{
		"name": "Enemy HP",
		"desc": "Multiplier to enemy health points",
		"color": Color(0.96, 0.26, 0.21)
	},
	{
		"name": "Enemy Damage",
		"desc": "Multiplier to damage enemies deal to castle",
		"color": Color(0.8, 0.4, 0.4)
	},
	{
		"name": "Enemy Speed",
		"desc": "Multiplier to enemy movement speed",
		"color": Color(0.5, 0.8, 1.0)
	},
	{
		"name": "Wave Size",
		"desc": "Multiplier to number of enemies per wave",
		"color": Color(0.6, 0.5, 0.7)
	},
	{
		"name": "Gold Earned",
		"desc": "Multiplier to gold from defeating enemies",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"name": "Typo Forgiveness",
		"desc": "Number of typos allowed before word resets",
		"color": Color(0.5, 0.8, 0.3)
	}
]

# Difficulty tips
const DIFFICULTY_TIPS: Array[String] = [
	"Story Mode is perfect for learning typing without stress",
	"Adventure Mode is the standard balanced experience",
	"Champion Mode rewards gold at 130% - risk vs reward",
	"Nightmare gives 175% gold but enemies are brutal",
	"Zen Mode is ideal for warming up or practicing new lessons",
	"Typo forgiveness of 0 means any mistake resets the word"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(560, 680)

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
	title.add_theme_color_override("font_color", Color(0.8, 0.5, 0.9))
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
	subtitle.text = "5 difficulty modes from Story to Nightmare"
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
	footer.text = "Change difficulty from Settings menu"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_difficulty_modes_reference() -> void:
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
	_build_modifiers_section()

	# Each difficulty mode
	for mode in DIFFICULTY_MODES:
		_build_mode_section(mode)

	# Tips
	_build_tips_section()


func _build_modifiers_section() -> void:
	var section := _create_section_panel("MODIFIER LEGEND", Color(0.6, 0.6, 0.8))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for mod in MODIFIER_INFO:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(mod.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 9)
		name_label.add_theme_color_override("font_color", mod.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(100, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(mod.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_mode_section(mode: Dictionary) -> void:
	var color: Color = mode.get("color", Color.WHITE)
	var section := _create_section_panel(str(mode.get("name", "")).to_upper(), color)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Description
	var desc_label := Label.new()
	desc_label.text = str(mode.get("desc", ""))
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", Color.WHITE)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	# Recommended
	var rec_label := Label.new()
	rec_label.text = "Recommended: " + str(mode.get("recommended", ""))
	rec_label.add_theme_font_size_override("font_size", 9)
	rec_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.3))
	vbox.add_child(rec_label)

	# Unlock
	var unlock_label := Label.new()
	unlock_label.text = "Unlock: " + str(mode.get("unlock", ""))
	unlock_label.add_theme_font_size_override("font_size", 9)
	unlock_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(unlock_label)

	# Modifiers (skip for Zen which has 0 enemies)
	if mode.get("id", "") != "zen":
		var mods_hbox := HBoxContainer.new()
		mods_hbox.add_theme_constant_override("separation", 8)
		vbox.add_child(mods_hbox)

		var hp_label := Label.new()
		hp_label.text = "HP:%d%%" % mode.get("enemy_hp", 100)
		hp_label.add_theme_font_size_override("font_size", 9)
		hp_label.add_theme_color_override("font_color", Color(0.96, 0.26, 0.21))
		mods_hbox.add_child(hp_label)

		var dmg_label := Label.new()
		dmg_label.text = "Dmg:%d%%" % mode.get("enemy_dmg", 100)
		dmg_label.add_theme_font_size_override("font_size", 9)
		dmg_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4))
		mods_hbox.add_child(dmg_label)

		var spd_label := Label.new()
		spd_label.text = "Spd:%d%%" % mode.get("enemy_spd", 100)
		spd_label.add_theme_font_size_override("font_size", 9)
		spd_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
		mods_hbox.add_child(spd_label)

		var wave_label := Label.new()
		wave_label.text = "Wave:%d%%" % mode.get("wave_size", 100)
		wave_label.add_theme_font_size_override("font_size", 9)
		wave_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.7))
		mods_hbox.add_child(wave_label)

		var gold_label := Label.new()
		gold_label.text = "Gold:%d%%" % mode.get("gold", 100)
		gold_label.add_theme_font_size_override("font_size", 9)
		gold_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		mods_hbox.add_child(gold_label)

		var typo_label := Label.new()
		typo_label.text = "Typo:%d" % mode.get("typo_forgive", 1)
		typo_label.add_theme_font_size_override("font_size", 9)
		typo_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.3))
		mods_hbox.add_child(typo_label)
	else:
		var zen_label := Label.new()
		zen_label.text = "No enemies - pure practice mode"
		zen_label.add_theme_font_size_override("font_size", 9)
		zen_label.add_theme_color_override("font_color", Color(0.6, 0.4, 0.8))
		vbox.add_child(zen_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("DIFFICULTY TIPS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in DIFFICULTY_TIPS:
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
