# Command Pipeline Guide

This document explains how user input flows through the command system from text entry to state modification.

## Pipeline Overview

```
User types "build farm 5 3"
         │
         ▼
    ┌─────────────────┐
    │  CommandParser  │  sim/parse_command.gd
    │    .parse()     │
    └────────┬────────┘
             │ Returns: {ok: true, intent: {...}}
             ▼
    ┌─────────────────┐
    │  IntentApplier  │  sim/apply_intent.gd
    │    .apply()     │
    └────────┬────────┘
             │ Returns: {state: ..., events: [...]}
             ▼
    ┌─────────────────┐
    │   game/main.gd  │  Renders state, shows events
    │  _render_state  │
    └─────────────────┘
```

## Stage 1: Parsing (`sim/parse_command.gd`)

### Input/Output

```gdscript
# Input: raw text string
var result = CommandParser.parse("build farm 5 3")

# Output on success:
{
    "ok": true,
    "intent": {
        "kind": "build",
        "building": "farm",
        "x": 5,
        "y": 3
    }
}

# Output on failure:
{
    "ok": false,
    "error": "Usage: build <type> [x y]"
}
```

### Parser Structure

```gdscript
static func parse(command: String) -> Dictionary:
    var trimmed = command.strip_edges()
    if trimmed.is_empty():
        return {"ok": false, "error": "Enter a command..."}

    var tokens = trimmed.split(" ", false)
    var verb = tokens[0].to_lower()

    match verb:
        "build":
            return _parse_build(tokens)
        "gather":
            return _parse_gather(tokens)
        # ... more commands ...
        _:
            return {"ok": false, "error": "Unknown command: %s" % verb}
```

### Adding a New Command (Parser)

1. Add keyword to `sim/command_keywords.gd`:

```gdscript
const KEYWORDS: Array[String] = [
    # ... existing ...
    "newcmd",
]
```

2. Add match case in `parse_command.gd`:

```gdscript
match verb:
    # ... existing cases ...
    "newcmd":
        if tokens.size() < 2:
            return {"ok": false, "error": "Usage: newcmd <param>"}
        var param = tokens[1]
        return {"ok": true, "intent": SimIntents.make("new_command", {"param": param})}
```

## Stage 2: Intent Creation (`sim/intents.gd`)

### Intent Structure

Intents are dictionaries with a required `kind` field:

```gdscript
static func make(kind: String, data: Dictionary = {}) -> Dictionary:
    var intent = {"kind": kind}
    for key in data.keys():
        intent[key] = data[key]
    return intent

# Example intents:
{"kind": "build", "building": "farm", "x": 5, "y": 3}
{"kind": "gather", "resource": "wood", "amount": 10}
{"kind": "defend_input", "text": "goblin"}
{"kind": "cursor_move", "dx": 1, "dy": 0, "steps": 1}
```

### Help Lines

Document commands in `help_lines()`:

```gdscript
static func help_lines() -> Array[String]:
    return [
        "Commands:",
        "  help - list commands",
        "  newcmd <param> - description of new command",
        # ...
    ]
```

## Stage 3: Application (`sim/apply_intent.gd`)

### Application Structure

```gdscript
static func apply(state: GameState, intent: Dictionary) -> Dictionary:
    var events: Array[String] = []
    var new_state = _copy_state(state)  # Copy first!
    var request: Dictionary = {}
    var kind = str(intent.get("kind", ""))

    match kind:
        "build":
            _apply_build(new_state, intent, events)
        "gather":
            _apply_gather(new_state, intent, events)
        # ... more handlers ...
        _:
            events.append("Unknown intent: %s" % kind)

    var result = {"state": new_state, "events": events}
    if not request.is_empty():
        result["request"] = request
    return result
```

### Handler Pattern

Each intent has a handler function:

```gdscript
static func _apply_gather(state: GameState, intent: Dictionary, events: Array[String]) -> void:
    # 1. Validate phase
    if not _require_day(state, events):
        return

    # 2. Consume resources (AP, materials, etc.)
    if not _consume_ap(state, events):
        return

    # 3. Extract intent parameters
    var resource = str(intent.get("resource", ""))
    var amount = int(intent.get("amount", 0))

    # 4. Validate parameters
    if not state.resources.has(resource) or amount <= 0:
        events.append("Invalid gather request.")
        return

    # 5. Apply effect
    state.resources[resource] += amount

    # 6. Report result
    events.append("Gathered %d %s." % [amount, resource])
```

### Adding a New Command (Handler)

Add handler in `apply_intent.gd`:

```gdscript
# In apply() match statement:
"new_command":
    _apply_new_command(new_state, intent, events)

# Handler function:
static func _apply_new_command(state: GameState, intent: Dictionary, events: Array[String]) -> void:
    # Validate
    if not _require_day(state, events):
        return

    # Get parameters
    var param = str(intent.get("param", ""))

    # Do the thing
    # ... modify state ...

    # Report
    events.append("Did the thing with %s." % param)
```

## Helper Functions

### Phase Requirements

```gdscript
# Day phase only
static func _require_day(state: GameState, events: Array[String]) -> bool:
    if state.phase != "day":
        events.append("That action is only available during the day.")
        return false
    return true

# Day or game over (for lesson changes)
static func _require_day_or_game_over(state: GameState, events: Array[String]) -> bool:
    if state.phase != "day" and state.phase != "game_over":
        events.append("Lesson changes are only available during the day or after game over.")
        return false
    return true
```

### Resource Handling

