> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Semantic Release Automation - 2025-11-21

**Summary**
- Added semantic-release with a project-scoped `.releaserc.json`, CHANGELOG, and an `npm run release(:dry-run)` entry so releases are reproducible locally and in CI.
- Authored `scripts/packageRelease.mjs`, which bundles `public/` + docs into `artifacts/release/keyboard-defense-<version>.zip` and emits a checksum manifest for GitHub releases.
- Created `.github/workflows/release.yml` that installs deps, runs the full test + Codex validation stack, then invokes semantic-release on `master` and the `nightly` prerelease channel.
- Documented the workflow (Guide, Portal, Playbooks) so Codex operators know how to dry-run releases and where to find the published artifacts + manifests.

**Next Steps**
1. Consider exposing the release manifest inside the static dashboard so non-engineers can download the latest bundle without opening the GitHub release page.
2. Add a lightweight smoke that unzips the bundle and verifies the public assets load (basic HTML + asset hash check) before attaching to a release.

## Follow-up
- `docs/codex_pack/tasks/06-semantic-release.md`

