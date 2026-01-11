class_name SpecialCommandsPanel
extends PanelContainer
## Special Commands Panel - Shows all special typing commands and their effects

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")
const SimSpecialCommands = preload("res://sim/special_commands.gd")

var _player_level: int = 1
var _command_cooldowns: Dictionary = {}

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Effect type colors
const EFFECT_COLORS: Dictionary = {
	"damage": Color(0.9, 0.4, 0.4),
	"defense": Color(0.4, 0.6, 0.9),
	"utility": Color(0.9, 0.9, 0.4),
	"buff": Color(0.4, 0.9, 0.4)
}

# Difficulty colors
const DIFFICULTY_COLORS: Dictionary = {
	"easy": Color(0.4, 0.9, 0.4),
	"medium": Color(0.9, 0.9, 0.4),
	"hard": Color(0.9, 0.6, 0.3)
}


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(500, 540)

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
	title.text = "SPECIAL COMMANDS"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.4))
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
	subtitle.text = "Type these words during combat to trigger powerful abilities"
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
	_content_vbox.add_theme_constant_override("separation", 8)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_vbox)

	# Footer
	var footer := Label.new()
	footer.text = "Commands have cooldowns - use them wisely!"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_special_commands(player_level: int = 1, cooldowns: Dictionary = {}) -> void:
	_player_level = player_level
	_command_cooldowns = cooldowns
	_build_content()
	show()


func refresh(cooldowns: Dictionary = {}) -> void:
	_command_cooldowns = cooldowns
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Group commands by unlock status
	var unlocked_commands: Array[String] = []
	var locked_commands: Array[String] = []

	for command_id in SimSpecialCommands.COMMANDS.keys():
		if SimSpecialCommands.is_unlocked(command_id, _player_level):
			unlocked_commands.append(command_id)
		else:
			locked_commands.append(command_id)

	# Sort by unlock level
	unlocked_commands.sort_custom(_sort_by_unlock_level)
	locked_commands.sort_custom(_sort_by_unlock_level)

	# Unlocked section
	if not unlocked_commands.is_empty():
		var section := _create_section_panel("AVAILABLE COMMANDS", Color(0.4, 0.9, 0.4))
		_content_vbox.add_child(section)

		var vbox: VBoxContainer = section.get_child(0)

		for command_id in unlocked_commands:
			var command: Dictionary = SimSpecialCommands.get_command(command_id)
			var cooldown: float = _command_cooldowns.get(command_id, 0.0)
			var card := _create_command_card(command_id, command, true, cooldown)
			vbox.add_child(card)

	# Locked section
	if not locked_commands.is_empty():
		var section := _create_section_panel("LOCKED COMMANDS", Color(0.5, 0.5, 0.5))
		_content_vbox.add_child(section)

		var vbox: VBoxContainer = section.get_child(0)

		for command_id in locked_commands:
			var command: Dictionary = SimSpecialCommands.get_command(command_id)
			var card := _create_command_card(command_id, command, false, 0.0)
			vbox.add_child(card)

	# Tips section
	_build_tips_section()


func _sort_by_unlock_level(a: String, b: String) -> bool:
	return SimSpecialCommands.get_unlock_level(a) < SimSpecialCommands.get_unlock_level(b)


func _create_section_panel(title: String, color: Color) -> PanelContainer:
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

	var header := Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 13)
	header.add_theme_color_override("font_color", color)
	vbox.add_child(header)

	return container


