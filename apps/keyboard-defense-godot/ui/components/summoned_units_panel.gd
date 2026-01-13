class_name SummonedUnitsPanel
extends PanelContainer
## Summoned Units Panel - Shows active summoned units and their status.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Unit type definitions
const UNIT_TYPES: Dictionary = {
	"soldier": {
		"name": "Soldier",
		"description": "Basic melee fighter",
		"color": Color(0.6, 0.6, 0.7)
	},
	"archer": {
		"name": "Archer",
		"description": "Ranged attacker with low HP",
		"color": Color(0.3, 0.8, 0.4)
	},
	"knight": {
		"name": "Knight",
		"description": "Heavy armored tank",
		"color": Color(0.4, 0.5, 0.9)
	},
	"mage": {
		"name": "Mage",
		"description": "Powerful magic damage",
		"color": Color(0.7, 0.4, 0.9)
	},
	"healer": {
		"name": "Healer",
		"description": "Restores castle HP",
		"color": Color(0.3, 0.9, 0.6)
	},
	"golem": {
		"name": "Stone Golem",
		"description": "Extremely durable summoned defender",
		"color": Color(0.5, 0.4, 0.3)
	}
}

# Current state
var _state: Dictionary = {}


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_MD, 400)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "SUMMONED UNITS"
	DesignSystem.style_label(title, "h2", Color(0.4, 0.7, 0.9))
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
	subtitle.text = "Units fighting for your kingdom"
	DesignSystem.style_label(subtitle, "body_small", ThemeColors.TEXT_DIM)
	main_vbox.add_child(subtitle)

	# Content scroll
	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_content_scroll)

	_content_vbox = DesignSystem.create_vbox(DesignSystem.SPACE_SM)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_vbox)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_summons(state) -> void:
	if state is Dictionary:
		_state = state
	else:
		# Handle GameState object
		_state = {
			"summoned_units": state.get("summoned_units") if state.has_method("get") else []
		}
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _build_content() -> void:
	_clear_content()

	var units: Array = []
	if _state.has("summoned_units"):
		units = _state["summoned_units"]
	elif _state.has("active_summons"):
		units = _state["active_summons"]

	if units.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No units currently summoned"
		empty_label.add_theme_font_size_override("font_size", 12)
		empty_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_content_vbox.add_child(empty_label)

		var tip_label := Label.new()
		tip_label.text = "Type 'summon [unit]' to call reinforcements"
		tip_label.add_theme_font_size_override("font_size", 10)
		tip_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_content_vbox.add_child(tip_label)
		return

	# Count units by type
	var unit_counts: Dictionary = {}
	for unit in units:
		var unit_type: String = str(unit.get("type", "soldier"))
		unit_counts[unit_type] = int(unit_counts.get(unit_type, 0)) + 1

	# Display each unit type
	for unit_type in unit_counts.keys():
		var count: int = unit_counts[unit_type]
		var unit_panel := _create_unit_entry(unit_type, count)
		_content_vbox.add_child(unit_panel)

	# Summary
	var summary := Label.new()
	summary.text = "Total: %d units" % units.size()
	summary.add_theme_font_size_override("font_size", 11)
	summary.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_content_vbox.add_child(summary)


func _create_unit_entry(unit_type: String, count: int) -> PanelContainer:
	var container := PanelContainer.new()

	var info: Dictionary = UNIT_TYPES.get(unit_type, {
		"name": unit_type.capitalize(),
		"description": "Unknown unit type",
		"color": Color(0.6, 0.6, 0.6)
	})

	var unit_color: Color = info.get("color", Color.WHITE)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = unit_color.darkened(0.85)
	panel_style.border_color = unit_color.darkened(0.5)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(DesignSystem.RADIUS_SM)
	panel_style.set_content_margin_all(DesignSystem.SPACE_MD)
	container.add_theme_stylebox_override("panel", panel_style)

	var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	container.add_child(hbox)

	# Unit info
	var info_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_XS)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var name_label := Label.new()
	name_label.text = str(info.get("name", unit_type))
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", unit_color)
	info_vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = str(info.get("description", ""))
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	info_vbox.add_child(desc_label)

	# Count
	var count_label := Label.new()
	count_label.text = "x%d" % count
	count_label.add_theme_font_size_override("font_size", 16)
	count_label.add_theme_color_override("font_color", unit_color)
	hbox.add_child(count_label)

	return container


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
