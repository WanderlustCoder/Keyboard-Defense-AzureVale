# Event Effects Guide

This document explains the event effects system that applies consequences from events, choices, and game mechanics to the game state.

## Overview

The event effects system provides a unified way to apply various effects:

```
Event Choice → Effect Array → apply_effects() → State Changes + Results
      ↓              ↓              ↓                    ↓
  "reward"    [{type, params}]   dispatch         [{type, old, new}]
```

## Effect Types

| Type | Description | Parameters |
|------|-------------|------------|
| `resource_add` | Add/remove resources | resource, amount |
| `buff_apply` | Apply timed buff | buff, duration |
| `damage_castle` | Deal damage to castle | amount |
| `heal_castle` | Heal castle HP | amount, max_hp |
| `threat_add` | Modify threat level | amount |
| `ap_add` | Add action points | amount |
| `set_flag` | Set event flag | flag, value |
| `clear_flag` | Remove event flag | flag |

## Applying Effects

### Batch Application

```gdscript
# sim/event_effects.gd:6
static func apply_effects(state: GameState, effects: Array) -> Array:
    var results: Array = []
    for effect in effects:
        if typeof(effect) != TYPE_DICTIONARY:
            continue
        var result: Dictionary = apply_effect(state, effect)
        results.append(result)
    return results
```

### Single Effect Dispatch

```gdscript
# sim/event_effects.gd:15
static func apply_effect(state: GameState, effect: Dictionary) -> Dictionary:
    var effect_type: String = str(effect.get("type", ""))
    match effect_type:
        "resource_add":
            return apply_resource_add(state, effect)
        "buff_apply":
            return apply_buff(state, effect)
        "damage_castle":
            return apply_damage_castle(state, effect)
        "set_flag":
            return apply_set_flag(state, effect)
        "clear_flag":
            return apply_clear_flag(state, effect)
        "heal_castle":
            return apply_heal_castle(state, effect)
        "threat_add":
            return apply_threat_add(state, effect)
        "ap_add":
            return apply_ap_add(state, effect)
        _:
            return {"type": effect_type, "error": "unknown_effect_type"}
```

## Effect Implementations

### Resource Add

```gdscript
# sim/event_effects.gd:37
static func apply_resource_add(state: GameState, effect: Dictionary) -> Dictionary:
    var resource: String = str(effect.get("resource", ""))
    var amount: int = int(effect.get("amount", 0))
    if resource == "" or not resource in GameState.RESOURCE_KEYS:
        return {"type": "resource_add", "error": "invalid_resource", "resource": resource}
    var old_value: int = int(state.resources.get(resource, 0))
    var new_value: int = max(0, old_value + amount)
    state.resources[resource] = new_value
    return {
        "type": "resource_add",
        "resource": resource,
        "amount": amount,
        "old_value": old_value,
        "new_value": new_value
    }
```

**Input:**
```gdscript
{"type": "resource_add", "resource": "wood", "amount": 10}
{"type": "resource_add", "resource": "food", "amount": -5}  # Negative = remove
```

### Buff Apply

```gdscript
# sim/event_effects.gd:53
static func apply_buff(state: GameState, effect: Dictionary) -> Dictionary:
    var buff_id: String = str(effect.get("buff", ""))
    var duration: int = int(effect.get("duration", 1))

    # Check if buff already exists (refresh duration)
    var found_index: int = -1
    for i in range(state.active_buffs.size()):
        var existing: Dictionary = state.active_buffs[i]
        if str(existing.get("buff_id", "")) == buff_id:
            found_index = i
            break

    var buff_data: Dictionary = {
        "buff_id": buff_id,
        "expires_day": state.day + duration,
        "applied_day": state.day
    }

    if found_index >= 0:
        state.active_buffs[found_index] = buff_data
        return {"type": "buff_apply", "buff_id": buff_id, "duration": duration, "refreshed": true}
    else:
        state.active_buffs.append(buff_data)
        return {"type": "buff_apply", "buff_id": buff_id, "duration": duration, "refreshed": false}
```

**Input:**
```gdscript
{"type": "buff_apply", "buff": "production_boost", "duration": 3}
```

**Buff Data Structure:**
```gdscript
{
    "buff_id": "production_boost",
    "expires_day": 8,    # Current day + duration
    "applied_day": 5     # When applied
}
```

