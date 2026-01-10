# Balance & Day Tick Guide

This document explains the day progression system, midgame catch-up mechanics, resource caps, and night wave formula in Keyboard Defense.

## Overview

The balance and tick systems manage game pacing:

```
Day Start → Production → Catch-up Bonuses → Resource Caps → Night Wave
    ↓           ↓              ↓                 ↓              ↓
  day++    buildings      stone/food boost    trim excess    formula
```

## Day Advancement

### Advance Day

```gdscript
# sim/tick.gd:32
static func advance_day(state: GameState) -> Dictionary:
    state.day += 1

    # Calculate and apply production
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

    # Apply midgame food bonus
    var bonus_food: int = SimBalance.midgame_food_bonus(state)
    if bonus_food > 0:
        state.resources["food"] = int(state.resources.get("food", 0)) + bonus_food
        events.append("Midgame supply: +%d food." % bonus_food)

    # Apply resource caps
    var trimmed: Dictionary = SimBalance.apply_resource_caps(state)
    if not trimmed.is_empty():
        events.append("Storage limits: -%s." % _format_resource_delta(trimmed))

    return {"state": state, "events": events}
```

### Day Advancement Order

1. Increment day counter
2. Apply building production
3. Apply midgame catch-up bonuses
4. Enforce resource storage caps
5. Return events for display

## Midgame Catch-Up Mechanics

### Constants

```gdscript
# sim/balance.gd
const MIDGAME_STONE_CATCHUP_DAY := 4       # When stone catch-up activates
const MIDGAME_STONE_CATCHUP_MIN := 10      # Stone threshold for catch-up

const MIDGAME_FOOD_BONUS_DAY := 4          # When food bonus activates
const MIDGAME_FOOD_BONUS_THRESHOLD := 12   # Food threshold
const MIDGAME_FOOD_BONUS_AMOUNT := 2       # Bonus food per day
```

### Stone Catch-Up

Forces exploration rewards to give stone if player is behind:

```gdscript
# sim/balance.gd:16
static func maybe_override_explore_reward(state: GameState, reward_resource: String) -> String:
    # Before day 4, no override
    if state.day < MIDGAME_STONE_CATCHUP_DAY:
        return reward_resource

    # If player has enough stone, no override
    if int(state.resources.get("stone", 0)) >= MIDGAME_STONE_CATCHUP_MIN:
        return reward_resource

    # Override to stone
    return "stone"
```

**Purpose**: Prevents players from getting stuck without stone for walls/towers.

### Food Bonus

Provides free food if player's food is low:

```gdscript
# sim/balance.gd:23
static func midgame_food_bonus(state: GameState) -> int:
    # Before day 4, no bonus
    if state.day < MIDGAME_FOOD_BONUS_DAY:
        return 0

    # If player has enough food, no bonus
    if int(state.resources.get("food", 0)) >= MIDGAME_FOOD_BONUS_THRESHOLD:
        return 0

    # Grant bonus food
    return MIDGAME_FOOD_BONUS_AMOUNT
```

**Purpose**: Prevents starvation spirals where lack of food leads to worker loss.

## Resource Caps

### Cap Values by Day

```gdscript
# sim/balance.gd
const MIDGAME_CAPS_DAY5 := {"wood": 40, "stone": 20, "food": 25}
const MIDGAME_CAPS_DAY7 := {"wood": 50, "stone": 35, "food": 35}
```

| Day | Wood Cap | Stone Cap | Food Cap |
|-----|----------|-----------|----------|
| 1-4 | None | None | None |
| 5-6 | 40 | 20 | 25 |
| 7+ | 50 | 35 | 35 |

### Getting Caps

```gdscript
# sim/balance.gd:30
static func caps_for_day(day: int) -> Dictionary:
    if day >= 7:
        return MIDGAME_CAPS_DAY7
    if day >= 5:
        return MIDGAME_CAPS_DAY5
    return {}  # No caps
```

### Applying Caps

```gdscript
# sim/balance.gd:37
static func apply_resource_caps(state: GameState) -> Dictionary:
    var caps: Dictionary = caps_for_day(state.day)
    var trimmed: Dictionary = {}

    for key in caps.keys():
        var cap: int = int(caps.get(key, 0))
        var value: int = int(state.resources.get(key, 0))
        if value > cap:
            var delta: int = value - cap
            state.resources[key] = cap
            trimmed[key] = delta

    return trimmed  # Returns what was trimmed
```

**Purpose**: Prevents resource hoarding, encouraging players to spend.

## Night Wave Formula

### Base Wave Sizes

```gdscript
# sim/tick.gd:9
const NIGHT_WAVE_BASE_BY_DAY := {
    1: 2,
    2: 3,
    3: 3,
    4: 4,
    5: 5,
    6: 6,
    7: 7
}
```

| Day | Base Enemies |
|-----|--------------|
| 1 | 2 |
| 2 | 3 |
| 3 | 3 |
| 4 | 4 |
| 5 | 5 |
| 6 | 6 |
| 7 | 7 |
| 8+ | 2 + day/2 |

### Wave Size Calculation

```gdscript
# sim/tick.gd:61
static func compute_night_wave_total(state: GameState, defense: int) -> int:
    # Get base from table, or calculate for later days
    var base: int = int(NIGHT_WAVE_BASE_BY_DAY.get(state.day, 2 + int(state.day / 2)))

    # Formula: base + threat - defense
    var raw: int = base + state.threat - defense

    # Minimum 1 enemy
    return max(1, raw)
```

**Formula**: `wave_size = base + threat - defense`

