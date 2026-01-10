# Typing Statistics Guide

This document explains the typing statistics tracking system that monitors player performance during night combat phases.

## Overview

The typing statistics system tracks real-time metrics during combat:

```
Night Start → Track Inputs → Record Attempts → Generate Report
     ↓             ↓               ↓                  ↓
  reset()    on_text_changed()  record_*()     to_report_dict()
```

## Tracked Metrics

### Core Counters

```gdscript
# sim/typing_stats.gd
var night_day: int = 0          # Which day this night is for
var wave_total: int = 0         # Total enemies in wave
var night_steps: int = 0        # Actions taken (defend + advancing commands)
var enter_presses: int = 0      # Total enter key presses
var incomplete_enters: int = 0  # Enters with partial/invalid input
var command_enters: int = 0     # Enters that executed commands
var defend_attempts: int = 0    # Word typing attempts
var wait_steps: int = 0         # "wait" command uses
var hits: int = 0               # Successful word matches
var misses: int = 0             # Failed word attempts
```

### Input Tracking

```gdscript
var typed_chars: int = 0        # Characters typed
var deleted_chars: int = 0      # Characters deleted (backspace)
var sum_accuracy: float = 0.0   # Cumulative accuracy score
var accuracy_attempts: int = 0  # Attempts counted for accuracy
var sum_edit_distance: int = 0  # Cumulative edit distance
var edit_distance_attempts: int = 0
```

### Combo System

```gdscript
var current_combo: int = 0      # Current streak of hits
var max_combo: int = 0          # Best streak this night
var combo_thresholds: Array[int] = [3, 5, 10, 20, 50]
```

### Timing

```gdscript
var start_msec: int = -1        # Night start timestamp
```

## Initialization

### Starting a Night

```gdscript
# sim/typing_stats.gd:27
func start_night(day: int, wave_total_value: int, now_msec: int = -1) -> void:
    night_day = day
    wave_total = wave_total_value
    night_steps = 0
    enter_presses = 0
    incomplete_enters = 0
    command_enters = 0
    defend_attempts = 0
    wait_steps = 0
    hits = 0
    misses = 0
    typed_chars = 0
    deleted_chars = 0
    sum_accuracy = 0.0
    accuracy_attempts = 0
    sum_edit_distance = 0
    edit_distance_attempts = 0
    start_msec = now_msec
    current_combo = 0
    max_combo = 0
```

## Event Recording

### Text Changes

```gdscript
# sim/typing_stats.gd:48
func on_text_changed(prev_text: String, new_text: String) -> void:
    var prev_len: int = prev_text.length()
    var new_len: int = new_text.length()
    if new_len > prev_len:
        typed_chars += new_len - prev_len
    elif new_len < prev_len:
        deleted_chars += prev_len - new_len
```

Tracks character additions and deletions separately.

### Enter Presses

```gdscript
# sim/typing_stats.gd:56
func on_enter_pressed() -> void:
    enter_presses += 1

func record_incomplete_enter(reason: String) -> void:
    incomplete_enters += 1

func record_command_enter(kind: String, advances_step: bool) -> void:
    command_enters += 1
    if advances_step:
        night_steps += 1
    if kind == "wait":
        wait_steps += 1
```

### Defend Attempts

```gdscript
# sim/typing_stats.gd:69
func record_defend_attempt(typed_raw: String, enemies: Array) -> void:
    defend_attempts += 1
    night_steps += 1
    var typed: String = SimTypingFeedback.normalize_input(typed_raw)

    # Check for exact match
    var hit: bool = false
    for enemy in enemies:
        var word: String = SimTypingFeedback.normalize_input(str(enemy.get("word", "")))
        if word != "" and typed == word:
            hit = true
            break

    # Update combo
    if hit:
        hits += 1
        current_combo += 1
        if current_combo > max_combo:
            max_combo = current_combo
    else:
        misses += 1
        current_combo = 0

    # Calculate accuracy via edit distance
    # ... finds closest enemy word and computes accuracy
```

