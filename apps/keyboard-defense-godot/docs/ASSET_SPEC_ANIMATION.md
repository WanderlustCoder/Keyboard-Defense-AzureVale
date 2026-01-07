# Animation Timing & Standards Specification

## Design Philosophy
- **Responsive Feel**: Animations never delay player action
- **Visual Clarity**: Movement readable at all speeds
- **Consistency**: Similar actions have similar timings
- **Performance**: Frame counts balanced with visual quality

---

## TIMING FUNDAMENTALS

### Frame Rate Standard
```
Target Frame Rate:  60 FPS (16.67ms per frame)
Animation Rate:     Variable (designed for 60 FPS playback)
Minimum Frames:     2 (for any visible animation)
Maximum Frames:     16 (for complex sequences)
```

### Duration Guidelines
```
Instant:       50-100ms   (feedback, micro-interactions)
Fast:          100-200ms  (combat, typing feedback)
Normal:        200-400ms  (standard animations)
Slow:          400-800ms  (emphasis, dramatic)
Extended:      800-2000ms (celebrations, transitions)
```

---

## EASING FUNCTIONS

### Standard Easings
```
ease-out:       Most common - snappy start, smooth end
ease-in:        Building tension - slow start, fast end
ease-in-out:    Smooth both ends - natural movement
linear:         Constant speed - mechanical, looping
```

### Easing by Context
| Context | Easing | Reason |
|---------|--------|--------|
| UI appear | ease-out | Responsive feel |
| UI dismiss | ease-in | Quick exit |
| Movement | ease-in-out | Natural motion |
| Loop/Idle | linear | Seamless repeat |
| Impact | ease-out | Punchy |
| Hover | ease-out | Responsive |

---

## SPRITE ANIMATION STANDARDS

### Frame Layout
```
All frames in horizontal strip:
[Frame 1][Frame 2][Frame 3][Frame 4]...

Total Width = frame_width × frame_count
Height = single frame height
```

### Loop Types
| Type | Description | Example |
|------|-------------|---------|
| Loop | Repeats infinitely | Idle, walking |
| Ping-pong | Forward then reverse | Breathing |
| One-shot | Plays once | Attack, death |
| Hold | Ends on last frame | Transition |

---

## CHARACTER ANIMATIONS

### Idle Animation
```
Frames:     4
Duration:   1600-2400ms (400-600ms per frame)
Motion:     Subtle breathing, weight shift
Easing:     Linear (seamless loop)
Loop:       Yes (ping-pong or standard)
```

**Frame Breakdown**:
- Frame 1: Neutral pose
- Frame 2: Slight rise (inhale)
- Frame 3: Peak/hold
- Frame 4: Lower (exhale)

---

### Walk Animation
```
Frames:     6
Duration:   600ms total (100ms per frame)
Motion:     Contact-pass-lift cycle
Easing:     Linear
Loop:       Yes
```

**Frame Breakdown**:
- Frame 1: Right contact
- Frame 2: Right pass
- Frame 3: Right lift
- Frame 4: Left contact
- Frame 5: Left pass
- Frame 6: Left lift

---

### Run Animation
```
Frames:     6
Duration:   400ms total (~67ms per frame)
Motion:     Faster cycle, more exaggerated
Easing:     Linear
Loop:       Yes
```

---

### Attack Animation
```
Frames:     6
Duration:   400-600ms
Phases:     Anticipation → Action → Recovery
Easing:     Ease-out (punchy impact)
Loop:       No (one-shot)
```

**Frame Breakdown**:
- Frame 1-2: Wind-up (anticipation)
- Frame 3: Strike (impact frame)
- Frame 4-5: Follow-through
- Frame 6: Return to neutral

---

### Death Animation
```
Frames:     6-8
Duration:   600-800ms
Motion:     Fall, dissolve, or dramatic
Easing:     Ease-out
Loop:       No (hold on last frame)
```

---

### Hit Reaction
```
Frames:     3-4
Duration:   200-300ms
Motion:     Knockback, flash, return
Easing:     Ease-out
Loop:       No
```

---

## ENEMY-SPECIFIC TIMINGS

### Standard Enemy
```
Idle:       4 frames, 2000ms
Walk:       4 frames, 600ms (slow march)
Attack:     4 frames, 400ms
Death:      6 frames, 400ms
```

