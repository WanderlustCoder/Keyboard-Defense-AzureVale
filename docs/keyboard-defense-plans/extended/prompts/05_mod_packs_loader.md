# Codex Milestone EXT-05 - Content Pack Loader (Safe)

## LANDMARK: Goal
Allow loading additional content packs from a local folder with strict validation.

## Tasks
1) Implement pack manifest loader:
   - reads `user://content_packs/<pack_id>/pack.json`
   - validates against `docs/keyboard-defense-plans/extended/schemas/pack.schema.json`
2) Load referenced content files and merge with base content.
3) Add settings UI:
   - list packs
   - enable or disable pack (typing)
4) Enforce safety:
   - no path traversal
   - no URL loads
   - schema validation required

## Tests
- Load base pack only.
- Load a valid additional pack.
- Reject invalid pack.
