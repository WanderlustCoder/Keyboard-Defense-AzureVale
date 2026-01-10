class_name ThreatBar
extends VBoxContainer
## Displays threat level and castle health.

const ThemeColors = preload("res://ui/theme_colors.gd")

const BAR_CORNER_RADIUS := 3
const THREAT_BAR_BG := Color(0.1, 0.09, 0.15, 1)
const THREAT_HIGH_THRESHOLD := 80.0
const THREAT_MEDIUM_THRESHOLD := 50.0

# Health bar visual constants
const HEALTH_HEART_SIZE := 20.0
const HEALTH_HEART_GAP := 4.0
const HEALTH_FULL_COLOR := Color(0.85, 0.25, 0.3, 1.0)  # Red
const HEALTH_EMPTY_COLOR := Color(0.25, 0.2, 0.22, 0.6)  # Dark gray
const HEALTH_LOW_PULSE_SPEED := 4.0

@onready var threat_label: Label = $ThreatLabel
@onready var threat_progress: ProgressBar = $ThreatProgress
@onready var castle_label: Label = $CastleLabel

var _threat_style: StyleBoxFlat = null
var _threat_bg_style: StyleBoxFlat = null
var _health_bar: Control = null
var _health_hearts: Array[ColorRect] = []
var _current_health: int = 3
var _max_health: int = 3
var _health_pulse_time: float = 0.0
var _health_flash_timer: float = 0.0
var _settings_manager = null

func _ready() -> void:
	_create_styles()
	_apply_styling()
	_setup_health_bar()
	_settings_manager = get_node_or_null("/root/SettingsManager")

func _process(delta: float) -> void:
	# Flash timer for damage feedback
	if _health_flash_timer > 0.0:
		_health_flash_timer -= delta
		_update_health_visuals()

	# Pulse animation for low health
	if _current_health <= 1 and _current_health > 0:
		var reduced_motion := false
		if _settings_manager != null and _settings_manager.get("reduced_motion") != null:
			reduced_motion = _settings_manager.reduced_motion

		if not reduced_motion:
			_health_pulse_time += delta * HEALTH_LOW_PULSE_SPEED
			_update_health_visuals()

func _setup_health_bar() -> void:
	# Create container for health hearts
	_health_bar = HBoxContainer.new()
	_health_bar.name = "HealthBar"
	_health_bar.add_theme_constant_override("separation", int(HEALTH_HEART_GAP))
	(_health_bar as HBoxContainer).alignment = BoxContainer.ALIGNMENT_CENTER

	# Insert after castle label
	add_child(_health_bar)
	if castle_label != null:
		move_child(_health_bar, castle_label.get_index() + 1)

	# Create initial hearts
	_rebuild_health_hearts(_max_health)

func _rebuild_health_hearts(max_hp: int) -> void:
	# Clear existing hearts
	for heart in _health_hearts:
		if is_instance_valid(heart):
			heart.queue_free()
	_health_hearts.clear()

	if _health_bar == null:
		return

	# Create new heart containers
	for i in range(max_hp):
		var heart := ColorRect.new()
		heart.custom_minimum_size = Vector2(HEALTH_HEART_SIZE, HEALTH_HEART_SIZE)
		heart.color = HEALTH_FULL_COLOR
		_health_bar.add_child(heart)
		_health_hearts.append(heart)

	_update_health_visuals()

func _update_health_visuals() -> void:
	for i in range(_health_hearts.size()):
		var heart := _health_hearts[i]
		if not is_instance_valid(heart):
			continue

		var is_filled := i < _current_health

		if is_filled:
			# Full heart - red, possibly pulsing if low health
			var color := HEALTH_FULL_COLOR
			if _current_health <= 1 and _health_pulse_time > 0.0:
				var pulse_t := (sin(_health_pulse_time) + 1.0) * 0.5
				color = color.lightened(0.2 * pulse_t)
			# Flash white on recent damage
			if _health_flash_timer > 0.0:
				var flash_t := _health_flash_timer / 0.3
				color = color.lerp(Color.WHITE, flash_t * 0.4)
			heart.color = color
		else:
			# Empty heart - dark gray
			heart.color = HEALTH_EMPTY_COLOR

func _create_styles() -> void:
	_threat_bg_style = StyleBoxFlat.new()
	_threat_bg_style.bg_color = THREAT_BAR_BG
	_threat_bg_style.set_corner_radius_all(BAR_CORNER_RADIUS)

	_threat_style = StyleBoxFlat.new()
	_threat_style.bg_color = ThemeColors.THREAT
	_threat_style.set_corner_radius_all(BAR_CORNER_RADIUS)

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
		if value >= THREAT_HIGH_THRESHOLD:
			_threat_style.bg_color = ThemeColors.ERROR
		elif value >= THREAT_MEDIUM_THRESHOLD:
			_threat_style.bg_color = ThemeColors.WARNING
		else:
			_threat_style.bg_color = ThemeColors.THREAT

## Set castle health
func set_castle_health(current: int, max_health: int = 3) -> void:
	var took_damage := current < _current_health
	var max_changed := max_health != _max_health

	_current_health = current
	_max_health = max_health

	# Rebuild hearts if max changed
	if max_changed:
		_rebuild_health_hearts(max_health)

	# Flash on damage
	if took_damage:
		_health_flash_timer = 0.3

	_update_health_visuals()

	# Update text label
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
