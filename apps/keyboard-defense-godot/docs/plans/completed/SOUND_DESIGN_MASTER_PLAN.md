# Sound Design Master Plan

## Executive Summary

This document outlines the complete audio design specification for Keyboard Defense. All audio is generated procedurally via the `sfx_presets.json` synthesizer system, eliminating the need for licensed audio assets.

**Target**: ~80 unique sound effects + ambient/music specifications
**Implementation**: 100% procedural via Godot AudioStreamGenerator
**Style**: Retro-inspired synth with warm, satisfying feedback

---

## Current Audio Inventory

### Existing Presets (48 sounds)
From `data/audio/sfx_presets.json`:

#### UI Category (5)
- [x] `ui_keytap` - Subtle key press
- [x] `ui_confirm` - Positive confirmation
- [x] `ui_cancel` - Negative cancel
- [x] `tutorial_ding` - Tutorial completion

#### Typing Category (6)
- [x] `type_correct` - Correct character
- [x] `type_mistake` - Incorrect character
- [x] `combo_up` - Combo milestone
- [x] `combo_break` - Combo broken
- [x] `word_complete` - Full word typed

#### World Category (6)
- [x] `build_place` - Building placement
- [x] `build_complete` - Construction finished
- [x] `resource_pickup` - Resource collected
- [x] `unit_spawn` - Friendly unit appears
- [x] `enemy_spawn` - Enemy appears
- [x] `wave_start` - New wave begins
- [x] `wave_end` - Wave completed

#### Combat Category (6)
- [x] `hit_player` - Castle takes damage
- [x] `hit_enemy` - Enemy takes damage
- [x] `enemy_death` - Enemy defeated
- [x] `critical_hit` - Critical damage
- [x] `boss_appear` - Boss spawns
- [x] `boss_defeated` - Boss killed

#### Tower Category (11)
- [x] `tower_arrow` - Arrow projectile
- [x] `tower_cannon` - Cannon blast
- [x] `tower_fire` - Flame burst
- [x] `tower_ice` - Frost shot
- [x] `tower_lightning` - Electric zap
- [x] `tower_poison` - Poison spit
- [x] `tower_arcane` - Magic bolt
- [x] `tower_holy` - Radiance
- [x] `tower_siege` - Heavy blast
- [x] `tower_multi` - Multi-shot volley

#### Status Category (10)
- [x] `status_freeze` - Frozen applied
- [x] `status_burn` - Burn tick
- [x] `status_poison` - Poison tick
- [x] `status_stun` - Stun applied
- [x] `status_slow` - Slow applied
- [x] `shield_activate` - Shield buff
- [x] `shield_break` - Shield depleted
- [x] `heal_tick` - Health restored
- [x] `speed_boost` - Speed buff
- [x] `damage_boost` - Damage buff

#### Progression Category (3)
- [x] `level_up` - Level increase
- [x] `achievement_unlock` - Achievement earned
- [x] `upgrade_purchase` - Upgrade bought

#### Stinger Category (2)
- [x] `victory_fanfare` - Battle won
- [x] `defeat_stinger` - Battle lost

---

## Sound Design Philosophy

### Core Principles

1. **Satisfying Feedback**
   - Every action has immediate audio response
   - Typing sounds must be pleasant at high frequency
   - Success feels rewarding, failure is informative not punishing

2. **Audio Hierarchy**
   - **Critical**: Player damage, boss spawns, wave alerts
   - **Important**: Combo milestones, word completion, upgrades
   - **Ambient**: Typing, tower shots, enemy hits
   - **Background**: Environmental, music

3. **Retro-Synth Aesthetic**
   - Warm sine and triangle waves for pleasant sounds
   - Sawtooth and square for urgency/danger
   - Noise for impacts and environmental

4. **Accessibility**
   - All critical info has visual alternative
   - Audio can be disabled without gameplay impact
   - Volume categories for granular control

### Frequency Ranges

