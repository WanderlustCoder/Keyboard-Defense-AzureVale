# Typing Feedback Guide

This document explains the real-time typing feedback system that provides intelligent word matching, candidate ranking, and input routing during night combat.

## Overview

The typing feedback system analyzes player input and determines the best response:

```
Player Input → Normalize → Find Candidates → Rank by Match Quality → Route Action
      ↓            ↓              ↓                   ↓                   ↓
  "rai"        "rai"       [raider, raid]      prefix > edit dist    incomplete
```

## Core Algorithms

### Input Normalization

```gdscript
# sim/typing_feedback.gd:6
static func normalize_input(s: String) -> String:
    return s.strip_edges().to_lower()
```

All comparisons use lowercase, trimmed strings for consistent matching.

### Prefix Length Calculation

Determines how many characters match from the start:

```gdscript
# sim/typing_feedback.gd:9
static func prefix_len(typed: String, word: String) -> int:
    var left: String = normalize_input(typed)
    var right: String = normalize_input(word)
    var limit: int = min(left.length(), right.length())
    var count: int = 0
    while count < limit:
        if left[count] != right[count]:
            break
        count += 1
    return count
```

Examples:
- `prefix_len("rai", "raider")` → 3 (all match)
- `prefix_len("rad", "raider")` → 2 (r, a match; d ≠ i)
- `prefix_len("scout", "raider")` → 0 (no common prefix)

### Edit Distance (Levenshtein)

Measures minimum edits needed to transform one string into another:

```gdscript
# sim/typing_feedback.gd:20
static func edit_distance(a: String, b: String) -> int:
    var left: String = normalize_input(a)
    var right: String = normalize_input(b)
    var n: int = left.length()
    var m: int = right.length()

    if n == 0:
        return m
    if m == 0:
        return n

    # Dynamic programming with two-row optimization
    var prev: Array[int] = []
    var curr: Array[int] = []
    prev.resize(m + 1)
    curr.resize(m + 1)

    for j in range(m + 1):
        prev[j] = j

    for i in range(1, n + 1):
        curr[0] = i
        var left_char: String = left.substr(i - 1, 1)
        for j in range(1, m + 1):
            var right_char: String = right.substr(j - 1, 1)
            var cost: int = 0 if left_char == right_char else 1
            curr[j] = min(prev[j] + 1, curr[j - 1] + 1, prev[j - 1] + cost)
        var tmp: Array[int] = prev
        prev = curr
        curr = tmp

    return prev[m]
```

Examples:
- `edit_distance("raider", "raider")` → 0 (identical)
- `edit_distance("raider", "radier")` → 1 (one substitution)
- `edit_distance("raid", "raider")` → 2 (two insertions)

## Candidate Ranking

### Enemy Candidates

Find and rank potential target enemies based on typed input:

```gdscript
# sim/typing_feedback.gd:47
static func enemy_candidates(enemies: Array, typed_raw: String) -> Dictionary:
    var typed: String = normalize_input(typed_raw)
    var candidate_ids: Array[int] = []      # Enemies whose words START with typed
    var best_prefix_len: int = 0            # Longest prefix match
    var best_ids: Array[int] = []           # IDs with best prefix
    var exact_id: int = -1                  # Single exact match (-1 if none or multiple)
    var exact_count: int = 0
    var suggestions: Array = []

    for enemy in enemies:
        var enemy_id: int = int(enemy.get("id", -1))
        var word: String = normalize_input(str(enemy.get("word", "")))
        var match_len: int = prefix_len(typed, word)

        # Track exact matches
        if typed != "" and word == typed:
            exact_count += 1
            if exact_count == 1:
                exact_id = enemy_id

        # Track prefix matches (typed is start of word)
        if typed != "" and word.begins_with(typed):
            candidate_ids.append(enemy_id)

        # Track best partial matches
        if typed != "" and match_len > 0:
            if match_len > best_prefix_len:
                best_prefix_len = match_len
                best_ids = [enemy_id]
            elif match_len == best_prefix_len:
                best_ids.append(enemy_id)

        # Build suggestion list
        if typed != "":
            suggestions.append({
                "id": enemy_id,
                "word": word,
                "prefix_len": match_len,
                "dist": int(enemy.get("dist", 9999))
            })

    # Invalidate exact_id if multiple exact matches
    if exact_count > 1:
        exact_id = -1

    # ... calculate expected_next_chars and sort suggestions ...

    return {
        "typed": typed,
        "exact_id": exact_id,
        "candidate_ids": candidate_ids,
        "best_prefix_len": best_prefix_len,
        "best_ids": best_ids,
        "expected_next_chars": expected_next_chars,
        "suggestions": suggestions
    }
```

