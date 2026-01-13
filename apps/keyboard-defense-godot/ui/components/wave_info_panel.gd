class_name WaveInfoPanel
extends PanelContainer
## Wave Info Panel - Shows current wave composition and modifiers.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

var _day: int = 1
var _wave: int = 1
var _waves_per_day: int = 3
var _composition: Dictionary = {}

# UI elements
var _close_btn: Button = null
var _content_vbox: VBoxContainer = null

# Theme colors
const THEME_COLORS: Dictionary = {
	"standard": Color(0.6, 0.6, 0.8),
	"swarm": Color(0.4, 0.8, 0.4),
	"elite": Color(1.0, 0.84, 0.0),
	"speedy": Color(0.4, 0.8, 1.0),
	"tanky": Color(0.7, 0.5, 0.3),
	"magic": Color(0.8, 0.4, 1.0),
	"undead": Color(0.5, 0.7, 0.5),
	"balanced": Color(0.6, 0.6, 0.6),
	"boss_assault": Color(1.0, 0.5, 0.3),
	"burning": Color(1.0, 0.4, 0.2),
	"frozen": Color(0.3, 0.7, 1.0)
}


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_MD, 350)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "WAVE INFORMATION"
	DesignSystem.style_label(title, "h2", ThemeColors.ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.custom_minimum_size = Vector2(DesignSystem.SIZE_BUTTON_SM, DesignSystem.SIZE_BUTTON_SM)
	_style_close_button()
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Content
	_content_vbox = DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(_content_vbox)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_wave_info(day: int, wave: int, waves_per_day: int, composition: Dictionary) -> void:
	_day = day
	_wave = wave
	_waves_per_day = waves_per_day
	_composition = composition
	_build_content()
	show()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Day/Wave display
	var progress_panel := _create_progress_panel()
	_content_vbox.add_child(progress_panel)

	if _composition.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No wave composition data available."
		empty_label.add_theme_font_size_override("font_size", 12)
		empty_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		_content_vbox.add_child(empty_label)
		return

	# Theme display
	var theme_panel := _create_theme_panel()
	_content_vbox.add_child(theme_panel)

	# Modifiers
	var modifiers: Array = _composition.get("modifier_names", [])
	if not modifiers.is_empty():
		var mod_panel := _create_modifiers_panel(modifiers)
		_content_vbox.add_child(mod_panel)

	# Stats
	var stats_panel := _create_stats_panel()
	_content_vbox.add_child(stats_panel)


func _create_progress_panel() -> Control:
	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = Color(0.1, 0.12, 0.18, 0.9)
	container_style.border_color = ThemeColors.ACCENT.darkened(0.5)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(6)
	container_style.set_content_margin_all(12)
	container.add_theme_stylebox_override("panel", container_style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 30)
	container.add_child(hbox)

	# Day info
	var day_vbox := VBoxContainer.new()
	day_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(day_vbox)

	var day_header := Label.new()
	day_header.text = "DAY"
	day_header.add_theme_font_size_override("font_size", 11)
	day_header.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	day_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_vbox.add_child(day_header)

	var day_value := Label.new()
	day_value.text = str(_day)
	day_value.add_theme_font_size_override("font_size", 24)
	day_value.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	day_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_vbox.add_child(day_value)

	# Wave info
	var wave_vbox := VBoxContainer.new()
	wave_vbox.add_theme_constant_override("separation", 2)
	wave_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(wave_vbox)

	var wave_header := Label.new()
	wave_header.text = "WAVE"
	wave_header.add_theme_font_size_override("font_size", 11)
	wave_header.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	wave_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_vbox.add_child(wave_header)

	var wave_value := Label.new()
	wave_value.text = "%d / %d" % [_wave, _waves_per_day]
	wave_value.add_theme_font_size_override("font_size", 24)
	wave_value.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	wave_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_vbox.add_child(wave_value)

	# Progress bar
	var progress_bar := ProgressBar.new()
	progress_bar.value = float(_wave) / float(maxi(1, _waves_per_day)) * 100.0
	progress_bar.custom_minimum_size = Vector2(0, 8)
	progress_bar.show_percentage = false
	wave_vbox.add_child(progress_bar)

	# Enemy count
	var enemy_vbox := VBoxContainer.new()
	enemy_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(enemy_vbox)

	var enemy_header := Label.new()
	enemy_header.text = "ENEMIES"
	enemy_header.add_theme_font_size_override("font_size", 11)
	enemy_header.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	enemy_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_vbox.add_child(enemy_header)

	var enemy_count: int = int(_composition.get("enemy_count", 0))
	var enemy_value := Label.new()
	enemy_value.text = str(enemy_count)
	enemy_value.add_theme_font_size_override("font_size", 24)
	enemy_value.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	enemy_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_vbox.add_child(enemy_value)

	return container


func _create_theme_panel() -> Control:
	var theme_id: String = str(_composition.get("theme", "standard"))
	var theme_name: String = str(_composition.get("theme_name", "Standard"))
	var description: String = str(_composition.get("description", ""))
	var color: Color = THEME_COLORS.get(theme_id, Color.WHITE)

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = Color(0.06, 0.07, 0.1, 0.9)
	container_style.border_color = color.darkened(0.4)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	container.add_child(vbox)

	var header := Label.new()
	header.text = "THEME"
	header.add_theme_font_size_override("font_size", 10)
	header.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(header)

	var name_label := Label.new()
	name_label.text = theme_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", color)
	vbox.add_child(name_label)

	if not description.is_empty():
		var desc_label := Label.new()
		desc_label.text = description
		desc_label.add_theme_font_size_override("font_size", 11)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		vbox.add_child(desc_label)

	return container


func _create_modifiers_panel(modifiers: Array) -> Control:
	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = Color(0.08, 0.06, 0.04, 0.9)
	container_style.border_color = Color(1.0, 0.6, 0.3, 0.5)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	container.add_child(vbox)

	var header := Label.new()
	header.text = "MODIFIERS"
	header.add_theme_font_size_override("font_size", 10)
	header.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(header)

	var mod_hbox := HBoxContainer.new()
	mod_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(mod_hbox)

	for mod_name in modifiers:
		var mod_label := Label.new()
		mod_label.text = str(mod_name)
		mod_label.add_theme_font_size_override("font_size", 12)
		mod_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))

		var mod_container := PanelContainer.new()
		var mod_style := StyleBoxFlat.new()
		mod_style.bg_color = Color(0.15, 0.1, 0.05, 0.8)
		mod_style.set_corner_radius_all(3)
		mod_style.set_content_margin_all(4)
		mod_container.add_theme_stylebox_override("panel", mod_style)
		mod_container.add_child(mod_label)
		mod_hbox.add_child(mod_container)

	return container


