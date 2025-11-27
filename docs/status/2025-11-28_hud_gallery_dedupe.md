# HUD Gallery Deduplication - 2025-11-28

## Summary
- Deduped HUD gallery generation so each shot id renders a single row while retaining all metadata sources. The builder now prefers live artifact captures when both artifact + fixture metadata are present.
- Added `metaFiles` output to the gallery JSON and surfaced multiple sources per id in the Markdown metadata section so dashboards/docs stay transparent about inputs.
- Introduced regression coverage for the dedupe preference and source retention behavior.
- Regenerated `docs/hud_gallery.md` and `artifacts/summaries/ui-snapshot-gallery.json` to remove duplicate rows and list combined sources; Codex dashboard/portal now render all HUD shots (no ellipsis when <=10) and report the metadata source count.

## Next Steps
1. Refresh live HUD captures via `node scripts/hudScreenshots.mjs --ci --out artifacts/screenshots` once Playwright is available to replace placeholder PNGs.
2. Fold the `metaFiles` field into any downstream dashboard tooling that consumes the gallery JSON, if needed.

## Follow-up
- `docs/codex_pack/tasks/41-hud-gallery-dedupe.md`
