class_name TypingDisplay
extends PanelContainer
## The main typing display component showing the current word and progress.
## Migrated to use DesignSystem and ThemeColors for consistency.

# Font sizes — values match DesignSystem (FONT_H3, FONT_BODY_SMALL, FONT_DISPLAY, FONT_H2)
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
const SHINE_WIDTH := 0.15
const SHINE_SPEED := 1.5
const SHINE_COLOR := Color(1.0, 1.0, 1.0, 0.4)

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
var _shine_position: float = -0.3  # -0.3 to 1.3 for full sweep
var _shine_active: bool = false
var _shine_tween: Tween = null
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

# Current character pulse effect
var _char_pulse_scale: float = 1.0
var _char_pulse_direction: float = 1.0
const CHAR_PULSE_MIN := 0.95
const CHAR_PULSE_MAX := 1.1
const CHAR_PULSE_SPEED := 4.0
const CHAR_PULSE_COLOR := Color(1.0, 0.95, 0.7, 1.0)  # Warm highlight

# Word shake on error
var _shake_offset: float = 0.0
var _shake_intensity: float = 0.0
var _shake_decay: float = 0.0
const SHAKE_MAGNITUDE := 8.0
const SHAKE_FREQUENCY := 30.0
const SHAKE_DECAY_RATE := 8.0

# Letter pop animation
var _pop_letters: Array = []  # [{letter, pos, scale, alpha, color}]
const POP_DURATION := 0.35
const POP_SCALE_START := 1.2
const POP_SCALE_END := 1.8
const POP_RISE := 15.0

# Perfect word celebration
var _celebration_active: bool = false
var _celebration_time: float = 0.0
var _celebration_word: String = ""
const CELEBRATION_DURATION := 0.8
const CELEBRATION_COLORS: Array[Color] = [
	Color(1.0, 0.4, 0.4),   # Red
	Color(1.0, 0.7, 0.2),   # Orange
	Color(1.0, 1.0, 0.3),   # Yellow
	Color(0.4, 1.0, 0.4),   # Green
	Color(0.3, 0.7, 1.0),   # Blue
	Color(0.7, 0.4, 1.0),   # Purple
]

# Typing trail effect
var _trail_chars: Array = []  # [{letter, pos, alpha, time}]
const TRAIL_MAX_LENGTH := 5
const TRAIL_FADE_TIME := 0.4
const TRAIL_SPACING := 18.0

# Combo streak visual
var _combo_count: int = 0
var _combo_glow_intensity: float = 0.0
var _combo_fire_time: float = 0.0
const COMBO_GLOW_MAX := 0.8
const COMBO_THRESHOLD_WARM := 3
const COMBO_THRESHOLD_HOT := 7
const COMBO_THRESHOLD_FIRE := 12
const COMBO_COLOR_NONE := Color(1.0, 1.0, 1.0, 0.0)
const COMBO_COLOR_WARM := Color(1.0, 0.9, 0.5, 0.3)
const COMBO_COLOR_HOT := Color(1.0, 0.6, 0.2, 0.5)
const COMBO_COLOR_FIRE := Color(1.0, 0.3, 0.1, 0.7)

func _ready() -> void:
	_apply_styling()
	_setup_progress_bar()
	_setup_accuracy_ring()
	_setup_burst_canvas()
	_settings_manager = get_node_or_null("/root/SettingsManager")
	_audio_manager = get_node_or_null("/root/AudioManager")

func _process(delta: float) -> void:
	# Update current character pulse
	_update_char_pulse(delta)

	# Update word shake
	_update_word_shake(delta)

	# Update letter pop animations
	_update_letter_pops(delta)

	# Update celebration effect
	_update_celebration(delta)

	# Update typing trail
	_update_typing_trail(delta)

	# Update combo glow
	_update_combo_glow(delta)

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


## Update the current character pulse effect
func _update_char_pulse(delta: float) -> void:
	if current_char == null or current_char.text.is_empty():
		return

	# Check reduced motion setting
	if _settings_manager != null and _settings_manager.get("reduced_motion") != null:
		if _settings_manager.reduced_motion:
			current_char.scale = Vector2.ONE
			return

	# Oscillate the scale
	_char_pulse_scale += _char_pulse_direction * CHAR_PULSE_SPEED * delta

	# Bounce at limits
	if _char_pulse_scale >= CHAR_PULSE_MAX:
		_char_pulse_scale = CHAR_PULSE_MAX
		_char_pulse_direction = -1.0
	elif _char_pulse_scale <= CHAR_PULSE_MIN:
		_char_pulse_scale = CHAR_PULSE_MIN
		_char_pulse_direction = 1.0

	# Apply scale to current character
	current_char.pivot_offset = current_char.size * 0.5
	current_char.scale = Vector2(_char_pulse_scale, _char_pulse_scale)

	# Apply subtle color tint based on pulse
	var t := (_char_pulse_scale - CHAR_PULSE_MIN) / (CHAR_PULSE_MAX - CHAR_PULSE_MIN)
	var tinted_color := ThemeColors.ACCENT.lerp(CHAR_PULSE_COLOR, t * 0.3)
	current_char.add_theme_color_override("font_color", tinted_color)


