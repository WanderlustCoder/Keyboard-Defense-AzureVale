# Lesson Progression Tree

**Created:** 2026-01-08

This document defines the lesson unlock system, prerequisites, and progression paths.

## Progression Philosophy

1. **Gated by Mastery** - Players must demonstrate competency before advancing
2. **Multiple Paths** - Core curriculum is linear; side tracks are optional
3. **No Dead Ends** - Always have something new to try
4. **Celebrate Progress** - Unlocks feel rewarding

## Unlock Criteria

### Mastery Levels

| Level | Accuracy | Completions | WPM | Badge |
|-------|----------|-------------|-----|-------|
| Attempted | Any | 1+ | Any | Bronze |
| Practiced | 70%+ | 3+ | Any | Silver |
| Proficient | 80%+ | 5+ | 20+ | Gold |
| Mastered | 90%+ | 10+ | 30+ | Platinum |
| Legendary | 95%+ | 20+ | 40+ | Diamond |

### Default Unlock Formula

```gdscript
func can_unlock(lesson_id: String, profile: Dictionary) -> bool:
    var prereqs = get_prerequisites(lesson_id)
    for prereq in prereqs:
        var stats = profile.get("lesson_stats", {}).get(prereq, {})
        var accuracy = stats.get("best_accuracy", 0.0)
        var completions = stats.get("completions", 0)

        # Default: 75% accuracy and 2+ completions
        if accuracy < 0.75 or completions < 2:
            return false

    return true
```

## Core Curriculum Tree

```
                            ┌─────────────────┐
                            │  training_basics │ (Always unlocked)
                            │    ASDF only     │
                            └────────┬────────┘
                                     │
                            ┌────────▼────────┐
                            │ training_rhythm  │
                            │   ASDF + JKL     │
                            └────────┬────────┘
                                     │
                            ┌────────▼────────┐
                            │   home_row_1     │
                            │   ASDF JKL;      │
                            └────────┬────────┘
                                     │
                            ┌────────▼────────┐
                            │   home_row_2     │
                            │  Home row drill  │
                            └────────┬────────┘
                                     │
              ┌──────────────────────┼──────────────────────┐
              │                      │                      │
     ┌────────▼────────┐   ┌────────▼────────┐   ┌────────▼────────┐
     │   reach_row_1   │   │  bottom_row_1   │   │   upper_row_1   │
     │   + E R T G     │   │   + Z X C V     │   │    + Q W P      │
     └────────┬────────┘   └────────┬────────┘   └────────┬────────┘
              │                      │                      │
     ┌────────▼────────┐   ┌────────▼────────┐   ┌────────▼────────┐
     │   reach_row_2   │   │  bottom_row_2   │   │   upper_row_2   │
     │ + Y U I O H N M │   │   + B N M       │   │  Full alphabet  │
     └────────┬────────┘   └────────┬────────┘   └────────┬────────┘
              │                      │                      │
              └──────────────────────┼──────────────────────┘
                                     │
                            ┌────────▼────────┐
                            │   mixed_rows    │
                            │   All letters   │
                            └────────┬────────┘
                                     │
              ┌──────────────────────┼──────────────────────┐
              │                      │                      │
     ┌────────▼────────┐   ┌────────▼────────┐   ┌────────▼────────┐
     │   speed_alpha   │   │   full_alpha    │   │  nexus_blend    │
     │  Short bursts   │   │ General practice│   │   Longer words  │
     └────────┬────────┘   └────────┬────────┘   └────────┬────────┘
              │                      │                      │
              └──────────────────────┼──────────────────────┘
                                     │
                            ┌────────▼────────┐
                            │  apex_mastery   │
                            │ Ultimate alpha  │
                            └────────┬────────┘
                                     │
              ┌──────────────────────┼──────────────────────┐
              │                      │                      │
     ┌────────▼────────┐   ┌────────▼────────┐   ┌────────▼────────┐
     │   numbers_1     │   │  capitals_1     │   │ punctuation_1   │
     │    + 1-5        │   │   + Shift       │   │   + . , ; :     │
     └────────┬────────┘   └────────┬────────┘   └────────┬────────┘
              │                      │                      │
     ┌────────▼────────┐   ┌────────▼────────┐   ┌────────▼────────┐
     │   numbers_2     │   │  capitals_2     │   │ punctuation_2   │
     │   + 6-0         │   │ Full capitals   │   │   + ! ? -       │
     └────────┬────────┘   └────────┬────────┘   └────────┬────────┘
              │                      │                      │
              └──────────────────────┼──────────────────────┘
                                     │
                            ┌────────▼────────┐
                            │   symbols_1     │
                            │  + @ # $ % &    │
                            └────────┬────────┘
                                     │
                            ┌────────▼────────┐
                            │   symbols_2     │
                            │ + ( ) [ ] { }   │
                            └─────────────────┘
```

