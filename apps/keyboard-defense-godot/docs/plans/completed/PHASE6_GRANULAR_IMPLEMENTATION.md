# Phase 6: Word Effects - Granular Implementation Guide

## Overview

This document covers visual effects for the typing experience including character animations, error feedback, and celebration effects. These make typing feel responsive and satisfying.

---

## Task 6.1: Add Current Character Pulse Effect

**Time**: 15 minutes
**File to modify**: `ui/components/typing_display.gd`

### Step 6.1.1: Add pulse state variables

**File**: `ui/components/typing_display.gd`
**Action**: Add after existing animation constants

```gdscript
# Current character pulse effect
var _char_pulse_scale: float = 1.0
var _char_pulse_direction: float = 1.0
const CHAR_PULSE_MIN := 0.95
const CHAR_PULSE_MAX := 1.1
const CHAR_PULSE_SPEED := 4.0
const CHAR_PULSE_COLOR := Color(1.0, 0.95, 0.7, 1.0)  # Slight glow
```

### Step 6.1.2: Update pulse in _process

**File**: `ui/components/typing_display.gd`
**Action**: Add to `_process()` function

```gdscript
func _update_char_pulse(delta: float) -> void:
	# Oscillate pulse scale
	_char_pulse_scale += CHAR_PULSE_SPEED * delta * _char_pulse_direction

	if _char_pulse_scale >= CHAR_PULSE_MAX:
		_char_pulse_scale = CHAR_PULSE_MAX
		_char_pulse_direction = -1.0
	elif _char_pulse_scale <= CHAR_PULSE_MIN:
		_char_pulse_scale = CHAR_PULSE_MIN
		_char_pulse_direction = 1.0

	# Apply to current character label
	if current_char != null:
		current_char.scale = Vector2(_char_pulse_scale, _char_pulse_scale)
		current_char.pivot_offset = current_char.size * 0.5

		# Subtle color pulse
		var pulse_t := (_char_pulse_scale - CHAR_PULSE_MIN) / (CHAR_PULSE_MAX - CHAR_PULSE_MIN)
		var base_color := Color.WHITE
		current_char.modulate = base_color.lerp(CHAR_PULSE_COLOR, pulse_t * 0.3)
```

**Call in `_process()`**:
```gdscript
	_update_char_pulse(delta)
```

### Verification:
1. Current character gently pulses (scale oscillates)
2. Slight color glow at max scale
3. Effect is subtle and not distracting

---

## Task 6.2: Add Word Shake on Error

**Time**: 20 minutes
**File to modify**: `ui/components/typing_display.gd`

### Step 6.2.1: Add shake state variables

**File**: `ui/components/typing_display.gd`
**Action**: Add shake variables

```gdscript
# Word shake on error
var _word_shake_intensity: float = 0.0
var _word_shake_offset: Vector2 = Vector2.ZERO
var _word_original_position: Vector2 = Vector2.ZERO
const WORD_SHAKE_DECAY := 8.0
const WORD_SHAKE_MAX_OFFSET := 6.0
const WORD_SHAKE_FREQUENCY := 30.0
var _word_shake_time: float = 0.0
```

### Step 6.2.2: Add shake trigger method

**File**: `ui/components/typing_display.gd`
**Action**: Add shake method

