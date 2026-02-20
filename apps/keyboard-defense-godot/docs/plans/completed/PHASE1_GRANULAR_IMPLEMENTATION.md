# Phase 1: Core Polish - Granular Implementation Guide

## Overview

This document breaks Phase 1 into micro-tasks of 15-30 minutes each. Every task includes:
- Exact file paths
- Line numbers for modifications
- Complete code blocks
- Before/after comparisons
- Verification steps

---

## Task 1.1: Create Screen Shake System

**Time**: 20 minutes
**File to create**: `game/screen_shake.gd`

### Step 1.1.1: Create the file

**Action**: Create new file `game/screen_shake.gd`

**Complete file contents** (copy exactly):

```gdscript
class_name ScreenShake
extends Node
## Screen shake system using noise-based trauma.
## Add as autoload named "ScreenShake" for global access.

signal intensity_changed(new_intensity: float)

## Current trauma (0-1)
var trauma: float = 0.0

## Decay rate per second
var decay_rate: float = 0.8

## Maximum offset in pixels
var max_offset: Vector2 = Vector2(16.0, 12.0)

## Maximum rotation in radians
var max_rotation: float = 0.03

## Noise generator
var _noise: FastNoiseLite = null

## Target camera
var _camera: Camera2D = null

## Original camera offset
var _original_offset: Vector2 = Vector2.ZERO

## Noise sample position
var _noise_y: float = 0.0

## Enable/disable (for accessibility)
var enabled: bool = true


func _ready() -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = randi()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 2.0

	# Try to auto-find camera
	await get_tree().process_frame
	var viewport := get_viewport()
	if viewport:
		_camera = viewport.get_camera_2d()
		if _camera:
			_original_offset = _camera.offset


func set_camera(camera: Camera2D) -> void:
	_camera = camera
	if _camera:
		_original_offset = _camera.offset


func add_trauma(amount: float) -> void:
	if not enabled:
		return
	trauma = clampf(trauma + amount, 0.0, 1.0)
	intensity_changed.emit(trauma)


func _process(delta: float) -> void:
	if not enabled or _camera == null or trauma <= 0.0:
		return

	# Decay
	trauma = maxf(trauma - decay_rate * delta, 0.0)

	# Quadratic for better feel
	var shake := trauma * trauma

	# Sample noise
	_noise_y += delta * 50.0
	var nx := _noise.get_noise_2d(_noise_y, 0.0)
	var ny := _noise.get_noise_2d(0.0, _noise_y)
	var nr := _noise.get_noise_2d(_noise_y, _noise_y)

	# Apply
	_camera.offset = _original_offset + Vector2(
		nx * max_offset.x * shake,
		ny * max_offset.y * shake
	)
	_camera.rotation = nr * max_rotation * shake

	# Reset when done
	if trauma <= 0.0:
		_camera.offset = _original_offset
		_camera.rotation = 0.0


# ============================================================================
# PRESET AMOUNTS - Call these from game code
# ============================================================================

## Typing feedback - barely perceptible
func shake_typing() -> void:
	add_trauma(0.02)

## Word complete - subtle satisfaction
func shake_word_complete() -> void:
	add_trauma(0.04)

## Enemy death - small impact
func shake_enemy_death() -> void:
	add_trauma(0.06)

## Critical hit - noticeable
func shake_critical() -> void:
	add_trauma(0.12)

## Castle damage - significant
func shake_castle_damage() -> void:
	add_trauma(0.25)

## Boss spawn - dramatic
func shake_boss_spawn() -> void:
	add_trauma(0.4)

## Wave complete - celebration
func shake_wave_complete() -> void:
	add_trauma(0.2)

## Game over - heavy
func shake_game_over() -> void:
	add_trauma(0.5)
```

### Step 1.1.2: Register as autoload

**Action**: Open Project Settings

1. Go to `Project > Project Settings > Globals` tab
2. In the "Autoload" section at bottom:
   - Path: `res://game/screen_shake.gd`
   - Node Name: `ScreenShake`
   - Click "Add"

### Step 1.1.3: Verify

**Run test**:
```bash
godot --headless --path . --script res://tests/run_tests.gd
```

**Expected**: Tests pass (no errors from new file)

---

## Task 1.2: Wire Screen Shake to Battlefield

**Time**: 15 minutes
**File to modify**: `scripts/Battlefield.gd`