## Prerequisite Definitions

### Core Curriculum

```json
{
  "training_basics": {
    "prerequisites": [],
    "unlock_requirement": "always_unlocked"
  },
  "training_rhythm": {
    "prerequisites": ["training_basics"],
    "unlock_requirement": {"accuracy": 0.70, "completions": 1}
  },
  "home_row_1": {
    "prerequisites": ["training_rhythm"],
    "unlock_requirement": {"accuracy": 0.75, "completions": 2}
  },
  "home_row_2": {
    "prerequisites": ["home_row_1"],
    "unlock_requirement": {"accuracy": 0.75, "completions": 2}
  },
  "reach_row_1": {
    "prerequisites": ["home_row_2"],
    "unlock_requirement": {"accuracy": 0.80, "completions": 3}
  },
  "reach_row_2": {
    "prerequisites": ["reach_row_1"],
    "unlock_requirement": {"accuracy": 0.80, "completions": 3}
  },
  "bottom_row_1": {
    "prerequisites": ["home_row_2"],
    "unlock_requirement": {"accuracy": 0.80, "completions": 3}
  },
  "bottom_row_2": {
    "prerequisites": ["bottom_row_1"],
    "unlock_requirement": {"accuracy": 0.80, "completions": 3}
  },
  "upper_row_1": {
    "prerequisites": ["home_row_2"],
    "unlock_requirement": {"accuracy": 0.80, "completions": 3}
  },
  "upper_row_2": {
    "prerequisites": ["upper_row_1"],
    "unlock_requirement": {"accuracy": 0.80, "completions": 3}
  },
  "mixed_rows": {
    "prerequisites": ["reach_row_2", "bottom_row_2", "upper_row_2"],
    "unlock_requirement": {"accuracy": 0.80, "completions": 2}
  },
  "speed_alpha": {
    "prerequisites": ["mixed_rows"],
    "unlock_requirement": {"accuracy": 0.80, "completions": 3}
  },
  "full_alpha": {
    "prerequisites": ["mixed_rows"],
    "unlock_requirement": {"accuracy": 0.75, "completions": 2}
  },
  "nexus_blend": {
    "prerequisites": ["mixed_rows"],
    "unlock_requirement": {"accuracy": 0.80, "completions": 3}
  },
  "apex_mastery": {
    "prerequisites": ["speed_alpha", "nexus_blend"],
    "unlock_requirement": {"accuracy": 0.85, "completions": 5}
  }
}
```

### Extended Characters

