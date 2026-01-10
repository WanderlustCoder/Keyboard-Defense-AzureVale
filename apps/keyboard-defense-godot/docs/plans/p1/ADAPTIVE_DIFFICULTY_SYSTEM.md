# Adaptive Difficulty System

**Created:** 2026-01-08

This document specifies how the game dynamically adjusts difficulty based on player performance to maintain optimal challenge and learning.

## Design Goals

1. **Optimal Challenge** - Keep players in the "flow zone"
2. **Prevent Frustration** - Reduce difficulty when struggling
3. **Prevent Boredom** - Increase difficulty when coasting
4. **Invisible Adjustment** - Changes feel natural, not jarring
5. **Preserve Determinism** - Difficulty affects content, not RNG

## Flow Zone Theory

```
              ┌───────────────────────────────────────┐
              │                                       │
   Anxiety    │                   X Too Hard          │
              │               ↗                       │
              │           Flow                        │
   Challenge  │       ↗   Zone                        │
              │   ↗       ████                        │
              │ X         ████                        │
              │ Too Easy  ████                        │
   Boredom    │                                       │
              └───────────────────────────────────────┘
                         Skill Level →
```

**Target:** Keep players in the Flow Zone where challenge matches skill.

## Difficulty Parameters

### Word Parameters

| Parameter | Min | Default | Max | Effect |
|-----------|-----|---------|-----|--------|
| word_length_min | 2 | 3 | 5 | Shorter = easier |
| word_length_max | 4 | 6 | 12 | Shorter = easier |
| word_complexity | 0.0 | 0.5 | 1.0 | Uncommon letters |
| word_familiarity | 0.0 | 0.5 | 1.0 | Common words |

### Enemy Parameters

| Parameter | Min | Default | Max | Effect |
|-----------|-----|---------|-----|--------|
| enemy_speed | 0.5 | 1.0 | 2.0 | Slower = easier |
| enemy_count | 0.5 | 1.0 | 1.5 | Fewer = easier |
| enemy_hp | 0.5 | 1.0 | 1.5 | Lower = easier |
| spawn_interval | 1.5 | 1.0 | 0.5 | Longer = easier |

### Time Parameters

| Parameter | Min | Default | Max | Effect |
|-----------|-----|---------|-----|--------|
| time_pressure | 0.5 | 1.0 | 1.5 | Lower = easier |
| reaction_window | 1.5 | 1.0 | 0.7 | Longer = easier |

## Performance Tracking

### Session Metrics

```gdscript
class_name SessionMetrics

var accuracy_history: Array[float] = []
var wpm_history: Array[float] = []
var combo_history: Array[int] = []
var damage_taken_history: Array[int] = []

func get_recent_accuracy(count: int = 5) -> float:
    if accuracy_history.is_empty():
        return 0.5
    var recent = accuracy_history.slice(-count)
    var sum = 0.0
    for a in recent:
        sum += a
    return sum / recent.size()

func get_trend() -> String:
    if accuracy_history.size() < 3:
        return "insufficient_data"

    var recent = get_recent_accuracy(3)
    var older = get_recent_accuracy(6) - recent

    if recent > older + 0.05:
        return "improving"
    elif recent < older - 0.05:
        return "declining"
    return "stable"
```

### Struggle Detection

```gdscript
func is_struggling(metrics: SessionMetrics) -> bool:
    # Check recent accuracy
    if metrics.get_recent_accuracy(3) < 0.70:
        return true

    # Check damage trend
    var recent_damage = metrics.damage_taken_history.slice(-3)
    if recent_damage.size() >= 3:
        var avg_damage = 0
        for d in recent_damage:
            avg_damage += d
        avg_damage /= recent_damage.size()
        if avg_damage > 2:
            return true

    # Check if declining
    if metrics.get_trend() == "declining":
        var accuracy = metrics.get_recent_accuracy()
        if accuracy < 0.80:
            return true

    return false

func is_coasting(metrics: SessionMetrics) -> bool:
    # Check if too easy
    if metrics.get_recent_accuracy(5) > 0.95:
        var recent_wpm = metrics.wpm_history.slice(-3)
        if recent_wpm.size() >= 3:
            var avg_wpm = 0.0
            for w in recent_wpm:
                avg_wpm += w
            avg_wpm /= recent_wpm.size()
            if avg_wpm > 50:  # Fast AND accurate
                return true

    # Perfect runs with no damage
    var recent_damage = metrics.damage_taken_history.slice(-3)
    if recent_damage.size() >= 3:
        var total_damage = 0
        for d in recent_damage:
            total_damage += d
        if total_damage == 0:
            return true

    return false
```

## Difficulty Adjustment Algorithm

### Core Algorithm

