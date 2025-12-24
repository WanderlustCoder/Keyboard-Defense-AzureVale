# Codex prompt - Milestone A: battle loop foundations

You are working in the Keyboard Defense (Godot) repo.

## Goal
Strengthen the core battle loop and drill scheduling:
- tighten drill plan resolution
- ensure reward math is deterministic
- expand tests that cover battle start, victory, and defeat

## Constraints
- Keep logic in scripts/.
- Update or add scripts/tests/test_*.gd.
- Use data/ for content changes.

## Landmarks / files
- scripts/Battlefield.gd
- scripts/TypingSystem.gd
- scripts/ProgressionState.gd
- scripts/tests/test_battle_smoke.gd
- scripts/tests/test_battle_autoplay.gd

## Acceptance
- scripts/run_tests.ps1 passes.
- Drill plans are stable for every map node.
- Reward summaries are consistent across runs.
