class_name OnboardingFlow
extends RefCounted

# Source of truth: docs/plans/p0/ONBOARDING_COPY.md (keep this copy in sync).
# Snapshot contract (passed from game/main.gd):
# - used_help_or_status: bool
# - did_gather: bool
# - did_build: bool
# - did_explore: bool
# - entered_night: bool
# - hit_enemy: bool
# - reached_dawn: bool
# - opened_lessons: bool
# - opened_settings: bool
# - toggled_tutorial: bool
# - phase: String (optional, current phase)
# - buildings_total: int (optional, total built count)
# - explored_count: int (optional, discovered tile count)

const STEPS: Array = [
    {
        "id": "welcome_focus",
        "title": "Welcome to Keyboard Defense",
        "body_lines": [
            "This game is typing-first. Keep your hands on the keyboard.",
            "The command bar stays focused so you can act instantly.",
            "We will use short commands to learn the day and night loop."
        ],
        "try_line": "Try this: help",
        "success_line": "Success: The log shows the help output."
    },
    {
        "id": "day_actions",
        "title": "Daytime actions",
        "body_lines": [
            "Daytime is for gathering, building, and exploring.",
            "Actions cost AP, so pick a small plan each day.",
            "Watch the log to confirm each command result."
        ],
        "try_line": "Try this: gather wood 5, build farm, explore",
        "success_line": "Success: Resources change and a tile is discovered."
    },
    {
        "id": "end_day",
        "title": "End the day",
        "body_lines": [
            "Ending the day starts the night wave.",
            "Production happens immediately when you end the day.",
            "A defend prompt will appear at night."
        ],
        "try_line": "Try this: end",
        "success_line": "Success: Phase changes to night and a prompt appears."
    },
    {
        "id": "night_typing",
        "title": "Defend by typing",
        "body_lines": [
            "Each enemy has a word. Type the word to attack that enemy.",
            "Prefixes are safe; Enter only submits on a full match.",
            "Commands like status still work at night."
        ],
        "try_line": "Try this: Type an enemy word from the wave list, then press Enter.",
        "success_line": "Success: The targeted enemy loses HP and the wave list updates."
    },
    {
        "id": "reach_dawn",
        "title": "Reach dawn",
        "body_lines": [
            "Keep typing enemy words until the wave is cleared.",
            "If you need a pause, use wait to advance without a penalty.",
            "Dawn returns you to the day phase."
        ],
        "try_line": "Try this: Defeat enemies until Dawn (or use wait if needed).",
        "success_line": "Success: Dawn is announced and the typing report appears."
    },
    {
        "id": "wrap_up",
        "title": "Panels and replay",
        "body_lines": [
            "Lessons and settings are available any time.",
            "The tutorial can be replayed if you want a refresher.",
            "You can switch goals and lessons as you improve."
        ],
        "try_line": "Try this: lessons, settings, tutorial",
        "success_line": "Success: Panels open and the tutorial controls are shown."
    }
]

static func steps() -> Array:
    return STEPS

static func step_count() -> int:
    return STEPS.size()

static func clamp_step(step: int) -> int:
    return clamp(step, 0, step_count())

static func format_step(step: int) -> String:
    var total: int = step_count()
    var lines: Array[String] = []
    lines.append("[b]Tutorial[/b]")
    if total == 0:
        lines.append("No tutorial steps configured.")
        return "\n".join(lines)
    var clamped: int = clamp_step(step)
    if clamped >= total:
        lines.append("Status: COMPLETE")
        lines.append("Use 'tutorial restart' to replay.")
        lines.append("Commands: tutorial | tutorial restart | tutorial skip")
        return "\n".join(lines)
    var entry: Dictionary = STEPS[clamped]
    lines.append("Step %d/%d" % [clamped + 1, total])
    lines.append("[b]%s[/b]" % str(entry.get("title", "Step")))
    var body_lines: Array = entry.get("body_lines", [])
    for line in body_lines:
        lines.append(str(line))
    var try_line: String = str(entry.get("try_line", ""))
    if try_line != "":
        lines.append(try_line)
    var success_line: String = str(entry.get("success_line", ""))
    if success_line != "":
        lines.append(success_line)
    lines.append("Commands: tutorial | tutorial restart | tutorial skip")
    return "\n".join(lines)

static func is_step_complete(step: int, snapshot: Dictionary) -> bool:
    var phase: String = str(snapshot.get("phase", ""))
    match step:
        0:
            return bool(snapshot.get("used_help_or_status", false))
        1:
            var built: bool = bool(snapshot.get("did_build", false))
            var explored: bool = bool(snapshot.get("did_explore", false))
            var gathered: bool = bool(snapshot.get("did_gather", false))
            if not built:
                built = int(snapshot.get("buildings_total", 0)) > 0
            if not explored:
                explored = int(snapshot.get("explored_count", 0)) > 1
            return built and explored and gathered
        2:
            return bool(snapshot.get("entered_night", false)) or phase == "night"
        3:
            return bool(snapshot.get("hit_enemy", false))
        4:
            return bool(snapshot.get("reached_dawn", false)) or phase == "day"
        5:
            return bool(snapshot.get("opened_lessons", false)) \
                and bool(snapshot.get("opened_settings", false)) \
                and bool(snapshot.get("toggled_tutorial", false))
    return false

static func advance(step: int, snapshot: Dictionary) -> int:
    var clamped: int = clamp_step(step)
    var total: int = step_count()
    if clamped >= total:
        return total
    if is_step_complete(clamped, snapshot):
        return clamped + 1
    return clamped