```gdscript
class_name DifficultyManager

var current_difficulty: float = 1.0  # 0.5 to 1.5
var adjustment_rate: float = 0.1     # How fast to adjust
var cooldown_battles: int = 0        # Prevent rapid changes

func update_difficulty(metrics: SessionMetrics):
    if cooldown_battles > 0:
        cooldown_battles -= 1
        return

    var target_difficulty = current_difficulty

    if is_struggling(metrics):
        target_difficulty = max(0.5, current_difficulty - adjustment_rate)
        cooldown_battles = 2  # Wait before adjusting again
    elif is_coasting(metrics):
        target_difficulty = min(1.5, current_difficulty + adjustment_rate * 0.5)
        cooldown_battles = 3  # Slower to increase

    # Smooth transition
    current_difficulty = lerp(current_difficulty, target_difficulty, 0.3)
```

### Difficulty Application

```gdscript
func apply_difficulty_to_wave(base_wave: Dictionary) -> Dictionary:
    var adjusted = base_wave.duplicate(true)

    # Adjust enemy count
    var count = adjusted.get("enemy_count", 5)
    adjusted["enemy_count"] = int(count * current_difficulty)

    # Adjust enemy speed
    var speed = adjusted.get("enemy_speed", 1.0)
    adjusted["enemy_speed"] = speed * sqrt(current_difficulty)

    # Adjust word length
    var min_len = adjusted.get("word_length_min", 3)
    var max_len = adjusted.get("word_length_max", 6)

    if current_difficulty < 1.0:
        # Easier - shorter words
        adjusted["word_length_max"] = max(min_len + 1, max_len - 2)
    elif current_difficulty > 1.0:
        # Harder - longer words
        adjusted["word_length_min"] = min(min_len + 1, max_len - 2)
        adjusted["word_length_max"] = max_len + 1

    return adjusted

func apply_difficulty_to_words(base_words: Array, charset: String) -> Array:
    var adjusted = []

    for word in base_words:
        # Filter by difficulty
        var complexity = calculate_word_complexity(word, charset)

        if current_difficulty < 0.8:
            # Easy - only simple words
            if complexity < 0.4:
                adjusted.append(word)
        elif current_difficulty > 1.2:
            # Hard - include complex words
            adjusted.append(word)
        else:
            # Normal - moderate filter
            if complexity < 0.7:
                adjusted.append(word)

    return adjusted if not adjusted.is_empty() else base_words
```

## Word Complexity Scoring

```gdscript
const UNCOMMON_LETTERS = "qzxjkvbpyw"
const HARD_BIGRAMS = ["qu", "xc", "zz", "kn", "wr", "gh"]

func calculate_word_complexity(word: String, charset: String) -> float:
    var score = 0.0

    # Length factor (longer = harder)
    score += (word.length() - 3) * 0.05

    # Uncommon letter factor
    for c in word:
        if c in UNCOMMON_LETTERS:
            score += 0.1

    # Hard bigram factor
    for bigram in HARD_BIGRAMS:
        if bigram in word:
            score += 0.15

    # Same-hand sequences (harder)
    var same_hand_count = count_same_hand_sequences(word)
    score += same_hand_count * 0.05

    # Double letter (easier)
    if has_double_letters(word):
        score -= 0.1

    return clamp(score, 0.0, 1.0)

func count_same_hand_sequences(word: String) -> int:
    var count = 0
    var left_keys = "qwertasdfgzxcvb"
    var last_hand = ""

    for c in word:
        var current_hand = "left" if c in left_keys else "right"
        if current_hand == last_hand:
            count += 1
        last_hand = current_hand

    return count
```

## Difficulty Presets

### Story Mode Difficulty

```json
{
  "story_easy": {
    "base_difficulty": 0.7,
    "adjustment_enabled": true,
    "min_difficulty": 0.5,
    "max_difficulty": 1.0,
    "description": "Relaxed pace, forgiving timing"
  },
  "story_normal": {
    "base_difficulty": 1.0,
    "adjustment_enabled": true,
    "min_difficulty": 0.7,
    "max_difficulty": 1.3,
    "description": "Balanced challenge"
  },
  "story_hard": {
    "base_difficulty": 1.2,
    "adjustment_enabled": true,
    "min_difficulty": 1.0,
    "max_difficulty": 1.5,
    "description": "Demanding, requires skill"
  },
  "story_master": {
    "base_difficulty": 1.5,
    "adjustment_enabled": false,
    "description": "Fixed high difficulty, no mercy"
  }
}
```

### Practice Mode Difficulty

```json
{
  "practice_free": {
    "adjustment_enabled": false,
    "description": "No time pressure, pure practice"
  },
  "practice_adaptive": {
    "adjustment_enabled": true,
    "min_difficulty": 0.3,
    "max_difficulty": 2.0,
    "aggressive_adjustment": true,
    "description": "Constantly adjusts to skill"
  }
}
```

## Player Skill Profile

### Long-term Skill Tracking

