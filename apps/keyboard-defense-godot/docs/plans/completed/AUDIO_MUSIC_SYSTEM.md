# Audio & Music System

**Created:** 2026-01-08

Complete specification for sound effects, music, and audio design.

---

## Audio Philosophy

### Design Goals

```
┌─────────────────────────────────────────────────────────────┐
│                 AUDIO DESIGN GOALS                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. RESPONSIVE FEEDBACK                                     │
│     → Every keystroke produces satisfying sound             │
│     → Audio confirms success/failure instantly              │
│     → Sound enhances typing rhythm                          │
│                                                             │
│  2. ATMOSPHERIC IMMERSION                                   │
│     → Music reflects region and mood                        │
│     → Ambient sounds create sense of place                  │
│     → Combat intensity matches music dynamics               │
│                                                             │
│  3. NON-INTRUSIVE                                           │
│     → Audio never distracts from typing                     │
│     → Music loops seamlessly                                │
│     → Volume balanced for extended play                     │
│                                                             │
│  4. ACCESSIBILITY                                           │
│     → Visual alternatives for all audio cues                │
│     → Granular volume controls                              │
│     → Captions for important dialogue                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Audio Categories

### Category Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                    AUDIO HIERARCHY                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  MASTER VOLUME                                              │
│  ├── MUSIC                                                  │
│  │   ├── Ambient/Exploration                               │
│  │   ├── Combat                                            │
│  │   └── Boss                                              │
│  │                                                         │
│  ├── SOUND EFFECTS                                         │
│  │   ├── Typing                                            │
│  │   ├── Combat                                            │
│  │   ├── Environment                                       │
│  │   └── Rewards                                           │
│  │                                                         │
│  ├── UI                                                    │
│  │   ├── Navigation                                        │
│  │   ├── Feedback                                          │
│  │   └── Notifications                                     │
│  │                                                         │
│  └── VOICE (Future)                                        │
│      ├── Narrator                                          │
│      └── NPC                                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Typing Sounds

### Keystroke Audio

```json
{
  "typing_sounds": {
    "key_press": {
      "variations": 5,
      "files": [
        "key_press_01.wav",
        "key_press_02.wav",
        "key_press_03.wav",
        "key_press_04.wav",
        "key_press_05.wav"
      ],
      "volume": -6,
      "pitch_variation": 0.05,
      "selection": "random_no_repeat"
    },
    "key_correct": {
      "description": "Played on correct letter",
      "file": "key_correct.wav",
      "volume": -3,
      "pitch_scale_by_combo": {
        "enabled": true,
        "min_pitch": 1.0,
        "max_pitch": 1.3,
        "combo_for_max": 20
      }
    },
    "key_error": {
      "description": "Played on wrong letter",
      "file": "key_error.wav",
      "volume": 0,
      "pitch": 0.9
    },
    "backspace": {
      "file": "backspace.wav",
      "volume": -6
    },
    "space": {
      "file": "space_bar.wav",
      "volume": -6,
      "pitch_variation": 0.03
    }
  }
}
```

### Word Completion Sounds

```json
{
  "word_sounds": {
    "word_complete": {
      "description": "Normal word finished",
      "file": "word_complete.wav",
      "volume": -3
    },
    "word_perfect": {
      "description": "Word completed with 100% accuracy",
      "file": "word_perfect.wav",
      "volume": 0,
      "layers": ["chime", "sparkle"]
    },
    "combo_5": {
      "description": "5 combo reached",
      "file": "combo_tier_1.wav",
      "volume": -3
    },
    "combo_10": {
      "file": "combo_tier_2.wav",
      "volume": -1
    },
    "combo_20": {
      "file": "combo_tier_3.wav",
      "volume": 0,
      "layers": ["bass_drop"]
    },
    "combo_50": {
      "file": "combo_tier_4.wav",
      "volume": 3,
      "layers": ["epic_chord"]
    },
    "combo_break": {
      "file": "combo_break.wav",
      "volume": -6
    }
  }
}
```

### Keyboard Sound Themes

```json
{
  "keyboard_themes": {
    "mechanical": {
      "name": "Mechanical Keyboard",
      "description": "Classic clicky mechanical sounds",
      "files": "sfx/keyboards/mechanical/",
      "unlock": "default"
    },
    "typewriter": {
      "name": "Vintage Typewriter",
      "description": "Old-school typewriter clicks and dings",
      "files": "sfx/keyboards/typewriter/",
      "unlock": "collect_all_lore"
    },
    "digital": {
      "name": "Digital Soft",
      "description": "Soft digital keyboard sounds",
      "files": "sfx/keyboards/digital/",
      "unlock": "level_25"
    },
    "fantasy": {
      "name": "Magical Keys",
      "description": "Fantasy-themed magical sounds",
      "files": "sfx/keyboards/fantasy/",
      "unlock": "complete_all_realms"
    },
    "silent": {
      "name": "Silent Mode",
      "description": "Minimal sound feedback",
      "files": null,
      "visual_only": true,
      "unlock": "default"
    }
  }
}
```

---

## Music System

### Track Categories

| Category | Tempo | Energy | Usage |
|----------|-------|--------|-------|
| Main Menu | 80-100 BPM | Low | Title screen |
| Exploration | 90-110 BPM | Low-Medium | Map navigation |
| Combat | 120-140 BPM | Medium-High | Regular waves |
| Boss | 140-160 BPM | High | Boss encounters |
| Victory | 100-120 BPM | Medium | Wave/battle won |
| Defeat | 60-80 BPM | Low | Game over |

### Regional Music

```json
{
  "region_music": {
    "castle_keystonia": {
      "exploration": "music/castle_theme.ogg",
      "combat": "music/castle_battle.ogg",
      "mood": "hopeful, heroic"
    },
    "evergrove": {
      "exploration": "music/forest_ambient.ogg",
      "combat": "music/forest_battle.ogg",
      "mood": "peaceful, mysterious"
    },
    "sunfields": {
      "exploration": "music/plains_theme.ogg",
      "combat": "music/arena_battle.ogg",
      "mood": "bright, competitive"
    },
    "stonepass": {
      "exploration": "music/mountain_echo.ogg",
      "combat": "music/mountain_battle.ogg",
      "mood": "majestic, dangerous"
    },
    "mistfen": {
      "exploration": "music/swamp_ambient.ogg",
      "combat": "music/swamp_battle.ogg",
      "mood": "eerie, tense"
    },
    "citadel": {
      "exploration": "music/citadel_grandeur.ogg",
      "combat": "music/citadel_defense.ogg",
      "mood": "regal, determined"
    },
    "fire_realm": {
      "exploration": "music/fire_realm.ogg",
      "combat": "music/fire_realm.ogg",
      "mood": "intense, relentless",
      "note": "Same track, tempo tied to gameplay"
    },
    "ice_realm": {
      "exploration": "music/ice_realm.ogg",
      "combat": "music/ice_realm.ogg",
      "mood": "cold, precise"
    },
    "nature_realm": {
      "exploration": "music/nature_realm.ogg",
      "combat": "music/nature_realm.ogg",
      "mood": "balanced, flowing"
    },
    "void_rift": {
      "exploration": "music/void_approach.ogg",
      "combat": "music/void_battle.ogg",
      "boss": "music/void_tyrant.ogg",
      "mood": "dark, oppressive, climactic"
    }
  }
}
```

### Boss Music

```json
{
  "boss_music": {
    "grove_guardian": {
      "intro": "music/boss/grove_guardian_intro.ogg",
      "loop": "music/boss/grove_guardian_loop.ogg",
      "phase2": "music/boss/grove_guardian_phase2.ogg",
      "victory": "music/boss/grove_guardian_victory.ogg"
    },
    "sunlord_champion": {
      "intro": "music/boss/sunlord_intro.ogg",
      "loop": "music/boss/sunlord_loop.ogg",
      "phase2": "music/boss/sunlord_phase2.ogg",
      "phase3": "music/boss/sunlord_phase3.ogg",
      "victory": "music/boss/sunlord_victory.ogg"
    },
    "void_tyrant": {
      "approach": "music/boss/void_approach.ogg",
      "phase1": "music/boss/void_tyrant_p1.ogg",
      "phase2": "music/boss/void_tyrant_p2.ogg",
      "phase3": "music/boss/void_tyrant_p3.ogg",
      "phase4": "music/boss/void_tyrant_finale.ogg",
      "victory": "music/boss/void_tyrant_victory.ogg"
    }
  }
}
```

### Dynamic Music System

```json
{
  "dynamic_music": {
    "combat_intensity": {
      "description": "Music layers add based on combat state",
      "layers": {
        "base": "Always playing during combat",
        "drums": "Added when enemies > 5",
        "strings": "Added when HP < 50%",
        "choir": "Added during combo > 20",
        "brass": "Added in final wave"
      }
    },
    "typing_sync": {
      "description": "Music responds to typing rhythm",
      "features": {
        "tempo_match": "Slight BPM adjustment to player rhythm",
        "hit_sync": "Percussion hits on perfect words",
        "crescendo": "Building intensity with combo"
      }
    },
    "transitions": {
      "exploration_to_combat": "2s crossfade",
      "combat_to_victory": "Immediate stinger, then fade",
      "phase_change": "Seamless loop point transition"
    }
  }
}
```

---

## Combat Sound Effects

### Enemy Sounds

```json
{
  "enemy_sounds": {
    "spawn": {
      "typhos_spawn": "sfx/enemies/spawn_small.wav",
      "typhos_scout": "sfx/enemies/spawn_medium.wav",
      "typhos_lord": "sfx/enemies/spawn_large.wav"
    },
    "movement": {
      "ground": "sfx/enemies/footstep_ground.wav",
      "fly": "sfx/enemies/wings_flap.wav",
      "slither": "sfx/enemies/slither.wav"
    },
    "attack": {
      "melee": "sfx/enemies/attack_melee.wav",
      "ranged": "sfx/enemies/attack_arrow.wav",
      "magic": "sfx/enemies/attack_magic.wav"
    },
    "hit": {
      "normal": "sfx/enemies/hit_normal.wav",
      "armored": "sfx/enemies/hit_armored.wav",
      "critical": "sfx/enemies/hit_critical.wav"
    },
    "death": {
      "small": "sfx/enemies/death_small.wav",
      "medium": "sfx/enemies/death_medium.wav",
      "large": "sfx/enemies/death_large.wav",
      "boss": "sfx/enemies/death_boss.wav"
    }
  }
}
```

### Tower Sounds

```json
{
  "tower_sounds": {
    "arrow": {
      "fire": "sfx/towers/arrow_fire.wav",
      "hit": "sfx/towers/arrow_hit.wav"
    },
    "arcane": {
      "charge": "sfx/towers/arcane_charge.wav",
      "fire": "sfx/towers/arcane_fire.wav",
      "hit": "sfx/towers/arcane_hit.wav",
      "chain": "sfx/towers/arcane_chain.wav"
    },
    "holy": {
      "pulse": "sfx/towers/holy_pulse.wav",
      "smite": "sfx/towers/holy_smite.wav",
      "heal": "sfx/towers/holy_heal.wav"
    },
    "siege": {
      "load": "sfx/towers/siege_load.wav",
      "fire": "sfx/towers/siege_fire.wav",
      "explosion": "sfx/towers/siege_explosion.wav"
    },
    "multi": {
      "fire": "sfx/towers/multi_fire.wav",
      "mark": "sfx/towers/multi_mark.wav"
    },
    "build": "sfx/towers/tower_build.wav",
    "upgrade": "sfx/towers/tower_upgrade.wav",
    "sell": "sfx/towers/tower_sell.wav"
  }
}
```

### Castle/Damage Sounds

```json
{
  "castle_sounds": {
    "hit_light": "sfx/castle/hit_light.wav",
    "hit_heavy": "sfx/castle/hit_heavy.wav",
    "low_hp_warning": "sfx/castle/warning_low_hp.wav",
    "critical_hp": "sfx/castle/warning_critical.wav",
    "destroyed": "sfx/castle/castle_destroyed.wav",
    "repair": "sfx/castle/castle_repair.wav"
  }
}
```

---

## Ambient Sounds

### Environmental Audio

```json
{
  "ambient_sounds": {
    "evergrove": {
      "layers": [
        {"id": "birds", "file": "ambient/forest_birds.ogg", "volume": -12},
        {"id": "wind", "file": "ambient/wind_leaves.ogg", "volume": -15},
        {"id": "stream", "file": "ambient/water_stream.ogg", "volume": -18, "zones": ["riverside"]}
      ],
      "random_events": [
        {"id": "owl", "file": "ambient/owl_hoot.wav", "interval": [30, 60], "time": "night"}
      ]
    },
    "stonepass": {
      "layers": [
        {"id": "wind", "file": "ambient/mountain_wind.ogg", "volume": -10},
        {"id": "echoes", "file": "ambient/cave_echo.ogg", "volume": -15, "zones": ["caves"]}
      ],
      "random_events": [
        {"id": "rockfall", "file": "ambient/distant_rockfall.wav", "interval": [45, 90]}
      ]
    },
    "mistfen": {
      "layers": [
        {"id": "bugs", "file": "ambient/swamp_bugs.ogg", "volume": -10},
        {"id": "water", "file": "ambient/swamp_bubbles.ogg", "volume": -12}
      ],
      "random_events": [
        {"id": "frog", "file": "ambient/frog_croak.wav", "interval": [20, 45]}
      ]
    },
    "void_rift": {
      "layers": [
        {"id": "drone", "file": "ambient/void_drone.ogg", "volume": -8},
        {"id": "whispers", "file": "ambient/void_whispers.ogg", "volume": -15}
      ],
      "random_events": [
        {"id": "pulse", "file": "ambient/void_pulse.wav", "interval": [15, 30]}
      ]
    }
  }
}
```

### Weather Sounds

```json
{
  "weather_sounds": {
    "rain": {
      "light": "ambient/rain_light.ogg",
      "heavy": "ambient/rain_heavy.ogg"
    },
    "storm": {
      "wind": "ambient/storm_wind.ogg",
      "thunder": [
        "ambient/thunder_01.wav",
        "ambient/thunder_02.wav",
        "ambient/thunder_03.wav"
      ],
      "thunder_interval": [10, 30]
    },
    "snow": {
      "ambient": "ambient/snow_wind.ogg"
    },
    "fog": {
      "ambient": "ambient/fog_eerie.ogg"
    }
  }
}
```

---

## UI Sounds

### Navigation

```json
{
  "ui_navigation": {
    "hover": "sfx/ui/hover.wav",
    "click": "sfx/ui/click.wav",
    "back": "sfx/ui/back.wav",
    "open_menu": "sfx/ui/menu_open.wav",
    "close_menu": "sfx/ui/menu_close.wav",
    "tab_switch": "sfx/ui/tab_switch.wav",
    "scroll": "sfx/ui/scroll.wav"
  }
}
```

### Feedback

```json
{
  "ui_feedback": {
    "success": "sfx/ui/success.wav",
    "error": "sfx/ui/error.wav",
    "warning": "sfx/ui/warning.wav",
    "purchase": "sfx/ui/coin_purchase.wav",
    "sell": "sfx/ui/coin_sell.wav",
    "equip": "sfx/ui/equip.wav",
    "unequip": "sfx/ui/unequip.wav",
    "level_up": "sfx/ui/level_up.wav",
    "achievement": "sfx/ui/achievement.wav",
    "quest_complete": "sfx/ui/quest_complete.wav",
    "new_quest": "sfx/ui/quest_new.wav"
  }
}
```

### Notifications

```json
{
  "ui_notifications": {
    "message": "sfx/ui/notification.wav",
    "alert": "sfx/ui/alert.wav",
    "daily_reset": "sfx/ui/daily_reset.wav",
    "boss_approaching": "sfx/ui/boss_warning.wav"
  }
}
```

---

## Audio Engine

### Audio Bus Layout

```
┌─────────────────────────────────────────────────────────────┐
│                    AUDIO BUS STRUCTURE                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Master ─┬─ Music ─────┬─ Exploration                      │
│          │             ├─ Combat                            │
│          │             └─ Boss                              │
│          │                                                  │
│          ├─ SFX ───────┬─ Typing                           │
│          │             ├─ Combat                            │
│          │             ├─ Environment                       │
│          │             └─ Rewards                           │
│          │                                                  │
│          ├─ UI ────────┬─ Navigation                       │
│          │             └─ Feedback                          │
│          │                                                  │
│          └─ Ambient ───┬─ Environmental                    │
│                        └─ Weather                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Audio Manager API