### Step 1.2.1: Add screen shake reference

**Location**: Line 74 (after other @onready vars)

**Find this line**:
```gdscript
@onready var audio_manager = get_node_or_null("/root/AudioManager")
```

**Add AFTER it** (new line 75):
```gdscript
@onready var screen_shake = get_node_or_null("/root/ScreenShake")
```

### Step 1.2.2: Add shake to word completion

**Location**: Find the function that handles word completion

**Search for**: `play_word_complete` or `word_complete`

**In the word completion handler, add**:
```gdscript
# After audio plays
if screen_shake:
	screen_shake.shake_word_complete()
```

### Step 1.2.3: Add shake to castle damage

**Location**: Find where `castle_health` is decremented

**Search for**: `castle_health -=` or `castle_health = castle_health - 1`

**Add after the health decrease**:
```gdscript
if screen_shake:
	screen_shake.shake_castle_damage()
```

### Step 1.2.4: Verify

**Test manually**:
1. Run game: `godot --path .`
2. Start a battle
3. Complete a word - should see subtle shake
4. Let castle take damage - should see larger shake

---

## Task 1.3: Create Hit Pause System

**Time**: 15 minutes
**File to create**: `game/hit_pause.gd`

### Step 1.3.1: Create the file

**Complete file contents**:

```gdscript
class_name HitPause
extends Node
## Hit pause / freeze frame system.
## Add as autoload named "HitPause" for global access.

## Whether hit pause is enabled (accessibility)
var enabled: bool = true

## Current pause timer
var _timer: float = 0.0

## Is currently paused
var _paused: bool = false

## Original time scale
var _original_scale: float = 1.0

## Cooldown between pauses
var _cooldown: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta

	if _paused and _timer > 0.0:
		_timer -= delta
		if _timer <= 0.0:
			_end_pause()


func pause_ms(duration_ms: float) -> void:
	if not enabled:
		return
	if _cooldown > 0.0:
		return
	if duration_ms <= 0.0:
		return

	_timer = duration_ms / 1000.0
	_paused = true
	_original_scale = Engine.time_scale
	Engine.time_scale = 0.0001
	_cooldown = 0.05


func _end_pause() -> void:
	_paused = false
	Engine.time_scale = _original_scale


# ============================================================================
# PRESET DURATIONS - Call these from game code
# ============================================================================

## Word complete - micro pause (30ms)
func pause_word_complete() -> void:
	pause_ms(30)

## Perfect word - slightly longer (50ms)
func pause_word_perfect() -> void:
	pause_ms(50)

## Enemy death - quick snap (25ms)
func pause_enemy_death() -> void:
	pause_ms(25)

## Critical hit - noticeable (45ms)
func pause_critical() -> void:
	pause_ms(45)

## Elite death - satisfying (60ms)
func pause_elite_death() -> void:
	pause_ms(60)

## Boss hit - weighty (70ms)
func pause_boss_hit() -> void:
	pause_ms(70)

## Boss death - dramatic (180ms)
func pause_boss_death() -> void:
	pause_ms(180)

## Castle damage - alert (100ms)
func pause_castle_damage() -> void:
	pause_ms(100)

## Combo milestone - beat (40ms)
func pause_combo_milestone() -> void:
	pause_ms(40)
```

### Step 1.3.2: Register as autoload

1. Project > Project Settings > Globals > Autoload
2. Add:
   - Path: `res://game/hit_pause.gd`
   - Node Name: `HitPause`

---

## Task 1.4: Wire Hit Pause to Battlefield

**Time**: 10 minutes
**File to modify**: `scripts/Battlefield.gd`

### Step 1.4.1: Add reference

**Location**: After the screen_shake @onready (line 75)

**Add**:
```gdscript
@onready var hit_pause = get_node_or_null("/root/HitPause")
```

### Step 1.4.2: Add to word completion

**Location**: Same place as screen shake (word completion handler)

**Add**:
```gdscript
if hit_pause:
	hit_pause.pause_word_complete()
```

### Step 1.4.3: Add to castle damage

**Location**: Same place as screen shake (castle damage handler)

**Add**:
```gdscript
if hit_pause:
	hit_pause.pause_castle_damage()
```

---

## Task 1.5: Create Damage Numbers System

**Time**: 30 minutes
**File to create**: `game/damage_numbers.gd`

