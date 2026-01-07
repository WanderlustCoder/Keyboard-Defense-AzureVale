# Codex prompt - Milestone F: first playable expansion

## Goal
Expand the first playable loop:
- add new lessons and drill templates
- extend the map with additional nodes
- add at least one new upgrade per category

## Constraints
- Update data/*.json and ensure integrity tests pass.
- Keep new content aligned with the typing curriculum.

## Landmarks
- data/lessons.json
- data/drills.json
- data/map.json
- data/kingdom_upgrades.json
- data/unit_upgrades.json
- scripts/tests/test_data_integrity.gd

## Acceptance
- scripts/run_tests.ps1 passes.
- New nodes unlock in sequence and battles run end-to-end.
