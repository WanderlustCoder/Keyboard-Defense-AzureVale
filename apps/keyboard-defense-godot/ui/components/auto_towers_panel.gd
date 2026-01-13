class_name AutoTowersPanel
extends PanelContainer
## Auto Towers Panel - Shows auto-defense tower status and info.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

const SimAutoTowerTypes = preload("res://sim/auto_tower_types.gd")

var _active_towers: Array[Dictionary] = []

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null
var _towers_list: VBoxContainer = null
var _info_section: VBoxContainer = null

# Tower targeting mode descriptions
const TARGETING_DESCRIPTIONS: Dictionary = {
	"nearest": "Attacks closest enemy",
	"highest_hp": "Targets enemy with most HP",
	"lowest_hp": "Finishes off weakened enemies",
	"fastest": "Targets fastest moving enemy",
	"cluster": "Attacks center of enemy groups",
	"chain": "Lightning chains between enemies",
	"zone": "Damages all enemies in range",
	"contact": "Damages enemies passing through",
	"smart": "AI-driven optimal selection"
}


func _get_tower_color(tower_type: String) -> Color:
	var tier: int = SimAutoTowerTypes.get_tier(tower_type)
	return SimAutoTowerTypes.TIER_COLORS.get(tier, Color.WHITE)


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_MD + 40, 500)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "AUTO-DEFENSE TOWERS"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	DesignSystem.style_label(title, "h2", ThemeColors.ACCENT)
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

	_content_vbox = DesignSystem.create_vbox(DesignSystem.SPACE_LG)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_vbox)

	# Towers list section
	_towers_list = DesignSystem.create_vbox(DesignSystem.SPACE_SM)
	_content_vbox.add_child(_towers_list)

	# Separator
	_content_vbox.add_child(DesignSystem.create_separator())

	# Tower types info section
	_info_section = DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	_content_vbox.add_child(_info_section)

	# Footer
	var footer := Label.new()
	footer.text = "Auto-towers attack automatically during defense waves!"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_auto_towers(towers: Array[Dictionary]) -> void:
	_active_towers = towers
	_build_towers_list()
	_build_info_section()
	show()


func _clear_towers_list() -> void:
	for child in _towers_list.get_children():
		child.queue_free()


func _clear_info_section() -> void:
	for child in _info_section.get_children():
		child.queue_free()


func _build_towers_list() -> void:
	_clear_towers_list()

	# Section header
	var header := Label.new()
	header.text = "YOUR TOWERS"
	DesignSystem.style_label(header, "body", ThemeColors.ACCENT)
	_towers_list.add_child(header)

	if _active_towers.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No auto-towers built yet."
		DesignSystem.style_label(empty_label, "body_small", ThemeColors.TEXT_DIM)
		_towers_list.add_child(empty_label)

		var hint_label := Label.new()
		hint_label.text = "Build with: build auto_sentry, build auto_spark, build auto_thorns"
		DesignSystem.style_label(hint_label, "caption", ThemeColors.TEXT_DIM)
		_towers_list.add_child(hint_label)
		return

	# Count towers by type
	var count_label := Label.new()
	count_label.text = "Active Towers: %d" % _active_towers.size()
	DesignSystem.style_label(count_label, "body_small", ThemeColors.SUCCESS)
	_towers_list.add_child(count_label)

	# Display each tower
	for tower in _active_towers:
		var widget := _create_tower_widget(tower)
		_towers_list.add_child(widget)


