# Phase 2: Combat Juice - Granular Implementation Guide

## Overview

This document breaks Phase 2 (Combat Juice) into micro-tasks. Each task includes:
- Exact file paths
- Line numbers for modifications
- Complete code blocks
- Before/after comparisons
- Verification steps

**Prerequisite**: Phase 1 screen shake and hit pause systems should be in place.

---

## Task 2.1: Add Critical Hit Visual Effects

**Time**: 20 minutes
**Files to modify**: `scripts/BattleStage.gd`, `game/hit_effects.gd`

### Step 2.1.1: Add critical hit particles to HitEffects

**File**: `game/hit_effects.gd`
**Action**: Add new method after `spawn_power_burst()` (around line 102)

**Add this method**:

```gdscript
func spawn_critical_hit(parent: Node, position: Vector2) -> void:
	_ensure_parent(parent)

	# Spawn expanding ring effect (8 particles in circle)
	for i in range(8):
		var particle: ColorRect = _particle_pool.acquire()
		if particle == null:
			continue

		particle.size = SPARK_SIZE * 2.0
		particle.color = Color(1.0, 0.2, 0.1, 1.0)  # Red-orange
		particle.position = position - particle.size * 0.5
		particle.visible = true

		if particle.get_parent() == null:
			parent.add_child(particle)

		var angle := (float(i) / 8.0) * TAU
		var speed := PARTICLE_SPEED * 2.0
		var velocity := Vector2(cos(angle), sin(angle)) * speed

		_active_particles.append({
			"node": particle,
			"velocity": velocity,
			"lifetime": PARTICLE_LIFETIME * 0.6,
			"fade_start": PARTICLE_LIFETIME * 0.3,
			"no_gravity": true
		})

	# Spawn secondary burst (golden sparks)
	for i in range(12):
		var particle: ColorRect = _particle_pool.acquire()
		if particle == null:
			continue

		particle.size = PARTICLE_SIZE if i % 2 == 0 else SPARK_SIZE
		particle.color = Color(1.0, 0.85, 0.3, 1.0)  # Gold
		particle.position = position - particle.size * 0.5
		particle.visible = true

		if particle.get_parent() == null:
			parent.add_child(particle)

		var angle := randf() * TAU
		var speed := PARTICLE_SPEED * 1.8 * (0.6 + randf() * 0.4)
		var velocity := Vector2(cos(angle), sin(angle)) * speed

		_active_particles.append({
			"node": particle,
			"velocity": velocity,
			"lifetime": PARTICLE_LIFETIME * 0.8,
			"fade_start": PARTICLE_LIFETIME * 0.4,
			"no_gravity": false
		})
```

### Step 2.1.2: Add critical hit spawn to BattleStage

**File**: `scripts/BattleStage.gd`
**Action**: Modify `_spawn_hit_effect()` method (around line 286)

**Before** (lines 286-294):
```gdscript
func _spawn_hit_effect(hit_position: Vector2, is_power_shot: bool) -> void:
	if hit_effects == null or projectile_layer == null:
		return
	if is_power_shot:
		hit_effects.spawn_power_burst(projectile_layer, hit_position)
		_spawn_damage_number(hit_position, "POWER!", true)
	else:
		hit_effects.spawn_hit_sparks(projectile_layer, hit_position)
		_spawn_damage_number(hit_position, "HIT", false)
```

**After**:
```gdscript
func _spawn_hit_effect(hit_position: Vector2, is_power_shot: bool, is_critical: bool = false) -> void:
	if hit_effects == null or projectile_layer == null:
		return
	if is_critical:
		hit_effects.spawn_critical_hit(projectile_layer, hit_position)
		_spawn_damage_number(hit_position, "CRITICAL!", true)
		# Trigger screen shake for critical hits
		var screen_shake = get_node_or_null("/root/ScreenShake")
		if screen_shake != null:
			screen_shake.add_trauma(0.4)
	elif is_power_shot:
		hit_effects.spawn_power_burst(projectile_layer, hit_position)
		_spawn_damage_number(hit_position, "POWER!", true)
	else:
		hit_effects.spawn_hit_sparks(projectile_layer, hit_position)
		_spawn_damage_number(hit_position, "HIT", false)
```

### Step 2.1.3: Update projectile hit detection for criticals

