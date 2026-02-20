# Mastery Assessment Criteria

**Created:** 2026-01-08

This document defines how typing mastery is measured, displayed, and rewarded across the game.

## Assessment Philosophy

1. **Multiple Dimensions** - Speed alone doesn't equal mastery
2. **Progress Over Perfection** - Reward improvement, not just achievement
3. **Clear Goals** - Players always know what to work toward
4. **Fair Comparison** - Normalize scores across difficulty levels

## Core Metrics

### 1. Accuracy

**Definition:** Percentage of correctly typed characters.

```gdscript
func calculate_accuracy(correct: int, total: int) -> float:
    if total == 0:
        return 0.0
    return float(correct) / float(total)
```

**Accuracy Tiers:**

| Tier | Range | Badge | Description |
|------|-------|-------|-------------|
| Novice | 0-69% | - | Needs significant practice |
| Apprentice | 70-79% | Bronze | Building foundations |
| Proficient | 80-89% | Silver | Solid fundamentals |
| Expert | 90-94% | Gold | High skill level |
| Master | 95-97% | Platinum | Near perfect |
| Legendary | 98-100% | Diamond | Exceptional |

### 2. Words Per Minute (WPM)

**Definition:** Typing speed measured in words per minute.

```gdscript
func calculate_wpm(characters: int, time_seconds: float) -> float:
    if time_seconds == 0:
        return 0.0
    # Standard: 5 characters = 1 word
    var words = characters / 5.0
    var minutes = time_seconds / 60.0
    return words / minutes
```

**Gross vs Net WPM:**
- **Gross WPM:** Total characters typed / 5 / minutes
- **Net WPM:** (Total characters - errors) / 5 / minutes
- **Game uses Net WPM** for all displays and rankings

**WPM Tiers:**

| Tier | WPM | Badge | Percentile |
|------|-----|-------|------------|
| Beginner | 0-19 | - | Bottom 25% |
| Developing | 20-34 | Bronze | 25-50% |
| Average | 35-49 | Silver | 50-75% |
| Above Average | 50-64 | Gold | 75-90% |
| Fast | 65-84 | Platinum | 90-97% |
| Elite | 85-99 | Diamond | 97-99% |
| World Class | 100+ | Mythic | Top 1% |

### 3. Consistency

**Definition:** Variance in keystroke timing.

```gdscript
func calculate_consistency(keystroke_times: Array) -> float:
    if keystroke_times.size() < 2:
        return 1.0

    var avg = 0.0
    for t in keystroke_times:
        avg += t
    avg /= keystroke_times.size()

    var variance = 0.0
    for t in keystroke_times:
        variance += pow(t - avg, 2)
    variance /= keystroke_times.size()

    # Convert to 0-1 score (lower variance = higher score)
    var std_dev = sqrt(variance)
    return clamp(1.0 - (std_dev / avg), 0.0, 1.0)
```

**Consistency Tiers:**

| Tier | Score | Description |
|------|-------|-------------|
| Erratic | 0.0-0.5 | Highly variable timing |
| Unsteady | 0.5-0.7 | Noticeable variation |
| Steady | 0.7-0.85 | Good rhythm |
| Consistent | 0.85-0.95 | Very even timing |
| Metronome | 0.95-1.0 | Machine-like precision |

### 4. Combo/Streak

**Definition:** Consecutive correct words without errors.

```gdscript
var current_combo: int = 0
var max_combo: int = 0

func on_word_complete(correct: bool):
    if correct:
        current_combo += 1
        max_combo = max(max_combo, current_combo)
    else:
        current_combo = 0
```

**Combo Multipliers:**

| Combo | Multiplier | Visual Effect |
|-------|------------|---------------|
| 1-4 | 1.0x | None |
| 5-9 | 1.1x | Subtle glow |
| 10-14 | 1.25x | Bright glow |
| 15-19 | 1.5x | Particles |
| 20-24 | 1.75x | Screen flash |
| 25+ | 2.0x | Full effects |

## Composite Scores

### Mastery Score

Combines all metrics into a single 0-100 score.

```gdscript
func calculate_mastery_score(accuracy: float, wpm: float, consistency: float) -> float:
    # Weight factors
    var accuracy_weight = 0.50  # Accuracy is most important
    var speed_weight = 0.35     # Speed matters but less
    var consistency_weight = 0.15  # Bonus for consistency

    # Normalize WPM to 0-1 (100 WPM = 1.0)
    var normalized_wpm = clamp(wpm / 100.0, 0.0, 1.0)

    var score = (
        accuracy * accuracy_weight +
        normalized_wpm * speed_weight +
        consistency * consistency_weight
    ) * 100

    return clamp(score, 0.0, 100.0)
```

