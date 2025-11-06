## Gold Event History Overlay - 2025-11-08

**Summary**
- `RuntimeMetrics` now exposes `recentGoldEvents` (last three entries, cloned from analytics) so any HUD/automation consumer can render short economy timelines without parsing the full analytics payload.
- Diagnostics overlay renders a dedicated “Recent gold events” block with delta, resulting total, timestamp, and time-since values, giving designers and CI smoke logs immediate context for sudden resource swings.
- Added regression coverage to `diagnostics.test.js` to ensure the overlay always prints the new block when data is present and keeps default output untouched when empty.

**Next Steps**
1. Consider surfacing the same condensed history in the HUD castle panel for quick reference while playing.
2. Pipe the `recentGoldEvents` array into smoke artifacts (JSON) so dashboards can show side-by-side passive + gold timelines.
