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

### Data Integrity Checker

Deep validation beyond schema checks:

```bash
./scripts/check_integrity.sh                    # All checks
./scripts/check_integrity.sh --category lessons # Specific category
./scripts/check_integrity.sh --json             # JSON output
./scripts/check_integrity.sh --list             # List categories
```

Categories: `lessons`, `upgrades`, `buildings`, `assets`, `story`, `cross_ref`, `balance`

Checks:
- Reference integrity (all IDs exist)
- Upgrade chain validity
- Balance sanity (cost progression)
- Asset completeness

### Changelog Generator

Generate changelogs from git commits:

```bash
./scripts/generate_changelog.sh                     # Last 20 commits
./scripts/generate_changelog.sh --since 2026-01-01  # Since date
./scripts/generate_changelog.sh --tag v1.0.0        # Since tag
./scripts/generate_changelog.sh --format markdown   # Markdown output
./scripts/generate_changelog.sh --category          # Group by type
./scripts/generate_changelog.sh --format release --version 1.0.0
```

Formats: `plain`, `markdown`, `json`, `release`

### Quick Reference Card

One-page reference at `docs/QUICK_REFERENCE.md`:
- Essential commands
- File locations
- Code patterns
- Common validation snippets

### Project Statistics

Codebase metrics and health overview:

```bash
./scripts/project_stats.sh              # Full report
./scripts/project_stats.sh --brief      # Summary only
./scripts/project_stats.sh --json       # JSON output
```

Reports:
- Lines of code by type and directory
- Function/class counts
- Data file statistics
- Asset counts (SVG, PNG, audio)
- Documentation coverage
- Health indicators (comment ratio, TODOs, file sizes)

### Dead Code Finder

Find potentially unused code:

```bash
./scripts/find_dead_code.sh              # Full analysis
./scripts/find_dead_code.sh --functions  # Functions only
./scripts/find_dead_code.sh --files      # Orphan files only
./scripts/find_dead_code.sh --json       # JSON output
./scripts/find_dead_code.sh --verbose    # Show usage details
```

Detects:
- Unused functions (defined but never called)
- Unused classes (defined but never referenced)
- Unused constants and signals
- Orphan files (not loaded/preloaded anywhere)

### Command Reference Generator

Auto-generate command documentation:

```bash
./scripts/generate_command_ref.sh                    # Markdown output
./scripts/generate_command_ref.sh --json             # JSON output
./scripts/generate_command_ref.sh --html             # HTML output
./scripts/generate_command_ref.sh -o docs/COMMANDS.md  # Write to file
```

Analyzes:
- `sim/intents.gd` - Help text and definitions
- `sim/parse_command.gd` - Aliases and parsing
- `sim/apply_intent.gd` - Phase restrictions

### Dependency Graph Generator

Visualize file import relationships:

```bash
./scripts/dependency_graph.sh                    # Full overview
./scripts/dependency_graph.sh --file sim/types.gd    # Single file deps
./scripts/dependency_graph.sh --reverse sim/types.gd # What depends on file
./scripts/dependency_graph.sh --dot > deps.dot   # Graphviz DOT format
./scripts/dependency_graph.sh --json             # JSON output
```

Reports:
- Import/dependency relationships
- Cross-layer violations (sim → game/ui)
- Circular dependencies
- Most imported files (core dependencies)
- Highest coupling files

### Unused Asset Finder

Find assets not referenced anywhere:

```bash
./scripts/find_unused_assets.sh              # Full report
./scripts/find_unused_assets.sh --svg        # SVG files only
./scripts/find_unused_assets.sh --png        # PNG files only
./scripts/find_unused_assets.sh --audio      # Audio files only
./scripts/find_unused_assets.sh --json       # JSON output
```

Detects:
- SVG files not in assets_manifest.json
- PNG files not referenced in code/scenes
- Audio files not in sfx_presets.json
- Orphan manifest entries (missing source files)

### Data Migration Helper

Manage data file schema migrations:

