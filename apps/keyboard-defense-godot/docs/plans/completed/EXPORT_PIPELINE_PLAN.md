# P0 Export Pipeline Plan

Roadmap IDs: P0-EXP-001

## Target platform
- Windows desktop is the first supported export target.

## Export presets
- Add a Windows preset in Godot export settings.
- Capture required templates in a known `exports/` or `builds/` folder.

## Release layout
- `/builds/windows/KeyboardDefense/` (versioned output)
- `/builds/windows/KeyboardDefense/readme.txt` (run instructions)
- `/builds/windows/KeyboardDefense/LICENSE.txt` (if applicable)

## Release smoke checklist
- Headless tests pass.
- Headless boot passes.
- Settings and lesson panels open and respond to typing.
- Save/load works for a short run.

## Planning references
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/preprod/CI_CD_AND_RELEASE.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/business/QUALITY_GATES.md`

## Acceptance criteria
- Windows export preset is documented and reproducible.
- A versioned Windows build can be generated on demand.
- A release checklist exists and is followed for builds.

## Test plan
- Manual: run the Windows build on a clean machine.
- Record export steps in docs/ROADMAP.md or a release checklist doc.