## Update word shake effect
func _update_word_shake(delta: float) -> void:
	if _shake_intensity <= 0.01:
		_shake_intensity = 0.0
		_apply_shake_offset(0.0)
		return

	# Decay the intensity
	_shake_intensity *= exp(-SHAKE_DECAY_RATE * delta)

	# Calculate shake offset using sine wave
	_shake_decay += delta * SHAKE_FREQUENCY
	var offset := sin(_shake_decay) * SHAKE_MAGNITUDE * _shake_intensity
	_apply_shake_offset(offset)


## Apply shake offset to word display labels
func _apply_shake_offset(offset: float) -> void:
	var word_display := get_node_or_null("Content/WordDisplay")
	if word_display != null:
		word_display.position.x = offset


## Trigger word shake on typing error
func trigger_word_shake() -> void:
	# Check reduced motion setting
	if _settings_manager != null and _settings_manager.get("reduced_motion") != null:
		if _settings_manager.reduced_motion:
			return

	_shake_intensity = 1.0
	_shake_decay = 0.0


## Update letter pop animations
func _update_letter_pops(delta: float) -> void:
	if _pop_letters.is_empty():
		return

	var to_remove: Array[int] = []
	for i in range(_pop_letters.size()):
		var p = _pop_letters[i]
		p.lifetime -= delta
		if p.lifetime <= 0:
			to_remove.append(i)
		else:
			# Calculate progress (0 to 1)
			var progress: float = 1.0 - (float(p.lifetime) / POP_DURATION)
			# Ease out for smooth animation
			var eased := 1.0 - pow(1.0 - progress, 2.0)
			# Update scale and alpha
			p.scale = lerp(POP_SCALE_START, POP_SCALE_END, eased)
			p.alpha = 1.0 - eased
			p.pos.y -= POP_RISE * delta

	# Remove expired pops in reverse order
	for i in range(to_remove.size() - 1, -1, -1):
		_pop_letters.remove_at(to_remove[i])

	if _burst_canvas != null:
		_burst_canvas.queue_redraw()


## Trigger a letter pop animation when a character is correctly typed
func trigger_letter_pop(letter: String) -> void:
	# Check reduced motion setting
	if _settings_manager != null and _settings_manager.get("reduced_motion") != null:
		if _settings_manager.reduced_motion:
			return

	if letter.is_empty():
		return

	# Get position from current char (it just moved to typed)
	var spawn_pos := size * 0.5
	if typed_label != null:
		var word_display := get_node_or_null("Content/WordDisplay")
		if word_display != null:
			spawn_pos = word_display.global_position - global_position
			spawn_pos.x += typed_label.size.x - 10  # Near the last typed char
			spawn_pos.y += typed_label.size.y * 0.5

	var pop := {
		"letter": letter.to_upper(),
		"pos": spawn_pos,
		"scale": POP_SCALE_START,
		"alpha": 1.0,
		"lifetime": POP_DURATION,
		"color": ThemeColors.TYPED_CORRECT.lightened(0.2)
	}
	_pop_letters.append(pop)


## Update celebration effect
func _update_celebration(delta: float) -> void:
	if not _celebration_active:
		return

	_celebration_time += delta
	if _celebration_time >= CELEBRATION_DURATION:
		_celebration_active = false
		_celebration_time = 0.0
		_celebration_word = ""
		return

	if _burst_canvas != null:
		_burst_canvas.queue_redraw()


## Trigger perfect word celebration (rainbow shimmer)
func trigger_perfect_celebration(word: String) -> void:
	# Check reduced motion setting
	if _settings_manager != null and _settings_manager.get("reduced_motion") != null:
		if _settings_manager.reduced_motion:
			return

	if word.is_empty():
		return

	_celebration_active = true
	_celebration_time = 0.0
	_celebration_word = word


