# Practice Goals & Typing Trends Guide

This document explains the practice goals system for personalized typing improvement and the typing trends analysis in Keyboard Defense.

## Overview

Practice goals customize the gameplay feedback and coaching:

```
Goal Selection → Threshold Calculation → Trend Analysis → Coach Suggestions
      ↓                  ↓                    ↓                  ↓
   balanced         accuracy ≥ 78%       compare waves      "slow down"
   accuracy         hit rate ≥ 55%       deltas shown       "clean input"
   backspace        backspace ≤ 20%      averages           "goal met"
   speed            incomplete ≤ 30%     history
```

## Practice Goals

### Available Goals

```gdscript
# sim/practice_goals.gd:4
const GOAL_ORDER: Array[String] = [
    "balanced",
    "accuracy",
    "backspace",
    "speed"
]
```

| Goal ID | Label | Description |
|---------|-------|-------------|
| `balanced` | Balanced | Keep a steady balance of accuracy and pace |
| `accuracy` | Accuracy | Prioritize correct words over speed |
| `backspace` | Clean Keystrokes | Reduce corrections and commit to clean input |
| `speed` | Speed | Maintain a fast pace with steady hits |

### Goal Labels and Descriptions

```gdscript
# sim/practice_goals.gd:23
static func goal_label(goal_id: String) -> String:
    match normalize_goal(goal_id):
        "accuracy":
            return "Accuracy"
        "backspace":
            return "Clean Keystrokes"
        "speed":
            return "Speed"
        _:
            return "Balanced"

static func goal_description(goal_id: String) -> String:
    match normalize_goal(goal_id):
        "accuracy":
            return "Prioritize correct words over speed."
        "backspace":
            return "Reduce corrections and commit to clean input."
        "speed":
            return "Maintain a fast pace with steady hits."
        _:
            return "Keep a steady balance of accuracy and pace."
```

### Goal Thresholds

Each goal has specific performance thresholds:

```gdscript
# sim/practice_goals.gd:45
static func thresholds(goal_id: String) -> Dictionary:
    match normalize_goal(goal_id):
        "accuracy":
            return {
                "min_hit_rate": 0.45,
                "min_accuracy": 0.85,
                "max_backspace_rate": 0.25,
                "max_incomplete_rate": 0.35
            }
        "backspace":
            return {
                "min_hit_rate": 0.50,
                "min_accuracy": 0.75,
                "max_backspace_rate": 0.12,
                "max_incomplete_rate": 0.30
            }
        "speed":
            return {
                "min_hit_rate": 0.70,
                "min_accuracy": 0.75,
                "max_backspace_rate": 0.25,
                "max_incomplete_rate": 0.25
            }
        _:  # balanced
            return {
                "min_hit_rate": 0.55,
                "min_accuracy": 0.78,
                "max_backspace_rate": 0.20,
                "max_incomplete_rate": 0.30
            }
```

### Threshold Summary Table

| Goal | Min Hit Rate | Min Accuracy | Max Backspace | Max Incomplete |
|------|-------------|--------------|---------------|----------------|
| Balanced | 55% | 78% | 20% | 30% |
| Accuracy | 45% | 85% | 25% | 35% |
| Backspace | 50% | 75% | 12% | 30% |
| Speed | 70% | 75% | 25% | 25% |

### Goal Normalization

```gdscript
# sim/practice_goals.gd:17
static func normalize_goal(goal_id: String) -> String:
    var normalized: String = goal_id.strip_edges().to_lower()
    if normalized == "" or not is_valid(normalized):
        return "balanced"
    return normalized

static func is_valid(goal_id: String) -> bool:
    return GOAL_ORDER.has(goal_id)
```

## Goal Theme Colors

Goals have associated colors for UI consistency:

