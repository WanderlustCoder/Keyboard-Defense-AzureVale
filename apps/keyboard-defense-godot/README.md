# Keyboard Defense (Godot 4)

This is the Windows-targeted Godot 4 port focused on a pixel-art fantasy kingdom typing trainer.
The typing loop drives all defense outcomes; map progression and kingdom upgrades unlock as typing mastery grows.

## Open in Godot

1. Launch Godot 4.
2. Import the project from this folder.
3. Run the main scene (`scenes/Main.tscn`).

## Data

- `data/lessons.json`: lesson word lists for battles.
- `data/map.json`: campaign nodes, unlock requirements, drill template references, and optional `drill_overrides`.
- `data/drills.json`: shared drill templates referenced by the map.

`drill_overrides` supports:
- `steps`: array of `{ "index": 0, "data": { ... } }` to merge into a step.
- `replace`: array of `{ "index": 0, "step": { ... } }` to replace a step.
- `remove`: array of step indices to remove.
- `prepend`/`append`: arrays of step objects to insert.

## Debug Drill Editor

Press `F1` in a battle to open the debug panel. Paste `drill_overrides` JSON, hit Apply to reload the drills, and use Copy JSON to export the overrides.
- `data/kingdom_upgrades.json`: kingdom upgrade definitions.
- `data/unit_upgrades.json`: unit upgrade definitions.
- `data/assets_manifest.json`: asset audit manifest.

## Battle Buffs and Pause

- Typing streaks trigger short buffs that boost typing power or slow threat.
- Press `Esc` (or the Pause button) to open the pause menu; it freezes drills and buff timers.
- Intermission steps can be skipped during the tutorial (first battle) with `Space`.
- Active buffs appear as timers and bars inside the playfield HUD.

## Performance Rewards

- Battle rewards include a performance tier (C/B/A/S) based on accuracy + WPM.
- Higher tiers grant bonus gold on top of the base reward and practice gold.

## Notes

- Save data is stored at `user://savegame.json`.
- This is an early playable loop: map -> battle -> rewards -> kingdom.

## Typing Commands (Milestone 02)

Day commands:
- `gather wood 10`
- `build wall`
- `build tower 9 5`
- `explore`
- `end`

Navigation and inspection:
- `cursor 8 5`
- `cursor up 3`
- `inspect`
- `inspect 8 5`
- `preview tower`
- `map`
- `demolish`
- `overlay path on`
- `upgrade`
- `upgrade 8 5`

Run control:
- `save`
- `load`
- `new`
- `wait`
- `enemies`
- `report`
- `history`
- `history clear`
- `trend`
- `goal`
- `goal accuracy`
- `goal backspace`
- `goal speed`
- `goal balanced`
- `goal next`
- `settings`
- `bind cycle_goal`
- `bind cycle_goal reset`
- Hotkey: `F2` cycles goals (default; rebind via `bind cycle_goal`)

Tower levels:
- Level 1: range 3, damage 1, shots 1
- Level 2: range 4, damage 1, shots 2
- Level 3: range 5, damage 2, shots 2

Enemy types:
- raider: speed 1, armor 0
- scout: speed 2, armor 0
- armored: speed 1, armor 1

Night typing feedback:
- Matching enemy words highlight live in the wave panel as you type.
- Each enemy shows a progress bar based on your current prefix.
- Enter is safe on prefixes (no penalty); it only defends on exact matches or intentional misses.
- A typing report appears at dawn or game over; toggle it with `report`.
- Typing history and trend panels can be toggled with `history` and `trend`.
- Trend includes coach suggestions for builds and upgrades.
- The HUD goal badge shows the current goal and PASS/NOT YET (or -- if no reports yet).
- Practice goal only affects coaching thresholds, not gameplay difficulty.

## Automated Tests

Run headless tests with Godot 4 installed:

```powershell
.\scripts\test.ps1
```

Set `GODOT_PATH` if the executable is not on PATH.

To run the minimal sim tests only:

```powershell
godot --headless --path . --script res://tests/run_tests.gd
```

Or in bash:

```bash
./scripts/test.sh
```

Under WSL with a Windows Godot executable, `test.sh` converts paths automatically.

See `docs/GODOT_TESTING_PLAN.md` for the test strategy and asset QA checklist.
Instruction for future AI agents: when adding art or audio, update `data/assets_manifest.json` so the audit stays green.

Design and planning docs live in `docs/keyboard-defense-plans/README.md`.       
Asset creation docs live in `docs/keyboard-defense-plans/assets/README.md`.
Pre-production docs live in `docs/keyboard-defense-plans/preprod/README.md`.
Extended planning docs live in `docs/keyboard-defense-plans/extended/README.md`.
Business planning docs live in `docs/keyboard-defense-plans/business/README.md`.