### Fast Enemy (Swarm, Assassin)
```
Idle:       2 frames, 400ms
Walk:       4 frames, 300ms
Attack:     3 frames, 250ms
Death:      4 frames, 200ms
```

### Heavy Enemy (Golem, Tank)
```
Idle:       4 frames, 3000ms (slow breathing)
Walk:       6 frames, 1000ms (heavy steps)
Attack:     8 frames, 1000ms (wind-up)
Death:      10 frames, 1200ms (crumble)
```

### Boss Enemy
```
Idle:       6 frames, 2000ms (menacing)
Attack:     8-12 frames, 800-1200ms
Death:      12-16 frames, 1500-2000ms (dramatic)
Phase:      8 frames transition between phases
```

---

## TOWER ANIMATIONS

### Tower Idle
```
Frames:     2-4
Duration:   2000-3000ms
Motion:     Minimal ambient (flag wave, glow pulse)
Loop:       Yes
```

### Tower Firing
```
Frames:     4-6
Duration:   300-500ms
Motion:     Aim → Fire → Recoil → Reset
Easing:     Ease-out
Loop:       No
```

**Per Tower Type**:
| Tower | Frames | Duration | Notes |
|-------|--------|----------|-------|
| Arrow | 4 | 300ms | Quick release |
| Cannon | 6 | 500ms | Recoil heavy |
| Fire | 4 | 350ms | Flame burst |
| Ice | 5 | 400ms | Crystal form |
| Lightning | 3 | 200ms | Instant arc |
| Poison | 4 | 350ms | Spray |
| Support | 4 | 400ms | Pulse expand |

---

### Tower Construction
```
Frames:     8
Duration:   2000ms
Motion:     Foundation → Walls → Complete
Easing:     Ease-in-out
Loop:       No
```

---

### Tower Upgrade
```
Frames:     6
Duration:   600ms
Motion:     Glow → Transform → Settle
Easing:     Ease-out
Loop:       No
```

---

## PROJECTILE ANIMATIONS

### Flight Animation
```
Frames:     2-4
Duration:   100-200ms loop
Motion:     Spin, flicker, or trail
Easing:     Linear
Loop:       Yes (while in flight)
```

### Impact Animation
```
Frames:     4-8
Duration:   200-500ms
Motion:     Burst, scatter, fade
Easing:     Ease-out
Loop:       No
```

---

## EFFECT ANIMATIONS

### Particle Effects
```
Spawn:      Immediate appearance
Lifetime:   200-1000ms
Motion:     Based on type (rise, fall, drift)
Fade:       Last 20% of lifetime
```

### Screen Effects
| Effect | Duration | Notes |
|--------|----------|-------|
| Flash | 100-200ms | White overlay, fade out |
| Shake | 200-500ms | Decay over time |
| Vignette | 300-600ms | Pulse or hold |
| Zoom | 300-500ms | Ease-in-out |

---

## UI ANIMATIONS

### Button States
```
Hover Enter:    150ms ease-out
Hover Exit:     100ms ease-in
Press:          50ms ease-out
Release:        100ms ease-out
```

### Menu Transitions
```
Open:           200-300ms ease-out
Close:          150-200ms ease-in
Switch Tab:     200ms ease-in-out
```

### Tooltip
```
Appear:         150ms ease-out (after delay)
Delay:          300ms before showing
Dismiss:        100ms ease-in
```

### Notifications
```
Enter:          300ms ease-out (slide)
Hold:           2000-4000ms
Exit:           200ms ease-in
```

---

## TYPING FEEDBACK TIMING

### Keystroke Feedback
```
Visual Flash:   100ms
Key Depression: 50ms
Release:        50ms
Total:          ~150ms
```

### Letter Animation
```
Correct:        100ms scale-up + color
Wrong:          150ms shake + color
Current:        Continuous pulse (600ms)
```

### Word Completion
```
Flash:          100ms
Clear:          200ms (letters fly)
Score Pop:      300ms (number rises)
Total:          ~400ms
```

### Combo Animation
```
Increase:       300ms (scale + glow)
Milestone:      500ms (burst + particles)
Drop:           400ms (shatter effect)
```

---

## COMBAT TIMING

### Attack Cycle
```
Tower Target:   Instant (no delay)
Fire Delay:     0-100ms (feel responsive)
Projectile:     Variable (based on distance)
Impact:         Immediate
Damage Number:  300ms float up
Enemy React:    200ms
```

