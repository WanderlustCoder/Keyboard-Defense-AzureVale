# Schema Alignment Plan

## Current JSON-like artifacts
- `data/lessons.json` (lesson packs and word lengths)
- `data/drills.json` (drill templates)
- `data/map.json` (campaign nodes and overrides)
- `data/kingdom_upgrades.json`
- `data/unit_upgrades.json`
- `data/assets_manifest.json`
- `user://savegame.json` (run state)
- `user://profile.json` (prefs, history, keybinds, onboarding)

## Planpack schema mismatches
- `planpack_2025-12-27_tempPlans/keyboard-defense-plans/DATA_SCHEMAS.md` uses a
  different lesson schema shape and pre-Godot naming.
- Content pipeline docs assume separate wordpack files not yet adopted.

## What we will formalize
- Lessons and drills schemas (Phase 1).
- Profile and savegame formats (Phase 2 with migrations).
- Asset manifest schema (Phase 2).

## Phased approach
Phase 1: Document schemas and add presence tests only.
Phase 2: Add optional validators (non-blocking, logs warnings).
Phase 3: Make validators gating with versioned migrations.

## Acceptance criteria
- Schema docs exist for the active JSON files.
- Headless tests verify presence of schema docs and core data fields.
- Migrations documented before any breaking change.

## Test plan
- Add doc presence tests for schema docs (no content assertions).
- Add lightweight field checks for lessons/drills when validators exist.

## References (planpack)
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/DATA_SCHEMAS.md`
- `docs/plans/planpack_2025-12-27_tempPlans/generated/CONTENT_DATA_PIPELINE_PLAN.md`
