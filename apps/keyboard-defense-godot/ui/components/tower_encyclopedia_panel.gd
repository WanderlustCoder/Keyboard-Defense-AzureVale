class_name TowerEncyclopediaPanel
extends PanelContainer
## Tower Encyclopedia Panel - Reference for all tower types and their stats.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

const SimTowerTypes = preload("res://sim/tower_types.gd")
const SimDamageTypes = preload("res://sim/damage_types.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null
var _category_filter: OptionButton = null
var _selected_category: int = -1  # -1 = all

# Category colors
const CATEGORY_COLORS: Dictionary = {
	SimTowerTypes.TowerCategory.BASIC: Color(0.6, 0.8, 0.6),
	SimTowerTypes.TowerCategory.ADVANCED: Color(0.4, 0.6, 1.0),
	SimTowerTypes.TowerCategory.SPECIALIST: Color(0.9, 0.5, 0.9),
	SimTowerTypes.TowerCategory.LEGENDARY: Color(1.0, 0.84, 0.0)
}

const CATEGORY_NAMES: Dictionary = {
	SimTowerTypes.TowerCategory.BASIC: "Basic",
	SimTowerTypes.TowerCategory.ADVANCED: "Advanced",
	SimTowerTypes.TowerCategory.SPECIALIST: "Specialist",
	SimTowerTypes.TowerCategory.LEGENDARY: "Legendary"
}


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 560)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "TOWER ENCYCLOPEDIA"
	DesignSystem.style_label(title, "h2", Color(0.4, 0.7, 0.9))
	header.add_child(title)

	header.add_child(DesignSystem.create_spacer())

	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.custom_minimum_size = Vector2(DesignSystem.SIZE_BUTTON_SM, DesignSystem.SIZE_BUTTON_SM)
	_style_close_button()
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Filter row
	var filter_row := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(filter_row)

	var filter_label := Label.new()
	filter_label.text = "Category:"
	DesignSystem.style_label(filter_label, "body_small", ThemeColors.TEXT_DIM)
	filter_row.add_child(filter_label)

	_category_filter = OptionButton.new()
	_category_filter.add_item("All Towers", -1)
	_category_filter.add_item("Basic", SimTowerTypes.TowerCategory.BASIC)
	_category_filter.add_item("Advanced", SimTowerTypes.TowerCategory.ADVANCED)
	_category_filter.add_item("Specialist", SimTowerTypes.TowerCategory.SPECIALIST)
	_category_filter.add_item("Legendary", SimTowerTypes.TowerCategory.LEGENDARY)
	_category_filter.item_selected.connect(_on_category_selected)
	filter_row.add_child(_category_filter)

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
	footer.text = "Build towers to defend against enemy waves"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_encyclopedia() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	if _selected_category >= 0:
		# Show specific category
		var category_name: String = CATEGORY_NAMES.get(_selected_category, "Unknown")
		var category_color: Color = CATEGORY_COLORS.get(_selected_category, Color.WHITE)
		var tower_ids: Array[String] = _get_tower_ids_for_category(_selected_category)

		var section := _create_section_panel(category_name.to_upper() + " TOWERS", category_color)
		_content_vbox.add_child(section)

		var vbox: VBoxContainer = section.get_child(0)
		for tower_id in tower_ids:
			var card := _create_tower_card(tower_id)
			vbox.add_child(card)
	else:
		# Show all categories
		for category in [SimTowerTypes.TowerCategory.BASIC, SimTowerTypes.TowerCategory.ADVANCED, SimTowerTypes.TowerCategory.SPECIALIST, SimTowerTypes.TowerCategory.LEGENDARY]:
			var category_name: String = CATEGORY_NAMES.get(category, "Unknown")
			var category_color: Color = CATEGORY_COLORS.get(category, Color.WHITE)
			var tower_ids: Array[String] = _get_tower_ids_for_category(category)

			if tower_ids.is_empty():
				continue

			var unlock_text: String = _get_unlock_text(category)
			var section := _create_section_panel(category_name.to_upper() + " TOWERS", category_color, unlock_text)
			_content_vbox.add_child(section)

			var vbox: VBoxContainer = section.get_child(0)
			for tower_id in tower_ids:
				var card := _create_tower_card(tower_id)
				vbox.add_child(card)