## Update typing trail effect
func _update_typing_trail(delta: float) -> void:
	if _trail_chars.is_empty():
		return

	var to_remove: Array[int] = []
	for i in range(_trail_chars.size()):
		var t = _trail_chars[i]
		t.time += delta
		t.alpha = 1.0 - (t.time / TRAIL_FADE_TIME)
		if t.alpha <= 0:
			to_remove.append(i)

	# Remove expired trails in reverse order
	for i in range(to_remove.size() - 1, -1, -1):
		_trail_chars.remove_at(to_remove[i])

	if _burst_canvas != null:
		_burst_canvas.queue_redraw()


## Add a character to the typing trail
func add_trail_char(letter: String) -> void:
	# Check reduced motion setting
	if _settings_manager != null and _settings_manager.get("reduced_motion") != null:
		if _settings_manager.reduced_motion:
			return

	if letter.is_empty():
		return

	# Get spawn position (near current char)
	var spawn_pos := size * 0.5
	if current_char != null:
		var word_display := get_node_or_null("Content/WordDisplay")
		if word_display != null:
			spawn_pos = word_display.global_position - global_position
			spawn_pos.x += current_char.position.x
			spawn_pos.y += current_char.size.y * 0.5 + 25  # Below the word

	var trail := {
		"letter": letter.to_upper(),
		"pos": spawn_pos,
		"alpha": 1.0,
		"time": 0.0
	}
	_trail_chars.append(trail)

	# Limit trail length
	while _trail_chars.size() > TRAIL_MAX_LENGTH:
		_trail_chars.pop_front()


## Update combo glow effect
func _update_combo_glow(delta: float) -> void:
	# Calculate target intensity based on combo
	var target_intensity := 0.0
	if _combo_count >= COMBO_THRESHOLD_FIRE:
		target_intensity = COMBO_GLOW_MAX
	elif _combo_count >= COMBO_THRESHOLD_HOT:
		target_intensity = COMBO_GLOW_MAX * 0.7
	elif _combo_count >= COMBO_THRESHOLD_WARM:
		target_intensity = COMBO_GLOW_MAX * 0.4

	# Smooth transition to target
	_combo_glow_intensity = lerp(_combo_glow_intensity, target_intensity, delta * 5.0)

	# Update fire animation time
	if _combo_glow_intensity > 0.01:
		_combo_fire_time += delta

	# Apply glow to panel
	if _combo_glow_intensity > 0.01:
		var glow_color := _get_combo_glow_color()
		# Flicker effect for fire
		if _combo_count >= COMBO_THRESHOLD_FIRE:
			var flicker := 0.9 + 0.1 * sin(_combo_fire_time * 15.0)
			glow_color = glow_color * flicker
		self_modulate = Color(1.0, 1.0, 1.0, 1.0).lerp(glow_color, _combo_glow_intensity * 0.3)
	else:
		self_modulate = Color.WHITE


## Get the current combo glow color
func _get_combo_glow_color() -> Color:
	if _combo_count >= COMBO_THRESHOLD_FIRE:
		return COMBO_COLOR_FIRE
	elif _combo_count >= COMBO_THRESHOLD_HOT:
		return COMBO_COLOR_HOT
	elif _combo_count >= COMBO_THRESHOLD_WARM:
		return COMBO_COLOR_WARM
	return COMBO_COLOR_NONE


## Set the current combo count for visual feedback
func set_combo(count: int) -> void:
	_combo_count = count


## Reset combo visual
func reset_combo() -> void:
	_combo_count = 0
	_combo_glow_intensity = 0.0
	self_modulate = Color.WHITE


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

	# Trigger shine sweep
	_trigger_shine()

	# Play subtle sound
	if _audio_manager != null and _audio_manager.has_method("play_ui_confirm"):
		_audio_manager.play_ui_confirm()

func _set_glow(value: float) -> void:
	_progress_glow = value
	if _progress_bar != null:
		_progress_bar.queue_redraw()


func _trigger_shine() -> void:
	# Check reduced motion
	if _settings_manager != null and _settings_manager.get("reduced_motion") != null:
		if _settings_manager.reduced_motion:
			return

	# Kill existing shine tween
	if _shine_tween != null and _shine_tween.is_valid():
		_shine_tween.kill()

	_shine_active = true
	_shine_position = -0.3

	_shine_tween = create_tween()
	_shine_tween.tween_property(self, "_shine_position", 1.3, SHINE_SPEED)
	_shine_tween.tween_callback(func():
		_shine_active = false
		if _progress_bar != null:
			_progress_bar.queue_redraw()
	)