func _create_command_card(command_id: String, command: Dictionary, is_unlocked: bool, cooldown: float) -> Control:
	var cmd_name: String = str(command.get("name", command_id))
	var word: String = str(command.get("word", ""))
	var description: String = str(command.get("description", ""))
	var difficulty: String = str(command.get("difficulty", "medium"))
	var base_cooldown: float = float(command.get("cooldown", 60.0))
	var unlock_level: int = SimSpecialCommands.get_unlock_level(command_id)

	var diff_color: Color = DIFFICULTY_COLORS.get(difficulty, Color.WHITE)
	var effect_category: String = _get_effect_category(command)
	var category_color: Color = EFFECT_COLORS.get(effect_category, Color.WHITE)

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	if is_unlocked:
		container_style.bg_color = category_color.darkened(0.85)
		container_style.border_color = category_color.darkened(0.5)
	else:
		container_style.bg_color = Color(0.1, 0.1, 0.12, 0.6)
		container_style.border_color = Color(0.3, 0.3, 0.35)
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

	# Word to type (prominent)
	var word_label := Label.new()
	word_label.text = word
	word_label.add_theme_font_size_override("font_size", 16)
	if is_unlocked:
		word_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	else:
		word_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	header.add_child(word_label)

	# Command name
	var name_label := Label.new()
	name_label.text = "(%s)" % cmd_name
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)

	# Status/unlock indicator
	if is_unlocked:
		if cooldown > 0:
			var cd_label := Label.new()
			cd_label.text = "%.0fs" % cooldown
			cd_label.add_theme_font_size_override("font_size", 12)
			cd_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
			header.add_child(cd_label)
		else:
			var ready_label := Label.new()
			ready_label.text = "READY"
			ready_label.add_theme_font_size_override("font_size", 12)
			ready_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
			header.add_child(ready_label)
	else:
		var unlock_label := Label.new()
		unlock_label.text = "Lv %d" % unlock_level
		unlock_label.add_theme_font_size_override("font_size", 12)
		unlock_label.add_theme_color_override("font_color", Color(0.5, 0.4, 0.4))
		header.add_child(unlock_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_vbox.add_child(desc_label)

	# Stats row
	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 15)
	main_vbox.add_child(stats_row)

	# Difficulty chip
	var diff_chip := _create_stat_chip(difficulty.capitalize(), diff_color)
	stats_row.add_child(diff_chip)

	# Cooldown chip
	var cd_chip := _create_stat_chip("%.0fs CD" % base_cooldown, Color(0.6, 0.6, 0.8))
	stats_row.add_child(cd_chip)

	# Category chip
	var cat_chip := _create_stat_chip(effect_category.capitalize(), category_color)
	stats_row.add_child(cat_chip)

	return container


func _get_effect_category(command: Dictionary) -> String:
	var effect: Dictionary = command.get("effect", {})
	var effect_type: String = str(effect.get("type", ""))

	match effect_type:
		"damage_charges", "crit_charges", "cleave_next", "execute", "auto_tower_speed":
			return "damage"
		"damage_reduction", "block_charges", "heal":
			return "defense"
		"freeze_all":
			return "utility"
		"damage_buff", "gold_buff", "combo_boost":
			return "buff"
		_:
			return "utility"


func _create_stat_chip(text: String, color: Color) -> Control:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", color)
	return label


func _build_tips_section() -> void:
	var section := PanelContainer.new()

	var section_style := StyleBoxFlat.new()
	section_style.bg_color = Color(0.12, 0.15, 0.18, 0.8)
	section_style.border_color = Color(0.3, 0.4, 0.5)
	section_style.set_border_width_all(1)
	section_style.set_corner_radius_all(6)
	section_style.set_content_margin_all(10)
	section.add_theme_stylebox_override("panel", section_style)

	_content_vbox.add_child(section)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	section.add_child(vbox)

	var header := Label.new()
	header.text = "COMMAND TIPS"
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
	vbox.add_child(header)

	var tips: Array[String] = [
		"Type commands exactly as shown (case insensitive)",
		"Commands only work during the defense phase",
		"Harder commands have longer words but stronger effects",
		"Plan your cooldowns around difficult waves"
	]

	for tip in tips:
		var tip_label := Label.new()
		tip_label.text = "- " + tip
		tip_label.add_theme_font_size_override("font_size", 10)
		tip_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
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
