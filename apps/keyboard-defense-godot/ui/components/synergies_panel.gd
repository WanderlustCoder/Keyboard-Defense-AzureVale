class_name SynergiesPanel
extends PanelContainer
## Synergies Panel - Shows tower synergy combinations and their effects.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

const SimSynergyDetector = preload("res://sim/synergy_detector.gd")

var _state: Variant = null  # GameState
var _show_all: bool = false

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null
var _toggle_btn: Button = null
var _active_count_label: Label = null

# Synergy type colors
const SYNERGY_COLORS: Dictionary = {
	"fire_ice": Color(0.9, 0.5, 0.3),
	"arrow_rain": Color(0.6, 0.4, 0.2),
	"arcane_support": Color(0.6, 0.3, 0.9),
	"holy_purification": Color(1.0, 0.9, 0.5),
	"chain_reaction": Color(0.3, 0.7, 1.0),
	"kill_box": Color(0.5, 0.9, 0.4),
	"legion": Color(0.9, 0.4, 0.4),
	"titan_slayer": Color(0.8, 0.6, 0.2)
}


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 480)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "TOWER SYNERGIES"
	DesignSystem.style_label(title, "h2", Color(0.9, 0.6, 0.3))
	header.add_child(title)

	header.add_child(DesignSystem.create_spacer())

	_active_count_label = Label.new()
	DesignSystem.style_label(_active_count_label, "body", Color(0.4, 0.9, 0.4))
	header.add_child(_active_count_label)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(15, 0)
	header.add_child(spacer2)

	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.custom_minimum_size = Vector2(DesignSystem.SIZE_BUTTON_SM, DesignSystem.SIZE_BUTTON_SM)
	_style_close_button()
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Subtitle with toggle
	var subtitle_row := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(subtitle_row)

	var subtitle := Label.new()
	subtitle.text = "Combine towers to unlock powerful bonuses"
	DesignSystem.style_label(subtitle, "body_small", ThemeColors.TEXT_DIM)
	subtitle_row.add_child(subtitle)

	subtitle_row.add_child(DesignSystem.create_spacer())

	_toggle_btn = Button.new()
	_toggle_btn.text = "Show All"
	_toggle_btn.toggle_mode = true
	_toggle_btn.custom_minimum_size = Vector2(80, 24)
	_toggle_btn.pressed.connect(_on_toggle_pressed)
	subtitle_row.add_child(_toggle_btn)

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
	footer.text = "Place required towers near each other to activate synergies"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_synergies(state: Variant) -> void:
	_state = state
	_build_content()
	show()


func refresh() -> void:
	if _state != null:
		_build_content()


func _on_toggle_pressed() -> void:
	_show_all = _toggle_btn.button_pressed
	_toggle_btn.text = "Active Only" if _show_all else "Show All"
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	if _state == null:
		return

	var active_synergies: Array = _state.active_synergies
	var active_ids: Array[String] = []
	for syn in active_synergies:
		active_ids.append(str(syn.get("id", "")))

	_active_count_label.text = "%d active" % active_synergies.size()

	# Build synergy list
	var all_ids: Array[String] = SimSynergyDetector.get_all_synergy_ids()

	# Active synergies first
	if not active_synergies.is_empty():
		var active_section := _create_section_panel("ACTIVE SYNERGIES", Color(0.4, 0.9, 0.4))
		_content_vbox.add_child(active_section)

		var vbox: VBoxContainer = active_section.get_child(0)
		for syn in active_synergies:
			var card := _create_synergy_card(str(syn.get("id", "")), true, syn)
			vbox.add_child(card)

	# Inactive synergies (if showing all)
	if _show_all:
		var inactive_ids: Array[String] = []
		for id in all_ids:
			if not id in active_ids:
				inactive_ids.append(id)

		if not inactive_ids.is_empty():
			var inactive_section := _create_section_panel("AVAILABLE SYNERGIES", Color(0.5, 0.5, 0.55))
			_content_vbox.add_child(inactive_section)

			var vbox: VBoxContainer = inactive_section.get_child(0)
			for id in inactive_ids:
				var card := _create_synergy_card(id, false, {})
				vbox.add_child(card)

	# Empty state
	if active_synergies.is_empty() and not _show_all:
		var empty_label := Label.new()
		empty_label.text = "No synergies active. Build towers near each other to unlock synergies!"
		empty_label.add_theme_font_size_override("font_size", 12)
		empty_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_content_vbox.add_child(empty_label)

		var hint := Label.new()
		hint.text = "Click 'Show All' to see available synergy combinations."
		hint.add_theme_font_size_override("font_size", 11)
		hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		_content_vbox.add_child(hint)