```json
{
  "numbers_1": {
    "prerequisites": ["apex_mastery"],
    "unlock_requirement": {"accuracy": 0.80, "completions": 3}
  },
  "numbers_2": {
    "prerequisites": ["numbers_1"],
    "unlock_requirement": {"accuracy": 0.80, "completions": 3}
  },
  "capitals_1": {
    "prerequisites": ["apex_mastery"],
    "unlock_requirement": {"accuracy": 0.80, "completions": 3}
  },
  "capitals_2": {
    "prerequisites": ["capitals_1"],
    "unlock_requirement": {"accuracy": 0.80, "completions": 3}
  },
  "punctuation_1": {
    "prerequisites": ["apex_mastery"],
    "unlock_requirement": {"accuracy": 0.80, "completions": 3}
  },
  "punctuation_2": {
    "prerequisites": ["punctuation_1"],
    "unlock_requirement": {"accuracy": 0.80, "completions": 3}
  },
  "symbols_1": {
    "prerequisites": ["numbers_2", "punctuation_2"],
    "unlock_requirement": {"accuracy": 0.80, "completions": 3}
  },
  "symbols_2": {
    "prerequisites": ["symbols_1"],
    "unlock_requirement": {"accuracy": 0.85, "completions": 5}
  }
}
```

## Side Track: Finger Training

```
                     ┌──────────────┐
                     │  home_row_2  │
                     └──────┬───────┘
                            │
         ┌──────────────────┼──────────────────┐
         │                  │                  │
┌────────▼────────┐ ┌───────▼───────┐ ┌────────▼────────┐
│ finger_gym_left │ │ weak_fingers  │ │ finger_gym_right│
└────────┬────────┘ └───────┬───────┘ └────────┬────────┘
         │                  │                  │
         │          ┌───────┴───────┐          │
         │          │               │          │
         │   ┌──────▼──────┐ ┌──────▼──────┐   │
         │   │ pinky_power │ │ring_finger_ │   │
         │   │             │ │   focus     │   │
         │   └─────────────┘ └─────────────┘   │
         │                                     │
         └─────────────────┬───────────────────┘
                           │
                  ┌────────▼────────┐
                  │alternating_hands│
                  └─────────────────┘
```

### Finger Training Prerequisites

```json
{
  "finger_gym_left": {
    "prerequisites": ["home_row_2"],
    "unlock_requirement": {"accuracy": 0.75, "completions": 2}
  },
  "finger_gym_right": {
    "prerequisites": ["home_row_2"],
    "unlock_requirement": {"accuracy": 0.75, "completions": 2}
  },
  "weak_fingers": {
    "prerequisites": ["home_row_2"],
    "unlock_requirement": {"accuracy": 0.75, "completions": 2}
  },
  "pinky_power": {
    "prerequisites": ["weak_fingers"],
    "unlock_requirement": {"accuracy": 0.70, "completions": 3}
  },
  "ring_finger_focus": {
    "prerequisites": ["weak_fingers"],
    "unlock_requirement": {"accuracy": 0.70, "completions": 3}
  },
  "alternating_hands": {
    "prerequisites": ["finger_gym_left", "finger_gym_right"],
    "unlock_requirement": {"accuracy": 0.80, "completions": 3}
  }
}
```

## Side Track: Pattern Training

```
                     ┌──────────────┐
                     │  mixed_rows  │
                     └──────┬───────┘
                            │
    ┌───────────────────────┼───────────────────────┐
    │                       │                       │
┌───▼───────────┐   ┌───────▼───────┐   ┌───────────▼───┐
│  bigram_flow  │   │ double_letters│   │ consonant_    │
│               │   │               │   │ clusters      │
└───────┬───────┘   └───────┬───────┘   └───────┬───────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            │
                   ┌────────▼────────┐
                   │   vowel_flow    │
                   └────────┬────────┘
                            │
                   ┌────────▼────────┐
                   │  rhythm_words   │
                   └─────────────────┘
```

## Side Track: Challenge Modes

```
                     ┌──────────────┐
                     │ apex_mastery │
                     └──────┬───────┘
                            │
    ┌───────────────────────┼───────────────────────┐
    │                       │                       │
┌───▼───────────┐   ┌───────▼───────┐   ┌───────────▼───┐
│gauntlet_speed │   │   precision_  │   │ time_trial_   │
│               │   │    bronze     │   │   sprint      │
└───────┬───────┘   └───────┬───────┘   └───────┬───────┘
        │                   │                   │
┌───────▼───────┐   ┌───────▼───────┐   ┌───────▼───────┐
│ gauntlet_     │   │  precision_   │   │ time_trial_   │
│  endurance    │   │   silver      │   │  marathon     │
└───────┬───────┘   └───────┬───────┘   └───────────────┘
        │                   │
┌───────▼───────┐   ┌───────▼───────┐
│gauntlet_chaos │   │  precision_   │
│               │   │    gold       │
└───────┬───────┘   └───────────────┘
        │
┌───────▼───────────────────────────┐
│         legendary_apex            │
└───────────────────────────────────┘
```

