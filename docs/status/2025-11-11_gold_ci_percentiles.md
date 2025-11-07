## Gold Summary CI Percentiles - 2025-11-11

**Summary**
- Tutorial smoke automation now pipes `--percentiles 25,50,90` into `goldSummary.mjs`, ensuring the artifacts uploaded by CI always expose the dashboard cutlines without manual flags.
- `goldReport.mjs` adopted the same default (still overridable via `--percentiles`) so local investigations mirror CI output automatically while keeping the option to request other cutlines when needed.
- Added regression coverage for the new flag in `goldReport.test.js` so the orchestrator keeps forwarding the percentile list as the CLI evolves.

**Details**
- Smoke summary JSON tracks the exact command invocation, making it clear which percentile list generated each artifact.
- The default list lives in one place (`25,50,90`), minimizing the chance of future drift between automation and developer tooling.

**Next Steps**
1. Surface the requested percentile list directly inside the serialized gold summary output metadata so downstream tools can assert expectations without inspecting command logs.
