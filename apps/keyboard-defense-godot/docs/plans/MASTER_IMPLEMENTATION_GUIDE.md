# Master Implementation Guide - Polish & Juice

## Executive Summary

This document consolidates all polish implementation phases with:
- **Exact file paths and line numbers**
- **Complete code with settings integration**
- **Accessibility support throughout**
- **Testing verification for each feature**
- **Performance considerations**
- **Troubleshooting guides**

---

## Prerequisites & Dependencies

### Existing Systems to Leverage

The codebase already has these polish systems in `scripts/Battlefield.gd`:

| System | Lines | Variables |
|--------|-------|-----------|
| Screen Shake | 149-154, 394 | `_shake_intensity`, `_shake_duration` |
| Error Shake | 237-242, 294-297 | `_error_shake_tween`, `ERROR_SHAKE_INTENSITY` |
| Typing Pulse | 244-248 | `_typing_pulse_tween`, `TYPING_PULSE_SCALE` |
| Combo Indicator | 192-196, 277, 395 | `combo_label`, `_combo_pulse_timer` |
| Milestone Popup | 197-210, 278, 396 | `_milestone_popup`, `MILESTONE_THRESHOLDS` |
| Edge Glow | 212-215, 279, 397 | `_edge_glow_container`, `EDGE_GLOW_THRESHOLD` |
| Threat Glow | 176-180, 282, 399 | `_threat_glow`, `THREAT_GLOW_THRESHOLD` |
| Streak Glow | 182-189, 283, 400 | `_streak_glow`, `STREAK_GLOW_COLOR_*` |
| Accuracy Badge | 217-235, 281 | `_accuracy_badge`, `ACCURACY_BADGE_*` |
| Grade System | 250-266 | `GRADE_THRESHOLDS`, `GRADE_COLORS` |

### Settings Integration Points

From `game/settings_manager.gd`:

| Setting | Variable | Default | Line |
|---------|----------|---------|------|
| Screen Shake | `screen_shake` | `true` | 27 |
| Reduced Motion | `reduced_motion` | `false` | 31 |
| High Contrast | `high_contrast` | `false` | 32 |
| Colorblind Mode | `colorblind_mode` | `"none"` | 34 |
| Typing Sounds | `typing_sounds` | `true` | 30 |

### Existing Autoloads (project.godot lines 19-27)

```
ThemeColors      -> res://ui/theme_colors.gd
DesignSystem     -> res://ui/design_system.gd
AssetLoader      -> res://game/asset_loader.gd
ProgressionState -> res://scripts/ProgressionState.gd
GameController   -> res://scripts/GameController.gd
AudioManager     -> res://game/audio_manager.gd
SettingsManager  -> res://game/settings_manager.gd
```

---

## Phase 1: Core Polish Systems

### 1.1 Screen Shake Enhancement

**Current Implementation** (Battlefield.gd:149-154):
```gdscript
var _shake_intensity: float = 0.0
var _shake_duration: float = 0.0
var _shake_initial_duration: float = 0.0
var _shake_offset: Vector2 = Vector2.ZERO
const SHAKE_DECAY := 5.0
```

**Enhancement**: Create global ScreenShake autoload for use across all scenes.

**File**: `game/screen_shake.gd` (CREATE)