```gdscript
func trigger_error_shake(intensity: float = 0.5) -> void:
	_word_shake_intensity = clampf(intensity, 0.0, 1.0)
	_word_shake_time = 0.0

	# Store original position if not already stored
	if typed_label != null and _word_original_position == Vector2.ZERO:
		_word_original_position = typed_label.position


func _update_word_shake(delta: float) -> void:
	if _word_shake_intensity <= 0.0:
		return

	_word_shake_time += delta * WORD_SHAKE_FREQUENCY
	_word_shake_intensity = maxf(0.0, _word_shake_intensity - WORD_SHAKE_DECAY * delta)

	# Calculate shake offset using sine waves
	var shake := _word_shake_intensity * _word_shake_intensity  # Quadratic falloff
	_word_shake_offset = Vector2(
		sin(_word_shake_time * 1.1) * WORD_SHAKE_MAX_OFFSET * shake,
		sin(_word_shake_time * 0.9) * WORD_SHAKE_MAX_OFFSET * shake * 0.5
	)

	# Apply to word display container
	if typed_label != null:
		typed_label.position = _word_original_position + _word_shake_offset
	if current_char != null:
		current_char.position = current_char.position + _word_shake_offset
	if remaining_label != null:
		remaining_label.position = remaining_label.position + _word_shake_offset

	# Reset when done
	if _word_shake_intensity <= 0.0:
		_reset_word_positions()


func _reset_word_positions() -> void:
	_word_shake_offset = Vector2.ZERO
	if typed_label != null and _word_original_position != Vector2.ZERO:
		typed_label.position = _word_original_position
```

**Call in `_process()`**:
```gdscript
	_update_word_shake(delta)
```

### Step 6.2.3: Trigger shake on typing error

**Action**: Find error handling code and add:

```gdscript
# When typing error occurs:
trigger_error_shake(0.6)
```

### Verification:
1. Type wrong character
2. Word shakes horizontally
3. Shake decays quickly
4. Positions reset properly

---

## Task 6.3: Add Letter Pop Animation

**Time**: 20 minutes
**File to modify**: `ui/components/typing_display.gd`

### Step 6.3.1: Add letter pop spawn method

**File**: `ui/components/typing_display.gd`
**Action**: Add letter pop effect

```gdscript
# Letter pop state
var _letter_pops: Array = []
const LETTER_POP_DURATION := 0.35
const LETTER_POP_RISE := 20.0
const LETTER_POP_SCALE_START := 1.3
const LETTER_POP_SCALE_END := 0.6


func spawn_letter_pop(letter: String, position: Vector2, color: Color = Color.WHITE) -> void:
	if _burst_canvas == null:
		return

	var label := Label.new()
	label.text = letter
	label.add_theme_font_size_override("font_size", WORD_FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	label.position = position
	label.scale = Vector2(LETTER_POP_SCALE_START, LETTER_POP_SCALE_START)
	label.pivot_offset = Vector2(8, 12)  # Approximate center
	label.modulate.a = 1.0

	_burst_canvas.add_child(label)

	# Animate with tween
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)

	# Rise and shrink
	tween.tween_property(label, "position:y", position.y - LETTER_POP_RISE, LETTER_POP_DURATION)
	tween.tween_property(label, "scale", Vector2(LETTER_POP_SCALE_END, LETTER_POP_SCALE_END), LETTER_POP_DURATION)
	tween.tween_property(label, "modulate:a", 0.0, LETTER_POP_DURATION * 0.7).set_delay(LETTER_POP_DURATION * 0.3)

	# Cleanup
	tween.chain().tween_callback(label.queue_free)
```

### Step 6.3.2: Trigger pop on correct character

**Action**: Find correct character handling and add:

```gdscript
# When character typed correctly:
var char_pos := current_char.global_position if current_char != null else Vector2(400, 300)
spawn_letter_pop(typed_char, char_pos, Color(0.4, 0.9, 0.5))  # Green for correct
```

### Verification:
1. Type correct character
2. Letter pops up from word, rises, shrinks, fades
3. Effect is satisfying but not overwhelming

---

## Task 6.4: Add Perfect Word Celebration

**Time**: 25 minutes
**File to modify**: `ui/components/typing_display.gd`

### Step 6.4.1: Add celebration effect

**File**: `ui/components/typing_display.gd`
**Action**: Add celebration methods

