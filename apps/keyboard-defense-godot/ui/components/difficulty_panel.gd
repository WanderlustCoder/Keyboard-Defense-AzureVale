class_name DifficultyPanel
extends PanelContainer
## Difficulty Panel - View and change game difficulty mode.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed
signal difficulty_changed(mode_id: String)

const SimDifficulty = preload("res://sim/difficulty.gd")

var _current_mode: String = "adventure"
var _unlocked_modes: Array[String] = []

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Mode colors (domain-specific, kept as constant)
const MODE_COLORS: Dictionary = {
	"story": Color(0.4, 0.8, 0.4),     # Green
	"adventure": Color(0.4, 0.6, 1.0), # Blue
	"champion": Color(1.0, 0.84, 0.0), # Gold
	"nightmare": Color(0.8, 0.2, 0.2), # Red
	"zen": Color(0.7, 0.5, 0.9)        # Purple
}


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_MD + 40, 480)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "DIFFICULTY SETTINGS"
	DesignSystem.style_label(title, "h2", ThemeColors.ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.custom_minimum_size = Vector2(DesignSystem.SIZE_BUTTON_SM, DesignSystem.SIZE_BUTTON_SM)
	_style_close_button()
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Content scroll
	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_content_scroll)

	_content_vbox = DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_vbox)

	# Footer hint
	var footer := Label.new()
	footer.text = "Click a difficulty mode to select it"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_difficulty(current_mode: String, unlocked_modes: Array[String]) -> void:
	_current_mode = current_mode
	_unlocked_modes = unlocked_modes
	_build_modes_list()
	show()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_modes_list() -> void:
	_clear_content()

	# Current difficulty header
	var current_header := Label.new()
	current_header.text = "CURRENT: %s" % SimDifficulty.get_mode_name(_current_mode).to_upper()
	DesignSystem.style_label(current_header, "body_small", MODE_COLORS.get(_current_mode, Color.WHITE))
	_content_vbox.add_child(current_header)

	var sep := Control.new()
	sep.custom_minimum_size = Vector2(0, DesignSystem.SPACE_XS)
	_content_vbox.add_child(sep)

	# Build mode cards for all modes
	var all_modes: Array[String] = SimDifficulty.get_all_mode_ids()
	for mode_id in all_modes:
		var is_unlocked: bool = mode_id in _unlocked_modes
		var is_current: bool = mode_id == _current_mode
		var card := _create_mode_card(mode_id, is_unlocked, is_current)
		_content_vbox.add_child(card)


func _create_mode_card(mode_id: String, is_unlocked: bool, is_current: bool) -> Control:
	var mode: Dictionary = SimDifficulty.get_mode(mode_id)
	var name: String = str(mode.get("name", mode_id.capitalize()))
	var desc: String = str(mode.get("description", ""))
	var recommended: String = str(mode.get("recommended", ""))
	var color: Color = MODE_COLORS.get(mode_id, Color.WHITE)

	var container := PanelContainer.new()

	var container_style: StyleBoxFlat
	if is_current:
		container_style = DesignSystem.create_elevated_style(color.darkened(0.7))
		container_style.border_color = color
		container_style.set_border_width_all(2)
	elif is_unlocked:
		container_style = DesignSystem.create_elevated_style(ThemeColors.BG_CARD)
		container_style.border_color = color.darkened(0.5)
		container_style.set_border_width_all(1)
	else:
		container_style = DesignSystem.create_elevated_style(ThemeColors.BG_CARD_DISABLED)
		container_style.border_color = ThemeColors.BORDER
		container_style.set_border_width_all(1)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := DesignSystem.create_vbox(DesignSystem.SPACE_SM)
	container.add_child(vbox)

	# Header row: name + status
	var header_hbox := DesignSystem.create_hbox(DesignSystem.SPACE_SM)
	vbox.add_child(header_hbox)

	var name_label := Label.new()
	name_label.text = name
	if is_unlocked:
		DesignSystem.style_label(name_label, "body", color)
	else:
		DesignSystem.style_label(name_label, "body", ThemeColors.TEXT_DISABLED)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(name_label)

	if is_current:
		var status_label := Label.new()
		status_label.text = "CURRENT"
		DesignSystem.style_label(status_label, "caption", ThemeColors.SUCCESS)
		header_hbox.add_child(status_label)
	elif not is_unlocked:
		var lock_label := Label.new()
		lock_label.text = "LOCKED"
		DesignSystem.style_label(lock_label, "caption", ThemeColors.ERROR.darkened(0.2))
		header_hbox.add_child(lock_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = desc
	if is_unlocked:
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
	else:
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DISABLED)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	# Modifiers display
	var mods_panel := _create_modifiers_display(mode, is_unlocked)
	vbox.add_child(mods_panel)

	# Recommended
	if not recommended.is_empty():
		var rec_label := Label.new()
		rec_label.text = "Recommended: %s" % recommended
		if is_unlocked:
			DesignSystem.style_label(rec_label, "caption", ThemeColors.TEXT_DIM)
		else:
			DesignSystem.style_label(rec_label, "caption", ThemeColors.TEXT_DISABLED)
		vbox.add_child(rec_label)

	# Make clickable if unlocked and not current
	if is_unlocked and not is_current:
		var btn := Button.new()
		btn.text = "Select"
		btn.custom_minimum_size = Vector2(80, DesignSystem.SIZE_BUTTON_SM)
		_style_select_button(btn)
		btn.pressed.connect(_on_mode_selected.bind(mode_id))
		vbox.add_child(btn)

	return container