### Accuracy Calculation

For each defend attempt, accuracy is calculated as:

```gdscript
var acc: float = 1.0 - float(edit_distance) / float(max_len)
```

Where:
- `edit_distance` = Levenshtein distance to closest enemy word
- `max_len` = max(word_length, typed_length)

## Report Generation

### Dictionary Report

```gdscript
# sim/typing_stats.gd:119
func to_report_dict() -> Dictionary:
    var attempt_div: float = float(max(defend_attempts, 1))
    var backspace_div: float = float(max(typed_chars + deleted_chars, 1))
    var accuracy_div: float = float(max(accuracy_attempts, 1))

    return {
        "night_day": night_day,
        "wave_total": wave_total,
        "night_steps": night_steps,
        "enter_presses": enter_presses,
        "incomplete_enters": incomplete_enters,
        "command_enters": command_enters,
        "defend_attempts": defend_attempts,
        "wait_steps": wait_steps,
        "hits": hits,
        "misses": misses,
        "typed_chars": typed_chars,
        "deleted_chars": deleted_chars,
        "current_combo": current_combo,
        "max_combo": max_combo,
        "hit_rate": float(hits) / attempt_div,
        "backspace_rate": float(deleted_chars) / backspace_div,
        "incomplete_rate": float(incomplete_enters) / float(max(enter_presses, 1)),
        "avg_accuracy": sum_accuracy / accuracy_div,
        "avg_edit_distance": float(sum_edit_distance) / float(max(edit_distance_attempts, 1))
    }
```

### Derived Metrics

| Metric | Formula | Description |
|--------|---------|-------------|
| `hit_rate` | hits / defend_attempts | Percentage of successful word matches |
| `backspace_rate` | deleted_chars / total_chars | Correction frequency |
| `incomplete_rate` | incomplete_enters / enter_presses | Premature submission rate |
| `avg_accuracy` | sum_accuracy / accuracy_attempts | Average per-attempt accuracy |
| `avg_edit_distance` | sum_edit_distance / edit_distance_attempts | Average typing errors |

## Combo System

### Tier Calculation

```gdscript
# sim/typing_stats.gd:152
func get_combo_tier() -> int:
    var tier: int = 0
    for threshold in combo_thresholds:
        if current_combo >= threshold:
            tier += 1
        else:
            break
    return tier
```

| Combo | Tier | Visual |
|-------|------|--------|
| 0-2 | 0 | (hidden) |
| 3-4 | 1 | x3 |
| 5-9 | 2 | x5 |
| 10-19 | 3 | x10 |
| 20-49 | 4 | x20 |
| 50+ | 5 | x50 |

### Display Text

```gdscript
# sim/typing_stats.gd:162
func get_combo_display() -> String:
    if current_combo < 2:
        return ""
    var tier: int = get_combo_tier()
    var flame: String = ""
    for i in range(tier):
        flame += "..."  # Fire emoji per tier
    if flame == "":
        return "x%d" % current_combo
    return "%s x%d" % [flame, current_combo]
```

### Threshold Detection

```gdscript
# sim/typing_stats.gd:174
func did_reach_threshold(prev_combo: int) -> bool:
    for threshold in combo_thresholds:
        if current_combo >= threshold and prev_combo < threshold:
            return true
    return false
```

Used to trigger audio/visual feedback when crossing combo milestones.

## Text Report

```gdscript
# sim/typing_stats.gd:180
func to_report_text() -> String:
    var report: Dictionary = to_report_dict()
    var lines: Array[String] = []
    lines.append("Typing Report (Day %d)" % report.night_day)
    lines.append("Wave total: %d" % report.wave_total)
    lines.append("Steps: %d | Enters: %d | Incomplete: %d | Commands: %d | Waits: %d" % [...])
    lines.append("Defend: %d attempts | Hits %d | Misses %d | Hit rate %.1f%%" % [...])
    lines.append("Input: typed %d | backspace %d (%.1f%%)" % [...])
    lines.append("Incomplete enter rate: %.1f%%" % [...])
    lines.append("Accuracy: avg %.1f%% | avg edit distance %.2f" % [...])
    if report.max_combo > 0:
        lines.append("Combo: max %d" % report.max_combo)
    return "\n".join(lines)
```