func _create_tower_card(tower_id: String) -> Control:
	var stats: Dictionary = SimTowerTypes.TOWER_STATS.get(tower_id, {})
	if stats.is_empty():
		return Control.new()

	var tower_name: String = str(stats.get("name", tower_id))
	var category: int = int(stats.get("category", 0))
	var damage_type: int = int(stats.get("damage_type", 0))
	var target_type: int = int(stats.get("target_type", 0))
	var attack_type: int = int(stats.get("attack_type", 0))
	var damage: int = int(stats.get("damage", 0))
	var attack_range: int = int(stats.get("range", 0))
	var attack_speed: float = float(stats.get("attack_speed", 1.0))
	var cost: Dictionary = stats.get("cost", {})

	var category_color: Color = CATEGORY_COLORS.get(category, Color.WHITE)
	var damage_color: Color = SimDamageTypes.get_damage_type_color(damage_type)

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = category_color.darkened(0.85)
	container_style.border_color = category_color.darkened(0.5)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", container_style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 6)
	container.add_child(main_vbox)

	# Header row
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	main_vbox.add_child(header)

	# Tower icon
	var icon_panel := _create_tower_icon(tower_id, category_color)
	header.add_child(icon_panel)

	# Name and type info
	var info_vbox := VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 2)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(info_vbox)

	var name_label := Label.new()
	name_label.text = tower_name
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", category_color)
	info_vbox.add_child(name_label)

	var type_row := HBoxContainer.new()
	type_row.add_theme_constant_override("separation", 8)
	info_vbox.add_child(type_row)

	var damage_label := Label.new()
	damage_label.text = SimDamageTypes.get_damage_type_name(damage_type)
	damage_label.add_theme_font_size_override("font_size", 11)
	damage_label.add_theme_color_override("font_color", damage_color)
	type_row.add_child(damage_label)

	var target_label := Label.new()
	target_label.text = _get_target_type_name(target_type)
	target_label.add_theme_font_size_override("font_size", 11)
	target_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	type_row.add_child(target_label)

	# Stats row
	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 15)
	main_vbox.add_child(stats_row)

	# Damage
	var dmg_chip := _create_stat_chip("DMG", str(damage), Color(0.9, 0.4, 0.4))
	stats_row.add_child(dmg_chip)

	# Range
	var range_chip := _create_stat_chip("RNG", str(attack_range), Color(0.4, 0.8, 0.4))
	stats_row.add_child(range_chip)

	# Attack speed
	var speed_chip := _create_stat_chip("SPD", "%.1f/s" % attack_speed, Color(0.9, 0.9, 0.4))
	stats_row.add_child(speed_chip)

	# DPS estimate
	var dps: float = float(damage) * attack_speed
	var dps_chip := _create_stat_chip("DPS", "~%.0f" % dps, Color(0.9, 0.6, 0.3))
	stats_row.add_child(dps_chip)

	# Special abilities
	var specials: Array[String] = _get_special_abilities(stats)
	if not specials.is_empty():
		var specials_row := HBoxContainer.new()
		specials_row.add_theme_constant_override("separation", 8)
		main_vbox.add_child(specials_row)

		var specials_label := Label.new()
		specials_label.text = "Special:"
		specials_label.add_theme_font_size_override("font_size", 10)
		specials_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		specials_row.add_child(specials_label)

		for special in specials:
			var s_label := Label.new()
			s_label.text = "[%s]" % special
			s_label.add_theme_font_size_override("font_size", 10)
			s_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.4))
			specials_row.add_child(s_label)

	# Cost row
	var cost_row := HBoxContainer.new()
	cost_row.add_theme_constant_override("separation", 10)
	main_vbox.add_child(cost_row)

	var cost_label := Label.new()
	cost_label.text = "Cost:"
	cost_label.add_theme_font_size_override("font_size", 10)
	cost_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	cost_row.add_child(cost_label)

	for resource in cost.keys():
		var amount: int = int(cost[resource])
		var res_label := Label.new()
		res_label.text = "%d %s" % [amount, resource]
		res_label.add_theme_font_size_override("font_size", 10)
		res_label.add_theme_color_override("font_color", _get_resource_color(resource))
		cost_row.add_child(res_label)

	return container


func _create_tower_icon(tower_id: String, color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(44, 44)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = color.darkened(0.7)
	panel_style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", panel_style)

	var icon_text: String = _get_tower_icon(tower_id)

	var label := Label.new()
	label.text = icon_text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(label)

	return panel


func _create_stat_chip(label: String, value: String, color: Color) -> Control:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)

	var label_txt := Label.new()
	label_txt.text = label + ":"
	label_txt.add_theme_font_size_override("font_size", 10)
	label_txt.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	hbox.add_child(label_txt)

	var value_txt := Label.new()
	value_txt.text = value
	value_txt.add_theme_font_size_override("font_size", 11)
	value_txt.add_theme_color_override("font_color", color)
	hbox.add_child(value_txt)

	return hbox