### Challenge Mode Prerequisites

```json
{
  "gauntlet_speed": {
    "prerequisites": ["apex_mastery"],
    "unlock_requirement": {"accuracy": 0.85, "completions": 5}
  },
  "gauntlet_endurance": {
    "prerequisites": ["gauntlet_speed"],
    "unlock_requirement": {"accuracy": 0.80, "completions": 3}
  },
  "gauntlet_chaos": {
    "prerequisites": ["gauntlet_endurance", "symbols_2"],
    "unlock_requirement": {"accuracy": 0.80, "completions": 5}
  },
  "precision_bronze": {
    "prerequisites": ["apex_mastery"],
    "unlock_requirement": {"accuracy": 0.90, "completions": 3}
  },
  "precision_silver": {
    "prerequisites": ["precision_bronze"],
    "unlock_requirement": {"accuracy": 0.92, "completions": 5}
  },
  "precision_gold": {
    "prerequisites": ["precision_silver"],
    "unlock_requirement": {"accuracy": 0.95, "completions": 10}
  },
  "time_trial_sprint": {
    "prerequisites": ["apex_mastery"],
    "unlock_requirement": {"accuracy": 0.80, "wpm": 40}
  },
  "time_trial_marathon": {
    "prerequisites": ["time_trial_sprint"],
    "unlock_requirement": {"accuracy": 0.85, "wpm": 45}
  },
  "legendary_apex": {
    "prerequisites": ["gauntlet_chaos", "precision_gold"],
    "unlock_requirement": {"accuracy": 0.90, "completions": 10}
  }
}
```

## Side Track: Themed Content

### Realm Progression

```
                     ┌──────────────┐
                     │  full_alpha  │
                     └──────┬───────┘
                            │
    ┌───────────────────────┼───────────────────────┐
    │                       │                       │
┌───▼───────────┐   ┌───────▼───────┐   ┌───────────▼───┐
│ fire_realm_1  │   │ ice_realm_1   │   │nature_realm_1 │
│  Ember Path   │   │Frozen Approach│   │ Living Grove  │
└───────┬───────┘   └───────┬───────┘   └───────┬───────┘
        │                   │                   │
┌───────▼───────┐   ┌───────▼───────┐   ┌───────▼───────┐
│ fire_realm_2  │   │ ice_realm_2   │   │nature_realm_2 │
│ Inferno Core  │   │ Glacier Heart │   │  World Tree   │
└───────┬───────┘   └───────┬───────┘   └───────┬───────┘
        │                   │                   │
┌───────▼───────┐   ┌───────▼───────┐   ┌───────▼───────┐
│fire_realm_boss│   │ice_realm_boss │   │nature_realm_  │
│ Flame Tyrant  │   │ Frost Empress │   │  boss         │
└───────────────┘   └───────────────┘   └───────────────┘
```

### Biome Progression

```
                     ┌──────────────┐
                     │  mixed_rows  │
                     └──────┬───────┘
                            │
    ┌───────────────────────┼───────────────────────┐
    │                       │                       │
┌───▼───────────┐   ┌───────▼───────┐   ┌───────────▼───┐
│biome_sunfields│   │biome_evergrove│   │ biome_        │
│   (easiest)   │   │  (standard)   │   │ stonepass     │
└───────────────┘   └───────────────┘   └───────┬───────┘
                                                │
                                        ┌───────▼───────┐
                                        │biome_mistfen  │
                                        │  (hardest)    │
                                        └───────────────┘
```

