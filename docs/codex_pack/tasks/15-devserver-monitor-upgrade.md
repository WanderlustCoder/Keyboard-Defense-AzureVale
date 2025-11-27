---
id: devserver-monitor-upgrade
title: "Dev server flags & CI monitor summary"
priority: P2
effort: M
depends_on: [ci-step-summary]
produces:
  - devServer.mjs flag enhancements
  - monitor artifact summary injected into CI (Build/Test job)
  - README/docs updates describing new flags & CI output
status_note: docs/status/2025-11-16_devserver_monitor_refresh.md
backlog_refs:
  - "#82"
traceability:
  tests:
    - path: apps/keyboard-defense/tests/devServerFlags.test.js
      description: Dev server flag handling and state updates
    - path: apps/keyboard-defense/tests/devMonitor.test.js
      description: Dev monitor artifact metadata + summary fields
  commands:
    - npm run monitor:dev -- --wait-ready --artifact artifacts/monitor/dev-monitor.json
---

**Context**  
Dev server automation returned (`scripts/devServer.mjs`, `devMonitor.mjs`), but we
still need QoL flags (`--no-build`, `--force-restart`) and better CI surfacing for
monitor artifacts.

## Steps

1. **Flag implementation**
   - Update `scripts/devServer.mjs` to accept:
     - `--no-build` (skip compilation)
     - `--force-restart` (stop existing server before starting)
   - Ensure `npm run start`, `start:monitored`, and related commands pass through
     the flags.
   - Add tests covering the new behaviors (mock spawn, ensure state files update).
2. **Monitor artifact surfacing**
   - Extend `scripts/ci/emit-summary.mjs` (or new helper) to read the monitor
     artifact (`artifacts/monitor/dev-monitor.json`) and print:
     - URL monitored, latency statistics, uptime, artifact path.
   - Update `.github/workflows/ci-e2e-azure-vale.yml` to run this summary step.
3. **Docs**
   - Update `README.md` and/or `docs/codex_pack/tasks/01-ci-step-summary.md`
     referencing the new monitor summary fields.
   - Document the new dev server flags (developer guide + Codex portal).

## Implementation Notes

- **Flag plumbing**
  - Centralize option parsing inside `scripts/devServer.mjs` so `npm run start`,
    `start:monitored`, and `dev:watch` all share the same argument schema (`yargs`
    or lightweight parser).
  - `--no-build` should skip the build step but still run integrity/config checks;
    expose an environment variable (`DEVSERVER_NO_BUILD=1`) for shell usage.
  - `--force-restart` should look for an existing PID file (`.devserver/pid`) or
    running port, gracefully shut it down, and wait for confirmation before booting.
  - Persist option usage in the monitor artifact (e.g., `"flags": ["no-build"]`) so
    CI summaries can report which path ran.
- **Monitor summary ingestion**
  - Extend the monitor CLI to emit JSON at
    `artifacts/monitor/dev-monitor.json` containing host, port, uptime, retry count,
    last ping latency, and log file locations.
  - Build a helper (`scripts/ci/devMonitorSummary.mjs`) that pretty-prints those fields
    to Markdown (tables + ✅/⚠️ badges) and appends them to `$GITHUB_STEP_SUMMARY`.
  - In CI workflows, run the helper right after uploading the monitor artifact so
    reviewers see the status without downloading files.
- **Testing**
  - Mock `child_process.spawn` in Vitest to ensure `--no-build` bypasses build-only
    calls and `--force-restart` issues a stop/start sequence.
  - Add integration tests for the summary helper using fixture JSON.
- **Docs & onboarding**
  - Update `apps/keyboard-defense/docs/DEVELOPMENT.md` with a “Dev server flags”
    table, example commands, and troubleshooting tips (e.g., when to use `--no-build`).
  - Add a Codex Portal tile referencing the new flags + CI summary so automation
    contributors know where to look for monitor health.
  - Refresh the Nov-16 status note once summary output and flags land.

## Deliverables & Artifacts

- Enhanced `scripts/devServer.mjs` + tests.
- Monitor artifact JSON + Markdown summary helper.
- CI workflow updates appending the summary to GitHub logs.
- Documentation updates (DEVELOPMENT.md, CODEX_GUIDE.md, status note).

## Implementation Notes

- **Flag plumbing**
  - Centralize option parsing inside `scripts/devServer.mjs` so `npm run start`,
    `start:monitored`, and `dev:watch` all share the same argument schema (`yargs`
    or lightweight parser).
  - `--no-build` should skip the build step but still run integrity/config checks;
    expose an environment variable (`DEVSERVER_NO_BUILD=1`) for shell usage.
  - `--force-restart` should look for an existing PID file (`.devserver/pid`) or
    running port, gracefully shut it down, and wait for confirmation before booting.
  - Persist option usage in the monitor artifact (e.g., `"flags": ["no-build"]`) so
    CI summaries can report which path ran.
- **Monitor summary ingestion**
  - Extend the monitor CLI to emit JSON at
    `artifacts/monitor/dev-monitor.json` containing host, port, uptime, retry count,
    last ping latency, and log file locations.
  - Build a helper (`scripts/ci/devMonitorSummary.mjs`) that pretty-prints those fields
    to Markdown (tables + ✅/⚠️ badges) and appends them to `$GITHUB_STEP_SUMMARY`.
  - In CI workflows, run the helper right after uploading the monitor artifact so
    reviewers see the status without downloading files.
- **Testing**
  - Mock `child_process.spawn` in Vitest to ensure `--no-build` bypasses build-only
    calls and `--force-restart` issues a stop/start sequence.
  - Add integration tests for the summary helper using fixture JSON.
- **Docs & onboarding**
  - Update `apps/keyboard-defense/docs/DEVELOPMENT.md` with a “Dev server flags”
    table, example commands, and troubleshooting tips (e.g., when to use `--no-build`).
  - Add a Codex Portal tile referencing the new flags + CI summary so automation
    contributors know where to look for monitor health.
  - Refresh the Nov-16 status note once summary output and flags land.

## Deliverables & Artifacts

- Enhanced `scripts/devServer.mjs` + tests.
- Monitor artifact JSON + Markdown summary helper.
- CI workflow updates appending the summary to GitHub logs.
- Documentation updates (DEVELOPMENT.md, CODEX_GUIDE.md, status note).

## Acceptance criteria

- `npm run start -- --no-build` skips builds; `--force-restart` restarts when a
  server is already running.
- CI job summary includes monitor artifact info (and direct links).
- Docs describe usage + flags.

## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status
- Locally run `node scripts/devServer.mjs start --no-build` and
  `node scripts/devServer.mjs start --force-restart` to confirm behavior.
- Run the monitor summary step (`npm run codex:dashboard` already runs after CI).
