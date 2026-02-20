class_name DamageNumbers
extends Node2D
## Floating damage numbers that appear when enemies are hit.
## Supports accessibility settings (reduced motion, high contrast, large text).

# Animation settings
const FLOAT_DURATION := 0.9
const FLOAT_DISTANCE := 45.0
const INITIAL_VELOCITY := Vector2(0, -80)
const GRAVITY := 60.0
const SPREAD_X := 25.0
const FADE_START := 0.5  # When to start fading (fraction of lifetime)

# Pool settings
const MAX_NUMBERS := 50
const POOL_SIZE := 20

# Visual settings
const FONT_SIZE_NORMAL := 14
const FONT_SIZE_CRIT := 18
const FONT_SIZE_HEAL := 12
const LARGE_TEXT_SCALE := 1.4

# Colors by type
const COLORS := {
	"damage": Color("#ff4c33"),      # Red
	"heal": Color("#4de666"),         # Green
	"gold": Color("#ffd700"),         # Gold
	"xp": Color("#80b3ff"),           # Blue
	"combo": Color("#ff99cc"),        # Pink
	"critical": Color("#ffe64d"),     # Yellow
	"miss": Color("#b3b3b3"),         # Gray
	"blocked": Color("#808099"),      # Dark gray
	"fire": Color("#ff6619"),         # Orange
	"ice": Color("#4db3ff"),          # Cyan
	"poison": Color("#66e64d"),       # Lime
}

# High contrast overrides
const HIGH_CONTRAST_COLOR := Color.WHITE
const HIGH_CONTRAST_SHADOW := Color.BLACK

# Colorblind substitutions
const COLORBLIND_SUBSTITUTIONS := {
	"protanopia": {
		"damage": Color(0.9, 0.5, 0.0),
		"heal": Color(0.0, 0.7, 1.0),
	},
	"deuteranopia": {
		"damage": Color(0.9, 0.4, 0.0),
		"heal": Color(0.9, 0.9, 0.3),
	},
	"tritanopia": {
		"damage": Color(1.0, 0.3, 0.3),
		"heal": Color(0.4, 0.9, 0.4),
	}
}

# Legacy color constants for backwards compatibility
const COLOR_NORMAL := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_CRIT := Color(1.0, 0.85, 0.2, 1.0)
const COLOR_HEAL := Color(0.3, 0.9, 0.4, 1.0)
const COLOR_BLOCKED := Color(0.6, 0.6, 0.7, 0.8)
const COLOR_FIRE := Color(1.0, 0.5, 0.2, 1.0)
const COLOR_ICE := Color(0.4, 0.8, 1.0, 1.0)
const COLOR_POISON := Color(0.6, 0.9, 0.3, 1.0)

# Active damage numbers
var _numbers: Array = []  # [{pos, vel, value, color, lifetime, font_size, is_crit}]
var _settings_manager = null

func _ready() -> void:
	_settings_manager = get_node_or_null("/root/SettingsManager")

func _process(delta: float) -> void:
	if _numbers.is_empty():
		return

	var to_remove: Array[int] = []

	for i in range(_numbers.size()):
		var n = _numbers[i]
		n.lifetime -= delta

		if n.lifetime <= 0:
			to_remove.append(i)
		else:
			# Apply gravity
			n.vel.y += GRAVITY * delta
			n.pos += n.vel * delta

	# Remove expired in reverse order
	for i in range(to_remove.size() - 1, -1, -1):
		_numbers.remove_at(to_remove[i])

	queue_redraw()