| Category | Fundamental Hz | Purpose |
|----------|---------------|---------|
| Typing feedback | 600-1200 | Clear, mid-range, non-fatiguing |
| UI | 800-1200 | Crisp, attention-getting |
| Combat | 100-400 | Impactful, weighty |
| Victory | 400-900 | Uplifting, harmonic |
| Danger | 100-300 | Low, ominous |
| Ambient | Variable | Non-intrusive |

---

## Phase 1: Missing Essential SFX

### UI Sounds (Priority: High)
```json
{
  "id": "ui_hover",
  "description": "Button/menu hover",
  "category": "ui",
  "oscillator": {"type": "sine", "frequency": 1200},
  "envelope": {"attack_ms": 2, "decay_ms": 20, "sustain": 0.0, "release_ms": 15},
  "volume": 0.1,
  "duration_ms": 35
}
```

- [ ] `ui_hover` - Menu item hover
- [ ] `ui_click` - Generic button click
- [ ] `ui_open_panel` - Panel/menu opens
- [ ] `ui_close_panel` - Panel/menu closes
- [ ] `ui_tab_switch` - Tab navigation
- [ ] `ui_scroll` - Scroll feedback (subtle)
- [ ] `ui_slider_tick` - Volume slider tick
- [ ] `ui_toggle_on` - Toggle enabled
- [ ] `ui_toggle_off` - Toggle disabled
- [ ] `ui_error` - Invalid action attempted

### Typing Sounds (Priority: High)
- [ ] `type_space` - Spacebar hit (distinct from letter)
- [ ] `type_backspace` - Delete character
- [ ] `type_enter` - Submit command
- [ ] `type_target_lock` - Target selected (first letter match)
- [ ] `type_target_lost` - Target escaped/killed by other
- [ ] `word_perfect` - Word with no mistakes (variant of word_complete)
- [ ] `speed_bonus` - Fast completion bonus
- [ ] `accuracy_bonus` - High accuracy bonus

### Combat Sounds (Priority: High)
- [ ] `projectile_launch` - Generic projectile fired
- [ ] `projectile_impact` - Generic impact
- [ ] `enemy_attack` - Enemy attacks castle
- [ ] `enemy_special` - Elite/affix ability
- [ ] `armor_hit` - Armored enemy reduces damage
- [ ] `dodge` - Attack missed/dodged
- [ ] `reflect` - Damage reflected back
- [ ] `chain_lightning` - Lightning chain jump
- [ ] `splash_damage` - Area damage applied
- [ ] `overkill` - Excessive damage dealt

---

## Phase 2: Atmospheric & Environmental

### Ambient Sounds
- [ ] `ambient_wind_light` - Soft background wind
- [ ] `ambient_wind_storm` - Storm/threat high
- [ ] `ambient_fire_crackle` - Burning nearby
- [ ] `ambient_magic_hum` - Arcane towers active
- [ ] `ambient_nature` - Peaceful, day phase
- [ ] `ambient_tension` - Night phase, enemies active

### Environmental Events
- [ ] `day_dawn` - Day phase begins
- [ ] `night_fall` - Night phase begins
- [ ] `thunder_distant` - Storm brewing (threat rising)
- [ ] `earthquake_rumble` - Boss approaching
- [ ] `wind_gust` - Random environmental
- [ ] `bird_chirp` - Peaceful day ambiance

### Building Sounds
- [ ] `building_upgrade` - Structure leveled up
- [ ] `building_destroy` - Structure destroyed
- [ ] `building_repair` - Structure being repaired
- [ ] `worker_assign` - Worker assigned to building
- [ ] `worker_complete` - Worker finished task
- [ ] `production_tick` - Resource generated
- [ ] `gold_coins` - Gold received (coin jingle)

---

## Phase 3: Advanced Combat & Effects

### Enemy-Specific Sounds
- [ ] `enemy_grunt_hit` - Basic enemy hurt
- [ ] `enemy_grunt_death` - Basic enemy dies
- [ ] `enemy_elite_roar` - Elite spawn
- [ ] `enemy_elite_death` - Elite defeated
- [ ] `enemy_boss_roar` - Boss entrance
- [ ] `enemy_boss_phase` - Boss phase change
- [ ] `enemy_heal` - Enemy regenerates
- [ ] `enemy_speed_up` - Enemy enraged/faster
- [ ] `enemy_shield_up` - Enemy gains shield
- [ ] `enemy_summon` - Enemy spawns minions