```gdscript
extends CanvasLayer
class_name ScreenShake
## Global screen shake system with trauma-based intensity.
## Respects SettingsManager.screen_shake and reduced_motion settings.

signal trauma_changed(new_value: float)

# Configuration
const MAX_OFFSET := Vector2(20.0, 15.0)
const MAX_ROTATION := 0.04
const DECAY_RATE := 0.8
const TRAUMA_POWER := 2.0  # Quadratic for better feel

# Shake presets
const PRESET_LIGHT := 0.2
const PRESET_MEDIUM := 0.4
const PRESET_HEAVY := 0.6
const PRESET_EXTREME := 0.9

# State
var trauma: float = 0.0
var _noise: FastNoiseLite
var _noise_y: float = 0.0
var _camera: Camera2D
var _original_offset: Vector2 = Vector2.ZERO
var _original_rotation: float = 0.0

# Settings reference
var _settings_manager = null


func _ready() -> void:
	layer = 99  # High layer for overlay effects
	_setup_noise()
	_cache_settings_manager()
	call_deferred("_find_camera")


func _setup_noise() -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = randi()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 4.0


func _cache_settings_manager() -> void:
	_settings_manager = get_node_or_null("/root/SettingsManager")


func _find_camera() -> void:
	await get_tree().process_frame
	var viewport := get_viewport()
	if viewport:
		_camera = viewport.get_camera_2d()
		if _camera:
			_original_offset = _camera.offset
			_original_rotation = _camera.rotation


func set_camera(camera: Camera2D) -> void:
	"""Manually set the camera to shake."""
	_camera = camera
	if _camera:
		_original_offset = _camera.offset
		_original_rotation = _camera.rotation


func add_trauma(amount: float) -> void:
	"""Add trauma (0.0-1.0). Clamps to max 1.0."""
	if not _is_shake_enabled():
		return

	var old_trauma := trauma
	trauma = clampf(trauma + amount, 0.0, 1.0)

	if trauma != old_trauma:
		trauma_changed.emit(trauma)


func set_trauma(amount: float) -> void:
	"""Set trauma directly (0.0-1.0)."""
	if not _is_shake_enabled():
		trauma = 0.0
		return

	trauma = clampf(amount, 0.0, 1.0)
	trauma_changed.emit(trauma)


func shake_light() -> void:
	add_trauma(PRESET_LIGHT)


func shake_medium() -> void:
	add_trauma(PRESET_MEDIUM)


func shake_heavy() -> void:
	add_trauma(PRESET_HEAVY)


func shake_extreme() -> void:
	add_trauma(PRESET_EXTREME)


func _process(delta: float) -> void:
	if trauma <= 0.0 or _camera == null:
		return

	# Decay trauma
	trauma = maxf(0.0, trauma - DECAY_RATE * delta)

	# Calculate shake amount (quadratic for snappier feel)
	var shake_amount := pow(trauma, TRAUMA_POWER)

	# Reduced motion: use smaller offsets, no rotation
	var is_reduced := _is_reduced_motion()
	var effective_offset := MAX_OFFSET * (0.3 if is_reduced else 1.0)
	var effective_rotation := 0.0 if is_reduced else MAX_ROTATION

	# Sample noise
	_noise_y += delta * 50.0
	var offset_x := _noise.get_noise_2d(0.0, _noise_y) * effective_offset.x * shake_amount
	var offset_y := _noise.get_noise_2d(100.0, _noise_y) * effective_offset.y * shake_amount
	var rotation := _noise.get_noise_2d(200.0, _noise_y) * effective_rotation * shake_amount

	# Apply to camera
	_camera.offset = _original_offset + Vector2(offset_x, offset_y)
	_camera.rotation = _original_rotation + rotation

	# Reset when done
	if trauma <= 0.0:
		_camera.offset = _original_offset
		_camera.rotation = _original_rotation


func _is_shake_enabled() -> bool:
	if _settings_manager == null:
		_cache_settings_manager()
	if _settings_manager != null:
		return _settings_manager.screen_shake
	return true


func _is_reduced_motion() -> bool:
	if _settings_manager == null:
		_cache_settings_manager()
	if _settings_manager != null:
		return _settings_manager.reduced_motion
	return false


func get_trauma() -> float:
	return trauma


func is_shaking() -> bool:
	return trauma > 0.0
```

**Register Autoload** - Add to `project.godot` at line 28:
```ini
ScreenShake="*res://game/screen_shake.gd"
```

**Integration** - Replace direct shake calls in Battlefield.gd:

```gdscript
# OLD (Battlefield.gd line 420):
_trigger_screen_shake(12.0, 0.3)

# NEW:
var screen_shake = get_node_or_null("/root/ScreenShake")
if screen_shake != null:
	screen_shake.shake_heavy()
```

**Test Script** - Add to `tests/run_tests.gd`:

```gdscript
func test_screen_shake_settings_integration() -> void:
	var shake = ScreenShake.new()
	add_child(shake)

	# Test that shake respects settings
	var settings = get_node_or_null("/root/SettingsManager")
	if settings != null:
		settings.screen_shake = false
		shake.add_trauma(0.5)
		assert(shake.trauma == 0.0, "Shake should be disabled when settings.screen_shake is false")

		settings.screen_shake = true
		shake.add_trauma(0.5)
		assert(shake.trauma == 0.5, "Shake should work when enabled")

	shake.queue_free()
	_pass("test_screen_shake_settings_integration")
```

