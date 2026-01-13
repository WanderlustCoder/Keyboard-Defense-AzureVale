class_name WaveComposerReferencePanel
extends PanelContainer
## Wave Composer Reference Panel - Shows wave themes, modifiers, and special events.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Wave themes
const WAVE_THEMES: Array[Dictionary] = [
	{
		"id": "standard",
		"name": "Standard Assault",
		"desc": "Balanced mix of enemies",
		"unlock_day": 1,
		"color": Color(0.7, 0.7, 0.7)
	},
	{
		"id": "swarm",
		"name": "Swarming Tide",
		"desc": "Many weak enemies (1.5x count, 0.6x HP)",
		"unlock_day": 2,
		"color": Color(0.4, 0.8, 0.4)
	},
	{
		"id": "balanced",
		"name": "Mixed Forces",
		"desc": "Diverse enemy types",
		"unlock_day": 2,
		"color": Color(0.5, 0.6, 0.8)
	},
	{
		"id": "speedy",
		"name": "Swift Raiders",
		"desc": "Fast-moving enemies (1.4x speed)",
		"unlock_day": 3,
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"id": "tanky",
		"name": "Iron Wall",
		"desc": "Slow but durable (0.7x speed, 1.8x HP)",
		"unlock_day": 3,
		"color": Color(0.5, 0.5, 0.6)
	},
	{
		"id": "elite",
		"name": "Elite Vanguard",
		"desc": "Fewer but stronger (0.6x count, 1.5x HP/gold)",
		"unlock_day": 5,
		"color": Color(0.8, 0.6, 1.0)
	},
	{
		"id": "magic",
		"name": "Arcane Invasion",
		"desc": "Magical creatures",
		"unlock_day": 5,
		"color": Color(0.6, 0.4, 1.0)
	},
	{
		"id": "undead",
		"name": "Undead Uprising",
		"desc": "Risen horrors (0.7x gold)",
		"unlock_day": 7,
		"color": Color(0.4, 0.5, 0.4)
	},
	{
		"id": "burning",
		"name": "Infernal Tide",
		"desc": "Fire-aligned (30% burning affix)",
		"unlock_day": 7,
		"color": Color(1.0, 0.4, 0.2)
	},
	{
		"id": "frozen",
		"name": "Frozen Legion",
		"desc": "Ice-aligned (30% frozen affix)",
		"unlock_day": 10,
		"color": Color(0.4, 0.7, 1.0)
	},
	{
		"id": "boss_assault",
		"name": "Champion's Challenge",
		"desc": "Mini-bosses leading (0.7x count, 1.3x HP)",
		"unlock_day": 10,
		"color": Color(0.96, 0.26, 0.21)
	}
]

# Wave modifiers
const WAVE_MODIFIERS: Array[Dictionary] = [
	{
		"id": "swift",
		"name": "Swift Advance",
		"desc": "Enemies move 1.3x faster",
		"unlock_day": 3,
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"id": "treasure",
		"name": "Treasure Carriers",
		"desc": "Enemies drop 2x gold",
		"unlock_day": 3,
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"id": "armored",
		"name": "Armored Assault",
		"desc": "40% chance of armored affix",
		"unlock_day": 4,
		"color": Color(0.5, 0.5, 0.6)
	},
	{
		"id": "enraged",
		"name": "Enraged Horde",
		"desc": "Enemies deal 1.5x damage",
		"unlock_day": 4,
		"color": Color(0.96, 0.26, 0.21)
	},
	{
		"id": "toxic",
		"name": "Toxic Menace",
		"desc": "25% chance of toxic affix",
		"unlock_day": 6,
		"color": Color(0.4, 0.8, 0.3)
	},
	{
		"id": "double_trouble",
		"name": "Double Trouble",
		"desc": "2x enemies but 0.5x HP",
		"unlock_day": 6,
		"color": Color(0.8, 0.6, 0.2)
	},
	{
		"id": "shielded",
		"name": "Shield Wall",
		"desc": "20% chance of shielded affix",
		"unlock_day": 8,
		"color": Color(0.4, 0.6, 1.0)
	},
	{
		"id": "vampiric",
		"name": "Blood Drinkers",
		"desc": "15% chance of vampiric affix",
		"unlock_day": 10,
		"color": Color(0.6, 0.2, 0.2)
	}
]