func _create_tower_widget(tower: Dictionary) -> Control:
	var tower_type: String = str(tower.get("type", "unknown"))
	var pos: Vector2i = tower.get("pos", Vector2i.ZERO)
	var damage: int = int(tower.get("damage", 1))
	var attack_range: int = int(tower.get("range", 2))
	var cooldown: float = float(tower.get("cooldown", 1.0))
	var targeting: String = str(tower.get("targeting", "nearest"))

	var tower_data: Dictionary = SimAutoTowerTypes.get_tower(tower_type)
	var tower_name: String = SimAutoTowerTypes.get_tower_name(tower_type)
	var tier: int = SimAutoTowerTypes.get_tier(tower_type)
	var color: Color = _get_tower_color(tower_type)

	var container := PanelContainer.new()
	var container_style := DesignSystem.create_elevated_style(ThemeColors.BG_CARD)
	container_style.border_color = color.darkened(0.4)
	container_style.set_border_width_all(1)
	container.add_theme_stylebox_override("panel", container_style)

	var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_LG)
	container.add_child(hbox)

	# Tower name, tier badge, and position
	var name_vbox := DesignSystem.create_vbox(2)
	name_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_vbox)

	var name_hbox := DesignSystem.create_hbox(DesignSystem.SPACE_SM)
	name_vbox.add_child(name_hbox)

	var name_label := Label.new()
	name_label.text = tower_name
	DesignSystem.style_label(name_label, "body_small", color)
	name_hbox.add_child(name_label)

	# Tier badge
	var tier_badge := Label.new()
	tier_badge.text = "T%d" % tier
	DesignSystem.style_label(tier_badge, "caption", color)
	name_hbox.add_child(tier_badge)

	var pos_label := Label.new()
	pos_label.text = "Position: (%d, %d)" % [pos.x, pos.y]
	DesignSystem.style_label(pos_label, "caption", ThemeColors.TEXT_DIM)
	name_vbox.add_child(pos_label)

	# Stats
	var stats_hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	hbox.add_child(stats_hbox)

	# Damage
	_add_stat_column(stats_hbox, "DMG", str(damage), ThemeColors.ERROR)

	# Range
	_add_stat_column(stats_hbox, "RNG", str(attack_range), ThemeColors.INFO)

	# Cooldown
	_add_stat_column(stats_hbox, "CD", "%.1fs" % cooldown, ThemeColors.TEXT_DIM)

	# DPS calculation
	var dps: float = float(damage) / cooldown if cooldown > 0 else 0.0
	_add_stat_column(stats_hbox, "DPS", "%.1f" % dps, ThemeColors.ACCENT)

	return container


func _add_stat_column(parent: Control, header_text: String, value_text: String, value_color: Color) -> void:
	var vbox := DesignSystem.create_vbox(2)
	parent.add_child(vbox)

	var header := Label.new()
	header.text = header_text
	DesignSystem.style_label(header, "caption", ThemeColors.TEXT_DIM)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)

	var value := Label.new()
	value.text = value_text
	DesignSystem.style_label(value, "body", value_color)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(value)


func _build_info_section() -> void:
	_clear_info_section()

	# Section header
	var header := Label.new()
	header.text = "TOWER TYPES BY TIER"
	DesignSystem.style_label(header, "body", ThemeColors.ACCENT)
	_info_section.add_child(header)

	# Build towers by tier
	for tier in [1, 2, 3, 4]:
		var tier_towers: Array[String] = SimAutoTowerTypes.get_towers_by_tier(tier)
		if tier_towers.is_empty():
			continue

		# Tier header
		var tier_label := Label.new()
		var tier_name: String = "Tier %d" % tier
		if tier == 4:
			tier_name = "Tier 4 (Legendary)"
		var tier_color: Color = SimAutoTowerTypes.TIER_COLORS.get(tier, Color.WHITE)
		DesignSystem.style_label(tier_label, "body_small", tier_color)
		tier_label.text = tier_name
		_info_section.add_child(tier_label)

		# Tower cards for this tier
		for tower_id in tier_towers:
			var card := _create_tower_type_card(tower_id)
			_info_section.add_child(card)


