# Recent Changes

Log of recent changes made by Claude Code. Most recent first.

---

## 2026-01-10: TODO Tracker, Test Coverage Analyzer, and Build Info Generator

**Added TODO/FIXME tracker:**
- `scripts/track_todos.py` - Find and categorize TODO/FIXME comments
- `scripts/track_todos.sh` - Shell wrapper
- Tracks: TODO, FIXME, HACK, XXX, BUG, NOTE, OPTIMIZE, REFACTOR
- Priority detection, context extraction, markdown export

**Added test coverage analyzer:**
- `scripts/analyze_test_coverage.py` - Analyze test coverage
- `scripts/analyze_test_coverage.sh` - Shell wrapper
- Reports coverage by layer, untested function priorities
- Identifies files needing tests

**Added build info generator:**
- `scripts/generate_build_info.py` - Generate build metadata
- `scripts/generate_build_info.sh` - Shell wrapper
- Includes version, git info, build date, project stats
- Can export to game/build_info.gd

---

## 2026-01-10: Scene Analyzer, Code Duplication Finder, and API Docs Generator

**Added scene analyzer:**
- `scripts/analyze_scenes.py` - Analyze .tscn files for issues
- `scripts/analyze_scenes.sh` - Shell wrapper
- Detects broken references, deep nesting, large scenes
- Reports duplicate node names, missing scripts

**Added code duplication finder:**
- `scripts/find_duplicates.py` - Find duplicate code blocks
- `scripts/find_duplicates.sh` - Shell wrapper
- Identifies copy-paste code patterns
- Reports duplication percentage and hot spots

**Added API documentation generator:**
- `scripts/generate_api_docs.py` - Generate docs from source
- `scripts/generate_api_docs.sh` - Shell wrapper
- Documents classes, functions, signals, enums
- Supports markdown and JSON output

---

## 2026-01-10: Code Complexity Analyzer, Import Optimizer, and Naming Checker

**Added code complexity analyzer:**
- `scripts/analyze_complexity.py` - Analyze function complexity metrics
- `scripts/analyze_complexity.sh` - Shell wrapper
- Metrics: cyclomatic, lines, nesting, cognitive complexity
- Risk levels: low, medium, high

**Added import optimizer:**
- `scripts/optimize_imports.py` - Find unused preload/load imports
- `scripts/optimize_imports.sh` - Shell wrapper
- Supports dry-run and auto-fix modes
- Detects const, var, and @onready preloads

**Added naming convention checker:**
- `scripts/check_naming.py` - Check naming standards
- `scripts/check_naming.sh` - Shell wrapper
- snake_case, PascalCase, SCREAMING_SNAKE conventions
- Suggests corrections for violations

---

## 2026-01-10: Dependency Graph, Unused Asset Finder, and Data Migration Helper

**Added dependency graph generator:**
- `scripts/dependency_graph.py` - Visualize file import relationships
- `scripts/dependency_graph.sh` - Shell wrapper
- Detects cross-layer violations, circular dependencies
- Supports Graphviz DOT output for visualization

**Added unused asset finder:**
- `scripts/find_unused_assets.py` - Find unreferenced assets
- `scripts/find_unused_assets.sh` - Shell wrapper
- Checks SVGs, PNGs, audio against manifest and code
- Finds orphan manifest entries

**Added data migration helper:**
- `scripts/migrate_data.py` - Schema migration management
- `scripts/migrate_data.sh` - Shell wrapper
- Auto-generate migration scripts from schema changes
- Backup and rollback support

---

## 2026-01-10: Project Statistics, Dead Code Finder, and Command Reference Generator

**Added project statistics tool:**
- `scripts/project_stats.py` - Codebase metrics and health overview
- `scripts/project_stats.sh` - Shell wrapper
- Reports: lines of code, functions, classes, data entries, asset counts
- Health indicators: comment ratio, TODOs, file sizes

**Added dead code finder:**
- `scripts/find_dead_code.py` - Find potentially unused code
- `scripts/find_dead_code.sh` - Shell wrapper
- Detects: unused functions, classes, constants, signals
- Finds orphan files not loaded/preloaded anywhere

**Added command reference generator:**
- `scripts/generate_command_ref.py` - Auto-document game commands
- `scripts/generate_command_ref.sh` - Shell wrapper
- Formats: markdown, JSON, HTML
- Parses intents.gd, parse_command.gd, apply_intent.gd

---

## 2026-01-10: Quick Reference, Integrity Checker, and Changelog Generator

**Added quick reference card:**
- `docs/QUICK_REFERENCE.md` - One-page essential reference
- Commands, file locations, code patterns, validation snippets

**Added data integrity checker:**
- `scripts/check_integrity.py` - Deep validation beyond schemas
- `scripts/check_integrity.sh` - Shell wrapper
- Categories: lessons, upgrades, buildings, assets, story, cross_ref, balance
- Checks reference integrity, upgrade chains, balance sanity

**Added changelog generator:**
- `scripts/generate_changelog.py` - Generate changelogs from git
- `scripts/generate_changelog.sh` - Shell wrapper
- Formats: plain, markdown, json, release
- Supports date ranges, tags, category grouping

