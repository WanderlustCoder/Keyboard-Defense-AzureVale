## Tutorial & Castle Panel Condensed States - 2025-11-18

**Summary**
- Tutorial banner now adapts to compact viewports (<540px tall) with a built-in preview toggle so lengthy guidance no longer shoves the HUD off-screen on short, landscape devices.
- Castle passives, gold events, and pause-menu passive cards now consider viewport height (in addition to width) when deciding whether to collapse by default, keeping mobile HUDs tidy without hiding data permanently.
- HUD tests gained viewport-aware matchMedia stubs that assert the condensed flow, validating both the DOM structure (message container + toggle) and the persistence of player preferences when height constraints change.
- Styles expose a focused toggle control with truncated preview text, including compact typography and body-level `data-compact-height` hooks for future responsive tweaks.

**Next Steps**
1. Pull the same compact-height heuristic into diagnostics overlays to prevent the telemetry cards from overlapping the game surface on phones held sideways.
2. Surface the condensed-state preference in analytics snapshots so automation artifacts can differentiate between mobile-first and desktop HUD captures.
