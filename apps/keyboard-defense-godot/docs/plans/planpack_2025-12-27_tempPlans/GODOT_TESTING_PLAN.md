# Godot Testing Plan

This plan defines how new features and assets are validated for the Godot
project.

## Goals
- Every code feature ships with automated tests.
- Art and audio assets have automated validation plus a human QA pass.
- Tests run headless and are suitable for CI gating.

## Automated Test Layers
1) Unit and system tests (GDScript)
   - Cover core logic: typing rules, progression, buffs, rewards, and save/load.
   - Add `scripts/tests/test_*.gd` coverage for each new system or mechanic.
2) Data contract tests
   - Validate lessons, map nodes, drills, and upgrades.
   - Extend `test_data_integrity.gd` when schemas or new data files change.
3) Scene and UI layout tests
   - Ensure scenes load and key nodes exist.
   - Validate layout invariants for new panels or HUD elements.
4) Gameplay integration tests
   - Scripted battles for victory/defeat, autoplay, and buff triggers.
   - Assert unlocks, rewards, and summary outputs remain consistent.
5) Regression hooks (planned)
   - Visual snapshots for main screens and HUD states.
   - Budget checks for performance-sensitive systems if needed.

## Feature Test Matrix
| Feature type | Required automated coverage |
| --- | --- |
| Gameplay logic | Unit tests + battle integration smoke |
| Progression and economy | Unit tests + save/load assertions |
| UI or HUD changes | Scene load + layout checks + (planned) snapshots |
| Data content | Data integrity assertions |
| Tools or debug panels | Unit tests + smoke if used in runtime flow |

## Asset Testing
### Art (automated)
- Validate file naming and folder placement.
- Ensure `.import` files exist and use nearest filtering for pixel art.
- Enforce size and dimension budgets in `apps/keyboard-defense-godot/data/assets_manifest.json`.
- Require every tracked asset under `apps/keyboard-defense-godot/assets/` to be listed in the manifest.
- Instruction for future AI agents: when adding art or audio, update `apps/keyboard-defense-godot/data/assets_manifest.json` so the audit stays green.
- Check sprite sheets for grid alignment when applicable.

### Audio (automated)
- Validate format (wav/ogg), duration range, and sample rate/channels when exposed by Godot.
- Check peak levels to avoid clipping and preserve headroom.
- Confirm assets load in headless runs.

### Manual QA (required)
- Visual review at 720p and 1080p for clarity and contrast.
- Animation cadence, UI spacing, and legibility under motion.
- Audio balance, loop seams, and feedback timing in gameplay.

## Execution
- Run `.\scripts\run_tests.ps1` for GDScript tests.
- Asset audit coverage lives in `apps/keyboard-defense-godot/scripts/tests/test_asset_integrity.gd`.
- CI should gate merges on automated tests; manual QA signoff is required for
  new art and audio.
