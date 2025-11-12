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

**Steps (sketch)**

- Build a tiny static page that reads last run’s JSON (gold, breach, smoke) and shows trendlines & thumbnails.
- Deploy via GitHub Pages (workflow push to `gh-pages`).

**Acceptance**: Non‑engineers can browse the latest results without downloading artifacts.
