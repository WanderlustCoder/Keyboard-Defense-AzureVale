# Polish and Juice Master Plan

## Executive Summary

This document defines all "game feel" enhancements needed to make Keyboard Defense satisfying to play. Polish and juice create the difference between a functional game and one that feels great.

**Goal**: Transform every player action into a rewarding, tactile experience
**Philosophy**: Every input deserves feedback, every event deserves celebration

---

## Current Polish Systems

### Existing Features (game/hit_effects.gd)
- [x] Object-pooled particle spawner
- [x] Hit spark particles (6 particles, 0.4s lifetime)
- [x] Power burst effect (10 particles, larger)
- [x] Damage flash effect (8 particles, red)
- [x] Word complete burst (12 particles, gold/cyan)
- [x] Tower shot trails (3-4 particles)
- [x] Gravity-affected particles
- [x] Fade-out transitions

### Existing Visuals (game/grid_renderer.gd)
- [x] Castle morphing animation
- [x] Threat bar visual
- [x] Basic sprite rendering
- [x] Procedural terrain

### Gaps Identified
- [ ] No screen shake
- [ ] No hit pause/freeze frames
- [ ] No damage numbers
- [ ] No combo visuals
- [ ] No input flash feedback
- [ ] No screen transitions
- [ ] No particle trails
- [ ] Limited animation variety
- [ ] No boss entrance effects
- [ ] No victory/defeat screens

---

## Phase 1: Core Feedback Systems

### 1.1 Screen Shake System

**Implementation**: `game/screen_shake.gd`

```gdscript
class_name ScreenShake
extends Node

var trauma: float = 0.0
var trauma_decay: float = 0.8
var max_offset: Vector2 = Vector2(16, 12)
var max_rotation: float = 0.05
var noise: FastNoiseLite

func add_trauma(amount: float) -> void:
    trauma = minf(trauma + amount, 1.0)

func _process(delta: float) -> void:
    trauma = maxf(trauma - trauma_decay * delta, 0.0)
    var shake = trauma * trauma  # Quadratic falloff
    # Apply to camera offset
```

**Shake Intensities**:
| Event | Trauma Amount | Notes |
|-------|---------------|-------|
| Correct keystroke | 0.0 | No shake |
| Word complete | 0.02 | Subtle pulse |
| Critical hit | 0.1 | Noticeable |
| Enemy death | 0.05 | Light |
| Castle hit | 0.2 | Heavy, impactful |
| Boss spawn | 0.3 | Dramatic entrance |
| Boss phase change | 0.25 | Alert the player |
| Wave complete | 0.15 | Celebratory |
| Game over | 0.4 | Full impact |

**Accessibility**: `reduced_motion` setting disables all shake.

---

### 1.2 Hit Pause / Freeze Frames

**Implementation**: `game/hit_pause.gd`

```gdscript
class_name HitPause
extends Node

var pause_timer: float = 0.0

func pause(duration: float) -> void:
    pause_timer = duration
    get_tree().paused = true

func _process(delta: float) -> void:
    if pause_timer > 0:
        pause_timer -= delta
        if pause_timer <= 0:
            get_tree().paused = false
```

**Pause Durations**:
| Event | Duration (ms) | Effect |
|-------|---------------|--------|
| Word complete | 30 | Micro-pause, satisfying |
| Perfect word | 50 | Slightly longer |
| Critical hit | 40 | Impact emphasis |
| Enemy death | 20 | Quick snap |
| Boss hit | 60 | Weighty impact |
| Boss death | 150 | Dramatic finish |
| Combo milestone | 35 | Celebration beat |
| Castle damage | 80 | Alert player |

**Note**: Actual input is unaffected (typing continues during pause).

---

### 1.3 Damage Numbers System

**Implementation**: `game/damage_numbers.gd`

```gdscript
class_name DamageNumbers
extends Node

func spawn_number(position: Vector2, value: int, type: String) -> void:
    var label = Label.new()
    label.text = str(value)
    label.position = position + Vector2(randf_range(-8, 8), 0)

    # Style based on type
    match type:
        "normal": label.add_theme_color_override("font_color", Color.WHITE)
        "critical":
            label.add_theme_color_override("font_color", Color.GOLD)
            label.add_theme_font_size_override("font_size", 24)
        "heal": label.add_theme_color_override("font_color", Color.GREEN)
        "block": label.add_theme_color_override("font_color", Color.GRAY)

    add_child(label)
    animate_number(label)
```

