class_name LessonHealth
extends RefCounted

const MiniTrend = preload("res://game/mini_trend.gd")

static func score_recent(recent: Array, eps: float = 0.01) -> int:
    if not (recent is Array) or recent.size() < 2:
        return 0
    var newest = recent[0]
    var oldest = recent[recent.size() - 1]
    if typeof(newest) != TYPE_DICTIONARY or typeof(oldest) != TYPE_DICTIONARY:
        return 0
    var score: int = 0
    var acc_d: float = float(newest.get("avg_accuracy", 0.0)) - float(oldest.get("avg_accuracy", 0.0))
    var hit_d: float = float(newest.get("hit_rate", 0.0)) - float(oldest.get("hit_rate", 0.0))
    var back_d: float = float(newest.get("backspace_rate", 0.0)) - float(oldest.get("backspace_rate", 0.0))
    if acc_d > eps:
        score += 1
    if hit_d > eps:
        score += 1
    if back_d < -eps:
        score += 1
    return score

static func label_for_score(score: int, has_delta: bool) -> String:
    if not has_delta:
        return "--"
    if score >= 2:
        return "GOOD"
    if score == 1:
        return "OK"
    return "WARN"

static func legend_line() -> String:
    return "Health: GOOD=improving, OK=mixed, WARN=slipping"

static func build_hud_text(lesson_name: String, lesson_id: String, recent: Array, sparkline_enabled: bool) -> String:
    var name_text: String = lesson_name if lesson_name != "" else lesson_id
    var has_delta: bool = recent is Array and recent.size() >= 2
    if not has_delta:
        return "Lesson: %s (%s) | Health: --" % [name_text, lesson_id]
    var trend: Dictionary = MiniTrend.format_last3_delta(recent)
    if not bool(trend.get("has_delta", false)):
        return "Lesson: %s (%s) | Health: --" % [name_text, lesson_id]
    var score: int = score_recent(recent)
    var label: String = label_for_score(score, true)
    var acc_arrow: String = str(trend.get("acc_arrow", ""))
    var hit_arrow: String = str(trend.get("hit_arrow", ""))
    var back_arrow: String = str(trend.get("back_arrow", ""))
    var line: String = "Lesson: %s | Health: %s | acc %s hit %s back %s" % [
        name_text,
        label,
        acc_arrow,
        hit_arrow,
        back_arrow
    ]
    if sparkline_enabled and recent.size() > 0:
        var width: int = min(3, recent.size())
        var spark: String = MiniTrend.sparkline_from_recent(recent, "avg_accuracy", width)
        line = "%s | acc %s" % [line, spark]
    return line
