class_name TypingDisplay
extends PanelContainer
## The main typing display component showing the current word and progress.
## Migrated to use DesignSystem and ThemeColors for consistency.

# Font sizes
const TITLE_FONT_SIZE := 18
const HINT_FONT_SIZE := 14
const WORD_FONT_SIZE := 32
const FEEDBACK_FONT_SIZE := 20

# Animation timing
const FEEDBACK_FADE_RATIO := 0.4
const FEEDBACK_DELAY_RATIO := 0.6
const ERROR_DURATION := 0.6
const SUCCESS_DURATION := 0.75
const SPECIAL_DURATION := 1.1

# Progress bar settings
const PROGRESS_BAR_HEIGHT := 6.0
const PROGRESS_BAR_MARGIN := 8.0
const PROGRESS_COLOR_START := Color(0.3, 0.5, 0.8, 1.0)    # Blue
const PROGRESS_COLOR_HALF := Color(0.4, 0.7, 0.4, 1.0)     # Green
const PROGRESS_COLOR_NEAR := Color(0.9, 0.7, 0.2, 1.0)     # Yellow/gold
const PROGRESS_COLOR_DONE := Color(0.3, 0.9, 0.5, 1.0)     # Bright green
const PROGRESS_BG_COLOR := Color(0.15, 0.15, 0.2, 0.6)
const MILESTONE_GLOW_DURATION := 0.4

# Accuracy ring settings
const ACCURACY_RING_RADIUS := 28.0
const ACCURACY_RING_WIDTH := 4.0
const ACCURACY_RING_BG_COLOR := Color(0.2, 0.2, 0.25, 0.5)
const ACCURACY_RING_EXCELLENT := Color(0.3, 0.9, 0.4, 1.0)  # 95%+ green
const ACCURACY_RING_GOOD := Color(0.5, 0.8, 0.3, 1.0)       # 85-95% lime
const ACCURACY_RING_OK := Color(0.9, 0.8, 0.2, 1.0)         # 70-85% yellow
const ACCURACY_RING_POOR := Color(0.9, 0.5, 0.2, 1.0)       # 50-70% orange
const ACCURACY_RING_BAD := Color(0.9, 0.3, 0.3, 1.0)        # <50% red
const ACCURACY_PULSE_DURATION := 0.3

# Letter burst settings
const BURST_DURATION := 0.8
const BURST_SPEED := 120.0
const BURST_GRAVITY := 150.0
const BURST_FONT_SIZE := 18
const BURST_COLOR_SHORT := Color(0.4, 0.8, 0.9, 1.0)   # Cyan for short words
const BURST_COLOR_MEDIUM := Color(0.9, 0.8, 0.3, 1.0)  # Gold for medium words
const BURST_COLOR_LONG := Color(0.9, 0.5, 0.9, 1.0)    # Purple for long words

@onready var drill_title: Label = $Content/DrillTitle
@onready var drill_hint: Label = $Content/DrillHint
@onready var typed_label: Label = $Content/WordDisplay/TypedLabel
@onready var current_char: Label = $Content/WordDisplay/CurrentChar
@onready var remaining_label: Label = $Content/WordDisplay/RemainingLabel
@onready var feedback_label: Label = $Content/FeedbackLabel

var _feedback_tween: Tween = null
var _progress_bar: Control = null
var _progress_fill: float = 0.0
var _progress_glow: float = 0.0
var _glow_tween: Tween = null
var _last_milestone: int = 0  # 0=none, 1=50%, 2=75%, 3=100%
var _settings_manager = null
var _audio_manager = null

# Accuracy ring state
var _accuracy_ring: Control = null
var _accuracy_correct: int = 0
var _accuracy_total: int = 0
var _accuracy_display: float = 0.0  # Smoothed display value
var _accuracy_pulse: float = 0.0
var _accuracy_pulse_tween: Tween = null

# Letter burst state
var _burst_canvas: Control = null
var _burst_particles: Array = []  # [{letter, pos, vel, lifetime, color}]

