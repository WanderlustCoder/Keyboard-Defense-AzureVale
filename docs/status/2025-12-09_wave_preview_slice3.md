# Wave Preview UI - Slice 3 (2025-12-09)
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## What shipped
- `npm run wave:preview` now serves a designer-focused HTML preview with lane filters, event-type toggles (spawns/hazards/dynamic/evac/boss), and per-wave timelines that highlight spawns, hazards, dynamic events, evacuations, and boss markers.
- Live reload via SSE when the config or schema changes; validation failures are rendered inline with guidance so fixes auto-refresh.
- Feature toggle panel surfaces `dynamicSpawns`, `eliteAffixes`, `evacuationEvents`, and boss flags for quick auditing, and each wave card exposes searchable tokens for tiers, affixes, lanes, and evac words.

## How to use
- Generate/update the designer config (`npm run wave:edit -- --create-from-core --force`) and run `npm run wave:preview -- --config config/waves.designer.json --open`.
- Filter by lane or event type, search by tier/affix/word, and leave the tab open--the page reloads as soon as the config or schema changes.

## Verification
- `cd apps/keyboard-defense && npx vitest run waveConfigEditor waveConfigPreviewRender`

## Backlog
- #38 Wave Config Schema/Editor (slice 3 complete)

