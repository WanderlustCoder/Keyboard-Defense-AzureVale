class_name AffixesPanel
extends PanelContainer
## Affixes Panel - Encyclopedia of enemy affixes and their effects

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")
const SimAffixes = preload("res://sim/affixes.gd")

var _state: RefCounted = null

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Affix tier colors
const TIER_COLORS: Dictionary = {
	1: Color(0.6, 0.8, 0.6),   # Green - common
	2: Color(0.4, 0.6, 1.0),   # Blue - rare
	3: Color(0.9, 0.5, 0.9)    # Purple - epic
}

# Affix glyph colors
const GLYPH_COLORS: Dictionary = {
	"swift": Color(0.9, 0.9, 0.4),
	"armored": Color(0.6, 0.6, 0.7),
	"resilient": Color(0.9, 0.4, 0.4),
	"shielded": Color(0.4, 0.8, 1.0),
	"splitting": Color(0.4, 0.9, 0.4),
	"regenerating": Color(0.4, 0.9, 0.7),
	"enraged": Color(1.0, 0.5, 0.3),
	"vampiric": Color(0.8, 0.2, 0.3)
}


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(460, 480)

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
	title.text = "ENEMY AFFIXES"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.9, 0.5, 0.9))
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
	subtitle.text = "Special modifiers that make enemies more dangerous"
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
	footer.text = "Affixed enemies appear after Day 4"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_affixes(state: RefCounted = null) -> void:
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

	# Build affix tiers
	for tier in [1, 2, 3]:
		var tier_name: String = _get_tier_name(tier)
		var tier_color: Color = TIER_COLORS.get(tier, Color.WHITE)
		var unlock_day: int = _get_unlock_day(tier)

		var section := _create_section_panel(tier_name, tier_color, unlock_day)
		_content_vbox.add_child(section)

		var vbox: VBoxContainer = section.get_child(0)

		var affixes: Array = SimAffixes.get_affixes_for_tier(tier)
		for affix in affixes:
			var card := _create_affix_card(affix)
			vbox.add_child(card)

	# Active affixes section (if state provided)
	if _state != null:
		_build_active_affixes_section()


func _build_active_affixes_section() -> void:
	if _state == null:
		return

	# Count active affixes on enemies
	var active_counts: Dictionary = {}
	for enemy in _state.enemies:
		var affix: String = str(enemy.get("affix", ""))
		if affix != "":
			active_counts[affix] = active_counts.get(affix, 0) + 1

	if active_counts.is_empty():
		return

	var section := _create_section_panel("ACTIVE ON FIELD", Color(0.9, 0.4, 0.4), 0)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for affix_id in active_counts.keys():
		var count: int = active_counts[affix_id]
		var affix: Dictionary = SimAffixes.get_affix(affix_id)
		var row := _create_active_row(affix, count)
		vbox.add_child(row)


func _create_section_panel(title: String, color: Color, unlock_day: int) -> PanelContainer:
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

	var header_row := HBoxContainer.new()
	vbox.add_child(header_row)

	var header := Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 13)
	header.add_theme_color_override("font_color", color)
	header_row.add_child(header)

	if unlock_day > 0:
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header_row.add_child(spacer)

		var unlock_label := Label.new()
		unlock_label.text = "Unlocks Day %d" % unlock_day
		unlock_label.add_theme_font_size_override("font_size", 10)
		unlock_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		header_row.add_child(unlock_label)

	return container


func _create_affix_card(affix: Dictionary) -> Control:
	var affix_id: String = str(affix.get("id", ""))
	var affix_name: String = str(affix.get("name", ""))
	var description: String = str(affix.get("description", ""))
	var glyph: String = str(affix.get("glyph", "?"))
	var tier: int = int(affix.get("tier", 1))

	var speed_bonus: int = int(affix.get("speed_bonus", 0))
	var armor_bonus: int = int(affix.get("armor_bonus", 0))
	var hp_bonus: int = int(affix.get("hp_bonus", 0))
	var special: String = str(affix.get("special", ""))

	var color: Color = GLYPH_COLORS.get(affix_id, Color(0.7, 0.7, 0.7))
	var tier_color: Color = TIER_COLORS.get(tier, Color.WHITE)

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = color.darkened(0.85)
	container_style.border_color = color.darkened(0.5)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(8)
	container.add_theme_stylebox_override("panel", container_style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	container.add_child(hbox)

	# Glyph icon
	var glyph_panel := _create_glyph_icon(glyph, color)
	hbox.add_child(glyph_panel)

	# Info column
	var info_vbox := VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 4)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	# Name
	var name_label := Label.new()
	name_label.text = affix_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", color)
	info_vbox.add_child(name_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	info_vbox.add_child(desc_label)

	# Stats row
	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 10)
	info_vbox.add_child(stats_row)

	if speed_bonus > 0:
		var stat := _create_stat_chip("+%d SPD" % speed_bonus, Color(0.9, 0.9, 0.4))
		stats_row.add_child(stat)

	if armor_bonus > 0:
		var stat := _create_stat_chip("+%d ARM" % armor_bonus, Color(0.6, 0.6, 0.7))
		stats_row.add_child(stat)

	if hp_bonus > 0:
		var stat := _create_stat_chip("+%d HP" % hp_bonus, Color(0.9, 0.4, 0.4))
		stats_row.add_child(stat)

	if special != "":
		var special_label := _create_stat_chip(_format_special(special), Color(0.9, 0.7, 0.4))
		stats_row.add_child(special_label)

	return container


func _create_glyph_icon(glyph: String, color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(40, 40)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = color.darkened(0.7)
	panel_style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", panel_style)

	var label := Label.new()
	label.text = glyph
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", color)
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


func _create_active_row(affix: Dictionary, count: int) -> Control:
	var affix_id: String = str(affix.get("id", ""))
	var affix_name: String = str(affix.get("name", ""))
	var glyph: String = str(affix.get("glyph", "?"))
	var color: Color = GLYPH_COLORS.get(affix_id, Color(0.7, 0.7, 0.7))

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	var glyph_label := Label.new()
	glyph_label.text = "[%s]" % glyph
	glyph_label.add_theme_font_size_override("font_size", 14)
	glyph_label.add_theme_color_override("font_color", color)
	hbox.add_child(glyph_label)

	var name_label := Label.new()
	name_label.text = affix_name
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", color)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)

	var count_label := Label.new()
	count_label.text = "x%d" % count
	count_label.add_theme_font_size_override("font_size", 14)
	count_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
	hbox.add_child(count_label)

	return hbox


func _get_tier_name(tier: int) -> String:
	match tier:
		1:
			return "TIER 1 - COMMON"
		2:
			return "TIER 2 - RARE"
		3:
			return "TIER 3 - EPIC"
	return "UNKNOWN"


func _get_unlock_day(tier: int) -> int:
	match tier:
		1:
			return 5
		2:
			return 4
		3:
			return 7
	return 1


func _format_special(special: String) -> String:
	match special:
		"first_hit_immunity":
			return "Shield"
		"spawn_on_death":
			return "Splits"
		"regenerate":
			return "Regen"
		"enrage_on_damage":
			return "Enrage"
		"lifesteal":
			return "Lifesteal"
	return special.capitalize()


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
