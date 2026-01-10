extends PanelContainer
class_name AchievementPanel
## Panel displaying all achievements and their unlock status

const TypingProfile = preload("res://game/typing_profile.gd")
const AchievementChecker = preload("res://game/achievement_checker.gd")

signal close_requested

var _checker: AchievementChecker
var _profile: Dictionary = {}

@onready var title_label: Label = $Content/Header/Title
@onready var count_label: Label = $Content/Header/Count
@onready var achievement_list: VBoxContainer = $Content/ScrollContainer/AchievementList
@onready var close_button: Button = $Content/Header/CloseButton

func _ready() -> void:
	_checker = AchievementChecker.new()
	if close_button != null:
		close_button.pressed.connect(_on_close_pressed)
	visible = false

func show_achievements(profile: Dictionary) -> void:
	_profile = profile
	_refresh_list()
	visible = true

func hide_achievements() -> void:
	visible = false

func _refresh_list() -> void:
	# Clear existing items
	for child in achievement_list.get_children():
		child.queue_free()

	# Get achievement count
	var count_data := TypingProfile.get_achievement_count(_profile)
	count_label.text = "%d / %d" % [count_data.get("unlocked", 0), count_data.get("total", 0)]

	# Get all achievement info
	var all_info := _checker.get_all_achievement_info()
	var unlocked_list := TypingProfile.get_unlocked_achievements(_profile)

	# Create entries for each achievement
	for achievement_id in TypingProfile.ACHIEVEMENT_IDS:
		var info: Dictionary = all_info.get(achievement_id, {})
		var is_unlocked: bool = unlocked_list.has(achievement_id)
		_add_achievement_entry(achievement_id, info, is_unlocked)

func _add_achievement_entry(achievement_id: String, info: Dictionary, is_unlocked: bool) -> void:
	var entry := HBoxContainer.new()
	entry.add_theme_constant_override("separation", 12)

	# Icon
	var icon_label := Label.new()
	icon_label.custom_minimum_size = Vector2(32, 32)
	icon_label.add_theme_font_size_override("font_size", 24)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var icon: String = str(info.get("icon", "star"))
	var icon_map := {
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

	if is_unlocked:
		icon_label.text = icon_map.get(icon, "🏆")
	else:
		icon_label.text = "🔒"
		icon_label.modulate = Color(0.5, 0.5, 0.5, 0.7)

	entry.add_child(icon_label)

	# Text container
	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Name
	var name_label := Label.new()
	name_label.text = str(info.get("name", achievement_id))
	if not is_unlocked:
		name_label.modulate = Color(0.6, 0.6, 0.6, 1.0)
	text_box.add_child(name_label)

	# Description
	var desc_label := Label.new()
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	desc_label.text = str(info.get("description", ""))
	if not is_unlocked:
		desc_label.modulate = Color(0.5, 0.5, 0.5, 1.0)
	text_box.add_child(desc_label)

	entry.add_child(text_box)

	# Status indicator
	var status_label := Label.new()
	status_label.custom_minimum_size = Vector2(80, 0)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if is_unlocked:
		status_label.text = "✓ Unlocked"
		status_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4, 1.0))
	else:
		status_label.text = "Locked"
		status_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
	status_label.add_theme_font_size_override("font_size", 12)
	entry.add_child(status_label)

	achievement_list.add_child(entry)

	# Add separator
	var separator := HSeparator.new()
	separator.modulate = Color(1, 1, 1, 0.2)
	achievement_list.add_child(separator)

func _on_close_pressed() -> void:
	hide_achievements()
	close_requested.emit()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		accept_event()
