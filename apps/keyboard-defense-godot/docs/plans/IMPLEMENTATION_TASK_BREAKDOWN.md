# Implementation Task Breakdown

## Overview

This document breaks down every implementation task with exact file paths, code changes, and verification steps.

**Reference Documents**:
- `ART_ASSET_IMPLEMENTATION_GUIDE.md` - SVG templates and art specs
- `SOUND_DESIGN_IMPLEMENTATION_GUIDE.md` - Complete JSON presets
- `POLISH_AND_JUICE_IMPLEMENTATION_GUIDE.md` - Full GDScript code

---

## Phase 1: Core Polish Systems (Week 1-2)

### Task 1.1: Screen Shake System

**Priority**: High
**Estimated Time**: 2 hours

**Create File**: `game/screen_shake.gd`
```
Copy complete code from: POLISH_AND_JUICE_IMPLEMENTATION_GUIDE.md Part 1.1
```

**Setup Autoload**:
1. Open Project > Project Settings > Globals/AutoLoad
2. Add new autoload:
   - Path: `res://game/screen_shake.gd`
   - Name: `ScreenShake`
   - Enable: Yes

**Wire Up Events** (modify these files):

`scripts/Battlefield.gd`:
```gdscript
# In _on_word_completed():
ScreenShake.on_word_complete()

# In _on_enemy_killed():
ScreenShake.on_enemy_death()

# In _on_castle_damaged():
ScreenShake.on_castle_damage(damage_percent)
```

`scripts/BattleStage.gd`:
```gdscript
# In _on_wave_complete():
ScreenShake.on_wave_complete()

# In _on_boss_spawn():
ScreenShake.on_boss_spawn()
```

**Verification**:
- [ ] Run game, complete a word - subtle shake occurs
- [ ] Kill enemy - small shake
- [ ] Take castle damage - larger shake
- [ ] Complete wave - celebration shake
- [ ] Tests pass: `godot --headless --path . --script res://tests/run_tests.gd`

---

### Task 1.2: Hit Pause System

**Priority**: High
**Estimated Time**: 1 hour

**Create File**: `game/hit_pause.gd`
```
Copy complete code from: POLISH_AND_JUICE_IMPLEMENTATION_GUIDE.md Part 2.1
```

**Setup Autoload**:
1. Path: `res://game/hit_pause.gd`
2. Name: `HitPause`

**Wire Up Events**:

`scripts/Battlefield.gd`:
```gdscript
# In _on_word_completed():
if perfect:
    HitPause.on_word_perfect()
else:
    HitPause.on_word_complete()

# In _on_enemy_killed():
HitPause.on_enemy_death()

# In _on_critical_hit():
HitPause.on_critical_hit()
```

**Verification**:
- [ ] Complete word - brief micro-pause
- [ ] Kill enemy - noticeable pause
- [ ] Critical hit - satisfying freeze
- [ ] Tests pass

---

### Task 1.3: Damage Numbers System

**Priority**: High
**Estimated Time**: 3 hours

**Create File**: `game/damage_numbers.gd`
```
Copy complete code from: POLISH_AND_JUICE_IMPLEMENTATION_GUIDE.md Part 3.1
```

**Integration in** `scripts/Battlefield.gd`:
```gdscript
# At top of file
var _damage_numbers: DamageNumbers = null

# In _ready():
_damage_numbers = DamageNumbers.new()
add_child(_damage_numbers)

# In _on_enemy_hit():
var world_pos = _grid_to_world(enemy.x, enemy.y)
_damage_numbers.spawn_damage(world_pos, damage)

# In _on_critical_hit():
_damage_numbers.spawn_critical(world_pos, damage)

# In _on_gold_earned():
_damage_numbers.spawn_gold(world_pos, amount)
```

**Verification**:
- [ ] Hit enemy - white number floats up
- [ ] Critical hit - gold number with shake
- [ ] Earn gold - gold "+X" appears
- [ ] Many numbers don't lag (test spawning 50)
- [ ] Tests pass

---

### Task 1.4: New Sound Presets (Batch 1)

**Priority**: High
**Estimated Time**: 1 hour

**Modify File**: `data/audio/sfx_presets.json`

Add these presets (copy from SOUND_DESIGN_IMPLEMENTATION_GUIDE.md):
- `ui_hover`
- `ui_click`
- `ui_error`
- `type_space`
- `type_backspace`
- `type_enter`
- `type_target_lock`
- `word_perfect`

**Integration Points**:

