# Phase 3: UI Feedback - Granular Implementation Guide

## Overview

This document covers UI polish including panel transitions, resource indicators, and enhanced feedback. Each task includes exact code and integration points.

---

## Task 3.1: Create Panel Transition System

**Time**: 25 minutes
**File to create**: `ui/panel_transitions.gd`

### Step 3.1.1: Create the transition utility

**Action**: Create new file `ui/panel_transitions.gd`

**Complete file contents**:

```gdscript
class_name PanelTransitions
extends RefCounted
## Utility class for animated panel show/hide transitions.
## Supports slide, fade, scale, and combo transitions.

enum TransitionType {
	FADE,
	SLIDE_LEFT,
	SLIDE_RIGHT,
	SLIDE_UP,
	SLIDE_DOWN,
	SCALE,
	SCALE_FADE,
	SLIDE_FADE_LEFT,
	SLIDE_FADE_RIGHT
}

const DEFAULT_DURATION := 0.25
const DEFAULT_EASE := Tween.EASE_OUT
const DEFAULT_TRANS := Tween.TRANS_QUAD
const OVERSHOOT_TRANS := Tween.TRANS_BACK

static var _panel_tweens: Dictionary = {}  # Control -> Tween
static var _panel_positions: Dictionary = {}  # Control -> original position
static var _settings_manager = null


## Show a panel with animation
static func show_panel(
	panel: Control,
	transition: TransitionType = TransitionType.SCALE_FADE,
	duration: float = DEFAULT_DURATION,
	callback: Callable = Callable()
) -> void:
	if panel == null or not panel.is_inside_tree():
		return

	if _is_reduced_motion():
		panel.visible = true
		panel.modulate.a = 1.0
		panel.scale = Vector2.ONE
		if callback.is_valid():
			callback.call()
		return

	_kill_tween(panel)
	_store_position(panel)

	# Reset to hidden state first
	match transition:
		TransitionType.FADE:
			panel.modulate.a = 0.0
		TransitionType.SLIDE_LEFT:
			panel.position.x = _panel_positions[panel].x - 50.0
		TransitionType.SLIDE_RIGHT:
			panel.position.x = _panel_positions[panel].x + 50.0
		TransitionType.SLIDE_UP:
			panel.position.y = _panel_positions[panel].y - 30.0
		TransitionType.SLIDE_DOWN:
			panel.position.y = _panel_positions[panel].y + 30.0
		TransitionType.SCALE:
			panel.scale = Vector2(0.8, 0.8)
			panel.pivot_offset = panel.size * 0.5
		TransitionType.SCALE_FADE:
			panel.modulate.a = 0.0
			panel.scale = Vector2(0.9, 0.9)
			panel.pivot_offset = panel.size * 0.5
		TransitionType.SLIDE_FADE_LEFT:
			panel.modulate.a = 0.0
			panel.position.x = _panel_positions[panel].x - 30.0
		TransitionType.SLIDE_FADE_RIGHT:
			panel.modulate.a = 0.0
			panel.position.x = _panel_positions[panel].x + 30.0

	panel.visible = true

	var tween := panel.create_tween()
	if tween == null:
		return

	tween.set_parallel(true)
	tween.set_ease(DEFAULT_EASE)

	match transition:
		TransitionType.FADE:
			tween.set_trans(DEFAULT_TRANS)
			tween.tween_property(panel, "modulate:a", 1.0, duration)
		TransitionType.SLIDE_LEFT, TransitionType.SLIDE_RIGHT:
			tween.set_trans(OVERSHOOT_TRANS)
			tween.tween_property(panel, "position:x", _panel_positions[panel].x, duration)
		TransitionType.SLIDE_UP, TransitionType.SLIDE_DOWN:
			tween.set_trans(OVERSHOOT_TRANS)
			tween.tween_property(panel, "position:y", _panel_positions[panel].y, duration)
		TransitionType.SCALE:
			tween.set_trans(OVERSHOOT_TRANS)
			tween.tween_property(panel, "scale", Vector2.ONE, duration)
		TransitionType.SCALE_FADE:
			tween.set_trans(OVERSHOOT_TRANS)
			tween.tween_property(panel, "modulate:a", 1.0, duration * 0.6)
			tween.tween_property(panel, "scale", Vector2.ONE, duration)
		TransitionType.SLIDE_FADE_LEFT, TransitionType.SLIDE_FADE_RIGHT:
			tween.set_trans(DEFAULT_TRANS)
			tween.tween_property(panel, "modulate:a", 1.0, duration)
			tween.tween_property(panel, "position:x", _panel_positions[panel].x, duration)

	if callback.is_valid():
		tween.chain().tween_callback(callback)

	_panel_tweens[panel] = tween


## Hide a panel with animation
static func hide_panel(
	panel: Control,
	transition: TransitionType = TransitionType.SCALE_FADE,
	duration: float = DEFAULT_DURATION,
	callback: Callable = Callable()
) -> void:
	if panel == null or not panel.is_inside_tree():
		return

	if _is_reduced_motion():
		panel.visible = false
		if callback.is_valid():
			callback.call()
		return

	_kill_tween(panel)
	_store_position(panel)

	var tween := panel.create_tween()
	if tween == null:
		return

	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(DEFAULT_TRANS)

	match transition:
		TransitionType.FADE:
			tween.tween_property(panel, "modulate:a", 0.0, duration)
		TransitionType.SLIDE_LEFT:
			tween.tween_property(panel, "position:x", panel.position.x - 50.0, duration)
		TransitionType.SLIDE_RIGHT:
			tween.tween_property(panel, "position:x", panel.position.x + 50.0, duration)
		TransitionType.SLIDE_UP:
			tween.tween_property(panel, "position:y", panel.position.y - 30.0, duration)
		TransitionType.SLIDE_DOWN:
			tween.tween_property(panel, "position:y", panel.position.y + 30.0, duration)
		TransitionType.SCALE:
			tween.tween_property(panel, "scale", Vector2(0.8, 0.8), duration)
		TransitionType.SCALE_FADE:
			tween.tween_property(panel, "modulate:a", 0.0, duration)
			tween.tween_property(panel, "scale", Vector2(0.9, 0.9), duration)
		TransitionType.SLIDE_FADE_LEFT:
			tween.tween_property(panel, "modulate:a", 0.0, duration)
			tween.tween_property(panel, "position:x", panel.position.x - 30.0, duration)
		TransitionType.SLIDE_FADE_RIGHT:
			tween.tween_property(panel, "modulate:a", 0.0, duration)
			tween.tween_property(panel, "position:x", panel.position.x + 30.0, duration)

	tween.chain().tween_callback(func():
		panel.visible = false
		_restore_position(panel)
		if callback.is_valid():
			callback.call()
	)

	_panel_tweens[panel] = tween


static func _store_position(panel: Control) -> void:
	if not _panel_positions.has(panel):
		_panel_positions[panel] = panel.position


static func _restore_position(panel: Control) -> void:
	if _panel_positions.has(panel):
		panel.position = _panel_positions[panel]


static func _kill_tween(panel: Control) -> void:
	if _panel_tweens.has(panel):
		var tween: Tween = _panel_tweens[panel]
		if tween != null and tween.is_valid():
			tween.kill()
		_panel_tweens.erase(panel)


static func _is_reduced_motion() -> bool:
	if _settings_manager == null:
		var tree = Engine.get_main_loop()
		if tree != null and tree.root != null:
			_settings_manager = tree.root.get_node_or_null("/root/SettingsManager")
	if _settings_manager != null and _settings_manager.get("reduced_motion") != null:
		return _settings_manager.reduced_motion
	return false
```

