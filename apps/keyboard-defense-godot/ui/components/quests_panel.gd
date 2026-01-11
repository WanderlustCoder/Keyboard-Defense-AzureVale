class_name QuestsPanel
extends PanelContainer
## Quests Panel - View and claim daily/weekly quests

signal closed
signal quest_claimed(quest_id: String, rewards: Dictionary)

const ThemeColors = preload("res://ui/theme_colors.gd")
const SimQuests = preload("res://sim/quests.gd")

enum Tab { DAILY, WEEKLY }

var _quest_state: Dictionary = {}
var _current_tab: Tab = Tab.DAILY

# UI elements
var _close_btn: Button = null
var _tab_container: HBoxContainer = null
var _tab_buttons: Array[Button] = []
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null
var _quest_widgets: Dictionary = {}  # quest_id -> widget container


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(480, 420)

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
	title.text = "QUESTS"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", ThemeColors.ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_close_btn = Button.new()
	_close_btn.text = "X"
	_close_btn.custom_minimum_size = Vector2(30, 30)
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Tab buttons
	_tab_container = HBoxContainer.new()
	_tab_container.add_theme_constant_override("separation", 5)
	main_vbox.add_child(_tab_container)

	var tab_names: Array[String] = ["Daily", "Weekly"]
	for i in range(tab_names.size()):
		var btn := Button.new()
		btn.text = tab_names[i]
		btn.custom_minimum_size = Vector2(100, 30)
		btn.pressed.connect(_on_tab_pressed.bind(i))
		_tab_container.add_child(btn)
		_tab_buttons.append(btn)

	# Quest content
	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_content_scroll)

	_content_vbox = VBoxContainer.new()
	_content_vbox.add_theme_constant_override("separation", 10)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_vbox)

	_update_tab_buttons()


func show_quests(quest_state: Dictionary) -> void:
	_quest_state = quest_state
	_update_tab_buttons()
	_build_quests_list()
	show()


func update_quest_state(quest_state: Dictionary) -> void:
	_quest_state = quest_state
	_build_quests_list()


func _update_tab_buttons() -> void:
	for i in range(_tab_buttons.size()):
		var btn: Button = _tab_buttons[i]
		if i == _current_tab:
			btn.add_theme_color_override("font_color", ThemeColors.ACCENT)
		else:
			btn.remove_theme_color_override("font_color")


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()
	_quest_widgets.clear()


func _build_quests_list() -> void:
	_clear_content()

	var quests: Array = []
	var progress: Dictionary = {}
	var claimed: Array = []
	var color: Color = Color.WHITE

	if _current_tab == Tab.DAILY:
		quests = _quest_state.get("daily_quests", [])
		progress = _quest_state.get("daily_progress", {})
		claimed = _quest_state.get("daily_claimed", [])
		color = Color(0.4, 0.8, 1.0)  # Cyan
	else:
		quests = _quest_state.get("weekly_quests", [])
		progress = _quest_state.get("weekly_progress", {})
		claimed = _quest_state.get("weekly_claimed", [])
		color = Color(0.8, 0.4, 1.0)  # Purple

	if quests.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No quests available.\nCheck back later!"
		empty_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_content_vbox.add_child(empty_label)
		return

	for quest_id in quests:
		var widget := _create_quest_widget(quest_id, progress, claimed, color)
		_content_vbox.add_child(widget)
		_quest_widgets[quest_id] = widget


