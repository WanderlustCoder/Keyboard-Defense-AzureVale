> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Gold Summary Percentile Flag - 2025-11-10

**Summary**
- `scripts/goldSummary.mjs` now accepts `--percentiles <comma-list>` so dashboards can request arbitrary gain/spend cutlines (defaults remain 50 and 90 to preserve median/p90 coverage).
- The CLI injects `gainP<percent>` / `spendP<percent>` columns for every requested percentile and still publishes the legacy `medianGain`, `p90Gain`, `medianSpend`, and `p90Spend` aliases for downstream tools that have not yet been updated.
- Global aggregates now respect the same percentile list, ensuring cross-file rows line up with per-file artifacts and manual analysts can dial in identical horizon cuts.

**Details**
- Percentile parsing accepts floats between 0 and 100; duplicates collapse automatically so `--percentiles 50,50,90` behaves identically to the default.
- CSV headers list the percentile columns immediately after `uniquePassiveIds` (e.g., `gainP50,spendP50,gainP90,spendP90`) so consumers parsing by position get deterministic ordering.
- Vitest coverage exercises the parser, per-file math, CSV header contract, and JSON output when custom cutlines (25/75/95) are provided.

**Next Steps**
1. Consider surfacing the chosen percentile list in the serialized output metadata for easier downstream auditing.

## Follow-up
- `docs/codex_pack/tasks/36-gold-percentile-ingestion-guard.md`

