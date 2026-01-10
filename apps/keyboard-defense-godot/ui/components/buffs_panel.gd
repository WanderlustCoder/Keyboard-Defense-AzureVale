class_name BuffsPanel
extends PanelContainer
## Buffs Panel - Shows active buffs and their remaining duration

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")
const SimLoginRewards = preload("res://sim/login_rewards.gd")

var _profile: Dictionary = {}

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null
var _active_count_label: Label = null

# Buff type colors
const BUFF_COLORS: Dictionary = {
	"xp_boost": Color(0.4, 0.8, 1.0),
	"power_boost": Color(0.9, 0.4, 0.4),
	"damage_boost": Color(0.9, 0.5, 0.3),
	"gold_boost": Color(1.0, 0.84, 0.0),
	"accuracy_boost": Color(0.4, 0.9, 0.4),
	"combo_boost": Color(0.9, 0.4, 0.9),
	"defense_boost": Color(0.5, 0.7, 0.9),
	"speed_boost": Color(0.9, 0.9, 0.4)
}

# Buff icons (text-based for now)
const BUFF_ICONS: Dictionary = {
	"xp_boost": "+XP",
	"power_boost": "+PWR",
	"damage_boost": "+DMG",
	"gold_boost": "+GOLD",
	"accuracy_boost": "+ACC",
	"combo_boost": "+CMB",
	"defense_boost": "+DEF",
	"speed_boost": "+SPD"
}

func _ready() -> void:
	_build_ui()
	hide()

func _build_ui() -> void:
	custom_minimum_size = Vector2(440, 380)

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
	title.text = "ACTIVE BUFFS"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	header.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_active_count_label = Label.new()
	_active_count_label.add_theme_font_size_override("font_size", 14)
	_active_count_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	header.add_child(_active_count_label)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(15, 0)
	header.add_child(spacer2)

	_close_btn = Button.new()
	_close_btn.text = "X"
	_close_btn.custom_minimum_size = Vector2(30, 30)
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "Temporary bonuses from rewards and items"
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
	footer.text = "Buffs are consumed after battles"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)

func show_buffs(profile: Dictionary) -> void:
	_profile = profile
	_build_content()
	show()

func refresh() -> void:
	_build_content()

func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()

func _build_content() -> void:
	_clear_content()

	var active_buffs: Array = SimLoginRewards.get_active_buffs(_profile)
	_active_count_label.text = "%d active" % active_buffs.size()

	if active_buffs.is_empty():
		_build_empty_state()
		return

	# Group buffs by type
	var combat_buffs: Array = []
	var reward_buffs: Array = []

	for buff in active_buffs:
		var buff_type: String = str(buff.get("type", ""))
		if buff_type in ["xp_boost", "gold_boost"]:
			reward_buffs.append(buff)
		else:
			combat_buffs.append(buff)

	# Combat buffs section
	if not combat_buffs.is_empty():
		var combat_section := _create_section_panel("COMBAT BUFFS", Color(0.9, 0.5, 0.3))
		_content_vbox.add_child(combat_section)

		var vbox: VBoxContainer = combat_section.get_child(0)
		for buff in combat_buffs:
			var card := _create_buff_card(buff)
			vbox.add_child(card)

	# Reward buffs section
	if not reward_buffs.is_empty():
		var reward_section := _create_section_panel("REWARD BUFFS", Color(1.0, 0.84, 0.0))
		_content_vbox.add_child(reward_section)

		var vbox: VBoxContainer = reward_section.get_child(0)
		for buff in reward_buffs:
			var card := _create_buff_card(buff)
			vbox.add_child(card)

	# Buff sources info
	_build_sources_info()

