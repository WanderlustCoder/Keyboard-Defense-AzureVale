class_name WaveThemesPanel
extends PanelContainer
## Wave Themes Panel - Encyclopedia of wave themes, modifiers, and special events

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")
const SimWaveComposer = preload("res://sim/wave_composer.gd")

var _state: RefCounted = null

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Theme colors based on type
const THEME_COLORS: Dictionary = {
	"standard": Color(0.7, 0.7, 0.7),
	"swarm": Color(0.9, 0.6, 0.3),
	"elite": Color(0.8, 0.5, 0.9),
	"speedy": Color(0.4, 0.9, 0.9),
	"tanky": Color(0.6, 0.6, 0.7),
	"magic": Color(0.6, 0.3, 0.9),
	"undead": Color(0.5, 0.7, 0.5),
	"balanced": Color(0.7, 0.8, 0.6),
	"boss_assault": Color(0.9, 0.3, 0.3),
	"burning": Color(1.0, 0.4, 0.1),
	"frozen": Color(0.4, 0.8, 1.0)
}


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(520, 560)

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
	title.text = "WAVE THEMES"
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
	subtitle.text = "Enemy wave compositions and their characteristics"
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
	footer.text = "Wave themes unlock as you progress through days"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_wave_themes(state: RefCounted = null) -> void:
	_state = state
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Current day for unlock status
	var current_day: int = 1
	if _state != null:
		current_day = int(_state.day)

	# Wave themes section
	_build_themes_section(current_day)

	# Wave modifiers section
	_build_modifiers_section(current_day)

	# Special waves section
	_build_special_section(current_day)