func _ready() -> void:
	_apply_styling()
	_setup_progress_bar()
	_setup_accuracy_ring()
	_setup_burst_canvas()
	_settings_manager = get_node_or_null("/root/SettingsManager")
	_audio_manager = get_node_or_null("/root/AudioManager")

func _process(delta: float) -> void:
	# Update letter burst particles
	if not _burst_particles.is_empty():
		var to_remove: Array[int] = []
		for i in range(_burst_particles.size()):
			var p = _burst_particles[i]
			p.lifetime -= delta
			if p.lifetime <= 0:
				to_remove.append(i)
			else:
				# Apply physics
				p.vel.y += BURST_GRAVITY * delta
				p.pos += p.vel * delta
		# Remove expired particles in reverse order
		for i in range(to_remove.size() - 1, -1, -1):
			_burst_particles.remove_at(to_remove[i])
		if _burst_canvas != null:
			_burst_canvas.queue_redraw()

func _exit_tree() -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()

func _apply_styling() -> void:
	if drill_title:
		drill_title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
		drill_title.add_theme_color_override("font_color", ThemeColors.ACCENT)

	if drill_hint:
		drill_hint.add_theme_font_size_override("font_size", HINT_FONT_SIZE)
		drill_hint.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)

	if typed_label:
		typed_label.add_theme_font_size_override("font_size", WORD_FONT_SIZE)
		typed_label.add_theme_color_override("font_color", ThemeColors.TYPED_CORRECT)

	if current_char:
		current_char.add_theme_font_size_override("font_size", WORD_FONT_SIZE)
		current_char.add_theme_color_override("font_color", ThemeColors.ACCENT)

	if remaining_label:
		remaining_label.add_theme_font_size_override("font_size", WORD_FONT_SIZE)
		remaining_label.add_theme_color_override("font_color", ThemeColors.TYPED_PENDING)

	if feedback_label:
		feedback_label.add_theme_font_size_override("font_size", FEEDBACK_FONT_SIZE)
		feedback_label.modulate.a = 0.0

## Set the drill title
func set_drill_title(text: String) -> void:
	if drill_title:
		drill_title.text = text

## Set the drill hint
func set_drill_hint(text: String) -> void:
	if drill_hint:
		drill_hint.text = text
		drill_hint.visible = text != ""

## Update the word display with current typing progress
func update_word(full_word: String, typed_count: int) -> void:
	if typed_count < 0:
		typed_count = 0
	if typed_count > full_word.length():
		typed_count = full_word.length()

	var typed_part := full_word.substr(0, typed_count)
	var current := ""
	var remaining := ""

	if typed_count < full_word.length():
		current = full_word[typed_count]
		remaining = full_word.substr(typed_count + 1)

	if typed_label:
		typed_label.text = typed_part

	if current_char:
		current_char.text = current

	if remaining_label:
		remaining_label.text = remaining

	# Update progress bar
	_update_progress(full_word.length(), typed_count)

## Show feedback message with fade animation
func show_feedback(text: String, color: Color = ThemeColors.TEXT, duration: float = 0.75) -> void:
	if feedback_label == null:
		return

	if _feedback_tween and _feedback_tween.is_running():
		_feedback_tween.kill()

	feedback_label.text = text
	feedback_label.add_theme_color_override("font_color", color)
	feedback_label.modulate.a = 1.0

	_feedback_tween = create_tween()
	_feedback_tween.tween_property(feedback_label, "modulate:a", 0.0, duration * FEEDBACK_FADE_RATIO).set_delay(duration * FEEDBACK_DELAY_RATIO)

## Show error feedback (red, quick)
func show_error(text: String = "Missed!") -> void:
	show_feedback(text, ThemeColors.ERROR, ERROR_DURATION)

## Show success feedback (accent color)
func show_success(text: String = "Strike!") -> void:
	show_feedback(text, ThemeColors.ACCENT, SUCCESS_DURATION)

## Show special feedback (blue, longer)
func show_special(text: String) -> void:
	show_feedback(text, ThemeColors.ACCENT_BLUE, SPECIAL_DURATION)