---

### 1.2 Hit Pause System

**File**: `game/hit_pause.gd` (CREATE)

```gdscript
extends Node
class_name HitPause
## Frame-perfect hit pause for impactful moments.
## Uses Engine.time_scale for true pause effect.

signal pause_started
signal pause_ended

# Configuration
const MIN_PAUSE_DURATION := 0.016  # ~1 frame at 60fps
const MAX_PAUSE_DURATION := 0.25   # Never pause longer than this

# Pause presets (in seconds)
const PRESET_MICRO := 0.03   # Barely noticeable
const PRESET_LIGHT := 0.05   # Subtle hit
const PRESET_MEDIUM := 0.08  # Normal hit
const PRESET_HEAVY := 0.12   # Heavy hit
const PRESET_EXTREME := 0.18 # Critical/boss hit

# State
var _is_pausing: bool = false
var _pause_timer: float = 0.0
var _original_time_scale: float = 1.0
var _settings_manager = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Process even when paused
	_cache_settings_manager()


func _cache_settings_manager() -> void:
	_settings_manager = get_node_or_null("/root/SettingsManager")


func _process(delta: float) -> void:
	if not _is_pausing:
		return

	# Use unscaled delta for accurate timing
	var unscaled_delta := delta / maxf(Engine.time_scale, 0.001)
	_pause_timer -= unscaled_delta

	if _pause_timer <= 0.0:
		_end_pause()


func pause(duration: float) -> void:
	"""Pause the game for a duration (in seconds)."""
	if not _is_enabled():
		return

	# Clamp duration
	duration = clampf(duration, MIN_PAUSE_DURATION, MAX_PAUSE_DURATION)

	# Reduced motion: shorter pauses
	if _is_reduced_motion():
		duration *= 0.3

	# If already pausing, extend if new duration is longer
	if _is_pausing:
		_pause_timer = maxf(_pause_timer, duration)
		return

	_is_pausing = true
	_pause_timer = duration
	_original_time_scale = Engine.time_scale
	Engine.time_scale = 0.0
	pause_started.emit()


func pause_micro() -> void:
	pause(PRESET_MICRO)


func pause_light() -> void:
	pause(PRESET_LIGHT)


func pause_medium() -> void:
	pause(PRESET_MEDIUM)


func pause_heavy() -> void:
	pause(PRESET_HEAVY)


func pause_extreme() -> void:
	pause(PRESET_EXTREME)


func _end_pause() -> void:
	_is_pausing = false
	Engine.time_scale = _original_time_scale
	pause_ended.emit()


func cancel_pause() -> void:
	"""Immediately end any active pause."""
	if _is_pausing:
		_end_pause()


func _is_enabled() -> bool:
	# Hit pause follows screen_shake setting
	if _settings_manager == null:
		_cache_settings_manager()
	if _settings_manager != null:
		return _settings_manager.screen_shake
	return true


func _is_reduced_motion() -> bool:
	if _settings_manager == null:
		_cache_settings_manager()
	if _settings_manager != null:
		return _settings_manager.reduced_motion
	return false


func is_pausing() -> bool:
	return _is_pausing
```

**Register Autoload** - Add to `project.godot` at line 29:
```ini
HitPause="*res://game/hit_pause.gd"
```

**Integration Example** - For critical hits in BattleStage.gd:

```gdscript
func _on_critical_hit() -> void:
	var hit_pause = get_node_or_null("/root/HitPause")
	if hit_pause != null:
		hit_pause.pause_heavy()

	var screen_shake = get_node_or_null("/root/ScreenShake")
	if screen_shake != null:
		screen_shake.shake_medium()
```

---

### 1.3 Damage Numbers System

**File**: `game/damage_numbers.gd` (CREATE)

