class_name SimTypingTrends
extends RefCounted

const PracticeGoals = preload("res://sim/practice_goals.gd")

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
    var suggestions: Array[String] = _build_suggestions(count, latest_hit, latest_accuracy, latest_backspace, latest_incomplete, thresholds)
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

static func coach_suggestions(summary: Dictionary) -> Array[String]:
    if summary.has("suggestions"):
        return summary.get("suggestions", [])
    return []

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

static func _value(entry: Dictionary, key: String) -> float:
    if entry.has(key):
        return float(entry.get(key, 0.0))
    return 0.0

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
