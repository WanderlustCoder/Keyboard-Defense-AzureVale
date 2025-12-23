---
id: static-dashboard
title: "Publish a static dashboard from CI artifacts"
priority: P2
effort: M
depends_on: [ci-step-summary, scenario-matrix]
produces:
  - gh-pages branch with HTML+JSON
status_note: docs/status/2025-11-18_devserver_smoke_ci.md
backlog_refs:
  - "#79"
---
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

**Steps (sketch)**

- Build a tiny static page that reads last run’s JSON (gold, breach, smoke) and shows trendlines & thumbnails.
- Deploy via GitHub Pages (workflow push to `gh-pages`).

**Acceptance**: Non‑engineers can browse the latest results without downloading artifacts.
## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- Build the static dashboard locally and open index.html to confirm charts load