### Performance Tier

Based on mastery score:

| Tier | Score Range | Grade | Stars |
|------|-------------|-------|-------|
| Novice | 0-29 | F | ☆☆☆☆☆ |
| Apprentice | 30-44 | D | ★☆☆☆☆ |
| Developing | 45-59 | C | ★★☆☆☆ |
| Proficient | 60-74 | B | ★★★☆☆ |
| Advanced | 75-89 | A | ★★★★☆ |
| Master | 90-100 | S | ★★★★★ |

### Battle Performance Rating

For game battles specifically:

```gdscript
func calculate_battle_rating(stats: Dictionary) -> String:
    var accuracy = stats.get("accuracy", 0.0)
    var wpm = stats.get("wpm", 0.0)
    var enemies_defeated = stats.get("enemies_defeated", 0)
    var damage_taken = stats.get("damage_taken", 0)

    var score = 0

    # Accuracy component (40 points max)
    score += accuracy * 40

    # Speed component (30 points max, caps at 60 WPM)
    score += min(wpm / 60.0, 1.0) * 30

    # Efficiency component (20 points max)
    var efficiency = enemies_defeated / max(enemies_defeated + damage_taken, 1)
    score += efficiency * 20

    # Flawless bonus (10 points)
    if damage_taken == 0:
        score += 10

    # Grade
    if score >= 95: return "S"
    if score >= 85: return "A"
    if score >= 70: return "B"
    if score >= 55: return "C"
    if score >= 40: return "D"
    return "F"
```

## Lesson Mastery

### Per-Lesson Tracking

```json
{
  "lesson_id": "home_row_1",
  "attempts": 15,
  "completions": 12,
  "best_accuracy": 0.96,
  "best_wpm": 42,
  "avg_accuracy": 0.89,
  "avg_wpm": 35,
  "mastery_level": "proficient",
  "mastery_score": 72,
  "time_spent_minutes": 45,
  "last_played": "2026-01-08T14:30:00Z"
}
```

### Mastery Level Progression

```
Attempted → Practiced → Proficient → Mastered → Legendary

Requirements:
- Attempted: 1+ completion
- Practiced: 3+ completions, 70%+ accuracy
- Proficient: 5+ completions, 80%+ accuracy
- Mastered: 10+ completions, 90%+ accuracy, 35+ WPM
- Legendary: 20+ completions, 95%+ accuracy, 50+ WPM
```

## Key-Level Mastery

### Per-Key Statistics

```json
{
  "key": "q",
  "finger": "left_pinky",
  "total_presses": 456,
  "correct_presses": 421,
  "accuracy": 0.923,
  "avg_reaction_time_ms": 312,
  "mastery_level": "proficient"
}
```

### Key Mastery Calculation

```gdscript
func calculate_key_mastery(key_stats: Dictionary) -> String:
    var accuracy = key_stats.get("accuracy", 0.0)
    var presses = key_stats.get("total_presses", 0)
    var reaction_time = key_stats.get("avg_reaction_time_ms", 999)

    # Need enough data
    if presses < 50:
        return "insufficient_data"

    # Accuracy thresholds
    if accuracy < 0.70:
        return "struggling"
    if accuracy < 0.80:
        return "developing"
    if accuracy < 0.90:
        return "proficient"
    if accuracy < 0.95:
        return "advanced"

    # Reaction time bonus for legendary
    if reaction_time < 200:
        return "legendary"

    return "mastered"
```

### Weak Key Detection

```gdscript
func get_weak_keys(profile: Dictionary, threshold: float = 0.85) -> Array:
    var weak = []
    var key_stats = profile.get("key_stats", {})

    for key in key_stats:
        var stats = key_stats[key]
        if stats.get("total_presses", 0) >= 30:  # Need enough data
            if stats.get("accuracy", 1.0) < threshold:
                weak.append({
                    "key": key,
                    "accuracy": stats.get("accuracy"),
                    "finger": FINGER_MAP.get(key, "unknown")
                })

    # Sort by accuracy (worst first)
    weak.sort_custom(func(a, b): return a.accuracy < b.accuracy)
    return weak
```

## Achievement System

### Skill Achievements

| Achievement | Requirement | Points |
|-------------|-------------|--------|
| First Steps | Complete first lesson | 10 |
| Home Row Hero | Master home_row_2 | 25 |
| Full Alphabet | Master full_alpha | 50 |
| Speed Demon | Reach 50 WPM | 50 |
| Lightning Fingers | Reach 75 WPM | 100 |
| Perfectionist | 100% accuracy on any lesson | 50 |
| Streak Master | 25-word combo | 75 |
| Endurance Runner | Complete 10 battles in one session | 50 |

