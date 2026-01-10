# Event & POI System Guide

This document explains the Point of Interest (POI) and Event systems in Keyboard Defense. Inspired by Super Fantasy Kingdom's exploration events, this system provides narrative choices and rewards during exploration.

## Overview

The POI/Event system provides emergent storytelling through discoverable locations that trigger interactive events:

```
Exploration → POI Spawn → Discovery → Event Trigger → Choice Selection → Effects Applied
     ↑                                                                           ↓
     └──────────────────────── Continue Game ←──────────────────────────────────┘
```

## Core Components

| Component | File | Purpose |
|-----------|------|---------|
| `SimPoi` | `sim/poi.gd` | POI spawning, filtering, discovery |
| `SimEvents` | `sim/events.gd` | Event triggering, choice resolution |
| `SimEventTables` | `sim/event_tables.gd` | Weighted event selection |
| `SimEventEffects` | `sim/event_effects.gd` | Effect application |

## POI System

### POI Data Structure

POIs are defined in `data/pois/pois.json`:

```json
{
  "pois": [
    {
      "id": "ancient_shrine",
      "name": "Ancient Shrine",
      "description": "A weathered stone shrine covered in moss.",
      "biome": "evergrove",
      "event_table_id": "shrine_events",
      "min_day": 1,
      "max_day": 999,
      "rarity": 30,
      "tags": ["sacred", "magic"]
    }
  ]
}
```

### POI Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Unique identifier |
| `name` | String | Display name |
| `description` | String | Flavor text |
| `biome` | String | Which biome this POI appears in |
| `event_table_id` | String | Links to event table for random event selection |
| `min_day` | int | Earliest day this can spawn |
| `max_day` | int | Latest day this can spawn |
| `rarity` | int | Weight for spawn chance (1-100) |
| `tags` | Array | Classification tags for filtering |

### POI State

Active POIs track runtime state:

```gdscript
# sim/poi.gd:112
state.active_pois[poi_id] = {
    "poi_id": poi_id,
    "pos": pos,           # Vector2i position on map
    "discovered": false,  # Has player seen it?
    "interacted": false   # Has player triggered event?
}
```

### POI Spawning

POIs spawn during exploration based on biome and rarity:

```gdscript
# sim/poi.gd:120
static func try_spawn_random_poi(state: GameState, biome: String, pos: Vector2i) -> String:
    var candidates: Array = get_pois_for_biome(biome)
    candidates = filter_by_day(candidates, state.day)
    var spawnable: Array = []
    for poi in candidates:
        if can_spawn_poi(state, poi):
            spawnable.append(poi)
    if spawnable.is_empty():
        return ""

    # Weighted random selection
    var total_weight: int = 0
    for poi in spawnable:
        total_weight += int(poi.get("rarity", 50))
    var roll: int = SimRng.roll_range(state, 1, total_weight)
    # ... select based on roll
```

### POI Spawn Validation

```gdscript
# sim/poi.gd:87
static func can_spawn_poi(state: GameState, poi: Dictionary) -> bool:
    var poi_id: String = str(poi.get("id", ""))
    if poi_id == "":
        return false
    # Already active
    if state.active_pois.has(poi_id):
        return false
    # Day range check
    var min_day: int = int(poi.get("min_day", 1))
    var max_day: int = int(poi.get("max_day", 999))
    if state.day < min_day or state.day > max_day:
        return false
    return true
```

### POI Discovery

POIs must be discovered before events trigger:

```gdscript
# sim/poi.gd:146
static func discover_poi(state: GameState, poi_id: String) -> bool:
    if not state.active_pois.has(poi_id):
        return false
    var poi_state: Dictionary = state.active_pois[poi_id]
    if poi_state.get("discovered", false):
        return false
    poi_state["discovered"] = true
    state.active_pois[poi_id] = poi_state
    return true
```

## Event System

### Event Data Structure

Events are defined in `data/events/events.json`:

