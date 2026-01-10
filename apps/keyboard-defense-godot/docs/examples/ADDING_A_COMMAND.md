# Implementation Example: Adding a New Command

This walkthrough shows every file you need to touch when adding a new command to Keyboard Defense.

## Example: Adding a "scout" Command

The `scout` command reveals enemy positions and stats for one turn, costing 1 AP.

---

## Step 1: Add to `sim/intents.gd` Help Text

Update the help_lines() function:

```gdscript
# sim/intents.gd - in help_lines()
static func help_lines() -> Array[String]:
    return [
        "Commands:",
        # ... existing commands ...
        "  scout - reveal enemy info for one turn (1 AP, day only)",
        # ...
    ]
```

## Step 2: Add Keyword to `sim/command_keywords.gd`

Register the command keyword:

```gdscript
# sim/command_keywords.gd

static func keywords() -> Array[String]:
    return [
        # ... existing keywords ...
        "scout",
        # ...
    ]
```

## Step 3: Parse the Command in `sim/parse_command.gd`

Add the parsing logic in the match statement:

```gdscript
# sim/parse_command.gd - in parse()

static func parse(command: String) -> Dictionary:
    # ... existing code ...

    match verb:
        # ... existing commands ...

        "scout":
            # No arguments required
            if tokens.size() > 1:
                return {"ok": false, "error": "'scout' takes no arguments."}
            return {"ok": true, "intent": SimIntents.make("scout")}

        # ... rest of match ...
```

**For commands with arguments:**

```gdscript
        "scout":
            # Optional range argument
            var range_val: int = 3  # default
            if tokens.size() == 2:
                if not tokens[1].is_valid_int():
                    return {"ok": false, "error": "Range must be a number."}
                range_val = int(tokens[1])
                if range_val < 1 or range_val > 10:
                    return {"ok": false, "error": "Range must be 1-10."}
            elif tokens.size() > 2:
                return {"ok": false, "error": "Usage: scout [range]"}
            return {"ok": true, "intent": SimIntents.make("scout", {"range": range_val})}
```

## Step 4: Apply the Intent in `sim/apply_intent.gd`

Add the intent handler:

```gdscript
# sim/apply_intent.gd - in apply() match statement

static func apply(state: GameState, intent: Dictionary) -> Dictionary:
    # ... existing code ...

    match kind:
        # ... existing intents ...

        "scout":
            _apply_scout(new_state, intent, events)

        # ... rest of match ...
```

Then implement the handler function:

```gdscript
# sim/apply_intent.gd - new static function

static func _apply_scout(state: GameState, intent: Dictionary, events: Array[String]) -> void:
    # Check phase
    if state.phase != "day":
        events.append("Can only scout during the day phase.")
        return

    # Check AP cost
    var cost: int = 1
    if state.ap < cost:
        events.append("Not enough AP. Need %d, have %d." % [cost, state.ap])
        return

    # Deduct AP
    state.ap -= cost

    # Apply effect
    var range_val: int = int(intent.get("range", 3))
    state.scout_active = true
    state.scout_range = range_val

    # Build info string
    var enemy_count: int = state.enemies.size()
    if enemy_count == 0:
        events.append("Scout report: No enemies detected.")
    else:
        var info_lines: Array[String] = ["Scout report:"]
        for enemy in state.enemies:
            var kind: String = str(enemy.get("kind", "unknown"))
            var hp: int = int(enemy.get("hp", 0))
            var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
            info_lines.append("  %s at (%d,%d) - HP: %d" % [kind, pos.x, pos.y, hp])
        events.append_array(info_lines)

    events.append("Scouted the area. (-1 AP)")
```

## Step 5: Add State Fields if Needed

If the command adds new state, update `sim/types.gd`:

```gdscript
# sim/types.gd - in GameState class

class GameState:
    extends RefCounted

    # ... existing fields ...

    # Scout state
    var scout_active: bool = false
    var scout_range: int = 0
```