### Damage Timing
```
Hit Flash:      100ms (white tint)
Knockback:      150ms
Health Bar:     200ms (smooth decrease)
Status Apply:   100ms (icon appear)
```

### Death Timing
```
Final Hit:      100ms pause (hit stop)
Death Anim:     400-800ms
Loot Drop:      200ms delay after death
Fade Out:       300ms
```

---

## PICKUP ANIMATIONS

### Spawn
```
Appear:         200ms (pop-in with particles)
Idle Bob:       1000ms loop (gentle bounce)
```

### Collection
```
Attract:        200ms (fly toward player)
Collect Flash:  100ms
Counter Update: 200ms (number change)
```

### Expire Warning
```
Start:          5 seconds before despawn
Blink Rate:     500ms on, 500ms off
Final:          Rapid blink last 2 seconds
```

---

## SPECIAL ANIMATION TECHNIQUES

### Squash & Stretch
```
Use for:        Bouncy, organic motion
Compression:    10-20% on impact
Extension:      10-20% on launch
Recovery:       Return to normal shape
```

### Anticipation
```
Duration:       1-2 frames
Purpose:        Signal upcoming action
Amount:         Opposite of action direction
```

### Follow-Through
```
Duration:       2-3 frames
Purpose:        Natural motion completion
Amount:         Slight overshoot then settle
```

### Smear Frames
```
Use for:        Fast movement
Frames:         1-2 stretched frames
Effect:         Motion blur approximation
```

---

## ANIMATION STATE MACHINE

### Standard Character States
```
┌─────────────────────────────────────┐
│              IDLE                   │
│    ↓ move     ↓ attack    ↓ hit    │
├─────────────────────────────────────┤
│   WALK    │  ATTACK  │  HIT_REACT  │
│    ↓ stop │   ↓ end  │    ↓ end    │
├─────────────────────────────────────┤
│         → IDLE ←                    │
│              ↓ die                  │
│            DEATH                    │
└─────────────────────────────────────┘
```

### Transition Rules
```
Any → Death:       Immediate override
Attack → Move:     Wait for attack complete
Hit → Attack:      After hit recovery
Idle → Any:        Immediate
```

---

## PERFORMANCE OPTIMIZATION

### Frame Count Limits
| Category | Max Frames | Reason |
|----------|------------|--------|
| Idle | 4-6 | Always playing |
| Combat | 6-8 | Frequent |
| Death | 8-12 | Infrequent |
| Effects | 6-8 | Many instances |
| UI | 4-6 | Responsive |

### Animation Pooling
```
Reuse patterns:     Similar animations share frames
Cache timing:       Pre-calculate frame durations
Instance limit:     Max 50 animated sprites on screen
LOD:                Reduce frames for distant objects
```

### Update Optimization
```
Visible only:       Don't update off-screen
Batch similar:      Group same-animation sprites
Priority system:    Important animations update first
Frame skip:         Allow skip if behind
```

---

## TIMING CHEAT SHEET

### Quick Reference
| Animation | Frames | Duration | Easing |
|-----------|--------|----------|--------|
| Idle | 4 | 2000ms | Linear |
| Walk | 6 | 600ms | Linear |
| Attack | 6 | 400ms | Ease-out |
| Death | 6 | 600ms | Ease-out |
| Hit | 3 | 200ms | Ease-out |
| Button hover | 1 | 150ms | Ease-out |
| Menu open | 1 | 200ms | Ease-out |
| Keystroke | 2 | 100ms | Ease-out |
| Word complete | 6 | 400ms | Ease-out |
| Projectile fly | 4 | 200ms | Linear |
| Impact | 6 | 300ms | Ease-out |
| Pickup collect | 4 | 200ms | Ease-out |
| Level up | 12 | 1500ms | Ease-out |

---

## IMPLEMENTATION NOTES

### Frame Timing in Godot
```gdscript
# AnimationPlayer timing
animation.length = duration_seconds
animation.step = 1.0 / frame_count

# AnimatedSprite2D timing
sprite.speed_scale = 1.0  # Adjust for faster/slower
sprite.frame = 0  # Reset to start
```

### Sync with Game Events
```
Combat hit:     Sync damage with impact frame
Typing:         Sync feedback with keypress
Collection:     Sync sound with visual
```

