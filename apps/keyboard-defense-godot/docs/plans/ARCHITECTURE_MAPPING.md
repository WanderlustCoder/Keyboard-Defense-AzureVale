# Architecture Mapping

## Current architecture snapshot
- `res://sim/**`: deterministic game rules, intent parsing, and state transitions.
- `res://game/**`: UI orchestration, profile persistence, panels, and rendering.
- `res://ui/**`: command bar and input behavior.
- `res://tests/**`: headless unit tests and smoke boot checks.

## Contract rules
- Sim logic must not depend on Nodes, scenes, or rendering.
- UI-only intents are handled in `game/main.gd` before reducer calls.
- Persistence is split:
  - `user://savegame.json` for run state
  - `user://profile.json` for preferences, history, and onboarding

## Planpack mapping (pre-Godot -> current files)
| Planpack doc | Legacy assumption | Current mapping | Notes |
| --- | --- | --- | --- |
| `planpack_2025-12-27_tempPlans/keyboard-defense-plans/ARCHITECTURE.md` | Monolithic runtime modules | `sim/**` + `game/**` split | Treat planpack as conceptual; update paths. |
| `planpack_2025-12-27_tempPlans/generated/CORE_SIM_GAMEPLAY_PLAN.md` | Single reducer | `sim/apply_intent.gd` + `sim/tick.gd` | Intent-based reducers already in place. |
| `planpack_2025-12-27_tempPlans/keyboard-defense-plans/preprod/SAVE_SYSTEM_SPEC.md` | Unified save/profile | `game/typing_profile.gd` + `sim/save.gd` | Split is intentional. |
| `planpack_2025-12-27_tempPlans/GODOT_TESTING_PLAN.md` | Custom harness | `tests/run_tests.gd` + scripts | Headless harness is active. |

## Mismatches and guidance
- Some planpack docs assume non-Godot UI layers; treat them as UX guidance only.
- Old schemas may not match current JSON layout; follow `docs/plans/SCHEMA_ALIGNMENT_PLAN.md`.

## How to add a feature safely
- Add sim logic in `res://sim/**` only.
- Add UI intent handling in `game/main.gd` without mutating sim state.
- Add tests for parser + reducer + data validation.
- Update ROADMAP and CHANGELOG as part of the milestone.