```gdscript
# Perfect word celebration
const CELEBRATION_COLORS := [
	Color(1.0, 0.3, 0.3),  # Red
	Color(1.0, 0.6, 0.2),  # Orange
	Color(1.0, 0.9, 0.2),  # Yellow
	Color(0.4, 0.9, 0.4),  # Green
	Color(0.3, 0.7, 1.0),  # Blue
	Color(0.6, 0.4, 1.0),  # Purple
]

func spawn_perfect_celebration(word: String, center_position: Vector2) -> void:
	if _burst_canvas == null:
		return

	# Spawn each letter flying outward in rainbow colors
	for i in range(word.length()):
		var letter := word[i]
		var color := CELEBRATION_COLORS[i % CELEBRATION_COLORS.size()]

		# Calculate angle for circular spread
		var angle := (float(i) / float(word.length())) * TAU - PI * 0.5
		var offset := Vector2(cos(angle), sin(angle)) * 20.0

		var label := Label.new()
		label.text = letter
		label.add_theme_font_size_override("font_size", WORD_FONT_SIZE + 4)
		label.add_theme_color_override("font_color", color)
		label.position = center_position
		label.scale = Vector2(0.5, 0.5)
		label.pivot_offset = Vector2(8, 12)
		label.modulate.a = 1.0

		_burst_canvas.add_child(label)

		# Animate outward
		var tween := label.create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)

		var target_pos := center_position + offset * 4.0

		# Stagger start
		var delay := i * 0.03

		tween.tween_property(label, "position", target_pos, 0.4).set_delay(delay)
		tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.3).set_delay(delay)
		tween.tween_property(label, "modulate:a", 0.0, 0.3).set_delay(delay + 0.25)

		# Cleanup
		tween.chain().tween_callback(label.queue_free)


func spawn_word_complete_flash(position: Vector2) -> void:
	if _burst_canvas == null:
		return

	# Create white flash
	var flash := ColorRect.new()
	flash.color = Color(1.0, 1.0, 1.0, 0.6)
	flash.size = Vector2(200, 40)
	flash.position = position - flash.size * 0.5

	_burst_canvas.add_child(flash)

	# Animate flash
	var tween := flash.create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.2)
	tween.tween_callback(flash.queue_free)
```

### Step 6.4.2: Trigger celebration on perfect word

**Action**: Find word completion logic and add:

```gdscript
# When word completed with 0 errors:
if errors_in_word == 0:
	var center := word_display.global_position + word_display.size * 0.5
	spawn_perfect_celebration(completed_word, center)
	spawn_word_complete_flash(center)
```

### Verification:
1. Complete word with no mistakes
2. Letters explode outward in rainbow colors
3. White flash appears briefly
4. Effect is celebratory but quick

---

## Task 6.5: Add Typing Trail Effect

**Time**: 20 minutes
**File to modify**: `ui/components/typing_display.gd`

### Step 6.5.1: Add trail particles

**File**: `ui/components/typing_display.gd`
**Action**: Add trail system

```gdscript
# Typing trail effect
var _typing_trails: Array = []
const TRAIL_LIFETIME := 0.4
const TRAIL_SIZE := Vector2(3, 3)
const TRAIL_SPAWN_INTERVAL := 0.05
var _trail_spawn_timer: float = 0.0


func spawn_typing_trail(position: Vector2, color: Color) -> void:
	if _burst_canvas == null:
		return

	var trail := ColorRect.new()
	trail.color = color
	trail.size = TRAIL_SIZE
	trail.position = position - TRAIL_SIZE * 0.5 + Vector2(randf_range(-4, 4), randf_range(-4, 4))
	trail.modulate.a = 0.8

	_burst_canvas.add_child(trail)

	_typing_trails.append({
		"node": trail,
		"lifetime": TRAIL_LIFETIME
	})


func _update_typing_trails(delta: float) -> void:
	for i in range(_typing_trails.size() - 1, -1, -1):
		var trail = _typing_trails[i]
		if not trail is Dictionary:
			_typing_trails.remove_at(i)
			continue

		var node = trail.get("node")
		if node == null or not is_instance_valid(node):
			_typing_trails.remove_at(i)
			continue

		var lifetime: float = trail.get("lifetime", 0.0)
		lifetime -= delta
		trail["lifetime"] = lifetime

		if lifetime <= 0.0:
			node.queue_free()
			_typing_trails.remove_at(i)
			continue

		# Fade and shrink
		var t := lifetime / TRAIL_LIFETIME
		node.modulate.a = t * 0.8
		node.scale = Vector2(t, t)
```