func _create_synergy_card(synergy_id: String, is_active: bool, active_data: Dictionary) -> Control:
	var definition: Dictionary = SimSynergyDetector.get_synergy_definition(synergy_id)
	var name: String = str(definition.get("name", synergy_id))
	var description: String = str(definition.get("description", ""))
	var required: Array = definition.get("required_towers", [])
	var min_count: Dictionary = definition.get("min_count", {})
	var proximity: int = int(definition.get("proximity", 5))
	var effects: Dictionary = definition.get("effects", {})

	var color: Color = SYNERGY_COLORS.get(synergy_id, Color(0.6, 0.6, 0.7))
	if not is_active:
		color = color.darkened(0.4)

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	if is_active:
		container_style.bg_color = color.darkened(0.8)
		container_style.border_color = color
	else:
		container_style.bg_color = Color(0.06, 0.07, 0.1, 0.9)
		container_style.border_color = Color(0.3, 0.3, 0.35)
	container_style.set_border_width_all(is_active as int + 1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	container.add_child(vbox)

	# Header row
	var header := HBoxContainer.new()
	vbox.add_child(header)

	var name_label := Label.new()
	name_label.text = name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", color if is_active else color.lightened(0.2))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)

	if is_active:
		var active_chip := _create_chip("ACTIVE", Color(0.4, 0.9, 0.4))
		header.add_child(active_chip)

	# Description
	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM if not is_active else Color(0.8, 0.8, 0.8))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	# Requirements row
	var req_row := HBoxContainer.new()
	req_row.add_theme_constant_override("separation", 8)
	vbox.add_child(req_row)

	var req_label := Label.new()
	req_label.text = "Requires:"
	req_label.add_theme_font_size_override("font_size", 10)
	req_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	req_row.add_child(req_label)

	# Required towers
	for tower_type in required:
		var tower_name: String = _format_tower_name(str(tower_type))
		var has_tower: bool = _state_has_tower(str(tower_type)) if _state != null else false
		var tower_chip := _create_requirement_chip(tower_name, has_tower or is_active)
		req_row.add_child(tower_chip)

	# Min count towers
	for tower_type in min_count.keys():
		var count: int = int(min_count[tower_type])
		var tower_name: String = _format_tower_name(str(tower_type))
		var has_enough: bool = _state_has_tower_count(str(tower_type), count) if _state != null else false
		var tower_chip := _create_requirement_chip("%s x%d" % [tower_name, count], has_enough or is_active)
		req_row.add_child(tower_chip)

	# Proximity info
	var proximity_chip := _create_chip("Range: %d" % proximity, Color(0.5, 0.5, 0.55))
	req_row.add_child(proximity_chip)

	# Effects (when active)
	if is_active and not effects.is_empty():
		var effects_row := HBoxContainer.new()
		effects_row.add_theme_constant_override("separation", 10)
		vbox.add_child(effects_row)

		var effects_label := Label.new()
		effects_label.text = "Effects:"
		effects_label.add_theme_font_size_override("font_size", 10)
		effects_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		effects_row.add_child(effects_label)

		var effect_texts: Array[String] = []
		for effect_key in effects.keys():
			var effect_text: String = _format_effect(effect_key, effects[effect_key])
			if not effect_text.is_empty():
				effect_texts.append(effect_text)

		var effects_value := Label.new()
		effects_value.text = ", ".join(effect_texts)
		effects_value.add_theme_font_size_override("font_size", 10)
		effects_value.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		effects_value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effects_row.add_child(effects_value)

	return container


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


func _create_chip(text: String, color: Color) -> Control:
	var chip := PanelContainer.new()

	var chip_style := StyleBoxFlat.new()
	chip_style.bg_color = color.darkened(0.7)
	chip_style.set_corner_radius_all(3)
	chip_style.set_content_margin_all(4)
	chip.add_theme_stylebox_override("panel", chip_style)

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", color)
	chip.add_child(label)

	return chip


func _create_requirement_chip(text: String, is_met: bool) -> Control:
	var chip := PanelContainer.new()

	var chip_style := StyleBoxFlat.new()
	if is_met:
		chip_style.bg_color = Color(0.1, 0.2, 0.1, 0.8)
		chip_style.border_color = Color(0.3, 0.6, 0.3)
	else:
		chip_style.bg_color = Color(0.15, 0.1, 0.1, 0.8)
		chip_style.border_color = Color(0.4, 0.3, 0.3)
	chip_style.set_border_width_all(1)
	chip_style.set_corner_radius_all(3)
	chip_style.set_content_margin_all(4)
	chip.add_theme_stylebox_override("panel", chip_style)

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4) if is_met else Color(0.7, 0.5, 0.5))
	chip.add_child(label)

	return chip


func _format_tower_name(tower_type: String) -> String:
	# Convert tower_arrow -> Arrow, etc.
	if tower_type.begins_with("tower_"):
		return tower_type.substr(6).capitalize()
	return tower_type.capitalize()


func _state_has_tower(tower_type: String) -> bool:
	if _state == null:
		return false
	for key in _state.structures.keys():
		if str(_state.structures[key]) == tower_type:
			return true
	return false


func _state_has_tower_count(tower_type: String, count: int) -> bool:
	if _state == null:
		return false
	var found: int = 0
	for key in _state.structures.keys():
		if str(_state.structures[key]) == tower_type:
			found += 1
	return found >= count


func _format_effect(effect_key: String, value: Variant) -> String:
	match effect_key:
		"frozen_fire_mult":
			return "%.0fx fire vs frozen" % float(value)
		"burning_cold_mult":
			return "%.0fx cold vs burning" % float(value)
		"coordinated_attack_mult":
			return "%.0fx coordinated damage" % float(value)
		"coordinated_attack_interval":
			return "every %.0fs" % float(value)
		"accuracy_scaling_bonus":
			return "+%.0f%% accuracy scaling" % (float(value) * 100)
		"purify_chance_mult":
			return "%.0fx purify chance" % float(value)
		"purify_explosion":
			return "purify explosion" if bool(value) else ""
		"purify_explosion_damage":
			return "%d explosion damage" % int(value)
		"extra_chain_jumps":
			return "+%d chain jumps" % int(value)
		"no_chain_falloff":
			return "no chain falloff" if bool(value) else ""
		"slow_damage_bonus":
			return "+%.0f%% to slowed" % (float(value) * 100)
		"max_summons_bonus":
			return "+%d max summons" % int(value)
		"summon_stat_bonus":
			return "+%.0f%% summon stats" % (float(value) * 100)
		"charge_speed_bonus":
			return "+%.0f%% charge speed" % (float(value) * 100)
		"boss_damage_bonus":
			return "+%.0f%% boss damage" % (float(value) * 100)
		_:
			return ""


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