`ui/components/command_bar.gd`:
```gdscript
# In _on_key_pressed():
if key == KEY_SPACE:
    AudioManager.play_sfx("type_space")
elif key == KEY_BACKSPACE:
    AudioManager.play_sfx("type_backspace")
elif key == KEY_ENTER:
    AudioManager.play_sfx("type_enter")
```

**Verification**:
- [ ] Press space - distinct sound
- [ ] Press backspace - different sound
- [ ] Press enter - command sound
- [ ] Invalid command - error sound
- [ ] JSON validates: `./scripts/validate.sh`

---

### Task 1.5: Panel Animations

**Priority**: Medium
**Estimated Time**: 2 hours

**Modify**: Add to `ui/design_system.gd`:
```gdscript
## Animate panel opening
static func animate_panel_open(panel: Control) -> void:
    panel.scale = Vector2(0.8, 0.8)
    panel.modulate.a = 0.0
    panel.visible = true

    var tween = panel.create_tween()
    tween.set_parallel(true)
    tween.tween_property(panel, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT)
    tween.tween_property(panel, "modulate:a", 1.0, 0.15)

## Animate panel closing
static func animate_panel_close(panel: Control, callback: Callable = Callable()) -> void:
    var tween = panel.create_tween()
    tween.set_parallel(true)
    tween.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.15)
    tween.tween_property(panel, "modulate:a", 0.0, 0.15)

    if callback.is_valid():
        tween.tween_callback(callback)
    else:
        tween.tween_callback(panel.hide)
```

**Update panel components to use animations**:
- `ui/components/modal_panel.gd`
- `ui/components/event_panel.gd`
- `ui/components/achievement_panel.gd`

**Verification**:
- [ ] Open settings - smooth scale-up animation
- [ ] Close panel - smooth scale-down
- [ ] No visual glitches
- [ ] Tests pass

---

## Phase 2: Combat Juice (Week 3-4)

### Task 2.1: Enhanced Hit Effects

**Priority**: High
**Estimated Time**: 3 hours

**Modify**: `game/hit_effects.gd`

Add new effect methods:
```gdscript
func spawn_enemy_death_explosion(parent: Node, position: Vector2, color: Color) -> void:
    # Core burst - 12 particles
    for i in range(12):
        var particle: ColorRect = _particle_pool.acquire()
        if particle == null:
            continue

        particle.size = SPARK_SIZE if i % 3 == 0 else PARTICLE_SIZE * 1.5
        particle.color = color if i % 2 == 0 else color.lightened(0.3)
        particle.position = position - particle.size * 0.5
        particle.visible = true

        if particle.get_parent() == null:
            parent.add_child(particle)

        var angle := randf() * TAU
        var speed := PARTICLE_SPEED * 1.5 * (0.6 + randf() * 0.6)
        var velocity := Vector2(cos(angle), sin(angle)) * speed

        _active_particles.append({
            "node": particle,
            "velocity": velocity,
            "lifetime": PARTICLE_LIFETIME * 1.2,
            "fade_start": PARTICLE_LIFETIME * 0.4
        })

    # Outer ring - 8 particles
    for i in range(8):
        var particle: ColorRect = _particle_pool.acquire()
        if particle == null:
            continue

        particle.size = Vector2(8, 3)
        particle.color = color.lightened(0.5)
        particle.position = position - particle.size * 0.5
        particle.visible = true

        if particle.get_parent() == null:
            parent.add_child(particle)

        var angle := TAU * float(i) / 8.0
        var velocity := Vector2(cos(angle), sin(angle)) * PARTICLE_SPEED * 2.5

        _active_particles.append({
            "node": particle,
            "velocity": velocity,
            "lifetime": PARTICLE_LIFETIME * 0.6,
            "fade_start": PARTICLE_LIFETIME * 0.2,
            "no_gravity": true
        })


func spawn_status_particles(parent: Node, position: Vector2, status: String) -> void:
    var color: Color
    var count: int = 4
    var rise: bool = true

    match status:
        "burn":
            color = Color(1.0, 0.5, 0.2)  # Orange
            rise = true
        "freeze":
            color = Color(0.5, 0.8, 1.0)  # Light blue
            rise = false
        "poison":
            color = Color(0.3, 0.8, 0.3)  # Green
            rise = true
        "stun":
            color = Color(1.0, 1.0, 0.3)  # Yellow
            rise = false
        _:
            color = Color.WHITE

    for i in range(count):
        var particle: ColorRect = _particle_pool.acquire()
        if particle == null:
            continue

        particle.size = PARTICLE_SIZE
        particle.color = color
        particle.position = position + Vector2(randf_range(-12, 12), randf_range(-8, 8))
        particle.visible = true

        if particle.get_parent() == null:
            parent.add_child(particle)

        var velocity: Vector2
        if rise:
            velocity = Vector2(randf_range(-20, 20), randf_range(-60, -30))
        else:
            velocity = Vector2(randf_range(-30, 30), randf_range(20, 40))

        _active_particles.append({
            "node": particle,
            "velocity": velocity,
            "lifetime": PARTICLE_LIFETIME * 0.8,
            "fade_start": PARTICLE_LIFETIME * 0.3,
            "no_gravity": not rise
        })
```