```bash
./scripts/migrate_data.sh --check            # Check for needed migrations
./scripts/migrate_data.sh --generate lessons # Generate migration script
./scripts/migrate_data.sh --apply lessons    # Apply pending migrations
./scripts/migrate_data.sh --apply lessons --dry-run  # Preview changes
./scripts/migrate_data.sh --rollback lessons # Restore from backup
./scripts/migrate_data.sh --history          # Show migration history
```

Features:
- Automatic version detection from schemas
- Backup before applying changes
- Migration script generation
- Rollback support

### Code Complexity Analyzer

Analyze functions for complexity metrics:

```bash
./scripts/analyze_complexity.sh              # Full report
./scripts/analyze_complexity.sh --threshold 10  # Only high complexity
./scripts/analyze_complexity.sh --file game/main.gd  # Single file
./scripts/analyze_complexity.sh --sort lines # Sort by line count
./scripts/analyze_complexity.sh --json       # JSON output
```

Metrics:
- Cyclomatic complexity (decision points)
- Function length (lines of code)
- Nesting depth
- Cognitive complexity
- Risk level (low/medium/high)

### Import Optimizer

Find and remove unused imports:

```bash
./scripts/optimize_imports.sh              # Report unused imports
./scripts/optimize_imports.sh --file game/main.gd  # Single file
./scripts/optimize_imports.sh --fix        # Show removals (dry run)
./scripts/optimize_imports.sh --fix --apply  # Actually remove unused
./scripts/optimize_imports.sh --json       # JSON output
```

Detects:
- Unused const preloads
- Unused var preloads
- Unused @onready preloads

### Naming Convention Checker

Check code against naming standards:

```bash
./scripts/check_naming.sh              # Full report
./scripts/check_naming.sh --file game/main.gd  # Single file
./scripts/check_naming.sh --strict     # Stricter checks
./scripts/check_naming.sh --json       # JSON output
```

Conventions:
- `snake_case` for functions, variables, signals
- `PascalCase` for classes, class_name
- `SCREAMING_SNAKE_CASE` for constants
- `_prefixed` for private members

### Scene Analyzer

Analyze Godot scene files for issues:

```bash
./scripts/analyze_scenes.sh              # Full report
./scripts/analyze_scenes.sh --file scenes/Main.tscn  # Single scene
./scripts/analyze_scenes.sh --verbose    # Show all nodes
./scripts/analyze_scenes.sh --json       # JSON output
```

Detects:
- Missing/broken resource references
- Duplicate node names
- Deep nesting (>10 levels)
- Large scenes (>100 nodes)
- Scenes without root scripts

### Code Duplication Finder

Find duplicate code blocks:

```bash
./scripts/find_duplicates.sh              # Full report
./scripts/find_duplicates.sh --min-lines 5  # Min block size
./scripts/find_duplicates.sh --json       # JSON output
```

Reports:
- Duplicate function implementations
- Copy-paste code patterns
- Files with most duplication
- Refactoring suggestions

### API Documentation Generator

Generate docs from source code:

```bash
./scripts/generate_api_docs.sh              # Full docs
./scripts/generate_api_docs.sh --layer sim  # Only sim layer
./scripts/generate_api_docs.sh --file sim/types.gd  # Single file
./scripts/generate_api_docs.sh -o docs/API.md  # Write to file
./scripts/generate_api_docs.sh --json       # JSON output
```

Documents:
- Classes with class_name
- Functions with signatures
- Signals and parameters
- Constants and enums
- Export properties

### TODO/FIXME Tracker

Track technical debt and code comments:

```bash
./scripts/track_todos.sh              # Full report
./scripts/track_todos.sh --type TODO  # Only TODOs
./scripts/track_todos.sh --type FIXME # Only FIXMEs
./scripts/track_todos.sh --layer sim  # Only sim layer
./scripts/track_todos.sh --markdown   # Markdown for issue tracking
./scripts/track_todos.sh --json       # JSON output
```

Tracks:
- TODO, FIXME, HACK, XXX, BUG, NOTE comments
- Priority detection (urgent, critical, later, etc.)
- Context (function/class containing the comment)
- Health indicators

### Test Coverage Analyzer

Analyze test coverage across the codebase:

