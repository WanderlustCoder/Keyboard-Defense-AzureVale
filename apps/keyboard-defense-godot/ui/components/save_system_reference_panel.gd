class_name SaveSystemReferencePanel
extends PanelContainer
## Save System Reference Panel - Shows what data is saved and how.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Save data categories
const SAVE_CATEGORIES: Array[Dictionary] = [
	{
		"name": "Core State",
		"desc": "Day, phase, action points, castle HP",
		"fields": "day, phase, ap, ap_max, hp, threat",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"name": "Resources",
		"desc": "All gathered and stored resources",
		"fields": "gold, wood, stone, food",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"name": "Map State",
		"desc": "Terrain, structures, discovery",
		"fields": "terrain, structures, structure_levels, discovered",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"name": "Enemies",
		"desc": "Active enemies with positions and words",
		"fields": "enemies, enemy_next_id",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"name": "Tower System",
		"desc": "Tower states, summons, traps, synergies",
		"fields": "tower_states, summoned_units, active_traps",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"name": "Events",
		"desc": "POIs, event flags, cooldowns, buffs",
		"fields": "active_pois, event_flags, event_cooldowns, active_buffs",
		"color": Color(0.7, 0.5, 0.9)
	},
	{
		"name": "Upgrades",
		"desc": "Purchased kingdom and unit upgrades",
		"fields": "purchased_kingdom_upgrades, purchased_unit_upgrades",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"name": "Typing Metrics",
		"desc": "Battle typing statistics",
		"fields": "typing_metrics, lesson_id",
		"color": Color(0.5, 0.8, 0.3)
	}
]

# Save features
const SAVE_FEATURES: Array[Dictionary] = [
	{
		"feature": "Version Check",
		"desc": "Saves include version number for compatibility",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"feature": "Full State",
		"desc": "Complete game state is preserved",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"feature": "Enemy Words",
		"desc": "Enemy words are regenerated on load if missing",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"feature": "Structure Levels",
		"desc": "Building upgrade levels are tracked per tile",
		"color": Color(0.7, 0.5, 0.9)
	},
	{
		"feature": "RNG State",
		"desc": "Random seed and state for deterministic replay",
		"color": Color(0.9, 0.4, 0.4)
	}
]

# Profile data (separate from game save)
const PROFILE_DATA: Array[Dictionary] = [
	{
		"category": "Progress",
		"items": "XP, level, unlocked lessons, achievements",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"category": "Statistics",
		"items": "Total words typed, accuracy, best WPM",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"category": "Streaks",
		"items": "Daily login streak, practice streak",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"category": "Equipment",
		"items": "Equipped items across all slots",
		"color": Color(0.7, 0.5, 0.9)
	},
	{
		"category": "Settings",
		"items": "Volume, difficulty, key bindings",
		"color": Color(0.9, 0.4, 0.4)
	}
]

# Serialization notes
const SERIALIZATION_INFO: Array[Dictionary] = [
	{
		"topic": "Vector2i",
		"desc": "Positions stored as {x: N, y: N} dictionaries",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"topic": "Dictionaries",
		"desc": "Integer keys converted to strings for JSON",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"topic": "Arrays",
		"desc": "Lists preserved with full structure",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"topic": "Defaults",
		"desc": "Missing fields get default values on load",
		"color": Color(0.7, 0.5, 0.9)
	}
]

# Tips
const SAVE_TIPS: Array[String] = [
	"Game auto-saves at the start of each day",
	"Profile saves separately from the current run",
	"Save files are JSON format for portability",
	"Version mismatches show a warning on load",
	"RNG state ensures replays are deterministic"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 620)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "SAVE SYSTEM"
	DesignSystem.style_label(title, "h2", Color(0.5, 0.8, 0.3))
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
	subtitle.text = "What data is saved and how"
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
	footer.text = "Progress is automatically saved"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_save_system_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Save categories section
	_build_categories_section()

	# Features section
	_build_features_section()

	# Profile section
	_build_profile_section()

	# Serialization section
	_build_serialization_section()

	# Tips section
	_build_tips_section()


func _build_categories_section() -> void:
	var section := _create_section_panel("GAME SAVE DATA", Color(0.4, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for cat in SAVE_CATEGORIES:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 2)
		vbox.add_child(container)

		var name_label := Label.new()
		name_label.text = str(cat.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", cat.get("color", Color.WHITE))
		container.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = "  " + str(cat.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		container.add_child(desc_label)


func _build_features_section() -> void:
	var section := _create_section_panel("SAVE FEATURES", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for feature in SAVE_FEATURES:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var feature_label := Label.new()
		feature_label.text = str(feature.get("feature", ""))
		feature_label.add_theme_font_size_override("font_size", 10)
		feature_label.add_theme_color_override("font_color", feature.get("color", Color.WHITE))
		feature_label.custom_minimum_size = Vector2(110, 0)
		hbox.add_child(feature_label)

		var desc_label := Label.new()
		desc_label.text = str(feature.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_profile_section() -> void:
	var section := _create_section_panel("PROFILE DATA (Separate)", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for data in PROFILE_DATA:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var cat_label := Label.new()
		cat_label.text = str(data.get("category", ""))
		cat_label.add_theme_font_size_override("font_size", 10)
		cat_label.add_theme_color_override("font_color", data.get("color", Color.WHITE))
		cat_label.custom_minimum_size = Vector2(80, 0)
		hbox.add_child(cat_label)

		var items_label := Label.new()
		items_label.text = str(data.get("items", ""))
		items_label.add_theme_font_size_override("font_size", 9)
		items_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(items_label)


func _build_serialization_section() -> void:
	var section := _create_section_panel("SERIALIZATION", Color(0.7, 0.5, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in SERIALIZATION_INFO:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var topic_label := Label.new()
		topic_label.text = str(info.get("topic", ""))
		topic_label.add_theme_font_size_override("font_size", 10)
		topic_label.add_theme_color_override("font_color", info.get("color", Color.WHITE))
		topic_label.custom_minimum_size = Vector2(80, 0)
		hbox.add_child(topic_label)

		var desc_label := Label.new()
		desc_label.text = str(info.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("SAVE TIPS", Color(0.9, 0.4, 0.4))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in SAVE_TIPS:
		var tip_label := Label.new()
		tip_label.text = "- " + tip
		tip_label.add_theme_font_size_override("font_size", 10)
		tip_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(tip_label)


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
