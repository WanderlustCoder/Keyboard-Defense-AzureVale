# Typing Drills Specification

**Created:** 2026-01-08

This document specifies drill types, exercise formats, and practice modes for the typing curriculum.

## Drill Philosophy

1. **Targeted Practice** - Each drill focuses on specific skills
2. **Short Sessions** - 2-5 minute drills prevent fatigue
3. **Measurable Progress** - Clear metrics for improvement
4. **Gamified Flow** - Make practice feel like play

## Drill Types

### 1. Single Key Drills

Practice individual key reaches from home position.

```json
{
  "type": "single_key",
  "description": "Practice one key at a time",
  "format": "Press the highlighted key repeatedly",
  "duration": "30 seconds per key",
  "metrics": ["accuracy", "consistency"],
  "example_sequence": "e e e e e e e e e e"
}
```

**Use Case:** New key introduction, finger isolation

**Implementation:**
```gdscript
func generate_single_key_drill(key: String, count: int = 20) -> Array[String]:
    var drill = []
    for i in range(count):
        drill.append(key)
    return drill
```

### 2. Key Pair Drills

Practice two-key combinations for muscle memory.

```json
{
  "type": "key_pair",
  "description": "Alternate between two keys",
  "format": "Type the displayed pair repeatedly",
  "duration": "60 seconds per pair",
  "metrics": ["accuracy", "speed", "rhythm"],
  "example_sequence": "ed ed ed ed de de de de"
}
```

**Common Pairs by Finger:**
- Left Index: `rf`, `fr`, `tf`, `ft`, `gf`, `fg`, `vf`, `fv`
- Left Middle: `ed`, `de`, `ec`, `ce`
- Left Ring: `ws`, `sw`, `sx`, `xs`
- Left Pinky: `qa`, `aq`, `az`, `za`
- Right Index: `uj`, `ju`, `yj`, `jy`, `hj`, `jh`, `nj`, `jn`
- Right Middle: `ik`, `ki`
- Right Ring: `ol`, `lo`
- Right Pinky: `p;`, `;p`

### 3. Trigram Drills

Practice three-letter sequences for word-building flow.

```json
{
  "type": "trigram",
  "description": "Common three-letter patterns",
  "format": "Type each trigram as a unit",
  "duration": "90 seconds",
  "metrics": ["accuracy", "speed", "flow"],
  "example_sequence": "the ing and ion ent"
}
```

**High-Value Trigrams:**
```json
{
  "most_common": [
    "the", "and", "ing", "ion", "tio", "ent", "ati", "for",
    "her", "ter", "hat", "tha", "ere", "ate", "his", "con",
    "res", "ver", "all", "ons", "nce", "men", "ith", "ted"
  ]
}
```

### 4. Word Burst Drills

Type complete words as fast as possible.

```json
{
  "type": "word_burst",
  "description": "Rapid-fire word typing",
  "format": "Type each word, press space, continue",
  "duration": "2 minutes",
  "metrics": ["wpm", "accuracy", "words_completed"],
  "word_length": "3-5 letters",
  "example_sequence": "the cat sat hat mat fat rat"
}
```

**Difficulty Levels:**
| Level | Word Length | Words/Minute Target |
|-------|-------------|---------------------|
| Easy | 2-3 | 30+ |
| Medium | 3-5 | 40+ |
| Hard | 4-6 | 50+ |
| Expert | 5-8 | 60+ |

### 5. Sentence Drills

Type complete sentences for real-world practice.

```json
{
  "type": "sentence",
  "description": "Full sentence typing with punctuation",
  "format": "Type the sentence exactly as shown",
  "duration": "3-5 minutes",
  "metrics": ["wpm", "accuracy", "punctuation_accuracy"],
  "example": "The quick brown fox jumps over the lazy dog."
}
```

**Sentence Categories:**
- **Pangrams:** Use all 26 letters
- **Common Phrases:** Everyday expressions
- **Technical:** Programming-related
- **Fantasy:** Game-themed content

### 6. Accuracy Challenge Drills

Focus entirely on error-free typing.

```json
{
  "type": "accuracy_challenge",
  "description": "Zero-error typing challenge",
  "format": "One mistake resets the drill",
  "duration": "Until 20 words typed perfectly",
  "metrics": ["consecutive_correct", "reset_count"],
  "difficulty": "Words matched to skill level"
}
```

**Rules:**
- Any error resets progress
- Track longest streak
- Gradually increase word complexity

### 7. Speed Challenge Drills

Push typing speed limits.

```json
{
  "type": "speed_challenge",
  "description": "Maximum speed typing",
  "format": "Type as fast as possible for 60 seconds",
  "duration": "60 seconds",
  "metrics": ["raw_wpm", "net_wpm", "error_rate"],
  "accuracy_minimum": "90% or result doesn't count"
}
```

