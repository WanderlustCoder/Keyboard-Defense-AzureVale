# Content and Data Pipeline Plan

## Purpose
Expand lessons, map content, and upgrades while keeping JSON data validated and
audited assets within budget.

## Sources
- apps/keyboard-defense-godot/docs/PROJECT_STATUS.md
- docs/GODOT_PROJECT.md
- docs/keyboard-defense-plans/DATA_SCHEMAS.md
- docs/keyboard-defense-plans/TYPING_PEDAGOGY.md
- docs/keyboard-defense-plans/assets/README.md
- docs/keyboard-defense-plans/assets/ASSET_CREATION_OVERVIEW.md

## Scope
- Lessons, drills, map nodes, and upgrades in JSON.
- Schema validation and data integrity tests.
- Asset manifest compliance for art/audio additions.

## Workstreams
1) Lesson and drill expansion
   - Add new lessons aligned with typing pedagogy stages.
   - Define drill templates and pacing with readable hints.
2) Map and progression content
   - Add nodes and branching routes aligned with new lessons.
   - Ensure rewards and unlocks remain balanced.
3) Upgrade catalog growth
   - Expand kingdom/unit upgrades with clear, testable effects.
4) Data schema hygiene
   - Update schemas when adding new fields.
   - Extend data integrity tests to cover new content types.
5) Asset pipeline
   - Use procedural or original placeholder assets only.
   - Update `apps/keyboard-defense-godot/data/assets_manifest.json` for every
     new art/audio asset.

## Acceptance criteria
- All data files validate against schemas in headless tests.
- New lessons and drills appear in map content without runtime errors.
- Asset audit passes with manifest completeness and size constraints.