Where:
- `base` = Day-specific enemy count
- `threat` = Current threat level (accumulated danger)
- `defense` = Tower defense rating

### Examples

| Day | Base | Threat | Defense | Wave Size |
|-----|------|--------|---------|-----------|
| 1 | 2 | 0 | 0 | 2 |
| 3 | 3 | 2 | 1 | 4 |
| 5 | 5 | 5 | 3 | 7 |
| 7 | 7 | 8 | 5 | 10 |

## Night Prompts

Random words for night phase transition:

```gdscript
# sim/tick.gd:19
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

static func build_night_prompt(state: GameState) -> String:
    var prompt = SimRng.choose(state, NIGHT_PROMPTS)
    if prompt == null:
        return ""
    return str(prompt)
```

**Purpose**: Provides thematic flavor during phase transitions.

## Integration Examples

### End Day Intent Handler

```gdscript
# sim/apply_intent.gd
"end_day":
    if state.phase != "day":
        events.append("Can only end day during day phase.")
        return

    # Advance day and apply production
    var result: Dictionary = SimTick.advance_day(state)
    for event in result.events:
        events.append(event)

    # Transition to night
    state.phase = "night"

    # Calculate wave size
    var defense: int = _calculate_defense(state)
    var wave_size: int = SimTick.compute_night_wave_total(state, defense)

    # Spawn enemies
    _spawn_wave(state, wave_size)

    # Get night prompt
    var prompt: String = SimTick.build_night_prompt(state)
    events.append("Night falls. Type '%s' to begin defense." % prompt)
```

### Exploration with Catch-Up

```gdscript
# sim/apply_intent.gd
"explore":
    # Determine base reward
    var reward_resource: String = _roll_explore_reward(state)

    # Apply catch-up override
    reward_resource = SimBalance.maybe_override_explore_reward(state, reward_resource)

    # Grant reward
    var amount: int = randi_range(2, 5)
    state.resources[reward_resource] = int(state.resources.get(reward_resource, 0)) + amount
    events.append("Found %d %s." % [amount, reward_resource])
```

### Production Preview

```gdscript
func get_day_preview(state: GameState) -> Dictionary:
    # Preview what would happen on day end
    var production: Dictionary = SimBuildings.daily_production(state)
    var food_bonus: int = SimBalance.midgame_food_bonus(state)
    var caps: Dictionary = SimBalance.caps_for_day(state.day + 1)

    var projected: Dictionary = {}
    for key in GameState.RESOURCE_KEYS:
        var current: int = int(state.resources.get(key, 0))
        var prod: int = int(production.get(key, 0))
        var bonus: int = food_bonus if key == "food" else 0
        var total: int = current + prod + bonus

        # Apply cap preview
        var cap: int = int(caps.get(key, 9999))
        projected[key] = min(total, cap)

    return projected
```

## Balance Tuning

### Adjusting Difficulty

**Easier Game:**
- Increase `MIDGAME_STONE_CATCHUP_MIN` (more catch-up)
- Increase `MIDGAME_FOOD_BONUS_AMOUNT`
- Reduce base wave sizes
- Increase resource caps

**Harder Game:**
- Decrease or remove catch-up mechanics
- Reduce or remove food bonus
- Increase base wave sizes
- Lower or remove resource caps

### Adding New Catch-Up Mechanics

```gdscript
# Example: Gold catch-up for struggling players
const MIDGAME_GOLD_CATCHUP_DAY := 5
const MIDGAME_GOLD_CATCHUP_MIN := 20
const MIDGAME_GOLD_BONUS_AMOUNT := 5

static func midgame_gold_bonus(state: GameState) -> int:
    if state.day < MIDGAME_GOLD_CATCHUP_DAY:
        return 0
    if state.gold >= MIDGAME_GOLD_CATCHUP_MIN:
        return 0
    return MIDGAME_GOLD_BONUS_AMOUNT
```

## Testing

```gdscript
func test_advance_day():
    var state := GameState.new()
    state.day = 1

    var result := SimTick.advance_day(state)
    assert(state.day == 2)
    assert(result.events.size() > 0)

    _pass("test_advance_day")

func test_stone_catchup():
    var state := GameState.new()
    state.day = 4
    state.resources["stone"] = 5  # Below threshold

    var reward := SimBalance.maybe_override_explore_reward(state, "wood")
    assert(reward == "stone")  # Should override to stone

    state.resources["stone"] = 15  # Above threshold
    reward = SimBalance.maybe_override_explore_reward(state, "wood")
    assert(reward == "wood")  # Should not override

    _pass("test_stone_catchup")

func test_food_bonus():
    var state := GameState.new()
    state.day = 4
    state.resources["food"] = 5  # Below threshold

    var bonus := SimBalance.midgame_food_bonus(state)
    assert(bonus == 2)

    state.resources["food"] = 15  # Above threshold
    bonus = SimBalance.midgame_food_bonus(state)
    assert(bonus == 0)

    _pass("test_food_bonus")

func test_resource_caps():
    var state := GameState.new()
    state.day = 5
    state.resources["wood"] = 60  # Over cap

    var trimmed := SimBalance.apply_resource_caps(state)
    assert(state.resources["wood"] == 40)
    assert(trimmed["wood"] == 20)

    _pass("test_resource_caps")

func test_wave_formula():
    var state := GameState.new()
    state.day = 3
    state.threat = 2

    var wave_size := SimTick.compute_night_wave_total(state, 1)
    # base(3) + threat(2) - defense(1) = 4
    assert(wave_size == 4)

    _pass("test_wave_formula")
```