### Verification:
1. Import in any UI scene with `const PanelTransitions = preload("res://ui/panel_transitions.gd")`
2. Call `PanelTransitions.show_panel(my_panel, PanelTransitions.TransitionType.SCALE_FADE)`
3. Panel fades and scales in smoothly
4. Call `PanelTransitions.hide_panel(my_panel)` to animate out

---

## Task 3.2: Create Resource Change Indicator

**Time**: 25 minutes
**File to create**: `ui/resource_popup.gd`

### Step 3.2.1: Create the resource popup system

**Action**: Create new file `ui/resource_popup.gd`

**Complete file contents**:

```gdscript
class_name ResourcePopup
extends RefCounted
## Floating +/- indicators for resource changes.

const POPUP_DURATION := 1.2
const POPUP_RISE_SPEED := 40.0
const POPUP_FADE_START := 0.6  # When to start fading
const FONT_SIZE := 16
const FONT_SIZE_LARGE := 20

# Resource colors
const RESOURCE_COLORS := {
	"gold": Color(1.0, 0.84, 0.0),
	"wood": Color(0.6, 0.4, 0.2),
	"stone": Color(0.6, 0.6, 0.7),
	"food": Color(0.4, 0.8, 0.4),
	"mana": Color(0.5, 0.4, 1.0),
	"xp": Color(0.4, 0.9, 1.0),
	"hp": Color(0.9, 0.3, 0.3),
	"default": Color(0.9, 0.9, 0.9)
}

var _active_popups: Array = []
var _parent: Node = null


func set_parent(parent: Node) -> void:
	_parent = parent


func spawn_popup(
	position: Vector2,
	amount: int,
	resource_type: String = "default",
	is_large: bool = false
) -> void:
	if _parent == null:
		return

	var label := Label.new()

	# Format text
	var prefix := "+" if amount > 0 else ""
	label.text = "%s%d" % [prefix, amount]

	# Style
	var color: Color = RESOURCE_COLORS.get(resource_type, RESOURCE_COLORS["default"])
	if amount < 0:
		color = color.darkened(0.2)

	label.add_theme_font_size_override("font_size", FONT_SIZE_LARGE if is_large else FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)

	# Position centered above spawn point
	label.position = position - Vector2(20, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(40, 0)

	_parent.add_child(label)

	_active_popups.append({
		"node": label,
		"lifetime": POPUP_DURATION,
		"velocity": Vector2(randf_range(-10, 10), -POPUP_RISE_SPEED)
	})


func spawn_resource_change(
	position: Vector2,
	resource_type: String,
	old_value: int,
	new_value: int
) -> void:
	var delta := new_value - old_value
	if delta == 0:
		return

	var is_large := abs(delta) >= 50
	spawn_popup(position, delta, resource_type, is_large)


func update(delta: float) -> void:
	for i in range(_active_popups.size() - 1, -1, -1):
		var popup = _active_popups[i]
		if not popup is Dictionary:
			_active_popups.remove_at(i)
			continue

		var node = popup.get("node")
		if node == null or not is_instance_valid(node):
			_active_popups.remove_at(i)
			continue

		var lifetime: float = popup.get("lifetime", 0.0)
		var velocity: Vector2 = popup.get("velocity", Vector2.ZERO)

		lifetime -= delta
		popup["lifetime"] = lifetime

		if lifetime <= 0.0:
			node.queue_free()
			_active_popups.remove_at(i)
			continue

		# Move
		node.position += velocity * delta

		# Fade
		if lifetime < POPUP_FADE_START:
			node.modulate.a = lifetime / POPUP_FADE_START


func clear() -> void:
	for popup in _active_popups:
		if popup is Dictionary:
			var node = popup.get("node")
			if node != null and is_instance_valid(node):
				node.queue_free()
	_active_popups.clear()
```