### Step 1.5.1: Create the file

**Complete file contents**:

```gdscript
class_name DamageNumbers
extends Node2D
## Floating damage numbers with object pooling.

const ObjectPool = preload("res://game/object_pool.gd")

enum Type { DAMAGE, CRITICAL, HEAL, GOLD, COMBO, BLOCK }

const STYLES := {
	Type.DAMAGE: {"color": Color.WHITE, "size": 16, "rise": 60},
	Type.CRITICAL: {"color": Color(1.0, 0.85, 0.2), "size": 24, "rise": 80},
	Type.HEAL: {"color": Color(0.2, 0.9, 0.3), "size": 16, "rise": 50},
	Type.GOLD: {"color": Color(1.0, 0.85, 0.2), "size": 16, "rise": 45},
	Type.COMBO: {"color": Color(0.4, 0.9, 1.0), "size": 20, "rise": 70},
	Type.BLOCK: {"color": Color(0.6, 0.6, 0.6), "size": 14, "rise": 30}
}

var _active: Array = []
var _pool: ObjectPool = null
const MAX_ACTIVE := 50
const DURATION := 0.8


func _ready() -> void:
	_pool = ObjectPool.new(_create_label, _reset_label, MAX_ACTIVE * 2)
	_pool.set_parent(self)
	_pool.prewarm(20)


func _create_label() -> Label:
	var lbl := Label.new()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.visible = false
	return lbl


func _reset_label(lbl: Label) -> void:
	lbl.modulate = Color.WHITE
	lbl.scale = Vector2.ONE
	lbl.text = ""


func spawn(pos: Vector2, value, type: Type = Type.DAMAGE) -> void:
	if _active.size() >= MAX_ACTIVE:
		_remove(0)

	var lbl: Label = _pool.acquire()
	if lbl == null:
		return

	var style: Dictionary = STYLES.get(type, STYLES[Type.DAMAGE])

	# Format text
	var txt: String
	if type == Type.GOLD:
		txt = "+%d" % int(value)
	elif type == Type.HEAL:
		txt = "+%d" % int(value)
	elif type == Type.COMBO:
		txt = "%dx" % int(value)
	elif type == Type.BLOCK:
		txt = "BLOCK"
	else:
		txt = str(int(value))

	lbl.text = txt
	lbl.add_theme_font_size_override("font_size", style.size)
	lbl.add_theme_color_override("font_color", style.color)
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))

	# Position with jitter
	lbl.position = pos + Vector2(randf_range(-8, 8), randf_range(-4, 4))
	lbl.scale = Vector2.ZERO
	lbl.visible = true

	_active.append({
		"label": lbl,
		"time": 0.0,
		"rise": style.rise,
		"is_critical": type == Type.CRITICAL
	})


func _process(delta: float) -> void:
	for i in range(_active.size() - 1, -1, -1):
		var d: Dictionary = _active[i]
		var lbl: Label = d.label

		if not is_instance_valid(lbl):
			_active.remove_at(i)
			continue

		d.time += delta
		var progress: float = d.time / DURATION

		if progress >= 1.0:
			_remove(i)
			continue

		# Pop in (0-10%)
		if progress < 0.1:
			lbl.scale = Vector2.ONE * 1.3 * (progress / 0.1)
		# Settle (10-20%)
		elif progress < 0.2:
			var t := (progress - 0.1) / 0.1
			lbl.scale = Vector2.ONE * lerpf(1.3, 1.0, t)
		else:
			lbl.scale = Vector2.ONE

		# Rise
		lbl.position.y -= d.rise * delta

		# Shake for critical
		if d.is_critical and progress < 0.5:
			lbl.position.x += randf_range(-1.5, 1.5)

		# Fade (last 30%)
		if progress > 0.7:
			lbl.modulate.a = 1.0 - ((progress - 0.7) / 0.3)


func _remove(idx: int) -> void:
	if idx < 0 or idx >= _active.size():
		return
	var d: Dictionary = _active[idx]
	var lbl: Label = d.label
	if is_instance_valid(lbl):
		lbl.visible = false
		_pool.release(lbl)
	_active.remove_at(idx)


func clear() -> void:
	for i in range(_active.size() - 1, -1, -1):
		_remove(i)


# ============================================================================
# CONVENIENCE METHODS
# ============================================================================

func damage(pos: Vector2, amount: int) -> void:
	spawn(pos, amount, Type.DAMAGE)

func critical(pos: Vector2, amount: int) -> void:
	spawn(pos, amount, Type.CRITICAL)

func heal(pos: Vector2, amount: int) -> void:
	spawn(pos, amount, Type.HEAL)

func gold(pos: Vector2, amount: int) -> void:
	spawn(pos, amount, Type.GOLD)

func combo(pos: Vector2, multiplier: int) -> void:
	spawn(pos, multiplier, Type.COMBO)

func block(pos: Vector2) -> void:
	spawn(pos, 0, Type.BLOCK)
```

