# Environmental Mechanics

**Created:** 2026-01-08

How terrain, weather, time, and hazards affect gameplay in Keystonia.

---

## Overview

Environmental mechanics add variety and strategic depth to exploration and combat. Each region has distinct environmental characteristics that influence typing challenges, enemy behavior, and available rewards.

---

## Time System

### Day/Night Cycle

```
┌─────────────────────────────────────────────────────────────┐
│                    24-HOUR CYCLE                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  DAWN (5:00-7:00)     │  Transition, fog clearing          │
│  MORNING (7:00-12:00) │  High visibility, normal gameplay  │
│  AFTERNOON (12:00-17:00) │ Peak activity, bonus rewards    │
│  DUSK (17:00-19:00)   │  Transition, shadows lengthening   │
│  NIGHT (19:00-5:00)   │  Reduced visibility, special events│
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Time Effects by Phase

| Phase | Visibility | Enemy Activity | Special Effects |
|-------|------------|----------------|-----------------|
| **Dawn** | 70% | Low | Morning mist, peaceful start |
| **Morning** | 100% | Normal | Standard gameplay |
| **Afternoon** | 100% | High | 10% bonus gold |
| **Dusk** | 80% | Rising | Shadow enemies appear |
| **Night** | 50% | Varies | Night-only POIs active |

### Time-Locked Content

```json
{
  "time_locked_events": [
    {
      "id": "spirit_shrine_blessing",
      "available": "night",
      "location": "evergrove_shrine",
      "description": "Forest spirits only appear under moonlight"
    },
    {
      "id": "shadow_merchant",
      "available": ["dusk", "night"],
      "location": "wandering",
      "description": "Sells rare shadow-themed items"
    },
    {
      "id": "sunrise_challenge",
      "available": "dawn",
      "location": "sunfields_arena",
      "description": "Speed bonus challenge at first light"
    }
  ]
}
```

---

## Weather System

### Weather Types

| Weather | Frequency | Duration | Visual Effect |
|---------|-----------|----------|---------------|
| **Clear** | 40% | 4-8 hours | None |
| **Cloudy** | 25% | 2-6 hours | Dimmed lighting |
| **Rain** | 15% | 1-3 hours | Rain particles, puddles |
| **Storm** | 8% | 30min-1hr | Lightning, heavy effects |
| **Fog** | 7% | 2-4 hours | Reduced visibility |
| **Snow** | 5% | 2-5 hours | Snow particles (region-specific) |

### Weather Effects on Gameplay

```
┌─────────────────────────────────────────────────────────────┐
│                    WEATHER EFFECTS                          │
├──────────────┬──────────────────────────────────────────────┤
│ CLEAR        │ No modifiers - baseline gameplay             │
├──────────────┼──────────────────────────────────────────────┤
│ CLOUDY       │ -5% enemy spawn rate                         │
│              │ Neutral atmosphere                           │
├──────────────┼──────────────────────────────────────────────┤
│ RAIN         │ -10% visibility (UI slightly dimmed)         │
│              │ Water-type words appear more often           │
│              │ Fire enemies weakened (-10% HP)              │
│              │ "Wet" status: typing sounds muffled          │
├──────────────┼──────────────────────────────────────────────┤
│ STORM        │ -20% visibility                              │
│              │ Lightning strikes add random letters         │
│              │ +25% rewards for battles won                 │
│              │ Electric-themed word challenges              │
├──────────────┼──────────────────────────────────────────────┤
│ FOG          │ -30% visibility                              │
│              │ Words partially obscured until typed         │
│              │ Mystery events more common                   │
│              │ Navigation hints disabled                    │
├──────────────┼──────────────────────────────────────────────┤
│ SNOW         │ -15% movement speed on map                   │
│              │ Ice/cold themed vocabulary                   │
│              │ Frozen enemies spawn                         │
└──────────────┴──────────────────────────────────────────────┘
```

### Regional Weather Patterns

| Region | Common Weather | Rare Weather | Never |
|--------|----------------|--------------|-------|
| **Evergrove** | Clear, Rain | Fog | Snow |
| **Sunfields** | Clear, Cloudy | Storm | Snow, Fog |
| **Stonepass** | Cloudy, Snow | Storm | - |
| **Mistfen** | Fog, Rain | Storm | Clear |
| **Citadel** | Clear, Cloudy | All | - |
| **Fire Realm** | Clear (hot) | Ash storm | Rain, Snow, Fog |
| **Ice Realm** | Snow, Fog | Blizzard | Rain, Clear |
| **Nature Realm** | Rain, Clear | Storm | Snow |

---

## Terrain Types

### Base Terrain

| Terrain | Movement | Combat Modifier | Visual |
|---------|----------|-----------------|--------|
| **Grass** | Normal | None | Green tiles |
| **Path** | +20% | None | Dirt/stone road |
| **Forest** | -10% | +5% evasion | Trees, shadows |
| **Water** | Blocked | N/A | Lakes, rivers |
| **Bridge** | Normal | Ambush risk | Wood/stone spans |
| **Mountain** | Blocked | N/A | Rocky peaks |
| **Cliff Pass** | -30% | +10% accuracy req | Narrow paths |
| **Sand** | -15% | Speed challenges harder | Dunes, beach |
| **Swamp** | -25% | Words scrambled | Murky water |
| **Snow** | -20% | Typos more punishing | White ground |
| **Lava** | Blocked | N/A | Molten rock |
| **Lava Crust** | -40% | Speed is critical | Cooled lava |
| **Ice** | -10% | Perfect accuracy needed | Frozen ground |
| **Void** | Special | Anti-typing effects | Corrupted space |

### Terrain Challenges

```json
{
  "terrain_challenges": {
    "swamp": {
      "effect": "word_scramble",
      "description": "First 2 letters of each word are swapped",
      "example": "forest → ofrset",
      "mitigation": "Swamp Boots item negates effect"
    },
    "ice": {
      "effect": "no_backspace",
      "description": "Cannot correct mistakes - one chance per word",
      "mitigation": "Ice Grip gloves allow 1 correction"
    },
    "void": {
      "effect": "letter_decay",
      "description": "Typed letters fade if you pause too long",
      "decay_time": 2.0,
      "mitigation": "Void Resistance buff extends to 4 seconds"
    },
    "lava_crust": {
      "effect": "speed_pressure",
      "description": "Must maintain minimum WPM or take damage",
      "min_wpm": 20,
      "damage_per_tick": 5,
      "mitigation": "Heat Shield negates first 3 ticks"
    }
  }
}
```

---

## Environmental Hazards

### Static Hazards

| Hazard | Location | Effect | Interaction |
|--------|----------|--------|-------------|
| **Spike Trap** | Dungeons | Damage on wrong key | Type carefully |
| **Poison Cloud** | Swamp | Accuracy debuff | Rush through or wait |
| **Falling Rocks** | Mountains | Random letter added | Quick reactions |
| **Frozen Floor** | Ice areas | Slip on pause | Maintain rhythm |
| **Fire Geyser** | Volcanic | Timed damage | Speed typing |
| **Void Rift** | Corrupted | Letter stealing | Type stolen letter twice |
| **Quicksand** | Desert | Speed requirement | Don't slow down |
| **Thorns** | Forest | Typo damage amplified | Precision focus |

### Dynamic Hazards

```json
{
  "dynamic_hazards": {
    "lightning_strike": {
      "trigger": "storm_weather",
      "effect": "Adds random letter to current word",
      "warning": "Screen flash 0.5s before",
      "avoidance": "Complete word before strike"
    },
    "earthquake": {
      "trigger": "mountain_region + random",
      "effect": "UI shakes, keys visually scramble",
      "duration": 3,
      "avoidance": "Pause and wait it out"
    },
    "fog_bank": {
      "trigger": "fog_weather + movement",
      "effect": "Word visibility reduced to 50%",
      "duration": "Until word completed",
      "avoidance": "Memory challenge"
    },
    "void_pulse": {
      "trigger": "void_rift_proximity",
      "effect": "All progress on current word reset",
      "warning": "Purple glow intensifies",
      "avoidance": "Step back or finish fast"
    }
  }
}
```

---

## Region-Specific Mechanics

### Evergrove Forest

**Unique Mechanic: Nature's Rhythm**

```json
{
  "mechanic": "natures_rhythm",
  "description": "Typing in rhythm with forest sounds grants bonus accuracy",
  "implementation": {
    "ambient_beat": 60,
    "sync_window": 0.2,
    "bonus": "Perfect letters on beat grant +1 combo"
  }
}
```

**Environmental Features:**
- Healing groves restore health over time
- Ancient trees provide shelter from weather
- Fairy lights guide to hidden POIs at night
- Pollen clouds (spring) cause sneezing (random letter insert)

---

### Sunfields Plains

**Unique Mechanic: Solar Power**

```json
{
  "mechanic": "solar_power",
  "description": "Typing speed scales with time of day",
  "implementation": {
    "dawn": { "speed_bonus": 0.0 },
    "morning": { "speed_bonus": 0.1 },
    "afternoon": { "speed_bonus": 0.2 },
    "dusk": { "speed_bonus": 0.05 },
    "night": { "speed_bonus": -0.1 }
  }
}
```

**Environmental Features:**
- Heat waves (summer) blur distant text
- Dust storms reduce visibility
- Crop fields provide resource gathering
- Arena challenges more rewarding at noon

---

### Stonepass Mountains

**Unique Mechanic: Echo Typing**

```json
{
  "mechanic": "echo_typing",
  "description": "Completed words echo, creating combo chains",
  "implementation": {
    "echo_delay": 0.5,
    "echo_count": 2,
    "combo_multiplier": 1.1,
    "location": "caves_only"
  }
}
```

**Environmental Features:**
- Altitude sickness above certain height (reduced accuracy)
- Cave systems block weather but have own hazards
- Crystal formations reflect light (bonus visibility)
- Avalanche risk after loud combat

---

### Mistfen Marshes

**Unique Mechanic: Will-o'-Wisp**

```json
{
  "mechanic": "will_o_wisp",
  "description": "Mysterious lights lead to treasure or traps",
  "implementation": {
    "spawn_chance": 0.3,
    "treasure_chance": 0.6,
    "trap_chance": 0.4,
    "follow_challenge": {
      "type": "typing_test",
      "scrambled": true
    }
  }
}
```

**Environmental Features:**
- Perpetual fog reduces visibility
- Boggy ground slows movement
- Poisonous plants cause word corruption
- Hidden solid ground paths (memory puzzle)

---

### The Citadel

**Unique Mechanic: Order's Blessing**

```json
{
  "mechanic": "orders_blessing",
  "description": "Accumulated typing accuracy unlocks city bonuses",
  "implementation": {
    "threshold_1": { "accuracy": 0.85, "bonus": "10% shop discount" },
    "threshold_2": { "accuracy": 0.90, "bonus": "Access to library" },
    "threshold_3": { "accuracy": 0.95, "bonus": "Royal court audience" }
  }
}
```

**Environmental Features:**
- Protected from weather effects
- Multiple districts with different themes
- Training facilities with controlled conditions
- Archives with historical challenges

---

### Fire Realm

**Unique Mechanic: Heat Meter**

```json
{
  "mechanic": "heat_meter",
  "description": "Heat builds with time; speed typing cools you down",
  "implementation": {
    "heat_gain": 1,
    "heat_per_second": true,
    "heat_reduction": "wpm * 0.5",
    "overheat_threshold": 100,
    "overheat_effect": "Take damage, reset meter"
  }
}
```

**Environmental Features:**
- No healing without special items
- Fire geysers on timed intervals
- Lava flows reshape terrain
- Speed is survival

---

### Ice Realm

**Unique Mechanic: Frost Accumulation**

```json
{
  "mechanic": "frost_accumulation",
  "description": "Mistakes cause frost buildup; too much freezes you",
  "implementation": {
    "frost_per_error": 10,
    "frost_decay": 2,
    "frost_decay_per_second": true,
    "freeze_threshold": 100,
    "freeze_duration": 3,
    "perfect_word_bonus": "Clear 20 frost"
  }
}
```

**Environmental Features:**
- Blizzards blind the screen
- Ice floors require steady rhythm
- Frozen enemies shatter for bonus
- Precision is survival

---

### Nature Realm

**Unique Mechanic: Harmony Balance**

```json
{
  "mechanic": "harmony_balance",
  "description": "Must maintain balance between speed and accuracy",
  "implementation": {
    "target_ratio": 1.0,
    "ratio_calculation": "accuracy / (wpm / 50)",
    "tolerance": 0.2,
    "in_harmony_bonus": "Double rewards",
    "out_of_harmony": "No rewards"
  }
}
```

**Environmental Features:**
- Living terrain responds to typing quality
- Growth/decay cycle affects paths
- Symbiotic enemies (defeat one, affects another)
- Balance is mastery

---

### Void Rift

**Unique Mechanic: Reality Decay**

```json
{
  "mechanic": "reality_decay",
  "description": "The world itself fights against typing",
  "implementation": {
    "letter_deletion_chance": 0.05,
    "word_scramble_chance": 0.1,
    "visual_glitch_chance": 0.15,
    "resistance_buff": "Reduces all chances by 50%"
  }
}
```

**Environmental Features:**
- No weather (void has no weather)
- Terrain constantly shifts
- Words actively resist being typed
- Void Tyrant's influence everywhere
- The final test of all skills

---

## Seasonal Events

### Spring: Renewal Festival

```json
{
  "season": "spring",
  "event": "renewal_festival",
  "duration": "7 days",
  "effects": {
    "evergrove": "Flowers bloom, +20% herb spawn",
    "sunfields": "Perfect planting, agriculture words",
    "global": "Growth-themed vocabulary"
  },
  "rewards": "Seed items for garden feature"
}
```

### Summer: Speed Championship

```json
{
  "season": "summer",
  "event": "speed_championship",
  "duration": "7 days",
  "effects": {
    "sunfields": "Arena tournaments active",
    "citadel": "Racing challenges",
    "global": "+10% WPM bonus rewards"
  },
  "rewards": "Speed Champion title, golden keyboard skin"
}
```

### Autumn: Accuracy Trials

```json
{
  "season": "autumn",
  "event": "accuracy_trials",
  "duration": "7 days",
  "effects": {
    "mistfen": "Special precision challenges",
    "stonepass": "Crystal extraction events",
    "global": "Accuracy-focused vocabulary"
  },
  "rewards": "Precision Master title, crystal items"
}
```

### Winter: Silence Remembrance

```json
{
  "season": "winter",
  "event": "silence_remembrance",
  "duration": "7 days",
  "effects": {
    "all_regions": "Snow falls everywhere",
    "void_rift": "Void Tyrant sends elite forces",
    "global": "Bonus lore drops, somber vocabulary"
  },
  "rewards": "Memorial badge, lore collection bonus"
}
```

---

## Implementation Checklist

- [ ] Implement day/night cycle with visual changes
- [ ] Add weather system with random transitions
- [ ] Create terrain effect handlers for each type
- [ ] Add hazard triggers and visual warnings
- [ ] Implement region-specific mechanics
- [ ] Create seasonal event framework
- [ ] Add weather/time to save system
- [ ] Visual effects for each environmental state
- [ ] Audio changes for weather/time
- [ ] UI indicators for active effects

---

## References

- `docs/plans/p1/WORLD_EXPANSION_PLAN.md` - World structure
- `docs/plans/p1/REGION_SPECIFICATIONS.md` - Region details
- `docs/plans/p1/POI_EVENT_SYSTEM.md` - POI events
- `sim/world_tick.gd` - World simulation
- `game/grid_renderer.gd` - Visual rendering