### Damage Castle

```gdscript
# sim/event_effects.gd:88
static func apply_damage_castle(state: GameState, effect: Dictionary) -> Dictionary:
    var amount: int = int(effect.get("amount", 1))
    var old_hp: int = state.hp
    state.hp = max(0, state.hp - amount)
    return {
        "type": "damage_castle",
        "amount": amount,
        "old_hp": old_hp,
        "new_hp": state.hp
    }
```

### Heal Castle

```gdscript
# sim/event_effects.gd:99
static func apply_heal_castle(state: GameState, effect: Dictionary) -> Dictionary:
    var amount: int = int(effect.get("amount", 1))
    var max_hp: int = int(effect.get("max_hp", 10))
    var old_hp: int = state.hp
    state.hp = min(max_hp, state.hp + amount)
    return {
        "type": "heal_castle",
        "amount": amount,
        "old_hp": old_hp,
        "new_hp": state.hp
    }
```

### Threat Add

```gdscript
# sim/event_effects.gd:138
static func apply_threat_add(state: GameState, effect: Dictionary) -> Dictionary:
    var amount: int = int(effect.get("amount", 1))
    var old_threat: int = state.threat
    state.threat = max(0, state.threat + amount)
    return {
        "type": "threat_add",
        "amount": amount,
        "old_threat": old_threat,
        "new_threat": state.threat
    }
```

### AP Add

```gdscript
# sim/event_effects.gd:149
static func apply_ap_add(state: GameState, effect: Dictionary) -> Dictionary:
    var amount: int = int(effect.get("amount", 1))
    var old_ap: int = state.ap
    state.ap = clamp(state.ap + amount, 0, state.ap_max)
    return {
        "type": "ap_add",
        "amount": amount,
        "old_ap": old_ap,
        "new_ap": state.ap
    }
```

### Set/Clear Flags

```gdscript
# sim/event_effects.gd:111
static func apply_set_flag(state: GameState, effect: Dictionary) -> Dictionary:
    var flag: String = str(effect.get("flag", ""))
    var value: Variant = effect.get("value", true)
    var old_value: Variant = state.event_flags.get(flag, null)
    state.event_flags[flag] = value
    return {
        "type": "set_flag",
        "flag": flag,
        "value": value,
        "old_value": old_value
    }

static func apply_clear_flag(state: GameState, effect: Dictionary) -> Dictionary:
    var flag: String = str(effect.get("flag", ""))
    var had_flag: bool = state.event_flags.has(flag)
    if had_flag:
        state.event_flags.erase(flag)
    return {
        "type": "clear_flag",
        "flag": flag,
        "removed": had_flag
    }
```

## Buff Management

### Check Active Buff

```gdscript
# sim/event_effects.gd:160
static func has_buff(state: GameState, buff_id: String) -> bool:
    for buff in state.active_buffs:
        if str(buff.get("buff_id", "")) == buff_id:
            if int(buff.get("expires_day", 0)) > state.day:
                return true
    return false
```

### Get Remaining Duration

```gdscript
# sim/event_effects.gd:169
static func get_buff_remaining_days(state: GameState, buff_id: String) -> int:
    for buff in state.active_buffs:
        if str(buff.get("buff_id", "")) == buff_id:
            var expires: int = int(buff.get("expires_day", 0))
            if expires > state.day:
                return expires - state.day
    return 0
```

### Expire Buffs

```gdscript
# sim/event_effects.gd:179
static func expire_buffs(state: GameState) -> Array:
    var expired: Array = []
    var remaining: Array = []
    for buff in state.active_buffs:
        var expires: int = int(buff.get("expires_day", 0))
        if state.day >= expires:
            expired.append(str(buff.get("buff_id", "")))
        else:
            remaining.append(buff)
    state.active_buffs = remaining
    return expired  # List of expired buff IDs
```

### Get Active Buffs

```gdscript
# sim/event_effects.gd:193
static func get_active_buffs(state: GameState) -> Array:
    var result: Array = []
    for buff in state.active_buffs:
        if int(buff.get("expires_day", 0)) > state.day:
            result.append(buff)
    return result
```

## Buff Serialization