**File**: `scripts/BattleStage.gd`
**Action**: Modify projectile collision in `_update_projectiles()` (around line 250)

**Before** (lines 250-255):
```gdscript
		if enemy != null and node.position.x >= enemy.position.x:
			var hit_pos: Vector2 = node.position
			node.queue_free()
			projectiles.remove_at(i)
			_flash_enemy()
			_spawn_hit_effect(hit_pos, is_power)
```

**After**:
```gdscript
		if enemy != null and node.position.x >= enemy.position.x:
			var hit_pos: Vector2 = node.position
			var is_critical: bool = entry.get("critical", false)
			node.queue_free()
			projectiles.remove_at(i)
			_flash_enemy()
			_spawn_hit_effect(hit_pos, is_power, is_critical)
```

### Step 2.1.4: Add critical flag to spawn_projectile

**File**: `scripts/BattleStage.gd`
**Action**: Modify `spawn_projectile()` signature (around line 148)

**Before** (line 148):
```gdscript
func spawn_projectile(power_shot: bool = false) -> void:
```

**After**:
```gdscript
func spawn_projectile(power_shot: bool = false, critical_shot: bool = false) -> void:
```

**And update the projectile dictionary** (around line 170):

**Before**:
```gdscript
	projectiles.append({
		"node": shot,
		"velocity": Vector2(PROJECTILE_SPEED, 0.0),
		"power": power_shot,
		"trail_timer": 0.0,
		"rotation": 0.0
	})
```

**After**:
```gdscript
	projectiles.append({
		"node": shot,
		"velocity": Vector2(PROJECTILE_SPEED * (1.2 if critical_shot else 1.0), 0.0),
		"power": power_shot,
		"critical": critical_shot,
		"trail_timer": 0.0,
		"rotation": 0.0
	})
```

### Verification:
1. Run `godot --headless --path . --script res://tests/run_tests.gd`
2. Start a battle and observe that critical hits show expanded particle ring
3. Critical damage numbers show "CRITICAL!" text
4. Screen shakes on critical hits

---

## Task 2.2: Add Enemy Death Animation

**Time**: 25 minutes
**Files to modify**: `scripts/BattleStage.gd`, `game/hit_effects.gd`

### Step 2.2.1: Add death explosion particles

**File**: `game/hit_effects.gd`
**Action**: Add new method after `spawn_critical_hit()`

**Add this method**:

```gdscript
func spawn_enemy_death(parent: Node, position: Vector2, enemy_color: Color = Color(0.8, 0.2, 0.2)) -> void:
	_ensure_parent(parent)

	# Large explosion burst - 16 particles outward
	for i in range(16):
		var particle: ColorRect = _particle_pool.acquire()
		if particle == null:
			continue

		var base_size := SPARK_SIZE if i % 3 == 0 else PARTICLE_SIZE
		particle.size = base_size * (1.5 + randf() * 0.5)

		# Mix enemy color with orange/yellow for fire effect
		var t := float(i) / 16.0
		var fire_color := Color(1.0, 0.6, 0.2, 1.0)
		particle.color = enemy_color.lerp(fire_color, t * 0.6 + randf() * 0.3)
		particle.position = position - particle.size * 0.5
		particle.visible = true

		if particle.get_parent() == null:
			parent.add_child(particle)

		var angle := randf() * TAU
		var speed := PARTICLE_SPEED * 2.2 * (0.5 + randf() * 0.5)
		var velocity := Vector2(cos(angle), sin(angle)) * speed

		_active_particles.append({
			"node": particle,
			"velocity": velocity,
			"lifetime": PARTICLE_LIFETIME * 1.3,
			"fade_start": PARTICLE_LIFETIME * 0.5,
			"no_gravity": false
		})

	# Smoke particles - rise upward
	for i in range(6):
		var particle: ColorRect = _particle_pool.acquire()
		if particle == null:
			continue

		particle.size = PARTICLE_SIZE * 2.5
		particle.color = Color(0.3, 0.3, 0.3, 0.6)  # Gray smoke
		particle.position = position - particle.size * 0.5 + Vector2(randf_range(-12, 12), 0)
		particle.visible = true

		if particle.get_parent() == null:
			parent.add_child(particle)

		var velocity := Vector2(randf_range(-20, 20), -60 - randf() * 30)

		_active_particles.append({
			"node": particle,
			"velocity": velocity,
			"lifetime": PARTICLE_LIFETIME * 2.0,
			"fade_start": PARTICLE_LIFETIME * 1.0,
			"no_gravity": true
		})
```

