class_name DifficultyModesPanel
extends PanelContainer
## Difficulty Modes Panel - Shows all difficulty modes and their modifiers

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Difficulty mode data (from SimDifficulty)
const DIFFICULTY_MODES: Array[Dictionary] = [
	{
		"id": "story",
		"name": "Story Mode",
		"description": "Experience the tale of Keystonia at your own pace",
		"recommended": "New typists, story enthusiasts",
		"color": Color(0.5, 0.8, 0.3),
		"modifiers": {
			"enemy_health": 0.6,
			"enemy_damage": 0.5,
			"enemy_speed": 0.8,
			"wave_size": 0.7,
			"gold_earned": 1.0,
			"typo_forgiveness": 2
		}
	},
	{
		"id": "adventure",
		"name": "Adventure Mode",
		"description": "The intended experience. Balanced challenge that rewards skill",
		"recommended": "Most players, 40-60 WPM",
		"color": Color(0.4, 0.8, 1.0),
		"modifiers": {
			"enemy_health": 1.0,
			"enemy_damage": 1.0,
			"enemy_speed": 1.0,
			"wave_size": 1.0,
			"gold_earned": 1.0,
			"typo_forgiveness": 1
		}
	},
	{
		"id": "champion",
		"name": "Champion Mode",
		"description": "For experienced defenders. Enemies hit harder, margins are thin",
		"recommended": "Skilled typists, 70+ WPM",
		"color": Color(0.9, 0.6, 0.3),
		"modifiers": {
			"enemy_health": 1.4,
			"enemy_damage": 1.5,
			"enemy_speed": 1.2,
			"wave_size": 1.3,
			"gold_earned": 1.3,
			"typo_forgiveness": 0
		},
		"unlock": "Complete Act 3"
	},
	{
		"id": "nightmare",
		"name": "Nightmare Mode",
		"description": "The ultimate test. Only the fastest survive",
		"recommended": "Elite typists, 100+ WPM",
		"color": Color(0.9, 0.4, 0.4),
		"modifiers": {
			"enemy_health": 2.0,
			"enemy_damage": 2.0,
			"enemy_speed": 1.4,
			"wave_size": 1.5,
			"gold_earned": 1.75,
			"typo_forgiveness": 0
		},
		"unlock": "Complete Champion Mode"
	},
	{
		"id": "zen",
		"name": "Zen Mode",
		"description": "No pressure. Pure typing practice with no enemies",
		"recommended": "Warm-up, focused practice",
		"color": Color(0.7, 0.5, 0.9),
		"modifiers": {
			"enemy_health": 0.0,
			"enemy_damage": 0.0,
			"enemy_speed": 0.0,
			"wave_size": 0.0,
			"gold_earned": 0.25,
			"typo_forgiveness": 99
		}
	}
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(540, 600)

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
	_content_vbox.add_theme_constant_override("separation", 8)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_vbox)

	# Footer
	var footer := Label.new()
	footer.text = "Difficulty affects enemy stats, gold, and typing forgiveness"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_difficulty_modes() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	for mode in DIFFICULTY_MODES:
		var card := _create_mode_card(mode)
		_content_vbox.add_child(card)


func _create_mode_card(mode: Dictionary) -> Control:
	var name_str: String = str(mode.get("name", ""))
	var description: String = str(mode.get("description", ""))
	var recommended: String = str(mode.get("recommended", ""))
	var unlock: String = str(mode.get("unlock", ""))
	var color: Color = mode.get("color", Color.WHITE)
	var modifiers: Dictionary = mode.get("modifiers", {})

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = color.darkened(0.85)
	container_style.border_color = color.darkened(0.6)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", container_style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 5)
	container.add_child(main_vbox)

	# Header
	var name_label := Label.new()
	name_label.text = name_str
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", color)
	main_vbox.add_child(name_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_vbox.add_child(desc_label)

	# Modifiers grid
	var mod_grid := GridContainer.new()
	mod_grid.columns = 3
	mod_grid.add_theme_constant_override("h_separation", 15)
	mod_grid.add_theme_constant_override("v_separation", 2)
	main_vbox.add_child(mod_grid)

	var health: float = float(modifiers.get("enemy_health", 1.0))
	var damage: float = float(modifiers.get("enemy_damage", 1.0))
	var speed: float = float(modifiers.get("enemy_speed", 1.0))
	var wave: float = float(modifiers.get("wave_size", 1.0))
	var gold: float = float(modifiers.get("gold_earned", 1.0))
	var forgive: int = int(modifiers.get("typo_forgiveness", 1))

	_add_modifier(mod_grid, "HP", "x%.1f" % health, _get_modifier_color(health, true))
	_add_modifier(mod_grid, "DMG", "x%.1f" % damage, _get_modifier_color(damage, true))
	_add_modifier(mod_grid, "SPD", "x%.1f" % speed, _get_modifier_color(speed, true))
	_add_modifier(mod_grid, "Wave", "x%.1f" % wave, _get_modifier_color(wave, true))
	_add_modifier(mod_grid, "Gold", "x%.2f" % gold, _get_modifier_color(gold, false))
	_add_modifier(mod_grid, "Typo", "%d" % forgive, _get_modifier_color(float(forgive), false))

	# Recommended
	var rec_label := Label.new()
	rec_label.text = "For: " + recommended
	rec_label.add_theme_font_size_override("font_size", 9)
	rec_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5))
	main_vbox.add_child(rec_label)

	# Unlock requirement
	if not unlock.is_empty():
		var unlock_label := Label.new()
		unlock_label.text = "Unlock: " + unlock
		unlock_label.add_theme_font_size_override("font_size", 9)
		unlock_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3))
		main_vbox.add_child(unlock_label)

	return container


func _add_modifier(grid: GridContainer, label: String, value: String, color: Color) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 3)

	var label_node := Label.new()
	label_node.text = label + ":"
	label_node.add_theme_font_size_override("font_size", 9)
	label_node.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	hbox.add_child(label_node)

	var value_node := Label.new()
	value_node.text = value
	value_node.add_theme_font_size_override("font_size", 9)
	value_node.add_theme_color_override("font_color", color)
	hbox.add_child(value_node)

	grid.add_child(hbox)


func _get_modifier_color(value: float, higher_is_harder: bool) -> Color:
	if value == 1.0 or value == 0.0:
		return ThemeColors.TEXT_DIM
	if higher_is_harder:
		return Color(0.9, 0.4, 0.4) if value > 1.0 else Color(0.5, 0.8, 0.3)
	else:
		return Color(0.5, 0.8, 0.3) if value > 1.0 else Color(0.9, 0.4, 0.4)


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
