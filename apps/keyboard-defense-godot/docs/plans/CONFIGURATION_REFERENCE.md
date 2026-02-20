# Configuration Reference

## All Polish System Constants

This document lists every configurable constant across all polish systems for easy tuning.

---

## Screen Shake (`game/screen_shake.gd`)

| Constant | Default | Description | Range |
|----------|---------|-------------|-------|
| `MAX_OFFSET` | `Vector2(20, 15)` | Maximum camera offset in pixels | 5-50 |
| `MAX_ROTATION` | `0.04` | Maximum rotation in radians | 0-0.1 |
| `DECAY_RATE` | `0.8` | Trauma decay per second | 0.5-2.0 |
| `TRAUMA_POWER` | `2.0` | Exponent for shake curve | 1.0-3.0 |

### Presets
| Preset | Value | Use Case |
|--------|-------|----------|
| `PRESET_LIGHT` | `0.2` | Small hits, UI feedback |
| `PRESET_MEDIUM` | `0.4` | Normal hits, word complete |
| `PRESET_HEAVY` | `0.6` | Critical hits, enemy death |
| `PRESET_EXTREME` | `0.9` | Boss hits, defeat |

---

## Hit Pause (`game/hit_pause.gd`)

| Constant | Default | Description | Range |
|----------|---------|-------------|-------|
| `MIN_PAUSE_DURATION` | `0.016` | Minimum pause (1 frame) | 0.016-0.05 |
| `MAX_PAUSE_DURATION` | `0.25` | Maximum allowed pause | 0.1-0.5 |

### Presets
| Preset | Value | Use Case |
|--------|-------|----------|
| `PRESET_MICRO` | `0.03` | Subtle confirmation |
| `PRESET_LIGHT` | `0.05` | Light hit |
| `PRESET_MEDIUM` | `0.08` | Normal hit |
| `PRESET_HEAVY` | `0.12` | Critical hit |
| `PRESET_EXTREME` | `0.18` | Boss hit, defeat |

---

## Damage Numbers (`game/damage_numbers.gd`)

| Constant | Default | Description | Range |
|----------|---------|-------------|-------|
| `POOL_SIZE` | `20` | Initial pool size | 10-50 |
| `MAX_POOL_SIZE` | `50` | Maximum pool size | 30-100 |
| `BASE_FONT_SIZE` | `16` | Normal number size | 12-24 |
| `CRIT_FONT_SIZE` | `24` | Critical number size | 18-36 |
| `RISE_SPEED` | `60.0` | Upward movement speed | 30-100 |
| `LIFETIME` | `0.9` | Seconds visible | 0.5-1.5 |
| `FADE_START` | `0.5` | When to start fading | 0.3-0.7 |
| `SPREAD` | `30.0` | Horizontal random spread | 10-50 |

### Colors
| Type | Color | Hex |
|------|-------|-----|
| `damage` | Red | `#ff4c33` |
| `heal` | Green | `#4de666` |
| `gold` | Gold | `#ffd700` |
| `xp` | Blue | `#80b3ff` |
| `combo` | Pink | `#ff99cc` |
| `critical` | Yellow | `#ffe64d` |
| `miss` | Gray | `#b3b3b3` |
| `blocked` | Dark gray | `#808099` |

---

## Hit Effects (`game/hit_effects.gd`)

| Constant | Default | Description | Range |
|----------|---------|-------------|-------|
| `PARTICLE_COUNT` | `6` | Base particle count | 4-12 |
| `PARTICLE_LIFETIME` | `0.4` | Seconds alive | 0.2-0.8 |
| `PARTICLE_SPEED` | `120.0` | Initial velocity | 60-200 |
| `PARTICLE_SIZE` | `Vector2(4, 4)` | Square size | 2-8 |
| `SPARK_SIZE` | `Vector2(6, 2)` | Elongated size | 4-10 |
| `POOL_SIZE` | `100` | Pre-warm count | 50-200 |
| `MAX_POOL_SIZE` | `200` | Maximum count | 100-300 |

### Effect Particle Counts
| Effect | Count | Notes |
|--------|-------|-------|
| `spawn_hit_sparks` | 6 | Standard hit |
| `spawn_power_burst` | 10 | Power shot |
| `spawn_damage_flash` | 8 | Castle damage |
| `spawn_word_complete_burst` | 12 | Word celebration |
| `spawn_critical_hit` | 20 | Critical (8 ring + 12 burst) |
| `spawn_enemy_death` | 22 | Death (16 burst + 6 smoke) |

---

## Scene Transition (`game/scene_transition.gd`)

| Constant | Default | Description | Range |
|----------|---------|-------------|-------|
| `DEFAULT_DURATION` | `0.4` | Total transition time | 0.2-0.8 |
| `DEFAULT_COLOR` | Near-black | Fade color | Any |
| `WHITE_COLOR` | White | White fade | - |

### Transition Types
| Type | Description |
|------|-------------|
| `FADE` | Simple fade to black |
| `FADE_WHITE` | Fade to white |
| `WIPE_LEFT` | Wipe from right to left |
| `WIPE_RIGHT` | Wipe from left to right |
| `WIPE_UP` | Wipe from bottom to top |
| `WIPE_DOWN` | Wipe from top to bottom |