### Step 2.2.2: Add death effect trigger to BattleStage

**File**: `scripts/BattleStage.gd`
**Action**: Add new public method after `spawn_castle_damage_effect()` (around line 310)

**Add this method**:

```gdscript
func spawn_enemy_death_effect() -> void:
	if hit_effects == null or projectile_layer == null or enemy == null:
		return

	var death_pos := enemy.position

	# Get enemy color based on type for tinted death particles
	var enemy_color := _get_enemy_color(current_enemy_kind)

	# Spawn death particles
	hit_effects.spawn_enemy_death(projectile_layer, death_pos, enemy_color)

	# Spawn "DEFEATED!" text
	_spawn_damage_number(death_pos + Vector2(0, -20), "DEFEATED!", true)

	# Trigger screen shake
	var screen_shake = get_node_or_null("/root/ScreenShake")
	if screen_shake != null:
		screen_shake.add_trauma(0.35)

	# Play death sound
	if audio_manager != null:
		audio_manager.play_sfx(audio_manager.SFX.HIT_ENEMY)


func _get_enemy_color(kind: String) -> Color:
	match kind:
		"runner":
			return Color(0.8, 0.3, 0.3)  # Red
		"tank":
			return Color(0.5, 0.5, 0.6)  # Gray-blue
		"fast":
			return Color(0.3, 0.8, 0.4)  # Green
		"boss_fen_seer", "boss_fen_knight", "boss_fen_queen":
			return Color(0.6, 0.2, 0.8)  # Purple for bosses
		_:
			return Color(0.8, 0.2, 0.2)  # Default red
```

### Verification:
1. Call `battle_stage.spawn_enemy_death_effect()` when enemy is defeated
2. Observe 16+ particles exploding outward
3. Smoke particles rise
4. "DEFEATED!" text appears
5. Screen shakes

---

## Task 2.3: Add Status Effect Indicators

**Time**: 30 minutes
**File to create**: `game/status_indicators.gd`

### Step 2.3.1: Create the status indicator system

**Action**: Create new file `game/status_indicators.gd`

**Complete file contents**:

