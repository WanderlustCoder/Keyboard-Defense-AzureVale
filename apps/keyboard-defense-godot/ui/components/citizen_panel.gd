class_name CitizenPanel
extends PanelContainer
## Panel displaying all citizens in the kingdom with filtering and management.
## Shows citizen cards, average morale, and assignment controls.

signal closed
signal citizen_selected(citizen_id: int)
signal assignment_requested(citizen_id: int, building_index: int)

const SimCitizens = preload("res://sim/citizens.gd")
const SimWorkers = preload("res://sim/workers.gd")

## Current game state reference
var game_state = null

## Filter mode for citizen display
enum FilterMode { ALL, ASSIGNED, UNASSIGNED, BY_PROFESSION }
var current_filter: FilterMode = FilterMode.ALL
var profession_filter: String = ""

# Internal nodes
var _header: HBoxContainer
var _title_label: Label
var _close_button: Button
var _stats_row: HBoxContainer
var _filter_row: HBoxContainer
var _scroll: ScrollContainer
var _card_container: VBoxContainer
var _cards: Array[CitizenCard] = []

# Summary labels
var _total_label: Label
var _morale_label: Label
var _assigned_label: Label


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# Panel styling
	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_MD, 500)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header with title and close button
	_header = DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(_header)

	_title_label = Label.new()
	_title_label.text = "Citizens"
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	DesignSystem.style_label(_title_label, "h1", ThemeColors.ACCENT)
	_header.add_child(_title_label)

	_close_button = Button.new()
	_close_button.text = "✕"
	_close_button.custom_minimum_size = Vector2(32, 32)
	_style_close_button()
	_close_button.pressed.connect(_on_close_pressed)
	_header.add_child(_close_button)

	# Separator
	main_vbox.add_child(DesignSystem.create_separator())

	# Stats summary row
	_stats_row = DesignSystem.create_hbox(DesignSystem.SPACE_LG)
	main_vbox.add_child(_stats_row)

	_total_label = _create_stat_item("Total", "0")
	_stats_row.add_child(_total_label.get_parent())

	_morale_label = _create_stat_item("Avg Morale", "50%")
	_stats_row.add_child(_morale_label.get_parent())

	_assigned_label = _create_stat_item("Assigned", "0/0")
	_stats_row.add_child(_assigned_label.get_parent())

	# Filter row
	_filter_row = DesignSystem.create_hbox(DesignSystem.SPACE_SM)
	main_vbox.add_child(_filter_row)

	var filter_label := Label.new()
	filter_label.text = "Filter:"
	DesignSystem.style_label(filter_label, "body_small", ThemeColors.TEXT_DIM)
	_filter_row.add_child(filter_label)

	_add_filter_button("All", FilterMode.ALL)
	_add_filter_button("Assigned", FilterMode.ASSIGNED)
	_add_filter_button("Unassigned", FilterMode.UNASSIGNED)

	# Spacer
	_filter_row.add_child(DesignSystem.create_spacer())

	# Scroll container for citizen cards
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_scroll)

	_card_container = DesignSystem.create_vbox(DesignSystem.SPACE_SM)
	_card_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_card_container)


func _create_stat_item(label_text: String, value_text: String) -> Label:
	var vbox := DesignSystem.create_vbox(2)

	var label := Label.new()
	label.text = label_text
	DesignSystem.style_label(label, "caption", ThemeColors.TEXT_DIM)
	vbox.add_child(label)

	var value := Label.new()
	value.text = value_text
	DesignSystem.style_label(value, "h3", ThemeColors.TEXT)
	vbox.add_child(value)

	return value


func _add_filter_button(text: String, mode: FilterMode) -> void:
	var button := Button.new()
	button.text = text
	button.toggle_mode = true
	button.button_pressed = mode == current_filter
	_style_filter_button(button, mode == current_filter)
	button.pressed.connect(func(): _set_filter(mode))
	_filter_row.add_child(button)


