# Steam Depot Plan Template

## Depots
Define depots per platform.

Example (edit to match your targets):
- Depot 1: Windows x64
- Depot 2: (Optional) macOS
- Depot 3: (Optional) Linux

## Build Output Layout (recommended)
- `build/<platform>/KeyboardDefense.exe` (or equivalent)
- `build/<platform>/assets/`
- `build/<platform>/licenses/`
- `build/<platform>/version.json`

## Upload Checklist
- Confirm version.json contains:
  - version string
  - git commit hash
  - build timestamp (UTC)
- Run smoke test:
  - New run starts
  - Save/load works
  - Typing input works
  - Audio and rendering work

## Rollback Plan
- Keep the previous build available as a "last known good".
- Tag releases in git for traceability.