## Side Track: Professional Skills

### Coding Track

```
                     ┌──────────────┐
                     │  full_alpha  │
                     └──────┬───────┘
                            │
                   ┌────────▼────────┐
                   │ code_variables  │
                   └────────┬────────┘
                            │
                   ┌────────▼────────┐
                   │  code_keywords  │
                   └────────┬────────┘
                            │
            ┌───────────────┴───────────────┐
            │                               │
   ┌────────▼────────┐             ┌────────▼────────┐
   │   code_syntax   │             │   mixed_case    │
   │ (requires       │             │   (CamelCase)   │
   │  symbols_1)     │             └─────────────────┘
   └────────┬────────┘
            │
   ┌────────▼────────┐
   │   code_master   │
   └────────┬────────┘
            │
   ┌────────▼────────┐
   │  email_patterns │
   └─────────────────┘
```

## Boss Unlock Chain

Bosses unlock based on story progression (day completion) rather than lesson mastery:

```json
{
  "boss_grove_guardian": {
    "unlock_type": "story",
    "requirement": {"day_completed": 3}
  },
  "boss_citadel_warden": {
    "unlock_type": "story",
    "requirement": {"day_completed": 7}
  },
  "boss_twilight_lord": {
    "unlock_type": "story",
    "requirement": {"day_completed": 11}
  },
  "boss_eternal_scribe": {
    "unlock_type": "story",
    "requirement": {"day_completed": 15}
  },
  "boss_fen_seer": {
    "unlock_type": "story",
    "requirement": {"day_completed": 18}
  },
  "boss_sunlord": {
    "unlock_type": "story",
    "requirement": {"day_completed": 19}
  }
}
```

## UI Display

### Lesson Selection Panel

```
┌─────────────────────────────────────────────────────────┐
│ LESSONS                                    [Filter ▼]   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│ ★ CORE CURRICULUM                                       │
│ ├─ ✓ Training Basics     [Mastered]  ████████████ 95%  │
│ ├─ ✓ Training Rhythm     [Proficient] ████████░░ 82%   │
│ ├─ ● Home Row 1          [In Progress] ██████░░░░ 65%  │
│ ├─ 🔒 Home Row 2          [Locked]                      │
│ └─ 🔒 ...                                               │
│                                                         │
│ ★ FINGER TRAINING                                       │
│ ├─ 🔒 Left Hand Gym       [Requires: Home Row 2]       │
│ └─ 🔒 ...                                               │
│                                                         │
│ ★ CHALLENGE MODES                                       │
│ └─ 🔒 ...                                               │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Unlock Notification

```
┌─────────────────────────────────────────────────────────┐
│                    ★ NEW LESSON UNLOCKED ★              │
│                                                         │
│                    [Home Row Extended]                  │
│                                                         │
│     "Master the full home row with both hands."        │
│                                                         │
│              Prerequisites Met:                         │
│              ✓ Home Row Basics (82% accuracy)          │
│              ✓ 3 completions                           │
│                                                         │
│                    [ Start Now ]                        │
└─────────────────────────────────────────────────────────┘
```

## Implementation Checklist

### Data
- [ ] Add `prerequisites` field to lessons.json
- [ ] Add `unlock_requirements` to lessons.json
- [ ] Create progression tree data structure

### Code
- [ ] Implement unlock checking in typing_profile.gd
- [ ] Add lesson filtering by unlock status
- [ ] Create unlock notification system
- [ ] Track lesson statistics per lesson

### UI
- [ ] Update lesson panel with lock/unlock status
- [ ] Add unlock notification popup
- [ ] Show prerequisites on locked lessons
- [ ] Display mastery badges

## References

- `docs/plans/p1/LESSON_GUIDE_PLAN.md` - Lesson inventory
- `docs/plans/p1/PEDAGOGY_GUIDE_FRAMEWORK.md` - Mastery levels
- `data/lessons.json` - Lesson definitions
- `game/typing_profile.gd` - Player statistics
