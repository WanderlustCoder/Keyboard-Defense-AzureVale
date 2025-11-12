---
id: semantic-release
title: "Automated releases and changelog"
priority: P2
effort: M
depends_on: []
produces:
  - semantic-release config
  - GitHub Releases with attached build
status_note: docs/status/2025-11-15_tooling_baseline.md
backlog_refs:
  - "#80"
---

**Steps (sketch)**

- Enforce **Conventional Commits** (PR title check or commit linter).
- Configure **semantic-release** (node project): npm plugin, changelog, GitHub releases.
- Attach zipped build artifacts (game bundle) to each release; create a nightly prerelease channel.