### Affix Sounds
- [ ] `affix_armored_hit` - Armored damage reduction
- [ ] `affix_swift_dash` - Swift movement burst
- [ ] `affix_regenerate` - Healing tick
- [ ] `affix_explosive_warn` - Explosive primed
- [ ] `affix_explosive_boom` - Explosive death
- [ ] `affix_splitter_split` - Splits into smaller
- [ ] `affix_vampiric_drain` - Life steal
- [ ] `affix_reflective_bounce` - Damage reflected
- [ ] `affix_phasing` - Phase in/out
- [ ] `affix_enraged_roar` - Enrage triggers

### Combo System
- [ ] `combo_2x` - 2x multiplier
- [ ] `combo_3x` - 3x multiplier
- [ ] `combo_4x` - 4x multiplier
- [ ] `combo_5x` - 5x multiplier (rare)
- [ ] `combo_max` - Maximum combo achieved
- [ ] `combo_extend` - Combo timer extended
- [ ] `streak_5` - 5 perfect words
- [ ] `streak_10` - 10 perfect words
- [ ] `streak_25` - 25 perfect words
- [ ] `streak_50` - 50 perfect words (legendary)

---

## Phase 4: Progression & Rewards

### Achievement Sounds
- [ ] `achievement_bronze` - Bronze tier unlock
- [ ] ] `achievement_silver` - Silver tier unlock
- [ ] `achievement_gold` - Gold tier unlock
- [ ] `achievement_platinum` - Platinum tier unlock
- [ ] `achievement_secret` - Hidden achievement
- [ ] `milestone_reached` - Generic milestone
- [ ] `daily_complete` - Daily challenge done
- [ ] `weekly_complete` - Weekly challenge done

### Research & Upgrade
- [ ] `research_start` - Begin research
- [ ] `research_progress` - Research tick
- [ ] `research_complete` - Research finished
- [ ] `tech_unlock` - Technology unlocked
- [ ] `upgrade_common` - Common upgrade
- [ ] `upgrade_rare` - Rare upgrade
- [ ] `upgrade_epic` - Epic upgrade
- [ ] `upgrade_legendary` - Legendary upgrade

### Story & Events
- [ ] `dialogue_character` - Character speaks (blip)
- [ ] `dialogue_advance` - Next dialogue line
- [ ] `dialogue_choice` - Choice selected
- [ ] `story_reveal` - Lore discovered
- [ ] `event_appear` - POI event spawns
- [ ] `event_positive` - Good event outcome
- [ ] `event_negative` - Bad event outcome
- [ ] `event_neutral` - Neutral outcome

---

## Phase 5: Polish & Variation

### Sound Variations
Each major sound should have 2-4 variants to prevent audio fatigue:

**Typing Correct Variations:**
- `type_correct_1` - Base pitch
- `type_correct_2` - Slightly higher
- `type_correct_3` - Slightly lower
- `type_correct_4` - With harmonic

**Enemy Death Variations:**
- `enemy_death_1` - Standard
- `enemy_death_2` - Higher pitch
- `enemy_death_3` - With echo
- `enemy_death_4` - Crunchy

**Tower Shot Variations (per type):**
- Each tower type gets 2-3 shot variants
- Randomized on fire for organic feel

### Pitch Variation System
For sounds marked `[vary]`, apply random pitch offset:
```json
"pitch_variance": {
  "min_offset": -50,
  "max_offset": 50,
  "mode": "random"
}
```

---

## Music System Specification

### Overview
Music is generated procedurally using layered loops and dynamic mixing.

### Track List

#### Main Menu Theme
- **Mood**: Hopeful, adventurous, inviting
- **Tempo**: 100 BPM
- **Key**: C Major
- **Layers**:
  1. Pad drone (sustained chords)
  2. Arpeggiated melody (sine wave)
  3. Light percussion (optional)