func _set_shine_position(value: float) -> void:
	_shine_position = value
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

	# Draw shine sweep if active
	if _shine_active and fill_width > 0:
		var shine_x := PROGRESS_BAR_MARGIN + fill_width * _shine_position
		var shine_half_width := fill_width * SHINE_WIDTH * 0.5
		var shine_rect := Rect2(
			shine_x - shine_half_width,
			bar_y,
			shine_half_width * 2,
			PROGRESS_BAR_HEIGHT
		)
		# Clip to fill area
		var fill_area := Rect2(PROGRESS_BAR_MARGIN, bar_y, fill_width, PROGRESS_BAR_HEIGHT)
		shine_rect = shine_rect.intersection(fill_area)
		if shine_rect.size.x > 0:
			_progress_bar.draw_rect(shine_rect, SHINE_COLOR)

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
		var letter: String = word[i]
		var x_offset: float = start_x + i * letter_spacing - spawn_center.x

		# Random upward burst with spread
		var angle: float = randf_range(-PI * 0.6, -PI * 0.4)  # Mostly upward
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
	if _burst_canvas == null:
		return

	var font := ThemeDB.fallback_font

	# Draw burst particles
	for p in _burst_particles:
		# Calculate alpha based on remaining lifetime
		var alpha: float = clamp(p.lifetime / (BURST_DURATION * 0.5), 0.0, 1.0)
		var draw_color := Color(p.color.r, p.color.g, p.color.b, alpha)

		# Scale shrinks as particle ages
		var scale_factor: float = lerp(0.5, 1.0, alpha)
		var adjusted_font_size := int(BURST_FONT_SIZE * scale_factor)

		_burst_canvas.draw_string(font, p.pos, p.letter, HORIZONTAL_ALIGNMENT_CENTER, -1, adjusted_font_size, draw_color)

	# Draw letter pop animations
	for p in _pop_letters:
		var draw_color := Color(p.color.r, p.color.g, p.color.b, p.alpha)
		var pop_font_size := int(WORD_FONT_SIZE * p.scale)
		_burst_canvas.draw_string(font, p.pos, p.letter, HORIZONTAL_ALIGNMENT_CENTER, -1, pop_font_size, draw_color)

	# Draw celebration effect
	if _celebration_active and not _celebration_word.is_empty():
		_draw_celebration(font)

	# Draw typing trail
	for i in range(_trail_chars.size()):
		var t = _trail_chars[i]
		var trail_color := ThemeColors.ACCENT.darkened(0.3)
		trail_color.a = t.alpha * 0.6
		var offset_x := (i - _trail_chars.size() + 1) * TRAIL_SPACING
		var trail_pos := Vector2(t.pos.x + offset_x, t.pos.y)
		var trail_font_size := int(14 * (0.6 + t.alpha * 0.4))  # Shrink as they fade
		_burst_canvas.draw_string(font, trail_pos, t.letter, HORIZONTAL_ALIGNMENT_CENTER, -1, trail_font_size, trail_color)


## Draw the celebration rainbow text effect
func _draw_celebration(font: Font) -> void:
	if _burst_canvas == null:
		return

	var progress := _celebration_time / CELEBRATION_DURATION
	var alpha := 1.0 - progress  # Fade out

	# Get center position
	var word_display := get_node_or_null("Content/WordDisplay")
	var center := _burst_canvas.size * 0.5
	if word_display != null:
		center = word_display.global_position - global_position + word_display.size * 0.5

	# Calculate letter spacing and starting position
	var letter_width := 20.0
	var total_width := _celebration_word.length() * letter_width
	var start_x := center.x - total_width * 0.5

	# Rise effect
	var rise := progress * 30.0

	# Draw each letter with rainbow color
	for i in range(_celebration_word.length()):
		var letter: String = _celebration_word[i].to_upper()

		# Calculate color based on letter index and time (creates shimmer)
		var color_offset: float = (_celebration_time * 8.0 + float(i) * 0.5)
		var color_index: int = int(color_offset) % CELEBRATION_COLORS.size()
		var next_index: int = (color_index + 1) % CELEBRATION_COLORS.size()
		var blend: float = fmod(color_offset, 1.0)

		var letter_color: Color = CELEBRATION_COLORS[color_index].lerp(CELEBRATION_COLORS[next_index], blend)
		letter_color.a = alpha

		# Scale pulse based on time
		var scale_pulse := 1.0 + 0.2 * sin(_celebration_time * 10.0 + float(i) * 0.5)
		var font_size := int(WORD_FONT_SIZE * scale_pulse)

		var letter_pos := Vector2(start_x + i * letter_width, center.y - rise)
		_burst_canvas.draw_string(font, letter_pos, letter, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, letter_color)
