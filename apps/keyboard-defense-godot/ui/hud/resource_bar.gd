class_name ResourceBar
extends HBoxContainer
## Always-visible resource bar for the HUD.
## Displays gold and resources with icons and animated value changes.

signal resource_clicked(resource_name: String)

## Whether to show the gold display
@export var show_gold: bool = true

## Whether to show standard resources (wood, stone, food)
@export var show_resources: bool = true

## Whether to animate value changes
@export var animate_changes: bool = true

## Compact mode (icons only, values on hover)
@export var compact_mode: bool = false

# Internal state
var _resource_displays: Dictionary = {}
var _last_values: Dictionary = {}
var _tweens: Dictionary = {}


func _ready() -> void:
	_build_display()


func _build_display() -> void:
	add_theme_constant_override("separation", DesignSystem.SPACE_LG)

	if show_gold:
		_add_resource_display("gold", ThemeColors.RESOURCE_GOLD, "G")

	if show_resources:
		_add_resource_display("wood", ThemeColors.RESOURCE_WOOD, "W")
		_add_resource_display("stone", ThemeColors.RESOURCE_STONE, "S")
		_add_resource_display("food", ThemeColors.RESOURCE_FOOD, "F")


func _add_resource_display(resource_name: String, color: Color, icon_char: String) -> void:
	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", DesignSystem.SPACE_XS)
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	container.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	container.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			resource_clicked.emit(resource_name)
	)
	add_child(container)

	# Icon
	var icon := Label.new()
	icon.name = "Icon"
	icon.text = icon_char
	icon.add_theme_font_size_override("font_size", DesignSystem.FONT_BODY)
	icon.add_theme_color_override("font_color", color)
	icon.tooltip_text = resource_name.capitalize()
	container.add_child(icon)

	# Value label
	var value_label := Label.new()
	value_label.name = "Value"
	value_label.text = "0"
	value_label.custom_minimum_size.x = 40  # Prevent layout jumping
	value_label.add_theme_font_size_override("font_size", DesignSystem.FONT_BODY)
	value_label.add_theme_color_override("font_color", ThemeColors.TEXT)
	if compact_mode:
		value_label.visible = false
	container.add_child(value_label)

	# Change indicator (shows +/- when values change)
	var change_label := Label.new()
	change_label.name = "Change"
	change_label.text = ""
	change_label.add_theme_font_size_override("font_size", DesignSystem.FONT_CAPTION)
	change_label.modulate.a = 0.0
	container.add_child(change_label)

	_resource_displays[resource_name] = {
		"container": container,
		"icon": icon,
		"value": value_label,
		"change": change_label,
		"color": color
	}
	_last_values[resource_name] = 0


## Update all resource values from game state
func update_from_state(state: RefCounted) -> void:
	if show_gold:
		set_value("gold", state.gold)

	if show_resources:
		set_value("wood", int(state.resources.get("wood", 0)))
		set_value("stone", int(state.resources.get("stone", 0)))
		set_value("food", int(state.resources.get("food", 0)))


## Set a single resource value with optional animation
func set_value(resource_name: String, value: int) -> void:
	if not _resource_displays.has(resource_name):
		return

	var display: Dictionary = _resource_displays[resource_name]
	var old_value: int = _last_values.get(resource_name, 0)

	# Update the display
	display.value.text = _format_value(value)
	_last_values[resource_name] = value

	# Animate change if enabled and value changed
	if animate_changes and value != old_value:
		_animate_change(resource_name, old_value, value)


## Format large numbers with K/M suffixes
func _format_value(value: int) -> String:
	if value >= 1000000:
		return "%.1fM" % (float(value) / 1000000.0)
	elif value >= 10000:
		return "%.1fK" % (float(value) / 1000.0)
	return str(value)


## Animate value change with flash and floating indicator
func _animate_change(resource_name: String, old_value: int, new_value: int) -> void:
	var display: Dictionary = _resource_displays[resource_name]
	var change: int = new_value - old_value
	var is_positive: bool = change > 0

	# Cancel existing tween
	if _tweens.has(resource_name) and _tweens[resource_name]:
		_tweens[resource_name].kill()

	# Flash the value label
	var value_label: Label = display.value
	var flash_color: Color = ThemeColors.SUCCESS if is_positive else ThemeColors.ERROR
	value_label.add_theme_color_override("font_color", flash_color)

	var tween := create_tween()
	_tweens[resource_name] = tween

	tween.tween_property(value_label, "theme_override_colors/font_color", ThemeColors.TEXT, DesignSystem.ANIM_NORMAL)

	# Show change indicator
	var change_label: Label = display.change
	change_label.text = "%s%d" % ["+" if is_positive else "", change]
	change_label.add_theme_color_override("font_color", flash_color)
	change_label.modulate.a = 1.0
	change_label.position.y = 0

	var change_tween := create_tween()
	change_tween.set_parallel(true)
	change_tween.tween_property(change_label, "modulate:a", 0.0, DesignSystem.ANIM_SLOW)
	change_tween.tween_property(change_label, "position:y", -20.0, DesignSystem.ANIM_SLOW)


## Set warning state for a resource (e.g., when low)
func set_warning(resource_name: String, is_warning: bool) -> void:
	if not _resource_displays.has(resource_name):
		return

	var display: Dictionary = _resource_displays[resource_name]
	var icon: Label = display.icon

	if is_warning:
		# Pulse animation for warning
		var tween := create_tween()
		tween.set_loops()
		tween.tween_property(icon, "modulate:a", 0.5, 0.5)
		tween.tween_property(icon, "modulate:a", 1.0, 0.5)
		_tweens[resource_name + "_warning"] = tween
	else:
		# Stop warning animation
		if _tweens.has(resource_name + "_warning"):
			_tweens[resource_name + "_warning"].kill()
			_tweens.erase(resource_name + "_warning")
		display.icon.modulate.a = 1.0


## Check for low resources and set warnings automatically
func check_warnings(state: RefCounted, thresholds: Dictionary = {}) -> void:
	var default_thresholds := {
		"wood": 5,
		"stone": 5,
		"food": 3,
		"gold": 10
	}

	for resource_name in default_thresholds.keys():
		var threshold: int = thresholds.get(resource_name, default_thresholds[resource_name])
		var current: int = _last_values.get(resource_name, 0)
		set_warning(resource_name, current < threshold)


## Create a styled resource bar with panel background
static func create_with_panel() -> PanelContainer:
	var panel := PanelContainer.new()

	var style := StyleBoxFlat.new()
	style.bg_color = ThemeColors.BG_PANEL
	style.border_color = ThemeColors.BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(DesignSystem.RADIUS_SM)
	style.content_margin_left = DesignSystem.SPACE_MD
	style.content_margin_right = DesignSystem.SPACE_MD
	style.content_margin_top = DesignSystem.SPACE_SM
	style.content_margin_bottom = DesignSystem.SPACE_SM
	panel.add_theme_stylebox_override("panel", style)

	var bar := ResourceBar.new()
	panel.add_child(bar)

	return panel