func _create_quest_widget(quest_id: String, progress: Dictionary, claimed: Array, accent_color: Color) -> Control:
	var quest: Dictionary = SimQuests.get_quest(quest_id)
	if quest.is_empty():
		var label := Label.new()
		label.text = "Unknown quest: %s" % quest_id
		return label

	var name: String = str(quest.get("name", quest_id))
	var desc: String = str(quest.get("description", ""))
	var objective: Dictionary = quest.get("objective", {})
	var rewards: Dictionary = quest.get("rewards", {})
	var is_completed: bool = SimQuests.check_objective(quest_id, progress)
	var is_claimed: bool = quest_id in claimed

	# Calculate progress
	var current_progress: int = SimQuests.get_progress_value(quest_id, progress)
	var target: int = int(objective.get("target", 1))
	var progress_percent: float = clamp(float(current_progress) / float(max(1, target)), 0.0, 1.0)

	# Container
	var container := PanelContainer.new()
	container.custom_minimum_size = Vector2(0, 90)

	var container_style := StyleBoxFlat.new()
	if is_claimed:
		container_style.bg_color = Color(0.1, 0.15, 0.1, 0.8)  # Dim green
		container_style.border_color = Color(0.3, 0.5, 0.3)
	elif is_completed:
		container_style.bg_color = Color(0.15, 0.2, 0.1, 0.9)  # Bright green tint
		container_style.border_color = Color(0.4, 0.8, 0.4)
	else:
		container_style.bg_color = Color(0.06, 0.07, 0.1, 0.9)
		container_style.border_color = ThemeColors.BORDER_DISABLED
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(8)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	container.add_child(vbox)

	# Quest name row
	var name_row := HBoxContainer.new()
	vbox.add_child(name_row)

	var name_label := Label.new()
	name_label.text = name
	name_label.add_theme_font_size_override("font_size", 14)
	if is_claimed:
		name_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	elif is_completed:
		name_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	else:
		name_label.add_theme_color_override("font_color", accent_color)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_label)

	# Status/Claim button
	if is_claimed:
		var claimed_label := Label.new()
		claimed_label.text = "CLAIMED"
		claimed_label.add_theme_font_size_override("font_size", 11)
		claimed_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		name_row.add_child(claimed_label)
	elif is_completed:
		var claim_btn := Button.new()
		claim_btn.text = "Claim!"
		claim_btn.custom_minimum_size = Vector2(70, 25)
		claim_btn.pressed.connect(_on_claim_pressed.bind(quest_id))
		name_row.add_child(claim_btn)

	# Description
	var desc_label := Label.new()
	desc_label.text = desc
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(desc_label)

	# Progress bar
	var progress_container := HBoxContainer.new()
	progress_container.add_theme_constant_override("separation", 5)
	vbox.add_child(progress_container)

	var progress_bar := ProgressBar.new()
	progress_bar.value = progress_percent * 100.0
	progress_bar.custom_minimum_size = Vector2(0, 12)
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar.show_percentage = false
	progress_container.add_child(progress_bar)

	var progress_label := Label.new()
	progress_label.text = "%d/%d" % [mini(current_progress, target), target]
	progress_label.add_theme_font_size_override("font_size", 11)
	progress_container.add_child(progress_label)

	# Rewards row
	var rewards_row := HBoxContainer.new()
	rewards_row.add_theme_constant_override("separation", 10)
	vbox.add_child(rewards_row)

	var rewards_label := Label.new()
	rewards_label.text = "Rewards:"
	rewards_label.add_theme_font_size_override("font_size", 10)
	rewards_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	rewards_row.add_child(rewards_label)

	if rewards.has("gold"):
		var gold_label := Label.new()
		gold_label.text = "%d gold" % int(rewards.get("gold", 0))
		gold_label.add_theme_font_size_override("font_size", 10)
		gold_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		rewards_row.add_child(gold_label)

	if rewards.has("xp"):
		var xp_label := Label.new()
		xp_label.text = "%d XP" % int(rewards.get("xp", 0))
		xp_label.add_theme_font_size_override("font_size", 10)
		xp_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		rewards_row.add_child(xp_label)

	return container


func _on_tab_pressed(tab_index: int) -> void:
	_current_tab = tab_index as Tab
	_update_tab_buttons()
	_build_quests_list()


func _on_claim_pressed(quest_id: String) -> void:
	var quest: Dictionary = SimQuests.get_quest(quest_id)
	var rewards: Dictionary = quest.get("rewards", {})
	quest_claimed.emit(quest_id, rewards)


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