## Clear the display
func clear() -> void:
	if drill_title:
		drill_title.text = ""
	if drill_hint:
		drill_hint.text = ""
		drill_hint.visible = false
	if typed_label:
		typed_label.text = ""
	if current_char:
		current_char.text = ""
	if remaining_label:
		remaining_label.text = ""
	if feedback_label:
		feedback_label.text = ""
		feedback_label.modulate.a = 0.0
	# Reset progress bar
	_progress_fill = 0.0
	_progress_glow = 0.0
	_last_milestone = 0
	if _progress_bar != null:
		_progress_bar.queue_redraw()
	# Reset accuracy ring
	_accuracy_correct = 0
	_accuracy_total = 0
	_accuracy_display = 0.0
	_accuracy_pulse = 0.0
	if _accuracy_ring != null:
		_accuracy_ring.queue_redraw()

## Setup the progress bar below the word display
func _setup_progress_bar() -> void:
	_progress_bar = Control.new()
	_progress_bar.name = "ProgressBar"
	_progress_bar.custom_minimum_size = Vector2(0, PROGRESS_BAR_HEIGHT + PROGRESS_BAR_MARGIN)
	_progress_bar.draw.connect(_draw_progress_bar)
	_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Add after feedback label or at end
	var content := get_node_or_null("Content")
	if content != null:
		content.add_child(_progress_bar)
	else:
		add_child(_progress_bar)

func _update_progress(word_length: int, typed_count: int) -> void:
	if word_length <= 0:
		_progress_fill = 0.0
		_last_milestone = 0
		if _progress_bar != null:
			_progress_bar.queue_redraw()
		return

	var new_fill := float(typed_count) / float(word_length)
	_progress_fill = new_fill

	# Check milestones
	var new_milestone := 0
	if new_fill >= 1.0:
		new_milestone = 3
	elif new_fill >= 0.75:
		new_milestone = 2
	elif new_fill >= 0.5:
		new_milestone = 1

	# Trigger glow if milestone increased
	if new_milestone > _last_milestone:
		_trigger_milestone_glow()
		_last_milestone = new_milestone

	if _progress_bar != null:
		_progress_bar.queue_redraw()

func _trigger_milestone_glow() -> void:
	# Check reduced motion
	if _settings_manager != null and _settings_manager.get("reduced_motion") != null:
		if _settings_manager.reduced_motion:
			return

	# Kill existing glow
	if _glow_tween != null and _glow_tween.is_valid():
		_glow_tween.kill()

	_progress_glow = 1.0
	_glow_tween = create_tween()
	_glow_tween.tween_method(_set_glow, 1.0, 0.0, MILESTONE_GLOW_DURATION)
	_glow_tween.set_ease(Tween.EASE_OUT)

	# Play subtle sound
	if _audio_manager != null and _audio_manager.has_method("play_ui_confirm"):
		_audio_manager.play_ui_confirm()

func _set_glow(value: float) -> void:
	_progress_glow = value
	if _progress_bar != null:
		_progress_bar.queue_redraw()

func _draw_progress_bar() -> void:
	if _progress_bar == null:
		return

	var bar_width: float = _progress_bar.size.x - PROGRESS_BAR_MARGIN * 2
	var bar_y: float = PROGRESS_BAR_MARGIN * 0.5

	# Draw background
	var bg_rect := Rect2(PROGRESS_BAR_MARGIN, bar_y, bar_width, PROGRESS_BAR_HEIGHT)
	_progress_bar.draw_rect(bg_rect, PROGRESS_BG_COLOR)

	# Calculate fill width
	var fill_width := bar_width * _progress_fill
	if fill_width <= 0:
		return

	# Determine fill color based on progress
	var fill_color: Color
	if _progress_fill >= 1.0:
		fill_color = PROGRESS_COLOR_DONE
	elif _progress_fill >= 0.75:
		fill_color = PROGRESS_COLOR_NEAR
	elif _progress_fill >= 0.5:
		fill_color = PROGRESS_COLOR_HALF
	else:
		fill_color = PROGRESS_COLOR_START

	# Apply glow effect
	if _progress_glow > 0.0:
		fill_color = fill_color.lightened(0.3 * _progress_glow)

	# Draw fill
	var fill_rect := Rect2(PROGRESS_BAR_MARGIN, bar_y, fill_width, PROGRESS_BAR_HEIGHT)
	_progress_bar.draw_rect(fill_rect, fill_color)

	# Draw glow border if active
	if _progress_glow > 0.1:
		var glow_color := fill_color
		glow_color.a = _progress_glow * 0.5
		var glow_expand := 2.0 * _progress_glow
		var glow_rect := Rect2(
			PROGRESS_BAR_MARGIN - glow_expand,
			bar_y - glow_expand,
			fill_width + glow_expand * 2,
			PROGRESS_BAR_HEIGHT + glow_expand * 2
		)
		_progress_bar.draw_rect(glow_rect, glow_color, false, 2.0)