func _draw() -> void:
	if _numbers.is_empty():
		return

	var font := ThemeDB.fallback_font

	for n in _numbers:
		# Calculate alpha based on remaining lifetime
		var alpha: float
		if n.lifetime > FLOAT_DURATION * 0.7:
			alpha = 1.0
		else:
			alpha = n.lifetime / (FLOAT_DURATION * 0.7)
		alpha = clamp(alpha, 0.0, 1.0)

		var draw_color := Color(n.color.r, n.color.g, n.color.b, n.color.a * alpha)

		# Scale effect for crits
		var scale_factor := 1.0
		if n.is_crit:
			var age: float = FLOAT_DURATION - n.lifetime
			if age < 0.1:
				scale_factor = lerpf(1.5, 1.0, age / 0.1)

		var adjusted_size := int(n.font_size * scale_factor)

		# Format the value
		var text := _format_value(n)

		# Draw shadow for readability (thicker in high contrast mode)
		var shadow_color := Color(0, 0, 0, alpha * 0.5)
		var shadow_offset := Vector2(1, 1)
		if _is_high_contrast():
			shadow_color = Color(0, 0, 0, alpha * 0.9)
			shadow_offset = Vector2(2, 2)
			# Draw extra shadow for better contrast
			draw_string(font, n.pos + Vector2(-1, 2), text, HORIZONTAL_ALIGNMENT_CENTER, -1, adjusted_size, shadow_color)
			draw_string(font, n.pos + Vector2(2, -1), text, HORIZONTAL_ALIGNMENT_CENTER, -1, adjusted_size, shadow_color)
		draw_string(font, n.pos + shadow_offset, text, HORIZONTAL_ALIGNMENT_CENTER, -1, adjusted_size, shadow_color)

		# Draw main text
		draw_string(font, n.pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, adjusted_size, draw_color)

func _format_value(n: Dictionary) -> String:
	if n.get("is_miss", false):
		return "MISS"
	elif n.get("is_heal", false):
		return "+%d" % n.value
	elif n.value == 0:
		return "BLOCKED"
	else:
		return str(n.value)

## Spawn a normal damage number
func spawn_damage(world_pos: Vector2, damage: int, damage_type: String = "normal") -> void:
	# Check reduced motion
	if _settings_manager != null and _settings_manager.get("reduced_motion") != null:
		if _settings_manager.reduced_motion:
			return

	var color := COLOR_NORMAL
	match damage_type:
		"fire":
			color = COLOR_FIRE
		"ice":
			color = COLOR_ICE
		"poison":
			color = COLOR_POISON

	_spawn_number(world_pos, damage, color, FONT_SIZE_NORMAL, false, false)

## Spawn a critical hit damage number
func spawn_crit(world_pos: Vector2, damage: int) -> void:
	# Check reduced motion
	if _settings_manager != null and _settings_manager.get("reduced_motion") != null:
		if _settings_manager.reduced_motion:
			return

	_spawn_number(world_pos, damage, COLOR_CRIT, FONT_SIZE_CRIT, true, false)

## Spawn a healing number
func spawn_heal(world_pos: Vector2, amount: int) -> void:
	# Check reduced motion
	if _settings_manager != null and _settings_manager.get("reduced_motion") != null:
		if _settings_manager.reduced_motion:
			return

	_spawn_number(world_pos, amount, COLOR_HEAL, FONT_SIZE_HEAL, false, true)

## Spawn a blocked damage indicator
func spawn_blocked(world_pos: Vector2) -> void:
	# Check reduced motion
	if _settings_manager != null and _settings_manager.get("reduced_motion") != null:
		if _settings_manager.reduced_motion:
			return

	_spawn_number(world_pos, 0, COLOR_BLOCKED, FONT_SIZE_NORMAL, false, false)

func _spawn_number(world_pos: Vector2, value: int, color: Color, font_size: int, is_crit: bool, is_heal: bool) -> void:
	# Add random horizontal spread
	var spread := randf_range(-SPREAD_X, SPREAD_X)

	# Randomize velocity slightly
	var vel := INITIAL_VELOCITY
	vel.x = spread * 2.0
	vel.y *= randf_range(0.9, 1.1)

	var number := {
		"pos": world_pos + Vector2(spread, 0),
		"vel": vel,
		"value": value,
		"color": color,
		"lifetime": FLOAT_DURATION,
		"font_size": _get_scaled_font_size(font_size),
		"is_crit": is_crit,
		"is_heal": is_heal,
		"is_miss": false
	}

	_add_number_to_pool(number)