---

## Task 1.6: Add Damage Numbers to Battlefield

**Time**: 15 minutes
**File to modify**: `scripts/Battlefield.gd`

### Step 1.6.1: Add member variable

**Location**: Around line 149 (with other var declarations)

**Find**:
```gdscript
var _shake_intensity: float = 0.0
```

**Add after**:
```gdscript
var _damage_numbers: DamageNumbers = null
```

### Step 1.6.2: Initialize in _ready()

**Location**: In the `_ready()` function

**Add** (near the end of _ready, before any await):
```gdscript
# Setup damage numbers
_damage_numbers = DamageNumbers.new()
add_child(_damage_numbers)
```

### Step 1.6.3: Use when dealing damage

**Location**: Find where enemies take damage

**Add when enemy is hit**:
```gdscript
if _damage_numbers:
	var screen_pos = _get_enemy_screen_position(enemy)  # You'll need to implement this
	_damage_numbers.damage(screen_pos, damage_amount)
```

---

## Task 1.7: Add New Sound Enum Values

**Time**: 10 minutes
**File to modify**: `game/audio_manager.gd`

### Step 1.7.1: Add to SFX enum

**Location**: Lines 21-58 (the SFX enum)

**Find the end of the enum** (after `WORD_COMPLETE`):
```gdscript
	WORD_COMPLETE
}
```

**Change to**:
```gdscript
	WORD_COMPLETE,
	# New sounds
	TYPE_SPACE,
	TYPE_BACKSPACE,
	TYPE_ENTER,
	TYPE_TARGET_LOCK,
	WORD_PERFECT,
	ENEMY_GRUNT_HIT,
	ENEMY_GRUNT_DEATH,
	ENEMY_ELITE_ROAR,
	COMBO_2X,
	COMBO_3X,
	COMBO_4X,
	COMBO_5X
}
```

### Step 1.7.2: Add to _sfx_files mapping

**Location**: Lines 71-108 (the _sfx_files dictionary)

**Find the end** (after `SFX.WORD_COMPLETE`):
```gdscript
	SFX.WORD_COMPLETE: "combo_up.wav"  # Reuse combo_up with slight pitch variation
}
```

**Change to** (note: these will reuse existing sounds with pitch shift until we create proper files):
```gdscript
	SFX.WORD_COMPLETE: "combo_up.wav",
	# New sound mappings (reuse with pitch shift for now)
	SFX.TYPE_SPACE: "ui_keytap.wav",
	SFX.TYPE_BACKSPACE: "ui_cancel.wav",
	SFX.TYPE_ENTER: "ui_confirm.wav",
	SFX.TYPE_TARGET_LOCK: "combo_up.wav",
	SFX.WORD_PERFECT: "combo_up.wav",
	SFX.ENEMY_GRUNT_HIT: "hit_enemy.wav",
	SFX.ENEMY_GRUNT_DEATH: "hit_enemy.wav",
	SFX.ENEMY_ELITE_ROAR: "boss_appear.wav",
	SFX.COMBO_2X: "combo_up.wav",
	SFX.COMBO_3X: "combo_up.wav",
	SFX.COMBO_4X: "combo_up.wav",
	SFX.COMBO_5X: "level_up.wav"
}
```

### Step 1.7.3: Add convenience methods

**Location**: At end of file (after line 569)

