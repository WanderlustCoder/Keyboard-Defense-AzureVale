# Project Master Plan (Keyboard Defense)

## Purpose
Align the near-term roadmap with current project state, determinism rules, and
headless validation requirements.

## Sources
- apps/keyboard-defense-godot/docs/ROADMAP.md
- apps/keyboard-defense-godot/docs/PROJECT_STATUS.md
- docs/keyboard-defense-plans/PROJECT_ROADMAP.md
- docs/keyboard-defense-plans/CODEX_CLI_PLAYBOOK.md

## Current baseline
- Day/night loop with command-bar driven actions and deterministic sim layer.
- Typing-first night defense with per-enemy words and performance stats.
- Headless tests via `res://tests/run_tests.gd`.

## Milestones (P0/P1)
1) Onboarding and first-run guidance (P0)
   - Guided first night tutorial and command primer.
   - Minimal in-game checklist for day/night flow.
   - Success: new player can start a run, end day, and survive a night.
2) Balance pass for core loop (P0)
   - Tune enemy stats, tower costs/upgrades, and word length ranges.
   - Validate difficulty curve for days 1-7 with deterministic seeds.
   - Success: balance tests show smooth progression without hard gates.
3) Accessibility and readability polish (P1)
   - Improve panel readability, font sizes, and contrast.
   - Add reduced motion and extra legibility toggles.
   - Success: UI layout tests pass and readability checks are documented.
4) Content expansion (P1)
   - Add lessons, enemy variants, and building roster expansions.
   - Add exploration events and road-based map expansion.
   - Success: new content validates against schemas and data tests pass.
5) Packaging and export pipeline (P1)
   - Document export presets and Windows build workflow.
   - Add a smoke-test checklist for release builds.
   - Success: headless boot and smoke checklist are documented and repeatable.

## Cross-cutting requirements
- Deterministic sim logic stays in `res://sim/**`; UI/game code uses intents and
  renders events only.
- Data remains JSON-driven and validated against schemas.
- Every milestone includes headless tests and a smoke boot attempt.

## Risks
- Onboarding complexity overwhelms new typists.
- UI density reduces clarity and increases cognitive load.
- Balance drift if rewards scale too steeply or too slowly.

## Definition of done (milestone)
- Headless tests pass via `godot --headless --path . --script res://tests/run_tests.gd`.
- Smoke boot succeeds in headless mode.
- Documentation updated with roadmap alignment and known issues.