```gdscript
class_name PlayerSkillProfile

var overall_skill: float = 0.5      # 0.0 to 1.0
var accuracy_skill: float = 0.5
var speed_skill: float = 0.5
var consistency_skill: float = 0.5

var lesson_skills: Dictionary = {}  # Per-lesson skill ratings
var key_skills: Dictionary = {}     # Per-key proficiency

func update_from_battle(battle_stats: Dictionary):
    var accuracy = battle_stats.get("accuracy", 0.5)
    var wpm = battle_stats.get("wpm", 30)
    var consistency = battle_stats.get("consistency", 0.5)

    # Exponential moving average
    var alpha = 0.2
    accuracy_skill = lerp(accuracy_skill, accuracy, alpha)
    speed_skill = lerp(speed_skill, wpm / 100.0, alpha)
    consistency_skill = lerp(consistency_skill, consistency, alpha)

    overall_skill = (accuracy_skill * 0.5 +
                     speed_skill * 0.35 +
                     consistency_skill * 0.15)

func get_recommended_difficulty() -> float:
    # Map skill to difficulty
    # Skill 0.3 -> Difficulty 0.7
    # Skill 0.5 -> Difficulty 1.0
    # Skill 0.7 -> Difficulty 1.3
    return 0.4 + overall_skill * 1.2
```

## Adaptive Content Selection

### Lesson Recommendation

```gdscript
func get_recommended_lessons(profile: PlayerSkillProfile) -> Array:
    var recommendations = []

    # Find lessons at appropriate difficulty
    for lesson in all_lessons:
        var lesson_difficulty = get_lesson_difficulty(lesson)
        var skill_match = abs(lesson_difficulty - profile.overall_skill)

        if skill_match < 0.2:  # Good match
            recommendations.append({
                "lesson": lesson,
                "reason": "matches_skill",
                "priority": 1.0 - skill_match
            })

    # Add lessons targeting weak keys
    var weak_keys = get_weak_keys(profile)
    for lesson in all_lessons:
        if lesson_targets_keys(lesson, weak_keys):
            recommendations.append({
                "lesson": lesson,
                "reason": "targets_weakness",
                "priority": 0.8
            })

    # Sort by priority
    recommendations.sort_custom(func(a, b): return a.priority > b.priority)
    return recommendations.slice(0, 5)
```

### Word Selection for Weak Keys

```gdscript
func select_adaptive_words(profile: PlayerSkillProfile, lesson: Dictionary) -> Array:
    var words = []
    var weak_keys = get_weak_keys_from_profile(profile)
    var charset = lesson.get("charset", "")

    # 40% words targeting weak keys
    var weak_key_words = generate_words_with_keys(weak_keys, charset, 4)
    words.append_array(weak_key_words)

    # 30% balanced practice
    var balanced_words = generate_balanced_words(charset, 3)
    words.append_array(balanced_words)

    # 30% varied difficulty
    var varied_words = generate_varied_words(charset, 3, profile.overall_skill)
    words.append_array(varied_words)

    return words
```

## Feedback Systems

### Difficulty Indicator (Optional)

```
┌─────────────────────────────────────────────────────────┐
│ Current Challenge: ████████░░ 80%                       │
│ [Adjusting to your skill level...]                     │
└─────────────────────────────────────────────────────────┘
```

### Post-Battle Feedback

```gdscript
func generate_feedback(battle_stats: Dictionary, difficulty: float) -> String:
    var accuracy = battle_stats.get("accuracy", 0.0)
    var wpm = battle_stats.get("wpm", 0)

    if accuracy > 0.95 and wpm > 50:
        if difficulty < 1.3:
            return "Excellent! Challenge increased for next battle."
        return "Masterful performance!"

    if accuracy < 0.70:
        if difficulty > 0.7:
            return "That was tough. Next battle will be slightly easier."
        return "Keep practicing! Every attempt makes you stronger."

    return "Good job! Keep up the practice."
```

## Configuration Options

### Player Settings

```json
{
  "adaptive_difficulty": {
    "enabled": true,
    "show_indicator": false,
    "base_difficulty": "normal",
    "allow_increase": true,
    "allow_decrease": true
  }
}
```

### Accessibility Options

```json
{
  "accessibility": {
    "fixed_easy_mode": false,
    "extended_timers": false,
    "reduced_enemy_speed": false,
    "no_fail_mode": false
  }
}
```

## Implementation Checklist

### Core System
- [ ] Implement DifficultyManager class
- [ ] Add session metrics tracking
- [ ] Create struggle/coast detection
- [ ] Implement difficulty application

### Content Adaptation
- [ ] Add word complexity scoring
- [ ] Implement adaptive word selection
- [ ] Create lesson recommendation system
- [ ] Add weak key targeting

### Player Profile
- [ ] Track long-term skill metrics
- [ ] Persist difficulty preferences
- [ ] Implement skill progression

### UI/Feedback
- [ ] Create difficulty indicator (optional)
- [ ] Add adjustment notifications
- [ ] Show skill progression

## References

- `docs/plans/p1/MASTERY_ASSESSMENT_CRITERIA.md` - Skill metrics
- `docs/plans/p1/LESSON_PROGRESSION_TREE.md` - Unlock system
- `docs/plans/p1/TYPING_DRILLS_SPECIFICATION.md` - Practice modes
- `game/typing_profile.gd` - Profile persistence
- `sim/enemies.gd` - Enemy parameters
