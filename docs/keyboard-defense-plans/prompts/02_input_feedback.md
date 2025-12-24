# Codex prompt - Milestone B: input and feedback clarity

## Goal
Improve typing feedback and HUD clarity:
- ensure labels stay synchronized with battle state
- tighten feedback messaging for hits, errors, and clears
- validate default visibility of overlays

## Constraints
- Keep UI changes in scenes/ and scripts/.
- Add or update layout tests in scripts/tests/.

## Landmarks
- scenes/Battlefield.tscn
- scripts/Battlefield.gd
- scripts/tests/test_battle_hud_state.gd
- scripts/tests/test_battle_overlays.gd

## Acceptance
- scripts/run_tests.ps1 passes.
- HUD text remains readable on base and scaled viewports.
- Feedback uses consistent tone and timing.