### Recommended Durations
| Transition | Duration | Use Case |
|------------|----------|----------|
| Menu transitions | 0.3s | Quick, responsive |
| Battle start | 0.5s | Dramatic |
| Victory/Defeat | 0.6s | Allow moment to sink in |
| Settings | 0.25s | Very quick |

---

## Panel Transitions (`ui/panel_transitions.gd`)

| Constant | Default | Description | Range |
|----------|---------|-------------|-------|
| `DEFAULT_DURATION` | `0.25` | Animation time | 0.1-0.5 |
| `DEFAULT_EASE` | `EASE_OUT` | Easing function | - |
| `DEFAULT_TRANS` | `TRANS_QUAD` | Transition curve | - |
| `OVERSHOOT_TRANS` | `TRANS_BACK` | Bounce transition | - |

---

## Status Indicators (`game/status_indicators.gd`)

| Constant | Default | Description | Range |
|----------|---------|-------------|-------|
| `INDICATOR_SIZE` | `Vector2(8, 8)` | Icon size | 6-12 |
| `INDICATOR_OFFSET` | `Vector2(0, -24)` | Above target | -30 to -16 |
| `INDICATOR_SPACING` | `10.0` | Between icons | 8-14 |
| `PULSE_SPEED` | `3.0` | Pulse rate | 2-5 |
| `ICON_SCALE` | `1.5` | Display scale | 1.0-2.0 |

### Status Colors
| Status | Color | Hex |
|--------|-------|-----|
| `burn` | Orange-red | `#ff6619` |
| `slow` | Ice blue | `#4db3ff` |
| `poison` | Green | `#66e64d` |
| `shield` | Gold | `#e6d933` |
| `stun` | Yellow | `#ffff4d` |
| `weaken` | Purple | `#994d99` |
| `haste` | Cyan-green | `#4dff99` |
| `armor` | Steel | `#9999b3` |

---

## Battlefield.gd Polish Constants

### Combo System (lines 192-210)
| Constant | Value | Description |
|----------|-------|-------------|
| `COMBO_PULSE_DURATION` | `0.15` | Pulse animation time |
| `MILESTONE_POPUP_DURATION` | `1.2` | Popup display time |
| `MILESTONE_THRESHOLDS` | `[5,10,15,20,30,50]` | Combo milestones |

### Milestone Messages
| Threshold | Message |
|-----------|---------|
| 5 | "COMBO!" |
| 10 | "ON FIRE!" |
| 15 | "UNSTOPPABLE!" |
| 20 | "BLAZING!" |
| 30 | "LEGENDARY!" |
| 50 | "GODLIKE!" |

### Error Shake (lines 237-242)
| Constant | Value |
|----------|-------|
| `ERROR_SHAKE_INTENSITY` | `4.0` |
| `ERROR_SHAKE_DURATION` | `0.15` |

### Typing Pulse (lines 244-248)
| Constant | Value |
|----------|-------|
| `TYPING_PULSE_SCALE` | `1.08` |
| `TYPING_PULSE_DURATION` | `0.12` |

### Streak Glow Colors (lines 187-189)
| Streak | Color | Description |
|--------|-------|-------------|
| 3-9 | `#4db3ff66` | Cyan |
| 10-19 | `#806aff80` | Purple |
| 20+ | `#ffb33399` | Gold |

### Accuracy Badge Thresholds (lines 221-235)
| Streak | Label | Color |
|--------|-------|-------|
| 5 | "SHARP" | Light blue |
| 10 | "PRECISE" | Green |
| 20 | "FOCUSED" | Gold |
| 35 | "FLAWLESS" | Orange |
| 50 | "PERFECT" | Pink |

### Grade Thresholds (lines 252-258)
| Grade | Accuracy | Min WPM | Max Errors |
|-------|----------|---------|------------|
| S | 98% | 40 | 1 |
| A | 95% | 30 | 3 |
| B | 90% | 20 | 6 |
| C | 80% | 15 | 10 |
| D | 70% | 10 | 15 |

---

## Audio Manager Constants

### Rate Limiting
| Constant | Value | Description |
|----------|-------|-------------|
| `RATE_LIMIT_KEYTAP` | `0.05` | Key press cooldown |
| `RATE_LIMIT_TYPE` | `0.03` | Typing sound cooldown |

### Music
| Constant | Value |
|----------|-------|
| `MUSIC_FADE_DURATION` | `1.5s` |
| `SFX_POOL_SIZE` | `8` |

---

## Recommended Tuning Profiles

### Subtle (for sensitive users)
```gdscript
# screen_shake.gd
MAX_OFFSET = Vector2(8, 6)
MAX_ROTATION = 0.01
DECAY_RATE = 1.2

# hit_pause.gd
PRESET_HEAVY = 0.06

# damage_numbers.gd
BASE_FONT_SIZE = 14
LIFETIME = 0.6
```

### Punchy (for action feel)
```gdscript
# screen_shake.gd
MAX_OFFSET = Vector2(25, 20)
MAX_ROTATION = 0.06
DECAY_RATE = 0.6

# hit_pause.gd
PRESET_HEAVY = 0.15

# damage_numbers.gd
BASE_FONT_SIZE = 18
CRIT_FONT_SIZE = 28
```

### Performance (for low-end devices)
```gdscript
# hit_effects.gd
POOL_SIZE = 50
MAX_POOL_SIZE = 100
PARTICLE_COUNT = 4

# damage_numbers.gd
POOL_SIZE = 10
MAX_POOL_SIZE = 25
```
