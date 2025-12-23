> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Gold Summary Validator CLI - 2025-11-13

**Summary**
- Introduced `scripts/goldSummaryCheck.mjs` (`npm run analytics:gold:check`) so dashboards/alerts can verify that gold summary artifacts (JSON or CSV) embed the expected percentile list before ingesting them.
- The CLI accepts directories or explicit files, supports custom `--percentiles`, and rejects any artifact missing the JSON `{ percentiles, rows }` envelope or the CSV `summaryPercentiles` column.
- Added a vitest suite covering JSON/CSV success/failure cases, ensuring future schema tweaks keep the guardrails intact.
- Smoke summaries now record `goldSummaryPercentiles`, and the changelog/backlog call out the new tooling so other contributors know how to use it.

**Next Steps**
1. Hook `npm run analytics:gold:check artifacts/gold-summary.report.json` into CI dashboards/alerts so mismatched cutlines block ingestion automatically.

## Follow-up
- `docs/codex_pack/tasks/36-gold-percentile-ingestion-guard.md`

