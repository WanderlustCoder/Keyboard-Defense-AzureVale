# Keyboard Defense (Godot 4)

This is the Windows-targeted Godot 4 port focused on a pixel-art fantasy kingdom typing trainer.
The typing loop drives all defense outcomes; map progression and kingdom upgrades unlock as typing mastery grows.

## Open in Godot

1. Launch Godot 4.
2. Import the project from this folder.
3. Run the main scene (`scenes/MainMenu.tscn`).

## Data

- `data/lessons.json`: lesson word lists for battles.
- `data/map.json`: campaign nodes, unlock requirements, and drill template references.
- `data/drills.json`: shared drill templates referenced by the map.
- `data/kingdom_upgrades.json`: kingdom upgrade definitions.
- `data/unit_upgrades.json`: unit upgrade definitions.

## Notes

- Save data is stored at `user://typing_kingdom_save.json`.
- This is an early playable loop: map -> battle -> rewards -> kingdom.

## Automated Tests

Run headless tests with Godot 4 installed:

```powershell
.\scripts\run_tests.ps1
```

Set `GODOT_PATH` if the executable is not on PATH.
