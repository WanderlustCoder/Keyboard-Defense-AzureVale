class_name ComboSystemPanel
extends PanelContainer
## Combo System Panel - Shows combo tiers, bonuses, and current combo status

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")
const SimCombo = preload("res://sim/combo.gd")

var _state: RefCounted = null

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null
var _current_combo_label: Label = null
var _current_tier_label: Label = null


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(440, 480)

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
	title.text = "COMBO SYSTEM"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
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
	subtitle.text = "Chain words together for damage and gold bonuses"
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	main_vbox.add_child(subtitle)

	# Current combo display
	_build_current_combo_section(main_vbox)

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
	footer.text = "Mistakes reset your combo - type carefully!"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _build_current_combo_section(parent: VBoxContainer) -> void:
	var section := PanelContainer.new()

	var section_style := StyleBoxFlat.new()
	section_style.bg_color = Color(0.12, 0.12, 0.16, 0.9)
	section_style.border_color = Color(1.0, 0.84, 0.0, 0.5)
	section_style.set_border_width_all(1)
	section_style.set_corner_radius_all(6)
	section_style.set_content_margin_all(12)
	section.add_theme_stylebox_override("panel", section_style)

	parent.add_child(section)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	section.add_child(hbox)

	# Current combo count
	var combo_vbox := VBoxContainer.new()
	combo_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(combo_vbox)

	var combo_title := Label.new()
	combo_title.text = "CURRENT COMBO"
	combo_title.add_theme_font_size_override("font_size", 10)
	combo_title.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	combo_vbox.add_child(combo_title)

	_current_combo_label = Label.new()
	_current_combo_label.text = "x0"
	_current_combo_label.add_theme_font_size_override("font_size", 24)
	_current_combo_label.add_theme_color_override("font_color", Color.WHITE)
	combo_vbox.add_child(_current_combo_label)

	var sep := VSeparator.new()
	sep.custom_minimum_size = Vector2(2, 40)
	hbox.add_child(sep)

	# Current tier
	var tier_vbox := VBoxContainer.new()
	tier_vbox.add_theme_constant_override("separation", 2)
	tier_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(tier_vbox)

	var tier_title := Label.new()
	tier_title.text = "TIER"
	tier_title.add_theme_font_size_override("font_size", 10)
	tier_title.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	tier_vbox.add_child(tier_title)

	_current_tier_label = Label.new()
	_current_tier_label.text = "No Combo"
	_current_tier_label.add_theme_font_size_override("font_size", 16)
	_current_tier_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	tier_vbox.add_child(_current_tier_label)


func show_combo_system(state: RefCounted = null) -> void:
	_state = state
	_build_content()
	_update_current_combo()
	show()


func refresh() -> void:
	_build_content()
	_update_current_combo()


func _update_current_combo() -> void:
	var combo: int = 0
	if _state != null and "combo" in _state:
		combo = int(_state.combo)

	_current_combo_label.text = "x%d" % combo

	var tier: Dictionary = SimCombo.get_tier_for_combo(combo)
	var tier_name: String = str(tier.get("name", ""))
	var tier_color: Color = Color.from_string(str(tier.get("color", "#FFFFFF")), Color.WHITE)

	if tier_name.is_empty():
		_current_tier_label.text = "No Combo"
		_current_tier_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	else:
		_current_tier_label.text = tier_name
		_current_tier_label.add_theme_color_override("font_color", tier_color)

	_current_combo_label.add_theme_color_override("font_color", tier_color)


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Tiers section header
	var header := Label.new()
	header.text = "COMBO TIERS"
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	_content_vbox.add_child(header)

	# Get current combo for highlighting
	var current_combo: int = 0
	if _state != null and "combo" in _state:
		current_combo = int(_state.combo)

	var current_tier: int = SimCombo.get_tier_number(current_combo)

	# Build tier cards (skip tier 0 which is "no combo")
	for tier_data in SimCombo.TIERS:
		var tier_num: int = int(tier_data.get("tier", 0))
		if tier_num == 0:
			continue

		var is_current: bool = tier_num == current_tier
		var is_reached: bool = tier_num <= current_tier
		var card := _create_tier_card(tier_data, is_current, is_reached)
		_content_vbox.add_child(card)

	# Tips section
	_build_tips_section()


