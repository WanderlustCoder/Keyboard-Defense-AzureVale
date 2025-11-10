## Tutorial & Castle Panel Condensed States - 2025-11-18

**Summary**
- Tutorial banner now adapts to compact viewports (<540px tall) with a built-in preview toggle so lengthy guidance no longer shoves the HUD off-screen on short, landscape devices.
- Castle passives, gold events, and pause-menu passive cards now consider viewport height (in addition to width) when deciding whether to collapse by default, keeping mobile HUDs tidy without hiding data permanently.
- HUD tests gained viewport-aware matchMedia stubs that assert the condensed flow, validating both the DOM structure (message container + toggle) and the persistence of player preferences when height constraints change.
- Styles expose a focused toggle control with truncated preview text, including compact typography and body-level `data-compact-height` hooks for future responsive tweaks.
- Analytics exports now attach a `ui` snapshot capturing tutorial banner layout, HUD/pause collapse preferences, and diagnostics overlay condensed state, so automation artifacts can distinguish mobile-first captures without scraping the DOM.
- `scripts/hudScreenshots.mjs` now includes the live `uiSnapshot` metadata alongside each screenshot summary entry, making it obvious whether HUD cards were collapsed, diagnostics were minimized, or the tutorial banner was condensed when the PNG was captured.
- `scripts/analyticsAggregate.mjs` now emits the same UI snapshot fields (banner, HUD, options, diagnostics, player preferences) as dedicated CSV columns, and the CLI tests assert their presence so regressions are caught automatically.

**Next Steps**
1. Surface the `uiSnapshot` details inside docs/regression galleries so reviewers don't need to open the JSON artifact manually.
2. Extend analytics CLI tests to assert the presence of `ui` metadata when consuming exported snapshots, preventing regressions when the snapshot schema evolves.
