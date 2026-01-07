# Core Sim and Gameplay Plan

## Purpose
Define the deterministic gameplay core (day/night loop, typing defense, and
progression) with clear test coverage and data dependencies.

## Sources
- apps/keyboard-defense-godot/docs/PROJECT_STATUS.md
- apps/keyboard-defense-godot/docs/COMMAND_REFERENCE.md
- docs/keyboard-defense-plans/GDD.md
- docs/keyboard-defense-plans/BALANCING_MODEL.md
- docs/keyboard-defense-plans/TYPING_PEDAGOGY.md
- docs/keyboard-defense-plans/ARCHITECTURE.md

## Scope
- Sim layer: deterministic rules, RNG state, and data helpers (`res://sim/**`).
- Game layer: intent routing, event rendering, and panel updates.
- Day phase: gather/build/explore/upgrade/demolish/end actions.
- Night phase: typing defense, enemy words, hit/miss logic, and reward flow.

## Workstreams
1) Deterministic sim state
   - Define state structs for map, resources, enemies, phase, and RNG.
   - Ensure identical outcomes for same seed and action list.
   - Persist/restore via save/load without UI dependencies.
2) Typing system and coaching
   - Prefix-safe input rules and Enter gating for night typing.
   - Accuracy/WPM tracking and streak-based feedback.
   - Optional coaching goals that do not alter sim balance.
3) Combat pacing and balance
   - Threat rate, relief per correct word, and mistake penalties.
   - Buff triggers with short, readable durations.
   - Tune word-length ranges per night day index.
4) Progression and economy
   - Gold rewards, upgrade effects, and scaling costs.
   - Ensure base rewards progress without forcing high WPM.
5) Battle smoke and integration checks
   - Simulate a full night cycle with deterministic inputs.
   - Validate victory/defeat paths and summary outputs.

## Acceptance criteria
- Determinism: same seed + actions yields identical results across runs.
- Input rules match command reference (prefix-safe, miss only on invalid text).
- Balance tests confirm smooth day 1-7 curve with no hard gates.
- Save/load restores sim state without UI-specific data.
- Headless tests cover core sim, typing stats, and night battle smoke.
