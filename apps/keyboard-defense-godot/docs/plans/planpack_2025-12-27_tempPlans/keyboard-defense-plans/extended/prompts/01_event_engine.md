# Codex Milestone EXT-01 - Implement Deterministic Event Engine

## LANDMARK: Goal
Add a data-driven event system (POIs -> event tables -> events -> choices) that
is deterministic and testable.

## Constraints
- No renderer or UI dependence. Put core logic under `scripts/sim/events/`.
- Do not introduce external runtime dependencies.
- Add tests for determinism and schema validation.

## Tasks
1) Create types and helpers:
   - `Event`, `Choice`, `EventTable`, `POI`, `Effect`
2) Implement `EventRng` wrapper around the existing seeded RNG utility (or add one).
3) Implement selection:
   - `select_poi(...)`
   - `select_event_from_table(...)`
   - `resolve_choice(...)` producing Effects applied to run state
4) Add cooldown support (`cooldown_days`) and a simple seen-history filter.

## LANDMARK: Determinism tests
- With fixed seed, selecting events from the same table yields the same sequence.
- Changing seed changes the sequence.
- History and cooldowns work deterministically.

## Deliverables
- `apps/keyboard-defense-godot/scripts/sim/events/`
- `apps/keyboard-defense-godot/scripts/tests/test_event_determinism.gd`
- Minimal fixtures in `apps/keyboard-defense-godot/data/events/fixtures/` for tests.
