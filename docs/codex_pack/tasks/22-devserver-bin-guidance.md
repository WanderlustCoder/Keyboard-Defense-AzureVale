---
id: devserver-bin-guidance
title: "Dev server guidance & start smoke automation"
priority: P2
effort: S
depends_on: [devserver-monitor-upgrade]
produces:
  - enhanced error messaging for http-server resolution
  - CI smoke script (`npm run serve:start-smoke`) verifying `npm run start`
status_note: docs/status/2025-11-18_devserver_bin_resolution.md
backlog_refs:
  - "#82"
---

**Context**  
`devServer.mjs` now resolves `http-server` more reliably, but when resolution still
fails we should provide friendlier guidance. Additionally, CI should run a
minimal `npm run start` smoke to catch regressions automatically.

## Steps

1. **Friendly guidance**
   - When `http-server` resolution fails, print actionable hints:
     - Commands to install `http-server`
     - Link to the README section describing dev server setup
     - Mention `npm run start -- --no-build` option if relevant
   - Include error codes/log paths.
2. **Start smoke automation**
   - Add `scripts/serveStartSmoke.mjs` (or similar) that:
     - Runs `npm run start -- --no-build`
     - Waits for readiness, then `npm run serve:stop`
   - Wire into CI (Build/Test job) after `npm run serve:smoke` but before Codex validation.
   - Record artifact (log summary) for debugging.
3. **Docs**
   - Update dev server README section with the new guidance text + instructions for the smoke script.

## Acceptance criteria

- Dev server errors provide clear install instructions and links.
- CI runs the new start smoke step, failing fast if `npm run start` regressions occur.
- Documentation explains how to run the smoke locally.

## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status
- Run the new smoke locally (`node scripts/serveStartSmoke.mjs --ci`) to ensure it exits 0 on success.
