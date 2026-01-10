# Recent Changes

Log of recent changes made by Claude Code. Most recent first.

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