```gdscript
class_name StatusIndicators
extends RefCounted
## Visual indicators for status effects on enemies/towers.

const INDICATOR_SIZE := Vector2(8, 8)
const INDICATOR_OFFSET := Vector2(0, -24)  # Above sprite
const INDICATOR_SPACING := 10.0
const PULSE_SPEED := 3.0
const ICON_SCALE := 1.5

# Status effect colors
const STATUS_COLORS := {
	"burn": Color(1.0, 0.4, 0.1, 1.0),      # Orange-red
	"slow": Color(0.3, 0.7, 1.0, 1.0),      # Ice blue
	"poison": Color(0.4, 0.9, 0.3, 1.0),    # Green
	"shield": Color(0.9, 0.85, 0.2, 1.0),   # Gold
	"stun": Color(1.0, 1.0, 0.3, 1.0),      # Yellow
	"weaken": Color(0.6, 0.3, 0.6, 1.0),    # Purple
	"haste": Color(0.3, 1.0, 0.6, 1.0),     # Cyan-green
	"armor": Color(0.6, 0.6, 0.7, 1.0),     # Steel gray
}

var _active_indicators: Array = []
var _time: float = 0.0


func update(delta: float) -> void:
	_time += delta

	for i in range(_active_indicators.size() - 1, -1, -1):
		var indicator = _active_indicators[i]
		if not indicator is Dictionary:
			_active_indicators.remove_at(i)
			continue

		var node = indicator.get("node")
		if node == null or not is_instance_valid(node):
			_active_indicators.remove_at(i)
			continue

		var duration: float = indicator.get("duration", 0.0)
		var elapsed: float = indicator.get("elapsed", 0.0)

		elapsed += delta
		indicator["elapsed"] = elapsed

		# Remove expired indicators
		if duration > 0.0 and elapsed >= duration:
			node.queue_free()
			_active_indicators.remove_at(i)
			continue

		# Pulse effect
		var pulse := sin(_time * PULSE_SPEED + indicator.get("phase", 0.0)) * 0.15 + 0.85
		node.modulate.a = pulse

		# Scale pulse for low duration
		if duration > 0.0:
			var remaining := duration - elapsed
			if remaining < 1.0:
				node.scale = Vector2.ONE * ICON_SCALE * (0.5 + remaining * 0.5)


func add_indicator(parent: Node, target: Node2D, status_type: String, duration: float = -1.0) -> void:
	if parent == null or target == null:
		return

	var color: Color = STATUS_COLORS.get(status_type, Color.WHITE)

	# Create indicator visual
	var indicator := ColorRect.new()
	indicator.size = INDICATOR_SIZE
	indicator.color = color

	# Position above target
	var existing_count := _count_indicators_for_target(target)
	var offset_x := (existing_count - 0.5) * INDICATOR_SPACING
	indicator.position = target.position + INDICATOR_OFFSET + Vector2(offset_x, 0)
	indicator.scale = Vector2.ONE * ICON_SCALE
	indicator.pivot_offset = INDICATOR_SIZE * 0.5

	parent.add_child(indicator)

	_active_indicators.append({
		"node": indicator,
		"target": target,
		"status": status_type,
		"duration": duration,
		"elapsed": 0.0,
		"phase": randf() * TAU  # Random pulse phase
	})


func remove_indicator(target: Node2D, status_type: String) -> void:
	for i in range(_active_indicators.size() - 1, -1, -1):
		var indicator = _active_indicators[i]
		if not indicator is Dictionary:
			continue
		if indicator.get("target") == target and indicator.get("status") == status_type:
			var node = indicator.get("node")
			if node != null and is_instance_valid(node):
				node.queue_free()
			_active_indicators.remove_at(i)
			break


func remove_all_for_target(target: Node2D) -> void:
	for i in range(_active_indicators.size() - 1, -1, -1):
		var indicator = _active_indicators[i]
		if not indicator is Dictionary:
			continue
		if indicator.get("target") == target:
			var node = indicator.get("node")
			if node != null and is_instance_valid(node):
				node.queue_free()
			_active_indicators.remove_at(i)


func _count_indicators_for_target(target: Node2D) -> int:
	var count := 0
	for indicator in _active_indicators:
		if indicator is Dictionary and indicator.get("target") == target:
			count += 1
	return count


func clear() -> void:
	for indicator in _active_indicators:
		if indicator is Dictionary:
			var node = indicator.get("node")
			if node != null and is_instance_valid(node):
				node.queue_free()
	_active_indicators.clear()
```

### Step 2.3.2: Integrate status indicators into BattleStage

**File**: `scripts/BattleStage.gd`
**Action**: Add preload and initialization

**Add at top of file** (after line 4):
```gdscript
const StatusIndicators = preload("res://game/status_indicators.gd")
```

**Add to class variables** (around line 42):
```gdscript
var status_indicators: StatusIndicators
```

**Modify `_ready()`** (around line 48-51):

**Before**:
```gdscript
func _ready() -> void:
	asset_loader = AssetLoader.new()
	asset_loader._load_manifest()
	hit_effects = HitEffects.new()
```

**After**:
```gdscript
func _ready() -> void:
	asset_loader = AssetLoader.new()
	asset_loader._load_manifest()
	hit_effects = HitEffects.new()
	status_indicators = StatusIndicators.new()
```

**Update `advance()` to update indicators** (around line 122):

**Before**:
```gdscript
	if hit_effects != null:
		hit_effects.update(delta)
```

**After**:
```gdscript
	if hit_effects != null:
		hit_effects.update(delta)
	if status_indicators != null:
		status_indicators.update(delta)
```

**Add public methods for status effects** (after enemy death method):

```gdscript
func add_enemy_status(status_type: String, duration: float = -1.0) -> void:
	if status_indicators == null or projectile_layer == null or enemy == null:
		return
	status_indicators.add_indicator(projectile_layer, enemy, status_type, duration)


func remove_enemy_status(status_type: String) -> void:
	if status_indicators == null or enemy == null:
		return
	status_indicators.remove_indicator(enemy, status_type)


func clear_enemy_statuses() -> void:
	if status_indicators == null or enemy == null:
		return
	status_indicators.remove_all_for_target(enemy)
```