func _create_tier_card(tier_data: Dictionary, is_current: bool, is_reached: bool) -> Control:
	var tier_num: int = int(tier_data.get("tier", 0))
	var tier_name: String = str(tier_data.get("name", ""))
	var min_combo: int = int(tier_data.get("min_combo", 0))
	var dmg_bonus: int = int(tier_data.get("damage_bonus", 0))
	var gold_bonus: int = int(tier_data.get("gold_bonus", 0))
	var color: Color = Color.from_string(str(tier_data.get("color", "#FFFFFF")), Color.WHITE)

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	if is_current:
		container_style.bg_color = color.darkened(0.7)
		container_style.border_color = color
		container_style.set_border_width_all(2)
	elif is_reached:
		container_style.bg_color = color.darkened(0.85)
		container_style.border_color = color.darkened(0.4)
		container_style.set_border_width_all(1)
	else:
		container_style.bg_color = Color(0.1, 0.1, 0.12, 0.6)
		container_style.border_color = Color(0.3, 0.3, 0.35)
		container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(8)
	container.add_theme_stylebox_override("panel", container_style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	container.add_child(hbox)

	# Tier number badge
	var tier_badge := _create_tier_badge(tier_num, color, is_reached)
	hbox.add_child(tier_badge)

	# Info column
	var info_vbox := VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 2)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	# Name and threshold
	var name_row := HBoxContainer.new()
	info_vbox.add_child(name_row)

	var name_label := Label.new()
	name_label.text = tier_name
	name_label.add_theme_font_size_override("font_size", 14)
	if is_reached:
		name_label.add_theme_color_override("font_color", color)
	else:
		name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_label)

	var threshold := Label.new()
	threshold.text = "x%d+" % min_combo
	threshold.add_theme_font_size_override("font_size", 12)
	threshold.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	name_row.add_child(threshold)

	# Bonuses row
	var bonus_row := HBoxContainer.new()
	bonus_row.add_theme_constant_override("separation", 15)
	info_vbox.add_child(bonus_row)

	# Damage bonus
	var dmg_label := Label.new()
	dmg_label.text = "+%d%% Damage" % dmg_bonus
	dmg_label.add_theme_font_size_override("font_size", 11)
	if is_reached:
		dmg_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
	else:
		dmg_label.add_theme_color_override("font_color", Color(0.4, 0.3, 0.3))
	bonus_row.add_child(dmg_label)

	# Gold bonus
	var gold_label := Label.new()
	gold_label.text = "+%d%% Gold" % gold_bonus
	gold_label.add_theme_font_size_override("font_size", 11)
	if is_reached:
		gold_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	else:
		gold_label.add_theme_color_override("font_color", Color(0.4, 0.35, 0.2))
	bonus_row.add_child(gold_label)

	# Current indicator
	if is_current:
		var current_label := Label.new()
		current_label.text = "CURRENT"
		current_label.add_theme_font_size_override("font_size", 10)
		current_label.add_theme_color_override("font_color", color)
		bonus_row.add_child(current_label)

	return container


func _create_tier_badge(tier_num: int, color: Color, is_reached: bool) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(36, 36)

	var panel_style := StyleBoxFlat.new()
	if is_reached:
		panel_style.bg_color = color.darkened(0.6)
	else:
		panel_style.bg_color = Color(0.15, 0.15, 0.18)
	panel_style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", panel_style)

	var label := Label.new()
	label.text = str(tier_num)
	label.add_theme_font_size_override("font_size", 16)
	if is_reached:
		label.add_theme_color_override("font_color", color)
	else:
		label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(label)

	return panel


func _build_tips_section() -> void:
	var section := PanelContainer.new()

	var section_style := StyleBoxFlat.new()
	section_style.bg_color = Color(0.15, 0.18, 0.12, 0.8)
	section_style.border_color = Color(0.4, 0.6, 0.3)
	section_style.set_border_width_all(1)
	section_style.set_corner_radius_all(6)
	section_style.set_content_margin_all(10)
	section.add_theme_stylebox_override("panel", section_style)

	_content_vbox.add_child(section)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	section.add_child(vbox)

	var header := Label.new()
	header.text = "COMBO TIPS"
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(0.6, 0.9, 0.5))
	vbox.add_child(header)

	var tips: Array[String] = [
		"Type words correctly to build combo",
		"Any mistake resets combo to zero",
		"Higher combo = more damage + more gold",
		"GODLIKE combo doubles all rewards!"
	]

	for tip in tips:
		var tip_label := Label.new()
		tip_label.text = "- " + tip
		tip_label.add_theme_font_size_override("font_size", 10)
		tip_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		vbox.add_child(tip_label)


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