- **Duration**: 2-minute loop

#### Kingdom Hub Theme
- **Mood**: Peaceful, productive, warm
- **Tempo**: 90 BPM
- **Key**: G Major
- **Layers**:
  1. Ambient pad
  2. Gentle melody (triangle)
  3. Soft bass pulse
- **Duration**: 3-minute loop

#### Day Phase Theme
- **Mood**: Calm, focused, strategic
- **Tempo**: 85 BPM
- **Key**: D Major
- **Layers**:
  1. Ambient foundation
  2. Typing rhythm sync (optional)
  3. Building activity stingers
- **Dynamic**: Fades based on activity

#### Night Phase Theme
- **Mood**: Tense, urgent, heroic
- **Tempo**: 120 BPM
- **Key**: D Minor
- **Layers**:
  1. Driving bass
  2. Tension strings (sawtooth)
  3. Action percussion
  4. Heroic brass stabs
- **Dynamic**: Intensity scales with threat

#### Boss Battle Theme
- **Mood**: Epic, dangerous, climactic
- **Tempo**: 140 BPM
- **Key**: E Minor
- **Layers**:
  1. Heavy bass drops
  2. Aggressive leads
  3. Choir stabs (harmonics)
  4. Intense percussion
- **Triggers**: Phase changes sync

#### Victory Theme
- **Mood**: Triumphant, celebratory
- **Tempo**: 110 BPM
- **Key**: F Major
- **Duration**: 15-second stinger → 1-minute loop
- **Instruments**: Full harmonic stack

#### Defeat Theme
- **Mood**: Somber, reflective
- **Tempo**: 70 BPM
- **Key**: A Minor
- **Duration**: 10-second stinger
- **Instruments**: Low strings, fading

---

## Audio Mixing Guidelines

### Volume Hierarchy
```json
{
  "master_volume": 0.8,
  "categories": {
    "music": 0.5,
    "sfx": 0.7,
    "typing": 0.6,
    "ui": 0.65,
    "ambient": 0.3,
    "voice": 0.85
  }
}
```

### Ducking Rules
```json
{
  "ducking": {
    "typing_active": {
      "target": ["music", "ambient"],
      "amount": 0.3,
      "attack_ms": 100,
      "release_ms": 500
    },
    "wave_start": {
      "target": ["music"],
      "amount": 0.5,
      "attack_ms": 200,
      "release_ms": 1000
    },
    "boss_roar": {
      "target": ["sfx", "typing"],
      "amount": 0.4,
      "attack_ms": 50,
      "release_ms": 300
    }
  }
}
```

### Rate Limiting
```json
{
  "rate_limits": {
    "ui_keytap": {"max_per_second": 12, "cooldown_ms": 83},
    "type_correct": {"max_per_second": 15, "cooldown_ms": 66},
    "enemy_death": {"max_per_second": 8, "cooldown_ms": 125},
    "projectile_impact": {"max_per_second": 10, "cooldown_ms": 100}
  }
}
```

### Polyphony Limits
```json
{
  "max_concurrent": {
    "typing": 3,
    "combat": 6,
    "tower": 8,
    "ambient": 2,
    "ui": 2,
    "music": 1
  }
}
```

---

## Procedural Audio Parameters Reference

### Oscillator Types
| Type | Character | Best For |
|------|-----------|----------|
| `sine` | Pure, warm, smooth | Pleasant feedback, melodies |
| `triangle` | Soft, hollow | Calm sounds, pads |
| `square` | Buzzy, retro | 8-bit feel, alerts |
| `sawtooth` | Harsh, bright | Danger, intensity |
| `noise` | Random, percussive | Impacts, explosions, wind |

### Envelope Timing Guidelines
| Sound Type | Attack | Decay | Sustain | Release |
|------------|--------|-------|---------|---------|
| Snappy UI | 2-5ms | 20-40ms | 0.0-0.2 | 20-50ms |
| Typing | 3-10ms | 40-80ms | 0.1-0.3 | 40-80ms |
| Impact | 2-10ms | 40-100ms | 0.0-0.1 | 30-60ms |
| Ambient | 50-200ms | 100-300ms | 0.3-0.6 | 100-300ms |
| Stinger | 10-50ms | 150-300ms | 0.4-0.6 | 200-500ms |

