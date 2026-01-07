# Codex Milestone - Evaluation Harness Scaffolding (Local-Only)

## Objective
Implement a local-only evaluation harness stub that can later collect typing metrics **without** enabling telemetry.

## Tasks
1) Add a `apps/keyboard-defense-godot/scripts/eval/` module with:
   - baseline test definitions (timed prompts)
   - metrics computation (WPM, accuracy)
2) Add a debug command or menu action to launch the baseline test scene/mode.
3) Store results locally in the save/profile structure (no network).

## Constraints
- Opt-in telemetry is out of scope; local-only.
- Do not store raw typed strings; store aggregated stats.

## Acceptance
- Running baseline produces a local report and prints summary to UI/log.
- Unit tests cover metric calculations.



