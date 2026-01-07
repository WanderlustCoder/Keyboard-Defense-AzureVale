# Codex prompt - Milestone D: battle interventions

## Goal
Add battle intervention prompts that trigger during drills:
- spawn intervention prompts at defined intervals
- resolve prompts to apply threat relief or buffs
- record outcomes in battle summaries

## Constraints
- Keep logic in scripts/.
- Use data/ for new intervention definitions.
- Add tests for success and failure cases.

## Landmarks
- scripts/Battlefield.gd
- data/drills.json (or new data file for interventions)
- scripts/tests/test_battle_smoke.gd
- scripts/tests/test_battle_autoplay.gd

## Acceptance
- scripts/run_tests.ps1 passes.
- Interventions trigger and resolve without blocking drills.