**Number Types**:
| Type | Color | Size | Animation |
|------|-------|------|-----------|
| Normal | White | 16px | Float up, fade |
| Critical | Gold | 24px | Pop + float, shake |
| Combo bonus | Cyan | 20px | Scale up, fade |
| Heal | Green | 16px | Float up |
| Shield | Blue | 16px | Pop |
| Block/Resist | Gray | 14px | Slide right |
| Overkill | Red | 28px | Explode outward |

**Animation**:
- Start: Scale 0 → 1.2 → 1.0 (100ms)
- Rise: -60 pixels over 0.8s
- Fade: Alpha 1 → 0 over last 0.3s
- Critical: Add horizontal shake

---

### 1.4 Input Flash Feedback

**Implementation**: In typing display

```gdscript
func flash_correct(key: String) -> void:
    # Create flash overlay on typed character
    var flash = ColorRect.new()
    flash.color = Color(1, 1, 1, 0.5)
    flash.size = character_size
    flash.position = get_char_position(current_index)
    add_child(flash)

    var tween = create_tween()
    tween.tween_property(flash, "modulate:a", 0.0, 0.15)
    tween.tween_callback(flash.queue_free)
```

**Visual Feedback**:
| Input | Effect |
|-------|--------|
| Correct letter | White flash, text turns green |
| Incorrect letter | Red flash, brief shake |
| Word complete | All letters pulse gold |
| Target locked | Border highlight on word |
| Space bar | Ripple effect |
| Backspace | Character dissolve |

---

## Phase 2: Combat Polish

### 2.1 Enhanced Particle Effects

**New Effects to Add**:

#### Enemy Death Explosions
```gdscript
func spawn_enemy_death(position: Vector2, enemy_type: String) -> void:
    var count = 12  # Base
    var color = get_enemy_color(enemy_type)

    # Core explosion
    for i in range(count):
        spawn_particle(position, color, {
            "speed": randf_range(80, 150),
            "angle": randf() * TAU,
            "lifetime": 0.5,
            "size": Vector2(6, 6),
            "gravity": 100
        })

    # Outer ring
    for i in range(8):
        var angle = TAU * i / 8.0
        spawn_particle(position, color.lightened(0.3), {
            "speed": 200,
            "angle": angle,
            "lifetime": 0.3,
            "size": Vector2(4, 2)
        })
```

#### Tower Attack Trails
| Tower Type | Trail Effect |
|------------|--------------|
| Arrow | Thin white streak |
| Fire | Orange ember trail + smoke |
| Ice | Blue crystal shards |
| Lightning | Jagged line + afterglow |
| Poison | Green droplets |
| Arcane | Purple spiral |
| Holy | White radiance |
| Cannon | Smoke puff + debris |

#### Status Effect Particles
| Status | Particle Type |
|--------|---------------|
| Burning | Rising embers |
| Frozen | Falling ice crystals |
| Poisoned | Green bubbles |
| Slowed | Blue mist |
| Stunned | Stars circling head |
| Shielded | Bubble shimmer |

---

### 2.2 Enemy Visual Feedback

**Hit Flash**:
```gdscript
func flash_enemy_hit(sprite: Sprite2D) -> void:
    var shader = preload("res://shaders/flash_white.gdshader")
    sprite.material = ShaderMaterial.new()
    sprite.material.shader = shader
    sprite.material.set_shader_parameter("flash_amount", 1.0)

    var tween = create_tween()
    tween.tween_property(sprite.material, "shader_parameter/flash_amount", 0.0, 0.1)
```

**Enemy State Visuals**:
| State | Visual |
|-------|--------|
| Idle | Subtle bob animation |
| Moving | Walk cycle + dust puffs |
| Attacking | Wind-up + strike frame |
| Hurt | Flash white + recoil |
| Dying | Flash + dissolve/explode |
| Stunned | Stars + grayed out |
| Enraged | Red tint + size pulse |

---

### 2.3 Boss Encounter Polish

**Boss Entrance Sequence**:
1. Screen darkens (0.3s)
2. Boss silhouette appears
3. Lightning/dramatic effect
4. Boss name card slides in
5. Music transitions
6. Screen shake
7. Fight begins

**Boss Phase Transitions**:
- Screen flash
- Boss invulnerable briefly
- Visual transformation
- New attack pattern indicator

**Boss Death**:
- Extended freeze frame (200ms)
- Massive particle explosion
- Screen shake sequence
- Slow motion (0.5x for 1s)
- Victory fanfare

---

## Phase 3: UI Polish

### 3.1 Menu Transitions

**Scene Transitions**:
```gdscript
func transition_to(scene: String) -> void:
    var transition = ColorRect.new()
    transition.color = Color.BLACK
    transition.modulate.a = 0.0

    var tween = create_tween()
    tween.tween_property(transition, "modulate:a", 1.0, 0.3)
    tween.tween_callback(func(): get_tree().change_scene_to_file(scene))
    tween.tween_property(transition, "modulate:a", 0.0, 0.3)
```

