# Keyboard Defense (Godot) Reference

The active project is the Godot 4 version located at `apps/keyboard-defense-godot`.
The previous web app (`apps/keyboard-defense`) has been retired.

## Open in Godot

1. Launch Godot 4.
2. Import the project from `apps/keyboard-defense-godot`.
3. Run the main scene: `scenes/MainMenu.tscn`.

## Key Data Files

- `apps/keyboard-defense-godot/data/lessons.json` - Lesson word lists for battles.
- `apps/keyboard-defense-godot/data/map.json` - Campaign nodes, unlocks, drill templates.
- `apps/keyboard-defense-godot/data/drills.json` - Drill templates referenced by the map.
- `apps/keyboard-defense-godot/data/kingdom_upgrades.json` - Kingdom upgrade definitions.
- `apps/keyboard-defense-godot/data/unit_upgrades.json` - Unit upgrade definitions.

`map.json` supports `drill_overrides`:
- `steps`: merge data into existing steps by index.
- `replace`: replace steps by index.
- `remove`: remove steps by index.
- `prepend`/`append`: insert steps at the start/end.

## Tests

Run headless tests (Godot 4 required):

```powershell
.\scripts\run_tests.ps1
```

Set `GODOT_PATH` if the Godot executable is not on PATH.

## Notes

- Save data lives at `user://typing_kingdom_save.json`.
- Core folders: `scenes/`, `scripts/`, `assets/`, `themes/`.
