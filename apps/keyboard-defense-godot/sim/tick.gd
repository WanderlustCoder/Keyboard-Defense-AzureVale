class_name SimTick
extends RefCounted

const GameState = preload("res://sim/types.gd")
const SimBuildings = preload("res://sim/buildings.gd")
const SimRng = preload("res://sim/rng.gd")

const NIGHT_PROMPTS := [
    "bastion",
    "banner",
    "citadel",
    "ember",
    "forge",
    "lantern",
    "rune",
    "shield",
    "spear",
    "ward"
]

static func advance_day(state: GameState) -> Dictionary:
    state.day += 1
    var production: Dictionary = SimBuildings.daily_production(state)
    var summary: Array[String] = []
    for key in GameState.RESOURCE_KEYS:
        var amount: int = int(production.get(key, 0))
        if amount > 0:
            state.resources[key] = int(state.resources.get(key, 0)) + amount
            summary.append("%d %s" % [amount, key])
    var events: Array[String] = ["Day advanced to %d." % state.day]
    if summary.is_empty():
        events.append("Production: none.")
    else:
        events.append("Production: +%s." % ", ".join(summary))
    return {"state": state, "events": events}

static func build_night_prompt(state: GameState) -> String:
    var prompt = SimRng.choose(state, NIGHT_PROMPTS)
    if prompt == null:
        return ""
    return str(prompt)

static func compute_night_wave_total(state: GameState, defense: int) -> int:
    var raw: int = 2 + int(state.day / 2) + state.threat - defense
    return max(1, raw)