```json
{
  "events": [
    {
      "id": "shrine_blessing",
      "name": "Shrine Blessing",
      "description": "The ancient shrine glows with a soft light...",
      "prompt": "Will you pray at the shrine?",
      "cooldown_days": 5,
      "choices": [
        {
          "id": "pray",
          "label": "Pray",
          "description": "Offer a prayer for protection.",
          "input": {
            "mode": "phrase",
            "text": "grant me strength"
          },
          "effects": [
            {"type": "buff_apply", "buff": "blessed", "duration": 3}
          ],
          "fail_effects": []
        },
        {
          "id": "leave",
          "label": "Leave",
          "description": "This place feels unsettling.",
          "input": {
            "mode": "code",
            "text": "leave"
          },
          "effects": []
        }
      ]
    }
  ]
}
```

### Event Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Unique identifier |
| `name` | String | Display title |
| `description` | String | Narrative text |
| `prompt` | String | Question presented to player |
| `cooldown_days` | int | Days before event can trigger again |
| `choices` | Array | Available player choices |

### Choice Structure

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Unique choice ID |
| `label` | String | Button/option text |
| `description` | String | Explanation text |
| `input` | Dictionary | Input validation config |
| `effects` | Array | Effects applied on success |
| `fail_effects` | Array | Effects applied on failure |
| `next_event_id` | String | Chain to another event (optional) |

### Input Modes

```gdscript
# sim/events.gd:109
static func validate_input(choice: Dictionary, input_text: String) -> Dictionary:
    var mode: String = str(input_config.get("mode", "code"))
    match mode:
        "code":
            # Single keyword match
            var expected: String = str(input_config.get("text", "")).to_lower()
            var actual: String = input_text.to_lower().strip_edges()
            return {"valid": actual == expected, "complete": actual == expected}

        "phrase":
            # Full phrase match
            var expected: String = str(input_config.get("text", "")).to_lower()
            return {"valid": actual == expected, "complete": actual == expected}

        "prompt_burst":
            # Multiple word sequence
            var prompts: Array = input_config.get("prompts", [])
            var typed_words: Array = input_text.split(" ", false)
            var matched: int = 0
            for i in range(min(typed_words.size(), prompts.size())):
                if typed_words[i].to_lower() == str(prompts[i]).to_lower():
                    matched += 1
            return {"valid": matched == prompts.size(), "matched": matched}

        "command":
            # Command-style input
            var expected: String = str(input_config.get("text", "")).to_lower()
            return {"valid": actual == expected, "complete": actual == expected}
```

### Input Mode Examples

| Mode | Config | Valid Input |
|------|--------|-------------|
| `code` | `{"text": "accept"}` | "accept", "ACCEPT" |
| `phrase` | `{"text": "grant me strength"}` | "grant me strength" |
| `prompt_burst` | `{"prompts": ["fire", "ice", "wind"]}` | "fire ice wind" |
| `command` | `{"text": "flee"}` | "flee" |

## Event Triggering

### From POI

```gdscript
# sim/events.gd:52
static func trigger_event_from_poi(state: GameState, poi_id: String) -> Dictionary:
    var poi_data: Dictionary = SimPoi.get_poi(poi_id)
    if poi_data.is_empty():
        return {"success": false, "error": "poi_not_found"}

    var table_id: String = str(poi_data.get("event_table_id", ""))
    if table_id == "":
        return {"success": false, "error": "no_event_table"}

    var event_id: String = SimEventTables.select_event(state, table_id)
    if event_id == "":
        return {"success": false, "error": "no_valid_event"}

    return start_event(state, event_id, poi_id)
```

### Starting an Event

```gdscript
# sim/events.gd:64
static func start_event(state: GameState, event_id: String, source_poi: String = "") -> Dictionary:
    var event_data: Dictionary = get_event(event_id)
    if event_data.is_empty():
        return {"success": false, "error": "event_not_found"}

    state.pending_event = {
        "event_id": event_id,
        "source_poi": source_poi,
        "started_day": state.day,
        "choice_index": -1,
        "input_progress": "",
        "resolved": false
    }
    return {"success": true, "event_id": event_id, "event": event_data}
```

### Pending Event State

```gdscript
state.pending_event = {
    "event_id": "shrine_blessing",  # Which event
    "source_poi": "ancient_shrine", # Where it came from
    "started_day": 5,               # When started
    "choice_index": -1,             # Selected choice (-1 = none)
    "input_progress": "",           # Partial input
    "resolved": false               # Completed?
}
```