**Add to `_process()`**:
```gdscript
	_update_typing_trails(delta)
```

### Step 6.5.2: Spawn trail on typing

**Action**: When character typed:

```gdscript
# Spawn trail behind cursor as user types
_trail_spawn_timer -= delta
if _trail_spawn_timer <= 0.0 and is_typing:
	var pos := current_char.global_position if current_char != null else Vector2.ZERO
	var trail_color := Color(0.4, 0.8, 1.0, 0.5)  # Cyan trail
	spawn_typing_trail(pos, trail_color)
	_trail_spawn_timer = TRAIL_SPAWN_INTERVAL
```

### Verification:
1. Type rapidly
2. Small cyan particles trail behind cursor
3. Trails fade and shrink
4. Creates sense of speed and momentum

---

## Task 6.6: Add Combo Streak Visual

**Time**: 15 minutes
**File to modify**: `scripts/Battlefield.gd`

### Step 6.6.1: Add streak glow effect

**File**: `scripts/Battlefield.gd`
**Action**: Enhance existing streak glow (if not already present)

```gdscript
# Enhanced streak glow colors based on combo
func _get_streak_glow_color(combo: int) -> Color:
	if combo >= 50:
		# Legendary - pulsing gold/white
		var pulse := sin(Time.get_ticks_msec() / 100.0) * 0.3 + 0.7
		return Color(1.0, 0.9, 0.5, pulse)
	elif combo >= 20:
		# Amazing - gold
		return STREAK_GLOW_COLOR_HIGH
	elif combo >= 10:
		# Great - purple
		return STREAK_GLOW_COLOR_MID
	elif combo >= 3:
		# Nice - cyan
		return STREAK_GLOW_COLOR_LOW
	else:
		return Color(0, 0, 0, 0)  # No glow


func _update_streak_glow() -> void:
	if _streak_glow == null:
		return

	var combo := typing_system.get_combo() if typing_system != null else 0
	var color := _get_streak_glow_color(combo)

	_streak_glow.modulate = color

	# Scale glow with combo (subtle)
	var scale := 1.0 + min(combo, 50) * 0.002
	_streak_glow.scale = Vector2(scale, scale)
```

### Verification:
1. Build combo to 3 - cyan glow appears
2. At 10 combo - purple glow
3. At 20 combo - gold glow
4. At 50+ combo - pulsing legendary glow

---

## Summary Checklist

After completing all Phase 6 tasks, verify:

- [ ] Current character pulses gently (scale + color)
- [ ] Typing error causes word to shake
- [ ] Correct character causes letter to pop up
- [ ] Perfect word triggers rainbow celebration
- [ ] White flash on word completion
- [ ] Typing trail follows cursor
- [ ] Streak glow changes color with combo tier
- [ ] High combo has pulsing legendary glow
- [ ] Effects are satisfying but not overwhelming

---

## Integration Points

### In TypingDisplay when character typed:
```gdscript
func on_character_typed(char: String, is_correct: bool) -> void:
	if is_correct:
		spawn_letter_pop(char, current_char.global_position, Color.GREEN)
		spawn_typing_trail(current_char.global_position, Color(0.4, 0.8, 1.0))
	else:
		trigger_error_shake(0.6)
```

### In TypingDisplay when word completed:
```gdscript
func on_word_completed(word: String, errors: int) -> void:
	var center := get_word_center_position()
	spawn_word_complete_flash(center)

	if errors == 0:
		spawn_perfect_celebration(word, center)
```

---

## Files Modified/Created Summary

| File | Action | Lines Changed |
|------|--------|--------------|
| `ui/components/typing_display.gd` | Modified | +150 lines |
| `scripts/Battlefield.gd` | Modified | +30 lines |

**Total new code**: ~180 lines
