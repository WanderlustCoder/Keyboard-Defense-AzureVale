# Research & Trade Guide

This document explains the research tech tree and resource trading systems in Keyboard Defense.

## Overview

Two interconnected economic systems:

```
Research:  Gold → Active Research → Wave Progress → Completed → Effects Applied
Trade:     Level 3 Market → Daily Rates → Resource Exchange → Market Bonus
```

## Research System

### Research State

Research is tracked in `GameState`:

```gdscript
# sim/types.gd
var active_research: String = ""     # Currently researching ID
var research_progress: int = 0       # Waves completed toward research
var completed_research: Array = []   # List of completed research IDs
```

### Research Data Structure

Research is defined in `res://data/research.json`:

```json
{
  "research": [
    {
      "id": "stone_masonry",
      "label": "Stone Masonry",
      "description": "Reduce stone costs for building walls",
      "category": "construction",
      "cost": { "gold": 50 },
      "waves_to_complete": 3,
      "requires": [],
      "effects": {
        "stone_cost_reduction": 0.2
      }
    },
    {
      "id": "advanced_architecture",
      "label": "Advanced Architecture",
      "description": "Build more structures",
      "category": "construction",
      "cost": { "gold": 100 },
      "waves_to_complete": 4,
      "requires": ["stone_masonry"],
      "effects": {
        "build_limit_bonus": 2
      }
    }
  ]
}
```

### Research Categories

```gdscript
# sim/research.gd:246
func get_research_tree(state: GameState) -> Dictionary:
    var tree := {
        "construction": [],  # Building improvements
        "economy": [],       # Resource production
        "military": [],      # Combat effectiveness
        "mystical": []       # Typing powers
    }
```

### Checking Prerequisites

```gdscript
# sim/research.gd:38
func has_prerequisites(state: GameState, research_id: String) -> bool:
    var research: Dictionary = get_research(research_id)
    if research.is_empty():
        return false

    var requires: Array = research.get("requires", [])
    for req_id in requires:
        if not state.completed_research.has(str(req_id)):
            return false
    return true
```

### Starting Research

```gdscript
# sim/research.gd:50
func can_start_research(state: GameState, research_id: String) -> Dictionary:
    var result := {"ok": false, "reason": ""}

    var research: Dictionary = get_research(research_id)
    if research.is_empty():
        result.reason = "unknown research"
        return result

    # Check if already completed
    if state.completed_research.has(research_id):
        result.reason = "already completed"
        return result

    # Check if already researching something
    if not state.active_research.is_empty():
        result.reason = "already researching"
        return result

    # Check prerequisites
    if not has_prerequisites(state, research_id):
        result.reason = "prerequisites not met"
        return result

    # Check gold cost
    var cost: Dictionary = research.get("cost", {})
    var gold_cost: int = int(cost.get("gold", 0))
    if state.gold < gold_cost:
        result.reason = "not enough gold"
        return result

    result.ok = true
    return result

# sim/research.gd:84
func start_research(state: GameState, research_id: String) -> bool:
    var check: Dictionary = can_start_research(state, research_id)
    if not check.ok:
        return false

    var research: Dictionary = get_research(research_id)
    var cost: Dictionary = research.get("cost", {})
    var gold_cost: int = int(cost.get("gold", 0))

    # Deduct cost
    state.gold -= gold_cost

    # Set active research
    state.active_research = research_id
    state.research_progress = 0

    return true
```

### Research Progress

Research advances after each wave:

```gdscript
# sim/research.gd:121
func advance_research(state: GameState) -> Dictionary:
    var result := {"completed": false, "research_id": "", "effects": {}}

    if state.active_research.is_empty():
        return result

    state.research_progress += 1

    var research: Dictionary = get_research(state.active_research)
    var waves_needed: int = int(research.get("waves_to_complete", 1))

    if state.research_progress >= waves_needed:
        # Research completed
        result.completed = true
        result.research_id = state.active_research
        result.effects = research.get("effects", {})

        state.completed_research.append(state.active_research)
        state.active_research = ""
        state.research_progress = 0

    return result
```

### Canceling Research

