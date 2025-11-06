## Gold Event History Overlay - 2025-11-08

**Summary**
- `RuntimeMetrics` now exposes `recentGoldEvents` (last three entries, cloned from analytics) so any HUD/automation consumer can render short economy timelines without parsing the full analytics payload.
- Diagnostics overlay renders a dedicated “Recent gold events” block with delta, resulting total, timestamp, and time-since values, giving designers and CI smoke logs immediate context for sudden resource swings.
- Tutorial smoke artifacts now embed `recentGoldEvents`, letting dashboards/alarm bots plot passive unlocks alongside the exact gold deltas that triggered them without reprocessing raw analytics exports.
- Added regression coverage to `diagnostics.test.js` (and tutorial smoke artifact tests) to ensure both the overlay and artifacts retain the new block.

**Next Steps**
1. Surface the same condensed history in the HUD castle panel for moment-to-moment play (beyond diagnostics).
2. Extend smoke/e2e dashboards to visualize both `recentGoldEvents` and passive unlocks, highlighting suspect spikes automatically.