**Wire up in** `scripts/Battlefield.gd`:
```gdscript
func _on_enemy_killed(enemy: Dictionary) -> void:
    var pos = _grid_to_world(enemy.x, enemy.y)
    var color = _get_enemy_color(enemy.type)
    _hit_effects.spawn_enemy_death_explosion(_effects_layer, pos, color)

func _on_status_tick(enemy: Dictionary, status: String) -> void:
    var pos = _grid_to_world(enemy.x, enemy.y)
    _hit_effects.spawn_status_particles(_effects_layer, pos, status)
```

**Verification**:
- [ ] Kill enemy - satisfying explosion burst
- [ ] Burning enemy - rising ember particles
- [ ] Frozen enemy - falling ice particles
- [ ] Poisoned enemy - rising bubble particles
- [ ] Tests pass

---

### Task 2.2: Enemy Hit Flash Shader

**Priority**: High
**Estimated Time**: 2 hours

**Create File**: `shaders/flash_white.gdshader`
```glsl
shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    COLOR = mix(tex_color, flash_color * tex_color.a, flash_amount);
}
```

**Create utility function** in `game/visual_effects.gd`:
```gdscript
class_name VisualEffects
extends RefCounted

static var _flash_shader: Shader = preload("res://shaders/flash_white.gdshader")

## Flash a sprite white for hit feedback
static func flash_sprite(sprite: Node2D, duration: float = 0.1) -> void:
    if sprite == null:
        return

    # Create or get shader material
    var mat: ShaderMaterial
    if sprite.material is ShaderMaterial:
        mat = sprite.material
    else:
        mat = ShaderMaterial.new()
        mat.shader = _flash_shader
        sprite.material = mat

    # Flash to white
    mat.set_shader_parameter("flash_amount", 1.0)

    # Animate back
    var tween = sprite.create_tween()
    tween.tween_method(
        func(val): mat.set_shader_parameter("flash_amount", val),
        1.0,
        0.0,
        duration
    )
```

**Verification**:
- [ ] Hit enemy - flashes white briefly
- [ ] Multiple hits in quick succession work
- [ ] No visual artifacts
- [ ] Tests pass

---

### Task 2.3: Sound Presets (Batch 2 - Combat)

**Priority**: High
**Estimated Time**: 45 minutes

**Modify File**: `data/audio/sfx_presets.json`

Add these presets (from SOUND_DESIGN_IMPLEMENTATION_GUIDE.md):
- `projectile_launch`
- `projectile_impact`
- `enemy_attack`
- `enemy_special`
- `armor_hit`
- `chain_lightning`
- `splash_damage`
- `enemy_grunt_hit`
- `enemy_grunt_death`
- `enemy_elite_roar`
- `enemy_elite_death`

**Wire up in combat code**.

**Verification**:
- [ ] Tower fires - launch sound
- [ ] Projectile hits - impact sound
- [ ] Elite spawns - roar sound
- [ ] JSON validates

---

## Phase 3: Audio Foundation (Week 5-6)

### Task 3.1: UI Sounds Complete

**Modify**: `data/audio/sfx_presets.json`

Add remaining UI presets:
- `ui_open_panel`
- `ui_close_panel`
- `ui_tab_switch`
- `ui_toggle_on`
- `ui_toggle_off`
- `ui_scroll`
- `ui_slider_tick`

**Wire up in UI components**.

---

### Task 3.2: Combo Sounds

**Modify**: `data/audio/sfx_presets.json`

Add combo presets:
- `combo_2x`
- `combo_3x`
- `combo_4x`
- `combo_5x`
- `combo_max`
- `streak_5`
- `streak_10`
- `streak_25`
- `streak_50`

**Wire up in** `scripts/Battlefield.gd`:
```gdscript
func _on_combo_changed(old_combo: int, new_combo: int) -> void:
    if new_combo >= 50 and old_combo < 50:
        AudioManager.play_sfx("combo_5x")
    elif new_combo >= 35 and old_combo < 35:
        AudioManager.play_sfx("combo_4x")
    elif new_combo >= 20 and old_combo < 20:
        AudioManager.play_sfx("combo_3x")
    elif new_combo >= 10 and old_combo < 10:
        AudioManager.play_sfx("combo_2x")
    elif new_combo >= 5 and old_combo < 5:
        AudioManager.play_sfx("combo_up")
```

