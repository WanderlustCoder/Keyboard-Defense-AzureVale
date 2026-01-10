# Claude Code Development Guide

This is the primary reference for Claude Code when working on Keyboard Defense.

## Quick Reference

```
Project Root:     apps/keyboard-defense-godot/
Godot Version:    4.x
Language:         GDScript
Test Command:     godot --headless --path . --script res://tests/run_tests.gd
Main Scene:       res://scenes/Main.tscn
```

## Architecture Overview

```
res://
├── sim/          # Deterministic game logic (NO Node dependencies)
├── game/         # Rendering, input, scene management
├── ui/           # UI components and panels
├── data/         # JSON data files
├── scenes/       # .tscn scene files
├── assets/       # Art and audio
├── tests/        # Headless tests
└── tools/        # Scenario harness, utilities
```

### Critical Rule: Sim/Game Separation

**sim/** contains ONLY pure logic:
- No `extends Node` - use `extends RefCounted`
- No signals, no scenes, no UI
- All functions should be static or operate on passed state
- Must be testable headless

**game/** renders and handles input:
- Calls sim via intents
- Renders state to screen
- Handles user input
- Manages scenes and nodes

## Code Patterns

### Adding a New Sim Feature

```gdscript
# sim/new_feature.gd
class_name NewFeature
extends RefCounted

# Static functions operating on GameState
static func do_something(state: GameState, param: String) -> void:
    state.some_value = param

static func calculate_something(state: GameState) -> int:
    return state.value * 2
```

### Adding a New Intent (Command)

1. Add to `sim/intents.gd` help_lines()
2. Add to `sim/command_keywords.gd` if new keyword
3. Handle in `sim/apply_intent.gd`:

```gdscript
# In apply() match statement:
"new_command":
    _apply_new_command(new_state, intent, events)

# Add handler function:
static func _apply_new_command(state: GameState, intent: Dictionary, events: Array[String]) -> void:
    var param = str(intent.get("param", ""))
    if state.phase != "day":
        events.append("Can only use during day phase.")
        return
    # Do the thing
    NewFeature.do_something(state, param)
    events.append("Did the thing with %s." % param)
```

4. Add parsing in `sim/parse_command.gd`:

```gdscript
# In parse() function:
"newcmd", "new_command":
    if tokens.size() > 1:
        return SimIntents.make("new_command", {"param": tokens[1]})
    return SimIntents.make("new_command")
```

### GameState Structure

The `GameState` class in `sim/types.gd` holds all game state. Key fields:

```gdscript
# Core
var day: int
var phase: String          # "day", "night", "game_over"
var ap: int                # Action points
var hp: int                # Castle health
var resources: Dictionary  # {"wood": 0, "stone": 0, "food": 0}

# Map
var map_w: int, map_h: int
var terrain: Array         # Flat array, index = y * map_w + x
var structures: Dictionary # {index: "type"}
var cursor_pos: Vector2i

# Combat
var enemies: Array         # Array of enemy dictionaries
var enemy_next_id: int

# Progression
var lesson_id: String
var gold: int
var purchased_kingdom_upgrades: Array
```

### Adding Data to JSON

Data files in `data/` follow this pattern:

```json
{
  "version": 1,
  "entries": {
    "entry_id": {
      "name": "Display Name",
      "property": "value"
    }
  }
}
```

Load with:
```gdscript
var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/file.json"))
```

### Creating UI Components

```gdscript
# ui/new_panel.gd
extends PanelContainer

signal closed

@onready var label: Label = $VBox/Label

func _ready() -> void:
    # Setup

func update_display(data: Dictionary) -> void:
    label.text = str(data.get("value", ""))

func _on_close_pressed() -> void:
    closed.emit()
    hide()
```

### Creating Visual Effects

Prefer procedural over sprites:

```gdscript
# game/effects/damage_number.gd
extends Node2D

var velocity: Vector2 = Vector2(0, -50)
var lifetime: float = 1.0
var text: String = ""
var color: Color = Color.WHITE

func _ready() -> void:
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 0.0, lifetime)
    tween.tween_callback(queue_free)

func _process(delta: float) -> void:
    position += velocity * delta
    velocity.y += 100 * delta  # gravity

func _draw() -> void:
    draw_string(ThemeDB.fallback_font, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, color)
```

## Common Tasks

### Add a New Enemy Type

1. Add to `sim/enemies.gd`:
```gdscript
const ENEMY_TYPES = {
    "new_enemy": {"hp": 20, "speed": 50, "damage": 2, "word_pool": "common"}
}
```

2. Update balance in `sim/balance.gd` if needed

3. Add spawn logic in appropriate wave composition

### Add a New Building

1. Add to `GameState.BUILDING_KEYS` in `sim/types.gd`
2. Add building data to `data/buildings.json`
3. Add production logic in `sim/buildings.gd`
4. Add build cost in `sim/balance.gd`

### Add a New Lesson

1. Add to `data/lessons.json`:
```json
"new_lesson": {
  "name": "Lesson Name",
  "description": "What this teaches",
  "focus_keys": ["a", "s", "d", "f"],
  "word_pool": ["word1", "word2"],
  "difficulty": 2
}
```

2. Add to graduation paths if part of progression

### Add a New Setting

1. Add to profile structure in `game/typing_profile.gd`
2. Add UI in settings panel
3. Apply setting where needed (check `speed_multiplier` pattern)

## Testing

### Running Tests

```bash
cd apps/keyboard-defense-godot
godot --headless --path . --script res://tests/run_tests.gd
```

### Writing Tests

Add test functions to `tests/run_tests.gd`:

```gdscript
func test_new_feature() -> void:
    var state = GameState.new()
    NewFeature.do_something(state, "test")
    assert(state.some_value == "test", "Feature should set value")
    _pass("test_new_feature")
```

### Scenario Testing

```bash
godot --headless --path . --script res://tools/run_scenarios.gd
```

Scenarios defined in `data/scenarios.json`.

## Development Tools

### Schema Validation

Validate JSON data files against their schemas before committing:

```bash
# Validate all data files
./scripts/validate.sh

# Only files with schemas (faster)
./scripts/validate.sh --quick

# Validate specific files
./scripts/validate.sh lessons map
```

Requires: `pip install jsonschema`

### Pre-commit Validation

Run all checks before committing:

```bash
# Full validation (includes headless tests)
./scripts/precommit.sh

# Quick mode (skip slow tests)
./scripts/precommit.sh --quick

# Skip tests only
./scripts/precommit.sh --no-tests
```

Checks performed:
1. JSON syntax validation
2. Schema validation
3. Sim layer architecture (no Node imports)
4. GDScript syntax
5. Headless tests
6. Common mistakes (TODOs, debug prints)

### Context Directory

The `/.claude/` directory at repo root contains persistent context for Claude Code:

| File | Purpose |
|------|---------|
| `CURRENT_TASK.md` | What's being worked on now |
| `RECENT_CHANGES.md` | Log of recent changes |
| `DECISIONS.md` | Architecture decisions made |
| `KNOWN_ISSUES.md` | Gotchas and edge cases |
| `BLOCKED.md` | Current blockers |

**Session workflow:**
1. Read `CURRENT_TASK.md` at session start
2. Check `KNOWN_ISSUES.md` before implementing
3. Update `RECENT_CHANGES.md` after completing work
4. Record decisions in `DECISIONS.md`

### Implementation Examples

Complete worked examples in `docs/examples/`:

| Example | Description |
|---------|-------------|
| `ADDING_AN_ENEMY.md` | Full walkthrough: stats, scaling, behavior, assets |
| `ADDING_A_COMMAND.md` | Parse → intent → apply flow with tests |
| `ADDING_A_LESSON.md` | Lesson modes, word generation, graduation paths |
| `ADDING_A_BUILDING.md` | Costs, production, effects, validation |

### Code Templates

Boilerplate templates in `templates/`:

```bash
# Copy and modify for new features
templates/sim_feature.gd.template      # Sim layer feature
templates/ui_component.gd.template     # UI panel/component
templates/intent_handler.gd.template   # New command (multi-file)
templates/enemy_type.gd.template       # New enemy (multi-file)
```

### Diagnostic Scripts

Check for common issues:

```bash
./scripts/diagnose.sh              # Run all diagnostics
./scripts/diagnose.sh assets       # Check asset manifest
./scripts/diagnose.sh lessons      # Check lesson configs
./scripts/diagnose.sh references   # Check cross-references
./scripts/diagnose.sh balance      # Check balance values
```

### Asset Pipeline

Convert SVG source files to PNG sprites:

```bash
./scripts/convert_assets.sh              # Convert all missing PNGs
./scripts/convert_assets.sh --all        # Reconvert everything
./scripts/convert_assets.sh --id enemy_scout  # Convert specific asset
./scripts/convert_assets.sh --dry-run    # Show what would be converted
```

Requires one of: `pip install cairosvg`, `inkscape`, `rsvg-convert`, or `imagemagick`

The script reads `data/assets_manifest.json` to find SVG sources and expected dimensions, then converts to PNG in `assets/sprites/`.

### Session Context Loader

Get aggregated project context at session start:

```bash
./scripts/session_context.sh           # Full context
./scripts/session_context.sh --brief   # Quick summary
./scripts/session_context.sh --json    # Machine-readable output
./scripts/session_context.sh --no-diagnostics  # Skip running diagnostics
```

Aggregates:
- Git status and recent commits
- `.claude/` directory files (current task, blockers, known issues)
- Diagnostic summary
- Project statistics

**Recommended session start:** Run `./scripts/session_context.sh --brief` to quickly understand project state.

### Balance Simulator

Test game balance scenarios without running full Godot:

```bash
# Using GDScript (requires Godot)
godot --headless --path . --script res://tools/balance_simulator.gd

# Using Python fallback
python3 scripts/simulate_balance.py

# Options
./scripts/simulate_balance.sh --scenario economy --days 10
./scripts/simulate_balance.sh --scenario waves --verbose
./scripts/simulate_balance.sh --verify    # Run balance checks only
./scripts/simulate_balance.sh --json      # JSON output
```

Scenarios:
- `economy` - Resource production, caps, catch-up mechanics
- `waves` - Wave composition, threat scaling
- `towers` - Tower damage output, DPS scaling
- `combat` - Full combat simulation (wave HP vs tower DPS)
- `all` - Run all scenarios (default)

### Word List Generator

Generate themed word lists for typing lessons:

```bash
./scripts/generate_words.sh --theme fantasy --count 50
./scripts/generate_words.sh --theme coding --min-length 4 --max-length 8
./scripts/generate_words.sh --charset "asdfghjkl" --count 30
./scripts/generate_words.sh --theme nature --json
./scripts/generate_words.sh --theme medieval --lesson "medieval_words" --name "Medieval Words"
```

Available themes: `fantasy`, `coding`, `nature`, `medieval`, `science`, `common`, `bigrams`, `double_letters`

### Test Scaffolding Generator

Generate test stubs for new features:

```bash
./scripts/generate_tests.sh --file sim/new_feature.gd   # Analyze file
./scripts/generate_tests.sh --intent build_tower        # Intent tests
./scripts/generate_tests.sh --enemy dragon              # Enemy tests
./scripts/generate_tests.sh --building barracks         # Building tests
./scripts/generate_tests.sh --lesson home_row_1         # Lesson tests
./scripts/generate_tests.sh --enemy orc --append        # Append to run_tests.gd
```

### System Dependency Graph

Visual architecture reference at `docs/SYSTEM_GRAPH.md`:
- Layer diagram (UI → Game → Sim → Data)
- Command pipeline flow
- Typing combat flow
- Day/night cycle
- Data dependencies
- File impact matrix

## File Locations Quick Reference

| Need to... | Location |
|------------|----------|
| Add game logic | `sim/*.gd` |
| Add UI component | `ui/*.gd` + `scenes/*.tscn` |
| Add command | `sim/intents.gd`, `sim/parse_command.gd`, `sim/apply_intent.gd` |
| Add enemy type | `sim/enemies.gd` |
| Add building | `sim/types.gd`, `data/buildings.json`, `sim/buildings.gd` |
| Add lesson | `data/lessons.json` |
| Add balance value | `sim/balance.gd` |
| Add visual effect | `game/hit_effects.gd` or new file in `game/` |
| Add setting | `game/typing_profile.gd`, `game/settings_manager.gd` |
| Add story content | `data/story.json`, `game/story_manager.gd` |
| Add upgrade | `data/kingdom_upgrades.json` or `data/unit_upgrades.json` |
| Add scene | `scenes/*.tscn` |
| Add test | `tests/run_tests.gd` |

## Data File Schemas

### lessons.json
```json
{
  "lesson_id": {
    "name": "string",
    "description": "string",
    "focus_keys": ["char array"],
    "word_pool": ["word array"],
    "difficulty": 1-5,
    "category": "string"
  }
}
```

### buildings.json
```json
{
  "building_id": {
    "name": "string",
    "description": "string",
    "cost": {"wood": 0, "stone": 0},
    "production": {"resource": amount},
    "provides": "string"
  }
}
```

### story.json
```json
{
  "acts": [...],
  "dialogue": {"id": {"speaker": "", "lines": []}},
  "tips": {"category": ["tip strings"]},
  "achievements": [...]
}
```

## Pitfalls to Avoid

1. **Never import Node classes in sim/**
   - Wrong: `extends Node`
   - Right: `extends RefCounted` or static class

2. **Don't modify state directly from game layer**
   - Wrong: `state.hp -= 1`
   - Right: Create intent, apply through `IntentApplier.apply()`

3. **Don't hardcode balance values**
   - Wrong: `damage = 10`
   - Right: `damage = SimBalance.get_tower_damage(tier)`

4. **Don't forget to update version numbers**
   - JSON files have `"version": N`
   - Increment when schema changes

5. **Don't use await in sim/**
   - Sim must be synchronous for determinism
   - Use events array for multi-step feedback

6. **Don't create new singletons/autoloads without good reason**
   - Pass state explicitly
   - Use signals for loose coupling

## Creating Art Assets

Since Claude Code creates all assets:

### SVG (Preferred for sprites)
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <!-- 32x32 standard size -->
  <rect x="4" y="4" width="24" height="24" fill="#dc143c"/>
</svg>
```
Save to: `assets/art/src-svg/[category]/name.svg`

### Godot Draw (Preferred for dynamic)
```gdscript
func _draw():
    draw_rect(Rect2(-16, -16, 32, 32), Color.RED)
    draw_circle(Vector2.ZERO, 8, Color.WHITE)
```

### Placeholder (For prototyping)
```gdscript
draw_rect(Rect2(-16, -16, 32, 32), Color.MAGENTA)
draw_string(ThemeDB.fallback_font, Vector2(-8, 4), "?", HORIZONTAL_ALIGNMENT_CENTER)
```

## Color Palette

Use these colors for consistency:

```gdscript
const COLORS = {
    "enemy": Color("#dc143c"),
    "player": Color("#4169e1"),
    "gold": Color("#ffd700"),
    "health_full": Color("#32cd32"),
    "health_low": Color("#ff4500"),
    "ui_bg": Color("#1a1a2e"),
    "ui_text": Color("#f0f0f5"),
}
```

## Signals Convention

```gdscript
# Declare at top of class
signal something_happened(data: Dictionary)
signal value_changed(old_value: int, new_value: int)

# Emit with explicit types
something_happened.emit({"key": "value"})
value_changed.emit(old, new)

# Connect with callables
node.something_happened.connect(_on_something_happened)
```

## Performance Tips

1. Use `@onready` for node references
2. Cache expensive lookups
3. Use object pooling for frequent spawns (projectiles, particles)
4. Prefer `queue_free()` over `free()`
5. Use `set_process(false)` when idle

## Debugging

```gdscript
# Print to console
print("Debug: ", value)

# Conditional debug
if OS.is_debug_build():
    print("Debug only: ", value)

# Draw debug visuals
func _draw():
    if Engine.is_editor_hint():
        draw_circle(Vector2.ZERO, range, Color(1, 0, 0, 0.3))
```

## Key Documentation

### Implementation Guides
- `GAME_VISION.md` - Design bible, pillars, player fantasy
- `docs/DATA_EXTRACTION_GUIDE.md` - Converting plans to data files
- `docs/SYSTEM_DEPENDENCIES.md` - System interconnections and architecture
- `docs/SVG_TEMPLATES.md` - Ready-to-use SVG templates for assets

### Core System Guides
- `docs/TYPING_COMBAT_GUIDE.md` - Typing mechanics, word matching, damage flow
- `docs/THREAT_WAVE_SYSTEM.md` - Threat levels, wave triggers, roaming enemies
- `docs/STATE_PATTERNS.md` - State copying, immutability, adding new fields
- `docs/COMMAND_PIPELINE.md` - Command parsing, intents, application flow
- `docs/ENEMY_AFFIXES_GUIDE.md` - Affix system, special behaviors, adding new affixes
- `docs/TOWER_PATHFINDING_GUIDE.md` - Distance field pathfinding, tower targeting
- `docs/BUILDING_ECONOMY_GUIDE.md` - Buildings, resources, upgrades, economy
- `docs/LESSON_CURRICULUM_GUIDE.md` - Lessons, word generation, graduation paths
- `docs/EVENT_POI_GUIDE.md` - POI spawning, events, choices, effects
- `docs/PLAYER_PROFILE_GUIDE.md` - Settings, achievements, streaks, persistence
- `docs/WORKER_ECONOMY_GUIDE.md` - Worker assignment, production bonuses, upkeep
- `docs/AUDIO_SYSTEM_GUIDE.md` - SFX, music, crossfading, volume control
- `docs/ASSET_ANIMATION_GUIDE.md` - Asset loading, sprite mapping, animation frames
- `docs/RESEARCH_TRADE_GUIDE.md` - Tech tree, trading, market bonuses
- `docs/ONBOARDING_GUIDE.md` - Tutorial flow, step completion, first-time UX
- `docs/PRACTICE_GOALS_GUIDE.md` - Goal thresholds, typing trends, coach suggestions
- `docs/TYPING_FEEDBACK_GUIDE.md` - Prefix matching, edit distance, candidate ranking, input routing
- `docs/BALANCE_TICK_GUIDE.md` - Day advancement, catch-up mechanics, resource caps, wave formula
- `docs/KEYBIND_INPUT_GUIDE.md` - Key signatures, conflict detection, resolution plans
- `docs/STORY_PROGRESSION_GUIDE.md` - Acts, bosses, dialogue, performance feedback
- `docs/SAVE_SYSTEM_GUIDE.md` - State serialization, deserialization, version handling
- `docs/TYPING_STATISTICS_GUIDE.md` - Performance metrics, combo tracking, reports
- `docs/EVENT_EFFECTS_GUIDE.md` - Effect types, buff management, event consequences
- `docs/ACHIEVEMENT_SYSTEM_GUIDE.md` - Achievement checks, unlocking, progress tracking
- `docs/OPEN_WORLD_GUIDE.md` - Exploration mode, cursor navigation, real-time threats
- `docs/TYPING_DEFENSE_GUIDE.md` - Wave combat, power calculation, lesson progression
- `docs/KEYBOARD_DISPLAY_GUIDE.md` - On-screen keyboard, finger zones, key highlighting
- `docs/DIALOGUE_BOX_GUIDE.md` - Story dialogue, auto-advance, input handling
- `docs/EVENT_TABLES_GUIDE.md` - Weighted event selection, conditions, cooldowns
- `docs/TYPING_TRENDS_GUIDE.md` - Performance trend analysis, goal checking, coach suggestions
- `docs/LESSON_HEALTH_GUIDE.md` - Per-lesson health scoring, sorting, sparklines
- `docs/KINGDOM_DASHBOARD_GUIDE.md` - Resource management, workers, buildings, research, trade UI
- `docs/BATTLEFIELD_ORCHESTRATION_GUIDE.md` - Battle controller, drills, buffs, threat mechanics
- `docs/SCENARIO_TESTING_GUIDE.md` - Headless scenario harness, balance testing, CI integration
- `docs/GAME_LOOP_ORCHESTRATION_GUIDE.md` - Main controller, command routing, HUD refresh, event feedback
- `docs/GRID_RENDERER_GUIDE.md` - Procedural map rendering, sprites, particles, animations
- `docs/PROGRESSION_STATE_GUIDE.md` - Campaign nodes, upgrades, gold, modifiers, mastery
- `docs/EVENT_PANEL_GUIDE.md` - Event UI, choice buttons, input modes, fade animations
- `docs/KEYBIND_CONFLICTS_GUIDE.md` - Signature-based conflict detection, resolution planning, settings export
- `docs/KINGDOM_DEFENSE_MODE_GUIDE.md` - RTS typing game mode, planning/defense phases, build commands
- `docs/TYPING_PROFILE_MODEL_GUIDE.md` - Profile persistence, keybinds, achievements, streaks, UI preferences
- `docs/BALANCE_REPORT_GUIDE.md` - Balance analysis, verification, export, diff comparison
- `docs/SCENE_NAVIGATION_GUIDE.md` - GameController, scene transitions, battle stage, campaign map
- `docs/CONTROLS_FORMATTER_GUIDE.md` - Keybind parsing, text formatting, InputMap integration
- `docs/SETTINGS_MANAGER_GUIDE.md` - Settings persistence, audio/gameplay preferences
- `docs/INTENT_APPLICATION_GUIDE.md` - State mutation engine, intent routing, combat flow
- `docs/COMMAND_PARSER_GUIDE.md` - Command parsing, syntax validation, intent creation
- `docs/WORLD_TICK_GUIDE.md` - Open-world ticking, threat system, roaming enemies
- `docs/STORY_MANAGER_GUIDE.md` - Narrative content, dialogue, performance feedback
- `docs/SPRITE_ANIMATOR_GUIDE.md` - Frame animation, oneshot playback, reduced motion
- `docs/ASSET_LOADER_GUIDE.md` - Texture loading, caching, sprite ID mapping
- `docs/SIM_UTILITIES_GUIDE.md` - GameState, RNG, intents, tick, balance, defaults
- `docs/TYPING_ANALYSIS_GUIDE.md` - Trends, sparklines, goal themes, lesson health
- `docs/VFX_PERSISTENCE_GUIDE.md` - Hit effects, particles, save/load system
- `docs/UI_COMPONENTS_GUIDE.md` - Theme colors, command bar, stat bar, popups

### Planning Documents
Check `docs/plans/` before implementing:
- `p1/ENEMY_BESTIARY_CATALOG.md` - Enemy stats and types
- `p1/TOWER_SPECIFICATIONS_COMPLETE.md` - Tower stats
- `p1/ITEM_CATALOG_COMPLETE.md` - Items and equipment
- `p1/SKILL_TREE_COMPLETE.md` - Skills and abilities
- `p1/SPRITE_USAGE_GUIDE.md` - Art asset guidelines
- See `docs/plans/README.md` for full index

Extract JSON directly from these docs into `data/` files.
