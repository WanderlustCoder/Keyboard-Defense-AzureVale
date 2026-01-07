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
- `lesson` (show lesson list in log)
- `lesson home_row`
- `lesson full_alpha`
- `lesson next`
- `lesson prev`
- `lesson sample 3`
- `lessons` (toggle lesson panel)
- `lessons reset`
- `lessons reset all`
- `lessons sort recent`
- `lessons sort default`
- `lessons sort name`
- `lessons sparkline on`
- `lessons sparkline off`
- `settings`
- `settings show`
- `settings hide`
- `settings lessons`
- `settings prefs`
- `tutorial`
- `tutorial restart`
- `tutorial skip`
- `bind cycle_goal`
- `bind cycle_goal reset`
- `bind toggle_trend`
- `bind toggle_trend reset`
- `bind toggle_compact`
- `bind toggle_compact reset`
- `bind toggle_history`
- `bind toggle_history reset`
- Hotkeys: `F1` settings, `F2` lessons, `F3` trend, `F4` compact panels, `F5` history, `F6` report, `F7` cycle goals (defaults; rebind via `bind`)
- Settings now include a Controls list that shows friendly names, action ids, and current bindings.

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
- Lesson selection only changes enemy word content; it does not change gameplay difficulty.
- The onboarding tutorial panel appears on first run; use `tutorial` to toggle and `tutorial restart` to replay.
- The Lesson panel shows an active lesson summary, per-lesson progress, mini-trend deltas with optional sparklines for the last 3 nights, sorting controls, and sample words.
- Settings now include Lessons prefs (sort mode + sparklines) plus the Lesson Health legend.
- Use `settings lessons` to print lesson prefs and the health legend in the log.
- Use `settings prefs` to print a full configuration summary (lesson, goal, panels, keybinds).
- The HUD shows Lesson Health (GOOD/OK/WARN/--) based on recent lesson trends.

## Docs

- `docs/PROJECT_STATUS.md` - current project status snapshot.
- `docs/ROADMAP.md` - near-term roadmap and quality gates.
- `docs/COMMAND_REFERENCE.md` - command reference with phases and examples.
- `docs/RESEARCH_SFK_SUMMARY.md` - research summary and mapping notes.
- `docs/CHANGELOG.md` - milestone changelog.
- `docs/BALANCE_CONSTANTS.md` - balance constants index (guardrails, costs, stats).
- `docs/QUALITY_GATES.md` - merge/release gate checklist.
- `docs/PLAYTEST_PROTOCOL.md` - playtest session script and reporting.
- `docs/plans/README.md` - plan library and action plans index.
- `docs/plans/PLANPACK_TRIAGE.md` - planpack triage and adoption decisions.

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

Scenario harness (Phase 2):

```powershell
.\scripts\scenarios.ps1
```

```bash
./scripts/scenarios.sh
```

Wrappers default to the P0 balance suite (`--tag p0 --tag balance`).

Run the full catalog directly:

```bash
godot --headless --path . --script res://tools/run_scenarios.gd --all
```

See `docs/plans/planpack_2025-12-27_tempPlans/GODOT_TESTING_PLAN.md` for the test strategy and asset QA checklist.
Instruction for future AI agents: when adding art or audio, update `data/assets_manifest.json` so the audit stays green.
Instruction for future AI agents: end-of-milestone summaries should include the headings Milestone Goal, What Shipped, Current Project State, Roadmap Next, and Known Issues / Tech Debt before the LANDMARK block.