```bash
./scripts/analyze_test_coverage.sh              # Full report
./scripts/analyze_test_coverage.sh --layer sim  # Sim layer only
./scripts/analyze_test_coverage.sh --untested   # Show only untested functions
./scripts/analyze_test_coverage.sh --json       # JSON output
```

Reports:
- Coverage percentage by layer
- Untested function priorities
- Files needing tests
- Existing test inventory

### Build Info Generator

Generate build metadata:

```bash
./scripts/generate_build_info.sh              # Show build info
./scripts/generate_build_info.sh --json       # JSON output
./scripts/generate_build_info.sh --export     # Generate game/build_info.gd
./scripts/generate_build_info.sh -o path/file.gd  # Custom output path
```

Includes:
- Version from project.godot
- Git commit hash, branch, tag
- Build date/timestamp
- Project statistics (files, lines)
- Data counts (lessons, buildings, etc.)

### Signal Analyzer

Analyze GDScript signal declarations and connections:

```bash
./scripts/analyze_signals.sh              # Full report
./scripts/analyze_signals.sh --unused     # Show only unused signals
./scripts/analyze_signals.sh --file game/main.gd  # Single file
./scripts/analyze_signals.sh --json       # JSON output
```

Reports:
- Signal declarations and parameters
- Signal connections and emissions
- Unused signals (declared but never connected)
- Signals by layer (warns about sim/ signals)

### Type Checker

Find missing type annotations:

```bash
./scripts/check_types.sh              # Full report
./scripts/check_types.sh --strict     # Include private functions
./scripts/check_types.sh --layer sim  # Only sim layer
./scripts/check_types.sh --file game/main.gd  # Single file
./scripts/check_types.sh --json       # JSON output
```

Reports:
- Function return type coverage
- Parameter type coverage
- Untyped variables
- Files needing type annotations

### Resource Path Validator

Validate res:// paths in code and scenes:

```bash
./scripts/validate_paths.sh              # Full report
./scripts/validate_paths.sh --broken     # Show only broken paths
./scripts/validate_paths.sh --file game/main.gd  # Single file
./scripts/validate_paths.sh --json       # JSON output
```

Reports:
- Valid vs broken resource paths
- Reference types (preload, load, scene, string)
- Files with broken references

### Documentation Coverage Checker

Check documentation coverage:

```bash
./scripts/check_docs.sh              # Full report
./scripts/check_docs.sh --layer sim  # Only sim layer
./scripts/check_docs.sh --public     # Only public functions
./scripts/check_docs.sh --file game/main.gd  # Single file
./scripts/check_docs.sh --json       # JSON output
```

Reports:
- Function and class documentation coverage
- Undocumented public functions (priority)
- Files needing documentation
- Coverage by layer

### Performance Linter

Find potential performance issues:

```bash
./scripts/lint_performance.sh              # Full report
./scripts/lint_performance.sh --severity high  # Only high severity
./scripts/lint_performance.sh --file game/main.gd  # Single file
./scripts/lint_performance.sh --json       # JSON output
```

Detects:
- Hot path issues (allocations in _process/_physics_process)
- Nested loops (O(n^2) complexity)
- String concatenation in loops
- get_node() calls in hot paths

### Memory Leak Detector

Find potential memory leaks:

```bash
./scripts/check_memory.sh              # Full report
./scripts/check_memory.sh --strict     # More aggressive checks
./scripts/check_memory.sh --file game/main.gd  # Single file
./scripts/check_memory.sh --json       # JSON output
```

Detects:
- Signal connects without _exit_tree cleanup
- Lambda signal handlers (prevent GC)
- Tweens without kill() on cleanup
- Connect/disconnect imbalance

### Export Variable Checker

Check @export variables:

```bash
./scripts/check_exports.sh              # Full report
./scripts/check_exports.sh --untyped    # Only untyped exports
./scripts/check_exports.sh --file game/main.gd  # Single file
./scripts/check_exports.sh --json       # JSON output
```

Reports:
- Export type hint coverage
- Missing default values
- Invalid export_range/export_enum usage

### Magic Number Detector

