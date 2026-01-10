# Typing Combat Guide

This document explains how the typing-as-combat system works in Keyboard Defense, providing implementation patterns for Claude Code.

## Overview

Typing is the primary combat mechanic. Players defeat enemies by typing their associated words. The system connects keyboard input to enemy targeting and damage resolution.

```
Player types word → Word matching → Enemy targeted → Damage applied → Combat step advances
```

## Core Flow

### 1. Input Capture (`game/main.gd`)

```gdscript
# In _input() or command bar submission
var intent = CommandParser.parse(text)
var result = IntentApplier.apply(state, intent)
```

During night phase, text that isn't a command becomes a defend intent:
```gdscript
# Implicit conversion for night phase
intent = SimIntents.make("defend_input", {"text": typed_text})
```

### 2. Word Matching (`sim/typing_feedback.gd`)

The `enemy_candidates()` function evaluates typed text against all active enemies:

```gdscript
static func enemy_candidates(enemies: Array, typed_raw: String) -> Dictionary:
    # Returns:
    # - exact_id: ID of enemy if exactly one exact match
    # - candidate_ids: All enemies whose words begin with typed text
    # - best_prefix_len: Longest matching prefix
    # - best_ids: Enemies with the longest prefix match
    # - expected_next_chars: Valid next characters to type
    # - suggestions: Top 3 closest matches
```

**Key algorithms:**

| Function | Purpose | Used When |
|----------|---------|-----------|
| `normalize_input(s)` | Strips whitespace, lowercases | Every input |
| `prefix_len(typed, word)` | Count matching characters from start | Checking partial matches |
| `edit_distance(a, b)` | Levenshtein distance for similarity | Ranking suggestions |

### 3. Combat Resolution (`sim/apply_intent.gd`)

```gdscript
static func _apply_defend_input(state, intent, events) -> bool:
    var text = intent.get("text", "")
    var normalized = SimTypingFeedback.normalize_input(text)
    var target_index = _find_enemy_index_by_word(state, normalized)

    if target_index >= 0:
        # Hit! Attack the enemy
        return _advance_night_step(state, target_index, true, events, normalized)
    else:
        # Miss! Penalty applied
        return _advance_night_step(state, -1, true, events, "")
```

### 4. Night Step (`sim/apply_intent.gd`)

Each typed word (hit or miss) advances the combat step:

```
1. Player attack (if hit)
2. Spawn new enemies (if spawns remaining)
3. Tower attacks (autonomous)
4. Enemy movement
5. Enemy abilities tick
6. Check victory/defeat conditions
```

```gdscript
static func _advance_night_step(state, hit_enemy_index, apply_miss_penalty, events, hit_word) -> bool:
    var dist_field = SimMap.compute_dist_to_base(state)

    # 1. Player attack
    if hit_enemy_index >= 0:
        _apply_player_attack_target(state, hit_enemy_index, hit_word, events)
    else:
        # Miss penalty (unless forgiven by upgrades)
        if apply_miss_penalty and not state.practice_mode:
            state.hp -= 1

    # 2-5. Combat step
    _spawn_enemy_step(state, events)
    _tower_attack_step(state, dist_field, events)
    _enemy_move_step(state, dist_field, events)
    _enemy_ability_tick(state, events)

    # 6. Victory/defeat
    if state.hp <= 0:
        state.phase = "game_over"
    elif state.night_spawn_remaining <= 0 and state.enemies.is_empty():
        state.phase = "day"  # Dawn!
```

## Word Assignment

### From Lessons (`sim/lessons.gd`, `sim/words.gd`)

Enemies receive words from the current lesson's word pool:

```gdscript
# In sim/enemies.gd make_enemy()
var word_pool = SimLessons.get_word_pool(state.lesson_id)
var word = SimWords.pick_word(state, word_pool, enemy_tier)
enemy["word"] = word
```

**Word selection factors:**
- Lesson focus keys
- Enemy tier (higher tier = longer/harder words)
- Already-assigned words (avoid duplicates)

### Word Difficulty Scaling

| Enemy Tier | Word Length | Complexity |
|------------|-------------|------------|
| 1 (basic) | 3-5 chars | Home row only |
| 2 (elite) | 5-7 chars | Add reach keys |
| 3 (champion) | 7-10 chars | Full keyboard |
| Boss | 8-12 chars | Complex patterns |

## Damage Calculation

### Player Attack (`sim/apply_intent.gd:371+`)

