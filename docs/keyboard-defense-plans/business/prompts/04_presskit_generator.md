# Codex Milestone - Press Kit/Marketing Folder Generator (Optional)

## Objective
Ensure marketing assets can be organized consistently.

## Tasks
1) Add `docs/keyboard-defense-plans/business/marketing/press-kit/` templates into the repo if missing.
2) Add a small PowerShell script `scripts/build_press_kit.ps1` that:
   - copies templates into a `dist/press-kit/` folder
   - includes current version and date in a `press-kit.json`
3) Document how to run the script (PowerShell).

## Constraints
- Do not generate actual images; just structure and metadata.

## Acceptance
- `scripts/build_press_kit.ps1` creates `dist/press-kit/` with expected files.



