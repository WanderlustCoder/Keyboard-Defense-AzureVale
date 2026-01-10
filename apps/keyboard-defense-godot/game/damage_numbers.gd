class_name DamageNumbers
extends Node2D
## Floating damage numbers that appear when enemies are hit

# Animation settings
const FLOAT_DURATION := 0.9
const FLOAT_DISTANCE := 45.0
const INITIAL_VELOCITY := Vector2(0, -80)
const GRAVITY := 60.0
const SPREAD_X := 25.0

# Visual settings
const FONT_SIZE_NORMAL := 14
const FONT_SIZE_CRIT := 18
const FONT_SIZE_HEAL := 12

# Colors
const COLOR_NORMAL := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_CRIT := Color(1.0, 0.85, 0.2, 1.0)  # Gold
const COLOR_HEAL := Color(0.3, 0.9, 0.4, 1.0)   # Green
const COLOR_BLOCKED := Color(0.6, 0.6, 0.7, 0.8)  # Gray
const COLOR_FIRE := Color(1.0, 0.5, 0.2, 1.0)   # Orange for fire damage
const COLOR_ICE := Color(0.4, 0.8, 1.0, 1.0)    # Cyan for ice damage
const COLOR_POISON := Color(0.6, 0.9, 0.3, 1.0) # Lime for poison

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
		var text := _format_value(n.value, n.is_heal)

		# Draw shadow for readability
		var shadow_color := Color(0, 0, 0, alpha * 0.5)
		var shadow_offset := Vector2(1, 1)
		draw_string(font, n.pos + shadow_offset, text, HORIZONTAL_ALIGNMENT_CENTER, -1, adjusted_size, shadow_color)

		# Draw main text
		draw_string(font, n.pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, adjusted_size, draw_color)

func _format_value(value: int, is_heal: bool) -> String:
	if is_heal:
		return "+%d" % value
	elif value == 0:
		return "BLOCKED"
	else:
		return str(value)

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
		"font_size": font_size,
		"is_crit": is_crit,
		"is_heal": is_heal
	}

	_numbers.append(number)
	queue_redraw()

## Clear all active damage numbers
func clear() -> void:
	_numbers.clear()
	queue_redraw()

## Get the current count of active numbers (for debugging/tests)
func get_active_count() -> int:
	return _numbers.size()
