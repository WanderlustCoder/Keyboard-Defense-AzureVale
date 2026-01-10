# Command Parser Guide

Text command parsing and intent generation system.

## Overview

`CommandParser` (sim/parse_command.gd) converts text commands into structured intent dictionaries that `IntentApplier` can process. It handles tokenization, argument validation, and error messaging.

## Core Function

```gdscript
static func parse(command: String) -> Dictionary:
    # Returns: {"ok": true, "intent": Dictionary}
    # Or: {"ok": false, "error": String}
```

## Command Syntax

Commands follow the pattern:
```
verb [arguments...]
```

Arguments can be:
- Positional: `build tower 5 3`
- Named subcommands: `settings scale +`
- Text parameters: `defend hello world`

## Command Categories

### Core Commands

| Command | Syntax | Intent |
|---------|--------|--------|
| help | `help [topic]` | `help` or `help` with topic |
| version | `version` | `ui_version` |
| status | `status` | `status` |
| end | `end` | `end` |
| restart | `restart` | `restart` |
| new | `new` | `new` |
| save | `save` | `save` |
| load | `load` | `load` |

### Resource Commands

| Command | Syntax | Intent |
|---------|--------|--------|
| gather | `gather <resource> <amount>` | `gather` with resource, amount |
| build | `build <type> [x y]` | `build` with building, x?, y? |
| demolish | `demolish [x y]` | `demolish` with x?, y? |
| upgrade | `upgrade [x y]` | `upgrade` with x?, y? |

### Navigation Commands

| Command | Syntax | Intent |
|---------|--------|--------|
| cursor | `cursor <x> <y>` | `cursor` with x, y |
| cursor | `cursor <direction> [n]` | `cursor_move` with dx, dy, steps |
| inspect | `inspect [x y]` | `inspect` with x?, y? |
| map | `map` | `map` |
| explore | `explore` | `explore` |

### Combat Commands

| Command | Syntax | Intent |
|---------|--------|--------|
| defend | `defend <text>` | `defend_input` with text |
| wait | `wait` | `wait` |
| enemies | `enemies` | `enemies` |

### Lesson Commands

| Command | Syntax | Intent |
|---------|--------|--------|
| lesson | `lesson` | `lesson_show` |
| lesson | `lesson <id>` | `lesson_set` with lesson_id |
| lesson | `lesson next` | `lesson_next` |
| lesson | `lesson prev` | `lesson_prev` |
| lesson | `lesson sample [n]` | `lesson_sample` with count |
| lessons | `lessons` | `ui_lessons_toggle` |
| lessons | `lessons sort [mode]` | `ui_lessons_sort` with mode |
| lessons | `lessons sparkline [on/off]` | `ui_lessons_sparkline` |
| lessons | `lessons reset [all]` | `ui_lessons_reset` with scope |

### UI Commands

| Command | Syntax | Intent |
|---------|--------|--------|
| preview | `preview <type/none>` | `ui_preview` with building |
| overlay | `overlay path <on/off>` | `ui_overlay` with name, enabled |
| history | `history [show/hide/clear]` | `ui_history` with mode |
| trend | `trend [show/hide]` | `ui_trend` with mode |
| report | `report [show/hide]` | `ui_report` with mode |
| goal | `goal [id/next]` | `ui_goal_*` |

### Settings Commands

| Command | Syntax | Intent |
|---------|--------|--------|
| settings | `settings` | `ui_settings_toggle` |
| settings | `settings show/hide` | `ui_settings_show/hide` |
| settings | `settings scale [value/+/-/reset]` | `ui_settings_scale` |
| settings | `settings compact [on/off]` | `ui_settings_compact` |
| settings | `settings motion [on/off/reduced]` | `ui_settings_motion` |
| settings | `settings speed [slower/faster/0.5-2.0]` | `ui_settings_speed` |
| settings | `settings contrast [on/off]` | `ui_settings_contrast` |
| settings | `settings hints [on/off]` | `ui_settings_hints` |
| settings | `settings practice [on/off]` | `ui_settings_practice` |
| settings | `settings verify` | `ui_settings_verify` |
| settings | `settings conflicts` | `ui_settings_conflicts` |
| settings | `settings resolve [apply]` | `ui_settings_resolve` |
| settings | `settings export [save]` | `ui_settings_export` |

### Balance Commands

| Command | Syntax | Intent |
|---------|--------|--------|
| balance | `balance verify` | `ui_balance_verify` |
| balance | `balance summary [group]` | `ui_balance_summary` |
| balance | `balance diff [group]` | `ui_balance_diff` |
| balance | `balance export [save] [group]` | `ui_balance_export` |

### Event Commands