### 8. Finger Isolation Drills

Target specific fingers for strengthening.

```json
{
  "type": "finger_isolation",
  "description": "Practice keys for one specific finger",
  "format": "Only keys for the target finger appear",
  "duration": "60 seconds per finger",
  "metrics": ["accuracy", "speed", "fatigue_consistency"],
  "fingers": ["left_pinky", "left_ring", "left_middle", "left_index",
              "right_index", "right_middle", "right_ring", "right_pinky"]
}
```

**Finger Key Sets:**
```json
{
  "left_pinky": ["q", "a", "z", "1", "`"],
  "left_ring": ["w", "s", "x", "2"],
  "left_middle": ["e", "d", "c", "3"],
  "left_index": ["r", "f", "v", "t", "g", "b", "4", "5"],
  "right_index": ["y", "h", "n", "u", "j", "m", "6", "7"],
  "right_middle": ["i", "k", ",", "8"],
  "right_ring": ["o", "l", ".", "9"],
  "right_pinky": ["p", ";", "/", "0", "-", "=", "[", "]", "'"]
}
```

### 9. Hand Alternation Drills

Practice smooth hand transitions.

```json
{
  "type": "hand_alternation",
  "description": "Words that alternate between hands",
  "format": "Type words with left-right-left-right patterns",
  "duration": "90 seconds",
  "metrics": ["rhythm_consistency", "speed", "accuracy"],
  "example_words": ["their", "world", "right", "light", "fight"]
}
```

### 10. Recovery Drills

Practice recovering from errors gracefully.

```json
{
  "type": "recovery",
  "description": "Learn to continue smoothly after mistakes",
  "format": "Intentionally contains tricky words",
  "duration": "3 minutes",
  "metrics": ["recovery_speed", "post_error_accuracy"],
  "goal": "Maintain rhythm even after errors"
}
```

## Drill Sequences

### Warm-Up Routine (5 minutes)

```json
{
  "name": "Daily Warm-Up",
  "drills": [
    {"type": "single_key", "keys": "home_row", "duration": 30},
    {"type": "key_pair", "pairs": "common", "duration": 60},
    {"type": "word_burst", "length": "short", "duration": 60},
    {"type": "sentence", "count": 3, "duration": 90}
  ],
  "total_duration": "5 minutes"
}
```

### Finger Strength Routine (10 minutes)

```json
{
  "name": "Finger Strength Builder",
  "drills": [
    {"type": "finger_isolation", "finger": "left_pinky", "duration": 60},
    {"type": "finger_isolation", "finger": "right_pinky", "duration": 60},
    {"type": "finger_isolation", "finger": "left_ring", "duration": 60},
    {"type": "finger_isolation", "finger": "right_ring", "duration": 60},
    {"type": "key_pair", "pairs": "weak_finger_pairs", "duration": 120},
    {"type": "word_burst", "charset": "weak_keys", "duration": 120}
  ],
  "total_duration": "10 minutes"
}
```

### Speed Building Routine (10 minutes)

```json
{
  "name": "Speed Builder",
  "drills": [
    {"type": "word_burst", "length": "short", "duration": 60},
    {"type": "word_burst", "length": "medium", "duration": 90},
    {"type": "speed_challenge", "duration": 60},
    {"type": "trigram", "focus": "common", "duration": 90},
    {"type": "speed_challenge", "duration": 60}
  ],
  "total_duration": "10 minutes"
}
```

### Accuracy Focus Routine (10 minutes)

```json
{
  "name": "Accuracy Master",
  "drills": [
    {"type": "single_key", "mode": "precision", "duration": 60},
    {"type": "accuracy_challenge", "words": 10, "duration": 180},
    {"type": "sentence", "mode": "perfect", "duration": 120},
    {"type": "accuracy_challenge", "words": 20, "duration": 180}
  ],
  "total_duration": "10 minutes"
}
```

## Practice Mode Specifications

### Free Practice

```json
{
  "mode": "free_practice",
  "description": "Unstructured typing practice",
  "features": [
    "Choose any lesson",
    "No time pressure",
    "Real-time stats display",
    "Pause/resume anytime"
  ],
  "metrics_tracked": ["accuracy", "wpm", "time_spent"]
}
```

### Guided Practice

```json
{
  "mode": "guided_practice",
  "description": "AI-selected drills based on weaknesses",
  "features": [
    "Automatic drill selection",
    "Targets weak areas",
    "Progressive difficulty",
    "Session summary"
  ],
  "algorithm": "Select drills for keys with lowest accuracy"
}
```

### Challenge Mode

```json
{
  "mode": "challenge",
  "description": "Competitive drills with rankings",
  "features": [
    "Daily challenges",
    "Personal bests tracking",
    "Achievement unlocks",
    "Leaderboards (optional)"
  ],
  "challenge_types": ["speed", "accuracy", "endurance", "perfect_run"]
}
```

### Key-by-Key Practice

```json
{
  "mode": "key_practice",
  "description": "Practice specific keys introduced in lesson",
  "features": [
    "Shows keyboard with target keys highlighted",
    "Single key repetition",
    "Key combination practice",
    "Gradual word introduction"
  ],
  "sequence": [
    "Single key taps (10x each)",
    "Key pairs (5x each combination)",
    "Short words using new keys",
    "Mixed words with old + new keys"
  ]
}
```

## Drill Generation Algorithms

### Adaptive Word Selection

```gdscript
func select_practice_words(profile: Dictionary, lesson: Dictionary) -> Array:
    var words = []
    var weak_keys = get_weak_keys(profile)
    var lesson_charset = lesson.get("charset", "")

    # 40% words targeting weak keys
    for i in range(4):
        words.append(generate_word_with_keys(weak_keys, lesson_charset))

    # 30% balanced words
    for i in range(3):
        words.append(generate_balanced_word(lesson_charset))

    # 30% random from charset
    for i in range(3):
        words.append(generate_random_word(lesson_charset))

    return words