```gdscript
# sim/research.gd:103
func cancel_research(state: GameState) -> bool:
    if state.active_research.is_empty():
        return false

    var research: Dictionary = get_research(state.active_research)
    var cost: Dictionary = research.get("cost", {})
    var gold_cost: int = int(cost.get("gold", 0))

    # Refund half
    state.gold += int(gold_cost / 2)

    # Clear research
    state.active_research = ""
    state.research_progress = 0

    return true
```

### Getting Progress

```gdscript
# sim/research.gd:145
func get_progress_percent(state: GameState) -> float:
    if state.active_research.is_empty():
        return 0.0

    var research: Dictionary = get_research(state.active_research)
    var waves_needed: int = int(research.get("waves_to_complete", 1))

    return float(state.research_progress) / float(waves_needed)
```

### Available Research

```gdscript
# sim/research.gd:155
func get_available_research(state: GameState) -> Array:
    var available: Array = []

    for item in _research_data:
        var research_id: String = str(item.get("id", ""))

        # Skip completed
        if state.completed_research.has(research_id):
            continue

        # Skip currently researching
        if state.active_research == research_id:
            continue

        # Check prerequisites
        if not has_prerequisites(state, research_id):
            continue

        available.append(item.duplicate(true))

    return available
```

### Research Effects

Accumulate effects from all completed research:

```gdscript
# sim/research.gd:178
func get_total_effects(state: GameState) -> Dictionary:
    var effects := {
        "stone_cost_reduction": 0.0,
        "build_limit_bonus": 0,
        "wall_defense_bonus": 0,
        "build_cost_reduction": 0.0,
        "food_production_bonus": 0.0,
        "gold_production_bonus": 0.0,
        "gold_per_building": 0,
        "resource_multiplier": 0.0,
        "tower_range_bonus": 0,
        "typing_power": 0.0,
        "combo_multiplier": 0.0,
        "tower_damage_bonus": 0,
        "critical_chance": 0.0,
        "wave_heal": 0,
        "planning_time_bonus": 0,
        "perfect_word_crit": false,
        "critical_damage": 0.0,
        "castle_health_bonus": 0,
        "mistake_forgiveness": 0.0
    }

    for research_id in state.completed_research:
        var research: Dictionary = get_research(research_id)
        var research_effects: Dictionary = research.get("effects", {})

        for key in research_effects.keys():
            if effects.has(key):
                var value = research_effects[key]
                if typeof(value) == TYPE_BOOL:
                    effects[key] = value
                elif typeof(effects[key]) == TYPE_INT:
                    effects[key] = int(effects[key]) + int(value)
                else:
                    effects[key] = float(effects[key]) + float(value)

    return effects
```

### Research Summary

```gdscript
# sim/research.gd:218
func get_research_summary(state: GameState) -> Dictionary:
    var summary := {
        "active_research": "",
        "active_label": "",
        "progress": 0,
        "waves_needed": 0,
        "progress_percent": 0.0,
        "completed_count": state.completed_research.size(),
        "total_count": _research_data.size(),
        "available_count": get_available_research(state).size()
    }

    if not state.active_research.is_empty():
        var research: Dictionary = get_research(state.active_research)
        summary.active_research = state.active_research
        summary.active_label = str(research.get("label", ""))
        summary.progress = state.research_progress
        summary.waves_needed = int(research.get("waves_to_complete", 1))
        summary.progress_percent = get_progress_percent(state)

    return summary
```

### Research Tree View

```gdscript
# sim/research.gd:245
func get_research_tree(state: GameState) -> Dictionary:
    var tree := {
        "construction": [],
        "economy": [],
        "military": [],
        "mystical": []
    }

    for item in _research_data:
        var category: String = str(item.get("category", ""))
        var research_id: String = str(item.get("id", ""))

        if not tree.has(category):
            continue

        var entry: Dictionary = item.duplicate(true)
        entry["completed"] = state.completed_research.has(research_id)
        entry["active"] = state.active_research == research_id
        entry["available"] = has_prerequisites(state, research_id) and not entry["completed"]
        entry["can_afford"] = state.gold >= int(item.get("cost", {}).get("gold", 0))

        tree[category].append(entry)

    return tree
```