## Event Tables

Event tables provide weighted random event selection with conditions.

### Table Structure

```json
{
  "tables": [
    {
      "id": "shrine_events",
      "conditions": [],
      "entries": [
        {
          "event_id": "shrine_blessing",
          "weight": 50,
          "conditions": [
            {"type": "day_range", "min": 1, "max": 10}
          ]
        },
        {
          "event_id": "shrine_curse",
          "weight": 20,
          "conditions": [
            {"type": "day_range", "min": 5, "max": 999}
          ]
        }
      ]
    }
  ]
}
```

### Condition Types

```gdscript
# sim/event_tables.gd:43
static func check_conditions(state: GameState, conditions: Array) -> bool:
    for condition in conditions:
        var cond_type: String = str(condition.get("type", ""))
        match cond_type:
            "day_range":
                var min_day: int = int(condition.get("min", 1))
                var max_day: int = int(condition.get("max", 999))
                if state.day < min_day or state.day > max_day:
                    return false

            "resource_min":
                var resource: String = str(condition.get("resource", ""))
                var min_amount: int = int(condition.get("amount", 0))
                var current: int = int(state.resources.get(resource, 0))
                if current < min_amount:
                    return false

            "flag_set":
                var flag: String = str(condition.get("flag", ""))
                var expected: bool = bool(condition.get("value", true))
                var actual: bool = bool(state.event_flags.get(flag, false))
                if actual != expected:
                    return false

            "flag_not_set":
                var flag: String = str(condition.get("flag", ""))
                if state.event_flags.has(flag) and bool(state.event_flags[flag]):
                    return false
    return true
```

### Condition Examples

| Type | Config | Passes When |
|------|--------|-------------|
| `day_range` | `{"min": 5, "max": 15}` | Day 5-15 |
| `resource_min` | `{"resource": "gold", "amount": 50}` | Gold >= 50 |
| `flag_set` | `{"flag": "met_elder", "value": true}` | Flag is true |
| `flag_not_set` | `{"flag": "shrine_cursed"}` | Flag not set |

### Cooldown System

Events have cooldown periods:

```gdscript
# sim/event_tables.gd:72
static func is_event_on_cooldown(state: GameState, event_id: String) -> bool:
    if not state.event_cooldowns.has(event_id):
        return false
    var cooldown_until: int = int(state.event_cooldowns[event_id])
    return state.day < cooldown_until

# sim/event_tables.gd:121
static func set_cooldown(state: GameState, event_id: String, cooldown_days: int) -> void:
    if cooldown_days <= 0:
        return
    state.event_cooldowns[event_id] = state.day + cooldown_days
```

## Event Effects

### Effect Types

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
        "heal_castle":
            return apply_heal_castle(state, effect)
        "set_flag":
            return apply_set_flag(state, effect)
        "clear_flag":
            return apply_clear_flag(state, effect)
        "threat_add":
            return apply_threat_add(state, effect)
        "ap_add":
            return apply_ap_add(state, effect)
```

### Effect Reference

| Type | Parameters | Example |
|------|------------|---------|
| `resource_add` | `resource`, `amount` | `{"type": "resource_add", "resource": "wood", "amount": 10}` |
| `buff_apply` | `buff`, `duration` | `{"type": "buff_apply", "buff": "blessed", "duration": 3}` |
| `damage_castle` | `amount` | `{"type": "damage_castle", "amount": 2}` |
| `heal_castle` | `amount`, `max_hp` | `{"type": "heal_castle", "amount": 1, "max_hp": 10}` |
| `set_flag` | `flag`, `value` | `{"type": "set_flag", "flag": "met_elder", "value": true}` |
| `clear_flag` | `flag` | `{"type": "clear_flag", "flag": "shrine_visited"}` |
| `threat_add` | `amount` | `{"type": "threat_add", "amount": 10}` |
| `ap_add` | `amount` | `{"type": "ap_add", "amount": 2}` |

### Buff System

```gdscript
# sim/event_effects.gd:53
static func apply_buff(state: GameState, effect: Dictionary) -> Dictionary:
    var buff_id: String = str(effect.get("buff", ""))
    var duration: int = int(effect.get("duration", 1))

    var buff_data: Dictionary = {
        "buff_id": buff_id,
        "expires_day": state.day + duration,
        "applied_day": state.day
    }

    # Check for existing buff to refresh
    var found_index: int = -1
    for i in range(state.active_buffs.size()):
        if str(state.active_buffs[i].get("buff_id", "")) == buff_id:
            found_index = i
            break

    if found_index >= 0:
        state.active_buffs[found_index] = buff_data  # Refresh
    else:
        state.active_buffs.append(buff_data)  # Add new