### Result Dictionary

| Field | Type | Description |
|-------|------|-------------|
| `typed` | String | Normalized input |
| `exact_id` | int | Enemy ID for exact match (-1 if none/multiple) |
| `candidate_ids` | Array[int] | All enemies whose words start with typed |
| `best_prefix_len` | int | Longest matching prefix found |
| `best_ids` | Array[int] | Enemy IDs with best prefix length |
| `expected_next_chars` | Array[String] | Valid next characters to type |
| `suggestions` | Array | Top 3 candidates with metadata |

### Next Character Prediction

Determines which keys would continue a valid word:

```gdscript
# From enemy_candidates():
var expected_next_chars: Array[String] = []
if typed != "" and best_prefix_len > 0 and not best_ids.is_empty():
    var next_chars: Dictionary = {}
    for enemy in enemies:
        var enemy_id: int = int(enemy.get("id", -1))
        if not best_ids.has(enemy_id):
            continue
        var word: String = normalize_input(str(enemy.get("word", "")))
        if best_prefix_len < word.length():
            var next_char: String = word.substr(best_prefix_len, 1)
            next_chars[next_char] = true
    for key in next_chars.keys():
        expected_next_chars.append(str(key))
    expected_next_chars.sort()
```

Example: If typed = "ra" and words are ["raider", "ranger", "radiant"]:
- `expected_next_chars` = ["d", "i", "n"] (next valid characters)

### Suggestion Sorting

Suggestions are sorted by quality:

```gdscript
# sim/typing_feedback.gd:150
static func _sort_suggestions(a: Dictionary, b: Dictionary) -> bool:
    # 1. Longer prefix match is better
    var a_len: int = int(a.get("prefix_len", 0))
    var b_len: int = int(b.get("prefix_len", 0))
    if a_len != b_len:
        return a_len > b_len

    # 2. Closer enemies (lower dist) are better
    var a_dist: int = int(a.get("dist", 9999))
    var b_dist: int = int(b.get("dist", 9999))
    if a_dist != b_dist:
        return a_dist < b_dist

    # 3. Tiebreaker: lower ID first
    return int(a.get("id", 0)) < int(b.get("id", 0))
```

## Input Routing

### Night Input Router

Determines what action to take based on input:

```gdscript
# sim/typing_feedback.gd:124
static func route_night_input(parse_ok: bool, intent_kind: String, typed_raw: String, enemies: Array) -> Dictionary:
    var candidates: Dictionary = enemy_candidates(enemies, typed_raw)

    # If it parsed as a valid command, execute command
    if parse_ok:
        return {"action": "command", "reason": "parsed command", "candidates": candidates}

    var typed: String = str(candidates.get("typed", ""))

    # Empty input
    if typed == "":
        return {"action": "incomplete", "reason": "empty", "candidates": candidates}

    # Exact match found - attack that enemy
    if int(candidates.get("exact_id", -1)) != -1:
        return {"action": "defend", "reason": "exact match", "candidates": candidates}

    # Partial matches exist - keep typing
    if Array(candidates.get("candidate_ids", [])).size() > 0:
        return {"action": "incomplete", "reason": "prefix match; keep typing", "candidates": candidates}

    # Might be typing a command
    if _is_command_prefix(typed):
        return {"action": "incomplete", "reason": "command prefix; keep typing", "candidates": candidates}

    # No match - treat as miss attempt
    return {"action": "defend", "reason": "no match; miss attempt", "candidates": candidates}
```

### Action Types

| Action | Meaning | When Triggered |
|--------|---------|----------------|
| `command` | Execute parsed command | Valid command syntax detected |
| `defend` | Attack enemy / miss | Exact match OR no possible matches |
| `incomplete` | Keep typing | Partial match OR possible command |

### Command Prefix Detection

```gdscript
# sim/typing_feedback.gd:144
static func _is_command_prefix(typed: String) -> bool:
    for keyword in CommandKeywords.KEYWORDS:
        if str(keyword).begins_with(typed):
            return true
    return false
```

Prevents accidental misses when typing commands like "help" or "status".

## Integration Examples

### Battle Input Handler

