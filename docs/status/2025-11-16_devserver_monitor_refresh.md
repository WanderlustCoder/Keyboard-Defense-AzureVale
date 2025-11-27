## Dev Server & Monitor Refresh - 2025-11-16

**Summary**
- Reintroduced `scripts/devServer.mjs`, giving `npm run start` the documented lifecycle again (build + detached `http-server` launch, `.devserver/state.json`, `.devserver/server.log`, readiness probe, and helper commands for status/check/logs/monitor/stop).
- Added the standalone `scripts/devMonitor.mjs` CLI so `npm run monitor:dev` can poll any URL, write JSON artifacts, and fail fast when readiness timeouts occur; included targeted Vitest coverage for its argument parser and wait-ready behavior.
- Shipped `scripts/startMonitored.mjs` so `npm run start:monitored` chains the server launch with the readiness monitor. CLI args after `--` are forwarded to the monitor (e.g., `--timeout 60000 --artifact artifacts/monitor/dev-monitor.json`), while dev-server flags such as `--no-build` / `--force-restart` are now supported and recorded in `.devserver/state.json`.
- Monitor artifacts moved to `artifacts/monitor/dev-monitor.json`, now embed host/port/log metadata plus last latency + uptime fields, and CI summaries ingest the JSON so reviewers see monitor health without downloading files.

**Next Steps**
1. Add Playwright/tutorial smoke metadata (condensed HUD screenshots, CI tolerances) to the monitor artifact so traceability reports can pair readiness probes with UI captures.
2. Wire the monitor summary into the static dashboard so non-engineers can review the latest uptime + latency trendlines alongside the rest of the automation tiles.