---

### Task 3.3: Ambient Sounds

**Modify**: `data/audio/sfx_presets.json`

Add ambient presets:
- `ambient_wind_light`
- `ambient_tension`
- `day_dawn`
- `night_fall`
- `thunder_distant`
- `earthquake_rumble`

**Create ambient manager** or integrate with existing audio system.

---

## Phase 4: Visual Polish (Week 7-9)

### Task 4.1: Tower Upgrade Art

**Create Files** (following ART_ASSET_IMPLEMENTATION_GUIDE.md):
- `assets/art/src-svg/buildings/tower_arrow_t2.svg`
- `assets/art/src-svg/buildings/tower_arrow_t3.svg`
- `assets/art/src-svg/buildings/tower_fire_t2.svg`
- `assets/art/src-svg/buildings/tower_fire_t3.svg`
- `assets/art/src-svg/buildings/tower_ice_t2.svg`
- `assets/art/src-svg/buildings/tower_ice_t3.svg`

**Update**: `data/assets_manifest.json`

**Convert**: `./scripts/convert_assets.sh`

---

### Task 4.2: Effect Sprites

**Create Files**:
- `assets/art/src-svg/effects/effect_word_complete.svg`
- `assets/art/src-svg/effects/effect_word_error.svg`
- `assets/art/src-svg/effects/effect_critical.svg`
- `assets/art/src-svg/effects/effect_combo_spark.svg`

Use templates from ART_ASSET_IMPLEMENTATION_GUIDE.md.

---

## Phase 5: Screens & Flow (Week 10-11)

### Task 5.1: Screen Transitions

**Create File**: `game/screen_transition.gd`
```
Copy from POLISH_AND_JUICE_IMPLEMENTATION_GUIDE.md Part 4.1
```

**Setup autoload and wire up scene changes**.

---

### Task 5.2: Victory Screen

**Create/Modify**: `scenes/VictoryScreen.tscn` and script

Elements needed:
- "VICTORY" text with slam animation
- Stats display with count-up
- Star rating
- Continue button

---

### Task 5.3: Defeat Screen

**Create/Modify**: `scenes/DefeatScreen.tscn` and script

Elements needed:
- "DEFEATED" text with fade-in
- Desaturated background
- Stats (dimmed)
- Try Again / Return buttons
- Encouraging message

---

## Phase 6: Combo Visuals (Week 12)

### Task 6.1: Combo Display Component

**Create File**: `ui/components/combo_display.gd`
```
Copy from POLISH_AND_JUICE_IMPLEMENTATION_GUIDE.md Part 6.1
```

**Integrate** into battle UI.

---

### Task 6.2: Streak Indicator

**Create File**: `ui/components/streak_display.gd`

Implement flame trail visual that grows with streak.

---

## Phase 7: Final Polish (Week 13-14)

### Task 7.1: Accessibility Options

**Modify**: `game/settings_manager.gd`

Add settings:
```gdscript
var reduced_motion: bool = false
var screen_shake_intensity: float = 1.0
var hit_pause_enabled: bool = true
```

**Wire up** to polish systems.

---

### Task 7.2: Performance Optimization

**Audit**:
- Object pool sizes
- Particle counts
- Tween cleanup
- Memory leaks

**Fix** any issues found.

---

### Task 7.3: Final Balance Pass

**Test and tune**:
- Screen shake intensities
- Hit pause durations
- Sound volumes
- Animation timings

---

## Verification Checklist

### Per-Task Verification
- [ ] Code compiles without errors
- [ ] Tests pass: `godot --headless --path . --script res://tests/run_tests.gd`
- [ ] JSON validates: `./scripts/validate.sh`
- [ ] Feature works as expected in-game
- [ ] No performance regression

### End-of-Phase Verification
- [ ] All tasks in phase completed
- [ ] Game is playable start to finish
- [ ] No crashes or major bugs
- [ ] Performance is acceptable (60 FPS)

### Final Verification
- [ ] Complete playthrough successful
- [ ] All sounds play correctly
- [ ] All visuals display correctly
- [ ] Accessibility options work
- [ ] Ready for use!

---

## Quick Command Reference

```bash
# Run tests
godot --headless --path . --script res://tests/run_tests.gd

# Validate JSON
./scripts/validate.sh

# Convert SVG to PNG
./scripts/convert_assets.sh

# Run all checks
./scripts/run_all_checks.sh

# Check for issues
./scripts/precommit.sh --quick
```
