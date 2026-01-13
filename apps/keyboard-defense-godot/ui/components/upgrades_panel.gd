class_name UpgradesPanel
extends PanelContainer
## Upgrades Panel - Shows kingdom and unit upgrade trees.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed
signal upgrade_selected(upgrade_id: String, category: String)

const SimUpgrades = preload("res://sim/upgrades.gd")

var _current_gold: int = 0
var _purchased_kingdom: Array = []
var _purchased_unit: Array = []

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Tier colors (domain-specific)
const TIER_COLORS: Dictionary = {
	1: Color(0.5, 0.8, 0.3),
	2: Color(0.4, 0.8, 1.0),
	3: Color(0.9, 0.6, 0.9)
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
	title.text = "UPGRADE TREES"
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
	subtitle.text = "Permanent upgrades purchased with gold"
	DesignSystem.style_label(subtitle, "body_small", ThemeColors.TEXT_DIM)
	main_vbox.add_child(subtitle)

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
	footer.text = "Type 'buy upgrade <name>' during day phase"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_upgrades(gold: int = 0, purchased_kingdom: Array = [], purchased_unit: Array = []) -> void:
	_current_gold = gold
	_purchased_kingdom = purchased_kingdom
	_purchased_unit = purchased_unit
	_build_content()
	show()


func refresh(gold: int = 0, purchased_kingdom: Array = [], purchased_unit: Array = []) -> void:
	_current_gold = gold
	_purchased_kingdom = purchased_kingdom
	_purchased_unit = purchased_unit
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Gold summary
	_build_gold_summary()

	# Kingdom upgrades
	_build_kingdom_section()

	# Unit upgrades
	_build_unit_section()


func _build_gold_summary() -> void:
	var section := PanelContainer.new()

	var section_style := StyleBoxFlat.new()
	section_style.bg_color = ThemeColors.RESOURCE_GOLD.darkened(0.85)
	section_style.border_color = ThemeColors.RESOURCE_GOLD.darkened(0.5)
	section_style.set_border_width_all(2)
	section_style.set_corner_radius_all(DesignSystem.RADIUS_SM)
	section_style.set_content_margin_all(DesignSystem.SPACE_MD)
	section.add_theme_stylebox_override("panel", section_style)

	_content_vbox.add_child(section)

	var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_XL)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	section.add_child(hbox)

	# Gold available
	_add_summary_stat(hbox, "Gold Available", str(_current_gold), ThemeColors.RESOURCE_GOLD)

	# Kingdom owned
	var kingdom_total: int = SimUpgrades.get_all_kingdom_upgrades().size()
	_add_summary_stat(hbox, "Kingdom", "%d/%d" % [_purchased_kingdom.size(), kingdom_total], ThemeColors.SUCCESS)

	# Unit owned
	var unit_total: int = SimUpgrades.get_all_unit_upgrades().size()
	_add_summary_stat(hbox, "Unit", "%d/%d" % [_purchased_unit.size(), unit_total], ThemeColors.INFO)


func _add_summary_stat(parent: Control, label: String, value: String, color: Color) -> void:
	var vbox := DesignSystem.create_vbox(0)
	parent.add_child(vbox)

	var label_node := Label.new()
	label_node.text = label
	DesignSystem.style_label(label_node, "caption", ThemeColors.TEXT_DIM)
	label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label_node)

	var value_node := Label.new()
	value_node.text = value
	DesignSystem.style_label(value_node, "body", color)
	value_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(value_node)


func _build_kingdom_section() -> void:
	var section := _create_section_panel("KINGDOM UPGRADES", ThemeColors.SUCCESS)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var upgrades: Array = SimUpgrades.get_all_kingdom_upgrades()

	if upgrades.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No kingdom upgrades available"
		DesignSystem.style_label(empty_label, "caption", ThemeColors.TEXT_DIM)
		vbox.add_child(empty_label)
		return

	# Group by tier
	for tier in [1, 2, 3]:
		var tier_upgrades: Array = []
		for upgrade in upgrades:
			if int(upgrade.get("tier", 1)) == tier:
				tier_upgrades.append(upgrade)

		if tier_upgrades.is_empty():
			continue

		var tier_label := Label.new()
		tier_label.text = "Tier %d" % tier
		DesignSystem.style_label(tier_label, "caption", TIER_COLORS.get(tier, Color.WHITE))
		vbox.add_child(tier_label)

		for upgrade in tier_upgrades:
			var card := _create_upgrade_card(upgrade, "kingdom")
			vbox.add_child(card)