**Transition Types**:
| Transition | Effect | Duration |
|------------|--------|----------|
| Fade | Simple black fade | 0.5s |
| Wipe | Horizontal wipe | 0.4s |
| Circle | Expanding circle | 0.6s |
| Pixelate | Pixel dissolve | 0.5s |
| Shatter | Breaking glass | 0.8s |

---

### 3.2 Panel Animations

**Open Animation**:
```gdscript
func open_panel(panel: Control) -> void:
    panel.scale = Vector2(0.8, 0.8)
    panel.modulate.a = 0.0
    panel.visible = true

    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(panel, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT)
    tween.tween_property(panel, "modulate:a", 1.0, 0.15)
```

**Panel Behaviors**:
| Panel Type | Open | Close |
|------------|------|-------|
| Modal | Scale up + fade | Scale down + fade |
| Slide | Slide from edge | Slide out |
| Achievement | Pop + glow | Fade out |
| Tooltip | Instant + fade | Fade out |

---

### 3.3 Button Feedback

**Hover State**:
```gdscript
func _on_button_mouse_entered() -> void:
    var tween = create_tween()
    tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)
    # Play hover sound
```

**Click State**:
```gdscript
func _on_button_pressed() -> void:
    var tween = create_tween()
    tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.05)
    tween.tween_property(button, "scale", Vector2.ONE, 0.1)
    # Play click sound
```

---

### 3.4 Typing Display Polish

**Character States**:
| State | Visual |
|-------|--------|
| Pending | Dim gray text |
| Current | Highlighted, cursor |
| Correct | Green, fade pulse |
| Error | Red, shake |
| Complete | Gold, particles |

**Word Completion Animation**:
1. All letters turn gold (0.1s stagger)
2. Scale pulse 1.0 → 1.1 → 1.0
3. Particle burst from word center
4. Word slides up and fades
5. New word appears with bounce

**Error Animation**:
- Character flashes red
- Horizontal shake (2-3 pixels)
- Brief sound cue
- Returns to pending state

---

## Phase 4: Combo System Visuals

### 4.1 Combo Counter Display

**Visual Scaling**:
| Combo | Size | Effect |
|-------|------|--------|
| 1-4 | 100% | Basic display |
| 5-9 | 110% | Subtle glow |
| 10-19 | 120% | Pulsing glow |
| 20-34 | 130% | Fire particles |
| 35-49 | 140% | Intense fire |
| 50+ | 150% | Rainbow fire |

**Milestone Celebrations**:
```gdscript
func show_combo_milestone(combo: int) -> void:
    var label = Label.new()
    match combo:
        5: label.text = "GREAT!"
        10: label.text = "AWESOME!"
        20: label.text = "AMAZING!"
        35: label.text = "INCREDIBLE!"
        50: label.text = "LEGENDARY!"

    # Animate with scale, glow, and particles
    animate_milestone(label)
```

---

### 4.2 Streak Visuals

**Streak Indicator**:
- Perfect word streak shown as connected flames
- Each word adds a flame
- Miss extinguishes all flames with smoke puff

**Streak Milestones**:
| Streak | Visual |
|--------|--------|
| 5 | Bronze flame trail |
| 10 | Silver flame trail |
| 25 | Gold flame trail |
| 50 | Diamond flame + screen glow |

---

## Phase 5: Environmental Polish

### 5.1 Day/Night Transitions

**Day to Night**:
1. Sun begins to set (orange gradient)
2. Shadows lengthen
3. Stars begin appearing
4. Moon rises
5. Ambient lighting shifts blue
6. Threat music fades in

**Night to Day**:
1. Sky lightens gradually
2. Stars fade
3. Sun rises (golden glow)
4. Birds chirp (audio cue)
5. Shadows reset
6. Peaceful music fades in

---

### 5.2 Weather Effects

**Rain**:
- Particle raindrops
- Puddle splashes
- Screen darkening
- Ambient rain sound

**Storm**:
- Heavy rain
- Lightning flashes (screen flash + shake)
- Thunder rumble
- Wind particles

**Snow** (for ice levels):
- Gentle snowflakes
- Frost buildup on edges
- Breath puffs on characters

---

### 5.3 Castle Damage States

| HP % | Visual State |
|------|--------------|
| 100-75% | Pristine, flags waving |
| 74-50% | Minor damage, cracks |
| 49-25% | Heavy damage, fires |
| 24-1% | Critical, crumbling |
| 0% | Collapsed, smoke |

