# Butler Workflow (itch.io) - Planning Notes

Butler is itch.io's recommended command-line uploader (verify latest usage in itch.io docs).

## Channel Naming
- `windows`: Windows build zip
- `mac`: macOS build zip
- `linux`: Linux build zip

## Suggested Script Layout
- `scripts/build-windows`
- `scripts/publish-itch`

## Preflight Checks
- Fresh Windows run:
  - input capture works (no focus issues)
  - windowed and fullscreen toggles work
- Save behavior:
  - saves write to `user://` without errors