## Clear all active damage numbers
func clear() -> void:
	_numbers.clear()
	queue_redraw()

## Get the current count of active numbers (for debugging/tests)
func get_active_count() -> int:
	return _numbers.size()

## Spawn a gold pickup number
func spawn_gold(world_pos: Vector2, amount: int) -> void:
	if _should_skip_number(false):
		return
	var color := _get_type_color("gold")
	_spawn_number(world_pos, amount, color, FONT_SIZE_NORMAL, false, false)

## Spawn an XP gain number
func spawn_xp(world_pos: Vector2, amount: int) -> void:
	if _should_skip_number(false):
		return
	var color := _get_type_color("xp")
	_spawn_number(world_pos, amount, color, FONT_SIZE_NORMAL, false, false)

## Spawn a combo multiplier number
func spawn_combo(world_pos: Vector2, combo: int) -> void:
	if _should_skip_number(false):
		return
	var color := _get_type_color("combo")
	_spawn_number(world_pos, combo, color, FONT_SIZE_CRIT, true, false)

## Spawn a miss indicator
func spawn_miss(world_pos: Vector2) -> void:
	if _should_skip_number(false):
		return
	var color := _get_type_color("miss")
	var number := {
		"pos": world_pos,
		"vel": Vector2(0, -30),
		"value": -1,  # Special value for "MISS"
		"color": color,
		"lifetime": FLOAT_DURATION * 0.7,
		"font_size": _get_scaled_font_size(FONT_SIZE_NORMAL),
		"is_crit": false,
		"is_heal": false,
		"is_miss": true
	}
	_add_number_to_pool(number)

## Generic spawn with type string
func spawn(world_pos: Vector2, value: int, type: String, is_crit: bool = false) -> void:
	if _should_skip_number(is_crit):
		return
	var color := _get_type_color(type)
	var font_size := FONT_SIZE_CRIT if is_crit else FONT_SIZE_NORMAL
	_spawn_number(world_pos, value, color, font_size, is_crit, type == "heal")

# =============================================================================
# ACCESSIBILITY HELPERS
# =============================================================================

func _should_skip_number(is_critical: bool) -> bool:
	## Check if we should skip spawning based on settings.
	if _settings_manager == null:
		return false
	# In reduced motion, only show critical numbers
	if _settings_manager.get("reduced_motion") and not is_critical:
		return true
	return false

func _get_type_color(type: String) -> Color:
	## Get color for type, adjusted for accessibility settings.
	var base_color: Color = COLORS.get(type, COLOR_NORMAL)

	if _settings_manager == null:
		return base_color

	# High contrast mode - use white with black shadow
	if _settings_manager.get("high_contrast"):
		return HIGH_CONTRAST_COLOR

	# Colorblind mode adjustments
	var colorblind_mode: String = _settings_manager.get("colorblind_mode", "none")
	if colorblind_mode != "none" and COLORBLIND_SUBSTITUTIONS.has(colorblind_mode):
		var substitutions: Dictionary = COLORBLIND_SUBSTITUTIONS[colorblind_mode]
		if substitutions.has(type):
			return substitutions[type]

	return base_color

func _get_scaled_font_size(base_size: int) -> int:
	## Get font size, scaled for large text mode.
	if _settings_manager != null and _settings_manager.get("large_text"):
		return int(base_size * LARGE_TEXT_SCALE)
	return base_size

func _is_high_contrast() -> bool:
	if _settings_manager != null:
		return _settings_manager.get("high_contrast", false)
	return false

func _add_number_to_pool(number: Dictionary) -> void:
	## Add number to pool, removing oldest if at max.
	if _numbers.size() >= MAX_NUMBERS:
		_numbers.pop_front()  # Remove oldest
	_numbers.append(number)
	queue_redraw()
