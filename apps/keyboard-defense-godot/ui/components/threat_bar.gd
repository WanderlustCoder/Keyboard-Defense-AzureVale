class_name ThreatBar
extends VBoxContainer
## Displays threat level and castle health.

const ThemeColors = preload("res://ui/theme_colors.gd")

@onready var threat_label: Label = $ThreatLabel
@onready var threat_progress: ProgressBar = $ThreatProgress
@onready var castle_label: Label = $CastleLabel

var _threat_style: StyleBoxFlat = null
var _threat_bg_style: StyleBoxFlat = null

func _ready() -> void:
	_create_styles()
	_apply_styling()

func _create_styles() -> void:
	_threat_bg_style = StyleBoxFlat.new()
	_threat_bg_style.bg_color = Color(0.1, 0.09, 0.15, 1)
	_threat_bg_style.set_corner_radius_all(3)

	_threat_style = StyleBoxFlat.new()
	_threat_style.bg_color = ThemeColors.THREAT
	_threat_style.set_corner_radius_all(3)

func _apply_styling() -> void:
	if threat_label:
		threat_label.add_theme_font_size_override("font_size", 14)
		threat_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)

	if threat_progress:
		threat_progress.add_theme_stylebox_override("background", _threat_bg_style)
		threat_progress.add_theme_stylebox_override("fill", _threat_style)

	if castle_label:
		castle_label.add_theme_font_size_override("font_size", 16)

## Set threat level (0-100)
func set_threat(value: float) -> void:
	if threat_progress:
		threat_progress.value = clampf(value, 0.0, 100.0)

	# Update bar color based on threat level
	if _threat_style:
		if value >= 80.0:
			_threat_style.bg_color = ThemeColors.ERROR
		elif value >= 50.0:
			_threat_style.bg_color = ThemeColors.WARNING
		else:
			_threat_style.bg_color = ThemeColors.THREAT

## Set castle health
func set_castle_health(current: int, max_health: int = 3) -> void:
	if castle_label:
		castle_label.text = "Castle: %d / %d" % [current, max_health]

		if current <= 1:
			castle_label.add_theme_color_override("font_color", ThemeColors.ERROR)
		elif current <= 2:
			castle_label.add_theme_color_override("font_color", ThemeColors.WARNING)
		else:
			castle_label.add_theme_color_override("font_color", ThemeColors.SUCCESS)

## Set maximum threat value
func set_max_threat(value: float) -> void:
	if threat_progress:
		threat_progress.max_value = value