func _create_tower_type_card(tower_id: String) -> Control:
	var tower_data: Dictionary = SimAutoTowerTypes.get_tower(tower_id)
	var tower_name: String = str(tower_data.get("name", tower_id))
	var description: String = str(tower_data.get("description", ""))
	var tier: int = int(tower_data.get("tier", 1))
	var color: Color = SimAutoTowerTypes.TIER_COLORS.get(tier, Color.WHITE)

	var damage: int = int(tower_data.get("damage", 1))
	var attack_speed: float = float(tower_data.get("attack_speed", 1.0))
	var range_val: int = int(tower_data.get("range", 2))
	var targeting: int = int(tower_data.get("targeting", 0))
	var cost: Dictionary = SimAutoTowerTypes.get_cost(tower_id)

	var cooldown: float = 1.0 / attack_speed if attack_speed > 0 else 0.0
	var dps: float = float(damage) * attack_speed

	var container := PanelContainer.new()
	var container_style := DesignSystem.create_elevated_style(ThemeColors.BG_CARD, DesignSystem.SHADOW_SM)
	container_style.border_color = color.darkened(0.5)
	container_style.set_border_width_all(1)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := DesignSystem.create_vbox(DesignSystem.SPACE_XS)
	container.add_child(vbox)

	# Header row
	var header_hbox := DesignSystem.create_hbox(DesignSystem.SPACE_SM)
	vbox.add_child(header_hbox)

	var name_label := Label.new()
	name_label.text = tower_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	DesignSystem.style_label(name_label, "body_small", color)
	header_hbox.add_child(name_label)

	# Cost
	var cost_str := _format_cost(cost)
	var cost_label := Label.new()
	cost_label.text = cost_str
	DesignSystem.style_label(cost_label, "caption", ThemeColors.RESOURCE_GOLD)
	header_hbox.add_child(cost_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = description
	DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_label)

	# Stats row
	var stats_label := Label.new()
	stats_label.text = "DMG: %d | Range: %d | CD: %.1fs | DPS: %.1f" % [damage, range_val, cooldown, dps]
	DesignSystem.style_label(stats_label, "caption", ThemeColors.TEXT_DIM)
	vbox.add_child(stats_label)

	# Targeting info
	var targeting_str: String = _get_targeting_description(targeting)
	var targeting_label := Label.new()
	targeting_label.text = targeting_str
	DesignSystem.style_label(targeting_label, "caption", ThemeColors.INFO)
	vbox.add_child(targeting_label)

	# Upgrade path indicator
	var upgrade_options: Array[String] = SimAutoTowerTypes.get_upgrade_options(tower_id)
	if not upgrade_options.is_empty():
		var upgrade_label := Label.new()
		var upgrade_names: Array[String] = []
		for opt in upgrade_options:
			upgrade_names.append(SimAutoTowerTypes.get_tower_name(opt))
		upgrade_label.text = "Upgrades to: %s" % ", ".join(upgrade_names)
		DesignSystem.style_label(upgrade_label, "caption", ThemeColors.SUCCESS)
		vbox.add_child(upgrade_label)

	# Build command
	var cmd_label := Label.new()
	cmd_label.text = "build %s" % tower_id
	DesignSystem.style_label(cmd_label, "caption", ThemeColors.TEXT_DIM)
	vbox.add_child(cmd_label)

	return container


func _format_cost(cost: Dictionary) -> String:
	var parts: Array[String] = []
	if cost.has("gold"):
		parts.append("%dg" % int(cost.gold))
	if cost.has("wood"):
		parts.append("%dw" % int(cost.wood))
	if cost.has("stone"):
		parts.append("%ds" % int(cost.stone))
	return " ".join(parts)


func _get_targeting_description(mode: int) -> String:
	match mode:
		SimAutoTowerTypes.TargetMode.NEAREST:
			return "Targeting: Nearest enemy"
		SimAutoTowerTypes.TargetMode.HIGHEST_HP:
			return "Targeting: Highest HP enemy"
		SimAutoTowerTypes.TargetMode.LOWEST_HP:
			return "Targeting: Lowest HP (finish off)"
		SimAutoTowerTypes.TargetMode.FASTEST:
			return "Targeting: Fastest enemy"
		SimAutoTowerTypes.TargetMode.CLUSTER:
			return "Targeting: Enemy clusters (splash)"
		SimAutoTowerTypes.TargetMode.CHAIN:
			return "Targeting: Chain lightning"
		SimAutoTowerTypes.TargetMode.ZONE:
			return "Targeting: All enemies in range (AoE)"
		SimAutoTowerTypes.TargetMode.CONTACT:
			return "Targeting: Contact damage"
		SimAutoTowerTypes.TargetMode.SMART:
			return "Targeting: AI-driven optimal selection"
		_:
			return "Targeting: Unknown"


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