## Trade System

### Trade State

Trade is tracked in `GameState`:

```gdscript
# sim/types.gd
var trade_rates: Dictionary = {}  # Current day's trade rates
var last_trade_day: int = -1      # Day when rates were calculated
```

### Base Exchange Rates

```gdscript
# sim/trade.gd:9
const BASE_RATES := {
    "wood_to_stone": 0.67,     # 3 wood -> 2 stone
    "stone_to_wood": 1.5,      # 2 stone -> 3 wood
    "wood_to_food": 1.0,       # 1 wood -> 1 food
    "food_to_wood": 1.0,       # 1 food -> 1 wood
    "stone_to_food": 1.5,      # 2 stone -> 3 food
    "food_to_stone": 0.67,     # 3 food -> 2 stone
    "wood_to_gold": 0.33,      # 3 wood -> 1 gold
    "gold_to_wood": 3.0,       # 1 gold -> 3 wood
    "stone_to_gold": 0.5,      # 2 stone -> 1 gold
    "gold_to_stone": 2.0,      # 1 gold -> 2 stone
    "food_to_gold": 0.5,       # 2 food -> 1 gold
    "gold_to_food": 2.0        # 1 gold -> 2 food
}

# Rate variance based on day (simulates market fluctuation)
const RATE_VARIANCE := 0.15  # +/- 15% variance
```

### Trading Requirements

Trading requires a Level 3 Market:

```gdscript
# sim/trade.gd:28
static func is_trading_enabled(state: GameState) -> bool:
    for key in state.structures.keys():
        var building_type: String = str(state.structures[key])
        if building_type == "market":
            var level: int = SimBuildings.structure_level(state, int(key))
            if level >= 3:
                return true
    return false
```

### Daily Rate Calculation

Rates vary each day using deterministic seeding:

```gdscript
# sim/trade.gd:50
static func _calculate_rates(state: GameState) -> Dictionary:
    var rates: Dictionary = {}

    # Use day as seed for consistent rates within a day
    var rng := RandomNumberGenerator.new()
    rng.seed = hash(str(state.rng_seed) + str(state.day))

    for rate_key in BASE_RATES.keys():
        var base_rate: float = BASE_RATES[rate_key]
        var variance: float = rng.randf_range(-RATE_VARIANCE, RATE_VARIANCE)
        rates[rate_key] = base_rate * (1.0 + variance)

    # Apply market bonuses
    var market_bonus: float = _get_market_bonus(state)
    if market_bonus > 0:
        for rate_key in rates.keys():
            if rate_key.ends_with("_to_gold"):
                # Get more gold when selling
                rates[rate_key] = rates[rate_key] * (1.0 + market_bonus)
            else:
                # Pay less when buying
                rates[rate_key] = rates[rate_key] * (1.0 + market_bonus * 0.5)

    return rates
```

### Market Bonus

```gdscript
# sim/trade.gd:77
static func _get_market_bonus(state: GameState) -> float:
    var bonus: float = 0.0

    for key in state.structures.keys():
        var building_type: String = str(state.structures[key])
        if building_type == "market":
            var level: int = SimBuildings.structure_level(state, int(key))
            bonus += 0.05 * level  # 5% per market level

    return min(bonus, 0.3)  # Cap at 30%
```

### Getting Current Rates

```gdscript
# sim/trade.gd:38
static func get_rates(state: GameState) -> Dictionary:
    var rates: Dictionary = state.trade_rates.duplicate(true)

    # If rates are empty or day changed, recalculate
    if rates.is_empty() or state.last_trade_day != state.day:
        rates = _calculate_rates(state)
        state.trade_rates = rates.duplicate(true)
        state.last_trade_day = state.day

    return rates
```

### Calculating a Trade

