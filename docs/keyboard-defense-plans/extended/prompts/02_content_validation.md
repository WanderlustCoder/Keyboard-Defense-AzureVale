# Codex Milestone EXT-02 - Add Content Validators (Schemas + CLI)

## LANDMARK: Goal
Add JSON schema validation for events, POIs, and packs plus a command that
validates all content.

## Tasks
1) Add schemas from `docs/keyboard-defense-plans/extended/schemas/` into the
   runtime validator module.
2) Implement a validator script:
   - `apps/keyboard-defense-godot/scripts/tools/validate_extended_content.gd`
   - loads all JSON under `apps/keyboard-defense-godot/data/`
   - validates against schemas
   - enforces custom rules:
     - prompt length cap
     - required pedagogy tags
     - duplicate ID detection
3) Wire into tests:
   - add a test that calls the validator and asserts success
4) If CI exists, run the validator in CI.

## LANDMARK: Output
- On error, print:
  - file path
  - JSON path to invalid field
  - human readable message

## Tests
- Add a failing fixture and assert validator catches it.
- Add a passing fixture and assert success.