Find hardcoded magic numbers:

```bash
./scripts/find_magic_numbers.sh              # Full report
./scripts/find_magic_numbers.sh --threshold 3  # Min occurrences
./scripts/find_magic_numbers.sh --file game/main.gd  # Single file
./scripts/find_magic_numbers.sh --json       # JSON output
```

Reports:
- Repeated numeric values
- Suggested constant names
- Files with most magic numbers

### Code Health Dashboard

Aggregate all metrics:

```bash
./scripts/health_dashboard.sh              # Full dashboard
./scripts/health_dashboard.sh --quick      # Quick summary
./scripts/health_dashboard.sh --save       # Save to history
./scripts/health_dashboard.sh --json       # JSON output
```

Aggregates:
- Type, doc, test coverage
- Performance and memory scores
- Tech debt and magic numbers
- Overall grade (A-F)

### Autoload Analyzer

Analyze autoload singletons:

```bash
./scripts/analyze_autoloads.sh              # Full report
./scripts/analyze_autoloads.sh --deps       # Show dependency graph
./scripts/analyze_autoloads.sh --usage      # Show usage stats
./scripts/analyze_autoloads.sh --json       # JSON output
```

Reports:
- Autoload list and paths
- Dependency order
- Circular dependencies
- Usage statistics

### Input Action Validator

Validate input actions:

```bash
./scripts/validate_inputs.sh              # Full report
./scripts/validate_inputs.sh --undefined  # Show undefined references
./scripts/validate_inputs.sh --unused     # Show unused actions
./scripts/validate_inputs.sh --json       # JSON output
```

Reports:
- Defined vs used actions
- Undefined action references
- Unused actions

### Run All Checks

Master script for all tools:

```bash
./scripts/run_all_checks.sh              # Full check suite
./scripts/run_all_checks.sh --quick      # Quick checks only
./scripts/run_all_checks.sh --ci         # CI mode (exit 1 on fail)
./scripts/run_all_checks.sh -o report.md # Output to file
./scripts/run_all_checks.sh --json       # JSON output
```

Runs:
- All validators and analyzers
- Pass/fail thresholds
- Summary report

### Class Name Validator

Validate class_name declarations:

```bash
./scripts/check_class_names.sh              # Full report
./scripts/check_class_names.sh --strict     # Check missing class_name
./scripts/check_class_names.sh --json       # JSON output
```

Reports:
- class_name vs filename mismatches
- Duplicate class_name declarations
- Missing class_name (strict mode)

### Scene Validator

Validate scene (.tscn) files:

```bash
./scripts/validate_scenes.sh              # Full report
./scripts/validate_scenes.sh --file scenes/Main.tscn  # Single scene
./scripts/validate_scenes.sh --verbose    # Show all nodes
./scripts/validate_scenes.sh --json       # JSON output
```

Reports:
- Missing resources and scripts
- Deep nesting (>10 levels)
- Large scenes (>100 nodes)
- Duplicate node names

### Signal Signature Checker

Validate signal declarations and usage:

```bash
./scripts/check_signal_signatures.sh              # Full report
./scripts/check_signal_signatures.sh --file game/main.gd  # Single file
./scripts/check_signal_signatures.sh --json       # JSON output
```

Reports:
- Emission parameter count vs declaration
- Undeclared signal emissions
- Signal connection patterns

### Function Length Checker

Find overly long functions:

```bash
./scripts/check_func_length.sh              # Full report
./scripts/check_func_length.sh --threshold 50  # Custom threshold
./scripts/check_func_length.sh --file game/main.gd  # Single file
./scripts/check_func_length.sh --json       # JSON output
```

Reports:
- Functions over threshold
- Refactoring candidates
- Average function length

### JSON Reference Validator

Validate cross-references in data files:

```bash
./scripts/validate_json_refs.sh              # Full report
./scripts/validate_json_refs.sh --file data/lessons.json  # Single file
./scripts/validate_json_refs.sh --json       # JSON output
```

Reports:
- Broken ID references
- Missing resource paths
- Orphan entries (never referenced)

### Node Reference Checker

