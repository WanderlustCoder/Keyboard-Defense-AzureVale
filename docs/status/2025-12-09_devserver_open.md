# Dev Server One-Command Open - 2025-12-09
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Added `npm run serve:open` to automatically start the dev server with `--no-build` when needed, reuse a healthy running instance, and open the game in the default browser. Supports `--force-restart` to replace an existing server before opening, plus `--host`/`--port` overrides for remote/device testing.
- Updated `apps/keyboard-defense/docs/DEVELOPMENT.md` to document the shortcut alongside the existing serve/monitor commands.

## Verification
- `cd apps/keyboard-defense && npm run serve:open`
- `cd apps/keyboard-defense && npm run serve:open -- --force-restart`
- `cd apps/keyboard-defense && npm run serve:open -- --host 0.0.0.0 --port 4200`

## Related Work
- `apps/keyboard-defense/scripts/openDevServer.mjs`
- `apps/keyboard-defense/scripts/devServer.mjs`