func get_weak_keys(profile: Dictionary) -> Array:
    var key_stats = profile.get("key_stats", {})
    var weak = []
    for key in key_stats:
        if key_stats[key].get("accuracy", 1.0) < 0.85:
            weak.append(key)
    return weak
```

### Rhythm-Based Word Selection

```gdscript
func select_rhythm_words(target_pattern: String) -> Array:
    # Patterns: "LRL" = left-right-left, "LL" = same hand, etc.
    var words = []
    for word in wordlist:
        if get_hand_pattern(word) == target_pattern:
            words.append(word)
    return words

func get_hand_pattern(word: String) -> String:
    var pattern = ""
    for c in word:
        if c in LEFT_HAND_KEYS:
            pattern += "L"
        else:
            pattern += "R"
    return pattern
```

## Progress Tracking

### Per-Key Statistics

```json
{
  "key_stats": {
    "e": {
      "total_presses": 1542,
      "correct": 1498,
      "accuracy": 0.971,
      "avg_time_ms": 145,
      "recent_accuracy": 0.98
    }
  }
}
```

### Per-Drill Statistics

```json
{
  "drill_stats": {
    "word_burst": {
      "sessions": 45,
      "best_wpm": 62,
      "avg_wpm": 48,
      "best_accuracy": 0.98,
      "avg_accuracy": 0.94
    }
  }
}
```

### Session Summary

```json
{
  "session": {
    "date": "2026-01-08",
    "duration_minutes": 15,
    "drills_completed": 6,
    "words_typed": 234,
    "avg_wpm": 45,
    "avg_accuracy": 0.92,
    "keys_improved": ["q", "z"],
    "recommendation": "Focus on left pinky keys tomorrow"
  }
}
```

## UI Specifications

### Drill Display

```
┌─────────────────────────────────────────────────────────┐
│ WORD BURST DRILL                           ⏱️ 1:23      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│                     castle                              │
│                                                         │
│                   [cas    ]                             │
│                                                         │
├─────────────────────────────────────────────────────────┤
│ WPM: 45    Accuracy: 94%    Streak: 7    Words: 12/20  │
└─────────────────────────────────────────────────────────┘
```

### Drill Selection

```
┌─────────────────────────────────────────────────────────┐
│ PRACTICE DRILLS                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│ ★ RECOMMENDED FOR YOU                                   │
│ ├─ Pinky Strengthening (2 min)    [Weak area detected] │
│ └─ Word Burst - Medium (3 min)    [Build speed]        │
│                                                         │
│ ★ QUICK DRILLS (< 2 min)                               │
│ ├─ Single Key Practice                                  │
│ ├─ Key Pairs                                           │
│ └─ Trigrams                                            │
│                                                         │
│ ★ FOCUSED SESSIONS (5-10 min)                          │
│ ├─ Daily Warm-Up                                       │
│ ├─ Speed Builder                                       │
│ └─ Accuracy Master                                     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Implementation Checklist

### Data
- [ ] Create drill definitions in data/drills.json
- [ ] Add drill sequences for routines
- [ ] Define key statistics schema

### Code
- [ ] Implement drill runner in game/drill_runner.gd
- [ ] Add adaptive word selection
- [ ] Create progress tracking system
- [ ] Implement drill UI components

### Integration
- [ ] Connect drills to lesson system
- [ ] Add drill recommendations to home screen
- [ ] Track drill stats in profile

## References

- `docs/plans/p1/LESSON_GUIDE_PLAN.md` - Lesson structure
- `docs/plans/p1/LESSON_PROGRESSION_TREE.md` - Unlock system
- `docs/FINGER_GUIDE_REFERENCE.md` - Key assignments
- `game/typing_profile.gd` - Profile persistence