func _build_empty_state() -> void:
	var empty_panel := PanelContainer.new()

	var empty_style := StyleBoxFlat.new()
	empty_style.bg_color = Color(0.06, 0.06, 0.08, 0.9)
	empty_style.border_color = ThemeColors.BORDER_DISABLED
	empty_style.set_border_width_all(1)
	empty_style.set_corner_radius_all(4)
	empty_style.set_content_margin_all(20)
	empty_panel.add_theme_stylebox_override("panel", empty_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	empty_panel.add_child(vbox)

	var empty_label := Label.new()
	empty_label.text = "No active buffs"
	empty_label.add_theme_font_size_override("font_size", 14)
	empty_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(empty_label)

	var hint_label := Label.new()
	hint_label.text = "Earn buffs from daily login rewards and special items!"
	hint_label.add_theme_font_size_override("font_size", 12)
	hint_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(hint_label)

	_content_vbox.add_child(empty_panel)

	# Still show sources info
	_build_sources_info()

func _build_sources_info() -> void:
	var sources_panel := _create_section_panel("HOW TO GET BUFFS", Color(0.5, 0.5, 0.55))
	_content_vbox.add_child(sources_panel)

	var vbox: VBoxContainer = sources_panel.get_child(0)

	var sources: Array[Dictionary] = [
		{"source": "Daily Login (Day 3)", "buff": "XP Boost (+25%)", "color": BUFF_COLORS["xp_boost"]},
		{"source": "Daily Login (Day 5)", "buff": "Power Surge (+10%)", "color": BUFF_COLORS["power_boost"]},
		{"source": "Weekly Challenge", "buff": "Various buffs", "color": Color(0.9, 0.4, 0.9)},
		{"source": "Shop Items", "buff": "Consumable buffs", "color": Color(1.0, 0.84, 0.0)}
	]

	for source in sources:
		var row := _create_source_row(source)
		vbox.add_child(row)

func _create_buff_card(buff: Dictionary) -> Control:
	var buff_type: String = str(buff.get("type", ""))
	var buff_name: String = str(buff.get("name", buff_type))
	var remaining: int = int(buff.get("remaining", 0))
	var value: float = float(buff.get("value", 0))

	var color: Color = BUFF_COLORS.get(buff_type, Color(0.6, 0.6, 0.7))
	var icon: String = BUFF_ICONS.get(buff_type, "+")

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = color.darkened(0.8)
	container_style.border_color = color
	container_style.set_border_width_all(2)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", container_style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	container.add_child(hbox)

	# Icon
	var icon_panel := _create_icon_panel(icon, color)
	hbox.add_child(icon_panel)

	# Info
	var info_vbox := VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 2)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var name_label := Label.new()
	name_label.text = buff_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", color)
	info_vbox.add_child(name_label)

	var value_label := Label.new()
	value_label.text = "+%.0f%% bonus" % (value * 100)
	value_label.add_theme_font_size_override("font_size", 11)
	value_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	info_vbox.add_child(value_label)

	# Remaining uses
	var remaining_vbox := VBoxContainer.new()
	remaining_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(remaining_vbox)

	var remaining_label := Label.new()
	remaining_label.text = str(remaining)
	remaining_label.add_theme_font_size_override("font_size", 18)
	remaining_label.add_theme_color_override("font_color", color)
	remaining_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	remaining_vbox.add_child(remaining_label)

	var uses_label := Label.new()
	uses_label.text = "battles" if remaining != 1 else "battle"
	uses_label.add_theme_font_size_override("font_size", 10)
	uses_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	uses_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	remaining_vbox.add_child(uses_label)

	return container

func _create_icon_panel(icon_text: String, color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(48, 48)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = color.darkened(0.6)
	panel_style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", panel_style)

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
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", color)
	vbox.add_child(header)

	return container

func _create_source_row(source: Dictionary) -> Control:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)

	var source_label := Label.new()
	source_label.text = str(source.get("source", ""))
	source_label.add_theme_font_size_override("font_size", 11)
	source_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	source_label.custom_minimum_size = Vector2(140, 0)
	hbox.add_child(source_label)

	var buff_label := Label.new()
	buff_label.text = str(source.get("buff", ""))
	buff_label.add_theme_font_size_override("font_size", 11)
	buff_label.add_theme_color_override("font_color", source.get("color", Color.WHITE))
	hbox.add_child(buff_label)

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