And update the copy function:

```gdscript
# sim/types.gd - in copy()

func copy() -> GameState:
    var c := GameState.new()
    # ... existing copies ...
    c.scout_active = scout_active
    c.scout_range = scout_range
    return c
```

## Step 6: Handle in UI/Rendering (Optional)

If the command affects display, update the renderer:

```gdscript
# game/grid_renderer.gd - in draw or similar

if state.scout_active:
    for enemy in state.enemies:
        var pos: Vector2 = _grid_to_screen(enemy.get("pos", Vector2i.ZERO))
        # Draw enhanced enemy info
        draw_string(font, pos + Vector2(0, -20),
            "HP: %d" % enemy.get("hp", 0),
            HORIZONTAL_ALIGNMENT_CENTER)
```

## Step 7: Clear State on Phase Change

Reset temporary state when appropriate:

```gdscript
# sim/tick.gd - in _end_day() or phase transition

static func _end_day(state: GameState) -> void:
    # ... existing code ...

    # Clear scout effect
    state.scout_active = false
    state.scout_range = 0
```

## Step 8: Add to Balance Constants

If the command has costs or effects, document in `sim/balance.gd`:

```gdscript
# sim/balance.gd

const SCOUT_AP_COST: int = 1
const SCOUT_DEFAULT_RANGE: int = 3
```

Then reference these in apply_intent.gd instead of hardcoding.

## Step 9: Add Tests

```gdscript
# tests/run_tests.gd

func test_scout_command_parses() -> void:
    var result := CommandParser.parse("scout")
    assert(result["ok"] == true, "Scout should parse")
    assert(result["intent"]["kind"] == "scout", "Intent kind should be scout")
    _pass("test_scout_command_parses")

func test_scout_requires_day_phase() -> void:
    var state := GameState.new()
    state.phase = "night"
    var intent := SimIntents.make("scout")
    var result := IntentApplier.apply(state, intent)
    assert("day phase" in result["events"][0].to_lower(), "Should reject during night")
    _pass("test_scout_requires_day_phase")

func test_scout_costs_ap() -> void:
    var state := GameState.new()
    state.phase = "day"
    state.ap = 5
    var intent := SimIntents.make("scout")
    var result := IntentApplier.apply(state, intent)
    assert(result["state"].ap == 4, "Should cost 1 AP")
    _pass("test_scout_costs_ap")
```

## Step 10: Run Validation

```bash
# Validate everything
./scripts/precommit.sh --quick

# Or individually:
godot --headless --path . --script res://tests/run_tests.gd
```

---

## Files Changed Summary

| File | Change |
|------|--------|
| `sim/intents.gd` | Add help text |
| `sim/command_keywords.gd` | Register keyword |
| `sim/parse_command.gd` | Add parsing logic |
| `sim/apply_intent.gd` | Add intent handler |
| `sim/types.gd` | Add state fields (if needed) |
| `sim/balance.gd` | Add cost constants |
| `sim/tick.gd` | Clear state on phase change |
| `game/grid_renderer.gd` | Add visual feedback (if needed) |
| `tests/run_tests.gd` | Add test cases |

## Command Flow Diagram

```
User types "scout"
        ↓
CommandParser.parse("scout")
        ↓
Returns {"ok": true, "intent": {"kind": "scout"}}
        ↓
IntentApplier.apply(state, intent)
        ↓
_apply_scout() validates and modifies state
        ↓
Returns {"state": new_state, "events": ["Scout report: ..."]}
        ↓
UI displays events to user
```

## Common Pitfalls

1. **Forgetting command_keywords.gd** - Autocomplete won't suggest the command
2. **Not checking phase** - Command may work when it shouldn't
3. **Not copying state** - Direct modification breaks undo/determinism
4. **Missing help text** - Users won't know the command exists
5. **Hardcoded values** - Use balance.gd constants for tuning