### Step 3.2.2: Integrate into Kingdom Hub

**File**: `scripts/KingdomHub.gd`
**Action**: Add resource popup instance

**Add preload at top**:
```gdscript
const ResourcePopup = preload("res://ui/resource_popup.gd")
```

**Add variable**:
```gdscript
var resource_popup: ResourcePopup
```

**Initialize in `_ready()`**:
```gdscript
	resource_popup = ResourcePopup.new()
	resource_popup.set_parent(self)
```

**Update in `_process()`**:
```gdscript
	if resource_popup != null:
		resource_popup.update(delta)
```

**Spawn popups when resources change** (find resource update code):
```gdscript
# Example usage when gold changes:
var gold_label_pos := gold_label.global_position + Vector2(gold_label.size.x * 0.5, 0)
resource_popup.spawn_resource_change(gold_label_pos, "gold", old_gold, new_gold)
```

### Verification:
1. When gold increases, "+X" appears in gold color and floats up
2. When resources decrease, "-X" appears slightly darker
3. Large changes (50+) use larger font
4. Popups fade out smoothly

---

## Task 3.3: Add Progress Bar Shine Effect

**Time**: 15 minutes
**File to modify**: `ui/components/typing_display.gd`

### Step 3.3.1: Add shine animation state

**File**: `ui/components/typing_display.gd`
**Action**: Add variables after existing progress bar vars (around line 61)