**Add**:
```gdscript

## New sound convenience methods
func play_type_space() -> void:
	play_sfx_pitched(SFX.TYPE_SPACE, 0.9, -4.0)

func play_type_backspace() -> void:
	play_sfx_pitched(SFX.TYPE_BACKSPACE, 1.2, -6.0)

func play_type_enter() -> void:
	play_sfx(SFX.TYPE_ENTER)

func play_type_target_lock() -> void:
	play_sfx_pitched(SFX.TYPE_TARGET_LOCK, 1.3, -2.0)

func play_word_perfect() -> void:
	play_sfx_pitched(SFX.WORD_PERFECT, 1.25, 0.0)

func play_enemy_grunt_hit() -> void:
	play_sfx_pitched(SFX.ENEMY_GRUNT_HIT, randf_range(0.9, 1.1), -4.0)

func play_enemy_grunt_death() -> void:
	play_sfx_pitched(SFX.ENEMY_GRUNT_DEATH, 0.8, -2.0)

func play_enemy_elite_roar() -> void:
	play_sfx_pitched(SFX.ENEMY_ELITE_ROAR, 0.7, 2.0)

func play_combo_2x() -> void:
	play_sfx_pitched(SFX.COMBO_2X, 1.1, 0.0)

func play_combo_3x() -> void:
	play_sfx_pitched(SFX.COMBO_3X, 1.2, 0.0)

func play_combo_4x() -> void:
	play_sfx_pitched(SFX.COMBO_4X, 1.3, 2.0)

func play_combo_5x() -> void:
	play_sfx(SFX.COMBO_5X, 2.0)
```

---

## Task 1.8: Add Input Flash to Typing Display

**Time**: 20 minutes
**File to modify**: `ui/components/typing_display.gd` (or equivalent)

### Step 1.8.1: Add flash method

**Location**: Add to the typing display class

```gdscript
## Flash a character position for correct input
func _flash_correct(char_rect: Rect2) -> void:
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.5)
	flash.size = char_rect.size
	flash.position = char_rect.position
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)

	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.12)
	tween.tween_callback(flash.queue_free)


## Flash and shake for error
func _flash_error(char_rect: Rect2) -> void:
	var flash := ColorRect.new()
	flash.color = Color(1, 0.2, 0.2, 0.5)
	flash.size = char_rect.size
	flash.position = char_rect.position
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)

	# Store original for shake
	var orig_x := char_rect.position.x

	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.15)
	tween.tween_callback(flash.queue_free)
```

### Step 1.8.2: Call on input

**Location**: Where correct/incorrect input is processed

**For correct input, add**:
```gdscript
_flash_correct(character_rect)  # Pass the rect of the typed character
```

**For incorrect input, add**:
```gdscript
_flash_error(character_rect)
```

---

## Verification Checklist for Phase 1

### After Task 1.1-1.2 (Screen Shake):
- [ ] `game/screen_shake.gd` exists
- [ ] Autoload registered as "ScreenShake"
- [ ] Complete a word → subtle shake
- [ ] Castle damage → larger shake
- [ ] Tests pass

### After Task 1.3-1.4 (Hit Pause):
- [ ] `game/hit_pause.gd` exists
- [ ] Autoload registered as "HitPause"
- [ ] Complete a word → micro-pause (feel the "snap")
- [ ] Castle damage → longer pause
- [ ] Input still works during pause
- [ ] Tests pass

### After Task 1.5-1.6 (Damage Numbers):
- [ ] `game/damage_numbers.gd` exists
- [ ] Numbers appear when damage dealt
- [ ] Numbers float up and fade
- [ ] No lag with many numbers
- [ ] Tests pass

### After Task 1.7 (Audio):
- [ ] New enum values compile without error
- [ ] New sounds play (even if reusing existing files)
- [ ] Tests pass

### After Task 1.8 (Input Flash):
- [ ] Correct input → white flash
- [ ] Incorrect input → red flash
- [ ] Tests pass

---

## Quick Reference: All New Files

| File | Size | Purpose |
|------|------|---------|
| `game/screen_shake.gd` | ~100 lines | Camera shake system |
| `game/hit_pause.gd` | ~70 lines | Freeze frame system |
| `game/damage_numbers.gd` | ~150 lines | Floating numbers |

## Quick Reference: Modified Files

| File | Lines Changed | Changes |
|------|---------------|---------|
| `scripts/Battlefield.gd` | +10-15 lines | Wire up polish systems |
| `game/audio_manager.gd` | +40 lines | New sound enum/methods |

---

## Commands to Run After Each Task

```bash
# Verify tests pass
godot --headless --path . --script res://tests/run_tests.gd

# Manual test (opens game)
godot --path .

# Check for syntax errors only (fast)
godot --headless --path . --quit
```