## Setup the accuracy ring indicator
func _setup_accuracy_ring() -> void:
	_accuracy_ring = Control.new()
	_accuracy_ring.name = "AccuracyRing"
	_accuracy_ring.custom_minimum_size = Vector2(ACCURACY_RING_RADIUS * 2 + 12, ACCURACY_RING_RADIUS * 2 + 12)
	_accuracy_ring.draw.connect(_draw_accuracy_ring)
	_accuracy_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Position to the right side of the display
	_accuracy_ring.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_accuracy_ring.position = Vector2(-ACCURACY_RING_RADIUS - 20, -ACCURACY_RING_RADIUS - 6)

	add_child(_accuracy_ring)

## Update accuracy with a new keystroke result
func update_accuracy(correct: bool) -> void:
	_accuracy_total += 1
	if correct:
		_accuracy_correct += 1

	# Calculate new accuracy
	var new_accuracy := float(_accuracy_correct) / float(_accuracy_total) if _accuracy_total > 0 else 1.0

	# Trigger pulse on accuracy change
	var accuracy_delta: float = abs(new_accuracy - _accuracy_display)
	if accuracy_delta > 0.02:  # Only pulse for noticeable changes
		_trigger_accuracy_pulse()

	_accuracy_display = new_accuracy
	if _accuracy_ring != null:
		_accuracy_ring.queue_redraw()

## Reset accuracy tracking for a new session
func reset_accuracy() -> void:
	_accuracy_correct = 0
	_accuracy_total = 0
	_accuracy_display = 0.0
	_accuracy_pulse = 0.0
	if _accuracy_ring != null:
		_accuracy_ring.queue_redraw()

func _trigger_accuracy_pulse() -> void:
	# Check reduced motion
	if _settings_manager != null and _settings_manager.get("reduced_motion") != null:
		if _settings_manager.reduced_motion:
			return

	if _accuracy_pulse_tween != null and _accuracy_pulse_tween.is_valid():
		_accuracy_pulse_tween.kill()

	_accuracy_pulse = 1.0
	_accuracy_pulse_tween = create_tween()
	_accuracy_pulse_tween.tween_method(_set_accuracy_pulse, 1.0, 0.0, ACCURACY_PULSE_DURATION)
	_accuracy_pulse_tween.set_ease(Tween.EASE_OUT)

func _set_accuracy_pulse(value: float) -> void:
	_accuracy_pulse = value
	if _accuracy_ring != null:
		_accuracy_ring.queue_redraw()

func _get_accuracy_color(accuracy: float) -> Color:
	if accuracy >= 0.95:
		return ACCURACY_RING_EXCELLENT
	elif accuracy >= 0.85:
		return ACCURACY_RING_GOOD
	elif accuracy >= 0.70:
		return ACCURACY_RING_OK
	elif accuracy >= 0.50:
		return ACCURACY_RING_POOR
	else:
		return ACCURACY_RING_BAD

