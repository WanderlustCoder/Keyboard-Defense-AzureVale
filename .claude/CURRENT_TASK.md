# Current Task

## Active Work
<!-- Update this section when starting new work -->

*No active task.*

## Recently Completed

**Task:** Test coverage expansion and data validation fixes

**Completed:** 2026-01-12

**What was done:**
- Added tests for ScenarioReport, ButtonFeedback, ThemeColors modules
- Added version fields to 7 data files (building_upgrades, buildings, drills, kingdom_upgrades, map, research, unit_upgrades)
- Updated 4 schemas to allow version field (drills, kingdom_upgrades, map, unit_upgrades)
- Added procedural fallback portraits for Elder Lyra in dialogue_box.gd and lyra_dialogue.gd
- All schema validations now pass (18/18)
- Test suite now at ~3,000+ assertion calls

**Previous Task:** Development infrastructure for Claude Code automation

**Completed:** 2026-01-10

**What was done:**
- Added schema validation script (`scripts/validate_schemas.py`)
- Added `.claude/` context directory with memory files
- Added pre-commit validation script (`scripts/precommit.sh`)
- Updated CLAUDE.md and AGENTS.md with documentation

## Next Steps
<!-- What should happen after current work completes -->

1. Consider adding schemas for remaining files without them (`buffs.json`, `expeditions.json`, `loot_tables.json`, `research.json`, `resource_nodes.json`, `story.json`, `tower_upgrades.json`, `towers.json`)
2. P0-BAL-001: Final balance validation pass
3. P0-ACC-001: Final 1280x720 accessibility audit
4. P0-EXP-001: Windows export smoke test

## Notes
<!-- Any context that would help resume this work -->

- Schema validation requires `pip install jsonschema`
- Pre-commit script can run in `--quick` mode to skip slow tests
- assets_manifest schema already has `category` and `source_svg` fields (was up to date)
