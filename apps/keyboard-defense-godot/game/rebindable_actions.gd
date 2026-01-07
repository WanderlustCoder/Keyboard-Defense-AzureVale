extends RefCounted
class_name RebindableActions

# Add future InputMap actions here.
static func actions() -> PackedStringArray:
    return PackedStringArray([
        "toggle_settings",
        "toggle_lessons",
        "toggle_trend",
        "toggle_compact",
        "toggle_history",
        "toggle_report",
        "cycle_goal"
    ])

static func display_name(action: String) -> String:
    match action:
        "cycle_goal":
            return "Cycle Goal"
        "toggle_settings":
            return "Toggle Settings Panel"
        "toggle_lessons":
            return "Toggle Lessons Panel"
        "toggle_trend":
            return "Toggle Trend Panel"
        "toggle_compact":
            return "Toggle Compact Panels"
        "toggle_history":
            return "Toggle History Panel"
        "toggle_report":
            return "Toggle Report Panel"
        _:
            return action

static func help_line(action: String) -> String:
    return "%s (%s)" % [display_name(action), action]

static func format_actions_hint() -> String:
    var parts: Array[String] = []
    for action_name in actions():
        parts.append(help_line(action_name))
    return "Actions: %s" % ", ".join(parts)