---

## 2026-01-10: System Graph, Word Generator, and Test Scaffolding

**Added system dependency graph:**
- `docs/SYSTEM_GRAPH.md` - Visual architecture reference
- Layer diagrams, command pipeline, typing combat flow
- File impact matrix for understanding change ripples

**Added word list generator:**
- `scripts/generate_words.py` - Generate themed word lists for lessons
- `scripts/generate_words.sh` - Shell wrapper
- Themes: fantasy, coding, nature, medieval, science, common, bigrams, double_letters
- Supports charset-based generation, length filters, JSON/lesson output

**Added test scaffolding generator:**
- `scripts/generate_tests.py` - Auto-generate test stubs
- `scripts/generate_tests.sh` - Shell wrapper
- Templates for: file analysis, intents, enemies, buildings, lessons
- Can append directly to tests/run_tests.gd

---

## 2026-01-10: Asset Pipeline, Session Context, and Balance Simulator

**Added asset pipeline script:**
- `scripts/convert_assets.py` - Converts SVG source files to PNG sprites
- `scripts/convert_assets.sh` - Shell wrapper
- Supports multiple backends: cairosvg, Inkscape, rsvg-convert, ImageMagick
- Reads dimensions from `assets_manifest.json`

**Added session context loader:**
- `scripts/session_context.py` - Aggregates project context for session start
- `scripts/session_context.sh` - Shell wrapper
- Combines: git status, .claude/ files, diagnostics, project stats
- Supports `--brief`, `--json`, `--no-diagnostics` flags

**Added balance simulator:**
- `tools/balance_simulator.gd` - GDScript headless balance testing
- `scripts/simulate_balance.py` - Python fallback when Godot unavailable
- `scripts/simulate_balance.sh` - Shell wrapper with auto-fallback
- Scenarios: economy, waves, towers, combat

**Fixed duplicate lesson IDs in lessons.json:**
- `alternating_hands` → `hand_alternation_drill`
- `double_letters` → `double_letter_drill`
- `bigram_flow` (second) → `bigram_common`
- `weak_fingers` (second) → `pinky_ring_strength`

---

## 2026-01-10: Implementation Examples, Diagnostics, and Templates

**Added implementation examples (`docs/examples/`):**
- `ADDING_AN_ENEMY.md` - Complete walkthrough with stats, scaling, behavior, assets
- `ADDING_A_COMMAND.md` - Full parse → intent → apply flow
- `ADDING_A_LESSON.md` - Lesson modes, word generation, graduation paths
- `ADDING_A_BUILDING.md` - Costs, production, effects, validation

**Added diagnostic scripts:**
- `scripts/diagnose.py` - Python diagnostic tool
- `scripts/diagnose.sh` - Shell wrapper
- Checks: orphaned assets, missing manifests, invalid lessons, broken references, balance anomalies

**Added code templates (`templates/`):**
- `sim_feature.gd.template` - Sim layer feature boilerplate
- `ui_component.gd.template` - UI panel/component boilerplate
- `intent_handler.gd.template` - Command handler (multi-file)
- `enemy_type.gd.template` - Enemy type (multi-file)

**Updated CLAUDE.md** with documentation for all new resources.

---

## 2026-01-10: Schema Updates

**Fixed all outdated schemas:**
- `assets_manifest.schema.json` - Added `category`, `source_svg`, `source_svg_frames` (string or array), `description`, `duration_ms`, `frames`, `frame_width`, `frame_height` to textures; Added `nineslice` as boolean or object; Added `margin_*` at texture level; Added `music` section; Added animation `duration_ms`
- `kingdom_upgrades.schema.json` - Added `gold_income` to effects
- `unit_upgrades.schema.json` - Added `resource_multiplier`, `gold_multiplier`, `gold_income`, `wave_heal` to effects
- `lessons.schema.json` - Added `sentence` mode, `sentences` property, `graduation_paths` section

All 7 schema-validated files now pass: `./scripts/validate.sh --quick` returns 8 passed, 0 failed.

---

## 2026-01-10: Development Infrastructure Setup

**Added schema validation system:**
- `scripts/validate_schemas.py` - Python script that validates JSON data files against schemas
- `scripts/validate.sh` / `validate.ps1` - Shell wrappers
- Validates all `data/*.json` files against `data/schemas/*.schema.json`
- Also checks sim/ directory for Node imports (architecture rule)

**Added .claude/ context directory:**
- `CURRENT_TASK.md` - Active work tracking
- `RECENT_CHANGES.md` - This file
- `DECISIONS.md` - Architecture decisions log
- `KNOWN_ISSUES.md` - Known quirks and edge cases
- `BLOCKED.md` - Current blockers

**Added pre-commit validation:**
- `scripts/precommit.sh` / `precommit.ps1` - Runs all validations before commit
- Validates schemas, runs headless tests, checks architecture rules

---

<!-- Template for new entries:

## YYYY-MM-DD: Short Description

**What changed:**
- Item 1
- Item 2

**Why:**
Brief rationale

**Files:**
- `path/to/file1`
- `path/to/file2`

---
-->
