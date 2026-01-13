class_name SpecialCommandsReferencePanel
extends PanelContainer
## Special Commands Reference Panel - Shows special typing abilities.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# All special commands
const SPECIAL_COMMANDS: Array[Dictionary] = [
	{
		"word": "HEAL",
		"name": "Healing Word",
		"desc": "Restore 3 castle HP",
		"cooldown": 120,
		"difficulty": "easy",
		"unlock_level": 1,
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"word": "FURY",
		"name": "Typing Fury",
		"desc": "+50% damage for 10 seconds",
		"cooldown": 40,
		"difficulty": "easy",
		"unlock_level": 3,
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"word": "GOLD",
		"name": "Gold Rush",
		"desc": "+100% gold for 20 seconds",
		"cooldown": 60,
		"difficulty": "easy",
		"unlock_level": 5,
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"word": "COMBO",
		"name": "Combo Boost",
		"desc": "Instantly gain +10 combo",
		"cooldown": 45,
		"difficulty": "medium",
		"unlock_level": 7,
		"color": Color(0.7, 0.5, 0.9)
	},
	{
		"word": "BARRAGE",
		"name": "Barrage",
		"desc": "Next 5 typing attacks deal double damage",
		"cooldown": 45,
		"difficulty": "medium",
		"unlock_level": 10,
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"word": "FREEZE",
		"name": "Frost Nova",
		"desc": "Freeze all enemies for 3 seconds",
		"cooldown": 75,
		"difficulty": "medium",
		"unlock_level": 12,
		"color": Color(0.0, 0.75, 1.0)
	},
	{
		"word": "CRITICAL",
		"name": "Critical Focus",
		"desc": "Next 3 attacks are guaranteed crits",
		"cooldown": 30,
		"difficulty": "hard",
		"unlock_level": 15,
		"color": Color(1.0, 0.5, 0.0)
	},
	{
		"word": "CLEAVE",
		"name": "Cleaving Strike",
		"desc": "Next attack hits all enemies for 50% damage",
		"cooldown": 50,
		"difficulty": "medium",
		"unlock_level": 18,
		"color": Color(0.8, 0.4, 0.4)
	},
	{
		"word": "SHIELD",
		"name": "Shield Wall",
		"desc": "Block the next 2 enemies from damaging castle",
		"cooldown": 80,
		"difficulty": "medium",
		"unlock_level": 20,
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"word": "EXECUTE",
		"name": "Execute",
		"desc": "Instantly kill targeted enemy if below 30% HP",
		"cooldown": 35,
		"difficulty": "hard",
		"unlock_level": 22,
		"color": Color(0.55, 0.0, 0.0)
	},
	{
		"word": "FORTIFY",
		"name": "Fortify",
		"desc": "Castle takes 50% less damage for 15 seconds",
		"cooldown": 90,
		"difficulty": "hard",
		"unlock_level": 25,
		"color": Color(0.5, 0.5, 0.5)
	},
	{
		"word": "OVERCHARGE",
		"name": "Overcharge",
		"desc": "All auto-towers fire at 200% speed for 5 seconds",
		"cooldown": 60,
		"difficulty": "hard",
		"unlock_level": 30,
		"color": Color(1.0, 1.0, 0.0)
	}
]

# Effect types
const EFFECT_TYPES: Array[Dictionary] = [
	{
		"type": "Instant",
		"desc": "Effect applies immediately",
		"examples": "HEAL, COMBO, EXECUTE",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"type": "Duration",
		"desc": "Effect lasts for a set time",
		"examples": "FURY, GOLD, FREEZE, FORTIFY",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"type": "Charges",
		"desc": "Effect applies to next N attacks",
		"examples": "BARRAGE, CRITICAL, SHIELD",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"type": "Next Attack",
		"desc": "Effect applies to next attack only",
		"examples": "CLEAVE",
		"color": Color(0.7, 0.5, 0.9)
	}
]

# Difficulty info
const DIFFICULTY_INFO: Array[Dictionary] = [
	{
		"level": "Easy",
		"words": "4-5 letters",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"level": "Medium",
		"words": "5-7 letters",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"level": "Hard",
		"words": "7-10 letters",
		"color": Color(0.9, 0.4, 0.4)
	}
]

