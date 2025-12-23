---
id: ci-matrix
title: "OS/Node matrix and concurrency hygiene"
priority: P1
effort: S
depends_on: []
produces:
  - .github/workflows/ci-e2e-azure-vale.yml (modified)
status_note: docs/status/2025-11-18_devserver_bin_resolution.md
backlog_refs:
  - "#82"
---
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

**Context**  
Docs mention Windows `http-server` bin resolution fixes. Lock it in with CI coverage and cancel redundant runs.

## Steps

1) Add a matrix: `os: [ubuntu-latest, windows-latest]`, `node: [18, 20]` for the Build/Test job.
2) Add workflow concurrency: cancel in‑progress runs per branch.
3) Keep Playwright/browser caches pinned.

## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- gh workflow lint (or act) to ensure matrix/concurrency syntax is valid

## Snippet

See `snippets/workflow.patch.yaml`.






