# CI/CD and Release Plan

This is a lightweight plan that Codex can implement early to prevent regressions.

---
## Landmark: Minimum CI (recommended)
Run on every PR/push:
- Install Godot 4 (headless or full) and set `GODOT_PATH`.
- Run headless tests:
  - `.\apps\keyboard-defense-godot\scripts\run_tests.ps1`
- If a formatting or linting tool is added, run it here.

Artifacts:
- Optional: upload the exported build for preview.

---
## Landmark: Versioning
- App version: store in a small JSON (e.g., `apps/keyboard-defense-godot/data/version.json`).
- Content version: hash or semver for `data/` packs.
- Display both in the main menu footer for support and debugging.

---
## Landmark: Release checklist (human)
See `docs/keyboard-defense-plans/preprod/checklists/RELEASE_CHECKLIST.md`.

---
## Landmark: Build reproducibility rules
- Track Godot version in documentation.
- Avoid build steps that download unpinned binaries.
- Keep export presets under version control.

---
## Landmark: Optional automation (post-MVP)
- Tagged releases build artifacts.
- Automated changelog generation.
