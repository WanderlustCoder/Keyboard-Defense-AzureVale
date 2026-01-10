# Current Task

## Active Work
<!-- Update this section when starting new work -->

*No active task.*

## Recently Completed

**Task:** Development infrastructure for Claude Code automation

**Completed:** 2026-01-10

**What was done:**
- Added schema validation script (`scripts/validate_schemas.py`)
- Added `.claude/` context directory with memory files
- Added pre-commit validation script (`scripts/precommit.sh`)
- Updated CLAUDE.md and AGENTS.md with documentation

## Next Steps
<!-- What should happen after current work completes -->

1. Update `assets_manifest.schema.json` to include `category` and `source_svg` fields (validation found schema is outdated)
2. Consider adding schemas for files that don't have them (`buildings.json`, `story.json`, etc.)

## Notes
<!-- Any context that would help resume this work -->

- Schema validation requires `pip install jsonschema`
- Pre-commit script can run in `--quick` mode to skip slow tests