```gdscript
extends Node
class_name DamageNumbers
## Floating damage/score numbers with pooling.

const ObjectPool = preload("res://game/object_pool.gd")

# Configuration
const POOL_SIZE := 20
const MAX_POOL_SIZE := 50
const BASE_FONT_SIZE := 16
const CRIT_FONT_SIZE := 24
const RISE_SPEED := 60.0
const LIFETIME := 0.9
const FADE_START := 0.5  # Start fading at this remaining lifetime
const SPREAD := 30.0  # Horizontal spread

# Number types with colors
const NUMBER_TYPES := {
	"damage": Color(1.0, 0.3, 0.2),
	"heal": Color(0.3, 0.9, 0.4),
	"gold": Color(1.0, 0.84, 0.0),
	"xp": Color(0.5, 0.7, 1.0),
	"combo": Color(1.0, 0.6, 0.8),
	"critical": Color(1.0, 0.9, 0.3),
	"miss": Color(0.7, 0.7, 0.7),
	"blocked": Color(0.5, 0.5, 0.6)
}

var _pool: ObjectPool
var _active_numbers: Array = []
var _parent: Node = null
var _settings_manager = null


func _ready() -> void:
	_setup_pool()
	_cache_settings_manager()


func _cache_settings_manager() -> void:
	_settings_manager = get_node_or_null("/root/SettingsManager")


func _setup_pool() -> void:
	_pool = ObjectPool.new(_create_label, _reset_label, MAX_POOL_SIZE)


func _create_label() -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.visible = false
	return label


func _reset_label(label: Label) -> void:
	label.text = ""
	label.modulate = Color.WHITE
	label.scale = Vector2.ONE
	label.rotation = 0.0


func set_parent(parent: Node) -> void:
	_parent = parent
	_pool.set_parent(parent)
	_pool.prewarm(POOL_SIZE)


func spawn(
	position: Vector2,
	value: Variant,
	number_type: String = "damage",
	is_critical: bool = false
) -> void:
	if _parent == null:
		return

	# Check reduced motion
	if _is_reduced_motion():
		# In reduced motion, only show critical numbers
		if not is_critical:
			return

	var label: Label = _pool.acquire()
	if label == null:
		return

	# Format text
	var text: String
	if value is int:
		text = "+%d" % value if value > 0 else str(value)
	elif value is float:
		text = "+%.1f" % value if value > 0 else "%.1f" % value
	else:
		text = str(value)

	label.text = text

	# Style based on type
	var color := NUMBER_TYPES.get(number_type, Color.WHITE)
	if is_critical:
		color = NUMBER_TYPES.get("critical", color)

	# High contrast mode
	if _is_high_contrast():
		color = Color.WHITE
		label.add_theme_color_override("font_shadow_color", Color.BLACK)

	label.add_theme_color_override("font_color", color)

	# Font size
	var font_size := CRIT_FONT_SIZE if is_critical else BASE_FONT_SIZE
	if _is_large_text():
		font_size = int(font_size * 1.3)
	label.add_theme_font_size_override("font_size", font_size)

	# Position with spread
	var spread_offset := Vector2(randf_range(-SPREAD, SPREAD), 0)
	label.position = position + spread_offset - Vector2(40, 0)  # Center offset
	label.custom_minimum_size = Vector2(80, 30)

	# Initial scale for pop effect
	if is_critical:
		label.scale = Vector2(1.5, 1.5)
	else:
		label.scale = Vector2(1.2, 1.2)
	label.pivot_offset = Vector2(40, 15)

	label.visible = true

	if label.get_parent() == null:
		_parent.add_child(label)

	_active_numbers.append({
		"node": label,
		"lifetime": LIFETIME,
		"velocity": Vector2(randf_range(-10, 10), -RISE_SPEED),
		"is_critical": is_critical
	})


func spawn_damage(position: Vector2, amount: int, is_crit: bool = false) -> void:
	spawn(position, -amount, "damage", is_crit)


func spawn_heal(position: Vector2, amount: int) -> void:
	spawn(position, amount, "heal", false)


func spawn_gold(position: Vector2, amount: int) -> void:
	spawn(position, amount, "gold", amount >= 50)


func spawn_combo(position: Vector2, combo: int) -> void:
	spawn(position, "x%d" % combo, "combo", combo >= 20)


func spawn_text(position: Vector2, text: String, color: Color = Color.WHITE) -> void:
	if _parent == null:
		return

	var label: Label = _pool.acquire()
	if label == null:
		return

	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", BASE_FONT_SIZE + 2)
	label.position = position - Vector2(40, 0)
	label.custom_minimum_size = Vector2(80, 30)
	label.scale = Vector2(1.1, 1.1)
	label.pivot_offset = Vector2(40, 15)
	label.visible = true

	if label.get_parent() == null:
		_parent.add_child(label)

	_active_numbers.append({
		"node": label,
		"lifetime": LIFETIME * 1.2,
		"velocity": Vector2(0, -RISE_SPEED * 0.8),
		"is_critical": false
	})


func update(delta: float) -> void:
	for i in range(_active_numbers.size() - 1, -1, -1):
		var entry = _active_numbers[i]
		if not entry is Dictionary:
			_active_numbers.remove_at(i)
			continue

		var node = entry.get("node")
		if node == null or not is_instance_valid(node):
			_active_numbers.remove_at(i)
			continue

		var lifetime: float = entry.get("lifetime", 0.0)
		var velocity: Vector2 = entry.get("velocity", Vector2.ZERO)
		var is_crit: bool = entry.get("is_critical", false)

		lifetime -= delta
		entry["lifetime"] = lifetime

		if lifetime <= 0.0:
			_release_number(node)
			_active_numbers.remove_at(i)
			continue

		# Move
		node.position += velocity * delta

		# Gravity (slow down rise)
		velocity.y += 40.0 * delta
		entry["velocity"] = velocity

		# Scale down from initial pop
		if is_crit:
			var scale_t := minf(1.0, (LIFETIME - lifetime) / 0.15)
			node.scale = Vector2.ONE.lerp(Vector2(1.5, 1.5), 1.0 - scale_t)

		# Fade
		if lifetime < FADE_START:
			node.modulate.a = lifetime / FADE_START


func _release_number(node: Label) -> void:
	node.visible = false
	_pool.release(node)


func _is_reduced_motion() -> bool:
	if _settings_manager != null:
		return _settings_manager.reduced_motion
	return false


func _is_high_contrast() -> bool:
	if _settings_manager != null:
		return _settings_manager.high_contrast
	return false


func _is_large_text() -> bool:
	if _settings_manager != null:
		return _settings_manager.large_text
	return false


func clear() -> void:
	for entry in _active_numbers:
		if entry is Dictionary:
			var node = entry.get("node")
			if node != null and is_instance_valid(node):
				_release_number(node)
	_active_numbers.clear()


func get_active_count() -> int:
	return _active_numbers.size()
```

