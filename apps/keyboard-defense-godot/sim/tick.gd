class_name SimTick
extends RefCounted

const GameState = preload("res://sim/types.gd")
const SimBuildings = preload("res://sim/buildings.gd")
const SimRng = preload("res://sim/rng.gd")
const SimBalance = preload("res://sim/balance.gd")
const SimUpgrades = preload("res://sim/upgrades.gd")

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

    # Get research production bonuses
    var food_bonus: float = SimUpgrades.get_food_production_bonus(state)
    var gold_bonus: float = SimUpgrades.get_gold_production_bonus(state)

    for key in GameState.RESOURCE_KEYS:
        var base_amount: int = int(production.get(key, 0))
        var amount: int = base_amount

        # Apply food production bonus from research
        var bonus_applied: bool = false
        if key == "food" and food_bonus > 0.0 and base_amount > 0:
            amount = max(base_amount, int(float(base_amount) * (1.0 + food_bonus)))
            bonus_applied = amount > base_amount

        if amount > 0:
            state.resources[key] = int(state.resources.get(key, 0)) + amount
            if bonus_applied:
                summary.append("%d %s (+%d%%)" % [amount, key, int(food_bonus * 100)])
            else:
                summary.append("%d %s" % [amount, key])

    # Apply gold per building from research (Taxation)
    var gold_per_building: int = SimUpgrades.get_gold_per_building(state)
    if gold_per_building > 0:
        var building_count: int = state.structures.size()
        var tax_gold: int = building_count * gold_per_building
        if tax_gold > 0:
            state.gold += tax_gold
            summary.append("+%d gold (tax)" % tax_gold)

    # Apply gold production bonus (if there's any gold income source)
    # This would apply to market/trade buildings if implemented

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
