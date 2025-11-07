## Gold Summary CI Guard - 2025-11-14

**Summary**
- The tutorial smoke job now runs `npm run analytics:gold:check artifacts/smoke/gold-summary.ci.json` immediately after generating the gold summary artifact, failing the workflow if the embedded percentile metadata ever drifts from the canonical `25,50,90` cutlines.
- The E2E job mirrors the same guard by running `npm run analytics:gold:report` against the tutorial & campaign artifacts and `npm run analytics:gold:check artifacts/e2e/gold-summary.ci.json`, so every automation artifact uploaded to CI is validated before dashboards ingest it.
- This closes the loop on the percentiles rollout: the CLI is available locally, smoke/e2e summaries record `goldSummaryPercentiles`, and CI now enforces the contract before uploading artifacts for dashboards.