```gdscript
# sim/event_effects.gd:202
static func serialize_buffs(buffs: Array) -> Array:
    var result: Array = []
    for buff in buffs:
        result.append({
            "buff_id": str(buff.get("buff_id", "")),
            "expires_day": int(buff.get("expires_day", 0)),
            "applied_day": int(buff.get("applied_day", 0))
        })
    return result

static func deserialize_buffs(raw: Array) -> Array:
    var result: Array = []
    for item in raw:
        result.append({
            "buff_id": str(item.get("buff_id", "")),
            "expires_day": int(item.get("expires_day", 0)),
            "applied_day": int(item.get("applied_day", 0))
        })
    return result
```

## Integration Examples

### Event Choice Handler

```gdscript
func apply_event_choice(state: GameState, choice: Dictionary) -> Array[String]:
    var effects: Array = choice.get("effects", [])
    var results: Array = SimEventEffects.apply_effects(state, effects)

    var messages: Array[String] = []
    for result in results:
        match result.type:
            "resource_add":
                var sign: String = "+" if result.amount > 0 else ""
                messages.append("%s%d %s" % [sign, result.amount, result.resource])
            "buff_apply":
                if result.refreshed:
                    messages.append("Refreshed %s buff." % result.buff_id)
                else:
                    messages.append("Gained %s for %d days." % [result.buff_id, result.duration])
            "damage_castle":
                messages.append("Castle took %d damage!" % result.amount)

    return messages
```

### Day Start Buff Processing

```gdscript
func process_day_start(state: GameState) -> void:
    # Expire old buffs
    var expired: Array = SimEventEffects.expire_buffs(state)
    for buff_id in expired:
        _show_message("%s effect has worn off." % buff_id)

    # Apply buff effects to production
    if SimEventEffects.has_buff(state, "production_boost"):
        _production_modifier = 1.25
    else:
        _production_modifier = 1.0
```

### Building Effect JSON

```gdscript
# Example effect arrays in data files:
var reward_effects: Array = [
    {"type": "resource_add", "resource": "gold", "amount": 50},
    {"type": "buff_apply", "buff": "morale_boost", "duration": 2}
]

var penalty_effects: Array = [
    {"type": "resource_add", "resource": "food", "amount": -10},
    {"type": "threat_add", "amount": 2}
]

var healing_effects: Array = [
    {"type": "heal_castle", "amount": 3, "max_hp": 10},
    {"type": "ap_add", "amount": 1}
]
```

## Testing

```gdscript
func test_resource_add():
    var state := GameState.new()
    state.resources["wood"] = 10

    var effect := {"type": "resource_add", "resource": "wood", "amount": 5}
    var result := SimEventEffects.apply_effect(state, effect)

    assert(result.type == "resource_add")
    assert(result.old_value == 10)
    assert(result.new_value == 15)
    assert(state.resources["wood"] == 15)

    _pass("test_resource_add")

func test_buff_lifecycle():
    var state := GameState.new()
    state.day = 5

    # Apply buff
    var effect := {"type": "buff_apply", "buff": "test_buff", "duration": 3}
    SimEventEffects.apply_effect(state, effect)

    assert(SimEventEffects.has_buff(state, "test_buff"))
    assert(SimEventEffects.get_buff_remaining_days(state, "test_buff") == 3)

    # Advance time
    state.day = 7
    assert(SimEventEffects.get_buff_remaining_days(state, "test_buff") == 1)

    # Expire
    state.day = 8
    var expired := SimEventEffects.expire_buffs(state)
    assert(expired.has("test_buff"))
    assert(not SimEventEffects.has_buff(state, "test_buff"))

    _pass("test_buff_lifecycle")

func test_batch_effects():
    var state := GameState.new()
    state.resources["wood"] = 0
    state.hp = 10

    var effects := [
        {"type": "resource_add", "resource": "wood", "amount": 20},
        {"type": "damage_castle", "amount": 2},
        {"type": "set_flag", "flag": "quest_started", "value": true}
    ]

    var results := SimEventEffects.apply_effects(state, effects)

    assert(results.size() == 3)
    assert(state.resources["wood"] == 20)
    assert(state.hp == 8)
    assert(state.event_flags.has("quest_started"))

    _pass("test_batch_effects")
```