```gdscript
# audio_manager.gd

class_name AudioManager
extends Node

# Music
func play_music(track: String, fade_time: float = 1.0) -> void
func stop_music(fade_time: float = 1.0) -> void
func set_music_layer(layer: String, enabled: bool) -> void
func crossfade_music(new_track: String, duration: float = 2.0) -> void

# Sound Effects
func play_sfx(sound: String, volume_db: float = 0.0, pitch: float = 1.0) -> void
func play_sfx_at_position(sound: String, position: Vector2) -> void
func play_typing_sound(correct: bool, combo: int) -> void

# Ambient
func set_ambient_region(region: String) -> void
func set_weather_sound(weather: String) -> void
func trigger_random_ambient() -> void

# UI
func play_ui(sound: String) -> void

# Volume Control
func set_bus_volume(bus: String, volume: float) -> void
func get_bus_volume(bus: String) -> float
func mute_bus(bus: String, muted: bool) -> void
```

---

## Implementation Checklist

- [ ] Set up audio bus structure
- [ ] Implement AudioManager singleton
- [ ] Create typing sound system
- [ ] Add word completion sounds
- [ ] Implement combo sound escalation
- [ ] Create dynamic music system
- [ ] Add music layer system
- [ ] Implement crossfade transitions
- [ ] Add regional ambient sounds
- [ ] Implement weather audio
- [ ] Create enemy sound effects
- [ ] Add tower sound effects
- [ ] Implement UI sound system
- [ ] Add keyboard sound themes
- [ ] Create volume settings UI
- [ ] Test audio balance

---

## References

- `data/audio/sfx_presets.json` - Sound effect presets
- `docs/plans/p2/AUDIO_PLAN.md` - Audio roadmap
- `docs/plans/p1/UI_UX_SPECIFICATIONS.md` - UI audio integration
- Godot AudioStreamPlayer documentation
