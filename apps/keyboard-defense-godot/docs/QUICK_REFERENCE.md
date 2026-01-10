# Quick Reference Card

One-page reference for Keyboard Defense development. For details, see CLAUDE.md.

## Commands

```bash
# Validation
./scripts/validate.sh              # Schema validation
./scripts/diagnose.sh              # Find issues
./scripts/precommit.sh             # Pre-commit checks

# Testing
godot --headless --path . --script res://tests/run_tests.gd
./scripts/simulate_balance.sh      # Balance testing

# Generation
./scripts/generate_words.sh --theme fantasy --count 50
./scripts/generate_tests.sh --enemy dragon
./scripts/convert_assets.sh        # SVG to PNG

# Context
./scripts/session_context.sh --brief
```

## File Locations

| Task | Files |
|------|-------|
| New command | `parse_command.gd` → `intents.gd` → `apply_intent.gd` |
| New enemy | `sim/enemies.gd`, `data/assets_manifest.json` |
| New building | `sim/types.gd`, `data/buildings.json`, `sim/buildings.gd` |
| New lesson | `data/lessons.json` |
| New upgrade | `data/kingdom_upgrades.json` or `data/unit_upgrades.json` |
| New UI panel | `ui/components/*.gd`, `scenes/*.tscn` |
| Balance tweak | `sim/balance.gd` |

## Intent Pattern

```gdscript
# 1. parse_command.gd
"mycommand":
    return {"ok": true, "intent": SimIntents.make("mycommand", {"param": tokens[1]})}

# 2. apply_intent.gd
"mycommand":
    _apply_mycommand(new_state, intent, events)

static func _apply_mycommand(state: GameState, intent: Dictionary, events: Array[String]) -> void:
    if state.phase != "day":
        events.append("Only during day phase.")
        return
    var param: String = str(intent.get("param", ""))
    # Do the thing
    events.append("Did %s." % param)
```

## GameState Key Fields

```gdscript
state.day          # Current day (int)
state.phase        # "day" | "night" | "game_over"
state.ap           # Action points (int)
state.hp           # Castle health (int)
state.gold         # Gold currency (int)
state.resources    # {"wood": int, "stone": int, "food": int}
state.enemies      # Array of enemy dicts
state.structures   # {index: "building_type"}
state.lesson_id    # Current lesson ID
```

## Enemy Dict Structure

```gdscript
{
    "id": int,           # Unique ID
    "kind": String,      # "scout", "raider", "armored", etc.
    "hp": int,           # Current HP
    "x": int, "y": int,  # Grid position
    "word": String,      # Word to type
    "typed": String,     # What player has typed
}
```

## Lesson Modes

| Mode | Required Fields |
|------|-----------------|
| `charset` | `charset`, `lengths` |
| `wordlist` | `wordlist`, `lengths` |
| `sentence` | `sentences` |

## Common Validation

```gdscript
# Phase check
if state.phase != "day":
    events.append("Only during day phase.")
    return

# AP check
if state.ap < cost:
    events.append("Not enough AP.")
    return

# Resource check
if int(state.resources.get("wood", 0)) < cost:
    events.append("Not enough wood.")
    return
```

## Sim Layer Rules

- `extends RefCounted` (never Node)
- Static functions only
- No signals, no scenes
- Pass state explicitly
- Must work headless

## Colors

```gdscript
Color("#dc143c")  # Enemy red
Color("#4169e1")  # Player blue
Color("#ffd700")  # Gold
Color("#32cd32")  # Health green
Color("#ff4500")  # Health low
Color("#1a1a2e")  # UI background
```

## JSON Data Paths

```
data/lessons.json           # Typing lessons
data/buildings.json         # Building definitions
data/kingdom_upgrades.json  # Kingdom upgrades
data/unit_upgrades.json     # Unit/combat upgrades
data/story.json             # Story content
data/assets_manifest.json   # Asset registry
```

## Test Pattern

```gdscript
func test_feature_works() -> void:
    var state := GameState.new()
    state.phase = "day"
    state.ap = 10

    var intent := SimIntents.make("command", {"param": "value"})
    var result := IntentApplier.apply(state, intent)

    assert(result["state"].ap < 10, "Should cost AP")
    _pass("test_feature_works")
```

## Git Workflow

```bash
# Before committing
./scripts/precommit.sh

# Commit format
git commit -m "Add feature X

- Detail 1
- Detail 2

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

## Debugging

```gdscript
print("Debug: ", value)                    # Console output
if OS.is_debug_build(): print("...")       # Debug only
breakpoint                                  # Debugger pause
```

## Key Documentation

- `CLAUDE.md` - Full development guide
- `docs/SYSTEM_GRAPH.md` - Architecture diagram
- `docs/examples/` - Implementation walkthroughs
- `templates/` - Code templates
- `.claude/` - Session context