func _style_filter_button(button: Button, active: bool) -> void:
	var bg_color := ThemeColors.ACCENT.darkened(0.5) if active else ThemeColors.BG_BUTTON
	var border_color := ThemeColors.ACCENT if active else ThemeColors.BORDER

	var style := DesignSystem.create_button_style(bg_color, border_color)
	button.add_theme_stylebox_override("normal", style)

	var hover := DesignSystem.create_button_style(bg_color.lightened(0.1), border_color)
	button.add_theme_stylebox_override("hover", hover)

	button.add_theme_color_override("font_color", ThemeColors.TEXT if active else ThemeColors.TEXT_DIM)
	button.add_theme_font_size_override("font_size", DesignSystem.FONT_BODY_SMALL)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)

	_close_button.add_theme_stylebox_override("normal", normal)
	_close_button.add_theme_stylebox_override("hover", hover)
	_close_button.add_theme_color_override("font_color", ThemeColors.TEXT)


## Update the panel with game state
func update_from_state(state) -> void:
	game_state = state
	_update_stats()
	_update_citizen_list()


func _update_stats() -> void:
	if game_state == null:
		return

	var citizens: Array = SimCitizens.get_citizens(game_state)
	var total := citizens.size()
	var avg_morale := SimCitizens.get_average_morale(game_state)
	var assigned := total - SimCitizens.get_unassigned_citizens(game_state).size()

	_total_label.text = str(total)
	_morale_label.text = "%d%%" % int(avg_morale)
	_morale_label.add_theme_color_override("font_color", ThemeColors.get_morale_color(avg_morale))
	_assigned_label.text = "%d/%d" % [assigned, total]


func _update_citizen_list() -> void:
	if game_state == null:
		return

	# Clear existing cards
	for card in _cards:
		card.queue_free()
	_cards.clear()

	# Get filtered citizens
	var citizens: Array = _get_filtered_citizens()

	if citizens.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No citizens found"
		DesignSystem.style_label(empty_label, "body", ThemeColors.TEXT_DIM)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_card_container.add_child(empty_label)
		return

	# Create cards for each citizen
	for citizen in citizens:
		var card := CitizenCard.new()
		card.show_assignment_controls = true
		card.citizen_clicked.connect(_on_citizen_clicked)
		card.assign_clicked.connect(_on_assign_clicked)
		card.unassign_clicked.connect(_on_unassign_clicked)
		_card_container.add_child(card)
		card.set_citizen(citizen)
		_cards.append(card)


func _get_filtered_citizens() -> Array:
	if game_state == null:
		return []

	var citizens: Array = SimCitizens.get_citizens(game_state)

	match current_filter:
		FilterMode.ALL:
			return citizens
		FilterMode.ASSIGNED:
			return citizens.filter(func(c): return c.get("assigned_building", -1) >= 0)
		FilterMode.UNASSIGNED:
			return SimCitizens.get_unassigned_citizens(game_state)
		FilterMode.BY_PROFESSION:
			return SimCitizens.get_citizens_by_profession(game_state, profession_filter)
		_:
			return citizens


func _set_filter(mode: FilterMode) -> void:
	current_filter = mode

	# Update button states
	var buttons := _filter_row.get_children().filter(func(c): return c is Button)
	for i in range(buttons.size()):
		var button: Button = buttons[i]
		button.button_pressed = i == mode
		_style_filter_button(button, i == mode)

	_update_citizen_list()


func _on_close_pressed() -> void:
	closed.emit()
	hide()


func _on_citizen_clicked(citizen_id: int) -> void:
	citizen_selected.emit(citizen_id)


func _on_assign_clicked(citizen_id: int) -> void:
	# For now, emit a generic assignment request
	# The parent should handle showing a building selection UI
	assignment_requested.emit(citizen_id, -1)


func _on_unassign_clicked(citizen_id: int) -> void:
	if game_state == null:
		return

	SimWorkers.unassign_citizen(game_state, citizen_id)
	_update_stats()
	_update_citizen_list()


## Refresh the display
func refresh() -> void:
	_update_stats()
	_update_citizen_list()


## Set filter to show only citizens with a specific profession
func filter_by_profession(profession: String) -> void:
	profession_filter = profession
	_set_filter(FilterMode.BY_PROFESSION)


## Show all citizens
func show_all() -> void:
	_set_filter(FilterMode.ALL)


## Get the currently selected filter mode
func get_filter_mode() -> FilterMode:
	return current_filter


## Create a citizen panel with state
static func create(state = null) -> CitizenPanel:
	var panel := CitizenPanel.new()
	if state:
		panel.ready.connect(func(): panel.update_from_state(state))
	return panel
