## Dev Server & Monitor Refresh - 2025-11-16

**Summary**
- Reintroduced `scripts/devServer.mjs`, giving `npm run start` the documented lifecycle again (build + detached `http-server` launch, `.devserver/state.json`, `.devserver/server.log`, readiness probe, and helper commands for status/check/logs/monitor/stop).
- Added the standalone `scripts/devMonitor.mjs` CLI so `npm run monitor:dev` can poll any URL, write JSON artifacts, and fail fast when readiness timeouts occur; included targeted Vitest coverage for its argument parser and wait-ready behavior.
- Shipped `scripts/startMonitored.mjs` so `npm run start:monitored` chains the server launch with the readiness monitor (CLI args after `--` are forwarded to the monitor, e.g., `--timeout 60000 --artifact monitor-artifacts/run.json`).
- Updated automation consumers (smoke CLI, HUD screenshots, monitor script) can now rely on the restored commands without stubbing missing files.

**Next Steps**
1. Consider adding a `--no-build` or `--force-restart` flag to `devServer.mjs` for workflows that want to skip compilation or restart an existing instance automatically. *(Codex: `docs/codex_pack/tasks/15-devserver-monitor-upgrade.md`)*
2. Surface the monitor artifact path in CI summaries so dashboards can pick up the JSON directly from the uploaded artifacts. *(Same Codex task as above.)*
