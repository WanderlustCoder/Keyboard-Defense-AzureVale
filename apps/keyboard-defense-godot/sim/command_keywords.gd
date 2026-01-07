class_name CommandKeywords
extends RefCounted

const KEYWORDS: Array[String] = [
    "help",
    "version",
    "status",
    "balance",
    "gather",
    "build",
    "explore",
    "interact",
    "choice",
    "skip",
    "buy",
    "upgrades",
    "end",
    "seed",
    "defend",
    "wait",
    "save",
    "load",
    "new",
    "restart",
    "cursor",
    "inspect",
    "map",
    "overlay",
    "preview",
    "upgrade",
    "demolish",
    "enemies",
    "goal",
    "lesson",
    "lessons",
    "settings",
    "bind",
    "report",
    "history",
    "trend",
    "tutorial"
]

static func keywords() -> Array[String]:
    return KEYWORDS
