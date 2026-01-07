# Codex CLI playbook - Keyboard Defense (Godot)

This workflow keeps changes reviewable and testable for the Godot project.

## 0) Launch Codex CLI
- Launch: codex
- Recommended: codex --sandbox workspace-write --ask-for-approval on-request

## 1) Baseline project conventions
- Keep gameplay logic in scripts/.
- Data lives in data/ and stays JSON-driven.
- Tests live in scripts/tests/ and run headless.

## 2) Milestone plan (each milestone is a Codex task)
Each milestone should follow: prompt -> apply diff -> run tests -> update docs.

### Milestone A: Battle loop foundations
Prompt: prompts/01_battle_core.md
Acceptance:
- Headless tests validate battle flow and rewards.
- Drill plans run cleanly across all map nodes.

### Milestone B: Input and feedback clarity
Prompt: prompts/02_input_feedback.md
Acceptance:
- Typing feedback is readable and consistent.
- HUD labels stay in sync with battle stats.

### Milestone C: Map and kingdom UX
Prompt: prompts/03_map_kingdom_ui.md
Acceptance:
- Map cards show unlock state and rewards.
- Kingdom upgrades reflect affordability and effects.

### Milestone D: Battle interventions
Prompt: prompts/04_battle_interventions.md
Acceptance:
- New intervention prompts trigger and resolve cleanly.
- Tests cover success and failure outcomes.

### Milestone E: Typing adaptivity
Prompt: prompts/05_typing_adaptivity.md
Acceptance:
- Weak-key tracking feeds drill targets.
- Tests cover selection logic and variety rules.

### Milestone F: First playable expansion
Prompt: prompts/06_first_playable.md
Acceptance:
- Campaign path extends with new lessons and nodes.
- Player can complete a multi-node run with upgrades.

## 3) Working practices
- Keep tasks small and focused.
- Add or update tests with every feature.
- Document changes in docs/keyboard-defense-plans/.

## 4) Suggested commit strategy
- feat: battle loop and drills
- feat: map/kingdom UI
- feat: typing adaptivity
- chore: tests and docs updates

## 5) Definition of done
- Automated tests pass via scripts/run_tests.ps1.
- UI and layout checks pass for all main scenes.
- Manual QA checklist is completed for art and audio changes.
