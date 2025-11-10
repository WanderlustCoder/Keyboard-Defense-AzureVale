## Dev Server Smoke Automation - 2025-11-18

**Summary**
- Introduced `npm run serve:smoke` (`scripts/devServerSmoke.mjs`), which launches the dev server via `npm run start`, waits for readiness, performs reachability probes, and tears everything down so CI can validate the harness without leaving background processes running. The command skips the redundant build by default but accepts `--full-build` for thorough local runs.
- Updated the dev server README/DEVELOPMENT notes so the new smoke helper is documented alongside the existing lifecycle commands and expectations.
- Wired a "Dev server smoke" step into the `build-test` job, ensuring every CI run exercises the start/check/stop flow before we reach the heavier smoke/e2e stages.
- Hardened the `http-server` resolution path with actionable guidance (exact lookup targets plus remediation steps) so missing installs fail fast with links back to the Dev Server Automation docs.
- The smoke script now writes `artifacts/smoke/devserver-smoke-summary.json` (configurable via `DEVSERVER_SMOKE_SUMMARY`) with the server URL, PID, and timestamps, automatically prints the tail of `.devserver/server.log` when failures occur, and accepts `--json` so CI can emit the summary directly to stdout in addition to the artifact.
- Build-test CI now runs `npm run serve:smoke -- --ci --json` and uploads `artifacts/smoke/devserver-smoke-summary.json` with the other build artifacts, so both the logs and downloadable bundle contain identical telemetry for debugging.

**Next Steps**
1. Parse the smoke summary JSON in CI (via a follow-up workflow step) to echo a concise status table/Set-Output that downstream jobs can consume.
2. Pipe the parsed summary into GitHub workflow commands (annotations or job summaries) so failures link directly to the smoke run metadata/log tail.
