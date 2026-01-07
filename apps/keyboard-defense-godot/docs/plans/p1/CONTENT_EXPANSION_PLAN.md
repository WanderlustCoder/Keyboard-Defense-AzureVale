# Content Expansion Plan

Roadmap ID: P1-CNT-001 (Status: Not started)

## Goals
- Expand lessons, enemies, buildings, terrain variants, and event content while preserving deterministic sim rules.
- Keep typing-first training intent clear: short/medium/long prompts mapped to enemy kinds and lesson stages.
- Maintain data-driven workflows with headless validation for new content packs.

## Content taxonomy
- Lessons: lesson ids, names, charset, and length ranges in `data/lessons.json`.
- Enemies: kinds, speed/armor/word length rules in `sim/enemies.gd` and `sim/words.gd`.
- Buildings: costs, production, defense, and upgrades in `sim/buildings.gd`.
- Terrain: base types and map generation logic in `sim/map.gd`.
- Events/POIs: exploration reward entries and optional log events (future data file).

## Definition of a content unit
- Lesson: id, name, description, charset, lengths, tests for validation and determinism.
- Enemy: kind config (speed/armor/hp bonus), word bank mapping, glyph, tests for spawn determinism.
- Building: cost, effect, adjacency rules, and inspector preview rules.
- Event/POI: deterministic reward rule and a log output entry.

## Data pipeline approach
- Source data lives under `apps/keyboard-defense-godot/data/`.
- Lessons stay deterministic via hash-based word selection (no RNG state usage).
- Add headless tests for new data files (schema presence + core constraints).
- Keep sim-only logic in `res://sim/**` and UI rendering in `res://game/**`.

## Staged release plan
Phase 1
- Add 2 new lessons (early-stage charsets).
- Add 1 new enemy variant and 1 new building type.
- Extend tests for lessons and enemy determinism.

Phase 2
- Add 2-3 mid-tier lessons and a new exploration event table.
- Add UI cues for new content types (icons/glyphs only).

Phase 3
- Add a full lesson progression track plus optional advanced drills.
- Add POI/event variety with deterministic reward rules.

## Acceptance criteria
- New content loads without errors in headless tests.
- Lessons pass validation: charset, length ranges, and uniqueness rules.
- Deterministic outcomes unchanged for the same seed and action sequence.
- UI surfaces new content without breaking typing flow.

## Test plan
- Extend unit tests for lesson validation and word generation.
- Add determinism tests for new enemy kinds.
- Manual smoke: run day->night->dawn with new content enabled.

## References (planpack)
- `docs/plans/planpack_2025-12-27_tempPlans/generated/CONTENT_DATA_PIPELINE_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/TYPING_PEDAGOGY.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/DATA_SCHEMAS.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/preprod/CONTENT_PIPELINE_WORDPACKS.md`