```gdscript
# Consume action point
static func _consume_ap(state: GameState, events: Array[String]) -> bool:
    if state.ap <= 0:
        events.append("No AP left.")
        return false
    state.ap -= 1
    return true

# Check resource availability
static func _has_resources(state: GameState, cost: Dictionary) -> bool:
    for key in cost.keys():
        if int(state.resources.get(key, 0)) < int(cost[key]):
            return false
    return true

# Deduct resources
static func _apply_cost(state: GameState, cost: Dictionary) -> void:
    for key in cost.keys():
        state.resources[key] = int(state.resources.get(key, 0)) - int(cost[key])
```

### Position Handling

```gdscript
# Get position from intent (explicit or cursor)
static func _intent_position(state: GameState, intent: Dictionary) -> Vector2i:
    if intent.has("x") and intent.has("y"):
        return Vector2i(int(intent.x), int(intent.y))
    return state.cursor_pos
```

## Request System

Some intents trigger side effects via requests:

```gdscript
# In apply()
match kind:
    "end":
        if _apply_end(new_state, events):
            request = {"kind": "autosave", "reason": "night"}
    "save":
        request = {"kind": "save"}
    "load":
        request = {"kind": "load"}

# Return with request
var result = {"state": new_state, "events": events}
if not request.is_empty():
    result["request"] = request
return result
```

### Request Types

| Request Kind | Triggered By | Handled In |
|-------------|--------------|------------|
| `autosave` | End day, dawn | `game/main.gd` |
| `save` | Save command | `game/persistence.gd` |
| `load` | Load command | `game/persistence.gd` |

## Stage 4: Rendering (`game/main.gd`)

### Processing Results

```gdscript
func _on_command_submitted(text: String) -> void:
    var parse_result = CommandParser.parse(text)

    if not parse_result.ok:
        _log(parse_result.error)
        return

    var intent = parse_result.intent
    var result = IntentApplier.apply(state, intent)

    # Update state
    state = result.state

    # Show events
    for event in result.events:
        _log(event)

    # Handle requests
    if result.has("request"):
        _handle_request(result.request)

    # Render new state
    _render_state()
```

### Event Display

Events are strings displayed in the game log:

```gdscript
func _log(message: String) -> void:
    log_label.text += "\n" + message
```

## UI-Only Intents

Some intents don't modify game state, only trigger UI:

```gdscript
"ui_preview":
    var building = str(intent.get("building", ""))
    events.append("Build preview set to: %s (UI-only)." % building)
    # No state modification, just a message

"ui_overlay":
    var overlay_name = str(intent.get("name", ""))
    var enabled = bool(intent.get("enabled", false))
    events.append("%s overlay: %s (UI-only)." % [overlay_name, enabled])
```

## Night Phase Input Routing

During night phase, input is routed specially:

```gdscript
# In game/main.gd
func _on_command_submitted(text: String) -> void:
    var parse_result = CommandParser.parse(text)

    if state.phase == "night":
        # Route through typing feedback
        var route = SimTypingFeedback.route_night_input(
            parse_result.ok,
            parse_result.intent.get("kind", "") if parse_result.ok else "",
            text,
            state.enemies
        )

        match route.action:
            "command":
                # Process as normal command
                _process_intent(parse_result.intent)
            "defend":
                # Convert to defend intent
                var intent = SimIntents.make("defend_input", {"text": text})
                _process_intent(intent)
            "incomplete":
                # Keep typing, show partial match feedback
                _update_typing_feedback(route.candidates)
```

## Complete Command Flow Example

```
User types: "build tower 8 5"

1. CommandParser.parse("build tower 8 5")
   → Tokenize: ["build", "tower", "8", "5"]
   → Validate: "tower" is valid building
   → Validate: 8, 5 are integers
   → Return: {ok: true, intent: {kind: "build", building: "tower", x: 8, y: 5}}

2. IntentApplier.apply(state, intent)
   → _copy_state(state)
   → Match "build" → _apply_build()
   → _require_day() → true
   → _intent_position() → Vector2i(8, 5)
   → Validate bounds, discovered, not occupied
   → _has_resources() → true
   → _consume_ap() → true
   → _apply_cost()
   → state.structures[index] = "tower"
   → events.append("Built tower at (8,5).")
   → Return: {state: modified, events: [...]}

3. game/main.gd
   → state = result.state
   → _log("Built tower at (8,5).")
   → _render_state()
   → Tower appears on grid
```

## Debugging Commands

```gdscript
# Add debug output
print("Parse: ", CommandParser.parse("build farm"))
print("Intent: ", intent)
print("Events: ", result.events)

# Test specific intent
var test_intent = SimIntents.make("build", {"building": "farm"})
var test_result = IntentApplier.apply(state, test_intent)
print("Test result: ", test_result.events)
```

## Checklist for New Commands

1. **sim/command_keywords.gd**
   - [ ] Add keyword to `KEYWORDS` array

2. **sim/intents.gd**
   - [ ] Add to `help_lines()`

3. **sim/parse_command.gd**
   - [ ] Add match case
   - [ ] Validate token count
   - [ ] Parse and validate parameters
   - [ ] Return intent dictionary

4. **sim/apply_intent.gd**
   - [ ] Add match case in `apply()`
   - [ ] Create handler function `_apply_X()`
   - [ ] Validate phase requirements
   - [ ] Validate parameters
   - [ ] Modify state appropriately
   - [ ] Append descriptive events

5. **Testing**
   - [ ] Test with valid input
   - [ ] Test with invalid input
   - [ ] Test phase restrictions
   - [ ] Test edge cases
