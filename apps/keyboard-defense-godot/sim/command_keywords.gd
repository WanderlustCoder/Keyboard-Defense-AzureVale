class_name CommandKeywords
extends RefCounted

const KEYWORDS: Array[String] = [
    "help",
    "status",
    "gather",
    "build",
    "explore",
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
    "settings",
    "bind",
    "report",
    "history",
    "trend"
]

static func keywords() -> Array[String]:
    return KEYWORDS