| Command | Syntax | Intent |
|---------|--------|--------|
| interact | `interact` | `interact_poi` |
| choice | `choice <id> [input]` | `event_choice` with choice_id, input |
| skip | `skip` | `event_skip` |

### Upgrade Commands

| Command | Syntax | Intent |
|---------|--------|--------|
| buy | `buy <category> <id>` | `buy_upgrade` with category, upgrade_id |
| upgrades | `upgrades [category]` | `ui_upgrades` with category |

### Quick Action Commands (Open-World)

| Command | Syntax | Intent |
|---------|--------|--------|
| look, l | `look` | `inspect_tile` |
| talk, t | `talk` | `interact_poi` |
| take, grab | `take` | `gather_at_cursor` |
| attack, fight | `attack` | `engage_enemy` |

### Keybinding Commands

| Command | Syntax | Intent |
|---------|--------|--------|
| bind | `bind <action>` | `ui_bind_action` (start rebind) |
| bind | `bind <action> <key>` | `ui_bind_action` with key_text |
| bind | `bind <action> reset` | `ui_bind_action_reset` |

### Tutorial Commands

| Command | Syntax | Intent |
|---------|--------|--------|
| tutorial | `tutorial` | `ui_tutorial_toggle` |
| tutorial | `tutorial restart` | `ui_tutorial_restart` |
| tutorial | `tutorial skip` | `ui_tutorial_skip` |

## Error Handling

Parse errors return descriptive messages:

```gdscript
# Empty input
{"ok": false, "error": "Enter a command. Type 'help' for options."}

# Unknown command
{"ok": false, "error": "Unknown command: xyz"}

# Wrong argument count
{"ok": false, "error": "Usage: gather <resource> <amount>"}

# Invalid argument type
{"ok": false, "error": "Amount must be a positive integer."}

# Invalid resource
{"ok": false, "error": "Unknown resource: gold"}

# Invalid building type
{"ok": false, "error": "Unknown build type: castle"}
```

## Direction Parsing

Cursor movement supports cardinal directions:

```gdscript
var dir_map := {
    "up": Vector2i(0, -1),
    "down": Vector2i(0, 1),
    "left": Vector2i(-1, 0),
    "right": Vector2i(1, 0)
}

# cursor up -> cursor_move {dx: 0, dy: -1, steps: 1}
# cursor right 5 -> cursor_move {dx: 1, dy: 0, steps: 5}
```

## Text Extraction

Some commands capture remaining text after the verb:

```gdscript
# defend hello world
var text: String = ""
if trimmed.length() > verb.length():
    text = trimmed.substr(verb.length()).strip_edges()
# text = "hello world"

# seed my custom seed
var seed_value: String = trimmed.substr(verb.length()).strip_edges()
# seed_value = "my custom seed"
```

## Validation Patterns

### Integer Validation

```gdscript
if not tokens[2].is_valid_int():
    return {"ok": false, "error": "Amount must be a positive integer."}
var amount: int = int(tokens[2])
if amount <= 0:
    return {"ok": false, "error": "Amount must be a positive integer."}
```

### Resource Validation

```gdscript
if not GameState.RESOURCE_KEYS.has(resource):
    return {"ok": false, "error": "Unknown resource: %s" % resource}
```

### Building Type Validation

```gdscript
if not SimBuildings.is_valid(build_type):
    return {"ok": false, "error": "Unknown build type: %s" % build_type}
```

### Float Range Validation

```gdscript
if speed_arg.is_valid_float():
    var val: float = speed_arg.to_float()
    if val >= 0.5 and val <= 2.0:
        return {"ok": true, "intent": ...}
```

## Adding New Commands

To add a new command:

1. Add case to match statement:
```gdscript
"newcmd":
    if tokens.size() != 2:
        return {"ok": false, "error": "Usage: newcmd <arg>"}
    var arg: String = tokens[1].to_lower()
    return {"ok": true, "intent": SimIntents.make("new_intent", {"arg": arg})}
```

2. Add intent handler in apply_intent.gd (see INTENT_APPLICATION_GUIDE.md)

3. Add help text in intents.gd

## Intent Factory

Commands use `SimIntents.make()` to create intent dictionaries:

```gdscript
# Simple intent
SimIntents.make("help")
# Returns: {"kind": "help"}

# Intent with parameters
SimIntents.make("build", {"building": "tower", "x": 5, "y": 3})
# Returns: {"kind": "build", "building": "tower", "x": 5, "y": 3}
```

## File Dependencies

- `sim/types.gd` - GameState.RESOURCE_KEYS
- `sim/buildings.gd` - SimBuildings.is_valid()
- `sim/intents.gd` - SimIntents.make()
