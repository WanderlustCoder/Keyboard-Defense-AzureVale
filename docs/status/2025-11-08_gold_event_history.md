## Gold Event History Overlay - 2025-11-08

**Summary**
- `RuntimeMetrics` now exposes `recentGoldEvents` (last three entries, cloned from analytics) so any HUD/automation consumer can render short economy timelines without parsing the full analytics payload.
- Diagnostics overlay renders a dedicated "Recent gold events" block with delta, resulting total, timestamp, and time-since values, giving designers and CI smoke logs immediate context for sudden resource swings.
- HUD castle upgrade panel mirrors the same timeline, surfacing the most recent three gold deltas directly alongside passive listings so players (and HUD screenshots) can track surges without opening diagnostics.
- Tutorial smoke artifacts now embed `recentGoldEvents`, letting dashboards/alarm bots plot passive unlocks alongside the exact gold deltas that triggered them without reprocessing raw analytics exports.
- Added regression coverage to `diagnostics.test.js` (and tutorial smoke artifact tests) to ensure both the overlay and artifacts retain the new block.

**Next Steps**
1. Extend smoke/e2e dashboards (and analytics CSV tooling) to visualize both passive unlocks and `recentGoldEvents`, highlighting suspect spikes automatically.
2. Consider echoing the condensed gold history in the options overlay or battle log so the data remains visible even when diagnostics are hidden.
