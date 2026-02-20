class_name BuildMenu
extends Control
## Build menu panel showing available buildings with sprites, tooltips, and click selection.

signal building_selected(building_id: String)
signal building_hovered(building_id: String)

const BUILDINGS_PATH := "res://data/buildings.json"

# Building button size (smaller for sidebar)
const BUTTON_SIZE := Vector2(52, 52)
const BUTTON_SPACING := 6
const COLUMNS := 3

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var grid: GridContainer = $ScrollContainer/Grid
@onready var tooltip_panel: Panel = $TooltipPanel
@onready var tooltip_name: Label = $TooltipPanel/VBox/NameLabel
@onready var tooltip_desc: Label = $TooltipPanel/VBox/DescLabel
@onready var tooltip_cost: Label = $TooltipPanel/VBox/CostLabel

var buildings_data: Dictionary = {}
var building_buttons: Dictionary = {}  # building_id -> Button
var selected_building: String = ""

# Category colors
var category_colors: Dictionary = {
	"production": Color(0.3, 0.69, 0.31),  # Green
	"economy": Color(1.0, 0.76, 0.03),     # Gold
	"defense": Color(0.96, 0.26, 0.21),    # Red
	"military": Color(0.61, 0.15, 0.69),   # Purple
	"support": Color(0.13, 0.59, 0.95),    # Blue
	"monument": Color(0.61, 0.15, 0.69),   # Purple
}


func _ready() -> void:
	_load_buildings_data()
	_create_building_buttons()
	_hide_tooltip()


func _load_buildings_data() -> void:
	if not FileAccess.file_exists(BUILDINGS_PATH):
		push_error("Buildings data not found: %s" % BUILDINGS_PATH)
		return

	var file := FileAccess.open(BUILDINGS_PATH, FileAccess.READ)
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()

	if error != OK:
		push_error("Failed to parse buildings.json: %s" % json.get_error_message())
		return

	var data: Dictionary = json.data
	buildings_data = data.get("buildings", {})


func _create_building_buttons() -> void:
	# Clear existing buttons
	for child in grid.get_children():
		child.queue_free()
	building_buttons.clear()

	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", BUTTON_SPACING)
	grid.add_theme_constant_override("v_separation", BUTTON_SPACING)

	# Sort buildings by category for display
	var sorted_ids: Array = buildings_data.keys()
	sorted_ids.sort_custom(_sort_by_category)

	for building_id in sorted_ids:
		var building: Dictionary = buildings_data[building_id]
		var button := _create_building_button(building_id, building)
		grid.add_child(button)
		building_buttons[building_id] = button


func _sort_by_category(a: String, b: String) -> bool:
	var cat_order := ["production", "economy", "defense", "military", "support", "monument"]
	var cat_a: String = buildings_data.get(a, {}).get("category", "")
	var cat_b: String = buildings_data.get(b, {}).get("category", "")
	var idx_a: int = cat_order.find(cat_a) if cat_order.has(cat_a) else 999
	var idx_b: int = cat_order.find(cat_b) if cat_order.has(cat_b) else 999
	return idx_a < idx_b


func _create_building_button(building_id: String, building: Dictionary) -> Button:
	var button := Button.new()
	button.custom_minimum_size = BUTTON_SIZE
	button.toggle_mode = true
	button.button_group = _get_or_create_button_group()

	# Style the button
	var category: String = building.get("category", "")
	var cat_color: Color = category_colors.get(category, Color.WHITE)

	# Create a texture rect for the building sprite
	var texture_rect := TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(40, 40)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Try to load sprite
	var sprite_path := _get_building_sprite_path(building_id)
	if FileAccess.file_exists(sprite_path):
		texture_rect.texture = load(sprite_path)
	else:
		# Create placeholder with first letter
		var label := Label.new()
		label.text = building.get("label", building_id).substr(0, 1).to_upper()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", cat_color)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(label)
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Add texture rect centered in button
	button.add_child(texture_rect)
	texture_rect.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	texture_rect.offset_left = -20
	texture_rect.offset_top = -20
	texture_rect.offset_right = 20
	texture_rect.offset_bottom = 20

	# Add colored border indicator
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	style.border_color = cat_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	button.add_theme_stylebox_override("normal", style)

	var style_hover := style.duplicate()
	style_hover.bg_color = Color(0.25, 0.25, 0.3, 0.95)
	style_hover.border_color = cat_color.lightened(0.3)
	button.add_theme_stylebox_override("hover", style_hover)

	var style_pressed := style.duplicate()
	style_pressed.bg_color = Color(0.2, 0.2, 0.25, 1.0)
	style_pressed.border_color = Color.WHITE
	style_pressed.set_border_width_all(3)
	button.add_theme_stylebox_override("pressed", style_pressed)

	# Connect signals
	button.pressed.connect(_on_building_pressed.bind(building_id))
	button.mouse_entered.connect(_on_building_hover.bind(building_id))
	button.mouse_exited.connect(_on_building_unhover)

	return button