func _build_unit_section() -> void:
	var section := _create_section_panel("UNIT UPGRADES", ThemeColors.INFO)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var upgrades: Array = SimUpgrades.get_all_unit_upgrades()

	if upgrades.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No unit upgrades available"
		DesignSystem.style_label(empty_label, "caption", ThemeColors.TEXT_DIM)
		vbox.add_child(empty_label)
		return

	# Group by tier
	for tier in [1, 2, 3]:
		var tier_upgrades: Array = []
		for upgrade in upgrades:
			if int(upgrade.get("tier", 1)) == tier:
				tier_upgrades.append(upgrade)

		if tier_upgrades.is_empty():
			continue

		var tier_label := Label.new()
		tier_label.text = "Tier %d" % tier
		DesignSystem.style_label(tier_label, "caption", TIER_COLORS.get(tier, Color.WHITE))
		vbox.add_child(tier_label)

		for upgrade in tier_upgrades:
			var card := _create_upgrade_card(upgrade, "unit")
			vbox.add_child(card)


func _create_upgrade_card(upgrade: Dictionary, category: String) -> Control:
	var upgrade_id: String = str(upgrade.get("id", ""))
	var label: String = str(upgrade.get("label", upgrade_id))
	var description: String = str(upgrade.get("description", ""))
	var cost: int = int(upgrade.get("cost", 0))
	var tier: int = int(upgrade.get("tier", 1))
	var requires: Array = upgrade.get("requires", [])
	var effects: Dictionary = upgrade.get("effects", {})

	var purchased: bool = false
	if category == "kingdom":
		purchased = upgrade_id in _purchased_kingdom
	else:
		purchased = upgrade_id in _purchased_unit

	var can_afford: bool = _current_gold >= cost

	# Check requirements
	var reqs_met: bool = true
	for req_id in requires:
		if category == "kingdom":
			if str(req_id) not in _purchased_kingdom:
				reqs_met = false
				break
		else:
			if str(req_id) not in _purchased_unit:
				reqs_met = false
				break

	var container := PanelContainer.new()
	var tier_color: Color = TIER_COLORS.get(tier, Color.WHITE)

	var bg_color: Color
	var border_color: Color
	if purchased:
		bg_color = ThemeColors.SUCCESS.darkened(0.7)
		border_color = ThemeColors.SUCCESS.darkened(0.3)
	elif reqs_met and can_afford:
		bg_color = ThemeColors.BG_CARD
		border_color = tier_color.darkened(0.3)
	else:
		bg_color = ThemeColors.BG_CARD_DISABLED
		border_color = ThemeColors.BORDER

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = bg_color
	container_style.border_color = border_color
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(DesignSystem.RADIUS_XS)
	container_style.set_content_margin_all(DesignSystem.SPACE_SM)
	container.add_theme_stylebox_override("panel", container_style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_XS)
	container.add_child(main_vbox)

	# Header row
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var name_label := Label.new()
	name_label.text = label
	if purchased:
		DesignSystem.style_label(name_label, "caption", ThemeColors.SUCCESS)
	else:
		DesignSystem.style_label(name_label, "caption", tier_color)
	header.add_child(name_label)

	header.add_child(DesignSystem.create_spacer())

	# Status/cost
	var status_label := Label.new()
	if purchased:
		status_label.text = "OWNED"
		DesignSystem.style_label(status_label, "caption", ThemeColors.SUCCESS)
	elif not reqs_met:
		status_label.text = "LOCKED"
		DesignSystem.style_label(status_label, "caption", ThemeColors.TEXT_DISABLED)
	elif can_afford:
		status_label.text = "%d gold" % cost
		DesignSystem.style_label(status_label, "caption", ThemeColors.RESOURCE_GOLD)
	else:
		status_label.text = "%d gold" % cost
		DesignSystem.style_label(status_label, "caption", ThemeColors.ERROR)
	header.add_child(status_label)

	# Description
	if not description.is_empty():
		var desc_label := Label.new()
		desc_label.text = description
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		main_vbox.add_child(desc_label)

	# Effects
	if not effects.is_empty():
		var effects_str: String = ""
		for key in effects.keys():
			var value: float = float(effects[key])
			if not effects_str.is_empty():
				effects_str += ", "
			effects_str += "%s: %+.0f%%" % [key.replace("_", " ").capitalize(), value * 100]

		var effects_label := Label.new()
		effects_label.text = effects_str
		DesignSystem.style_label(effects_label, "caption", ThemeColors.SUCCESS.darkened(0.2))
		main_vbox.add_child(effects_label)

	# Requirements
	if not requires.is_empty() and not purchased:
		var req_label := Label.new()
		req_label.text = "Requires: " + ", ".join(requires)
		DesignSystem.style_label(req_label, "caption", ThemeColors.TEXT_DIM)
		main_vbox.add_child(req_label)

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


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
