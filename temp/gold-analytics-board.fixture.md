## Gold Analytics Board
Generated: 2025-11-14T22:52:02.934Z
Status: ✅ Pass

### Inputs
| Source | Path |
| --- | --- |
| summary | ..\..\docs\codex_pack\fixtures\gold\gold-summary-report.json |
| timeline | ..\..\docs\codex_pack\fixtures\gold\gold-timeline-summary.json |
| passive | ..\..\docs\codex_pack\fixtures\gold\passive-gold-summary.json |
| guard | ..\..\docs\codex_pack\fixtures\gold\percentile-guard.json |
| alerts | ..\..\docs\codex_pack\fixtures\gold\gold-percentiles.baseline.json |

- Summary net Δ: **175**, Avg median gain: 60, Avg median spend: -35
- Timeline net Δ: **75**, Max spend streak: 60 (limit 200)
- Passive unlocks: **3**, Max gap: 35.5s
- Percentile guard: ✅ Pass (1 files)
- Percentile alerts: ✅ All metrics within thresholds

### Scenario Snapshot
| Scenario | Net Δ | Median Gain | Median Spend | Last Gold Δ | Last Passive | Alerts |
| --- | --- | --- | --- | --- | --- | --- |
| tutorial-skip | 175 | 60 | -35 | -60 @ 75.2s | gold L1 (+1.15) @ 78.2s | ✅ 4 |

### Warnings
_None_

JSON: `..\..\temp\gold-analytics-board.fixture.json`
Markdown: `..\..\temp\gold-analytics-board.fixture.md`