func _draw_accuracy_ring() -> void:
	if _accuracy_ring == null:
		return

	var center := _accuracy_ring.size * 0.5
	var radius := ACCURACY_RING_RADIUS
	var width := ACCURACY_RING_WIDTH

	# Apply pulse scale
	if _accuracy_pulse > 0.0:
		radius += 3.0 * _accuracy_pulse
		width += 1.5 * _accuracy_pulse

	# Draw background ring
	_accuracy_ring.draw_arc(center, radius, 0, TAU, 48, ACCURACY_RING_BG_COLOR, width, true)

	# Only draw fill if we have data
	if _accuracy_total == 0:
		return

	# Calculate fill arc (starts from top, goes clockwise)
	var fill_angle := _accuracy_display * TAU
	var start_angle := -PI * 0.5  # Start from top

	# Get color based on accuracy
	var ring_color := _get_accuracy_color(_accuracy_display)

	# Apply pulse glow
	if _accuracy_pulse > 0.0:
		ring_color = ring_color.lightened(0.3 * _accuracy_pulse)

	# Draw filled arc
	_accuracy_ring.draw_arc(center, radius, start_angle, start_angle + fill_angle, 48, ring_color, width, true)

	# Draw percentage text in center
	var percent_text := "%d%%" % int(_accuracy_display * 100)
	var font := ThemeDB.fallback_font
	var font_size := 11
	var text_size := font.get_string_size(percent_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos := center - text_size * 0.5 + Vector2(0, text_size.y * 0.35)
	_accuracy_ring.draw_string(font, text_pos, percent_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ring_color)

## Setup the letter burst canvas
func _setup_burst_canvas() -> void:
	_burst_canvas = Control.new()
	_burst_canvas.name = "BurstCanvas"
	_burst_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_burst_canvas.draw.connect(_draw_burst_particles)
	_burst_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_burst_canvas)

## Trigger a letter burst effect for a completed word
func trigger_letter_burst(word: String) -> void:
	# Check reduced motion
	if _settings_manager != null and _settings_manager.get("reduced_motion") != null:
		if _settings_manager.reduced_motion:
			return

	if word.is_empty():
		return

	# Determine burst color based on word length
	var burst_color: Color
	if word.length() >= 8:
		burst_color = BURST_COLOR_LONG
	elif word.length() >= 5:
		burst_color = BURST_COLOR_MEDIUM
	else:
		burst_color = BURST_COLOR_SHORT

	# Get the center of the word display as spawn point
	var word_display := get_node_or_null("Content/WordDisplay")
	var spawn_center := size * 0.5
	if word_display != null:
		spawn_center = word_display.global_position - global_position + word_display.size * 0.5

	# Spawn letter particles
	var letter_spacing := 20.0
	var total_width := (word.length() - 1) * letter_spacing
	var start_x := spawn_center.x - total_width * 0.5

	for i in range(word.length()):
		var letter := word[i]
		var x_offset := start_x + i * letter_spacing - spawn_center.x

		# Random upward burst with spread
		var angle := randf_range(-PI * 0.6, -PI * 0.4)  # Mostly upward
		angle += x_offset * 0.005  # Slight outward spread based on position
		var speed := BURST_SPEED * randf_range(0.8, 1.2)

		var particle := {
			"letter": letter.to_upper(),
			"pos": Vector2(spawn_center.x + x_offset, spawn_center.y),
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"lifetime": BURST_DURATION * randf_range(0.8, 1.0),
			"color": burst_color.lightened(randf_range(-0.1, 0.1))
		}
		_burst_particles.append(particle)

	if _burst_canvas != null:
		_burst_canvas.queue_redraw()

func _draw_burst_particles() -> void:
	if _burst_canvas == null or _burst_particles.is_empty():
		return

	var font := ThemeDB.fallback_font

	for p in _burst_particles:
		# Calculate alpha based on remaining lifetime
		var alpha: float = clamp(p.lifetime / (BURST_DURATION * 0.5), 0.0, 1.0)
		var draw_color := Color(p.color.r, p.color.g, p.color.b, alpha)

		# Scale shrinks as particle ages
		var scale: float = lerp(0.5, 1.0, alpha)
		var adjusted_font_size := int(BURST_FONT_SIZE * scale)

		_burst_canvas.draw_string(font, p.pos, p.letter, HORIZONTAL_ALIGNMENT_CENTER, -1, adjusted_font_size, draw_color)
