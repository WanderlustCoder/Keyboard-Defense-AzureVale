> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Tutorial & Castle Panel Condensed States - 2025-11-18

**Summary**
- Tutorial banner now adapts to compact viewports (<540px tall) with a built-in preview toggle so lengthy guidance no longer shoves the HUD off-screen on short, landscape devices.
- Castle passives, gold events, and pause-menu passive cards now consider viewport height (in addition to width) when deciding whether to collapse by default, keeping mobile HUDs tidy without hiding data permanently.
- HUD tests gained viewport-aware matchMedia stubs that assert the condensed flow, validating both the DOM structure (message container + toggle) and the persistence of player preferences when height constraints change.
- Styles expose a focused toggle control with truncated preview text, including compact typography and body-level `data-compact-height` hooks for future responsive tweaks.
- Analytics exports now attach a `ui` snapshot capturing tutorial banner layout, HUD/pause collapse preferences, and diagnostics overlay condensed state, so automation artifacts can distinguish mobile-first captures without scraping the DOM.
- `scripts/hudScreenshots.mjs` now includes the live `uiSnapshot` metadata alongside each screenshot summary entry, making it obvious whether HUD cards were collapsed, diagnostics were minimized, or the tutorial banner was condensed when the PNG was captured.
- `scripts/analyticsAggregate.mjs` now emits the same UI snapshot fields (banner, HUD, options, diagnostics, player preferences) as dedicated CSV columns, and the CLI tests assert their presence so regressions are caught automatically.
- `scripts/docs/renderHudGallery.mjs` now copies the raw `uiSnapshot` details into both `docs/hud_gallery.md` and `artifacts/summaries/ui-snapshot-gallery*.json`, adding a dedicated column so reviewers see condensed state, collapsed sections, and viewport flags without opening the `.meta.json`.

**Next Steps**
- Completed; analytics CLI tests now assert that `ui*` columns remain populated (or intentionally blank) for every row, so regressions in the snapshot schema will fail the suite immediately.

## Follow-up
- `docs/codex_pack/tasks/33-tutorial-ui-snapshot-publishing.md`
- `docs/status/2025-11-20_ui_snapshot_gallery.md`

