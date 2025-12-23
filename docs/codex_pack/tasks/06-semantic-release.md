---
id: semantic-release
title: "Automated releases and changelog"
priority: P2
effort: M
depends_on: []
produces:
  - semantic-release config
  - GitHub Releases with attached build
status_note: docs/status/2025-11-21_semantic_release.md
backlog_refs:
  - "#80"
---
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

**Steps (sketch)**

- Enforce **Conventional Commits** (PR title check or commit linter).
- Configure **semantic-release** (node project): npm plugin, changelog, GitHub releases.
- Attach zipped build artifacts (game bundle) to each release; create a nightly prerelease channel.
## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- npx semantic-release --dry-run (once configured)