---

## Phase 2: Combat Juice (Enhanced)

### 2.1 Critical Hit System

**File**: `game/critical_effects.gd` (CREATE)

```gdscript
extends RefCounted
class_name CriticalEffects
## Orchestrates all critical hit effects in one place.

var _screen_shake = null
var _hit_pause = null
var _audio_manager = null
var _settings_manager = null


func _init() -> void:
	_cache_systems()


func _cache_systems() -> void:
	var tree = Engine.get_main_loop()
	if tree == null or tree.root == null:
		return
	_screen_shake = tree.root.get_node_or_null("/root/ScreenShake")
	_hit_pause = tree.root.get_node_or_null("/root/HitPause")
	_audio_manager = tree.root.get_node_or_null("/root/AudioManager")
	_settings_manager = tree.root.get_node_or_null("/root/SettingsManager")


func trigger_critical(
	hit_effects: HitEffects,
	damage_numbers: DamageNumbers,
	parent: Node,
	position: Vector2,
	damage_amount: int = 0
) -> void:
	"""Trigger all critical hit effects at once."""

	# 1. Hit Pause
	if _hit_pause != null:
		_hit_pause.pause_heavy()

	# 2. Screen Shake
	if _screen_shake != null:
		_screen_shake.shake_medium()

	# 3. Particles
	if hit_effects != null and parent != null:
		hit_effects.spawn_critical_hit(parent, position)

	# 4. Damage Number
	if damage_numbers != null and damage_amount > 0:
		damage_numbers.spawn_damage(position + Vector2(0, -20), damage_amount, true)

	# 5. Audio
	if _audio_manager != null:
		_audio_manager.play_sfx(_audio_manager.SFX.HIT_ENEMY, 1.2, 2.0)


func trigger_light_hit(
	hit_effects: HitEffects,
	damage_numbers: DamageNumbers,
	parent: Node,
	position: Vector2,
	damage_amount: int = 0
) -> void:
	"""Trigger standard hit effects."""

	# 1. Small shake
	if _screen_shake != null:
		_screen_shake.add_trauma(0.1)

	# 2. Particles
	if hit_effects != null and parent != null:
		hit_effects.spawn_hit_sparks(parent, position)

	# 3. Damage Number
	if damage_numbers != null and damage_amount > 0:
		damage_numbers.spawn_damage(position + Vector2(0, -15), damage_amount, false)

	# 4. Audio
	if _audio_manager != null:
		_audio_manager.play_sfx(_audio_manager.SFX.HIT_ENEMY)


func trigger_boss_hit(
	hit_effects: HitEffects,
	damage_numbers: DamageNumbers,
	parent: Node,
	position: Vector2,
	damage_amount: int = 0
) -> void:
	"""Extra dramatic effects for boss enemies."""

	# 1. Long pause
	if _hit_pause != null:
		_hit_pause.pause_extreme()

	# 2. Heavy shake
	if _screen_shake != null:
		_screen_shake.shake_heavy()

	# 3. Big particles
	if hit_effects != null and parent != null:
		hit_effects.spawn_power_burst(parent, position)
		hit_effects.spawn_critical_hit(parent, position)

	# 4. Big number
	if damage_numbers != null and damage_amount > 0:
		damage_numbers.spawn(position + Vector2(0, -30), damage_amount, "critical", true)
		damage_numbers.spawn_text(position + Vector2(0, -50), "BOSS HIT!", Color(1.0, 0.5, 0.2))

	# 5. Special audio
	if _audio_manager != null:
		_audio_manager.play_sfx(_audio_manager.SFX.HIT_ENEMY, 0.8, 3.0)
```

