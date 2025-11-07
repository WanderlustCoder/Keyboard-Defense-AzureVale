## Gold Summary CI Guard - 2025-11-14

**Summary**
- The tutorial smoke job now runs `npm run analytics:gold:check artifacts/smoke/gold-summary.ci.json` immediately after generating the gold summary artifact, failing the workflow if the embedded percentile metadata ever drifts from the canonical `25,50,90` cutlines.
- This closes the loop on the percentiles rollout: the CLI is available locally, smoke already records `goldSummaryPercentiles`, and CI now enforces the contract before uploading artifacts for dashboards.

**Next Steps**
1. Wire the same guard into the e2e job once its gold summaries go live, keeping all automation artifacts aligned.
