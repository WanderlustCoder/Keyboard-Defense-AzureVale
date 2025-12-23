---
id: hud-gallery-dedupe
title: "Deduplicate HUD gallery rows and preserve metadata sources"
priority: P2
effort: S
depends_on: []
produces:
  - docs/hud_gallery.md
  - apps/keyboard-defense/artifacts/summaries/ui-snapshot-gallery.json
status_note: docs/status/2025-11-28_hud_gallery_dedupe.md
backlog_refs:
  - "#72"
---
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

**Context**  
The HUD gallery began duplicating rows whenever both live captures and fixtures were present, making the doc noisy and hiding which metadata source was used. We need deterministic deduping that prefers live artifact captures while still listing every metadata source.

## Steps

1. Update `scripts/docs/renderHudGallery.mjs` to merge entries by shot id, preferring artifact metadata and retaining a list of all source files.
2. Reflect the merged `metaFiles` in the Markdown metadata source section and JSON payload so dashboards know which sources contributed.
3. Add regression coverage for the dedupe behavior.
4. Regenerate the gallery/JSON so only one row per shot remains while keeping both fixture + artifact sources listed.

## Acceptance criteria

- Gallery output shows a single row per shot id even when multiple metadata files exist.
- Metadata sources list includes all contributing `.meta.json` files.
- JSON payload surfaces `metaFiles` for each shot.
- Tests cover the dedupe preference and source retention behavior.

## Verification

- `npm run docs:gallery`
- `npm run test -- renderHudGallery`
- `npm run codex:validate-pack`






