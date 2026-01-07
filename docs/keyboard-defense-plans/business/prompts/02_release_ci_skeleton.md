# Codex Milestone - Release/CI Skeleton (Minimal)

## Objective
Create a minimal CI and release skeleton that enforces the Quality Gates without being over-engineered.

## Tasks
1) Add a GitHub Actions workflow:
   - installs Godot (or uses a cached binary)
   - runs `.\apps\keyboard-defense-godot\scripts\run_tests.ps1`
   - runs an export step if export presets exist
2) Add a small script (GDScript or PowerShell) that writes `apps/keyboard-defense-godot/data/version.json` with:
   - game version string
   - git commit hash (if available)
   - build timestamp UTC
3) Add `docs/keyboard-defense-plans/business/RELEASE_STRATEGY.md` references into a `RELEASE.md` at repo root.

## Constraints
- Keep CI fast and deterministic.
- No secrets required.

## Acceptance
- Workflow runs on pull_request and push to main.
- Version file generation works locally without network.



