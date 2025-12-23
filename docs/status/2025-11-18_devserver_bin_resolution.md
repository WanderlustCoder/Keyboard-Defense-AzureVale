> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Dev Server http-server Resolution - 2025-11-18

**Summary**
- Updated `scripts/devServer.mjs` to locate `http-server` regardless of whether the package exposes `bin/http-server.js` or the platform shim `bin/http-server`, eliminating the "Unable to locate http-server" error after installs on Windows.
- Kept the same fallback messaging but now try both candidates before failing, so `npm run start` works out of the box without requiring manual edits.
- Added friendlier guidance + `.devserver/resolution-error.json` when resolution still fails (suggested install commands, doc links, and a reminder that `npm run start -- --no-build` speeds up retries).
- Landed `npm run serve:start-smoke`, a lightweight harness that force-restarts the dev server, waits for readiness, copies logs, and writes `artifacts/monitor/start-smoke.json`; CI now runs it right after the traditional smoke so startup regressions surface immediately.

**Next Steps**
1. Feed the start-smoke summary into the Codex dashboard/static site so non-engineers can see the latest readiness metrics without opening CI.
2. Consider adding Playwright smoke coverage that reuses the new start-smoke artifact so UI regressions share the same log bundle.

