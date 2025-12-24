# Codex Milestone: CI Workflow (Tests and Build)

## Landmark: Objective
Add a minimal CI workflow that runs on every push or PR:
- install Godot
- run tests
- optional export build
- content validation

## Landmark: Tasks
1) Add `.github/workflows/ci.yml`
2) Cache the Godot download where helpful
3) Run:
   - `.\apps\keyboard-defense-godot\scripts\run_tests.ps1`
4) If an export preset exists, run a headless export step
5) If a lint script exists, run it; otherwise do not fail

## Landmark: Verification
- CI passes on main branch

Summarize with LANDMARKS:
- A: Workflow triggers
- B: Steps executed
- C: Notes for future improvements
