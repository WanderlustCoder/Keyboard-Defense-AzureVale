class_name SimTick
extends RefCounted

const GameState = preload("res://sim/types.gd")
const SimBuildings = preload("res://sim/buildings.gd")
const SimRng = preload("res://sim/rng.gd")
const SimBalance = preload("res://sim/balance.gd")

const NIGHT_WAVE_BASE_BY_DAY := {
    1: 2,
    2: 3,
    3: 3,
    4: 4,
    5: 5,
    6: 6,
    7: 7
}

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
    var bonus_food: int = SimBalance.midgame_food_bonus(state)
    if bonus_food > 0:
        state.resources["food"] = int(state.resources.get("food", 0)) + bonus_food
        events.append("Midgame supply: +%d food." % bonus_food)
    var trimmed: Dictionary = SimBalance.apply_resource_caps(state)
    if not trimmed.is_empty():
        events.append("Storage limits: -%s." % _format_resource_delta(trimmed))
    return {"state": state, "events": events}

static func build_night_prompt(state: GameState) -> String:
    var prompt = SimRng.choose(state, NIGHT_PROMPTS)
    if prompt == null:
        return ""
    return str(prompt)

static func compute_night_wave_total(state: GameState, defense: int) -> int:    
    var base: int = int(NIGHT_WAVE_BASE_BY_DAY.get(state.day, 2 + int(state.day / 2)))
    var raw: int = base + state.threat - defense
    return max(1, raw)

static func _format_resource_delta(values: Dictionary) -> String:
    var parts: Array[String] = []
    for key in GameState.RESOURCE_KEYS:
        if not values.has(key):
            continue
        var amount: int = int(values.get(key, 0))
        if amount <= 0:
            continue
        parts.append("%s %d" % [key, amount])
    if parts.is_empty():
        return "none"
    return ", ".join(parts)