---

## Accessibility Matrix

All polish features should respect these settings:

| Feature | `screen_shake` | `reduced_motion` | `high_contrast` | `colorblind_mode` |
|---------|---------------|------------------|-----------------|-------------------|
| Screen Shake | Required ON | Reduces intensity | - | - |
| Hit Pause | Required ON | Reduces duration | - | - |
| Damage Numbers | - | Only criticals | White text | - |
| Particles | - | Fewer/shorter | Higher contrast | Adjusted colors |
| Combo Glow | - | Disabled | Solid colors | Pattern + color |
| Transitions | - | Instant | - | - |
| Letter Pop | - | Disabled | - | - |
| Word Shake | Required ON | Reduced | - | - |

### Colorblind Color Substitutions

```gdscript
const COLORBLIND_PALETTES := {
	"protanopia": {
		Color(1.0, 0.0, 0.0): Color(0.9, 0.6, 0.0),  # Red -> Orange
		Color(0.0, 1.0, 0.0): Color(0.0, 0.7, 1.0),  # Green -> Cyan
	},
	"deuteranopia": {
		Color(1.0, 0.0, 0.0): Color(0.9, 0.5, 0.0),  # Red -> Orange
		Color(0.0, 1.0, 0.0): Color(0.9, 0.9, 0.0),  # Green -> Yellow
	},
	"tritanopia": {
		Color(0.0, 0.0, 1.0): Color(0.0, 0.8, 0.8),  # Blue -> Cyan
		Color(1.0, 1.0, 0.0): Color(1.0, 0.6, 0.6),  # Yellow -> Pink
	}
}

static func adjust_color_for_colorblind(color: Color, mode: String) -> Color:
	if mode == "none" or not COLORBLIND_PALETTES.has(mode):
		return color

	var palette: Dictionary = COLORBLIND_PALETTES[mode]

	# Find closest match and substitute
	var closest_key: Color = Color.WHITE
	var closest_dist: float = INF

	for key in palette.keys():
		var dist := color.distance_to(key)
		if dist < closest_dist:
			closest_dist = dist
			closest_key = key

	if closest_dist < 0.5:  # Threshold for substitution
		return color.lerp(palette[closest_key], 0.7)

	return color
```

---

## Performance Considerations

### Object Pooling Requirements

