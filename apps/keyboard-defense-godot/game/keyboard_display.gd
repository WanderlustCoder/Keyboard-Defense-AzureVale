extends Control

## On-screen keyboard visualization for typing tutor
## Shows finger zones, highlights next key, flashes on correct/wrong input

# Key layout (QWERTY)
const ROWS := [
	["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "="],
	["q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "[", "]"],
	["a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "'"],
	["z", "x", "c", "v", "b", "n", "m", ",", ".", "/"],
	[" "]  # Spacebar
]

# Pixel offsets for staggered keyboard rows
const ROW_OFFSETS := [0.0, 15.0, 25.0, 40.0, 120.0]

# Finger zone assignments for proper touch typing
const FINGER_ZONES := {
	# Left hand - pinky
	"1": "left_pinky", "`": "left_pinky",
	"q": "left_pinky", "a": "left_pinky", "z": "left_pinky",
	# Left hand - ring
	"2": "left_ring",
	"w": "left_ring", "s": "left_ring", "x": "left_ring",
	# Left hand - middle
	"3": "left_middle",
	"e": "left_middle", "d": "left_middle", "c": "left_middle",
	# Left hand - index (includes reach keys)
	"4": "left_index", "5": "left_index",
	"r": "left_index", "f": "left_index", "v": "left_index",
	"t": "left_index", "g": "left_index", "b": "left_index",
	# Right hand - index (includes reach keys)
	"6": "right_index", "7": "right_index",
	"y": "right_index", "h": "right_index", "n": "right_index",
	"u": "right_index", "j": "right_index", "m": "right_index",
	# Right hand - middle
	"8": "right_middle",
	"i": "right_middle", "k": "right_middle", ",": "right_middle",
	# Right hand - ring
	"9": "right_ring",
	"o": "right_ring", "l": "right_ring", ".": "right_ring",
	# Right hand - pinky
	"0": "right_pinky", "-": "right_pinky", "=": "right_pinky",
	"p": "right_pinky", ";": "right_pinky", "'": "right_pinky",
	"[": "right_pinky", "]": "right_pinky", "/": "right_pinky",
	# Thumbs
	" ": "thumb"
}

# Colors for each finger (symmetric for left/right)
const FINGER_COLORS := {
	"left_pinky": Color(0.7, 0.5, 0.8, 1.0),    # Purple
	"left_ring": Color(0.4, 0.6, 0.9, 1.0),     # Blue
	"left_middle": Color(0.4, 0.8, 0.5, 1.0),   # Green
	"left_index": Color(0.9, 0.6, 0.3, 1.0),    # Orange
	"right_index": Color(0.9, 0.6, 0.3, 1.0),   # Orange
	"right_middle": Color(0.4, 0.8, 0.5, 1.0),  # Green
	"right_ring": Color(0.4, 0.6, 0.9, 1.0),    # Blue
	"right_pinky": Color(0.7, 0.5, 0.8, 1.0),   # Purple
	"thumb": Color(0.5, 0.5, 0.55, 1.0)         # Gray
}

# Display state
var active_charset: String = ""
var next_key: String = ""
var pressed_key: String = ""
var pressed_correct: bool = false
var key_rects: Dictionary = {}
var _flash_alpha: float = 0.0  # For smooth flash fade
var _flash_tween: Tween = null
var _next_key_pulse_time: float = 0.0  # For next-key pulsing animation
var _settings_manager = null

# Visual settings
var key_size := Vector2(36, 36)
var key_gap := 4.0
var spacebar_width := 180.0
var font: Font

const FLASH_DURATION := 0.2  # Smooth fade duration
const NEXT_KEY_PULSE_SPEED := 4.0  # Pulse cycles per second
const NEXT_KEY_PULSE_MIN_WIDTH := 2.5
const NEXT_KEY_PULSE_MAX_WIDTH := 4.0

# Impact ripple settings
const RIPPLE_DURATION := 0.35
const RIPPLE_MAX_RADIUS := 28.0
const RIPPLE_START_WIDTH := 3.0
const RIPPLE_END_WIDTH := 1.0
const RIPPLE_CORRECT_COLOR := Color(0.3, 0.9, 0.5, 0.8)
const RIPPLE_ERROR_COLOR := Color(0.9, 0.3, 0.3, 0.8)

# Active impact ripples
var _impact_ripples: Array = []  # [{center: Vector2, progress: float, correct: bool}]

func _ready() -> void:
	font = ThemeDB.fallback_font
	_settings_manager = get_node_or_null("/root/SettingsManager")

func _process(delta: float) -> void:
	var needs_redraw := false

	# Only animate if there's a next key to highlight
	if next_key.length() > 0:
		# Check reduced motion setting
		var reduced_motion := false
		if _settings_manager != null and _settings_manager.get("reduced_motion") != null:
			reduced_motion = _settings_manager.reduced_motion

		if not reduced_motion:
			_next_key_pulse_time += delta * NEXT_KEY_PULSE_SPEED * TAU
			# Keep time bounded to prevent float overflow
			if _next_key_pulse_time > TAU:
				_next_key_pulse_time -= TAU
			needs_redraw = true

	# Update impact ripples
	if not _impact_ripples.is_empty():
		var to_remove: Array[int] = []
		for i in range(_impact_ripples.size()):
			_impact_ripples[i].progress += delta / RIPPLE_DURATION
			if _impact_ripples[i].progress >= 1.0:
				to_remove.append(i)
		# Remove expired ripples in reverse order
		for i in range(to_remove.size() - 1, -1, -1):
			_impact_ripples.remove_at(to_remove[i])
		needs_redraw = true

	if needs_redraw:
		queue_redraw()

func update_state(charset: String, next: String) -> void:
	active_charset = charset.to_lower()
	next_key = next.to_lower() if next.length() > 0 else ""
	queue_redraw()

func flash_key(key: String, correct: bool) -> void:
	pressed_key = key.to_lower()
	pressed_correct = correct

	# Kill existing flash tween
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()

	# Start at full intensity, fade to zero
	_flash_alpha = 1.0
	queue_redraw()

	# Spawn impact ripple if we have the key rect
	_spawn_impact_ripple(key.to_lower(), correct)

	# Create fade-out tween
	_flash_tween = create_tween()
	_flash_tween.tween_method(_update_flash_alpha, 1.0, 0.0, FLASH_DURATION)
	_flash_tween.set_ease(Tween.EASE_OUT)
	_flash_tween.tween_callback(_clear_flash.bind(key.to_lower()))

func _update_flash_alpha(alpha: float) -> void:
	_flash_alpha = alpha
	queue_redraw()

func _clear_flash(original_key: String) -> void:
	if pressed_key == original_key:
		pressed_key = ""
		_flash_alpha = 0.0
		queue_redraw()

func _spawn_impact_ripple(key: String, correct: bool) -> void:
	# Check reduced motion
	if _settings_manager != null and _settings_manager.get("reduced_motion") != null:
		if _settings_manager.reduced_motion:
			return

	# Get key center position from key_rects (may need to wait for draw)
	var rect: Rect2 = key_rects.get(key, Rect2())
	if rect.size == Vector2.ZERO:
		# Key not found or not drawn yet, skip ripple
		return

	var center := rect.get_center()
	_impact_ripples.append({
		"center": center,
		"progress": 0.0,
		"correct": correct
	})

func _draw() -> void:
	key_rects.clear()
	var y := 0.0

	# Center the keyboard horizontally
	var total_width := 12.0 * (key_size.x + key_gap)
	var start_x := (size.x - total_width) / 2.0

	for row_idx in range(ROWS.size()):
		var row: Array = ROWS[row_idx]
		var x: float = start_x + ROW_OFFSETS[row_idx]

		for key in row:
			var rect: Rect2
			if key == " ":
				# Spacebar is wider and centered
				var spacebar_x := start_x + (total_width - spacebar_width) / 2.0
				rect = Rect2(Vector2(spacebar_x, y), Vector2(spacebar_width, key_size.y))
			else:
				rect = Rect2(Vector2(x, y), key_size)

			key_rects[key] = rect
			_draw_key(key, rect)
			x += key_size.x + key_gap

		y += key_size.y + key_gap

	# Draw impact ripples on top of keys
	_draw_impact_ripples()

func _draw_impact_ripples() -> void:
	for ripple in _impact_ripples:
		var center: Vector2 = ripple.center
		var progress: float = ripple.progress
		var correct: bool = ripple.correct

		# Ease out the expansion
		var eased_progress := 1.0 - pow(1.0 - progress, 3.0)  # Cubic ease out

		# Calculate current radius and line width
		var radius := eased_progress * RIPPLE_MAX_RADIUS
		var line_width: float = lerp(RIPPLE_START_WIDTH, RIPPLE_END_WIDTH, progress)

		# Fade out as ripple expands
		var alpha := 1.0 - progress
		var base_color: Color = RIPPLE_CORRECT_COLOR if correct else RIPPLE_ERROR_COLOR
		var draw_color := Color(base_color.r, base_color.g, base_color.b, base_color.a * alpha)

		# Draw expanding ring
		draw_arc(center, radius, 0, TAU, 32, draw_color, line_width, true)

func _draw_key(key: String, rect: Rect2) -> void:
	var bg_color: Color
	var border_color := Color(0.3, 0.3, 0.35, 1.0)
	var border_width := 1.5
	var text_color := Color(0.9, 0.9, 0.9, 1.0)

	# Determine key state
	var is_active := active_charset.find(key) >= 0
	var is_next := (key == next_key)
	var is_pressed := (key == pressed_key)

	# Background color based on state
	if is_pressed and _flash_alpha > 0.0:
		# Flash green for correct, red for wrong - use alpha for smooth fade
		var flash_color: Color
		if pressed_correct:
			flash_color = Color(0.2, 0.75, 0.3, 1.0)
		else:
			flash_color = Color(0.85, 0.25, 0.25, 1.0)

		# Get base color for blending
		var finger: String = FINGER_ZONES.get(key, "")
		var zone_color: Color = FINGER_COLORS.get(finger, Color(0.25, 0.25, 0.3, 1.0))
		var base_color: Color = zone_color.lerp(Color(0.18, 0.18, 0.22, 1.0), 0.65)

		# Blend flash color with base using alpha
		bg_color = base_color.lerp(flash_color, _flash_alpha)
		border_color = flash_color.lightened(0.3 * _flash_alpha)
		border_width = 1.5 + (1.0 * _flash_alpha)  # 1.5 to 2.5
	elif not is_active:
		# Inactive/dimmed key
		bg_color = Color(0.12, 0.12, 0.15, 1.0)
		text_color = Color(0.35, 0.35, 0.4, 1.0)
		border_color = Color(0.2, 0.2, 0.22, 1.0)
	else:
		# Active key - show finger zone color (subtle)
		var finger: String = FINGER_ZONES.get(key, "")
		var zone_color: Color = FINGER_COLORS.get(finger, Color(0.25, 0.25, 0.3, 1.0))
		# Blend with dark background to make it subtle
		bg_color = zone_color.lerp(Color(0.18, 0.18, 0.22, 1.0), 0.65)

	# Highlight border for next key with pulsing animation
	if is_next:
		border_color = Color(1.0, 0.85, 0.2, 1.0)  # Bright yellow
		# Pulse border width using sine wave
		var pulse_t := (sin(_next_key_pulse_time) + 1.0) * 0.5  # 0.0 to 1.0
		border_width = lerp(NEXT_KEY_PULSE_MIN_WIDTH, NEXT_KEY_PULSE_MAX_WIDTH, pulse_t)
		# Also pulse the border color brightness slightly
		border_color = border_color.lightened(0.15 * pulse_t)
		# Also brighten the background slightly (static)
		bg_color = bg_color.lightened(0.15)

	# Draw rounded rectangle background
	draw_rect(rect, bg_color)

	# Draw border
	draw_rect(rect, border_color, false, border_width)

	# Draw key label
	var label: String
	if key == " ":
		label = "SPACE"
	else:
		label = key.to_upper()

	var font_size: int = 12 if key == " " else 14
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos := rect.position + (rect.size - text_size) / 2.0 + Vector2(0, text_size.y * 0.75)
	draw_string(font, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)

	# Draw home row indicators (F and J keys have bumps)
	if key == "f" or key == "j":
		var bump_y := rect.position.y + rect.size.y - 8
		var bump_x := rect.position.x + rect.size.x / 2.0
		draw_line(Vector2(bump_x - 6, bump_y), Vector2(bump_x + 6, bump_y), text_color.darkened(0.2), 2.0)
