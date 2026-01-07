@tool
class_name StatBar
extends HBoxContainer
## A simple stat display component showing a label and value.
## Use for displaying stats like "Accuracy: 95%" or "WPM: 62".

@export var stat_name: String = "Stat":
	set(value):
		stat_name = value
		_update_display()

@export var stat_value: String = "0":
	set(value):
		stat_value = value
		_update_display()

@export var suffix: String = "":
	set(value):
		suffix = value
		_update_display()

@export var value_color: Color = Color(0.94, 0.94, 0.98, 1):
	set(value):
		value_color = value
		_update_display()

@onready var name_label: Label = $NameLabel
@onready var value_label: Label = $ValueLabel

func _ready() -> void:
	_update_display()

func _update_display() -> void:
	if not is_inside_tree():
		return
	if name_label:
		name_label.text = stat_name + ":"
	if value_label:
		value_label.text = stat_value + suffix
		value_label.add_theme_color_override("font_color", value_color)

## Sets the stat value as an integer
func set_int(val: int) -> void:
	stat_value = str(val)

## Sets the stat value as a float with specified decimal places
func set_float(val: float, decimals: int = 1) -> void:
	stat_value = str(snapped(val, pow(10, -decimals)))

## Sets the stat value as a percentage (0-1 range displayed as 0-100%)
func set_percent(val: float) -> void:
	stat_value = str(int(round(val * 100.0)))
	suffix = "%"