```gdscript
# Progress bar shine effect
var _shine_position: float = -0.3  # -0.3 to 1.3 for full sweep
var _shine_active: bool = false
const SHINE_WIDTH := 0.15
const SHINE_SPEED := 1.5
const SHINE_COLOR := Color(1.0, 1.0, 1.0, 0.4)
```

### Step 3.3.2: Trigger shine on milestone

**File**: `ui/components/typing_display.gd`
**Action**: Find where progress milestones are detected and add shine trigger

**Add method**:
```gdscript
func _trigger_shine() -> void:
	_shine_active = true
	_shine_position = -0.3

	# Tween shine across
	var tween := create_tween()
	tween.tween_property(self, "_shine_position", 1.3, SHINE_SPEED)
	tween.tween_callback(func(): _shine_active = false)
```

**Call when milestone reached** (in update_progress or similar):
```gdscript
# When progress crosses a milestone threshold:
_trigger_shine()
```

### Step 3.3.3: Draw shine in progress bar

**File**: `ui/components/typing_display.gd`
**Action**: Modify `_draw_progress_bar()` or create custom draw

**Add to progress bar drawing** (if using custom `_draw()`):
```gdscript
func _draw_progress_shine(rect: Rect2) -> void:
	if not _shine_active:
		return

	# Calculate shine rectangle position
	var shine_x := rect.position.x + rect.size.x * _shine_position
	var shine_rect := Rect2(
		shine_x - rect.size.x * SHINE_WIDTH * 0.5,
		rect.position.y,
		rect.size.x * SHINE_WIDTH,
		rect.size.y
	)

	# Clip to progress bar bounds
	shine_rect = shine_rect.intersection(rect)

	if shine_rect.size.x > 0:
		draw_rect(shine_rect, SHINE_COLOR)
```

### Verification:
1. Progress bar shows normal fill
2. At 50%, 75%, 100% milestones, a white shine sweeps across
3. Shine is subtle and doesn't distract

---

## Task 3.4: Add Threat Bar Pulse Effect

**Time**: 15 minutes
**File to modify**: `scripts/Battlefield.gd`

### Step 3.4.1: Add pulse state variables

**File**: `scripts/Battlefield.gd`
**Action**: Add after `THREAT_WARNING_THRESHOLD` (around line 166)

```gdscript
# Threat pulse effect
var _threat_pulse: float = 0.0
var _threat_pulse_direction: float = 1.0
const THREAT_PULSE_SPEED := 2.5
const THREAT_PULSE_MIN := 0.85
const THREAT_PULSE_MAX := 1.0
const THREAT_DANGER_THRESHOLD := 80.0  # Start pulsing at 80%
```

### Step 3.4.2: Update pulse in _process

**File**: `scripts/Battlefield.gd`
**Action**: Add to existing `_process()` function

**Add this logic**:
```gdscript
func _update_threat_pulse(delta: float) -> void:
	if threat < THREAT_DANGER_THRESHOLD:
		_threat_pulse = THREAT_PULSE_MAX
		return

	# Oscillate pulse
	_threat_pulse += THREAT_PULSE_SPEED * delta * _threat_pulse_direction

	if _threat_pulse >= THREAT_PULSE_MAX:
		_threat_pulse = THREAT_PULSE_MAX
		_threat_pulse_direction = -1.0
	elif _threat_pulse <= THREAT_PULSE_MIN:
		_threat_pulse = THREAT_PULSE_MIN
		_threat_pulse_direction = 1.0

	# Apply to threat bar scale
	if threat_bar != null:
		threat_bar.scale = Vector2(_threat_pulse, _threat_pulse)
```

**Call in `_process()`**:
```gdscript
	_update_threat_pulse(delta)
```

### Step 3.4.3: Add color transition based on threat

**File**: `scripts/Battlefield.gd`
**Action**: Add threat bar color update

