> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Gold Summary CI Guard - 2025-11-14

**Summary**
- The tutorial smoke job now runs `npm run analytics:gold:check artifacts/smoke/gold-summary.ci.json` immediately after generating the gold summary artifact, failing the workflow if the embedded percentile metadata ever drifts from the canonical `25,50,90` cutlines.
- The E2E job mirrors the same guard by running `npm run analytics:gold:report` against the tutorial & campaign artifacts and `npm run analytics:gold:check artifacts/e2e/gold-summary.ci.json`, so every automation artifact uploaded to CI is validated before dashboards ingest it.
- This closes the loop on the percentiles rollout: the CLI is available locally, smoke/e2e summaries record `goldSummaryPercentiles`, and CI now enforces the contract before uploading artifacts for dashboards.

## Follow-up
Broader guard orchestration (screenshots, monitor stats, breach drill) is owned by
`docs/codex_pack/tasks/02-ci-guards.md`; this status note intentionally avoids duplicating the task
steps or acceptance criteria.