func _create_section_panel(title: String, color: Color, subtitle: String = "") -> PanelContainer:
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

	var header_row := HBoxContainer.new()
	vbox.add_child(header_row)

	var header := Label.new()
	header.text = title
	DesignSystem.style_label(header, "body_small", color)
	header_row.add_child(header)

	if subtitle != "":
		header_row.add_child(DesignSystem.create_spacer())

		var sub_label := Label.new()
		sub_label.text = subtitle
		DesignSystem.style_label(sub_label, "caption", ThemeColors.TEXT_DIM)
		header_row.add_child(sub_label)

	return container


func _get_tower_ids_for_category(category: int) -> Array[String]:
	match category:
		SimTowerTypes.TowerCategory.BASIC:
			return SimTowerTypes.CATEGORY_BASIC
		SimTowerTypes.TowerCategory.ADVANCED:
			return SimTowerTypes.CATEGORY_ADVANCED
		SimTowerTypes.TowerCategory.SPECIALIST:
			return SimTowerTypes.CATEGORY_SPECIALIST
		SimTowerTypes.TowerCategory.LEGENDARY:
			return SimTowerTypes.CATEGORY_LEGENDARY
	return []


func _get_unlock_text(category: int) -> String:
	match category:
		SimTowerTypes.TowerCategory.BASIC:
			return "Available from start"
		SimTowerTypes.TowerCategory.ADVANCED:
			return "Unlocks at Level 10"
		SimTowerTypes.TowerCategory.SPECIALIST:
			return "Unlocks at Level 18"
		SimTowerTypes.TowerCategory.LEGENDARY:
			return "Quest unlock, limit 1"
	return ""


func _get_tower_icon(tower_id: String) -> String:
	match tower_id:
		SimTowerTypes.TOWER_ARROW:
			return "ARW"
		SimTowerTypes.TOWER_MAGIC:
			return "MAG"
		SimTowerTypes.TOWER_FROST:
			return "FRT"
		SimTowerTypes.TOWER_CANNON:
			return "CAN"
		SimTowerTypes.TOWER_MULTI:
			return "MLT"
		SimTowerTypes.TOWER_ARCANE:
			return "ARC"
		SimTowerTypes.TOWER_HOLY:
			return "HLY"
		SimTowerTypes.TOWER_SIEGE:
			return "SIG"
		SimTowerTypes.TOWER_POISON:
			return "PSN"
		SimTowerTypes.TOWER_TESLA:
			return "TSL"
		SimTowerTypes.TOWER_SUMMONER:
			return "SUM"
		SimTowerTypes.TOWER_SUPPORT:
			return "SUP"
		SimTowerTypes.TOWER_TRAP:
			return "TRP"
		SimTowerTypes.TOWER_WORDSMITH:
			return "WRD"
		SimTowerTypes.TOWER_SHRINE:
			return "SHR"
		SimTowerTypes.TOWER_PURIFIER:
			return "PUR"
	return "TWR"


func _get_target_type_name(target_type: int) -> String:
	match target_type:
		SimTowerTypes.TargetType.SINGLE:
			return "Single"
		SimTowerTypes.TargetType.MULTI:
			return "Multi-target"
		SimTowerTypes.TargetType.AOE:
			return "Area"
		SimTowerTypes.TargetType.CHAIN:
			return "Chain"
		SimTowerTypes.TargetType.ADAPTIVE:
			return "Adaptive"
		SimTowerTypes.TargetType.NONE:
			return "Support"
	return "Unknown"


func _get_special_abilities(stats: Dictionary) -> Array[String]:
	var specials: Array[String] = []

	if stats.get("armor_pierce", false):
		specials.append("Pierce Armor")
	if stats.has("slow_percent"):
		specials.append("Slow %d%%" % int(stats.get("slow_percent", 0)))
	if stats.has("aoe_radius"):
		specials.append("AoE %d" % int(stats.get("aoe_radius", 0)))
	if stats.has("target_count"):
		specials.append("%d Targets" % int(stats.get("target_count", 0)))
	if stats.has("chain_targets"):
		specials.append("Chain %d" % int(stats.get("chain_targets", 0)))

	return specials


func _get_resource_color(resource: String) -> Color:
	match resource:
		"gold":
			return Color(1.0, 0.84, 0.0)
		"wood":
			return Color(0.6, 0.4, 0.2)
		"stone":
			return Color(0.7, 0.7, 0.75)
	return Color(0.7, 0.7, 0.7)


func _on_category_selected(index: int) -> void:
	_selected_category = _category_filter.get_item_id(index)
	_build_content()


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
