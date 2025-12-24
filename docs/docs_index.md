# Project Documentation Index

This repo now ships the Godot 4 version of Keyboard Defense.
The previous implementation has been retired.

## Godot Project
- `docs/GODOT_PROJECT.md` - Current Godot workflow, data files, and test command.
- `docs/GODOT_TESTING_PLAN.md` - Test strategy for features and assets.
- `docs/keyboard-defense-plans/README.md` - Design and planning pack for the Godot project.
- `docs/keyboard-defense-plans/assets/README.md` - Art and audio asset planning pack.
- `docs/keyboard-defense-plans/preprod/README.md` - Pre-production planning pack.
- `docs/keyboard-defense-plans/extended/README.md` - Extended planning pack.
- `docs/keyboard-defense-plans/business/README.md` - Business and delivery planning pack.
- `apps/keyboard-defense-godot/README.md` - Godot project overview.
- `apps/keyboard-defense-godot/project.godot` - Godot project definition.
- `apps/keyboard-defense-godot/scenes/Main.tscn` - Main entry scene.
- `apps/keyboard-defense-godot/data/lessons.json` - Lesson word lists.
- `apps/keyboard-defense-godot/data/map.json` - Campaign map, unlocks, drill overrides.
- `apps/keyboard-defense-godot/data/drills.json` - Drill templates.
- `apps/keyboard-defense-godot/data/kingdom_upgrades.json` - Kingdom upgrades.
- `apps/keyboard-defense-godot/data/unit_upgrades.json` - Unit upgrades.
- `apps/keyboard-defense-godot/data/assets_manifest.json` - Asset audit manifest.
- `apps/keyboard-defense-godot/data/schemas/` - JSON schemas for integrity tests.
- `apps/keyboard-defense-godot/scripts/run_tests.ps1` - Headless Godot test runner.
Instruction for future AI agents: when adding art or audio, update `apps/keyboard-defense-godot/data/assets_manifest.json` so the audit stays green.

## Legacy Docs (Archived)
These documents are archived from a pre-Godot implementation and are kept only for historical context.
See `docs/GODOT_PROJECT.md` for the current project.

- `docs/CODEX_GUIDE.md`
- `docs/CODEX_PLAYBOOKS.md`
- `docs/CODEX_PORTAL.md`
- `docs/analytics_schema.md`
- `docs/hud_gallery.md`
- `docs/nightly_ops.md`
- `docs/codex_pack/`
- `docs/status/`
