# Backlog Workbook Spec (Keyboard Defense)

This is a planning artifact for tracking epics, stories, and delivery cadence.
It replaces the spreadsheet in the original pack with a text-first spec.

## Suggested sheets or sections

### Epics
- id
- name
- milestone (VS or MVP)
- owner
- status
- notes

### Stories
- id
- epic_id
- summary
- player_value
- acceptance_criteria
- data_or_schema_impacts
- test_plan
- estimate
- status

### Tasks
- story_id
- task description
- owner
- status
- blocking dependencies

### Release cadence
- sprint number
- dates
- focus theme
- playtest target

## Integration notes
- Epic definitions live in `docs/keyboard-defense-plans/business/backlog/epics.yaml`.
- Use `docs/keyboard-defense-plans/business/USER_STORY_FORMAT.md` for story shape.
- Use `docs/keyboard-defense-plans/business/QUALITY_GATES.md` for promotion criteria.