### Verification:
1. Call `battle_stage.add_enemy_status("burn", 5.0)` to add burning indicator
2. Observe colored square appears above enemy
3. Indicator pulses with alpha
4. Indicator disappears after duration
5. Multiple indicators stack horizontally

---

## Task 2.4: Add Tower Attack Animations

**Time**: 25 minutes
**Files to modify**: `scripts/BattleStage.gd`

### Step 2.4.1: Add tower recoil animation state

**File**: `scripts/BattleStage.gd`
**Action**: Add new variables after `current_enemy_kind` (around line 41)

**Add these variables**:
```gdscript
# Tower animation state
var _castle_base_position: Vector2 = Vector2.ZERO
var _castle_recoil: float = 0.0
const CASTLE_RECOIL_AMOUNT := 8.0
const CASTLE_RECOIL_RECOVERY := 12.0
```

### Step 2.4.2: Apply recoil when shooting

**File**: `scripts/BattleStage.gd`
**Action**: Modify `spawn_projectile()` to trigger recoil

**Add at end of `spawn_projectile()` method** (before closing brace):
```gdscript
	# Trigger castle recoil
	_castle_recoil = 1.0
```

### Step 2.4.3: Update castle position with recoil

**File**: `scripts/BattleStage.gd`
**Action**: Add recoil update to `advance()` method

**Add after line 121 (after `_update_damage_numbers(delta)`)**:
```gdscript
	_update_castle_recoil(delta)
```

**Add the recoil update method** (after `_update_damage_numbers`):

```gdscript
func _update_castle_recoil(delta: float) -> void:
	if castle == null:
		return

	if _castle_base_position == Vector2.ZERO:
		_castle_base_position = castle.position

	# Decay recoil
	if _castle_recoil > 0.0:
		_castle_recoil = maxf(0.0, _castle_recoil - CASTLE_RECOIL_RECOVERY * delta)

	# Apply recoil offset (push back then return)
	var recoil_curve := _castle_recoil * _castle_recoil  # Quadratic for snap
	var offset := Vector2(-CASTLE_RECOIL_AMOUNT * recoil_curve, 0.0)
	castle.position = _castle_base_position + offset
```

### Step 2.4.4: Cache base position in layout

**File**: `scripts/BattleStage.gd`
**Action**: Modify `_layout()` to store base position

**Add at end of `_layout()` method** (before `_update_enemy_position()`):
```gdscript
	if castle != null:
		_castle_base_position = castle.position
```

### Verification:
1. Start a battle and type words
2. Castle visually recoils when projectile fires
3. Castle smoothly returns to position
4. Recoil is subtle but noticeable

---

## Task 2.5: Add Enemy Hit Stagger

**Time**: 20 minutes
**Files to modify**: `scripts/BattleStage.gd`

### Step 2.5.1: Add stagger state variables

**File**: `scripts/BattleStage.gd`
**Action**: Add variables after castle recoil vars

```gdscript
# Enemy stagger state
var _enemy_stagger: float = 0.0
var _enemy_stagger_direction: float = 1.0
const ENEMY_STAGGER_AMOUNT := 6.0
const ENEMY_STAGGER_RECOVERY := 8.0
```

### Step 2.5.2: Trigger stagger on hit

**File**: `scripts/BattleStage.gd`
**Action**: Modify `_flash_enemy()` to trigger stagger

**Before** (around line 265-269):
```gdscript
func _flash_enemy() -> void:
	hit_flash_timer = HIT_FLASH_DURATION
	_apply_enemy_flash(1.0)
	if audio_manager != null:
		audio_manager.play_hit_enemy()
```

**After**:
```gdscript
func _flash_enemy() -> void:
	hit_flash_timer = HIT_FLASH_DURATION
	_apply_enemy_flash(1.0)
	# Trigger stagger
	_enemy_stagger = 1.0
	_enemy_stagger_direction = -_enemy_stagger_direction  # Alternate direction
	if audio_manager != null:
		audio_manager.play_hit_enemy()
```

### Step 2.5.3: Apply stagger in enemy position update

**File**: `scripts/BattleStage.gd`
**Action**: Modify `_update_enemy_position()` to include stagger

**Before** (around line 208-214):
```gdscript
func _update_enemy_position() -> void:
	if enemy == null:
		return
	if lane_right_x == 0.0 and lane_left_x == 0.0:
		_layout()
	var x = lerp(lane_right_x, lane_left_x, progress)
	enemy.position = Vector2(x, lane_y)
```

