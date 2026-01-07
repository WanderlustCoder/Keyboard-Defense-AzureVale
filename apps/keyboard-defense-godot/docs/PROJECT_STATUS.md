# Project Status

## Overview
Keyboard Defense is a Godot 4 typing-first kingdom defense roguelite. The sim layer is deterministic and data-first, while the game layer renders a tile grid, HUD, and typing-driven day/night loop.
Reference research summary: `docs/RESEARCH_SFK_SUMMARY.md` (inspiration only).
Plan library: `docs/plans/README.md` (reference material only).

## Current Feature Set
- Day phase
  - Gather, explore, build, upgrade, demolish, cursor movement, inspect, map.
  - Action points, resource costs, adjacency bonuses, and wall/tower path blocking.
  - Midgame economy guardrails (stone catch-up explores, low-food bonus, storage caps) with a one-time UI note.
  - Save/load and new run commands.
- Night phase
  - Turn-based typing defense with enemy variety (raider/scout/armored) and per-enemy words.
  - Enemies spawn on borders, move via pathfinding, and are targeted by typing.
  - Towers attack with upgrade scaling; wave panel shows enemies and progress bars.
- Typing tutor features
  - Live prefix feedback, safe Enter gating, typing stats, reports, history, trends, and coaching.
  - Practice goals with thresholds and colored goal badge.
  - Lesson selection and per-lesson progress with recent trends and sparklines.
- UI and controls
  - Typing-first command bar, panels (settings, lessons, trend, history, report), and hotkeys.
  - Rebindable actions (settings, lessons, trend, compact, history, report, goal) with in-game bind flow and controls list.
  - UI scale setting (settings scale/font) and compact panels mode for readability on smaller screens.
  - Accessibility checklist: `docs/ACCESSIBILITY_VERIFICATION.md` (manual 1280x720 readability + keyboard-only checks, plus `settings verify` output and keybind conflict warnings).
  - Onboarding tutorial flow with step engine, copy-based panel, and replay/skip controls.

## Persistence Model
- Run savegame: `user://savegame.json` stores the current deterministic run state (map, resources, phase, enemies, lesson id, RNG state).
- Profile: `user://profile.json` stores typing history, lifetime stats, practice goal, preferred lesson, lesson progress, keybinds, and UI preferences.

## Architecture Snapshot
- `sim/**`: deterministic rules and data helpers (no Node/Scene dependencies).  
- `game/**` and `ui/**`: rendering, input routing, panels, and profile persistence.
- Tests: headless via `godot --headless --path . --script res://tests/run_tests.gd` (wrappers in `scripts/`).
- Scenario harness (Phase 2): `res://tools/run_scenarios.gd` runs `data/scenarios.json` headless with tag/priority filtering and expanded balance coverage.
- Scenario reports and summaries are written under `Logs/ScenarioReports/` for CI-friendly collection (via `--out-dir`).

## Planning
- `docs/ROADMAP.md` is the authoritative milestone list.
- `docs/plans/p0/` contains P0 action plans tied to roadmap IDs.
- `docs/plans/README.md` is the plan library index for imported references.
- `docs/plans/PLANPACK_TRIAGE.md` tracks planpack adoption decisions.

## P0-ACC Signoff (manual)
- [ ] Run `docs/ACCESSIBILITY_VERIFICATION.md` at 1280x720.
- [ ] Capture `settings verify` output and panel screenshots for the milestone report.

## Definition of Done (Playable Vertical Slice)
- [ ] New player can start a run and see the HUD/grid.
- [ ] Commands and hotkeys are discoverable (help/settings) and usable without mouse.
- [ ] Player can survive at least one night and see a typing report.
- [ ] Save/load restores the run state reliably.
- [ ] Lessons, goals, and trend panels provide feedback without affecting sim outcomes.