func _create_stats_panel() -> Control:
	var hp_mult: float = float(_composition.get("hp_mult", 1.0))
	var speed_mult: float = float(_composition.get("speed_mult", 1.0))
	var gold_mult: float = float(_composition.get("gold_mult", 1.0))
	var damage_mult: float = float(_composition.get("damage_mult", 1.0))

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = Color(0.06, 0.07, 0.1, 0.9)
	container_style.border_color = ThemeColors.BORDER_DISABLED
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	container.add_child(vbox)

	var header := Label.new()
	header.text = "STAT MODIFIERS"
	header.add_theme_font_size_override("font_size", 10)
	header.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(header)

	var stats_hbox := HBoxContainer.new()
	stats_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(stats_hbox)

	# HP
	var hp_stat := _create_stat_display("HP", hp_mult, Color(1.0, 0.4, 0.4))
	stats_hbox.add_child(hp_stat)

	# Speed
	var speed_stat := _create_stat_display("SPD", speed_mult, Color(0.4, 0.8, 1.0))
	stats_hbox.add_child(speed_stat)

	# Gold
	var gold_stat := _create_stat_display("GOLD", gold_mult, Color(1.0, 0.84, 0.0))
	stats_hbox.add_child(gold_stat)

	# Damage
	if damage_mult != 1.0:
		var dmg_stat := _create_stat_display("DMG", damage_mult, Color(1.0, 0.5, 0.3))
		stats_hbox.add_child(dmg_stat)

	return container


func _create_stat_display(stat_name: String, multiplier: float, color: Color) -> Control:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	var name_label := Label.new()
	name_label.text = stat_name
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	var value_label := Label.new()
	if multiplier == 1.0:
		value_label.text = "x1.0"
		value_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	elif multiplier > 1.0:
		value_label.text = "x%.1f" % multiplier
		value_label.add_theme_color_override("font_color", color)
	else:
		value_label.text = "x%.1f" % multiplier
		value_label.add_theme_color_override("font_color", color.darkened(0.3))

	value_label.add_theme_font_size_override("font_size", 16)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(value_label)

	return vbox


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