**After**:
```gdscript
func _update_enemy_position() -> void:
	if enemy == null:
		return
	if lane_right_x == 0.0 and lane_left_x == 0.0:
		_layout()
	var x = lerp(lane_right_x, lane_left_x, progress)

	# Apply stagger offset
	var stagger_offset := 0.0
	if _enemy_stagger > 0.0:
		var stagger_curve := _enemy_stagger * _enemy_stagger
		stagger_offset = ENEMY_STAGGER_AMOUNT * stagger_curve * _enemy_stagger_direction

	enemy.position = Vector2(x + stagger_offset, lane_y)
```

### Step 2.5.4: Decay stagger in advance

**File**: `scripts/BattleStage.gd`
**Action**: Add stagger decay to `advance()` method

**Add after `_update_castle_recoil(delta)`**:
```gdscript
	# Decay enemy stagger
	if _enemy_stagger > 0.0:
		_enemy_stagger = maxf(0.0, _enemy_stagger - ENEMY_STAGGER_RECOVERY * delta)
```

### Verification:
1. Start a battle and hit enemies
2. Enemy visually staggers on each hit
3. Stagger alternates left/right
4. Stagger is subtle and doesn't affect gameplay

---

## Task 2.6: Add Combo Visual Escalation

**Time**: 25 minutes
**Files to modify**: `scripts/Battlefield.gd`

### Step 2.6.1: Add combo tier visual constants

**File**: `scripts/Battlefield.gd`
**Action**: Add constants after existing constants (around line 36)

```gdscript
# Combo tier thresholds and colors
const COMBO_TIER_2 := 5
const COMBO_TIER_3 := 10
const COMBO_TIER_4 := 20
const COMBO_TIER_5 := 50

const COMBO_COLORS := {
	1: Color(0.9, 0.9, 0.9, 1.0),      # White - basic
	2: Color(0.4, 0.8, 1.0, 1.0),      # Cyan - getting warm
	3: Color(0.5, 0.4, 1.0, 1.0),      # Purple - on fire
	4: Color(1.0, 0.7, 0.2, 1.0),      # Gold - blazing
	5: Color(1.0, 0.3, 0.3, 1.0),      # Red - legendary
}

const COMBO_LABELS := {
	1: "",
	2: "NICE!",
	3: "GREAT!",
	4: "AMAZING!",
	5: "LEGENDARY!",
}
```

### Step 2.6.2: Add combo tier calculation function

**File**: `scripts/Battlefield.gd`
**Action**: Add helper function after `_is_key_pressed()` (around line 42)

```gdscript
func _get_combo_tier(combo: int) -> int:
	if combo >= COMBO_TIER_5:
		return 5
	elif combo >= COMBO_TIER_4:
		return 4
	elif combo >= COMBO_TIER_3:
		return 3
	elif combo >= COMBO_TIER_2:
		return 2
	else:
		return 1


func _get_combo_color(combo: int) -> Color:
	return COMBO_COLORS.get(_get_combo_tier(combo), Color.WHITE)


func _get_combo_label(combo: int) -> String:
	return COMBO_LABELS.get(_get_combo_tier(combo), "")
```

### Step 2.6.3: Update combo display with tier colors

**File**: `scripts/Battlefield.gd`
**Action**: Find the combo label update code and enhance it

**Locate where combo_label text is set** (search for `combo_label.text`) and update to:

```gdscript
func _update_combo_display() -> void:
	if combo_label == null:
		return

	var combo := typing_system.get_combo()
	if combo < 2:
		combo_label.visible = false
		return

	combo_label.visible = true
	var tier := _get_combo_tier(combo)
	var tier_color := _get_combo_color(combo)
	var tier_label := _get_combo_label(combo)

	# Update text with tier label
	if tier_label.is_empty():
		combo_label.text = "x%d" % combo
	else:
		combo_label.text = "%s x%d" % [tier_label, combo]

	# Apply tier color
	combo_label.add_theme_color_override("font_color", tier_color)

	# Scale based on tier
	var target_scale := 1.0 + (tier - 1) * 0.1
	combo_label.scale = Vector2.ONE * target_scale
```

