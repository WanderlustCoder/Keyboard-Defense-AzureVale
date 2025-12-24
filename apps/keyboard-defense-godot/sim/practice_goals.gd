class_name PracticeGoals
extends RefCounted

const GOAL_ORDER: Array[String] = [
    "balanced",
    "accuracy",
    "backspace",
    "speed"
]

static func all_goal_ids() -> PackedStringArray:
    return PackedStringArray(GOAL_ORDER)

static func is_valid(goal_id: String) -> bool:
    return GOAL_ORDER.has(goal_id)

static func normalize_goal(goal_id: String) -> String:
    var normalized: String = goal_id.strip_edges().to_lower()
    if normalized == "" or not is_valid(normalized):
        return "balanced"
    return normalized

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
        _:
            return {
                "min_hit_rate": 0.55,
                "min_accuracy": 0.78,
                "max_backspace_rate": 0.20,
                "max_incomplete_rate": 0.30
            }