```gdscript
# sim/trade.gd:93
static func calculate_trade(state: GameState, from_resource: String, to_resource: String, amount: int) -> Dictionary:
    var result := {
        "ok": false,
        "reason": "",
        "from_resource": from_resource,
        "to_resource": to_resource,
        "from_amount": amount,
        "to_amount": 0,
        "rate": 0.0
    }

    # Check trading is enabled
    if not is_trading_enabled(state):
        result.reason = "trading not enabled (need Level 3 Market)"
        return result

    # Validate resources
    var valid_resources := ["wood", "stone", "food", "gold"]
    if from_resource not in valid_resources or to_resource not in valid_resources:
        result.reason = "invalid resource"
        return result

    if from_resource == to_resource:
        result.reason = "cannot trade same resource"
        return result

    if amount <= 0:
        result.reason = "invalid amount"
        return result

    # Check we have enough
    var have: int
    if from_resource == "gold":
        have = state.gold
    else:
        have = int(state.resources.get(from_resource, 0))

    if have < amount:
        result.reason = "not enough " + from_resource
        return result

    # Get rate and calculate result
    var rate_key: String = from_resource + "_to_" + to_resource
    var rates: Dictionary = get_rates(state)

    if not rates.has(rate_key):
        result.reason = "trade not available"
        return result

    var rate: float = rates[rate_key]
    var to_amount: int = int(floor(float(amount) * rate))

    if to_amount <= 0:
        result.reason = "trade amount too small"
        return result

    result.ok = true
    result.to_amount = to_amount
    result.rate = rate

    return result
```

### Executing a Trade

```gdscript
# sim/trade.gd:156
static func execute_trade(state: GameState, from_resource: String, to_resource: String, amount: int) -> Dictionary:
    var calc: Dictionary = calculate_trade(state, from_resource, to_resource, amount)
    if not calc.ok:
        return calc

    # Deduct from resource
    if from_resource == "gold":
        state.gold -= amount
    else:
        state.resources[from_resource] = int(state.resources.get(from_resource, 0)) - amount

    # Add to resource
    if to_resource == "gold":
        state.gold += calc.to_amount
    else:
        state.resources[to_resource] = int(state.resources.get(to_resource, 0)) + calc.to_amount

    return calc
```

### Parsing Trade Commands

```gdscript
# sim/trade.gd:176
static func parse_trade_command(command: String) -> Dictionary:
    var result := {
        "ok": false,
        "from_resource": "",
        "to_resource": "",
        "amount": 0,
        "reason": ""
    }

    # Normalize the command
    command = command.to_lower().strip_edges()

    # Remove "trade" prefix if present
    if command.begins_with("trade "):
        command = command.substr(6).strip_edges()

    # Try to parse: "<amount> <resource> for/to <resource>"
    var parts: Array = command.split(" ")
    if parts.size() < 4:
        result.reason = "invalid format"
        return result

    # First part should be amount
    if not parts[0].is_valid_int():
        result.reason = "invalid amount"
        return result

    var amount: int = int(parts[0])
    if amount <= 0:
        result.reason = "amount must be positive"
        return result

    # Second part should be from_resource
    var from_resource: String = parts[1]

    # Third part should be "for" or "to"
    if parts[2] != "for" and parts[2] != "to":
        result.reason = "expected 'for' or 'to'"
        return result

    # Fourth part should be to_resource
    var to_resource: String = parts[3]

    result.ok = true
    result.amount = amount
    result.from_resource = from_resource
    result.to_resource = to_resource

    return result
```

### Trade Summary

```gdscript
# sim/trade.gd:227
static func get_trade_summary(state: GameState) -> Dictionary:
    var summary := {
        "enabled": is_trading_enabled(state),
        "market_bonus": _get_market_bonus(state),
        "rates": {},
        "resources": {
            "wood": int(state.resources.get("wood", 0)),
            "stone": int(state.resources.get("stone", 0)),
            "food": int(state.resources.get("food", 0)),
            "gold": state.gold
        }
    }

    if summary.enabled:
        summary.rates = get_rates(state)

    return summary
```

### Suggested Trades

Get AI-suggested trades based on resource imbalance:

```gdscript
# sim/trade.gd:246
static func get_suggested_trades(state: GameState) -> Array:
    var suggestions: Array = []

    if not is_trading_enabled(state):
        return suggestions

    var resources := {
        "wood": int(state.resources.get("wood", 0)),
        "stone": int(state.resources.get("stone", 0)),
        "food": int(state.resources.get("food", 0)),
        "gold": state.gold
    }

    var rates: Dictionary = get_rates(state)

    # Find resources we have a lot of
    var avg: float = float(resources["wood"] + resources["stone"] + resources["food"]) / 3.0
    var high_threshold: float = avg * 1.5
    var low_threshold: float = avg * 0.5

    for from_res in ["wood", "stone", "food"]:
        if resources[from_res] > high_threshold:
            # We have excess, suggest trading
            for to_res in ["wood", "stone", "food", "gold"]:
                if from_res == to_res:
                    continue
                if to_res != "gold" and resources[to_res] > low_threshold:
                    continue  # Don't suggest if target is not low

                var rate_key: String = from_res + "_to_" + to_res
                if rates.has(rate_key):
                    var trade_amount: int = int(resources[from_res] * 0.3)  # 30%
                    if trade_amount > 0:
                        suggestions.append({
                            "from": from_res,
                            "to": to_res,
                            "amount": trade_amount,
                            "receive": int(floor(float(trade_amount) * rates[rate_key])),
                            "rate": rates[rate_key]
                        })

    return suggestions
```

## Integration Examples

### Research Intent Handler

```gdscript
# sim/apply_intent.gd
"research":
    _apply_research(new_state, intent, events)

static func _apply_research(state: GameState, intent: Dictionary, events: Array[String]) -> void:
    var action: String = str(intent.get("action", ""))
    var research_id: String = str(intent.get("id", ""))

    match action:
        "start":
            var research := SimResearch.instance()
            if research.start_research(state, research_id):
                var info := research.get_research(research_id)
                events.append("Started researching: %s" % info.get("label", ""))
            else:
                var check := research.can_start_research(state, research_id)
                events.append("Cannot start research: %s" % check.reason)

        "cancel":
            var research := SimResearch.instance()
            if research.cancel_research(state):
                events.append("Research canceled. 50% gold refunded.")
            else:
                events.append("No active research to cancel.")
```

### Trade Intent Handler

```gdscript
# sim/apply_intent.gd
"trade":
    _apply_trade(new_state, intent, events)

static func _apply_trade(state: GameState, intent: Dictionary, events: Array[String]) -> void:
    var from_res: String = str(intent.get("from", ""))
    var to_res: String = str(intent.get("to", ""))
    var amount: int = int(intent.get("amount", 0))

    var result := SimTrade.execute_trade(state, from_res, to_res, amount)

    if result.ok:
        events.append("Traded %d %s for %d %s (rate: %.2f)" % [
            amount, from_res, result.to_amount, to_res, result.rate
        ])
    else:
        events.append("Trade failed: %s" % result.reason)
```

### Wave End Research Advancement

```gdscript
# sim/world_tick.gd
func _on_wave_end(state: GameState, events: Array[String]) -> void:
    var research := SimResearch.instance()
    var result := research.advance_research(state)

    if result.completed:
        events.append("Research Complete: %s" % result.research_id)
        _apply_research_effects(state, result.effects)
```

### Applying Research Effects

```gdscript
func _apply_research_effects(state: GameState, effects: Dictionary) -> void:
    # Get all current effects
    var research := SimResearch.instance()
    var total := research.get_total_effects(state)

    # Apply bonuses
    if total.get("castle_health_bonus", 0) > 0:
        state.max_hp += int(total.castle_health_bonus)
        state.hp = min(state.hp + int(total.castle_health_bonus), state.max_hp)

    # Tower range bonus applied in targeting
    # Typing power applied in damage calculation
    # Build limits applied in build validation
```

## UI Integration

### Research Panel

```gdscript
func _update_research_panel(state: GameState) -> void:
    var research := SimResearch.instance()
    var summary := research.get_research_summary(state)

    # Show current research
    if not summary.active_research.is_empty():
        research_label.text = summary.active_label
        progress_bar.value = summary.progress_percent * 100
        progress_label.text = "%d/%d waves" % [summary.progress, summary.waves_needed]
    else:
        research_label.text = "No active research"
        progress_bar.value = 0

    # Show available research
    var available := research.get_available_research(state)
    for item in available:
        _add_research_button(item)
```

