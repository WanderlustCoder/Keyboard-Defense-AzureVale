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
traceability:
  tests:
    - path: apps/keyboard-defense/tests/serveStartSmoke.test.js
      description: Dev server start smoke harness + artifacts
  commands:
    - npm run serve:start-smoke -- --artifact temp/start-smoke.fixture.json --log temp/start-smoke.fixture.log --attempts 1
---
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

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

## Implementation Notes

- **Guidance UX**
  - When resolution fails, surface a multi-line block that includes:
    - The exact command that failed and exit code.
    - Suggested fixes (install via `npm install --global http-server`, run `npx http-server`, or add to project devDependencies).
    - Pointer to `apps/keyboard-defense/docs/DEVELOPMENT.md#dev-server` and the Codex Portal section.
    - If `--no-build` is supported (task 15), mention it as a faster retry option.
  - Emit a structured JSON error (`devserver-resolution-error.json`) with timestamp, cwd, and PATH info to aid support.
- **Smoke script behavior**
  - `scripts/serveStartSmoke.mjs` should:
    - Spawn `npm run start -- --no-build --ci` with a timeout.
    - Poll the monitor endpoint (localhost:4173 or configured port) for readiness.
    - Capture logs to `artifacts/monitor/start-smoke.log`.
    - Call the existing stop command (or send SIGINT) and verify shutdown.
    - Exit non-zero on timeout or unexpected HTTP status.
  - Accept flags (`--retries`, `--timeout-ms`, `--port`) so CI and local devs can tune behavior.
- **CI wiring**
  - Add a job step `npm run serve:start-smoke` that runs before Codex validation but after build/tests, uploading the log artifact on failure.
  - Feed the resulting status into the monitor summary helper (task 15) so GitHub step summaries show start-smoke health.
- **Docs**
  - Expand `apps/keyboard-defense/README.md` and portal docs with:
    - Troubleshooting checklist (PATH, permissions, reinstall instructions).
    - `serve:start-smoke` usage and how to interpret logs.
    - Guidance on when to run the smoke locally (before pushing dev server changes).
- **Testing**
  - Unit test the guidance module to ensure each failure scenario logs hints + links.
  - Add integration tests for `scripts/serveStartSmoke.mjs` (mock server) verifying timeout handling, retries, and artifact writing.

## Deliverables & Artifacts

- Improved error messaging module within `devServer.mjs`.
- `scripts/serveStartSmoke.mjs` + npm script `npm run serve:start-smoke`.
- CI workflow step + uploaded `artifacts/monitor/start-smoke.log`.
- Documentation updates (README, DEVELOPMENT.md, portal) referencing guidance + smoke command.

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
- npm run serve:start-smoke -- --artifact temp/start-smoke.fixture.json --log temp/start-smoke.fixture.log --attempts 1
- Run the new smoke locally (`node scripts/serveStartSmoke.mjs --ci`) to ensure it exits 0 on success.