```

### Flag System

Flags track persistent event outcomes:

```gdscript
# Set a flag
state.event_flags["met_elder"] = true

# Check a flag
if state.event_flags.get("shrine_blessed", false):
    # Player has received shrine blessing

# Clear a flag
state.event_flags.erase("temporary_curse")
```

## Choice Resolution

### Success Path

```gdscript
# sim/events.gd:153
static func resolve_choice(state: GameState, choice_id: String, input_text: String) -> Dictionary:
    if not has_pending_event(state):
        return {"success": false, "error": "no_pending_event"}

    var event_data: Dictionary = get_pending_event(state)
    var choice: Dictionary = get_choice(event_data, choice_id)
    var validation: Dictionary = validate_input(choice, input_text)

    if not validation.get("complete", false):
        return {"success": false, "error": "input_incomplete", "validation": validation}

    # Apply effects
    var effects: Array = choice.get("effects", [])
    var results: Array = SimEventEffects.apply_effects(state, effects)

    # Set cooldown
    var cooldown: int = int(event_data.get("cooldown_days", 0))
    SimEventTables.set_cooldown(state, event_id, cooldown)

    # Mark POI as interacted
    var source_poi: String = str(state.pending_event.get("source_poi", ""))
    if source_poi != "" and state.active_pois.has(source_poi):
        state.active_pois[source_poi]["interacted"] = true

    # Handle chain events
    var next_event_id: String = str(choice.get("next_event_id", ""))
    if next_event_id != "":
        start_event(state, next_event_id, source_poi)
    else:
        state.pending_event = {}

    return {"success": true, "effects_applied": results}
```

### Failure Path

```gdscript
# sim/events.gd:197
static func fail_choice(state: GameState, choice_id: String) -> Dictionary:
    var choice: Dictionary = get_choice(event_data, choice_id)

    # Apply fail effects instead of success effects
    var fail_effects: Array = choice.get("fail_effects", [])
    var results: Array = SimEventEffects.apply_effects(state, fail_effects)

    state.pending_event = {}
    return {"success": true, "failed": true, "effects_applied": results}
```

### Skip Event

```gdscript
# sim/events.gd:220
static func skip_event(state: GameState) -> Dictionary:
    state.pending_event = {}
    return {"success": true, "skipped": true}
```

## Event Chaining

Events can trigger follow-up events:

```json
{
  "id": "elder_quest_start",
  "choices": [
    {
      "id": "accept",
      "label": "Accept the Quest",
      "effects": [{"type": "set_flag", "flag": "elder_quest_active"}],
      "next_event_id": "elder_quest_details"
    }
  ]
}
```

## Integration Flow

### Complete POI → Event Flow

```
1. Player explores tile
   └── SimPoi.try_spawn_random_poi(state, biome, pos)
       └── Filters by biome, day, already-spawned
       └── Weighted random selection
       └── spawn_poi_at() → adds to state.active_pois

2. Player moves to POI tile
   └── SimPoi.get_poi_at(state, pos) → returns poi_id
   └── SimPoi.discover_poi(state, poi_id) → sets discovered=true

3. Player interacts with POI
   └── SimEvents.trigger_event_from_poi(state, poi_id)
       └── Gets event_table_id from POI
       └── SimEventTables.select_event() → weighted roll
       └── start_event() → sets state.pending_event

4. UI displays event
   └── SimEvents.get_pending_event(state) → event data
   └── Render description, choices, input fields

