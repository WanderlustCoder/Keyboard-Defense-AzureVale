class_name SimIntents
extends RefCounted

const CommandKeywords = preload("res://sim/command_keywords.gd")
static var COMMANDS: Array[String] = CommandKeywords.keywords()

static func make(kind: String, data: Dictionary = {}) -> Dictionary:
    var intent := {"kind": kind}
    for key in data.keys():
        intent[key] = data[key]
    return intent

static func help_lines() -> Array[String]:
    return [
        "Commands:",
        "  help - list commands",
        "  status - show phase and resources",
        "  gather <resource> <amount> - add resources (day only)",
        "  build <type> [x y] - place a building (day only)",
        "  build types: farm, lumber, quarry, wall, tower",
        "  explore - reveal a tile and gain loot (day only)",
        "  cursor <x> <y> - move cursor",
        "  cursor <dir> [n] - move cursor up/down/left/right",
        "  inspect [x y] - inspect tile at cursor or coords",
        "  map - print ASCII map",
        "  demolish [x y] - remove a structure (day only)",
        "  preview <type|none> - toggle build preview",
        "  wait - advance a night step without a miss penalty (night only)",
        "  overlay path <on|off> - toggle path overlay",
        "  upgrade [x y] - upgrade a tower (day only)",
        "  enemies - list active enemies",
        "  report - toggle typing report panel",
        "  settings - toggle settings panel",
        "  bind cycle_goal - set the cycle goal hotkey",
        "  bind cycle_goal reset - restore default hotkey",
        "  history - toggle typing history panel",
        "  history clear - clear typing history",
        "  trend - toggle typing trend panel",
        "  goal - show practice goal and options",
        "  goal <balanced|accuracy|backspace|speed> - set practice goal",
        "  goal next - cycle practice goals",
        "  Hotkey: F2 cycles goals",
        "  end - finish day and begin night",
        "  seed <string> - set RNG seed",
        "  defend <text> - debug alias for night input",
        "  restart - restart after game over",
        "  save - write savegame.json",
        "  load - load savegame.json",
        "  new - start a new run",
        "Night:",
        "  Type an enemy word and press Enter",
        "Examples:",
        "  gather wood 10",
        "  build farm",
        "  build tower 9 5",
        "  cursor 8 5",
        "  cursor up 3",
        "  inspect",
        "  preview tower",
        "  wait",
        "  overlay path on",
        "  upgrade",
        "  enemies",
        "  goal",
        "  report",
        "  history",
        "  trend",
        "  map",
        "  seed warmup-run"
    ]
