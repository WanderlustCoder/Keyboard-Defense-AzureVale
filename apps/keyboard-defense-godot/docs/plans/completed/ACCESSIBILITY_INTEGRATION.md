# Accessibility Integration Guide

## Overview

All polish features must support these accessibility settings from `SettingsManager`:

| Setting | Purpose | Impact |
|---------|---------|--------|
| `screen_shake` | Motion sensitivity | Disables camera shake |
| `reduced_motion` | Vestibular disorders | Reduces/removes animations |
| `high_contrast` | Low vision | Higher contrast colors |
| `large_text` | Low vision | Larger fonts |
| `colorblind_mode` | Color blindness | Alternative color schemes |
| `focus_indicators` | Keyboard navigation | Visible focus rings |

---

## Implementation Pattern

### Standard Accessibility Check

Every visual effect should include this pattern:

```gdscript
var _settings_manager = null

func _cache_settings() -> void:
	if _settings_manager == null:
		_settings_manager = get_node_or_null("/root/SettingsManager")


func _is_enabled() -> bool:
	_cache_settings()
	if _settings_manager != null:
		return _settings_manager.screen_shake
	return true  # Default enabled


func _is_reduced_motion() -> bool:
	_cache_settings()
	if _settings_manager != null:
		return _settings_manager.reduced_motion
	return false


func _is_high_contrast() -> bool:
	_cache_settings()
	if _settings_manager != null:
		return _settings_manager.high_contrast
	return false


func _get_colorblind_mode() -> String:
	_cache_settings()
	if _settings_manager != null:
		return _settings_manager.colorblind_mode
	return "none"


func _is_large_text() -> bool:
	_cache_settings()
	if _settings_manager != null:
		return _settings_manager.large_text
	return false
```

---

## Feature-Specific Implementations

### Screen Shake

```gdscript
func add_trauma(amount: float) -> void:
	# Skip entirely if disabled
	if not _is_enabled():
		return

	# Reduce intensity for reduced motion
	if _is_reduced_motion():
		amount *= 0.3

	trauma = clampf(trauma + amount, 0.0, 1.0)


func _apply_shake(delta: float) -> void:
	# Reduce offset for reduced motion
	var effective_offset := MAX_OFFSET
	var effective_rotation := MAX_ROTATION

	if _is_reduced_motion():
		effective_offset *= 0.3
		effective_rotation = 0.0  # No rotation
```

### Hit Pause

```gdscript
func pause(duration: float) -> void:
	if not _is_enabled():
		return

	# Shorter pause for reduced motion
	if _is_reduced_motion():
		duration *= 0.3

	# Minimum perceivable pause
	duration = maxf(duration, 0.016)

	_start_pause(duration)
```

### Damage Numbers

```gdscript
func spawn(position: Vector2, value: int, type: String, is_crit: bool) -> void:
	# In reduced motion, only show critical numbers
	if _is_reduced_motion() and not is_crit:
		return

	var label := _create_label()

	# High contrast: use white with black outline
	var color := _get_type_color(type)
	if _is_high_contrast():
		color = Color.WHITE
		label.add_theme_color_override("font_shadow_color", Color.BLACK)
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)

	# Colorblind adjustment
	color = _adjust_for_colorblind(color)

	# Large text
	var font_size := BASE_FONT_SIZE
	if _is_large_text():
		font_size = int(font_size * 1.4)
	if is_crit:
		font_size = int(font_size * 1.5)

	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
```

### Particles

```gdscript
func spawn_particles(position: Vector2, count: int) -> void:
	# Reduce particle count for reduced motion
	if _is_reduced_motion():
		count = maxi(1, count / 3)

	for i in range(count):
		_spawn_single_particle(position)


func _update_particle(particle: Dictionary, delta: float) -> void:
	# Shorter lifetime for reduced motion
	var lifetime: float = particle.get("lifetime", 0.0)
	if _is_reduced_motion():
		lifetime -= delta * 2.0  # Faster decay
	else:
		lifetime -= delta

	particle["lifetime"] = lifetime
```

### Scene Transitions

```gdscript
func transition_to_scene(path: String, type: TransitionType, duration: float) -> void:
	# Instant transition for reduced motion
	if _is_reduced_motion():
		get_tree().change_scene_to_file(path)
		return

	# Normal animated transition
	_play_transition(path, type, duration)
```

### UI Animations

```gdscript
static func show_panel(panel: Control, type: TransitionType, duration: float) -> void:
	# Instant show for reduced motion
	if _is_reduced_motion():
		panel.visible = true
		panel.modulate.a = 1.0
		panel.scale = Vector2.ONE
		return

	# Animated show
	_animate_panel_show(panel, type, duration)
```

---

## Colorblind Mode Implementation

### Color Substitution Map

```gdscript
const COLORBLIND_SUBSTITUTIONS := {
	"protanopia": {
		# Red-green blindness (no red cones)
		"damage": Color(0.9, 0.5, 0.0),    # Orange instead of red
		"heal": Color(0.0, 0.7, 1.0),      # Cyan instead of green
		"combo": Color(1.0, 0.8, 0.2),     # Yellow
		"critical": Color(1.0, 1.0, 0.5),  # Bright yellow
	},
	"deuteranopia": {
		# Red-green blindness (no green cones)
		"damage": Color(0.9, 0.4, 0.0),    # Orange
		"heal": Color(0.9, 0.9, 0.3),      # Yellow instead of green
		"combo": Color(0.5, 0.7, 1.0),     # Blue
		"critical": Color(1.0, 0.9, 0.4),  # Gold
	},
	"tritanopia": {
		# Blue-yellow blindness
		"damage": Color(1.0, 0.3, 0.3),    # Keep red
		"heal": Color(0.4, 0.9, 0.4),      # Keep green
		"combo": Color(1.0, 0.5, 0.5),     # Pink instead of purple
		"critical": Color(1.0, 0.6, 0.6),  # Light pink
	}
}


func _get_colorblind_color(type: String) -> Color:
	var mode := _get_colorblind_mode()
	if mode == "none":
		return _get_base_color(type)

	var substitutions: Dictionary = COLORBLIND_SUBSTITUTIONS.get(mode, {})
	return substitutions.get(type, _get_base_color(type))
```