```gdscript
# game/goal_theme.gd
const GOAL_HEX: Dictionary = {
    "balanced": "#B0B0B0",   # Gray
    "accuracy": "#0072B2",   # Blue
    "backspace": "#CC79A7",  # Pink
    "speed": "#D55E00"       # Orange
}

const PASS_HEX: String = "#009E73"  # Green
const FAIL_HEX: String = "#D55E00"  # Orange

static func color_for_goal(goal_id: String) -> Color:
    match PracticeGoals.normalize_goal(goal_id):
        "accuracy":
            return Color(0.0, 0.447, 0.698, 1.0)
        "backspace":
            return Color(0.8, 0.475, 0.655, 1.0)
        "speed":
            return Color(0.835, 0.369, 0.0, 1.0)
        _:
            return Color(0.69, 0.69, 0.69, 1.0)

static func color_for_pass(passed: bool) -> Color:
    return Color(0.0, 0.62, 0.451, 1.0) if passed else Color(0.835, 0.369, 0.0, 1.0)
```

## Typing Trends

### Report Structure

A typing report from a wave contains:

```gdscript
# Expected report dictionary:
{
    "avg_accuracy": float,      # 0.0-1.0, correct keystrokes / total
    "hit_rate": float,          # 0.0-1.0, enemies hit / total enemies
    "backspace_rate": float,    # 0.0-1.0, corrections / total keystrokes
    "incomplete_rate": float    # 0.0-1.0, partial submits / total submits
}
```

### Trend Summary

```gdscript
# sim/typing_trends.gd:6
static func summarize(history: Array, goal_id: String = "balanced") -> Dictionary:
    var normalized_goal: String = PracticeGoals.normalize_goal(goal_id)
    var thresholds: Dictionary = PracticeGoals.thresholds(normalized_goal)
    var count: int = history.size()

    var latest: Dictionary = {}
    var previous: Dictionary = {}
    if count > 0 and typeof(history[count - 1]) == TYPE_DICTIONARY:
        latest = history[count - 1]
    if count > 1 and typeof(history[count - 2]) == TYPE_DICTIONARY:
        previous = history[count - 2]

    // Extract values and calculate deltas
    // ...

    return {
        "count": count,
        "goal_id": normalized_goal,
        "goal_label": PracticeGoals.goal_label(normalized_goal),
        "goal_description": PracticeGoals.goal_description(normalized_goal),
        "thresholds": thresholds,
        "goal_met": goal_met,
        "suggestions": suggestions,
        "latest_accuracy": latest_accuracy,
        "latest_hit_rate": latest_hit,
        "latest_backspace_rate": latest_backspace,
        "latest_incomplete_rate": latest_incomplete,
        "delta_accuracy": latest_accuracy - prev_accuracy,
        "delta_hit_rate": latest_hit - prev_hit,
        "delta_backspace_rate": latest_backspace - prev_backspace,
        "avg_accuracy": avg_accuracy,
        "avg_hit_rate": avg_hit,
        "avg_backspace_rate": avg_backspace
    }
```

### Goal Evaluation

```gdscript
# sim/typing_trends.gd:68
static func report_meets_goal(report: Dictionary, thresholds: Dictionary) -> bool:
    if report.is_empty():
        return false
    if _value(report, "hit_rate") < float(thresholds.get("min_hit_rate", 0.0)):
        return false
    if _value(report, "avg_accuracy") < float(thresholds.get("min_accuracy", 0.0)):
        return false
    if _value(report, "backspace_rate") > float(thresholds.get("max_backspace_rate", 1.0)):
        return false
    if _value(report, "incomplete_rate") > float(thresholds.get("max_incomplete_rate", 1.0)):
        return false
    return true
```

### Coach Suggestions

```gdscript
# sim/typing_trends.gd:81
static func _build_suggestions(count: int, hit_rate: float, accuracy: float, backspace_rate: float, incomplete_rate: float, thresholds: Dictionary) -> Array[String]:
    var suggestions: Array[String] = []

    if count < 2:
        suggestions.append("Play 2+ nights to unlock trend insights.")

    if hit_rate < float(thresholds.get("min_hit_rate", 0.0)):
        suggestions.append("Hit rate below target: build or upgrade towers and reduce exploration.")

    if accuracy < float(thresholds.get("min_accuracy", 0.0)):
        suggestions.append("Accuracy below target: slow down and focus on clean words.")

    if backspace_rate > float(thresholds.get("max_backspace_rate", 1.0)):
        suggestions.append("Backspace rate high: pause before typing and aim for clean first hits.")

    if incomplete_rate > float(thresholds.get("max_incomplete_rate", 1.0)):
        suggestions.append("Too many incomplete enters: finish words before pressing Enter.")

    if suggestions.is_empty():
        suggestions.append("Goal met: keep upgrading towers and expanding safely.")

    return suggestions
```

