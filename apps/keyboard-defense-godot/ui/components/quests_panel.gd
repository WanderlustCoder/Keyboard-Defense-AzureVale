class_name QuestsPanel
extends PanelContainer
## Quests Panel - View and claim daily/weekly quests.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed
signal quest_claimed(quest_id: String, rewards: Dictionary)

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

# Tab colors (domain-specific)
const TAB_COLORS: Dictionary = {
	"daily": Color(0.4, 0.8, 1.0),   # Cyan
	"weekly": Color(0.8, 0.4, 1.0)   # Purple
}


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_MD, 420)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "QUESTS"
	DesignSystem.style_label(title, "h2", ThemeColors.ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.custom_minimum_size = Vector2(DesignSystem.SIZE_BUTTON_SM, DesignSystem.SIZE_BUTTON_SM)
	_style_close_button()
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Tab buttons
	_tab_container = DesignSystem.create_hbox(DesignSystem.SPACE_XS)
	main_vbox.add_child(_tab_container)

	var tab_names: Array[String] = ["Daily", "Weekly"]
	for i in range(tab_names.size()):
		var btn := Button.new()
		btn.text = tab_names[i]
		btn.custom_minimum_size = Vector2(100, DesignSystem.SIZE_BUTTON_SM)
		_style_tab_button(btn)
		btn.pressed.connect(_on_tab_pressed.bind(i))
		_tab_container.add_child(btn)
		_tab_buttons.append(btn)

	# Quest content
	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_content_scroll)

	_content_vbox = DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_vbox)

	_update_tab_buttons()


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func _style_tab_button(btn: Button) -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.BG_BUTTON_HOVER, ThemeColors.BORDER_HIGHLIGHT)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_color_override("font_color", ThemeColors.TEXT)


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
		var color: Color = TAB_COLORS.get("daily" if i == 0 else "weekly", ThemeColors.TEXT)
		if i == _current_tab:
			var style := DesignSystem.create_button_style(ThemeColors.BG_CARD, ThemeColors.BORDER_HIGHLIGHT)
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_color_override("font_color", color)
		else:
			var style := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_color_override("font_color", ThemeColors.TEXT)


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
		color = TAB_COLORS.get("daily", Color.WHITE)
	else:
		quests = _quest_state.get("weekly_quests", [])
		progress = _quest_state.get("weekly_progress", {})
		claimed = _quest_state.get("weekly_claimed", [])
		color = TAB_COLORS.get("weekly", Color.WHITE)

	if quests.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No quests available.\nCheck back later!"
		DesignSystem.style_label(empty_label, "body_small", ThemeColors.TEXT_DIM)
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
		DesignSystem.style_label(label, "caption", ThemeColors.ERROR)
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

	var container_style: StyleBoxFlat
	if is_claimed:
		container_style = DesignSystem.create_elevated_style(ThemeColors.SUCCESS.darkened(0.8))
		container_style.border_color = ThemeColors.SUCCESS.darkened(0.5)
	elif is_completed:
		container_style = DesignSystem.create_elevated_style(ThemeColors.SUCCESS.darkened(0.7))
		container_style.border_color = ThemeColors.SUCCESS
	else:
		container_style = DesignSystem.create_elevated_style(ThemeColors.BG_CARD)
		container_style.border_color = ThemeColors.BORDER
	container_style.set_border_width_all(1)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := DesignSystem.create_vbox(DesignSystem.SPACE_XS)
	container.add_child(vbox)

	# Quest name row
	var name_row := DesignSystem.create_hbox(DesignSystem.SPACE_SM)
	vbox.add_child(name_row)

	var name_label := Label.new()
	name_label.text = name
	if is_claimed:
		DesignSystem.style_label(name_label, "body_small", ThemeColors.TEXT_DIM)
	elif is_completed:
		DesignSystem.style_label(name_label, "body_small", ThemeColors.SUCCESS)
	else:
		DesignSystem.style_label(name_label, "body_small", accent_color)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_label)

	# Status/Claim button
	if is_claimed:
		var claimed_label := Label.new()
		claimed_label.text = "CLAIMED"
		DesignSystem.style_label(claimed_label, "caption", ThemeColors.TEXT_DIM)
		name_row.add_child(claimed_label)
	elif is_completed:
		var claim_btn := Button.new()
		claim_btn.text = "Claim!"
		claim_btn.custom_minimum_size = Vector2(70, 25)
		_style_claim_button(claim_btn)
		claim_btn.pressed.connect(_on_claim_pressed.bind(quest_id))
		name_row.add_child(claim_btn)

	# Description
	var desc_label := Label.new()
	desc_label.text = desc
	DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
	vbox.add_child(desc_label)

	# Progress bar
	var progress_container := DesignSystem.create_hbox(DesignSystem.SPACE_XS)
	vbox.add_child(progress_container)

	var progress_bar := ProgressBar.new()
	progress_bar.value = progress_percent * 100.0
	progress_bar.custom_minimum_size = Vector2(0, 12)
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar.show_percentage = false
	progress_container.add_child(progress_bar)

	var progress_label := Label.new()
	progress_label.text = "%d/%d" % [mini(current_progress, target), target]
	DesignSystem.style_label(progress_label, "caption", ThemeColors.TEXT)
	progress_container.add_child(progress_label)

	# Rewards row
	var rewards_row := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	vbox.add_child(rewards_row)

	var rewards_label := Label.new()
	rewards_label.text = "Rewards:"
	DesignSystem.style_label(rewards_label, "caption", ThemeColors.TEXT_DIM)
	rewards_row.add_child(rewards_label)

	if rewards.has("gold"):
		var gold_label := Label.new()
		gold_label.text = "%d gold" % int(rewards.get("gold", 0))
		DesignSystem.style_label(gold_label, "caption", ThemeColors.RESOURCE_GOLD)
		rewards_row.add_child(gold_label)

	if rewards.has("xp"):
		var xp_label := Label.new()
		xp_label.text = "%d XP" % int(rewards.get("xp", 0))
		DesignSystem.style_label(xp_label, "caption", ThemeColors.INFO)
		rewards_row.add_child(xp_label)

	return container


func _style_claim_button(btn: Button) -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.SUCCESS.darkened(0.3), ThemeColors.SUCCESS)
	var hover := DesignSystem.create_button_style(ThemeColors.SUCCESS.darkened(0.1), ThemeColors.SUCCESS.lightened(0.2))
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_color_override("font_color", ThemeColors.TEXT)


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