### Filter Types
| Type | Effect | Use Case |
|------|--------|----------|
| `lowpass` | Removes highs, muffled | Distance, underwater |
| `highpass` | Removes lows, thin | Sharpness, clarity |
| `bandpass` | Isolates middle | Radio, telephone |

### Pitch Slide Curves
| Curve | Effect |
|-------|--------|
| `linear` | Steady change |
| `exponential` | Fast start, slow end (natural) |
| `inverse_exponential` | Slow start, fast end |

---

## Implementation Checklist

### Phase 1 (Essential)
- [ ] Add missing UI sounds to sfx_presets.json
- [ ] Add missing typing feedback sounds
- [ ] Add missing combat sounds
- [ ] Update audio_manager.gd to play new sounds
- [ ] Test all sounds in-game

### Phase 2 (Atmosphere)
- [ ] Add ambient sound presets
- [ ] Add environmental event sounds
- [ ] Add building sounds
- [ ] Implement ambient layer system
- [ ] Add day/night ambient transitions

### Phase 3 (Combat Polish)
- [ ] Add enemy-specific sounds
- [ ] Add affix sounds
- [ ] Add combo milestone sounds
- [ ] Wire up all combat events
- [ ] Balance combat audio mix

### Phase 4 (Progression)
- [ ] Add achievement tier sounds
- [ ] Add research sounds
- [ ] Add story/dialogue sounds
- [ ] Add event sounds
- [ ] Test full progression audio

### Phase 5 (Polish)
- [ ] Create sound variations
- [ ] Implement pitch variance
- [ ] Fine-tune volume balance
- [ ] Implement ducking system
- [ ] Optimize audio performance

### Phase 6 (Music)
- [ ] Implement procedural music generator
- [ ] Create main menu theme
- [ ] Create gameplay themes
- [ ] Add boss battle music
- [ ] Implement dynamic music layers
- [ ] Add crossfade transitions

---

## Quality Checklist

### Per-Sound Verification
- [ ] Volume appropriate relative to category
- [ ] Duration matches action length
- [ ] Doesn't cause audio fatigue at high frequency
- [ ] Clearly communicates its purpose
- [ ] Distinct from similar sounds

### System Verification
- [ ] No audio clipping at max volume
- [ ] Rate limiting prevents spam
- [ ] Polyphony limits respected
- [ ] Ducking transitions smooth
- [ ] All game events have audio

### Accessibility Verification
- [ ] Critical events have visual feedback
- [ ] Audio categories independently adjustable
- [ ] Can play without audio (no gameplay impact)
- [ ] Frequency ranges avoid hearing damage

---

## Asset Count Summary

| Category | Existing | New | Total |
|----------|----------|-----|-------|
| UI | 5 | 10 | 15 |
| Typing | 5 | 8 | 13 |
| Combat | 6 | 10 | 16 |
| Tower | 11 | 0 | 11 |
| Status | 10 | 0 | 10 |
| Progression | 3 | 8 | 11 |
| Stinger | 2 | 0 | 2 |
| Ambient | 0 | 6 | 6 |
| Environmental | 0 | 6 | 6 |
| Building | 0 | 7 | 7 |
| Enemy | 0 | 10 | 10 |
| Affix | 0 | 10 | 10 |
| Combo | 0 | 10 | 10 |
| Achievement | 0 | 8 | 8 |
| Research | 0 | 5 | 5 |
| Story | 0 | 8 | 8 |
| Variations | 0 | ~30 | ~30 |
| **TOTAL** | **48** | **~136** | **~178** |

Plus music tracks:
- Main menu theme
- Kingdom hub theme
- Day phase theme
- Night phase theme
- Boss battle theme
- Victory/defeat stingers

**Estimated new presets to add: ~130-140**
