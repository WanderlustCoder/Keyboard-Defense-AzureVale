# Codex Milestone: Save System and Migration

## Landmark: Objective
Implement the save system described in
`docs/keyboard-defense-plans/preprod/SAVE_SYSTEM_SPEC.md`:
- profile save (settings + unlocks + typing profile)
- run save (seed + rng state + sim snapshot)
- schema versioning and migrations
- determinism sanity checks in tests

## Landmark: Tasks
1) Add schemas
   - Ensure `docs/keyboard-defense-plans/preprod/schemas/savegame.schema.json` is referenced in tooling.
2) Implement save module
   - `apps/keyboard-defense-godot/scripts/save/save_manager.gd`
   - `load_save() -> SaveData`
   - `write_save(save: SaveData) -> void`
   - store in `user://keyboard_defense_save.json`
3) Implement migrations
   - `migrate_save(raw) -> SaveCurrent`
   - increment `save_version` only when schema changes
4) Integrate with game
   - on run start/end: update active run
   - on settings change: persist profile
5) Tests
   - roundtrip save/load
   - migration from a fixture older version
   - deterministic golden run stores and restores without changing state

## Landmark: Verification steps
- `.\apps\keyboard-defense-godot\scripts\run_tests.ps1`
- manual check: start run -> quit -> resume works

Summarize with LANDMARKS:
- A: Save schema and migration approach
- B: Storage paths and formats
- C: Tests and fixtures