### Pattern + Color for Critical Information

When colorblind mode is enabled, add patterns in addition to colors:

```gdscript
func _draw_status_indicator(type: String, rect: Rect2) -> void:
	var color := _get_colorblind_color(type)
	draw_rect(rect, color)

	# Add pattern for colorblind users
	if _get_colorblind_mode() != "none":
		match type:
			"burn":
				_draw_flame_pattern(rect)
			"slow":
				_draw_ice_pattern(rect)
			"poison":
				_draw_drip_pattern(rect)
			"shield":
				_draw_shield_pattern(rect)


func _draw_flame_pattern(rect: Rect2) -> void:
	# Draw small triangles pointing up
	var center := rect.get_center()
	for i in range(3):
		var offset := Vector2((i - 1) * 3, 0)
		draw_polygon([
			center + offset + Vector2(0, -3),
			center + offset + Vector2(-2, 2),
			center + offset + Vector2(2, 2)
		], [Color(1, 1, 1, 0.7)])
```

---

## High Contrast Mode

### Color Overrides

```gdscript
const HIGH_CONTRAST_COLORS := {
	"background": Color(0.0, 0.0, 0.0),
	"foreground": Color(1.0, 1.0, 1.0),
	"accent": Color(1.0, 1.0, 0.0),      # Yellow for highlights
	"error": Color(1.0, 0.0, 0.0),       # Pure red
	"success": Color(0.0, 1.0, 0.0),     # Pure green
	"warning": Color(1.0, 0.5, 0.0),     # Orange
	"info": Color(0.0, 1.0, 1.0),        # Cyan
}


func _get_high_contrast_color(type: String) -> Color:
	if _is_high_contrast():
		return HIGH_CONTRAST_COLORS.get(type, Color.WHITE)
	return _get_base_color(type)
```

### Border Emphasis

```gdscript
func _draw_element(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color)

	# Add thick border in high contrast mode
	if _is_high_contrast():
		draw_rect(rect, Color.WHITE, false, 2.0)
```

---

## Large Text Mode

### Font Size Scaling

```gdscript
const TEXT_SCALE_FACTOR := 1.4  # 40% larger in large text mode

func _get_scaled_font_size(base_size: int) -> int:
	if _is_large_text():
		return int(base_size * TEXT_SCALE_FACTOR)
	return base_size


# Usage:
label.add_theme_font_size_override("font_size", _get_scaled_font_size(16))
```

### Minimum Sizes

```gdscript
const MIN_FONT_SIZE := 12
const MIN_FONT_SIZE_LARGE := 16

func _get_min_font_size() -> int:
	return MIN_FONT_SIZE_LARGE if _is_large_text() else MIN_FONT_SIZE
```

---

## Focus Indicators

For keyboard navigation, ensure all interactive elements have visible focus:

```gdscript
func _setup_focus_style(control: Control) -> void:
	if not _settings_manager.focus_indicators:
		return

	# Create focus style
	var focus_style := StyleBoxFlat.new()
	focus_style.draw_center = false
	focus_style.border_width_left = 2
	focus_style.border_width_right = 2
	focus_style.border_width_top = 2
	focus_style.border_width_bottom = 2
	focus_style.border_color = Color(1.0, 0.8, 0.0)  # Yellow focus ring

	control.add_theme_stylebox_override("focus", focus_style)
```

---

## Testing Accessibility

### Automated Checks

```gdscript
func test_accessibility_compliance() -> void:
	var settings = get_node_or_null("/root/SettingsManager")
	if settings == null:
		_skip("No SettingsManager")
		return

	# Test each accessibility mode
	for mode in ["reduced_motion", "high_contrast", "large_text"]:
		settings.set(mode, true)

		# Create test effects
		var shake = ScreenShake.new()
		add_child(shake)
		shake.add_trauma(0.5)

		# Verify behavior changes
		match mode:
			"reduced_motion":
				assert(shake.trauma < 0.5 or shake.trauma == 0.0,
					"Reduced motion should reduce or disable shake")

		shake.queue_free()
		settings.set(mode, false)

	_pass("test_accessibility_compliance")
```

### Manual Testing Checklist

- [ ] **Reduced Motion**: All animations significantly reduced or disabled
- [ ] **Screen Shake Off**: No camera movement on any action
- [ ] **High Contrast**: All text readable, clear borders
- [ ] **Large Text**: All text readable without zooming
- [ ] **Colorblind Modes**: All information distinguishable
- [ ] **Focus Indicators**: Can navigate with keyboard only

---

## Accessibility Settings UI

Recommended settings panel layout:

```
[Accessibility]

[ ] Reduce motion
    Minimize animations and movement effects

[ ] Disable screen shake
    Remove camera shake effects

[ ] High contrast mode
    Increase contrast for better visibility

[ ] Large text
    Increase text size by 40%

Colorblind mode:
[v] None
[ ] Protanopia (red-weak)
[ ] Deuteranopia (green-weak)
[ ] Tritanopia (blue-weak)

[ ] Show focus indicators
    Highlight keyboard-focused elements
```