# Special wave events
const SPECIAL_WAVES: Array[Dictionary] = [
	{
		"id": "ambush",
		"name": "Ambush!",
		"desc": "Enemies spawn from multiple directions",
		"unlock_day": 5,
		"color": Color(0.96, 0.26, 0.21)
	},
	{
		"id": "boss_rush",
		"name": "Boss Rush",
		"desc": "Multiple mini-bosses attack at once",
		"unlock_day": 5,
		"color": Color(0.8, 0.2, 0.2)
	},
	{
		"id": "countdown",
		"name": "Countdown",
		"desc": "Complete the wave in 60 seconds!",
		"unlock_day": 5,
		"color": Color(1.0, 0.6, 0.2)
	},
	{
		"id": "survival",
		"name": "Survival Wave",
		"desc": "Endless enemies for 45 seconds",
		"unlock_day": 5,
		"color": Color(0.8, 0.4, 1.0)
	}
]

# Wave mechanics
const WAVE_MECHANICS: Array[Dictionary] = [
	{
		"name": "Theme Selection",
		"desc": "Themes unlock as you progress through days",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"name": "Modifier Chance",
		"desc": "20% chance for modifier after day 3",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"name": "Special Chance",
		"desc": "5% chance on final wave after day 5",
		"color": Color(0.96, 0.26, 0.21)
	},
	{
		"name": "Enemy Count",
		"desc": "Base: 3 + wave_num + (day * 0.5)",
		"color": Color(0.6, 0.6, 0.8)
	},
	{
		"name": "Final Wave Bonus",
		"desc": "40% chance of elite/boss theme on final wave",
		"color": Color(0.8, 0.6, 1.0)
	}
]

# Tips
const WAVE_TIPS: Array[String] = [
	"Themes determine the types of enemies you'll face",
	"Modifiers add extra challenge with special properties",
	"Special waves are rare events on final waves",
	"Elite and Boss themes give more gold but are harder",
	"Watch for affix chances - they can stack!"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 740)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "WAVE COMPOSER"
	DesignSystem.style_label(title, "h2", ThemeColors.ERROR)
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
	subtitle.text = "11 themes, 8 modifiers, 4 special events"
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
	footer.text = "Waves become more varied as you progress"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_wave_composer_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Mechanics overview
	_build_mechanics_section()

	# Wave themes
	_build_themes_section()

	# Wave modifiers
	_build_modifiers_section()

	# Special waves
	_build_specials_section()

	# Tips
	_build_tips_section()


func _build_mechanics_section() -> void:
	var section := _create_section_panel("WAVE MECHANICS", Color(0.5, 0.6, 0.7))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for mech in WAVE_MECHANICS:
		var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(mech.get("name", ""))
		DesignSystem.style_label(name_label, "caption", mech.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(110, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(mech.get("desc", ""))
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_themes_section() -> void:
	var section := _create_section_panel("WAVE THEMES (11)", Color(0.6, 0.5, 0.8))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for theme in WAVE_THEMES:
		var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_SM)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(theme.get("name", ""))
		DesignSystem.style_label(name_label, "caption", theme.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(120, 0)
		hbox.add_child(name_label)

		var day_label := Label.new()
		day_label.text = "D%d+" % theme.get("unlock_day", 1)
		DesignSystem.style_label(day_label, "caption", Color(0.5, 0.6, 0.5))
		day_label.custom_minimum_size = Vector2(30, 0)
		hbox.add_child(day_label)

		var desc_label := Label.new()
		desc_label.text = str(theme.get("desc", ""))
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_modifiers_section() -> void:
	var section := _create_section_panel("WAVE MODIFIERS (8)", Color(1.0, 0.6, 0.2))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for mod in WAVE_MODIFIERS:
		var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_SM)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(mod.get("name", ""))
		DesignSystem.style_label(name_label, "caption", mod.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(110, 0)
		hbox.add_child(name_label)

		var day_label := Label.new()
		day_label.text = "D%d+" % mod.get("unlock_day", 1)
		DesignSystem.style_label(day_label, "caption", Color(0.5, 0.6, 0.5))
		day_label.custom_minimum_size = Vector2(30, 0)
		hbox.add_child(day_label)

		var desc_label := Label.new()
		desc_label.text = str(mod.get("desc", ""))
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_specials_section() -> void:
	var section := _create_section_panel("SPECIAL EVENTS (4)", ThemeColors.ERROR)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for special in SPECIAL_WAVES:
		var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(special.get("name", ""))
		DesignSystem.style_label(name_label, "caption", special.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(110, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(special.get("desc", ""))
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("WAVE TIPS", ThemeColors.SUCCESS)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in WAVE_TIPS:
		var tip_label := Label.new()
		tip_label.text = "- " + tip
		DesignSystem.style_label(tip_label, "caption", ThemeColors.TEXT_DIM)
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
