# Command Reference

This guide lists every command in the Godot project, grouped by purpose. Each entry
includes one example and phase restriction so it stays usable during play.

## General (Any)
- help - Example: help - Phase: Any. Shows a quick-start and current hotkeys.
- help settings - Example: help settings - Phase: Any. Shows settings shortcuts.
- help hotkeys - Example: help hotkeys - Phase: Any. Lists all rebindable hotkeys.
- help topics - Example: help topics - Phase: Any. Lists available help topics.
- help play - Example: help play - Phase: Any. Shows quick play steps with current hotkeys.
- help accessibility - Example: help accessibility - Phase: Any. Shows accessibility guidance and diagnostics.
- version - Example: version - Phase: Any. Shows game and engine versions.
- status - Example: status - Phase: Any. Shows phase, day, and resources.

help output (excerpt):
```
Quick start:
Commands:
  settings verify
  settings conflicts
  help hotkeys
  help topics
Tip: type help hotkeys to list all hotkeys.
Tip: type help topics to see all help topics.
Current hotkeys:
  toggle_settings: F1
```

help settings output (excerpt):
```
Settings help:
  settings verify
  settings conflicts
```

help hotkeys output (excerpt):
```
Hotkeys:
  toggle_settings: F1
  toggle_lessons: F2
  toggle_trend: (unbound)
Conflicts: none
```

help topics output (excerpt):
```
Help topics:
  settings
  hotkeys
  play
  accessibility
  topics
```

help play output (excerpt):
```
How to play:
  1) Open Lessons: toggle_lessons (F2)
  2) Open Settings: toggle_settings (F1)
  5) Check setup: settings verify
  6) If conflicts: settings conflicts, then settings resolve apply
```

help accessibility output (excerpt):
```
Accessibility:
  Open Settings: toggle_settings (F1)
  Open Lessons: toggle_lessons (F2)
  Compact on: settings compact on
  Compact off: settings compact off
  Export diagnostics: settings export save
  Manual checklist: docs/ACCESSIBILITY_VERIFICATION.md
```

version output (example):
```
Keyboard Defense v1.0.0
Godot v4.2.2
```

## Core Gameplay (Day)
- gather <resource> <amount> - Example: gather wood 10 - Phase: Day only.
- build <type> [x y] - Example: build tower 9 5 - Phase: Day only.
- explore - Example: explore - Phase: Day only.
- upgrade [x y] - Example: upgrade 8 5 - Phase: Day only (tower only).
- demolish [x y] - Example: demolish 8 5 - Phase: Day only.
- end - Example: end - Phase: Day only (starts night).

## Core Gameplay (Night)
- Type an enemy word + Enter - Example: type moss then Enter - Phase: Night only.
- wait - Example: wait - Phase: Night only (advance night step without miss).
- defend <text> - Example: defend moss - Phase: Night only (debug alias).

Night input rules:
- Exact enemy word = hit.
- Prefix of any enemy word or command = no action (safe to keep typing).
- Non-matching text = miss (consumes a night step).

## Planning and Map Tools (Any)
- cursor <x y> - Example: cursor 8 5 - Phase: Any.
- cursor <dir> [n] - Example: cursor up 3 - Phase: Any.
- inspect [x y] - Example: inspect 8 5 - Phase: Any.
- map - Example: map - Phase: Any.
- preview <type|none> - Example: preview tower - Phase: Any (UI-only preview).
- overlay path <on|off> - Example: overlay path on - Phase: Any.