### Verification:
1. Start a battle and build combo
2. At 5 combo, color changes to cyan and shows "NICE!"
3. At 10 combo, color changes to purple and shows "GREAT!"
4. At 20 combo, color changes to gold and shows "AMAZING!"
5. At 50 combo, color changes to red and shows "LEGENDARY!"

---

## Task 2.7: Add Audio Enhancement for Combat

**Time**: 15 minutes
**Files to modify**: `game/audio_manager.gd`

### Step 2.7.1: Add new combat SFX enum values

**File**: `game/audio_manager.gd`
**Action**: Add to SFX enum (around line 56, before closing brace)

```gdscript
	CRITICAL_HIT,
	ENEMY_DEATH,
	STATUS_APPLY,
	STATUS_EXPIRE,
	TOWER_RECOIL
```

### Step 2.7.2: Add file mappings

**File**: `game/audio_manager.gd`
**Action**: Add to `_sfx_files` dictionary (around line 107)

```gdscript
	SFX.CRITICAL_HIT: "hit_enemy.wav",  # Reuse with pitch shift
	SFX.ENEMY_DEATH: "boss_defeated.wav",  # Reuse boss sound
	SFX.STATUS_APPLY: "event_show.wav",  # Subtle effect apply
	SFX.STATUS_EXPIRE: "event_skip.wav",  # Subtle effect end
	SFX.TOWER_RECOIL: "build_place.wav"  # Short thump
```

### Step 2.7.3: Add convenience methods

**File**: `game/audio_manager.gd`
**Action**: Add methods at end of file (after other play_ methods)

```gdscript
func play_critical_hit() -> void:
	play_sfx(SFX.CRITICAL_HIT, 1.3)  # Higher pitch


func play_enemy_death() -> void:
	play_sfx(SFX.ENEMY_DEATH, 0.9)  # Slightly lower


func play_status_apply() -> void:
	play_sfx(SFX.STATUS_APPLY, 1.1, -6.0)  # Quiet, higher pitch


func play_status_expire() -> void:
	play_sfx(SFX.STATUS_EXPIRE, 0.9, -8.0)  # Very quiet
```

### Verification:
1. Run tests to ensure no syntax errors
2. Call `audio_manager.play_critical_hit()` - should play with higher pitch
3. Call `audio_manager.play_enemy_death()` - should play death sound
4. Status sounds are subtle and non-intrusive

---

## Summary Checklist

After completing all Phase 2 tasks, verify:

- [ ] Critical hits show expanded red-orange ring + gold particles
- [ ] Critical damage number shows "CRITICAL!"
- [ ] Screen shakes on critical hits
- [ ] Enemy death shows 16+ exploding particles + smoke
- [ ] "DEFEATED!" text appears on enemy death
- [ ] Status indicators pulse above enemies
- [ ] Multiple status indicators stack horizontally
- [ ] Castle recoils when firing
- [ ] Enemy staggers when hit (alternating direction)
- [ ] Combo display changes color at tier thresholds
- [ ] Combo labels appear at milestones (NICE!, GREAT!, etc.)
- [ ] New combat sounds integrate properly

---

## Integration Points

### From Battlefield.gd (parent controller):
```gdscript
# When word completes with critical
var is_critical := typing_system.get_combo() >= 10 and randf() < 0.25
battle_stage.spawn_projectile(is_power_shot, is_critical)

# When enemy is defeated
battle_stage.spawn_enemy_death_effect()

# When applying status effect
battle_stage.add_enemy_status("burn", 5.0)

# When effect expires
battle_stage.remove_enemy_status("burn")
```

### Screen Shake Integration:
```gdscript
# Requires ScreenShake autoload from Phase 1
# BattleStage automatically calls ScreenShake.add_trauma() for:
# - Critical hits (0.4 trauma)
# - Enemy deaths (0.35 trauma)
```

---

## Files Modified/Created Summary

| File | Action | Lines Changed |
|------|--------|--------------|
| `game/hit_effects.gd` | Modified | +80 lines (2 new methods) |
| `scripts/BattleStage.gd` | Modified | +100 lines (methods + vars) |
| `game/status_indicators.gd` | Created | 130 lines |
| `scripts/Battlefield.gd` | Modified | +50 lines (combo tiers) |
| `game/audio_manager.gd` | Modified | +20 lines (new SFX) |

**Total new code**: ~380 lines
