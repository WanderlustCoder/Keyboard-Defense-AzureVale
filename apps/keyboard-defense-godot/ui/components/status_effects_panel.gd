class_name StatusEffectsPanel
extends PanelContainer
## Status Effects Panel - Encyclopedia of all status effects in the game.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed
const SimStatusEffects = preload("res://sim/status_effects.gd")

var _state: RefCounted = null

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Effect category display order and colors
const CATEGORY_INFO: Dictionary = {
	"movement": {
		"name": "MOVEMENT EFFECTS",
		"color": Color(0.53, 0.81, 0.92),
		"effects": ["slow", "frozen", "rooted"]
	},
	"dot": {
		"name": "DAMAGE OVER TIME",
		"color": Color(1.0, 0.27, 0.0),
		"effects": ["burning", "poisoned", "bleeding", "corrupting"]
	},
	"defensive": {
		"name": "DEFENSIVE REDUCTION",
		"color": Color(0.6, 0.6, 0.7),
		"effects": ["armor_broken", "exposed", "weakened"]
	},
	"special": {
		"name": "SPECIAL EFFECTS",
		"color": Color(0.9, 0.7, 0.4),
		"effects": ["marked", "purifying", "confused"]
	}
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
	title.text = "STATUS EFFECTS"
	DesignSystem.style_label(title, "h2", Color(0.9, 0.5, 0.5))
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
	subtitle.text = "Effects applied by towers and enemy abilities"
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
	footer.text = "Debuffs applied by your towers; some enemies have immunities"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_status_effects(state: RefCounted = null) -> void:
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

	# Build each category section
	for category_id in ["movement", "dot", "defensive", "special"]:
		var category: Dictionary = CATEGORY_INFO.get(category_id, {})
		var cat_name: String = str(category.get("name", ""))
		var cat_color: Color = category.get("color", Color.WHITE)
		var effect_ids: Array = category.get("effects", [])

		var section := _create_section_panel(cat_name, cat_color)
		_content_vbox.add_child(section)

		var vbox: VBoxContainer = section.get_child(0)

		for effect_id in effect_ids:
			var effect_def: Dictionary = SimStatusEffects.get_effect(effect_id)
			if not effect_def.is_empty():
				var card := _create_effect_card(effect_id, effect_def)
				vbox.add_child(card)

	# Active effects section (if state provided)
	if _state != null:
		_build_active_effects_section()

	# Interactions section
	_build_interactions_section()


func _build_active_effects_section() -> void:
	if _state == null:
		return

	# Count active effects on enemies
	var active_counts: Dictionary = {}
	for enemy in _state.enemies:
		var effects: Array = enemy.get("status_effects", [])
		for effect in effects:
			if typeof(effect) == TYPE_DICTIONARY:
				var effect_id: String = str(effect.get("effect_id", ""))
				if effect_id != "":
					active_counts[effect_id] = active_counts.get(effect_id, 0) + 1

	if active_counts.is_empty():
		return

	var section := _create_section_panel("ACTIVE ON ENEMIES", Color(0.9, 0.4, 0.4))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for effect_id in active_counts.keys():
		var count: int = active_counts[effect_id]
		var row := _create_active_row(effect_id, count)
		vbox.add_child(row)


func _build_interactions_section() -> void:
	var section := _create_section_panel("EFFECT INTERACTIONS", Color(0.7, 0.5, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var interactions: Array[Dictionary] = [
		{"name": "Fire vs Ice", "desc": "Frozen removes Burning; Burning removes Frozen", "color": Color(0.9, 0.5, 0.3)},
		{"name": "Frozen Damage", "desc": "Frozen enemies take 50% more damage", "color": Color(0.53, 0.81, 0.92)},
		{"name": "Freeze Immunity", "desc": "After thawing, enemies are immune to freeze for 5s", "color": Color(0.4, 0.8, 1.0)},
		{"name": "Corruption", "desc": "Permanently reduces max HP while active", "color": Color(0.3, 0.0, 0.5)},
		{"name": "Poison Stacking", "desc": "Poison damage increases with each stack", "color": Color(0.6, 0.2, 0.8)}
	]

	for interaction in interactions:
		var row := _create_interaction_row(interaction)
		vbox.add_child(row)


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


func _create_effect_card(effect_id: String, effect_def: Dictionary) -> Control:
	var effect_name: String = str(effect_def.get("name", effect_id.capitalize()))
	var description: String = str(effect_def.get("description", ""))
	var color: Color = SimStatusEffects.get_effect_color(effect_id)
	var category: String = str(effect_def.get("category", "debuff"))

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = color.darkened(0.85)
	container_style.border_color = color.darkened(0.5)
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

	# Category badge
	var badge := _create_category_badge(category)
	header.add_child(badge)

	# Name
	var name_label := Label.new()
	name_label.text = effect_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", color)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_vbox.add_child(desc_label)

	# Stats row
	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 12)
	main_vbox.add_child(stats_row)

	# Duration
	var base_duration: float = float(effect_def.get("duration", 0))
	if base_duration > 0:
		var dur_chip := _create_stat_chip("%.1fs" % base_duration, Color(0.9, 0.9, 0.4))
		stats_row.add_child(dur_chip)

	# Max stacks
	var max_stacks: int = int(effect_def.get("max_stacks", 1))
	if max_stacks > 1:
		var stack_chip := _create_stat_chip("Max %d stacks" % max_stacks, Color(0.6, 0.8, 0.6))
		stats_row.add_child(stack_chip)

	# Tick damage
	if effect_def.has("tick_damage"):
		var tick_dmg: int = int(effect_def.get("tick_damage", 0))
		var tick_int: float = float(effect_def.get("tick_interval", 1.0))
		var dmg_chip := _create_stat_chip("%d dmg/%.0fs" % [tick_dmg, tick_int], Color(0.9, 0.4, 0.4))
		stats_row.add_child(dmg_chip)

	# Movement effects
	if effect_def.has("immobilize") and bool(effect_def.get("immobilize", false)):
		var stop_chip := _create_stat_chip("Stops movement", Color(0.4, 0.8, 1.0))
		stats_row.add_child(stop_chip)

	# Slow tiers
	if effect_def.has("tiers"):
		var tiers: Array = effect_def.get("tiers", [])
		if not tiers.is_empty():
			var tier1: Dictionary = tiers[0]
			var slow_pct: int = int(tier1.get("slow_percent", 0))
			if slow_pct > 0:
				var slow_chip := _create_stat_chip("-%d%% speed" % slow_pct, Color(0.53, 0.81, 0.92))
				stats_row.add_child(slow_chip)

	# Damage modifiers
	if effect_def.has("damage_taken_increase"):
		var increase: int = int(float(effect_def.get("damage_taken_increase", 0)) * 100)
		var mod_chip := _create_stat_chip("+%d%% dmg taken" % increase, Color(0.9, 0.4, 0.9))
		stats_row.add_child(mod_chip)

	if effect_def.has("armor_reduction_percent"):
		var reduction: int = int(effect_def.get("armor_reduction_percent", 0))
		var armor_chip := _create_stat_chip("-%d%% armor" % reduction, Color(0.6, 0.6, 0.7))
		stats_row.add_child(armor_chip)

	if effect_def.has("damage_dealt_reduction"):
		var reduction: int = int(float(effect_def.get("damage_dealt_reduction", 0)) * 100)
		var dmg_chip := _create_stat_chip("-%d%% dmg dealt" % reduction, Color(0.7, 0.7, 0.8))
		stats_row.add_child(dmg_chip)

	return container


func _create_category_badge(category: String) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(50, 20)

	var badge_color: Color
	var badge_text: String
	match category:
		"debuff":
			badge_color = Color(0.9, 0.4, 0.4)
			badge_text = "DBF"
		"buff":
			badge_color = Color(0.4, 0.9, 0.4)
			badge_text = "BUF"
		_:
			badge_color = Color(0.7, 0.7, 0.7)
			badge_text = "NEU"

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = badge_color.darkened(0.6)
	panel_style.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel", panel_style)

	var label := Label.new()
	label.text = badge_text
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", badge_color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(label)

	return panel


func _create_stat_chip(text: String, color: Color) -> Control:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", color)
	return label


func _create_active_row(effect_id: String, count: int) -> Control:
	var effect_name: String = SimStatusEffects.get_effect_name(effect_id)
	var color: Color = SimStatusEffects.get_effect_color(effect_id)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	var name_label := Label.new()
	name_label.text = effect_name
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", color)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)

	var count_label := Label.new()
	count_label.text = "x%d enemies" % count
	count_label.add_theme_font_size_override("font_size", 12)
	count_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
	hbox.add_child(count_label)

	return hbox


func _create_interaction_row(interaction: Dictionary) -> Control:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	var name_label := Label.new()
	name_label.text = str(interaction.get("name", ""))
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", interaction.get("color", Color.WHITE))
	name_label.custom_minimum_size = Vector2(100, 0)
	hbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = str(interaction.get("desc", ""))
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(desc_label)

	return hbox


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