### Formatting Trend Text

```gdscript
# sim/typing_trends.gd:53
static func format_trend_text(summary: Dictionary) -> String:
    var count: int = int(summary.get("count", 0))
    var accuracy: float = float(summary.get("latest_accuracy", 0.0)) * 100.0
    var hit_rate: float = float(summary.get("latest_hit_rate", 0.0)) * 100.0
    var backspace: float = float(summary.get("latest_backspace_rate", 0.0)) * 100.0
    var delta_accuracy: float = float(summary.get("delta_accuracy", 0.0)) * 100.0
    var delta_hit: float = float(summary.get("delta_hit_rate", 0.0)) * 100.0
    var delta_backspace: float = float(summary.get("delta_backspace_rate", 0.0)) * 100.0

    var lines: Array[String] = []
    lines.append("Trend (last %d)" % count)
    lines.append("Accuracy: %.1f%% (%+.1f%%)" % [accuracy, delta_accuracy])
    lines.append("Hit rate: %.1f%% (%+.1f%%)" % [hit_rate, delta_hit])
    lines.append("Backspace: %.1f%% (%+.1f%%)" % [backspace, delta_backspace])

    return "\n".join(lines)
```

Example output:
```
Trend (last 5)
Accuracy: 82.3% (+2.1%)
Hit rate: 68.5% (+5.2%)
Backspace: 15.2% (-3.1%)
```

## Integration Examples

### Wave End Report

```gdscript
func _on_wave_complete(wave_report: Dictionary) -> void:
    # Add to history
    typing_history.append(wave_report)

    # Keep history bounded
    if typing_history.size() > 10:
        typing_history.pop_front()

    # Generate summary
    var profile := TypingProfile.load_or_create()
    var goal_id: String = profile.get("practice_goal", "balanced")
    var summary := SimTypingTrends.summarize(typing_history, goal_id)

    # Display results
    _show_wave_summary(summary)
```

### Wave Summary Display

```gdscript
func _show_wave_summary(summary: Dictionary) -> void:
    # Show goal status
    var goal_color: Color
    if summary.goal_met:
        goal_color = GoalTheme.color_for_pass(true)
        goal_label.text = "Goal Met!"
    else:
        goal_color = GoalTheme.color_for_pass(false)
        goal_label.text = "Keep practicing"

    goal_label.modulate = goal_color

    # Show stats
    accuracy_label.text = "%.1f%%" % (summary.latest_accuracy * 100)
    hit_label.text = "%.1f%%" % (summary.latest_hit_rate * 100)
    backspace_label.text = "%.1f%%" % (summary.latest_backspace_rate * 100)

    # Show trend deltas
    accuracy_delta.text = "%+.1f%%" % (summary.delta_accuracy * 100)
    accuracy_delta.modulate = _delta_color(summary.delta_accuracy)

    # Show suggestions
    var suggestions := SimTypingTrends.coach_suggestions(summary)
    suggestions_label.text = "\n".join(suggestions)
```

### Goal Selection UI

```gdscript
func _setup_goal_selector() -> void:
    var goals := PracticeGoals.all_goal_ids()
    for goal_id in goals:
        var button := Button.new()
        button.text = PracticeGoals.goal_label(goal_id)
        button.tooltip_text = PracticeGoals.goal_description(goal_id)
        button.modulate = GoalTheme.color_for_goal(goal_id)
        button.pressed.connect(_on_goal_selected.bind(goal_id))
        goal_container.add_child(button)

func _on_goal_selected(goal_id: String) -> void:
    var profile := TypingProfile.load_or_create()
    profile["practice_goal"] = goal_id
    TypingProfile.save(profile)
    _update_goal_display(goal_id)
```

### Threshold Display

```gdscript
func _show_goal_thresholds(goal_id: String) -> void:
    var thresholds := PracticeGoals.thresholds(goal_id)

    threshold_labels["hit_rate"].text = "Hit Rate: ≥ %.0f%%" % (thresholds.min_hit_rate * 100)
    threshold_labels["accuracy"].text = "Accuracy: ≥ %.0f%%" % (thresholds.min_accuracy * 100)
    threshold_labels["backspace"].text = "Backspace: ≤ %.0f%%" % (thresholds.max_backspace_rate * 100)
    threshold_labels["incomplete"].text = "Incomplete: ≤ %.0f%%" % (thresholds.max_incomplete_rate * 100)
```