### Trade Panel

```gdscript
func _update_trade_panel(state: GameState) -> void:
    var summary := SimTrade.get_trade_summary(state)

    if not summary.enabled:
        trade_status.text = "Trading requires Level 3 Market"
        trade_buttons.hide()
        return

    trade_status.text = "Market Bonus: +%.0f%%" % (summary.market_bonus * 100)

    # Show current rates
    for rate_key in summary.rates:
        var rate: float = summary.rates[rate_key]
        _add_rate_display(rate_key, rate)

    # Show suggestions
    var suggestions := SimTrade.get_suggested_trades(state)
    for suggestion in suggestions:
        _add_trade_suggestion(suggestion)
```

## Testing

```gdscript
func test_research_prerequisites():
    var state := GameState.new()
    var research := SimResearch.new()

    # First research has no prerequisites
    assert(research.has_prerequisites(state, "stone_masonry"))

    # Second research requires first
    assert(not research.has_prerequisites(state, "advanced_architecture"))

    # Complete first research
    state.completed_research.append("stone_masonry")
    assert(research.has_prerequisites(state, "advanced_architecture"))

    _pass("test_research_prerequisites")

func test_research_completion():
    var state := GameState.new()
    state.gold = 100
    var research := SimResearch.new()

    research.start_research(state, "stone_masonry")
    assert(state.active_research == "stone_masonry")
    assert(state.gold == 50)  # Cost deducted

    # Advance through waves
    var result := research.advance_research(state)
    assert(not result.completed)

    result = research.advance_research(state)
    result = research.advance_research(state)
    assert(result.completed)
    assert(state.completed_research.has("stone_masonry"))

    _pass("test_research_completion")

func test_trade_rates():
    var state := GameState.new()
    state.structures[0] = "market"
    state.structure_levels[0] = 3

    assert(SimTrade.is_trading_enabled(state))

    var rates := SimTrade.get_rates(state)
    assert(rates.has("wood_to_gold"))
    assert(rates["wood_to_gold"] > 0)

    _pass("test_trade_rates")

func test_trade_execution():
    var state := GameState.new()
    state.structures[0] = "market"
    state.structure_levels[0] = 3
    state.resources["wood"] = 100

    var result := SimTrade.execute_trade(state, "wood", "gold", 30)
    assert(result.ok)
    assert(state.resources["wood"] == 70)
    assert(state.gold > 0)

    _pass("test_trade_execution")

func test_trade_command_parsing():
    var result := SimTrade.parse_trade_command("trade 10 wood for gold")
    assert(result.ok)
    assert(result.amount == 10)
    assert(result.from_resource == "wood")
    assert(result.to_resource == "gold")

    result = SimTrade.parse_trade_command("5 stone to food")
    assert(result.ok)
    assert(result.amount == 5)

    _pass("test_trade_command_parsing")
```

## Balance Reference

### Research Costs & Times

| Category | Typical Gold Cost | Waves to Complete |
|----------|------------------|-------------------|
| Tier 1 | 50 | 2-3 |
| Tier 2 | 100 | 3-4 |
| Tier 3 | 200 | 5-6 |
| Tier 4 | 400 | 7-8 |

### Trade Rate Summary

| Trade | Base Rate | Example |
|-------|-----------|---------|
| Wood → Stone | 0.67 | 3 wood = 2 stone |
| Stone → Wood | 1.5 | 2 stone = 3 wood |
| Wood/Food | 1.0 | 1:1 exchange |
| Resources → Gold | 0.33-0.5 | 2-3 resources = 1 gold |
| Gold → Resources | 2.0-3.0 | 1 gold = 2-3 resources |

### Market Bonus Scaling

| Market Levels | Bonus |
|--------------|-------|
| L3 (1 market) | 15% |
| L3 + L2 | 25% |
| L3 + L3 | 30% (cap) |
