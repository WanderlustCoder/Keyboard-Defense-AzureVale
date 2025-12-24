class_name GoalTheme
extends RefCounted

const PracticeGoals = preload("res://sim/practice_goals.gd")

const GOAL_HEX: Dictionary = {
    "balanced": "#B0B0B0",
    "accuracy": "#0072B2",
    "backspace": "#CC79A7",
    "speed": "#D55E00"
}

const PASS_HEX: String = "#009E73"
const FAIL_HEX: String = "#D55E00"

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

static func hex_for_goal(goal_id: String) -> String:
    var normalized: String = PracticeGoals.normalize_goal(goal_id)
    if GOAL_HEX.has(normalized):
        return GOAL_HEX[normalized]
    return GOAL_HEX["balanced"]

static func color_for_pass(passed: bool) -> Color:
    return Color(0.0, 0.62, 0.451, 1.0) if passed else Color(0.835, 0.369, 0.0, 1.0)

static func hex_for_pass(passed: bool) -> String:
    return PASS_HEX if passed else FAIL_HEX