## Panels and UI Toggles (UI-only)
- settings - Example: settings - Phase: Any (toggle panel).
- settings show - Example: settings show - Phase: Any.
- settings hide - Example: settings hide - Phase: Any.
- settings scale <80|90|100|110|120|130|140|+|-|reset> - Example: settings scale 120 - Phase: Any.
- settings font <80|90|100|110|120|130|140|+|-|reset> - Example: settings font 120 - Phase: Any (alias for settings scale).
- settings compact <on|off|toggle> - Example: settings compact on - Phase: Any.
- settings verify - Example: settings verify - Phase: Any (prints UI diagnostics + keybind conflicts).
- settings conflicts - Example: settings conflicts - Phase: Any (prints keybind conflicts only).
- settings resolve - Example: settings resolve - Phase: Any (dry-run auto-resolve plan).
- settings resolve apply - Example: settings resolve apply - Phase: Any (apply auto-resolve plan).
- settings export - Example: settings export - Phase: Any (prints keybind + UI diagnostics JSON to stdout, schema v4 includes game version).
- settings export save - Example: settings export save - Phase: Any (writes user://settings_export.json).
- tutorial - Example: tutorial - Phase: Any (toggle tutorial panel).
- tutorial restart - Example: tutorial restart - Phase: Any.
- tutorial skip - Example: tutorial skip - Phase: Any.
Note: Tutorial auto-shows on first run when enabled; use `tutorial restart` to replay.
- lessons - Example: lessons - Phase: Any (toggle lessons panel).
- trend - Example: trend - Phase: Any (toggle trend panel).
- history - Example: history - Phase: Any (toggle history panel).
- report [show|hide] - Example: report show - Phase: Any (typing report panel).

## Lessons
- lesson - Example: lesson - Phase: Any (prints list in log).
- lesson <id> - Example: lesson home_row - Phase: Day or game_over only.
- lesson next - Example: lesson next - Phase: Day or game_over only.
- lesson prev - Example: lesson prev - Phase: Day or game_over only.
- lesson sample [n] - Example: lesson sample 3 - Phase: Any.
- lessons sort <default|recent|name> - Example: lessons sort recent - Phase: Any.
- lessons sparkline <on|off> - Example: lessons sparkline off - Phase: Any.
- lessons reset [all] - Example: lessons reset all - Phase: Any.

## Goals (Coaching Only)
- goal - Example: goal - Phase: Any.
- goal <balanced|accuracy|backspace|speed> - Example: goal accuracy - Phase: Any.
- goal next - Example: goal next - Phase: Any.
Note: Goals affect coaching thresholds only, not gameplay balance.

## Keybinds
- bind <action> [key] - Example: bind toggle_compact F4 - Phase: Any.
- bind <action> reset - Example: bind cycle_goal reset - Phase: Any.
Note: binding a key that conflicts with another rebindable action will log a warning; use `settings verify`, `settings conflicts`, or `settings resolve` for details.
Note: auto-resolve uses a safe key pool (F1-F12, then Insert/Delete/Home/End/PageUp/PageDown/PrintScreen/ScrollLock/Pause), then falls back to Ctrl+<safe key> if the pool is exhausted.
Note: key strings are case-insensitive and accept common aliases (PgUp, PrtSc, ScrLk). Spaces, underscores, and hyphens are treated the same; modifier aliases include Control/Ctrl, Option/Alt, and Cmd/Meta/Super/Win.
Note: modifier binds are exact-match at runtime; Ctrl+F1 will not trigger an action bound to F1.
Note: modifier binds persist across sessions and reload with their modifiers intact.
Rebindable actions and defaults:
- toggle_settings (F1)
- toggle_lessons (F2)
- toggle_trend (F3)
- toggle_compact (F4)
- toggle_history (F5)
- toggle_report (F6)
- cycle_goal (F7)

settings verify output format (example):
```
Settings Verify:
Window: 1280x720
UI scale: 100%
Compact panels: OFF
Keybinds: toggle_settings=F1; toggle_lessons=F2; toggle_trend=F3; toggle_compact=F4; toggle_history=F5; toggle_report=F6; cycle_goal=F7
Keybind conflicts: none
Panels: settings=ON lessons=OFF trend=OFF history=OFF report=OFF
Recommendations: settings compact on
```

settings conflicts output format (example):
```
Keybind conflicts: none
```

settings resolve output format (example):
```
Keybind resolve plan (dry-run):
CHANGE: Toggle Lessons Panel (toggle_lessons) F4 -> F8
```

settings resolve output format (example when F-keys are saturated):
```
Keybind resolve plan (dry-run):
CHANGE: Toggle Lessons Panel (toggle_lessons) F4 -> Insert
```

settings resolve output format (example when safe pool is exhausted):
```
Keybind resolve plan (dry-run):
CHANGE: Toggle Lessons Panel (toggle_lessons) F4 -> Ctrl+F1
```

settings resolve apply output format (example):
```
Keybind resolve apply:
APPLIED: Toggle Lessons Panel (toggle_lessons) F4 -> F8
Changes applied: 1
Conflicts remaining: 0
```

settings export output format (example; schema v4 adds game/engine/window/panels):
```
{
  "schema": "typing-defense.settings-export",
  "schema_version": 4,
  "game": { "name": "Keyboard Defense", "version": "1.0.0" },
  "engine": { "godot": "4.2.2", "major": 4, "minor": 2, "patch": 2 },
  "ui": { "scale": 1.0, "compact": false },
  "window": { "width": 1280, "height": 720 },
  "panels": { "settings": false, "lessons": false, "trend": false, "history": false, "report": false },
  "keybinds": [
    { "action": "toggle_settings", "key": "F1" }
  ],
  "conflicts": [],
  "resolve_plan": { "changes": [], "unresolved": [] }
}
```

## Diagnostics and Run Control
- balance verify - Example: balance verify - Phase: Any (runs balance invariant checks).
- balance export [group] - Example: balance export wave - Phase: Any (prints balance JSON to stdout).
- balance export save [group] - Example: balance export save wave - Phase: Any (writes user://balance_export_wave.json).
- balance diff [group] - Example: balance diff wave - Phase: Any (diffs current balance export vs saved baseline).
- balance summary - Example: balance summary - Phase: Any (prints compact balance summary).
- balance summary enemies - Example: balance summary enemies - Phase: Any (prints enemy-focused summary).
- balance summary towers - Example: balance summary towers - Phase: Any (prints tower-focused summary).
- balance summary wave - Example: balance summary wave - Phase: Any (prints wave-focused summary).
- balance summary buildings - Example: balance summary buildings - Phase: Any (prints building-focused summary).
- balance summary midgame - Example: balance summary midgame - Phase: Any (prints midgame-focused summary).
- enemies - Example: enemies - Phase: Any (list active enemies).
- save - Example: save - Phase: Any.
- load - Example: load - Phase: Any.
- new - Example: new - Phase: Any.
- seed <string> - Example: seed warmup-run - Phase: Any.
- restart - Example: restart - Phase: Game over only.
- settings lessons - Example: settings lessons - Phase: Any.
- settings prefs - Example: settings prefs - Phase: Any.

balance verify output format (example):
```
Balance verify: OK
```

balance export groups (prefix filters):
- all (default): all metrics
- wave: night_wave_
- enemies: enemy_
- towers: tower_ or tower_upgrade
- buildings: building_
- midgame: midgame_

balance export axis: days (samples day_01..day_07).

balance diff baseline files:
- all: user://balance_export.json
- wave: user://balance_export_wave.json
- enemies: user://balance_export_enemies.json
- towers: user://balance_export_towers.json
- buildings: user://balance_export_buildings.json
- midgame: user://balance_export_midgame.json

balance diff output format:
```
Balance diff: missing baseline user://balance_export_wave.json
Balance diff: invalid baseline user://balance_export_wave.json
Balance diff: no changes
Balance diff: 1 changes
day_07 night_wave_total_base: 5 -> 6
```

balance export metrics (48):
```
building_farm_cost_wood
building_farm_production_food
building_lumber_cost_food
building_lumber_cost_wood
building_lumber_production_wood
building_quarry_cost_food
building_quarry_cost_wood
building_quarry_production_stone
building_tower_cost_stone
building_tower_cost_wood
building_tower_defense
building_wall_cost_stone
building_wall_cost_wood
building_wall_defense
enemy_armored_armor
enemy_armored_hp_bonus
enemy_armored_speed
enemy_raider_armor
enemy_raider_hp_bonus
enemy_raider_speed
enemy_scout_armor
enemy_scout_hp_bonus
enemy_scout_speed
midgame_caps_food
midgame_caps_stone
midgame_caps_wood
midgame_food_bonus
midgame_food_bonus_amount
midgame_food_bonus_day
midgame_food_bonus_threshold
midgame_stone_catchup_day
midgame_stone_catchup_min
night_wave_total_base
night_wave_total_threat2
night_wave_total_threat4
tower_level1_damage
tower_level1_range
tower_level1_shots
tower_level2_damage
tower_level2_range
tower_level2_shots
tower_level3_damage
tower_level3_range
tower_level3_shots
tower_upgrade1_cost_stone
tower_upgrade1_cost_wood
tower_upgrade2_cost_stone
tower_upgrade2_cost_wood
```

balance summary output format (default):
```
Balance summary (days):
id | night_wave_total_base | night_wave_total_threat2 | night_wave_total_threat4 | enemy_scout_speed | tower_level1_damage
day_01 | 2 | 4 | 6 | 2 | 1
```

balance summary enemies output format:
```
Balance summary (days/enemies):
id | enemy_scout_hp_bonus | enemy_raider_hp_bonus | enemy_armored_hp_bonus | enemy_scout_speed | enemy_raider_speed | enemy_armored_speed
day_01 | -1 | 0 | 1 | 2 | 1 | 1
```

balance summary towers output format:
```
Balance summary (days/towers):
id | tower_level1_damage | tower_level1_shots | tower_level2_damage | tower_level2_shots | tower_level3_damage | tower_level3_shots
day_01 | 1 | 1 | 1 | 2 | 2 | 2
```

balance summary wave output format:
```
Balance summary (days/wave):
id | night_wave_total_base | night_wave_total_threat2 | night_wave_total_threat4
day_01 | 2 | 4 | 6
```

balance summary buildings output format:
```
Balance summary (days/buildings):
id | building_farm_cost_wood | building_farm_production_food | building_lumber_cost_food | building_lumber_cost_wood | building_lumber_production_wood | building_quarry_cost_food | building_quarry_cost_wood | building_quarry_production_stone | building_tower_cost_stone | building_tower_cost_wood | building_wall_cost_stone | building_wall_cost_wood
day_01 | 10 | 2 | 2 | 5 | 2 | 2 | 5 | 2 | 10 | 5 | 5 | 5
```

balance summary midgame output format:
```
Balance summary (days/midgame):
id | midgame_caps_food | midgame_caps_wood | midgame_caps_stone | midgame_food_bonus_day | midgame_food_bonus_amount | midgame_food_bonus_threshold | midgame_food_bonus | midgame_stone_catchup_day | midgame_stone_catchup_min
day_01 | 0 | 0 | 0 | 5 | 2 | 12 | 0 | 4 | 8
```

balance summary unknown group output:
```
Balance summary: unknown group banana
```

## External Scripts
- scripts/export_windows.ps1 - Example: powershell -ExecutionPolicy Bypass -File .\scripts\export_windows.ps1 - Phase: Any (dry-run export; see docs/EXPORT_WINDOWS.md).
- scripts/export_windows.sh - Example: bash ./scripts/export_windows.sh - Phase: Any (dry-run export; see docs/EXPORT_WINDOWS.md).
## Verification Scripts
Use these scripts to validate tests, scenarios, and a smoke boot.
The canonical invocation is from the repo root so relative paths match.
Run from the repo root when automating CI or when unsure of your CWD.
Repo-root verification commands (canonical):
```
powershell -ExecutionPolicy Bypass -File .\scripts\test.ps1
bash ./scripts/test.sh
powershell -ExecutionPolicy Bypass -File .\scripts\scenarios.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\scenarios_early.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\scenarios_mid.ps1
bash ./scripts/scenarios.sh
bash ./scripts/scenarios_early.sh
bash ./scripts/scenarios_mid.sh
godot --headless --path . --quit-after 2
```
These commands assume the current working directory is the repo root.
The repo-root scripts locate the Godot project under apps/keyboard-defense-godot.
They write logs into the app folder so outputs stay consistent.
App-local wrappers allow the same commands from inside the app directory.
Use them when you are already in apps/keyboard-defense-godot.
App-dir verification commands (wrappers):
```
powershell -ExecutionPolicy Bypass -File .\scripts\test.ps1
bash ./scripts/test.sh
powershell -ExecutionPolicy Bypass -File .\scripts\scenarios.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\scenarios_early.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\scenarios_mid.ps1
bash ./scripts/scenarios.sh
bash ./scripts/scenarios_early.sh
bash ./scripts/scenarios_mid.sh
```
Each wrapper prints a single delegation line before executing.
The wrappers change to the repo root before invoking the target script.
This keeps relative paths identical to the canonical repo-root run.
Arguments are passed through unchanged to the root scripts.
Exit codes are returned directly to the caller.
If you see a delegation line, you are using the wrapper path.
If you are in the repo root, the root scripts run directly.
Do not run these scripts from other directories unless you intend delegation.
Both paths are supported so local testing is less error-prone.
Prefer the repo-root commands in documentation and automation.
Use app-dir wrappers for quick local iteration.
Logs: _test.log and _scenarios*.log are written under the app folder.
Scenario summaries still emit from Logs/ScenarioReports/last_summary.txt.
Godot resolution is unchanged; set GODOT_PATH to override.
These wrappers are deterministic and do not modify script behavior.
Keep the repo-root scripts as the source of truth for verification logic.
