class_name ComboSystemPanel
extends PanelContainer
## Combo System Panel - Shows combo tiers, bonuses, and current combo status.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

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
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_MD, 480)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "COMBO SYSTEM"
	DesignSystem.style_label(title, "h2", ThemeColors.RESOURCE_GOLD)
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
	subtitle.text = "Chain words together for damage and gold bonuses"
	DesignSystem.style_label(subtitle, "body_small", ThemeColors.TEXT_DIM)
	main_vbox.add_child(subtitle)

	# Current combo display
	_build_current_combo_section(main_vbox)

	# Content scroll
	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_content_scroll)

	_content_vbox = DesignSystem.create_vbox(DesignSystem.SPACE_SM)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_vbox)

	# Footer
	var footer := Label.new()
	footer.text = "Mistakes reset your combo - type carefully!"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func _build_current_combo_section(parent: VBoxContainer) -> void:
	var section := PanelContainer.new()

	var section_style := StyleBoxFlat.new()
	section_style.bg_color = ThemeColors.BG_CARD
	section_style.border_color = ThemeColors.RESOURCE_GOLD.darkened(0.5)
	section_style.set_border_width_all(1)
	section_style.set_corner_radius_all(DesignSystem.RADIUS_SM)
	section_style.set_content_margin_all(DesignSystem.SPACE_MD)
	section.add_theme_stylebox_override("panel", section_style)

	parent.add_child(section)

	var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_LG)
	section.add_child(hbox)

	# Current combo count
	var combo_vbox := DesignSystem.create_vbox(2)
	hbox.add_child(combo_vbox)

	var combo_title := Label.new()
	combo_title.text = "CURRENT COMBO"
	DesignSystem.style_label(combo_title, "caption", ThemeColors.TEXT_DIM)
	combo_vbox.add_child(combo_title)

	_current_combo_label = Label.new()
	_current_combo_label.text = "x0"
	DesignSystem.style_label(_current_combo_label, "display", ThemeColors.TEXT)
	combo_vbox.add_child(_current_combo_label)

	var sep := VSeparator.new()
	sep.custom_minimum_size = Vector2(2, 40)
	hbox.add_child(sep)

	# Current tier
	var tier_vbox := DesignSystem.create_vbox(2)
	tier_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(tier_vbox)

	var tier_title := Label.new()
	tier_title.text = "TIER"
	DesignSystem.style_label(tier_title, "caption", ThemeColors.TEXT_DIM)
	tier_vbox.add_child(tier_title)

	_current_tier_label = Label.new()
	_current_tier_label.text = "No Combo"
	DesignSystem.style_label(_current_tier_label, "h3", ThemeColors.TEXT_DIM)
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
		_current_tier_label.add_theme_color_override("font_color", ThemeColors.TEXT_DISABLED)
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
	DesignSystem.style_label(header, "body", ThemeColors.RESOURCE_GOLD)
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
		container_style.bg_color = ThemeColors.BG_CARD_DISABLED
		container_style.border_color = ThemeColors.BORDER
		container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(DesignSystem.RADIUS_XS)
	container_style.set_content_margin_all(DesignSystem.SPACE_SM)
	container.add_theme_stylebox_override("panel", container_style)

	var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	container.add_child(hbox)

	# Tier number badge
	var tier_badge := _create_tier_badge(tier_num, color, is_reached)
	hbox.add_child(tier_badge)

	# Info column
	var info_vbox := DesignSystem.create_vbox(2)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	# Name and threshold
	var name_row := DesignSystem.create_hbox(DesignSystem.SPACE_SM)
	info_vbox.add_child(name_row)

	var name_label := Label.new()
	name_label.text = tier_name
	DesignSystem.style_label(name_label, "body", color if is_reached else ThemeColors.TEXT_DISABLED)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_label)

	var threshold := Label.new()
	threshold.text = "x%d+" % min_combo
	DesignSystem.style_label(threshold, "body_small", ThemeColors.TEXT_DIM)
	name_row.add_child(threshold)

	# Bonuses row
	var bonus_row := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	info_vbox.add_child(bonus_row)

	# Damage bonus
	var dmg_label := Label.new()
	dmg_label.text = "+%d%% Damage" % dmg_bonus
	DesignSystem.style_label(dmg_label, "caption", ThemeColors.ERROR if is_reached else ThemeColors.ERROR.darkened(0.5))
	bonus_row.add_child(dmg_label)

	# Gold bonus
	var gold_label := Label.new()
	gold_label.text = "+%d%% Gold" % gold_bonus
	DesignSystem.style_label(gold_label, "caption", ThemeColors.RESOURCE_GOLD if is_reached else ThemeColors.RESOURCE_GOLD.darkened(0.5))
	bonus_row.add_child(gold_label)

	# Current indicator
	if is_current:
		var current_label := Label.new()
		current_label.text = "CURRENT"
		DesignSystem.style_label(current_label, "caption", color)
		bonus_row.add_child(current_label)

	return container


func _create_tier_badge(tier_num: int, color: Color, is_reached: bool) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(36, 36)

	var panel_style := StyleBoxFlat.new()
	if is_reached:
		panel_style.bg_color = color.darkened(0.6)
	else:
		panel_style.bg_color = ThemeColors.BG_CARD_DISABLED
	panel_style.set_corner_radius_all(DesignSystem.RADIUS_XS)
	panel.add_theme_stylebox_override("panel", panel_style)

	var label := Label.new()
	label.text = str(tier_num)
	DesignSystem.style_label(label, "h3", color if is_reached else ThemeColors.TEXT_DISABLED)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(label)

	return panel


func _build_tips_section() -> void:
	var section := PanelContainer.new()

	var section_style := StyleBoxFlat.new()
	section_style.bg_color = ThemeColors.SUCCESS.darkened(0.85)
	section_style.border_color = ThemeColors.SUCCESS.darkened(0.5)
	section_style.set_border_width_all(1)
	section_style.set_corner_radius_all(DesignSystem.RADIUS_SM)
	section_style.set_content_margin_all(DesignSystem.SPACE_MD)
	section.add_theme_stylebox_override("panel", section_style)

	_content_vbox.add_child(section)

	var vbox := DesignSystem.create_vbox(DesignSystem.SPACE_SM)
	section.add_child(vbox)

	var header := Label.new()
	header.text = "COMBO TIPS"
	DesignSystem.style_label(header, "body_small", ThemeColors.SUCCESS)
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
		DesignSystem.style_label(tip_label, "caption", ThemeColors.TEXT_DIM)
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