func _build_themes_section(current_day: int) -> void:
	var section := _create_section_panel("WAVE THEMES", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Theme unlock days
	var unlock_days: Dictionary = {
		"standard": 1, "swarm": 2, "balanced": 2,
		"speedy": 3, "tanky": 3, "elite": 5,
		"magic": 5, "undead": 7, "burning": 7,
		"frozen": 10, "boss_assault": 10
	}

	for theme_id in SimWaveComposer.WAVE_THEMES.keys():
		var theme: Dictionary = SimWaveComposer.WAVE_THEMES[theme_id]
		var unlock_day: int = unlock_days.get(theme_id, 1)
		var is_unlocked: bool = current_day >= unlock_day
		var card := _create_theme_card(theme_id, theme, unlock_day, is_unlocked)
		vbox.add_child(card)


func _build_modifiers_section(current_day: int) -> void:
	var section := _create_section_panel("WAVE MODIFIERS", Color(0.9, 0.5, 0.5))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Modifier unlock days
	var unlock_days: Dictionary = {
		"swift": 3, "treasure": 3, "armored": 4,
		"enraged": 4, "toxic": 6, "double_trouble": 6,
		"shielded": 8, "vampiric": 10
	}

	for mod_id in SimWaveComposer.WAVE_MODIFIERS.keys():
		var modifier: Dictionary = SimWaveComposer.WAVE_MODIFIERS[mod_id]
		var unlock_day: int = unlock_days.get(mod_id, 3)
		var is_unlocked: bool = current_day >= unlock_day
		var card := _create_modifier_card(mod_id, modifier, unlock_day, is_unlocked)
		vbox.add_child(card)


func _build_special_section(current_day: int) -> void:
	var section := _create_section_panel("SPECIAL EVENTS", Color(0.9, 0.3, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var unlock_day: int = 5
	var is_unlocked: bool = current_day >= unlock_day

	for special_id in SimWaveComposer.SPECIAL_WAVES.keys():
		var special: Dictionary = SimWaveComposer.SPECIAL_WAVES[special_id]
		var card := _create_special_card(special_id, special, unlock_day, is_unlocked)
		vbox.add_child(card)


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
	vbox.add_theme_constant_override("separation", 8)
	container.add_child(vbox)

	var header := Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 13)
	header.add_theme_color_override("font_color", color)
	vbox.add_child(header)

	return container


func _create_theme_card(theme_id: String, theme: Dictionary, unlock_day: int, is_unlocked: bool) -> Control:
	var theme_name: String = str(theme.get("name", theme_id))
	var description: String = str(theme.get("description", ""))
	var color: Color = THEME_COLORS.get(theme_id, Color.WHITE)
	var enemy_weights: Dictionary = theme.get("enemy_weights", {})

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	if is_unlocked:
		container_style.bg_color = color.darkened(0.85)
		container_style.border_color = color.darkened(0.5)
	else:
		container_style.bg_color = Color(0.1, 0.1, 0.12, 0.6)
		container_style.border_color = Color(0.3, 0.3, 0.35)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(8)
	container.add_theme_stylebox_override("panel", container_style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 4)
	container.add_child(main_vbox)

	# Header row
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	main_vbox.add_child(header)

	var name_label := Label.new()
	name_label.text = theme_name
	name_label.add_theme_font_size_override("font_size", 13)
	if is_unlocked:
		name_label.add_theme_color_override("font_color", color)
	else:
		name_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)

	var unlock_label := Label.new()
	if is_unlocked:
		unlock_label.text = "Unlocked"
		unlock_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	else:
		unlock_label.text = "Day %d" % unlock_day
		unlock_label.add_theme_color_override("font_color", Color(0.6, 0.4, 0.4))
	unlock_label.add_theme_font_size_override("font_size", 10)
	header.add_child(unlock_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	main_vbox.add_child(desc_label)

	# Stats row
	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 10)
	main_vbox.add_child(stats_row)

	# Show stat modifiers
	if theme.has("hp_mult") and float(theme.get("hp_mult", 1.0)) != 1.0:
		var chip := _create_stat_chip("HP x%.1f" % float(theme.get("hp_mult", 1.0)), Color(0.9, 0.4, 0.4))
		stats_row.add_child(chip)

	if theme.has("speed_mult") and float(theme.get("speed_mult", 1.0)) != 1.0:
		var chip := _create_stat_chip("Speed x%.1f" % float(theme.get("speed_mult", 1.0)), Color(0.4, 0.9, 0.9))
		stats_row.add_child(chip)

	if theme.has("count_mult") and float(theme.get("count_mult", 1.0)) != 1.0:
		var chip := _create_stat_chip("Count x%.1f" % float(theme.get("count_mult", 1.0)), Color(0.9, 0.9, 0.4))
		stats_row.add_child(chip)

	if theme.has("gold_mult") and float(theme.get("gold_mult", 1.0)) != 1.0:
		var chip := _create_stat_chip("Gold x%.1f" % float(theme.get("gold_mult", 1.0)), Color(1.0, 0.84, 0.0))
		stats_row.add_child(chip)

	# Enemy composition
	if not enemy_weights.is_empty() and is_unlocked:
		var enemies_row := HBoxContainer.new()
		enemies_row.add_theme_constant_override("separation", 5)
		main_vbox.add_child(enemies_row)

		var enemies_prefix := Label.new()
		enemies_prefix.text = "Enemies:"
		enemies_prefix.add_theme_font_size_override("font_size", 9)
		enemies_prefix.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		enemies_row.add_child(enemies_prefix)

		var enemy_names: Array[String] = []
		for enemy_type in enemy_weights.keys():
			enemy_names.append(str(enemy_type).capitalize())

		var enemies_label := Label.new()
		enemies_label.text = ", ".join(enemy_names)
		enemies_label.add_theme_font_size_override("font_size", 9)
		enemies_label.add_theme_color_override("font_color", color.lightened(0.2))
		enemies_row.add_child(enemies_label)

	return container


func _create_modifier_card(mod_id: String, modifier: Dictionary, unlock_day: int, is_unlocked: bool) -> Control:
	var mod_name: String = str(modifier.get("name", mod_id))
	var description: String = str(modifier.get("description", ""))

	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", 10)

	var name_label := Label.new()
	name_label.text = mod_name
	name_label.add_theme_font_size_override("font_size", 11)
	if is_unlocked:
		name_label.add_theme_color_override("font_color", Color(0.9, 0.5, 0.5))
	else:
		name_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	name_label.custom_minimum_size = Vector2(120, 0)
	container.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(desc_label)

	if not is_unlocked:
		var unlock_label := Label.new()
		unlock_label.text = "Day %d" % unlock_day
		unlock_label.add_theme_font_size_override("font_size", 9)
		unlock_label.add_theme_color_override("font_color", Color(0.5, 0.4, 0.4))
		container.add_child(unlock_label)

	return container


func _create_special_card(special_id: String, special: Dictionary, unlock_day: int, is_unlocked: bool) -> Control:
	var special_name: String = str(special.get("name", special_id))
	var description: String = str(special.get("description", ""))

	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", 10)

	var name_label := Label.new()
	name_label.text = special_name
	name_label.add_theme_font_size_override("font_size", 11)
	if is_unlocked:
		name_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	else:
		name_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	name_label.custom_minimum_size = Vector2(100, 0)
	container.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(desc_label)

	if not is_unlocked:
		var unlock_label := Label.new()
		unlock_label.text = "Day %d+" % unlock_day
		unlock_label.add_theme_font_size_override("font_size", 9)
		unlock_label.add_theme_color_override("font_color", Color(0.5, 0.4, 0.4))
		container.add_child(unlock_label)

	return container


func _create_stat_chip(text: String, color: Color) -> Control:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", color)
	return label


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