## Profile Integration

### Saving Goal

```gdscript
# In typing_profile.gd
func set_practice_goal(goal_id: String) -> void:
    var profile := load_or_create()
    profile["practice_goal"] = PracticeGoals.normalize_goal(goal_id)
    save(profile)

func get_practice_goal() -> String:
    var profile := load_or_create()
    return str(profile.get("practice_goal", "balanced"))
```

### Saving History

```gdscript
func add_wave_report(report: Dictionary) -> void:
    var profile := load_or_create()
    var history: Array = profile.get("typing_history", [])
    history.append(report)

    # Keep last 20 reports
    while history.size() > 20:
        history.pop_front()

    profile["typing_history"] = history
    save(profile)
```

## Testing

```gdscript
func test_goal_thresholds():
    var balanced := PracticeGoals.thresholds("balanced")
    assert(balanced.min_hit_rate == 0.55)
    assert(balanced.min_accuracy == 0.78)

    var accuracy := PracticeGoals.thresholds("accuracy")
    assert(accuracy.min_accuracy == 0.85)  # Higher for accuracy goal

    _pass("test_goal_thresholds")

func test_goal_normalization():
    assert(PracticeGoals.normalize_goal("ACCURACY") == "accuracy")
    assert(PracticeGoals.normalize_goal("  speed  ") == "speed")
    assert(PracticeGoals.normalize_goal("invalid") == "balanced")
    assert(PracticeGoals.normalize_goal("") == "balanced")

    _pass("test_goal_normalization")

func test_report_meets_goal():
    var report := {
        "avg_accuracy": 0.80,
        "hit_rate": 0.60,
        "backspace_rate": 0.15,
        "incomplete_rate": 0.25
    }

    var balanced_thresholds := PracticeGoals.thresholds("balanced")
    assert(SimTypingTrends.report_meets_goal(report, balanced_thresholds))

    var speed_thresholds := PracticeGoals.thresholds("speed")
    assert(not SimTypingTrends.report_meets_goal(report, speed_thresholds))  # Hit rate too low

    _pass("test_report_meets_goal")

func test_trend_summary():
    var history := [
        {"avg_accuracy": 0.75, "hit_rate": 0.50, "backspace_rate": 0.20, "incomplete_rate": 0.30},
        {"avg_accuracy": 0.80, "hit_rate": 0.55, "backspace_rate": 0.18, "incomplete_rate": 0.25}
    ]

    var summary := SimTypingTrends.summarize(history, "balanced")
    assert(summary.count == 2)
    assert(summary.delta_accuracy > 0)  # Improved
    assert(summary.delta_backspace_rate < 0)  # Improved (less backspaces)

    _pass("test_trend_summary")

func test_coach_suggestions():
    var history := [
        {"avg_accuracy": 0.60, "hit_rate": 0.40, "backspace_rate": 0.30, "incomplete_rate": 0.40}
    ]

    var summary := SimTypingTrends.summarize(history, "balanced")
    var suggestions := summary.suggestions

    assert(suggestions.size() > 0)
    assert("Accuracy below target" in suggestions[0] or "Hit rate below target" in suggestions[0])

    _pass("test_coach_suggestions")
```

## Metric Definitions

| Metric | Calculation | Good Range |
|--------|-------------|------------|
| **Hit Rate** | Enemies hit / Total enemies | 55-70%+ |
| **Accuracy** | Correct keystrokes / Total keystrokes | 75-85%+ |
| **Backspace Rate** | Corrections / Total keystrokes | 12-20% |
| **Incomplete Rate** | Partial submits / Total submits | 25-35% |

## Goal Selection Guidelines

| Player Type | Recommended Goal | Reason |
|-------------|------------------|--------|
| New player | Balanced | General improvement |
| Makes many typos | Accuracy | Focus on precision |
| Over-corrects | Backspace | Build confidence |
| Types slowly | Speed | Build momentum |
| Skilled typist | Speed | Maximize challenge |