func _get_building_sprite_path(building_id: String) -> String:
	# Check for specific building sprite first
	var specific_path := "res://assets/art/src-svg/buildings/building_%s.svg" % building_id
	if FileAccess.file_exists(specific_path):
		return specific_path

	# Check for tower variants
	if building_id == "tower":
		return "res://assets/art/src-svg/buildings/tower_arrow.svg"

	# Check for generic building
	var generic_path := "res://assets/art/src-svg/buildings/%s.svg" % building_id
	if FileAccess.file_exists(generic_path):
		return generic_path

	return ""


var _button_group: ButtonGroup = null

func _get_or_create_button_group() -> ButtonGroup:
	if _button_group == null:
		_button_group = ButtonGroup.new()
	return _button_group


func _on_building_pressed(building_id: String) -> void:
	selected_building = building_id
	building_selected.emit(building_id)


func _on_building_hover(building_id: String) -> void:
	building_hovered.emit(building_id)
	_show_tooltip(building_id)


func _on_building_unhover() -> void:
	_hide_tooltip()


func _show_tooltip(building_id: String) -> void:
	var building: Dictionary = buildings_data.get(building_id, {})
	if building.is_empty():
		return

	tooltip_name.text = building.get("label", building_id)
	tooltip_desc.text = building.get("description", "")

	# Format cost
	var cost: Dictionary = building.get("cost", {})
	var cost_parts: Array[String] = []
	for resource in cost:
		cost_parts.append("%s: %d" % [resource.capitalize(), cost[resource]])
	tooltip_cost.text = "Cost: " + ", ".join(cost_parts) if not cost_parts.is_empty() else "Free"

	# Color the name by category
	var category: String = building.get("category", "")
	var cat_color: Color = category_colors.get(category, Color.WHITE)
	tooltip_name.add_theme_color_override("font_color", cat_color)

	tooltip_panel.visible = true

	# Position tooltip near mouse but keep on screen
	await get_tree().process_frame
	var mouse_pos := get_global_mouse_position()
	var tooltip_size := tooltip_panel.size
	var viewport_size := get_viewport_rect().size

	var pos := mouse_pos + Vector2(15, 15)

	# Keep on screen
	if pos.x + tooltip_size.x > viewport_size.x:
		pos.x = mouse_pos.x - tooltip_size.x - 15
	if pos.y + tooltip_size.y > viewport_size.y:
		pos.y = mouse_pos.y - tooltip_size.y - 15

	tooltip_panel.global_position = pos


func _hide_tooltip() -> void:
	tooltip_panel.visible = false


# Public API

func get_selected_building() -> String:
	return selected_building


func select_building(building_id: String) -> void:
	if building_buttons.has(building_id):
		building_buttons[building_id].button_pressed = true
		selected_building = building_id


func clear_selection() -> void:
	selected_building = ""
	for button in building_buttons.values():
		button.button_pressed = false


func set_building_enabled(building_id: String, enabled: bool) -> void:
	if building_buttons.has(building_id):
		building_buttons[building_id].disabled = not enabled


func set_building_affordable(building_id: String, affordable: bool) -> void:
	if building_buttons.has(building_id):
		var button: Button = building_buttons[building_id]
		button.modulate = Color.WHITE if affordable else Color(0.5, 0.5, 0.5, 0.7)