# Tips
const COMMAND_TIPS: Array[String] = [
	"Type command words during defense phase to activate",
	"Commands have cooldowns - plan your usage",
	"Higher level = more powerful commands unlocked",
	"HEAL is essential for survival in tough waves",
	"FREEZE + BARRAGE is a devastating combo"
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
	title.text = "SPECIAL COMMANDS"
	DesignSystem.style_label(title, "h2", Color(1.0, 0.84, 0.0))
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
	subtitle.text = "Powerful abilities activated by typing words"
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
	footer.text = "12 special commands available"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_special_commands_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Commands section
	_build_commands_section()

	# Effect types section
	_build_effect_types_section()

	# Difficulty section
	_build_difficulty_section()

	# Tips section
	_build_tips_section()


func _build_commands_section() -> void:
	var section := _create_section_panel("ALL COMMANDS", Color(1.0, 0.84, 0.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for cmd in SPECIAL_COMMANDS:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 2)
		vbox.add_child(container)

		# Word and name
		var header_hbox := HBoxContainer.new()
		header_hbox.add_theme_constant_override("separation", 10)
		container.add_child(header_hbox)

		var word_label := Label.new()
		word_label.text = str(cmd.get("word", ""))
		word_label.add_theme_font_size_override("font_size", 10)
		word_label.add_theme_color_override("font_color", cmd.get("color", Color.WHITE))
		word_label.custom_minimum_size = Vector2(90, 0)
		header_hbox.add_child(word_label)

		var name_label := Label.new()
		name_label.text = "(%s)" % cmd.get("name", "")
		name_label.add_theme_font_size_override("font_size", 9)
		name_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		header_hbox.add_child(name_label)

		# Description
		var desc_label := Label.new()
		desc_label.text = "  " + str(cmd.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		container.add_child(desc_label)

		# Details
		var difficulty: String = str(cmd.get("difficulty", "medium"))
		var diff_color: Color
		match difficulty:
			"easy": diff_color = Color(0.5, 0.8, 0.3)
			"medium": diff_color = Color(0.9, 0.6, 0.3)
			_: diff_color = Color(0.9, 0.4, 0.4)

		var details_hbox := HBoxContainer.new()
		details_hbox.add_theme_constant_override("separation", 15)
		container.add_child(details_hbox)

		var cd_label := Label.new()
		cd_label.text = "  CD: %ds" % cmd.get("cooldown", 0)
		cd_label.add_theme_font_size_override("font_size", 9)
		cd_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		details_hbox.add_child(cd_label)

		var diff_label := Label.new()
		diff_label.text = difficulty.capitalize()
		diff_label.add_theme_font_size_override("font_size", 9)
		diff_label.add_theme_color_override("font_color", diff_color)
		details_hbox.add_child(diff_label)

		var unlock_label := Label.new()
		unlock_label.text = "Lv.%d" % cmd.get("unlock_level", 1)
		unlock_label.add_theme_font_size_override("font_size", 9)
		unlock_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		details_hbox.add_child(unlock_label)


func _build_effect_types_section() -> void:
	var section := _create_section_panel("EFFECT TYPES", Color(0.7, 0.5, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in EFFECT_TYPES:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 2)
		vbox.add_child(container)

		var type_label := Label.new()
		type_label.text = str(info.get("type", ""))
		type_label.add_theme_font_size_override("font_size", 10)
		type_label.add_theme_color_override("font_color", info.get("color", Color.WHITE))
		container.add_child(type_label)

		var desc_label := Label.new()
		desc_label.text = "  " + str(info.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		container.add_child(desc_label)

		var examples_label := Label.new()
		examples_label.text = "  Ex: " + str(info.get("examples", ""))
		examples_label.add_theme_font_size_override("font_size", 9)
		examples_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		container.add_child(examples_label)


func _build_difficulty_section() -> void:
	var section := _create_section_panel("WORD DIFFICULTY", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in DIFFICULTY_INFO:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var level_label := Label.new()
		level_label.text = str(info.get("level", ""))
		level_label.add_theme_font_size_override("font_size", 10)
		level_label.add_theme_color_override("font_color", info.get("color", Color.WHITE))
		level_label.custom_minimum_size = Vector2(60, 0)
		hbox.add_child(level_label)

		var words_label := Label.new()
		words_label.text = str(info.get("words", ""))
		words_label.add_theme_font_size_override("font_size", 9)
		words_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(words_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("COMMAND TIPS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in COMMAND_TIPS:
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