| System | Pool Size | Max Size | Pre-warm |
|--------|-----------|----------|----------|
| Hit Particles | 100 | 200 | Yes |
| Damage Numbers | 20 | 50 | Yes |
| Trail Particles | 50 | 100 | No |
| Status Indicators | 10 | 20 | No |

### Update Frequency

| System | Update In | Condition |
|--------|-----------|-----------|
| Screen Shake | `_process` | When `trauma > 0` |
| Hit Pause | `_process` | When `_is_pausing` |
| Damage Numbers | `_process` | When `_active_numbers.size() > 0` |
| Particles | `_process` | When `_active_particles.size() > 0` |
| Status Indicators | `_process` | When `_active_indicators.size() > 0` |

### Early Exit Patterns

```gdscript
# Always check early exit conditions first
func _process(delta: float) -> void:
	if not _should_update():
		return
	# ... rest of update

func _should_update() -> bool:
	return _has_active_items() and is_visible_in_tree()
```

---

## File Summary

### New Files to Create

| File | Type | Lines | Priority |
|------|------|-------|----------|
| `game/screen_shake.gd` | Autoload | ~150 | P1 |
| `game/hit_pause.gd` | Autoload | ~120 | P1 |
| `game/damage_numbers.gd` | Class | ~200 | P1 |
| `game/scene_transition.gd` | Autoload | ~200 | P2 |
| `game/critical_effects.gd` | Class | ~100 | P2 |
| `game/status_indicators.gd` | Class | ~130 | P2 |
| `ui/panel_transitions.gd` | Static | ~170 | P3 |
| `ui/resource_popup.gd` | Class | ~120 | P3 |
| `ui/scene_entry.gd` | Static | ~60 | P3 |
| `game/ambient_audio.gd` | Class | ~90 | P4 |

### Files to Modify

| File | Changes | Lines Added |
|------|---------|-------------|
| `project.godot` | Add autoloads | +3 |
| `scripts/GameController.gd` | Use transitions | +30 |
| `scripts/Battlefield.gd` | Integration | +50 |
| `scripts/BattleStage.gd` | Combat effects | +80 |
| `game/audio_manager.gd` | New methods | +100 |
| `game/hit_effects.gd` | New effects | +80 |
| `data/audio/sfx_presets.json` | New presets | +60 |

---

## Implementation Order

### Week 1: Core Systems
1. ScreenShake autoload
2. HitPause autoload
3. DamageNumbers class
4. Integration into Battlefield.gd

### Week 2: Combat Polish
5. CriticalEffects orchestrator
6. StatusIndicators class
7. Enhanced HitEffects methods
8. BattleStage integration

### Week 3: UI Polish
9. SceneTransition autoload
10. PanelTransitions utility
11. ResourcePopup class
12. GameController integration

### Week 4: Audio & Art
13. New SFX presets
14. Adaptive music system
15. New SVG assets
16. Animation frames

---

## Quick Reference Card

### Triggering Effects

```gdscript
# Screen shake
var shake = get_node_or_null("/root/ScreenShake")
shake.shake_light()   # 0.2 trauma
shake.shake_medium()  # 0.4 trauma
shake.shake_heavy()   # 0.6 trauma
shake.add_trauma(0.3) # Custom amount

# Hit pause
var pause = get_node_or_null("/root/HitPause")
pause.pause_light()   # 0.05s
pause.pause_medium()  # 0.08s
pause.pause_heavy()   # 0.12s
pause.pause(0.1)      # Custom duration

# Scene transition
var trans = get_node_or_null("/root/SceneTransition")
trans.transition_to_scene("res://scenes/X.tscn", trans.TransitionType.FADE, 0.4)

# Damage numbers
damage_numbers.spawn_damage(pos, 50, true)  # Critical
damage_numbers.spawn_gold(pos, 100)
damage_numbers.spawn_combo(pos, 15)
```

### Checking Settings

```gdscript
var settings = get_node_or_null("/root/SettingsManager")
if settings != null:
	if settings.screen_shake:  # Shake enabled
	if settings.reduced_motion: # Reduce animations
	if settings.high_contrast:  # Use high contrast colors
	if settings.colorblind_mode != "none":  # Adjust colors
```