Example output:
```
Typing Report (Day 3)
Wave total: 8
Steps: 12 | Enters: 15 | Incomplete: 2 | Commands: 1 | Waits: 0
Defend: 11 attempts | Hits 8 | Misses 3 | Hit rate 72.7%
Input: typed 45 | backspace 5 (10.0%)
Incomplete enter rate: 13.3%
Accuracy: avg 85.2% | avg edit distance 0.45
Combo: max 5
```

## Integration Examples

### Night Combat Controller

```gdscript
var typing_stats := SimTypingStats.new()

func _start_night(state: GameState) -> void:
    typing_stats.start_night(state.day, state.night_wave_total, Time.get_ticks_msec())

func _on_input_changed(old_text: String, new_text: String) -> void:
    typing_stats.on_text_changed(old_text, new_text)

func _on_submit(text: String) -> void:
    typing_stats.on_enter_pressed()

    var routing := SimTypingFeedback.route_night_input(...)
    match routing.action:
        "command":
            typing_stats.record_command_enter(intent.kind, advances_step)
        "defend":
            typing_stats.record_defend_attempt(text, state.enemies)
        "incomplete":
            typing_stats.record_incomplete_enter(routing.reason)

func _end_night() -> void:
    var report := typing_stats.to_report_dict()
    _show_results_screen(report)
    _update_player_profile(report)
```

### Combo Feedback

```gdscript
func _on_hit() -> void:
    var prev_combo: int = typing_stats.current_combo - 1  # Already incremented
    if typing_stats.did_reach_threshold(prev_combo):
        _play_combo_sound(typing_stats.get_combo_tier())
        _show_combo_popup(typing_stats.get_combo_display())
```

### Profile Integration

```gdscript
func _save_stats_to_profile(profile: Dictionary, stats: SimTypingStats) -> void:
    var report := stats.to_report_dict()
    TypingProfile.update_best_stat(profile, "best_combo", report.max_combo)
    TypingProfile.update_best_stat(profile, "best_hit_rate", report.hit_rate)
    TypingProfile.record_night_history(profile, report)
```

## Testing

```gdscript
func test_basic_tracking():
    var stats := SimTypingStats.new()
    stats.start_night(1, 5, 0)

    stats.on_text_changed("", "rai")
    stats.on_text_changed("rai", "raid")
    assert(stats.typed_chars == 4)

    stats.on_text_changed("raid", "rai")
    assert(stats.deleted_chars == 1)

    _pass("test_basic_tracking")

func test_hit_miss_tracking():
    var stats := SimTypingStats.new()
    stats.start_night(1, 3, 0)

    var enemies := [{"id": 1, "word": "raider"}]

    stats.record_defend_attempt("raider", enemies)
    assert(stats.hits == 1)
    assert(stats.current_combo == 1)

    stats.record_defend_attempt("wrong", enemies)
    assert(stats.misses == 1)
    assert(stats.current_combo == 0)

    _pass("test_hit_miss_tracking")

func test_combo_thresholds():
    var stats := SimTypingStats.new()
    stats.current_combo = 4
    assert(stats.get_combo_tier() == 1)  # >= 3

    stats.current_combo = 10
    assert(stats.get_combo_tier() == 3)  # >= 3, 5, 10

    assert(stats.did_reach_threshold(9))   # 9 -> 10 crosses threshold
    assert(not stats.did_reach_threshold(10))  # 10 -> 10 doesn't

    _pass("test_combo_thresholds")
```
