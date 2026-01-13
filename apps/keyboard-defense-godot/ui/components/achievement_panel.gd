class_name AchievementPanel
extends PanelContainer
## Achievement Panel - Displays all achievements and their unlock status.
## Migrated to use DesignSystem and ThemeColors for consistency.

const TypingProfile = preload("res://game/typing_profile.gd")
const AchievementChecker = preload("res://game/achievement_checker.gd")

signal close_requested

var _checker: AchievementChecker
var _profile: Dictionary = {}

# UI elements
var _close_btn: Button = null
var _title_label: Label = null
var _count_label: Label = null
var _content_scroll: ScrollContainer = null
var _achievement_list: VBoxContainer = null

# Icon mapping
const ICON_MAP: Dictionary = {
	"sword": "⚔",
	"flame": "🔥",
	"fire": "🔥",
	"lightning": "⚡",
	"star": "⭐",
	"home": "🏠",
	"book": "📖",
	"calculator": "🔢",
	"crown": "👑",
	"shield": "🛡",
	"heart": "❤",
	"skull": "💀"
}


func _ready() -> void:
	_checker = AchievementChecker.new()
	_build_ui()
	visible = false


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_MD, 500)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	_title_label = Label.new()
	_title_label.text = "ACHIEVEMENTS"
	DesignSystem.style_label(_title_label, "h2", ThemeColors.ACCENT)
	header.add_child(_title_label)

	header.add_child(DesignSystem.create_spacer())

	_count_label = Label.new()
	DesignSystem.style_label(_count_label, "body_small", ThemeColors.SUCCESS)
	header.add_child(_count_label)

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
	subtitle.text = "Track your typing milestones and accomplishments"
	DesignSystem.style_label(subtitle, "caption", ThemeColors.TEXT_DIM)
	main_vbox.add_child(subtitle)

	# Content scroll
	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_content_scroll)

	_achievement_list = DesignSystem.create_vbox(DesignSystem.SPACE_SM)
	_achievement_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_achievement_list)

	# Footer
	var footer := Label.new()
	footer.text = "Complete achievements to unlock rewards!"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_achievements(profile: Dictionary) -> void:
	_profile = profile
	_refresh_list()
	visible = true


func hide_achievements() -> void:
	visible = false


func _refresh_list() -> void:
	# Clear existing items
	for child in _achievement_list.get_children():
		child.queue_free()

	# Get achievement count
	var count_data := TypingProfile.get_achievement_count(_profile)
	_count_label.text = "%d / %d" % [count_data.get("unlocked", 0), count_data.get("total", 0)]

	# Get all achievement info
	var all_info := _checker.get_all_achievement_info()
	var unlocked_list := TypingProfile.get_unlocked_achievements(_profile)

	# Create entries for each achievement
	for achievement_id in TypingProfile.ACHIEVEMENT_IDS:
		var info: Dictionary = all_info.get(achievement_id, {})
		var is_unlocked: bool = unlocked_list.has(achievement_id)
		_add_achievement_entry(achievement_id, info, is_unlocked)


func _add_achievement_entry(achievement_id: String, info: Dictionary, is_unlocked: bool) -> void:
	var container := PanelContainer.new()
	var container_style: StyleBoxFlat

	if is_unlocked:
		container_style = DesignSystem.create_elevated_style(ThemeColors.BG_CARD)
		container_style.border_color = ThemeColors.SUCCESS.darkened(0.3)
	else:
		container_style = DesignSystem.create_elevated_style(ThemeColors.BG_CARD_DISABLED)
		container_style.border_color = ThemeColors.BORDER
	container_style.set_border_width_all(1)
	container.add_theme_stylebox_override("panel", container_style)

	var entry := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	container.add_child(entry)

	# Icon
	var icon_panel := _create_icon_panel(info, is_unlocked)
	entry.add_child(icon_panel)

	# Text container
	var text_box := DesignSystem.create_vbox(2)
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.add_child(text_box)

	# Name
	var name_label := Label.new()
	name_label.text = str(info.get("name", achievement_id))
	if is_unlocked:
		DesignSystem.style_label(name_label, "body_small", ThemeColors.TEXT)
	else:
		DesignSystem.style_label(name_label, "body_small", ThemeColors.TEXT_DIM)
	text_box.add_child(name_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = str(info.get("description", ""))
	if is_unlocked:
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
	else:
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DISABLED)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_box.add_child(desc_label)

	# Status indicator
	var status_vbox := DesignSystem.create_vbox(2)
	status_vbox.custom_minimum_size = Vector2(80, 0)
	entry.add_child(status_vbox)

	var status_label := Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if is_unlocked:
		status_label.text = "✓ Unlocked"
		DesignSystem.style_label(status_label, "caption", ThemeColors.SUCCESS)
	else:
		status_label.text = "Locked"
		DesignSystem.style_label(status_label, "caption", ThemeColors.TEXT_DISABLED)
	status_vbox.add_child(status_label)

	_achievement_list.add_child(container)


func _create_icon_panel(info: Dictionary, is_unlocked: bool) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(DesignSystem.SIZE_ICON_XL, DesignSystem.SIZE_ICON_XL)

	var panel_style := StyleBoxFlat.new()
	if is_unlocked:
		panel_style.bg_color = ThemeColors.SUCCESS.darkened(0.6)
	else:
		panel_style.bg_color = ThemeColors.BG_CARD_DISABLED
	panel_style.set_corner_radius_all(DesignSystem.RADIUS_SM)
	panel.add_theme_stylebox_override("panel", panel_style)

	var label := Label.new()
	var icon_key: String = str(info.get("icon", "star"))

	if is_unlocked:
		label.text = ICON_MAP.get(icon_key, "🏆")
		DesignSystem.style_label(label, "h2", ThemeColors.TEXT)
	else:
		label.text = "🔒"
		DesignSystem.style_label(label, "h2", ThemeColors.TEXT_DISABLED)

	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(label)

	return panel


func _on_close_pressed() -> void:
	hide_achievements()
	close_requested.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