### Progression Achievements

| Achievement | Requirement | Points |
|-------------|-------------|--------|
| Act I Clear | Complete Act 1 | 100 |
| Act II Clear | Complete Act 2 | 100 |
| Act III Clear | Complete Act 3 | 100 |
| Act IV Clear | Complete Act 4 | 100 |
| Act V Clear | Complete Act 5 | 200 |
| Boss Slayer | Defeat any boss | 50 |
| Void Vanquisher | Defeat Void Tyrant | 200 |

### Collection Achievements

| Achievement | Requirement | Points |
|-------------|-------------|--------|
| Lesson Collector | Attempt 20 different lessons | 50 |
| Master of Many | Master 10 lessons | 100 |
| Finger Trainer | Master all finger training lessons | 75 |
| Realm Conqueror | Complete all realm lessons | 150 |
| Legendary Status | Complete any legendary lesson | 200 |

## Progress Visualization

### Skill Radar Chart

Display proficiency across dimensions:

```
         Accuracy
            ▲
           /|\
          / | \
         /  |  \
        /   |   \
       /    |    \
Speed ◄─────┼─────► Consistency
       \    |    /
        \   |   /
         \  |  /
          \ | /
           \|/
            ▼
         Combo
```

### Progress Timeline

```
┌─────────────────────────────────────────────────────────┐
│ YOUR PROGRESS                                           │
├─────────────────────────────────────────────────────────┤
│                                                         │
│ WPM  60 ┤                                    ○          │
│      50 ┤                          ○──○──○──○           │
│      40 ┤              ○──○──○──○──○                    │
│      30 ┤    ○──○──○──○                                 │
│      20 ┤ ○──○                                          │
│         └────┬────┬────┬────┬────┬────┬────┬────┬───    │
│           Week 1    2    3    4    5    6    7    8     │
│                                                         │
│ Accuracy: 78% → 89% (+11%)                             │
│ Lessons Mastered: 8                                     │
│ Total Practice Time: 12h 34m                           │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Keyboard Heatmap

Visual display of key mastery:

```
┌─────────────────────────────────────────────────────────┐
│ KEY MASTERY HEATMAP                                     │
├─────────────────────────────────────────────────────────┤
│                                                         │
│ [Q]  [W]  [E]  [R]  [T]  [Y]  [U]  [I]  [O]  [P]       │
│  75   92   97   95   94   93   96   98   94   78        │
│                                                         │
│   [A]  [S]  [D]  [F]  [G]  [H]  [J]  [K]  [L]  [;]     │
│    82   94   96   98   95   96   99   97   95   80      │
│                                                         │
│     [Z]  [X]  [C]  [V]  [B]  [N]  [M]                   │
│      70   85   94   93   91   95   96                   │
│                                                         │
│ 🔴 <70%  🟠 70-79%  🟡 80-89%  🟢 90-94%  🔵 95%+       │
└─────────────────────────────────────────────────────────┘
```

## Certification System

### Skill Certificates

```json
{
  "certificate": "Home Row Master",
  "awarded": "2026-01-08",
  "requirements_met": {
    "lesson": "home_row_2",
    "mastery_level": "mastered",
    "accuracy": 0.92,
    "wpm": 38
  },
  "badge": "🏆"
}
```

### Certificate Levels

| Certificate | Requirements |
|-------------|--------------|
| Home Row Certified | Master home_row_1 + home_row_2 |
| Full Keyboard Certified | Master all row lessons |
| Speed Certified | 50+ WPM on any lesson |
| Precision Certified | 95%+ accuracy on 5 lessons |
| Numbers Certified | Master numbers_1 + numbers_2 |
| Symbols Certified | Master symbols_1 + symbols_2 |
| Master Typist | All above + 60 WPM + 90% accuracy overall |

## Implementation Checklist

### Data
- [ ] Define mastery thresholds in config
- [ ] Create achievement definitions
- [ ] Design certificate requirements

### Code
- [ ] Implement mastery score calculation
- [ ] Add per-key statistics tracking
- [ ] Create weak key detection
- [ ] Build achievement checking system
- [ ] Implement certificate awarding

### UI
- [ ] Create mastery display components
- [ ] Build skill radar chart
- [ ] Implement keyboard heatmap
- [ ] Design achievement notifications
- [ ] Create certificate display

## References

- `docs/plans/p1/LESSON_GUIDE_PLAN.md` - Lesson structure
- `docs/plans/p1/LESSON_PROGRESSION_TREE.md` - Unlock criteria
- `docs/plans/p1/TYPING_DRILLS_SPECIFICATION.md` - Drill types
- `game/typing_profile.gd` - Profile persistence
