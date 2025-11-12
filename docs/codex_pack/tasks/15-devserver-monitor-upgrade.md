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
     artifact (`monitor-artifacts/dev-monitor.json`) and print:
     - URL monitored, latency statistics, uptime, artifact path.
   - Update `.github/workflows/ci-e2e-azure-vale.yml` to run this summary step.
3. **Docs**
   - Update `README.md` and/or `docs/codex_pack/tasks/01-ci-step-summary.md`
     referencing the new monitor summary fields.
   - Document the new dev server flags (developer guide + Codex portal).

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