```gdscript
static func _apply_player_attack_target(state, target_index, hit_word, events):
    var enemy = state.enemies[target_index]

    # Base damage
    var base_damage = 2
    var typing_power = SimUpgrades.get_typing_power(state)  # Default 1.0
    var damage = int(base_damage * typing_power)

    # Critical hit (word length bonus)
    var crit_chance = SimUpgrades.get_crit_chance(state)
    if hit_word.length() >= 6:
        crit_chance += 0.1  # Long words have higher crit chance

    if randf() <= crit_chance:
        damage *= 2
        is_crit = true

    # Armor reduction
    var armor = enemy.get("armor", 0)
    damage = max(1, damage - armor)

    # Apply damage
    enemy["hp"] -= damage
    if enemy["hp"] <= 0:
        _kill_enemy(state, target_index, events)
```

### Upgrade Effects

| Upgrade | Effect | Source |
|---------|--------|--------|
| Typing Power | Damage multiplier | `SimUpgrades.get_typing_power()` |
| Crit Chance | % chance for 2x damage | `SimUpgrades.get_crit_chance()` |
| Mistake Forgiveness | % chance to avoid miss penalty | `SimUpgrades.get_mistake_forgiveness()` |
| Wave Heal | HP restored at dawn | `SimUpgrades.get_wave_heal()` |

## Enemy Targeting

### Finding Target by Word

```gdscript
static func _find_enemy_index_by_word(state: GameState, word: String) -> int:
    for i in range(state.enemies.size()):
        var enemy = state.enemies[i]
        var enemy_word = SimTypingFeedback.normalize_input(enemy.get("word", ""))
        if enemy_word == word:
            return i
    return -1  # No match
```

### Priority Rules

When multiple enemies share word prefixes:
1. **Exact match wins** - If typed text exactly matches one enemy's word
2. **Keep typing** - If typed text is a prefix of multiple words
3. **Closest enemy** - For UI highlighting/suggestions

## Typing Feedback UI

### Real-time Feedback (`game/main.gd`)

```gdscript
# Update as user types
var candidates = SimTypingFeedback.enemy_candidates(state.enemies, partial_text)

# Show:
# - Which enemy words match the partial input
# - Expected next characters
# - Top 3 closest suggestions
```

### Feedback Dictionary

```gdscript
{
    "typed": "gob",                    # Normalized input
    "exact_id": -1,                    # No exact match yet
    "candidate_ids": [3, 7],           # Enemies with words starting "gob..."
    "best_prefix_len": 3,              # Matched 3 characters
    "best_ids": [3, 7],                # Enemies with best match
    "expected_next_chars": ["l", "b"], # Valid next chars (goblin, gobbler)
    "suggestions": [                   # Top matches
        {"id": 3, "word": "goblin", "prefix_len": 3, "dist": 45},
        {"id": 7, "word": "gobbler", "prefix_len": 3, "dist": 67}
    ]
}
```

## Practice Mode

When `state.practice_mode == true`:
- Misses don't reduce HP
- "Miss. (practice mode - no damage)" message
- All other mechanics work normally

## Integration Points

### Adding New Typing Mechanics

1. **New word source**: Modify `SimWords.pick_word()`
2. **New damage modifier**: Add to `_apply_player_attack_target()`
3. **New feedback type**: Extend `enemy_candidates()` return dict
4. **New upgrade effect**: Add to `SimUpgrades` and apply in damage calc

### Common Patterns

**Checking typed progress:**
```gdscript
var candidates = SimTypingFeedback.enemy_candidates(state.enemies, text)
if candidates.best_prefix_len > 0:
    # Partial match - show highlighting
    highlight_enemies(candidates.best_ids)
```

**Custom word validation:**
```gdscript
# Before standard matching
if is_special_command(text):
    handle_special(text)
    return
# Fall through to normal combat
```

## Testing Typing Combat

```gdscript
func test_typing_combat():
    var state = GameState.new()
    state.phase = "night"

    # Add enemy with known word
    var enemy = {"id": 1, "word": "test", "hp": 5, "dist": 10}
    state.enemies.append(enemy)

    # Simulate typing
    var intent = SimIntents.make("defend_input", {"text": "test"})
    var result = IntentApplier.apply(state, intent)

    # Verify hit
    assert(state.enemies.is_empty() or state.enemies[0]["hp"] < 5)
```

## Common Pitfalls

1. **Forgetting normalization** - Always use `normalize_input()` before comparing
2. **Case sensitivity** - All comparisons should be lowercase
3. **Empty input** - Check for empty string before processing
4. **Duplicate words** - Two enemies shouldn't have the same word
5. **Phase check** - Combat only works in "night" phase