5. Player makes choice
   └── SimEvents.resolve_choice(state, choice_id, input)
       └── validate_input() → check typing
       └── apply_effects() → modify state
       └── set_cooldown() → prevent repeat
       └── Handle chain events or clear pending

6. Game continues
   └── POI marked interacted
   └── Buffs expire over time
   └── Cooldowns tick down
```

## Adding New POIs

### Step 1: Define POI

```json
// data/pois/pois.json
{
  "id": "abandoned_tower",
  "name": "Abandoned Tower",
  "description": "A crumbling watchtower from a forgotten age.",
  "biome": "stonepass",
  "event_table_id": "tower_events",
  "min_day": 3,
  "max_day": 999,
  "rarity": 25,
  "tags": ["ruin", "exploration"]
}
```

### Step 2: Create Event Table

```json
// data/events/event_tables.json
{
  "id": "tower_events",
  "conditions": [],
  "entries": [
    {"event_id": "tower_treasure", "weight": 40},
    {"event_id": "tower_ambush", "weight": 30},
    {"event_id": "tower_ghost", "weight": 20, "conditions": [{"type": "day_range", "min": 7}]}
  ]
}
```

### Step 3: Create Events

```json
// data/events/events.json
{
  "id": "tower_treasure",
  "name": "Hidden Cache",
  "description": "You find a hidden compartment in the tower floor...",
  "prompt": "Do you open it?",
  "cooldown_days": 10,
  "choices": [
    {
      "id": "open",
      "label": "Open",
      "input": {"mode": "code", "text": "open"},
      "effects": [
        {"type": "resource_add", "resource": "gold", "amount": 25},
        {"type": "resource_add", "resource": "wood", "amount": 5}
      ]
    },
    {
      "id": "leave",
      "label": "Leave it alone",
      "input": {"mode": "code", "text": "leave"},
      "effects": []
    }
  ]
}
```

## Common Patterns

### Check for Pending Event

```gdscript
if SimEvents.has_pending_event(state):
    var event = SimEvents.get_pending_event(state)
    # Display event UI
```

### Get POI at Cursor

```gdscript
var poi_id = SimPoi.get_poi_at(state, state.cursor_pos)
if poi_id != "":
    var poi_data = SimPoi.get_poi(poi_id)
    # Show POI info
```

### List Discovered POIs

```gdscript
var discovered = SimPoi.get_discovered_pois(state)
for poi_id in discovered:
    var poi_data = SimPoi.get_poi(poi_id)
    print("%s at %s" % [poi_data.name, state.active_pois[poi_id].pos])
```

### Check Active Buff

```gdscript
if SimEventEffects.has_buff(state, "blessed"):
    var remaining = SimEventEffects.get_buff_remaining_days(state, "blessed")
    print("Blessed for %d more days" % remaining)
```

### Daily Buff Expiration

```gdscript
# Call at start of each day
var expired = SimEventEffects.expire_buffs(state)
for buff_id in expired:
    events.append("The %s effect has worn off." % buff_id)
```

## Testing Events

### Test POI Spawn

```gdscript
func test_poi_spawn():
    var state = GameState.new()
    state.day = 5
    var poi_id = SimPoi.try_spawn_random_poi(state, "evergrove", Vector2i(5, 5))
    assert(poi_id != "" or SimPoi.get_pois_for_biome("evergrove").is_empty())
    _pass("test_poi_spawn")
```

### Test Event Trigger

```gdscript
func test_event_trigger():
    var state = GameState.new()
    SimPoi.spawn_poi_at(state, "ancient_shrine", Vector2i(3, 3))
    SimPoi.discover_poi(state, "ancient_shrine")
    var result = SimEvents.trigger_event_from_poi(state, "ancient_shrine")
    assert(result.success or result.error == "no_valid_event")
    _pass("test_event_trigger")
```

### Test Choice Resolution

```gdscript
func test_choice_resolution():
    var state = GameState.new()
    SimEvents.start_event(state, "shrine_blessing", "")
    var result = SimEvents.resolve_choice(state, "pray", "grant me strength")
    assert(result.success)
    assert(SimEventEffects.has_buff(state, "blessed"))
    _pass("test_choice_resolution")
```