func _style_select_button(btn: Button) -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.BG_BUTTON_HOVER, ThemeColors.BORDER_HIGHLIGHT)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func _create_modifiers_display(mode: Dictionary, is_unlocked: bool) -> Control:
	var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_LG)

	# Enemy HP
	var hp_mult: float = float(mode.get("enemy_health", 1.0))
	var hp_stat := _create_stat_chip("HP", hp_mult, is_unlocked)
	hbox.add_child(hp_stat)

	# Enemy Damage
	var dmg_mult: float = float(mode.get("enemy_damage", 1.0))
	var dmg_stat := _create_stat_chip("DMG", dmg_mult, is_unlocked)
	hbox.add_child(dmg_stat)

	# Enemy Speed
	var spd_mult: float = float(mode.get("enemy_speed", 1.0))
	var spd_stat := _create_stat_chip("SPD", spd_mult, is_unlocked)
	hbox.add_child(spd_stat)

	# Wave Size
	var wave_mult: float = float(mode.get("wave_size", 1.0))
	var wave_stat := _create_stat_chip("WAVE", wave_mult, is_unlocked)
	hbox.add_child(wave_stat)

	# Gold Earned
	var gold_mult: float = float(mode.get("gold_earned", 1.0))
	var gold_stat := _create_stat_chip("GOLD", gold_mult, is_unlocked, true)
	hbox.add_child(gold_stat)

	return hbox


func _create_stat_chip(stat_name: String, multiplier: float, is_unlocked: bool, is_reward: bool = false) -> Control:
	var vbox := DesignSystem.create_vbox(0)

	var name_label := Label.new()
	name_label.text = stat_name
	if is_unlocked:
		DesignSystem.style_label(name_label, "caption", ThemeColors.TEXT_DIM)
	else:
		DesignSystem.style_label(name_label, "caption", ThemeColors.TEXT_DISABLED)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	var value_label := Label.new()
	var value_color: Color

	if multiplier == 0.0:
		value_label.text = "OFF"
		value_color = ThemeColors.TEXT_DISABLED if not is_unlocked else ThemeColors.TEXT_DIM
	elif multiplier == 1.0:
		value_label.text = "x1.0"
		value_color = ThemeColors.TEXT_DISABLED if not is_unlocked else ThemeColors.TEXT_DIM
	elif multiplier > 1.0:
		value_label.text = "x%.1f" % multiplier
		if is_reward:
			value_color = ThemeColors.TEXT_DISABLED if not is_unlocked else ThemeColors.SUCCESS
		else:
			value_color = ThemeColors.TEXT_DISABLED if not is_unlocked else ThemeColors.ERROR
	else:
		value_label.text = "x%.1f" % multiplier
		if is_reward:
			value_color = ThemeColors.TEXT_DISABLED if not is_unlocked else ThemeColors.ERROR
		else:
			value_color = ThemeColors.TEXT_DISABLED if not is_unlocked else ThemeColors.SUCCESS

	DesignSystem.style_label(value_label, "caption", value_color)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(value_label)

	return vbox


func _on_mode_selected(mode_id: String) -> void:
	_current_mode = mode_id
	difficulty_changed.emit(mode_id)
	_build_modes_list()


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