**Damage Transition**:
- Dust cloud burst
- Debris particles
- Structure shake
- Sound effect

---

## Phase 6: Victory/Defeat Screens

### 6.1 Victory Screen

**Sequence**:
1. Time slow (0.5x for 0.5s)
2. "VICTORY" text slam (scale from 2.0)
3. Confetti particles
4. Stats roll in one by one
5. Star rating animation
6. Rewards display
7. Continue button appears

**Stats Animation**:
```
Words typed:     0 → 47  (count up)
Accuracy:        0% → 94% (count up)
Max combo:       0 → 23  (count up)
Time:            00:00 → 02:34 (tick)
Grade:           ??? → A (reveal)
```

---

### 6.2 Defeat Screen

**Sequence**:
1. Screen desaturates
2. Slow zoom out from castle
3. "DEFEATED" fades in
4. Soft particles (embers/ash)
5. Stats (dimmer, no celebration)
6. "Try Again" / "Return to Hub" buttons
7. Encouraging message

---

## Phase 7: Quality of Life Polish

### 7.1 Loading States

**Loading Indicator**:
- Animated typing cursor
- Progress bar (if applicable)
- Tip display rotation
- Animated background

---

### 7.2 First-Time Experience

**Tutorial Polish**:
- Lyra character animations
- Highlight pulse on UI elements
- Arrow indicators
- Success celebrations
- Gentle error guidance

---

### 7.3 Accessibility Features

**Reduced Motion Mode**:
- Disable screen shake
- Disable particle effects (or reduce to 25%)
- Instant transitions
- Static UI elements
- Maintain audio feedback

**High Contrast Mode**:
- Sharper color boundaries
- Larger UI elements
- Stronger text outlines
- Reduced visual noise

---

## Implementation Priority

### Sprint 1: Core Feel (Week 1-2)
- [ ] Screen shake system
- [ ] Hit pause system
- [ ] Basic damage numbers
- [ ] Input flash feedback
- [ ] Panel open/close animations

### Sprint 2: Combat Juice (Week 3-4)
- [ ] Enhanced enemy death particles
- [ ] Tower trail effects
- [ ] Enemy hit flash
- [ ] Status effect particles
- [ ] Boss entrance sequence

### Sprint 3: UI Polish (Week 5-6)
- [ ] Scene transitions
- [ ] Button animations
- [ ] Typing display polish
- [ ] Combo counter visuals
- [ ] Streak indicator

### Sprint 4: Environmental (Week 7-8)
- [ ] Day/night transitions
- [ ] Weather effects
- [ ] Castle damage states
- [ ] Ambient particles
- [ ] Background animations

### Sprint 5: Screens & Flow (Week 9-10)
- [ ] Victory screen
- [ ] Defeat screen
- [ ] Loading states
- [ ] Achievement popups
- [ ] Milestone celebrations

### Sprint 6: Accessibility & QoL (Week 11-12)
- [ ] Reduced motion mode
- [ ] High contrast mode
- [ ] Tutorial polish
- [ ] Performance optimization
- [ ] Final tuning pass

---

## Technical Specifications

### Performance Budgets
| System | Max Active | Pool Size |
|--------|------------|-----------|
| Particles | 200 | 300 |
| Damage numbers | 30 | 50 |
| Tweens | 50 | - |
| Shaders | 10 unique | - |

### Frame Timing
- All animations: 60 FPS target
- Particle update: Every frame
- Shake update: Every frame
- Tween update: Engine managed

### Memory Considerations
- Pool all frequently spawned objects
- Reuse tween instances where possible
- Shader caching for flash effects
- Particle texture atlasing

---

## Quality Checklist

### Per-Feature Verification
- [ ] Feels good in isolation
- [ ] Works with other systems
- [ ] Respects accessibility settings
- [ ] Performs within budget
- [ ] Audio syncs with visual

### Full Game Verification
- [ ] No visual noise/chaos at peak gameplay
- [ ] Hierarchy clear (important > ambient)
- [ ] Consistent style throughout
- [ ] Loading times acceptable
- [ ] No jarring transitions

### Playtesting Questions
- Does typing feel satisfying?
- Are hits impactful?
- Is progress clear and rewarding?
- Do failures feel fair (not frustrating)?
- Is the game visually readable during combat?

---

## Asset Count Summary

| Category | Items |
|----------|-------|
| Particle effects | ~20 new types |
| Screen transitions | 5 types |
| UI animations | ~15 behaviors |
| Shader effects | 5 shaders |
| Environmental effects | ~10 systems |

**Total new visual systems: ~55**
