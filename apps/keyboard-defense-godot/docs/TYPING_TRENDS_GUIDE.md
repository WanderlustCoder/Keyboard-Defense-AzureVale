# Typing Trends Guide

This document explains the typing performance trend analysis system that tracks improvement over time and provides coaching suggestions.

## Overview

The typing trends system analyzes performance history to detect patterns:

```
Night History → Extract Metrics → Compare Deltas → Generate Suggestions
      ↓              ↓                 ↓                   ↓
  [reports]      latest/prev       +/- changes        coach tips
```

## Trend Summary

### Main Summary Function

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

    var latest_accuracy: float = _value(latest, "avg_accuracy")
    var latest_hit: float = _value(latest, "hit_rate")
    var latest_backspace: float = _value(latest, "backspace_rate")
    var latest_incomplete: float = _value(latest, "incomplete_rate")

    var prev_accuracy: float = _value(previous, "avg_accuracy")
    var prev_hit: float = _value(previous, "hit_rate")
    var prev_backspace: float = _value(previous, "backspace_rate")

    var avg_accuracy: float = _average(history, "avg_accuracy")
    var avg_hit: float = _average(history, "hit_rate")
    var avg_backspace: float = _average(history, "backspace_rate")

    var goal_met: bool = report_meets_goal(latest, thresholds)
    var suggestions: Array[String] = _build_suggestions(...)

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

### Summary Fields

| Field | Type | Description |
|-------|------|-------------|
| `count` | int | Number of history entries |
| `goal_id` | String | Active goal identifier |
| `goal_label` | String | Human-readable goal name |
| `goal_description` | String | Goal explanation text |
| `thresholds` | Dictionary | Target values for goal |
| `goal_met` | bool | Whether latest report meets goal |
| `suggestions` | Array[String] | Coach tips for improvement |
| `latest_*` | float | Most recent metrics |
| `delta_*` | float | Change from previous |
| `avg_*` | float | Historical average |

## Goal Checking

### Report Meets Goal

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

### Threshold Checks

| Metric | Check | Pass Condition |
|--------|-------|----------------|
| hit_rate | >= min_hit_rate | Higher is better |
| avg_accuracy | >= min_accuracy | Higher is better |
| backspace_rate | <= max_backspace_rate | Lower is better |
| incomplete_rate | <= max_incomplete_rate | Lower is better |

## Coach Suggestions

### Building Suggestions

```gdscript
# sim/typing_trends.gd:81
static func _build_suggestions(count: int, hit_rate: float, accuracy: float,
    backspace_rate: float, incomplete_rate: float, thresholds: Dictionary) -> Array[String]:
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

### Suggestion Messages

| Condition | Suggestion |
|-----------|------------|
| count < 2 | "Play 2+ nights to unlock trend insights." |
| hit_rate low | "Hit rate below target: build or upgrade towers..." |
| accuracy low | "Accuracy below target: slow down and focus..." |
| backspace high | "Backspace rate high: pause before typing..." |
| incomplete high | "Too many incomplete enters: finish words..." |
| all goals met | "Goal met: keep upgrading towers..." |

### Getting Suggestions

```gdscript
# sim/typing_trends.gd:48
static func coach_suggestions(summary: Dictionary) -> Array[String]:
    if summary.has("suggestions"):
        return summary.get("suggestions", [])
    return []
```

## Text Formatting

### Format Trend Text

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

**Example Output:**
```
Trend (last 5)
Accuracy: 85.2% (+3.1%)
Hit rate: 78.5% (+2.0%)
Backspace: 12.3% (-1.5%)
```

## Helper Functions

### Value Extraction

```gdscript
# sim/typing_trends.gd:97
static func _value(entry: Dictionary, key: String) -> float:
    if entry.has(key):
        return float(entry.get(key, 0.0))
    return 0.0
```

### Average Calculation

```gdscript
# sim/typing_trends.gd:102
static func _average(history: Array, key: String) -> float:
    if history.is_empty():
        return 0.0
    var sum: float = 0.0
    var count: int = 0
    for entry in history:
        if typeof(entry) != TYPE_DICTIONARY:
            continue
        sum += float(entry.get(key, 0.0))
        count += 1
    if count == 0:
        return 0.0
    return sum / float(count)
```

## Integration Examples

### End of Night Summary

```gdscript
func _on_night_complete(report: Dictionary) -> void:
    # Add to history
    profile.night_history.append(report)

    # Keep last N entries
    while profile.night_history.size() > 10:
        profile.night_history.pop_front()

    # Generate trend summary
    var summary: Dictionary = SimTypingTrends.summarize(
        profile.night_history,
        profile.current_goal
    )

    # Display results
    _show_trend_panel(summary)
```

### Trend Display Panel

```gdscript
func _show_trend_panel(summary: Dictionary) -> void:
    # Show trend text
    trend_label.text = SimTypingTrends.format_trend_text(summary)

    # Show goal status
    if summary.goal_met:
        goal_label.text = "[color=green]GOAL MET![/color]"
    else:
        goal_label.text = "[color=yellow]Keep practicing[/color]"

    # Show suggestions
    var suggestions: Array[String] = SimTypingTrends.coach_suggestions(summary)
    suggestion_label.text = "\n".join(suggestions)
```

### Profile Integration

```gdscript
func get_current_trends() -> Dictionary:
    return SimTypingTrends.summarize(
        profile.get("night_history", []),
        profile.get("current_goal", "balanced")
    )
```

## Testing

```gdscript
func test_summarize_empty():
    var summary := SimTypingTrends.summarize([], "balanced")
    assert(summary.count == 0)
    assert(summary.goal_met == false)
    assert(summary.suggestions.size() > 0)

    _pass("test_summarize_empty")

func test_summarize_with_history():
    var history := [
        {"avg_accuracy": 0.75, "hit_rate": 0.70, "backspace_rate": 0.15},
        {"avg_accuracy": 0.80, "hit_rate": 0.75, "backspace_rate": 0.12}
    ]

    var summary := SimTypingTrends.summarize(history, "balanced")

    assert(summary.count == 2)
    assert(summary.latest_accuracy == 0.80)
    assert(summary.delta_accuracy == 0.05)  # 0.80 - 0.75

    _pass("test_summarize_with_history")

func test_goal_met():
    var thresholds := {
        "min_hit_rate": 0.70,
        "min_accuracy": 0.75,
        "max_backspace_rate": 0.20,
        "max_incomplete_rate": 0.15
    }

    var good_report := {
        "hit_rate": 0.80,
        "avg_accuracy": 0.85,
        "backspace_rate": 0.10,
        "incomplete_rate": 0.05
    }

    assert(SimTypingTrends.report_meets_goal(good_report, thresholds))

    var bad_report := {
        "hit_rate": 0.60,  # Below threshold
        "avg_accuracy": 0.85,
        "backspace_rate": 0.10,
        "incomplete_rate": 0.05
    }

    assert(not SimTypingTrends.report_meets_goal(bad_report, thresholds))

    _pass("test_goal_met")
```
