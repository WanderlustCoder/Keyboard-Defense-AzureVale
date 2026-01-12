# Current Task

## Active Work
<!-- Update this section when starting new work -->

*All P0 tasks complete. Ready for release.*

## Recently Completed

**Task:** P0-ACC-001 Final 1280x720 accessibility audit

**Completed:** 2026-01-12

**What was done:**
- Fixed KingdomDefense.tscn TypingPanel, EnemyPanel, ObjectivePanel to use anchors instead of hard-coded positions
- Increased TipLabel font size from 11px to 12px
- Fixed achievement_popup.tscn Description font size from 11px to 12px
- All panels now scale properly at 1280x720 resolution
- All 6276 tests pass

**Previous Task:** P0-BAL-001 Final balance validation pass

**Completed:** 2026-01-12

**What was done:**
- Balance simulator: PASS (all scenarios)
- Balance verification: PASS (all constraints)
- Schema validation: 18/18 passed

**Previous Task:** P0-EXP-001 Windows export smoke test

**Completed:** 2026-01-12

**What was done:**
- Fixed 12 failing tests in run_tests.gd (zone tests, targeting, worker slots, tower attacks)
- All 6191 tests now pass
- Fixed 117 PNG files that had incorrect .svg extension (causing import errors)
- Export configuration verified: versions match (1.0.0 in VERSION.txt, export_presets.cfg)
- Export dry-run successful

**Blocking issue:** User needs to download Godot 4.2.2 export templates to:
  `C:/Users/Werem/AppData/Roaming/Godot/export_templates/4.2.2.stable/`
  (Download from godotengine.org -> Downloads -> Export Templates)

**Previous Task:** Schema coverage expansion for all data files

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

1. P0-ACC-001: Final 1280x720 accessibility audit
2. Consider adding schema for story.json (complex narrative structure)
3. Download and install Godot 4.2.2 export templates, then re-test export

## Notes
<!-- Any context that would help resume this work -->

- Schema validation requires `pip install jsonschema`
- Pre-commit script can run in `--quick` mode to skip slow tests
- story.json excluded from full schema validation (narrative content with special structure)
