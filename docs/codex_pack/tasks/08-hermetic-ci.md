---
id: hermetic-ci
title: "Hermetic CI via Playwright base container"
priority: P2
effort: M
depends_on: []
produces:
  - Dockerfile (playwright base)
  - workflow `container:` config
status_note: docs/status/2025-11-16_devserver_monitor_refresh.md
backlog_refs:
  - "#82"
---
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

**Steps (sketch)**

- Create a Dockerfile `FROM mcr.microsoft.com/playwright:lts` and install `http-server` + your deps.
- Run smoke/e2e jobs under `container:` for perfect parity with local.
## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- Docker build ./ci/Dockerfile-playwright







