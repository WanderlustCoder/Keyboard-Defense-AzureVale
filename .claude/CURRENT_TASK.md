# Current Task

## Active Work
<!-- Update this section when starting new work -->

*No active task.*

## Recently Completed

**Task:** Schema coverage expansion for all data files

**Completed:** 2026-01-12

**What was done:**
- Created 9 new JSON schemas: buffs, towers, buildings, building_upgrades, expeditions, loot_tables, research, resource_nodes, tower_upgrades
- Updated validate_schemas.py SCHEMA_MAP to include all new schemas
- Now 16/17 data files have full schema validation (only story.json has basic validation)
- All 18 validation checks pass

**Previous Task:** Test coverage expansion and data validation fixes

**Completed:** 2026-01-12

**What was done:**
- Added tests for ScenarioReport, ButtonFeedback, ThemeColors modules
- Added version fields to 7 data files (building_upgrades, buildings, drills, kingdom_upgrades, map, research, unit_upgrades)
- Updated 4 schemas to allow version field (drills, kingdom_upgrades, map, unit_upgrades)
- Added procedural fallback portraits for Elder Lyra in dialogue_box.gd and lyra_dialogue.gd
- Test suite now at ~3,000+ assertion calls

## Next Steps
<!-- What should happen after current work completes -->

1. P0-BAL-001: Final balance validation pass
2. P0-ACC-001: Final 1280x720 accessibility audit
3. P0-EXP-001: Windows export smoke test
4. Consider adding schema for story.json (complex narrative structure)

## Notes
<!-- Any context that would help resume this work -->

- Schema validation requires `pip install jsonschema`
- Pre-commit script can run in `--quick` mode to skip slow tests
- story.json excluded from full schema validation (narrative content with special structure)
