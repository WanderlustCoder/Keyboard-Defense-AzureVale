# Codex Milestone: Acceptance Harness and Content Validation

## Landmark: Objective
Create a minimal acceptance harness and automated checks so future work is safer:
1) A validator for JSON content packs (wordpacks, drills, upgrades)
2) A deterministic golden-run sim test (seeded) that catches unintended rule changes
3) An optional dev scene that can exercise the loop quickly

## Landmark: Constraints
- Godot 4 and GDScript
- Keep game rules deterministic and data-driven
- No third-party assets copied from other games

## Landmark: Tasks
1) Implement a validator script
   - `apps/keyboard-defense-godot/scripts/tools/validate_content.gd`
   - It should:
     - load all JSON under `apps/keyboard-defense-godot/data/`
     - validate against schemas under `apps/keyboard-defense-godot/data/schemas/`
     - print a clear report (file -> pass/fail; error messages)
     - exit non-zero on failure
2) Add a headless test
   - `apps/keyboard-defense-godot/scripts/tests/test_content_validation.gd`
   - It should invoke the validator in-process and assert success
3) Add a deterministic sim golden run test
   - `apps/keyboard-defense-godot/scripts/tests/test_golden_run.gd`
   - Choose a seed, simulate fixed steps, serialize a small snapshot
   - Compare to a fixture (JSON) committed to the repo
4) Optional: Dev Acceptance Scene
   - `apps/keyboard-defense-godot/scenes/dev/AcceptanceScene.tscn`
   - Small map, one battle loop, quick metrics overlay
   - Wire behind a debug flag

## Landmark: Code quality expectations
- Keep validator and tests deterministic and fast.
- Include clear error messages that help fix content.

## Landmark: Verification steps (must run)
- `.\apps\keyboard-defense-godot\scripts\run_tests.ps1`

## Landmark: Deliverables
- Validator script and tests
- Golden run fixture and test
- Optional acceptance scene

When you finish, summarize changes using LANDMARKS:
- LANDMARK A: Files added or changed
- LANDMARK B: How to run validation and tests
- LANDMARK C: Known limitations or next steps