```gdscript
func _update_threat_bar_color() -> void:
	if threat_bar == null:
		return

	var color: Color
	if threat < 30.0:
		color = Color(0.3, 0.8, 0.4)  # Green - safe
	elif threat < 50.0:
		color = Color(0.9, 0.9, 0.3)  # Yellow - caution
	elif threat < 80.0:
		color = Color(1.0, 0.6, 0.2)  # Orange - danger
	else:
		color = Color(1.0, 0.3, 0.3)  # Red - critical

	# Apply via modulate for simple color change
	threat_bar.modulate = color
```

### Verification:
1. Threat bar stays stable below 80%
2. At 80%+ threat, bar starts pulsing (scale oscillates)
3. Color transitions: green -> yellow -> orange -> red
4. Pulse creates urgency without being annoying

---

## Task 3.5: Add Button Press Sound Feedback

**Time**: 10 minutes
**File to modify**: `ui/components/button_feedback.gd`

### Step 3.5.1: Add audio integration

**File**: `ui/components/button_feedback.gd`
**Action**: Modify `_on_button_down` to play sound

**Before** (around line 53-67):
```gdscript
static func _on_button_down(button: BaseButton) -> void:
	if _is_reduced_motion():
		return
	if not button.is_inside_tree():
		return

	_kill_tween(button)

	var tween := button.create_tween()
	if tween == null:
		return
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(button, "scale", Vector2(PRESS_SCALE, PRESS_SCALE), PRESS_DURATION)
	_button_tweens[button] = tween
```

**After**:
```gdscript
static func _on_button_down(button: BaseButton) -> void:
	# Play click sound (always, even with reduced motion)
	_play_click_sound(button)

	if _is_reduced_motion():
		return
	if not button.is_inside_tree():
		return

	_kill_tween(button)

	var tween := button.create_tween()
	if tween == null:
		return
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(button, "scale", Vector2(PRESS_SCALE, PRESS_SCALE), PRESS_DURATION)
	_button_tweens[button] = tween


static var _audio_manager = null

static func _play_click_sound(button: BaseButton) -> void:
	if _audio_manager == null:
		var tree = Engine.get_main_loop()
		if tree != null and tree.root != null:
			_audio_manager = tree.root.get_node_or_null("/root/AudioManager")

	if _audio_manager != null:
		_audio_manager.play_sfx(_audio_manager.SFX.UI_KEYTAP)
```

### Verification:
1. Click any button
2. Hear subtle click sound
3. Sound plays even with reduced motion enabled
4. Sound is rate-limited (no spam on rapid clicks)

---

## Task 3.6: Add Modal Backdrop Blur Simulation

**Time**: 20 minutes
**File to modify**: `ui/components/modal_panel.gd`

### Step 3.6.1: Add backdrop overlay

**File**: `ui/components/modal_panel.gd`
**Action**: Add backdrop creation to modal

**Add at top of file**:
```gdscript
const BACKDROP_COLOR := Color(0.0, 0.0, 0.0, 0.5)
const BACKDROP_FADE_DURATION := 0.2
```

**Add variables**:
```gdscript
var _backdrop: ColorRect = null
var _backdrop_tween: Tween = null
```

**Add backdrop creation method**:
```gdscript
func _create_backdrop() -> void:
	if _backdrop != null:
		return

	_backdrop = ColorRect.new()
	_backdrop.color = Color(0, 0, 0, 0)  # Start transparent
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP

	# Size to fill parent
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Insert behind this modal
	var parent := get_parent()
	if parent != null:
		parent.add_child(_backdrop)
		parent.move_child(_backdrop, get_index())


func _show_backdrop() -> void:
	_create_backdrop()

	if _backdrop_tween != null and _backdrop_tween.is_valid():
		_backdrop_tween.kill()

	_backdrop_tween = create_tween()
	_backdrop_tween.tween_property(_backdrop, "color", BACKDROP_COLOR, BACKDROP_FADE_DURATION)


func _hide_backdrop() -> void:
	if _backdrop == null:
		return

	if _backdrop_tween != null and _backdrop_tween.is_valid():
		_backdrop_tween.kill()

	_backdrop_tween = create_tween()
	_backdrop_tween.tween_property(_backdrop, "color", Color(0, 0, 0, 0), BACKDROP_FADE_DURATION)
	_backdrop_tween.tween_callback(func():
		if _backdrop != null:
			_backdrop.queue_free()
			_backdrop = null
	)
```

