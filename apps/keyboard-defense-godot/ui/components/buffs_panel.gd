class_name BuffsPanel
extends PanelContainer
## Buffs Panel - Shows active buffs and their remaining duration.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

const SimLoginRewards = preload("res://sim/login_rewards.gd")

var _profile: Dictionary = {}

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null
var _active_count_label: Label = null

# Buff type colors (domain-specific, kept as constant)
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
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_SM + 120, 380)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "ACTIVE BUFFS"
	DesignSystem.style_label(title, "h2", ThemeColors.SUCCESS)
	header.add_child(title)

	header.add_child(DesignSystem.create_spacer())

	_active_count_label = Label.new()
	DesignSystem.style_label(_active_count_label, "body_small", ThemeColors.TEXT_DIM)
	header.add_child(_active_count_label)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(DesignSystem.SPACE_LG, 0)
	header.add_child(spacer2)

	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.custom_minimum_size = Vector2(DesignSystem.SIZE_BUTTON_SM, DesignSystem.SIZE_BUTTON_SM)
	_style_close_button()
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "Temporary bonuses from rewards and items"
	DesignSystem.style_label(subtitle, "caption", ThemeColors.TEXT_DIM)
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
	footer.text = "Buffs are consumed after battles"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


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
		var combat_section := _create_section_panel("COMBAT BUFFS", ThemeColors.ERROR)
		_content_vbox.add_child(combat_section)

		var vbox: VBoxContainer = combat_section.get_child(0)
		for buff in combat_buffs:
			var card := _create_buff_card(buff)
			vbox.add_child(card)

	# Reward buffs section
	if not reward_buffs.is_empty():
		var reward_section := _create_section_panel("REWARD BUFFS", ThemeColors.ACCENT)
		_content_vbox.add_child(reward_section)

		var vbox: VBoxContainer = reward_section.get_child(0)
		for buff in reward_buffs:
			var card := _create_buff_card(buff)
			vbox.add_child(card)

	# Buff sources info
	_build_sources_info()


func _build_empty_state() -> void:
	var empty_panel := PanelContainer.new()
	var empty_style := DesignSystem.create_elevated_style(ThemeColors.BG_CARD_DISABLED)
	empty_style.set_content_margin_all(DesignSystem.SPACE_XL)
	empty_panel.add_theme_stylebox_override("panel", empty_style)

	var vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	empty_panel.add_child(vbox)

	var empty_label := Label.new()
	empty_label.text = "No active buffs"
	DesignSystem.style_label(empty_label, "body", ThemeColors.TEXT_DIM)
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(empty_label)

	var hint_label := Label.new()
	hint_label.text = "Earn buffs from daily login rewards and special items!"
	DesignSystem.style_label(hint_label, "body_small", ThemeColors.TEXT_DIM)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(hint_label)

	_content_vbox.add_child(empty_panel)

	# Still show sources info
	_build_sources_info()


func _build_sources_info() -> void:
	var sources_panel := _create_section_panel("HOW TO GET BUFFS", ThemeColors.TEXT_DIM)
	_content_vbox.add_child(sources_panel)

	var vbox: VBoxContainer = sources_panel.get_child(0)

	var sources: Array[Dictionary] = [
		{"source": "Daily Login (Day 3)", "buff": "XP Boost (+25%)", "color": BUFF_COLORS["xp_boost"]},
		{"source": "Daily Login (Day 5)", "buff": "Power Surge (+10%)", "color": BUFF_COLORS["power_boost"]},
		{"source": "Weekly Challenge", "buff": "Various buffs", "color": ThemeColors.RARITY_EPIC},
		{"source": "Shop Items", "buff": "Consumable buffs", "color": ThemeColors.ACCENT}
	]

	for source in sources:
		var row := _create_source_row(source)
		vbox.add_child(row)


func _create_buff_card(buff: Dictionary) -> Control:
	var buff_type: String = str(buff.get("type", ""))
	var buff_name: String = str(buff.get("name", buff_type))
	var remaining: int = int(buff.get("remaining", 0))
	var value: float = float(buff.get("value", 0))

	var color: Color = BUFF_COLORS.get(buff_type, ThemeColors.TEXT_DIM)
	var icon: String = BUFF_ICONS.get(buff_type, "+")

	var container := PanelContainer.new()
	var container_style := DesignSystem.create_elevated_style(color.darkened(0.8))
	container_style.border_color = color
	container_style.set_border_width_all(2)
	container.add_theme_stylebox_override("panel", container_style)

	var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	container.add_child(hbox)

	# Icon
	var icon_panel := _create_icon_panel(icon, color)
	hbox.add_child(icon_panel)

	# Info
	var info_vbox := DesignSystem.create_vbox(2)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var name_label := Label.new()
	name_label.text = buff_name
	DesignSystem.style_label(name_label, "body", color)
	info_vbox.add_child(name_label)

	var value_label := Label.new()
	value_label.text = "+%.0f%% bonus" % (value * 100)
	DesignSystem.style_label(value_label, "caption", ThemeColors.TEXT_DIM)
	info_vbox.add_child(value_label)

	# Remaining uses
	var remaining_vbox := DesignSystem.create_vbox(2)
	hbox.add_child(remaining_vbox)

	var remaining_label := Label.new()
	remaining_label.text = str(remaining)
	DesignSystem.style_label(remaining_label, "h2", color)
	remaining_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	remaining_vbox.add_child(remaining_label)

	var uses_label := Label.new()
	uses_label.text = "battles" if remaining != 1 else "battle"
	DesignSystem.style_label(uses_label, "caption", ThemeColors.TEXT_DIM)
	uses_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	remaining_vbox.add_child(uses_label)

	return container


func _create_icon_panel(icon_text: String, color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(DesignSystem.SIZE_ICON_XL, DesignSystem.SIZE_ICON_XL)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = color.darkened(0.6)
	panel_style.set_corner_radius_all(DesignSystem.RADIUS_SM)
	panel.add_theme_stylebox_override("panel", panel_style)

	var label := Label.new()
	label.text = icon_text
	DesignSystem.style_label(label, "caption", color)
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
	panel_style.set_corner_radius_all(DesignSystem.RADIUS_MD)
	panel_style.set_content_margin_all(DesignSystem.SPACE_MD)
	container.add_theme_stylebox_override("panel", panel_style)

	var vbox := DesignSystem.create_vbox(DesignSystem.SPACE_SM)
	container.add_child(vbox)

	var header := Label.new()
	header.text = title
	DesignSystem.style_label(header, "body_small", color)
	vbox.add_child(header)

	return container


func _create_source_row(source: Dictionary) -> Control:
	var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_LG)

	var source_label := Label.new()
	source_label.text = str(source.get("source", ""))
	DesignSystem.style_label(source_label, "caption", ThemeColors.TEXT_DIM)
	source_label.custom_minimum_size = Vector2(140, 0)
	hbox.add_child(source_label)

	var buff_label := Label.new()
	buff_label.text = str(source.get("buff", ""))
	DesignSystem.style_label(buff_label, "caption", source.get("color", Color.WHITE))
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
