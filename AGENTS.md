# AGENTS

## Development Model

**All development on this project is done by Claude Code.** There are no human developers writing code, creating art assets, or implementing features directly. The user provides direction and requirements; Claude Code handles all implementation.

This means:
- All code is written by Claude Code
- All art assets are created procedurally, via SVG generation, or using Godot's built-in drawing
- All documentation is both a reference for Claude Code AND the implementation specification
- Planning documents should be treated as implementation blueprints, not team coordination docs

## Project Structure

Godot project root is `apps/keyboard-defense-godot` (res:// maps there).

Key directories:
- `res://sim/**` - Deterministic sim logic only (no Node/UI/scene dependencies)
- `res://game/**` - Game rendering and input handling
- `res://ui/**` - UI components and panels
- `res://data/**` - JSON data files (lessons, story, balance)
- `res://assets/**` - Art and audio assets
- `docs/plans/` - Design specifications and implementation blueprints

## Architecture Rules

- Deterministic sim logic in `res://sim/**` only (no Node/UI/scene dependencies)
- UI/game code calls sim via intents and renders events
- Add/maintain tests runnable headless via `godot --headless --path . --script res://tests/run_tests.gd`
- Do not add copied third-party assets; prefer procedural placeholders

## Planning Documents

The `docs/plans/` directory contains extensive design specifications. These serve as:

1. **Implementation Blueprints** - JSON schemas and specifications can be directly converted to code/data
2. **Reference Material** - When implementing a feature, check relevant plan docs first
3. **Consistency Guide** - Use the documented values, IDs, and structures

Key plan categories:
- `p0/` - High priority, mostly complete
- `p1/` - Implementation-ready specifications (enemies, items, skills, towers, etc.)
- `p2/` - Future features

When implementing from plans:
- Extract JSON directly from plan docs into `data/` files
- Follow naming conventions specified in docs
- Use documented values for balance (damage, costs, timing)
- Reference the plan doc in code comments when helpful

## Art Asset Creation

Since Claude Code creates all assets, use these approaches:

### Preferred Methods (in order):
1. **Godot Draw Primitives** - Use `_draw()` for simple shapes, indicators, UI elements
2. **SVG Files** - Create SVG markup for sprites (stored in `assets/art/src-svg/`)
3. **Procedural Generation** - Generate textures/patterns via GDScript
4. **Placeholder Rectangles** - Colored rectangles with labels for rapid prototyping

### SVG Creation Guidelines:
- Keep SVGs simple and readable at small sizes
- Use the color palette from `docs/plans/p1/SPRITE_USAGE_GUIDE.md`
- Standard sizes: 32x32 (normal), 64x64 (large), 128x128 (boss)
- Store source SVGs in `assets/art/src-svg/[category]/`

### Animation:
- Use AnimationPlayer for programmatic animations
- Sprite sheet animations when SVG frames are created
- Prefer tweens and procedural animation over frame-by-frame when possible

## Implementation Workflow

When implementing a new feature:

1. **Check existing plans** - Look in `docs/plans/` for relevant specifications
2. **Read existing code** - Understand current patterns before adding new code
3. **Follow architecture** - Keep sim logic separate from rendering
4. **Extract data to JSON** - Game data belongs in `data/` files, not hardcoded
5. **Add tests** - Headless tests for sim logic
6. **Update manifests** - Add new assets to `data/assets_manifest.json`

## Testing

Before finalizing changes:
- Attempt to run headless tests: `godot --headless --path . --script res://tests/run_tests.gd`
- Run headless smoke boot to check for parse errors
- Use scenario harness for balance testing: `res://tools/run_scenarios.gd`

## Development Tools

### Pre-commit Validation
Run before committing to catch issues early:
```bash
./scripts/precommit.sh          # Full validation
./scripts/precommit.sh --quick  # Skip slow tests
```

### Schema Validation
Validate JSON data files against schemas:
```bash
./scripts/validate.sh           # All files
./scripts/validate.sh lessons   # Specific file
```

## Context Directory

The `/.claude/` directory at repo root contains persistent context files:
- `CURRENT_TASK.md` - Active work tracking (update at session start)
- `RECENT_CHANGES.md` - Log of recent changes (update after work)
- `DECISIONS.md` - Architecture decisions log
- `KNOWN_ISSUES.md` - Gotchas and edge cases to check before implementing
- `BLOCKED.md` - Current blockers

**Session workflow:** Read context files at start, update after completing work.

## Work Summary Format

When summarizing work, use LANDMARK sections:
- **LANDMARK A**: Files changed
- **LANDMARK B**: How to run
- **LANDMARK C**: Tests executed (with results)
- **LANDMARK D**: Next steps

Use `apps/keyboard-defense-godot/docs/CODEX_SUMMARY_TEMPLATE.md` for required end-of-milestone headings and checklist.

## Asset Manifest

When adding art or audio, update `apps/keyboard-defense-godot/data/assets_manifest.json` so the audit stays green.

## Key Reference Documents

### Primary Guides (Start Here)
- **`apps/keyboard-defense-godot/CLAUDE.md`** - **Primary dev guide with code patterns, examples, and quick reference**
- **`apps/keyboard-defense-godot/GAME_VISION.md`** - Design bible, pillars, inspirations, player fantasy

### Architecture & Implementation
- `apps/keyboard-defense-godot/docs/SYSTEM_DEPENDENCIES.md` - System interconnections and dependency map
- `apps/keyboard-defense-godot/docs/DATA_EXTRACTION_GUIDE.md` - Converting plans to data files
- `apps/keyboard-defense-godot/docs/SVG_TEMPLATES.md` - Ready-to-use SVG templates

### Core System Guides
- `apps/keyboard-defense-godot/docs/TYPING_COMBAT_GUIDE.md` - Typing mechanics and combat flow
- `apps/keyboard-defense-godot/docs/THREAT_WAVE_SYSTEM.md` - Threat levels and wave spawning
- `apps/keyboard-defense-godot/docs/STATE_PATTERNS.md` - State management and copying patterns
- `apps/keyboard-defense-godot/docs/COMMAND_PIPELINE.md` - Command parsing and intent system
- `apps/keyboard-defense-godot/docs/ENEMY_AFFIXES_GUIDE.md` - Enemy affixes and special abilities
- `apps/keyboard-defense-godot/docs/TOWER_PATHFINDING_GUIDE.md` - Distance field pathfinding, tower targeting
- `apps/keyboard-defense-godot/docs/BUILDING_ECONOMY_GUIDE.md` - Buildings, resources, upgrades, economy
- `apps/keyboard-defense-godot/docs/LESSON_CURRICULUM_GUIDE.md` - Lessons, word generation, graduation paths
- `apps/keyboard-defense-godot/docs/EVENT_POI_GUIDE.md` - POI spawning, events, choices, effects
- `apps/keyboard-defense-godot/docs/PLAYER_PROFILE_GUIDE.md` - Settings, achievements, streaks, persistence
- `apps/keyboard-defense-godot/docs/WORKER_ECONOMY_GUIDE.md` - Worker assignment, production bonuses, upkeep
- `apps/keyboard-defense-godot/docs/AUDIO_SYSTEM_GUIDE.md` - SFX, music, crossfading, volume control
- `apps/keyboard-defense-godot/docs/ASSET_ANIMATION_GUIDE.md` - Asset loading, sprite mapping, animation frames
- `apps/keyboard-defense-godot/docs/RESEARCH_TRADE_GUIDE.md` - Tech tree, trading, market bonuses
- `apps/keyboard-defense-godot/docs/ONBOARDING_GUIDE.md` - Tutorial flow, step completion, first-time UX
- `apps/keyboard-defense-godot/docs/PRACTICE_GOALS_GUIDE.md` - Goal thresholds, typing trends, coach suggestions
- `apps/keyboard-defense-godot/docs/TYPING_FEEDBACK_GUIDE.md` - Prefix matching, edit distance, candidate ranking
- `apps/keyboard-defense-godot/docs/BALANCE_TICK_GUIDE.md` - Day advancement, catch-up mechanics, wave formula
- `apps/keyboard-defense-godot/docs/KEYBIND_INPUT_GUIDE.md` - Key signatures, conflict detection, resolution
- `apps/keyboard-defense-godot/docs/STORY_PROGRESSION_GUIDE.md` - Acts, bosses, dialogue, performance feedback
- `apps/keyboard-defense-godot/docs/SAVE_SYSTEM_GUIDE.md` - State serialization, version handling
- `apps/keyboard-defense-godot/docs/TYPING_STATISTICS_GUIDE.md` - Performance metrics, combo tracking
- `apps/keyboard-defense-godot/docs/EVENT_EFFECTS_GUIDE.md` - Effect types, buff management
- `apps/keyboard-defense-godot/docs/ACHIEVEMENT_SYSTEM_GUIDE.md` - Achievement checks, unlocking
- `apps/keyboard-defense-godot/docs/OPEN_WORLD_GUIDE.md` - Exploration, cursor navigation, threats
- `apps/keyboard-defense-godot/docs/TYPING_DEFENSE_GUIDE.md` - Wave combat, power calculation
- `apps/keyboard-defense-godot/docs/KEYBOARD_DISPLAY_GUIDE.md` - On-screen keyboard, finger zones
- `apps/keyboard-defense-godot/docs/DIALOGUE_BOX_GUIDE.md` - Story dialogue, auto-advance
- `apps/keyboard-defense-godot/docs/EVENT_TABLES_GUIDE.md` - Weighted event selection, cooldowns
- `apps/keyboard-defense-godot/docs/TYPING_TRENDS_GUIDE.md` - Performance trends, coach suggestions
- `apps/keyboard-defense-godot/docs/LESSON_HEALTH_GUIDE.md` - Per-lesson health scoring, sparklines
- `apps/keyboard-defense-godot/docs/KINGDOM_DASHBOARD_GUIDE.md` - Resource management, workers, buildings, trade UI
- `apps/keyboard-defense-godot/docs/BATTLEFIELD_ORCHESTRATION_GUIDE.md` - Battle controller, drills, buffs, threat
- `apps/keyboard-defense-godot/docs/SCENARIO_TESTING_GUIDE.md` - Headless scenario harness, balance testing
- `apps/keyboard-defense-godot/docs/GAME_LOOP_ORCHESTRATION_GUIDE.md` - Main controller, command routing, event feedback
- `apps/keyboard-defense-godot/docs/GRID_RENDERER_GUIDE.md` - Map rendering, sprites, particles, animations
- `apps/keyboard-defense-godot/docs/PROGRESSION_STATE_GUIDE.md` - Campaign nodes, upgrades, modifiers
- `apps/keyboard-defense-godot/docs/EVENT_PANEL_GUIDE.md` - Event UI, choice buttons, input modes
- `apps/keyboard-defense-godot/docs/KEYBIND_CONFLICTS_GUIDE.md` - Signature-based conflict detection, resolution
- `apps/keyboard-defense-godot/docs/KINGDOM_DEFENSE_MODE_GUIDE.md` - RTS typing mode, planning/defense phases
- `apps/keyboard-defense-godot/docs/TYPING_PROFILE_MODEL_GUIDE.md` - Profile persistence, achievements, streaks
- `apps/keyboard-defense-godot/docs/BALANCE_REPORT_GUIDE.md` - Balance analysis, verification, export
- `apps/keyboard-defense-godot/docs/SCENE_NAVIGATION_GUIDE.md` - Scene transitions, campaign map, upgrades
- `apps/keyboard-defense-godot/docs/CONTROLS_FORMATTER_GUIDE.md` - Keybind parsing, text formatting
- `apps/keyboard-defense-godot/docs/SETTINGS_MANAGER_GUIDE.md` - Settings persistence, audio preferences
- `apps/keyboard-defense-godot/docs/INTENT_APPLICATION_GUIDE.md` - State mutation, intent routing
- `apps/keyboard-defense-godot/docs/COMMAND_PARSER_GUIDE.md` - Command parsing, syntax validation
- `apps/keyboard-defense-godot/docs/WORLD_TICK_GUIDE.md` - Open-world ticking, threat system
- `apps/keyboard-defense-godot/docs/STORY_MANAGER_GUIDE.md` - Narrative content, dialogue
- `apps/keyboard-defense-godot/docs/SPRITE_ANIMATOR_GUIDE.md` - Frame animation, reduced motion
- `apps/keyboard-defense-godot/docs/ASSET_LOADER_GUIDE.md` - Texture loading, sprite mapping
- `apps/keyboard-defense-godot/docs/SIM_UTILITIES_GUIDE.md` - GameState, RNG, intents, tick
- `apps/keyboard-defense-godot/docs/TYPING_ANALYSIS_GUIDE.md` - Trends, lesson health, sorting
- `apps/keyboard-defense-godot/docs/VFX_PERSISTENCE_GUIDE.md` - Hit effects, save/load
- `apps/keyboard-defense-godot/docs/UI_COMPONENTS_GUIDE.md` - Theme colors, UI widgets

### Project Status
- `docs/PROJECT_STATUS.md` - Current state of the project
- `docs/ROADMAP.md` - Milestone list and priorities
- `docs/plans/README.md` - Index of all planning documents
- `docs/COMMAND_REFERENCE.md` - In-game command documentation
- `docs/BALANCE_CONSTANTS.md` - Game balance values

## Code Style

- GDScript 4.x style
- Type hints preferred
- Signals for decoupling
- Comments for non-obvious logic
- Keep functions focused and small