**Integrate with show/hide**:
```gdscript
func show_modal() -> void:
	_show_backdrop()
	# ... existing show code

func hide_modal() -> void:
	_hide_backdrop()
	# ... existing hide code
```

### Verification:
1. Open any modal
2. Dark overlay fades in behind modal
3. Overlay blocks clicks to background
4. Closing modal fades out overlay

---

## Task 3.7: Add Tooltip Appear Animation

**Time**: 15 minutes
**File to create**: `ui/components/action_tooltip.gd` (if not exists, enhance existing)

### Step 3.7.1: Create animated tooltip

**Action**: Create or modify `ui/components/action_tooltip.gd`

**Add animation logic**:

```gdscript
class_name ActionTooltip
extends PanelContainer
## Animated tooltip that fades and slides in.

const SHOW_DELAY := 0.4  # Delay before showing
const FADE_DURATION := 0.15
const SLIDE_OFFSET := Vector2(0, 8)

var _show_timer: float = 0.0
var _target_visible: bool = false
var _original_position: Vector2 = Vector2.ZERO

@onready var label: Label = $Label


func _ready() -> void:
	visible = false
	modulate.a = 0.0


func _process(delta: float) -> void:
	if _target_visible and not visible:
		_show_timer += delta
		if _show_timer >= SHOW_DELAY:
			_animate_show()


func show_tooltip(text: String, at_position: Vector2) -> void:
	if label != null:
		label.text = text
	_original_position = at_position
	position = at_position + SLIDE_OFFSET
	_target_visible = true
	_show_timer = 0.0


func hide_tooltip() -> void:
	_target_visible = false
	_show_timer = 0.0
	_animate_hide()


func _animate_show() -> void:
	visible = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)
	tween.tween_property(self, "position", _original_position, FADE_DURATION)


func _animate_hide() -> void:
	if not visible:
		return
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION * 0.7)
	tween.tween_callback(func(): visible = false)
```

### Verification:
1. Hover over UI element with tooltip
2. After 0.4s delay, tooltip slides up and fades in
3. Moving away immediately hides tooltip
4. Tooltip doesn't flicker on quick hover

---

## Summary Checklist

After completing all Phase 3 tasks, verify:

- [ ] Panel show/hide uses smooth scale+fade transition
- [ ] Resource changes show floating +/- indicators
- [ ] Progress bar has shine sweep on milestones
- [ ] Threat bar pulses when above 80%
- [ ] Threat bar color changes based on level
- [ ] Button clicks play audio feedback
- [ ] Modals have dark backdrop overlay
- [ ] Tooltips fade and slide in with delay

---

## Integration Points

### Using PanelTransitions in any UI:
```gdscript
const PanelTransitions = preload("res://ui/panel_transitions.gd")

func _on_open_button_pressed() -> void:
	PanelTransitions.show_panel(my_panel, PanelTransitions.TransitionType.SCALE_FADE)

func _on_close_button_pressed() -> void:
	PanelTransitions.hide_panel(my_panel, PanelTransitions.TransitionType.SCALE_FADE, 0.2, _on_panel_closed)
```

### Using ResourcePopup in Kingdom Hub:
```gdscript
# When resource changes:
func _on_gold_changed(old_gold: int, new_gold: int) -> void:
	var pos := gold_label.global_position + Vector2(gold_label.size.x * 0.5, 0)
	resource_popup.spawn_resource_change(pos, "gold", old_gold, new_gold)
```

---

## Files Modified/Created Summary

| File | Action | Lines Changed |
|------|--------|--------------|
| `ui/panel_transitions.gd` | Created | ~170 lines |
| `ui/resource_popup.gd` | Created | ~120 lines |
| `ui/components/typing_display.gd` | Modified | +30 lines |
| `scripts/Battlefield.gd` | Modified | +40 lines |
| `ui/components/button_feedback.gd` | Modified | +15 lines |
| `ui/components/modal_panel.gd` | Modified | +50 lines |
| `ui/components/action_tooltip.gd` | Created/Modified | ~80 lines |

**Total new code**: ~505 lines