```gdscript
func _on_input_submitted(text: String) -> void:
    # Try to parse as command first
    var parse_result := SimParseCommand.parse(text)
    var parse_ok: bool = parse_result.get("ok", false)
    var intent_kind: String = str(parse_result.get("kind", ""))

    # Get routing decision
    var routing := SimTypingFeedback.route_night_input(
        parse_ok,
        intent_kind,
        text,
        state.enemies
    )

    match routing.action:
        "command":
            _execute_command(parse_result)
        "defend":
            var candidates: Dictionary = routing.candidates
            if int(candidates.exact_id) != -1:
                _attack_enemy(candidates.exact_id)
            else:
                _register_miss()
        "incomplete":
            _show_feedback(routing.reason)
```

### Real-Time Typing Display

```gdscript
func _on_text_changed(new_text: String) -> void:
    var candidates := SimTypingFeedback.enemy_candidates(state.enemies, new_text)

    # Highlight matching enemies
    for suggestion in candidates.suggestions:
        _highlight_enemy(suggestion.id, suggestion.prefix_len)

    # Show next valid keys
    _update_keyboard_hints(candidates.expected_next_chars)

    # Update suggestion display
    _show_suggestions(candidates.suggestions)
```

### Autocomplete Hints

```gdscript
func _get_autocomplete_text(typed: String) -> String:
    var candidates := SimTypingFeedback.enemy_candidates(state.enemies, typed)

    if candidates.suggestions.is_empty():
        return ""

    # Show best match word with typed portion highlighted
    var best: Dictionary = candidates.suggestions[0]
    var word: String = best.word
    var prefix_len: int = best.prefix_len

    # Return the remaining portion
    return word.substr(prefix_len)
```

## Match Quality Tiers

The system uses these priority tiers:

1. **Exact Match** - Input equals enemy word exactly
2. **Prefix Match** - Input is start of enemy word
3. **Partial Match** - Input shares some starting characters
4. **No Match** - No common prefix (miss)

```
Typed: "rai"

Enemy Words:
  "raider"    → Prefix match (candidate)
  "raid"      → Prefix match (candidate)
  "ranger"    → Partial match (2 chars: "ra")
  "scout"     → No match

Result:
  candidate_ids = [raider_id, raid_id]
  best_prefix_len = 3
  best_ids = [raider_id, raid_id]
```

## Performance Considerations

- Candidate search is O(n) where n = enemy count
- Edit distance is O(m*k) where m, k = string lengths
- Suggestions limited to top 3 to reduce UI updates
- Prefix length is cheapest comparison (O(min(len)))

## Testing

```gdscript
func test_prefix_len():
    assert(SimTypingFeedback.prefix_len("rai", "raider") == 3)
    assert(SimTypingFeedback.prefix_len("rad", "raider") == 2)
    assert(SimTypingFeedback.prefix_len("", "raider") == 0)
    assert(SimTypingFeedback.prefix_len("x", "raider") == 0)
    _pass("test_prefix_len")

func test_edit_distance():
    assert(SimTypingFeedback.edit_distance("raider", "raider") == 0)
    assert(SimTypingFeedback.edit_distance("raider", "radier") == 1)
    assert(SimTypingFeedback.edit_distance("raid", "raider") == 2)
    _pass("test_edit_distance")

func test_enemy_candidates():
    var enemies := [
        {"id": 1, "word": "raider", "dist": 5},
        {"id": 2, "word": "ranger", "dist": 3},
        {"id": 3, "word": "scout", "dist": 7}
    ]

    var result := SimTypingFeedback.enemy_candidates(enemies, "ra")
    assert(result.candidate_ids.has(1))  # raider
    assert(result.candidate_ids.has(2))  # ranger
    assert(not result.candidate_ids.has(3))  # scout
    assert(result.best_prefix_len == 2)

    _pass("test_enemy_candidates")

func test_exact_match_routing():
    var enemies := [{"id": 1, "word": "raider", "dist": 5}]

    var result := SimTypingFeedback.route_night_input(false, "", "raider", enemies)
    assert(result.action == "defend")
    assert(result.reason == "exact match")
    assert(result.candidates.exact_id == 1)

    _pass("test_exact_match_routing")

func test_prefix_match_routing():
    var enemies := [{"id": 1, "word": "raider", "dist": 5}]

    var result := SimTypingFeedback.route_night_input(false, "", "rai", enemies)
    assert(result.action == "incomplete")
    assert("prefix" in result.reason)

    _pass("test_prefix_match_routing")
```
