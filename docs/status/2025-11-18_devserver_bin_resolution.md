## Dev Server http-server Resolution - 2025-11-18

**Summary**
- Updated `scripts/devServer.mjs` to locate `http-server` regardless of whether the package exposes `bin/http-server.js` or the platform shim `bin/http-server`, eliminating the “Unable to locate http-server” error after installs on Windows.
- Kept the same fallback messaging but now try both candidates before failing, so `npm run start` works out of the box without requiring manual edits.

**Next Steps**
1. Consider surfacing friendlier guidance when the http-server binary still can't be resolved (e.g., link to repo README). *(Codex: `docs/codex_pack/tasks/22-devserver-bin-guidance.md`)*
2. Add an automated smoke script that runs `npm run start` in CI to catch regressions in the dev server harness. *(Same Codex task.)*