Check node reference patterns:

```bash
./scripts/check_node_refs.sh              # Full report
./scripts/check_node_refs.sh --file game/main.gd  # Single file
./scripts/check_node_refs.sh --strict     # Stricter checks
./scripts/check_node_refs.sh --json       # JSON output
```

Reports:
- $ syntax vs @onready usage
- get_node() call patterns
- Deep path fragility warnings

### Dictionary Key Checker

Find potential dictionary key issues:

```bash
./scripts/check_dict_keys.sh              # Full report
./scripts/check_dict_keys.sh --file game/main.gd  # Single file
./scripts/check_dict_keys.sh --json       # JSON output
```

Reports:
- Similar keys (potential typos)
- Single-use keys
- Naming consistency

### Inheritance Analyzer

Analyze class inheritance hierarchy:

```bash
./scripts/analyze_inheritance.sh              # Full report
./scripts/analyze_inheritance.sh --class GameState  # Single class
./scripts/analyze_inheritance.sh --depth 5    # Custom threshold
./scripts/analyze_inheritance.sh --json       # JSON output
```

Reports:
- Inheritance chains and depth
- Base class usage statistics
- Deep inheritance warnings

### Await Pattern Checker

Check async/await usage patterns:

```bash
./scripts/check_await_patterns.sh              # Full report
./scripts/check_await_patterns.sh --file game/main.gd  # Single file
./scripts/check_await_patterns.sh --strict     # Stricter checks
./scripts/check_await_patterns.sh --json       # JSON output
```

Reports:
- Hot path await issues (_process, _physics_process)
- Signal and timer await patterns
- Functions with most awaits

### String Literal Checker

Find repeated string literals:

```bash
./scripts/check_string_literals.sh              # Full report
./scripts/check_string_literals.sh --min 3      # Min occurrences
./scripts/check_string_literals.sh --file game/main.gd  # Single file
./scripts/check_string_literals.sh --json       # JSON output
```

Reports:
- Repeated strings (potential constants)
- Suggested constant names
- Categorization by type

### Coupling Analyzer

Measure file coupling metrics:

```bash
./scripts/analyze_coupling.sh              # Full report
./scripts/analyze_coupling.sh --file game/main.gd  # Single file
./scripts/analyze_coupling.sh --layer sim  # Single layer
./scripts/analyze_coupling.sh --json       # JSON output
```

Reports:
- Afferent/efferent coupling
- Instability metrics
- Layer violation detection

### Match Pattern Checker

Analyze match statement patterns:

```bash
./scripts/check_match_patterns.sh              # Full report
./scripts/check_match_patterns.sh --file game/main.gd  # Single file
./scripts/check_match_patterns.sh --strict     # Stricter checks
./scripts/check_match_patterns.sh --json       # JSON output
```

Reports:
- Missing default cases
- Large match statements
- Duplicate patterns

### Comment Quality Checker

Analyze comment quality and coverage:

```bash
./scripts/check_comments.sh              # Full report
./scripts/check_comments.sh --layer sim  # Single layer
./scripts/check_comments.sh --file game/main.gd  # Single file
./scripts/check_comments.sh --json       # JSON output
```

Reports:
- Comment density and distribution
- Commented-out code detection
- Doc comments (##) vs inline comments (#)
- Best/worst commented files

### Enum Analyzer

Analyze enum definitions and usage:

```bash
./scripts/analyze_enums.sh              # Full report
./scripts/analyze_enums.sh --unused     # Show only unused values
./scripts/analyze_enums.sh --file game/main.gd  # Single file
./scripts/analyze_enums.sh --json       # JSON output
```

Reports:
- Enum declarations and values
- Usage tracking per value
- Unused enum values
- Enum-like constant patterns

### File Organization Checker

Check file organization and structure:

```bash
./scripts/check_file_organization.sh              # Full report
./scripts/check_file_organization.sh --layer sim  # Single layer
./scripts/check_file_organization.sh --json       # JSON output
```

Reports:
- File placement by layer
- Naming convention compliance
- Large file detection (>500 lines)
- Directory structure consistency

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
